class Numeric
  def two
    "%.2f" % self
  end
end

define_stage :level_play do
  render_with :multi_viewport_renderer

  setup do
    # TODO cleaner way to summon these into existance at the stage context
    # required_stage_hands :bomb_coordinator, :bullet_coordinator, etc.. 
    bomb_c = this_object_context[:bomb_coordinator]
    bullet_c = this_object_context[:bullet_coordinator]
    sword_c = this_object_context[:sword_coordinator]

    director.update_slots = [:first, :before, :update, :last]

    @console = create_actor(:console, visible: false)

    backstage[:level_name] ||= LEVELS.keys[0]
    backstage[:player_count] ||= LEVELS.values[0]

    LEVELS.size.times do |i|
      input_manager.reg :down, Object.const_get("Kb#{i+1}") do
        backstage[:level_name] = LEVELS.keys[i]
        backstage[:player_count] = LEVELS.values[i]

        fire :restart_stage

      end
    end

    setup_level backstage[:level_name]
    setup_players backstage[:player_count]


    director.when :update do |time|
      # TODO EEEEEWWWWW
      renderer.viewports.each { |vp| vp.update time }

      unless @restarting
        alive_players = @players.select{|player| player.alive?}
        round_over if alive_players.size < @players.size
      end
    end

    # F1 console watch values
    player = @players[1]
    if player
      @console.react_to :watch, :p2x do player.x.two end
      @console.react_to :watch, :p2y do player.y.two end
      @console.react_to :watch, :sb2 do player.viewport.screen_bounds end
    end

  end


  helpers do
    include GameSession

    attr_accessor :players, :viewports

    LEVELS = {
      :advanced_jump => 2,
      :cave => 2,
      :basic_jump => 1,
      :hot_pocket => 2,
    }


    def setup_level(name)
      # TODO XXX hack until all other stages are in place
      init_session
      @level = LevelLoader.load self, name
    end

    def setup_players(player_count=1)
      @players = []
      player_count.times do |i|
        setup_player "player#{i+1}".to_sym
      end
      (4-player_count).times do |i|
        player_count + i
        remove_player "player#{player_count+i+1}".to_sym
      end
      renderer.viewports = PlayerViewport.create_n @players, config_manager[:screen_resolution]
    end

    def remove_player(name)
      player = @level.named_objects[name]
      player.remove if player
    end

    def setup_player(name)
      player = @level.named_objects[name]
      if player
        player.vel = vec2(0,3)
        player.input.map_input(controls[name])
        @players << player
      end
    end

    def controls
      { player1: {
          '+b' => :shoot,
          '+n' => :charging_jump,
          '+m' => :charging_bomb,
          '+v' => :shields_up,
          '+w' => :look_up,
          '+a' => [:look_left, :walk_left],
          '+d' => [:look_right, :walk_right],
          '+s' => :look_down,
        },
        player2: {
          '+i' => :shoot,
          '+o' => :charging_jump,
          '+p' => :charging_bomb, 
          '+u' => :shields_up, 
          '+t' => :look_up,
          '+f' => [:look_left, :walk_left],
          '+h' => [:look_right, :walk_right],
          '+g' => :look_down,

          '+gp_button_0' => :shoot,
          '+gp_button_1' => :charging_jump,
          '+gp_button_2' => :charging_bomb,
          '+gp_button_3' => :shields_up,
          '+gp_up' => :look_up,
          '+gp_left' => [:look_left, :walk_left],
          '+gp_right' => [:look_right, :walk_right],
          '+gp_down' => :look_down,
        }
      }
    end

    def round_over
      @restarting = true
      timer_manager.add_timer 'restart', 2000 do
        timer_manager.remove_timer 'restart'
        fire :restart_stage 
      end
    end

  end
end

class MultiViewportRenderer < Renderer
  construct_with :viewport
  attr_accessor :viewports

  def initialize
    super
    $debug_drawer = DebugDraw.new
  end

  def draw(target)
    @viewports.each do |vp|
      draw_viewport target, vp
    end

    @color ||= Color::BLACK #Color.new 255, 41, 145, 179
    target.fill_screen @color, -1
    $debug_drawer.draw_blocks.each do |name, dblock|
      dblock.call target
    end
  end

  private
  def draw_viewport(target, viewport)
    screen_bounds = viewport.screen_bounds
    center_x = screen_bounds.width / 2 + screen_bounds.x
    center_y = screen_bounds.height / 2 + screen_bounds.y

    target.draw_box(
      screen_bounds.x,
      screen_bounds.y, 
      screen_bounds.x+screen_bounds.width,
      screen_bounds.y+screen_bounds.height, Color::BLACK, ZOrder::HudText)

    target.clip_to(*screen_bounds) do
      target.rotate(-viewport.rotation, center_x, center_y) do
        z = 0
        @parallax_layers.each do |parallax_layer|
          drawables_on_parallax_layer = @drawables[parallax_layer]

          if drawables_on_parallax_layer
            @layer_orders[parallax_layer].each do |layer|

              trans_x = viewport.x_offset parallax_layer
              trans_y = viewport.y_offset parallax_layer

              z += 1
              drawables_on_parallax_layer[layer].each do |drawable|
                drawable.draw target, trans_x, trans_y, z
              end
            end
          end
        end
      end # rotate
    end # clip_to
  end
end

class DebugDraw
  attr_reader :draw_blocks
  def initialize
    clear
  end

  def clear
    @draw_blocks = {}
  end

  def draw(name, &block)
    @draw_blocks[name] = block
  end
end

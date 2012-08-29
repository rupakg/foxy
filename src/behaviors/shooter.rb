define_behavior :shooter do
  requires :timer_manager, :stage
  setup do
    actor.has_attributes accel: vec2(0,0),
                         shot_power: opts[:shot_power],
                         kickback: opts[:kickback],
                         shot_recharge_time: opts[:recharge_time],
                         can_shoot: true,
                         gun_direction: DIRECTIONS[:right]
                        
    # TODO abstract this into gamebox (controls or something)
    input = actor.input
    input.when :look_left do
      actor.gun_direction = DIRECTIONS[:left]
    end
    input.when :look_right do
      actor.gun_direction = DIRECTIONS[:right]
    end
    input.when :look_up do
      actor.gun_direction = DIRECTIONS[:up]
    end
    input.when :look_down do
      actor.gun_direction = DIRECTIONS[:down]
    end

    input.when :shoot do
      if actor.can_shoot?
        actor.can_shoot = false
        rotated_gun_dir = actor.gun_direction.rotate(degrees_to_radians(actor.rotation))
        actor.accel += rotated_gun_dir.dup.reverse! * actor.kickback
        # seems strange, even though in physics terms we should add the
        # actor.vel
        shot_vel = (rotated_gun_dir*actor.shot_power) #+ actor.vel
        stage.create_actor :bullet, player: actor, x: actor.x, y: actor.y, map: actor.map, vel: shot_vel
        actor.react_to :play_sound, :shoot
        unless actor.on_ground?
          gun_angle = actor.gun_direction.angle
          if gun_angle == 0
            actor.rotation_vel -= 0.3 
          elsif gun_angle == Math::PI
            actor.rotation_vel += 0.3 
          end
        end
        timer_name = "#{actor.object_id}:shot_recharge"
        timer_manager.add_timer timer_name, actor.shot_recharge_time do
          actor.can_shoot = true
          timer_manager.remove_timer timer_name
        end
      end
    end

    actor.when :remove_me do
      remove 
    end

    reacts_with :remove
  end

  helpers do
    DIRECTIONS = {
      left: vec2(-1,0),
      right: vec2(1,0),
      up: vec2(0,-1),
      down: vec2(0,1)
    }

    def remove
      timer_manager.remove_timer 'shot_recharge'
    end
  end

end


define_behavior :bomber do
  requires :stage, :director
  setup do
    # lets start with infinite bombs, fixed vel
    actor.has_attributes bomb_charge: 0,
                         max_bomb_charge: 2,
                         was_charging_bomb: false,
                         bomb_kickback: opts[:bomb_kickback] || 0
                        
    director.when :first do |time, time_secs|
      update_bombing time_secs
    end

  end

  helpers do
    include MinMaxHelpers

    def update_bombing(time_secs)
      input = actor.input
      if actor.was_charging_bomb? && !input.charging_bomb?
        actor.was_charging_bomb = false

        bomb_if_able

      elsif input.charging_bomb?
        actor.bomb_charge += time_secs
        actor.bomb_charge = min(actor.max_bomb_charge, actor.bomb_charge)
        actor.was_charging_bomb = true
      end
    end

    def bomb_if_able

      percent = (actor.bomb_charge / actor.max_bomb_charge.to_f)
      power = 10 * percent

      rotated_gun_dir = actor.gun_direction.rotate(degrees_to_radians(actor.rotation))
      # TODO not working!
      actor.accel += rotated_gun_dir.dup.reverse! * actor.bomb_kickback * percent

      bomb_vel = rotated_gun_dir * power

      stage.create_actor :bomb, player: actor, x: actor.x, y: actor.y, map: actor.map, vel: bomb_vel
      actor.react_to :play_sound, :shoot

      actor.bomb_charge = 0

      # TODO Add some rotational force
      # TODO scale kickback by charge
    end

  end

end


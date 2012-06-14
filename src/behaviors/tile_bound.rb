define_behavior :tile_bound do
  setup do
    raise "vel required" unless actor.has_attribute? :vel
    actor.when :tile_collisions do |collisions|
      if collisions
        new_x = nil
        new_y = nil

        # for events
        hit_top = false
        hit_bottom = false
        hit_left = false
        hit_right = false

        # puts "#{collisions.size} #{collisions.inspect}"
        collisions.each do |collision|
          point_index = collision[:point_index]
          fudge = 0.01
          case collision[:tile_face]
          when :top
            # some edge case here
            if point_index == 2 || point_index == 3
              new_y = (collision[:hit][1] - actor.height - fudge)
              # $debug_drawer.draw(:top_collision) do |target|
              #   c = Color::RED
              #   target.draw_line 0, new_y + actor.height, 2_000, new_y + actor.height, c, 99_999
              # end
              hit_bottom = true
            end
          when :bottom
            if point_index == 0 || point_index == 1
              new_y = collision[:hit][1] + fudge
              hit_top = true
            end
          when :left
            if point_index == 1 || point_index == 2
              # puts "LEFT    : #{collision.inspect}"
              new_x = (collision[:hit][0] - actor.width - fudge)
              # $debug_drawer.draw(:right_collision) do |target|
              #   c = Color::RED
              #   target.draw_line new_x + actor.width, 0, new_x + actor.width, 2_000, c, 99_999
              # end
              hit_right = true
            end
          when :right
            if point_index == 0 || point_index == 3
              new_x = collision[:hit][0] + fudge
              hit_left = true
            end
          end
        end

        if new_y
          # puts "moving actor from #{actor.y} to #{new_y}"
          actor.y = new_y
          # actor.vel.y = 0 
          # actor.accel.y = 0 
        end

        if new_x
          # puts "moving actor from #{actor.x} to #{new_x}"
          actor.x = new_x
          # actor.vel.x = 0 
          # actor.accel.x = 0 
        end

        actor.emit :hit_top if hit_top
        actor.emit :hit_bottom if hit_bottom
        actor.emit :hit_left if hit_left
        actor.emit :hit_right if hit_right
      end

      # TODO move actor, truncate velocity if required
      # send event to tiles that collided?
      
      # if collisions.nil? || (!collisions.nil? && collisions.empty?)
      actor.x += actor.vel.x unless hit_left || hit_right
      actor.y += actor.vel.y unless hit_top || hit_bottom
      # end

      # EEK.. TODO XXX where should this live?
      actor.accel = vec2(0,0)

      # puts "actor y : #{actor.y}"
    end
  end
end

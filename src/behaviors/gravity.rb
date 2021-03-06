define_behavior :gravity do
  requires :director
  setup do
    actor.has_attributes gravity: opts[:dir]

    director.when :first do |time, time_secs|
      actor.accel += (actor.gravity * time_secs)
    end

    actor.when :remove_me do
      director.unsubscribe_all self
    end

    reacts_with :remove
  end

  helpers do
    def remove
      director.unsubscribe_all self
    end
  end
end

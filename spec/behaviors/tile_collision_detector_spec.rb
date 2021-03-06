require 'spec_helper'

describe :tile_collision_detector do
  # TODO AAAAAHHHHH gamebox should hide this from me! VVVVVVVVVV
  let(:opts) { {} } 
  subject { subcontext[:behavior_factory].add_behavior actor, :tile_collision_detector, opts }
  let(:director) { evented_stub(stub_everything('director')) }
  let(:subcontext) do 
    it = nil
    Conject.default_object_context.in_subcontext{|ctx|it = ctx}; 
    _mocks = create_mocks *(Actor.object_definition.component_names + ActorView.object_definition.component_names - [:actor, :behavior, :this_object_context])
    _mocks.each do |k,v|
      it[k] = v
      it[:director] = director
    end
    it
  end
  let!(:actor) { subcontext[:actor] }
  # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

  let(:map_data) { stub('map data', tile_size: 16, tile_grid: grid) }
  let(:grid) { [
    [nil, 1 ,nil],
    [nil,nil,nil],
    [nil,nil, 1 ],
  ]}
  let(:map) { stub('map', map_data: map_data) }

  describe "a single point object" do
    before do
      actor.has_attributes vel: vec2(0,0), 
                           bb: Rect.new(0,0,10,10), 
                           map: map,
                           x: 5,
                           y: 5,
                           rotation: 0,
                           width: 10,
                           height: 10,
                           collision_point_deltas: [vec2(0,0)]

    end

    it 'emits w/ empty data when there are no collisions' do
      subject
      
      expects_event actor, :tile_collisions, [[nil]] do
        director.fire :update, 1
      end
    end

    it 'emits w/ data when there is a basic left collision' do
      actor.x = 12
      actor.vel = vec2(5,0)
      subject
      
      expects_event actor, :tile_collisions, [[[{:row=>0, :col=>1, :tile_face=>:left, :hit=>[16.ish, 5.0.ish, 17.0.ish, 5.0.ish], :point_index=>0}]]] do
        director.fire :update, 1
      end
    end

    it 'emits w/ data when with collision on the corner' do
      actor.x = 30
      actor.y = 30
      actor.bb = Rect.new(25,25,35,35)
      actor.vel = vec2(4.1,4.1)
      subject
      
      expects_event actor, :tile_collisions, [[[{:row=>2, :col=>2, :tile_face=>:top, :hit=>[32.ish, 32.ish, 34.1.ish, 34.1.ish], :point_index=>0}]]] do
        director.fire :update, 1
      end
    end
  end

  describe "a foxy-like object at glancing angle" do
    let(:grid) { [[nil,nil, 1]] * 8 }
    before do
      actor.has_attributes vel: vec2(0,-4), 
                           bb: Rect.new(0,0,16*3,16*8), 
                           map: map,
                           x: 17,
                           y: 65,
                           rotation: 0.0,
                           rotation_vel: -3,
                           width: 28,
                           height: 40,
                           collision_point_deltas: [
                             vec2(-14.0, -20.0), 
                             vec2(14.0, -20.0), 
                             vec2(14.0, -10.0), 
                             vec2(14.0, 10.0), 
                             vec2(14.0, 20.0), 
                             vec2(-14.0, 20.0), 
                             vec2(-14.0, 10.0), 
                             vec2(-14.0, -10.0)]
    end

    it 'does not get stuck on a wall' do
      subject
      
      expects_event actor, :tile_collisions, [[[{:row=>5, :col=>2, :tile_face=>:left, :hit=>
        [32.ish, 80.367.ish, 32.027.ish, 80.239.ish], :point_index=>4}]]] do
      director.fire :update, 1
      end
    end
  end

end

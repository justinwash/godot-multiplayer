extends Node

var started = true

var client_tick = 0

const BUFFER_SIZE := 120

var input_buffers := {}
var state_buffers := {}

var unacked_inputs := {}
var acked_inputs := {}

var snapshots_to_process := {}


func add_peer_and_self(id):
  input_buffers[id] = Types.RingBuffer.new(BUFFER_SIZE)
  state_buffers[id] = Types.RingBuffer.new(BUFFER_SIZE)
  unacked_inputs[id] = {}
  
  if multiplayer.get_unique_id() != 1:
    input_buffers[multiplayer.get_unique_id()] = Types.RingBuffer.new(BUFFER_SIZE)
    state_buffers[multiplayer.get_unique_id()] = Types.RingBuffer.new(BUFFER_SIZE)
    unacked_inputs[multiplayer.get_unique_id()] = {}


func _physics_process(delta):
  if !started: return
  
  # Process player entities (those that will be sending us inputs)
  for node in get_tree().get_nodes_in_group("player"):
    
    # If this node is still owned by the server, don't do anything
    var id = node.get_multiplayer_authority()
    if id == 1: return
    
    # If we are the local player, gather input (if any) and send to server
    if node.is_multiplayer_authority():
      var input = node._get_local_input()
      if input.size() > 0:
        unacked_inputs[id][client_tick] = input
          
        rpc_id(1, "receive_inputs", id, unacked_inputs[id])

      # Then process the input locally and save the resulting state
      node._network_process(input)
      state_buffers[id].put_t(client_tick, node._save_state())
      
      client_tick += 1
      
    # if we are the server, then try to process the inputs we have received
    elif multiplayer.is_server():
      input_buffers[id].reset_rollback_tick()
      if unacked_inputs[id].size() < 1:
        # print('no input received this tick from ', id)
        node._network_process({})
        state_buffers[id].append(node._save_state())

      for input_tick in unacked_inputs[id].keys():
        # If we already sent an acknowledgement for this tick, don't reprocess it
        if acked_inputs.has(input_tick):
          continue
          
        # If the tick is from over 2 second ago, don't process it, as its outside the buffer length
        if input_buffers[id].get_current_tick() - input_tick > 119:
          continue
          
        # Else put it in the input buffer
        input_buffers[id].put_t(input_tick, unacked_inputs[id][input_tick])

        if input_tick > input_buffers[id].get_current_tick():
          if input_buffers[id].get_rollback_tick() == input_buffers[id].get_current_tick():
            input_buffers[id].set_rollback_tick(input_tick)
          input_buffers[id].set_current_tick(input_tick)
        else:
          continue
        
#        elif input_tick <= input_buffers[id].get_rollback_tick():
#          input_buffers[id].set_rollback_tick(input_tick)
      
#      # If we received an old or missed input, then we need to rollback to the tick before that input
#      if input_buffers[id].get_rollback_tick() < input_buffers[id].get_current_tick():
#        node._load_state(state_buffers[id].get_t(input_buffers[id].get_rollback_tick() - 1))
#        for input_tick in range(input_buffers[id].get_rollback_tick(), input_buffers[id].get_current_tick()):
#          var input = input_buffers[id].get_t(input_tick)
#          node._network_process(input if input != null else {})
#          state_buffers[id].put_t(input_tick, node._save_state())
#
#      # If we don't need to change history, then we need just need to process it and move on
#      else:
        var input = input_buffers[id].current()
        var process_with = input if input != null else {}
        node._network_process(process_with)
        state_buffers[id].put_t(input_buffers[id].get_current_tick(), node._save_state())
        
      # Then move processed inputs from unacked to acked
      acked_inputs[id] = unacked_inputs[id].duplicate()
      unacked_inputs[id] = {}
        
    # If we are a remote player, do ...something?
    else:
      if snapshots_to_process.has(node.get_multiplayer_authority()):
        for state in snapshots_to_process[node.get_multiplayer_authority()]:
          node._load_state(state)
        

  # If we're not the server, then we're done
  if !multiplayer.is_server():
    return
    
  # If we are, then grab a snapshot of the current gamestate and send it to all the players
  var snapshot = {}
    
  for node in get_tree().get_nodes_in_group("player"):
    
    # If this node is still owned by the server, don't do anything
    var id = node.get_multiplayer_authority()
    if id == 1: return
        
    # Else add it to the snapshot of the current gamestate and the ids of ticks we acked
    snapshot[node.get_multiplayer_authority()] = {
      "state": state_buffers[id].current(),
      "acked_inputs": acked_inputs[id]
    }
    
  rpc("receive_snapshot", snapshot)
  

@rpc("any_peer", "unreliable") func receive_inputs(id, inputs):
  for input in inputs:
    if !unacked_inputs[id].has(input):
      unacked_inputs[id][input] = inputs[input]
  
  
@rpc("authority", "unreliable") func receive_snapshot(snapshot):
  var id = multiplayer.get_unique_id()
  for ack in snapshot[id]["acked_inputs"]:
    if unacked_inputs[id].has(ack):
      unacked_inputs[id].erase(ack)
  
  for node in get_tree().get_nodes_in_group("player"):
    var node_id = node.get_multiplayer_authority()
    if node_id != id:
      if !snapshots_to_process.has(node_id):
        snapshots_to_process[node_id] = [snapshot[node.get_multiplayer_authority()]["state"]]
      else:
        snapshots_to_process[node_id].append(snapshot[node.get_multiplayer_authority()]["state"])
  #print("received snapshot: ", snapshot)



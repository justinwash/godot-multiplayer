extends Node

var started = true

var tick = 0

const BUFFER_SIZE := 120

var input_buffers := {}
var state_buffers := {}

var unacked_inputs := {}


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
        unacked_inputs[id][tick] = input
          
        rpc_id(1, "receive_inputs", id, unacked_inputs[id])
      
      # Then predict the outcome of the input and save it to our state buffer
      node._network_process(input)
      state_buffers[id].append(node._save_state())
      
    
    elif multiplayer.is_server():
      pass
      
      
      
  tick += 1
  

@rpc("any_peer", "unreliable") func receive_inputs(id, inputs):
  for input in inputs:
    if !unacked_inputs[id].has(input):
      unacked_inputs[id][tick] = input
  



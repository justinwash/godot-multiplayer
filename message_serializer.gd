extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"

const input_path_map = {
  "/root/Main/Players/Player1": 1,
  "/root/Main/Players/Player2": 2,
}

var input_path_map_read := {}

func _init() -> void:
  for key in input_path_map:
    input_path_map_read[input_path_map[key]] = key

enum HEADER_FLAGS {
  HAS_INPUT_VECTOR = 0x01,
  HAS_JUMP = 0x02,
  HAS_ROTATION = 0x04,
  HAS_CAMERA_GLOBAL_ROTATION = 0x08,
  HAS_FIRE = 0x10,
  HAS_MOUSE_MOVEMENTS = 0x20,
  HAS_ROTATION_HELPER_GLOBAL_ROTATION = 0x40
}

func serialize_input(all_input: Dictionary) -> PackedByteArray:
  var buffer = StreamPeerBuffer.new()
  buffer.resize(32)
  
  buffer.put_32(all_input['$'])
  buffer.put_u8(all_input.size() - 1)
  
  for path in all_input:
    if path == '$':
      continue
    buffer.put_u8(input_path_map[path])
    
    var input = all_input[path]
    
    # input_vector
    var input_vector_header = 0
    if input.has("input_vector"):
      input_vector_header |= HEADER_FLAGS.HAS_INPUT_VECTOR
      
    buffer.put_u8(input_vector_header)
    
    if input.has("input_vector"):
      var input_vector = input["input_vector"]
      buffer.put_float(input_vector.x)
      buffer.put_float(input_vector.y)
      
    # jump
    var jump_header = 0
    if input.has("jump"):
      jump_header |= HEADER_FLAGS.HAS_JUMP
      
    buffer.put_u8(jump_header)
    
    if input.has("jump"):
      buffer.put_u8(1 if input["jump"] == true else 0)
      
    # fire
    var fire_header = 0
    if input.has("fire"):
      fire_header |= HEADER_FLAGS.HAS_FIRE
      
    buffer.put_u8(fire_header)
    
    if input.has("fire"):
      buffer.put_u8(1 if input["fire"] == true else 0)
    
    # camera_global_rotation
    var camera_global_rotation_header = 0
    if input.has("_camera_global_rotation"):
      camera_global_rotation_header |= HEADER_FLAGS.HAS_CAMERA_GLOBAL_ROTATION
      
    buffer.put_u8(camera_global_rotation_header)
    
    if input.has("_camera_global_rotation"):
      var camera_global_rotation = input["_camera_global_rotation"]
      buffer.put_float(camera_global_rotation.x)
      buffer.put_float(camera_global_rotation.y)
      buffer.put_float(camera_global_rotation.z)
      
    # rotation_helper_global_rotation
    var rotation_helper_global_rotation_header = 0
    if input.has("_rotation_helper_global_rotation"):
      rotation_helper_global_rotation_header |= HEADER_FLAGS.HAS_ROTATION_HELPER_GLOBAL_ROTATION
      
    buffer.put_u8(rotation_helper_global_rotation_header)
    
    if input.has("_rotation_helper_global_rotation"):
      var rotation_helper_global_rotation = input["_rotation_helper_global_rotation"]
      buffer.put_float(rotation_helper_global_rotation.x)
      buffer.put_float(rotation_helper_global_rotation.y)
      buffer.put_float(rotation_helper_global_rotation.z)
  
  buffer.resize(buffer.get_position())
  return buffer.data_array

func unserialize_input(serialized: PackedByteArray) -> Dictionary:
  var buffer := StreamPeerBuffer.new()
  buffer.put_data(serialized)
  buffer.seek(0)
  
  var all_input = {}
  
  all_input['$'] = buffer.get_u32()
  
  var input_count = buffer.get_u8()
  if input_count == 0:
    return all_input
    
  var path = input_path_map_read[buffer.get_u8()]
  var input := {}
  
  var input_vector_header = buffer.get_u8()
  if input_vector_header & HEADER_FLAGS.HAS_INPUT_VECTOR:
    input["input_vector"] = Vector2(buffer.get_float(), buffer.get_float())
    
  var jump_header = buffer.get_u8()
  if jump_header & HEADER_FLAGS.HAS_JUMP:
    var jump = buffer.get_u8()
    input["jump"] = true if jump == 1 else false
    
  var fire_header = buffer.get_u8()
  if fire_header & HEADER_FLAGS.HAS_FIRE:
    var fire = buffer.get_u8()
    input["fire"] = true if fire == 1 else false
    
  var camera_global_rotation_header = buffer.get_u8()
  if camera_global_rotation_header & HEADER_FLAGS.HAS_CAMERA_GLOBAL_ROTATION:
    input["_camera_global_rotation"] = Vector3(buffer.get_float(), buffer.get_float(), buffer.get_float())

  var rotation_helper_global_rotation_header = buffer.get_u8()
  if rotation_helper_global_rotation_header & HEADER_FLAGS.HAS_ROTATION_HELPER_GLOBAL_ROTATION:
    input["_rotation_helper_global_rotation"] = Vector3(buffer.get_float(), buffer.get_float(), buffer.get_float())
     
  all_input[path] = input
  return all_input
  

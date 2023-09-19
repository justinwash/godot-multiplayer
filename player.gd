extends CharacterBody3D

@onready var camera = $Camera3D

var mouse_movements = []

const SPEED = 20.0
const JUMP_VELOCITY = 16

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
  if multiplayer.get_unique_id() == get_multiplayer_authority() && multiplayer.get_unique_id() !=1:
    $Camera3D.current = true
  
  
func _get_local_input():
  var input_vector = Input.get_vector("strafe_left", "strafe_right", "forward", "backward")
    
  var input := {}
  if input_vector != Vector2.ZERO:
    input["input_vector"] = input_vector
  
  if Input.is_action_just_pressed("ui_accept") and is_on_floor():
    input["jump"] = true
  
  input["rotation"] = rotation
  input["camera_rotation"] = camera.rotation
  
  return input

func _network_process(input):
  if input.size() <= 0:
    return
    
  velocity = Vector3(0, velocity.y, 0)
  
  if !is_multiplayer_authority():
    rotation = input["rotation"]
    camera.rotation = input["camera_rotation"]
    
  if not is_on_floor():
    velocity.y -= 1
    
  if input.get("jump") and is_on_floor():
    velocity.y = JUMP_VELOCITY
  
  if input.get("input_vector"):
    var direction = (Vector3(input.input_vector.x, 0, input.input_vector.y).rotated(Vector3.UP, input["rotation"].y)).normalized()
    if direction:
      velocity.x = direction.x * SPEED
      velocity.z = direction.z * SPEED
    
  move_and_slide()
  
func _save_state():
  return {
    "position": position,
    "velocity": velocity,
    "rotation": rotation,
    "camera_rotation": camera.rotation
  }
  
func _load_state(state):
  position = state["position"]
  velocity = state["velocity"]
  rotation = state["rotation"]
  camera.rotation = state["camera_rotation"]
  
func _input(event):
  if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED && is_multiplayer_authority():
    if event is InputEventMouseMotion:
      rotate_y(deg_to_rad(-event.relative.x * 0.1))
      camera.rotate_x(deg_to_rad(-event.relative.y * 0.1))
      camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

extends CharacterBody3D

@onready var rotation_helper = $RotationHelper
@onready var camera: Camera3D = $RotationHelper/Camera3D
@onready var _fire_timer: NetworkTimer = $FireTimer
@onready var _aim_point: Marker3D = $RotationHelper/Camera3D/AimPoint
@onready var _projectile_spawn_point: Marker3D = $RotationHelper/Camera3D/ProjectileSpawnPoint
@onready var _projectiles_node: Node3D = get_node("/root/Main/Projectiles")
var fireball_scene = preload("res://projectiles/fireball/Fireball.tscn")

var mouse_movements = []

const SPEED = 16.0
const JUMP_VELOCITY = 16

var fire_ready = true

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var current_input = {}

var last_position
var last_velocity
var last_rotation
var last_camera_rotation

var start_rotation = null

var allow_mouse_input = false


func _process(delta):
  rotation_helper.global_position = global_position

func _physics_process(delta):
  if multiplayer.get_unique_id() == get_multiplayer_authority() && multiplayer.get_unique_id() !=1:
    camera.current = true
  
  
func _get_local_input():
  var input_vector = Input.get_vector("strafe_left", "strafe_right", "forward", "backward")
    
  var input := {}
  if input_vector != Vector2.ZERO:
    input["input_vector"] = input_vector
  
  if Input.is_action_just_pressed("ui_accept") and is_on_floor():
    input["jump"] = true
    
  if Input.is_action_just_pressed("fire"):
    input["fire"] = true
    input["global_camera_rotation"] = camera.global_rotation
  
  if mouse_movements.size() > 0:
    input["mouse_movements"] = mouse_movements.duplicate()
    mouse_movements.clear()
  current_input = input.duplicate()
  return input
  

func _predict_remote_input(previous_input, ticks_since_real_input):
  var input = previous_input.duplicate()
  input.erase("fire")
  
  return input


func _network_process(input):
  allow_mouse_input = true
  
  velocity = Vector3(0, velocity.y, 0)
  
  if not is_on_floor():
    velocity.y -= 1
    
  if input.size() <= 0:
    move_and_slide()
    return

  if input.get("mouse_movements"):
    for event in input["mouse_movements"]:
      rotate_y(deg_to_rad(-event.relative_x * 0.08))
      if !is_multiplayer_authority():
        rotation_helper.rotate_y(deg_to_rad(-event.relative_x * 0.08))
        camera.rotate_x(deg_to_rad(-event.relative_y * 0.08))
        camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
    
    
  if input.get("jump") and is_on_floor():
    velocity.y = JUMP_VELOCITY
  
  if input.get("input_vector"):
    var direction = (Vector3(input.input_vector.x, 0, input.input_vector.y).rotated(Vector3.UP, rotation.y)).normalized()
    if direction:
      velocity.x = direction.x * SPEED
      velocity.z = direction.z * SPEED
  
  move_and_slide()
  
  if input.get("fire") && input.get("global_camera_rotation") && fire_ready:
    fire(input["global_camera_rotation"])


func _save_state():
  return {
    "position": position,
    "velocity": velocity,
    "rotation": rotation,
    "_rotation_helper_rotation": rotation_helper.rotation,
    "_camera_rotation": camera.global_rotation
  }
  
  
func _load_state(state):
  position = state["position"]
  velocity = state["velocity"]
  rotation = state["rotation"]
  rotation_helper.rotation = state["_rotation_helper_rotation"]
  camera.global_rotation = state["_camera_rotation"]
  
  
func _input(event):
  if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED && is_multiplayer_authority() && allow_mouse_input:
    if event is InputEventMouseMotion:
      mouse_movements.append({"relative_x": event.relative.x, "relative_y": event.relative.y})
      rotation_helper.rotate_y(deg_to_rad(-event.relative.x * 0.08))
      camera.rotate_x(deg_to_rad(-event.relative.y * 0.08))
      camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func fire(camera_rotation):
  var old_camera_rotation = camera.global_rotation
  camera.global_rotation = camera_rotation
  
  fire_ready = false
  _fire_timer.start()
  
  var projectile_velocity = (_aim_point.global_position - _projectile_spawn_point.global_position).normalized()
  SyncManager.spawn("fireball", _projectiles_node, fireball_scene, { 
    position = _projectile_spawn_point.global_position, 
    velocity = projectile_velocity,
    owner = get_path()
    })
    
  camera.global_rotation = old_camera_rotation


func _on_fire_timer_timeout():
  fire_ready = true
  

func snap(value):
  match typeof(value):
    TYPE_VECTOR3:
      return snapped(value, Vector3(0.0001, 0.0001, 0.0001))
    TYPE_FLOAT:
      return snapped(value, 0.0001)
  

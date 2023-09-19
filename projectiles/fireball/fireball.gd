extends CharacterBody3D

var explosion_scene = preload("res://effects/Explosion.tscn")

@onready var _effects_node = get_node("/root/Main/Effects")

@onready var _collision_shape = $CollisionShape
@onready var _particles = $Particles
@onready var _abandonment_timer = $AbandonmentTimer

@onready var _audio_player = $AudioStreamPlayer3D

var speed = 30

var should_explode = false
var already_exploded = false

var projectile_owner

func _network_spawn(data: Dictionary):
  position = data["position"]
  velocity = data["velocity"] * speed
  add_collision_exception_with(get_node(data["owner"]))
  _abandonment_timer.start()
  
  
func _save_state():
  return {
    "position": global_position,
    "velocity": velocity
  }
  
func _load_state(data):
  global_position = data["position"]
  velocity = data["velocity"]
  
  
func _physics_process(_input):
  _move_and_explode()


func _move_and_explode():
  var exploded_this_tick = move_and_slide()
  if exploded_this_tick:
    should_explode = true
  if should_explode && !already_exploded:
    already_exploded = true
    _explode()


func _explode():
  SyncManager.spawn("explosion", _effects_node, explosion_scene, {position = global_position} )
  SyncManager.despawn(self)


func _on_abandonment_timer_timeout():
  SyncManager.despawn(self)


func receive_snapshot(rocket_snapshot):
  if rocket_snapshot.should_explode && !already_exploded:
    _explode()
  global_position = global_position.lerp(rocket_snapshot.position, 0.1)

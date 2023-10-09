extends CharacterBody3D

var explosion_scene = preload("res://effects/Explosion.tscn")

@onready var _effects_node = get_node("/root/Main/Effects")

@onready var _collision_shape = $CollisionShape
@onready var _particles = $Particles
@onready var _abandonment_timer = $AbandonmentTimer

@onready var _audio_player = $AudioStreamPlayer3D

var speed = 30

var exploded = false

var projectile_owner


func _network_spawn(data: Dictionary):
  position = data["position"]
  velocity = data["velocity"] * speed
  add_collision_exception_with(get_node(data["owner"]))
  _abandonment_timer.start()
  
  
func _save_state():
  return {
    "position": position,
    "velocity": velocity,
    "exploded": exploded
  }
  
func _load_state(data):
  position = data["position"]
  velocity = data["velocity"]
  exploded = data["exploded"]

  
func _physics_process(_delta):
  _network_process({})
  
  
func _network_process(_input):
  if !exploded:
    exploded = move_and_slide()
  
    if exploded:
      _explode()


func _explode():
  var explosion = explosion_scene.instantiate()
  _effects_node.add_child(explosion)
  explosion._network_spawn({
    position = global_position
  })
  queue_free()


func _on_abandonment_timer_timeout():
  queue_free()
  

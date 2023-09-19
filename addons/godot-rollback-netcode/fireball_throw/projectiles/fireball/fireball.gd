extends CharacterBody3D

var projectile_owner = null

var explosion_scene = preload("res://src/abilities/fireball_throw/effects/Explosion.tscn")

@onready var _game = get_node("/root/Game")
@onready var _projectiles = get_node("/root/Game/Actors/Projectiles")

@onready var _networker = get_node("/root/Game/Networker")

@onready var _collision_shape = $CollisionShape
@onready var _particles = $Particles
@onready var _timer = $Timer

@onready var _effects_node = get_node("/root/Game/Actors/Effects")

@onready var _audio_player = $AudioStreamPlayer3D

var creation_tick = -1
var creation_position = Vector3(0,0,0)
var creation_direction = Vector3(0,0,0)
var creation_rotation = Vector3(0,0,0)

var speed = 30

var catchup_ticks = 0

var should_explode = false
var already_exploded = false

var projectile_name = "fireball"
var fake = false


func _enter_tree():
  if creation_position && creation_rotation:
    global_position = creation_position
    global_rotation = creation_rotation


func _physics_process(_delta):
  if multiplayer.get_unique_id() == 1:
    _move_and_explode()


func _move_and_explode():
  var exploded_this_tick = move_and_slide()
  if exploded_this_tick:
    should_explode = true
  if should_explode && !already_exploded:
    already_exploded = true
    _explode()


func _explode():
  var explosion = explosion_scene.instantiate()
  explosion.projectile_owner = str(projectile_owner)
  explosion.name = str(name).replace("-rocket", "-explosion")
  explosion.global_position = global_position
  _effects_node.add_child(explosion, true)
  queue_free()


func _on_timer_timeout():
  queue_free()


func _on_abandonment_timer_timeout():
  queue_free()


func receive_snapshot(rocket_snapshot):
  if rocket_snapshot.should_explode && !already_exploded:
    _explode()
  global_position = global_position.lerp(rocket_snapshot.position, 0.1)

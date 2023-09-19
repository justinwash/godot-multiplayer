extends Area3D

var projectile_owner = null
var damage = 40
var impact = 2.0

@onready var _particles = $Particles

@onready var _audio_player = $AudioStreamPlayer3D

@onready var knockback_area: Area3D = $KnockbackArea


func _network_spawn(data: Dictionary):
  position = data["position"]
  $Timer.start()
  

func _ready():
  _particles.emitting = true


func _on_timer_timeout():
  SyncManager.despawn(self)

func _on_body_entered(body):
  pass
extends Area3D

var projectile_owner = null
var damage = 40
var impact = 2.0

@onready var _particles = $Particles

@onready var _audio_player = $AudioStreamPlayer3D

@onready var knockback_area: Area3D = $KnockbackArea

func _ready():
  _particles.emitting = true
  _audio_player.play()

func _on_timer_timeout():
  queue_free()

func _on_body_entered(body):
  set_deferred("monitoring", false)
  if body.has_method("on_hit"):
    body.on_hit(projectile_owner, global_position, damage, impact, name)
  elif body.has_method("explode") && !body.already_exploded:
    body.should_explode = true
    body.explode()

func _on_knockback_area_body_entered(body):
  var to_knock = knockback_area.get_overlapping_bodies()
  for actor in to_knock:
    if actor.has_method("apply_impulse"):
      var impulse_direction = (actor.global_position - self.global_position).normalized()
      var impulse_strength = abs(4 - actor.global_position.distance_to(self.global_position))
      actor.apply_central_impulse(impulse_direction * impulse_strength * 5)

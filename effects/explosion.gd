extends Area3D

var projectile_owner = null
var damage = 40
var impact = 2.0
var did_explode = false

@onready var _particles = $Particles

@onready var _audio_player = $AudioStreamPlayer3D


func _network_spawn(data: Dictionary):
  position = data["position"]
  $Timer.start()
  _particles.emitting = true


func _network_process(_input):
  if monitoring:
    for body in self.get_overlapping_bodies():
      if str(body.name).begins_with("Player"):
        monitoring = false
        print("hit player!")
        body.health -= 25
  
  
func _save_state():
  return {
    "monitoring": monitoring
  }
  
func load_state(state):
  monitoring = state["monitoring"]


func _on_timer_timeout():
  pass
  #SyncManager.despawn(self)

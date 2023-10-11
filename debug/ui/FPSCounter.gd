extends Control

func _physics_process(delta):
    $Label.text = "FPS: " + str(Engine.get_frames_per_second())

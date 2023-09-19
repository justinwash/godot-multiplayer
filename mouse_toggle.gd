extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
  pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  if Input.is_action_just_pressed("ui_cancel"):
    if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
      Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    else:
      Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

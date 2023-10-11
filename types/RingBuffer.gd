extends Node

class_name RingBuffer

var tick := -1
var rollback_tick := -1
var buffer : Array = []


func _init(size):
  buffer.resize(size)
  
  
func current() -> Variant:
  return buffer[tick % buffer.size()]


func next() -> Variant:
  tick += 1
  return buffer[tick % buffer.size()]
  

func step() -> void:
  tick += 1
  

func append(value) -> Variant:
  step()
  buffer[tick % buffer.size()] = value
  return buffer[tick % buffer.size()]
  
  
func put_t(index, value) -> void:
  var translated_index = index % buffer.size()
  buffer[translated_index] = value
  

func get_t(index) -> Variant:
  var translated_index = index % buffer.size()
  return buffer[translated_index]


func get_current_tick() -> int:
  return tick


func set_current_tick(index) -> void:
  tick = index


func get_rollback_tick() -> int:
  return rollback_tick
  
  
func set_rollback_tick(index) -> void:
  rollback_tick = index


func reset_rollback_tick() -> void:
  rollback_tick = tick

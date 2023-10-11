extends Node

class_name RingBuffer

var i := -1
var buffer : Array = []


func _init(size):
  buffer.resize(size)
  
  
func current() -> Variant:
  return buffer[i % buffer.size()]


func next() -> Variant:
  i += 1
  return buffer[i % buffer.size()]
  

func step() -> void:
  i += 1
  

func append(value) -> Variant:
  step()
  buffer[i % buffer.size()] = value
  return buffer[i % buffer.size()]
  
  
func put_t(index, value) -> void:
  var translated_index = index % buffer.size()
  buffer[translated_index] = value
  

func get_t(index) -> Variant:
  var translated_index = index % buffer.size()
  return buffer[translated_index]



extends Node

class_name RingBuffer

var i := 0
var buffer : PackedByteArray = []

func _init(size):
  buffer.resize(size)
  print(buffer.size())


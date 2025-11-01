extends Node2D

var layout: PackedByteArray = [];

func _process(_delta: float):
	random_walk();

func random_walk():
	for i in range(16):
		layout.push_back(0);
		
	var start_pos: Vector2i = Vector2i(8, 8);
	
	# Do a 
	var cur_pos: Vector2i = start_pos;
	
	
	

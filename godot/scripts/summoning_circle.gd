extends Node2D

@onready var pickup = $Pickup

var wave_time = 0;

func _process(delta: float):
	wave_time += 2 * delta;
	wave_time = fmod(wave_time, 2 * PI);
	
	pickup.position = Vector2.UP * (8 + 4 * sin(wave_time));

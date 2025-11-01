extends Area2D

var heading: Vector2 = Vector2.LEFT;
var damage: float = 1;
var speed: int = 16;

@onready var player = $"../Player";

func _physics_process(delta: float) -> void:
	self.position += delta * self.heading * self.speed;

func _on_body_entered(body: Node2D) -> void:
	if body == player:
		player.damage(self.damage);
	
	self.queue_free();

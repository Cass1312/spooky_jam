extends CharacterBody2D

@export var MOVE_SPEED: float = 32; # Tiles per second

var heading:Vector2 = Vector2.ZERO
var target_rot: float = deg_to_rad(-5);

var dodge_buffered = false;
var dodge_timer: float = 0;
const DODGE_LENGTH: float = 0.2;
const DODGE_COOLDOWN: float = 2;
var DODGE_SPEED = MOVE_SPEED * 4;

var health: float = 10;

@onready var sprite = $Sprite;
@onready var weapon = $Weapon;
@onready var walk_anim = create_tween().bind_node(self).set_trans(Tween.TRANS_SINE);
var is_walking = false;

func _process(_delta: float):
	##ANIMATION##
	var mouse_dir = get_local_mouse_position().normalized()
	self.weapon.rotation = (-mouse_dir).angle();
	self.weapon.position = mouse_dir * 20;
	
	if self.velocity.length_squared() > 0:
		if (self.target_rot < 0 && self.sprite.rotation <= self.target_rot) \
		|| (self.target_rot > 0 && self.sprite.rotation >= self.target_rot):
			self.target_rot *= -1;
			self.is_walking = false;
		if !self.is_walking:
			# Can play step sound here if desired
			animate_walk(self.target_rot * 1.1)
	elif self.is_walking:
		animate_walk(0)

func _physics_process(delta: float):
	self.velocity = Vector2(
		Input.get_axis(self.name + " - LEFT", self.name + " - RIGHT"),
		-Input.get_axis(self.name + " - DOWN", self.name + " - UP")
	).normalized();
	
	if dodge_buffered || Input.is_action_just_pressed("Player - DODGE"):
		if dodge_timer <= 0:
			dodge_buffered = 0;
			dodge_timer = DODGE_COOLDOWN;
		elif dodge_timer < 0.2:
			dodge_buffered = true;

	self.set_collision_layer_value(3, dodge_timer < (DODGE_COOLDOWN - (DODGE_LENGTH) * 1.2));
	
	if dodge_timer > (DODGE_COOLDOWN - DODGE_LENGTH):
		self.velocity = self.heading * DODGE_SPEED;
	elif self.velocity.length_squared() > 0:
		self.heading = self.velocity;
		self.velocity *= MOVE_SPEED;
	
	dodge_timer -= delta;
	if dodge_timer < 0: dodge_timer = 0;
	
	self.move_and_slide();	

func animate_walk(angle:float):
	self.is_walking = absf(angle) > 0;
	self.walk_anim.kill();
	self.walk_anim = create_tween().bind_node(self).set_trans(Tween.TRANS_SINE);
	self.walk_anim.tween_property(self.sprite, "rotation", angle, 0.25 if self.is_walking else 0.125);
	self.walk_anim.play();

func damage(damage: float):
	self.health -= damage;
	print(health);

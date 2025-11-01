extends CharacterBody2D

@export var MOVE_SPEED: int = 32;
@export var FLEE_SPEED: int = 28;

@export var bullet: PackedScene
@export var shoot_speed: float = 3;
@export var bullet_count: int = 1;
@export var bullet_spread: int = 15;
@export var bullet_speed: int = 64;
@export var bullet_randomness: int = 1;
@export var bullet_damage: float = 1;
@export var bullet_recoil: float = 0;
@export var shot_leading_strength: float = 1;

var shoot_timer = shoot_speed * randf();

var desired_velocity: Vector2 = Vector2.ZERO;
var recoil_force: Vector2 = Vector2.ZERO;

@onready var nav_agent: NavigationAgent2D = $NavAgent;
@onready var player = $"../Player";

#func _process(delta: float):

func _ready() -> void:
	var new_agent_rid: RID = self.nav_agent.get_rid();
	var default_2d_map_rid: RID = get_world_2d().get_navigation_map();

	NavigationServer2D.agent_set_map(new_agent_rid, default_2d_map_rid);
	NavigationServer2D.agent_set_avoidance_callback(new_agent_rid, self.on_safe_velocity_computed);

func on_safe_velocity_computed(safe_velocity: Vector2):
	self.velocity = (recoil_force + safe_velocity)
	self.move_and_slide();

func _physics_process(delta: float):
	self.nav_agent.target_desired_distance = 96;
	
	var speed = MOVE_SPEED;
	
	if self.position.distance_squared_to(player.position) > 96*96:
		self.nav_agent.target_desired_distance = 112;
		self.nav_agent.set_target_position(player.position);
	else:
		speed = FLEE_SPEED;
		self.nav_agent.target_desired_distance = 8;
		self.nav_agent.set_target_position(self.position + self.position - player.position);
	
	if !self.nav_agent.is_navigation_finished():
		var next_pos = self.nav_agent.get_next_path_position();
		self.desired_velocity = speed * self.position.direction_to(next_pos);
		NavigationServer2D.agent_set_velocity(self.nav_agent.get_rid(), self.desired_velocity);
	
	self.recoil_force *= 0.8;
	
	shoot_timer -= delta;
	if shoot_timer <= 0:
		shoot_timer = shoot_speed;
		var distance_to_player = self.position.distance_to(player.position);
		var time_to_player = distance_to_player / bullet_speed;
		var led_shot_position = player.position + (shot_leading_strength * time_to_player * player.velocity);
		var led_shot_heading = (led_shot_position - self.position).normalized();
		
		self.recoil_force += (-led_shot_heading * 64 * bullet_recoil);
		
		for i in range(bullet_count):
			var spawned_bullet = bullet.instantiate();
			owner.add_child(spawned_bullet);
			
			spawned_bullet.speed = bullet_speed;
			spawned_bullet.damage = bullet_damage;
			var bullet_heading = led_shot_heading.rotated(((bullet_count / 2) - i) * deg_to_rad(bullet_spread));
			bullet_heading = bullet_heading.rotated(randf_range(-1, 1) * deg_to_rad(bullet_randomness));
			spawned_bullet.position = self.position + (bullet_heading * 8);
			spawned_bullet.heading = bullet_heading;
		

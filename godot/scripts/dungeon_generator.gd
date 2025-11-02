extends Node2D

const UP_DOOR = 0b0001;
const DOWN_DOOR = 0b0010;
const LEFT_DOOR = 0b0100;
const RIGHT_DOOR = 0b1000;

enum RoomType {
	Normal = 0b0000,
	Spawn = 0b0001,
	Reward = 0b1101,
	Miniboss = 0b1110,
	Boss = 0b1111,
}

var cur_floor_num: int = 0;
var cur_floor_rooms: Array = [];
var loaded_rooms: Array = [];
var cur_coords: Vector2i = Vector2i.ZERO;

var load_timer: float = 0;

@export var room_prefab: PackedScene;
@export var enemy_prefab_1: PackedScene;
@export var enemy_prefab_2: PackedScene;
@export var enemy_prefab_3: PackedScene;

@onready var player = $/root/Scene/Player;

var is_loaded = false;

func _init() -> void:
	for y in range(16):
		loaded_rooms.push_back([]);
		for x in range(16):
			loaded_rooms[y].push_back(null);
			
func _physics_process(delta: float) -> void:
	if !is_loaded:
		load_next_floor();
		is_loaded = true;
	
	# This is jank AF, but whatever
	load_timer -= delta;
	if load_timer <= 0:
		load_timer = 0;
	else:
		return;
	
	var cur_room = loaded_rooms[cur_coords.y][cur_coords.x];
	if cur_room.find_child("Up").overlaps_body(player):
		load_timer = 1;
		var new_coords = cur_coords + Vector2i.UP;
		player.position = Vector2(0, 72 * 3.25);
		load_room(new_coords);
		unload_room(cur_coords);
		cur_coords = new_coords;
	elif cur_room.find_child("Down").overlaps_body(player):
		load_timer = 1;
		var new_coords = cur_coords + Vector2i.DOWN;
		player.position = Vector2(0, -72 * 3.25);
		load_room(new_coords);
		unload_room(cur_coords);
		cur_coords = new_coords;
	elif cur_room.find_child("Left").overlaps_body(player):
		load_timer = 1;
		var new_coords = cur_coords + Vector2i.LEFT;
		player.position = Vector2(120 * 3.25, 0);
		load_room(new_coords);
		unload_room(cur_coords);
		cur_coords = new_coords;
	elif cur_room.find_child("Right").overlaps_body(player):
		load_timer = 1;
		var new_coords = cur_coords + Vector2i.RIGHT;
		player.position = Vector2(-120 * 3.25, 0);
		load_room(new_coords);
		unload_room(cur_coords);
		cur_coords = new_coords;
	

func load_room(coords: Vector2i):
	var x = coords.x;
	var y = coords.y;
	
	if loaded_rooms[y][x] != null:
		loaded_rooms[y][x].process_mode = PROCESS_MODE_PAUSABLE;
		loaded_rooms[y][x].show();
	else:
		# First Load
		loaded_rooms[y][x] = room_prefab.instantiate();
		owner.add_child(loaded_rooms[y][x]);
		
		if cur_floor_rooms[y][x] >> 4 == RoomType.Normal:
			var num_enemies = randi_range(2, 6);
			for i in range(num_enemies):
				var enemy = rand_element([enemy_prefab_1, enemy_prefab_2, enemy_prefab_3]).instantiate();
				loaded_rooms[y][x].add_child(enemy);
				enemy.set_owner(loaded_rooms[y][x]);
				enemy.position = Vector2(randf_range(-96, 96), randf_range(-64, 64));
		
		if cur_floor_rooms[y][x] & UP_DOOR:
			print("UP");
			loaded_rooms[y][x].set_cell(Vector2i(-1, -5), -1);
			loaded_rooms[y][x].set_cell(Vector2i(0, -5), -1);
		if cur_floor_rooms[y][x] & DOWN_DOOR:
			print("DOWN");
			loaded_rooms[y][x].set_cell(Vector2i(-1, 4), -1);
			loaded_rooms[y][x].set_cell(Vector2i(0, 4), -1);
		if cur_floor_rooms[y][x] & LEFT_DOOR:
			print("LEFT");
			loaded_rooms[y][x].set_cell(Vector2i(-8, -1), -1);
			loaded_rooms[y][x].set_cell(Vector2i(-8, 0), -1);
		if cur_floor_rooms[y][x] & RIGHT_DOOR:
			print("RIGHT");
			loaded_rooms[y][x].set_cell(Vector2i(7, -1), -1);
			loaded_rooms[y][x].set_cell(Vector2i(7, 0), -1);
		
		loaded_rooms[y][x].process_mode = PROCESS_MODE_PAUSABLE;
		loaded_rooms[y][x].collision_enabled = true;
		loaded_rooms[y][x].show();

func unload_room(coords: Vector2i):
	loaded_rooms[coords.y][coords.x].process_mode = PROCESS_MODE_DISABLED;
	loaded_rooms[coords.y][coords.x].hide();
	loaded_rooms[coords.y][coords.x].collision_enabled = false;

func load_next_floor():
	cur_floor_num += 1;
	cur_floor_rooms = generate_floor(cur_floor_num);
	
	load_room(cur_coords)

func unload_floor():
	for y in range(loaded_rooms.size()):
		for x in range(loaded_rooms[y].size()):
			if loaded_rooms[y][x] != null:
				loaded_rooms[y][x].queue_free();
				loaded_rooms[y][x] = null;

func generate_floor(floor_num: int):
	var grid = random_walk((floor_num + 1) * 5);
	
	var one_door_rooms: Array = [];
	var two_door_rooms: Array = [];
	var three_door_rooms: Array = [];
	var four_door_rooms: Array = [];
	
	for y in range(grid.size()):
		var row = grid[y];
		
		for x in range(row.size()):
			var door_mask = row[x] & 0b1111;
			
			if door_mask > 0b0:
				var num_doors = 0;
				for i in range(4): if (door_mask >> i) & 0b1: num_doors += 1;
				
				if num_doors == 1: one_door_rooms.push_back(Vector2i(x, y));
				elif num_doors == 2: two_door_rooms.push_back(Vector2i(x, y));
				elif num_doors == 3: three_door_rooms.push_back(Vector2i(x, y));
				elif num_doors == 4: four_door_rooms.push_back(Vector2i(x, y));
	
	# Missing her rn :/ (rust's "let x = if {} else {}" syntax)
	var boss_room_pool = \
		one_door_rooms if one_door_rooms.size() > 0 else \
		two_door_rooms if two_door_rooms.size() > 0 else \
		three_door_rooms if three_door_rooms.size() > 0 else \
		four_door_rooms;
	
	var boss_room = rand_element(boss_room_pool);
	
	if floor_num % 2 == 0:
		grid[boss_room.y][boss_room.x] |= RoomType.Boss << 4
	else:
		grid[boss_room.y][boss_room.x] |= rand_element([RoomType.Miniboss, RoomType.Reward]) << 4

	var all_rooms = one_door_rooms + two_door_rooms + three_door_rooms + four_door_rooms;
	# TODO: Should pick the spawn room based on actually navigable distance, but no time to implement that
	
	all_rooms.remove_at(all_rooms.find(boss_room));
	cur_coords = rand_element(all_rooms); # Literally just a random room now
	grid[cur_coords.y][cur_coords.x] |= RoomType.Spawn << 4;
	
	return grid;

func random_walk(desired_rooms: int) -> Array:
	var grid: Array = [];
	
	# TODO: I want to make the arrays dynamically sized, but *definitely* don't have time for that now lol
	for y in range(16):
		var row: PackedByteArray = [];
		for x in range(16):
			row.push_back(0x00);
		grid.push_back(row);
	
	var start_pos: Vector2i = Vector2i(8, 8);
	
	var next_positions: Array = [start_pos]; 
	var last_positions: Array = [start_pos]; 
	
	var num_rooms: int = 0;
	
	while num_rooms < desired_rooms:
		if next_positions.size() == 0:
			next_positions = last_positions;
		
		last_positions = next_positions.duplicate();
		next_positions = [];
		
		for pos in last_positions:
			var desired_doors = randi_range(0b0001, 0b1111);
			
			if desired_doors & UP_DOOR && pos.y > 0:
				grid[pos.y][pos.x] |= UP_DOOR;
				
				var next_pos = pos + Vector2i.UP;
				
				if grid[next_pos.y][next_pos.x] == 0x00:
					num_rooms += 1;
					next_positions.push_back(next_pos);
				
				grid[next_pos.y][next_pos.x] |= DOWN_DOOR;
			
			if desired_doors & LEFT_DOOR && pos.x > 0:
				grid[pos.y][pos.x] |= LEFT_DOOR;
				
				var next_pos = pos + Vector2i.LEFT;
				
				if grid[next_pos.y][next_pos.x] == 0x00:
					num_rooms += 1;
					next_positions.push_back(next_pos);
				
				grid[next_pos.y][next_pos.x] |= RIGHT_DOOR;
				
			if desired_doors & DOWN_DOOR && pos.y < 15:
				grid[pos.y][pos.x] |= DOWN_DOOR;
				
				var next_pos = pos + Vector2i.DOWN;
				
				if grid[next_pos.y][next_pos.x] == 0x00:
					num_rooms += 1;
					next_positions.push_back(next_pos);
				
				grid[next_pos.y][next_pos.x] |= UP_DOOR;
				
			if desired_doors & RIGHT_DOOR && pos.x < 15:
				grid[pos.y][pos.x] |= RIGHT_DOOR;
				
				var next_pos = pos + Vector2i.RIGHT;
				
				if grid[next_pos.y][next_pos.x] == 0x00:
					num_rooms += 1;
					next_positions.push_back(next_pos);
				
				grid[next_pos.y][next_pos.x] |= LEFT_DOOR;
				
	return grid;

func rand_element(arr: Array):
	return arr[randi_range(0, arr.size() - 1)];

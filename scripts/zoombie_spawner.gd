extends Node2D


const GROUND_COLLISION_MASK: int = 1


@export var zombie_scene: PackedScene

@export var spawn_interval_min: float = 1.0
@export var spawn_interval_max: float = 10.0
# Long waits may produce a double spawn.
@export var double_spawn_threshold: float = 5
@export var double_spawn_chance: float = 0.65

@export var max_zombies: int = 6

# Horizontal distance from the player where enemies may spawn.
@export var spawn_min_distance: float = 650.0
@export var spawn_max_distance: float = 900.0

# Maximum number of positions tested before skipping this spawn.
@export var max_spawn_attempts: int = 12

# Raycast configuration.
@export var ray_start_height: float = 500.0
@export var ray_depth: float = 1500.0

# Keeps the enemy body above the floor when instantiated.
@export var spawn_height_above_ground: float = 70.0

@export var debug_spawn: bool = false

@export var spawning_enabled: bool = true

var active_zombies: int = 0
var player: Node2D
var current_spawn_interval: float = 0.0


@onready var spawn_timer: Timer = $SpawnTimer


func _ready() -> void:
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group(
		"player"
	) as Node2D

	spawn_timer.one_shot = true

	spawn_timer.timeout.connect(
		_on_spawn_timer_timeout
	)

	if spawning_enabled:
		schedule_next_spawn()

func schedule_next_spawn() -> void:
	current_spawn_interval = randf_range(
		spawn_interval_min,
		spawn_interval_max
	)

	if debug_spawn:
		print(
			"[SPAWNER] Next spawn attempt in ",
			snappedf(current_spawn_interval, 0.1),
			" seconds"
		)

	spawn_timer.start(current_spawn_interval)


func _on_spawn_timer_timeout() -> void:
	if (
		zombie_scene == null
		or not is_instance_valid(player)
	):
		schedule_next_spawn()
		return

	var available_slots: int = (
		max_zombies - active_zombies
	)

	if available_slots <= 0:
		schedule_next_spawn()
		return

	var spawn_amount: int = 1

	# Long waits have a chance to create a double spawn.
	if (
		current_spawn_interval >= double_spawn_threshold
		and randf() <= double_spawn_chance
	):
		spawn_amount = 2

	spawn_amount = mini(
		spawn_amount,
		available_slots
	)

	if debug_spawn:
		print(
			"[SPAWNER] Spawning ",
			spawn_amount,
			" zombie(s) after ",
			snappedf(current_spawn_interval, 0.1),
			" seconds"
		)

	for i: int in range(spawn_amount):
		spawn_zombie()

	schedule_next_spawn()


func spawn_zombie() -> void:
	var spawn_position: Vector2 = find_valid_spawn_position()

	if spawn_position == Vector2.INF:
		if debug_spawn:
			print(
				"[SPAWNER] Spawn cancelled: no valid ground found."
			)

		return

	var zombie: Node2D = (
		zombie_scene.instantiate() as Node2D
	)

	if zombie == null:
		return

	get_parent().add_child(
		zombie
	)

	zombie.global_position = spawn_position

	active_zombies += 1

	zombie.tree_exited.connect(
		_on_zombie_removed
	)

	var spawn_side: String

	if spawn_position.x < player.global_position.x:
		spawn_side = "LEFT"
	else:
		spawn_side = "RIGHT"

	print(
		"[SPAWNER] New zombie | Side: ",
		spawn_side,
		" | Position: ",
		spawn_position,
		" | Player: ",
		player.global_position
	)

	print(
		"[SPAWNER] Active zombies: ",
		active_zombies,
		"/",
		max_zombies
	)
	


func find_valid_spawn_position() -> Vector2:
	var space_state: PhysicsDirectSpaceState2D = (
		get_world_2d().direct_space_state
	)

	for attempt: int in range(max_spawn_attempts):
		var side: float = 1.0

		#if randi_range(0, 1) == 0:
			#side = -1.0
		#else:
			#side = 1.0

		var distance: float = randf_range(
			spawn_min_distance,
			spawn_max_distance
		)

		var candidate_x: float = (
			player.global_position.x
			+ distance * side
		)

		var ray_start := Vector2(
			candidate_x,
			player.global_position.y - ray_start_height
		)

		var ray_end := Vector2(
			candidate_x,
			player.global_position.y + ray_depth
		)

		var query := PhysicsRayQueryParameters2D.create(
			ray_start,
			ray_end,
			GROUND_COLLISION_MASK
		)

		var result: Dictionary = (
			space_state.intersect_ray(query)
		)

		if result.is_empty():
			if debug_spawn:
				print(
					"Spawn attempt ",
					attempt + 1,
					": no ground at X=",
					candidate_x
				)

			continue

		var ground_position: Vector2 = result["position"]

		var valid_position := Vector2(
			ground_position.x,
			ground_position.y
			- spawn_height_above_ground
		)

		if debug_spawn:
			print(
				"Spawn attempt ",
				attempt + 1,
				": ground found at ",
				ground_position
			)
			

		return valid_position

	return Vector2.INF


func _on_zombie_removed() -> void:
	active_zombies = maxi(
		active_zombies - 1,
		0
	)

	print(
		"[SPAWNER] Zombie removed | Active zombies: ",
		active_zombies,
		"/",
		max_zombies
	)
	
func start_spawning() -> void:
	if spawning_enabled:
		return

	spawning_enabled = true

	print(
		"[SPAWNER] Spawning started"
	)

	schedule_next_spawn()


func stop_spawning() -> void:
	spawning_enabled = false
	spawn_timer.stop()

	print(
		"[SPAWNER] Spawning stopped"
	)

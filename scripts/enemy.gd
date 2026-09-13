extends CharacterBody2D

@export var max_health: int = 100

@export var move_speed: float = 100.0
@export var stop_distance: float = 90.0

@export var attack_range: float = 140.0
@export var attack_damage: int = 10
@export var attack_interval: float = 0.8

var health: int = 100
var player: Node2D

var attack_cooldown: float = 0.0

@onready var health_bar: ProgressBar = $HealthBar
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health

	health_bar.max_value = max_health
	health_bar.value = health

	# Wait until the complete scene tree is ready.
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player") as Node2D

	print("Player found: ", player)


func _physics_process(delta: float) -> void:
	# Update attack cooldown.
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	# Apply gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_instance_valid(player):
		var distance_x: float = (
			player.global_position.x
			- global_position.x
		)

		var distance: float = absf(distance_x)
		
		# Chase the player.
		if distance > stop_distance:
			if distance_x > 0.0:
				velocity.x = move_speed
				sprite.flip_h = false
			else:
				velocity.x = -move_speed
				sprite.flip_h = true
		else:
			velocity.x = 0.0

		# Attack when close enough.
		if (
			distance <= attack_range
			and attack_cooldown <= 0.0
		):
			attack_player()
	else:
		velocity.x = 0.0

	move_and_slide()


func attack_player() -> void:
	if not is_instance_valid(player):
		return

	if player.has_method("take_damage"):
		player.take_damage(attack_damage)

		attack_cooldown = attack_interval


func take_damage(amount: int) -> void:
	health = max(
		health - amount,
		0
	)

	health_bar.value = health

	print("Enemy HP: ", health)

	if health <= 0:
		die()


func die() -> void:
	print("Enemy defeated")
	queue_free()

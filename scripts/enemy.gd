extends CharacterBody2D

@export var max_health: int = 100
@export var move_speed: float = 40.0

@export var attack_range_x: float = 90.0
@export var attack_range_y: float = 80.0
@export var attack_damage: int = 5
@export var attack_interval: float = 1.8
@export var corpse_lifetime: float = 5.0

const BLOOD_HIT_SCENE := preload(
	"res://scenes/effects/blood_hit.tscn"
)

var health: int = 100
var player: Node2D

var attack_cooldown: float = 0.0
var is_attacking: bool = false
var is_dead: bool = false

var attack_hit_frame_2: bool = false
var attack_hit_frame_3: bool = false


@onready var health_bar: ProgressBar = $HealthBar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	health = max_health

	health_bar.max_value = max_health
	health_bar.value = health

	animated_sprite.animation_finished.connect(
		_on_animation_finished
	)

	animated_sprite.frame_changed.connect(
		_on_frame_changed
	)

	animated_sprite.play("idle")

	await get_tree().process_frame

	player = get_tree().get_first_node_in_group(
		"player"
	) as Node2D


func _physics_process(delta: float) -> void:
	# Dead enemies still need physics so the corpse stays on the ground.
	if is_dead:
		apply_gravity(delta)

		velocity.x = 0.0

		move_and_slide()

		return

	update_attack_cooldown(delta)
	apply_gravity(delta)

	if is_instance_valid(player):
		update_behavior()
	else:
		velocity.x = 0.0

		if not is_attacking:
			animated_sprite.play("idle")

	move_and_slide()


func update_attack_cooldown(delta: float) -> void:
	if attack_cooldown <= 0.0:
		return

	attack_cooldown = maxf(
		attack_cooldown - delta,
		0.0
	)


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func update_behavior() -> void:
	if is_attacking:
		velocity.x = 0.0
		return

	var distance_x: float = (
		player.global_position.x - global_position.x
	)

	var distance_y: float = (
		player.global_position.y - global_position.y
	)

	var abs_distance_x: float = absf(distance_x)
	var abs_distance_y: float = absf(distance_y)

	update_facing_direction(distance_x)

	var can_attack: bool = (
		abs_distance_x <= attack_range_x
		and abs_distance_y <= attack_range_y
	)

	if can_attack:
		handle_attack_state()
	else:
		chase_player(distance_x)


func update_facing_direction(distance_x: float) -> void:
	if distance_x > 0.0:
		animated_sprite.flip_h = false

	elif distance_x < 0.0:
		animated_sprite.flip_h = true


func chase_player(distance_x: float) -> void:
	if distance_x > 0.0:
		velocity.x = move_speed

	elif distance_x < 0.0:
		velocity.x = -move_speed

	else:
		velocity.x = 0.0

	animated_sprite.play("walk")


func handle_attack_state() -> void:
	velocity.x = 0.0

	if attack_cooldown <= 0.0:
		start_attack()
	else:
		animated_sprite.play("idle")


func start_attack() -> void:
	if is_attacking or is_dead:
		return

	is_attacking = true
	velocity.x = 0.0

	# Reset hit control for the new attack cycle.
	attack_hit_frame_2 = false
	attack_hit_frame_3 = false

	animated_sprite.play("attack")


func _on_frame_changed() -> void:
	if is_dead:
		return

	if not is_attacking:
		return

	if animated_sprite.animation != "attack":
		return

	# Visual frame 2 = Godot frame index 1.
	if (
		animated_sprite.frame == 1
		and not attack_hit_frame_2
	):
		attack_hit_frame_2 = true
		attack_player()

	# Visual frame 3 = Godot frame index 2.
	elif (
		animated_sprite.frame == 2
		and not attack_hit_frame_3
	):
		attack_hit_frame_3 = true
		attack_player()


func attack_player() -> void:
	if is_dead:
		return

	if not is_instance_valid(player):
		return

	var distance_x: float = absf(
		player.global_position.x - global_position.x
	)

	var distance_y: float = absf(
		player.global_position.y - global_position.y
	)

	if (
		distance_x > attack_range_x
		or distance_y > attack_range_y
	):
		print("Attack missed")
		return

	if player.has_method("take_damage"):
		print(
			"HIT | Enemy=",
			global_position,
			" Player=",
			player.global_position,
			" dx=",
			distance_x,
			" dy=",
			distance_y
		)

		var hit_position: Vector2 = player.global_position

		hit_position.y -= 30.0

		player.take_damage(
			attack_damage,
			hit_position
		)


func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		finish_death()
		return

	if animated_sprite.animation != "attack":
		return

	if is_dead:
		return

	is_attacking = false

	# Start cooldown after the full attack animation.
	attack_cooldown = attack_interval

	animated_sprite.play("idle")


func finish_death() -> void:
	# Keep the final death frame visible.
	animated_sprite.pause()

	# Keep CollisionShape2D enabled.
	# The corpse still needs to collide with the ground.

	await get_tree().create_timer(
		corpse_lifetime
	).timeout

	queue_free()


func take_damage(amount: int, hit_position: Vector2) -> void:
	if is_dead:
		return

	health = maxi(
		health - amount,
		0
	)

	health_bar.value = health

	spawn_blood_hit(
		hit_position
	)

	print("Enemy HP: ", health)

	if health <= 0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_attacking = false

	velocity.x = 0.0

	health_bar.hide()

	# Remove the corpse from the Enemy layer.
	set_collision_layer_value(
		3,
		false
	)

	# The corpse no longer collides with the Player layer.
	set_collision_mask_value(
		2,
		false
	)

	# The corpse must continue detecting the Ground layer.
	set_collision_mask_value(
		1,
		true
	)

	print("Enemy defeated")

	animated_sprite.play("death")


func spawn_blood_hit(
	hit_position: Vector2
) -> void:
	var blood_hit: AnimatedSprite2D = (
		BLOOD_HIT_SCENE.instantiate()
	)

	var level: Node = get_current_level()

	if level == null:
		blood_hit.queue_free()
		return

	level.add_child(
		blood_hit
	)

	blood_hit.global_position = hit_position

func get_current_level() -> Node:
	var level: Node = get_tree().get_first_node_in_group(
		"level"
	)

	if level == null:
		push_error(
			"Enemy: Current level not found."
		)

	return level

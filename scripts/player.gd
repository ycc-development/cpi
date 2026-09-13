extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)

const SPEED := 300.0
const JUMP_VELOCITY := -400.0

# Weapon fire rate. Independent from animation speed.
const FIRE_INTERVAL := 0.12

const PROJECTILE_SCENE := preload(
	"res://scenes/projectiles/projectile.tscn"
)

@export var max_health: int = 100

var health: int = 100

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var projectile_spawn: Marker2D = $ProjectileSpawn

var fire_cooldown := 0.0

# True while an attack animation cycle is playing.
var attack_visual_active := false

# A new press during the current animation queues another cycle.
var attack_cycle_queued := false


func _ready() -> void:
	health = max_health

	animated_sprite.animation_finished.connect(
		_on_animation_finished
	)
	

func _physics_process(delta: float) -> void:
	# Update weapon cooldown.
	fire_cooldown = max(
		fire_cooldown - delta,
		0.0
	)

	# Apply gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Read horizontal movement.
	var direction := Input.get_axis(
		"move_left",
		"move_right"
	)

	# Handle horizontal movement.
	if direction != 0:
		velocity.x = direction * SPEED
		animated_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(
			velocity.x,
			0,
			SPEED
		)

	# A new attack press starts or queues an animation cycle.
	if Input.is_action_just_pressed("attack"):
		if attack_visual_active:
			attack_cycle_queued = true
		else:
			start_attack_cycle(direction)

	# Weapon firing is completely independent from animation.
	if Input.is_action_pressed("attack") and fire_cooldown <= 0.0:
		shoot()
		fire_cooldown = FIRE_INTERVAL

	move_and_slide()

	update_animation(direction)


func start_attack_cycle(direction: float) -> void:
	attack_visual_active = true
	attack_cycle_queued = false

	var animation_name := get_attack_animation(direction)

	animated_sprite.play(animation_name)


func get_attack_animation(direction: float) -> String:
	if not is_on_floor():
		return "jump_attack"

	if direction != 0:
		return "walk_attack"

	return "attack"


func update_animation(direction: float) -> void:
	# Never interrupt an attack animation cycle.
	if attack_visual_active:
		return

	if not is_on_floor():
		animated_sprite.play("jump")
	elif direction != 0:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")


func shoot() -> void:
	var projectile = PROJECTILE_SCENE.instantiate()

	projectile.global_position = projectile_spawn.global_position

	if animated_sprite.flip_h:
		projectile.direction = -1.0
	else:
		projectile.direction = 1.0

	get_tree().current_scene.add_child(projectile)


func _on_animation_finished() -> void:
	if not attack_visual_active:
		return

	if animated_sprite.animation not in [
		"attack",
		"walk_attack",
		"jump_attack",
	]:
		return

	# Continue the animation if:
	# 1. The attack button is still held, or
	# 2. The player pressed attack again during this cycle.
	if Input.is_action_pressed("attack") or attack_cycle_queued:
		attack_cycle_queued = false

		var direction := Input.get_axis(
			"move_left",
			"move_right"
		)

		start_attack_cycle(direction)
	else:
		attack_visual_active = false

func take_damage(amount: int) -> void:
	health = max(
		health - amount,
		0
	)
	
	health_changed.emit(health, max_health)
	
	print("Player HP: ", health)

	if health <= 0:
		die()


func die() -> void:
	print("Player defeated")
	queue_free()

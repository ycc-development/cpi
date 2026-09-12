extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var projectile_spawn: Marker2D = $ProjectileSpawn

const PROJECTILE_SCENE := preload("res://scenes/projectiles/projectile.tscn")

func _physics_process(delta: float) -> void:
	# Apply gravity while the character is in the air.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump input.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Read horizontal movement input.
	var direction := Input.get_axis("move_left", "move_right")

	# Handle horizontal movement.
	if direction != 0:
		velocity.x = direction * SPEED

		# Make the character face the movement direction.
		animated_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if Input.is_action_just_pressed("attack"):
		shoot()

	move_and_slide()

	# Update the animation after physics movement.
	update_animation(direction)


func update_animation(direction: float) -> void:
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

extends Area2D


@export var zombie_spawner: Node2D


var activated: bool = false


func _ready() -> void:
	body_entered.connect(
		_on_body_entered
	)


func _on_body_entered(
	body: Node2D
) -> void:
	if activated:
		return

	if not body.is_in_group(
		"player"
	):
		return

	if zombie_spawner == null:
		push_error(
			"Section02Trigger: ZombieSpawner was not configured."
		)
		return

	activated = true

	print(
		"[LEVEL01] Section02 started"
	)

	if zombie_spawner.has_method(
		"start_spawning"
	):
		zombie_spawner.start_spawning()

	set_deferred(
		"monitoring",
		false
	)

extends Area2D

const SPEED := 600.0

var direction := 1.0


func _physics_process(delta: float) -> void:
	position.x += SPEED * direction * delta

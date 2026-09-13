extends Area2D

const SPEED := 600.0
const DAMAGE := 10
const LIFETIME := 3.0

var direction := 1.0
var lifetime := LIFETIME


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.x += direction * SPEED * delta

	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)

	queue_free()

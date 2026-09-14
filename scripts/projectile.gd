extends Area2D

@onready var screen_notifier: VisibleOnScreenNotifier2D = (
	$VisibleOnScreenNotifier2D
)

@onready var sprite: Sprite2D = $Sprite2D

const SPEED := 600.0
const DAMAGE := 10
const LIFETIME := 3.0

var direction := 1.0
var lifetime := LIFETIME



func _ready() -> void:
	sprite.flip_h = direction < 0.0
	screen_notifier.screen_exited.connect(
		_on_screen_exited
	)

	body_entered.connect(
		_on_body_entered
	)

func _on_screen_exited() -> void:
	queue_free()

func _physics_process(delta: float) -> void:
	position.x += direction * SPEED * delta

	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		var hit_position: Vector2 = global_position
		hit_position.x += direction * 35.0
		body.take_damage(DAMAGE, hit_position)

	queue_free()

extends Camera2D

@export var fixed_y: float = 420.0

func _process(_delta: float) -> void:
	global_position.y = fixed_y

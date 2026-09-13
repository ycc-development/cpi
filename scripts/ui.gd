extends CanvasLayer

@onready var player_health_bar: ProgressBar = $PlayerHealthBar


func _on_player_health_changed(
	current_health: int,
	max_health: int
) -> void:
	player_health_bar.max_value = max_health
	player_health_bar.value = current_health

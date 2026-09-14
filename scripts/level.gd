extends Node2D


@export var level_music: AudioStream


func _ready() -> void:
	if level_music == null:
		MusicManager.stop_music()
		return

	MusicManager.play_music(
		level_music
	)

extends AnimatedSprite2D

@onready var hit_audio: AudioStreamPlayer2D = $HitAudio

const HIT_SOUNDS: Array[AudioStream] = [
	preload(
		"res://assets/audio/sfx/impacts/bullet_flesh_impact_01.mp3"
	),
	preload(
		"res://assets/audio/sfx/impacts/bullet_flesh_impact_02.mp3"
	),
	preload(
		"res://assets/audio/sfx/impacts/bullet_flesh_impact_03.mp3"
	),
]

func _ready() -> void:
	animation_finished.connect(
		_on_animation_finished
	)

	var sound_index: int = randi_range(
		0,
		HIT_SOUNDS.size() - 1
	)

	hit_audio.stream = HIT_SOUNDS[sound_index]
	hit_audio.play()

	play("blood_hit")


func _on_animation_finished() -> void:
	queue_free()

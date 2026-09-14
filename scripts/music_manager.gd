extends Node


var music_player: AudioStreamPlayer
var loop_music: bool = true


func _ready() -> void:
	music_player = AudioStreamPlayer.new()

	add_child(
		music_player
	)

	music_player.bus = "Music"

	music_player.finished.connect(
		_on_music_finished
	)


func play_music(
	stream: AudioStream,
	loop: bool = true
) -> void:
	if stream == null:
		return

	if (
		music_player.stream == stream
		and music_player.playing
	):
		return

	loop_music = loop
	music_player.stream = stream
	music_player.play()


func stop_music() -> void:
	music_player.stop()


func _on_music_finished() -> void:
	if loop_music:
		music_player.play()

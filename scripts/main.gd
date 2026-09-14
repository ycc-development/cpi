extends Node


@export var levels: Array[PackedScene]

@onready var level_container: Node = $LevelContainer
@onready var player: CharacterBody2D = $Player
@onready var ui: CanvasLayer = $UI

var current_level: Node
var current_level_scene: PackedScene
var current_level_index: int = 0


func _ready() -> void:
	if levels.is_empty():
		push_error(
			"Main: No levels configured."
		)
		return

	load_level(
		levels[current_level_index]
	)


func load_level(
	level_scene: PackedScene
) -> void:
	if level_scene == null:
		push_error(
			"Main: Cannot load a null level."
		)
		return

	if is_instance_valid(current_level):
		level_container.remove_child(
			current_level
		)

		current_level.queue_free()
		current_level = null

	var level_instance: Node = (
		level_scene.instantiate()
	)

	level_container.add_child(
		level_instance
	)

	current_level = level_instance
	current_level_scene = level_scene

	move_player_to_spawn()


func restart_current_level() -> void:
	if current_level_scene == null:
		push_error(
			"Main: There is no current level to restart."
		)
		return

	get_tree().paused = false

	player.reset_player()

	load_level(
		current_level_scene
	)


func change_level(
	level_scene: PackedScene
) -> void:
	if level_scene == null:
		push_error(
			"Main: Cannot change to a null level."
		)
		return

	get_tree().paused = false

	load_level(
		level_scene
	)


func move_player_to_spawn() -> void:
	if current_level == null:
		return

	var player_spawn: Marker2D = (
		current_level.get_node_or_null(
			"PlayerSpawn"
		) as Marker2D
	)

	if player_spawn == null:
		push_error(
			"Main: PlayerSpawn was not found in the level."
		)
		return

	player.global_position = (
		player_spawn.global_position
	)
	
func next_level() -> void:
	var next_level_index: int = (
		current_level_index + 1
	)

	if next_level_index >= levels.size():
		print(
			"Main: All levels completed."
		)
		return

	current_level_index = next_level_index

	load_level(
		levels[current_level_index]
	)
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(
		"debug_next_level"
	):
		next_level()

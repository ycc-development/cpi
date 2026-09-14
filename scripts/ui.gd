extends CanvasLayer

@onready var player: Node = get_parent().get_node(
	"Player"
)

@onready var player_health_bar: ProgressBar = $PlayerHealthBar

@onready var game_over_panel: ColorRect = $GameOverPanel

@onready var restart_button: Button = (
	$GameOverPanel/ButtonsContainer/RestartButton
)

@onready var main_menu_button: Button = (
	$GameOverPanel/ButtonsContainer/MainMenuButton
)

@onready var game_over_background: TextureRect = (
	$GameOverPanel/BackgroundImage
)


var game_over_images: Array[Texture2D] = [
	preload(
		"res://assets/ui/game_over/game_over_01.jpeg"
	),
]

@export var game_over_delay: float = 2


func _ready() -> void:
	player.health_changed.connect(
		_on_player_health_changed
	)

	restart_button.pressed.connect(
		_on_restart_button_pressed
	)

	main_menu_button.pressed.connect(
		_on_main_menu_button_pressed
	)
	
	if not player.is_connected(
		"died",
		_on_player_died
	):
		player.connect(
			"died",
			_on_player_died
		)

func _on_main_menu_button_pressed() -> void:
	print("Main menu")

func _on_player_health_changed(
	current_health: int,
	max_health: int
) -> void:
	player_health_bar.max_value = max_health
	player_health_bar.value = current_health


func _on_player_died() -> void:
	var index: int = randi_range(
		0,
		game_over_images.size() - 1
	)

	game_over_background.texture = (
		game_over_images[index]
	)

	# Freeze the game before showing the Game Over screen.
	get_tree().paused = true

	await get_tree().create_timer(
		game_over_delay,
		true
	).timeout

	game_over_panel.show()


func _on_restart_button_pressed() -> void:
	game_over_panel.hide()

	var main: Node = get_parent()

	if main.has_method(
		"restart_current_level"
	):
		main.restart_current_level()

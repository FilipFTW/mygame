extends Control
@export var game_scene: PackedScene
@onready var menu_box: VBoxContainer = $CenterContainer/VBoxContainer
@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var fullscreen_button: Button = $SettingsPanel/VBoxContainer/FullscreenButton
@onready var back_button: Button = $SettingsPanel/VBoxContainer/BackButton
func _ready() -> void:
	settings_panel.hide()
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	back_button.pressed.connect(_on_back_pressed)
func _on_play_pressed() -> void:
	if game_scene != null:
		get_tree().change_scene_to_packed(game_scene)
	else:
		push_warning("chose scene")
func _on_settings_pressed() -> void:
	menu_box.hide()
	settings_panel.show()
func _on_fullscreen_pressed() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
func _on_back_pressed() -> void:
	settings_panel.hide()
	menu_box.show()
func _on_quit_pressed() -> void:
	get_tree().quit()

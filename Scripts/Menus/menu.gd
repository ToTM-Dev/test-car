extends CanvasLayer

var game_paused : bool = false
@onready var resume_button : Button = $Main/Panel/VBoxContainer/ResumeButton
@onready var option_button : Button = $Main/Panel/VBoxContainer/OptionMenuButton

func _ready() -> void:
	GameManager.connect("game_paused",_paused)

func _paused() -> void:
	if !get_tree().paused:
		Input.mouse_mode =Input.MOUSE_MODE_HIDDEN
		game_paused = false
	else :
		Input.mouse_mode =Input.MOUSE_MODE_VISIBLE
		if not game_paused:
			resume_button.grab_focus()
			game_paused = true
	
	visible = game_paused

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	_paused()


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	LoadScreen.next_scene_path = "res://Scenes/Menus/Main_Menu.tscn"
	LoadScreen.load_scene()


func _on_return_button_pressed() -> void:
	$Option.visible = false
	$Main.visible = true
	option_button.grab_focus()


func _on_option_menu_button_pressed() -> void:
	$Main.visible = false
	$Option.visible = true

extends Node

signal  game_paused()

@export var players_car : Array[int] = [0,0,0,0,0,0,0,0]
@export var players_controllers : Array
@export var max_connected_players : int  = 8

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_update_controllers()
	print(players_controllers)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		if get_tree().root.get_child(2).name == "Scene":
			get_tree().paused = !get_tree().paused
			game_paused.emit()
	
	if event.is_action_pressed("toogle_fullscreen"):
		if DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _update_controllers():
	players_controllers = Input.get_connected_joypads()
	for  i in range(max_connected_players - players_controllers.size()):
		players_controllers.append(-2)
	if players_controllers[0] == -2:
		players_controllers[0] = -1 # -1 is equal to keyboard

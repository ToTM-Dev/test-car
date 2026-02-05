extends Node

@onready var screen_size = DisplayServer.screen_get_size(0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1152,648))
	DisplayServer.window_set_position(Vector2i((screen_size[0]-1152)/2,(screen_size[1]-648)/2))
	
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	

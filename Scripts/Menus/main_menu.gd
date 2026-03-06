extends Control

var map_dir_path : String = "res://Scenes/Maps"
@onready var grid_container = $Panel2/GridContainer

var Buttons : Dictionary

func _ready() -> void:
	Input.mouse_mode =Input.MOUSE_MODE_VISIBLE

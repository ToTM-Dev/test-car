extends Node3D

@export_enum("Normal", "Only Up") var game_mode : int
@export_group("Only Up Mod")
@export var time_before_lava : float = 20

@onready var hud : HUD = $HUD

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		if child is CarSpawner:
			child._import_car()
	hud._add_cameras()
	Input.mouse_mode =Input.MOUSE_MODE_HIDDEN

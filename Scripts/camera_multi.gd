extends CanvasLayer
class_name HUD

@export var camera_preload : PackedScene = preload("res://Scenes/Prefabs/multiplayer_camera.tscn")
# var camera_preload = preload("res://Scenes/multiplayer_camera.tscn")
@onready var viewport_container : GridContainer = $MarginContainer/ViewportsGridContainer

func _show_cameras() -> void:
	var cars : float = 0
	for child in get_parent().get_children():
		if child is RaycastCar:
			cars += 1
			var camera = camera_preload.instantiate()
			camera.get_child(0).get_child(0).get_child(0).target = child
			camera.get_child(0).get_child(0).get_child(0)._update_settings()
			viewport_container.add_child(camera)
	
	if cars:
		if cars == 2:
			cars += 1
		var cuts : int = ceil(cars/2)
		viewport_container.columns = cuts
		

extends CanvasLayer

var camera_preload = preload("res://Scenes/multiplayer_camera.tscn")
@onready var viewport_container : GridContainer = $MarginContainer/ViewportsGridContainer

func _ready() -> void:
	var cars : float = 0
	for child in get_parent().get_children():
		if child is RaycastCar and child.visible:
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
		

extends Node3D

@onready var id = int(self.name.split("_")[1])
@onready var portal : CSGBox3D = $CSGBox3D
@export var last : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	print(id)
	portal.set_layer_mask_value(id + 2, true)
	print(portal.get_layer_mask_value(id + 2))


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is RaycastCar:
		if last:
			body._change_camera_check_visi(0)
		else:
			body._change_camera_check_visi(id +1)
		body._change_camera_check_visi(id, false)

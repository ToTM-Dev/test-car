extends Node3D

@onready var id = int(self.name.split("_")[1])
@onready var portal : CSGBox3D = $CSGBox3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	print(id)
	portal.set_layer_mask_value(id + 2, true)
	print(portal.get_layer_mask_value(id + 2))

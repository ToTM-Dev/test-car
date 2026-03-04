extends Node3D
class_name CarSpawner

@export var cars : Array[PackedScene]
@export var player_id : int  = 0
@export var car_type : int = 0

# Called when the node enters the scene tree for the first time.
func _import_car() -> void:
	if GameManager.players_controllers[player_id] > -2 :
		var car : RaycastCar = cars[GameManager.players_car[player_id]].instantiate()
		car.car_id = player_id
		car.inital_position = global_position
		car.initial_rotation = global_rotation
		get_parent().add_child(car)
	queue_free()

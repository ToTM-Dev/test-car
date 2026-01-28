extends MeshInstance3D
class_name Gun


@export var feedback : float = 100
@export var left_time : float = 0.0
@export var enabled_time : float = 15


@onready var parent : RaycastCar = get_parent()
@onready var bullet := preload("res://Scenes/bullet.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if not event.device == parent.car_id: return
	
	if event.is_action_pressed("shoot"):
		var forward_dir : Vector3 = - parent.global_basis.z.normalized()
		var speed       : float = forward_dir.dot(parent.linear_velocity)
		var new_bullet : Bullet = bullet.instantiate()
		parent.get_parent().add_child(new_bullet)
		new_bullet.global_position = global_position
		new_bullet.execption = parent
		new_bullet.apply_central_force(forward_dir * absf(speed + 20) * 300)
		parent.apply_force(-forward_dir * feedback, global_position - parent.global_position)


func _process(delta: float) -> void:
	left_time -= delta
	if left_time <= 0:
		parent.animaton_player.play("hide_gun")

func _reset():
	left_time = enabled_time
	

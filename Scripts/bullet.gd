extends RigidBody3D
class_name Bullet

@export var dispawn_time : float = 2
@onready var collision_zone : CollisionShape3D = $Area3D/CollisionShape3D
@export var scale_curve : Curve
@export  var max_scale : float = 40

var time     : float = 0
var execption : RigidBody3D



func _physics_process(delta: float) -> void:
	time += delta
	scale =  Vector3(max_scale, max_scale, max_scale) * scale_curve.sample_baked(time/dispawn_time)
	if time > dispawn_time:
		queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is RaycastCar and  body != execption:
		#body.apply_force(constant_force, global_position)
		pass

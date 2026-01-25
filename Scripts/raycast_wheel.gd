extends RayCast3D
class_name RaycastWheel

@export var shapecast        : ShapeCast3D
@export var shape_offset     : float = 0.3

@export_group("Wheel Properties")
@export var spring_strength  : float = 100.0
@export var spring_damping   : float = 2.0
@export var max_spring_force : float = INF
@export var rest_dist        : float = 0.5
@export var over_extend      : float = 0.0
@export var wheel_radius     : float = 0.4
@export var z_traction       : float = 0.05
@export var z_brake_traction : float = 0.25

@export_category("Motor")
@export var is_motor         : bool = false
@export var is_steer         : bool = false
@export var grip_curve       : Curve

@onready var wheel           : Node3D = get_child(0)

var engine_force             : float = 0.0
var grip_factor              : float = 0.0
var is_braking               : bool = false

func  _ready() -> void:
	target_position.y = -(rest_dist + wheel_radius + over_extend)
	
	if shapecast:
		shapecast.target_position.x = -(rest_dist + over_extend) - shape_offset
		shapecast.add_exception(get_parent())
		shapecast.position.y = shape_offset

func apply_wheel_physics(car : RaycastCar) -> void:
	target_position.y = -(rest_dist + wheel_radius + over_extend)
	if shapecast:
		shapecast.target_position.x = -(rest_dist + over_extend) - shape_offset
	
	## Rotate wheel visuals
	var forward_dir : Vector3 = -global_basis.z.normalized()
	var speed       : float = forward_dir.dot(car.linear_velocity)
	wheel.rotate_x(-speed * get_physics_process_delta_time() / wheel_radius)
	
	if not shapecast and not is_colliding():return
	if shapecast and not shapecast.is_colliding(): return
	# From here on, the wheel raycast is now colliding
	
	var contact     : Vector3 = get_collision_point()
	if shapecast:
		contact = shapecast.get_collision_point(0)
	var spring_len  : float = maxf(0.0, global_position.distance_to(contact) - wheel_radius)
	var offset      : float = rest_dist - spring_len
	
	wheel.position.y = -spring_len  # move_toward(wheel.position.y, -spring_len, 5 * get_physics_process_delta_time())
	contact = wheel.global_position # Contact is now the wheel origin point
	var force_pos := contact - car.global_position
	
	## Spring force
	var spring_force      : float = offset * spring_strength
	var tire_vel          : Vector3 = car._get_point_velocity(contact) #Center of the wheel
	var spring_damp_force : float = spring_damping * global_basis.y.dot(tire_vel)
	var suspension_force  : float = clampf(spring_force - spring_damp_force, -max_spring_force, max_spring_force)
	
	var y_force           : Vector3 = suspension_force * get_collision_normal()
	if shapecast:
		y_force = suspension_force * shapecast.get_collision_normal(0)
	
	## Acceleration
	if is_motor and car .motor_input:
		var speed_ration   : float = speed / car.max_speed
		var ac             : float = car.accel_curve.sample_baked(speed_ration)
		if car.nitro:
			ac *= 10

		var accel_force    : Vector3 = forward_dir * car.acceleration * car.motor_input * ac
		car.apply_force(accel_force, force_pos)
	
	## Tire X traction (Steering)
	var steering_x_vel : float = global_basis.x.dot(tire_vel)
	
	grip_factor        = absf(steering_x_vel / tire_vel.length())
	
	if absf(speed) < 3.6:
		grip_factor = 0.0
	
	var x_traction     : float = grip_curve.sample_baked(grip_factor)
	
	
	if car.hand_break :
		x_traction     *= 0.1
	elif car.is_slipping :
		x_traction     *= 0.2
	
	var gravity        : float = -car.get_gravity().y
	var x_force        : Vector3 = -global_basis.x * steering_x_vel * x_traction * ((car.mass * gravity)/car.total_wheels)
	
	## Tire Z traction (Longitudinasl)
	var f_speed        : float = -global_basis.z.dot(tire_vel)
	var z_friction     : float = z_traction
	
	if absf(f_speed) < 1.0:
		z_friction = 2.0
	if is_braking:
		z_friction = z_brake_traction
	
	var z_force        : Vector3 = global_basis.z * f_speed * z_friction *  ((car.mass * car.gravity)/car.total_wheels)
	
	## Counter sliding
	if absf(f_speed) < 0.1:
		var susp := global_basis.y * suspension_force
		z_force.z -= susp.z * car.global_basis.y.dot(Vector3.UP)
		x_force.x -= susp.x * car.global_basis.y.dot(Vector3.UP)
	
	car.apply_force(y_force, force_pos)
	car.apply_force(x_force, force_pos)
	car.apply_force(z_force, force_pos)
	
	if shapecast:
		for idx in shapecast.get_collision_count():
			var collider := shapecast.get_collider(idx)
			if collider is RigidBody3D:
				collider.apply_force(-(x_force+y_force*z_force), force_pos)

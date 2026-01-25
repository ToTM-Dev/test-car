extends RigidBody3D
class_name RaycastCar

@export_group("Car properties")
@export var jump_force := 5000.0
@export var wheels : Array[RaycastWheel]
@export var acceleration := 30.0
@export var max_speed := 60.0
@export var accel_curve : Curve
@export var tire_turn_speed := 2.0
@export var tire_max_turn_degrees := 20

@export var skid_marks : Array[GPUParticles3D]

@export_group("Camera Settings")
@export var camera_min_distance : float = 4
@export var camera_max_distance : float = 6
@export var camera_height       : float = 3
@export var camera_min_fov      : float = 75
@export var camera_max_fov      : float = 120
@export var camera_fov_step     : float = 35

@export_category("Others")
@export var car_id      : int = 0
@export var vibration   : bool = false

@export_category("Mesh and Materials")
@export var materials : Array[Material]

@onready var mesh : MeshInstance3D = get_child(0)
@onready var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var total_wheels  : float = wheels.size()
@onready var timer         : Timer = $RespawnTimer
@onready var stream_player : AudioStreamPlayer = $AudioStreamPlayer3D
@onready var animaton_player : AnimationPlayer = $AnimationPlayer

@onready var inital_position  : Vector3 = global_position
@onready var initial_rotation : Vector3 = global_rotation

var motor_input          : float = 0
var hand_break           : bool  = false
var is_slipping          : bool  = false
var grounded             : bool  = false
var is_braking           : bool  = false
var controller_connected : bool  = false
var nitro                : bool  = false
var speed                : float = 0.0

func _ready() -> void:
	mesh.set_surface_override_material(0, materials[car_id])
	if Input.get_connected_joypads():
		controller_connected = true
	
	if car_id and Input.get_connected_joypads().size() < car_id + 1:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
	
	inital_position  = global_position
	initial_rotation = global_rotation
	
	animaton_player.play("hide_gun")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
			get_tree().quit()
	
	if event.is_action_pressed("reload_scene"):
		get_tree().reload_current_scene()
	
	if controller_connected and not event.device == car_id:
		return
	
	if event.is_action_pressed("jump") and grounded:
		apply_central_force(Vector3(0,1,0) * jump_force)
	
	if event.is_action_pressed("handbreak"):
		hand_break = true
		is_slipping = true
	elif  event.is_action_released("handbreak"):
		hand_break = false
	
	if event.is_action_pressed("next_car_color"):
		var material_index = materials.find(mesh.get_surface_override_material(0))
		material_index = (material_index + 1) % materials.size()
		mesh.set_surface_override_material(0, materials[material_index])
	elif event.is_action_pressed("preview_car_color"):
		var material_index = materials.find(mesh.get_surface_override_material(0))
		material_index = (material_index - 1) % materials.size()
		mesh.set_surface_override_material(0, materials[material_index])
	
	if event.is_action_pressed("brake"):
		is_braking = true
	if event.is_action_released("brake"):
		is_braking = false
	
	if event.is_action_pressed("nitro"):
		if not nitro and vibration:
			Input.start_joy_vibration(car_id, 1.0,0.5,0.5)
		nitro = true
	elif event.is_action_released("nitro"):
		nitro = false


func _basic_steering_rotation(wheel : RaycastWheel, delta : float) -> void:
	if not wheel.is_steer: return

	var turn_input : float = 0.0
	var controller_turn_input : float = 0.0
	
	if controller_connected:
		controller_turn_input = Input.get_joy_axis(car_id, JOY_AXIS_LEFT_X)
	else:
		turn_input = Input.get_axis("turn_right", "turn_left") * tire_turn_speed
		
	
	if absf(controller_turn_input) > 0.1:
		wheel.rotation.y = move_toward(wheel.rotation.y, -controller_turn_input * 0.01 * tire_max_turn_degrees, tire_turn_speed * delta)
	elif turn_input:
		wheel.rotation.y = wheel.rotation.y + turn_input * delta	
		wheel.rotation.y = clampf(wheel.rotation.y , deg_to_rad(-tire_max_turn_degrees), deg_to_rad(tire_max_turn_degrees))
	else:
		wheel.rotation.y = move_toward(wheel.rotation.y, 0, tire_turn_speed * delta)
	



func  _physics_process(_delta: float) -> void:
	
	speed = linear_velocity.dot(-global_basis.z.normalized())
	if get_colliding_bodies() and speed  > 1 and vibration:
		Input.start_joy_vibration(car_id, 0.2, 0.1 , 0.01)

	
	if controller_connected:
		motor_input = Input.get_joy_axis(car_id, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(car_id, JOY_AXIS_TRIGGER_LEFT)
		if absf(motor_input) < 0.1:
			motor_input = 0.0
	else:
		motor_input = Input.get_axis("brake","accelerate")
	
	var id       : int = 0
	grounded = false
	
	for wheel in wheels:
		wheel.apply_wheel_physics(self)
		_basic_steering_rotation(wheel, _delta)
		
		if is_braking:
			wheel.is_braking = true
		else:
			wheel.is_braking = false
		
		# Skid mark
		skid_marks[id].global_position = wheel.get_collision_point() + Vector3.UP * 0.05
		skid_marks[id].look_at(skid_marks[id].global_position + global_basis.z)
		
		if not hand_break and wheel.grip_factor < 0.2:
			is_slipping = false
			skid_marks[id].emitting = false
		if hand_break and not skid_marks[id].emitting:
			skid_marks[id].emitting = true
		
		if wheel.is_colliding():
			grounded = true
		id += 1
	
	var speed_ratio : float = speed / max_speed
	stream_player.pitch_scale = 1 + accel_curve.sample_baked(speed_ratio) * absf(motor_input)
	stream_player.volume_db   = absf(accel_curve.sample_baked(speed_ratio) - 0.35) * absf(motor_input) * 50 -5
	
	if grounded:
		center_of_mass = Vector3.ZERO
		if not timer.is_stopped():
			timer.stop()
			if vibration:
				Input.start_joy_vibration(car_id, 1, 0.4 , 0.1)
	else:
		if timer.is_stopped():
			timer.start()
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * 0.5


func _get_point_velocity(point:Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - to_global(center_of_mass))


func _on_respawn_timer_timeout() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_rotation = initial_rotation
	global_position = inital_position

extends RigidBody3D
class_name RaycastCar

@export_group("Car physics properties")
@export var wheels                : Array[RaycastWheel]
@export var acceleration          : float = 30
@export var max_speed             : float = 60.0
@export var accel_curve           : Curve
@export var tire_turn_speed       : float = 2
@export var tire_max_turn_degrees : float = 20
@export var skid_marks            : Array[GPUParticles3D]

@export_group("Camera Settings")
@export var camera_min_distance   : float = 4
@export var camera_max_distance   : float = 6
@export var camera_height         : float = 3
@export_subgroup("Camera FOV")
@export var camera_min_fov        : float = 75
@export var camera_max_fov        : float = 120
@export var camera_fov_step       : float = 35

@export_group("Others")
@export var car_id                : int = 0
@export var vibration             : bool = false

@export_group("Mesh and Materials")
@export var materials             : Array[Material]

@export_group("Power Ups and Penalties")
@export var can_jump              : bool              = true
@export var jump_range            : int               = 10
@export var jump_strength         : float             = 5000
@export var can_shoot             : bool              = false
@export var can_nitro             : bool              = true
@export var nitro_strength        : float             = 10
@export var reversed_commands     : bool              = false

@onready var mesh                 : MeshInstance3D    = get_child(0)
@onready var gravity              : float             = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var total_wheels         : float             = wheels.size()
@onready var timer                : Timer             = $RespawnTimer
@onready var animaton_player      : AnimationPlayer   = $AnimationPlayer

var inital_position               : Vector3 = Vector3.ZERO
var initial_rotation              : Vector3 = Vector3.ZERO

var motor_input                   : float = 0
var speed                         : float = 0.0
var hand_break                    : bool  = false
var is_slipping                   : bool  = false
var is_braking                    : bool  = false
var grounded                      : bool  = false
var controller_connected          : bool  = false
var nitro                         : bool  = false
var jump                          : bool  = false
var left_jumps                    : int   = 0
var controller                    : int   = 0 # -1 if is keyboard or > 0 if it's joypads
var camera                        : Camera3D
var ntc                           : int = 0 # next touched check

func _ready() -> void:
	mesh.set_surface_override_material(0, materials[car_id])
	
	if inital_position == Vector3.ZERO and initial_rotation == Vector3.ZERO:
		inital_position  = global_position
		initial_rotation = global_rotation
	else:
		global_position = inital_position
		global_rotation = initial_rotation
	
	animaton_player.play("hide_gun")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reload_scene"):
		_respawn()
		self.global_rotation = initial_rotation
		self.global_position = inital_position
	
	
	if event.is_action_pressed("jump") and grounded and can_jump:
		jump = true
	elif event.is_action_released("jump"):
		jump = false
	
	if event.is_action_pressed("handbreak"):
		hand_break = true
		is_slipping = true
	elif  event.is_action_released("handbreak"):
		hand_break = false
	
	if event.is_action_pressed("next_car_color"):
		var material       = mesh.get_surface_override_material(0)
		var material_index = materials.find(material)
		material_index = (material_index + 1) % materials.size()
		mesh.set_surface_override_material(0, materials[material_index])
	elif event.is_action_pressed("preview_car_color"):
		var material       = mesh.get_surface_override_material(0)
		var material_index = materials.find(material)
		material_index     = (material_index - 1) % materials.size()
		mesh.set_surface_override_material(0, materials[material_index])
	
	if event.is_action_pressed("brake"):
		is_braking = true
	if event.is_action_released("brake"):
		is_braking = false
	
	if event.is_action_pressed("nitro") and can_nitro:
		if not nitro and vibration:
			Input.start_joy_vibration(controller, 1.0,0.5,0.5)
		nitro = true
	elif event.is_action_released("nitro"):
		nitro = false


func _basic_steering_rotation(wheel : RaycastWheel, delta : float) -> void:
	if not wheel.is_steer: return

	var turn_input : float = 0.0
	
	if controller == -1:
		turn_input = Input.get_axis("turn_right", "turn_left") * tire_turn_speed
	elif controller > -1 :
		turn_input = Input.get_joy_axis(controller, JOY_AXIS_LEFT_X)
		
	if reversed_commands:
		turn_input = -turn_input
	
	if absf(turn_input) > 0.05 and controller > -1:
		wheel.rotation.y = move_toward(wheel.rotation.y, -turn_input * 0.01 * tire_max_turn_degrees, tire_turn_speed * delta)
		wheel.rotation.y = clampf(wheel.rotation.y , deg_to_rad(-tire_max_turn_degrees), deg_to_rad(tire_max_turn_degrees))
	elif turn_input and controller == -1:
		wheel.rotation.y = wheel.rotation.y + turn_input * delta
		wheel.rotation.y = clampf(wheel.rotation.y , deg_to_rad(-tire_max_turn_degrees), deg_to_rad(tire_max_turn_degrees))
	else:
		wheel.rotation.y = move_toward(wheel.rotation.y, 0, tire_turn_speed * delta)
	



func  _physics_process(_delta: float) -> void:
	
	speed = linear_velocity.dot(-global_basis.z.normalized())
	if get_colliding_bodies() and speed  > 10 and vibration:
		Input.start_joy_vibration(controller, 0.2 * speed / max_speed, 0.1 * speed / max_speed, 0.01)

	
	if controller > -1:
		motor_input = Input.get_joy_axis(controller, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(controller, JOY_AXIS_TRIGGER_LEFT)
		if absf(motor_input) < 0.1:
			motor_input = 0.0
	else:
		motor_input = Input.get_axis("brake","accelerate")
	
	if nitro:
		motor_input *= nitro_strength
	
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
		skid_marks[id].global_position = wheel.get_collision_point() + Vector3.UP * 0.001
		skid_marks[id].look_at(skid_marks[id].global_position + global_basis.z)
		
		if not hand_break and wheel.grip_factor < 0.1:
			is_slipping = false
			skid_marks[id].emitting = false
		if hand_break and not skid_marks[id].emitting:
			skid_marks[id].emitting = true
		
		if wheel.is_colliding():
			grounded = true
		id += 1
	
	if jump and left_jumps > 0:
		left_jumps -= 1
		#apply_central_force(Vector3(0,1,0) * jump_strength)
		linear_velocity.y = jump_strength
		linear_velocity.y += float(left_jumps) / 3
	
	if grounded:
		left_jumps = jump_range
		center_of_mass = Vector3.ZERO
		if not timer.is_stopped():
			timer.stop()
			if vibration:
				Input.start_joy_vibration(controller, 1, 0.4 , 0.1)
	else:
		if timer.is_stopped():
			timer.start()
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * 0.5


func _get_point_velocity(point:Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - to_global(center_of_mass))


func _on_respawn_timer_timeout() -> void:
	_respawn()

func _respawn():
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_rotation = initial_rotation
	global_position = inital_position
	_change_camera_check_visi(ntc, false)
	_change_camera_check_visi(0)
	camera.timer = 0.0
	camera._pause_timer()
	ntc = 0

func _change_camera_check_visi(check_id : int, boolean : bool = true):
	camera.set_cull_mask_value(check_id + 2, boolean)

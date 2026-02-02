extends Camera3D

@export var min_distance       : float = 4.0
@export var max_distance        : float = 8.0
@export var height            : float = 3.0
@export var min_fov            : float = 75
@export var max_fov            : float = 120
@export var fov_step           : float = 45
@export var offset             : float = 1
@export var nitro_max_distance : float = 8

@export var target : RaycastCar

@onready var parent = get_parent()

var speed_label : Label 
var respawn_label : Label

func  _ready() -> void:
	_update_settings()
	speed_label = $"../../Control/Label"
	respawn_label = $"../../Control/AspectRatioContainer/CenterContainer/Label"
	


func _physics_process(_delta: float) -> void:
	var from_target := global_position - target.global_position
	
	# Check range
	if from_target.length() < min_distance:
		from_target = from_target.normalized() * min_distance
	elif target.nitro:
		if from_target.length() > nitro_max_distance:
			from_target = from_target.normalized() * nitro_max_distance
	elif from_target.length() > max_distance:
		from_target = from_target.normalized() * max_distance
	
	from_target.y = height
	
	global_position = target.global_position + from_target
	
	# Look at the car
	var look_dir := global_position.direction_to(target.global_position).abs() - Vector3.UP
	if not look_dir.is_zero_approx():
		look_at_from_position(global_position, target.global_position + Vector3.UP * offset, Vector3.UP)
	
	
	# Change FOV in function of the speed of the car
	fov = min(lerp(fov, (max(target.speed, 0) / target.max_speed) * fov_step + min_fov,
			 5 * _delta), max_fov)
	
	if speed_label:
		_update_compteur(speed_label)
	
	if respawn_label:
		if 0.0 < target.timer.time_left and target.timer.time_left < 6.0:
			respawn_label.visible = true
			respawn_label.text    = str(roundf(target.timer.time_left * 10)/10)
		else:
			respawn_label.visible = false
	
	var turn_input = Input.get_joy_axis(target.car_id, JOY_AXIS_RIGHT_X)
	var z_turn_input = Input.get_joy_axis(target.car_id, JOY_AXIS_RIGHT_Y)
	
	if absf(turn_input) > 0.3 and parent is not SubViewport:
		parent.global_position = target.global_position
		top_level = false
		parent.rotate_y(0.1 * turn_input)
			
		top_level = true
	
	if absf(z_turn_input) > 0.3 and parent is not SubViewport:
		parent.global_position = target.global_position
		top_level = false
		parent.rotate_z(0.1 * z_turn_input)
			
		top_level = true

func _update_compteur(compteur : Label) ->void:
	var speed_km_h = target.speed * 2
	compteur.text = str(round(speed_km_h)) + "Km/H"

func _update_settings():
	if target is RaycastCar:
		min_distance = target.camera_min_distance
		max_distance = target.camera_max_distance
		nitro_max_distance = target.camera_max_distance
		height       = target.camera_height
		min_fov      = target.camera_min_fov
		max_fov      = target.camera_max_fov
		fov_step     = target.camera_fov_step

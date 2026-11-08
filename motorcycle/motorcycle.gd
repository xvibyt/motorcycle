extends RigidBody3D

@export var wheels: Array[RaycastWheel]
@export var acceleration := 500.0
#@export var deceleration := 250.0
@export var max_speed := 10.0
@export var acc_curve: Curve
@export var tire_turn_speed := 1.0
@export var tire_max_turn_degrees := 30

@export var skid_marks: Array[GPUParticles3D]

@export var Camera: Camera3D
@export var CamTarget: Node3D
@export var cam_speed := 9.0
@export var drift_cam_speed := 11.0
var cur_cam_speed := cam_speed

var motor_input := 0.0
var handbreak := false
var is_slipping := false


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("Handbreak"):
		handbreak = true
		is_slipping = true
	elif event.is_action_released("Handbreak"):
		handbreak = false
	
	#motor_input = event.get_action_strength("Forwards") - event.get_action_strength("Backwards")
	if event.is_action_pressed("Forwards"):
		motor_input = 1
		#printt("Forwards pressed", motor_input)
	elif event.is_action_released("Forwards"):
		motor_input = 0
		#printt("Forwards released", motor_input)
	
	if event.is_action_pressed("Backwards"):
		motor_input = -1
		#printt("Backwards pressed", motor_input)
	elif event.is_action_released("Backwards"):
		motor_input = 0
		#printt("Backwards released", motor_input)


func _physics_process(delta: float) -> void:
	#printt(linear_velocity)
	
	Camera.global_position = Camera.global_position.move_toward(CamTarget.global_position, delta * cur_cam_speed)
	var w := 1.0 - exp(-8.0 * delta)
	var look_dir := (global_position + Vector3.UP * 1.0) - Camera.global_position
	var look_basis := Basis.looking_at(look_dir, Vector3.UP)
	Camera.global_basis = Camera.global_basis.orthonormalized().slerp(look_basis, w)
	
	_steering_rotation(delta)
	var grounded := false
	var id := 0
	for wheel in wheels:
		if wheel.is_colliding():
			grounded = true
		wheel.force_raycast_update()
		_do_single_wheel_suspension(wheel)
		_do_single_wheel_acceleration(wheel)
		_do_single_wheel_traction(wheel, id)
		id += 1
	
	if grounded:
		#center_of_mass = Vector3.ZERO
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * 0.5
	else:
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * 1


func _steering_rotation(delta: float) -> void:
	var turn_input := Input.get_axis("Right", "Left") * tire_turn_speed
	if turn_input:
		$Wheel1.rotation.y = clampf($Wheel1.rotation.y + turn_input * delta, 
			deg_to_rad(-tire_max_turn_degrees), deg_to_rad(tire_max_turn_degrees))
	else:
		$Wheel1.rotation.y = move_toward($Wheel1.rotation.y, 0, tire_turn_speed * delta)


func _do_single_wheel_traction(ray: RaycastWheel, idx: int):
	if not ray.is_colliding(): return
	
	var steer_side_dir := ray.global_basis.x
	var tire_vel := _get_point_velocity(ray.wheel.global_position)
	var steer_x_vel := steer_side_dir.dot(tire_vel)
	
	var grip_factor := absf(steer_x_vel/tire_vel.length())
	var x_traction := ray.grip_curve.sample_baked(grip_factor)
	
	skid_marks[idx].global_position = ray.get_collision_point() + Vector3.UP * 0.01
	skid_marks[idx].look_at(skid_marks[idx].global_position + global_basis.z)
	
	if not handbreak and grip_factor < 0.2:
		is_slipping = false
		skid_marks[idx].emitting = false
		cur_cam_speed = cam_speed
	
	if handbreak:
		x_traction = 0.1
		if not skid_marks[idx].emitting:
			skid_marks[idx].emitting = true
		cur_cam_speed = drift_cam_speed
	elif is_slipping:
		x_traction = 0.1
		cur_cam_speed = drift_cam_speed
	
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var x_force := -steer_side_dir * steer_x_vel * x_traction * ((mass * gravity) / 2.0) # realistic
	#var x_force := -global_basis.x * steer_x_vel * x_traction * ((mass * gravity) / 2.0) # arcadish
	
	# BUG
	var f_vel := -ray.global_basis.z.dot(tire_vel)
	var z_traction := 0.05
	var z_force := global_basis.z * f_vel * z_traction * ((mass * gravity) / 2.0) # less realistic
	#var z_force := -ray.global_basis.z * f_vel * z_traction * ((mass * gravity) / 2.0) # more realistic
	
	var force_pos := ray.wheel.global_position - global_position
	apply_force(x_force, force_pos)
	apply_force(z_force, force_pos)


func _do_single_wheel_acceleration(ray: RaycastWheel):
	var forward_dir := -ray.global_basis.z
	var vel := forward_dir.dot(linear_velocity)
	
	ray.wheel.rotate_x((-vel * get_process_delta_time()) / ray.wheel_rad)
	
	if ray.is_colliding():
		var contact_pos :=  ray.wheel.global_position
		
		var force_pos = contact_pos - global_position
		
		if ray.is_motor and motor_input:
			var speed_ratio := vel / max_speed
			var acc := acc_curve.sample_baked(speed_ratio)
			var force_vector := forward_dir * acceleration * motor_input * acc
			apply_force(force_vector, force_pos)


func _get_spring_damp_force(ray: RaycastWheel, contact_pos: Vector3, spring_up_dir: Vector3) -> float:
	var world_vel := _get_point_velocity(contact_pos)
	var relative_vel := spring_up_dir.dot(world_vel)
	return ray.spring_damping * relative_vel

func _get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)

func _do_single_wheel_suspension(ray: RaycastWheel) -> void:
	if ray.is_colliding():
		ray.target_position.y = -(ray.rest_dis + ray.wheel_rad + ray.over_extend)
		var contact_pos := ray.get_collision_point()
		var spring_up_dir := ray.global_transform.basis.y
		var spring_len := maxf(0.0, ray.global_position.distance_to(contact_pos) - ray.wheel_rad)
		var offset := ray.rest_dis - spring_len
		
		ray.wheel.position.y = move_toward(ray.wheel.position.y, -spring_len, 5 * get_physics_process_delta_time())
		
		var spring_force := ray.spring_strength * offset
		var spring_damp_force := _get_spring_damp_force(ray, contact_pos, spring_up_dir)
		
		var force_vector := (spring_force - spring_damp_force) * ray.get_collision_normal() # spring_up_dir is more stable but can move the motorcycle if a wheel is bigger
		contact_pos = ray.wheel.global_position
		var force_pos_offset := contact_pos - global_position
		apply_force(force_vector, force_pos_offset)
		

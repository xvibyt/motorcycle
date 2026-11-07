extends RigidBody3D

@export var wheels: Array[RaycastWheel]
@export var acceleration := 500.0
@export var deceleration := 250.0
@export var max_speed := 10.0
@export var acc_curve: Curve

var motor_input := 0


func _unhandled_input(event: InputEvent):
	motor_input = Input.get_action_strength("Forwards") - Input.get_action_strength("Backwards")
	#if event.is_action_pressed("Forwards"):
		#motor_input = 1
	#elif event.is_action_released("Forwards"):
		#motor_input = 0
	#
	#if event.is_action_pressed("Backwards"):
		#motor_input = -1
	#elif event.is_action_released("Backwards"):
		#motor_input = 0


func _physics_process(delta: float) -> void:
	print(linear_velocity)
	var grounded := false
	for wheel in wheels:
		if wheel.is_colliding():
			grounded = true
		wheel.force_raycast_update()
		_do_single_wheel_suspension(wheel)
		_do_single_wheel_acceleration(wheel)
	
	if grounded:
		#center_of_mass = Vector3.ZERO
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * 0.2
	else:
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * 1


func _do_single_wheel_acceleration(ray: RaycastWheel):
	var forward_dir := -ray.global_basis.z
	var vel := forward_dir.dot(linear_velocity)
	
	ray.wheel.rotate_x(-vel * get_process_delta_time() * 2 * PI * ray.wheel_rad)
	
	if ray.is_colliding():
		var contact_pos :=  ray.wheel.global_position
		
		var force_pos = contact_pos - global_position
		
		if ray.is_motor and motor_input:
			var speed_ratio := vel / max_speed
			var acc := acc_curve.sample_baked(speed_ratio)
			var force_vector := forward_dir * acceleration * motor_input * acc
			apply_force(force_vector, force_pos)
		elif abs(vel) > 10.05 and not motor_input:
			var drag_force_vector = global_basis.z * deceleration * signf(vel)
			apply_force(drag_force_vector, force_pos)


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
		var spring_len := ray.global_position.distance_to(contact_pos) - ray.wheel_rad
		var offset := ray.rest_dis - spring_len
		
		ray.wheel.position.y = -spring_len
		
		var spring_force := ray.spring_strength * offset
		var spring_damp_force := _get_spring_damp_force(ray, contact_pos, spring_up_dir)
		
		var force_vector := (spring_force - spring_damp_force) * ray.get_collision_normal() # spring_up_dir is more stable but can move the motorcycle if a wheel is bigger
		contact_pos = ray.wheel.global_position
		var force_pos_offset := contact_pos - global_position
		apply_force(force_vector, force_pos_offset)
		

extends RigidBody3D

@export var wheels: Array[RaycastWheel]


func _physics_process(delta: float) -> void:
	for wheel in wheels:
		_do_single_wheel_suspension(wheel)


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
		
		print(spring_len)
		ray.wheel.position.y = -spring_len
		
		var spring_force := ray.spring_strength * offset
		var spring_damp_force := _get_spring_damp_force(ray, contact_pos, spring_up_dir)
		
		var force_vector := (spring_force - spring_damp_force) * spring_up_dir
		var force_pos_offset := contact_pos - global_position
		apply_force(force_vector, force_pos_offset)

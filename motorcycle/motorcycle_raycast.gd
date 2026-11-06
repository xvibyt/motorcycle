extends RigidBody3D

@export var wheels: Array[RayCast3D]
@export var spring_strength := 100.0
@export var spring_damping := 1.0
@export var rest_dist := 0.5


func _physics_process(delta: float) -> void:
	for wheel in wheels:
		_do_single_wheel_suspension(wheel)


func _get_spring_damp_force(contact_pos: Vector3, spring_up_dir: Vector3) -> float:
	var world_vel := _get_point_velocity(contact_pos)
	var relative_vel := spring_up_dir.dot(world_vel)
	return spring_damping * relative_vel

func _get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)

func _do_single_wheel_suspension(suspension_ray: RayCast3D) -> void:
	if suspension_ray.is_colliding():
		var contact_pos := suspension_ray.get_collision_point()
		var spring_up_dir := suspension_ray.global_transform.basis.y
		var spring_len := suspension_ray.global_position.distance_to(contact_pos)
		var offset := rest_dist - spring_len
		
		var spring_force := spring_strength * offset
		var spring_damp_force := _get_spring_damp_force(contact_pos, spring_up_dir)
		
		var force_vector := (spring_force - spring_damp_force) * spring_up_dir
		
		var force_pos_offset := contact_pos - global_position
		
		apply_force(force_vector, force_pos_offset)

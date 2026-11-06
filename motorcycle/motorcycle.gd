extends VehicleBody3D

func _physics_process(delta):
	if Input.is_action_pressed("Forwards"):
		engine_force += 1
	if Input.is_action_just_pressed("Backwards"):
		engine_force -= 1

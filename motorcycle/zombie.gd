extends RigidBody3D


@export var LeftLeg: RigidBody3D
@export var RightLeg: RigidBody3D

@export var LeftFoot: RigidBody3D
@export var RightFoot: RigidBody3D

#@export var LeftTarget: Node3D
#@export var RightTarget: Node3D

@export var Torso: Node3D

@export var speed := 50.0

var foot := "left"
var is_target_set := false
var target_pos: Vector3

func _physics_process(delta: float) -> void:
	if not is_target_set:
		print(1)
		if foot == "left":
			target_pos = global_position + global_basis.orthonormalized() * Vector3(0.25, -1.5, 0.5)
			is_target_set = true
			LeftFoot.global_position = LeftFoot.global_position.move_toward(target_pos, delta * speed)
			#if LeftFoot.global_position.distance_to(target_pos) < 0.1:
				#print(111)
				#foot = "right"
				#is_target_set = false
		#elif foot == "right":
			#target_pos = global_position + global_basis.orthonormalized() * Vector3(-0.25, -1.5, 0.5)
			#is_target_set = true
			#RightFoot.global_position = RightFoot.global_position.move_toward(target_pos, delta * speed)
			#if RightFoot.global_position.distance_to(target_pos) < 0.1:
				#print(111)
				#foot = "left"
				#is_target_set = false

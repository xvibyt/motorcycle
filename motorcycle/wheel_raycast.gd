extends RayCast3D
class_name RaycastWheel

@export_category("Suspension")
@export var spring_strength := 100.0
@export var spring_damping := 1.0
@export var rest_dis := 0.5
@export var over_extend := 0.0
@export var wheel_rad := 0.5
@export_category("Vehicle")
@export var is_motor := false
@export var grip_curve: Curve

@onready var wheel: Node3D = $WheelMesh

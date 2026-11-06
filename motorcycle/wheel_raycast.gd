extends RayCast3D
class_name RaycastWheel

@export var spring_strength := 100.0
@export var spring_damping := 1.0
@export var rest_dis := 0.5
@export var over_extend := 0.0
@export var wheel_rad := 0.5

@onready var wheel: Node3D = $WheelMesh

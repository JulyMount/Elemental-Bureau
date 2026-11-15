extends Node3D

@export var target: Node3D
@export var follow_speed: float = 10.0

func _physics_process(delta: float) -> void:
	if target:
		global_position = global_position.lerp(target.global_position, follow_speed * delta)

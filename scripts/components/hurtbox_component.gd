class_name HurtboxComponent
extends Area3D

@export var health_component: HealthComponent

func apply_hit(amount: float, _knockback: Vector3 = Vector3.ZERO) -> void:
	if health_component:
		health_component.damage(amount)

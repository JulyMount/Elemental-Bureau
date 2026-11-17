class_name HurtboxComponent
extends Area3D

signal hit_received(amount: float, knockback: Vector3)

@export var health_component: HealthComponent

func apply_hit(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if health_component:
		health_component.damage(amount)
	hit_received.emit(amount, knockback)

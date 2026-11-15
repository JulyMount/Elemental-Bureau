class_name HealthComponent
extends Node

signal health_changed(current_health: float, max_health: float)
signal died

@export var max_health: float = 100.0
var current_health: float
var is_invulnerable: bool = false

func _ready() -> void:
	current_health = max_health

func damage(amount: float) -> void:
	if is_invulnerable or current_health <= 0.0:
		return
		
	current_health = clamp(current_health - amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	current_health = clamp(current_health + amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)

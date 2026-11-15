class_name HitboxComponent
extends Area3D

@export var damage: float = 10.0
@export var knockback_force: float = 5.0
@export var hitstop_duration: float = 0.04 #tira isso aqui se tirar o hitstop

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if area is HurtboxComponent:
		var push_dir: Vector3 = (area.global_position - global_position)
		push_dir.y = 0.0
		push_dir = push_dir.normalized() * knockback_force
		area.apply_hit(damage, push_dir) #a partir daqui pode apagar para tirar o hitstop, acho que é esse o nome kkkkkkk
		_trigger_hitstop()
		
		
func _trigger_hitstop() -> void:
	if hitstop_duration <= 0.0:
		return
	Engine.time_scale = 0.05
	await get_tree().create_timer(hitstop_duration, true, false, true).timeout
	Engine.time_scale = 1.0

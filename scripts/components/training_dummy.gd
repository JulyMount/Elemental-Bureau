extends CSGCylinder3D

@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
	add_to_group("enemies")
	use_collision = true
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)

func _on_health_changed(current: float, maximum: float) -> void:
	print("Dummy atingido! Vida: ", current, "/", maximum)
	# Efeito rápido de achatamento (squash) ao tomar dano
	var tween := create_tween()
	scale = Vector3(1.25, 0.75, 1.25)
	tween.tween_property(self, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_ELASTIC)

func _on_died() -> void:
	print("Dummy derrotado!")
	queue_free()

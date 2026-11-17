class_name EnemyBrute
extends EnemyBase

@onready var slam_hitbox: HitboxComponent = get_node_or_null("VisualRoot/AttackHitbox") as HitboxComponent

func _ready() -> void:
	move_speed = 2.3
	attack_range = 2.2
	telegraph_duration = 0.85
	attack_duration = 0.25
	recover_duration = 1.05
	knockback_resistance = 2.8
	can_be_staggered = false
	base_color = Color(0.55, 0.22, 0.68) # Roxo pesado
	super._ready()
	
	if slam_hitbox:
		slam_hitbox.damage = 22.0
		slam_hitbox.knockback_force = 7.5
		slam_hitbox.monitoring = false
		# Garante que detecta a Layer 1 (onde está a Hurtbox do Player) e Layer 3
		slam_hitbox.collision_mask = (1 << 0) | (1 << 2)

func _build_default_mesh() -> Mesh:
	var box := BoxMesh.new()
	box.size = Vector3(1.15, 1.75, 1.15)
	return box

func _on_attack_started() -> void:
	# Dá um passo curto para frente no impacto e ativa o golpe pesado
	_move_velocity = _attack_direction * 4.5
	if slam_hitbox:
		slam_hitbox.monitoring = true

func _on_attack_tick(delta: float) -> void:
	_move_velocity = _move_velocity.move_toward(Vector3.ZERO, 22.0 * delta)

func _on_attack_finished() -> void:
	if slam_hitbox:
		slam_hitbox.monitoring = false

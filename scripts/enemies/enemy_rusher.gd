class_name EnemyRusher
extends EnemyBase

@export var lunge_speed: float = 13.5
@onready var attack_hitbox: HitboxComponent = $VisualRoot/AttackHitbox

func _ready() -> void:
	move_speed = 4.6
	attack_range = 3.2
	telegraph_duration = 0.48
	attack_duration = 0.22
	recover_duration = 0.65
	base_color = Color(0.88, 0.24, 0.28) # Vermelho vivo
	super._ready()
	if attack_hitbox:
		attack_hitbox.monitoring = false

func _on_attack_started() -> void:
	if attack_hitbox:
		attack_hitbox.monitoring = true

func _on_attack_tick(_delta: float) -> void:
	_move_velocity.x = _attack_direction.x * lunge_speed
	_move_velocity.z = _attack_direction.z * lunge_speed

func _on_attack_finished() -> void:
	if attack_hitbox:
		attack_hitbox.monitoring = false

class_name Player
extends CharacterBody3D

@export_group("Movimentacao")
@export var SPEED: float = 6.5
@export var ACCELERATION: float = 45.0
@export var DECELERATION: float = 55.0
@export var ROTATION_SPEED: float = 14.0

@export_group("Dash")
@export var DASH_SPEED: float = 18.0
@export var DASH_DURATION: float = 0.18
@export var DASH_COOLDOWN: float = 0.65

@export_group("Soft Lock")
@export var SOFT_LOCK_RANGE: float = 6.0
@export var SOFT_LOCK_CONE_ANGLE_DEG: float = 55.0

@onready var visual_root: Node3D = $VisualRoot
@onready var health_component: HealthComponent = $HealthComponent
@onready var melee_hitbox: HitboxComponent = $VisualRoot/MeleeHitbox
@onready var soft_lock_area: Area3D = $SoftLockArea

@onready var skill_manager: SkillManagerComponent = $SkillManagerComponent
@onready var elemental: ElementalComponent = $ElementalComponent

@onready var hurtbox: HurtboxComponent = get_node_or_null("HurtboxComponent") as HurtboxComponent
var _knockback_velocity: Vector3 = Vector3.ZERO

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _camera_yaw: float = deg_to_rad(45.0)
var _last_move_dir: Vector3 = Vector3(0, 0, -1)

# Estados de Dash e Ataque
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _is_attacking: bool = false

var _move_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("player")
	if hurtbox:
		hurtbox.hit_received.connect(_on_hurtbox_hit_received)
	# Detecta automaticamente a rotação Y da câmera ativa na cena (ex: 45° do CameraRig)
	var active_cam := get_viewport().get_camera_3d()
	if active_cam:
		_camera_yaw = active_cam.global_rotation.y
	if elemental:
		elemental.setup(self)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash") and not _is_dashing and _dash_cooldown_timer <= 0.0:
		_start_dash()
	elif event.is_action_pressed("attack_basic") and not _is_attacking and not _is_dashing:
		_perform_basic_attack()
	elif event.is_action_pressed("skill_1") and not _is_dashing:
		if skill_manager.trigger_skill("skill_1"):
			var aim_dir := _get_soft_lock_direction(_last_move_dir)
			visual_root.look_at(visual_root.global_position + aim_dir, Vector3.UP)
			elemental.cast_skill_1(global_position, aim_dir)
	elif event.is_action_pressed("skill_2") and not _is_dashing:
		if elemental and elemental.can_cast_skill_2() and skill_manager.trigger_skill("skill_2"):
			elemental.cast_skill_2(global_position)
	elif event.is_action_pressed("ultimate") and not _is_dashing:
		if skill_manager.trigger_skill("ultimate"):
			elemental.cast_ultimate()
	elif event.is_action_pressed("switch_element"):
		if elemental:
			elemental.switch_element()

func _physics_process(delta: float) -> void:
	# Timers
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta

	# Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# Vetor de Entrada usando seus inputs mapeados
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector3 = Vector3(input_dir.x, 0.0, input_dir.y).rotated(Vector3.UP, _camera_yaw).normalized()

	if direction != Vector3.ZERO:
		_last_move_dir = direction

	if _is_dashing:
		_process_dash(delta)
	else:
		_process_normal_movement(direction, delta)

	# Desacelera o knockback rápido sem afetar a velocidade normal de caminhada
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 42.0 * delta)
	velocity.x = _move_velocity.x + _knockback_velocity.x
	velocity.z = _move_velocity.z + _knockback_velocity.z

	move_and_slide()

func _process_normal_movement(direction: Vector3, delta: float) -> void:
	var current_max_speed := SPEED * (0.35 if _is_attacking else 1.0)

	if direction != Vector3.ZERO:
		_move_velocity.x = move_toward(_move_velocity.x, direction.x * current_max_speed, ACCELERATION * delta)
		_move_velocity.z = move_toward(_move_velocity.z, direction.z * current_max_speed, ACCELERATION * delta)

		if not _is_attacking:
			var target_rotation: float = atan2(-direction.x, -direction.z)
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rotation, ROTATION_SPEED * delta)
	else:
		_move_velocity.x = move_toward(_move_velocity.x, 0.0, DECELERATION * delta)
		_move_velocity.z = move_toward(_move_velocity.z, 0.0, DECELERATION * delta)

func _start_dash() -> void:
	_is_dashing = true
	_dash_timer = DASH_DURATION
	_dash_cooldown_timer = DASH_COOLDOWN
	_dash_direction = _last_move_dir

	# Ativa i-frames durante o Dash
	health_component.is_invulnerable = true
	visual_root.rotation.y = atan2(-_dash_direction.x, -_dash_direction.z)
	if elemental:
		elemental.on_dash_started(global_position)

func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	_move_velocity.x = _dash_direction.x * DASH_SPEED
	_move_velocity.z = _dash_direction.z * DASH_SPEED

	if _dash_timer <= 0.0:
		_is_dashing = false
		health_component.is_invulnerable = false
		_move_velocity.x *= 0.4
		_move_velocity.z *= 0.4

func _perform_basic_attack() -> void:
	_is_attacking = true
	var aim_dir: Vector3 = _get_soft_lock_direction(_last_move_dir)

	# Usa look_at para garantir que o eixo -Z (frente real) aponte exatamente para aim_dir
	visual_root.look_at(visual_root.global_position + aim_dir, Vector3.UP)

	melee_hitbox.monitoring = true
	await get_tree().create_timer(0.15).timeout
	melee_hitbox.monitoring = false
	await get_tree().create_timer(0.10).timeout
	_is_attacking = false

func _get_soft_lock_direction(desired_dir: Vector3) -> Vector3:
	var best_dir: Vector3 = desired_dir
	var best_score: float = -1.0
	var max_angle_rad: float = deg_to_rad(SOFT_LOCK_CONE_ANGLE_DEG)

	for body in soft_lock_area.get_overlapping_bodies():
		if body == self or not body.is_in_group("enemies"):
			continue
		var to_target: Vector3 = body.global_position - global_position
		to_target.y = 0.0
		var dist: float = to_target.length()
		if dist <= 0.05 or dist > SOFT_LOCK_RANGE:
			continue

		var dir_to_target: Vector3 = to_target / dist
		var angle: float = desired_dir.angle_to(dir_to_target)

		# Se estiver bem perto (< 2.5m) ou dentro do cone frontal, puxa a mira
		if dist < 2.5 or angle <= max_angle_rad:
			var score: float = (1.0 - min(angle / max_angle_rad, 1.0)) * 0.6 + (1.0 - (dist / SOFT_LOCK_RANGE)) * 0.4
			if score > best_score:
				best_score = score
				best_dir = dir_to_target

	return best_dir.normalized()

func _on_hurtbox_hit_received(_amount: float, knockback: Vector3) -> void:
	if health_component and health_component.is_invulnerable:
		return
	var kb: Vector3 = knockback
	kb.y = 0.0
	if kb.length() > 7.5:
		kb = kb.normalized() * 7.5
	_knockback_velocity = kb

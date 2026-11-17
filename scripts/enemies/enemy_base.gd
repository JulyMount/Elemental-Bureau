class_name EnemyBase
extends CharacterBody3D

enum State { CHASE, TELEGRAPH, ATTACK, RECOVER, STAGGER }

@export_group("Atributos Base")
@export var move_speed: float = 3.8
@export var acceleration: float = 22.0
@export var attack_range: float = 2.1
@export var telegraph_duration: float = 0.55
@export var attack_duration: float = 0.25
@export var recover_duration: float = 0.70
@export var knockback_resistance: float = 1.0
@export var can_be_staggered: bool = true

@export_group("Visual Blockout")
@export var base_color: Color = Color(0.85, 0.22, 0.28)
@export var telegraph_color: Color = Color(1.0, 0.92, 0.35)

@onready var health_component: HealthComponent = get_node_or_null("HealthComponent") as HealthComponent
@onready var hurtbox: HurtboxComponent = get_node_or_null("HurtboxComponent") as HurtboxComponent
@onready var visual_root: Node3D = get_node_or_null("VisualRoot") as Node3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var state: State = State.CHASE
var _state_timer: float = 0.0
var _player: Node3D
var _knockback_velocity: Vector3 = Vector3.ZERO
var _move_velocity: Vector3 = Vector3.ZERO
var _attack_direction: Vector3 = Vector3.FORWARD
var _body_mesh: MeshInstance3D
var _base_material: StandardMaterial3D

func _ready() -> void:
	add_to_group("enemies")
	_find_player()
	
	if not visual_root:
		visual_root = Node3D.new()
		visual_root.name = "VisualRoot"
		add_child(visual_root)
	
	_setup_visuals()
	
	if health_component:
		health_component.died.connect(_on_died)
	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node3D
	if not _player and get_tree().current_scene:
		for node in get_tree().current_scene.find_children("*", "Player", true, false):
			_player = node as Node3D
			break

func _setup_visuals() -> void:
	_body_mesh = visual_root.get_node_or_null("BodyMesh") as MeshInstance3D
	if not _body_mesh:
		_body_mesh = MeshInstance3D.new()
		_body_mesh.name = "BodyMesh"
		_body_mesh.mesh = _build_default_mesh()
		_body_mesh.position.y = 0.85
		visual_root.add_child(_body_mesh)
	
	_base_material = StandardMaterial3D.new()
	_base_material.albedo_color = base_color
	_base_material.roughness = 0.75
	_body_mesh.material_override = _base_material

func _build_default_mesh() -> Mesh:
	var cap := CapsuleMesh.new()
	cap.radius = 0.42
	cap.height = 1.65
	return cap

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	
	if not is_instance_valid(_player):
		_find_player()
	
	# Desacelera o empurrão rapidamente sem acumular velocidade infinita
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 45.0 * delta)
	
	match state:
		State.CHASE:
			_process_chase(delta)
		State.TELEGRAPH:
			_process_telegraph(delta)
		State.ATTACK:
			_process_attack(delta)
		State.RECOVER:
			_process_recover(delta)
		State.STAGGER:
			_process_stagger(delta)
	
	# Soma movimento intencional + recuo momentâneo do knockback
	velocity.x = _move_velocity.x + _knockback_velocity.x
	velocity.z = _move_velocity.z + _knockback_velocity.z
	move_and_slide()

func _process_chase(delta: float) -> void:
	if not _player:
		_move_velocity = _move_velocity.move_toward(Vector3.ZERO, 20.0 * delta)
		return
	
	var to_player: Vector3 = _player.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	
	if dist <= attack_range:
		_enter_telegraph(to_player.normalized())
		return
	
	var dir: Vector3 = to_player.normalized()
	_move_velocity.x = move_toward(_move_velocity.x, dir.x * move_speed, acceleration * delta)
	_move_velocity.z = move_toward(_move_velocity.z, dir.z * move_speed, acceleration * delta)
	_face_direction(dir, delta)

func _enter_telegraph(dir: Vector3) -> void:
	state = State.TELEGRAPH
	_state_timer = telegraph_duration
	_attack_direction = dir if dir.length_squared() > 0.001 else -visual_root.global_transform.basis.z
	_move_velocity = Vector3.ZERO
	
	if _base_material:
		_base_material.albedo_color = telegraph_color
		_base_material.emission_enabled = true
		_base_material.emission = telegraph_color * 0.45
	visual_root.scale = Vector3(1.18, 0.82, 1.18)

func _process_telegraph(delta: float) -> void:
	_state_timer -= delta
	_move_velocity = _move_velocity.move_toward(Vector3.ZERO, 25.0 * delta)
	
	if _player and _state_timer > telegraph_duration * 0.45:
		var to_p: Vector3 = _player.global_position - global_position
		to_p.y = 0.0
		if to_p.length_squared() > 0.001:
			_attack_direction = to_p.normalized()
			_face_direction(_attack_direction, delta * 1.5)
	
	if _state_timer <= 0.0:
		_enter_attack()

func _enter_attack() -> void:
	state = State.ATTACK
	_state_timer = attack_duration
	visual_root.scale = Vector3(0.88, 1.16, 0.88)
	if _base_material:
		_base_material.albedo_color = base_color
		_base_material.emission_enabled = false
	_on_attack_started()

func _process_attack(delta: float) -> void:
	_state_timer -= delta
	_on_attack_tick(delta)
	if _state_timer <= 0.0:
		_on_attack_finished()
		_enter_recover()

func _enter_recover() -> void:
	state = State.RECOVER
	_state_timer = recover_duration
	visual_root.scale = Vector3.ONE
	_move_velocity = Vector3.ZERO

func _process_recover(delta: float) -> void:
	_state_timer -= delta
	_move_velocity = _move_velocity.move_toward(Vector3.ZERO, 20.0 * delta)
	if _state_timer <= 0.0:
		state = State.CHASE

func _process_stagger(delta: float) -> void:
	_state_timer -= delta
	_move_velocity = _move_velocity.move_toward(Vector3.ZERO, 25.0 * delta)
	if _state_timer <= 0.0:
		visual_root.scale = Vector3.ONE
		if _base_material:
			_base_material.albedo_color = base_color
			_base_material.emission_enabled = false
		state = State.CHASE

# ==========================================
# MÉTODOS SOBRESCRITOS PELOS 3 ARQUÉTIPOS
# ==========================================

func _on_attack_started() -> void:
	pass

func _on_attack_tick(_delta: float) -> void:
	pass

func _on_attack_finished() -> void:
	pass

# ==========================================
# DANO, EMPURRÃO E MORTE
# ==========================================

func _on_hit_received(_amount: float, knockback: Vector3) -> void:
	var effective_kb: Vector3 = knockback / maxf(0.25, knockback_resistance)
	effective_kb.y = 0.0
	# Limita o recuo máximo para não arremessar o inimigo para fora da arena
	if effective_kb.length() > 11.0:
		effective_kb = effective_kb.normalized() * 11.0
	_knockback_velocity = effective_kb
	
	if _base_material:
		_base_material.albedo_color = Color.WHITE
		_base_material.emission_enabled = true
		_base_material.emission = Color.WHITE * 0.6
	
	var tween := create_tween()
	visual_root.scale = Vector3(1.24, 0.76, 1.24)
	tween.tween_property(visual_root, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_ELASTIC)
	
	if can_be_staggered and state != State.ATTACK:
		_on_attack_finished()
		state = State.STAGGER
		_state_timer = 0.22
	else:
		await get_tree().create_timer(0.08).timeout
		if is_instance_valid(self) and _base_material and state != State.TELEGRAPH:
			_base_material.albedo_color = base_color
			_base_material.emission_enabled = false

func _on_died() -> void:
	_on_attack_finished()
	queue_free()

func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.001:
		return
	var target_rot: float = atan2(-dir.x, -dir.z)
	visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot, 12.0 * delta)

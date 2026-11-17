class_name EnemyShooter
extends EnemyBase

@export var preferred_distance: float = 7.5
@export var projectile_speed: float = 11.0
@export var projectile_damage: float = 12.0

func _ready() -> void:
	move_speed = 3.2
	attack_range = 9.5
	telegraph_duration = 0.65
	attack_duration = 0.15
	recover_duration = 1.10
	base_color = Color(0.18, 0.68, 0.78) # Ciano/Azul
	super._ready()

func _build_default_mesh() -> Mesh:
	var prism := PrismMesh.new()
	prism.size = Vector3(0.95, 1.7, 0.95)
	return prism

func _process_chase(delta: float) -> void:
	if not _player:
		return
	var to_player: Vector3 = _player.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	var dir: Vector3 = to_player.normalized()
	_face_direction(dir, delta)
	
	if dist < preferred_distance * 0.65:
		_move_velocity.x = move_toward(_move_velocity.x, -dir.x * move_speed, acceleration * delta)
		_move_velocity.z = move_toward(_move_velocity.z, -dir.z * move_speed, acceleration * delta)
	elif dist <= attack_range:
		_enter_telegraph(dir)
	else:
		_move_velocity.x = move_toward(_move_velocity.x, dir.x * move_speed, acceleration * delta)
		_move_velocity.z = move_toward(_move_velocity.z, dir.z * move_speed, acceleration * delta)

func _on_attack_started() -> void:
	_spawn_enemy_orb()

func _spawn_enemy_orb() -> void:
	var orb := Area3D.new()
	orb.collision_layer = 0
	orb.collision_mask = (1 << 0) | (1 << 2) # Layer 1 (World/Pilares) + Layer 3 (PlayerHurtbox)
	
	var col := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 0.28
	col.shape = sphere_shape
	orb.add_child(col)
	
	var mesh_inst := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.26
	sm.height = 0.52
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.9, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.25, 0.9, 1.0) * 1.4
	mesh_inst.material_override = mat
	mesh_inst.mesh = sm
	orb.add_child(mesh_inst)
	
	get_tree().current_scene.add_child(orb)
	orb.global_position = global_position + Vector3.UP * 1.0 + _attack_direction * 0.9
	
	var dir: Vector3 = _attack_direction
	var spd: float = projectile_speed
	var dmg: float = projectile_damage
	
	orb.area_entered.connect(func(area: Area3D):
		if area is HurtboxComponent and area.get_parent() != self:
			area.apply_hit(dmg, dir * 6.0)
			orb.queue_free()
	)
	orb.body_entered.connect(func(body: Node3D):
		# Bloqueado por paredes ou pelos Pilares de Rocha do jogador!
		if body != self and not body.is_in_group("enemies"):
			orb.queue_free()
	)
	
	# Movimento simples e tempo de vida de 3s
	var life_timer := get_tree().create_timer(3.0)
	life_timer.timeout.connect(func():
		if is_instance_valid(orb):
			orb.queue_free()
	)
	get_tree().process_frame.connect(func():
		if is_instance_valid(orb):
			orb.global_position += dir * spd * get_process_delta_time()
	)

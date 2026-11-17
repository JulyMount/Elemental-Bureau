class_name ElementalComponent
extends Node

signal element_switched(new_element: ElementData)
signal thermal_pressure_changed(current_heat: float, max_heat: float, is_overheated: bool)
signal ultimate_state_changed(is_active: bool)

@export var fire_element: ElementData
@export var earth_element: ElementData
@export var current_element: ElementData

@export_group("Cenas de Habilidades")
@export var fireball_scene: PackedScene
@export var rock_pillar_scene: PackedScene

@export_group("Materiais de Shader VFX")
@export var fire_shader_material: ShaderMaterial
@export var ground_crack_material: ShaderMaterial

# Estado: Fogo
var thermal_pressure: float = 0.0
const MAX_THERMAL_PRESSURE: float = 100.0
var is_overheated: bool = false

# Estado: Terra
const MAX_ACTIVE_PILLARS: int = 3
var _active_pillars: Array[RockPillar] = []

# Estado Geral
var is_ultimate_active: bool = false
var _player: Player
var _effect_timer: float = 0.0

func setup(player_ref: Player) -> void:
	_player = player_ref
	if not current_element and fire_element:
		current_element = fire_element
	if current_element:
		element_switched.emit(current_element)

func switch_element() -> void:
	if is_ultimate_active:
		print("Não é possível trocar de elemento durante a Suprema V4!")
		return
	if current_element == fire_element and earth_element:
		current_element = earth_element
	elif fire_element:
		current_element = fire_element
	
	# Atualiza a cor base sutil do personagem para indicar o elemento ativo
	var body_mesh := _player.get_node_or_null("VisualRoot/BodyMesh") as MeshInstance3D
	if body_mesh and current_element:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = current_element.primary_color
		body_mesh.material_override = mat
	
	element_switched.emit(current_element)
	print("Elemento ativo: ", current_element.element_name)

func _process(delta: float) -> void:
	# Dissipação gradual de Pressão Térmica
	if thermal_pressure > 0.0:
		var decay_rate: float = 25.0 if is_overheated else 6.0
		thermal_pressure = max(0.0, thermal_pressure - decay_rate * delta)
		if is_overheated and thermal_pressure <= 0.0:
			is_overheated = false
		thermal_pressure_changed.emit(thermal_pressure, MAX_THERMAL_PRESSURE, is_overheated)
	
	# Efeitos contínuos durante a Suprema V4
	if is_ultimate_active and _player and current_element:
		_effect_timer -= delta
		if _effect_timer <= 0.0:
			if current_element.element_type == ElementData.ElementType.FIRE:
				_effect_timer = 0.12
				_spawn_fire_patch(_player.global_position, 12.0, 2.0)
			elif current_element.element_type == ElementData.ElementType.EARTH:
				_effect_timer = 0.85
				_trigger_seismic_pulse(_player.global_position, 3.8, 22.0)

# --- ROTEADOR DE HABILIDADES POR ELEMENTO ---

func on_dash_started(start_pos: Vector3) -> void:
	if not current_element:
		return
	if current_element.element_type == ElementData.ElementType.FIRE:
		add_thermal_pressure(10.0)
		for i in range(3):
			if _player:
				_spawn_fire_patch(_player.global_position, 15.0, 2.5)
			await get_tree().create_timer(0.06).timeout
	elif current_element.element_type == ElementData.ElementType.EARTH:
		# Dash Sísmico: empurra inimigos próximos no início e fim do impulso
		_damage_enemies_in_radius(start_pos, 2.4, 15.0, 14.0)
		_spawn_visual_ring(start_pos, 2.4, Color(0.62, 0.42, 0.23, 0.7))

func cast_skill_1(origin: Vector3, aim_dir: Vector3) -> void:
	if not current_element:
		return
	if current_element.element_type == ElementData.ElementType.FIRE:
		_cast_fireball(origin, aim_dir)
	elif current_element.element_type == ElementData.ElementType.EARTH:
		_cast_tectonic_eruption(origin, aim_dir)

func cast_skill_2(origin: Vector3) -> void:
	if not current_element:
		return
	if current_element.element_type == ElementData.ElementType.FIRE:
		_cast_heat_wave(origin)
	elif current_element.element_type == ElementData.ElementType.EARTH:
		_cast_shatter_pillars()

func cast_ultimate() -> void:
	if is_ultimate_active or not current_element:
		return
	if current_element.element_type == ElementData.ElementType.FIRE:
		_cast_living_flame_v4()
	elif current_element.element_type == ElementData.ElementType.EARTH:
		_cast_rock_colossus_v4()

# ==========================================
# KIT DE FOGO
# ==========================================

func add_thermal_pressure(amount: float) -> void:
	if is_overheated:
		return
	thermal_pressure = clamp(thermal_pressure + amount, 0.0, MAX_THERMAL_PRESSURE)
	thermal_pressure_changed.emit(thermal_pressure, MAX_THERMAL_PRESSURE, is_overheated)
	print("Pressão Térmica: ", int(thermal_pressure), "%")
	
	if thermal_pressure >= MAX_THERMAL_PRESSURE:
		is_overheated = true
		print("SOBRECARGA TÉRMICA! Explosão em área e resfriamento!")
		_damage_enemies_in_radius(_player.global_position, 4.0, 65.0)
		_spawn_visual_ring(_player.global_position, 4.0, Color(1.0, 0.2, 0.0, 0.75))

func get_damage_multiplier() -> float:
	if current_element and current_element.element_type == ElementData.ElementType.FIRE:
		return 1.0 + (thermal_pressure / MAX_THERMAL_PRESSURE) * 0.5
	return 1.0

func _cast_fireball(origin: Vector3, aim_dir: Vector3) -> void:
	if not fireball_scene:
		push_warning("FireballScene não atribuída no ElementalComponent!")
		return
	var fb := fireball_scene.instantiate() as FireballProjectile
	get_tree().current_scene.add_child(fb)
	fb.global_position = origin + Vector3(0, 1.0, 0) + aim_dir * 0.8
	fb.direction = aim_dir
	fb.damage = current_element.skill_1_damage * get_damage_multiplier()
	fb.look_at(fb.global_position + aim_dir, Vector3.UP)
	add_thermal_pressure(30.0)

func _cast_heat_wave(origin: Vector3) -> void:
	var heat_ratio: float = maxf(0.25, thermal_pressure / MAX_THERMAL_PRESSURE)
	var radius: float = lerpf(2.5, 5.5, heat_ratio)
	var dmg: float = current_element.skill_2_damage * heat_ratio
	
	print("Onda de Calor! Raio: ", snapped(radius, 0.1), "m | Dano: ", int(dmg))
	_damage_enemies_in_radius(origin, radius, dmg)
	_spawn_visual_ring(origin, radius, Color(1.0, 0.5, 0.0, 0.7))
	
	thermal_pressure = 0.0
	is_overheated = false
	thermal_pressure_changed.emit(thermal_pressure, MAX_THERMAL_PRESSURE, is_overheated)

func _cast_living_flame_v4() -> void:
	is_ultimate_active = true
	ultimate_state_changed.emit(true)
	_player.health_component.is_invulnerable = true
	_player.SPEED *= 1.35
	
	var body_mesh := _player.get_node_or_null("VisualRoot/BodyMesh") as MeshInstance3D
	if body_mesh:
		if fire_shader_material:
			body_mesh.material_override = fire_shader_material
		else:
			var flame_mat := StandardMaterial3D.new()
			flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			flame_mat.albedo_color = Color(1.0, 0.45, 0.0)
			body_mesh.material_override = flame_mat
		
	print("SUPREMA V4 ATIVADA: Corpo de Chama Viva!")
	await get_tree().create_timer(current_element.ultimate_duration).timeout
	
	_restore_player_appearance(body_mesh)
	_player.SPEED /= 1.35
	_player.health_component.is_invulnerable = false
	is_ultimate_active = false
	ultimate_state_changed.emit(false)
	print("Suprema V4 encerrada.")

# ==========================================
# KIT DE TERRA
# ==========================================

func _cast_tectonic_eruption(origin: Vector3, aim_dir: Vector3) -> void:
	if not rock_pillar_scene:
		push_warning("RockPillarScene não atribuída no ElementalComponent!")
		return
	
	# Limpa referências de pilares que já expiraram
	_active_pillars = _active_pillars.filter(func(p): return is_instance_valid(p))
	
	# Se já atingiu o limite de 3 pilares, detona o mais antigo automaticamente
	if _active_pillars.size() >= MAX_ACTIVE_PILLARS:
		var oldest: RockPillar = _active_pillars.pop_front()
		if is_instance_valid(oldest):
			oldest.shatter(true)
	
	var spawn_pos: Vector3 = origin + aim_dir * 2.6
	spawn_pos.y = origin.y
	
	var pillar := rock_pillar_scene.instantiate() as RockPillar
	get_tree().current_scene.add_child(pillar)
	pillar.global_position = spawn_pos
	pillar.shatter_damage = current_element.skill_2_damage
	_active_pillars.append(pillar)
	
	# Dano de impacto ao erguer o pilar do chão
	_damage_enemies_in_radius(spawn_pos, 2.0, current_element.skill_1_damage, 11.0)
	_spawn_visual_ring(spawn_pos, 2.0, Color(0.65, 0.45, 0.25, 0.8))
	print("Erupção Tectônica! Pilares ativos: ", _active_pillars.size(), "/", MAX_ACTIVE_PILLARS)

func _cast_shatter_pillars() -> void:
	_active_pillars = _active_pillars.filter(func(p): return is_instance_valid(p))
	
	if _active_pillars.is_empty():
		print("Estilhaçar: nenhum pilar de rocha ativo no momento!")
		return
	
	var count: int = _active_pillars.size()
	print("ESTILHAÇAR! Detonando ", count, " pilar(es) de rocha!")
	
	for pillar in _active_pillars:
		if is_instance_valid(pillar):
			_spawn_visual_ring(pillar.global_position, pillar.shatter_radius, Color(0.8, 0.55, 0.25, 0.75))
			pillar.shatter(true)
	_active_pillars.clear()
	
	# Hitstop tático na detonação
	Engine.time_scale = 0.08
	await get_tree().create_timer(0.045, true, false, true).timeout
	Engine.time_scale = 1.0

func _cast_rock_colossus_v4() -> void:
	is_ultimate_active = true
	ultimate_state_changed.emit(true)
	_player.health_component.is_invulnerable = true
	
	var visual_root := _player.get_node_or_null("VisualRoot") as Node3D
	var body_mesh := _player.get_node_or_null("VisualRoot/BodyMesh") as MeshInstance3D
	
	var colossus_mat := StandardMaterial3D.new()
	colossus_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	colossus_mat.albedo_color = Color(0.65, 0.45, 0.22)
	if body_mesh:
		body_mesh.material_override = colossus_mat
	if visual_root:
		var grow_tween := visual_root.create_tween()
		grow_tween.tween_property(visual_root, "scale", Vector3.ONE * 1.45, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Pulso inicial forte ao transformar
	_trigger_seismic_pulse(_player.global_position, 4.2, 35.0)
	print("SUPREMA V4 ATIVADA: Colosso de Rocha!")
	
	await get_tree().create_timer(current_element.ultimate_duration).timeout
	
	if visual_root:
		var shrink_tween := visual_root.create_tween()
		shrink_tween.tween_property(visual_root, "scale", Vector3.ONE, 0.2)
	_restore_player_appearance(body_mesh)
	_player.health_component.is_invulnerable = false
	is_ultimate_active = false
	ultimate_state_changed.emit(false)
	print("Colosso de Rocha encerrado.")

func _trigger_seismic_pulse(center: Vector3, radius: float, dmg: float) -> void:
	_damage_enemies_in_radius(center, radius, dmg, 12.0)
	_spawn_visual_ring(center, radius, Color(0.65, 0.45, 0.22, 0.75))

# ==========================================
# AUXILIARES DE DANO E VISUAL
# ==========================================

func _restore_player_appearance(body_mesh: MeshInstance3D) -> void:
	if not body_mesh:
		return
	if current_element:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = current_element.primary_color
		body_mesh.material_override = mat
	else:
		body_mesh.material_override = null

func _damage_enemies_in_radius(center: Vector3, radius: float, dmg: float, knockback_force: float = 10.0) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D:
			var enemy_pos: Vector3 = enemy.global_position
			var flat_dist: float = Vector2(enemy_pos.x, enemy_pos.z).distance_to(Vector2(center.x, center.z))
			if flat_dist <= radius:
				var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
				if hurtbox:
					var push: Vector3 = (enemy_pos - center).normalized() * knockback_force
					hurtbox.apply_hit(dmg, push)

func _spawn_fire_patch(pos: Vector3, dmg_per_tick: float, duration: float) -> void:
	var patch := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.6
	cyl.bottom_radius = 1.6
	cyl.height = 0.25
	patch.mesh = cyl
	
	if fire_shader_material:
		patch.material_override = fire_shader_material
	else:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.25, 0.0, 0.85)
		patch.material_override = mat
	
	get_tree().current_scene.add_child(patch)
	patch.global_position = Vector3(pos.x, pos.y + 0.15, pos.z)
	
	_damage_enemies_in_radius(patch.global_position, 1.7, dmg_per_tick)
	for i in range(2):
		await get_tree().create_timer(duration / 3.0).timeout
		if is_instance_valid(patch):
			_damage_enemies_in_radius(patch.global_position, 1.7, dmg_per_tick)
	
	if is_instance_valid(patch):
		patch.queue_free()

func _spawn_visual_ring(center: Vector3, radius: float, col: Color) -> void:
	# 1. Disco de rachadura no solo (Shader Voronoi)
	var ground_decal := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 2.0, radius * 2.0)
	ground_decal.mesh = plane
	
	if ground_crack_material:
		var mat_inst := ground_crack_material.duplicate() as ShaderMaterial
		mat_inst.set_shader_parameter("crack_core", col.lightened(0.35))
		mat_inst.set_shader_parameter("crack_glow", col)
		ground_decal.material_override = mat_inst
	else:
		var fallback := StandardMaterial3D.new()
		fallback.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fallback.albedo_color = col
		fallback.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ground_decal.material_override = fallback
	
	get_tree().current_scene.add_child(ground_decal)
	ground_decal.global_position = Vector3(center.x, center.y + 0.06, center.z)
	ground_decal.rotation.y = randf() * TAU
	
	var tween := ground_decal.create_tween()
	ground_decal.scale = Vector3(0.25, 1.0, 0.25)
	tween.tween_property(ground_decal, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.35)
	tween.tween_callback(ground_decal.queue_free)
	
	# 2. Coroa de onda de choque 3D procedural
	var crown := MeshInstance3D.new()
	crown.mesh = ProceduralMeshFactory.create_shockwave_crown(radius * 0.55, radius, 0.45, 14)
	var crown_mat := StandardMaterial3D.new()
	crown_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	crown_mat.albedo_color = col.lightened(0.25)
	crown_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	crown.material_override = crown_mat
	
	get_tree().current_scene.add_child(crown)
	crown.global_position = Vector3(center.x, center.y + 0.08, center.z)
	
	var c_tween := crown.create_tween().set_parallel(true)
	crown.scale = Vector3(0.2, 1.0, 0.2)
	c_tween.tween_property(crown, "scale", Vector3(1.05, 0.1, 1.05), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	c_tween.chain().tween_callback(crown.queue_free)

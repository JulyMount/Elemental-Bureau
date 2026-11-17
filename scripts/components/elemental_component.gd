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

@export_range(0.0, 0.015, 0.0002) var v4_heat_distortion_strength: float = 0.0032
@export_range(0.1, 1.5, 0.05) var v4_heat_fade_duration: float = 0.45

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
var _v4_light: OmniLight3D
var _v4_noise := FastNoiseLite.new()
var _v4_time: float = 0.0
var _effect_timer: float = 0.0

func _ready() -> void:
	_v4_noise.seed = randi()
	_v4_noise.frequency = 0.22

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
	if is_instance_valid(_v4_light):
		_v4_time += delta * 14.0
		var n: float = _v4_noise.get_noise_1d(_v4_time)
		_v4_light.light_energy = remap(n, -1.0, 1.0, 2.5, 5.2)

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
	
	var vfx_container := Node3D.new()
	vfx_container.name = "LivingFlameV4VFX"
	_player.add_child(vfx_container)
	
	# 1. Luz dinâmica oscilante iluminando o chão ao redor do player
	_v4_light = OmniLight3D.new()
	_v4_light.light_color = Color(1.0, 0.45, 0.08)
	_v4_light.light_energy = 3.5
	_v4_light.omni_range = 6.0
	_v4_light.position = Vector3(0, 1.1, 0)
	vfx_container.add_child(_v4_light)
	
	# 2. Aura de labaredas orgânicas subindo da base (sem cilindro rígido)
	var aura_flames := GPUParticles3D.new()
	aura_flames.amount = 36
	aura_flames.lifetime = 0.55
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_radius = 0.55
	pm.emission_ring_inner_radius = 0.25
	pm.emission_ring_height = 0.15
	pm.emission_ring_axis = Vector3(0, 1, 0)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 2.2
	pm.initial_velocity_max = 3.6
	pm.gravity = Vector3(0, 1.8, 0)
	pm.orbit_velocity_min = 0.35
	pm.orbit_velocity_max = 0.75
	
	# Curva de escala para afunilar no topo (começa médio -> cresce -> some em ponta)
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.45))
	scale_curve.add_point(Vector2(0.35, 1.0))
	scale_curve.add_point(Vector2(1.0, 0.0))
	var curve_tex := CurveTexture.new()
	curve_tex.curve = scale_curve
	pm.scale_curve = curve_tex
	pm.scale_min = 0.28
	pm.scale_max = 0.48
	
	# Gradiente de cor da chama (amarelo núcleo -> laranja -> vermelho escuro)
	var grad := Gradient.new()
	grad.add_point(0.0, Color(1.0, 0.92, 0.4, 1.0))
	grad.add_point(0.45, Color(1.0, 0.42, 0.05, 0.95))
	grad.add_point(1.0, Color(0.75, 0.1, 0.02, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	pm.color_ramp = grad_tex
	
	aura_flames.process_material = pm
	aura_flames.draw_pass_1 = _create_unshaded_quad(Vector2(0.42, 0.52), Color.WHITE, true)
	# Habilita vertex color para o gradiente funcionar no quad
	(aura_flames.draw_pass_1.material as StandardMaterial3D).vertex_color_use_as_albedo = true
	aura_flames.position = Vector3(0, 0.15, 0)
	vfx_container.add_child(aura_flames)
	
	# 3. Halo suave de Heat Distortion (esfera alongada sem bordas duras)
	if ResourceLoader.exists("res://shaders/heat_distortion.gdshader"):
		var heat_mesh := MeshInstance3D.new()
		var heat_sphere := SphereMesh.new()
		heat_sphere.radius = 0.95
		heat_sphere.height = 2.2
		heat_mesh.mesh = heat_sphere
		heat_mesh.position = Vector3(0, 1.0, 0)
		var heat_mat := ShaderMaterial.new()
		heat_mat.shader = load("res://shaders/heat_distortion.gdshader")
		heat_mat.set_shader_parameter("heat_tint", Color(1.0, 0.5, 0.1, 0.14))
		heat_mesh.material_override = heat_mat
		vfx_container.add_child(heat_mesh)
	
	# 4. Faíscas/brasas soltas subindo ao redor
	var body_sparks := _create_fire_particles(18, 0.65, 0.65, 3.0, Color(1.0, 0.75, 0.2))
	body_sparks.position = Vector3(0, 0.3, 0)
	vfx_container.add_child(body_sparks)
	
	# Burst inicial ao transformar
	StylizedHitVFX.spawn(get_tree(), _player.global_position + Vector3(0, 1.0, 0), Color(1.0, 0.45, 0.05), 1.4)
	
	# 5. Heat Distortion sutil na tela inteira com transição suave (Fade-in / Fade-out)
	var screen_heat_layer: CanvasLayer = null
	var s_mat: ShaderMaterial = null
	if ResourceLoader.exists("res://shaders/screen_heat_distortion.gdshader"):
		screen_heat_layer = CanvasLayer.new()
		screen_heat_layer.layer = 10
		
		var rect := ColorRect.new()
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		s_mat = ShaderMaterial.new()
		s_mat.shader = load("res://shaders/screen_heat_distortion.gdshader")
		s_mat.set_shader_parameter("distortion_strength", v4_heat_distortion_strength)
		s_mat.set_shader_parameter("intensity", 0.0)
		rect.material = s_mat
		
		screen_heat_layer.add_child(rect)
		get_tree().current_scene.add_child(screen_heat_layer)
		
		# Fade-in suave ao ativar a V4
		var fade_in := screen_heat_layer.create_tween()
		fade_in.tween_property(s_mat, "shader_parameter/intensity", 1.0, v4_heat_fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Aguarda a duração descontando o tempo do fade-out final
	var active_time: float = maxf(0.1, current_element.ultimate_duration - v4_heat_fade_duration)
	await get_tree().create_timer(active_time).timeout
	
	# Fade-out suave antes de encerrar a V4
	if is_instance_valid(screen_heat_layer) and s_mat:
		var fade_out := screen_heat_layer.create_tween()
		fade_out.tween_property(s_mat, "shader_parameter/intensity", 0.0, v4_heat_fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await fade_out.finished
	else:
		await get_tree().create_timer(v4_heat_fade_duration).timeout
	
	if is_instance_valid(screen_heat_layer):
		screen_heat_layer.queue_free()
	if is_instance_valid(vfx_container):
		vfx_container.queue_free()
	_v4_light = null
	_player.SPEED /= 1.35
	_player.health_component.is_invulnerable = false
	is_ultimate_active = false
	ultimate_state_changed.emit(false)

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
	var root := Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = pos
	
	# 1. Línguas de fogo 3D cruzadas (substitui o disco achatado)
	for i in range(3):
		var flame_blade := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(1.4, 1.25)
		flame_blade.mesh = quad
		flame_blade.position = Vector3(randf_range(-0.35, 0.35), 0.55, randf_range(-0.35, 0.35))
		flame_blade.rotation_degrees.y = i * 60.0 + randf_range(-15.0, 15.0)
		
		if fire_shader_material:
			var f_mat := fire_shader_material.duplicate() as ShaderMaterial
			f_mat.set_shader_parameter("use_tail_fade", true)
			f_mat.set_shader_parameter("noise_scale", 6.0)
			f_mat.set_shader_parameter("scroll_speed", Vector2(randf_range(-0.3, 0.3), -4.2))
			flame_blade.material_override = f_mat
		root.add_child(flame_blade)
	
	# 2. Faíscas/Brasas subindo + Fumaça escura subindo e girando
	var sparks := _create_fire_particles(14, 0.65, 0.5, 2.2, Color(1.0, 0.65, 0.15))
	root.add_child(sparks)
	
	var smoke := _create_smoke_particles(8, 0.9, 1.1, 1.8)
	smoke.position = Vector3(0, 0.4, 0)
	root.add_child(smoke)
	
	# 3. Luz quente local iluminando o piso
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.40, 0.05)
	light.light_energy = 2.2
	light.omni_range = 3.5
	light.position = Vector3(0, 0.5, 0)
	root.add_child(light)
	
	_damage_enemies_in_radius(pos, 1.7, dmg_per_tick)
	for i in range(2):
		await get_tree().create_timer(duration / 3.0).timeout
		if is_instance_valid(root):
			_damage_enemies_in_radius(pos, 1.7, dmg_per_tick)
	
	if is_instance_valid(root):
		var fade := root.create_tween()
		fade.tween_property(root, "scale", Vector3(0.1, 0.05, 0.1), 0.25)
		await fade.finished
		if is_instance_valid(root):
			root.queue_free()

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
	tween.tween_interval(0.45)
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
	
	# 3. Se for explosão de Fogo: burst radial de chamas + labaredas/fumaça nas rachaduras + flash laranja
	if current_element and current_element.element_type == ElementData.ElementType.FIRE:
		var burst_root := Node3D.new()
		get_tree().current_scene.add_child(burst_root)
		burst_root.global_position = center + Vector3(0, 0.15, 0)
		
		# Burst radial de chamas lançadas para fora
		var radial_fire := GPUParticles3D.new()
		radial_fire.emitting = true
		radial_fire.one_shot = true
		radial_fire.explosiveness = 0.95
		radial_fire.amount = 22
		radial_fire.lifetime = 0.38
		var r_mat := ParticleProcessMaterial.new()
		r_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		r_mat.emission_ring_radius = radius * 0.35
		r_mat.emission_ring_inner_radius = 0.1
		r_mat.emission_ring_height = 0.1
		r_mat.emission_ring_axis = Vector3(0, 1, 0)
		r_mat.direction = Vector3(0, 0.35, 0)
		r_mat.spread = 85.0
		r_mat.initial_velocity_min = radius * 1.4
		r_mat.initial_velocity_max = radius * 2.4
		r_mat.gravity = Vector3(0, 1.5, 0)
		r_mat.scale_min = 0.25
		r_mat.scale_max = 0.45
		r_mat.color = Color(1.0, 0.50, 0.08)
		radial_fire.process_material = r_mat
		radial_fire.draw_pass_1 = _create_unshaded_quad(Vector2(0.45, 0.45), Color(1.0, 0.55, 0.1))
		burst_root.add_child(radial_fire)
		
		# Labaredas e fumaça escura subindo pelas rachaduras
		var crack_flames := _create_fire_particles(16, radius * 0.65, 0.6, 2.8, Color(1.0, 0.45, 0.05), true)
		burst_root.add_child(crack_flames)
		
		var crack_smoke := _create_smoke_particles(12, radius * 0.65, 0.9, 2.2, true)
		burst_root.add_child(crack_smoke)
		
		# Flash de luz laranja no impacto
		var flash := OmniLight3D.new()
		flash.light_color = Color(1.0, 0.45, 0.08)
		flash.light_energy = 6.5
		flash.omni_range = radius * 2.2
		flash.position = Vector3(0, 0.6, 0)
		burst_root.add_child(flash)
		
		var l_tween := flash.create_tween()
		l_tween.tween_property(flash, "light_energy", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		await get_tree().create_timer(1.1).timeout
		if is_instance_valid(burst_root):
			burst_root.queue_free()

func _create_fire_particles(amount: int, spawn_radius: float, lifetime: float, up_vel: float, col: Color, one_shot: bool = false) -> GPUParticles3D:
	var gp := GPUParticles3D.new()
	gp.amount = amount
	gp.lifetime = lifetime
	gp.one_shot = one_shot
	gp.explosiveness = 0.85 if one_shot else 0.0
	
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = spawn_radius
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 22.0
	pm.initial_velocity_min = up_vel * 0.7
	pm.initial_velocity_max = up_vel * 1.2
	pm.gravity = Vector3(0, 1.2, 0)
	pm.scale_min = 0.14
	pm.scale_max = 0.30
	pm.color = col
	gp.process_material = pm
	gp.draw_pass_1 = _create_unshaded_quad(Vector2(0.32, 0.32), col)
	return gp

func _create_smoke_particles(amount: int, spawn_radius: float, lifetime: float, up_vel: float, one_shot: bool = false) -> GPUParticles3D:
	var gp := GPUParticles3D.new()
	gp.amount = amount
	gp.lifetime = lifetime
	gp.one_shot = one_shot
	gp.explosiveness = 0.80 if one_shot else 0.0
	
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = spawn_radius
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 28.0
	pm.initial_velocity_min = up_vel * 0.6
	pm.initial_velocity_max = up_vel * 1.1
	pm.gravity = Vector3(0, 0.8, 0)
	pm.angular_velocity_min = -90.0
	pm.angular_velocity_max = 90.0
	pm.scale_min = 0.25
	pm.scale_max = 0.48
	pm.color = Color(0.16, 0.14, 0.14, 0.75)
	gp.process_material = pm
	gp.draw_pass_1 = _create_unshaded_quad(Vector2(0.45, 0.45), Color(0.18, 0.15, 0.15, 0.72), true)
	return gp

func _create_unshaded_quad(size: Vector2, col: Color, use_alpha: bool = false) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = col
	if use_alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	return q

class_name ElementalComponent
extends Node

signal thermal_pressure_changed(current_heat: float, max_heat: float, is_overheated: bool)
signal ultimate_state_changed(is_active: bool)

@export var current_element: ElementData
@export var fireball_scene: PackedScene

var thermal_pressure: float = 0.0
const MAX_THERMAL_PRESSURE: float = 100.0
var is_overheated: bool = false
var is_ultimate_active: bool = false

var _player: Player
var _trail_timer: float = 0.0

func setup(player_ref: Player) -> void:
	_player = player_ref

func _process(delta: float) -> void:
	if thermal_pressure > 0.0:
		var decay_rate: float = 25.0 if is_overheated else 6.0
		thermal_pressure = max(0.0, thermal_pressure - decay_rate * delta)
		if is_overheated and thermal_pressure <= 0.0:
			is_overheated = false
		thermal_pressure_changed.emit(thermal_pressure, MAX_THERMAL_PRESSURE, is_overheated)
	
	if is_ultimate_active and _player:
		_trail_timer -= delta
		if _trail_timer <= 0.0:
			_trail_timer = 0.12
			_spawn_fire_patch(_player.global_position, 12.0, 2.0)

func add_thermal_pressure(amount: float) -> void:
	if is_overheated:
		return
	thermal_pressure = clamp(thermal_pressure + amount, 0.0, MAX_THERMAL_PRESSURE)
	thermal_pressure_changed.emit(thermal_pressure, MAX_THERMAL_PRESSURE, is_overheated)
	print("Pressão Térmica: ", int(thermal_pressure), "%")
	
	if thermal_pressure >= MAX_THERMAL_PRESSURE:
		_trigger_thermal_overload()

func _trigger_thermal_overload() -> void:
	is_overheated = true
	print("SOBRECARGA TÉRMICA! Explosão em área e resfriamento!")
	_damage_enemies_in_radius(_player.global_position, 4.0, 65.0)
	_spawn_visual_ring(_player.global_position, 4.0, Color(1.0, 0.2, 0.0, 0.75))

func get_damage_multiplier() -> float:
	return 1.0 + (thermal_pressure / MAX_THERMAL_PRESSURE) * 0.5

# --- HABILIDADES DE FOGO ---

func on_dash_started(start_pos: Vector3) -> void:
	add_thermal_pressure(10.0)
	for i in range(3):
		if _player:
			_spawn_fire_patch(_player.global_position, 15.0, 2.5)
		await get_tree().create_timer(0.06).timeout

func cast_skill_1(origin: Vector3, aim_dir: Vector3) -> void:
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

func cast_skill_2(origin: Vector3) -> void:
	var heat_ratio: float = maxf(0.25, thermal_pressure / MAX_THERMAL_PRESSURE)
	var radius: float = lerpf(2.5, 5.5, heat_ratio)
	var dmg: float = current_element.skill_2_damage * heat_ratio
	
	print("Onda de Calor! Raio: ", snapped(radius, 0.1), "m | Dano: ", int(dmg))
	_damage_enemies_in_radius(origin, radius, dmg)
	_spawn_visual_ring(origin, radius, Color(1.0, 0.5, 0.0, 0.7))
	
	thermal_pressure = 0.0
	is_overheated = false
	thermal_pressure_changed.emit(thermal_pressure, MAX_THERMAL_PRESSURE, is_overheated)

func cast_ultimate() -> void:
	if is_ultimate_active:
		return
	is_ultimate_active = true
	ultimate_state_changed.emit(true)
	_player.health_component.is_invulnerable = true
	_player.SPEED *= 1.35
	
	var body_mesh := _player.get_node_or_null("VisualRoot/BodyMesh") as MeshInstance3D
	var flame_mat := StandardMaterial3D.new()
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.albedo_color = Color(1.0, 0.45, 0.0)
	if body_mesh:
		body_mesh.material_override = flame_mat
		
	print("SUPREMA V4 ATIVADA: Corpo de Chama Viva!")
	
	await get_tree().create_timer(current_element.ultimate_duration).timeout
	
	if body_mesh:
		body_mesh.material_override = null
	_player.SPEED /= 1.35
	_player.health_component.is_invulnerable = false
	is_ultimate_active = false
	ultimate_state_changed.emit(false)
	print("Suprema V4 encerrada.")

# --- AUXILIARES DE DANO E VISUAL ---

func _damage_enemies_in_radius(center: Vector3, radius: float, dmg: float) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D:
			var enemy_pos: Vector3 = enemy.global_position
			var flat_dist: float = Vector2(enemy_pos.x, enemy_pos.z).distance_to(Vector2(center.x, center.z))
			if flat_dist <= radius:
				var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
				if hurtbox:
					var push: Vector3 = (enemy_pos - center).normalized() * 10.0
					hurtbox.apply_hit(dmg, push)

func _spawn_fire_patch(pos: Vector3, dmg_per_tick: float, duration: float) -> void:
	var patch := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.6
	cyl.bottom_radius = 1.6
	cyl.height = 0.25
	patch.mesh = cyl
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.25, 0.0, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
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
	var ring := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.35
	ring.mesh = cyl
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat
	
	get_tree().current_scene.add_child(ring)
	ring.global_position = Vector3(center.x, center.y + 0.2, center.z)
	
	var tween := ring.create_tween()
	ring.scale = Vector3(0.1, 1.0, 0.1)
	tween.tween_property(ring, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(ring.queue_free)

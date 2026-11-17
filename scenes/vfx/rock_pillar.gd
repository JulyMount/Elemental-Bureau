class_name RockPillar
extends StaticBody3D

@export var max_lifetime: float = 10.0
@export var shatter_radius: float = 3.5
@export var explosion_force: float = 6.2
@export var upward_force: float = 4.8
@export var persist_debris: bool = true # Deixe false para os escombros sumirem após debris_lifetime
@export var physics_freeze_delay: float = 4.0 # Tempo até congelar a física e colisão dos estilhaços
@export var debris_lifetime: float = 4.0
@export var max_world_debris: int = 120 # Limite de segurança para manter o FPS alto

var shatter_damage: float = 55.0
var _is_shattered: bool = false

func _ready() -> void:
	add_to_group("earth_pillars")
	
	# Substitui o cubo placeholder por uma estalagmite facetada única preservando o material original
	var mesh_inst := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_inst:
		var saved_mat: Material = mesh_inst.get_active_material(0)
		mesh_inst.position.y = 0.0
		mesh_inst.mesh = ProceduralMeshFactory.create_faceted_pillar(0.65, 2.4, 5, randi())
		if saved_mat:
			mesh_inst.material_override = saved_mat
		rotation.y = randf_range(0.0, TAU)
	
	# Variação sutil de porte e inclinação ao romper o solo
	var target_scale := Vector3(
		randf_range(0.90, 1.15),
		randf_range(0.88, 1.18),
		randf_range(0.90, 1.15)
	)
	rotation.x = randf_range(-0.07, 0.07)
	rotation.z = randf_range(-0.07, 0.07)
	
	scale = Vector3(target_scale.x, 0.05, target_scale.z)
	var tween := create_tween()
	tween.tween_property(self, "scale", target_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	_spawn_pillar_dust(global_position, 14, 3.2)
	
	await get_tree().create_timer(max_lifetime).timeout
	if not _is_shattered and is_instance_valid(self):
		shatter(false)

func shatter(deal_damage: bool = true) -> void:
	if _is_shattered:
		return
	_is_shattered = true
	remove_from_group("earth_pillars")
	
	var origin: Vector3 = global_position
	
	# Impacto estilizado de terra/âmbar + poeira radial
	StylizedHitVFX.spawn(get_tree(), origin + Vector3(0, 1.0, 0), Color(0.88, 0.62, 0.28), 1.2)
	_spawn_pillar_dust(origin, 20, 4.8)
	
	if deal_damage:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy is Node3D:
				var enemy_pos: Vector3 = enemy.global_position
				var flat_dist: float = Vector2(enemy_pos.x, enemy_pos.z).distance_to(Vector2(origin.x, origin.z))
				if flat_dist <= shatter_radius:
					var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
					if hurtbox:
						var push: Vector3 = (enemy_pos - origin).normalized() * 12.0
						hurtbox.apply_hit(shatter_damage, push)
	
	# Estilhaços angulares procedurais (create_rock_shard) com física RigidBody3D quicando no chão
	_spawn_rigid_shards(origin)
	
	queue_free()

func _spawn_rigid_shards(origin: Vector3) -> void:
	var container := Node3D.new()
	container.name = "RockShardsContainer"
	get_tree().current_scene.add_child(container)
	container.global_position = origin
	
	# Usa o mesmo material castanho original do pilar
	var shard_mat: Material = null
	var mesh_inst := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_inst:
		shard_mat = mesh_inst.get_active_material(0)
	if not shard_mat:
		var std := StandardMaterial3D.new()
		std.albedo_color = Color(0.62, 0.42, 0.23)
		shard_mat = std
	
	var shard_count: int = 8
	for i in range(shard_count):
		var rb := RigidBody3D.new()
		rb.mass = 1.5
		rb.linear_damp = 0.85
		rb.physics_material_override = PhysicsMaterial.new()
		rb.physics_material_override.bounce = 0.25
		rb.physics_material_override.friction = 0.90
		rb.collision_layer = 0
		rb.collision_mask = 1
		
		var angle: float = (TAU / float(shard_count)) * i + randf_range(-0.28, 0.28)
		var height_offset: float = randf_range(0.35, 1.95)
		var radial_offset: float = randf_range(0.12, 0.35)
		rb.position = Vector3(cos(angle) * radial_offset, height_offset, sin(angle) * radial_offset)
		rb.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		
		var chunk := MeshInstance3D.new()
		chunk.mesh = ProceduralMeshFactory.create_rock_shard(randf_range(0.32, 0.52), randi())
		chunk.material_override = shard_mat
		rb.add_child(chunk)
		
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.22
		col.shape = shape
		rb.add_child(col)
		
		container.add_child(rb)
		
		var out_dir := Vector3(cos(angle), 0.35, sin(angle)).normalized()
		var impulse: Vector3 = (out_dir * explosion_force * randf_range(0.75, 1.15)) + (Vector3.UP * upward_force * randf_range(0.85, 1.25))
		rb.apply_central_impulse(impulse)
		rb.apply_torque_impulse(Vector3(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)))
	
	_cleanup_shards(container)

func _cleanup_shards(container: Node3D) -> void:
	var tree := get_tree()
	container.add_to_group("earth_debris_clusters")
	
	# Limite de segurança para nunca pesar no FPS em lutas longas
	var clusters := tree.get_nodes_in_group("earth_debris_clusters")
	if clusters.size() * 8 > max_world_debris and clusters.size() > 1:
		var oldest := clusters[0] as Node3D
		if is_instance_valid(oldest) and oldest != container:
			oldest.queue_free()
	
	# Captura os valores dos @export antes do RockPillar ser destruído
	var should_persist: bool = persist_debris
	var life_time: float = debris_lifetime
	
	# 1. Após physics_freeze_delay (4s), congela a física e desativa colisões
	tree.create_timer(physics_freeze_delay).timeout.connect(func() -> void:
		if not is_instance_valid(container):
			return
		for child in container.get_children():
			if child is RigidBody3D:
				child.freeze = true
				child.collision_layer = 0
				child.collision_mask = 0
				var col := child.get_node_or_null("CollisionShape3D") as CollisionShape3D
				if col:
					col.disabled = true
	)
	
	# 2. Se persist_debris estiver desmarcado, encolhe e apaga após debris_lifetime
	if not should_persist:
		tree.create_timer(life_time).timeout.connect(func() -> void:
			if not is_instance_valid(container):
				return
			var tween := container.create_tween().set_parallel(true)
			for child in container.get_children():
				if child is RigidBody3D:
					tween.tween_property(child, "scale", Vector3.ZERO, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.chain().tween_callback(container.queue_free)
		)

func _spawn_pillar_dust(pos: Vector3, amount: int, speed: float) -> void:
	var dust := GPUParticles3D.new()
	dust.emitting = true
	dust.one_shot = true
	dust.explosiveness = 0.92
	dust.amount = amount
	dust.lifetime = 0.50
	
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_radius = 0.65
	pm.emission_ring_inner_radius = 0.15
	pm.emission_ring_height = 0.1
	pm.emission_ring_axis = Vector3(0, 1, 0)
	pm.direction = Vector3(0, 0.45, 0)
	pm.spread = 75.0
	pm.initial_velocity_min = speed * 0.6
	pm.initial_velocity_max = speed * 1.15
	pm.gravity = Vector3(0, -6.0, 0)
	pm.angular_velocity_min = -120.0
	pm.angular_velocity_max = 120.0
	pm.scale_min = 0.22
	pm.scale_max = 0.46
	pm.color = Color(0.58, 0.45, 0.34, 0.82)
	dust.process_material = pm
	
	var quad := QuadMesh.new()
	quad.size = Vector2(0.45, 0.45)
	var q_mat := StandardMaterial3D.new()
	q_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	q_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q_mat.albedo_color = Color(0.58, 0.46, 0.35, 0.80)
	quad.material = q_mat
	dust.draw_pass_1 = quad
	
	get_tree().current_scene.add_child(dust)
	dust.global_position = pos + Vector3(0, 0.15, 0)
	
	await get_tree().create_timer(0.70).timeout
	if is_instance_valid(dust):
		dust.queue_free()

class_name StylizedHitVFX
extends Node3D

static func spawn(tree: SceneTree, pos: Vector3, hit_color: Color = Color(1.0, 0.65, 0.15), scale_mult: float = 1.0) -> void:
	if not tree or not tree.current_scene:
		return
	
	var root := Node3D.new()
	tree.current_scene.add_child(root)
	root.global_position = pos
	root.scale = Vector3.ONE * scale_mult
	
	# 1. HitStar (Estrela estilizada com fade suave de opacidade e escala)
	var star := MeshInstance3D.new()
	star.mesh = ProceduralMeshFactory.create_hit_star(1.15, 0.20, 4)
	var star_mat := StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	star_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	star_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	star_mat.albedo_color = hit_color.lightened(0.45)
	star.material_override = star_mat
	root.add_child(star)
	star.rotation.z = randf() * TAU
	
	# 2. ShockwaveRing (Coroa de impacto que expande e desaparece suavemente)
	var ring := MeshInstance3D.new()
	ring.mesh = ProceduralMeshFactory.create_shockwave_crown(0.25, 0.90, 0.25, 10)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.albedo_color = hit_color
	ring.material_override = ring_mat
	root.add_child(ring)
	
	# 3. SparkDots (Faíscas que continuam caindo após o flash)
	var sparks := GPUParticles3D.new()
	sparks.emitting = true
	sparks.one_shot = true
	sparks.explosiveness = 0.92
	sparks.amount = 14
	sparks.lifetime = 0.45
	
	var p_mat := ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0, 1, 0)
	p_mat.spread = 180.0
	p_mat.initial_velocity_min = 3.5
	p_mat.initial_velocity_max = 7.5
	p_mat.gravity = Vector3(0, -11.0, 0)
	p_mat.scale_min = 0.08
	p_mat.scale_max = 0.16
	p_mat.color = hit_color.lightened(0.35)
	sparks.process_material = p_mat
	
	var quad := QuadMesh.new()
	quad.size = Vector2(0.18, 0.18)
	var q_mat := StandardMaterial3D.new()
	q_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	q_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q_mat.albedo_color = hit_color.lightened(0.4)
	quad.material = q_mat
	sparks.draw_pass_1 = quad
	root.add_child(sparks)
	
	# 4. OmniLight3D com atenuação gradual
	var flash_light := OmniLight3D.new()
	flash_light.light_color = hit_color
	flash_light.light_energy = 4.5
	flash_light.omni_range = 4.5
	root.add_child(flash_light)
	
	# Animação de impacto rápido + dissipação suave (Ease Out Cubic)
	var tween := root.create_tween().set_parallel(true)
	
	star.scale = Vector3.ONE * 0.25
	tween.tween_property(star, "scale", Vector3.ONE * 1.30, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(star, "rotation:z", star.rotation.z + 0.65, 0.40).set_ease(Tween.EASE_OUT)
	tween.tween_property(star_mat, "albedo_color:a", 0.0, 0.34).set_delay(0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(star, "scale", Vector3.ONE * 0.4, 0.30).set_delay(0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	ring.scale = Vector3(0.2, 1.0, 0.2)
	tween.tween_property(ring, "scale", Vector3(1.6, 0.05, 1.6), 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring_mat, "albedo_color:a", 0.0, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(flash_light, "light_energy", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	await tree.create_timer(0.50).timeout
	if is_instance_valid(root):
		root.queue_free()

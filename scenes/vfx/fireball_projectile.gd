class_name FireballProjectile
extends Area3D

@export var speed: float = 20.0
@export var max_lifetime: float = 2.5
@export var fire_material: ShaderMaterial

var damage: float = 25.0
var direction: Vector3 = Vector3.FORWARD

var _noise := FastNoiseLite.new()
var _time_acc: float = 0.0
var _omni_light: OmniLight3D

func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 0.2
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	_setup_vfx_hierarchy()
	
	await get_tree().create_timer(max_lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func _setup_vfx_hierarchy() -> void:
	var base_mat: ShaderMaterial = fire_material
	if not base_mat and ResourceLoader.exists("res://shaders/fire_mat.tres"):
		base_mat = load("res://shaders/fire_mat.tres") as ShaderMaterial
	
	# 1. FireCore (Núcleo principal com shader de fogo)
	var core_mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if core_mesh and base_mat:
		core_mesh.material_override = base_mat
	
	# 2. FireTrail (Cone alongado atrás do projétil com fade na ponta)
	var trail := MeshInstance3D.new()
	trail.name = "FireTrail"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.02
	cone.bottom_radius = 0.34
	cone.height = 1.45
	cone.radial_segments = 12
	trail.mesh = cone
	trail.rotation_degrees.x = 90.0
	trail.position = Vector3(0.0, 0.0, 0.72)
	if base_mat:
		var trail_mat := base_mat.duplicate() as ShaderMaterial
		trail_mat.set_shader_parameter("use_tail_fade", true)
		trail_mat.set_shader_parameter("scroll_speed", Vector2(0.0, -5.0))
		trail.material_override = trail_mat
	add_child(trail)
	
	# 3. Embers (GPUParticles3D de faíscas deixadas no rastro)
	var embers := GPUParticles3D.new()
	embers.name = "Embers"
	embers.amount = 18
	embers.lifetime = 0.35
	var p_mat := ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	p_mat.emission_sphere_radius = 0.22
	p_mat.direction = Vector3(0, 0.2, 1)
	p_mat.spread = 25.0
	p_mat.initial_velocity_min = 1.5
	p_mat.initial_velocity_max = 3.5
	p_mat.gravity = Vector3(0, 1.2, 0)
	p_mat.scale_min = 0.06
	p_mat.scale_max = 0.14
	p_mat.color = Color(1.0, 0.75, 0.2)
	embers.process_material = p_mat
	
	var quad := QuadMesh.new()
	quad.size = Vector2(0.14, 0.14)
	var q_mat := StandardMaterial3D.new()
	q_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	q_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q_mat.albedo_color = Color(1.0, 0.65, 0.1)
	quad.material = q_mat
	embers.draw_pass_1 = quad
	add_child(embers)
	
	# 4. OmniLight3D pulsante acompanhando o projétil
	_omni_light = OmniLight3D.new()
	_omni_light.light_color = Color(1.0, 0.45, 0.1)
	_omni_light.light_energy = 2.8
	_omni_light.omni_range = 4.0
	add_child(_omni_light)
	
	# 5. VisibleOnScreenNotifier3D (Limpeza automática fora da câmera)
	var notifier := VisibleOnScreenNotifier3D.new()
	notifier.screen_exited.connect(queue_free)
	add_child(notifier)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	if direction.length_squared() > 0.001:
		look_at(global_position + direction, Vector3.UP)
	
	# Oscilação natural da luz via FastNoiseLite
	if _omni_light:
		_time_acc += delta * 14.0
		var n: float = _noise.get_noise_1d(_time_acc)
		_omni_light.light_energy = remap(n, -1.0, 1.0, 2.0, 4.2)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		return
	_trigger_impact()

func _on_area_entered(area: Area3D) -> void:
	if area is HurtboxComponent:
		if area.get_parent().is_in_group("player"):
			return
		area.apply_hit(damage, direction * 6.0)
		_trigger_impact()

func _trigger_impact() -> void:
	StylizedHitVFX.spawn(get_tree(), global_position, Color(1.0, 0.48, 0.08), 1.0)
	queue_free()

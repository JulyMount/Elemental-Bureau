class_name FireballProjectile
extends Area3D

@export var speed: float = 16.0
@export var max_lifetime: float = 2.0
@export var explosion_radius: float = 2.8

var damage: float = 45.0
var direction: Vector3 = Vector3.FORWARD
var _has_exploded: bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Auto-destruição após o tempo máximo de alcance
	await get_tree().create_timer(max_lifetime).timeout
	if not _has_exploded:
		_explode()

func _physics_process(delta: float) -> void:
	if not _has_exploded:
		global_position += direction * speed * delta

func _on_area_entered(area: Area3D) -> void:
	if area is HurtboxComponent:
		_explode()

func _on_body_entered(body: Node3D) -> void:
	if not body is Player:
		_explode()

func _explode() -> void:
	if _has_exploded:
		return
	_has_exploded = true
	
	var hit_any: bool = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D:
			var enemy_pos: Vector3 = enemy.global_position
			var flat_dist: float = Vector2(enemy_pos.x, enemy_pos.z).distance_to(Vector2(global_position.x, global_position.z))
			if flat_dist <= explosion_radius:
				var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
				if hurtbox:
					var push_dir: Vector3 = (enemy_pos - global_position).normalized() * 8.0
					hurtbox.apply_hit(damage, push_dir)
					hit_any = true
	
	# Efeito visual de explosão (esfera unshaded bem visível no shader pixel art)
	var blast := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = explosion_radius
	sphere.height = explosion_radius * 2.0
	blast.mesh = sphere
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.45, 0.05, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blast.material_override = mat
	
	get_tree().current_scene.add_child(blast)
	blast.global_position = global_position
	
	var tween := blast.create_tween()
	blast.scale = Vector3.ONE * 0.25
	tween.tween_property(blast, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.12)
	tween.tween_callback(blast.queue_free)
	
	# Micro-hitstop quando acerta algum alvo
	if hit_any:
		Engine.time_scale = 0.08
		await get_tree().create_timer(0.035, true, false, true).timeout
		Engine.time_scale = 1.0
	
	queue_free()

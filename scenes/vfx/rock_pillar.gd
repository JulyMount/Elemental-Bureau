class_name RockPillar
extends StaticBody3D

@export var max_lifetime: float = 10.0
@export var shatter_radius: float = 3.5

var shatter_damage: float = 55.0
var _is_shattered: bool = false

func _ready() -> void:
	add_to_group("earth_pillars")
	
	# Animação rápida de emergir do solo
	scale = Vector3(1.0, 0.05, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Auto-destruição suave se não for estilhaçado antes
	await get_tree().create_timer(max_lifetime).timeout
	if not _is_shattered and is_instance_valid(self):
		shatter(false)

func shatter(deal_damage: bool = true) -> void:
	if _is_shattered:
		return
	_is_shattered = true
	remove_from_group("earth_pillars")
	
	if deal_damage:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy is Node3D:
				var enemy_pos: Vector3 = enemy.global_position
				var flat_dist: float = Vector2(enemy_pos.x, enemy_pos.z).distance_to(Vector2(global_position.x, global_position.z))
				if flat_dist <= shatter_radius:
					var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
					if hurtbox:
						var push: Vector3 = (enemy_pos - global_position).normalized() * 12.0
						hurtbox.apply_hit(shatter_damage, push)
	
	# Estilhaços visuais voando para os lados (baseado no guia de fratura 3D)
	for i in range(6):
		var chunk := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.45, 0.45, 0.45)
		chunk.mesh = box
		
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.55, 0.38, 0.22)
		chunk.material_override = mat
		
		get_tree().current_scene.add_child(chunk)
		chunk.global_position = global_position + Vector3(0, 1.0, 0)
		
		var angle: float = (TAU / 6.0) * i
		var target_pos: Vector3 = chunk.global_position + Vector3(cos(angle) * 2.5, -0.8, sin(angle) * 2.5)
		var c_tween := chunk.create_tween().set_parallel(true)
		c_tween.tween_property(chunk, "global_position", target_pos, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		c_tween.tween_property(chunk, "scale", Vector3.ZERO, 0.28)
		c_tween.chain().tween_callback(chunk.queue_free)
	
	queue_free()

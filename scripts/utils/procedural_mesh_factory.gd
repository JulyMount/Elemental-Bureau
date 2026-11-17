class_name ProceduralMeshFactory
extends RefCounted

## Gera um pilar monolítico de blocos de rocha empilhados com alta variação procedural
static func create_faceted_pillar(radius: float = 0.65, height: float = 2.4, segments: int = 5, seed_offset: int = 0) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_offset)
	
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var actual_segments: int = clampi(segments + rng.randi_range(-1, 1), 3, 7)
	var current_y: float = 0.0
	var seg_height: float = height / float(actual_segments)
	
	var drift_x: float = 0.0
	var drift_z: float = 0.0
	
	for s in range(actual_segments):
		var h: float = seg_height * rng.randf_range(0.75, 1.30)
		if s == actual_segments - 1:
			h = maxf(0.32, height - current_y)
		
		drift_x = clampf(drift_x + rng.randf_range(-0.08, 0.08), -0.16, 0.16)
		drift_z = clampf(drift_z + rng.randf_range(-0.08, 0.08), -0.16, 0.16)
		
		var step_factor: float = rng.randf_range(0.78, 1.18)
		var base_flare: float = 1.18 if s == 0 else 1.0
		var top_taper: float = 0.80 if s == actual_segments - 1 else 1.0
		
		var r_bot: float = radius * step_factor * base_flare * rng.randf_range(0.90, 1.10)
		var r_top: float = radius * step_factor * top_taper * rng.randf_range(0.82, 1.05)
		var sides: int = rng.randi_range(5, 8)
		var rot_offset: float = rng.randf_range(0.0, TAU)
		var tilt := Vector2(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.12, 0.12))
		
		_add_rock_block(st, Vector3(drift_x, current_y, drift_z), r_bot, r_top, h, sides, rot_offset, tilt, rng)
		current_y += h * rng.randf_range(0.88, 0.96)
	
	var base_rocks: int = rng.randi_range(2, 5)
	for b in range(base_rocks):
		var angle: float = (TAU / float(base_rocks)) * b + rng.randf_range(-0.55, 0.55)
		var dist: float = radius * rng.randf_range(0.75, 1.10)
		var base_pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		var rock_r: float = radius * rng.randf_range(0.28, 0.48)
		var rock_h: float = height * rng.randf_range(0.10, 0.24)
		var rock_tilt := Vector2(rng.randf_range(-0.2, 0.2), rng.randf_range(-0.2, 0.2))
		_add_rock_block(st, base_pos, rock_r, rock_r * 0.65, rock_h, rng.randi_range(5, 6), rng.randf() * TAU, rock_tilt, rng)
	
	st.generate_normals()
	return st.commit()

## Gera uma malha em forma de estrela estilizada 3D para flashes de impacto (HitStar)
static func create_hit_star(outer_radius: float = 1.1, inner_radius: float = 0.22, points: int = 4) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var center := Vector3.ZERO
	var total: int = points * 2
	for i in range(total):
		var next: int = (i + 1) % total
		var a0: float = (TAU / float(total)) * i
		var a1: float = (TAU / float(total)) * next
		var r0: float = outer_radius if i % 2 == 0 else inner_radius
		var r1: float = outer_radius if next % 2 == 0 else inner_radius
		
		var p0 := Vector3(cos(a0) * r0, sin(a0) * r0, 0.0)
		var p1 := Vector3(cos(a1) * r1, sin(a1) * r1, 0.0)
		_add_tri(st, center, p0, p1, Vector2(0.5, 0.5), Vector2(1.0, 0.5), Vector2(1.0, 1.0))
	
	st.generate_normals()
	return st.commit()

static func _add_rock_block(st: SurfaceTool, center: Vector3, r_bot: float, r_top: float, h: float, sides: int, rot_offset: float, tilt: Vector2, rng: RandomNumberGenerator) -> void:
	var bot_ring: Array[Vector3] = []
	var top_ring: Array[Vector3] = []
	
	for i in range(sides):
		var angle: float = rot_offset + (TAU / float(sides)) * i + rng.randf_range(-0.18, 0.18)
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		
		var height_tilt: float = (dir.x * tilt.x + dir.z * tilt.y) * h
		var local_h: float = h * rng.randf_range(0.88, 1.08) + height_tilt
		
		bot_ring.append(center + dir * (r_bot * rng.randf_range(0.80, 1.20)))
		top_ring.append(center + dir * (r_top * rng.randf_range(0.78, 1.18)) + Vector3(0, local_h, 0))
	
	var top_center := center + Vector3(rng.randf_range(-0.08, 0.08), h * rng.randf_range(0.96, 1.06), rng.randf_range(-0.08, 0.08))
	
	for i in range(sides):
		var next: int = (i + 1) % sides
		var u0: float = float(i) / float(sides)
		var u1: float = float(i + 1) / float(sides)
		
		_add_quad(st, bot_ring[i], bot_ring[next], top_ring[next], top_ring[i], u0, u1, 0.0, 1.0)
		_add_tri(st, top_ring[i], top_ring[next], top_center, Vector2(u0, 1.0), Vector2(u1, 1.0), Vector2(0.5, 1.0))

## Gera um estilhaço angular assimétrico
static func create_rock_shard(size: float = 0.42, seed_offset: int = 0) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_offset)
	
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var top := Vector3(0, size * rng.randf_range(0.8, 1.2), 0)
	var bottom := Vector3(0, -size * rng.randf_range(0.7, 1.1), 0)
	var ring: Array[Vector3] = []
	
	for i in range(4):
		var angle: float = (TAU / 4.0) * i + rng.randf_range(-0.25, 0.25)
		var r: float = size * rng.randf_range(0.6, 1.0)
		ring.append(Vector3(cos(angle) * r, rng.randf_range(-0.15, 0.15) * size, sin(angle) * r))
	
	for i in range(4):
		var next: int = (i + 1) % 4
		_add_tri(st, ring[i], ring[next], top, Vector2(0, 0.5), Vector2(1, 0.5), Vector2(0.5, 1.0))
		_add_tri(st, ring[next], ring[i], bottom, Vector2(1, 0.5), Vector2(0, 0.5), Vector2(0.5, 0.0))
	
	st.generate_normals()
	return st.commit()

## Gera uma coroa de ondas radiais 3D para impactos em área
static func create_shockwave_crown(inner_radius: float = 0.6, outer_radius: float = 1.0, height: float = 0.45, spikes: int = 12) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var total_pts: int = spikes * 2
	for i in range(total_pts):
		var next: int = (i + 1) % total_pts
		var a0: float = (TAU / total_pts) * i
		var a1: float = (TAU / total_pts) * next
		
		var h0: float = height if i % 2 == 0 else height * 0.35
		var h1: float = height if next % 2 == 0 else height * 0.35
		
		var in0 := Vector3(cos(a0) * inner_radius, 0.0, sin(a0) * inner_radius)
		var in1 := Vector3(cos(a1) * inner_radius, 0.0, sin(a1) * inner_radius)
		var out0 := Vector3(cos(a0) * outer_radius, h0, sin(a0) * outer_radius)
		var out1 := Vector3(cos(a1) * outer_radius, h1, sin(a1) * outer_radius)
		
		_add_quad(st, in0, in1, out1, out0, float(i) / total_pts, float(i + 1) / total_pts, 0.0, 1.0)
	
	st.generate_normals()
	return st.commit()

static func _add_quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u0: float, u1: float, v0: float, v1: float) -> void:
	_add_tri(st, p0, p1, p2, Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1))
	_add_tri(st, p0, p2, p3, Vector2(u0, v0), Vector2(u1, v1), Vector2(u0, v1))

static func _add_tri(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, uv0: Vector2, uv1: Vector2, uv2: Vector2) -> void:
	st.set_uv(uv0)
	st.add_vertex(p0)
	st.set_uv(uv1)
	st.add_vertex(p1)
	st.set_uv(uv2)
	st.add_vertex(p2)

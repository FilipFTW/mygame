@tool
extends Path3D
@export var road_mesh: MeshInstance3D
@export var road_path: Path3D
@export var road_half_width: float = 6
@export var carve_blend: float = 10
@export var auto_generate: bool = true
@export var snap_now: bool = false:
	set(value):
		snap_now = false
		_snap_to_terrain()
@export var terrain: Terrain3D:
	set(value):
		terrain = value
		_build()
@export var height_offset: float = 0.15:
	set(value):
		height_offset = value
		_build()
@export var radius_x: float = 80:
	set(value):
		radius_x = value
		_build()
@export var radius_z: float = 50:
	set(value):
		radius_z = value
		_build()
@export var bank_amount: float = 1:
	set(value):
		bank_amount = value
		_build()
func _ready() -> void:
	_build()
	#_carve_terrain()
func _build() -> void:
	if not auto_generate:
		return
	if not is_inside_tree():
		return
	var c := Curve3D.new()
	var count := 96
	var step := TAU / count
	var half_width := 6
	for i in range(count + 1):
		var a := -step * i
		var pos := Vector3(cos(a) * radius_x, 0, sin(a) * radius_z)
		var direction := Vector3(sin(a) * radius_x, 0, -cos(a) * radius_z)
		var forward := direction.normalized()
		var left := Vector3.UP.cross(forward)
		var tilt := 0.0
		if terrain != null:
			var h: float = terrain.data.get_height(to_global(pos))
			var hl: float = terrain.data.get_height(to_global(pos + left * half_width))
			var hr: float = terrain.data.get_height(to_global(pos - left * half_width))
			if not is_nan(h):
				pos.y = h - global_position.y + height_offset
			if not is_nan(hl) and not is_nan(hr):
				tilt = atan2(hl - hr, half_width * 2) * bank_amount
		var tangent := Vector3(sin(a) * radius_x, 0, -cos(a) * radius_z) * step / 3
		c.add_point(pos, -tangent, tangent)
		c.set_point_tilt(i, tilt)
	curve = c
func _carve_terrain() -> void:
	if terrain == null or road_path == null or Engine.is_editor_hint():
		return
	var c := road_path.curve
	var length := c.get_baked_length()
	var reach := road_half_width + carve_blend
	var d := 0.0
	while d <= length:
		var p := c.sample_baked(d)
		var a := c.sample_baked(maxf(d - 0.5, 0))
		var b := c.sample_baked(minf(d + 0.5, length))
		var left := Vector3.UP.cross((b - a).normalized())
		var road_y := to_global(p).y - height_offset
		var side := -reach
		while side <= reach:
			var world_pos := to_global(p + left * side)
			var current: float = terrain.data.get_height(world_pos)
			if not is_nan(current):
				var edge := maxf(absf(side) - road_half_width, 0)
				var weight := 1.0 - smoothstep(0.0, carve_blend, edge)
				terrain.data.set_height(world_pos, lerpf(current, road_y, weight))
				side += 0.5
			d += 0.5
		terrain.data.update_maps(Terrain3DRegion.TYPE_HEIGHT)
		terrain.collision.build()
func _snap_to_terrain() -> void:
	if terrain == null or road_path == null or curve.point_count < 3 or not is_inside_tree():
		return
	_add_handles(curve)
	var length := curve.get_baked_length()
	var rows := int(length)
	var cols := 13
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var last_y := 0.0
	for r in range(rows + 1):
		var d := length * r / rows
		var p := curve.sample_baked(d)
		var a := curve.sample_baked(maxf(d - 1.0, 0.0))
		var b := curve.sample_baked(minf(d + 1.0, length))
		var forward := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
		var left := Vector3.UP.cross(forward)
		for c in range(cols):
			var side := -road_half_width + 2.0 * road_half_width * c / (cols - 1)
			var v := p + left * side
			var h: float = terrain.data.get_height(to_global(v))
			if not is_nan(h):
				last_y = h - global_position.y + height_offset
			v.y = last_y
			st.add_vertex(v)
	for r in range(rows):
		for c in range(cols - 1):
			var i0 := r * cols + c
			var i2 := i0 + cols
			st.add_index(i0)
			st.add_index(i0 + 1)
			st.add_index(i2)
			st.add_index(i0 + 1)
			st.add_index(i2 + 1)
			st.add_index(i2)
	st.generate_normals()
	road_mesh.mesh = st.commit()
func _add_handles(c: Curve3D) -> void:
	var n := c.point_count
	var closed := n > 2 and c.get_point_position(0).is_equal_approx(c.get_point_position(n - 1))
	var m := (n - 1) if closed else n
	for i in range(m):
		var prev_i := ((i - 1 + m) % m) if closed else maxi(i - 1, 0)
		var next_i := ((i + 1) % m) if closed else mini(i + 1, m - 1)
		var tangent := (c.get_point_position(next_i) - c.get_point_position(prev_i)) / 6
		c.set_point_in(i, -tangent)
		c.set_point_out(i, tangent)
	if closed:
		c.set_point_in(n - 1, c.get_point_in(0))
		c.set_point_out(n - 1, c.get_point_out(0))

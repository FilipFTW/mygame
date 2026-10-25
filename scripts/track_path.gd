@tool
extends Path3D
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
	if terrain == null or Engine.is_editor_hint():
		return
	var length := curve.get_baked_length()
	var reach := road_half_width + carve_blend
	var d := 0.0
	while d <= length:
		var p := curve.sample_baked(d)
		var a := curve.sample_baked(maxf(d - 0.5, 0))
		var b := curve.sample_baked(minf(d + 0.5, length))
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
	if terrain == null or not is_inside_tree():
		return
	for i in range(curve.point_count):
		var p := curve.get_point_position(i)
		var h: float = terrain.data.get_height(to_global(p))
		if not is_nan(h):
			p.y = h - global_position.y + height_offset
			curve.set_point_position(i, p)
	var n := curve.point_count
	var closed := n>2 and curve.get_point_position(0).is_equal_approx(curve.get_point_position(n - 1))
	var m := (n - 1) if closed else n
	for i in range(m):
		var prev_i := ((i - 1 + m) % m) if closed else maxi(i - 1, 0)
		var next_i := ((i + 1) % m) if closed else mini(i + 1, m - 1)
		var tangent := (curve.get_point_position(next_i) - curve.get_point_position(prev_i)) / 6
		curve.set_point_in(i, -tangent)
		curve.set_point_out(i, tangent)
	if closed:
		curve.set_point_in(n - 1, curve.get_point_in(0))
		curve.set_point_out(n - 1, curve.get_point_out(0))
	

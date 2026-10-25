extends Camera3D
@export var target: RigidBody3D
@export var distance: float = 6
@export var height: float = 2.5
@export var follow_speed: float = 8
@export var base_fov: float = 70
@export var max_fov: float = 95
@export var max_speed_for_fov: float = 60
func _physics_process(delta: float) -> void:
	if target == null:
		return
	var forward := -target.global_basis.z
	forward.y = 0
	forward = forward.normalized()
	var wanted_position := target.global_position - forward * distance + Vector3.UP * height
	global_position = global_position.lerp(wanted_position, clampf(follow_speed * delta, 0, 1))
	look_at(target.global_position + Vector3.UP)
	var speed_ratio := clampf(target.linear_velocity.length() / max_speed_for_fov, 0, 1)
	var wanted_fov := lerpf(base_fov, max_fov, speed_ratio)
	fov = lerpf(fov, wanted_fov, clampf(3 * delta, 0, 1))

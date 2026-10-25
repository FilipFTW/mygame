extends RigidBody3D
@export var acceleration_force: float = 9000
@export var brake_force: float = 5000
@export var steering_force: float = 2.5
@export_group("Suspension")
@export var spring_strengh: float = 35000
@export var spring_damping: float = 4500
@export var rest_lenght: float = 0.65
@export var max_lenght: float = 1
@export var wheel_radius: float = 0.3
@export_group("Arcade")
@export var max_speed: float = 22
@export var lateral_grip: float = 5
@export var extra_downforce: float = 100
@export var max_wheel_steer_angle: float = 30
@onready var rays: Array[RayCast3D] = [
	$"SuspensionFL (RayCast3D)",
	$"SuspensionFR (RayCast3D)",
	$"SuspensionRL (RayCast3D)",
	$"SuspensionRR (RayCast3D)"
]
@onready var wheels: Array[Node3D] = [
	$"Visuals Node3D/WheelFL MeshInstance3D",
	$"Visuals Node3D/WheelFR MeshInstance3D",
	$"Visuals Node3D/WheelRL MeshInstance3D",
	$"Visuals Node3D/WheelRR MeshInstance3D"
]
var current_speed: float = 0
var wheel_position: Array[Vector3] = []
var steer_angle: float = 0
func _ready() -> void:
	for i in range(4):
		wheel_position.append(wheels[i].position)
		rays[i].target_position = Vector3(
			0, -(max_lenght + wheel_radius), 0
		)
		rays[i].enabled = true
	continuous_cd = true
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.3 ,0)
func _physics_process(delta: float) -> void:
	var throttle := Input.get_axis("reverse", "accelerate")
	var steering := Input.get_axis("steerright", "steerleft")
	var forward := -global_basis.z
	var forward_speed := linear_velocity.dot(forward)
	var wheels_on_ground := 0
	for ray in rays:
		if ray.is_colliding():
			wheels_on_ground += 1
	var grounded := wheels_on_ground > 0
	if grounded:
		if throttle > 0 and forward_speed < max_speed:
			apply_central_force(forward * acceleration_force)
		elif throttle < 0:
			if forward_speed > 1:
				apply_central_force(-forward * brake_force)
			else:
				apply_central_force(forward * acceleration_force * throttle)
		if Input.is_action_pressed("handbrake"):
			linear_velocity *= 0.99
	var speed_factor: float = clamp(abs(forward_speed) / 5, 0, 1)
	var turn_direction := 1
	if forward_speed < 0:
		turn_direction = -1
	apply_torque(
		global_basis.y * steering * steering_force
		* speed_factor * turn_direction * mass
	)
	var sideways := global_basis.x
	var side_speed := linear_velocity.dot(sideways)
	apply_central_force(
		-sideways * side_speed * lateral_grip * mass
	)
	for i in range(4):
		var ray := rays[i]
		ray.force_raycast_update()
		if ray.is_colliding():
			var hit_point := ray.get_collision_point()
			var hit_normal := ray.get_collision_normal().normalized()
			var mount := ray.global_position
			var distance: float = mount.distance_to(hit_point)
			var compression: float = rest_lenght + wheel_radius - distance
			compression = clampf(compression, 0, rest_lenght)
			var offset := hit_point - global_position
			var point_velocity := linear_velocity \
				+ angular_velocity.cross(offset)
			var suspension_axis := global_basis.y.normalized()
			var damping_speed := point_velocity.dot(suspension_axis)
			var spring_force: float = (
				compression * spring_strengh
				- damping_speed * spring_damping
			)
			spring_force = clampf(spring_force, 0, spring_strengh * rest_lenght)
			apply_force(
				suspension_axis * spring_force,
				offset
			)
			var local_hit : Vector3 = wheels[i].get_parent().to_local(hit_point)
			var target_pos := wheel_position[i]
			target_pos.y = local_hit.y + wheel_radius
			wheels[i].position = wheels[i].position.lerp(
				target_pos, clamp(delta * 12, 0, 1)
			)
	steer_angle = lerpf(steer_angle, steering * deg_to_rad(max_wheel_steer_angle), clampf(delta * 10, 0, 1))
	wheels[0].rotation.y = steer_angle
	wheels[1].rotation.y = steer_angle
	if linear_velocity.length() > 5:
		apply_central_force(
			- global_basis.y * extra_downforce
			* linear_velocity.length()
		)

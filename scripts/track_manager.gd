extends Node3D
@export var car: RigidBody3D
@export var total_laps: int = 3
var next_checkpoint: int = 0
var lap: int = 0
var lap_time: float = 0
var running: bool = false
var race_finished: bool = false
func _ready() -> void:
	var children := get_children()
	for i in range (children.size()):
		var area := children[i] as Area3D
		area.body_entered.connect(_on_checkpoint_entered.bind(i))
func _process(delta: float) -> void:
	if running:
		lap_time += delta
func _on_checkpoint_entered(body: Node3D, index: int) -> void:
	if body != car or race_finished or index != next_checkpoint:
		return
	if index == 0:
		if running:
			lap += 1
			print("Tur ", lap, "terminat: ", snappedf(lap_time, 0.01), " s")
			if lap >= total_laps:
				print("Cursa terminata!")
				race_finished = true
				running = false
				return
		else:
			print("Start!")
			running = true
		lap_time = 0
	else:
		print("Checkpoint ", index)
	next_checkpoint = (index + 1) % get_child_count()

extends StaticBody3D

@onready var bottom_detector: Area3D = $BottomDetector
@onready var mesh: Node3D = $Mesh
@onready var particles: GPUParticles3D = $Particles

var exploded := false

func _ready() -> void:
	bottom_detector.body_entered.connect(_on_bottom_hit)

func _on_bottom_hit(body: Node3D) -> void:
	if body.is_in_group("player"):
		explode()

func explode() -> void:
	if exploded:
		return
	exploded = true

	Audio.play("res://sounds/break.ogg")
	particles.restart()
	mesh.hide()
	$CollisionShape3D.set_deferred("disabled", true)  # <-- defer physics change
	bottom_detector.set_deferred("monitoring", false) # <-- defer during signal

	await get_tree().create_timer(1.0).timeout
	queue_free()

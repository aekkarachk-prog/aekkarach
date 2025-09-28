extends Node3D

@export var target: Node3D
@export var require_right_mouse: bool = false   # hold RMB to rotate (false = always rotate)

# --- Zoom (dolly along local +Z)
@export var zoom_minimum: float = 16.0   # farther
@export var zoom_maximum: float = 4.0    # nearer
@export var zoom_step: float = 1.0
@export var zoom_lerp_speed: float = 12.0

# --- Rotation
@export var mouse_sensitivity: float = 0.06
@export var invert_y: bool = false
@export var pitch_min: float = -80.0
@export var pitch_max: float = 80.0
@export var follow_lerp: float = 10.0     # follow smoothing
@export var rot_lerp: float = 12.0        # rotation smoothing

var yaw: float
var pitch: float
var cur_yaw: float
var cur_pitch: float
var zoom: float = 6.0

@onready var cam: Camera3D = $Camera3D   # <- change to your camera's node path if needed

func _ready() -> void:
	# Start from current orientation
	yaw = rotation_degrees.y
	pitch = rotation_degrees.x
	cur_yaw = yaw
	cur_pitch = pitch
	if cam:
		cam.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Follow target in WORLD SPACE (prevents shake if the target rotates/scales)
	if target:
		global_position = global_position.lerp(target.global_position, delta * follow_lerp)

	# Smooth yaw/pitch (wrap-safe for 360° yaw)
	cur_yaw = lerp_angle(cur_yaw, yaw, delta * rot_lerp)
	cur_pitch = lerp_angle(cur_pitch, pitch, delta * rot_lerp)
	rotation_degrees = Vector3(cur_pitch, cur_yaw, 0.0)

	# Smooth zoom (camera is a child at local +Z)
	if cam:
		var desired_local := Vector3(0, 0, zoom)
		cam.position = cam.position.lerp(desired_local, zoom_lerp_speed * delta)

func _input(event: InputEvent) -> void:
	# Rotate with mouse
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if not require_right_mouse or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			var m := event as InputEventMouseMotion
			yaw -= m.relative.x * mouse_sensitivity
			var dy: float = m.relative.y
			var sign: float = (1.0 if invert_y else -1.0)
			pitch += dy * sign * mouse_sensitivity
			pitch = clamp(pitch, pitch_min, pitch_max)
			# keep yaw bounded (still allows endless spin)
			yaw = wrapf(yaw, -180.0, 180.0)

	# Wheel zoom
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom -= zoom_step
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom += zoom_step
		zoom = clamp(zoom, zoom_maximum, zoom_minimum)

		# left-click to re-capture mouse
		if event.button_index == MOUSE_BUTTON_LEFT:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# ESC to release mouse
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

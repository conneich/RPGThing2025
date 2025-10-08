extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var _look_dir: Vector2
var _camera_sens = 50
var _tps_camera_zoom_desired = 4
var _tps_camera_current: bool = false

@onready var _eye_position = $EyePosition
@onready var look_at_collider: ShapeCast3D = $EyePosition/LookAtCollider
@onready var _mouse_sensitivity = GameInput.Settings["MouseSensitivity"]

func _handle_look_target() -> void:
	pass

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Game.focus_state == Globals.FocusState.UIOnly:
		return
	
	# Handle jump.
	if GameInput.get_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("MoveBackward", "MoveForward", "MoveLeft", "MoveRight")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	_rotate_view(delta)
	
	if look_at_collider.is_colliding():
		_handle_look_target()
	
	
	_zoom_tps_camera()
	move_and_slide()

func _input(event: InputEvent) -> void:
	if Game.focus_state == Globals.FocusState.UIOnly:
		return
	
	# Switch TPS view to FPS and vice versa
	if event is InputEventMouseButton:
		var _scroll_input = Input.get_axis("ZoomForward", "ZoomAway")
		_tps_camera_zoom_desired += _scroll_input
		
		if _tps_camera_zoom_desired > 10:
			_tps_camera_zoom_desired = 10
		elif _tps_camera_zoom_desired < 3:
			_tps_to_fps()
		elif not _tps_camera_current:
			_fps_to_tps()
		
		

func _unhandled_input(event: InputEvent) -> void:
	if Game.focus_state == Globals.FocusState.UIOnly:
		return
		
	if event is InputEventMouseMotion:  _look_dir = event.relative * 0.01

func _rotate_view(delta: float) -> void: 
	var input = Input.get_vector("LookLeft", "LookRight", "LookDown", "LookUp")
	_look_dir += input
	
	rotation.y -= _look_dir.x * _camera_sens * delta
	_eye_position.rotation.z = (_inverted_look()) * clamp(_eye_position.rotation.z - _look_dir.y * _camera_sens * _mouse_sensitivity * delta, -1.5, 1.5)
	_look_dir = Vector2.ZERO
	
	if _tps_camera_current:
		%TPSViewpoint.look_at(_eye_position.global_position)

func _zoom_tps_camera() -> void:
	var _tps_camera_zoom_current = $EyePosition/SpringArm3D.spring_length
	if _tps_camera_zoom_current != _tps_camera_zoom_desired:
		if is_equal_approx(_tps_camera_zoom_current, _tps_camera_zoom_desired):
			_tps_camera_zoom_current = _tps_camera_zoom_desired
			return
		$EyePosition/SpringArm3D.spring_length = lerpf(_tps_camera_zoom_current, _tps_camera_zoom_desired, 0.2)
		
		

func _tps_to_fps() -> void:
	_tps_camera_current = false
	
	%TPSViewpoint.clear_current()
	%FPSViewpoint.make_current()

func _fps_to_tps() -> void:
	_tps_camera_current = true
	
	$EyePosition/SpringArm3D.spring_length = 4
	_tps_camera_zoom_desired = 4
	%FPSViewpoint.clear_current()
	%TPSViewpoint.make_current()

func _inverted_look() -> float:
	if GameInput.Settings["InvertLook"]:
		return -1.0
	return 1.0

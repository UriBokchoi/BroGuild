extends GutTest
## Slide con física real: frena en llano hasta levantarse, se corta al soltar Ctrl, el slide-jump
## conserva el impulso y el dash con Ctrl mantenido sigue deslizando con su velocidad.

const PlayerScene := preload("res://entities/player/player.tscn")
const SETTLE_FRAMES := 5

var _player: Player
var _move: MovementData


func before_each() -> void:
	_add_ground()
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)
	_move = _player.stats.get_resolved(MovementData) as MovementData


func after_each() -> void:
	for action: StringName in [InputActions.MOVE_FORWARD, InputActions.SLIDE]:
		Input.action_release(action)


func test_slides_on_flat_ground_slowing_down_until_standing_up() -> void:
	await _run_and_slide()
	assert_true(_player.movement.current is SlideState, "desliza")
	assert_lt(_speed(), _move.run_speed, "en llano frena")
	assert_gt(_speed(), _move.slide_min_speed)
	await wait_physics_frames(60)
	assert_same(_player.movement.current, _player.ground_state, "se levanta al bajar de la mínima")


func test_can_steer_while_sliding() -> void:
	await _run_and_slide()
	Input.action_release(InputActions.MOVE_FORWARD)
	Input.action_press(InputActions.MOVE_RIGHT)
	await wait_physics_frames(10)
	Input.action_release(InputActions.MOVE_RIGHT)
	assert_true(_player.movement.current is SlideState, "sigue deslizando")
	assert_gt(_player.velocity.x, 2.0, "se curva hacia la derecha (+X)")


func test_releasing_ctrl_stops_sliding() -> void:
	await _run_and_slide()
	Input.action_release(InputActions.SLIDE)
	await wait_physics_frames(2)
	assert_same(_player.movement.current, _player.ground_state)


func test_slide_jump_keeps_the_momentum() -> void:
	await _run_and_slide()
	var slide_speed := _speed()
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(2)
	assert_gt(_player.velocity.y, 0.0, "salta")
	assert_almost_eq(_speed(), slide_speed, 1.0, "sin perder el impulso del slide")


func test_dash_holding_ctrl_keeps_sliding_at_dash_speed() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	Input.action_press(InputActions.SLIDE)
	_player.movement.request(InputActions.DASH)
	await wait_physics_frames(16)
	assert_true(_player.movement.current is SlideState, "el dash sigue como slide")
	assert_gt(_speed(), _move.dash_exit_speed, "sin el recorte de salida del dash")


func test_ctrl_in_the_middle_of_a_ground_dash_cuts_it_into_a_slide() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	_player.movement.request(InputActions.DASH)
	await wait_physics_frames(3)
	assert_true(_player.movement.current is DashState, "a mitad del dash")
	Input.action_press(InputActions.SLIDE)
	_player.movement.request(InputActions.SLIDE)
	await wait_physics_frames(2)
	assert_true(_player.movement.current is SlideState, "el slide corta el dash")
	assert_gt(_speed(), _move.dash_exit_speed, "con el impulso del dash")
	assert_true(_player.context.is_dash_jump_open(), "cortarlo abre la ventana del dash-jump")


func test_ctrl_does_not_cut_an_air_dash() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(8)
	_player.movement.request(InputActions.DASH)
	await wait_physics_frames(2)
	Input.action_press(InputActions.SLIDE)
	_player.movement.request(InputActions.SLIDE)
	await wait_physics_frames(2)
	assert_true(_player.movement.current is DashState, "en el aire, el slide no entra")


## Corre hacia delante a toda velocidad y empieza a deslizar manteniendo Ctrl.
func _run_and_slide() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	Input.action_press(InputActions.MOVE_FORWARD)
	await wait_physics_frames(20)
	Input.action_press(InputActions.SLIDE)
	_player.movement.request(InputActions.SLIDE)
	await wait_physics_frames(5)


func _speed() -> float:
	return Vector2(_player.velocity.x, _player.velocity.z).length()


func _add_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(120.0, 1.0, 120.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)

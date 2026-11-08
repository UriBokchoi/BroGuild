extends GutTest
## Movimiento del jugador con física real: correr, frenar, saltar, jump buffer y giro del modelo.

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
	for action: StringName in [
		InputActions.MOVE_FORWARD, InputActions.MOVE_BACK,
		InputActions.MOVE_LEFT, InputActions.MOVE_RIGHT,
	]:
		Input.action_release(action)


func test_runs_forward_up_to_run_speed() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	Input.action_press(InputActions.MOVE_FORWARD)
	await wait_physics_frames(30)
	var velocity := _player.velocity
	assert_almost_eq(Vector2(velocity.x, velocity.z).length(), _move.run_speed, 0.01)
	assert_lt(velocity.z, 0.0, "adelante es −Z con la cámara sin girar")


func test_run_speed_upgrade_makes_the_player_faster() -> void:
	var upgrade := StatModifier.create(&"run_speed", StatModifier.Kind.PERCENT, 0.5)
	_player.stats.add_modifier(upgrade, self)
	await wait_physics_frames(SETTLE_FRAMES)
	Input.action_press(InputActions.MOVE_FORWARD)
	await wait_physics_frames(30)
	var speed := Vector2(_player.velocity.x, _player.velocity.z).length()
	assert_almost_eq(speed, _move.run_speed, 0.01)
	assert_almost_eq(speed, _player.stats.get_base(&"run_speed") * 1.5, 0.01, "+50 %")


func test_stops_after_releasing() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	Input.action_press(InputActions.MOVE_FORWARD)
	await wait_physics_frames(30)
	Input.action_release(InputActions.MOVE_FORWARD)
	await wait_physics_frames(30)
	assert_almost_eq(_player.velocity.length(), 0.0, 0.01)


func test_jump_reaches_about_the_jump_height_and_lands() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	_player.movement.request(InputActions.JUMP)
	assert_almost_eq(await _highest_point_in(40), _move.jump_height, 0.15)
	await wait_physics_frames(20)
	assert_same(_player.movement.current, _player.ground_state, "vuelve al suelo")


func test_jump_pressed_just_before_landing_happens_on_landing() -> void:
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	# Cayendo desde 1 m toca suelo hacia el tick 15: se pulsa unos 4 ticks antes.
	await wait_physics_frames(11)
	assert_false(_player.is_on_floor(), "se pulsa todavía en el aire")
	_player.movement.request(InputActions.JUMP)
	assert_gt(await _highest_point_in(40), 1.5, "saltó al aterrizar")


func test_model_turns_towards_where_it_moves() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	Input.action_press(InputActions.MOVE_RIGHT)
	await wait_physics_frames(30)
	var model := _player.get_node(^"Body") as Node3D
	assert_almost_eq(model.rotation.y, -PI / 2.0, 0.01, "mirando hacia +X")


## Altura máxima que alcanza el jugador durante los próximos [param frames] ticks.
func _highest_point_in(frames: int) -> float:
	var highest := _player.global_position.y
	for _frame: int in frames:
		await wait_physics_frames(1)
		highest = maxf(highest, _player.global_position.y)
	return highest


func _add_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 1.0, 40.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)

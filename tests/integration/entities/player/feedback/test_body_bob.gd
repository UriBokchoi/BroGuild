extends GutTest
## Balanceo al andar con física real: corriendo por el suelo, el cuerpo sube y baja a cada paso (y
## avisa de cada paso), más alto y más a menudo cuanto más rápido va; en el slide o parado no se
## balancea y vuelve a su sitio.

const FakeState := preload("res://tests/unit/core/state_machine/fake_state.gd")
const RUN_SPEED := 8.0

var _body: CharacterBody3D
var _machine: StateMachine
var _ground: FakeState
var _slide: FakeState
var _part: Node3D
var _bob: BodyBob
var _steps: int = 0


func before_each() -> void:
	_steps = 0
	_add_floor()
	_body = CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.9, 0.0)
	_body.add_child(shape)
	add_child_autofree(_body)
	_part = Node3D.new()
	_part.position = Vector3(0.0, 0.9, 0.0)
	_body.add_child(_part)
	var stats := StatsComponent.new()
	var move := MovementData.new()
	move.run_speed = RUN_SPEED
	stats.sources.append(move)
	add_child_autofree(stats)
	_machine = StateMachine.new()
	_ground = FakeState.new()
	_slide = FakeState.new()
	_machine.add_child(_ground)
	_machine.add_child(_slide)
	_machine.initial_state = _ground
	add_child_autofree(_machine)
	_bob = BodyBob.new()
	_bob.body = _body
	_bob.stats = stats
	_bob.machine = _machine
	_bob.walk_states.append(_ground)
	_bob.parts.append(_part)
	add_child_autofree(_bob)
	_bob.stepped.connect(func(_ratio: float) -> void: _steps += 1)
	_machine.start(null)


func test_running_bobs_at_every_step() -> void:
	var start := Engine.get_physics_frames()
	var highest := await _run_for(RUN_SPEED, 2.0)
	var seconds := float(Engine.get_physics_frames() - start) / Engine.physics_ticks_per_second
	assert_between(highest, 0.02, _bob.bob_height + 0.001, "sube y baja, no más de su altura")
	var expected := _bob.run_steps * seconds
	assert_between(float(_steps), expected - 2.0, expected + 2.0, "un aviso por paso")


func test_faster_bobs_higher() -> void:
	var slow := await _run_for(RUN_SPEED * 0.4, 1.5)
	var fast := await _run_for(RUN_SPEED * 1.4, 1.5)
	assert_gt(fast, slow * 2.0)


func test_sliding_does_not_bob() -> void:
	_machine.transition_to(_slide)
	var highest := await _run_for(RUN_SPEED, 1.0)
	assert_eq(highest, 0.0)
	assert_eq(_steps, 0)


func test_stopping_settles_back() -> void:
	await _run_for(RUN_SPEED, 0.6)
	await _run_for(0.0, 0.6)
	assert_eq(_bob.get_offset(), 0.0)
	assert_eq(_part.position, Vector3(0.0, 0.9, 0.0), "vuelve a su sitio")
	assert_eq(_part.rotation, Vector3.ZERO)


## Corre a [param speed] durante [param seconds] y devuelve lo más alto que subió el cuerpo.
func _run_for(speed: float, seconds: float) -> float:
	var highest := 0.0
	var ticks := roundi(seconds * Engine.physics_ticks_per_second)
	for _tick: int in ticks:
		_body.velocity = Vector3(speed, -1.0, 0.0)
		_body.move_and_slide()
		await wait_physics_frames(1)
		highest = maxf(highest, _bob.get_offset())
	return highest


func _add_floor() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)

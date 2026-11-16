extends GutTest
## BodyCrouch: el modelo se agacha en los estados indicados y se levanta al salir, con los pies
## en el mismo sitio.

const FakeState := preload("res://tests/unit/core/state_machine/fake_state.gd")
const TICK := 1.0 / 60.0
const CROUCH := 0.5

var _machine: StateMachine
var _idle: FakeState
var _slide: FakeState
var _visual: Node3D
var _crouch: BodyCrouch


func before_each() -> void:
	_machine = StateMachine.new()
	add_child_autofree(_machine)
	_idle = FakeState.new()
	_slide = FakeState.new()
	_machine.add_child(_idle)
	_machine.add_child(_slide)
	_machine.initial_state = _idle
	_visual = Node3D.new()
	_visual.position = Vector3(0.0, 0.9, 0.0)
	add_child_autofree(_visual)
	_crouch = BodyCrouch.new()
	_crouch.machine = _machine
	_crouch.visual = _visual
	_crouch.crouch_states.append(_slide)
	_crouch.crouch_scale = CROUCH
	add_child_autofree(_crouch)
	_machine.start(null)


func test_crouches_in_the_listed_states_keeping_the_feet_down() -> void:
	_machine.transition_to(_slide)
	_settle()
	assert_almost_eq(_visual.scale.y, CROUCH, 1e-3)
	assert_almost_eq(_visual.position.y, 0.9 * CROUCH, 1e-3, "los pies siguen en el suelo")


func test_stands_up_again_in_other_states() -> void:
	_machine.transition_to(_slide)
	_settle()
	_machine.transition_to(_idle)
	_settle()
	assert_almost_eq(_visual.scale.y, 1.0, 1e-3)
	assert_eq(_crouch.get_target(), 1.0)


func _settle() -> void:
	for _tick: int in 60:
		_crouch._physics_process(TICK)

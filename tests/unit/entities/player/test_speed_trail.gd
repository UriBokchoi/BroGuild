extends GutTest
## SpeedTrail: emite solo mientras el movimiento está en uno de sus estados.

const FakeState := preload("res://tests/unit/core/state_machine/fake_state.gd")

var _machine: StateMachine
var _idle: FakeState
var _dash: FakeState
var _trail: SpeedTrail


func before_each() -> void:
	_machine = StateMachine.new()
	add_child_autofree(_machine)
	_idle = FakeState.new()
	_dash = FakeState.new()
	_machine.add_child(_idle)
	_machine.add_child(_dash)
	_machine.initial_state = _idle
	_trail = SpeedTrail.new()
	_trail.machine = _machine
	_trail.trail_states.append(_dash)
	add_child_autofree(_trail)
	_machine.start(null)


func test_emits_only_in_its_states() -> void:
	assert_false(_trail.emitting)
	_machine.transition_to(_dash)
	assert_true(_trail.emitting, "en el dash")
	_machine.transition_to(_idle)
	assert_false(_trail.emitting)

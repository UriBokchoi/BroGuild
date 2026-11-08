extends GutTest
## PlayerInput: reenvía a la máquina las pulsaciones de las acciones que activan estados.

const FakeState := preload("res://tests/unit/core/state_machine/fake_state.gd")
const TICK := 1.0 / 60.0

var _machine: StateMachine
var _jump: FakeState
var _input: PlayerInput


func before_each() -> void:
	_machine = StateMachine.new()
	_machine.buffer_time = 0.1
	add_child_autofree(_machine)
	var idle := FakeState.new()
	_machine.add_child(idle)
	_machine.initial_state = idle
	_jump = FakeState.new()
	_jump.trigger_action = InputActions.JUMP
	_machine.add_child(_jump)
	_machine.start(null)
	_input = PlayerInput.new()
	_input.machine = _machine
	add_child_autofree(_input)


func test_trigger_action_reaches_the_machine() -> void:
	_input._unhandled_input(_press(InputActions.JUMP))
	_machine.physics_update(TICK)
	assert_same(_machine.current, _jump)


func test_other_actions_are_ignored() -> void:
	_input._unhandled_input(_press(InputActions.INTERACT))
	_machine.physics_update(TICK)
	assert_eq(_jump.entered, 0)


func _press(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event

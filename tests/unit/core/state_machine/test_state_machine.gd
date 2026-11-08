extends GutTest
## StateMachine: transiciones y reglas de las acciones (primera pulsación, prioridad,
## compromiso, cancelación y buffer).

const FakeState := preload("res://tests/unit/core/state_machine/fake_state.gd")
const TICK := 1.0 / 60.0
const BUFFER := 0.12
const END_BUFFER := 0.1

var _machine: StateMachine
var _idle: FakeState


func before_each() -> void:
	_machine = StateMachine.new()
	_machine.buffer_time = BUFFER
	_machine.committed_end_buffer = END_BUFFER
	add_child_autofree(_machine)
	_idle = _add_state(&"")
	_machine.initial_state = _idle


func test_starts_in_the_initial_state() -> void:
	watch_signals(_machine)
	_machine.start(null)
	assert_same(_machine.current, _idle)
	assert_eq(_idle.entered, 1)
	assert_signal_emitted_with_parameters(_machine, "state_changed", [null, _idle])


func test_transition_exits_the_old_state_and_enters_the_new_one() -> void:
	var other := _add_state(&"")
	_machine.start(null)
	_machine.transition_to(other)
	assert_eq(_idle.exited, 1)
	assert_eq(other.entered, 1)
	assert_same(_machine.current, other)


func test_active_state_is_updated_every_tick() -> void:
	_machine.start(null)
	_machine.physics_update(TICK)
	_machine.physics_update(TICK)
	assert_eq(_idle.updates, 2)


func test_request_enters_the_state_of_that_action() -> void:
	var jump := _add_state(&"jump")
	_machine.start(null)
	_machine.request(&"jump")
	_machine.physics_update(TICK)
	assert_same(_machine.current, jump)


func test_first_request_wins_and_one_enters_per_tick() -> void:
	var jump := _add_state(&"jump")
	var dash := _add_state(&"dash")
	_machine.start(null)
	_machine.request(&"dash")
	_machine.request(&"jump")
	_machine.physics_update(TICK)
	assert_same(_machine.current, dash, "la primera pulsación entra antes")
	_machine.physics_update(TICK)
	assert_same(_machine.current, jump, "la segunda espera su turno")


func test_highest_priority_that_can_enter_wins() -> void:
	var low := _add_state(&"jump", 0)
	var high := _add_state(&"jump", 10)
	_machine.start(null)
	_machine.request(&"jump")
	_machine.physics_update(TICK)
	assert_same(_machine.current, high)
	_machine.transition_to(_idle)
	high.allow_enter = false
	_machine.request(&"jump")
	_machine.physics_update(TICK)
	assert_same(_machine.current, low, "si la prioritaria no puede, entra la siguiente")


func test_committed_state_drops_actions_pressed_with_time_left() -> void:
	var dash := _committed_state(&"dash", 1.0)
	_add_state(&"jump")
	_machine.start(null)
	_machine.transition_to(dash)
	_machine.request(&"jump")
	_machine.physics_update(TICK)
	assert_same(_machine.current, dash, "no se interrumpe")
	_machine.transition_to(_idle)
	_machine.physics_update(TICK)
	assert_same(_machine.current, _idle, "la pulsación se descartó")


func test_action_pressed_near_the_end_of_a_committed_state_is_kept() -> void:
	var dash := _committed_state(&"dash", END_BUFFER / 2.0)
	var jump := _add_state(&"jump")
	_machine.start(null)
	_machine.transition_to(dash)
	_machine.request(&"jump")
	_machine.physics_update(TICK)
	assert_same(_machine.current, dash, "no se interrumpe")
	_machine.transition_to(_idle)
	_machine.physics_update(TICK)
	assert_same(_machine.current, jump, "entra al terminar la acción")


func test_cancelling_state_enters_during_a_committed_state() -> void:
	var slide := _committed_state(&"slide", 1.0)
	var dash := _add_state(&"dash")
	dash.cancels_committed = true
	_machine.start(null)
	_machine.transition_to(slide)
	_machine.request(&"dash")
	_machine.physics_update(TICK)
	assert_same(_machine.current, dash)


func test_cancelling_state_can_restart_itself() -> void:
	var dash := _committed_state(&"dash", 1.0)
	dash.cancels_committed = true
	_machine.start(null)
	_machine.transition_to(dash)
	_machine.request(&"dash")
	_machine.physics_update(TICK)
	assert_same(_machine.current, dash)
	assert_eq(dash.entered, 2, "vuelve a entrar")
	assert_eq(dash.exited, 1)


func test_listed_state_interrupts_a_committed_state() -> void:
	var slide := _committed_state(&"slide", 1.0)
	var slide_jump := _add_state(&"jump")
	slide_jump.interrupts.append(slide)
	_machine.start(null)
	_machine.transition_to(slide)
	_machine.request(&"jump")
	_machine.physics_update(TICK)
	assert_same(_machine.current, slide_jump)


func test_request_waits_until_it_can_enter() -> void:
	var jump := _add_state(&"jump")
	jump.allow_enter = false
	_machine.start(null)
	_machine.request(&"jump")
	_machine.physics_update(TICK)
	assert_same(_machine.current, _idle)
	jump.allow_enter = true
	_machine.physics_update(TICK)
	assert_same(_machine.current, jump, "jump buffer: entra en cuanto puede")


func test_request_expires_after_the_buffer_time() -> void:
	var jump := _add_state(&"jump")
	jump.allow_enter = false
	_machine.start(null)
	_machine.request(&"jump")
	for _tick: int in ceili(BUFFER / TICK) + 1:
		_machine.physics_update(TICK)
	jump.allow_enter = true
	_machine.physics_update(TICK)
	assert_same(_machine.current, _idle, "caducó")


func test_request_is_evaluated_once_even_without_buffer() -> void:
	var jump := _add_state(&"jump")
	_machine.buffer_time = 0.0
	_machine.start(null)
	_machine.request(&"jump")
	_machine.physics_update(TICK)
	assert_same(_machine.current, jump)


func test_trigger_actions_lists_each_action_once() -> void:
	_add_state(&"jump")
	_add_state(&"jump", 5)
	_add_state(&"dash")
	_machine.start(null)
	var actions := _machine.get_trigger_actions()
	assert_eq(actions.size(), 2)
	assert_has(actions, &"jump")
	assert_has(actions, &"dash")


func test_changing_state_inside_enter_is_an_error() -> void:
	var other := _add_state(&"")
	var redirecting := _add_state(&"")
	redirecting.redirect_on_enter = other
	_machine.start(null)
	_machine.transition_to(redirecting)
	assert_push_error("durante otro cambio")
	assert_same(_machine.current, redirecting)


func _add_state(action: StringName, priority: int = 0) -> FakeState:
	var state := FakeState.new()
	state.trigger_action = action
	state.priority = priority
	_machine.add_child(state)
	return state


func _committed_state(action: StringName, remaining: float) -> FakeState:
	var state := _add_state(action)
	state.committed = true
	state.remaining = remaining
	return state

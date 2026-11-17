extends GutTest
## Interactor: con física real, elige el Interactable más cercano que toca, avisa de su texto por el
## EventBus, le dice que es el elegido (y al anterior que ya no) y lo activa al pulsar «interactuar».

const INTERACTABLE_LAYER := 256

var _body: Node3D
var _interactor: Interactor


func before_each() -> void:
	_body = Node3D.new()
	add_child_autofree(_body)
	_interactor = Interactor.new()
	_interactor.collision_layer = 0
	_interactor.collision_mask = INTERACTABLE_LAYER
	_interactor.body = _body
	_interactor.add_child(_sphere(0.6))
	add_child_autofree(_interactor)


func test_focuses_the_nearest_and_tells_the_hud() -> void:
	var far := _add_interactable(Vector3(1.4, 0.0, 0.0), &"FAR")
	var near := _add_interactable(Vector3(0.8, 0.0, 0.0), &"NEAR")
	watch_signals(EventBus)
	await wait_physics_frames(6)
	assert_same(_interactor.get_focus(), near)
	assert_ne(_interactor.get_focus(), far)
	assert_signal_emitted_with_parameters(EventBus, "interaction_prompt_changed", [&"NEAR"])


func test_only_the_chosen_one_knows_it() -> void:
	var far := _add_interactable(Vector3(-1.0, 0.0, 0.0), &"FAR")
	var near := _add_interactable(Vector3(0.8, 0.0, 0.0), &"NEAR")
	await wait_physics_frames(6)
	assert_true(near.is_focused())
	assert_false(far.is_focused())
	near.enabled = false
	await wait_physics_frames(4)
	assert_false(near.is_focused(), "desactivado, deja de ser el elegido")
	assert_true(far.is_focused())


func test_interact_action_activates_the_focus() -> void:
	var interactable := _add_interactable(Vector3(0.8, 0.0, 0.0), &"NEAR")
	watch_signals(interactable)
	await wait_physics_frames(6)
	_interactor._unhandled_input(_press(InputActions.INTERACT))
	assert_signal_emitted_with_parameters(interactable, "interacted", [_body])


func test_disabled_interactables_are_ignored() -> void:
	var interactable := _add_interactable(Vector3(0.8, 0.0, 0.0), &"NEAR")
	interactable.enabled = false
	await wait_physics_frames(6)
	assert_null(_interactor.get_focus())


func test_leaving_clears_the_prompt() -> void:
	var interactable := _add_interactable(Vector3(0.8, 0.0, 0.0), &"NEAR")
	await wait_physics_frames(6)
	watch_signals(EventBus)
	interactable.position = Vector3(20.0, 0.0, 0.0)
	await wait_physics_frames(6)
	assert_null(_interactor.get_focus())
	assert_signal_emitted_with_parameters(EventBus, "interaction_prompt_changed", [&""])


func test_a_prompt_that_changes_while_near_is_shown_again() -> void:
	var interactable := _add_interactable(Vector3(0.8, 0.0, 0.0), &"START")
	await wait_physics_frames(6)
	watch_signals(EventBus)
	interactable.prompt_key = &"STOP"
	await wait_physics_frames(3)
	assert_signal_emitted_with_parameters(EventBus, "interaction_prompt_changed", [&"STOP"])


func _add_interactable(at: Vector3, prompt: StringName) -> Interactable:
	var interactable := Interactable.new()
	interactable.collision_layer = INTERACTABLE_LAYER
	interactable.collision_mask = 0
	interactable.prompt_key = prompt
	interactable.position = at
	interactable.add_child(_sphere(0.5))
	add_child_autofree(interactable)
	return interactable


func _sphere(radius: float) -> CollisionShape3D:
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	return shape


func _press(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event

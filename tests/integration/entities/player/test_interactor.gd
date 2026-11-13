extends GutTest
## Interactor: con física real, elige el Interactable más cercano que toca, avisa de su texto por el
## EventBus y lo activa al pulsar «interactuar».

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

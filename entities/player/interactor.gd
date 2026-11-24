class_name Interactor
extends Area3D
## La zona alrededor del jugador que detecta lo que se puede usar: elige lo más cercano, avisa al HUD
## de qué se puede hacer y lo usa al pulsar «interactuar».

## Quien interactúa (el jugador): es lo que recibe el [Interactable].
@export var body: Node3D

var _focus: Interactable
var _shown_prompt: StringName = &""


func _ready() -> void:
	monitoring = true
	monitorable = false


func _physics_process(_delta: float) -> void:
	var nearest := _find_nearest()
	# Si el elegido desapareció (un cofre abierto), también cambia.
	if nearest != _focus or not is_instance_valid(_focus):
		_set_focus(nearest)
	var prompt := _focus.prompt_key if _focus else &""
	if prompt != _shown_prompt:
		_shown_prompt = prompt
		EventBus.interaction_prompt_changed.emit(prompt)


func _unhandled_input(event: InputEvent) -> void:
	if _focus and event.is_action_pressed(InputActions.INTERACT):
		get_viewport().set_input_as_handled()
		_focus.interact(body)


func _exit_tree() -> void:
	_set_focus(null)
	if not _shown_prompt.is_empty():
		_shown_prompt = &""
		EventBus.interaction_prompt_changed.emit(&"")


## El [Interactable] que se activaría ahora, o [code]null[/code].
func get_focus() -> Interactable:
	return _focus


## Cambia el que se usaría ahora y se lo dice a los dos (para su aviso visual).
func _set_focus(target: Interactable) -> void:
	if is_instance_valid(_focus):
		_focus.set_focused(false)
	_focus = target
	if _focus:
		_focus.set_focused(true)


func _find_nearest() -> Interactable:
	var nearest: Interactable = null
	var best := INF
	for area: Area3D in get_overlapping_areas():
		var interactable := area as Interactable
		if interactable == null or not interactable.enabled:
			continue
		var distance := global_position.distance_squared_to(interactable.global_position)
		if distance < best:
			best = distance
			nearest = interactable
	return nearest

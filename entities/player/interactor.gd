class_name Interactor
extends Area3D
## Zona alrededor del jugador que detecta [Interactable]: elige el más cercano, avisa de qué se
## puede hacer ([code]EventBus.interaction_prompt_changed[/code], para el HUD; también si su texto
## cambia mientras está cerca) y lo activa al pulsar «interactuar». Su máscara de física es
## [code]interactable[/code].

## Quien interactúa (el jugador): es lo que recibe el [Interactable].
@export var body: Node3D

var _focus: Interactable
var _shown_prompt: StringName = &""


func _ready() -> void:
	monitoring = true
	monitorable = false


func _physics_process(_delta: float) -> void:
	_focus = _find_nearest()
	var prompt := _focus.prompt_key if _focus else &""
	if prompt != _shown_prompt:
		_shown_prompt = prompt
		EventBus.interaction_prompt_changed.emit(prompt)


func _unhandled_input(event: InputEvent) -> void:
	if _focus and event.is_action_pressed(InputActions.INTERACT):
		get_viewport().set_input_as_handled()
		_focus.interact(body)


func _exit_tree() -> void:
	_focus = null
	if not _shown_prompt.is_empty():
		_shown_prompt = &""
		EventBus.interaction_prompt_changed.emit(&"")


## El [Interactable] que se activaría ahora, o [code]null[/code].
func get_focus() -> Interactable:
	return _focus


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

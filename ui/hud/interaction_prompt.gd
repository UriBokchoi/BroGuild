class_name InteractionPrompt
extends PanelContainer
## Aviso del HUD de lo que hace «interactuar» ahora mismo: la tecla y el texto. Se entera por
## [signal EventBus.interaction_prompt_changed] y se oculta si no hay nada con lo que interactuar.
## Estilo: variaciones [code]PromptPanel[/code], [code]KeyCap[/code] y [code]PromptLabel[/code].

@onready var _key: Label = %PromptKey
@onready var _text: Label = %PromptText


func _enter_tree() -> void:
	if not EventBus.interaction_prompt_changed.is_connected(show_prompt):
		EventBus.interaction_prompt_changed.connect(show_prompt)


func _ready() -> void:
	_key.text = key_text(InputActions.INTERACT)
	if _text.text.is_empty():
		visible = false


## Muestra [param prompt_key] (clave de traducción); vacía, oculta el aviso.
func show_prompt(prompt_key: StringName) -> void:
	visible = not prompt_key.is_empty()
	if is_node_ready():
		_text.text = prompt_key


## Nombre de la primera tecla asignada a [param action] (p. ej. «E»), o vacío si no tiene.
static func key_text(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key == null:
			continue
		if key.physical_keycode != KEY_NONE:
			return key.as_text_physical_keycode()
		return key.as_text_keycode()
	return ""

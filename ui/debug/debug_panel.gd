class_name DebugPanel
extends CanvasLayer
## Panel de depuración: F3 ([constant InputActions.TOGGLE_DEBUG]) lo muestra u oculta. Cada
## sistema añade su bloque como un [DebugSection] hijo de [code]%Sections[/code], sin tocar este
## script. Solo existe en builds de depuración. Mientras se ve pide el cursor, para poder
## pulsar sus botones; también funciona con el juego en pausa.

## Jugador que se depura; cada sección toma de él lo que necesita.
@export var player: Player

@onready var _sections: Container = %Sections


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	for section: DebugSection in _get_sections():
		section.setup(player)
	_set_shown(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.TOGGLE_DEBUG):
		_set_shown(not visible)
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	for section: DebugSection in _get_sections():
		section.refresh()


func _set_shown(shown: bool) -> void:
	visible = shown
	# Solo se actualiza mientras se ve.
	set_process(shown)
	EventBus.cursor_requested.emit(self, shown)


func _get_sections() -> Array[DebugSection]:
	var sections: Array[DebugSection] = []
	for child: Node in _sections.get_children():
		var section := child as DebugSection
		if section:
			sections.append(section)
	return sections

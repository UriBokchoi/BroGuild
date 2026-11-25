class_name ModalPanel
extends CanvasLayer
## Base de los paneles que obligan a elegir (subir de nivel, un objeto): pausan, piden el cursor y Esc
## no los salta ni abre la pausa debajo. Mientras están abiertos se pueden ver las stats con Tab.

## Lo que aparece al abrirse (vacío: nada se anima).
@export var appear_root: Control
## Texto que recuerda cómo ver tus stats (vacío: ninguno).
@export var stats_hint: Label
## Si el contenido no cabe en la pantalla (cartas con muchas mejoras, textos largos), se encoge lo
## justo para que quepa. Encoge el padre de [member appear_root], que debe ser un contenedor a pantalla
## completa que lo centre (y crezca hacia los dos lados): no se puede escalar [member appear_root]
## porque su escala la anima [method UiMotion.appear].
@export var fit_to_screen: bool = false
## Margen con el borde de la pantalla cuando se encoge.
@export_range(0.0, 64.0, 1.0, "suffix:px") var fit_margin: float = 12.0


func _ready() -> void:
	visible = false
	add_to_group(StatsOverlay.ALLOW_GROUP)
	if stats_hint:
		stats_hint.text = tr(&"HUD_STATS_HINT") % InteractionPrompt.key_text(InputActions.SHOW_STATS)
	if fit_to_screen and appear_root:
		# Diferido: cuando llega, el contenedor ya tiene su tamaño nuevo.
		appear_root.resized.connect(_fit_to_screen, CONNECT_DEFERRED)
		get_viewport().size_changed.connect(_fit_to_screen, CONNECT_DEFERRED)


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(InputActions.PAUSE):
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if visible:
		_set_open(false)


func close() -> void:
	if visible:
		_set_open(false)


func is_open() -> bool:
	return visible


## Escala a la que se ve el contenido (1 = cabe entero).
func get_fit() -> float:
	var holder: Control = appear_root.get_parent() as Control if appear_root else null
	return holder.scale.x if holder else 1.0


## Encoge el contenedor de [member appear_root] desde su centro (el de la pantalla) hasta que el
## contenido quepa con [member fit_margin] de margen; si ya cabe, lo deja a su tamaño.
func _fit_to_screen() -> void:
	var holder := appear_root.get_parent() as Control
	var needed := appear_root.size
	if holder == null or needed.x <= 0.0 or needed.y <= 0.0:
		return
	var room := holder.get_viewport_rect().size - Vector2.ONE * fit_margin * 2.0
	var fit := minf(1.0, minf(room.x / needed.x, room.y / needed.y))
	holder.pivot_offset = holder.size / 2.0
	holder.scale = Vector2.ONE * fit


func _set_open(open_panel: bool) -> void:
	visible = open_panel
	if open_panel and appear_root:
		UiMotion.appear(appear_root)
	get_tree().paused = open_panel
	EventBus.cursor_requested.emit(self, open_panel)

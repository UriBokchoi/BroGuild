@abstract
class_name DebugSection
extends VBoxContainer
## Bloque del panel de depuración. Cada sistema añade el suyo como hijo de las secciones del
## panel, sin tocar [DebugPanel]. Muestra nombres internos (stats, estados) a propósito: es una
## herramienta de desarrollo y no se traduce.


## Recibe al jugador, del que sale todo lo que se depura por ahora. Se llama una vez.
@abstract func setup(player: Player) -> void


## Actualiza lo que muestra. Se llama cada frame mientras el panel está visible.
func refresh() -> void:
	pass


## Añade el título del bloque.
func add_title(text: String) -> void:
	var title := make_label(text)
	title.theme_type_variation = &"HeaderSmall"
	add_child(title)


## Añade una fila «nombre: valor» y devuelve la etiqueta del valor para actualizarla.
func add_value_row(row_name: String) -> Label:
	var row := HBoxContainer.new()
	var name_label := make_label(row_name)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var value_label := make_label("")
	row.add_child(value_label)
	add_child(row)
	return value_label


func make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


## Botón que no coge el foco: así Espacio sigue saltando en vez de pulsarlo.
func make_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button

extends Node
## Vida de los botones de toda la interfaz ([UiMotion]): crecen un poco con el ratón encima o con el
## foco y se hunden al pulsarlos. Se engancha a cada [BaseButton] que entra en el árbol
## ([signal SceneTree.node_added]), como hace [code]Sfx[/code] con su clic. Los que se animan por su
## cuenta (las cartas de mejora) están en el grupo [constant SKIP_GROUP] y no se tocan.

## Grupo de los botones que no anima.
const SKIP_GROUP := &"ui_juice_skip"


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	# Los grupos de escena y los de _init ya están puestos al entrar en el árbol.
	if button == null or button.is_in_group(SKIP_GROUP) or button.has_meta(&"ui_juice"):
		return
	button.set_meta(&"ui_juice", true)
	button.mouse_entered.connect(_on_hover.bind(button, true))
	button.mouse_exited.connect(_on_hover.bind(button, false))
	button.focus_entered.connect(_on_hover.bind(button, true))
	button.focus_exited.connect(_on_hover.bind(button, false))
	button.button_down.connect(_on_pressed.bind(button, true))
	button.button_up.connect(_on_pressed.bind(button, false))


func _on_hover(button: BaseButton, inside: bool) -> void:
	if button.disabled:
		return
	UiMotion.scale_to(button, UiMotion.DATA.hover_scale if inside else 1.0)


func _on_pressed(button: BaseButton, down: bool) -> void:
	if button.disabled:
		return
	var resting := UiMotion.DATA.hover_scale if button.is_hovered() or button.has_focus() else 1.0
	UiMotion.scale_to(button, UiMotion.DATA.press_scale if down else resting)

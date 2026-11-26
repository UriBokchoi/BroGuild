class_name UpgradesPanel
extends PanelContainer
## La pestaña «Mejoras» del menú principal: las mejoras permanentes que se compran con bro-monedas
## (una fila por mejora, UpgradeRow), las monedas que quedan y «Reembolsar todo», que devuelve lo
## gastado. Lo compra y lo guarda Save; se nota en la partida siguiente. «Volver» o Esc la cierran.

## Se cerró.
signal closed

## Las mejoras que se pueden comprar, en orden.
@export var catalog: MetaUpgradeCatalog

var _rows: Array[UpgradeRow] = []

@onready var _coins: Label = %Coins
@onready var _list: VBoxContainer = %List
@onready var _scroll: ScrollContainer = %Scroll
@onready var _refund: Button = %Refund
@onready var _refunded: Label = %Refunded
@onready var _back: Button = %Back


func _ready() -> void:
	_back.pressed.connect(close)
	_refund.pressed.connect(refund)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(InputActions.PAUSE):
		close()
		get_viewport().set_input_as_handled()


## Muestra las mejoras con lo comprado hasta ahora.
func open() -> void:
	if Save.profile == null:
		Save.load_profile()
	_build_rows()
	_refunded.visible = false
	_refresh()
	_scroll.scroll_vertical = 0
	UiMotion.reveal(self)
	_back.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## Compra el siguiente nivel de [param upgrade] (si le llegan las monedas) y lo vuelve a pintar.
func buy(upgrade: MetaUpgradeData) -> bool:
	_refunded.visible = false
	var bought := Save.buy_upgrade(upgrade)
	_refresh()
	return bought


## Deshace todas las mejoras y devuelve sus bro-monedas; dice cuántas.
func refund() -> int:
	var refunded := Save.refund_upgrades(catalog)
	_refunded.text = tr(&"UPGRADES_REFUNDED") % refunded
	_refunded.visible = refunded > 0
	_refresh()
	return refunded


## Las filas, en orden.
func get_rows() -> Array[UpgradeRow]:
	return _rows.duplicate()


func _build_rows() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_rows.clear()
	for index: int in catalog.upgrades.size():
		var row := UpgradeRow.new(catalog.upgrades[index], index % 2 == 1)
		row.buy_pressed.connect(buy)
		_list.add_child(row)
		_rows.append(row)


func _refresh() -> void:
	_coins.text = str(Save.profile.bro_coins)
	for row: UpgradeRow in _rows:
		row.refresh(Save.profile)
	_refund.disabled = Save.profile.upgrades.is_empty()

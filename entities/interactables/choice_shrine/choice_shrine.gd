class_name ChoiceShrine
extends Node3D
## Sitio que ofrece elegir un objeto pasivo (el círculo de setas): con «interactuar» tira
## [member choices] objetos distintos de [member items] (con la Suerte del jugador) y los ofrece
## ([signal EventBus.item_choice_offered]; los muestra el [ItemChoicePanel]). Se usa una vez: luego
## se apaga su brillo.

## De dónde salen los objetos.
@export var items: ItemPool
## Cuántos ofrece.
@export_range(1, 6, 1) var choices: int = 3
@export var interactable: Interactable
## Lo que brilla mientras se puede usar.
@export var glow: Node3D

## Azar de lo que ofrece. Si no se asigna antes de entrar en el árbol, el flujo de apuestas de
## [code]Rng[/code].
var rng: RandomNumberGenerator

var _catalog: Array[PassiveItemData] = []
var _used: bool = false


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.GAMBLE)
	_catalog = items.load_catalog()
	interactable.interacted.connect(_on_interacted)


## Ofrece los objetos (tirados con [param luck] puntos de Suerte). Devuelve si los ofreció (una vez).
func offer(luck: float = 0.0) -> bool:
	if _used or _catalog.is_empty():
		return false
	_used = true
	interactable.enabled = false
	glow.visible = false
	EventBus.item_choice_offered.emit(items.roll_several(_catalog, choices, luck, rng))
	return true


func is_used() -> bool:
	return _used


func _on_interacted(by: Node3D) -> void:
	var player := by as Player
	if player:
		offer(player.stats.get_value(&"luck"))

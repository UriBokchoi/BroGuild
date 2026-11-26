class_name KillChest
extends Node3D
## El cofre de la taberna: se abre gratis cuando se han derrotado [member kills_needed] enemigos en
## esta fase (cuenta desde que sale el mapa) y deja elegir entre [member choices] objetos de las
## rarezas de [member items] (azules o mejores; los muestra el [ItemChoicePanel]). Encima, cuántos
## faltan. Una vez por fase.

## De dónde salen los objetos: solo los de sus rarezas.
@export var items: ItemPool
## Cuántos ofrece.
@export_range(1, 6, 1) var choices: int = 3
## Enemigos que hay que derrotar en la fase para abrirlo.
@export_range(1, 100000, 1, "or_greater") var kills_needed: int = 1500
@export var interactable: Interactable
## La tapa, que se abre (gira en X).
@export var lid: Node3D
## Lo que dice cuántos faltan.
@export var progress_label: Label3D
## Ángulo de la tapa abierta.
@export_range(10.0, 180.0, 1.0, "suffix:°") var lid_angle: float = 110.0
@export_range(0.05, 2.0, 0.05, "suffix:s") var lid_time: float = 0.35
## Texto de «interactuar» cuando se puede abrir, y del contador encima (con dos [code]%d[/code]).
@export var prompt_key: StringName = &"INTERACT_KILL_CHEST"
@export var locked_prompt_key: StringName = &"KILL_CHEST_LOCKED"
@export var progress_key: StringName = &"KILL_CHEST_PROGRESS"

## Azar de lo que ofrece. Si no se asigna antes de entrar en el árbol, el flujo de apuestas de
## [code]Rng[/code].
var rng: RandomNumberGenerator

var _catalog: Array[PassiveItemData] = []
var _kills: int = 0
var _opened: bool = false


func _enter_tree() -> void:
	if not EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.connect(_on_enemy_died)


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.GAMBLE)
	_catalog = _eligible(items.load_catalog())
	interactable.interacted.connect(_on_interacted)
	_refresh()


## ¿Se puede abrir ya? (Hay bastantes enemigos derrotados y aún no se abrió.)
func is_ready() -> bool:
	return not _opened and _kills >= kills_needed


func is_open() -> bool:
	return _opened


## Enemigos derrotados que cuenta.
func get_kills() -> int:
	return _kills


## Lo abre y ofrece los objetos (tirados con [param luck] puntos de Suerte). Devuelve si se abrió.
func open(luck: float = 0.0) -> bool:
	if not is_ready() or _catalog.is_empty():
		return false
	_opened = true
	interactable.enabled = false
	if lid:
		create_tween().tween_property(lid, ^"rotation:x", -deg_to_rad(lid_angle), lid_time) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	EventBus.chest_opened.emit()
	EventBus.item_choice_offered.emit(items.roll_several(_catalog, choices, luck, rng))
	_refresh()
	return true


## Solo los objetos de las rarezas de su [member items] (azules o mejores).
func _eligible(catalog: Array[PassiveItemData]) -> Array[PassiveItemData]:
	var eligible: Array[PassiveItemData] = []
	for item: PassiveItemData in catalog:
		if item.rarity and items.rarities.entries.has(item.rarity):
			eligible.append(item)
	return eligible


func _refresh() -> void:
	var left := mini(_kills, kills_needed)
	if progress_label:
		progress_label.visible = not _opened
		progress_label.text = tr(progress_key) % [left, kills_needed]
	interactable.prompt_key = prompt_key if is_ready() else StringName(tr(locked_prompt_key) % [left, kills_needed])


func _on_enemy_died(_enemy: Enemy) -> void:
	if _opened:
		return
	_kills += 1
	# Solo hace falta repintar mientras falte (y al llegar).
	if _kills <= kills_needed:
		_refresh()


func _on_interacted(by: Node3D) -> void:
	var player := by as Player
	if player:
		open(player.stats.get_value(&"luck"))

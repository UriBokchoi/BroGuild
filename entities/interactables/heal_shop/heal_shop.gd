class_name HealShop
extends Node3D
## Sitio donde se paga por vida (la taberna del Brosque): con «interactuar» cobra su coste y cura
## una parte de la vida máxima del jugador (la mitad, siempre). Cada vez cuesta más (y más con la
## dificultad). Con la vida llena no cobra. Lo que pasa sale en el HUD
## ([signal EventBus.announced]): la cura, que falta oro o que ya está bien.

## Cuánto cura y cuánto cuesta.
@export var data: HealShopData
@export var interactable: Interactable
## Aviso de «interactuar» (con un [code]%d[/code]: el coste).
@export var prompt_key: StringName = &""
## Textos del HUD al curar, si falta oro (con un [code]%d[/code]: el coste) y con la vida llena.
@export var healed_key: StringName = &""
@export var denied_key: StringName = &""
@export var full_key: StringName = &""
## Color de esos textos.
@export var announce_color: Color = Color.WHITE

var _difficulty: float = 0.0
var _uses: int = 0


func _enter_tree() -> void:
	if not EventBus.difficulty_changed.is_connected(_on_difficulty_changed):
		EventBus.difficulty_changed.connect(_on_difficulty_changed)


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	_refresh_prompt()


## Oro que cuesta ahora.
func get_cost() -> int:
	return data.cost_at(_difficulty, _uses)


## Veces que se ha usado.
func get_uses() -> int:
	return _uses


## Cura [param health] pagando con [param wallet]. Devuelve si curó (con la vida llena o sin oro, no).
func serve(wallet: WalletComponent, health: HealthComponent) -> bool:
	if health.is_dead() or health.get_current() >= health.get_maximum():
		_announce(full_key, [])
		return false
	var cost := get_cost()
	if not wallet.spend(cost):
		_announce(denied_key, [cost])
		return false
	health.heal(health.get_maximum() * data.heal_fraction)
	_uses += 1
	_refresh_prompt()
	_announce(healed_key, [])
	return true


func _announce(text_key: StringName, args: Array) -> void:
	if not text_key.is_empty():
		EventBus.announced.emit(text_key, args, announce_color)


## El aviso de «interactuar» lleva el coste (el Label que lo muestra no encuentra la clave y lo deja
## tal cual).
func _refresh_prompt() -> void:
	interactable.prompt_key = StringName(tr(prompt_key) % get_cost())


func _on_interacted(by: Node3D) -> void:
	var player := by as Player
	if player:
		serve(player.wallet, player.health)


func _on_difficulty_changed(difficulty: float) -> void:
	_difficulty = difficulty
	_refresh_prompt()

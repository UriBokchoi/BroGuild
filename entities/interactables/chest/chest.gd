class_name Chest
extends Node3D
## Cofre del nivel (GDD §5.2): con «interactuar» cobra su coste en oro y se abre. Sale un objeto
## pasivo con rareza (la Suerte del jugador sube las altas). El HUD lo revela
## ([signal EventBus.item_revealed]) y, al acabar el revelado, el objeto pasa al jugador y el cofre
## desaparece. El coste sube con la dificultad y con cada cofre abierto en la partida: todos los
## cofres cuentan los que se abren por el [code]EventBus[/code]. No pausa el juego. Al abrirse avisa
## ([signal opened]): en la escena, sus destellos dorados.

## Se abrió (con su objeto ya tirado).
signal opened

## Coste, rarezas, objetos y ritmo.
@export var data: ChestData
@export var interactable: Interactable
## Tapa: gira hacia atrás al abrirse (su origen es la bisagra).
@export var lid: Node3D
## Cuerpo que choca (se quita al abrirse).
@export var body: CollisionObject3D
## Grados que gira la tapa al abrirse.
@export_range(10.0, 180.0, 1.0, "suffix:°") var lid_angle: float = 110.0
## Segundos que tarda la tapa en abrirse.
@export_range(0.05, 2.0, 0.05, "suffix:s") var lid_time: float = 0.3
## Segundos que tarda en encogerse y desaparecer tras dar el objeto.
@export_range(0.05, 2.0, 0.05, "suffix:s") var vanish_time: float = 0.35
## Clave del aviso de «interactuar» (con un [code]%d[/code]: el coste).
@export var prompt_key: StringName = &""

## Azar de lo que sale. Si no se asigna antes de entrar en el árbol, el flujo de apuestas de
## [code]Rng[/code].
var rng: RandomNumberGenerator

var _catalog: Array[PassiveItemData] = []
var _difficulty: float = 0.0
var _opened_in_run: int = 0
var _open: bool = false


func _enter_tree() -> void:
	if not EventBus.difficulty_changed.is_connected(_on_difficulty_changed):
		EventBus.difficulty_changed.connect(_on_difficulty_changed)
		EventBus.chest_opened.connect(_on_chest_opened)


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.GAMBLE)
	_catalog = data.items.load_catalog()
	interactable.interacted.connect(_on_interacted)
	_refresh_prompt()


## Oro que cuesta abrirlo ahora.
func get_cost() -> int:
	return data.cost_at(_difficulty, _opened_in_run)


## ¿Ya está abierto?
func is_open() -> bool:
	return _open


## Lo abre pagando con [param wallet]; el objeto (tirado con [param luck] puntos de Suerte) va a
## [param items] al acabar el revelado. Devuelve si se abrió (no se abre si ya lo está, no hay
## objetos o falta oro).
func open(wallet: WalletComponent, items: PassiveInventory, luck: float = 0.0) -> bool:
	if _open or _catalog.is_empty():
		return false
	var cost := get_cost()
	if not wallet.spend(cost):
		EventBus.chest_denied.emit(cost)
		return false
	_open = true
	interactable.enabled = false
	body.process_mode = Node.PROCESS_MODE_DISABLED
	var item := data.items.roll(_catalog, luck, rng)
	opened.emit()
	EventBus.chest_opened.emit()
	EventBus.item_revealed.emit(item, data.reveal_time)
	# La bisagra está detrás (+Z) y el cierre delante (−Z): girar en +X levanta el frente.
	create_tween().tween_property(lid, ^"rotation:x", deg_to_rad(lid_angle), lid_time)
	# Con el juego en pausa, el revelado espera.
	get_tree().create_timer(data.reveal_time, false).timeout.connect(_give.bind(items, item))
	return true


func _give(items: PassiveInventory, item: PassiveItemData) -> void:
	if is_instance_valid(items):
		items.add(item)
	var vanish := create_tween()
	vanish.tween_property(self, ^"scale", Vector3.ONE * 0.01, vanish_time)
	vanish.tween_callback(queue_free)


## El aviso de «interactuar» lleva el coste (el Label que lo muestra no encuentra la clave y lo deja
## tal cual).
func _refresh_prompt() -> void:
	interactable.prompt_key = StringName(tr(prompt_key) % get_cost())


func _on_interacted(by: Node3D) -> void:
	var player := by as Player
	if player:
		open(player.wallet, player.items, player.stats.get_value(&"luck"))


func _on_difficulty_changed(difficulty: float) -> void:
	_difficulty = difficulty
	_refresh_prompt()


func _on_chest_opened() -> void:
	_opened_in_run += 1
	_refresh_prompt()

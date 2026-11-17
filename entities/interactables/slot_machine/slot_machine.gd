class_name SlotMachine
extends Node3D
## Tragaperras del nivel (GDD §5.3): con «interactuar» cobra su coste en oro (sube con la dificultad
## y cada vez que se usa esta máquina) y gira sus rodillos. Avisa por el [code]EventBus[/code] de lo
## que va a salir ([signal EventBus.slot_spun], para el panel del HUD) y, cuando paran, da el premio
## como una recompensa ([code]pickup_collected[/code]) y lo anuncia
## ([signal EventBus.slot_resolved]). No pausa el juego: apostar con la horda encima es el riesgo.

## Símbolos, coste y ritmo.
@export var data: SlotMachineData
@export var interactable: Interactable
## Clave del aviso de «interactuar» (con [code]%d[/code], el coste).
@export var prompt_key: StringName = &""

## Azar de los rodillos. Si no se asigna antes de entrar en el árbol, el flujo de apuestas de
## [code]Rng[/code].
var rng: RandomNumberGenerator

var _uses: int = 0
var _difficulty: float = 0.0
var _spinning: bool = false


func _enter_tree() -> void:
	if not EventBus.difficulty_changed.is_connected(_on_difficulty_changed):
		EventBus.difficulty_changed.connect(_on_difficulty_changed)


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.GAMBLE)
	interactable.interacted.connect(_on_interacted)
	_refresh_prompt()


## Oro que cuesta ahora la siguiente tirada.
func get_cost() -> int:
	return data.cost_at(_difficulty, _uses)


func is_spinning() -> bool:
	return _spinning


## Juega pagando con [param wallet]. Devuelve si giró (no gira si ya está girando o no hay oro).
func play(wallet: WalletComponent) -> bool:
	if _spinning:
		return false
	var cost := get_cost()
	if not wallet.spend(cost):
		EventBus.slot_resolved.emit(&"SLOT_NOT_ENOUGH_GOLD", cost, false)
		return false
	_uses += 1
	_spinning = true
	var results := data.roll(rng)
	EventBus.slot_spun.emit(data, results)
	var jackpot := results.count(results[0]) == results.size()
	var outcome := SlotMachineData.evaluate(results)
	# Con el juego en pausa, los rodillos esperan.
	get_tree().create_timer(data.total_time(), false).timeout.connect(_resolve.bind(outcome, cost, jackpot))
	return true


func _resolve(outcome: SlotOutcome, cost: int, jackpot: bool) -> void:
	_spinning = false
	_refresh_prompt()
	if outcome == null:
		EventBus.slot_resolved.emit(&"SLOT_NOTHING", 0.0, false)
		return
	var value := outcome.value_for(cost)
	EventBus.pickup_collected.emit(outcome.reward, value)
	EventBus.slot_resolved.emit(outcome.text_key, value, jackpot)


## El aviso de «interactuar» lleva el coste (el Label que lo muestra no encuentra la clave y lo deja
## tal cual).
func _refresh_prompt() -> void:
	interactable.prompt_key = StringName(tr(prompt_key) % get_cost())


func _on_interacted(by: Node3D) -> void:
	var player := by as Player
	if player:
		play(player.wallet)


func _on_difficulty_changed(difficulty: float) -> void:
	_difficulty = difficulty
	_refresh_prompt()

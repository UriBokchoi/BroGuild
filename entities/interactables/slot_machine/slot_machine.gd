class_name SlotMachine
extends Node3D
## Tragaperras (GDD §5.3): al usarla cobra oro, cada vez más, y gira sus rodillos; al parar da el
## premio. No pausa el juego: apostar con la horda encima es el riesgo. Tras unas cuantas tiradas,
## revienta.

## Símbolos, coste y ritmo.
@export var data: SlotMachineData
@export var interactable: Interactable
## Modelo que desaparece al reventar.
@export var visual: Node3D
## Cuerpo que choca (se quita al reventar).
@export var body: CollisionObject3D
## Destello de la explosión (oculto hasta entonces).
@export var explosion: GeometryInstance3D
## Segundos que dura la explosión.
@export_range(0.05, 3.0, 0.05, "suffix:s") var explosion_time: float = 0.5
## Tamaño final del destello.
@export_range(0.5, 20.0, 0.1) var explosion_scale: float = 4.0
## Clave del aviso de «interactuar» (con dos [code]%d[/code]: el coste y las tiradas que quedan).
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
	if _spinning or is_exhausted():
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
	else:
		var value := outcome.value_for(cost)
		EventBus.pickup_collected.emit(outcome.reward, value)
		EventBus.slot_resolved.emit(outcome.text_key, value, jackpot)
	if is_exhausted():
		_explode()


## ¿Ya no le quedan tiradas?
func is_exhausted() -> bool:
	return _uses >= data.max_uses


## Revienta: deja de poder usarse y de chocar, el destello crece y se apaga, y desaparece.
func _explode() -> void:
	interactable.enabled = false
	body.process_mode = Node.PROCESS_MODE_DISABLED
	visual.visible = false
	explosion.visible = true
	var blast := create_tween().set_parallel()
	blast.tween_property(explosion, ^"scale", Vector3.ONE * explosion_scale, explosion_time)
	blast.tween_property(explosion, ^"transparency", 1.0, explosion_time)
	blast.chain().tween_callback(queue_free)


## El aviso de «interactuar» lleva el coste (el Label que lo muestra no encuentra la clave y lo deja
## tal cual).
func _refresh_prompt() -> void:
	interactable.prompt_key = StringName(tr(prompt_key) % [get_cost(), data.max_uses - _uses])


func _on_interacted(by: Node3D) -> void:
	var player := by as Player
	if player:
		play(player.wallet)


func _on_difficulty_changed(difficulty: float) -> void:
	_difficulty = difficulty
	_refresh_prompt()

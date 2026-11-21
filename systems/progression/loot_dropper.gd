class_name LootDropper
extends Node
## Lo que sueltan los enemigos y los rompibles.
## - Al morir un enemigo ([code]EventBus.enemy_died[/code]): una gema con su experiencia
##   ([member EnemyStats.xp_reward]) y una moneda con su oro ([member EnemyStats.gold_reward]), que
##   vuela sola hacia el jugador.
## - Al romperse un rompible ([code]EventBus.breakable_broken[/code]): su botín ([BreakableData],
##   más cuanto mayor es la dificultad) en trozos repartidos alrededor.
## - Además, a veces, un extra (un power-up; más adelante, cofres) de una [WeightedTable]: con la
##   probabilidad de botín del jugador ([code]drop_chance[/code]) por el multiplicador de quien lo
##   suelta (×1 un enemigo normal; élites y rompibles, el de sus datos).
## Suelta como mucho [member max_drops_per_tick] recogibles en un tick de física y el resto en los
## siguientes: un golpe que mata a cien enemigos soltaba doscientos de golpe (un tirón). Al empezar
## prepara los de experiencia y oro ([member PickupData.prewarm]), para no crearlos en pleno
## combate.

## Dónde caen los recogibles.
@export var field: PickupField
## Stats del jugador: su dificultad y su probabilidad de botín. Vacío: dificultad 0 y sin extras.
@export var player_stats: StatsComponent
## Recogible de la experiencia.
@export var xp_gem: PickupData
## Recogible del oro.
@export var gold_coin: PickupData
## De qué tabla salen los extras de los enemigos normales (los élites usan la suya).
@export var enemy_drop_table: WeightedTable
## Recogibles que suelta como mucho en un mismo tick de física.
@export_range(1, 1000, 1, "or_greater") var max_drops_per_tick: int = 40

## Azar del reparto. Si no se asigna antes de entrar en el árbol, el flujo de botín de
## [code]Rng[/code].
var rng: RandomNumberGenerator

var _queued: Array[QueuedDrop] = []
var _tick: int = -1
var _dropped_this_tick: int = 0


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.LOOT)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.breakable_broken.connect(_on_breakable_broken)
	for pickup_data: PickupData in [xp_gem, gold_coin]:
		if pickup_data and field:
			field.prewarm(pickup_data, pickup_data.prewarm)


func _physics_process(_delta: float) -> void:
	# Lo que no cupo en ticks anteriores, por orden.
	while not _queued.is_empty() and _room_this_tick():
		var queued: QueuedDrop = _queued.pop_front()
		_release(queued.pickup_data, queued.at, queued.amount)


## Recogibles que esperan para salir en los próximos ticks.
func queued_count() -> int:
	return _queued.size()


func _on_enemy_died(enemy: Enemy) -> void:
	var at := enemy.global_position
	_drop(xp_gem, at, enemy.xp_reward())
	_drop(gold_coin, at, enemy.gold_reward())
	if enemy.is_elite():
		_roll_extra(enemy.elite.drop_table, enemy.elite.drop_chance_multiplier, at)
	else:
		_roll_extra(enemy_drop_table, 1.0, at)


func _on_breakable_broken(data: BreakableData, at: Vector3) -> void:
	var piece := data.amount_at(_stat(&"difficulty")) / data.pieces
	for _index: int in data.pieces:
		var angle := rng.randf_range(0.0, TAU)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * rng.randf_range(0.0, data.spread)
		_drop(data.reward, at + offset, piece)
	_roll_extra(data.drop_table, data.drop_chance_multiplier, at)


## Con la probabilidad de botín por [param multiplier], suelta un extra de [param table].
func _roll_extra(table: WeightedTable, multiplier: float, at: Vector3) -> void:
	if table == null or rng.randf() * 100.0 >= _stat(&"drop_chance") * multiplier:
		return
	var extra := table.pick(rng) as BonusDrop
	if extra:
		_drop(extra.pickup, at, extra.amount)


func _drop(pickup_data: PickupData, at: Vector3, amount: float) -> void:
	if pickup_data == null or amount <= 0.0:
		return
	if _queued.is_empty() and _room_this_tick():
		_release(pickup_data, at, amount)
	else:
		_queued.append(QueuedDrop.new(pickup_data, at, amount))


## ¿Cabe otro recogible en este tick? (Cuenta los ya soltados.)
func _room_this_tick() -> bool:
	var tick := Engine.get_physics_frames()
	if tick != _tick:
		_tick = tick
		_dropped_this_tick = 0
	return _dropped_this_tick < max_drops_per_tick


func _release(pickup_data: PickupData, at: Vector3, amount: float) -> void:
	field.drop(pickup_data, at, amount)
	_dropped_this_tick += 1


func _stat(stat: StringName) -> float:
	return player_stats.get_value(stat) if player_stats else 0.0


## Un recogible que espera su tick para salir.
class QueuedDrop:
	var pickup_data: PickupData
	var at: Vector3
	var amount: float

	func _init(queued_data: PickupData, queued_at: Vector3, queued_amount: float) -> void:
		pickup_data = queued_data
		at = queued_at
		amount = queued_amount

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

## Azar del reparto. Si no se asigna antes de entrar en el árbol, el flujo de botín de
## [code]Rng[/code].
var rng: RandomNumberGenerator


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.LOOT)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.breakable_broken.connect(_on_breakable_broken)


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
	if pickup_data and amount > 0.0:
		field.drop(pickup_data, at, amount)


func _stat(stat: StringName) -> float:
	return player_stats.get_value(stat) if player_stats else 0.0

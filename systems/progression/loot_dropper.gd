class_name LootDropper
extends Node
## Lo que sueltan los enemigos y los rompibles. Al morir un enemigo
## ([code]EventBus.enemy_died[/code]): una gema con su experiencia ([member EnemyStats.xp_reward])
## y una moneda con su oro ([member EnemyStats.gold_reward]), que vuela sola hacia el jugador. Al
## romperse un rompible ([code]EventBus.breakable_broken[/code]): su botín
## ([BreakableData], más cuanto mayor es la dificultad) en trozos repartidos alrededor. Cofres y
## probabilidades de botín llegarán aquí. Rompibles y élites pueden soltar además recogibles
## especiales ([BonusDrop]: imán, comida, bomba), cada uno con su probabilidad.

## Dónde caen los recogibles.
@export var field: PickupField
## Recogible de la experiencia.
@export var xp_gem: PickupData
## Recogible del oro.
@export var gold_coin: PickupData

## Azar del reparto. Si no se asigna antes de entrar en el árbol, el flujo de botín de
## [code]Rng[/code].
var rng: RandomNumberGenerator

## Última dificultad avisada ([code]EventBus.difficulty_changed[/code]).
var _difficulty: float = 0.0


func _enter_tree() -> void:
	# En _enter_tree para no perder el primer aviso, que llega en el _ready del jugador.
	if not EventBus.difficulty_changed.is_connected(_on_difficulty_changed):
		EventBus.difficulty_changed.connect(_on_difficulty_changed)


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.LOOT)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.breakable_broken.connect(_on_breakable_broken)


func _on_enemy_died(enemy: Enemy) -> void:
	_drop(xp_gem, enemy.global_position, enemy.xp_reward())
	_drop(gold_coin, enemy.global_position, enemy.gold_reward())
	if enemy.is_elite():
		_roll_bonus(enemy.elite.bonus_drops, enemy.global_position)


func _on_breakable_broken(data: BreakableData, at: Vector3) -> void:
	var piece := data.amount_at(_difficulty) / data.pieces
	for _index: int in data.pieces:
		var angle := rng.randf_range(0.0, TAU)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * rng.randf_range(0.0, data.spread)
		_drop(data.reward, at + offset, piece)
	_roll_bonus(data.bonus_drops, at)


## Tira cada recogible extra de [param drops] con su probabilidad y suelta los que salen.
func _roll_bonus(drops: Array[BonusDrop], at: Vector3) -> void:
	for bonus: BonusDrop in drops:
		if rng.randf() * 100.0 < bonus.chance:
			_drop(bonus.pickup, at, bonus.amount)


func _drop(pickup_data: PickupData, at: Vector3, amount: float) -> void:
	if pickup_data and amount > 0.0:
		field.drop(pickup_data, at, amount)


func _on_difficulty_changed(difficulty: float) -> void:
	_difficulty = difficulty

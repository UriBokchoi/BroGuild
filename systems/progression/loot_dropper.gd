class_name LootDropper
extends Node
## Lo que sueltan los enemigos al morir (una gema de experiencia y una moneda) y los rompibles al
## romperse (su botín, en trozos). A veces también un extra, como un power-up, según la probabilidad
## de botín del jugador.
##
## Suelta como mucho max_drops_per_tick por tick y deja el resto para los siguientes: un golpe que
## mataba a cien enemigos soltaba doscientos recogibles de golpe y daba un tirón.

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
## Dónde van los cofres que sueltan los élites (en el mundo). Vacío: no sueltan cofres.
@export var chest_parent: Node3D
## Qué cuenta como suelo para dejar un cofre, y cuánto mira hacia abajo.
@export_flags_3d_physics var ground_mask: int = 1
@export_range(0.5, 50.0, 0.5, "suffix:m") var ground_probe: float = 10.0

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
		_roll_chest(enemy.elite, at)
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


## Con la probabilidad del élite, deja su cofre en el suelo donde cayó.
func _roll_chest(elite: EliteData, at: Vector3) -> void:
	if elite.chest == null or not is_instance_valid(chest_parent) or rng.randf() * 100.0 >= elite.chest_chance:
		return
	var chest := elite.chest.instantiate() as Node3D
	chest_parent.add_child(chest)
	chest.global_position = _ground_below(at)
	chest.rotation.y = rng.randf_range(0.0, TAU)


func _ground_below(at: Vector3) -> Vector3:
	var from := at + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * ground_probe, ground_mask)
	var hit := chest_parent.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return at
	var ground: Vector3 = hit["position"]
	return ground


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

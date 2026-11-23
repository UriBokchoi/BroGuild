class_name BossEncounter
extends Node
## El jefe del nivel (GDD §9). Cuenta las llaves que coge el jugador
## ([signal EventBus.boss_key_collected]) y avisa de cuántas lleva
## ([signal EventBus.boss_keys_changed]). Cuando el altar lo pide
## ([signal EventBus.boss_summon_requested]) con las llaves suficientes, o sin ellas al acabar la
## ronda, saca al jefe ahí con el escalado de la dificultad de ese momento, lo anuncia y pasa al HUD
## su vida; sus refuerzos salen por el director ([method WaveDirector.spawn_around]).
## Al vencerlo: paran las oleadas, se retiran los demás enemigos, llega el premio (oro × lo pronto
## que cayó, como un recogible, y un objeto pasivo de rareza alta que el HUD revela) y se avisa de la
## victoria ([signal EventBus.boss_defeated]). Sin [member data], el nivel no tiene jefe.

## El jefe de este nivel (lo pone [RunSystems]).
@export var data: BossData
@export var director: WaveDirector
@export var swarm: EnemySwarm
## Stats del jugador: su Suerte para el objeto del premio.
@export var player_stats: StatsComponent
## Adonde va el objeto del premio.
@export var items: PassiveInventory

## Azar del objeto del premio. Si no se asigna antes de entrar en el árbol, el flujo de botín de
## [code]Rng[/code].
var rng: RandomNumberGenerator

var _keys: int = 0
var _boss: Boss
var _summoned: bool = false
var _catalog: Array[PassiveItemData] = []


func _enter_tree() -> void:
	# En _enter_tree: el altar (del mapa generado) y las llaves pueden avisar antes de nuestro _ready.
	if not EventBus.boss_key_collected.is_connected(_on_key_collected):
		EventBus.boss_key_collected.connect(_on_key_collected)
		EventBus.boss_summon_requested.connect(_on_summon_requested)


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.LOOT)
	if data == null:
		return
	if data.reward_items:
		_catalog = data.reward_items.load_catalog()
	_announce_keys()


## Llaves que lleva el jugador.
func get_keys() -> int:
	return _keys


## ¿Ya salió el jefe en esta partida?
func is_summoned() -> bool:
	return _summoned


## El jefe en juego, o [code]null[/code] si aún no salió.
func get_boss() -> Boss:
	return _boss


## Saca al jefe con los pies en [param at] (una sola vez por partida). Devuelve si salió.
func summon(at: Vector3) -> bool:
	if data == null or _summoned:
		return false
	_boss = swarm.spawn(data.enemy, at) as Boss
	if _boss == null:
		push_error("BossEncounter: la escena de '%s' no tiene raíz Boss." % data.enemy.id)
		return false
	_summoned = true
	_boss.health.health_changed.connect(EventBus.boss_health_changed.emit)
	_boss.summon_requested.connect(_on_summon_minions)
	_boss.died.connect(_on_boss_died, CONNECT_ONE_SHOT)
	EventBus.boss_spawned.emit(data.enemy.name_key)
	_boss.boost(data.scaling_at(director.get_difficulty()))
	if not data.arrival_keys.is_empty():
		EventBus.level_intro.emit(data.arrival_keys)
	return true


func _announce_keys() -> void:
	EventBus.boss_keys_changed.emit(_keys, data.keys_needed)


## El premio: oro por el multiplicador de rapidez (como un recogible) y un objeto que el HUD revela y
## llega al jugador al acabar el revelado. Devuelve el multiplicador.
func _give_reward(minutes: float) -> float:
	var bonus := data.bonus_at(minutes)
	EventBus.pickup_collected.emit(&"gold", data.reward_gold * bonus)
	var luck := player_stats.get_value(&"luck") if player_stats else 0.0
	var item: PassiveItemData = null
	if data.reward_items:
		item = data.reward_items.roll(_catalog, luck, rng)
	if item:
		EventBus.item_revealed.emit(item, data.reveal_time)
		get_tree().create_timer(data.reveal_time, false).timeout.connect(_hand_item.bind(item))
	return bonus


func _hand_item(item: PassiveItemData) -> void:
	if is_instance_valid(items):
		items.add(item)


func _on_key_collected() -> void:
	if data == null:
		return
	_keys += 1
	_announce_keys()


func _on_summon_requested(at: Vector3, forced: bool) -> void:
	if data and (forced or _keys >= data.keys_needed):
		summon(at)


func _on_summon_minions(enemy: EnemyData, count: int, center: Vector3, min_distance: float, max_distance: float) -> void:
	director.spawn_around(enemy, center, count, min_distance, max_distance)


func _on_boss_died(_enemy: Enemy) -> void:
	var seconds := director.get_elapsed()
	director.stop(false)
	# Los demás se retiran; el jefe termina de caer.
	swarm.clear(true)
	var bonus := _give_reward(seconds / 60.0)
	EventBus.boss_defeated.emit(data.victory_key, seconds, bonus)

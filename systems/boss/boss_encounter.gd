class_name BossEncounter
extends Node
## El jefe del nivel (GDD §9). Cuenta las llaves del jugador y saca al jefe cuando su portal lo pide
## (con las llaves, o sin ellas al acabar la ronda), más fuerte cuanto más alta sea la dificultad.
##
## Al vencerlo da el premio y su portal se abre, pero las oleadas siguen. Se gana la partida al
## cruzar el portal, o muriendo pasado el final de la ronda con el jefe ya vencido. En un tier que no
## es el último, cruzar el portal pasa al siguiente (stage_cleared). Sin data, no hay jefe.

## Se cruzó el portal de un jefe que no acaba la partida: toca la fase siguiente.
signal stage_cleared

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
## Si cruzar el portal gana la partida (no, en un tier que no es el último: pasa al siguiente).
var ends_run: bool = true
## Si morir con el jefe vencido gana aunque la ronda no haya acabado (la arena del jefe final).
var death_wins: bool = false

var _keys: int = 0
var _boss: Boss
var _summoned: bool = false
var _catalog: Array[PassiveItemData] = []
## Jefe vencido, con el premio por rapidez de ese momento.
var _defeated: bool = false
var _bonus: float = 1.0
var _won: bool = false
var _cleared: bool = false


func _enter_tree() -> void:
	# En _enter_tree: el portal (del mapa generado) y las llaves pueden avisar antes de nuestro _ready.
	if not EventBus.boss_key_collected.is_connected(_on_key_collected):
		EventBus.boss_key_collected.connect(_on_key_collected)
		EventBus.boss_summon_requested.connect(_on_summon_requested)
		EventBus.level_exit_reached.connect(_on_level_exit_reached)
		EventBus.player_died.connect(_on_player_died)


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.LOOT)
	_prepare()


## Vuelve a empezar con el jefe [param boss] (el de la fase siguiente): sin llaves y sin jefe.
func reset(boss: BossData) -> void:
	data = boss
	_keys = 0
	_boss = null
	_summoned = false
	_defeated = false
	_bonus = 1.0
	_cleared = false
	_catalog.clear()
	_prepare()


func _prepare() -> void:
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
	_boss.boost(director.stage_boost())
	if not data.arrival_keys.is_empty():
		EventBus.level_intro.emit(data.arrival_keys)
	return true


func _announce_keys() -> void:
	if data.keys_needed > 0:
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


## ¿Ya está vencido el jefe?
func is_defeated() -> bool:
	return _defeated


## ¿Se ganó ya la partida?
func is_won() -> bool:
	return _won


func _on_boss_died(_enemy: Enemy) -> void:
	var seconds := director.get_elapsed()
	_defeated = true
	_bonus = _give_reward(seconds / 60.0)
	EventBus.boss_defeated.emit(data.victory_key, seconds, _bonus)
	if not data.defeated_keys.is_empty():
		EventBus.level_intro.emit(data.defeated_keys)


## Gana la partida (una vez): paran las oleadas, se retiran los enemigos y se avisa.
func _win() -> void:
	if _won:
		return
	_won = true
	var seconds := director.get_elapsed()
	director.stop(false)
	swarm.clear(true)
	EventBus.run_won.emit(data.victory_key, seconds, _bonus)


func _on_level_exit_reached() -> void:
	if not _defeated:
		return
	if ends_run:
		_win()
	elif not _cleared:
		_cleared = true
		stage_cleared.emit()


## Morir con el jefe vencido y la ronda terminada (en la prórroga) también es ganar, si este jefe
## acaba la partida. En la arena final ([member death_wins]), aunque la ronda no haya acabado.
func _on_player_died() -> void:
	if not _defeated or not ends_run:
		return
	if death_wins or (director.data and director.data.is_overtime(director.get_elapsed())):
		_win()

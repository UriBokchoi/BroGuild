class_name MiniBossEncounter
extends Node
## Los minibosses de la ronda: a su minuto avisan con un texto y salen cerca del jugador, más fuertes
## con la dificultad. Al vencer a uno da su premio (oro y un objeto que el HUD revela). Su reloj
## solo corre con las oleadas en marcha, y pueden coincidir con el jefe.

@export var director: WaveDirector
## Stats del jugador: su Suerte para el objeto del premio.
@export var player_stats: StatsComponent
## Adonde va el objeto del premio.
@export var items: PassiveInventory

## Azar del objeto del premio. Si no se asigna antes de entrar en el árbol, el flujo de botín de
## [code]Rng[/code].
var rng: RandomNumberGenerator

## Siguiente miniboss por avisar o sacar, y si ya se avisó.
var _index: int = 0
var _warned: bool = false
## Minibosses en juego y sus datos.
var _alive: Dictionary[Boss, MiniBossData] = {}


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.LOOT)


func _physics_process(_delta: float) -> void:
	if director == null or director.data == null or not director.is_running():
		return
	var plan := director.data.mini_bosses
	if _index >= plan.size():
		return
	var next := plan[_index]
	var elapsed := director.get_elapsed()
	if not _warned and elapsed >= next.at_seconds() - next.warning_seconds:
		_warned = true
		if not next.announce_key.is_empty():
			EventBus.announced.emit(next.announce_key, [], next.announce_color)
	if elapsed >= next.at_seconds():
		_index += 1
		_warned = false
		summon(next)


## Saca a [param data] cerca del objetivo del director, ya. Devuelve el miniboss, o [code]null[/code]
## si no hubo sitio o su escena no es un [Boss].
func summon(data: MiniBossData) -> Boss:
	var center := director.target.global_position
	var modifiers := data.scaling_at(director.get_difficulty())
	var enemy := director.spawn_one_around(data.enemy, center, data.min_distance, data.max_distance, modifiers)
	var boss := enemy as Boss
	if boss == null:
		if enemy:
			push_error("MiniBossEncounter: la escena de '%s' no tiene raíz Boss." % data.enemy.id)
		return null
	_alive[boss] = data
	boss.health.health_changed.connect(_on_health_changed)
	boss.died.connect(_on_died, CONNECT_ONE_SHOT)
	EventBus.mini_boss_spawned.emit(data.enemy.name_key)
	EventBus.mini_boss_health_changed.emit(boss.health.get_current(), boss.health.get_maximum())
	return boss


## Minibosses en juego ahora.
func alive() -> Array[Boss]:
	var bosses: Array[Boss] = []
	bosses.assign(_alive.keys())
	return bosses


func _on_health_changed(current: float, maximum: float) -> void:
	EventBus.mini_boss_health_changed.emit(current, maximum)


func _on_died(enemy: Enemy) -> void:
	var boss := enemy as Boss
	if not _alive.has(boss):
		return
	var data := _alive[boss]
	_alive.erase(boss)
	# Sale del pool y podría volver a usarse: ya no es nuestro.
	boss.health.health_changed.disconnect(_on_health_changed)
	EventBus.mini_boss_defeated.emit(data.enemy.name_key)
	_give_reward(data)


## El premio: oro (como un recogible) y un objeto que el HUD revela y llega al acabar el revelado.
func _give_reward(data: MiniBossData) -> void:
	if data.reward_gold > 0.0:
		EventBus.pickup_collected.emit(&"gold", data.reward_gold)
	if data.reward_items == null:
		return
	var luck := player_stats.get_value(&"luck") if player_stats else 0.0
	var item := data.reward_items.roll(data.reward_items.load_catalog(), luck, rng)
	if item == null:
		return
	EventBus.item_revealed.emit(item, data.reveal_time)
	get_tree().create_timer(data.reveal_time, false).timeout.connect(_hand_item.bind(item))


func _hand_item(item: PassiveItemData) -> void:
	if is_instance_valid(items):
		items.add(item)

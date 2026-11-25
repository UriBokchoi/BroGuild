class_name RunRecorder
extends Node
## Apunta lo que pasa en la partida (enemigos, élites, daño, oro, nivel y tiempo) escuchando el
## EventBus. Deja de apuntar al morir o al ganar, para que los resultados se queden como estaban, y
## al final guarda la partida en los récords (si record_runs).
##
## La muerte se atiende al final del fotograma: si cuenta como victoria, se apunta la victoria.

## Jugador de la partida (su personaje, para la clasificación).
@export var player: Player
## Pactos sellados en la partida (para apuntarlos con la build). Vacío: ninguno.
@export var pact_panel: PactPanel
## Cuántas bro-monedas dan élites y jefes (vacío: ninguna). Se suman al perfil al acabar.
@export var bro_coin_data: BroCoinData
## Si al acabar apunta la partida en la clasificación (sí el de las partidas de verdad, en
## [code]run_systems.tscn[/code]; los tests la llevan a otro archivo: [code]tests/hooks/pre_run.gd[/code]).
@export var record_runs: bool = false

## Lo apuntado hasta ahora.
var stats := RunStats.new()
## Puesto que sacó en la clasificación (desde 0), o −1 si no entró o aún no se apuntó.
var place: int = -1

## Último oro conocido del jugador, para sumar solo lo que gana.
var _gold: float = 0.0
## Hay una ronda en marcha: el tiempo lo da su reloj.
var _round_running: bool = false
## Tiempo de antes de la ronda en marcha (en un nivel con tiers, el reloj vuelve a 0 en cada fase).
var _banked: float = 0.0
## Empezó otra fase: la próxima ronda suma a lo que ya se llevaba.
var _bank_next_round: bool = false
var _stopped: bool = false


func _enter_tree() -> void:
	# En _enter_tree para no perder los primeros avisos, que llegan en el _ready del jugador.
	_connect(EventBus.enemy_died, _on_enemy_died)
	_connect(EventBus.enemy_damaged, _on_enemy_damaged)
	_connect(EventBus.player_gold_changed, _on_gold_changed)
	_connect(EventBus.player_xp_changed, _on_xp_changed)
	_connect(EventBus.run_clock_changed, _on_clock_changed)
	_connect(EventBus.player_died, _on_player_died)
	_connect(EventBus.run_won, _on_run_won)
	_connect(EventBus.stage_started, _on_stage_started)
	_connect(EventBus.boss_defeated, _on_boss_defeated)


func _physics_process(delta: float) -> void:
	if not _stopped and not _round_running:
		stats.seconds += delta


## ¿Ya terminó (murió el jugador)?
func is_stopped() -> bool:
	return _stopped


func _connect(event: Signal, handler: Callable) -> void:
	if not event.is_connected(handler):
		event.connect(handler)


func _on_enemy_died(enemy: Enemy) -> void:
	if _stopped:
		return
	stats.kills += 1
	if enemy.is_elite():
		stats.elite_kills += 1
		if bro_coin_data:
			stats.bro_coins += bro_coin_data.per_elite


func _on_boss_defeated(_victory_key: StringName, _seconds: float, _bonus: float) -> void:
	if not _stopped and bro_coin_data:
		stats.bro_coins += bro_coin_data.per_boss


func _on_enemy_damaged(_position: Vector3, amount: float, _info: DamageInfo) -> void:
	if not _stopped:
		stats.damage_dealt += amount


func _on_gold_changed(gold: float) -> void:
	if not _stopped and gold > _gold:
		stats.gold_earned += gold - _gold
	_gold = gold


func _on_xp_changed(_current: float, _needed: float, level: int) -> void:
	if not _stopped:
		stats.level = level


func _on_clock_changed(seconds: float, _overtime: bool) -> void:
	if _stopped:
		return
	if seconds >= 0.0 and not _round_running and _bank_next_round:
		_banked = stats.seconds - seconds
		_bank_next_round = false
	_round_running = seconds >= 0.0
	if _round_running:
		stats.seconds = _banked + seconds


func _on_player_died() -> void:
	# Al final del fotograma: si morir cuenta como victoria, el aviso llega mientras tanto y manda.
	_stop_with_death.call_deferred()


func _stop_with_death() -> void:
	if _stopped:
		return
	_stopped = true
	_record()


func _on_run_won(_victory_key: StringName, seconds: float, bonus: float) -> void:
	if _stopped:
		return
	stats.won = true
	stats.boss_bonus = bonus
	stats.seconds = _banked + seconds
	_stopped = true
	_record()


func _on_stage_started(name_key: StringName, index: int, _count: int) -> void:
	if _stopped:
		return
	stats.stage_key = name_key
	if index > 0:
		_bank_next_round = true


## Apunta la partida en la clasificación (si se pide).
func _record() -> void:
	if not record_runs:
		return
	var character: CharacterData = player.character if is_instance_valid(player) else null
	var record := RunRecord.create(stats, character, RunState.level, RunState.tier)
	_add_build(record)
	place = Save.record_run(record)
	Save.add_bro_coins(stats.bro_coins)


## Apunta en [param record] la build del jugador: armas y runas con su nivel, objetos con sus copias
## y pactos sellados.
func _add_build(record: RunRecord) -> void:
	if not is_instance_valid(player):
		return
	for weapon: Weapon in player.weapons.get_weapons():
		record.weapons[String(weapon.data.id)] = weapon.level
	for rune: RuneData in player.runes.get_runes():
		record.runes[String(rune.id)] = player.runes.get_level(rune)
	for item: PassiveItemData in player.items.get_items():
		record.items[String(item.id)] = player.items.count(item)
	if is_instance_valid(pact_panel):
		for pact: PactData in pact_panel.get_sealed():
			record.pacts.append(String(pact.name_key))

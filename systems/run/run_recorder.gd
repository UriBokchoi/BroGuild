class_name RunRecorder
extends Node
## Apunta lo que pasa en la partida en un [RunStats], escuchando el [code]EventBus[/code]: enemigos
## y élites derrotados, daño infligido, oro ganado, nivel y tiempo. El tiempo es el del reloj de la
## ronda mientras hay una en marcha; si no, el que lleva el nivel. Deja de apuntar al morir el
## jugador o al vencer al jefe (con su premio por rapidez), así los resultados se quedan como estaban
## en ese momento.

## Lo apuntado hasta ahora.
var stats := RunStats.new()

## Último oro conocido del jugador, para sumar solo lo que gana.
var _gold: float = 0.0
## Hay una ronda en marcha: el tiempo lo da su reloj.
var _round_running: bool = false
var _stopped: bool = false


func _enter_tree() -> void:
	# En _enter_tree para no perder los primeros avisos, que llegan en el _ready del jugador.
	_connect(EventBus.enemy_died, _on_enemy_died)
	_connect(EventBus.enemy_damaged, _on_enemy_damaged)
	_connect(EventBus.player_gold_changed, _on_gold_changed)
	_connect(EventBus.player_xp_changed, _on_xp_changed)
	_connect(EventBus.run_clock_changed, _on_clock_changed)
	_connect(EventBus.player_died, _on_player_died)
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
	_round_running = seconds >= 0.0
	if _round_running:
		stats.seconds = seconds


func _on_player_died() -> void:
	_stopped = true


func _on_boss_defeated(_victory_key: StringName, seconds: float, bonus: float) -> void:
	if _stopped:
		return
	stats.won = true
	stats.boss_bonus = bonus
	stats.seconds = seconds
	_stopped = true

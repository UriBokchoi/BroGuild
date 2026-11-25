extends Node
## Estado de la partida en curso: sus datos y su ciclo de vida (empezar y
## terminar). La lógica de gameplay vive en systems/, nunca aquí.

## true entre start_run() y end_run().
var is_running: bool = false
## Personaje elegido. Vacío: el que traiga el jugador por defecto. Sobrevive a recargar el nivel
## (reintentar sigue con el mismo personaje).
var character: CharacterData
## Nivel elegido (o [code]null[/code] si se juega un nivel ejecutado solo).
var level: LevelData
## Tier elegido (en un nivel con tiers): la partida pasa por los tiers del 1 a este.
var tier: int = 1
## Semilla de la partida en curso (la última que empezó).
var run_seed: int = 0
## Lo que suman a la base del jugador las mejoras permanentes compradas (las pone Game al empezar
## cada partida). Vacío: nada (un nivel ejecutado solo).
var bonuses: StatModifierSet
## Lo que aún no se ha desbloqueado con misiones (armas y personajes): no sale en la partida. Lo pone
## Game al empezar cada partida.
var locked: Array[Resource] = []


## Empieza una partida nueva. Si ya había una, la termina antes (reinicio).
func start_run(new_seed: int) -> void:
	if is_running:
		end_run()
	run_seed = new_seed
	Rng.seed_run(new_seed)
	is_running = true
	EventBus.run_started.emit(new_seed)


## Termina la partida en curso. Sin partida en curso no hace nada.
func end_run() -> void:
	if not is_running:
		return
	is_running = false
	# Lo de esta partida (la siguiente lo vuelve a poner).
	bonuses = null
	locked = []
	EventBus.run_ended.emit()

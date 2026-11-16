extends Node
## Estado de la partida en curso: sus datos y su ciclo de vida (empezar y
## terminar). La lógica de gameplay vive en systems/, nunca aquí.

## true entre start_run() y end_run().
var is_running: bool = false
## Personaje elegido. Vacío: el que traiga el jugador por defecto. Sobrevive a recargar el nivel
## (reintentar sigue con el mismo personaje).
var character: CharacterData


## Empieza una partida nueva. Si ya había una, la termina antes (reinicio).
func start_run(run_seed: int) -> void:
	if is_running:
		end_run()
	Rng.seed_run(run_seed)
	is_running = true
	EventBus.run_started.emit(run_seed)


## Termina la partida en curso. Sin partida en curso no hace nada.
func end_run() -> void:
	if not is_running:
		return
	is_running = false
	EventBus.run_ended.emit()

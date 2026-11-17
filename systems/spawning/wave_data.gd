class_name WaveData
extends Resource
## Cómo salen los enemigos con el tiempo (GDD §6, «Director de oleadas»): una curva de enemigos por
## segundo que sube con los minutos, un pico al final de cada intervalo, un máximo de enemigos a la
## vez y qué enemigos pueden salir. Los valores viven en [code]data/waves/[/code]; aquí todo vale
## 0 o vacío a propósito.

@export_group("rate")
## Enemigos por segundo (y) según los minutos de partida (x).
@export var spawn_rate: Curve
## Segundos entre picos; 0 = sin picos. El pico ocupa el final de cada intervalo.
@export_range(0.0, 600.0, 1.0, "or_greater", "suffix:s") var peak_interval: float = 0.0
## Segundos que dura cada pico.
@export_range(0.0, 120.0, 0.5, "or_greater", "suffix:s") var peak_duration: float = 0.0
## Multiplica los enemigos por segundo durante un pico.
@export_range(1.0, 20.0, 0.1, "or_greater") var peak_multiplier: float = 1.0

@export_group("limits")
## Enemigos en juego a la vez como mucho (rendimiento y legibilidad).
@export_range(1, 2000, 1, "or_greater") var max_alive: int = 0
## Distancia mínima y máxima al jugador a la que aparecen.
@export_range(1.0, 200.0, 0.5, "or_greater", "suffix:m") var min_spawn_distance: float = 0.0
@export_range(1.0, 200.0, 0.5, "or_greater", "suffix:m") var max_spawn_distance: float = 0.0

@export_group("enemies")
@export var enemies: Array[WaveEnemy] = []

@export_group("elites")
## Probabilidad (%) de que cada enemigo salga élite (y) según los minutos de partida (x). Vacía:
## nunca.
@export var elite_chance: Curve
## Cómo son los élites.
@export var elite: EliteData


## Probabilidad (%) de que un enemigo que sale a los [param seconds] de partida sea élite.
func elite_chance_at(seconds: float) -> float:
	if elite_chance == null or elite == null:
		return 0.0
	return elite_chance.sample(seconds / 60.0)


## Enemigos por segundo a los [param seconds] de partida, con los picos.
func rate_at(seconds: float) -> float:
	if spawn_rate == null:
		return 0.0
	var rate := spawn_rate.sample(seconds / 60.0)
	return rate * peak_multiplier if is_peak(seconds) else rate


## ¿Hay pico a los [param seconds] de partida?
func is_peak(seconds: float) -> bool:
	if peak_interval <= 0.0 or peak_duration <= 0.0:
		return false
	return fmod(seconds, peak_interval) >= peak_interval - peak_duration


## Un enemigo al azar entre los disponibles a los [param seconds] de partida, según sus pesos.
## [code]null[/code] si no hay ninguno.
func pick_enemy(seconds: float, rng: RandomNumberGenerator) -> EnemyData:
	var minutes := seconds / 60.0
	var total := 0.0
	for entry: WaveEnemy in enemies:
		if entry.from_minute <= minutes:
			total += entry.weight
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for entry: WaveEnemy in enemies:
		if entry.from_minute > minutes:
			continue
		roll -= entry.weight
		if roll < 0.0:
			return entry.enemy
	return null

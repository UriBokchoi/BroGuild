class_name WaveData
extends Resource
## Cómo salen los enemigos de una ronda (GDD §6, «Director de oleadas»): una curva de enemigos por
## segundo, un pico al final de cada intervalo, un máximo de enemigos a la vez, qué enemigos pueden
## salir, cuántos salen élites, cómo se hacen más fuertes y cuánto dura la ronda (pasada, llegan los
## muy fuertes). Los valores viven en [code]data/waves/[/code]; aquí todo vale 0 o vacío a
## propósito.
##
## Las curvas van según la [b]dificultad[/b] (x), no según el tiempo: la stat
## [code]difficulty[/code] del jugador, que sube sola 1 por minuto (así, sin bonus, dificultad 5 es
## el minuto 5) y con objetos o runas (más riesgo, más recompensa). Los picos y la duración de la
## ronda sí van por el reloj.

@export_group("round")
## Minutos que dura la ronda. Pasados, el reloj del HUD se pone en rojo (y llegará el jefe).
@export_range(0.0, 120.0, 0.5, "or_greater", "suffix:min") var round_minutes: float = 0.0

@export_group("rate")
## Enemigos por segundo (y) según la dificultad (x).
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
## Probabilidad (%) de que cada enemigo salga élite (y) según la dificultad (x). Vacía: nunca.
@export var elite_chance: Curve
## Cómo son los élites.
@export var elite: EliteData

@export_group("hordes")
## Hordas de la ronda (en el orden en que salen).
@export var hordes: Array[HordeData] = []

@export_group("scaling")
## Stats de los enemigos que se multiplican con la dificultad (vida, daño…): cada enemigo sale con
## los multiplicadores de la dificultad de ese momento.
@export var stat_scaling: Array[StatScaling] = []


## ¿Ya pasó la ronda a los [param seconds] de partida? (Sin duración, nunca.)
func is_overtime(seconds: float) -> bool:
	return round_minutes > 0.0 and seconds >= round_minutes * 60.0


## Mejoras con las que sale un enemigo con dificultad [param difficulty] (un multiplicador por cada
## [member stat_scaling]), o [code]null[/code] si no hay escalado.
func scaling_at(difficulty: float) -> StatModifierSet:
	return scaling_for(stat_scaling, difficulty)


## Probabilidad (%) de que un enemigo que sale con dificultad [param difficulty] sea élite.
func elite_chance_at(difficulty: float) -> float:
	if elite_chance == null or elite == null:
		return 0.0
	return elite_chance.sample(difficulty)


## Enemigos por segundo con dificultad [param difficulty], a los [param seconds] de partida (los
## picos van por el reloj).
func rate_at(difficulty: float, seconds: float) -> float:
	if spawn_rate == null:
		return 0.0
	var rate := spawn_rate.sample(difficulty)
	return rate * peak_multiplier if is_peak(seconds) else rate


## ¿Hay pico a los [param seconds] de partida?
func is_peak(seconds: float) -> bool:
	if peak_interval <= 0.0 or peak_duration <= 0.0:
		return false
	return fmod(seconds, peak_interval) >= peak_interval - peak_duration


## Un enemigo al azar entre los disponibles con dificultad [param difficulty], según sus pesos.
## [code]null[/code] si no hay ninguno.
func pick_enemy(difficulty: float, rng: RandomNumberGenerator) -> EnemyData:
	var total := 0.0
	for entry: WaveEnemy in enemies:
		if entry.from_difficulty <= difficulty:
			total += entry.weight
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for entry: WaveEnemy in enemies:
		if entry.from_difficulty > difficulty:
			continue
		roll -= entry.weight
		if roll < 0.0:
			return entry.enemy
	return null


## Mejoras de [param scalings] con dificultad [param difficulty]: un multiplicador por cada uno, o
## [code]null[/code] si no hay ninguno. Lo usan las oleadas y los jefes ([BossData]).
static func scaling_for(scalings: Array[StatScaling], difficulty: float) -> StatModifierSet:
	if scalings.is_empty():
		return null
	var modifiers := StatModifierSet.new()
	for scaling: StatScaling in scalings:
		var factor := scaling.multiplier_at(difficulty)
		modifiers.stat_modifiers.append(StatModifier.create(scaling.stat, StatModifier.Kind.MULTIPLIER, factor))
	return modifiers

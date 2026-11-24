class_name BossData
extends Resource
## El jefe de un nivel (GDD §9): qué enemigo es, cuántas llaves hacen falta, qué se dice al salir y al
## vencerlo, cómo crece con la dificultad (con curvas propias) y su premio: oro, más cuanto antes
## caiga, y un objeto de rareza alta. Viven en data/bosses/.

## El jefe.
@export var enemy: EnemyData
## Llaves que hacen falta para invocarlo antes de que se acabe la ronda.
@export_range(0, 20, 1) var keys_needed: int = 0
## Mensajes al salir (claves de traducción; el primero, grande).
@export var arrival_keys: Array[StringName] = []
## Mensajes al vencerlo, que explican que ahora hay que cruzar su portal (claves de traducción; el
## primero, grande).
@export var defeated_keys: Array[StringName] = []
## Título de la pantalla de victoria (clave de traducción).
@export var victory_key: StringName = &""

@export_group("scaling")
## Stats del jefe que se multiplican con la dificultad del momento en que sale.
@export var stat_scaling: Array[StatScaling] = []

@export_group("reward")
## Oro del premio antes del multiplicador por rapidez.
@export_range(0.0, 100000.0, 1.0, "or_greater") var reward_gold: float = 0.0
## Multiplicador del premio (y) según los minutos de partida al vencerlo (x). Vacío: 1.
@export var early_bonus: Curve
## De dónde sale el objeto del premio (rarezas altas).
@export var reward_items: ItemPool
## Segundos que tarda en revelarse el objeto del premio.
@export_range(0.1, 10.0, 0.05, "suffix:s") var reveal_time: float = 0.0


## Mejoras con las que sale con dificultad [param difficulty] (o [code]null[/code] sin escalado).
func scaling_at(difficulty: float) -> StatModifierSet:
	return StatScaling.modifiers_for(stat_scaling, difficulty)


## Multiplicador del premio si cae a los [param minutes] minutos de partida.
func bonus_at(minutes: float) -> float:
	return early_bonus.sample(minutes) if early_bonus else 1.0

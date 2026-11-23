class_name MiniBossData
extends Resource
## Un miniboss de las oleadas de un nivel (en [member WaveData.mini_bosses]): un [Boss] que sale a su
## minuto cerca del jugador, avisado antes con un texto, con su barra de vida en el HUD. Al vencerlo da
## un premio de oro y un objeto pasivo que el HUD revela. No para la ronda ni cuenta para el máximo de
## enemigos a la vez. Lo saca un [MiniBossEncounter].

## El enemigo (su escena debe tener raíz [Boss]).
@export var enemy: EnemyData
## Minuto de la ronda en que sale.
@export_range(0.0, 60.0, 0.05, "suffix:min") var at_minute: float = 0.0
## Segundos antes de salir en que se avisa.
@export_range(0.0, 30.0, 0.5, "suffix:s") var warning_seconds: float = 0.0
## Texto del aviso (clave de traducción) y su color.
@export var announce_key: StringName = &""
@export var announce_color: Color = Color.WHITE
## Distancia al jugador a la que sale: cerca, para que se vea llegar, pero no encima.
@export_range(0.0, 100.0, 0.5, "suffix:m") var min_distance: float = 0.0
@export_range(0.0, 100.0, 0.5, "suffix:m") var max_distance: float = 0.0

@export_group("scaling")
## Stats del miniboss que se multiplican con la dificultad del momento en que sale.
@export var stat_scaling: Array[StatScaling] = []

@export_group("reward")
## Oro del premio.
@export_range(0.0, 100000.0, 1.0, "or_greater") var reward_gold: float = 0.0
## De dónde sale el objeto del premio. Vacío: sin objeto.
@export var reward_items: ItemPool
## Segundos que tarda en revelarse el objeto del premio.
@export_range(0.1, 10.0, 0.05, "suffix:s") var reveal_time: float = 0.0


## Segundo de la ronda en que sale.
func at_seconds() -> float:
	return at_minute * 60.0


## Mejoras con las que sale con dificultad [param difficulty] (o [code]null[/code] sin escalado).
func scaling_at(difficulty: float) -> StatModifierSet:
	return StatScaling.modifiers_for(stat_scaling, difficulty)

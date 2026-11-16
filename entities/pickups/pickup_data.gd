class_name PickupData
extends Resource
## Un tipo de recogible (gema de experiencia; más adelante fichas, curas…): su escena, qué da al
## recogerlo y cómo vuela hacia quien lo recoge. Los valores viven en [code]data/pickups/[/code];
## aquí todo vale 0 o vacío a propósito.

## Identificador estable (pool).
@export var id: StringName = &""
## Escena del recogible: su raíz es un [Pickup].
@export var scene: PackedScene
## Qué da al recogerlo. Lo escucha el sistema que lo usa por [code]EventBus.pickup_collected[/code]
## (p. ej. [code]experience[/code] → [ExperienceComponent]).
@export var reward: StringName = &""

@export_group("magnet")
## Velocidad a la que empieza a volar hacia quien lo recoge al entrar en su radio de recogida.
@export_range(0.0, 50.0, 0.1, "or_greater", "suffix:m/s") var start_speed: float = 0.0
## Aceleración mientras vuela (cuanto más tarda, más rápido va).
@export_range(0.0, 500.0, 1.0, "or_greater", "suffix:m/s²") var acceleration: float = 0.0
## Distancia a la que se recoge.
@export_range(0.05, 5.0, 0.05, "or_greater", "suffix:m") var collect_radius: float = 0.0
## Altura sobre los pies de quien lo recoge hacia la que vuela (el pecho).
@export_range(0.0, 3.0, 0.05, "suffix:m") var target_height: float = 0.0

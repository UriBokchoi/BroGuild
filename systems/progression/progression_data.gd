class_name ProgressionData
extends Resource
## Stats de progresión y botín: experiencia y oro ganados, suerte, radio de recogida y ranuras
## abiertas de armas y runas. Los valores viven en [code]data/player/progression.tres[/code]; aquí
## todo vale 0 a propósito. Su efecto exacto está en el GDD (§6, «Stats del personaje»).

@export_group("progression")
## Multiplica la experiencia que ganas.
@export_range(0.0, 1000.0, 1.0, "or_greater", "suffix:%") var xp_gain: float = 0.0
## Multiplica el oro que ganas.
@export_range(0.0, 1000.0, 1.0, "or_greater", "suffix:%") var currency_gain: float = 0.0
## Suerte: desplaza los pesos de las rarezas hacia arriba (GDD §5).
@export_range(0.0, 100.0, 1.0, "or_greater") var luck: float = 0.0
## Distancia desde la que se recogen experiencia y objetos (el oro llega solo).
@export_range(0.5, 50.0, 0.1, "or_greater", "suffix:m") var pickup_range: float = 0.0

@export_group("slots")
## Armas que puede llevar a la vez: las ranuras abiertas. Nunca pasan de las que hay
## ([member LevelUpData.max_weapon_slots]); el resto se ven cerradas en el HUD.
@export_range(1, 4, 1, "or_greater") var weapon_slots: int = 0
## Runas que puede llevar a la vez (como [member weapon_slots]).
@export_range(1, 4, 1, "or_greater") var rune_slots: int = 0

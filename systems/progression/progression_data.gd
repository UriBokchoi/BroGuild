class_name ProgressionData
extends Resource
## Stats de progresión y botín: experiencia y fichas ganadas, suerte y radio de recogida. Los
## valores viven en [code]data/player/progression.tres[/code]; aquí todo vale 0 a propósito.
## Su efecto exacto está en el GDD (§6, «Stats del personaje»).

@export_group("progression")
## Multiplica la experiencia que ganas.
@export_range(0.0, 1000.0, 1.0, "or_greater", "suffix:%") var xp_gain: float = 0.0
## Multiplica las fichas que ganas.
@export_range(0.0, 1000.0, 1.0, "or_greater", "suffix:%") var currency_gain: float = 0.0
## Suerte: desplaza los pesos de las rarezas hacia arriba (GDD §5).
@export_range(0.0, 100.0, 1.0, "or_greater") var luck: float = 0.0
## Distancia desde la que se recogen experiencia, fichas y objetos.
@export_range(0.5, 50.0, 0.1, "or_greater", "suffix:m") var pickup_range: float = 0.0

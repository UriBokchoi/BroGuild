class_name LayoutPiece
extends Resource
## Una pieza que un mapa generado reparte ([LevelLayout]): una meseta, unas pesas, una tragaperras…
## Cuántas, cuánto sitio ocupan (un círculo en el suelo) y si se puede poner algo encima.

## Escena de la pieza (su origen, en el suelo).
@export var scene: PackedScene
## Cuántas.
@export_range(0, 100, 1) var count: int = 0
## Radio del círculo del suelo que ocupa (con su rampa, si la tiene).
@export_range(0.5, 50.0, 0.5, "suffix:m") var footprint: float = 0.0
## Altura de su parte de arriba, donde se pueden poner piezas (0: no se puede).
@export_range(0.0, 50.0, 0.5, "suffix:m") var top_height: float = 0.0
## Si tiene que quedar fuera del claro donde aparece el jugador.
@export var avoid_clearing: bool = false

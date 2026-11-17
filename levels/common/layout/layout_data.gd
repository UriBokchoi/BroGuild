class_name LayoutData
extends Resource
## Cómo se genera un mapa ([LevelLayout]): dónde se reparte (un cuadrado alrededor del centro), el
## claro donde aparece el jugador, qué piezas van por el suelo y cuáles encima de otras, y su bosque.
## Valores en [code]data/layouts/[/code]; aquí todo es neutro a propósito.

## Mitad del lado del cuadrado donde se reparten piezas y árboles sueltos.
@export_range(1.0, 500.0, 0.5, "suffix:m") var half_size: float = 1.0
## Radio del claro del centro: sin árboles ni piezas que lo eviten.
@export_range(0.0, 100.0, 0.5, "suffix:m") var clearing_radius: float = 0.0
## Radio alrededor del punto de aparición sin nada de nada.
@export_range(0.0, 20.0, 0.5, "suffix:m") var spawn_radius: float = 0.0
## Hueco mínimo entre dos piezas.
@export_range(0.0, 20.0, 0.5, "suffix:m") var gap: float = 0.0
## Intentos por pieza.
@export_range(1, 1000, 1) var attempts: int = 1
## Piezas que van por el suelo (mesetas, pesas, bancos, tragaperras…), en orden: las grandes primero.
@export var pieces: Array[LayoutPiece] = []
## Piezas que van encima de otras (las que tienen [member LayoutPiece.top_height]): una por pieza.
@export var top_pieces: Array[LayoutPiece] = []
@export var forest: ForestData

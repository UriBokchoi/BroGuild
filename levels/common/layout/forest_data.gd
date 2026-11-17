class_name ForestData
extends Resource
## Cómo es el bosque de un mapa generado ([LevelLayout]): árboles sueltos que esquivan las piezas,
## un anillo denso que choca junto a las paredes y una banda grande y densa al otro lado (sin
## colisión) que tapa el final del mundo. Se dibujan con MultiMesh. Valores en
## [code]data/layouts/[/code]; aquí todo es neutro a propósito.

@export_group("scatter")
## Árboles sueltos como mucho.
@export_range(0, 1000, 1) var max_trees: int = 0
## Distancia mínima entre dos árboles sueltos.
@export_range(1.0, 50.0, 0.5, "suffix:m") var spacing: float = 1.0
## Hueco libre alrededor de cada pieza.
@export_range(0.0, 20.0, 0.5, "suffix:m") var piece_margin: float = 0.0
## Intentos para colocarlos.
@export_range(1, 20000, 1) var attempts: int = 1

@export_group("border")
## Distancia al centro del anillo junto a las paredes (con colisión), su grosor y su paso.
@export_range(1.0, 500.0, 0.5, "suffix:m") var border: float = 1.0
@export_range(0.0, 50.0, 0.5, "suffix:m") var border_depth: float = 0.0
@export_range(0.5, 50.0, 0.5, "suffix:m") var border_step: float = 1.0
## Banda de fuera de las paredes (sin colisión): desde y hasta dónde, y su paso.
@export_range(1.0, 1000.0, 0.5, "suffix:m") var outer_start: float = 1.0
@export_range(1.0, 1000.0, 0.5, "suffix:m") var outer_end: float = 1.0
@export_range(0.5, 50.0, 0.5, "suffix:m") var outer_step: float = 1.0

@export_group("trees")
## Tamaños de los árboles de dentro y de la banda de fuera.
@export var scale_range: Vector2 = Vector2.ONE
@export var outer_scale_range: Vector2 = Vector2.ONE
## Parte de árboles redondos (el resto, pinos) y de colores de acento.
@export_range(0.0, 1.0, 0.01) var round_share: float = 0.0
@export_range(0.0, 1.0, 0.01) var accent_share: float = 0.0
@export var pine_colors: Array[Color] = []
@export var round_colors: Array[Color] = []
@export var accent_colors: Array[Color] = []
## Materiales del tronco y de las copas (el de las copas usa el color de cada árbol).
@export var bark: Material
@export var foliage: Material
## Tronco: alto y radio de su colisión.
@export_range(0.5, 20.0, 0.1, "suffix:m") var trunk_height: float = 1.0
@export_range(0.05, 5.0, 0.05, "suffix:m") var trunk_radius: float = 0.1

class_name CanopyLeaves
extends Node3D
## Hojitas que caen al meterse en la copa de un árbol (saltando o desde una meseta). Cada poco mira
## si el cuerpo del jugador ha entrado en alguna copa y, si es así, caen hojas del color de ese árbol
## desde el borde de abajo de la copa, donde se ven. Los árboles los da el mapa generado.

## A quién mira (el jugador).
@export var target: Node3D
## El mapa con los árboles. Sin él, los que se pasen con [method set_trees].
@export var layout: LevelLayout
## Las hojas: una escena [GPUParticles3D] de un solo disparo, que se tiñe del color del árbol.
@export var leaves: PackedScene
## Segundos entre comprobaciones.
@export_range(0.02, 1.0, 0.01, "suffix:s") var check_interval: float = 0.1
## Altura del cuerpo sobre los pies de [member target] (el punto que tiene que entrar en la copa).
@export_range(0.0, 3.0, 0.05, "suffix:m") var body_height: float = 1.0
## Segundos antes de que el mismo árbol vuelva a soltar hojas.
@export_range(0.0, 10.0, 0.1, "suffix:s") var tree_cooldown: float = 1.5
## Hasta dónde se miran árboles (medio lado del cuadrado, desde el centro del mapa).
@export_range(1.0, 500.0, 1.0, "suffix:m") var reach: float = 82.0
## Emisores de hojas a la vez (si se acaban, se reutiliza el más viejo).
@export_range(1, 16, 1) var pool_size: int = 4

## Lado de cada celda de la rejilla de árboles.
const CELL := 8.0

## Copas: centro (x, z), radio, abajo, arriba y color, en listas paralelas.
var _centers: PackedVector2Array = PackedVector2Array()
var _radii: PackedFloat32Array = PackedFloat32Array()
var _bottoms: PackedFloat32Array = PackedFloat32Array()
var _tops: PackedFloat32Array = PackedFloat32Array()
var _colors: PackedColorArray = PackedColorArray()
## Árboles de cada celda de la rejilla.
var _grid: Dictionary[Vector2i, PackedInt32Array] = {}
## Cuándo soltó hojas cada árbol por última vez (segundos de juego).
var _last_drop: Dictionary[int, float] = {}
## Árbol en cuya copa está ahora (−1 = ninguno).
var _inside: int = -1
var _check_left: float = 0.0
var _clock: float = 0.0
var _pool: Array[GPUParticles3D] = []
var _next: int = 0
var _drops: int = 0


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	for index: int in pool_size:
		var emitter := leaves.instantiate() as GPUParticles3D
		emitter.emitting = false
		# Cada emisor con su material, para teñirlo sin teñir a los demás.
		emitter.process_material = emitter.process_material.duplicate()
		add_child(emitter)
		_pool.append(emitter)
	if layout:
		# Si el mapa se genera después (o se vuelve a generar), toma sus árboles nuevos.
		layout.generated.connect(func() -> void: set_trees(layout.get_trees()))
		set_trees(layout.get_trees())


func _process(delta: float) -> void:
	_clock += delta
	_check_left -= delta
	if _check_left > 0.0 or not is_instance_valid(target):
		return
	_check_left = check_interval
	var body := target.global_position + Vector3.UP * body_height
	var tree := _tree_at(body)
	if tree >= 0 and tree != _inside and _clock - _last_drop.get(tree, -INF) >= tree_cooldown:
		_last_drop[tree] = _clock
		_drop(Vector3(body.x, _bottoms[tree], body.z), _colors[tree])
	_inside = tree


## Usa [param trees] (como los da [ForestBuilder]) para saber dónde están las copas.
func set_trees(trees: Array[Dictionary]) -> void:
	_centers.clear()
	_radii.clear()
	_bottoms.clear()
	_tops.clear()
	_colors.clear()
	_grid.clear()
	for tree: Dictionary in trees:
		var at: Vector2 = tree["at"]
		if absf(at.x) > reach or absf(at.y) > reach:
			continue
		var canopy := ForestBuilder.canopy(tree)
		var index := _centers.size()
		_centers.append(at)
		_radii.append(canopy.x)
		_bottoms.append(canopy.y)
		_tops.append(canopy.z)
		_colors.append(tree["color"] as Color)
		var cell := _cell_of(at)
		if not _grid.has(cell):
			_grid[cell] = PackedInt32Array()
		_grid[cell].append(index)


## Copas que conoce.
func tree_count() -> int:
	return _centers.size()


## Cuántas veces han caído hojas.
func get_drops() -> int:
	return _drops


## El árbol en cuya copa está [param point] (−1 si ninguno). Una copa es un cilindro: su radio y su
## franja de alturas.
func _tree_at(point: Vector3) -> int:
	var flat := Vector2(point.x, point.z)
	var home := _cell_of(flat)
	# Una copa grande puede asomar a la celda de al lado.
	for dx: int in range(-1, 2):
		for dz: int in range(-1, 2):
			var cell := home + Vector2i(dx, dz)
			if not _grid.has(cell):
				continue
			for index: int in _grid[cell]:
				if point.y < _bottoms[index] or point.y > _tops[index]:
					continue
				if flat.distance_to(_centers[index]) <= _radii[index]:
					return index
	return -1


func _drop(at: Vector3, color: Color) -> void:
	_drops += 1
	var emitter := _pool[_next]
	_next = (_next + 1) % _pool.size()
	emitter.global_position = at
	(emitter.process_material as ParticleProcessMaterial).color = color.lightened(0.3)
	emitter.restart()


static func _cell_of(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / CELL), floori(at.y / CELL))

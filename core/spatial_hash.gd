class_name SpatialHash
extends RefCounted
## Rejilla en el plano XZ para encontrar lo que hay cerca de un punto sin comparar todo con todo.
## Cada tick: clear, un insert por cosa y las consultas que hagan falta.
##
## Guarda todo en arrays empaquetados ordenados por celda, sin diccionarios: con cientos de cosas,
## en GDScript es mucho más rápido. Cada cosa puede llevar una marca (tag) para filtrar.

## Celdas como mucho en la rejilla (recorrerlas cuesta: ver [method _build]).
const MAX_CELLS: int = 16384

## Lado de cada celda en metros. Mejor parecido al radio de las consultas. Si lo apuntado está tan
## disperso que harían falta más de [constant MAX_CELLS] celdas, se usan celdas más grandes.
var cell_size: float = 1.0

var _items: Array[Object] = []
var _positions: PackedVector3Array = PackedVector3Array()
var _tags: PackedInt32Array = PackedInt32Array()
var _built: bool = false
var _origin: Vector2 = Vector2.ZERO
## Lado de las celdas de la rejilla actual ([member cell_size] o más, si hay mucha dispersión).
var _cell: float = 1.0
var _columns: int = 0
var _rows: int = 0
## Índices de las cosas ordenados por celda; [member _cell_start] dice dónde empieza cada celda.
var _sorted: PackedInt32Array = PackedInt32Array()
var _cell_start: PackedInt32Array = PackedInt32Array()


func _init(cell: float) -> void:
	cell_size = maxf(cell, 0.01)


func clear() -> void:
	_items.clear()
	_positions.clear()
	_tags.clear()
	_built = false


## Apunta [param item] en [param position], con una marca opcional [param tag]. Devuelve su índice.
func insert(item: Object, position: Vector3, tag: int = 0) -> int:
	_items.append(item)
	_positions.append(position)
	_tags.append(tag)
	_built = false
	return _items.size() - 1


## Cuántas cosas hay apuntadas.
func size() -> int:
	return _items.size()


## Índices de lo apuntado a menos de [param radius] de [param position] (en el plano XZ), sin el de
## índice [param exclude_index] (el que pregunta, si está apuntado), y como mucho [param limit]
## (0 = todos; en una multitud basta con unos pocos). Con [method position_at], [method tag_at] e
## [method item_at] se lee cada uno.
func indices_near(position: Vector3, radius: float, exclude_index: int = -1, limit: int = 0) -> PackedInt32Array:
	var found := PackedInt32Array()
	if _items.is_empty():
		return found
	if not _built:
		_build()
	var low_x := maxi(floori((position.x - radius - _origin.x) / _cell), 0)
	var high_x := mini(floori((position.x + radius - _origin.x) / _cell), _columns - 1)
	var low_z := maxi(floori((position.z - radius - _origin.y) / _cell), 0)
	var high_z := mini(floori((position.z + radius - _origin.y) / _cell), _rows - 1)
	var radius_squared := radius * radius
	for z: int in range(low_z, high_z + 1):
		for x: int in range(low_x, high_x + 1):
			var cell := z * _columns + x
			for slot: int in range(_cell_start[cell], _cell_start[cell + 1]):
				var index := _sorted[slot]
				var offset := _positions[index] - position
				if offset.x * offset.x + offset.z * offset.z > radius_squared or index == exclude_index:
					continue
				found.append(index)
				if found.size() == limit:
					return found
	return found


## Posiciones de lo apuntado cerca, sin [param exclude] (ver [method indices_near]).
func positions_near(position: Vector3, radius: float, exclude: Object = null) -> PackedVector3Array:
	var found := PackedVector3Array()
	for index: int in indices_near(position, radius, _items.find(exclude) if exclude else -1):
		found.append(_positions[index])
	return found


## Lo apuntado cerca, sin [param exclude] (ver [method indices_near]).
func items_near(position: Vector3, radius: float, exclude: Object = null) -> Array[Object]:
	var found: Array[Object] = []
	for index: int in indices_near(position, radius, _items.find(exclude) if exclude else -1):
		found.append(_items[index])
	return found


func position_at(index: int) -> Vector3:
	return _positions[index]


func tag_at(index: int) -> int:
	return _tags[index]


func item_at(index: int) -> Object:
	return _items[index]


## Ordena los índices por celda (counting sort) en una rejilla que cubre todo lo apuntado.
func _build() -> void:
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for position: Vector3 in _positions:
		low = Vector2(minf(low.x, position.x), minf(low.y, position.z))
		high = Vector2(maxf(high.x, position.x), maxf(high.y, position.z))
	_origin = low
	_cell = cell_size
	while _grid_cells(low, high) > MAX_CELLS:
		_cell *= 2.0
	_columns = floori((high.x - low.x) / _cell) + 1
	_rows = floori((high.y - low.y) / _cell) + 1
	var cells := PackedInt32Array()
	cells.resize(_positions.size())
	_cell_start = PackedInt32Array()
	_cell_start.resize(_columns * _rows + 1)
	_cell_start.fill(0)
	for index: int in _positions.size():
		var cell := _cell_of(_positions[index])
		cells[index] = cell
		_cell_start[cell + 1] += 1
	for cell: int in _columns * _rows:
		_cell_start[cell + 1] += _cell_start[cell]
	var next := _cell_start.duplicate()
	_sorted = PackedInt32Array()
	_sorted.resize(_positions.size())
	for index: int in _positions.size():
		_sorted[next[cells[index]]] = index
		next[cells[index]] += 1
	_built = true


func _cell_of(position: Vector3) -> int:
	var x := floori((position.x - _origin.x) / _cell)
	var z := floori((position.z - _origin.y) / _cell)
	return z * _columns + x


func _grid_cells(low: Vector2, high: Vector2) -> int:
	return (floori((high.x - low.x) / _cell) + 1) * (floori((high.y - low.y) / _cell) + 1)

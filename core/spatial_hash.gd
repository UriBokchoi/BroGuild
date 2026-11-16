class_name SpatialHash
extends RefCounted
## Rejilla en el plano XZ para encontrar rápido lo que hay cerca de un punto (vecinos de un enemigo,
## botín cercano…) sin comparar todo con todo. Se vacía y se rellena cada tick con
## [method clear] e [method insert]; las consultas solo miran las celdas que toca el radio.

## Lado de cada celda en metros. Mejor parecido al radio de las consultas.
var cell_size: float = 1.0

var _cells: Dictionary[Vector2i, Array] = {}
var _items: Array[Object] = []
var _positions: PackedVector3Array = PackedVector3Array()


func _init(cell: float) -> void:
	cell_size = maxf(cell, 0.01)


func clear() -> void:
	_cells.clear()
	_items.clear()
	_positions.clear()


## Apunta [param item] en [param position].
func insert(item: Object, position: Vector3) -> void:
	var index := _items.size()
	_items.append(item)
	_positions.append(position)
	var key := _key(position)
	if not _cells.has(key):
		_cells[key] = []
	_cells[key].append(index)


## Posiciones de lo apuntado a menos de [param radius] de [param position] (en el plano XZ), sin
## [param exclude].
func positions_near(position: Vector3, radius: float, exclude: Object = null) -> PackedVector3Array:
	var found := PackedVector3Array()
	for index: int in _indices_near(position, radius, exclude):
		found.append(_positions[index])
	return found


## Lo apuntado a menos de [param radius] de [param position] (en el plano XZ), sin [param exclude].
func items_near(position: Vector3, radius: float, exclude: Object = null) -> Array[Object]:
	var found: Array[Object] = []
	for index: int in _indices_near(position, radius, exclude):
		found.append(_items[index])
	return found


## Cuántas cosas hay apuntadas.
func size() -> int:
	return _items.size()


func _indices_near(position: Vector3, radius: float, exclude: Object) -> Array[int]:
	var found: Array[int] = []
	var low := _key(position - Vector3(radius, 0.0, radius))
	var high := _key(position + Vector3(radius, 0.0, radius))
	var radius_squared := radius * radius
	for x: int in range(low.x, high.x + 1):
		for y: int in range(low.y, high.y + 1):
			var cell: Array = _cells.get(Vector2i(x, y), [])
			for index: int in cell:
				if _items[index] == exclude:
					continue
				var offset := _positions[index] - position
				if offset.x * offset.x + offset.z * offset.z <= radius_squared:
					found.append(index)
	return found


func _key(position: Vector3) -> Vector2i:
	return Vector2i(floori(position.x / cell_size), floori(position.z / cell_size))

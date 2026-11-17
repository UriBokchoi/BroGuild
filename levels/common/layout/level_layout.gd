class_name LevelLayout
extends Node3D
## Mapa generado al cargar el nivel, distinto en cada partida (con la semilla de la partida, flujo
## [code]LAYOUT[/code] de [code]Rng[/code]): reparte las piezas de [member data] por el suelo (las
## grandes primero) sin que se pisen ni invadan el claro del centro, pone encima de algunas las que
## van arriba (tragaperras en las mesetas) y construye el bosque alrededor ([ForestBuilder]). El
## centro de este nodo es el centro del mapa y el punto de aparición.

## Se terminó de generar.
signal generated

@export var data: LayoutData

## Azar del mapa. Si no se asigna antes de entrar en el árbol, el flujo de mapas de [code]Rng[/code].
var rng: RandomNumberGenerator

## Lo ocupado por piezas (x, z, radio) y sitios libres encima de piezas (x, alto, z).
var _occupied: Array[Vector3] = []
var _tops: Array[Vector3] = []


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.LAYOUT)
	generate()


## Genera (o vuelve a generar) el mapa.
func generate() -> void:
	for child: Node in get_children():
		child.free()
	_occupied.clear()
	_tops.clear()
	_occupied.append(Vector3(0.0, 0.0, data.spawn_radius))
	for piece: LayoutPiece in data.pieces:
		for _index: int in piece.count:
			_place_on_ground(piece)
	for piece: LayoutPiece in data.top_pieces:
		for _index: int in piece.count:
			_place_on_top(piece)
	ForestBuilder.build(self, data.forest, data.half_size, data.clearing_radius, _occupied, rng)
	generated.emit()


## Círculos del suelo ocupados por piezas (x, z, radio), incluido el punto de aparición.
func get_occupied() -> Array[Vector3]:
	return _occupied.duplicate()


## Piezas colocadas (sin el bosque).
func get_pieces() -> Array[Node3D]:
	var pieces: Array[Node3D] = []
	for child: Node in get_children():
		if child.name != &"Forest":
			pieces.append(child as Node3D)
	return pieces


func _place_on_ground(piece: LayoutPiece) -> void:
	var reach := data.half_size - piece.footprint
	for _attempt: int in data.attempts:
		var at := Vector2(rng.randf_range(-reach, reach), rng.randf_range(-reach, reach))
		if piece.avoid_clearing and at.length() < data.clearing_radius + piece.footprint:
			continue
		if _overlaps(at, piece.footprint):
			continue
		_spawn(piece, Vector3(at.x, 0.0, at.y))
		_occupied.append(Vector3(at.x, at.y, piece.footprint))
		if piece.top_height > 0.0:
			_tops.append(Vector3(at.x, piece.top_height, at.y))
		return


func _place_on_top(piece: LayoutPiece) -> void:
	if _tops.is_empty():
		return
	var top: Vector3 = _tops.pop_at(rng.randi_range(0, _tops.size() - 1))
	_spawn(piece, top)


func _spawn(piece: LayoutPiece, at: Vector3) -> void:
	var node := piece.scene.instantiate() as Node3D
	node.position = at
	node.rotation.y = rng.randf_range(0.0, TAU)
	add_child(node)


func _overlaps(at: Vector2, radius: float) -> bool:
	for zone: Vector3 in _occupied:
		if at.distance_to(Vector2(zone.x, zone.y)) < zone.z + radius + data.gap:
			return true
	return false

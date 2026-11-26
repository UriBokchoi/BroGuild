class_name CharacterModel
extends Node3D
## Modelo de un personaje: el cuerpo toma su color y lleva sus piezas
## ([member CharacterData.attachments]) en sus puntos de anclaje (manos, cabeza…). Lo usan el
## jugador, los pedestales y, más adelante, la selección de personaje. Sin personaje, se queda con
## su color de serie y sin piezas.

## Partes que toman el color del personaje (el cuerpo y las manos).
@export var tinted: Array[GeometryInstance3D] = []
## Padre de los puntos de anclaje: cada hijo es un punto y su nombre es el que usan los datos.
@export var sockets: Node3D
## Color sin personaje.
@export var default_color: Color = Color.WHITE
## Rugosidad de la piel.
@export_range(0.0, 1.0, 0.05) var roughness: float = 0.6

var _skin: StandardMaterial3D
var _pieces: Array[Node3D] = []


func _ready() -> void:
	# Un material por modelo: cada personaje en pantalla lleva su color.
	_skin = StandardMaterial3D.new()
	_skin.roughness = roughness
	_skin.albedo_color = default_color
	for part: GeometryInstance3D in tinted:
		part.material_override = _skin


## Viste el modelo como [param data]: su color y sus piezas (quita las del anterior). Con
## [code]null[/code], vuelve a su color de serie y sin piezas.
func dress(data: CharacterData) -> void:
	for piece: Node3D in _pieces:
		piece.queue_free()
	_pieces.clear()
	_skin.albedo_color = data.color if data else default_color
	if data == null:
		return
	for attachment: ModelAttachment in data.attachments:
		_attach(attachment)


## Color del cuerpo.
func get_color() -> Color:
	return _skin.albedo_color


## Hace brillar el cuerpo de [param color] con [param energy] (la rabia del Bárbaro); con energía 0,
## deja de brillar.
func set_glow(color: Color, energy: float) -> void:
	_skin.emission_enabled = energy > 0.0
	_skin.emission = color
	_skin.emission_energy_multiplier = energy


## ¿Brilla?
func is_glowing() -> bool:
	return _skin.emission_enabled


## Piezas que lleva puestas.
func get_pieces() -> Array[Node3D]:
	return _pieces.duplicate()


func _attach(attachment: ModelAttachment) -> void:
	var socket := sockets.get_node_or_null(NodePath(String(attachment.socket))) as Node3D
	if socket == null or attachment.scene == null:
		push_error("CharacterModel: no hay punto '%s' o falta la escena de la pieza." % attachment.socket)
		return
	var piece := attachment.scene.instantiate() as Node3D
	piece.transform = attachment.transform
	socket.add_child(piece)
	_pieces.append(piece)

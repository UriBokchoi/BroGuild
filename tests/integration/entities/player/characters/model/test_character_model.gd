extends GutTest
## Modelo de personaje: se viste con el color y las piezas del personaje, cada pieza en su punto;
## vestirse de otro quita las piezas del anterior y sin personaje vuelve a su color de serie.

const ModelScene := preload("res://entities/player/characters/model/character_model.tscn")
const WARRIOR := preload("res://data/characters/warrior.tres")
const ROGUE := preload("res://data/characters/rogue.tres")

var _model: CharacterModel


func before_each() -> void:
	_model = ModelScene.instantiate() as CharacterModel
	add_child_autofree(_model)


func test_starts_with_its_default_color_and_no_pieces() -> void:
	assert_eq(_model.get_color(), _model.default_color)
	assert_eq(_model.get_pieces().size(), 0)


func test_dressing_takes_the_color_and_the_pieces() -> void:
	_model.dress(WARRIOR)
	assert_eq(_model.get_color(), WARRIOR.color)
	var pieces := _model.get_pieces()
	assert_eq(pieces.size(), WARRIOR.attachments.size())
	for index: int in pieces.size():
		var attachment := WARRIOR.attachments[index]
		assert_eq(pieces[index].get_parent().name, attachment.socket, "cada pieza en su punto")
		assert_eq(pieces[index].transform, attachment.transform, "colocada como dicen los datos")


func test_the_body_and_hands_share_the_color() -> void:
	_model.dress(ROGUE)
	for part: GeometryInstance3D in _model.tinted:
		assert_eq((part.material_override as StandardMaterial3D).albedo_color, ROGUE.color)


func test_dressing_again_replaces_the_pieces() -> void:
	_model.dress(WARRIOR)
	_model.dress(ROGUE)
	await wait_process_frames(1)
	assert_eq(_model.get_pieces().size(), ROGUE.attachments.size())
	var in_sockets := 0
	for socket: Node in _model.sockets.get_children():
		# Cada punto tiene, como mucho, su mano y una pieza.
		in_sockets += socket.get_child_count()
	var hands := 2
	assert_eq(in_sockets, hands + ROGUE.attachments.size(), "sin las piezas del Guerrero")


func test_undressing_goes_back_to_default() -> void:
	_model.dress(WARRIOR)
	_model.dress(null)
	assert_eq(_model.get_color(), _model.default_color)
	assert_eq(_model.get_pieces().size(), 0)

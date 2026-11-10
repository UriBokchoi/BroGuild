extends GutTest
## Mantle con física real: sube un borde a media altura delante (−Z, hacia donde mira la cámara),
## no sube paredes demasiado altas y con Ctrl mantenido sale deslizando.

const PlayerScene := preload("res://entities/player/player.tscn")
const SETTLE_FRAMES := 5
## La cara del borde queda en z = −1; el jugador, en z = −0,5 (a 0,1 m de tocarla).
const LEDGE_FACE_Z := -1.0
const LEDGE_DEPTH := 12.0
const PLAYER_Z := -0.5

var _player: Player


func after_each() -> void:
	Input.action_release(InputActions.SLIDE)


func test_climbs_a_mid_height_ledge() -> void:
	await _setup(1.5)
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(2)
	assert_true(_player.movement.current is MantleState, "Espacio delante del borde")
	await wait_physics_frames(20)
	assert_almost_eq(_player.global_position.y, 1.5, 0.15, "encima del borde")
	assert_lt(_player.global_position.z, LEDGE_FACE_Z - 0.3, "pasado el filo")


func test_too_tall_walls_are_a_normal_jump() -> void:
	await _setup(4.0)
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(2)
	assert_true(_player.movement.current is AirState, "salto normal, sin mantle")


func test_holding_ctrl_exits_sliding() -> void:
	await _setup(1.5)
	Input.action_press(InputActions.SLIDE)
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(20)
	assert_true(_player.movement.current is SlideState, "sale deslizando")


## Suelo, un borde de [param height] m delante y el jugador quieto frente a él.
func _setup(height: float) -> void:
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(40.0, 1.0, 40.0))
	_add_box(
		Vector3(0.0, height / 2.0, LEDGE_FACE_Z - LEDGE_DEPTH / 2.0),
		Vector3(8.0, height, LEDGE_DEPTH)
	)
	_player = PlayerScene.instantiate() as Player
	_player.position = Vector3(0.0, 0.0, PLAYER_Z)
	add_child_autofree(_player)
	await wait_physics_frames(SETTLE_FRAMES)


func _add_box(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	body.position = center
	body.add_child(shape)
	add_child_autofree(body)

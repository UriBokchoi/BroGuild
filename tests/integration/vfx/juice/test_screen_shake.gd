extends GutTest
## Temblor de pantalla: un golpe al jugador mueve su cámara, más cuanto más vida quita (un roce,
## lo mínimo), y al poco la cámara vuelve a su sitio.

const PlayerScene := preload("res://entities/player/player.tscn")

var _player: Player
var _shake: ScreenShake
var _camera: Camera3D


func before_each() -> void:
	RunState.character = null
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)
	_shake = _player.get_node(^"ScreenShake") as ScreenShake
	_camera = _player.get_node(^"CameraRig/SpringArm3D/Camera3D") as Camera3D


func test_a_graze_shakes_the_minimum() -> void:
	_player.health.take_damage(DamageInfo.create(0.5))
	assert_almost_eq(_shake.get_trauma(), _shake.min_trauma, 0.05)


func test_a_big_hit_shakes_more() -> void:
	_player.health.take_damage(DamageInfo.create(_player.health.get_maximum() * 0.3))
	assert_gt(_shake.get_trauma(), _shake.min_trauma)


func test_the_camera_moves_and_settles() -> void:
	_shake.add_trauma(1.0)
	var moved := false
	for frame: int in 10:
		await wait_process_frames(1)
		moved = moved or absf(_camera.h_offset) + absf(_camera.v_offset) > 0.0
	assert_true(moved, "la cámara se mueve")
	await wait_seconds(1.0 / _shake.decay + 0.1)
	assert_eq(_shake.get_trauma(), 0.0)
	assert_eq(_camera.h_offset, 0.0, "vuelve a su sitio")
	assert_eq(_camera.v_offset, 0.0)
	assert_almost_eq(_camera.rotation.z, 0.0, 1e-6, "sin inclinación (la rotación vuelve como -0)")

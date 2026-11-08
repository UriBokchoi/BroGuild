extends GutTest
## CameraRig: sigue al objetivo, gira dentro de sus límites y se aleja con el nivel.

const RigScene := preload("res://entities/player/camera/camera_rig.tscn")
const TARGET_YAW := 0.5

var _target: Node3D
var _rig: CameraRig


func before_each() -> void:
	_target = Node3D.new()
	_target.position = Vector3(3.0, 1.0, -2.0)
	_target.rotation.y = TARGET_YAW
	add_child_autofree(_target)
	_rig = RigScene.instantiate() as CameraRig
	_rig.target = _target
	add_child_autofree(_rig)


func test_starts_behind_the_target_at_pivot_height() -> void:
	var pivot := _target.global_position + Vector3.UP * _rig.data.pivot_height
	assert_true(_rig.global_position.is_equal_approx(pivot), "pivote sobre los pies del objetivo")
	assert_almost_eq(_rig.rotation.y, TARGET_YAW, 1e-6, "mira hacia donde mira el objetivo")
	assert_almost_eq(_rig.rotation.x, _rig.data.initial_pitch, 1e-6)


func test_level_moves_the_camera_away() -> void:
	var arm := _rig.get_node(^"%SpringArm3D") as SpringArm3D
	assert_almost_eq(arm.spring_length, _rig.data.distance_at(1), 1e-6)
	_rig.level = 100
	assert_almost_eq(arm.spring_length, _rig.data.distance_at(100), 1e-6)


func test_pitch_stays_within_limits() -> void:
	_rig.rotate_view(Vector2(0.0, -100000.0))
	assert_almost_eq(_rig.rotation.x, _rig.data.pitch_max, 1e-6, "ratón arriba: mira arriba hasta el tope")
	_rig.rotate_view(Vector2(0.0, 100000.0))
	assert_almost_eq(_rig.rotation.x, _rig.data.pitch_min, 1e-6, "ratón abajo: mira abajo hasta el tope")


func test_horizontal_motion_turns_by_sensitivity() -> void:
	_rig.rotate_view(Vector2(10.0, 0.0))
	var expected := TARGET_YAW - deg_to_rad(_rig.data.mouse_sensitivity) * 10.0
	assert_almost_eq(_rig.rotation.y, expected, 1e-6)

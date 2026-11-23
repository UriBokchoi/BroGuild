extends GutTest
## Flecha del portal: al abrirse el portal del jefe aparece junto al jugador, hacia el portal y
## apuntándole, y se va al acabar su tiempo.

const ArrowScene := preload("res://vfx/juice/portal_arrow/portal_arrow.tscn")

var _target: Node3D
var _arrow: PortalArrow


func before_each() -> void:
	_target = Node3D.new()
	add_child_autofree(_target)
	_arrow = ArrowScene.instantiate() as PortalArrow
	_arrow.target = _target
	add_child_autofree(_arrow)


func test_points_at_the_portal_for_a_while() -> void:
	assert_false(_arrow.is_showing())
	_arrow.show_time = 0.4
	EventBus.boss_portal_opened.emit(Vector3(20.0, 2.0, 0.0))
	await wait_process_frames(2)
	assert_true(_arrow.is_showing())
	var at := _arrow.global_position
	assert_almost_eq(Vector2(at.x, at.z), Vector2(_arrow.distance, 0.0), Vector2(0.05, 0.05), "a un lado, hacia el portal")
	assert_gt((-_arrow.global_basis.z).dot(Vector3.RIGHT), 0.99, "apunta al portal")
	await wait_seconds(0.5)
	assert_false(_arrow.is_showing(), "y se va")

extends GutTest
## Filtro del tiempo parado: al pararse, la pantalla se tiñe de azul; al volver a correr, se destiñe
## y el filtro se oculta.

const FilterScene := preload("res://vfx/time_stop/time_stop_filter.tscn")


func test_tints_while_time_is_stopped() -> void:
	var filter := FilterScene.instantiate() as TimeStopFilter
	filter.fade_time = 0.05
	add_child_autofree(filter)
	var rect := filter.get_node(^"%Filter") as ColorRect
	assert_false(rect.visible)
	EventBus.time_stop_changed.emit(true)
	await wait_seconds(0.15)
	assert_true(rect.visible)
	assert_almost_eq(filter.get_strength(), 1.0, 0.001)
	EventBus.time_stop_changed.emit(false)
	await wait_seconds(0.15)
	assert_almost_eq(filter.get_strength(), 0.0, 0.001)
	assert_false(rect.visible)

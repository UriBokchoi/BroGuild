extends GutTest
## Barra de vida del HUD: se llena según la vida del jugador y lleva los números dentro (la vida
## redondeada hacia arriba, para no ver un 0 estando vivo). Al perder vida baja de golpe y deja un
## rastro que se vacía con retraso; al curarse sube suave.

const HudScene := preload("res://ui/hud/hud.tscn")

var _bar: HealthBar


func before_each() -> void:
	var hud := HudScene.instantiate()
	add_child_autofree(hud)
	_bar = hud.get_node(^"%HealthBar") as HealthBar


func test_fills_with_the_player_health() -> void:
	EventBus.player_health_changed.emit(60.0, 120.0)
	assert_eq(_bar.max_value, 120.0)
	assert_eq(_bar.value, 60.0)


func test_shows_the_numbers_inside() -> void:
	EventBus.player_health_changed.emit(84.3, 120.0)
	assert_eq(_bar.get_value_text(), tr(&"HUD_HEALTH_VALUE") % [85, 120])


func test_a_sliver_of_health_is_not_zero() -> void:
	EventBus.player_health_changed.emit(0.2, 120.0)
	assert_eq(_bar.get_value_text(), tr(&"HUD_HEALTH_VALUE") % [1, 120])


func test_losing_health_leaves_a_trail_that_drains_later() -> void:
	EventBus.player_health_changed.emit(100.0, 100.0)
	EventBus.player_health_changed.emit(70.0, 100.0)
	assert_eq(_bar.value, 70.0, "la barra baja de golpe")
	assert_eq(_bar.get_trail_value(), 100.0, "el rastro se queda donde estaba")
	await wait_seconds(UiMotion.DATA.trail_delay + UiMotion.DATA.trail_time + 0.1)
	assert_almost_eq(_bar.get_trail_value(), 70.0, 0.01, "y luego se vacía")


func test_healing_rises_smoothly() -> void:
	EventBus.player_health_changed.emit(50.0, 100.0)
	EventBus.player_health_changed.emit(90.0, 100.0)
	assert_lt(_bar.value, 90.0, "aún subiendo")
	await wait_seconds(UiMotion.DATA.bar_time + 0.1)
	assert_almost_eq(_bar.value, 90.0, 0.01)
	assert_eq(_bar.get_value_text(), tr(&"HUD_HEALTH_VALUE") % [90, 100], "los números, al momento")

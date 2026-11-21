extends GutTest
## Barra de vida del HUD: se llena según la vida del jugador y lleva los números dentro (la vida
## redondeada hacia arriba, para no ver un 0 estando vivo).

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

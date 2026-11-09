extends GutTest
## StaminaBar: una barra por carga, rellenas según las cargas, y se rehace si cambia el máximo.

var _bar: StaminaBar


func before_each() -> void:
	_bar = StaminaBar.new()
	add_child_autofree(_bar)


func test_one_bar_per_charge_with_partial_fill() -> void:
	EventBus.player_stamina_changed.emit(2.5, 3)
	assert_eq(_bar.get_fills(), PackedFloat64Array([1.0, 1.0, 0.5]))


func test_rebuilds_when_the_max_changes() -> void:
	EventBus.player_stamina_changed.emit(3.0, 3)
	EventBus.player_stamina_changed.emit(4.0, 4)
	assert_eq(_bar.get_fills(), PackedFloat64Array([1.0, 1.0, 1.0, 1.0]))

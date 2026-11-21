extends GutTest
## Borde rojo: destello al perder vida que se apaga solo; con poca vida, rojo que late y no se
## apaga, más fuerte cuanta menos vida; curarse no destella.

const VignetteScene := preload("res://vfx/juice/damage_vignette/damage_vignette.tscn")

var _vignette: DamageVignette


func before_each() -> void:
	_vignette = VignetteScene.instantiate() as DamageVignette
	add_child_autofree(_vignette)
	EventBus.player_health_changed.emit(100.0, 100.0)


func test_nothing_with_full_health() -> void:
	assert_eq(_vignette.get_strength(), 0.0)


func test_losing_health_flashes_and_fades() -> void:
	EventBus.player_health_changed.emit(80.0, 100.0)
	assert_almost_eq(_vignette.get_strength(), _vignette.flash_strength, 0.01)
	await wait_seconds(_vignette.flash_time + 0.1)
	assert_eq(_vignette.get_strength(), 0.0, "por encima de poca vida, se apaga")


func test_low_health_stays_red_and_beats() -> void:
	EventBus.player_health_changed.emit(10.0, 100.0)
	await wait_seconds(_vignette.flash_time + 0.1)
	var seen: Array[float] = []
	for frame: int in 40:
		await wait_process_frames(1)
		seen.append(_vignette.get_strength())
	var lowest: float = seen.min()
	var highest: float = seen.max()
	assert_gt(lowest, 0.0, "no se apaga")
	assert_gt(highest - lowest, 0.01, "late")


func test_less_health_is_more_danger() -> void:
	EventBus.player_health_changed.emit(30.0, 100.0)
	var some := _vignette.danger()
	EventBus.player_health_changed.emit(5.0, 100.0)
	assert_gt(_vignette.danger(), some)
	EventBus.player_health_changed.emit(90.0, 100.0)
	assert_eq(_vignette.danger(), 0.0)


func test_healing_does_not_flash() -> void:
	EventBus.player_health_changed.emit(90.0, 100.0)
	await wait_seconds(_vignette.flash_time + 0.1)
	EventBus.player_health_changed.emit(100.0, 100.0)
	assert_eq(_vignette.get_strength(), 0.0)


func test_health_before_it_is_ready_is_shown_once_ready() -> void:
	# Como en la partida: el jugador avisa de su vida en su _ready, antes que el borde.
	var early := VignetteScene.instantiate() as DamageVignette
	early.tree_entered.connect(func() -> void: EventBus.player_health_changed.emit(10.0, 100.0), CONNECT_ONE_SHOT)
	add_child_autofree(early)
	await wait_process_frames(2)
	assert_gt(early.get_strength(), 0.0)

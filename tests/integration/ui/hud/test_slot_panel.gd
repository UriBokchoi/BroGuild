extends GutTest
## Tragaperras en el HUD: al girar muestra los rodillos, que acaban en lo que salió; el resultado se
## lee con su valor; sin tirada (no había oro) solo sale el aviso. La cámara lenta del jackpot dura
## sus segundos reales y deja el juego a velocidad normal.

const HudScene := preload("res://ui/hud/hud.tscn")
const DATA := preload("res://data/slots/slot_machine.tres")

var _panel: SlotPanel


func before_each() -> void:
	var hud := HudScene.instantiate()
	add_child_autofree(hud)
	_panel = hud.get_node(^"%SlotPanel") as SlotPanel


func after_each() -> void:
	Engine.time_scale = 1.0


func test_the_reels_stop_on_the_results() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var results := DATA.roll(rng)
	EventBus.slot_spun.emit(DATA, results)
	assert_true(_panel.visible)
	assert_true(_panel.is_spinning())
	await wait_seconds(DATA.total_time() + 0.1)
	var shown := _panel.get_shown()
	for index: int in results.size():
		assert_same(shown[index], results[index].icon)


func test_shows_the_result_with_its_value() -> void:
	EventBus.slot_resolved.emit(&"SLOT_WIN_GOLD", 30.0, false)
	var label := _panel.get_node(^"%SlotResult") as Label
	assert_true(label.visible)
	assert_eq(label.text, tr(&"SLOT_WIN_GOLD") % 30)
	assert_false((_panel.get_node(^"%Reels") as Control).visible, "sin tirada, sin rodillos")


func test_the_jackpot_slow_motion_ends() -> void:
	var slow := SlowMotion.new()
	slow.duration = 0.1
	add_child_autofree(slow)
	EventBus.slot_resolved.emit(&"SLOT_JACKPOT_GOLD", 100.0, true)
	assert_true(slow.is_active())
	assert_almost_eq(Engine.time_scale, slow.time_scale, 0.001)
	await get_tree().create_timer(0.3, true, false, true).timeout
	assert_false(slow.is_active())
	assert_eq(Engine.time_scale, 1.0)

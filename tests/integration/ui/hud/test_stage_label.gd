extends GutTest
## StageLabel: oculto hasta que empieza una fase de un nivel con tiers; entonces dice cuál.


func test_shows_the_stage_once_it_starts() -> void:
	var label := StageLabel.new()
	add_child_autofree(label)
	assert_false(label.visible, "en un nivel sin tiers no sale")
	EventBus.stage_started.emit(&"BROSQUE_TIER_2", 1, 3)
	assert_true(label.visible)
	assert_eq(label.text, "BROSQUE_TIER_2")

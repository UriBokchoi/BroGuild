extends GutTest
## Textos breves del HUD: salen traducidos (también las claves de sus valores) y del color que
## toca, se apilan sin pasar del máximo y se van solos.

const HudScene := preload("res://ui/hud/hud.tscn")

var _feed: AnnouncementFeed


func before_each() -> void:
	var hud := HudScene.instantiate()
	add_child_autofree(hud)
	_feed = hud.get_node(^"%AnnouncementFeed") as AnnouncementFeed


func test_shows_the_text_translated_and_in_its_color() -> void:
	EventBus.announced.emit(&"PICKUP_MAGNET_ANNOUNCE", [], Color.CYAN)
	assert_eq(_feed.get_lines(), [tr(&"PICKUP_MAGNET_ANNOUNCE")] as Array[String])
	var label := _feed.get_child(0) as Label
	assert_eq(label.get_theme_color(&"font_color"), Color.CYAN)
	EventBus.announced.emit(&"HUD_BOSS_KEYS", [1, 3], Color.WHITE)
	EventBus.announced.emit(&"RESULTS_RETRY", [&"ENEMY_SAPLING_NAME"], Color.WHITE)
	var lines := _feed.get_lines()
	assert_eq(lines[1], tr(&"HUD_BOSS_KEYS") % [1, 3])
	assert_eq(lines[2], tr(&"RESULTS_RETRY") % tr(&"ENEMY_SAPLING_NAME"), "las claves de los valores, traducidas")


func test_stacks_up_to_the_max_and_fades_away() -> void:
	_feed.display_time = 0.2
	_feed.fade_time = 0.1
	for index: int in _feed.max_lines + 2:
		EventBus.announced.emit(&"PICKUP_BOMB_ANNOUNCE", [], Color.WHITE)
	assert_eq(_feed.get_lines().size(), _feed.max_lines)
	await wait_seconds(_feed.pop_time + 0.2 + 0.1 + 0.2)
	assert_eq(_feed.get_lines().size(), 0, "se van solos")

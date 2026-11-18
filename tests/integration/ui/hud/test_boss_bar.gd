extends GutTest
## El jefe en el HUD: su barra aparece al salir con su nombre y su vida, muestra sus gritos un rato y
## se va al vencerlo. Las llaves, debajo del oro: solo en niveles con jefe, «1/3», de otro color con
## todas, y se van cuando sale el jefe.

const HudScene := preload("res://ui/hud/hud.tscn")

var _hud: Node


func before_each() -> void:
	_hud = HudScene.instantiate()
	add_child_autofree(_hud)


func test_the_bar_shows_name_health_and_shouts() -> void:
	var bar := _hud.get_node(^"%BossBar") as BossBar
	assert_false(bar.visible)
	EventBus.boss_spawned.emit(&"ENEMY_ENT_TRAINER_NAME")
	assert_true(bar.visible)
	assert_eq((_hud.get_node(^"%BossName") as Label).text, "ENEMY_ENT_TRAINER_NAME")
	EventBus.boss_health_changed.emit(30.0, 120.0)
	var health := _hud.get_node(^"%BossHealth") as ProgressBar
	assert_eq(health.max_value, 120.0)
	assert_eq(health.value, 30.0)
	bar.shout_time = 0.2
	EventBus.boss_shouted.emit(&"ENT_TRAINER_SHOUT_ONE_MORE")
	assert_eq(bar.get_shout(), "ENT_TRAINER_SHOUT_ONE_MORE")
	await wait_seconds(0.3)
	assert_eq(bar.get_shout(), "", "el grito se va")
	EventBus.boss_defeated.emit(&"BROSQUE_VICTORY", 60.0, 2.0)
	assert_false(bar.visible)


func test_the_keys_show_only_with_a_boss_and_go_with_it() -> void:
	var counter := _hud.get_node(^"%BossKeyCounter") as BossKeyCounter
	assert_false(counter.visible, "sin jefe en el nivel, no se ve")
	EventBus.boss_keys_changed.emit(1, 3)
	var label := _hud.get_node(^"%BossKeyLabel") as Label
	assert_true(counter.visible)
	assert_eq(label.text, tr(&"HUD_BOSS_KEYS") % [1, 3])
	assert_eq(label.theme_type_variation, &"BossKeyLabel")
	EventBus.boss_keys_changed.emit(3, 3)
	assert_eq(label.theme_type_variation, &"BossKeyReadyLabel", "con todas, de otro color")
	EventBus.boss_spawned.emit(&"ENEMY_ENT_TRAINER_NAME")
	assert_false(counter.visible)

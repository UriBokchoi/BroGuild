extends GutTest
## El jefe en el HUD: su barra aparece al salir con su nombre, su vida en números (la actual, hacia
## arriba) y su barra, y se va al vencerlo. La del miniboss va con sus propias señales, debajo de la del
## jefe y sin solaparse con ella. Las llaves, debajo del oro: solo en niveles con jefe, «1/3», de otro
## color con todas, y se van cuando sale el jefe.

const HudScene := preload("res://ui/hud/hud.tscn")

var _hud: Node


func before_each() -> void:
	_hud = HudScene.instantiate()
	add_child_autofree(_hud)


func test_the_bar_shows_name_and_health() -> void:
	var bar := _hud.get_node(^"%BossBar") as BossBar
	assert_false(bar.visible)
	EventBus.boss_spawned.emit(&"ENEMY_ENT_TRAINER_NAME")
	assert_true(bar.visible)
	assert_eq((bar.get_node(^"%BossName") as Label).text, "ENEMY_ENT_TRAINER_NAME")
	EventBus.boss_health_changed.emit(30.0, 120.0)
	var health := bar.get_node(^"%BossHealth") as ProgressBar
	assert_eq(health.max_value, 120.0)
	assert_eq(health.value, 30.0)
	assert_eq(bar.get_value_text(), tr(&"HUD_HEALTH_VALUE") % [30, 120])
	EventBus.boss_health_changed.emit(0.5, 120.0)
	assert_eq(bar.get_value_text(), tr(&"HUD_HEALTH_VALUE") % [1, 120], "vivo, nunca 0")
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


func test_the_mini_boss_bar_follows_its_own_signals() -> void:
	var boss_bar := _hud.get_node(^"%BossBar") as BossBar
	var mini_bar := _hud.get_node(^"%MiniBossBar") as BossBar
	assert_false(mini_bar.visible)
	EventBus.mini_boss_spawned.emit(&"ENEMY_TROLLEADOR_NAME")
	assert_true(mini_bar.visible)
	assert_false(boss_bar.visible, "la del jefe no se entera")
	assert_eq((mini_bar.get_node(^"%BossName") as Label).text, "ENEMY_TROLLEADOR_NAME")
	EventBus.mini_boss_health_changed.emit(500.0, 2000.0)
	assert_eq((mini_bar.get_node(^"%BossHealth") as ProgressBar).value, 500.0)
	assert_eq(mini_bar.get_value_text(), tr(&"HUD_HEALTH_VALUE") % [500, 2000])
	EventBus.boss_defeated.emit(&"BROSQUE_VICTORY", 60.0, 2.0)
	assert_true(mini_bar.visible, "vencer al jefe no se lleva la del miniboss")
	EventBus.mini_boss_defeated.emit(&"ENEMY_TROLLEADOR_NAME")
	assert_false(mini_bar.visible)
	EventBus.mini_boss_spawned.emit(&"ENEMY_TROLLEADOR_NAME")
	EventBus.run_won.emit(&"BROSQUE_VICTORY", 60.0, 2.0)
	assert_false(mini_bar.visible, "al ganar la partida se van las dos")


func test_with_both_bosses_the_bars_do_not_overlap() -> void:
	EventBus.boss_spawned.emit(&"ENEMY_ENT_TRAINER_NAME")
	EventBus.mini_boss_spawned.emit(&"ENEMY_TROLLEADOR_NAME")
	await wait_process_frames(3)
	var boss_rect := (_hud.get_node(^"%BossBar") as Control).get_global_rect()
	var mini_rect := (_hud.get_node(^"%MiniBossBar") as Control).get_global_rect()
	var feed_rect := (_hud.get_node(^"%AnnouncementFeed") as Control).get_global_rect()
	assert_false(boss_rect.intersects(mini_rect), "una bajo la otra")
	assert_gt(mini_rect.position.y, boss_rect.position.y, "la del miniboss, debajo")
	assert_gte(feed_rect.position.y, mini_rect.end.y, "los textos breves, debajo de las dos")
	# Cuando se va el miniboss, la del jefe se queda donde estaba.
	EventBus.mini_boss_defeated.emit(&"ENEMY_TROLLEADOR_NAME")
	await wait_process_frames(2)
	assert_eq((_hud.get_node(^"%BossBar") as Control).get_global_rect().position, boss_rect.position)

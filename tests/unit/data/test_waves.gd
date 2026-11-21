extends GutTest
## Oleadas de data/waves: cada WaveData tiene ritmo, enemigos y duración de ronda, y su escalado
## solo toca stats que existen en los enemigos o en sus armas.

const WAVES_DIR := "res://data/waves"
const EnemyStatNames := preload("res://tests/unit/data/enemy_stat_names.gd")


func test_each_wave_data_is_complete() -> void:
	var waves := ResourceDir.load_all(WAVES_DIR, WaveData)
	assert_gt(waves.size(), 0)
	for resource: Resource in waves:
		var waves_data := resource as WaveData
		var label := waves_data.resource_path.get_file()
		assert_not_null(waves_data.spawn_rate, "%s: sin ritmo" % label)
		assert_false(waves_data.enemies.is_empty(), "%s: sin enemigos" % label)
		assert_gt(waves_data.round_minutes, 0.0, "%s: sin duración de ronda" % label)


func test_scaling_only_touches_enemy_or_weapon_stats() -> void:
	for resource: Resource in ResourceDir.load_all(WAVES_DIR, WaveData):
		var waves_data := resource as WaveData
		for scaling: StatScaling in waves_data.stat_scaling:
			assert_true(EnemyStatNames.has(scaling.stat), "«%s» no es una stat de enemigo ni de arma" % scaling.stat)
			assert_not_null(scaling.multiplier, "%s: sin curva" % scaling.stat)


func test_the_brosque_has_its_hordes_at_minutes_3_and_6() -> void:
	var waves: WaveData = load("%s/brosque.tres" % WAVES_DIR)
	var minutes: Array[float] = []
	for horde: HordeData in waves.hordes:
		minutes.append(horde.at_minute)
		assert_gt(horde.count, 0)
		assert_ne(tr(horde.announce_key), String(horde.announce_key), "aviso traducido")
		assert_lte(horde.elites, horde.count)
	assert_eq(minutes, [3.0, 6.0] as Array[float])


func test_hordes_come_in_order_within_the_round() -> void:
	for wave: Resource in ResourceDir.load_all(WAVES_DIR, WaveData):
		var data := wave as WaveData
		var previous := -1.0
		for horde: HordeData in data.hordes:
			assert_gt(horde.at_minute, previous, "%s: hordas en orden" % data.resource_path)
			assert_lt(horde.at_minute, data.round_minutes, "%s: dentro de la ronda" % data.resource_path)
			previous = horde.at_minute

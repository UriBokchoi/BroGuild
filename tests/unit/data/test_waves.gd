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

extends GutTest
## LevelStages en el Brosque, con el tier 3 elegido: la partida pasa por verano, otoño e invierno y
## acaba en la arena final. Al cambiar de fase el jugador conserva lo suyo (oro y objetos) y aparece
## en el mapa nuevo, más grande; la dificultad sube, las oleadas vuelven a empezar y el jefe se
## rearma. El último tier no acaba la partida; en la arena el jefe sale al entrar, las oleadas esperan
## a que caiga y morir después también gana. Ganar abre el tier siguiente.
## Las pruebas van en orden: cada una sigue la partida de la anterior.

const BROSQUE := preload("res://data/levels/brosque.tres")
const FINAL := preload("res://data/levels/brosque/final.tres")
const ITEM := preload("res://data/items/backwards_cap.tres")

var _level: Node3D
var _stages: LevelStages
var _systems: RunSystems


func before_all() -> void:
	RunState.level = BROSQUE
	RunState.tier = 3
	Rng.seed_run(5)
	_level = BROSQUE.scene.instantiate() as Node3D
	add_child(_level)
	_stages = _level.get_node(^"Stages") as LevelStages
	_systems = _level.get_node(^"RunSystems") as RunSystems


func after_all() -> void:
	_level.free()
	RunState.level = null
	RunState.tier = 1


func _wall() -> float:
	return (_stages.get_map().get_node(^"MapBoundary") as MapBoundary).half_extent.x


func test_1_the_plan_follows_the_chosen_tier() -> void:
	var stages := LevelStages.new()
	stages.tiers = BROSQUE.tiers
	stages.final_stage = FINAL
	assert_eq(stages.plan_for(1), [BROSQUE.tiers[0]] as Array[StageData], "el tier 1 solo")
	assert_eq(stages.plan_for(2).size(), 2, "el 1 y luego el 2")
	var full := stages.plan_for(3)
	assert_eq(full.size(), 4, "los tres tiers y la arena final")
	assert_eq(full[full.size() - 1], FINAL)
	stages.free()


func test_2_starts_in_summer_and_its_portal_leads_on() -> void:
	assert_eq(_stages.get_index_playing(), 0)
	assert_eq(_stages.get_stage_count(), 4)
	assert_almost_eq(_wall(), 110.0, 0.01)
	assert_true(_systems.director.is_running())
	assert_false(_systems.encounter.ends_run, "su portal lleva al tier 2")


func test_3_the_next_tier_keeps_the_build_and_is_bigger_and_harder() -> void:
	var player := _systems.player
	player.wallet.add(250.0)
	player.items.add(ITEM)
	var gold := player.wallet.get_gold()
	var difficulty := player.stats.get_value(&"difficulty")
	# Con su animación: entra en el portal (quieto y encogiendo) y sale en el mapa nuevo.
	_stages.advance()
	await wait_physics_frames(2)
	assert_eq(player.process_mode, Node.PROCESS_MODE_DISABLED, "sin control mientras entra")
	await wait_seconds(_stages.enter_time + _stages.fade_time * 2.0 + 0.3)
	assert_eq(player.process_mode, Node.PROCESS_MODE_INHERIT, "vuelve a moverse")
	assert_eq(player.model.scale, Vector3.ONE, "con su tamaño")
	assert_eq(_stages.get_index_playing(), 1)
	assert_gte(player.wallet.get_gold(), gold, "el oro se queda")
	assert_eq(player.items.get_items(), [ITEM] as Array[PassiveItemData], "los objetos también")
	assert_almost_eq(_wall(), 130.0, 0.01, "el mapa es más grande")
	assert_gte(player.stats.get_value(&"difficulty"), difficulty + BROSQUE.tiers[1].difficulty - 1.0, "más difícil")
	assert_true(_systems.director.is_running(), "las oleadas vuelven a empezar")
	assert_lt(_systems.director.get_elapsed(), 1.0, "desde el minuto 0")
	assert_false(_systems.encounter.is_summoned(), "el jefe, por sacar")
	assert_eq(_systems.encounter.get_keys(), 0)
	var spawn := _stages.get_map().spawn_point.global_position
	assert_almost_eq(player.global_position, spawn, Vector3.ONE * 0.5, "en el claro del mapa nuevo")


func test_4_winter_is_the_last_tier_but_not_the_end() -> void:
	_stages.advance_now()
	assert_eq(_stages.get_index_playing(), 2)
	assert_almost_eq(_wall(), 150.0, 0.01)
	assert_false(_systems.encounter.ends_run, "tras su portal, la arena final")


func test_5_the_final_arena_brings_the_boss_and_the_endless_wave_after_it() -> void:
	_stages.advance_now()
	assert_eq(_stages.get_index_playing(), 3)
	assert_true(_systems.encounter.ends_run)
	assert_true(_systems.encounter.death_wins, "vencido el jefe, morir también gana")
	assert_true(_systems.encounter.is_summoned(), "el jefe sale al entrar")
	assert_false(_systems.director.is_running(), "solo el jefe")
	var boss := _systems.encounter.get_boss()
	boss.health.take_damage(DamageInfo.create(boss.health.get_maximum() * 2.0))
	assert_true(_systems.director.is_running(), "y luego la oleada infinita")
	var portal := _stages.get_map().get_node(^"BossPortal") as BossPortal
	assert_true(portal.visible and portal.is_open(), "aparece el portal")


func test_6_winning_unlocks_the_next_tier() -> void:
	assert_false(Save.is_tier_unlocked(&"brosque", 2))
	EventBus.level_exit_reached.emit()
	assert_eq(Save.progress.completed(&"brosque"), 3, "superado el tier elegido")
	assert_true(Save.is_tier_unlocked(&"brosque", 3))

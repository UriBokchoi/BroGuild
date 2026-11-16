extends GutTest
## ExperienceComponent: suma la experiencia recogida (por su recompensa) con xp_gain, sube de nivel
## según la curva (varios de golpe si toca), pasa lo que sobra y para en el nivel máximo.

var _stats: StatsComponent
var _experience: ExperienceComponent


func before_each() -> void:
	var progression := ProgressionData.new()
	progression.xp_gain = 100.0
	progression.pickup_range = 3.0
	_stats = StatsComponent.new()
	_stats.sources.append(progression)
	add_child_autofree(_stats)
	var data := ExperienceData.new()
	var curve := Curve.new()
	curve.min_domain = 1.0
	curve.max_domain = 10.0
	curve.max_value = 100.0
	# 10 de experiencia por nivel, siempre.
	curve.add_point(Vector2(1.0, 10.0))
	curve.add_point(Vector2(10.0, 10.0))
	data.xp_to_next = curve
	data.max_level = 4
	_experience = ExperienceComponent.new()
	_experience.data = data
	_experience.stats = _stats
	add_child_autofree(_experience)


func test_starts_at_level_one_with_nothing() -> void:
	assert_eq(_experience.get_level(), 1)
	assert_eq(_experience.get_xp(), 0.0)
	assert_eq(_experience.needed(), 10.0)


func test_levels_up_and_keeps_the_rest() -> void:
	watch_signals(_experience)
	_experience.add(13.0)
	assert_eq(_experience.get_level(), 2)
	assert_eq(_experience.get_xp(), 3.0)
	assert_signal_emitted_with_parameters(_experience, "leveled_up", [2])


func test_several_levels_at_once() -> void:
	watch_signals(_experience)
	_experience.add(25.0)
	assert_eq(_experience.get_level(), 3)
	assert_signal_emit_count(_experience, "leveled_up", 2)


func test_xp_gain_multiplies() -> void:
	_stats.add_modifier(StatModifier.create(&"xp_gain", StatModifier.Kind.FLAT, 100.0), self)
	_experience.add(5.0)
	assert_eq(_experience.get_level(), 2, "5 × 200 % = 10")


func test_stops_at_the_max_level() -> void:
	_experience.add(1000.0)
	assert_eq(_experience.get_level(), 4)
	assert_eq(_experience.get_xp(), 0.0)


func test_counts_only_its_reward_from_pickups() -> void:
	EventBus.pickup_collected.emit(&"currency", 50.0)
	assert_eq(_experience.get_level(), 1, "las fichas no son experiencia")
	EventBus.pickup_collected.emit(&"experience", 10.0)
	assert_eq(_experience.get_level(), 2)

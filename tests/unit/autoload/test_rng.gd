extends GutTest
## Rng: misma semilla, misma secuencia; generadores independientes entre sí.
## Usa una instancia propia del script, no el autoload, para no tocar estado global.

const RngService := preload("res://autoload/rng.gd")
const SEED: int = 12345
const OTHER_SEED: int = 54321
const SAMPLE_SIZE: int = 16
const DRAWS_ON_OTHER_STREAM: int = 100

var _rng: RngService


func before_each() -> void:
	_rng = RngService.new()
	_rng.seed_run(SEED)


func after_each() -> void:
	_rng.free()


func test_same_seed_repeats_sequence() -> void:
	var first: Array[int] = _sample(RngService.Stream.LOOT)
	_rng.seed_run(SEED)
	assert_eq(_sample(RngService.Stream.LOOT), first)


func test_different_seed_changes_sequence() -> void:
	var first: Array[int] = _sample(RngService.Stream.LOOT)
	_rng.seed_run(OTHER_SEED)
	assert_ne(_sample(RngService.Stream.LOOT), first)


func test_run_seed_is_stored() -> void:
	_rng.seed_run(OTHER_SEED)
	assert_eq(_rng.run_seed, OTHER_SEED)


func test_using_one_stream_does_not_affect_another() -> void:
	var untouched: Array[int] = _sample(RngService.Stream.WAVES)
	_rng.seed_run(SEED)
	var loot: RandomNumberGenerator = _rng.stream(RngService.Stream.LOOT)
	for i: int in DRAWS_ON_OTHER_STREAM:
		loot.randi()
	assert_eq(_sample(RngService.Stream.WAVES), untouched)


func test_kept_reference_follows_new_seed() -> void:
	var kept: RandomNumberGenerator = _rng.stream(RngService.Stream.LOOT)
	_rng.seed_run(OTHER_SEED)
	var expected: Array[int] = _sample(RngService.Stream.LOOT)
	_rng.seed_run(OTHER_SEED)
	assert_same(_rng.stream(RngService.Stream.LOOT), kept)
	assert_eq(_draw(kept), expected)


func test_each_stream_has_its_own_sequence() -> void:
	var sequences: Dictionary[String, bool] = {}
	for id: RngService.Stream in RngService.Stream.values():
		sequences[str(_sample(id))] = true
	assert_eq(sequences.size(), RngService.Stream.size())


func test_stream_seed_depends_on_name_not_position() -> void:
	var expected: int = hash("%d:%s" % [SEED, "GAMBLE"])
	assert_eq(RngService.derive_seed(SEED, RngService.Stream.GAMBLE), expected)


func _sample(id: RngService.Stream) -> Array[int]:
	return _draw(_rng.stream(id))


func _draw(generator: RandomNumberGenerator) -> Array[int]:
	var values: Array[int] = []
	for i: int in SAMPLE_SIZE:
		values.append(generator.randi())
	return values

extends GutTest
## RunState: ciclo de vida de la partida, siembra de Rng y avisos por EventBus.
## Usa los autoloads reales; after_each deja la partida terminada.

const SEED: int = 777
const NEXT_SEED: int = 778


func before_each() -> void:
	watch_signals(EventBus)


func after_each() -> void:
	RunState.end_run()


func test_start_run_seeds_rng_and_notifies() -> void:
	RunState.start_run(SEED)
	assert_true(RunState.is_running)
	assert_eq(Rng.run_seed, SEED)
	assert_signal_emitted_with_parameters(EventBus.run_started, [SEED])


func test_end_run_notifies_only_once() -> void:
	RunState.start_run(SEED)
	RunState.end_run()
	RunState.end_run()
	assert_false(RunState.is_running)
	assert_signal_emit_count(EventBus.run_ended, 1)


func test_starting_again_ends_the_current_run() -> void:
	RunState.start_run(SEED)
	RunState.start_run(NEXT_SEED)
	assert_signal_emit_count(EventBus.run_ended, 1)
	assert_signal_emit_count(EventBus.run_started, 2)
	assert_eq(Rng.run_seed, NEXT_SEED)

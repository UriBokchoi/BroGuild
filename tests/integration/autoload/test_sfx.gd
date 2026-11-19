extends GutTest
## Sfx: suena con lo que pasa en el juego (golpes al jugador, subir de nivel, recogibles,
## tragaperras, botones), sube de tono la experiencia seguida y respeta las voces de cada sonido.

var _bank: SfxBank


var _real_bank: SfxBank


func before_each() -> void:
	_real_bank = Sfx.bank
	# Una copia: los tests pueden tocarla sin cambiar la de verdad.
	_bank = Sfx.bank.duplicate(true) as SfxBank
	Sfx.bank = _bank
	Sfx.reset()


func after_each() -> void:
	Sfx.bank = _real_bank
	Sfx.reset()


func test_losing_health_sounds_but_healing_does_not() -> void:
	EventBus.player_health_changed.emit(100.0, 100.0)
	assert_null(Sfx.last_cue, "la primera vez solo apunta la vida")
	EventBus.player_health_changed.emit(80.0, 100.0)
	assert_eq(Sfx.last_cue, _bank.player_hurt)
	Sfx.reset()
	EventBus.player_health_changed.emit(80.0, 100.0)
	EventBus.player_health_changed.emit(100.0, 100.0)
	assert_null(Sfx.last_cue)


func test_leveling_up_sounds() -> void:
	EventBus.player_leveled_up.emit(2)
	assert_eq(Sfx.last_cue, _bank.level_up)


func test_each_pickup_has_its_sound() -> void:
	EventBus.pickup_collected.emit(&"gold", 5.0)
	assert_eq(Sfx.last_cue, _bank.pickups[&"gold"])


func test_experience_in_a_row_goes_up_in_pitch() -> void:
	_bank.pickups[_bank.streak_reward].min_interval = 0.0
	var pitches: Array[float] = []
	for pickup: int in 3:
		EventBus.pickup_collected.emit(_bank.streak_reward, 1.0)
		pitches.append(Sfx.last_pitch)
	assert_gt(pitches[1], pitches[0])
	assert_gt(pitches[2], pitches[1])


func test_slot_results_sound_by_outcome() -> void:
	EventBus.slot_resolved.emit(&"SLOT_NOTHING", 0.0, false)
	assert_eq(Sfx.last_cue, _bank.slot_results[&"SLOT_NOTHING"])
	EventBus.slot_resolved.emit(&"SLOT_WIN_GOLD", 20.0, false)
	assert_eq(Sfx.last_cue, _bank.slot_won)
	EventBus.slot_resolved.emit(&"SLOT_JACKPOT_GOLD", 100.0, true)
	assert_eq(Sfx.last_cue, _bank.slot_jackpot)


func test_buttons_click() -> void:
	var button := Button.new()
	add_child_autofree(button)
	button.pressed.emit()
	assert_eq(Sfx.last_cue, _bank.button_pressed)


func test_a_cue_does_not_pass_its_voices() -> void:
	var cue := SoundCue.new()
	cue.stream = _bank.boss_spawned.stream
	cue.max_voices = 1
	assert_true(Sfx.play(cue))
	assert_false(Sfx.play(cue), "ya suena una vez")
	assert_eq(Sfx.voices_of(cue), 1)


func test_the_wheel_ticks_and_rarer_cards_ring_higher() -> void:
	EventBus.upgrade_spin_ticked.emit()
	assert_eq(Sfx.last_cue, _bank.upgrade_spin_tick)
	EventBus.upgrade_revealed.emit(load("res://data/rarities/common.tres"))
	var common := Sfx.last_pitch
	assert_eq(Sfx.last_cue, _bank.upgrade_revealed)
	EventBus.upgrade_revealed.emit(load("res://data/rarities/mythic.tres"))
	assert_gt(Sfx.last_pitch, common)

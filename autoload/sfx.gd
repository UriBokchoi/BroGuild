extends Node
## Efectos de sonido: escucha el [code]EventBus[/code] (y los botones de la interfaz) y hace sonar lo
## que dice su [SfxBank] con un grupo de [AudioStreamPlayer] en el bus de efectos. Respeta las voces
## y la separación de cada [SoundCue], y sube de tono la experiencia recogida seguida. Suena también
## en pausa (los menús). Sin lógica de gameplay.
##
## Sin pantalla (tests y validación, [code]--headless[/code]) lleva la cuenta igual pero no reproduce
## nada: no hay audio que oír, y salir con un sonido a medias deja su reproducción viva (Godot avisa
## de fugas al cerrar). Las voces se cuentan por lo que dura cada sonido, no por el reproductor.

const BANK := preload("res://data/audio/sfx_bank.tres")
## Multiplicador de tono de un semitono.
const SEMITONE := 1.0594630943592953

## Último sonido que sonó y con qué tono (para los tests y la depuración).
var last_cue: SoundCue
var last_pitch: float = 1.0
## Qué suena y cómo; los tests pueden cambiarlo.
var bank: SfxBank = BANK

var _players: Array[AudioStreamPlayer] = []
var _cue_of: Dictionary[AudioStreamPlayer, SoundCue] = {}
## Hasta cuándo suena cada reproductor (segundos desde que arrancó el juego).
var _busy_until: Dictionary[AudioStreamPlayer, float] = {}
## Si hay audio que oír (no en [code]--headless[/code]).
var _audible: bool = true
var _last_time: Dictionary[SoundCue, float] = {}
var _health: float = -1.0
var _streak: int = 0
var _streak_time: float = -INF
var _rng: RandomNumberGenerator


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_audible = DisplayServer.get_name() != "headless"
	_rng = Rng.stream(Rng.Stream.COSMETIC)
	for index: int in bank.voices:
		var player := AudioStreamPlayer.new()
		player.bus = bank.bus
		add_child(player)
		_players.append(player)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_died.connect(func() -> void: play(bank.player_died))
	EventBus.player_leveled_up.connect(func(_level: int) -> void: play(bank.level_up))
	EventBus.enemy_damaged.connect(func(_at: Vector3, _amount: float, _info: DamageInfo) -> void: play(bank.enemy_hit))
	EventBus.enemy_died.connect(func(_enemy: Enemy) -> void: play(bank.enemy_died))
	EventBus.boss_spawned.connect(func(_name: StringName) -> void: play(bank.boss_spawned))
	EventBus.boss_defeated.connect(func(_key: StringName, _seconds: float, _bonus: float) -> void: play(bank.boss_defeated))
	EventBus.pickup_collected.connect(_on_pickup_collected)
	EventBus.breakable_broken.connect(func(_data: BreakableData, _at: Vector3) -> void: play(bank.breakable_broken))
	EventBus.chest_opened.connect(func() -> void: play(bank.chest_opened))
	EventBus.chest_denied.connect(func(_cost: int) -> void: play(bank.chest_denied))
	EventBus.item_revealed.connect(_on_item_revealed)
	EventBus.slot_spun.connect(func(_data: SlotMachineData, _results: Array[SlotSymbol]) -> void: play(bank.slot_spun))
	EventBus.slot_resolved.connect(_on_slot_resolved)
	EventBus.upgrade_spin_ticked.connect(func() -> void: play(bank.upgrade_spin_tick))
	EventBus.upgrade_revealed.connect(_on_upgrade_revealed)
	EventBus.double_or_nothing_resolved.connect(_on_double_resolved)
	EventBus.horde_incoming.connect(func(_horde: HordeData, _seconds: float) -> void: play(bank.horde_incoming))
	EventBus.synergy_released.connect(_on_synergy_released)
	get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	# Al cerrar el juego, nada sonando ni guardado: si no, la reproducción y su audio quedan vivos al
	# salir (Godot avisa de fugas).
	for player: AudioStreamPlayer in _players:
		player.stop()
		player.stream = null


## Hace sonar [param cue] con el tono [param pitch] (y su variación al azar), si sus voces y su
## separación lo dejan y queda un reproductor libre. Devuelve si ha sonado.
func play(cue: SoundCue, pitch: float = 1.0) -> bool:
	if cue == null or cue.stream == null:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if _last_time.has(cue) and now - _last_time[cue] < cue.min_interval:
		return false
	if cue.max_voices > 0 and voices_of(cue) >= cue.max_voices:
		return false
	var player := _free_player(now)
	if player == null:
		return false
	player.stream = cue.stream
	player.volume_db = cue.volume_db + bank.volume_db
	player.pitch_scale = pitch * (1.0 + _rng.randf_range(-cue.pitch_variation, cue.pitch_variation))
	if _audible:
		player.play()
	_cue_of[player] = cue
	_busy_until[player] = now + cue.stream.get_length() / player.pitch_scale
	_last_time[cue] = now
	last_cue = cue
	last_pitch = player.pitch_scale
	return true


## Cuántas veces está sonando [param cue] ahora.
func voices_of(cue: SoundCue) -> int:
	var now := Time.get_ticks_msec() / 1000.0
	var count := 0
	for player: AudioStreamPlayer in _players:
		if _is_busy(player, now) and _cue_of.get(player) == cue:
			count += 1
	return count


## Olvida lo que ha sonado (separaciones, racha y vida apuntada); para empezar de cero en los tests.
func reset() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()
	_cue_of.clear()
	_busy_until.clear()
	_last_time.clear()
	_health = -1.0
	_streak = 0
	_streak_time = -INF
	last_cue = null
	last_pitch = 1.0


func _free_player(now: float) -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _players:
		if not _is_busy(player, now):
			return player
	return null


func _is_busy(player: AudioStreamPlayer, now: float) -> bool:
	return _busy_until.get(player, 0.0) > now


func _on_player_health_changed(current: float, maximum: float) -> void:
	if _health >= 0.0 and current < _health and maximum > 0.0:
		play(bank.player_hurt)
	_health = current


func _on_pickup_collected(reward: StringName, _amount: float) -> void:
	var cue: SoundCue = bank.pickups.get(reward)
	if reward != bank.streak_reward:
		play(cue)
		return
	# La racha sube solo con lo que suena: así se oye cada escalón (con el imán, muchas recogidas no
	# suenan por la separación del sonido).
	var now := Time.get_ticks_msec() / 1000.0
	if now - _streak_time > bank.streak_window:
		_streak = 0
	_streak_time = now
	if play(cue, pow(SEMITONE, _streak)):
		_streak = mini(_streak + 1, bank.streak_max_semitones)


func _on_item_revealed(_item: PassiveItemData, reveal_time: float) -> void:
	# Suena cuando la luz se para en la rareza, no al empezar a girar.
	get_tree().create_timer(reveal_time, true).timeout.connect(func() -> void: play(bank.item_revealed))


func _on_slot_resolved(text_key: StringName, _value: float, jackpot: bool) -> void:
	if jackpot:
		play(bank.slot_jackpot)
	elif bank.slot_results.has(text_key):
		play(bank.slot_results[text_key])
	else:
		play(bank.slot_won)


func _on_double_resolved(won: bool) -> void:
	play(bank.double_won if won else bank.double_lost)


func _on_upgrade_revealed(rarity: Rarity) -> void:
	var pitch: float = bank.reveal_pitches.get(rarity.id, 1.0) if rarity else 1.0
	play(bank.upgrade_revealed, pitch)


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button and not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	play(bank.button_pressed)


func _on_synergy_released(damage_stat: StringName, _at: Vector3) -> void:
	if bank.synergies.has(damage_stat):
		play(bank.synergies[damage_stat])

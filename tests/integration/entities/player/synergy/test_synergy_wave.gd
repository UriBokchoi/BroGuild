extends GutTest
## SynergyWave con física real: suelta su onda desde los pies del jugador al entrar en su estado
## (el dash) o al aterrizar de la caída rápida, con el daño de su stat pasado por las stats de ataque
## y el radio agrandado por el área %. Sin daño (sin su objeto) no suelta nada. En el jugador, el dash y
## la caída rápida la sueltan.

const Target := preload("res://tests/integration/entities/player/synergy/synergy_target.gd")
const FakeState := preload("res://tests/unit/core/state_machine/fake_state.gd")
const DashWaveScene := preload("res://entities/player/synergy/dash_wave.tscn")
const PlayerScene := preload("res://entities/player/player.tscn")

var _machine: StateMachine
var _idle: FakeState
var _dash: FakeState
var _body: Node3D


func before_each() -> void:
	_machine = StateMachine.new()
	add_child_autofree(_machine)
	_idle = FakeState.new()
	_dash = FakeState.new()
	_machine.add_child(_idle)
	_machine.add_child(_dash)
	_machine.initial_state = _idle
	_body = Node3D.new()
	add_child_autofree(_body)
	_machine.start(null)


func test_the_dash_releases_a_wave_that_hits_once_what_it_reaches() -> void:
	var wave := _wave(25.0)
	var near := Target.enemy(self, Vector3(3.0, 0.0, 0.0))
	var far := Target.enemy(self, Vector3(wave.waves()[0].radius + 4.0, 0.0, 0.0))
	await wait_physics_frames(2)
	_machine.transition_to(_dash)
	assert_eq(wave.running(), 1, "sale al entrar en el dash")
	await wait_seconds(wave.waves()[0].duration + 0.2)
	assert_almost_eq(near.get_current(), 75.0, 0.01, "una sola vez")
	assert_eq(far.get_current(), 100.0, "fuera de su alcance")
	assert_eq(wave.running(), 0)


func test_without_damage_nothing_comes_out() -> void:
	var wave := _wave(0.0)
	var released: Array[Vector3] = []
	wave.released.connect(func(at: Vector3, _trauma: float) -> void: released.append(at))
	_machine.transition_to(_dash)
	assert_false(wave.release())
	assert_eq(wave.running(), 0)
	assert_true(released.is_empty())


func test_area_grows_the_radius() -> void:
	var wave := _wave(10.0, 150.0)
	assert_true(wave.release())
	var shockwave := wave.waves()[0]
	assert_almost_eq(shockwave.current_radius(), shockwave.radius * 1.5, 0.001)


func test_chained_waves_use_the_pool() -> void:
	var wave := _wave(10.0)
	wave.release()
	wave.release()
	assert_eq(wave.running(), 2)
	wave.release()
	assert_eq(wave.running(), 2, "con todas en marcha, reinicia una")


func test_the_player_dash_and_slam_release_their_waves() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	var dash_wave := player.get_node("DashWave") as SynergyWave
	var slam := player.get_node("SlamBlast") as SynergyWave
	var fast_fall := player.get_node("Movement/FastFall") as FastFallState
	fast_fall.slammed.emit(45.0)
	assert_eq(slam.running(), 0, "sin su objeto, nada")
	player.stats.add_modifier(StatModifier.create(&"slam_damage", StatModifier.Kind.FLAT, 30.0), self)
	player.stats.add_modifier(StatModifier.create(&"dash_wave_damage", StatModifier.Kind.FLAT, 20.0), self)
	fast_fall.slammed.emit(45.0)
	assert_eq(slam.running(), 1, "explota al aterrizar")
	var shake := player.get_node("ScreenShake") as ScreenShake
	assert_gt(shake.get_trauma(), 0.0, "la explosión hace temblar la pantalla")
	player.movement.state_changed.emit(null, player.get_node("Movement/Dash") as State)
	assert_eq(dash_wave.running(), 1, "onda al entrar en el dash")


func test_the_player_slide_leaves_fire_with_its_rune() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	var trail := player.get_node("FireTrail") as FireTrail
	var slide := player.get_node("Movement/Slide") as State
	player.movement.state_changed.emit(null, slide)
	assert_false(trail.is_trailing(), "sin su objeto, nada")
	player.stats.add_modifier(StatModifier.create(&"fire_trail_damage", StatModifier.Kind.FLAT, 6.0), self)
	player.movement.state_changed.emit(slide, player.get_node("Movement/Ground") as State)
	player.movement.state_changed.emit(null, slide)
	assert_true(trail.is_trailing(), "con su objeto, deja fuego")
	assert_eq(trail.active_patches(), 1)


## Una SynergyWave con la onda del dash, que sale con [member _dash], con [param damage] de daño y
## [param area] % de área.
func _wave(damage: float, area: float = 100.0) -> SynergyWave:
	var synergy := MovementSynergyData.new()
	synergy.dash_wave_damage = damage
	var wave := SynergyWave.new()
	wave.stats = Target.stats(self, synergy, area)
	wave.damage_stat = &"dash_wave_damage"
	wave.body = _body
	wave.machine = _machine
	wave.enter_state = _dash
	wave.wave_scene = DashWaveScene
	add_child_autofree(wave)
	return wave

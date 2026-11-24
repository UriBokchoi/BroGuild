extends Node3D
## La prueba de estrés (se repite al cerrar cada hito): mantiene muchos enemigos a la vez contra un
## jugador quieto e inmortal y mide los fotogramas (media, el 1 % más lento y la física). Va sin
## VSync ni límite de FPS para medir lo que da la máquina, y con semilla fija para que se repita.

@export var player: Player
@export var swarm: EnemySwarm
@export var enemy: EnemyData
## Arma del jugador durante la prueba (para que también cuenten los golpes y los números).
@export var weapon: WeaponData
@export var results_label: Label
## Enemigos a la vez en cada fase.
@export var counts: PackedInt32Array = PackedInt32Array([300, 500])
## Segundos de cada fase antes de medir (para que la horda llegue y se apile).
@export_range(0.0, 60.0, 0.5, "suffix:s") var warmup: float = 5.0
## Segundos que mide cada fase.
@export_range(1.0, 120.0, 0.5, "suffix:s") var measure: float = 8.0
## Distancias al jugador entre las que aparecen.
@export_range(1.0, 100.0, 0.5, "suffix:m") var spawn_min: float = 8.0
@export_range(1.0, 200.0, 0.5, "suffix:m") var spawn_max: float = 35.0
## Enemigos que aparecen como mucho por frame (sin aparecer todos de golpe unos encima de otros).
@export_range(1, 500, 1) var spawns_per_frame: int = 40
@export var run_seed: int = 1
@export var quit_when_done: bool = true

var _rng: RandomNumberGenerator
var _phase: int = 0
var _time: float = 0.0
var _frame_ms: PackedFloat32Array = PackedFloat32Array()
var _physics_ms: float = 0.0
var _results: PackedStringArray = PackedStringArray()


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	Rng.seed_run(run_seed)
	_rng = Rng.stream(Rng.Stream.WAVES)
	player.health.immortal = true
	player.weapons.add(weapon)
	_show()


func _process(delta: float) -> void:
	if _phase >= counts.size():
		return
	_top_up(counts[_phase])
	_time += delta
	if _time < warmup:
		return
	_frame_ms.append(delta * 1000.0)
	_physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	if _time >= warmup + measure:
		_finish_phase()


func _top_up(count: int) -> void:
	var missing := mini(count - swarm.active_count(), spawns_per_frame)
	for _spawn: int in missing:
		var angle := _rng.randf() * TAU
		var distance := _rng.randf_range(spawn_min, spawn_max)
		swarm.spawn(enemy, player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * distance)


func _finish_phase() -> void:
	var sorted := _frame_ms.duplicate()
	sorted.sort()
	var average := 0.0
	for frame: float in sorted:
		average += frame
	average /= sorted.size()
	var slowest := sorted[mini(int(sorted.size() * 0.99), sorted.size() - 1)]
	var line := "%d enemigos: %.2f ms/frame (%.0f fps), 1 %% más lento %.2f ms, física %.2f ms" % [
		counts[_phase], average, 1000.0 / average, slowest, _physics_ms / sorted.size(),
	]
	print("ESTRÉS ", line)
	_results.append(line)
	_show()
	_phase += 1
	_time = 0.0
	_frame_ms.clear()
	_physics_ms = 0.0
	if _phase >= counts.size() and quit_when_done:
		get_tree().quit()


## Herramienta de desarrollo: como el panel de depuración, los resultados no se traducen.
func _show() -> void:
	if results_label:
		results_label.text = "\n".join(_results)

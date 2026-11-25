extends SceneTree
## Herramienta de equilibrio (sin traducir). Pone a cada personaje de data/characters/ quieto contra
## una horda de esbirros inmortales y contra un solo enemigo, al empezar y con una build de mitad de
## partida, y compara su daño por segundo con la media. Escribe líneas «SIM …» y sale.
##
## [codeblock]
## "$G" --headless --path . --fixed-fps 60 -s res://tools/sim_balance.gd
## "$G" --headless --path . --fixed-fps 60 -s res://tools/sim_balance.gd -- weapon   # solo el arma
## [/codeblock]
## Se puede pedir solo una parte de la build: weapon, runes o level. No nombra tipos del juego
## porque se compila antes que los autoloads.

const CHARACTERS_DIR := "res://data/characters"
const SEEDS: Array[int] = [7, 11, 23, 31, 47, 59]
## Ticks de calentamiento y de medida (a 60 por segundo).
const WARMUP: int = 60
const MEASURE: int = 900
const RUNES: Array[String] = ["strength", "multiplicity"]
const RUNE_LEVEL: int = 8
const WEAPON_LEVEL: int = 10
const PLAYER_LEVEL: int = 25
## Anillos de la horda (radio) y separación entre esbirros de un anillo.
const CROWD_RINGS: Array[float] = [2.5, 3.8, 5.1, 6.4, 7.7]
const CROWD_SPACING: float = 1.5
## Dónde está el enemigo solo (al alcance de un arma cuerpo a cuerpo).
const LONE_TARGET := Vector3(0.0, 0.0, -2.2)

var _parts: PackedStringArray = PackedStringArray(["weapon", "runes", "level"])
var _scenarios: Array = []
var _index: int = -1
var _frame: int = 0
var _world: Node3D
var _swarm: Node3D
var _damage: float = 0.0
var _results: Dictionary = {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_parts = args
	for file_name: String in ResourceLoader.list_directory(CHARACTERS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var character := file_name.get_basename()
		for crowd: bool in [true, false]:
			_scenarios.append([character, "base", crowd, 0])
			for seed_value: int in SEEDS:
				_scenarios.append([character, "build", crowd, seed_value])


func _process(_delta: float) -> bool:
	if _index < 0:
		_next()
		return false
	_frame += 1
	var bus: Node = root.get_node(^"EventBus")
	if not bus.is_connected(&"enemy_damaged", _on_damaged):
		bus.connect(&"enemy_damaged", _on_damaged)
	if _frame == WARMUP + MEASURE:
		var scenario: Array = _scenarios[_index]
		var key := "%s|%s|%s" % [scenario[1], "horda" if scenario[2] else "jefe", scenario[0]]
		_results[key] = (_results.get(key, []) as Array) + [_damage / (MEASURE / 60.0)]
		_next()
	return false


func _on_damaged(_at: Vector3, amount: float, _info: RefCounted) -> void:
	if _frame > WARMUP:
		_damage += amount


func _next() -> void:
	if _world:
		_world.free()
		_world = null
	_index += 1
	if _index >= _scenarios.size():
		_report()
		quit()
		return
	_frame = 0
	_damage = 0.0
	var scenario: Array = _scenarios[_index]
	var crowd: bool = scenario[2]
	_build_world(crowd)
	var player := (load("res://entities/player/player.tscn") as PackedScene).instantiate() as Node3D
	player.set(&"character", load("%s/%s.tres" % [CHARACTERS_DIR, scenario[0]]))
	_world.add_child(player)
	var health: Object = player.get(&"health")
	health.set(&"immortal", true)
	# Persiguen al personaje, como en la partida: los golpes los empujan y vuelven.
	_swarm.set(&"target", player)
	if scenario[1] == "build":
		var seed_value: int = scenario[3]
		_build(player, seed_value)


## Una línea por escenario y personaje: su daño por segundo y cuánto se aleja de la media.
func _report() -> void:
	var groups: Dictionary = {}
	for key: String in _results:
		var group := key.get_slice("|", 0) + " " + key.get_slice("|", 1)
		groups[group] = (groups.get(group, []) as Array) + [key]
	for group: String in groups:
		var means: Dictionary = {}
		var total := 0.0
		var keys: Array = groups[group]
		for key: String in keys:
			var values: Array = _results[key]
			var sum := 0.0
			for value: float in values:
				sum += value
			means[key] = sum / values.size()
			total += sum / values.size()
		var average := total / means.size()
		for key: String in means:
			var dps: float = means[key]
			print("SIM %-12s %-10s DPS %8.1f  (%3d %% de la media)" % [group, key.get_slice("|", 2), dps, roundi(dps / average * 100.0)])


func _build_world(crowd: bool) -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120.0, 1.0, 120.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	_world.add_child(ground)
	var swarm: Node3D = (load("res://systems/spawning/enemy_swarm.gd") as GDScript).new()
	_world.add_child(swarm)
	_swarm = swarm
	if not crowd:
		_dummy(swarm, LONE_TARGET)
		return
	for radius: float in CROWD_RINGS:
		var count := int(TAU * radius / CROWD_SPACING)
		for index: int in count:
			var angle := TAU * index / count
			_dummy(swarm, Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))


func _build(player: Node3D, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rarities: Resource = load("res://data/rarities/rarities.tres")
	var weapons: Object = player.get(&"weapons")
	var weapon: Node = (weapons.call(&"get_weapons") as Array)[0]
	var weapon_data: Resource = weapon.get(&"data")
	for _level: int in (WEAPON_LEVEL - 1 if _parts.has("weapon") else 0):
		weapon.call(&"add_upgrade", weapon_data.call(&"roll_upgrade", rarities.call(&"pick", rng), rng))
	var runes: Node = player.get(&"runes")
	for rune_name: String in (RUNES if _parts.has("runes") else [] as Array[String]):
		var rune: Resource = load("res://data/runes/%s.tres" % rune_name)
		runes.call(&"add", rune)
		for _level: int in RUNE_LEVEL - 1:
			runes.call(&"upgrade", rune, rune.call(&"roll_upgrade", rarities.call(&"pick", rng), rng))
	var experience: Node = player.get(&"experience")
	var level: int = experience.call(&"get_level")
	while _parts.has("level") and level < PLAYER_LEVEL:
		var needed: float = experience.call(&"needed")
		experience.call(&"add", needed * 2.0)
		level = experience.call(&"get_level")


## Un esbirro inmortal que persigue al personaje (los golpes lo empujan y vuelve, como en la partida).
func _dummy(swarm: Node3D, at: Vector3) -> void:
	var enemy: Node = swarm.call(&"spawn", load("res://data/enemies/swarmer.tres"), at)
	var health: Object = enemy.get(&"health")
	health.set(&"immortal", true)

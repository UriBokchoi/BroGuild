@abstract
class_name Weapon
extends Node3D
## Arma automática (GDD §6): ataca sola en cuanto acaba su espera y tiene un objetivo a su alcance.
## Cada ataque son [method projectile_count] golpes separados por
## [member WeaponStats.burst_interval]; el primero va al enemigo más cercano, el segundo al segundo
## más cercano, y así (si hay menos enemigos que golpes, se repiten). Qué es un golpe (un tajo, un
## proyectil…) lo decide cada arma en [method _fire]. Combina sus stats ([WeaponStats], con las
## mejoras de su nivel) con las del personaje ([OffenseData]). La monta un [WeaponInventory] con
## [method setup].

## Lanzó el golpe número [param index] (desde 0) de un ataque contra [param target].
signal fired(target: Node3D, index: int)
signal level_changed(level: int)

## Capas de física de los objetivos que busca ([code]enemy_hurtbox[/code] en las del jugador).
@export_flags_3d_physics var target_mask: int = 0
## Altura sobre los pies desde la que busca objetivos y apunta (el pecho de quien la lleva).
@export_range(0.0, 3.0, 0.05, "suffix:m") var aim_height: float = 0.0

## Datos del arma.
var data: WeaponData
## Stats propias del arma (las de [member data] con las mejoras de su nivel).
var stats: StatsComponent
## Stats de quien la lleva. Vacío: el arma usa solo las suyas.
var wielder_stats: StatsComponent
var level: int = 1

var _weapon: WeaponStats
var _offense: OffenseData
var _finder: TargetFinder
var _cooldown_left: float = 0.0
var _shots_left: int = 0
var _shot_index: int = 0
var _shot_timer: float = 0.0


## Prepara el arma antes de añadirla al árbol.
func setup(weapon_data: WeaponData, wielder: StatsComponent) -> void:
	data = weapon_data
	wielder_stats = wielder
	stats = StatsComponent.new()
	stats.name = "Stats"
	stats.sources.append(data.stats)
	add_child(stats)


func _ready() -> void:
	_weapon = stats.get_resolved(WeaponStats) as WeaponStats
	if wielder_stats:
		_offense = wielder_stats.get_resolved(OffenseData) as OffenseData
	_finder = TargetFinder.new(target_mask)


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if _shots_left > 0:
		_shot_timer -= delta
		while _shots_left > 0 and _shot_timer <= 0.0:
			_shoot()
	elif _cooldown_left <= 0.0:
		_start_attack()


## Sube o baja el arma a [param new_level] (entre 1 y su máximo): aplica las mejoras de cada nivel
## hasta ese.
func set_level(new_level: int) -> void:
	new_level = clampi(new_level, 1, data.max_level())
	if new_level == level:
		return
	for level_set: StatModifierSet in data.levels:
		stats.remove_modifiers_from(level_set)
	for index: int in new_level - 1:
		var level_set := data.levels[index]
		for modifier: StatModifier in level_set.stat_modifiers:
			stats.add_modifier(modifier, level_set)
	level = new_level
	level_changed.emit(level)


## Daño de cada golpe antes del daño % y el crítico del personaje (que se aplican al golpear).
func damage() -> float:
	return _weapon.damage


## Segundos entre ataques, con la velocidad de ataque del personaje.
func cooldown() -> float:
	return _weapon.cooldown / _percent(_offense.attack_speed if _offense else 100.0)


## Golpes de cada ataque: los del arma más los proyectiles extra del personaje.
func projectile_count() -> int:
	return _weapon.projectiles + (_offense.projectile_count if _offense else 0)


## Tamaño de los golpes respecto al normal (1 = el de la escena): área del arma × del personaje.
func area_scale() -> float:
	return _percent(_weapon.area) * _percent(_offense.area if _offense else 100.0)


## Segundos que dura cada golpe, con la duración del personaje.
func duration() -> float:
	return _weapon.duration * _percent(_offense.duration if _offense else 100.0)


## Distancia hasta la que busca objetivos. Un arma cuyo alcance crece con el área la cambia.
func reach() -> float:
	return _weapon.reach


## Punto desde el que busca objetivos y apunta: [member aim_height] sobre los pies.
func aim_origin() -> Vector3:
	return global_position + Vector3.UP * aim_height


## Lanza un golpe a [param target]; [param index] es su número dentro del ataque (desde 0).
@abstract func _fire(target: Node3D, index: int) -> void


func _start_attack() -> void:
	var targets := _find_targets()
	if targets.is_empty():
		return
	_cooldown_left = cooldown()
	_shots_left = projectile_count()
	_shot_index = 0
	_shot_timer = 0.0
	_fire_at(targets)


func _shoot() -> void:
	var targets := _find_targets()
	if targets.is_empty():
		# No queda nadie a quien dar: el resto del ataque se pierde.
		_shots_left = 0
		return
	_fire_at(targets)


func _fire_at(targets: Array[Node3D]) -> void:
	var target := targets[_shot_index % targets.size()]
	_fire(target, _shot_index)
	fired.emit(target, _shot_index)
	_shot_index += 1
	_shots_left -= 1
	_shot_timer += _weapon.burst_interval


func _find_targets() -> Array[Node3D]:
	var space := get_world_3d().direct_space_state
	return _finder.nearest(space, aim_origin(), reach(), projectile_count())


static func _percent(value: float) -> float:
	return value / 100.0

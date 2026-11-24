@abstract
class_name Weapon
extends Node3D
## Un arma automática (GDD §6): ataca sola cuando acaba su espera y hay a quién darle. Cada ataque
## son varios golpes seguidos (sus proyectiles), uno al enemigo más cercano, otro al siguiente, y así.
## Qué es un golpe (un tajo, un proyectil…) lo decide cada arma en _fire.
##
## Sus stats son las suyas con las mejoras de su nivel más las del personaje. La monta un
## WeaponInventory con setup.

## Lanzó el golpe número [param index] (desde 0) de un ataque contra [param target].
signal fired(target: Node3D, index: int)
signal level_changed(level: int)

## Capas de física de los objetivos que busca ([code]enemy_hurtbox[/code] en las del jugador,
## [code]player_hurtbox[/code] en las de los enemigos).
@export_flags_3d_physics var target_mask: int = 0
## Capas que tapan la vista (el mundo): no busca objetivos que no se vean. 0 = ve a través de todo.
@export_flags_3d_physics var sight_mask: int = 0
## Altura sobre los pies desde la que busca objetivos y apunta (el pecho de quien la lleva).
@export_range(0.0, 3.0, 0.05, "suffix:m") var aim_height: float = 0.0
## Segundos entre búsquedas de objetivo mientras no encuentra ninguno (0 = en cada tick). Las armas
## de los enemigos, que pueden ser muchas, buscan menos a menudo.
@export_range(0.0, 2.0, 0.01, "suffix:s") var search_interval: float = 0.0

## Datos del arma.
var data: WeaponData
## Stats propias del arma (las de [member data] con las mejoras de su nivel).
var stats: StatsComponent
## Stats de quien la lleva. Vacío: el arma usa solo las suyas.
var wielder_stats: StatsComponent
var level: int = 1
## Azar del golpe de más (la parte decimal de los proyectiles). Sin asignar, el de combate de
## [code]Rng[/code].
var rng: RandomNumberGenerator

var _weapon: WeaponStats
var _offense: OffenseData
var _upgrades: Array[ItemUpgrade] = []
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
		# Opcional: un enemigo no tiene daño % ni crítico.
		_offense = wielder_stats.find_resolved(OffenseData) as OffenseData
	_finder = TargetFinder.new(target_mask, sight_mask)
	if rng == null:
		rng = Rng.stream(Rng.Stream.COMBAT)


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if _shots_left > 0:
		_shot_timer -= delta
		while _shots_left > 0 and _shot_timer <= 0.0:
			_shoot()
	elif _cooldown_left <= 0.0:
		_start_attack()


## Le suma una mejora (un nivel más): sus modificadores van a las stats del arma. Al máximo, no
## hace nada.
func add_upgrade(upgrade: ItemUpgrade) -> void:
	if level >= data.max_level():
		return
	for modifier: StatModifier in upgrade.stat_modifiers:
		stats.add_modifier(modifier, upgrade)
	_upgrades.append(upgrade)
	level += 1
	level_changed.emit(level)


## Mejoras que lleva, de la primera a la última.
func get_upgrades() -> Array[ItemUpgrade]:
	return _upgrades.duplicate()


## Sube o baja el arma a [param new_level] (entre 1 y su máximo): para subir, suma mejoras
## estándar ([method ItemData.default_upgrade]; la armería de práctica); para bajar, quita las
## últimas.
func set_level(new_level: int) -> void:
	new_level = clampi(new_level, 1, data.max_level())
	while level < new_level:
		add_upgrade(data.default_upgrade())
	while level > new_level:
		var last: ItemUpgrade = _upgrades.pop_back()
		stats.remove_modifiers_from(last)
		level -= 1
		level_changed.emit(level)


## Deja de atacar hasta [method rearm] y corta el ataque a medias (quien la lleva murió).
func disarm() -> void:
	set_physics_process(false)
	_shots_left = 0
	_disarmed()


## Vuelve a atacar cuando pasen [param wait] segundos.
func rearm(wait: float) -> void:
	_cooldown_left = maxf(wait, 0.0)
	_shots_left = 0
	set_physics_process(true)


## Daño de cada golpe antes del daño % y el crítico del personaje (que se aplican al golpear).
func damage() -> float:
	return _weapon.damage


## Stats de ataque de quien la lleva (su daño % y su crítico), o [code]null[/code] si no tiene.
func offense() -> OffenseData:
	return _offense


## Segundos entre ataques, con la velocidad de ataque del personaje.
func cooldown() -> float:
	return _weapon.cooldown / _percent(_offense.attack_speed if _offense else 100.0)


## Golpes de cada ataque: los del arma más los proyectiles extra del personaje. Puede llevar
## decimales: la parte decimal es la probabilidad de un golpe más (ver [method roll_shots]).
func projectile_count() -> float:
	return _weapon.projectiles + (_offense.projectile_count if _offense else 0.0)


## Golpes de un ataque: la parte entera de [method projectile_count] y, con la probabilidad de su
## parte decimal, uno más.
func roll_shots() -> int:
	var count := projectile_count()
	var whole := floori(count)
	return whole + (1 if rng.randf() < count - whole else 0)


## Tamaño de los golpes respecto al normal (1 = el de la escena): área del arma × del personaje.
func area_scale() -> float:
	return _percent(_weapon.area) * _percent(_offense.area if _offense else 100.0)


## Segundos que dura cada golpe, con la duración del personaje.
func duration() -> float:
	return _weapon.duration * _percent(_offense.duration if _offense else 100.0)


## Empuje de cada golpe antes del empuje % del personaje (que se aplica al golpear).
func knockback() -> float:
	return _weapon.knockback


## Distancia hasta la que busca objetivos. Un arma cuyo alcance crece con el área la cambia.
func reach() -> float:
	return _weapon.reach


## Punto desde el que busca objetivos y apunta: [member aim_height] sobre los pies.
func aim_origin() -> Vector3:
	return global_position + Vector3.UP * aim_height


## Lanza un golpe a [param target]; [param index] es su número dentro del ataque (desde 0).
@abstract func _fire(target: Node3D, index: int) -> void


## Acaba de dejar de atacar ([method disarm]): para retirar lo que tenga en juego.
func _disarmed() -> void:
	pass


func _start_attack() -> void:
	var targets := _find_targets()
	if targets.is_empty():
		_cooldown_left = search_interval
		return
	_cooldown_left = cooldown()
	_shots_left = roll_shots()
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
	return _finder.nearest(space, aim_origin(), reach(), ceili(projectile_count()))


static func _percent(value: float) -> float:
	return value / 100.0

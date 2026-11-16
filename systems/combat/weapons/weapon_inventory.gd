class_name WeaponInventory
extends Node3D
## Armas que lleva una entidad (el jugador): las crea a partir de su [WeaponData], las tiene como
## hijas (atacan desde su posición) y las quita. Cada arma combina sus stats con las de
## [member wielder_stats].

signal weapon_added(weapon: Weapon)
signal weapon_removed(data: WeaponData)

## Stats de quien lleva las armas (su daño %, crítico, velocidad de ataque…).
@export var wielder_stats: StatsComponent
## Armas con las que empieza.
@export var starting_weapons: Array[WeaponData] = []

## Pool compartido para los proyectiles de sus armas (ver [member ProjectileWeapon.shared_pool]):
## lo usan los enemigos. Vacío: cada arma tiene el suyo.
var projectile_pool: ProjectilePool

var _weapons: Array[Weapon] = []


func _ready() -> void:
	for weapon_data: WeaponData in starting_weapons:
		add(weapon_data)


## Añade el arma de [param weapon_data] a nivel 1 y la devuelve. Si ya la lleva, no hace nada y
## devuelve [code]null[/code].
func add(weapon_data: WeaponData) -> Weapon:
	if weapon_data == null or has(weapon_data):
		return null
	var weapon := weapon_data.scene.instantiate() as Weapon
	if weapon == null:
		push_error("WeaponInventory: la escena de '%s' no es un Weapon." % weapon_data.id)
		return null
	weapon.setup(weapon_data, wielder_stats)
	var shooter := weapon as ProjectileWeapon
	if shooter:
		shooter.shared_pool = projectile_pool
	add_child(weapon)
	_weapons.append(weapon)
	weapon_added.emit(weapon)
	return weapon


## Quita el arma de [param weapon_data], si la lleva.
func remove(weapon_data: WeaponData) -> void:
	var weapon := get_weapon(weapon_data)
	if weapon == null:
		return
	_weapons.erase(weapon)
	# Se queda en el árbol, parada, hasta que se borre al acabar el frame: no ataca más ni queda
	# huérfana mientras tanto.
	weapon.process_mode = Node.PROCESS_MODE_DISABLED
	weapon.queue_free()
	weapon_removed.emit(weapon_data)


## El arma de [param weapon_data] que lleva, o [code]null[/code].
func get_weapon(weapon_data: WeaponData) -> Weapon:
	for weapon: Weapon in _weapons:
		if weapon.data.id == weapon_data.id:
			return weapon
	return null


func has(weapon_data: WeaponData) -> bool:
	return get_weapon(weapon_data) != null


## Armas que lleva, en el orden en que las consiguió.
func get_weapons() -> Array[Weapon]:
	return _weapons.duplicate()

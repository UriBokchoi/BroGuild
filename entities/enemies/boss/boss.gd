class_name Boss
extends Enemy
## Un jefe (GDD §9): un Enemy grande que persigue al jugador y, cada poco, hace uno de sus ataques
## (sus hijos BossAttack), elegido al azar por peso. Mientras ataca no persigue: el ataque mueve el
## cuerpo.
##
## Con poca vida entra en rabia: va más rápido y ataca más a menudo. Pide refuerzos con
## summon_requested y el BossEncounter los saca. Una bomba no lo mata de golpe.

## Pide [param count] enemigos de [param enemy] alrededor de [param center], entre
## [param min_distance] y [param max_distance].
signal summon_requested(enemy: EnemyData, count: int, center: Vector3, min_distance: float, max_distance: float)

## Segundos persiguiendo entre un ataque y el siguiente.
@export_range(0.1, 30.0, 0.1, "suffix:s") var attack_interval: float = 4.0
## Lo mismo con rabia.
@export_range(0.1, 30.0, 0.1, "suffix:s") var enraged_attack_interval: float = 2.5
## Parte de su vida por debajo de la cual entra en rabia (0 = nunca).
@export_range(0.0, 1.0, 0.05) var enrage_below: float = 0.5
## Mejoras de la rabia (hasta que vuelva a salir).
@export var enrage: StatModifierSet
## Material encima de sus mallas con rabia.
@export var enrage_overlay: Material
## Cuánto más ancho se pone al aplastarse, por cada parte de alto que pierde ([method squash]).
@export_range(0.0, 2.0, 0.05) var squash_widen: float = 0.5

var _attacks: Array[BossAttack] = []
var _attack: BossAttack
var _until_attack: float = 0.0
var _enraged: bool = false


func _ready() -> void:
	for child: Node in get_children():
		var attack := child as BossAttack
		if attack:
			attack.boss = self
			_attacks.append(attack)
	super()
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_stop_attack)


func spawn(feet: Vector3) -> void:
	super(feet)
	_enraged = false
	_set_overlay(null)
	_until_attack = attack_interval


func deactivate() -> void:
	_stop_attack()
	super()


func is_boss() -> bool:
	return true


func is_enraged() -> bool:
	return _enraged


## Ataque que está haciendo ahora, o [code]null[/code] si persigue.
func get_attack() -> BossAttack:
	return _attack


## Daño al tocar con sus stats de ahora (con el escalado de la dificultad): la base del daño de sus
## ataques.
func get_contact_damage() -> float:
	return _stats.contact_damage


## Empuje al tocar: la base del de sus ataques.
func get_contact_knockback() -> float:
	return _stats.knockback


## Cambia su velocidad horizontal (la vertical es de la física).
func move_flat(velocity: Vector3) -> void:
	linear_velocity = Vector3(velocity.x, linear_velocity.y, velocity.z)


## Gira el modelo hacia [param point] con su rapidez de giro.
func face_toward(point: Vector3, delta: float) -> void:
	_face(point - global_position, delta)


## Aplasta el modelo: [param factor] veces su alto (y algo más ancho). 1 = normal.
func squash(factor: float) -> void:
	var widen := 1.0 + (1.0 - factor) * squash_widen
	visual.scale = _rest_scale * _size * Vector3(widen, factor, widen)


## Pide refuerzos (ver [signal summon_requested]).
func summon(enemy: EnemyData, count: int, min_distance: float, max_distance: float) -> void:
	summon_requested.emit(enemy, count, global_position, min_distance, max_distance)


func physics_step(
	delta: float,
	target: Vector3,
	has_target: bool,
	neighbors: PackedVector3Array,
	footholds: PackedVector3Array,
) -> void:
	if _attack and not health.is_dead():
		if _attack.step(delta, target):
			_attack = null
			_until_attack = enraged_attack_interval if _enraged else attack_interval
		return
	super(delta, target, has_target, neighbors, footholds)
	if health.is_dead() or not has_target:
		return
	_until_attack -= delta
	if _until_attack <= 0.0:
		_start_attack(target)


func _start_attack(target: Vector3) -> void:
	var choices: Array[BossAttack] = []
	choices.assign(_attacks.filter(
		func(attack: BossAttack) -> bool: return attack.weight > 0.0 and (_enraged or not attack.enraged_only)
	))
	var total := 0.0
	for attack: BossAttack in choices:
		total += attack.weight
	var roll := rng.randf() * total
	for attack: BossAttack in choices:
		roll -= attack.weight
		if roll < 0.0:
			_attack = attack
			break
	if _attack == null:
		_until_attack = attack_interval
		return
	_attack.begin(target)


func _stop_attack() -> void:
	if _attack:
		_attack.cancel()
		_attack = null
	squash(1.0)


func _set_overlay(material: Material) -> void:
	for mesh: GeometryInstance3D in _meshes:
		mesh.material_overlay = material


func _on_health_changed(current: float, maximum: float) -> void:
	if _enraged or health.is_dead() or maximum <= 0.0 or current / maximum > enrage_below:
		return
	_enraged = true
	if enrage:
		_add_modifiers(enrage)
	_set_overlay(enrage_overlay)

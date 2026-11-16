class_name Enemy
extends RigidBody3D
## Enemigo: un cuerpo físico sin rotación que choca con el mundo, con el jugador y con otros
## enemigos. Se empujan y, con la presión de la horda, se apilan unos encima de otros, como en
## Megabonk. Persigue al objetivo separándose un poco de los que tiene al lado ([EnemySteering]), o
## se queda a su distancia si es de los que disparan ([member EnemyStats.keep_distance]). Hace daño
## al tocar (su hitbox de contacto) y con sus armas, si tiene ([member EnemyData.weapons]); al
## morir, sus armas paran (sus disparos en vuelo siguen) y él encoge y desaparece. No se mueve solo:
## un [EnemySwarm] lo saca de su pool con [method spawn], fija su velocidad horizontal con
## [method physics_step] cada tick (la física pone la gravedad y los choques) y lo guarda cuando
## avisa con [signal despawned]. Sus stats salen de su [EnemyData] ([method setup]).

## Acaba de morir (aún encogiéndose).
signal died(enemy: Enemy)
## Terminó de desaparecer: puede volver al pool.
signal despawned(enemy: Enemy)

@export var stats: StatsComponent
@export var health: HealthComponent
@export var hurtbox: HurtboxComponent
## Hitbox que daña al jugador al tocarlo.
@export var contact_hitbox: HitboxComponent
## Modelo: mira hacia donde va y encoge al morir.
@export var visual: Node3D
## Segundos que tarda en encoger al morir.
@export_range(0.0, 2.0, 0.01, "suffix:s") var death_time: float = 0.15
## Rapidez con la que gira hacia donde va.
@export_range(0.1, 60.0, 0.1, "suffix:1/s") var turn_speed: float = 12.0
## Al aparecer, sus armas esperan antes del primer ataque esta parte de su espera normal, al azar
## entre x e y: así no disparan nada más salir ni todos los que salen juntos a la vez.
@export var first_attack_delay: Vector2 = Vector2(0.5, 1.0)

## Tipo de enemigo.
var data: EnemyData
## Sus armas ([member EnemyData.weapons]), o [code]null[/code] si solo ataca al tocar.
var weapons: WeaponInventory
## Azar del desvío de aproximación. Si no se asigna antes de entrar en el árbol, el flujo de
## enemigos de [code]Rng[/code].
var rng: RandomNumberGenerator
## Si es élite en esta vida, cómo ([method promote]); si no, [code]null[/code].
var elite: EliteData

var _stats: EnemyStats
var _rest_scale: Vector3 = Vector3.ONE
var _rest_mass: float = 1.0
## Tamaño de esta vida respecto al normal (ver [member EliteData.size]).
var _size: float = 1.0
## Formas de colisión y marcadores que crecen con el tamaño, con su transform normal.
var _sized: Dictionary[Node3D, Transform3D] = {}
## Mallas del modelo (para el brillo de élite).
var _meshes: Array[GeometryInstance3D] = []
## Mejoras de esta vida ([method boost]); se quitan al volver a salir.
var _boosts: Array[StatModifierSet] = []
var _dying_left: float = 0.0
## Hacia dónde apartarse si otro enemigo está justo al lado (distinto para cada uno).
var _fallback: Vector3 = Vector3.RIGHT
## Desvío con el que se acerca al objetivo en esta vida, en radianes.
var _approach_angle: float = 0.0


## Prepara el enemigo antes de añadirlo al árbol. Sus armas disparan desde [param projectiles] (el
## pool compartido de los enemigos: así sus disparos sobreviven a su muerte); sin él, cada arma
## tiene el suyo.
func setup(enemy_data: EnemyData, projectiles: ProjectilePool = null) -> void:
	data = enemy_data
	stats.sources.assign(enemy_data.stat_sources)
	if not enemy_data.weapons.is_empty():
		weapons = WeaponInventory.new()
		weapons.name = "Weapons"
		weapons.wielder_stats = stats
		weapons.projectile_pool = projectiles
		weapons.starting_weapons.assign(enemy_data.weapons)
		add_child(weapons)


func _ready() -> void:
	_stats = stats.get_resolved(EnemyStats) as EnemyStats
	_rest_scale = visual.scale
	_rest_mass = mass
	for shape: Node in find_children("*", "CollisionShape3D", true, false):
		_sized[shape as Node3D] = (shape as Node3D).transform
	for child: Node in get_children():
		# Marcadores como el de los números de daño: suben con el tamaño.
		var marker := child as Node3D
		if marker and marker != visual and marker != weapons and not marker is CollisionObject3D and not marker is CollisionShape3D:
			_sized[marker] = marker.transform
	for mesh: Node in visual.find_children("*", "GeometryInstance3D", true, false):
		_meshes.append(mesh as GeometryInstance3D)
	_fallback = Vector3.RIGHT.rotated(Vector3.UP, float(get_instance_id() % 360))
	if rng == null:
		rng = Rng.stream(Rng.Stream.ENEMIES)
	health.died.connect(_on_died)
	deactivate()


## Lo pone en juego en [param feet], quieto, normal (sin las mejoras de su vida anterior) y con la
## vida llena. Quien lo saca puede mejorarlo después con [method boost] o [method promote].
func spawn(feet: Vector3) -> void:
	# Primero vuelve a la física; luego se coloca, para que el cuerpo aparezca ahí.
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	global_position = feet
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_clear_boosts()
	contact_hitbox.reset_hits()
	contact_hitbox.monitoring = true
	hurtbox.monitorable = true
	_dying_left = 0.0
	_approach_angle = deg_to_rad(rng.randf_range(-_stats.approach_spread, _stats.approach_spread))
	if weapons:
		for weapon: Weapon in weapons.get_weapons():
			weapon.rearm(weapon.cooldown() * rng.randf_range(first_attack_delay.x, first_attack_delay.y))
	reset_physics_interpolation()


## Lo mejora hasta que vuelva al pool: aplica [param modifiers] a sus stats y a las de sus armas
## (cada modificador adonde exista su stat) y le llena la vida. Lo usan los élites y el escalado de
## la dificultad.
func boost(modifiers: StatModifierSet) -> void:
	if modifiers == null:
		return
	_boosts.append(modifiers)
	for modifier: StatModifier in modifiers.stat_modifiers:
		for target_stats: StatsComponent in _all_stats():
			if target_stats.has_stat(modifier.stat):
				target_stats.add_modifier(modifier, modifiers)
	_refresh()


## Lo hace élite hasta que vuelva al pool: con las mejoras de [param elite_data], más grande y con
## su brillo.
func promote(elite_data: EliteData) -> void:
	elite = elite_data
	boost(elite_data.stat_modifiers)
	_resize(elite_data.size)
	for mesh: GeometryInstance3D in _meshes:
		mesh.material_overlay = elite_data.overlay


func is_elite() -> bool:
	return elite != null


## Lo saca del juego: invisible y fuera de la física hasta el siguiente [method spawn].
func deactivate() -> void:
	_disarm()
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func is_alive() -> bool:
	return visible and not health.is_dead()


## ¿Está apoyado (ni sube ni cae)? Solo así sirve de apoyo para que otro trepe encima.
func is_settled() -> bool:
	return is_alive() and absf(linear_velocity.y) < EnemySteering.SETTLED_SPEED


## Experiencia que suelta al morir (con los modificadores que tenga, p. ej. de élite).
func xp_reward() -> float:
	return _stats.xp_reward


## Oro que suelta al morir (con sus modificadores).
func gold_reward() -> float:
	return _stats.gold_reward


## Distancia a la que mira a sus vecinos para separarse y para trepar.
func separation_radius() -> float:
	return _stats.separation_radius


## Un tick: acelera hacia [param target] (si [param has_target]) separándose de [param neighbors]
## (posiciones de otros enemigos cercanos) y trepando sobre [param footholds] (los de ellos que
## están apoyados) si se atasca, o sigue encogiendo si está muriendo. Cambia la velocidad
## horizontal; la vertical es de la física (gravedad, pilas), salvo cuando trepa.
func physics_step(
	delta: float,
	target: Vector3,
	has_target: bool,
	neighbors: PackedVector3Array,
	footholds: PackedVector3Array,
) -> void:
	if health.is_dead():
		_shrink(delta)
		return
	var chase := Vector3.ZERO
	var keeps_range := _stats.keep_distance > 0.0
	if has_target and keeps_range:
		chase = EnemySteering.keep_range(
			global_position, target, _stats.move_speed, _approach_angle, _stats.keep_distance
		)
	elif has_target:
		chase = EnemySteering.approach(global_position, target, _stats.move_speed, _approach_angle)
	var push := EnemySteering.separation(global_position, neighbors, _stats.separation_radius, _fallback)
	var desired := (chase + push * _stats.separation_weight * _stats.move_speed).limit_length(_stats.move_speed)
	var current := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var vertical := linear_velocity.y
	if _is_stuck_behind(current, chase, target, footholds):
		vertical = maxf(vertical, _stats.climb_speed)
	var horizontal := current.move_toward(desired, _stats.acceleration * delta)
	linear_velocity = Vector3(horizontal.x, vertical, horizontal.z)
	# Uno que guarda la distancia mira siempre a su objetivo (también al retroceder).
	_face(target - global_position if has_target and keeps_range else horizontal, delta)


## ¿Quiere avanzar pero va frenado porque un enemigo apoyado le tapa el paso, y aún no está más alto
## de lo que necesita para llegar al objetivo? Entonces trepa encima (si trepa).
func _is_stuck_behind(current: Vector3, chase: Vector3, target: Vector3, footholds: PackedVector3Array) -> bool:
	if _stats.climb_speed <= 0.0 or chase.is_zero_approx():
		return false
	if current.length() > _stats.move_speed * EnemySteering.STUCK_SPEED:
		return false
	if global_position.y > target.y + _stats.climb_height:
		return false
	var reach := _stats.separation_radius
	return EnemySteering.blocked_ahead(global_position, chase.normalized(), target, footholds, reach)


func _face(direction: Vector3, delta: float) -> void:
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		return
	# Con rotation.y = θ, −Z apunta a (−sen θ, −cos θ).
	var yaw := atan2(-direction.x, -direction.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, yaw, 1.0 - exp(-turn_speed * delta))


func _shrink(delta: float) -> void:
	_dying_left -= delta
	if _dying_left > 0.0:
		visual.scale = _rest_scale * _size * (_dying_left / death_time)
		return
	deactivate()
	despawned.emit(self)


## Stats suyas y de sus armas: adonde van las mejoras.
func _all_stats() -> Array[StatsComponent]:
	var all: Array[StatsComponent] = [stats]
	if weapons:
		for weapon: Weapon in weapons.get_weapons():
			all.append(weapon.stats)
	return all


## Quita las mejoras de su vida anterior y vuelve a su tamaño y aspecto normales.
func _clear_boosts() -> void:
	for modifiers: StatModifierSet in _boosts:
		for target_stats: StatsComponent in _all_stats():
			target_stats.remove_modifiers_from(modifiers)
	_boosts.clear()
	# Solo si fue élite: rehacer formas y materiales en cada aparición cuesta con cientos de enemigos.
	if elite:
		elite = null
		_resize(1.0)
		for mesh: GeometryInstance3D in _meshes:
			mesh.material_overlay = null
	else:
		visual.scale = _rest_scale
	_refresh()


## Vida llena y daño al tocar con sus stats de ahora.
func _refresh() -> void:
	health.reset()
	contact_hitbox.base_damage = _stats.contact_damage
	contact_hitbox.rehit_interval = _stats.contact_interval


## Cambia su tamaño a [param factor] veces el normal: formas de colisión, marcadores, modelo y masa.
func _resize(factor: float) -> void:
	_size = factor
	for node: Node3D in _sized:
		var rest := _sized[node]
		node.transform = Transform3D(rest.basis.scaled(Vector3.ONE * factor), rest.origin * factor)
	visual.scale = _rest_scale * factor
	mass = _rest_mass * factor * factor * factor


## Sus armas dejan de atacar.
func _disarm() -> void:
	if weapons:
		for weapon: Weapon in weapons.get_weapons():
			weapon.disarm()


func _on_died() -> void:
	# Ya no recibe ni hace daño; desaparece al terminar de encoger.
	hurtbox.set_deferred(&"monitorable", false)
	contact_hitbox.set_deferred(&"monitoring", false)
	_disarm()
	_dying_left = death_time
	EventBus.enemy_died.emit(self)
	died.emit(self)

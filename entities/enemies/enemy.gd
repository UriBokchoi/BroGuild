class_name Enemy
extends RigidBody3D
## Enemigo: un cuerpo físico sin rotación que choca con el mundo, con el jugador y con otros
## enemigos. Se empujan y, con la presión de la horda, se apilan unos encima de otros, como en
## Megabonk. Persigue al objetivo separándose un poco de los que tiene al lado ([EnemySteering]),
## hace daño al tocar (su hitbox de contacto) y, al morir, encoge y desaparece. No se mueve solo:
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

## Tipo de enemigo.
var data: EnemyData
## Azar del desvío de aproximación. Si no se asigna antes de entrar en el árbol, el flujo de
## enemigos de [code]Rng[/code].
var rng: RandomNumberGenerator

var _stats: EnemyStats
var _rest_scale: Vector3 = Vector3.ONE
var _dying_left: float = 0.0
## Hacia dónde apartarse si otro enemigo está justo al lado (distinto para cada uno).
var _fallback: Vector3 = Vector3.RIGHT
## Desvío con el que se acerca al objetivo en esta vida, en radianes.
var _approach_angle: float = 0.0


## Prepara el enemigo antes de añadirlo al árbol.
func setup(enemy_data: EnemyData) -> void:
	data = enemy_data
	stats.sources.assign(enemy_data.stat_sources)


func _ready() -> void:
	_stats = stats.get_resolved(EnemyStats) as EnemyStats
	_rest_scale = visual.scale
	_fallback = Vector3.RIGHT.rotated(Vector3.UP, float(get_instance_id() % 360))
	if rng == null:
		rng = Rng.stream(Rng.Stream.ENEMIES)
	health.died.connect(_on_died)
	deactivate()


## Lo pone en juego en [param feet], quieto y con la vida llena.
func spawn(feet: Vector3) -> void:
	# Primero vuelve a la física; luego se coloca, para que el cuerpo aparezca ahí.
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	global_position = feet
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	health.reset()
	contact_hitbox.base_damage = _stats.contact_damage
	contact_hitbox.rehit_interval = _stats.contact_interval
	contact_hitbox.reset_hits()
	contact_hitbox.monitoring = true
	hurtbox.monitorable = true
	visual.scale = _rest_scale
	_dying_left = 0.0
	_approach_angle = deg_to_rad(rng.randf_range(-_stats.approach_spread, _stats.approach_spread))
	reset_physics_interpolation()


## Lo saca del juego: invisible y fuera de la física hasta el siguiente [method spawn].
func deactivate() -> void:
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
	if has_target:
		chase = EnemySteering.approach(global_position, target, _stats.move_speed, _approach_angle)
	var push := EnemySteering.separation(global_position, neighbors, _stats.separation_radius, _fallback)
	var desired := (chase + push * _stats.separation_weight * _stats.move_speed).limit_length(_stats.move_speed)
	var current := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var vertical := linear_velocity.y
	if _is_stuck_behind(current, chase, target, footholds):
		vertical = maxf(vertical, _stats.climb_speed)
	var horizontal := current.move_toward(desired, _stats.acceleration * delta)
	linear_velocity = Vector3(horizontal.x, vertical, horizontal.z)
	_face(horizontal, delta)


## ¿Quiere avanzar pero va frenado porque un enemigo apoyado le tapa el paso, y aún no está más alto
## de lo que necesita para llegar al objetivo? Entonces trepa encima.
func _is_stuck_behind(current: Vector3, chase: Vector3, target: Vector3, footholds: PackedVector3Array) -> bool:
	if chase.is_zero_approx() or current.length() > _stats.move_speed * EnemySteering.STUCK_SPEED:
		return false
	if global_position.y > target.y + _stats.climb_height:
		return false
	var reach := _stats.separation_radius
	return EnemySteering.blocked_ahead(global_position, chase.normalized(), target, footholds, reach)


func _face(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.01:
		return
	# Con rotation.y = θ, −Z apunta a (−sen θ, −cos θ).
	var yaw := atan2(-direction.x, -direction.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, yaw, 1.0 - exp(-turn_speed * delta))


func _shrink(delta: float) -> void:
	_dying_left -= delta
	if _dying_left > 0.0:
		visual.scale = _rest_scale * (_dying_left / death_time)
		return
	deactivate()
	despawned.emit(self)


func _on_died() -> void:
	# Ya no recibe ni hace daño; desaparece al terminar de encoger.
	hurtbox.set_deferred(&"monitorable", false)
	contact_hitbox.set_deferred(&"monitoring", false)
	_dying_left = death_time
	EventBus.enemy_died.emit(self)
	died.emit(self)

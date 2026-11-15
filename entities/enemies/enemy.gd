class_name Enemy
extends CharacterBody3D
## Enemigo: persigue al objetivo separándose de los demás ([EnemySteering]), hace daño al tocar
## (su hitbox de contacto) y, al morir, encoge y desaparece. No se mueve solo: un [EnemySwarm] lo
## saca de su pool con [method spawn], lo mueve con [method physics_step] cada tick y lo guarda
## cuando avisa con [signal despawned]. Sus stats salen de su [EnemyData] ([method setup]).

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

var _stats: EnemyStats
var _rest_scale: Vector3 = Vector3.ONE
var _dying_left: float = 0.0
## Hacia dónde apartarse si otro enemigo está justo encima (distinto para cada uno).
var _fallback: Vector3 = Vector3.RIGHT


## Prepara el enemigo antes de añadirlo al árbol.
func setup(enemy_data: EnemyData) -> void:
	data = enemy_data
	stats.sources.assign(enemy_data.stat_sources)


func _ready() -> void:
	_stats = stats.get_resolved(EnemyStats) as EnemyStats
	_rest_scale = visual.scale
	_fallback = Vector3.RIGHT.rotated(Vector3.UP, float(get_instance_id() % 360))
	health.died.connect(_on_died)
	deactivate()


## Lo pone en juego en [param feet], con la vida llena.
func spawn(feet: Vector3) -> void:
	global_position = feet
	velocity = Vector3.ZERO
	health.reset()
	contact_hitbox.base_damage = _stats.contact_damage
	contact_hitbox.rehit_interval = _stats.contact_interval
	contact_hitbox.reset_hits()
	contact_hitbox.monitoring = true
	hurtbox.monitorable = true
	visual.scale = _rest_scale
	_dying_left = 0.0
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	reset_physics_interpolation()


## Lo saca del juego: invisible y fuera de la física hasta el siguiente [method spawn].
func deactivate() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func is_alive() -> bool:
	return visible and not health.is_dead()


## Distancia a la que mira a sus vecinos para separarse.
func separation_radius() -> float:
	return _stats.separation_radius


## Un tick: persigue [param target] (si [param has_target]) separándose de [param neighbors]
## (posiciones de otros enemigos cercanos), o sigue encogiendo si está muriendo.
func physics_step(delta: float, target: Vector3, has_target: bool, neighbors: PackedVector3Array) -> void:
	if health.is_dead():
		_shrink(delta)
		return
	var desired := EnemySteering.seek(global_position, target, _stats.move_speed) if has_target else Vector3.ZERO
	var push := EnemySteering.separation(global_position, neighbors, _stats.separation_radius, _fallback)
	desired = (desired + push * _stats.separation_weight * _stats.move_speed).limit_length(_stats.move_speed)
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(desired, _stats.acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
	_face(horizontal, delta)


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
	velocity = Vector3.ZERO
	_dying_left = death_time
	EventBus.enemy_died.emit(data, global_position)
	died.emit(self)

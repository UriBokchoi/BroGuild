class_name Shockwave
extends Node3D
## Una onda que se abre por el suelo (el salto del jefe, el dash, la caída del jugador). Daña una vez
## a lo que alcanza su borde y lo empuja hacia fuera. Se esquiva saltándola: lo que está más alto que
## reach_height no se lleva el golpe. Se ve como un aro que se abre y se apaga.

## Salió desde [param center].
signal started(center: Vector3)

## Radio final (sin agrandar: ver [method start]).
@export_range(0.5, 100.0, 0.5, "suffix:m") var radius: float = 12.0
## Segundos que tarda en llegar al radio final.
@export_range(0.05, 5.0, 0.05, "suffix:s") var duration: float = 0.8
## Ancho del borde que daña.
@export_range(0.1, 5.0, 0.05, "suffix:m") var band: float = 1.5
## Altura del centro de una hurtbox sobre el suelo de la onda hasta la que daña.
@export_range(0.1, 5.0, 0.05, "suffix:m") var reach_height: float = 1.3
## Empuje hacia fuera de lo que alcanza.
@export_range(0.0, 50.0, 0.5, "or_greater", "suffix:m/s") var knockback: float = 0.0
## A quién daña (capas de hurtbox).
@export_flags_3d_physics var hit_mask: int = 0
## Hurtbox que mira como mucho en cada tick (también las que ya golpeó, más cerca del centro):
## pocas contra el jugador, muchas contra una horda.
@export_range(1, 512, 1) var max_results: int = 8
## Aro que se ve: un plano de 2 × 2 con [code]ground_ring.gdshader[/code] (se escala al radio).
@export var ring: GeometryInstance3D

## Azar del crítico. Si no se asigna antes de entrar en el árbol, el flujo de combate de
## [code]Rng[/code].
var rng: RandomNumberGenerator

var _damage: float = 0.0
var _offense: OffenseData
## Radio final de esta onda ([member radius] por el tamaño de [method start]).
var _radius: float = 0.0
var _elapsed: float = 0.0
## Hurtbox ya golpeadas en esta onda (por id de instancia).
var _hit: Dictionary[int, bool] = {}
var _sphere := SphereShape3D.new()
var _query := PhysicsShapeQueryParameters3D.new()


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.COMBAT)
	_query.shape = _sphere
	_query.collide_with_areas = true
	_query.collide_with_bodies = false
	_query.collision_mask = hit_mask
	_resize(radius)
	stop()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var progress := minf(_elapsed / duration, 1.0)
	ring.set_instance_shader_parameter(&"progress", progress)
	ring.set_instance_shader_parameter(&"fade", 1.0 - progress * progress)
	_hit_edge(_radius * progress)
	if progress >= 1.0:
		stop()


## Sale desde [param center] (en el suelo), con [param damage] de daño por golpe. Con
## [param offense] (las stats de ataque de quien la lanza), el daño pasa por su daño % y su crítico,
## y el empuje por su empuje %. [param size] agranda el radio (el área % del jugador: 1,2 = un 20 %
## más).
func start(center: Vector3, damage: float, offense: OffenseData = null, size: float = 1.0) -> void:
	global_position = center
	_damage = damage
	_offense = offense
	_resize(radius * size)
	_elapsed = 0.0
	_hit.clear()
	visible = true
	set_physics_process(true)
	started.emit(center)


## Se apaga (al terminar o si el jefe se retira).
func stop() -> void:
	visible = false
	set_physics_process(false)


func is_running() -> bool:
	return is_physics_processing()


## Radio final de la onda en marcha (o de la última).
func current_radius() -> float:
	return _radius


func _resize(final_radius: float) -> void:
	_radius = final_radius
	ring.scale = Vector3.ONE * final_radius
	ring.set_instance_shader_parameter(&"band", band / final_radius)


## Daña a las hurtbox que toca el borde (a [param edge] del centro) y no han recibido ya.
func _hit_edge(edge: float) -> void:
	_sphere.radius = edge + band
	_query.transform = Transform3D(Basis.IDENTITY, global_position)
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(_query, max_results):
		var collider: Object = result["collider"]
		var hurtbox := collider as HurtboxComponent
		if hurtbox == null or _hit.has(hurtbox.get_instance_id()):
			continue
		var at := hurtbox.get_center()
		var distance := Vector2(at.x - global_position.x, at.z - global_position.z).length()
		if absf(distance - edge) > band * 0.5 or at.y - global_position.y > reach_height:
			continue
		_hit[hurtbox.get_instance_id()] = true
		var push := DamageCalc.push(global_position, at, knockback)
		hurtbox.receive(DamageCalc.attack(_damage, _offense, rng, self, push))

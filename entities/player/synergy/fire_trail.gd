class_name FireTrail
extends Node3D
## Rastro ardiente: mientras el jugador está en [member trail_state] (el slide), deja manchas de fuego
## en el suelo cada [member spacing] metros. Cada [member burn_interval] segundos, lo que pisa alguna
## mancha (hurtbox de [member hit_mask]) se quema: recibe [code]fire_trail_damage[/code] de su
## [MovementSynergyData] (0 sin su objeto: entonces no deja nada), con el daño % y el crítico del
## jugador. Una sola quemadura por tick aunque pise varias manchas. Escala con las stats del jugador
## como un arma: el daño % y el crítico, el área % (manchas más grandes), la duración % (duran más) y
## la velocidad de ataque % (quema más a menudo). Son [member max_patches] como mucho: si hacen falta más, se
## reutiliza la más vieja. Va con [code]top_level[/code]: las manchas se quedan donde caen.

## Hurtbox que mira como mucho cada mancha en cada quemadura.
@export_range(1, 512, 1) var max_results: int = 64
## Stats del jugador (su [MovementSynergyData] y su [OffenseData]).
@export var stats: StatsComponent
## Quien deja el rastro (sus pies).
@export var body: Node3D
## Máquina del movimiento.
@export var machine: StateMachine
## Estado en el que deja rastro (el slide).
@export var trail_state: State
## Metros entre una mancha y la siguiente.
@export_range(0.1, 10.0, 0.05, "suffix:m") var spacing: float = 1.0
## Radio de cada mancha (sin agrandar por el área %).
@export_range(0.1, 10.0, 0.05, "suffix:m") var radius: float = 1.2
## Segundos que dura cada mancha (sin alargar por la duración %).
@export_range(0.1, 30.0, 0.1, "suffix:s") var lifetime: float = 3.0
## Segundos entre quemaduras con un 100 % de velocidad de ataque.
@export_range(0.05, 5.0, 0.05, "suffix:s") var burn_interval: float = 0.5
## Manchas a la vez como mucho.
@export_range(1, 256, 1) var max_patches: int = 32
## A quién quema (capas de hurtbox).
@export_flags_3d_physics var hit_mask: int = 0
## Lo que se ve de cada mancha: un plano de 2 × 2 (se escala a su radio) con
## [code]ground_fire.gdshader[/code], que se apaga con su parámetro [code]fade[/code].
@export var patch_mesh: Mesh
## Altura de las manchas sobre el suelo (para que no parpadeen con él).
@export_range(0.0, 0.5, 0.01, "suffix:m") var lift: float = 0.06

## Azar del crítico. Si no se asigna antes de entrar en el árbol, el flujo de combate de
## [code]Rng[/code].
var rng: RandomNumberGenerator

var _patches: Array[Patch] = []
## La siguiente mancha que se usa (la más vieja si están todas puestas).
var _next: int = 0
var _trailing: bool = false
var _last_drop: Vector3 = Vector3.ZERO
var _burn_left: float = 0.0
## Hurtbox ya quemadas en esta quemadura (por id de instancia).
var _burned: Dictionary[int, bool] = {}
var _sphere := SphereShape3D.new()
var _query := PhysicsShapeQueryParameters3D.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	if rng == null:
		rng = Rng.stream(Rng.Stream.COMBAT)
	_query.shape = _sphere
	_query.collide_with_areas = true
	_query.collide_with_bodies = false
	_query.collision_mask = hit_mask
	for index: int in max_patches:
		var patch := Patch.new()
		patch.mesh = MeshInstance3D.new()
		patch.mesh.mesh = patch_mesh
		patch.mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		patch.mesh.visible = false
		add_child(patch.mesh)
		_patches.append(patch)
	machine.state_changed.connect(_on_state_changed)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if _trailing and body.global_position.distance_to(_last_drop) >= spacing:
		_drop()
	var any_left := _age(delta)
	_burn_left -= delta
	if _burn_left <= 0.0:
		_burn_left += burn_interval / _attack_rate()
		_burn()
	if not _trailing and not any_left:
		set_physics_process(false)


## Manchas encendidas ahora mismo.
func active_patches() -> int:
	var count := 0
	for patch: Patch in _patches:
		if patch.active:
			count += 1
	return count


## ¿Está dejando rastro ahora (en el slide y con la mejora)?
func is_trailing() -> bool:
	return _trailing


func _on_state_changed(_previous: State, current: State) -> void:
	var trailing := current == trail_state and _damage() > 0.0
	if trailing and not _trailing:
		_trailing = true
		# Con manchas aún encendidas sigue el ritmo de quemaduras: encadenar slides no quema más.
		if not is_physics_processing():
			_burn_left = 0.0
		_drop()
		set_physics_process(true)
	elif not trailing:
		_trailing = false


func _damage() -> float:
	return stats.get_value(&"fire_trail_damage")


## La velocidad de ataque del jugador, en veces (1 = 100 %). Sin ella en sus datos, 1.
func _attack_rate() -> float:
	var offense := stats.find_resolved(OffenseData) as OffenseData
	return offense.attack_speed / 100.0 if offense and offense.attack_speed > 0.0 else 1.0


## Deja una mancha a los pies de [member body] (con el área % y la duración % de ahora).
func _drop() -> void:
	_last_drop = body.global_position
	var offense := stats.find_resolved(OffenseData) as OffenseData
	var patch := _patches[_next]
	_next = (_next + 1) % _patches.size()
	patch.active = true
	patch.radius = radius * (offense.area / 100.0 if offense else 1.0)
	patch.time_left = lifetime * (offense.duration / 100.0 if offense else 1.0)
	patch.lifetime = patch.time_left
	patch.mesh.global_position = _last_drop + Vector3.UP * lift
	patch.mesh.scale = Vector3(patch.radius, 1.0, patch.radius)
	patch.mesh.set_instance_shader_parameter(&"fade", 1.0)
	patch.mesh.visible = true


## Envejece las manchas y apaga las que se acaban. Devuelve si queda alguna.
func _age(delta: float) -> bool:
	var any_left := false
	for patch: Patch in _patches:
		if not patch.active:
			continue
		patch.time_left -= delta
		if patch.time_left <= 0.0:
			patch.active = false
			patch.mesh.visible = false
			continue
		var progress := 1.0 - patch.time_left / patch.lifetime
		patch.mesh.set_instance_shader_parameter(&"fade", 1.0 - progress * progress)
		any_left = true
	return any_left


## Quema una vez lo que pisa alguna mancha.
func _burn() -> void:
	var damage := _damage()
	if damage <= 0.0:
		return
	var offense := stats.find_resolved(OffenseData) as OffenseData
	var space := get_world_3d().direct_space_state
	_burned.clear()
	for patch: Patch in _patches:
		if not patch.active:
			continue
		_sphere.radius = patch.radius
		_query.transform = Transform3D(Basis.IDENTITY, patch.mesh.global_position)
		for result: Dictionary in space.intersect_shape(_query, max_results):
			var collider: Object = result["collider"]
			var hurtbox := collider as HurtboxComponent
			if hurtbox == null or _burned.has(hurtbox.get_instance_id()):
				continue
			_burned[hurtbox.get_instance_id()] = true
			hurtbox.receive(DamageCalc.attack(damage, offense, rng, patch.mesh))


## Una mancha de fuego.
class Patch:
	extends RefCounted

	var mesh: MeshInstance3D
	var active: bool = false
	var radius: float = 0.0
	var lifetime: float = 0.0
	var time_left: float = 0.0

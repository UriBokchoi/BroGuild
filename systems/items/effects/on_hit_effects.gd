class_name OnHitEffects
extends Node3D
## Los efectos al golpear de los objetos del jugador (veneno, rayo, frío). En cada golpe a un enemigo
## tira la probabilidad de cada uno según las copias que lleve. Lleva la cuenta de los venenos y los
## fríos activos y dibuja los rayos. El daño de un efecto no dispara más efectos.

## Los objetos del jugador.
@export var items: PassiveInventory
## Capas de las hurtbox a las que puede saltar un rayo.
@export_flags_3d_physics var chain_mask: int = 0
## Cómo se ven los rayos: grosor, color, cuánto tardan en apagarse y cuántos a la vez como mucho.
@export_range(0.01, 1.0, 0.01, "suffix:m") var bolt_width: float = 0.08
@export var bolt_color: Color = Color(0.55, 0.85, 1.0)
@export_range(0.02, 1.0, 0.01, "suffix:s") var bolt_time: float = 0.15
@export_range(1, 64, 1) var bolt_pool: int = 12

## Azar de las tiradas. Si no se asigna antes de entrar en el árbol, el flujo de combate de
## [code]Rng[/code].
var rng: RandomNumberGenerator

var _poisons: Dictionary[int, Poison] = {}
var _slows: Dictionary[int, Slow] = {}
var _bolts: Array[MeshInstance3D] = []
var _bolt_left: PackedFloat32Array = PackedFloat32Array()
var _next_bolt: int = 0
var _finder: TargetFinder


func _enter_tree() -> void:
	if not EventBus.enemy_hit.is_connected(_on_enemy_hit):
		EventBus.enemy_hit.connect(_on_enemy_hit)


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	if rng == null:
		rng = Rng.stream(Rng.Stream.COMBAT)
	_finder = TargetFinder.new(chain_mask)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = bolt_color
	var box := BoxMesh.new()
	box.size = Vector3(bolt_width, bolt_width, 1.0)
	box.material = material
	for index: int in bolt_pool:
		var bolt := MeshInstance3D.new()
		bolt.mesh = box
		bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bolt.visible = false
		add_child(bolt)
		_bolts.append(bolt)
	_bolt_left.resize(bolt_pool)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_tick_poisons(delta)
	_tick_slows(delta)
	var any_bolt := _age_bolts(delta)
	if _poisons.is_empty() and _slows.is_empty() and not any_bolt:
		set_physics_process(false)


## Envenena a [param target]: cada [param interval] segundos pierde [param damage] durante
## [param duration] segundos. Si ya lo estaba, alarga el veneno y se queda con el daño más alto.
func poison(target: Node3D, health: HealthComponent, damage: float, interval: float, duration: float, kind: StringName) -> void:
	var id := health.get_instance_id()
	var state: Poison = _poisons.get(id)
	if state == null:
		state = Poison.new()
		state.health = health
		state.next_tick = interval
		_poisons[id] = state
	state.target = target
	state.damage = maxf(state.damage, damage)
	state.interval = interval
	# Se cuenta en ticks, no en segundos: así el último no se pierde por redondeo.
	state.ticks_left = maxi(state.ticks_left, PoisonOnHit.ticks_in(duration, interval))
	state.kind = kind
	set_physics_process(true)


## Un rayo desde [param from] (con su vida, [param health]): salta a los [param jumps] enemigos más cercanos (cada uno a menos de
## [param reach] metros del anterior) y les quita [param damage].
func chain(from: Node3D, health: HealthComponent, damage: float, jumps: int, reach: float, kind: StringName) -> void:
	var space := get_world_3d().direct_space_state
	var origin := TargetFinder.aim_point(from)
	var hit_healths: Array[HealthComponent] = [health]
	for _jump: int in jumps:
		var next := _nearest_unhit(space, origin, reach, hit_healths)
		if next == null:
			return
		var to := next.get_center()
		_draw_bolt(origin, to)
		hit_healths.append(next.health)
		var info := DamageInfo.create(damage, false, self)
		info.kind = kind
		info.triggers_effects = false
		next.receive(info)
		origin = to


## Frena a [param target] (si es un enemigo) a [param factor] de su velocidad durante
## [param duration] segundos. Si ya iba frenado, alarga el frío.
func slow(target: Node3D, factor: float, duration: float) -> void:
	var enemy := target as Enemy
	if enemy == null or not enemy.is_alive():
		return
	var id := enemy.get_instance_id()
	var state: Slow = _slows.get(id)
	if state == null:
		state = Slow.new()
		state.enemy = enemy
		state.token = RefCounted.new()
		enemy.stats.add_modifier(StatModifier.create(&"move_speed", StatModifier.Kind.MULTIPLIER, factor), state.token)
		_slows[id] = state
	state.left = maxf(state.left, duration)
	set_physics_process(true)


## ¿Está envenenado (por estos efectos) el dueño de [param health]?
func is_poisoned(health: HealthComponent) -> bool:
	return _poisons.has(health.get_instance_id())


## ¿Va frenado [param enemy]?
func is_slowed(enemy: Enemy) -> bool:
	return _slows.has(enemy.get_instance_id())


func _on_enemy_hit(target: Node3D, health: HealthComponent, info: DamageInfo, amount: float) -> void:
	if not info.triggers_effects or amount <= 0.0 or not is_instance_valid(items):
		return
	var effects := items.on_hit_effects()
	for effect: OnHitEffect in effects:
		var chance := effect.chance * effects[effect]
		if rng.randf() * 100.0 < chance:
			effect.apply(self, target, health, info)


func _tick_poisons(delta: float) -> void:
	for id: int in _poisons.keys():
		var state := _poisons[id]
		if not is_instance_valid(state.health) or state.health.is_dead():
			_poisons.erase(id)
			continue
		state.next_tick -= delta
		if state.next_tick > 0.0:
			continue
		state.next_tick += state.interval
		state.ticks_left -= 1
		var info := DamageInfo.create(state.damage, false, self)
		info.kind = state.kind
		info.triggers_effects = false
		state.health.take_damage(info)
		if state.ticks_left <= 0:
			_poisons.erase(id)


func _tick_slows(delta: float) -> void:
	for id: int in _slows.keys():
		var state := _slows[id]
		state.left -= delta
		var gone := not is_instance_valid(state.enemy) or not state.enemy.is_alive()
		if state.left <= 0.0 or gone:
			if is_instance_valid(state.enemy):
				state.enemy.stats.remove_modifiers_from(state.token)
			_slows.erase(id)


func _nearest_unhit(space: PhysicsDirectSpaceState3D, origin: Vector3, reach: float, hit_healths: Array[HealthComponent]) -> HurtboxComponent:
	for found: Node3D in _finder.nearest(space, origin, reach, hit_healths.size() + 8):
		var hurtbox := found as HurtboxComponent
		if hurtbox and not hit_healths.has(hurtbox.health) and not hurtbox.health.is_dead():
			return hurtbox
	return null


func _draw_bolt(from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	if length < 0.01:
		return
	var bolt := _bolts[_next_bolt]
	_bolt_left[_next_bolt] = bolt_time
	_next_bolt = (_next_bolt + 1) % _bolts.size()
	var middle := (from + to) / 2.0
	var up := Vector3.UP if absf((to - from).normalized().dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	bolt.global_transform = Transform3D(Basis.looking_at(to - from, up).scaled(Vector3(1.0, 1.0, length)), middle)
	bolt.transparency = 0.0
	bolt.visible = true
	set_physics_process(true)


func _age_bolts(delta: float) -> bool:
	var any := false
	for index: int in _bolts.size():
		if not _bolts[index].visible:
			continue
		_bolt_left[index] -= delta
		if _bolt_left[index] <= 0.0:
			_bolts[index].visible = false
			continue
		_bolts[index].transparency = 1.0 - _bolt_left[index] / bolt_time
		any = true
	return any


## Un veneno activo.
class Poison:
	extends RefCounted

	var health: HealthComponent
	var target: Node3D
	var damage: float = 0.0
	var interval: float = 0.5
	var ticks_left: int = 0
	var next_tick: float = 0.0
	var kind: StringName = &""


## Un frío activo: el modificador de velocidad que puso (por su origen, [member token]).
class Slow:
	extends RefCounted

	var enemy: Enemy
	var token: RefCounted
	var left: float = 0.0

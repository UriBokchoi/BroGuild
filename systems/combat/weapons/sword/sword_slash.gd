class_name SwordSlash
extends Node3D
## Un tajo de la espada: un arco que barre hacia delante (−Z) y una hitbox que golpea una vez a
## cada enemigo mientras dura. Se dibuja y colisiona con alcance 1 m; [method swing] lo escala al
## alcance del arma. Se reutiliza (pool): al acabar se oculta y avisa con [signal finished].

signal finished

## Zona que golpea.
@export var hitbox: HitboxComponent
## Malla del arco (con el shader [code]sword_slash.gdshader[/code]).
@export var visual: GeometryInstance3D
## Inclinación del arco dibujado (baja hacia el lado al que barre); solo visual.
@export_range(0.0, 45.0, 1.0, "suffix:°") var tilt: float = 12.0

var _duration: float = 0.0
var _elapsed: float = 0.0


func _ready() -> void:
	_stop()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		_stop()
		finished.emit()


func _process(_delta: float) -> void:
	# El dibujo va por frames, con la fracción del tick, para que el barrido sea fluido a cualquier
	# tasa de refresco.
	var tick := 1.0 / Engine.physics_ticks_per_second
	var time := _elapsed + Engine.get_physics_interpolation_fraction() * tick
	visual.set_instance_shader_parameter(&"progress", clampf(time / _duration, 0.0, 1.0))


## Lanza el tajo hacia [param direction] (normalizada; puede ir inclinada hacia arriba o abajo, pero
## no vertical) con [param reach] metros de alcance. [param attacker] son las stats de quien golpea
## (daño %, crítico y empuje %); [param mirrored] barre al revés y [param knockback] es el empuje de
## cada golpe.
func swing(
	direction: Vector3,
	reach: float,
	duration: float,
	damage: float,
	attacker: StatsComponent,
	mirrored: bool,
	knockback: float = 0.0,
) -> void:
	global_basis = Basis.looking_at(direction, Vector3.UP).scaled(Vector3.ONE * reach)
	reset_physics_interpolation()
	hitbox.base_damage = damage
	hitbox.knockback = knockback
	hitbox.attacker_stats = attacker
	hitbox.reset_hits()
	hitbox.monitoring = true
	var side := -1.0 if mirrored else 1.0
	visual.set_instance_shader_parameter(&"direction", side)
	# Girar en Z sube el lado +X: el barrido empieza arriba y acaba abajo.
	visual.rotation.z = deg_to_rad(tilt) * -side
	visual.set_instance_shader_parameter(&"progress", 0.0)
	_duration = maxf(duration, 0.01)
	_elapsed = 0.0
	visible = true
	set_physics_process(true)
	set_process(true)


## ¿Está a mitad de un tajo?
func is_swinging() -> bool:
	return visible


func _stop() -> void:
	hitbox.monitoring = false
	visible = false
	set_physics_process(false)
	set_process(false)

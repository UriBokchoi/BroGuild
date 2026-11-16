class_name HitboxComponent
extends Area3D
## Zona que hace daño a las [HurtboxComponent] que toca; su máscara de física dice a quién
## ([code]enemy_hurtbox[/code] para el jugador y sus armas, [code]player_hurtbox[/code] para enemigos
## y trampas). Con [member rehit_interval] > 0 repite el golpe a cada objetivo mientras lo toque
## (daño por contacto); con 0, golpea una sola vez a cada uno (un proyectil, un tajo). Solo golpea
## con [member Area3D.monitoring] activado: un ataque la activa mientras dura.

## Golpeó a [param hurtbox]; [param amount] es la vida que quitó de verdad.
signal hit(hurtbox: HurtboxComponent, amount: float)

## Daño de cada golpe antes de las stats del atacante.
@export_range(0.0, 1000.0, 0.5, "or_greater") var base_damage: float = 0.0
## Segundos entre golpes al mismo objetivo mientras lo toca; 0 = una sola vez por objetivo.
@export_range(0.0, 10.0, 0.05, "or_greater", "suffix:s") var rehit_interval: float = 0.0
## Stats de quien golpea, para su daño % y su crítico. Vacío: el daño va tal cual.
@export var attacker_stats: StatsComponent

## Azar del crítico. Si no se asigna antes de entrar en el árbol, el flujo de combate de [code]Rng[/code].
var rng: RandomNumberGenerator

## Último golpe a cada objetivo (por id de instancia, para no retener nodos ya liberados), en
## segundos de física (ver [method _now]).
var _last_hit_at: Dictionary[int, float] = {}
## Hurtbox que toca ahora, según las señales de entrada y salida. Solo se procesa mientras toca
## alguna: cientos de enemigos llevan una hitbox de contacto que casi nunca toca nada.
var _touching: Array[HurtboxComponent] = []


func _ready() -> void:
	monitorable = false
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	set_physics_process(false)
	if rng == null:
		rng = Rng.stream(Rng.Stream.COMBAT)


func _physics_process(_delta: float) -> void:
	if not monitoring:
		_touching.clear()
		set_physics_process(false)
		return
	for hurtbox: HurtboxComponent in _touching:
		if _can_hit(hurtbox):
			_hit(hurtbox)


## Olvida a quién ha golpeado: el siguiente ataque vuelve a poder dar a todos.
func reset_hits() -> void:
	_last_hit_at.clear()


func _can_hit(hurtbox: HurtboxComponent) -> bool:
	var id := hurtbox.get_instance_id()
	if not _last_hit_at.has(id):
		return true
	return rehit_interval > 0.0 and _now() - _last_hit_at[id] >= rehit_interval


func _on_area_entered(area: Area3D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox and not _touching.has(hurtbox):
		_touching.append(hurtbox)
		set_physics_process(true)


func _on_area_exited(area: Area3D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox:
		_touching.erase(hurtbox)
		set_physics_process(not _touching.is_empty())


## Segundos de física desde que arrancó el juego: el reloj de los golpes repetidos, que no depende de
## si esta hitbox se procesa o no.
static func _now() -> float:
	return float(Engine.get_physics_frames()) / Engine.physics_ticks_per_second


func _hit(hurtbox: HurtboxComponent) -> void:
	_last_hit_at[hurtbox.get_instance_id()] = _now()
	var offense: OffenseData = null
	if attacker_stats:
		offense = attacker_stats.get_resolved(OffenseData) as OffenseData
	var amount := hurtbox.receive(DamageCalc.attack(base_damage, offense, rng, self))
	hit.emit(hurtbox, amount)

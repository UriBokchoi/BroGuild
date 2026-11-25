class_name PowerUpFx
extends Node3D
## Lo que se ve al coger un power-up (la bomba, el imán, la comida, la bebida energética, el reloj de
## arena): escucha [signal EventBus.pickup_collected] y, si esa recompensa tiene efecto en
## [member effects], lo lanza en el suelo bajo [member anchor] (el jugador), con su temblor de cámara y
## su destello. Solo visual: lo que hace el power-up va en su [PickupEffect].

## Dónde se lanzan (el jugador).
@export var anchor: Node3D
## Efecto de cada recompensa: una escena con raíz [FxBurst].
@export var effects: Dictionary[StringName, PackedScene] = {}
## Temblor de cámara del jugador (para los efectos que lo piden).
@export var shake: ScreenShake
## Destello de pantalla completa.
@export var flash: ColorRect
## Qué cuenta como suelo y cuánto mira hacia abajo (si coges el power-up en el aire, el efecto sale
## en el suelo).
@export_flags_3d_physics var ground_mask: int = 1
@export_range(0.5, 50.0, 0.5, "suffix:m") var ground_probe: float = 10.0

var _bursts: Dictionary[StringName, FxBurst] = {}
var _flash_tween: Tween


func _enter_tree() -> void:
	if not EventBus.pickup_collected.is_connected(_on_pickup_collected):
		EventBus.pickup_collected.connect(_on_pickup_collected)


func _ready() -> void:
	flash.visible = false
	# Se crean al cargar, no en el primer power-up: así ese momento no da un tirón.
	for reward: StringName in effects:
		var burst := effects[reward].instantiate() as FxBurst
		burst.top_level = true
		add_child(burst)
		_bursts[reward] = burst


## El efecto de [param reward] (o [code]null[/code] si no tiene).
func get_burst(reward: StringName) -> FxBurst:
	return _bursts.get(reward)


func _on_pickup_collected(reward: StringName, _amount: float) -> void:
	var burst := get_burst(reward)
	if burst == null or not is_instance_valid(anchor):
		return
	burst.global_position = _ground_below(anchor.global_position)
	burst.play()
	if burst.trauma > 0.0 and is_instance_valid(shake):
		shake.add_trauma(burst.trauma)
	if burst.flash.a > 0.0:
		_flash(burst.flash, burst.flash_time)


func _flash(color: Color, seconds: float) -> void:
	if _flash_tween:
		_flash_tween.kill()
	flash.color = color
	flash.visible = true
	_flash_tween = create_tween()
	_flash_tween.tween_property(flash, ^"color:a", 0.0, seconds).set_ease(Tween.EASE_IN)
	_flash_tween.tween_callback(flash.hide)


func _ground_below(at: Vector3) -> Vector3:
	var from := at + Vector3.UP * 0.5
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * ground_probe, ground_mask)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return at
	var ground: Vector3 = hit["position"]
	return ground

extends GutTest
## Números de daño: cada golpe a un enemigo (EventBus.enemy_damaged) saca un número del pool con el
## daño redondeado, blanco o del color de crítico y más grande; al acabar se oculta y se reutiliza.

const STYLE := preload("res://data/vfx/damage_numbers.tres")

var _numbers: DamageNumbers


func before_each() -> void:
	_numbers = DamageNumbers.new()
	_numbers.style = STYLE
	_numbers.prewarm = 2
	_numbers.max_numbers = 3
	add_child_autofree(_numbers)


func test_a_hit_shows_its_damage_in_white() -> void:
	EventBus.enemy_damaged.emit(Vector3(1.0, 2.0, 3.0), 12.4, DamageInfo.create(12.4))
	var number := _showing()[0]
	assert_eq(number.text, "12")
	assert_eq(Color(number.modulate, 1.0), STYLE.normal_color)
	assert_almost_eq(number.global_position.distance_to(Vector3(1.0, 2.0, 3.0)), 0.0, STYLE.spawn_jitter * 2.0)


func test_critical_hits_are_coloured_and_bigger() -> void:
	EventBus.enemy_damaged.emit(Vector3.ZERO, 10.0, DamageInfo.create(10.0))
	EventBus.enemy_damaged.emit(Vector3.ZERO, 30.0, DamageInfo.create(30.0, true))
	var normal := _with_text("10")
	var critical := _with_text("30")
	assert_eq(Color(critical.modulate, 1.0), STYLE.critical_color)
	assert_almost_eq(critical.scale.x / normal.scale.x, STYLE.critical_scale, 0.01)


func test_numbers_jump_then_vanish_and_are_reused() -> void:
	EventBus.enemy_damaged.emit(Vector3.ZERO, 5.0, DamageInfo.create(5.0))
	var number := _showing()[0]
	var start := number.global_position.y
	_advance(number, STYLE.lifetime * 0.2)
	assert_gt(number.global_position.y, start, "sube al salir")
	_advance(number, STYLE.lifetime)
	assert_false(number.is_showing(), "desaparece")
	EventBus.enemy_damaged.emit(Vector3.ZERO, 5.0, DamageInfo.create(5.0))
	assert_eq(_numbers.get_child_count(), 2, "sin crear nodos nuevos")


func test_too_many_numbers_are_skipped() -> void:
	for _hit: int in 5:
		EventBus.enemy_damaged.emit(Vector3.ZERO, 5.0, DamageInfo.create(5.0))
	assert_eq(_numbers.active_count(), 3)


func _showing() -> Array[DamageNumber]:
	var shown: Array[DamageNumber] = []
	for child: Node in _numbers.get_children():
		var number := child as DamageNumber
		if number and number.is_showing():
			shown.append(number)
	return shown


func _with_text(text: String) -> DamageNumber:
	for number: DamageNumber in _showing():
		if number.text == text:
			return number
	return null


func _advance(number: DamageNumber, seconds: float) -> void:
	var step := 1.0 / 60.0
	for _frame: int in ceili(seconds / step):
		if number.is_showing():
			number._process(step)

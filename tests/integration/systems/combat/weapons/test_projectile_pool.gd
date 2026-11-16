extends GutTest
## ProjectilePool: reparte proyectiles por escena, respeta su máximo en vuelo, recupera los que
## terminan y los retira todos con clear.

const BoltScene := preload("res://entities/enemies/shooter/shooter_bolt.tscn")

var _pool: ProjectilePool


func before_each() -> void:
	_pool = ProjectilePool.new()
	_pool.limit = 2
	add_child_autofree(_pool)


func test_respects_its_limit_in_flight() -> void:
	assert_not_null(_pool.acquire(BoltScene))
	assert_not_null(_pool.acquire(BoltScene))
	assert_null(_pool.acquire(BoltScene), "con el máximo, no sale")
	assert_eq(_pool.flying_count(), 2)


func test_finished_projectiles_free_their_slot_and_are_reused() -> void:
	var first := _pool.acquire(BoltScene)
	_pool.acquire(BoltScene)
	first.recall()
	assert_eq(_pool.flying_count(), 1)
	assert_same(_pool.acquire(BoltScene), first, "reutiliza el que terminó")


func test_clear_recalls_everything() -> void:
	_pool.acquire(BoltScene)
	_pool.acquire(BoltScene)
	_pool.clear()
	assert_eq(_pool.flying_count(), 0)

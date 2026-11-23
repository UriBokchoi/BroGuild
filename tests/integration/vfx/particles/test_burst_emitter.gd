extends GutTest
## Estallidos de partículas: el humo sale al morir un enemigo, a su altura y de su color; las chispas,
## al golpear, donde se golpea; como mucho tantos por fotograma, y la reserva se reutiliza. La onda
## de suelo levanta su polvo al salir (la del dash, no) y el cofre suelta destellos al abrirse.

const DEATH_PUFF := preload("res://vfx/particles/death_puff.tscn")
const HIT_SPARKS := preload("res://vfx/particles/hit_sparks.tscn")
const SWARMER := preload("res://data/enemies/swarmer.tres")
const ShockwaveScene := preload("res://entities/enemies/boss/shockwave/shockwave.tscn")
const DashWaveScene := preload("res://entities/player/synergy/dash_wave.tscn")


func test_a_dying_enemy_puffs_in_its_color() -> void:
	var puffs := _emitter(BurstEmitter.Trigger.ENEMY_DIED, DEATH_PUFF, 4, 4)
	puffs.offset = Vector3(0.0, 0.7, 0.0)
	puffs.tint_by_enemy = true
	add_child_autofree(puffs)
	var swarm := EnemySwarm.new()
	add_child_autofree(swarm)
	var enemy := swarm.spawn(SWARMER, Vector3(3.0, 0.0, 1.0))
	enemy.health.take_damage(DamageInfo.create(1.0e6))
	var emitting := _emitting(puffs)
	assert_eq(emitting.size(), 1)
	var puff := emitting[0]
	assert_eq(puff.global_position, Vector3(3.0, 0.7, 1.0), "a media altura del enemigo")
	assert_eq((puff.process_material as ParticleProcessMaterial).color, SWARMER.color, "de su color")


func test_hits_spark_where_they_land() -> void:
	var sparks := _emitter(BurstEmitter.Trigger.ENEMY_HIT, HIT_SPARKS, 4, 4)
	add_child_autofree(sparks)
	EventBus.enemy_damaged.emit(Vector3(1.0, 2.0, 3.0), 10.0, DamageInfo.create(10.0))
	var emitting := _emitting(sparks)
	assert_eq(emitting.size(), 1)
	assert_eq(emitting[0].global_position, Vector3(1.0, 2.0, 3.0))


func test_no_more_than_its_limit_per_frame_and_the_pool_is_reused() -> void:
	var sparks := _emitter(BurstEmitter.Trigger.ENEMY_HIT, HIT_SPARKS, 3, 2)
	add_child_autofree(sparks)
	assert_not_null(sparks.burst(Vector3.ZERO))
	assert_not_null(sparks.burst(Vector3.ZERO))
	assert_null(sparks.burst(Vector3.ZERO), "tope de este fotograma")
	await wait_process_frames(1)
	var third := sparks.burst(Vector3.ZERO)
	await wait_process_frames(1)
	var fourth := sparks.burst(Vector3.ZERO)
	assert_not_null(third)
	assert_same(fourth, sparks.get_child(0), "con la reserva llena, vuelve a la primera")


func test_a_ground_wave_raises_dust_but_the_dash_wave_does_not_show_it() -> void:
	var wave := ShockwaveScene.instantiate() as Shockwave
	add_child_autofree(wave)
	var dust := wave.get_node(^"Dust") as GPUParticles3D
	assert_false(dust.emitting)
	wave.start(Vector3.ZERO, 1.0)
	assert_true(dust.emitting, "levanta polvo al salir")
	var dash := DashWaveScene.instantiate() as Shockwave
	add_child_autofree(dash)
	assert_false((dash.get_node(^"Dust") as GPUParticles3D).visible, "el dash, sin polvo")


func _emitter(trigger: BurstEmitter.Trigger, effect: PackedScene, pool_size: int, max_per_frame: int) -> BurstEmitter:
	var emitter := BurstEmitter.new()
	emitter.trigger = trigger
	emitter.effect = effect
	emitter.pool_size = pool_size
	emitter.max_per_frame = max_per_frame
	return emitter


func _emitting(emitter: BurstEmitter) -> Array[GPUParticles3D]:
	var found: Array[GPUParticles3D] = []
	for child: Node in emitter.get_children():
		var particles := child as GPUParticles3D
		if particles and particles.emitting:
			found.append(particles)
	return found

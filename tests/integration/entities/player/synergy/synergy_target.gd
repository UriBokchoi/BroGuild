extends RefCounted
## Ayudas de los tests de las sinergias de movimiento: las stats de un jugador con su
## [MovementSynergyData] y sus stats de ataque, y hurtbox de enemigo con 100 de vida.

const RULES := preload("res://data/combat/rules.tres")


## Stats con [param synergy] y unas stats de ataque neutras (100 % de daño, sin crítico) con
## [param area] % de área.
static func stats(test: GutTest, synergy: MovementSynergyData, area: float = 100.0) -> StatsComponent:
	var offense := OffenseData.new()
	offense.damage = 100.0
	offense.crit_chance = 0.0
	offense.crit_damage = 150.0
	offense.area = area
	offense.duration = 100.0
	offense.knockback = 100.0
	var component := StatsComponent.new()
	component.sources.append(synergy)
	component.sources.append(offense)
	test.add_child_autofree(component)
	return component


## Una hurtbox de enemigo (capa [code]enemy_hurtbox[/code]) con 100 de vida y los pies en
## [param at].
static func enemy(test: GutTest, at: Vector3) -> HealthComponent:
	var stats_component := StatsComponent.new()
	var data := HealthData.new()
	data.max_health = 100.0
	stats_component.sources.append(data)
	test.add_child_autofree(stats_component)
	var health := HealthComponent.new()
	health.stats = stats_component
	health.rules = RULES
	test.add_child_autofree(health)
	var hurtbox := HurtboxComponent.new()
	hurtbox.collision_layer = PhysicsLayers.mask(PhysicsLayers.ENEMY_HURTBOX)
	hurtbox.collision_mask = 0
	hurtbox.health = health
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.9, 0.0)
	hurtbox.add_child(shape)
	test.add_child_autofree(hurtbox)
	hurtbox.global_position = at
	return health

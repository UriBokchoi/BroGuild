extends RefCounted
## Para los tests de datos: ¿es una stat del enemigo o de sus armas? Cada una va en su propio
## componente, así que pueden repetir nombre (como el empuje): se mira cada fuente por separado.


static func has(stat: StringName) -> bool:
	for source: Resource in [HealthData.new(), EnemyStats.new(), ProjectileStats.new()]:
		var block := StatBlock.new()
		block.define_from_resource(source)
		if block.has_stat(stat):
			return true
	return false

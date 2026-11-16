class_name ExperienceData
extends Resource
## Experiencia necesaria para cada nivel (GDD §6, «Subir de nivel»). Los valores viven en
## [code]data/progression/experience.tres[/code]; aquí todo vale 0 o vacío a propósito.

## Experiencia para pasar del nivel x al siguiente.
@export var xp_to_next: Curve
## Nivel máximo.
@export_range(1, 1000, 1, "or_greater") var max_level: int = 0


## Experiencia para pasar de [param level] al siguiente (al menos 1).
func needed_for(level: int) -> float:
	if xp_to_next == null:
		return 1.0
	return maxf(xp_to_next.sample(level), 1.0)

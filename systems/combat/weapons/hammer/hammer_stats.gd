class_name HammerStats
extends WeaponStats
## Stats del martillo de guerra: las de toda arma más el radio de su golpe (que también crece con el
## área). Los valores viven en [code]data/weapons/hammer.tres[/code].

@export_group("hammer")
## Radio del golpe al caer (antes del área).
@export_range(0.5, 20.0, 0.1, "or_greater", "suffix:m") var impact_radius: float = 0.0

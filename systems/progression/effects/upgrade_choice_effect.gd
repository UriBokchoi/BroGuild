class_name UpgradeChoiceEffect
extends PickupEffect
## Mejora gratis a elegir (la pareja de estrellas de la tragaperras): pide al jugador tantas
## elecciones como vale el premio, como al subir de nivel ([signal EventBus.upgrade_choice_requested],
## las ofrece el [LevelUpController]).


func apply(amount: float) -> void:
	EventBus.upgrade_choice_requested.emit(maxi(roundi(amount), 1))

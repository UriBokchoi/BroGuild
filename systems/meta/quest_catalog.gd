class_name QuestCatalog
extends Resource
## Las misiones, en el orden en que salen en la pestaña «Misiones». Dice qué está bloqueado para un
## perfil (lo que da una misión aún sin cumplir) y qué misiones cumple una partida. Los valores viven
## en data/meta/quests.tres.

@export var quests: Array[QuestData] = []


## ¿Está bloqueado [param content] para [param profile]? (Lo da una misión que aún no ha cumplido.)
func is_locked(content: Resource, profile: PlayerProfile) -> bool:
	var quest := quest_for(content)
	return quest != null and not profile.has_completed(quest.id)


## La misión que desbloquea [param content] (o [code]null[/code]).
func quest_for(content: Resource) -> QuestData:
	for quest: QuestData in quests:
		if quest.unlocks(content):
			return quest
	return null


## Lo que sigue bloqueado para [param profile].
func locked_content(profile: PlayerProfile) -> Array[Resource]:
	var locked: Array[Resource] = []
	for quest: QuestData in quests:
		if not profile.has_completed(quest.id):
			for reward: Resource in quest.rewards:
				if reward:
					locked.append(reward)
	return locked


## Las misiones que [param record] cumple y [param profile] aún no tenía.
func newly_met(record: RunRecord, profile: PlayerProfile) -> Array[QuestData]:
	var met: Array[QuestData] = []
	for quest: QuestData in quests:
		if not profile.has_completed(quest.id) and quest.is_met_by(record):
			met.append(quest)
	return met

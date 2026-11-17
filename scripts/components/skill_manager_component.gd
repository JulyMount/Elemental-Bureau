class_name SkillManagerComponent
extends Node

signal skill_triggered(slot_name: String)
signal cooldown_updated(slot_name: String, time_left: float, max_cooldown: float)

@export var cooldowns: Dictionary = {
	"skill_1": 3.0,
	"skill_2": 5.0,
	"ultimate": 12.0
}

var _timers: Dictionary = {
	"skill_1": 0.0,
	"skill_2": 0.0,
	"ultimate": 0.0
}

func _process(delta: float) -> void:
	for slot in _timers.keys():
		if _timers[slot] > 0.0:
			_timers[slot] = max(0.0, _timers[slot] - delta)
			cooldown_updated.emit(slot, _timers[slot], cooldowns[slot])

func can_use_skill(slot_name: String) -> bool:
	return _timers.get(slot_name, 0.0) <= 0.0

func trigger_skill(slot_name: String) -> bool:
	if not can_use_skill(slot_name):
		return false
	
	_timers[slot_name] = cooldowns.get(slot_name, 1.0)
	skill_triggered.emit(slot_name)
	return true

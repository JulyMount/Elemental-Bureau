class_name ElementData
extends Resource

enum ElementType { FIRE, EARTH }

@export_group("Identidade")
@export var element_name: String = "Fogo"
@export var element_type: ElementType = ElementType.FIRE
@export var primary_color: Color = Color(1.0, 0.35, 0.05)

@export_group("Atributos de Combate")
@export var basic_attack_damage: float = 20.0
@export var skill_1_damage: float = 45.0
@export var skill_2_damage: float = 60.0
@export var ultimate_duration: float = 6.0

@export_group("Cooldowns")
@export var skill_1_cooldown: float = 3.0
@export var skill_2_cooldown: float = 5.0
@export var ultimate_cooldown: float = 14.0

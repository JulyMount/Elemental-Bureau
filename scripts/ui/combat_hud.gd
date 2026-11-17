class_name CombatHUD
extends CanvasLayer

@export var player_path: NodePath

var _player: Player
var _health_bar: ProgressBar
var _health_label: Label

var _element_badge: PanelContainer
var _element_label: Label
var _resource_title: Label
var _heat_bar: ProgressBar
var _heat_value_label: Label
var _pillar_pips: Array[ColorRect] = []
var _pillar_box: HBoxContainer

var _slot_panels: Dictionary = {}
var _slot_overlays: Dictionary = {}
var _slot_cd_labels: Dictionary = {}
var _slot_status_labels: Dictionary = {}

var _active_color: Color = Color(1.0, 0.35, 0.05)
var _current_element_type: int = ElementData.ElementType.FIRE
var _can_use_s2: bool = false

func _ready() -> void:
	layer = 50
	_build_ui()
	
	# Aguarda 2 frames para garantir que Player e HealthComponent já rodaram _ready()
	await get_tree().process_frame
	await get_tree().process_frame
	
	if not player_path.is_empty():
		_player = get_node_or_null(player_path) as Player
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Player
	
	if _player:
		_bind_player(_player)

func _bind_player(p: Player) -> void:
	if p.health_component:
		p.health_component.health_changed.connect(_on_health_changed)
		var cur_hp: float = p.health_component.current_health if p.health_component.current_health > 0.0 else p.health_component.max_health
		_on_health_changed(cur_hp, p.health_component.max_health)
	
	if p.skill_manager:
		p.skill_manager.cooldown_updated.connect(_on_cooldown_updated)
		p.skill_manager.skill_triggered.connect(_on_skill_triggered)
	
	if p.elemental:
		p.elemental.element_switched.connect(_on_element_switched)
		p.elemental.thermal_pressure_changed.connect(_on_thermal_changed)
		p.elemental.earth_pillars_changed.connect(_on_pillars_changed)
		p.elemental.ultimate_state_changed.connect(_on_ultimate_changed)
		
		if p.elemental.current_element:
			_on_element_switched(p.elemental.current_element)
		_on_thermal_changed(p.elemental.thermal_pressure, p.elemental.MAX_THERMAL_PRESSURE, p.elemental.is_overheated)
		_on_pillars_changed(0, p.elemental.MAX_ACTIVE_PILLARS)

func _process(_delta: float) -> void:
	if not _player:
		return
	
	# Atualiza o slot do Dash em tempo real
	var dash_cd: float = maxf(0.0, _player._dash_cooldown_timer)
	_update_slot_visual("dash", dash_cd, _player.DASH_COOLDOWN, true)
	
	# Atualiza disponibilidade condicional da Skill 2
	if _player.elemental and _player.skill_manager:
		var cd_left: float = _player.skill_manager._timers.get("skill_2", 0.0)
		var max_cd: float = _player.skill_manager.cooldowns.get("skill_2", 5.0)
		_can_use_s2 = _player.elemental.can_cast_skill_2()
		_update_slot_visual("skill_2", cd_left, max_cd, _can_use_s2)

# ==========================================
# CALLBACKS DE SINAIS
# ==========================================

func _on_health_changed(current_hp: float, max_hp: float) -> void:
	_health_bar.max_value = max_hp
	_health_bar.value = current_hp
	_health_label.text = "%d / %d" % [ceili(current_hp), int(max_hp)]

func _on_element_switched(el: ElementData) -> void:
	_active_color = el.primary_color
	_current_element_type = el.element_type
	
	var switch_key: String = _get_action_key_hint("switch_element")
	if switch_key.is_empty():
		_element_label.text = "ELEMENTO: %s" % el.element_name.to_upper()
	else:
		_element_label.text = "ELEMENTO: %s  [%s]" % [el.element_name.to_upper(), switch_key]
	
	var style := _element_badge.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.border_color = _active_color
		style.bg_color = _active_color.darkened(0.78)
	
	var is_fire: bool = (el.element_type == ElementData.ElementType.FIRE)
	_heat_bar.visible = is_fire
	_heat_value_label.visible = is_fire
	_pillar_box.visible = not is_fire
	
	if is_fire:
		_resource_title.text = "PRESSÃO TÉRMICA"
		_slot_status_labels["skill_1"].text = "Bola Fogo"
		_slot_status_labels["skill_2"].text = "Onda Calor"
		_slot_status_labels["ultimate"].text = "Chama Viva"
	else:
		_resource_title.text = "PILARES DE ROCHA"
		_slot_status_labels["skill_1"].text = "Erguer Pilar"
		_slot_status_labels["skill_2"].text = "Estilhaçar"
		_slot_status_labels["ultimate"].text = "Colosso V4"

func _on_thermal_changed(current_heat: float, max_heat: float, is_overheated: bool) -> void:
	_heat_bar.max_value = max_heat
	_heat_bar.value = current_heat
	
	var fill := _heat_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if is_overheated:
		_heat_value_label.text = "SUPERAQUECIDO!"
		_heat_value_label.modulate = Color(1.0, 0.25, 0.2)
		if fill:
			fill.bg_color = Color(1.0, 0.18, 0.12)
	else:
		_heat_value_label.text = "%d%%" % int(current_heat)
		_heat_value_label.modulate = Color.WHITE
		if fill:
			fill.bg_color = Color(1.0, 0.45, 0.08).lerp(Color(1.0, 0.85, 0.2), current_heat / max_heat)

func _on_pillars_changed(active_count: int, max_count: int) -> void:
	for i in range(_pillar_pips.size()):
		if i < active_count:
			_pillar_pips[i].color = Color(0.88, 0.60, 0.26)
		elif i < max_count:
			_pillar_pips[i].color = Color(0.18, 0.16, 0.15, 0.85)

func _on_ultimate_changed(is_active: bool) -> void:
	var panel := _slot_panels.get("ultimate") as PanelContainer
	if panel:
		var sb := panel.get_theme_stylebox("panel") as StyleBoxFlat
		if sb:
			sb.border_color = Color(1.0, 0.9, 0.3) if is_active else Color(0.45, 0.45, 0.5)

func _on_skill_triggered(slot_name: String) -> void:
	if _player and _player.skill_manager:
		var max_cd: float = _player.skill_manager.cooldowns.get(slot_name, 1.0)
		_update_slot_visual(slot_name, max_cd, max_cd, true)

func _on_cooldown_updated(slot_name: String, time_left: float, max_cd: float) -> void:
	var condition_ok: bool = _can_use_s2 if slot_name == "skill_2" else true
	_update_slot_visual(slot_name, time_left, max_cd, condition_ok)

func _update_slot_visual(slot_name: String, time_left: float, max_cd: float, condition_met: bool) -> void:
	if not _slot_panels.has(slot_name):
		return
	
	var panel := _slot_panels[slot_name] as PanelContainer
	var overlay := _slot_overlays[slot_name] as ColorRect
	var cd_label := _slot_cd_labels[slot_name] as Label
	var sb := panel.get_theme_stylebox("panel") as StyleBoxFlat
	
	if time_left > 0.01:
		var ratio: float = clampf(time_left / maxf(0.01, max_cd), 0.0, 1.0)
		overlay.visible = true
		overlay.color = Color(0.05, 0.05, 0.07, 0.78)
		overlay.anchor_top = 1.0 - ratio
		cd_label.visible = true
		cd_label.text = "%.1fs" % time_left
		cd_label.add_theme_font_size_override("font_size", 15)
		sb.border_color = Color(0.35, 0.35, 0.40)
	elif not condition_met:
		overlay.visible = true
		overlay.anchor_top = 0.0
		overlay.color = Color(0.12, 0.08, 0.08, 0.62)
		cd_label.visible = true
		cd_label.text = "SEM CARGA" if _current_element_type == ElementData.ElementType.FIRE else "SEM PILAR"
		cd_label.add_theme_font_size_override("font_size", 10)
		sb.border_color = Color(0.45, 0.25, 0.25)
	else:
		overlay.visible = false
		cd_label.visible = false
		cd_label.add_theme_font_size_override("font_size", 15)
		sb.border_color = _active_color if slot_name == "skill_2" else Color(0.75, 0.75, 0.80)

# ==========================================
# LEITURA AUTOMÁTICA DE TECLAS DO INPUT MAP
# ==========================================

func _get_action_key_hint(action_name: String, fallback: String = "") -> String:
	if not InputMap.has_action(action_name):
		return fallback
	for ev in InputMap.action_get_events(action_name):
		if ev is InputEventKey:
			var keycode: Key = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
			return OS.get_keycode_string(keycode).to_upper()
		elif ev is InputEventMouseButton:
			match ev.button_index:
				MOUSE_BUTTON_LEFT: return "LMB"
				MOUSE_BUTTON_RIGHT: return "RMB"
				MOUSE_BUTTON_MIDDLE: return "MMB"
				MOUSE_BUTTON_WHEEL_UP: return "SCROLL+"
				MOUSE_BUTTON_WHEEL_DOWN: return "SCROLL-"
	return fallback

# ==========================================
# CONSTRUÇÃO DA INTERFACE (ESTILO CLEAN/HD)
# ==========================================

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	
	# --- CANTO SUPERIOR ESQUERDO: VIDA + ELEMENTO + RECURSO ---
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 18)
	top_margin.add_theme_constant_override("margin_top", 18)
	root.add_child(top_margin)
	
	var top_vbox := VBoxContainer.new()
	top_vbox.add_theme_constant_override("separation", 6)
	top_margin.add_child(top_vbox)
	
	# Barra de Vida
	var hp_panel := _make_box_panel(Color(0.08, 0.08, 0.10, 0.88), Color(0.35, 0.35, 0.40))
	hp_panel.custom_minimum_size = Vector2(230, 26)
	top_vbox.add_child(hp_panel)
	
	var hp_container := Control.new()
	hp_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_panel.add_child(hp_container)
	
	_health_bar = ProgressBar.new()
	_health_bar.show_percentage = false
	_health_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_health_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_health_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.14, 0.06, 0.06)
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.22, 0.78, 0.34)
	_health_bar.add_theme_stylebox_override("background", hp_bg)
	_health_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_container.add_child(_health_bar)
	
	_health_label = Label.new()
	_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_health_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_health_label.add_theme_font_size_override("font_size", 13)
	_health_label.add_theme_constant_override("outline_size", 2)
	_health_label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06))
	hp_container.add_child(_health_label)
	
	# Badge do Elemento Ativo
	_element_badge = _make_box_panel(Color(0.22, 0.09, 0.04, 0.90), _active_color)
	_element_badge.custom_minimum_size = Vector2(230, 26)
	top_vbox.add_child(_element_badge)
	
	_element_label = Label.new()
	var init_switch: String = _get_action_key_hint("switch_element")
	_element_label.text = "ELEMENTO: FOGO" if init_switch.is_empty() else "ELEMENTO: FOGO  [%s]" % init_switch
	_element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_element_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_element_label.add_theme_font_size_override("font_size", 12)
	_element_badge.add_child(_element_label)
	
	# Painel do Recurso Elemental (Pressão Térmica ou Pilares de Terra)
	var res_panel := _make_box_panel(Color(0.08, 0.08, 0.10, 0.88), Color(0.32, 0.32, 0.36))
	res_panel.custom_minimum_size = Vector2(230, 42)
	top_vbox.add_child(res_panel)
	
	var res_vbox := VBoxContainer.new()
	res_vbox.add_theme_constant_override("separation", 3)
	res_panel.add_child(res_vbox)
	
	var res_header := HBoxContainer.new()
	res_vbox.add_child(res_header)
	
	_resource_title = Label.new()
	_resource_title.text = "PRESSÃO TÉRMICA"
	_resource_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_resource_title.add_theme_font_size_override("font_size", 11)
	_resource_title.modulate = Color(0.85, 0.85, 0.88)
	res_header.add_child(_resource_title)
	
	_heat_value_label = Label.new()
	_heat_value_label.text = "0%"
	_heat_value_label.add_theme_font_size_override("font_size", 11)
	res_header.add_child(_heat_value_label)
	
	_heat_bar = ProgressBar.new()
	_heat_bar.show_percentage = false
	_heat_bar.custom_minimum_size = Vector2(0, 12)
	var h_bg := StyleBoxFlat.new()
	h_bg.bg_color = Color(0.16, 0.12, 0.10)
	var h_fill := StyleBoxFlat.new()
	h_fill.bg_color = Color(1.0, 0.45, 0.08)
	_heat_bar.add_theme_stylebox_override("background", h_bg)
	_heat_bar.add_theme_stylebox_override("fill", h_fill)
	res_vbox.add_child(_heat_bar)
	
	_pillar_box = HBoxContainer.new()
	_pillar_box.visible = false
	_pillar_box.add_theme_constant_override("separation", 6)
	res_vbox.add_child(_pillar_box)
	
	for i in range(3):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(68, 12)
		pip.color = Color(0.18, 0.16, 0.15, 0.85)
		_pillar_box.add_child(pip)
		_pillar_pips.append(pip)
	
	# --- BASE INFERIOR CENTRAL: BARRA DE SKILLS ---
	var bot_anchor := Control.new()
	bot_anchor.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_anchor.offset_top = -92
	bot_anchor.offset_bottom = -14
	bot_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bot_anchor)
	
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot_anchor.add_child(center)
	
	var slots_hbox := HBoxContainer.new()
	slots_hbox.add_theme_constant_override("separation", 10)
	center.add_child(slots_hbox)
	
	slots_hbox.add_child(_create_skill_slot("dash", _get_action_key_hint("dash", "SHIFT"), "Dash"))
	slots_hbox.add_child(_create_skill_slot("skill_1", _get_action_key_hint("skill_1", "1"), "Skill 1"))
	slots_hbox.add_child(_create_skill_slot("skill_2", _get_action_key_hint("skill_2", "2"), "Skill 2"))
	slots_hbox.add_child(_create_skill_slot("ultimate", _get_action_key_hint("ultimate", "R"), "Suprema"))

func _create_skill_slot(slot_key: String, key_hint: String, default_name: String) -> PanelContainer:
	var panel := _make_box_panel(Color(0.08, 0.08, 0.11, 0.90), Color(0.55, 0.55, 0.62))
	panel.custom_minimum_size = Vector2(78, 72)
	_slot_panels[slot_key] = panel
	
	var base := Control.new()
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(base)
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	base.add_child(vbox)
	
	var key_lbl := Label.new()
	key_lbl.text = key_hint
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_lbl.add_theme_font_size_override("font_size", 11)
	key_lbl.modulate = Color(0.75, 0.78, 0.85)
	vbox.add_child(key_lbl)
	
	var name_lbl := Label.new()
	name_lbl.text = default_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(name_lbl)
	_slot_status_labels[slot_key] = name_lbl
	
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.05, 0.05, 0.07, 0.75)
	overlay.visible = false
	base.add_child(overlay)
	_slot_overlays[slot_key] = overlay
	
	var cd_lbl := Label.new()
	cd_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_lbl.add_theme_font_size_override("font_size", 15)
	cd_lbl.visible = false
	base.add_child(cd_lbl)
	_slot_cd_labels[slot_key] = cd_lbl
	
	return panel

func _make_box_panel(bg: Color, border: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_content_margin_all(5)
	pc.add_theme_stylebox_override("panel", sb)
	return pc

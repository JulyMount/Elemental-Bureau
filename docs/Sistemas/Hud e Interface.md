# Sistema de HUD de Combate (`CombatHUD`)

* **Script:** `res://scripts/ui/combat_hud.gd`
* **Arquitetura Visual:** `CanvasLayer` configurado em `layer = 50` (fora do `SubViewport` e acima dos shaders de pós-processamento pixelado e distorção de calor), mantendo tipografia e bordas nítidas em `1280x720`.
* **Integrações por Sinais:**
  * `HealthComponent` (`health_changed`): Atualiza a barra de HP e os valores numéricos em tempo real.
  * `ElementalComponent` (`element_switched`, `thermal_pressure_changed`, `earth_pillars_changed`, `ultimate_state_changed`): Alterna automaticamente o medidor superior entre **Pressão Térmica (0%–100% + alerta de Superaquecimento)** e os **3 indicadores de Pilares de Rocha ativos**, além de sincronizar os cooldowns específicos de cada `ElementData`.
  * `SkillManagerComponent` (`cooldown_updated`, `skill_triggered`): Exibe contagem regressiva nos 4 slots (*Dash*, *Skill 1*, *Skill 2*, *Suprema V4*) e valida `can_cast_skill_2()` antes de gastar cooldown.
* **Leitura Dinâmica de Inputs:** Lê automaticamente as teclas/botões configurados no `InputMap` do projeto (`switch_element`, `dash`, `skill_1`, `skill_2`, `ultimate`).
# BrainStorming para o HUD
[[HUD.canvas]]
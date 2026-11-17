# Roadmap de Desenvolvimento

Conectado a: [[00 - Elemental Bureau (GDD)]]

## Concluído e Validado
* [x] **Etapa A — Fundação Visual e Câmera:** `CameraRig` 45°, arena graybox e pipeline 3D-to-Pixel Art.
* [x] **Etapa B — Movimentação e Combate Base:** `Player`, Dash com i-frames, Soft-Lock, Hitbox/Hurtbox, Hitstop e `SkillManagerComponent`.
* [x] **Controle de Versão:** Repositório Git configurado na raiz do projeto + GDD vivo no Obsidian (`docs/`).
* [x] **Etapa C1 — Elemento Fogo:** `ElementData` (`fogo.tres`), `ElementalComponent`, [[Fogo|Kit completo de Fogo]] validado.
* [x] **Etapa C2 — Elemento Terra:** `terra.tres`, `RockPillar` destrutível, [[Terra|Kit completo de Terra]] e troca rápida de elemento (`switch_element`).

## Próximos Passos
* [ ] **Etapa D — HUD e Feedback de UI:** Barra de vida, indicador do elemento ativo, medidor de Pressão Térmica / Pilares ativos e cooldowns visuais.
* [ ] **Etapa E — Inimigos e IA:** Inimigos com máquina de estados (`StateMachine`) para testar combate real, bloqueio de projéteis com pilares e balanceamento.
* [ ] **Etapa F — Polimento VFX 3D:** Shaders de fogo (`fireball_shader.gdshader`, `stylized_fire.gdshader`), rachadura no solo (`ground_crack.gdshader`) e `GPUParticles3D`.
# Roadmap de Desenvolvimento

Conectado a: [[00 - Elemental Bureau (GDD)]]

## Concluído e Validado
* [x] **Etapa A — Fundação Visual e Câmera:** `CameraRig` 45°, arena graybox e pipeline 3D-to-Pixel Art.
* [x] **Etapa B — Movimentação e Combate Base:** `Player`, Dash com i-frames, Soft-Lock, Hitbox/Hurtbox, Hitstop e `SkillManagerComponent`.
* [x] **Controle de Versão:** Repositório Git configurado na raiz do projeto + GDD vivo no Obsidian (`docs/`).
* [x] **Etapa C1 — Elemento Fogo:** `ElementData` (`fogo.tres`), `ElementalComponent`, [[Fogo|Kit completo de Fogo]] validado.
* [x] **Etapa C2 — Elemento Terra:** `terra.tres`, `RockPillar` destrutível, [[Terra|Kit completo de Terra]] e troca rápida de elemento (`switch_element`).
* [x] **Etapa F1 — Malhas Procedurais e Shaders Reutilizáveis:** `ProceduralMeshFactory` (monólitos segmentados, estilhaços, coroa radial) + shaders `stylized_fire.gdshader` e `ground_crack.gdshader`.
* [x] **Etapa F1-A — VFX Completo de Fogo & Impacto Stylized:** `FireballProjectile` com cauda e faíscas, `StylizedHitVFX` suavizado, trilhas 3D de fogo/fumaça no Dash, bursts radiais e Suprema V4 com aura de partículas + `screen_heat_distortion.gdshader` com fade.
* [x] **Etapa F1-B — VFX Completo de Terra & Rocha:** Pilares monolíticos procedurais (`create_faceted_pillar`), estilhaços físicos (`RigidBody3D`) com `physics_freeze_delay` e `persist_debris`, poeira volumétrica (`DustRing` + `FlyingDebris`) e Suprema V4 com lascas rochosas orbitais (`create_rock_shard`).
* [x] **Etapa F1-B — VFX Completo de Terra & Rocha:** Pilares monolíticos procedurais (`create_faceted_pillar`), estilhaços físicos (`RigidBody3D`) com congelamento automático de física (`physics_freeze_delay = 4.0s`), opção de persistência na arena (`persist_debris`), poeira volumétrica (`DustRing` + `FlyingDebris`) e Suprema V4 com lascas rochosas orbitais (`create_rock_shard`).
* [x] **Etapa F1-C — CombatHUD & Feedback de Interface:** Implementação de HUD em `CanvasLayer` (`layer = 50`) nítido acima do pós-processamento pixelado, barra de vida, medidores dinâmicos de Pressão Térmica (Fogo) e Pilares Ativos (Terra), leitura automática de atalhos do `InputMap` e bloqueio/aviso condicional da Skill 2 (`SEM CARGA` / `SEM PILAR`).

## Próximos Passos
* [ ] **Etapa D — HUD e Feedback de UI:** Barra de vida, indicador do elemento ativo, medidor de Pressão Térmica / Pilares ativos e cooldowns visuais.
* [ ] **Etapa E — Inimigos e IA:** Inimigos com máquina de estados (`StateMachine`) para testar combate real, bloqueio de projéteis com pilares e balanceamento.
* [ ] **Etapa F2 — Partículas e Acabamento Final:** `GPUParticles3D` e refinamento estético final.
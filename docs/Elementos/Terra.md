# Elemento: Terra

Conectado a: [[00 - Elemental Bureau (GDD)]] | [[02 - Arquitetura Tecnica]]

* **Arquivo de Dados:** `res://scripts/resources/terra.tres` (`ElementData`)
* **Cena Auxiliar:** `res://scenes/vfx/rock_pillar.tscn` (`RockPillar`)
* **Identidade:** Controle de terreno, barreiras físicas e detonação tática em área.

## Passiva: Placas Tectônicas
* Habilidades erguem pilares de rocha sólidos (`StaticBody3D`) no cenário com duração de `10.0s` que bloqueiam projéteis e deslocamento.
* **Limite de Campo:** Máximo de **3 pilares ativos** simultaneamente; erguer um 4º pilar detona automaticamente o mais antigo.

## Kit de Habilidades
| Slot | Habilidade | Mecânica | Valores Atuais |
| :--- | :--- | :--- | :--- |
| **Dash** | Dash Sísmico | Emite um pulso de terra no início do impulso que empurra e causa dano leve em área. | `15` dano \| Raio `2.4m` |
| **Skill 1** | Erupção Tectônica | Ergue um `RockPillar` à frente (com [[01 - Movimentacao e Combate|Soft-Lock]]), causando dano de impacto ao emergir. | `40` dano \| Raio `2.0m` \| Cooldown `2.5s` |
| **Skill 2** | Estilhaçar | Detona **todos** os pilares de rocha ativos no mapa de uma vez, arremessando blocos de pedra em área com *Hitstop*. | `55` dano/pilar \| Raio `3.5m` \| Cooldown `4.5s` |
| **Suprema V4** | Colosso de Rocha | Aumenta o tamanho do personagem em `+45%`, concede invulnerabilidade e emite pulsos sísmicos periódicos (`0.85s`). | `35` dano inicial + `22`/pulso \| Duração `7.0s` \| Cooldown `15.0s` |
## Detalhes Técnicos & Polimento (Implementado)
* **Pilares Procedurais (`rock_pillar.gd`):** Gerados via `ProceduralMeshFactory.create_faceted_pillar`, mantendo o material terroso original e disparando burst de poeira (`DustRing`) ao emergirem do solo.
* **Estilhaços Físicos Persistentes:** Ao usar *Estilhaçar* (`Skill 2`), o pilar explode em 8 lascas `RigidBody3D` (`create_rock_shard`) geridas via sinais na `SceneTree`. Após `physics_freeze_delay` (`4.0s`), a física e as colisões são congeladas (`freeze = true`) para não bloquear o movimento, mantendo os escombros como marca na arena (controlável via `persist_debris` e `max_world_debris = 120`).
* **Suprema V4 — Colosso de Rocha:** Invulnerabilidade, aumento de escala (`1.45x`), pulsos sísmicos periódicos e anel orbital (`RockColossusOrbit`) com 5 fragmentos rochosos girando em torno do jogador.
## Ajustes Pendentes (Polimento)
* [x] Substituir cubo placeholder por monólito procedural segmentado (`ProceduralMeshFactory`) com variação de blocos, pedras na base e inclinação única por conjuração.
* [x] Aplicar shader `ground_crack.gdshader` (`crack_mat.tres`) e coroa radial 3D nas ondas de impacto.
* [x] **Etapa F1-B — VFX Completo de Terra & Rocha:** Pilares monolíticos procedurais (`create_faceted_pillar`), estilhaços físicos (`RigidBody3D`) com `physics_freeze_delay` e `persist_debris`, poeira volumétrica (`DustRing` + `FlyingDebris`) e Suprema V4 com lascas rochosas orbitais (`create_rock_shard`).
* [ ] Ajustar paleta de cores/textura dos monólitos e adicionar partículas de poeira/detritos (`GPUParticles3D`).
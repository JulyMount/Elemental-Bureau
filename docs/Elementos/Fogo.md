# Elemento: Fogo

Conectado a: [[00 - Elemental Bureau (GDD)]] | [[02 - Arquitetura Tecnica]]

* **Arquivo de Dados:** `res://scripts/resources/fogo.tres` (`ElementData`)
* **Identidade:** Alto dano em área, mobilidade ofensiva e gestão de superaquecimento.

## Passiva: Pressão Térmica
* Usar habilidades acumula calor de `0%` a `100%` (dissipa lentamente fora de uso).
* **Bônus de Dano:** Concede até **+50% de dano** proporcional ao calor acumulado.
* **Sobrecarga Térmica (100%):** Dispara automaticamente uma explosão em área (`4.0m`, `65` de dano) ao redor do jogador e inicia resfriamento rápido.

## Kit de Habilidades
| Slot | Habilidade | Mecânica | Valores Atuais |
| :--- | :--- | :--- | :--- |
| **Dash** | Rastro de Brasas | Solta 3 poças de fogo ao longo do trajeto que causam dano imediato e contínuo. | `+10%` Calor \| `15` dano/tick |
| **Skill 1** | Bola de Fogo | Projétil linear com [[01 - Movimentacao e Combate|Soft-Lock]] que explode em área ao atingir inimigos ou paredes. | `45` dano base \| Cooldown `3.0s` |
| **Skill 2** | Onda de Calor | Consome toda a **Pressão Térmica** para liberar um pulso incendiário; raio e dano escalam com o calor. | Até `60` dano \| Raio `2.5m–5.5m` \| Cooldown `5.0s` |
| **Suprema V4** | Corpo de Chama Viva | Invulnerabilidade, **+35% de velocidade** e rastro contínuo de brasas ao correr. | Duração `6.0s` \| Cooldown `14.0s` |

## Visual e VFX Implementados (Alinhado à Knowledge Base)
* [x] **Bola de Fogo (`FireballProjectile`):** Núcleo incandescente (`EMISSION` HDR), cauda cônica com fade UV (`use_tail_fade`), partículas de brasas (`Embers`), luz dinâmica oscilante (`FastNoiseLite`) e impacto estilizado (`StylizedHitVFX` com estrela 3D, coroa e faíscas).
* [x] **Dash de Combustão:** Trilhas com 3 línguas de fogo 3D cruzadas, fumaça escura ascendente com rotação, faíscas e iluminação quente no piso.
* [x] **Onda de Calor & Sobrecarga Térmica:** Rachaduras Voronoi no solo com labaredas e fumaça escura subindo pelas fendas, burst radial de chamas e flash laranja.
* [x] **Suprema V4 (Corpo de Chama Viva):** Aura orgânica de labaredas em espiral (`GPUParticles3D` com `Scale Curve` e `Color Ramp`), halo 3D de calor (`heat_distortion.gdshader`), luz oscilante e distorção térmica de tela com fade-in/fade-out (`screen_heat_distortion.gdshader`, ajustável via Inspetor).

## Ajustes Pendentes (Balanceamento)
* [ ] Balancear dano da Suprema V4 contra inimigos móveis na Etapa E.
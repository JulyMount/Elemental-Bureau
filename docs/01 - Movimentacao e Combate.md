# Movimentação e Combate

Conectado a: [[00 - Elemental Bureau (GDD)]] | [[02 - Arquitetura Tecnica]]

## Câmera e Direção
* **Câmera Isométrica 45° (`CameraRig`):** Segue o jogador suavemente com suporte a *Screen Shake* no impacto.
* **Movimentação Relativa à Câmera:** O vetor de input (`WASD` / Analógico) é rotacionado pelo `yaw` da câmera para que "cima" sempre aponte para o topo da tela.

## Mecânicas Centrais
* **Dash:** Impulso rápido na direção do movimento com **i-frames** (invulnerabilidade temporária via `HealthComponent`). Ativa efeitos elementais no trajeto (ex: rastro de brasas em [[Fogo]]).
* **Soft-Lock Direcional:** Ao atacar ou usar skills, busca alvos no grupo `enemies` dentro de um cone frontal e ajusta suavemente a mira do jogador.
* **Feedback de Impacto:**
  * *Hitstop:* Breve congelamento de `Engine.time_scale` em golpes pesados e explosões.
  * *Squash & Stretch:* Deformação visual nos alvos ao receberem dano.
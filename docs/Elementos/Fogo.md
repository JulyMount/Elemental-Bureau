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

## Ajustes Pendentes (Balanceamento)
* [ ] Reduzir levemente o dano ou a frequência das poças da **Suprema V4** após testar contra inimigos móveis.
* [ ] Substituir placeholders 3D pelo shader `fireball_shader.gdshader` e partículas `GPUParticles3D`.
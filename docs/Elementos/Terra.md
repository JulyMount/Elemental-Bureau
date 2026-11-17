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

## Ajustes Pendentes (Polimento)
* [ ] Substituir placeholders 3D pelo shader `ground_crack.gdshader` e partículas de poeira/detritos (`GPUParticles3D`).
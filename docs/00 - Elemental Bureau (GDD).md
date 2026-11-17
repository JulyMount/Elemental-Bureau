# Elemental Bureau — Game Design Document

> **Engine:** Godot 4.7.2 | **Estética:** 3D-to-Pixel Art Isométrico (45°) | **Arquitetura:** Modular por Composição

## Pilares do Projeto
* **Combate Tático e Reativo:** Habilidades com sinergias internas (ex: acúmulo de pressão, terreno destrutível) em vez de apenas apertar botões no cooldown.
* **Game Feel Responsivo:** [[01 - Movimentacao e Combate|Soft-Lock direcional]], Hitstop, Screen Shake e Dash com i-frames.
* **Estética 3D-to-Pixel Art:** Modelos e VFX 3D renderizados sob câmera isométrica fixa de 45° com shader de pixelização e paleta controlada.

## Índice do GDD
* [[01 - Movimentacao e Combate]]
* [[02 - Arquitetura Tecnica]]
* [[03 - Roadmap e Etapas]]

### Elementos Jogáveis
* [[Fogo]] — Agressivo, acúmulo de risco/recompensa ([[Fogo#Pressão Térmica|Pressão Térmica]]).
* [[Terra]] — Controle de área, criação e detonação de pilares físicos *(Em desenvolvimento)*.
# Sistema de Inimigos e Arquétipos

**Status:** Concluído e Balanceado (Beta Combat Lock)  
**Scripts:** `res://scripts/enemies/` (`enemy_base.gd`, `enemy_rusher.gd`, `enemy_brute.gd`, `enemy_shooter.gd`)  
**Conexões:** [[Player_e_Movimentacao]] | [[Componentes_de_Combate]] | [[Sistema_Elemental]]

---

## 1. Arquitetura Base (`EnemyBase`)

Todos os inimigos herdam de `EnemyBase` (`CharacterBody3D`), pertencem ao grupo `"enemies"` (para detecção automática do *Soft Lock* do `Player`) e utilizam composição via [[Componentes_de_Combate]] (`HealthComponent` e `HurtboxComponent`).

### Máquina de Estados (FSM)
1. **`CHASE`**: Persegue o alvo no grupo `"player"` utilizando `_move_velocity` independente da gravidade e do recuo.
2. **`TELEGRAPH`**: Para o avanço, achata levemente a escala e ilumina o material em amarelo (`telegraph_color`) antes de desferir o ataque.
3. **`ATTACK`**: Executa a ação específica do arquétipo (`_on_attack_started` / `_on_attack_tick`).
4. **`RECOVER`**: Pausa breve pós-ataque antes de retomar a perseguição.
5. **`STAGGER`**: Interrompe ações e aplica flash branco + *squash & stretch* ao receber dano (exceto inimigos com `can_be_staggered = false`).

### Física e Knockback Bidirecional
* **Separação de Vetores**: O movimento intencional (`_move_velocity`) é mantido separado do impulso de impacto (`_knockback_velocity`), evitando acúmulo infinito de velocidade no `move_and_slide()`.
* **Leitura Direcional**: Cada arquétipo gera proceduralmente um `VisorMesh` frontal (`-Z`) via `_get_visor_transform()` dentro de `VisualRoot`, mantendo a orientação clara mesmo em blockout geométrico.

---

## 2. Os 3 Arquétipos da Beta

| Arquétipo | Script / Malha Procedural | Comportamento Tático | Atributos Chave |
| :--- | :--- | :--- | :--- |
| **Rusher (Batedor)** | `enemy_rusher.gd` (Cápsula Vermelha) | Perseguição rápida e bote curto (`lunge_speed = 13.5`) com `AttackHitbox` frontal. | Alta velocidade (`4.6`), `telegraph = 0.48s`, vulnerável a *stagger*. |
| **Brute (Colosso)** | `enemy_brute.gd` (Caixa Roxa) | Avanço pesado, imune a interrupção leve e golpe frontal de alto impacto. | `knockback_resistance = 2.8`, `can_be_staggered = false`, dano `22`, empurrão `7.5`. |
| **Shooter (Atirador)** | `enemy_shooter.gd` (Prisma Ciano) | Mantém distância média (`preferred_distance = 7.5m`), recua se pressionado e dispara orbes elementais. | Projéteis bloqueáveis por paredes e pelos Pilares de Rocha do [[Sistema_Elemental]]. |

---

## 3. Camadas de Física Padronizadas (3D Physics)

* **Layer 1 (`World`)**: Chão, paredes, Pilares de Rocha, corpo físico do `Player` e `HurtboxComponent` do `Player`.
* **Layer 2 (`EnemyHurtbox`)**: `HurtboxComponent` dos inimigos (alvo dos ataques básicos e habilidades do `Player`).
* **Layer 3 (`PlayerHurtbox`)**: Reserva dedicada para hurtboxes de dano ao jogador.
* **Layer 4 (`Enemies`)**: Corpos físicos (`CharacterBody3D`) dos inimigos e detecção da `SoftLockArea`.
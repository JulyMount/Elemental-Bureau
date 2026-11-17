# Arquitetura Técnica (Godot 4.7.2)

Conectado a: [[00 - Elemental Bureau (GDD)]]

## Padrão de Composição (Nós Filhos)
Em vez de herança profunda, as entidades combinam componentes independentes:
* `HealthComponent`: Gerencia HP atual/máximo, invulnerabilidade (i-frames / V4) e sinais de dano/morte.
* `HitboxComponent` & `HurtboxComponent`: Comunicação de dano desacoplada por *Collision Layers/Masks*.
* `SkillManagerComponent`: Controla cooldowns e disparo dos slots (`skill_1`, `skill_2`, `ultimate`).
* `ElementalComponent`: Gerencia o `ElementData` ativo ([[Fogo]], [[Terra]]), recursos elementais e instanciação de habilidades.

## Custom Resources (`ElementData`)
* Molde em `res://scripts/resources/element_data.gd`.
* Permite editar danos, durações e cooldowns direto no Inspetor via arquivos `.tres`.
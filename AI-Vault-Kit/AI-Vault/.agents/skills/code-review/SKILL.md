---
name: code-review
description: Reviews code and configuration for correctness, edge cases, security (secrets, injection, network exposure, permissions), test coverage and consistency with confirmed project decisions. Use when validating an implementation, a pull request or a configuration change before it is considered done.
---
# Code-Review

## Activation
Validation d'une implémentation, d'une PR, d'un script ou d'une configuration (ex. `mcp_config.json`).

## Checklist
1. **Exactitude** : répond aux exigences (`01-Requirements.md`) ?
2. **Décisions** : cohérent avec les entrées `confirmed` de `02-Decisions.md` ?
3. **Cas limites** : entrées vides/invalides, erreurs réseau, timeouts, concurrence.
4. **Sécurité** : secrets en clair, injections (shell, SQL, chemin), désactivation TLS, ports exposés hors localhost, permissions excessives, outils MCP destructifs activés.
5. **Tests** : présents, pertinents, exécutés ; résultats réels.
6. **Lisibilité / maintenabilité** : nommage, duplication, complexité.
7. **Données** : aucune suppression/écrasement non autorisé.

## Restitution
Verdict (APPROUVÉ / AVEC RÉSERVES / REFUSÉ) + tableau sévérité / emplacement / problème / correction + section « Non vérifié ».

## Limites
Ne modifie pas le code revu ; propose des corrections.

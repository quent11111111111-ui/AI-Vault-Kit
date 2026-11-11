---
name: python-development
description: Standard procedure for Python development - virtual environments, project layout, typing, pytest testing, linting, debugging and safe handling of secrets. Use when writing, modifying, debugging or testing Python code, scripts, APIs or automations.
---
# Python-Development

## Activation
Écriture, modification, débogage ou test de code Python.

## Procédure
1. **Contexte** : si projet existant, lire exigences/décisions (skill `context-retrieval`).
2. **Environnement** : `uv venv` (ou `python -m venv .venv`) ; dépendances déclarées dans `pyproject.toml` ; versions épinglées.
3. **Structure** : `src/<paquet>/`, `tests/`, `pyproject.toml`, `README.md`, `.env.example` (jamais `.env` versionné).
4. **Code** : typage (`from __future__ import annotations`), fonctions courtes, erreurs explicites, logs via `logging`.
5. **Tests** : `pytest` ; tester cas nominal + limites + erreurs ; mocks pour réseau/APIs.
6. **Qualité** : `ruff check` + `ruff format` ; optionnel `mypy`.
7. **Exécuter** les tests et rapporter la sortie réelle.
8. **Débogage** : reproduire → isoler (test minimal) → corriger → test de non-régression.
9. Proposer les décisions d'architecture à consigner (`project-management`).

## Limites
- Secrets via variables d'environnement uniquement.
- Trading : jamais d'ordres réels sans mode simulation/paper testé et accord explicite.
- Pas d'installation globale système ; tout en environnement virtuel.

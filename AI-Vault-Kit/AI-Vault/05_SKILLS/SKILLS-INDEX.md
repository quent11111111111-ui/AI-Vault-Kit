---
type: catalog
id: skills-index
status: active
updated: 2026-11-11
tags: [skills]
---
# Catalogue des skills

Skills natifs Antigravity : `.agents/skills/<nom>/SKILL.md`. Antigravity n'injecte que `name` + `description` à chaque tour ; le contenu complet est lu uniquement quand le skill est sélectionné.

| Skill | Description | Utilisé par | Chemin |
|---|---|---|---|
| `context-retrieval` | Retrouver uniquement la mémoire utile via AI-INDEX et le MCP | tous | `.agents/skills/context-retrieval/SKILL.md` |
| `project-management` | Créer un projet, consigner décisions, tâches, résumés | developer, principal | `.agents/skills/project-management/SKILL.md` |
| `knowledge-management` | Enregistrer des connaissances durables sans doublon | project-researcher, principal | `.agents/skills/knowledge-management/SKILL.md` |
| `web-research` | Recherche web fiable, sources datées et croisées | project-researcher | `.agents/skills/web-research/SKILL.md` |
| `python-development` | Environnement, structure, tests, qualité, débogage Python | developer | `.agents/skills/python-development/SKILL.md` |
| `code-review` | Revue : exactitude, sécurité, tests, cohérence | reviewer | `.agents/skills/code-review/SKILL.md` |

Limite : 3 skills chargés simultanément (indicatif).
Ajouter un skill : `06_TEMPLATES/Skill-Template.md`.

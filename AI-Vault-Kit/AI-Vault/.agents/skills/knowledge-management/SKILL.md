---
name: knowledge-management
description: Organises and saves durable, non-project knowledge into the Obsidian vault (03_KNOWLEDGE, 99_INBOX), deduplicating against existing notes and tagging status and sources. Use when a reusable fact, method or discovery should be remembered beyond the current conversation.
---
# Knowledge-Management

## Activation
Une connaissance durable et réutilisable émerge (hors décisions projet). Ne pas activer pour du contenu banal.

## Procédure
1. Tester la valeur : sera-t-elle utile dans des semaines ? Sinon, ne rien enregistrer.
2. Dédupliquer : `search_simple` sur le sujet. Note existante → `vault_append`/`vault_patch` d'une section datée, pas de doublon.
3. Choisir le domaine : `03_KNOWLEDGE/{Technology,Finance,Science,Programming,General}/`. Incertain → `99_INBOX/`.
4. Créer avec `vault_write` + `ifNoneMatch: "*"` et ce frontmatter :
   ```yaml
   type: knowledge
   domain: <Domaine>
   status: confirmed | hypothesis
   sources: [<url ou note>]
   created: AAAA-MM-JJ
   updated: AAAA-MM-JJ
   tags: []
   ```
5. Lier depuis le projet concerné (`[[...]]`) si pertinent.

## Limites
Jamais de secret ni de donnée personnelle sensible. Préférences personnelles → seulement si confirmées, dans `01_PROFILE/Preferences.md`, avec accord.

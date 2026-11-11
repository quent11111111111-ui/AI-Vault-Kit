---
name: context-retrieval
description: Retrieves only the relevant memory from the user's Obsidian vault through the obsidian MCP server, using the AI-INDEX router and progressive loading (index, project, notes, agent, skills). Use when a request mentions an existing project, prior decisions, preferences or "resume/continue" work.
---
# Context-Retrieval

## Activation
- La demande dépend d'un projet, d'une décision antérieure, d'une préférence ou d'une connaissance stockée.
- **Ne pas activer** pour une question générale indépendante de l'utilisateur.

## Instructions
- Toujours partir de `00_SYSTEM/AI-INDEX.md`. Ne jamais lister/lire tout le coffre.
- Budget initial : 1 projet, 3–5 notes. Justifier tout dépassement.

## Procédure
1. Extraire 2–4 mots-clés de la demande.
2. `vault_read` → `00_SYSTEM/PROJECTS-INDEX.md` ; faire correspondre id/alias/mots-clés.
   - Pas de correspondance → répondre : « Aucun projet *X* n'est enregistré dans le coffre » et proposer la création (skill `project-management`). Arrêter la recherche projet.
3. `vault_read` → `<projet>/00-Overview.md` (niveau 2). Suffisant ? Arrêter.
4. Niveau 3, au choix selon la demande :
   - décisions : `02-Decisions.md` (utiliser `vault_get_document_map` puis lire les dernières entrées) ;
   - avancement : `03-Tasks.md` + dernier fichier de `05-Session-Summaries/` (le nom commence par la date) ;
   - sujet précis : `search_simple` `{ "query": "<mots-clés>", "maxResults": 10 }` puis filtrer sur le chemin du projet.
   - filtre métadonnées : `search_query` avec JsonLogic, ex. `{"and":[{"==":[{"var":"frontmatter.project"},"<id>"]},{"==":[{"var":"frontmatter.status"},"confirmed"]}]}`.
5. Vérifier dates/statuts ; signaler contradictions et informations manquantes.
6. Restituer : liste des notes lues (chemins) + synthèse utile à la tâche.

## Limites
- Lecture seule. Pour écrire : skills `project-management` / `knowledge-management`.
- Si le serveur `obsidian` est indisponible : le dire, ne pas deviner.

## Références
`00_SYSTEM/AI-INDEX.md`, `00_SYSTEM/PROJECTS-INDEX.md`.

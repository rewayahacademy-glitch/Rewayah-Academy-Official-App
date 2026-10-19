# Fichiers à importer à la main

Ces fichiers servent des outils **hors du dépôt**. Un agent dans le dépôt ne peut pas les écrire à leur
place : ils restent préparés tant que le directeur ne les a pas importés.

## 1. Compétence de compte `rewayah-academy-knowledge` (claude.ai)

**Problème** : la version du compte (mai 2026) décrit un autre projet (cours préenregistrés de Tawhid,
Fiqh, Sira, EVI sur systeme.io) sous le nom de Rewayah Academy. Elle se déclenche dès qu'une session
parle de « Rewayah Academy », y compris dans Claude Design.

**À faire** :

1. Dans claude.ai, ouvrir Réglages, puis Compétences, puis `rewayah-academy-knowledge`.
2. Remplacer son contenu par `import/rewayah-academy-knowledge/SKILL.md` (ou la supprimer et téléverser
   ce dossier compressé en `.zip`).
3. Si le contenu de mai 2026 sert encore pour l'autre projet, le garder dans une compétence à son nom,
   séparée. Elle ne doit pas porter le nom de Rewayah Academy.
4. Les compétences `contenu-pedagogique-rewayah` et `systeme-io-*` parlent aussi de Rewayah pour des
   cours de Tawhid, Fiqh, Sira et EVI. Même vérification : renommer ou préciser leur projet.

## 2. Claude Design

Téléverser le dossier `.claude/skills/marque-rewayah/` en compétence (compressé en `.zip`), puis coller le
texte d'amorçage de `CAHIER-DES-CHARGES-VISUEL.md`, section G, au début de la session. Joindre les SVG de
`assets/brand/logo/` et les polices de `assets/fonts/`.

## 3. Mémoire Claude Code du poste du directeur

Le `CLAUDE.md` racine cite `C:\Users\dell\.claude\projects\C--\memory\MEMORY.md`. Ce fichier n'existe pas
dans les sessions cloud. Ajouter à l'index, sur le poste :

```
- Marque (19/10/2026) : source unique docs/current/marque/ (registre, manifeste, cahier visuel).
  PISI est un autre projet, sans interférence avec Rewayah. Le site public est un brouillon.
  Signatures : candidates, non adoptées.
```

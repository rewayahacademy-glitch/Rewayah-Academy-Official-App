# Constats UX/UI des parcours joués

Tenu par le robot de bout en bout (`METHODE-2026-11-01.md`, § « Revue UX/UI »), décision du
directeur du 31/10/2026. Le robot **consigne, il ne corrige pas**.

Règles pour que rien ne se perde :

- Chaque constat reçoit un identifiant suivi : UX-001, UX-002, … jamais réutilisé.
- Un constat ne se ferme **que** par une capture Playwright datée qui montre la correction ; la
  colonne Statut dit alors « corrigé le JJ/MM » et le chemin de la capture.
- Une consigne de worker qui touche un écran cite les UX-xxx ouverts de cet écran.
- Aucune pull request ne retire une ligne de ce fichier.
- L'ancien pilote vérifie chaque matin qu'aucun constat n'a disparu ni n'a été fermé sans capture.

Classe : Manquant · Mal placé · Doublon · Taille · Non branché · Cassé · Texte · Interprétation · Détour · Conforme.
Gravité : Bloquant (objectif impossible) · Gênant (possible mais difficile) · Finition.
Code : statut (absent, non routé, non branché, cassé, mal placé) et `fichier:ligne` probable.

Standards de référence (repris du mandat d'audit UX du 27/10, branche
`claude/admiring-brown-r6ai72-audit`, non fusionnée) : Material 3 (navigation, actions,
formulaires, cibles 48 × 48), Apple HIG, Google Meet (commandes et centre de la salle), Google
Classroom (espace de l'enseignant), Quran.com et Tarteel (lecteur du Coran, glisser pour tourner),
Baymard (formulaires), WCAG 2.2 AA (contraste 4,5:1, cible 24 × 24, texte à 200 %, focus visible).

| ID | Écran | Élément | Attendu (spec + standard) | Constaté | Preuve | Classe | Gravité | Code | Statut |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |

# HYGIENE-2 : captures R3 (08/11/2026)

Données de test uniquement (noms fictifs, aucun montant réel).

## (9) Fichier Wise : injection de formule

- `fichier-wise-apres.csv` : le fichier écrit par la vraie fonction
  `fichierCsvWise` (branche `claude/hygiene-2`) sur huit lignes de test.
- `fichier-wise-avant.csv` : les mêmes lignes, écrites comme le faisait la
  fonction de `main` (guillemets seulement).
- `fichier-wise-avant.png`, `fichier-wise-apres.png` : chaque fichier ouvert
  dans un tableur (LibreOffice Calc, import CSV avec évaluation des formules),
  puis exporté en image.

Ce qu'on lit :

- **Avant** : `=HYPERLINK(...)` devient un lien « Cliquer », et ` =1+1`
  est calculé (« 2 »). Le tableur exécute ce que le nom contient.
- **Après** : chaque cellule dangereuse s'affiche en texte, apostrophe en
  tête ; rien n'est calculé. « Nom Test », « Nom-Test » et les montants ne
  changent pas.

## (10) `purge_at` des pièces d'identité

Aucun écran. La preuve est le scénario
`supabase/tests/scenarios_hygiene_purge_kyc.sql` (rouge sans la migration,
vert avec), et le rejeu complet des 246 scénarios avec et sans.

# À harmoniser : règles d'argent, de suppression et d'arrêt (directeur, 07/11/2026)

Ce fichier est une **dette obligatoire**, pas une note. Il reste ouvert tant que le lot
d'harmonisation n'a pas réuni, dans une seule décision datée du directeur, toutes les règles
ci-dessous et supprimé les versions contradictoires du code et des documents. Tout agent qui
touche un remboursement, une suppression de profil, un arrêt, une facture ou une paie le lit
d'abord (renvoi dans `CLAUDE.md`).

## Les mots du directeur (07/11/2026, mot pour mot)

« on ne peut pas supprimer un enfant n'importe quand, s'il a réservé une place pour un mois alors
l'argent n'est plus remboursable, les nouveaux inscrits ont les 14 jours selon la loi... il faut
aussi permettre aux tuteurs/élèves de demander un arrêt temporaire là aussi si le mois est commencé
alors ce sera au prochain moi que l'arrêt pourra être effectif. toutes ces règles devront être
harmonisées après car il y'a eu trop de bricolage, alors tu le mentions où on ne l'oubliera
jamais. »

## Règles décidées le 07/11 (à appliquer dans le lot d'harmonisation)

1. **Suppression d'un profil d'élève et argent.** Quand un mois est réservé (payé pour une
   place), l'argent de ce mois n'est plus remboursable. Supprimer le profil ne rembourse pas ce
   mois.
2. **Délai légal de 14 jours.** Un nouvel inscrit garde son droit de rétractation de 14 jours :
   dans ce délai, la règle 1 ne s'applique pas. Le point de départ exact du délai et ce qui est
   remboursé dans ce cas sont à fixer dans le lot (droit : décision du directeur).
3. **Pas de suppression « n'importe quand ».** Le moment où un tuteur peut supprimer un profil
   est encadré par les règles 1 et 2 ; l'écran doit le dire avant la confirmation.
4. **Arrêt temporaire.** Un tuteur ou un élève adulte peut demander un arrêt temporaire. Si le
   mois est commencé, l'arrêt prend effet le **mois suivant**. Le mois en cours reste dû et la
   place reste tenue jusqu'à sa fin.

## Ce qui existe déjà et devra être réconcilié (relevé à faire par le lot, rien n'est supposé)

- Remboursements FN-115 (conditions, remboursement en ligne, Stripe) : migrations et écrans en
  production depuis le 02/11.
- Suppression d'un profil d'enfant par le tuteur (`tuteur_supprimer_profil_enfant`,
  `private.suppr_retirer`) : aujourd'hui sans aucune règle d'argent ; clôture des demandes
  ouvertes depuis le 07/11 (20261110340000).
- Factures mensuelles, allocations de recharge par profil, crédit du foyer (`wallets`).
- Contrat, conditions générales et pages juridiques (`juridique.*`).
- Pause de séance (`CONTRAT_PORT_PAUSE_SEANCE.md`) : **autre chose** (pause pendant une séance),
  à ne pas confondre avec l'arrêt temporaire.
- `DECISION-TARIFS-2026-10-18.md` : prix, remises, paie.

## Ce que le lot d'harmonisation doit livrer

- Une décision unique datée, relue par le directeur, qui remplace les règles éparses.
- La liste des règles contradictoires trouvées, avec l'endroit (fichier, fonction, écran) et le
  sort de chacune.
- Le serveur qui applique ces règles (aucun calcul d'argent de référence côté Flutter).
- Les textes visibles : contrat, conditions, écran de suppression, écran d'arrêt.

Inscrit au journal des décisions : `08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md` §5 bis,
ligne du 2026-11-07. Lot : **HARMONISER-ARGENT**, **en dernier dans la file, après tous les
autres lots** (directeur, 07/11/2026 : « l'harmonisation vient après tout ») ; il n'est pas
abandonné tant que ce fichier existe. Un relevé partiel, fait trop tôt le 07/11 puis arrêté,
est sur la branche `claude/harmoniser-argent` : le lot le reprend sans le refaire.

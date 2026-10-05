# HL-A-5 — Style de référence CL-4 sur AD-6 à AD-10 : corrections et fin

Branche `ui/admin-v1` (dépôt `D:\RA_TUTEUR\admin`). Référence : STYLE-REFERENCE-CL4-2026-09-26, captures CL-4.7.
Thème, couleurs (K-37), textes (spec 03, K-41), règles d'accès, appels serveur, frontière : inchangés.

## Commits

- `c61d66d` revue : emplacement de décision unique, carte Identité une ligne par élément, politique KYC bornée 760.
- `80eae2e` surfaces 02D/02E, /attente : Actualiser sous la carte d'état.
- `b2ecef2` planche de captures (84 PNG à l'époque ; 96 PNG, 16 écrans × 3 tailles × 2 thèmes, depuis HL-A-6 et AD-M2-CAPT, vérifiée le 05/10 sur `corrections/ad-nettoyage-2` @ d52314cb).
- `906d1a3` corrections d'audit (ce passage), voir ci-dessous.

## Ce qui a changé, écran par écran (906d1a3)

- **ADM-02B revue (bureau et tablette)** : la ligne d'état prend la place exacte de « Valider le dossier » dans la
  même rangée que « Refuser le dossier », au bord de fin. L'ordre est le même que sur mobile (Valider ou sa raison,
  puis Refuser). Une seule région annoncée. Majeur 1 corrigé.
- **ADM-02B carte Identité** : les lignes Type de dossier et Date de dépôt sont retirées, parce que la ligne de contexte
  de l'en-tête les dit déjà. La spec §10.7 les présente comme possibles et demande les champs nécessaires seulement.
  Aucun texte n'est modifié. Majeur 3 corrigé.
- **ADM-02D / 02E** : Annuler passe en tertiaire dans les deux surfaces, qui ont maintenant la même anatomie. Le
  destructif reste un texte rouge : le contrat d'ActionPrincipale interdit l'aplat rouge (`lib/core/widgets`, hors
  lot). Le motif passe en lecture seule pendant l'envoi, la vérification et quand le résultat est inconnu (rendu
  seulement).
- **/attente (AD-10)** : la prochaine action (« Corriger → » et les autres) est placée 16 sous la carte d'état, au bord
  de fin. Elle est en pleine largeur sur mobile et à largeur naturelle à partir de la tablette. Le pied ne garde que
  « Se déconnecter ». Aucune route ni aucun texte ne change. Majeur 2 corrigé.
- **Planche** : la fiche bureau est cadrée sur l'emplacement de décision ; elle n'est plus identique à « coque et
  file » (hash 97E6CA0E contre A831CB8E). « Retour après validation » est renommé
  `retour_apres_validation_hors_portee_*` : l'accueil tuteur ne fait pas partie de /attente. Les anciens
  `retour_apres_validation_*` n'ont pas pu être supprimés (protection de l'outil) et sont périmés.

## Chiffres

- `flutter analyze --fatal-infos` : aucun problème.
- Tests ciblés (revue, attente, décisions, AD-10, AD-11, dossiers) : verts après mise à jour de deux tests.
  - `revue_dossier_test` 1440 : la ligne d'état est au bord de fin, après Refuser.
  - `attente_test` : `ensureVisible` avant le tap, car l'action est maintenant dans le corps.
- Captures HL-A-5 : 84 PNG refaits à ce passage (14 écrans, 36 cas verts) ; la planche compte aujourd'hui 16 écrans et 96 PNG, avec l'écran 16 `retour_apres_validation_hors_portee`, ouverts : vérifications incomplètes, portail après refus, fiche,
  refus.
- Suite complète sous verrou (`suite_complete_hl_a5.log`) : **+2967 ~880, All tests passed**, 930 s, en un seul passage.

## Restes et décisions (directeur / HU-1)

- **Majeur 4, en-tête mobile de 02B** (onglets entre le titre et le contexte, tête figée à environ 28 %) : il relève
  de `dossiers_page.dart` et de PageShell (AD-5 et AD-S), hors portée. Il est renvoyé en HU-1 et noté comme défaut
  de 02B.
- **02C, deux sorties** (croix ou retour, et « Fermer ») : la spec §11.2 impose les deux sur mobile, et la croix
  appartient à `AppBottomSheet.ouvrirLecture`, qui est partagé. Décision du directeur, sinon HU-1.
- **Politique KYC** (le titre répète l'onglet, onglet tronqué sur mobile) : coque de configuration, HU-1.
- **02D destructif plein** : refusé par le contrat du composant (jamais d'aplat rouge). Décision du directeur si l'on
  veut une forme dominante.
- Les décisions de spec signalées par l'audit restent ouvertes : titre « Dossier de … » (§10.11), ligne d'état au
  lieu d'un bouton grisé (§10.14, CA-19), pièce absente (P-ADM-08.2), SousNavigationDomaine sur le détail mobile.
- Captures des dossiers AD-6 à AD-11 non refaites dans ce passage : seule la planche HL-A-5 couvre les écrans touchés.

## Mise à jour du 05/10 (AD-M2-CAPT, vérifiée)

- Planche `captures/HL-A-5` : **16 écrans × 6 = 96 PNG**, plus 6 captures de la revue d'un dossier en production et 2 captures `ad9_14` (corrections/ad-nettoyage-2 @ d52314cb). Écran 16 : `retour_apres_validation_hors_portee`.
- Écran 3 (`verifications_incompletes`) : sur tablette la fiche tient entière à l'écran, donc le lien « Terminez les vérifications requises. » n'a pas d'effet visible (le défilement est impossible à cette taille). Ce n'est pas un défaut de la capture.

# UX_REVIEW_DISPO-1 : disponibilités de l'enseignant par plages (09/10/2026)

- **Demande** : directeur, commentaire du 01/10 23:16 sur la page Essai de fusion (étape
  DISPO-1) : « un créneau par ligne (jour | de | à), saisie par plage plutôt qu'heures
  exactes » ; la grille de cases jour × heure est trop compliquée, à remplacer.
- **Proposition appliquée** : liste des plages + bouton « Ajouter une plage » qui ouvre une
  feuille (jours en puces, « de » et « à » dans deux listes, raccourcis) ; toucher une plage
  ouvre la même feuille préremplie pour la modifier ou la supprimer. **Décidé par délégation
  le 09/10** (orchestrateur, aucune question au directeur).
- **Cadre** : DESIGN-GOV-2026-09-26 §4.2. **Sources** : référentiels de la liste §4.1 tels
  que relevés dans les revues précédentes du dépôt (`UX_REVIEW_AD-X.md`) ; **aucune
  navigation web dans cette session le 09/10**, aucune source n'a été reconsultée ce jour.
  GOV.UK exclu.
- **Limite §4.3** : aucun état serveur ne change. `weekly_availability` stocke toujours des
  heures pleines (`Creneau.jour`, `Creneau.heure`) ; une plage s'enregistre heure par heure
  par `ServicePlanning.poser` / `retirer`. Aucune migration, rien sous `supabase/` (K-19).

| Proposition | Source | Règle utile | Conclusion | Modification | Dérogation |
|---|---|---|---|---|---|
| Une ligne par plage, trois colonnes « Lundi \| de 17 h \| à 23 h » | Gestalt (alignement, proximité) ; Nielsen n°6 (reconnaître plutôt que se rappeler) | Une même information au même bord sur chaque ligne | Conforme | Largeur de colonne mesurée sur la plus longue valeur (jour, puis « de ») : « de » et « à » commencent au même bord sur chaque ligne ; une seule carte à filets (`GroupeReglages`, K-55) | Aucune |
| 320 px ou texte agrandi : la ligne s'empile | WCAG 2.2 1.4.10 (redistribution) et 1.4.4 ; COUPE-MOTS-1 | Pas de défilement horizontal, aucun mot coupé | Ajustée | Au-delà de ×1,3 ou si les trois colonnes ne tiennent pas : « Lundi » puis « de 17 h à 23 h » dessous ; espaces insécables dans « 17 h » | Aucune |
| Les plages se déduisent des heures posées | Contrat serveur (§1 : aucune donnée inventée) | Ne pas changer le stockage | Conforme | Heures consécutives d'un même jour regroupées : 17, 18, …, 22 donnent « de 17 h à 23 h » ; 23 h donne « à minuit » | Pas de 30 min (la fiche DISPO-1 en parlait) : le serveur ne stocke que l'heure pleine ; pas d'1 h, décidé par délégation le 09/10 |
| « Ajouter une plage », seul bouton plein, sous la liste, bord de fin | K-56 ; contrat B (CTA trailing) ; Fitts | Une action pleine par écran, à sa place | Conforme | `ActionPrincipale` pleine largeur sur téléphone, largeur du contenu sur bureau ; non rendu hors ligne (jamais grisé) | Aucune |
| Feuille : jours en puces à choix multiple | Hick ; Baymard (préférer des choix visibles à la saisie) ; K-57 | Choisi plutôt que saisi | Conforme | `FilterPill` × 7, état retenu marqué par la puce elle-même | Aucune |
| Feuille : « de » et « à » dans deux listes, sans clavier | K-57 ; Nielsen n°5 (prévention des erreurs) | Une valeur impossible ne se propose pas | Conforme | `MenuFiltre<int>` ; la liste « à » ne propose que les heures après « de » ; choisir un « de » au-delà de « à » repousse « à » d'une heure | Aucune |
| Raccourcis « Soirée 17 h-23 h », « Matinée 8 h-12 h », « Week-end » | K-58 (tout choix s'explique) ; Hick | Chaque option dit ce qu'elle règle | Conforme | Phrase sous les puces : « Soirée et Matinée règlent les heures. Week-end choisit samedi et dimanche. » Heures de la matinée (8 h-12 h) : décidé par délégation le 09/10 | Aucune |
| Valeur de départ d'un ajout : soirée 17 h-23 h | K-57 (déduit > choisi > saisi) | Préremplir la valeur la plus probable | Ajustée | La plage citée par le directeur ; aucun jour présélectionné (l'enseignant les choisit) | Aucune |
| Chevauchement : fusion dite avant l'envoi | Nielsen n°1 (visibilité de l'état) et n°5 | Annoncer la conséquence avant l'acte | Conforme | « Lundi : cette plage chevauche ou touche une plage déjà posée. Elles seront réunies en une seule, de 17 h à 23 h. » ; seules les heures manquantes partent | Aucune |
| Supprimer une plage qui porte une Classe | ConfirmDestructive (catalogue §6) ; WCAG 3.3.4 | Confirmer un acte qui touche un engagement | Conforme | Confirmation seulement si une heure engagée est retirée (suppression ou modification) ; elle dit que retirer n'annule aucun cours | Une plage libre se supprime sans confirmation (réversible) |
| Conflit avec un élève engagé | WCAG 1.4.1 | Jamais la couleur seule | Conforme | Écrit sur la plage (« Classe déjà engagée sur jeudi 9 h ») et dans la phrase sous la liste | Aucune |
| Échec d'enregistrement, total ou partiel | K-59 ; D5 ; Nielsen n°9 | Dire quoi, pourquoi, quoi faire ; « non confirmé » | Conforme | Échec partiel : les heures non confirmées sont nommées, la feuille reste ouverte, un second envoi ne renvoie qu'elles ; la liste derrière montre ce qui est passé | Aucune |
| La grille `GrilleSemaine` | Directeur 01/10 23:17 | Trop compliquée pour l'enseignant | Retirée de l'écran enseignant | Reste l'écran famille (`TUT-04`, `lib/features/disponibilites`) et la galerie, inchangés | Aucune |

## Fiche d'écran ENS-06 « Disponibilités » (catalogue)

Le dépôt n'a pas de catalogue d'écrans dans `docs/current/` : la fiche tient ici.

- **Route** : `/enseignant/creneaux` (`CreneauxPage`), section `PlagesDisponibilite`
  (`lib/features/creneaux/plages_disponibilite.dart`) et feuille `FeuillePlage`
  (`lib/features/creneaux/feuille_plage.dart`) ; logique pure dans `plages.dart`.
- **États** : chargement (squelette tant que la session, le fuseau ou les heures ne sont pas
  lus) ; contenu (une ligne par plage) ; vide (« Vous n'avez proposé aucune heure… » et le
  bouton) ; erreur de lecture (`EmptyState` + Réessayer) ; hors ligne (liste lisible, lignes
  inertes, bouton non rendu, phrase qui le dit).
- **Champs de la feuille (K-57)** : jours = choisi (puces) ; de = déduit (plage touchée,
  sinon 17 h) puis choisi (liste) ; à = déduit (plage touchée, sinon 23 h) puis choisi
  (liste). Aucun champ saisi.
- **Alimente** : CLASSE-FORM-1 (proposition d'enseignant) et REMPL-1 (filtrage des
  remplacements), qui lisent les mêmes heures pleines.
- **Preuves** : `test/features/creneaux/plages_disponibilite_test.dart`,
  `test/features/creneaux/plages_test.dart` ; captures `docs/current/captures/DISPO-1/`.

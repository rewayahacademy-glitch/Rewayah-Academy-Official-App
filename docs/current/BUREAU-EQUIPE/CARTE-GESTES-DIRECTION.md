# Carte des gestes de la direction sur une candidature d'enseignant (16/11/2026, 20 h UTC)

Demande du directeur (16/11, soir) : « vérifier dans le système ce que l'admin peut vraiment faire avec une
candidature […] le système me donne toujours un bras en moins. » Lu dans `main` (commit `bce83349`) et dans la
base de production (lecture seule). Les deux faits du §0, points 1 et 4, ont été revérifiés en base par le pilote.
**Aucun code n'est écrit avant votre décision sur le §4.**

## 0. Ce qu'il faut savoir d'abord

1. **« Accueillir dans l'équipe » valide la pièce et accepte tout, d'un seul coup.** `valider_piece_candidat`
   approuve elle-même une pièce encore en attente, puis passe la candidature à `confirmee` et active le compte.
   Vous ne pouvez pas valider la pièce et garder des vérifications ouvertes. C'est le « tout est accepté
   automatiquement » que vous avez vu.
2. **Après `confirmee`, il ne reste presque rien** : la pause et le choix du responsable. On ne peut plus demander
   de vérification, refuser ni revenir en arrière.
3. **« Changer un créneau » n'existe pas.** Le seul chemin passe par deux gestes : déclarer l'entretien « annulé »
   (bouton « Autre issue »), puis le replanifier. Le candidat ne peut ni annuler ni déplacer son créneau.
4. **Un complément en cours n'empêche pas d'accueillir** : les contrôles de l'accueil ne le lisent pas.
5. **Deux gestes du serveur n'ont pas d'écran** : la dispense d'entretien (50 dossiers concernés) et
   « Débloquer le versement » (41 dossiers). Les deux écrans sont en cours (DISPENSE-ECRAN chez BE-DOSSIER,
   DEBLOQUER-VERSEMENT-ECRAN chez BE-GESTES).
6. **Cause de fond** : l'écran recalcule lui-même les gestes permis, avec sa propre copie des règles
   (`gestes_proposes.dart`), alors que le serveur les calcule déjà pour chaque ligne (`private.lp_gestes`). Chaque
   nouvelle règle du serveur doit donc être recopiée à la main, et chaque oubli donne un geste manquant ou
   proposé à tort.

## 1. Les états

- **Étape** : `recue` → `invitee` → `prequalification` (Salle d'examen) → `verifications` (Salle de vérification
  et d'entretien) → `confirmee`.
- **État**, en Salle d'examen : `en_examen`, `a_completer`, `paiement_non_disponible`.
- **État**, en Salle de vérification : `entretien_a_planifier`, `entretien_planifie`, `decision_en_attente`.
- **Issue** : `en_cours`, `refusee`, `retiree`.
- **À côté de l'état** : la pause, la restriction et l'indisponibilité (cette dernière seulement en `confirmee`).

Dossiers en cours le 16/11 à 20 h UTC (502 au total, aucun en pause ni restreint) :

| Étape et état | Nombre |
| :--- | --: |
| `en_examen` | 249 |
| `a_completer` | 143 |
| `paiement_non_disponible` | 41 |
| `entretien_a_planifier` | 50 |
| `entretien_planifie` | 0 |
| `decision_en_attente` | 0 |
| `recue` | 16 |
| `confirmee` | 3 (1 enseignant, 2 admissions) |

## 2. Ce que le serveur permet, et ce que l'écran montre

| État | Gestes du serveur (effet réel) | Ce que l'écran montre |
| :--- | :--- | :--- |
| `en_examen` | Demander un complément (→ `a_completer`, candidat prévenu) · Admettre (→ `entretien_a_planifier` ; le courriel « retenu pour un entretien » et une notification partent **automatiquement**) · Confirmer ou écarter le moyen de versement · Débloquer le versement · Refuser · Retrait · Pause · Responsable | Bouton plein : Admettre, ou « Confirmer le moyen » si le versement est à vérifier · Accepter, Demander une précision, Refuser · « Demander une nouvelle pièce » · Menu : écarter le moyen, pause, retrait, responsable. **Pas de « Débloquer le versement ».** La pièce n'est qu'une vignette (on ne la décide que dans la file « Fichiers à valider ») |
| `a_completer` | Rattacher un formulaire · Refuser · Retrait · Pause. **Rien pour modifier, clore ou annuler le complément demandé** | Refuser seulement, plus pause, retrait, responsable |
| `paiement_non_disponible` | Débloquer le versement (→ `a_completer`) · Refuser · Retrait · Pause. **Pas de complément** | Refuser seulement. **« Débloquer » absent** |
| `entretien_a_planifier` | Planifier l'entretien · Dispenser d'entretien (→ `decision_en_attente`) · Demander un complément (pièce, cadre religieux, contrat, avis, pays du versement), **sans changer l'état** · Clore le complément, seulement s'il y en a un · Refuser · Retrait · Pause | Planifier · Accueillir, désactivé avec sa raison · Demander une précision · Ne pas accueillir · Menu : **« Clore le complément » toujours affiché** (le serveur répond « aucun complément » sur les 50 dossiers). **Pas de dispense** |
| `entretien_planifie` | Consigner : tenu (→ `decision_en_attente`) ; annulé, absence du candidat ou de l'intervieweur (→ `entretien_a_planifier`) · Dispenser · Complément · Refuser · Pause | « Autre issue » (annulé, absence) · « Concluant / Non concluant / À refaire » **seulement à partir de l'heure de début** |
| `decision_en_attente` | Accueillir (`valider_piece_candidat`, détail ci-dessous) · Complément · Refuser · Pause. **Aucun retour vers l'entretien** | Bouton plein « Accueillir dans l'équipe » · Demander une précision · Ne pas accueillir · revue de la pièce si elle est encore en attente |
| `confirmee` | Pause · Responsable. Restreindre et noter une indisponibilité existent dans les règles mais sont **fermés** par le serveur, sans fonction publique | Pause, responsable |

**« Accueillir dans l'équipe » (`valider_piece_candidat`), dans l'ordre :**
1. Les contrôles : versement compatible, accords signés, profil renseigné, entretien tenu et favorable (ou dispense),
   évaluation, ni pause ni restriction. **Le complément en cours n'est pas contrôlé.**
2. Prend la pièce la plus récente, en attente **ou** validée ; **une pièce en attente est validée sur-le-champ**.
3. Écrit les langues, le fuseau horaire et les disponibilités dans le profil d'enseignant.
4. Passe la candidature en `confirmee`, puis le compte de `pending_kyc` à `active` ; le courriel de bienvenue part.

**Valider la pièce seule (`decider_dossier`, depuis la file « Fichiers à valider ») :**
- La validation ne fait que valider : le dossier reste où il est.
- Une pièce validée ou refusée **ne se rouvre jamais** (« dossier déjà décidé »).
- Le seul recours est un complément « pièce d'identité ».

## 3. Les trous, un par un

| N° | Trou | Preuve | Dossiers touchés |
| :-: | :--- | :--- | :--- |
| T1 | Accueillir valide la pièce et accepte tout d'un seul coup ; pas de « pièce validée, d'autres vérifications restent à faire » | `valider_piece_candidat` (revérifié en base) | 0 aujourd'hui ; les 50 de la Salle de vérification y arriveront |
| T2 | Une pièce validée ne peut être rouverte que par un complément « pièce d'identité » | `decider_dossier` | 91 dossiers ont déjà une pièce validée |
| T3 | Après `confirmee` : aucune vérification, aucun refus, aucun retour ; restreindre et indisponibilité sont fermés | règles et capacités du serveur | 1 enseignant (CAND-00003) |
| T4 | On peut accueillir pendant qu'un complément attend | `candidature_controles_salle3` ne lit pas le complément (revérifié en base) | 0 aujourd'hui ; les 50 sont exposés |
| T5 | « Clore le complément » affiché à tort | l'écran ne lit pas `complementEnCours` | 50 ; correctif #550 prêt, à remettre à jour (BE-GESTES) |
| T6 | En Salle d'examen, un complément demandé ne peut être ni modifié, ni clos, ni annulé ; seule la personne peut le débloquer | la règle n'existe qu'en Salle de vérification | 52 avec un complément en cours ; 87 « à compléter » sans complément (questionnaire jamais envoyé) |
| T7 | « Paiement non disponible » : ni complément ni « Débloquer » à l'écran | règle et absence d'écran | 41 ; écran en cours (BE-GESTES) |
| T8 | « Changer un créneau » n'existe pas ; le candidat ne peut ni annuler ni déplacer | `consigner_entretien`, `annuler_creneau_entretien` | 0 planifié aujourd'hui ; les 50 y passeront |
| T9 | Aucun retour à l'entretien après « tenu » ou après une dispense | aucune règle depuis `decision_en_attente` | 0 |
| T10 | La dispense d'entretien n'a pas d'écran | aucun appel dans l'application | 50 ; écran prêt mais non poussé (BE-DOSSIER attend votre mot) |
| T11 | Refuser, retirer ou mettre en pause laisse un entretien planifié en place, et une pause interdit ensuite de le consigner | ces gestes ne touchent pas les entretiens | 0 aujourd'hui |
| T12 | Admettre envoie toujours le courriel « retenu pour un entretien » ; pas d'admission en vérification sans entretien | `admettre_salle_verification` | 249 prêts à admettre ; les entretiens sont fermés |
| T13 | La pièce se décide seulement dans la file « Fichiers à valider », pas sur la fiche en Salle d'examen | `piece_vignette.dart` | 216 pièces en attente en Salle d'examen |
| T14 | L'écran ne lit pas les gestes calculés par le serveur ; c'est la cause de T5, de T10 et des prochains écarts | `gestes_proposes.dart` contre `private.lp_gestes` | tous |

## 4. Proposition (à décider par vous)

### 4.1 La logique cible, en un tableau

| État | Gestes cibles de la direction (en plus de : refuser, retrait, pause, responsable) |
| :--- | :--- |
| `en_examen` | Admettre (courriel seulement si un créneau est ouvert, déjà en place depuis ce soir) · Demander un complément · Valider ou refuser la pièce **sur la fiche** · Confirmer, écarter ou débloquer le versement |
| `a_completer` | **Modifier ou annuler le complément demandé** · Rappeler à la personne |
| `paiement_non_disponible` | **Débloquer le versement** · **Demander un complément** (pays ou moyen de versement) |
| `entretien_a_planifier` | Planifier · **Dispenser** · Demander un complément · Clore le complément (seulement s'il y en a un) |
| `entretien_planifie` | **Déplacer le créneau** (un seul geste, la personne est prévenue) · Consigner l'issue · Dispenser |
| `decision_en_attente` | **Valider la pièce** (geste séparé) · **Accueillir** (seulement si la pièce est déjà validée et qu'aucun complément n'attend) · Demander un complément · **Refaire l'entretien** |
| `confirmee` | **Demander une vérification** (pièce, versement) · **Restreindre / lever** · **Noter une indisponibilité / lever** |
| Tout état | Refuser, retirer ou mettre en pause **annule l'entretien planifié** et prévient l'intervieweur |

Règle de fond : **l'écran ne montre que les gestes que le serveur déclare permis pour la ligne** (fin de la copie
des règles dans l'écran).

### 4.2 Les lots, dans l'ordre recommandé

| Ordre | Lot | Contenu | Trous | Taille |
| :-: | :--- | :--- | :--- | :--- |
| 1 | ACCUEIL-SEPARE (serveur puis écran) | « Valider la pièce » devient un geste à part en Salle de vérification ; « Accueillir » refuse une pièce non validée et un complément en cours | T1, T4 | petit ; urgent avant le premier dossier en `decision_en_attente` |
| 2 | GESTES-DU-SERVEUR (écran) | l'écran lit les gestes permis rendus par le serveur pour chaque ligne et supprime sa propre copie | T5, T10, T14 | moyen ; supprime la cause de fond |
| 3 | DEPLACER-ENTRETIEN (serveur puis écran) | un geste « Déplacer le créneau » pour la direction ; la personne prévenue (courriel et notification) | T8 | moyen ; avant la réouverture des entretiens (D-3) |
| 4 | COMPLEMENT-SALLE-EXAMEN | modifier ou annuler un complément en Salle d'examen ; complément permis en « paiement non disponible » | T6, T7 | moyen |
| 5 | ENTRETIEN-SUIT-LE-DOSSIER (serveur) | refuser, retirer ou mettre en pause annule l'entretien planifié, avec rattrapage (0 cas aujourd'hui) | T11 | petit |
| 6 | PIECE-SUR-LA-FICHE (écran) | valider ou refuser la pièce sur la fiche, en Salle d'examen | T13 | petit |
| 7 | APRES-CONFIRMEE (serveur puis écran) | demander une vérification, restreindre, noter une indisponibilité | T3 | moyen ; à décider |
| 8 | REFAIRE-ENTRETIEN | retour de `decision_en_attente` vers `entretien_a_planifier` | T9 | petit ; à décider |

### 4.3 Questions pour vous

- **Q1 (T1).** « Accueillir » doit-il refuser une pièce non validée (la pièce devient une étape à part), ou la
  valider en passant comme aujourd'hui, mais avec un écran qui le dit clairement ?
  Recommandation : la refuser, pour que la pièce soit une étape à part.
- **Q2 (T8).** Le candidat doit-il pouvoir demander lui-même un changement de créneau, ou seulement la direction ?
  Recommandation : la direction d'abord ; le candidat dans un second temps.
- **Q3 (T3).** Après l'accueil, quels gestes voulez-vous ?
  Recommandation : demander une vérification de la pièce ou du versement, et restreindre.
- **Q4 (T12).** Faut-il une admission « sans courriel », ou une admission en vérification sans entretien
  (en plus de la dispense) ?
  Recommandation : non. La dispense suffit, et le courriel dit déjà la vérité depuis ce soir.
- **Q5.** Ces lots passent-ils avant la vague 2, comme le prévoit la passation ?
  Recommandation : oui pour les lots 1 à 3, les autres ensuite.

## 5. Non vérifié

- La comparaison complète des règles entre la production et les fichiers de migration (faite par sondages ; la
  production fait foi).
- La condition exacte du recalcul du versement après un déblocage.
- Comment 43 pièces de la Salle d'examen ont été validées (file « Fichiers à valider » avant novembre, ou autre
  chemin).
- Les déclencheurs de notification qui suivent un refus de pièce.
- Le comportement réel de chaque feuille de geste à l'écran : rien n'a été essayé en production.
- Le cas d'un dossier en `decision_en_attente` dont l'avis d'entretien est défavorable.

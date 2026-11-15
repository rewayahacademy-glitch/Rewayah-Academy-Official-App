# UX_REVIEW ANNONCES-SIMPLES (14/11/2026)

Lot ANNONCES-SIMPLES, demande du directeur du 14/11/2026 : « perfectionner le système d'annonce qui
existe déjà […] le rendre simple, user friendly, mobile first, mais surtout avec une version web
adaptée […] Actuellement celui qui existe demande un formulaire de plus de 5 étapes juste pour écrire
un petit message ; c'est scandaleux. » Arbitrages UX du pilote (consigne 19 : le directeur ne tranche
pas l'UX).

Cette note justifie la disposition (DESIGN-GOV §4). Elle ne change ni permission, ni état serveur
(§4.3) : les publics, leurs nombres, la séparation femmes et hommes (CAND-Q07) et la protection des
mineurs sont calculés par le serveur (migration `20261126700000_annonces_simples.sql`).

## Avant et après (direction, une annonce « à tous les candidats »)

| | Avant | Après |
| :-- | :-- | :-- |
| Écrans | 5 étapes (`PageEtape`) : contenu, destinataires, date, aperçu, publication | 1 écran, puis une confirmation |
| Gestes, envoi immédiat | 9 : titre, texte, Continuer, choisir le public, Continuer, « Dès la confirmation », Continuer, Continuer, Publier | 4 : toucher le public, écrire le message, « Envoyer à N personnes », « Envoyer » dans la confirmation |
| Titre | obligatoire | facultatif (la première ligne sert de titre) |
| Nombre de destinataires | jamais affiché | sous chaque public, puis exact pour la combinaison, dans le bouton et dans la confirmation |
| Publics | 3 (familles, enseignants, toute l'académie) | 9 et leurs combinaisons (voir plus bas) |
| Courriel | absent | option repliée, nombre d'adresses et jours d'envoi sous le plafond |

L'enseignant : 4 étapes avant, 1 écran après (sa Classe, sans choix ; le message ; « Publier dans
Classe X »), 2 gestes.

## Règles et conclusions

| # | Règle | Source | Conclusion | Modification |
| :-: | :-- | :-- | :-- | :-- |
| 1 | Réduire les étapes d'une tâche courte ; le formulaire en une page quand il tient sur une page | Baymard (formulaires) ; Nielsen n° 7 « Flexibilité et efficacité » | Écrire une annonce prend un public, un texte et un bouton : cinq étapes coûtaient quatre allers et retours et cachaient l'aperçu | `publieur_annonce.dart` réécrit sur une page ; `PageEtape` n'est plus employé par le publieur |
| 2 | Mobile d'abord, ordre de lecture = ordre de la tâche | Material 3, *Canonical layouts* ; Apple HIG, *Layout* | Au téléphone : « À qui », le message, les options, le bouton, dans cet ordre, une seule colonne | Colonne bornée à `largeurFormulaire` |
| 3 | Grand écran : contenu et volet d'appui côte à côte (*supporting pane*) ; pas d'onglets ni de menus déroulants de téléphone sur ordinateur | Material 3, *Window size classes* ; consigne 19 | À 1440 : rédaction à gauche, à droite l'aperçu tel que le destinataire le verra et le nombre de personnes | `Row` 3/2 à partir de la classe ordinateur ; captures `-haut` |
| 4 | Un choix proposé passe par `ChoiceCardGroup` ; liste longue en lignes compactes | lib/CLAUDE.md (jetons) ; CANDIDATURE-UX 14/11 | Les publics sont des lignes compactes à choix multiple ; le nombre réel est la légende de chaque ligne (K-58 : la conséquence se lit avant le choix) | `ChoiceCardGroup(selectionMultiple, compacte)` |
| 5 | Visibilité de l'état du système | Nielsen n° 1 | Le nombre exact de la combinaison se recalcule au serveur à chaque choix, se lit sous la liste (région vivante) et dans le bouton « Envoyer à N personnes » | `audienceAnnonceProvider` ; « Calcul du nombre de personnes. » pendant la lecture |
| 6 | Un bouton qui ne peut pas aboutir n'est pas rendu ; une phrase dit pourquoi | lib/CLAUDE.md (pièges payés) ; K-59 | Public vide : pas de bouton, « Personne ne correspond à ce choix… » ; profil sans côté : la phrase dit qui peut le compléter | Branche `vide` du publieur |
| 7 | Divulgation progressive : options rares repliées, fermées par défaut | Nielsen n° 8 ; Apple HIG, *Disclosure* | « Programmer l'envoi » et « Envoyer aussi par courriel » sont deux interrupteurs fermés ; ouverts, ils montrent les trois moments proposés ou le coût du courriel | `CarteLignes` de `SettingRow` + `Switch.adaptive` |
| 8 | Prévenir l'erreur avant un acte qui ne se défait pas | Nielsen n° 5 ; DECISION-FLUIDITE (attente animée pour le sensible seulement) | L'envoi n'est ni argent, ni compte, ni suppression : pas de `ConfirmDestructive`. Une confirmation simple répète publics, nombre, date et courriel | `confirmation_envoi_annonce.dart` (feuille au téléphone, boîte sur ordinateur) |
| 9 | Un seul bouton plein par écran, au bas du formulaire, au bord de fin ; pleine largeur au téléphone seulement | K-56 ; DESIGN-GOV contrat B | Vérifié par `verifierUnSeulBoutonPlein` à 390 et 1440, fr et ar, clair et sombre | `admin_publieur_test.dart`, `annonces_simples_test.dart` |
| 10 | Raccourci clavier pour l'expert | Nielsen n° 7 ; R-25 | Ctrl+Entrée envoie depuis un champ ; Entrée garde le saut de ligne | `raccourciEnvoi` gardé |
| 11 | Mesurer ce qui est envoyé | VISION-ECOLE (« une donnée saisie doit servir ») | Chaque annonce publiée dit « Vue par X sur N » sur la page des communications | `annonces_planifiees.dart`, `com_annonces_direction` |
| 12 | Le destinataire lit l'annonce là où il est déjà | Nielsen n° 4 « Cohérence » | Fil « Annonces de l'académie » en tête des notifications (adultes) et du portail candidat (`/attente`, compte en attente sans cloche) ; une annonce montrée est comptée vue | `annonces_recues.dart` |

## Écarts et limites

- Les cartes compactes de `ChoiceCardGroup` mesurent environ 76 points avec leur légende : neuf
  publics font une liste longue à 1440. Le composant partagé n'est pas retouché dans ce lot.
- La notification sous la cloche attend l'élargissement de la contrainte
  `notifications_evenement_check` (fichier à mot d'effacement, hors de la règle « aucun DROP » de ce
  lot) : `docs/current/annonces-simples/A-DECIDER-20261126700100_annonce_direction_evenement.sql`.
  Sans lui, l'annonce arrive dans le fil et, si demandé, par courriel.
- La direction ne vise plus une Classe précise depuis ce publieur (les publics de la décision ne la
  nomment pas) ; l'enseignant garde sa Classe.

## Ce qui n'est pas prouvé

- Rien n'a été vu par le directeur en production ; la migration n'est pas installée.
- Testé localement : scénario SQL `scenarios_annonces_simples.sql` (Postgres 16 neuf, toutes les
  migrations), tests Flutter ciblés, captures `docs/current/captures/E2E/annonces-simples/`.

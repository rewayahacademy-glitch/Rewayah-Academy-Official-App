# Communications V1, décisions du directeur en attente après COM-FUS (5 octobre 2026)

COM-FUS ne tranche aucune de ces questions. Le code fusionné sur `ui/communications-v1`
garde l'état décrit dans « État actuel ». Chaque décision liste ses options, et
l'option sans changement de code est toujours indiquée.

## D-FUS-1. Clés arabes `com.*` contre les règles 4 et 5 de `02_DECOUPAGE`

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : option 1 (garder l'arabe ; les dates suivent la langue choisie). `02_DECOUPAGE.md` règles 4 et 5, l.53, l.78, l.161 amendés le 05/10. Question R-08 (dates) : réponse a, même décision.

- **Conflit** : les règles 4 et 5 (et les lignes 53, 78, 161 de `02_DECOUPAGE.md`) disent
  que `ar.i18n.json` ne reçoit aucune clé `com` et qu'il est gelé après COM-F. Les
  consignes de chaque étape demandaient pourtant l'i18n fr ET ar. COM-F, COM-F-b et les
  cinq voies (msg, voc, commu, stu, ann) ont toutes ajouté leurs clés arabes.
- **État actuel** : toutes les clés `com.*` existent en fr et en ar, à parité (slang).
- **Options** :
  1. garder l'arabe : amender les règles 4 et 5 et les lignes 53, 78, 161 de
     `02_DECOUPAGE.md` (aucun changement de code) ;
  2. retirer toutes les clés `com.*` de `ar.i18n.json` d'un bloc, avec repli sur le
     français (un commit, slang régénéré ; l'interface arabe affichera du français dans
     les Communications).

## D-FUS-2. Texte d'échec du signalement (§5.2) contre K-59 et D5

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : option 1 (garder les textes actuels, corriger la spec §5.2). Amendement écrit dans `V/REWAYAH_COMMUNICATIONS_FRONTEND_V1.md` §5.2 (note datée) et ci-dessous, « Amendement de la spec §5.2 ».

- **Conflit** : la spec §5.2 impose « Le signalement n'a pas pu être envoyé. Réessayez. »
  et « Le contenu a été signalé à l'équipe de modération. ». K-59 et D5 interdisent
  d'affirmer un échec réseau que l'app ne peut pas prouver (« non confirmé, jamais non
  envoyé »), et `verifier_revue` (règle `affirmation-reseau`) le refuse.
- **État actuel** : le socle dit « Le signalement n'a pas encore été confirmé. Réessayez
  dans un instant. » et « Le contenu a été signalé. Il sera examiné. » ; la page
  Communauté dit « Vous avez signalé cette publication. L'équipe de modération va
  l'examiner. ».
- **Options** :
  1. amender la spec §5.2 pour suivre K-59 (aucun changement de code) ;
  2. admettre une exception datée à `verifier_revue` et reprendre le texte exact de la
     spec (`com.socle.signalement.erreur` et `.confirme`) ;
  3. seulement aligner le texte de confirmation sur « … à l'équipe de modération. »
     (sans toucher au texte d'échec).

## D-FUS-3. Bandeau hors ligne générique sur les pages Communications

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : option 1 (masquer le bandeau générique sur les pages Communications ; les autres écrans ne changent pas). Question R-03 : réponse a, même décision.

- **Conflit** : sur Messages (et les autres pages COM), le bandeau générique de
  `PageShell` (`OfflineBanner`, clé partagée `reseau.horsLigne`, « … l'envoi attendra »)
  s'affiche en plus du bandeau des Communications. Le texte générique promet une file
  d'envoi qui n'existe pas pour les messages.
- **État actuel** : les deux bandeaux s'affichent ; un commentaire le signale dans
  `messages_page.dart`.
- **Options** :
  1. masquer le bandeau générique sur les pages COM (paramètre de `PageShell`, socle) ;
  2. changer le texte de `reseau.horsLigne` pour tous les écrans (ne plus promettre la
     file d'envoi) ;
  3. garder les deux (aucun changement).

## D-FUS-4. Domaine actif de `/admin/notifications`

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : option 1 (acter `domaine: null` ; `02_DECOUPAGE.md` l.86 corrigé le 05/10).

- **Conflit** : `02_DECOUPAGE` §COM-F (compléments COM-0b, l.86) demande
  `AdminDomaine.accueil` ; COM-F-Q5 (8043c6ae, captures 6916b0ea) a choisi
  `domaine: null`, la cloche étant la seule entrée active.
- **État actuel** : `domaine: null` (`app_router.dart`), testé.
- **Options** :
  1. acter `domaine: null` en corrigeant `02_DECOUPAGE` l.86 (aucun changement de code) ;
  2. passer `AdminDomaine.accueil` (une ligne du routeur et le test associé).

## D-FUS-5. Historique : fusion anticipée de `ui/com-commu` dans `ui/com-ann` (6c69e0cb)

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : option 1 (fusion anticipée admise, aucune réécriture d'historique).

- **Constat** : COM-ANN-2 a fusionné `ui/com-commu` avant la fusion COM-FUS. COM-FUS a
  ensuite fusionné les deux branches dans `ui/communications-v1` ; la fusion anticipée
  est donc dans l'historique de la branche cible.
- **Options** :
  1. admettre explicitement cette fusion anticipée (aucun changement) ;
  2. reconstruire `ui/com-ann` (push forcé, feu vert explicite requis). Après COM-FUS,
     cela ne changerait plus `ui/communications-v1` sans réécrire aussi son historique.

## D-FUS-6. Capacité vocale `envoyerVocal` (ajoutée à COM-FUS)

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : option 1 (`envoyerVocal` validée ; inscrite dans la ligne COM-BR-16 de `COM-BR.md` le 05/10).

- **Constat** : pour que le composer vocal ne soit rendu qu'avec une capacité, COM-FUS a
  ajouté `CapaciteCommunication.envoyerVocal` (six capacités au lieu de cinq) et
  `PortEnvoiVocal` (neutre, COM-BR-03).
- **Options** :
  1. valider et inscrire `envoyerVocal` dans la ligne COM-BR-16 de `COM-BR.md` ;
  2. porter le vocal par la capacité `ecrireDansFil` seule (le composer apparaîtrait dès
     que l'écriture est ouverte et que l'enregistreur répond).

## D-FUS-7. Capacités de la Communauté et du Studio

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : option 1 (forme b : capacités portées par les objets ; inscrite dans la ligne COM-BR-16 de `COM-BR.md` le 05/10).

- **Constat** : la Communauté garde `CapacitesCommunaute` (`peutPublier`, `peutRepondre`,
  servies par `PortCommunaute`) et le Studio `CapaciteCanal` (par canal), à côté du port
  global `capacitesCommunicationProvider` (COM-BR-16).
- **Options** :
  1. garder les capacités portées par les objets (forme b de COM-BR-16, aucun changement) ;
  2. ajouter `publierCommunaute` au socle et rattacher `peutRepondre` à `ecrireDansFil`.

## D-FUS-8. Choix produit et libellés proposés par les agents

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : avertissement « potentiellement commercial » : **bloquer**, comme aujourd'hui (pas de « Publier quand même ») ; programmation : **garder les trois créneaux** ; libellés `com.*` : **pas de page de validation** : les sessions les valident par relecture croisée (vocabulaire de `docs/current`, K-59, pas de jargon) et marquent « validé par délégation le 05/10 » (relecture : `LIBELLES_COM_RELECTURE.md`). Correction déjà décidée : `com.communaute.garde.reponse.avertissement` devient « Cette réponse semble contenir une promotion commerciale. Retirez le lien, le code ou l'offre avant de l'envoyer. » ; `com.communaute.garde.reponse.consigneBlocage` et `com.communaute.reponses.refusee` sont bons. Colonne « Validation requise » : non tranchée, reste à COM-BR-11.

- Avertissement « potentiellement commercial » : il retient la publication comme un
  blocage (pas de « Publier quand même ») ; à confirmer ou à remplacer par un
  « Publier quand même ».
- Programmation d'une annonce : trois créneaux proposés (demain 8:00, demain 18:00,
  lundi suivant 8:00) au lieu d'un sélecteur de date ; aucun ordonnanceur serveur
  (BR-1, COM-BR-10).
- Colonne « Validation requise » de la matrice : « Non » partout en démonstration ; la
  valeur réelle relève de COM-BR-11.
- Libellés `com.*` marqués « proposé par un agent » dans `tool/libelles_sources.json`
  (toutes les voies) : à valider.

## D-FUS-9. Fichiers gelés que la suite demande d'ouvrir

- **Décision du 05/10, prise par délégation du directeur** (source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : icônes : **autoriser l'ajout** de « signet », « épingle », « lien » dans `app_icons.dart` ; UX_REVIEW : **les écrire avant la recette humaine** (écrits le 05/10 : `UX_REVIEW_COM-STU-1.md`, `UX_REVIEW_COM-STU-2.md`, `UX_REVIEW_COM-STU-3.md`).

- Icônes dédiées « signet », « épingle », « lien » absentes de `lib/core/icons/app_icons.dart`
  (gelé) : les voies utilisent des icônes de repli. Options : autoriser l'ajout des trois
  icônes, ou garder les replis.
- `UX_REVIEW_<lot>.md` (DESIGN-GOV §4) non écrits pour COM-STU-1, COM-STU-2 et COM-STU-3,
  dont les dispositions sont des PROPOSITIONS : à écrire avant HU-1, ou à dispenser.

## Réponses du 05/10 aux questions de la revue COM-R (par délégation du directeur)

Source : artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW. Décisions prises par délégation le 05/10/2026 ; l'artefact reste ouvert au directeur pour les corriger.

| Question | Sujet | Réponse | Effet |
|---|---|---|---|
| R-03 (D-FUS-3) | Double bandeau hors ligne | a : masquer le bandeau générique sur les pages Communications | correction de code à faire (paramètre de `PageShell`) |
| R-08 (D-FUS-1) | Arabe et dates | a : garder l'arabe, traduire les dates | correction de code à faire (dates selon la langue, bidi) |
| R-12 | Actions compactes centrées | a : corriger le composant commun (`ActionPrincipale`), captures de tous les écrans concernés vérifiées | correction de code à faire |
| R-16 | Annonce ou séance en tête (Classe du tuteur) | a : la séance en tête quand elle est ouverte ou proche ; l'annonce en haut le reste du temps | correction de code à faire |
| R-19 | Cinquième règle de la Communauté | a : la garder (« Aucune donnée personnelle d'un élève ou d'une famille ») | aucun changement |
| R-27 | Raccourci « Communauté enseignants » sans service | a : le cacher tant que la Communauté n'est pas ouverte | correction de code à faire |
| COM-R-3, constat 5 | Focus à 320, texte ×2 | a : zone d'écriture réduite à une ligne en Focus, qui s'agrandit quand on écrit | correction de code à faire |
| R-28 (vocal) | Ouverture du message vocal | a : un bouton micro à côté d'« Envoyer » | correction de code à faire |
| COM-RC (tour 5) | Huit défauts mineurs restants | a : un tour court de correction | étape à ouvrir |

## Amendement de la spec §5.2 (signalement), 05/10

La spec du directeur (`V/REWAYAH_COMMUNICATIONS_FRONTEND_V1.md` §5.2) est dans ce dossier de pilotage ; elle est amendée sur place (note datée sous le tableau). Aucune copie de cette spec n'existe dans `docs/current` (recherche `git grep` du 05/10 sur `origin/ui/communications-v1` et `origin/main` : aucun résultat). Textes retenus (K-59, D5 : « non confirmé », jamais « non envoyé ») :

- « Publication signalée » : « Le contenu a été signalé. Il sera examiné. » (`com.socle.signalement.confirme`), seulement après l'accusé du serveur ; la page Communauté garde « Vous avez signalé cette publication. L'équipe de modération va l'examiner. » ;
- « Modération indisponible » / envoi non confirmé : « Le signalement n'a pas encore été confirmé. Réessayez dans un instant. » (`com.socle.signalement.erreur`) ; service absent : « Le signalement n'est pas encore disponible ici. » (`com.socle.signalement.indisponible`).


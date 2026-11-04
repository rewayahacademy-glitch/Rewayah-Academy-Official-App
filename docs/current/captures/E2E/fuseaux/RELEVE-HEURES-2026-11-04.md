# FUSEAUX : où l'application affiche une heure, et d'où elle vient (relevé du 04/11/2026)

Fiche du garde-cap, PLAN-LOTS §12 : « Le relevé d'abord : la liste de chaque écran qui affiche une heure, avec sa source actuelle. »

Branche `claude/fuseaux-client`. Avant le lot : `main` c0f36a01. Les lignes « avant » ont été relevées dans le code, ligne par ligne.

## Les sources

- **Appareil** : `DateTime.toLocal()`, `DateTime.now()` ou `heureDeLAppareil` sur une date locale.
- **Serveur, sa propre heure** : `horloge_seance` / `horloge_classe` (`SessionClockVM.horlogeUtilisateur`), `mon_fuseau`.
- **Classe** : le fuseau de la classe (`groupes.timezone_iana`, `horlogeContrepartie`).
- **Profil (nouveau)** : `public.mon_horloge()` (migration 20261109900000), qui donne le fuseau du profil de la personne avec son décalage et ses changements d'heure. Il est lu par `monHorlogeProvider` et appliqué par `chezMoi` / `heureChezMoi`.
- **Interlocuteurs (nouveau)** : `public.horloge_interlocuteurs(classe)` (20261109500000 et 20261109900000). Il est lu par `interlocuteursClasseProvider`, une lecture par classe, et affiché par `HeureDouble` / `HeureCouranteDouble`.

## Écrans corrigés par ce lot

| Écran | Fichier | Qui | Avant | Après |
| :--- | :--- | :--- | :--- | :--- |
| Carte de séance (Espace Classe, fiche classe) | `tc_espace_groupe/carte_session.dart` | élève, tuteur, enseignant, direction | « Votre heure » (serveur), puis « Chez Sayyid X » posé sur l'heure de la **classe** : c'était le défaut central | `HeureDouble` : « Chez vous », puis l'enseignant **chez lui** (titre enregistré, drapeau) pour la famille, ou le nombre de familles par fuseau pour l'enseignant. Sans lecture : « Heure de la classe », sous ce nom. Puis « En ce moment », une heure qui avance à la minute |
| Mes classes, prochaine séance | `tc_mes_groupes/carte_groupe.dart` | tous | une seule heure (serveur) ; « Demain à » à l'heure de l'appareil, juste dessous | `HeureDouble` ; « Demain à » à l'heure rendue par le serveur |
| Accueil famille, Classe du tuteur (bloc séance) | `accueil_famille/bloc_seance.dart` | tuteur | heure du foyer, puis « Heure de la classe » | heure du foyer, puis l'enseignant chez lui (`HeureDouble` sans sa propre ligne) ; sans lecture, l'heure de la classe |
| Accueil élève, compte à rebours | `accueil_eleve/accueil_eleve_page.dart:484` | élève | appareil | profil (`chezMoi`) |
| Ma journée (enseignant) | `journee/journee_page.dart` | enseignant | appareil, « aucune mention de fuseau » | profil ; sans fuseau de profil, le sous-titre dit « Heure de cet appareil » |
| Mes classes (enseignant) | `enseignant_classes/mes_classes_page.dart:320` | enseignant | appareil | profil (jour et heure) ; la différence d'instants reste sur les vrais instants |
| Salle, reprise après la pause | `salle_seance/chrono_salle.dart` | enseignant, élève | appareil | profil |
| Notifications : regroupement par jour, ligne, phrase lue | `notifications/notifications_page.dart` (3 endroits) | tous | appareil | profil |
| « La salle ouvre à » sans heure du foyer | `classe_tuteur/rejoindre_avec_eleve.dart` | tuteur | appareil | profil, sinon appareil |
| Accueil adulte, séances passées | `accueil_adulte/accueil_adulte_page.dart` | élève adulte | date du serveur, heures de l'appareil, sur la même ligne | heures du profil, comme la date |
| Ville des cartes de séance | `core/tc_horloge/horloge_supabase.dart` | tous | `villeDeFuseau`, non traduite | `villeDuFuseauLibelle`, le seul helper traduit. `villeDeFuseau` est retiré |

`service_planning.dart:164` (`Seance._instant`) garde de vrais instants, parce que les comparaisons et les comptes à rebours en ont besoin. Seul l'affichage passe par `chezMoi`.

## Écrans non traités par ce lot (heure de l'appareil, une seule personne)

Ils ne figurent pas dans la liste de la fiche. Le garde-cap a exclu tout autre remaniement. Ils restent à l'heure de l'appareil :

- **Suivi de l'élève** (`suivi_eleve_page.dart:280, 302`), après la séance en Interface guidée (`apres_seance_accessibilite.dart:157`), pause prière de l'accueil élève (`accueil_eleve_page.dart:827`).
- **Historique du foyer** : détail de séance et observations (`suivi_foyer/*`). Cahier de transmission (`cahier_page.dart:1559`), absence et remplacement (`absence_remplacement_vue.dart:383`), salle « depuis la salle » (`depuis_salle.dart:250`).
- **Messages et annonces** : messages, annonces, studio, communauté. Appareils de l'élève, mouvements du foyer, contrôleur, entretien de candidature.
- **Écrans de direction et journaux** (observations, alertes, journal, tableau, planning, courriels, tirage, fusion, candidatures, dossiers, reprises).
- **Catalogue des classes** (`catalogue_classes_page.dart:463`) : affiche l'identifiant IANA brut (« Asia/Riyadh »). C'est un défaut de libellé, relevé ici mais hors lot.
- **E-mails** : hors lot (COURRIELS-UX).

Écrans déjà justes, inchangés : offres, suivi des demandes et suivi famille (heure murale du foyer, refusent l'UTC), regroupements, pilotage, offres de la direction (heure de la classe avec sa ville), étape fuseau de la candidature (volontairement l'appareil).

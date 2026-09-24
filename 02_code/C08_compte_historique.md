# C08 - Compte, historique, notifications, support, paiements, préférences, légal

Cartographie en lecture seule, 24/09/2026. Dépôt `D:\RA _APP\RA -OFFICIAL-APP`, branche
`c0/configuration-baseline-2026-09-23` (HEAD `3cf3544`). Dans le périmètre `lib/`, cette branche ne
diffère de `main` que par des chemins de documentation dans des commentaires (`git diff --stat
main..HEAD -- lib` : 114 fichiers, 236/247 lignes, toutes des chemins `docs/archive/...`) : les
numéros de ligne ci-dessous valent donc pour `main`.

Méthode : lecture du code, des migrations et des branches par `git show` / `git diff`. **Aucun test,
aucune analyse, aucun build n'a été lancé** ; la base de production n'a pas été interrogée. Tout
ce qui dépend d'une mesure en base est marqué `INCONNU`. Légende des statuts : `présent` (code
existant), `branché` (appelle un service réel), `testé localement` (un test existe, non rejoué ici),
`dépendance backend`.

---

## 0. Ce qu'il faut retenir

1. **Le tuteur n'a pas de destination Compte ni Historique** : sa barre compte Accueil,
   Disponibilités, Réglages, Suivi (`lib/core/widgets/nav_shell.dart:79-100`, figé par
   `test/router/navigation_test.dart:24-29`). « Mon compte » n'est qu'une entrée secondaire du rail
   et du tiroir, rendue seulement à partir de 600 px (`nav_shell.dart:160-168`, `:269-274`). **Sous
   600 px, aucun chemin ne mène à `/compte`, donc à « Se déconnecter »** : l'onglet Réglages pousse
   `/compte/profil`, `/compte/profils`, `/compte/reglages` (`lib/features/reglages_enfant/reglages_enfant_page.dart:59-76`)
   mais jamais `/compte`, seul écran qui porte la déconnexion (`lib/features/compte/compte_page.dart:103-109`).
2. **L'historique des séances existe déjà** sous le nom « Suivi du foyer » (`TUT-06`,
   `lib/features/suivi_foyer/suivi_foyer_page.dart`), branché sur `mes_seances_v` et
   `presence_seance_v` (`lib/core/suivi/service_suivi.dart:56-87`), avec une vue pure testée
   (`lib/features/suivi_foyer/vue_suivi_foyer.dart`). Il faut le **renommer et l'étendre**, pas en
   créer un second. Il lui manque : classe, filtres période/statut, détail de séance, fuseau affiché.
3. **La page Réglages du compte est un faux écran** : ses 9 contrôles écrivent dans un état en
   mémoire que rien ne lit. Le thème n'est pas consommé (`lib/app.dart:32,50`), la réduction
   d'animations suit le système seulement (`lib/core/theme/app_mouvement.dart:122`), les
   notifications n'existent pas. Le texte affirme pourtant « Ces préférences restent sur cet appareil
   et s'appliquent tout de suite » (`assets/i18n/fr.i18n.json:1124`).
4. **Paiements, factures, reçus, moyen de paiement, aide/contact, FAQ, notifications, documents
   légaux complets : aucune source** côté client ni côté base (§8 à §11). Seules données réelles :
   la date de fin d'accès par élève (`profiles.access_until`) et les acceptations signées
   (`contract_acceptances`).
5. **Le journal persistant des observations existe** (`guardian_session_visit`,
   `supabase/migrations/0032_tc_catalogue.sql:449-492`, appliqué en production d'après
   `docs/current/CONFIGURATION_BASELINE_2026-09-23.md:122`), mais : aucune lecture transversale
   (seulement `visites_observation(p_session_id)`, une séance à la fois, `0033_tc_vues_rpc.sql:1235-1257`),
   **motif de fin toujours `sortie_volontaire`** côté serveur quel que soit le motif réel
   (`observation/lot-2026-09-21:supabase/migrations/0039_...sql:344-346`), et **aucune fermeture
   serveur** des visites non quittées. La méthode Dart `PortVisiteObservation.visites()` n'a aucun
   appelant dans `lib/`.
6. **Risque de fuite à ne pas consommer** : `lesson_reports` est lisible par tout foyer dont un
   membre participe à la séance (`0001_fondations.sql:1070-1078`), or `content` contient les
   décisions de **tous** les élèves du groupe (`lib/core/enseignant/modeles_enseignant.dart:631-676`).
   Le « résumé destiné à la famille » du détail de séance ne doit pas être lu dans cette table.
7. **Côté admin**, la sidebar est gelée à huit domaines (`lib/core/admin/admin_domaine.dart:5-11,106-128`) :
   l'entrée « Historique » de la maquette admin ne peut pas devenir un neuvième domaine. Point
   d'ancrage proposé : Sécurité et audit, en fonction paire du Journal (§12).

---

## 1. Navigation actuelle du tuteur et cible

| Élément | Code actuel | Constat |
|---|---|---|
| Destinations | `nav_shell.dart:79-100` : Accueil (`/tuteur`), Disponibilités (`/tuteur/disponibilites`), Réglages (`/tuteur/reglages`), Suivi (`/tuteur/suivi`) | Aucune ne correspond à Foyer, Historique, Compte. Clés `nav.tuteur.foyer` existante (`fr.i18n.json`, bloc `nav.tuteur`) mais utilisée seulement par la galerie (`lib/features/_dev/galerie/catalogue_galerie.dart:198`) |
| Branches du shell | `lib/core/router/app_router.dart:236-277` (4 `StatefulShellBranch`) | `/tuteur/foyer`, ajout d'enfant, appairage, parcours sont hors coquille (`app_router.dart:278-298`) |
| Entrée Compte | `secondairesPour` : « Mon compte » avec l'icône `AppIcons.sortie` (`nav_shell.dart:162-168`) | Icône de sortie pour une entrée de compte ; invisible sous 600 (`nav_shell.dart:269-274`) |
| Compte rendu | `_CoquilleSecondaire` (`app_router.dart:727-775`) | Sous 600 et `indexActif` nul, la barre basse est omise (`nav_shell.dart:304`) : retour par le bouton précédent seulement |
| Test qui fige | `test/router/navigation_test.dart:24-29` | Toute nouvelle barre tuteur casse ce test : fichier du coordinateur |

**Cible du mandat** : Accueil · Foyer · Historique · Compte (`REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md:58`).
Les maquettes mobile et desktop « Mon compte » montrent exactement ces quatre onglets
(`tutuor image/mobile/mon compte tuteur mobile light mode.png`, `mon compte tuteur desktop light mode.png`).

**Avis sur « Historique » en quatrième destination (question du directeur).** Je le garde. Raisons
vérifiées dans le code : l'écran existe déjà et occupe déjà une destination (« Suivi »), il est
branché et testé, et la maquette « Observation et historique » y ajoute l'onglet Observations,
exigé par le mandat (§8 du complément). Les autres candidats ne tiennent pas la place : les
Notifications n'ont aucune source (§7), elles vont en icône d'en-tête comme sur la maquette
historique ; la Classe s'atteint depuis l'Accueil ; Disponibilités et Réglages enfant sont des
réglages par élève qui relèvent de la fiche élève (Foyer). Ce qui sort de la barre doit rester
accessible (Disponibilités depuis la fiche élève ou le parcours, Réglages enfant depuis Foyer) : à
arbitrer avec les propriétaires Foyer et Cours.

**Mapping des routes (proposition, décision au coordinateur, propriétaire du routeur).**

| Route logique du mandat | Existant | Proposition |
|---|---|---|
| `/tuteur/historique` | `/tuteur/suivi` (`routes.dart:103-104`) | Nouvelle branche `/tuteur/historique` ; `/tuteur/suivi` devient une redirection (mandat §4 : alias plutôt que route concurrente) |
| `/tuteur/seances/:seanceId` | absent | Route sous `/tuteur`, donc autorisée par `redirection.dart:114-115` ; la RLS de `mes_seances_v` borne la donnée |
| `/tuteur/compte` et sous-pages | `/compte`, `/compte/profil`, `/compte/reglages`, `/compte/profils`, `/compte/profils/:id` (`routes.dart:291-307`, `app_router.dart:159-186`), partagés par tous les rôles (`redirection.dart:98-102`) | `/compte/*` sert aussi l'enseignant (`profil_enseignant_page.dart:597,603`) et le contrôleur (`planning_page.dart:172`). Pour qu'il devienne un onglet du tuteur, il faut une branche du shell tuteur : soit `/tuteur/compte` avec redirection de `/compte*` pour le seul rôle tuteur, soit une branche dont la route est `/compte` pour le tuteur. Le premier évite de toucher les autres rôles |
| `/tuteur/notifications` | absent | Route sous `/tuteur`, écran « indisponible » honnête (§7) |
| Route inconnue sous `/tuteur/...` | aucun `errorBuilder` dans `app_router.dart` (recherche `errorBuilder` : aucun résultat dans le routeur) | Une URL `/tuteur/xyz` passe la redirection (préfixe du rôle) et tombe sur l'écran d'erreur par défaut de go_router. Hors C08, à signaler au C01 |

---

## 2. Écran Compte actuel : ce qu'il fait, ce qu'il prétend

Fichier unique `lib/features/compte/compte_page.dart` (756 lignes), cinq écrans, aucun service propre.
Source de toutes les données personnelles : `SessionState` (`lib/core/session/session_state.dart:64-113`),
qui ne porte ni nom, ni courriel, ni méthode de connexion. La lecture de profil ne demande que
`account_status` et `interface_mode` (`lib/core/session/source_session.dart:79-83`).

### 2.1 `ComptePage` (`compte_page.dart:30-114`)

| Élément | Ce que le code fait | Écart |
|---|---|---|
| En-tête | `AvatarTile(prenom: projection.libelleRole)` (`:472-475`) : les initiales du mot « Tuteur », puis le libellé du rôle, le statut, et **l'UUID du profil en clair** (`:487-490`) | Pas d'identité du titulaire ; identifiant technique exposé (jargon interne, mandat §9) |
| Résumé | `t.compte.roleDetail.guardian` « Suit le foyer et ses enfants » (`:640-642`) | Décoratif |
| Profil | → `/compte/profil` (`:55-60`) | voir 2.2 |
| Réglages | → `/compte/reglages` (`:61-66`) | voir 2.3 (faux écran) |
| Profils du foyer | tuteur seulement → `/compte/profils` (`:67-73`) | doublon du futur Foyer |
| Foyer | → `/tuteur/foyer` (`:74-82`), grisé pour les autres rôles | raccourci réel, conforme au mandat (« le raccourci Foyer mène au Foyer existant ») |
| Confidentialité | `enabled: false`, « Bientôt disponible » (`:83-88`, `fr.i18n.json:1107`) | Promesse sans service |
| Espaces | une ligne inerte par rôle, valeur « Habilité » (`:89-101`) | Décoratif ; le commentaire `:703-705` interdit à juste titre de déduire un cumul de rôles |
| Se déconnecter | `serviceAuthProvider.deconnexion()` sans confirmation (`:103-109`) | Pas de `ConfirmDestructive` (l'enseignant en a une, `profil_enseignant_page.dart:615-643`). En démonstration, `SessionControleur.fermerDemo()` n'est jamais appelée (`session_controleur.dart:94-101`, aucun appelant dans `lib/`) : la déconnexion ne ferme pas une session démo |

### 2.2 `ProfilPersonnelPage` (`compte_page.dart:117-187`)

Lignes en lecture seule : Identifiant = UUID (`:138-142`) ; Contact = « Non disponible · Géré par
l'académie » (`:143-148`) ; Langue = « Français » (`:149-153`) ; **Fuseau = « Non disponible »**
(`:154-158`) alors que `monFuseauProvider` existe et lit `mon_fuseau()` (`lib/core/planning/service_planning.dart:257-260,325-327`)
et que le tuteur peut lire `households.timezone` (policy `households_guardian_select`,
`0001_fondations.sql:700-701`). Nuance : `mon_fuseau()` retombe sur `Europe/Paris` côté serveur
(`0005_dashboards_affectation_regles.sql:411-417`) et côté client (`service_planning.dart:259`) :
on ne peut pas distinguer un fuseau choisi d'un défaut.

### 2.3 `ReglagesComptePage` (`compte_page.dart:190-358`)

| Contrôle | Stockage | Consommateur réel |
|---|---|---|
| Thème Système/Clair/Sombre (`:214-247`) | `PreferencesLocales` en mémoire (`lib/core/preferences/preferences_locales.dart:18-22,77-114`) | **Aucun** : `RewayahApp` prend `themeMode` en paramètre constant, défaut `ThemeMode.system` (`lib/app.dart:32,50`), `main.dart:68,107,130` ne le passe pas |
| Réduire les animations (`:250-258`) | mémoire | **Aucun** : `AppMouvement` lit `MediaQuery.disableAnimationsOf` (`app_mouvement.dart:122`) |
| Réduire les effets (`:259-267`) | mémoire | **Aucun** |
| Français actif / Arabe « Bientôt disponible » / Fuseau « Non disponible » (`:276-297`) | inerte | `assets/i18n/ar.i18n.json` existe (32 lignes, `AppLocale.ar` généré, `lib/core/i18n/strings.g.dart:30`) : presque vide, repli sur le français |
| Notifications Cours / Foyer (`:299-318`) | mémoire | **Aucun** système de notification (§7) |
| Économie de données, Lecture en grand (`:320-338`) | mémoire | **Aucun** (recherche `economieDonnees`, `lectureGrande` : seulement cette page) |
| Foyer, Confidentialité (`:340-354`) | doublons de `ComptePage` | |

Aucune persistance : pas de `shared_preferences` dans `pubspec.yaml`, le modèle le reconnaît
(`preferences_locales.dart:20-22`). Le test `test/features/compte_test.dart:28-54` vérifie seulement
que le notifier change d'état, pas que le thème s'applique. Conclusion : **UI réalisée, branchée à
rien**. À la reprise, chaque contrôle doit soit être câblé (thème : `ref.watch(preferencesLocalesProvider)`
dans `app.dart`, fichier du coordinateur ; persistance locale à choisir), soit disparaître au profit
d'une phrase qui dit la limite (`lib/CLAUDE.md` : « un bouton qui ne peut pas aboutir n'est pas rendu »).

### 2.4 `ProfilsComptePage` et `ProfilEnfantPage` (`compte_page.dart:362-460, 558-622`)

Branchés sur `elevesDuFoyerProvider` (`profils_du_foyer_v`, `lib/core/appairage/service_appairage.dart:89-138,202`),
avec chargement, erreur, vide (`:375-409`), testés (`compte_test.dart:108-223`). Défauts :
- libellé « Mode enfant » (`:546-548,590-593`, `fr.i18n.json:1161`) : terme banni, cible
  « Interface guidée » (mandat §9, `CLAUDE.md` racine) ;
- titre de `ProfilEnfantPage` = `t.compte.profilEnfant(prenom: t.compte.nonDisponible)` (`:429`) :
  s'affiche « Profil de Non disponible » même quand l'enfant est trouvé ;
- identifiant immuable affiché comme contenu principal (`:540-543,584-588`).
Ces deux écrans relèvent de la fiche élève (lot Foyer) : à rediriger vers elle, pas à reconduire
dans le Compte.

---

## 3. Sous-pages cibles du Compte : existant, source, statut

| Rubrique (mandat §4 et §5) | Donnée réelle disponible | Où | Statut / action honnête |
|---|---|---|---|
| Identité du titulaire (en-tête) | `profiles.first_name`, `last_name`, `immutable_id`, `account_status` lisibles par soi (`profiles_self_select`, `0001_fondations.sql:706-707` ; colonnes `:71-84`) ; courriel et fournisseur dans la session Supabase (`auth.currentUser`) | Aucune lecture dans `lib/` : `source_session.dart:79-83` ne sélectionne pas le nom ; `ServiceAuth` n'expose ni courriel ni fournisseur (`lib/core/auth/service_auth.dart:15-31`) | Adaptateur frontend à créer (lecture seule), sans migration |
| Modifier l'identité | Aucune RPC d'écriture pour le tuteur (la seule, `maj_profil_enseignant`, est bornée à l'enseignant, `0027_maj_profil_enseignant.sql:78`) ; téléphone, pays, ville : **aucune colonne** pour le tuteur (seul `teacher_profiles.country`, `0001_fondations.sql:92`) | | Bouton « Modifier » de la maquette non rendu ; phrase « modifiable par l'académie » ; `dépendance backend` |
| Connexion et sécurité | Production : lien à usage unique et Google (`service_auth.dart:12-14,51-64`) ; mot de passe réservé à `DEMO_AUTH` (`:19-24`) ; `signOut()` (`:67`) | Déconnexion branchée (`compte_page.dart:103-109`) | Méthode de connexion : lisible via la session (adaptateur). « Mot de passe » : **sans objet** en production. Liste des sessions : aucune API. « Déconnecter mes autres appareils » : possible par le SDK (`signOut` avec portée) sans backend, à valider. « Appareils connectés » de la maquette : ne pas confondre avec les appareils appairés des élèves (`mes_appareils_v`, lot Appareils) |
| Abonnement et accès | `profiles.access_until` par élève (`0001_fondations.sql:79`), exposé par `profils_du_foyer_v` et lu en `EleveDuFoyer.finAcces` (`service_appairage.dart:111,138`) ; déjà affiché dans `_BlocAcces` de l'accueil (`accueil_famille_page.dart:541-570`) et dans `ProfilEnfantPage` (`compte_page.dart:603-609`) | Seul l'admin peut changer `access_until` (déclencheur `0001_fondations.sql:539-550`) ; **aucun écran admin** ne le pose ; pas de date d'accès pour le titulaire non élève | Rubrique « Accès » par bénéficiaire : `branchable`. Ne pas écrire « abonnement » ni « actif jusqu'au » pour le titulaire (mandat §5 : un accès daté n'est pas un abonnement récurrent) |
| Paiements, historique, reçus, moyen de paiement | **Aucune** table de paiement famille, facture ou reçu. Seul le schéma finance « sans interface » (`wallets`, `wallet_entries`, `payouts`, `0001_fondations.sql:242-297`) ; montants de séance « inutilisés en MVP-0 » (`:171-173`) | `docs/current/06_SPEC_FONCTIONNELLE_MVP.md:28` : « Paiement transitoire » M essentiel, non construit | Écran « indisponible » ; les trois actions de la maquette (« Gérer les paiements », « Historique et reçus », « Moyen de paiement ») **ne sont pas rendues** ; `dépendance backend` |
| Préférences : langue | Français seul ; `ar` quasi vide | `fr.i18n.json:1140` | Afficher « Français » sans bascule |
| Préférences : apparence | Thème : aucun câblage (§2.3) | `app.dart:50` | À câbler par le coordinateur ou à retirer |
| Préférences : fuseau | Lecture `mon_fuseau()` possible | `service_planning.dart:257-260` | Lecture seule branchable ; modification : RPC seulement dans `0043_offres_horaires_et_intentions.sql:644`, **non appliquée** (`CONFIGURATION_BASELINE_2026-09-23.md:129`) |
| Préférences : notifications | Aucun système | §7 | Retirer les interrupteurs ou afficher « indisponible » |
| Accès au foyer | `/tuteur/foyer` | `compte_page.dart:74-82` | Branché ; « Créer mon profil élève » ouvre le flux du lot Foyer |
| Aide et support | **Aucun canal** : pas de courriel, pas de lien, pas de `url_launcher` dans `pubspec.yaml` ; « Contacter l'académie » n'est qu'un texte (`lib/features/dossier/attente_page.dart:97`, `fr.i18n.json:112`) | | Écran « indisponible » ; canal réel à fournir par le directeur ; `dépendance` (décision + éventuellement paquet) |
| Informations légales | Acceptations signées lisibles par soi : `ServiceAcceptations` (`lib/core/profil/service_acceptations.dart:73-119`) ; textes = les points `t.contrat.*` (`lib/features/dossier/signature_page.dart:46-70`), version `2026-09` (`lib/core/dossier/versions_contrat.dart:13`) ; motif d'affichage déjà codé pour l'enseignant (`profil_enseignant_page.dart:505-575`) | `acceptationsProvider` utilisé seulement par le profil enseignant | Rubrique « Documents acceptés » : `branchable` sans backend. CGU complètes, politique de confidentialité, mentions légales : **aucun document** dans le dépôt, à marquer « non disponible » |
| Déconnexion | branchée | `compte_page.dart:103-109` | Ajouter la confirmation, séparer visuellement (mandat §5) |

---

## 4. Historique des séances : ce qui existe

### 4.1 Chaîne de données

- Écran `SuiviFoyerPage` (`TUT-06`, `lib/features/suivi_foyer/suivi_foyer_page.dart:47-144`), vue pure
  `VueSuiviFoyer.depuis` (`vue_suivi_foyer.dart:125-185`), même vue réutilisée par l'élève
  (`lib/features/suivi_eleve/suivi_eleve_page.dart:69-73`).
- Service `ServiceSuiviSupabase` (`lib/core/suivi/service_suivi.dart:50-88`) : `mes_seances_v` trié
  décroissant, plafond 200 (`:16,57-64`) ; `presence_seance_v` même fenêtre, `null` si indisponible
  (`:67-87`).
- Bornage en base : `mes_seances_v` (`0014_acces_agent.sql:888-920`) une ligne par élève inscrit,
  filtrée foyer ; `presence_seance_v` (`0033_tc_vues_rpc.sql:47-87`) filtrée foyer (`est_du_foyer`).
  Le client ne filtre rien par foyer (`service_suivi.dart:20-27`) : bon principe, à conserver.
- Tests présents (non rejoués ici) : `test/features/suivi_foyer_test.dart` (16 cas),
  `test/suivi/vue_suivi_foyer_test.dart` (15 cas, dont « deux enfants, deux cours, aucun croisement »
  `:193`, « la ligne d'un autre profil n'est pas prise » `:233`).

### 4.2 Champs demandés par le mandat, un par un

| Champ (mandat §5 « Historique ») | Disponible ? | Preuve | Remarque |
|---|---|---|---|
| Date | oui | `Seance.debut` (`service_planning.dart:93-95`) | **Repli sur `DateTime.now()` si la date est illisible** (`:93-98`) : une ligne pourrait s'afficher « Aujourd'hui » à tort. À remplacer par un état « date inconnue » |
| Horaire début / fin | oui (prévu) | `debut`, `fin` (`:113-116`) | L'écran n'affiche que l'heure de début (`suivi_foyer_page.dart:353-374`) |
| Fuseau explicite | non affiché | `toLocal()` = fuseau de l'appareil (`service_planning.dart:94,97`) | Le mandat exige un fuseau explicite et cohérent ; `mon_fuseau()` donne celui du foyer |
| Classe | **non** | `mes_seances_v` n'expose pas `groupe_id` (`0014_acces_agent.sql:891-905`) bien que `sessions.groupe_id` existe (`0025_role_enseignant.sql:46-47`) | Contournement partiel possible sans migration : le foyer lit `sessions` (policy `sessions_family_read`, `0001_fondations.sql:1000-1005`) et `groupes` **seulement pour les groupes courants** (`0019_groupes_durcissement.sql:308-320`, `m.left_at is null`). Une ancienne classe n'est pas nommable : afficher « Classe non disponible », jamais deviner. Solution propre : `dépendance backend` B1 |
| Enseignant | prénom + identifiant immuable | `suivi_foyer_page.dart:300-308` | Titre Sayyid/Sayyida et photo : seulement dans `mes_groupes_famille_v` pour les groupes courants (`0033_tc_vues_rpc.sql:140-176`, `teacher_titre`, `teacher_photo_cle`) |
| Présence | oui, 14 états + inconnu | `lib/core/presence/service_presence.dart:23-111`, libellés `lib/core/widgets/ligne_presence.dart:59-75` | Voir 4.3 |
| Retard | oui | état `en_retard` si arrivée > seuil `presence.seuil_retard_secondes` (défaut 300) (`0042_...sql:137-139` sur la branche observation, en production) ; minutes calculables par `VuePresence` (`lib/core/presence/vue_presence.dart:82-85`) avec `entre_le` borné au début (`0033_tc_vues_rpc.sql:57-65`) | Non affiché en minutes dans l'historique aujourd'hui |
| Présence validée | partiellement | `consolide` = une décision humaine existe (`service_presence.dart:184-190`, `0033:70`) | Sans correction manuelle, un cours terminé reste `confirmation_en_attente` pour toujours (`0042_...sql:141-143`) : « validé » ne se lit qu'à travers `consolide` |
| Durée du cours | prévue seulement | `Seance.duree = fin - debut` (`service_planning.dart:143`) ; pause prière `minutesInterruption` (`:139-140`) | Durée effective : absente |
| Temps connecté | **non** | `presence_seance_v` ne rend que `entre_le` et `derniere_trace_le` (dernier événement de n'importe quel type, `0033:66-69`) | Ne pas présenter `derniere_trace_le` comme une heure de sortie. `dépendance backend` B10 si voulu |
| Qualité réseau | **non mesurée** | Seulement en direct dans la salle (`lib/core/video/livekit_session_provider.dart:214-220,415-420`), jamais persistée | La maquette historique (`tutuor image/mobile/Historique.png`, ancienne capture) affiche « Réseau élève / enseignant » : **à ne pas reproduire** (mandat §5) |
| Résumé famille, travail | **non** | voir 4.4 | |
| Annulé / non tenu | oui | `SortDuCours` (`vue_suivi_foyer.dart:19-30,195-205`) | Bonne règle : le sort du cours prime sur l'état de l'enfant |

### 4.3 Sémantique des états après la séance (à corriger à l'écran)

`etat_presence` (version en production : `observation/lot-2026-09-21:supabase/migrations/0042_...sql:34-150`)
laisse des états « en direct » sur des séances passées : un enfant parti par coupure reste
`deconnectee` (« Lien coupé »), un départ volontaire reste `sortie` (« A quitté le cours »), un
retard reste `en_retard`, un présent non corrigé reste `confirmation_en_attente` (« À confirmer »).
L'historique actuel les affiche tels quels, `deconnectee` en ton d'alerte (`vue_presence.dart:141`).
Or le mandat interdit « aucune absence déduite d'une simple déconnexion » et demande « En cours de
vérification » pour une preuve ambiguë. Proposition frontend (fonction pure, testable, sans backend) :
pour une séance terminée non consolidée, `deconnectee`, `en_reconnexion`, `sortie`,
`confirmation_en_attente`, `inconnu` → « En cours de vérification » (ton neutre) ; `absente` →
« Absence » seulement si `consolide` ou si le statut de séance est `ended` et qu'aucune entrée
n'existe (règle serveur `0042_...sql:98-101`) ; `en_retard` → « Retard N min » ; `excusee`,
`corrigee_manuel`, `finalisee` → libellé validé. La table de correspondance doit rester unique
(`LignePresence.libelle`, `ligne_presence.dart:59-75`), pas une seconde table.

### 4.4 Détail de séance

Absent : `DataCollection` accepte `onSelectionner` (`lib/core/widgets/data_collection.dart:123,329`)
mais `SuiviFoyerPage` ne le passe pas (`suivi_foyer_page.dart:246-251`). Données disponibles pour un
détail honnête : identité de séance, date/heure/durée prévues, enseignant, état de présence et
`entre_le`, sort du cours, pause prière. **À ne pas utiliser** :
- `lesson_reports` : lisible par tout foyer d'un participant (`0001_fondations.sql:1070-1078`,
  `session_in_household` `:441-450`), policy jamais redéfinie ensuite ; `content` porte les
  décisions de **chaque élève du groupe** (motif d'exception, point phonétique, objectif, travail :
  `modeles_enseignant.dart:631-676`). La RLS borne les lignes, pas les colonnes. Un résumé famille
  exige une projection par élève côté serveur (`dépendance backend` B2, sécurité).
- `concern_famille_v` (`0033_tc_vues_rpc.sql:272-282`) est la seule surface « message famille »
  correctement projetée, mais rien ne l'alimente (§7).
Travail à préparer : relève du lot Cours (`learning_assignment`, `0032_tc_catalogue.sql:354`) ; le
détail peut y renvoyer sans le dupliquer.

---

## 5. Historique des observations

### 5.1 Ce qui existe

| Élément | Preuve | Statut |
|---|---|---|
| Table `guardian_session_visit` : séance, groupe, observateur, rôle, enfant, entrée, sortie, durée générée, rang de visite, version de politique, motif de fin | `0032_tc_catalogue.sql:449-470` ; un seul intervalle ouvert par (séance, observateur) `:478-480` | présente, appliquée en production (`CONFIGURATION_BASELINE_2026-09-23.md:122`) |
| RLS : l'observateur voit ses lignes, l'admin toutes | `0032_tc_catalogue.sql:488-492` | Grants de table : défaut Supabase supposé (aucun `revoke` trouvé), `INCONNU` sans mesure |
| Ouverture | `entrer_observation` (`0033_tc_vues_rpc.sql:1086-1196`, puis `0037_...sql:56-186`) : journalise `observation_entree` (`0033:1181-1184`) | branché (`lib/core/tc_observation/port_visite_observation.dart:92-112`) |
| Fermeture | `sortir_observation` : cassée dans `main` (écrit une colonne générée et `'utilisateur'`, `0033:1208-1211`), **réparée en production** par `0039` (`observation/lot-2026-09-21`, `0039_...sql:331-370`) qui écrit **toujours** `fin_de_visite = 'sortie_volontaire'` (`:344-346`) | La production est en avance sur `main` (0039-0042 absents du dépôt `main`) |
| Lecture | `visites_observation(p_session_id)` : une séance, champs id, rôle, entrée, sortie, durée, rang, motif (`0033:1235-1257`) ; sans enfant ni classe ni groupe | Port Dart présent (`port_visite_observation.dart:127-141`), **aucun appelant** dans `lib/` |
| Modèle Dart | `GuardianSessionVisit`, `RoleObservateur`, `FinDeVisite` (`lib/core/tc_observation/guardian_session_visit.dart:14-182`) ; libellés de fin en deuxième personne (`libelles_observation.dart:19-25`, `fr.i18n.json`, bloc `tc.observation.fin`) | Réutilisable ; libellés d'historique courts (« Départ volontaire », « Limite atteinte ») à ajouter |
| Journal d'audit | événements `observation_entree` / `observation_sortie` via `log_sensitive_access` (`0033:1181-1184,1223-1226`) | Visibles dans `ADM-04`, mais sans libellé : `libelleEvenement` ne les connaît pas (`lib/features/admin_journal/journal_page.dart:591-618`) et affiche la valeur brute |

### 5.2 Défauts qui empêchent un historique fidèle

1. **Motif de fin faux** : le client appelle `sortir()` aussi quand le quota est atteint
   (`lib/core/tc_observation/moteur_visite_observation.dart:280,312,327`) ; le serveur enregistre
   `sortie_volontaire` dans tous les cas. La colonne « Fin » de la maquette admin
   (« Limite atteinte », « Départ volontaire ») ne peut pas être affichée vraie. `dépendance backend` B3.
2. **Visites jamais refermées côté serveur** : aucune Edge Function ni migration ne ferme un
   intervalle quitté par fermeture d'onglet ou coupure (recherche `guardian_session_visit`,
   `fin_de_visite` dans `supabase/functions` : aucun résultat, sur `c0` comme sur la branche
   d'observation). `left_at`, `duration_seconds`, `fin_de_visite` restent nuls ; le budget plafonne
   l'intervalle ouvert au TTL du jeton (`0036_...sql:326-337`) mais la ligne reste « en cours ».
   Conséquence probable, non mesurée : l'index `guardian_visit_ouvert_uidx` (`0032:478-480`)
   refuserait l'insertion d'une visite suivante pour ce même observateur et cette séance. `INCONNU`.
3. **Pas de lecture transversale** : ni vue ni RPC ne liste les visites d'un tuteur sur plusieurs
   séances, ni ne permet à l'admin de chercher par tuteur, élève, classe, période, statut.
   Contournement sans migration possible (non vérifié) : lecture directe de la table sous RLS avec
   jointures PostgREST vers `profiles`, `groupes`, `sessions` (clés étrangères `0032:451-455`). Pour
   le tuteur, `groupes` n'est lisible que pour les groupes courants (§4.2). `dépendance backend` B4
   recommandée.
4. **Enfant concerné unique** : `entrer_observation` choisit `limit 1` parmi les enfants du foyer
   dans le groupe (`0033:1134-1139`, repris par `0037`) : deux frères et sœurs dans la même séance ne
   produisent qu'un enfant. Point ouvert explicitement non tranché par le mandat (complément §9).
5. **Commentaires qui contredisent le code** : `port_visite_observation.dart:79-80` affirme
   qu'« aucune des trois fonctions n'existe encore en base » (elles existent, `0033:1086,1198,1235`) ;
   `guardian_session_visit.dart:5-13` dit que `admin_masked` / `admin_visible` n'existent pas (ajoutés
   par `0031_participant_role_admin.sql:13-14`).

### 5.3 Vue tuteur « Séances / Observations » sans second système

Même écran Historique, même sélecteur d'élève, mêmes filtres, deuxième segment « Observations »
(maquette `tuteur observation desktop light.png`, panneaux 2 et 4). Source : `guardian_session_visit`
lue sous RLS (observateur = soi), groupée par (séance, enfant). Chaque champ dit ce qu'il sait :
visite ouverte → « Durée non confirmée » ; motif → n'afficher que « Visite terminée » tant que B3
manque (ne pas afficher « Limite atteinte » d'après le seul client) ; fuseau affiché en clair. Tant
que la lecture transversale n'est pas validée (grants `INCONNU`, contrat B4), livrer l'écran avec
l'état « Historique des observations indisponible » plutôt qu'une liste locale (complément §8 :
« ne présente pas une liste locale ou fictive comme un historique enregistré »).

---

## 6. Session et observabilité

- `SessionState` : rôle et foyer du jeton, statut et mode lus en base (`session_state.dart:58-113`,
  `source_session.dart:51-75`). `peutEcrire` (`:119`) sert d'exemple de capacité lue par un widget.
- `LectureProfil.echouee` ferme sur l'attente (`session_state.dart:151-154`) : à respecter dans le
  Compte (un échec de lecture n'est pas une absence).
- `Supervision` (`lib/core/observabilite/supervision.dart`) : Sentry sans capture d'écran, sans
  hiérarchie de vues, sans identité, chaînes de requête coupées (`:52-73,89-117`). Contrainte pour
  C08 : ne jamais journaliser courriel, UUID ou identifiant d'observation dans un `debugPrint` qui
  pourrait remonter en miette (`service_suivi.dart:84` imprime l'erreur brute, sans identifiant).
- Présence/correction : `lib/features/presence_correction/` est côté enseignant (branché dans le
  cahier, `lib/features/cahier/cahier_page.dart:574-597`) ; l'historique tuteur ne fait que lire le
  résultat (`consolide`), jamais corriger (`suivi_foyer_page.dart:42-46`).

---

## 7. Notifications et messages

| Élément | Preuve | Constat |
|---|---|---|
| Centre de notifications tuteur | aucun | Route `/tuteur/notifications` absente |
| Préférences de notification | `compte_page.dart:299-318` | Interrupteurs sans effet (§2.3) |
| Jetons push | table `device_tokens` (`0001_fondations.sql:348-354`) | Aucun paquet push dans `pubspec.yaml`, aucune écriture dans `lib/` |
| Cloche admin | `lib/core/widgets/admin_shell.dart:459-471,519-523` | Ouvre toujours « Aucune notification / Rien à signaler pour l'instant » (`fr.i18n.json`, bloc `admin.notifications`) **sans aucune source** : faux état vide, à transformer en « indisponible » |
| Messages famille | `concern_famille_v` (`0033:272-282`) : résumé transmis par l'admin, note interne exclue colonne par colonne | Aucun lecteur dans `lib/`. Écriture : `PortSignalement` n'a qu'un double mémoire et son provider lève `UnimplementedError` (`lib/core/tc_parcours/port_signalement.dart:56-147`) ; son commentaire dit à tort que `student_concern` n'existe pas (`:50-51` contre `0032_tc_catalogue.sql:572`) ; aucune RPC de transmission |
| Annonces d'observation | `port_annonce_observation.dart`, `annonce_observation_pour_moi` (branche d'observation, `0040`/`0041`) | Notices en classe, pas un centre de notifications ; lot Cours |

Proposition : `/tuteur/notifications` = écran « Les notifications ne sont pas encore disponibles »,
atteint par l'icône d'en-tête, sans pastille de non-lu. Lecture de `concern_famille_v` à ne brancher
que lorsqu'un circuit de transmission admin existe (`dépendance backend` B6), sinon la liste serait
vide par construction.

---

## 8. Paiements et accès (résumé)

- Données réelles : `access_until` par élève (§3). Déjà rendu par `_BlocAcces`
  (`accueil_famille_page.dart:537-570`) avec le commentaire « tient lieu de portefeuille en MVP-0 ».
- Aucune donnée de paiement famille, ni prestataire, ni tarif en base consommable. Le mandat interdit
  tarifs fixes et faux paiements (§5, « Paiements et accès ») ; `01_PRODUIT_ET_PARCOURS.md:37`
  interdit d'afficher un paiement simulé comme réglé.
- Titulaire sans profil élève : aucune date d'accès propre (`access_until` est sur le profil ; le
  tuteur n'est pas l'élève). Ne rien afficher pour lui plutôt qu'un « Accès actif » inventé.

---

## 9. Admin : où brancher la consultation des observations

| Élément existant | Preuve | Usage |
|---|---|---|
| Huit domaines gelés, test vivant | `admin_domaine.dart:5-11,106-128` ; `test/widgets/admin_shell_test.dart:19` | Pas de domaine « Historique » (la maquette admin montre une sidebar « Vue d'ensemble, Personnes, Classes, Historique » : contradiction à consigner) |
| Sécurité et audit : Journal en fonction primaire, Accès des agents atteint depuis l'Accueil | `app_router.dart:526-545` ; `tableau_de_bord_page.dart:221-234` | Ancrage proposé : fonction paire « Observations » sous Sécurité et audit, route `/admin/securite-audit/observations` |
| Sous-navigation par domaine | `SousNavigationDomaine` + `ongletsPedagogie` / `ongletsConfiguration` (`admin_domaine.dart:146-180`, `lib/core/widgets/sous_navigation_domaine.dart`) | Ajouter `ongletsSecurite()` [Journal, Observations] : fichier partagé, **coordinateur** ; l'en-tête de `JournalPage` (`journal_page.dart:181-194`) devra porter la sous-navigation |
| Composants de liste filtrée | `DataCollection` (tableau desktop / cartes), `MenuFiltre`, `FilterPill`, `StatusPill`, `EmptyState`, `Skeleton` ; modèle de période `PeriodeJournal` (`journal_page.dart:25-41`) ; pagination par curseur (`lib/core/journal/service_journal.dart:214-228`) | Réutiliser tels quels ; même écran à cinq états que `ADM-04` |
| Réglage de politique par groupe | feuille `lib/features/admin_groupes/feuille_observation_groupe.dart` + `ModuleReglagesObservation` (`lib/features/tc_observation_ui/module_reglages_observation.dart:15-31`) | Lien secondaire « Voir les visites de ce groupe » vers l'écran Observations filtré |
| Recherche de la barre supérieure | navigation seulement, libellés fixes (`admin_domaine.dart:130-144`, `admin_shell.dart:438-457`) | La recherche tuteur/élève doit vivre dans l'écran, pas dans la barre |
| Libellés de journal | `journal_page.dart:591-618` | Ajouter `observation_entree`, `observation_sortie` (sinon valeur brute) |

Données : la policy `guardian_visit_admin` (`0032:491-492`) donne toutes les lignes à l'admin (sans
`app_account_valid()`, contrairement à d'autres policies). La recherche par nom et la pagination
demandent soit des jointures PostgREST (faisable, non vérifié), soit une vue/RPC dédiée (B4). Un seul
système : l'écran admin et l'écran tuteur lisent la même table ; le journal d'audit reste le journal
(ce que dit déjà `guardian_session_visit.dart:89-98` et `0032:445-447`). Question non tranchée : la
consultation admin de ces lignes doit-elle elle-même être journalisée ? Aucune décision trouvée.

---

## 10. Ce qui est absent et doit devenir un état « indisponible » honnête

| Surface | Raison | Forme proposée |
|---|---|---|
| Paiements, historique et reçus, moyen de paiement | aucune donnée | Une page, une phrase, pas de bouton |
| Modifier mes informations, téléphone, pays, ville | aucune RPC ni colonne | Lecture seule + « modifiable par l'académie » |
| Mot de passe | sans objet en production | Ne pas rendre |
| Sessions actives | aucune API | Ne pas rendre ; éventuellement « déconnecter les autres appareils » si validé |
| Langue arabe | traduction quasi vide | Ne pas proposer de bascule |
| Notifications (centre et préférences) | aucun système | Page indisponible, pas d'interrupteurs |
| Aide, FAQ, contacter Rewayah | aucun canal | Page indisponible jusqu'à décision du canal |
| CGU complètes, confidentialité, mentions légales | aucun document | « Document non disponible » ; seules les acceptations signées sont listées |
| Classe d'une séance passée | non exposée | « Classe non disponible » |
| Qualité réseau, temps connecté, résumé famille | non mesurés ou non projetés | Ne pas afficher la colonne |
| Motif de fin de visite | faux côté serveur | « Visite terminée » générique |
| Historique des observations (tant que B4 non validé) | pas de contrat de liste | État « indisponible » dans le segment Observations |
| Cloche admin | faux vide | « Notifications non disponibles » |

---

## 11. Dépendances backend (aucune n'est à réaliser dans ce lot)

| Id | Service attendu | Entrée / sortie | Impact si absent |
|---|---|---|---|
| B1 | `mes_seances_v` (ou vue dédiée) avec `groupe_id`, libellé de classe, titre et photo publique de l'enseignant, y compris classes quittées | séance → classe | Colonne et filtre « Classe » partiels |
| B2 | Projection « résumé famille » par élève d'une séance, sans note interne ni données d'autres élèves ; **revoir la policy `lesson_reports_reader`** | séance, élève → texte validé | Détail sans résumé ; risque de fuite existant indépendamment du frontend |
| B3 | Fermeture serveur des visites (fin de séance, expiration du jeton, départ LiveKit) et motif réel (`quota_atteint`, `seance_terminee`, `deconnexion`) ; `sortir_observation` recevant le motif | visite → motif, durée | Historique des observations avec motifs faux et visites ouvertes |
| B4 | Lecture transversale des visites : tuteur (ses visites, groupées par séance et enfant, classe, enseignant) et admin (recherche tuteur/élève/classe, période, statut, pagination) | filtres → lignes | Segment Observations et écran admin indisponibles, ou jointures client fragiles |
| B5 | Paiement transitoire : encaissement externe saisi par l'admin, lecture famille (montant, devise, statut, date, justificatif) ; écran admin pour `access_until` | foyer → paiements | Rubrique Paiements indisponible |
| B6 | Notifications : enregistrement `device_tokens`, émission ; messages : RPC de transmission admin de `student_concern` et adaptateur `PortSignalement` | événement → notification | Centre de notifications indisponible |
| B7 | Mise à jour bornée de l'identité du titulaire (et décision sur le téléphone) | champs permis | Identité en lecture seule |
| B8 | Application de `0043` (modification du fuseau du foyer) | fuseau IANA | Fuseau en lecture seule |
| B9 | Mécanisme de ré-acceptation pour comptes actifs (le sous-arbre `/attente` leur est fermé, `redirection.dart:81-87`), nécessaire au nouveau texte d'observation | version → acceptation | Lot Admission ; le Compte peut seulement lister les versions acceptées |
| B10 | Temps connecté cumulé et qualité réseau persistée, si le produit les veut | séance, élève → durées | Colonnes absentes |
| B11 | Rapatrier `0039`-`0042` dans le dépôt `main` (production en avance, `CONFIGURATION_BASELINE_2026-09-23.md:125,128,132`) | | Le code doit viser le comportement de production, pas celui de `main` |

---

## 12. Fichiers : ce qu'un lot « E - Compte et suivi » toucherait

Propriété de l'agent E (proposition) : `lib/features/compte/compte_page.dart` (à découper en un
fichier par sous-page), `lib/features/suivi_foyer/*` (renommage Historique, filtres, détail, segment
Observations), nouveaux fichiers sous `lib/features/compte/` et `lib/features/historique/` si le
coordinateur préfère un dossier neuf, nouvel écran admin `lib/features/admin_observations/`,
adaptateurs de lecture sous `lib/core/suivi/` (et un adaptateur identité/connexion en lecture seule),
tests associés, `journal_page.dart` (libellés d'événements et en-tête).

Fichiers partagés, **demande au coordinateur** : `nav_shell.dart` (destinations tuteur),
`app_router.dart`, `routes.dart`, `redirection.dart`, `admin_domaine.dart` (`ongletsSecurite`),
`app.dart` (thème), `assets/i18n/fr.i18n.json` et fichiers générés slang, `app_icons.dart`,
`test/router/navigation_test.dart`. Fichiers d'autres lots à ne pas toucher : `lib/core/tc_observation/*`
et `lib/features/tc_observation_ui/*` (Observation / Cours), `reglages_enfant_page.dart` et
`lib/features/appareils/*` (Foyer, Appareils), `accueil_famille_page.dart` (Cours). `vue_suivi_foyer.dart`
est aussi consommé par `suivi_eleve_page.dart` : toute évolution doit garder l'élève vert.

---

## 13. Contradictions et points ouverts

1. Maquette admin : sidebar « Vue d'ensemble / Personnes / Classes / Historique » contre gel à huit
   domaines (`admin_domaine.dart:5-11`). Proposition : ancrer sous Sécurité et audit.
2. Maquette « Mon compte » : téléphone, ville, pays, « Compte vérifié », « Accès actif jusqu'au »
   pour le titulaire, trois actions de paiement, « Appareils connectés 2 » : aucune donnée
   correspondante (§3). Reproduire la composition, pas ces contenus.
3. Maquette historique ancienne (`mobile/Historique.png`) : qualité réseau élève/enseignant non
   mesurée ; « Absente » en rouge pour une déconnexion possible.
4. Maquette observation admin : colonne « Fin » avec « Limite atteinte » que le serveur n'enregistre
   jamais (B3).
5. Brief coordinateur : « un seul fichier `fr.i18n.json` » ; il existe aussi `assets/i18n/ar.i18n.json`
   (32 lignes) et `AppLocale.ar`.
6. Libellé interdit « Cours en cours » présent dans `fr.i18n.json:1379,1700,2023` (hors C08, pour le
   lot Cours).
7. « Mode enfant » encore affiché dans le Compte (`compte_page.dart:546-548,590-593`).
8. Quota d'observation partagé ou individuel entre responsables, plusieurs enfants dans une même
   séance : non tranchés (complément §9) ; le serveur compte par observateur (`0036_...sql:319-337`)
   et ne retient qu'un enfant (`0033:1134-1139`).
9. Journalisation des consultations admin des observations : aucune décision trouvée.

## 14. Recette suggérée pour ce domaine

- Tuteur sous 600 px : atteindre Compte depuis la barre, se déconnecter avec confirmation.
- Historique : deux enfants, filtres élève/période/statut, aucune ligne d'un autre foyer (fixture à
  deux foyers, en plus du bornage RLS), séance passée « Lien coupé » affichée « En cours de
  vérification », date illisible sans « Aujourd'hui » inventé, fuseau affiché.
- Détail de séance : lien profond `/tuteur/seances/<id inconnu>` → état « introuvable », pas de crash.
- Observations : visite ouverte → « Durée non confirmée » ; aucun motif « Limite atteinte » déduit du
  client ; état « indisponible » si la lecture échoue ou n'est pas contractualisée.
- Compte : aucun interrupteur sans effet, aucune action de paiement rendue, documents acceptés
  listés avec version et date, thème appliqué réellement si le contrôle est conservé.
- Admin : Sécurité et audit > Observations, filtres, cinq états, aucun bouton d'écriture ou de
  suppression ; libellés `observation_entree` / `observation_sortie` dans le Journal.

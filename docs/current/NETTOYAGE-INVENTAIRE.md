# Nettoyage : inventaire du 11/11/2026

Relevé de A, demandé par le pilote le 11/11/2026, sur `main` `b86dbc9d9` (#428). **Ce relevé ne
supprime rien et ne décide rien.** Il dit quoi nettoyer, pourquoi (avec une preuve), et à qui
appartient chaque fichier. Aucune suppression dans la zone d'un autre agent ; côté serveur, aucun
`DROP` ni `DELETE`. Un module en double d'un module branché ne se supprime qu'avec l'accord du
directeur (règle du 31/10).

Il complète `INVENTAIRE-NON-BRANCHE-2026-11-11.md`, qui reste la référence pour l'état de chaque
module (branché, bouchon, supprimé). Il ne le recopie pas.

## Ce qui est faux, inconnu ou non prouvé, d'abord

- **La ligne du payout dans `tool/branchement_tolere.txt` est fausse.** Elle dit « supprimé le
  08/11 » ; sur `main`, le fichier `lib/core/capacites/port_capacite_payout.dart` existe toujours
  (dernier commit `900a17abb`, #202). Son échéance est dépassée de trois jours. **Traité par E**
  sur `claude/non-branche-echus-travail` (`86840822c`, sans PR) : fichier, `CapacitePayoutDemo` et
  ligne de la liste retirés. Pas encore dans `main`.
- **`tool/verifier_branchement.dart` ne lit pas les échéances.** Une date dépassée ne fait jamais
  échouer la vérification (`grep -n "DateTime" tool/verifier_branchement.dart` : rien).
- **La démo est compilée dans chaque aperçu de PR.** L'aperçu est construit avec
  `ENVIRONNEMENT=staging` (`.github/workflows/flutter-deploy.yml:95`), donc
  `Env.demoCompilee` est vrai (`lib/core/config/env.dart:149`). C'est voulu par le code ; à savoir
  avant de juger un aperçu.
- **Trois imports de démo entrent dans le paquet de production** (mesuré, voir §3).
- Rien ici n'est prouvé en production. Les routes « sans lien » sont trouvées par recherche de
  texte, pas en exécutant le routeur.

## Relais de E (mesures de E sur `main` `b86dbc9d`, reprises telles quelles)

- Les 10 doublons de M1 (03/11) sont supprimés de `main`.
- Aucune classe `*Page` n'est définie deux fois dans `lib/`. Pour les providers, A trouve une
  exception, voir §4.
- Le thème se règle sur deux pages : `ReglagesComptePage` (`compte_page.dart:333`) et
  `ApparenceComptePage` (`apparence_page.dart:61`). **P1+P4 (E) l'absorbe.**
- Routes : seule `/enseignant/bienvenue` (`app_router.dart:1635`) n'a aucun lien ; les autres sont
  atteintes par des fonctions de `Routes`, ou sont des alias pour d'anciens liens, à garder. A
  ajoute `/tc/mushaf`, voir §5.

## 1. Fichiers de `lib/` tolérés par `tool/branchement_tolere.txt`

`dart run tool/verifier_branchement.dart` : « 4 fichiers non atteints, tous tolérés ». Les quatre
existent.

| Fichier | Importé par | Échéance | Que faire | Zone |
|---|---|---|---|---|
| `lib/core/capacites/port_capacite_payout.dart` | seulement la démo (`features/demo/comptable/paiements_demo.dart:21`) et 3 tests (`test/features/comptable/paiements/confirmation_payout_test.dart:11`, `support_paiements.dart:13`, `test/support/demo/comptable/paiements_demo.dart:20`) | 08/11, **dépassée** | **traité par E** (`claude/non-branche-echus-travail`, `86840822c`) : ne pas y toucher | core/capacites (finance) |
| `lib/features/mon_espace_adulte/mon_espace_adulte_page.dart` | démo seulement ; 24 fichiers de test | 15/11 | **l'étape 3 FN-112 est annulée** (pilote, 11/11/2026) : E le supprime dans P1+P4, fusionnée avant le 15/11 | mon_espace_adulte (E) |
| `lib/features/recherche/domaines/finance_communications/moteur_finances.dart` | `moteurs_finance_communications.dart:8` (toléré aussi) | 30/11 | étape Listes | recherche |
| `lib/features/recherche/domaines/finance_communications/moteurs_finance_communications.dart` | aucun dans `lib/` ; 2 tests | 30/11 | étape Listes | recherche |

Proposition (pour le pilote, pas pour ce relevé) : que `verifier_branchement` échoue sur une
échéance dépassée.

## 2. Démo et bouchons atteignables en production

Galerie et playground exclus.

### 2.1 Bouchons « indisponible » lus par un écran

`INVENTAIRE-NON-BRANCHE-2026-11-11.md` les liste déjà (lignes 53, 72-73, 84, 96-97, 123-139). Ils
restent tous des bouchons au 11/11 : 30 ports lus par un écran, aucun surchargé dans
`lib/main.dart`. Leur décision, port par port (brancher ou retirer), est au §6. Deux n'ont aucun écran :

| Port | Preuve | Que faire | Zone |
|---|---|---|---|
| `portTransportDonneesProvider` | `lib/core/tc_realtime/providers_tc_realtime.dart:25`, seul lecteur : la chaîne morte du §4.2 | partira avec cette chaîne | core/tc_realtime |
| `portCapacitePayoutProvider` | `port_capacite_payout.dart:67`, aucun lecteur hors démo | traité par E, voir §1 | core/capacites |

**Détour à nettoyer** : `portNotificationsProvider` (`core/capacites/port_notifications.dart:295`)
rend « indisponible », et `notificationsPagePortProvider`
(`features/notifications/notifications_supabase_provider.dart:10-18`) bascule sur Supabase dans ce
cas. Le surcharger directement dans `lib/main.dart` et retirer le détour. Zone : notifications.

### 2.2 Classes de démo rangées dans du code de production

| Fichier | Ce qu'il contient | Preuve | Que faire | Zone |
|---|---|---|---|---|
| `lib/core/offres/offres_admin_demo.dart` | offres fictives | valeur par défaut non gardée de `portOffresAdminProvider` (`port_offres_admin.dart:176-177`), surchargée en production (`main.dart:355`). **Mesuré : son texte « Horaire remplacé par une offre plus proche des familles. » est dans le `main.dart.js` de production.** Jamais montré, mais livré | mettre « indisponible » par défaut et déplacer la classe sous `features/demo/` | core/offres |
| `lib/core/accessibilite/port_demande_presentation.dart:16` (`PortDemandePresentationDemo`) | réponse simulée | employée seulement par `features/demo/demo_accessibilite_page.dart:227` | déplacer sous `features/demo/` | core/accessibilite |
| `lib/features/revenus_enseignant/revenus_enseignant_page.dart:82` (`MoisRevenusDemo`) | mois vide | employée seulement par `features/demo/demo_enseignant_page.dart` | déplacer sous `features/demo/` | revenus_enseignant |
| `lib/features/admin_finance/vue_globale_finance.dart:88` (`MoisVueGlobaleDemo`) | mois vide | employée seulement par `features/demo/demo_finance_page.dart` | déplacer sous `features/demo/` | admin_finance |
| `lib/features/demo/comptable/port_mes_moyens_paiement.dart:205` | un port rangé sous la démo | aucun usage hors démo (`grep -rn port_mes_moyens_paiement lib`) | à trancher avec FINANCE-ENSEIGNANT (« Mes coordonnées de versement » l'a remplacé) | outils de dev |

Gardés par `PLAYGROUND` et absents du paquet de production (mesuré : « Lundi 21 septembre » de
`core/tc_horloge/demonstration_horloge.dart` est seulement dans l'aperçu ; « Classe Al-Baqara »
de `core/tc_groupe/demonstration_groupes.dart` n'est dans aucun des deux) : rien à faire.

## 3. Ce que la démo, la galerie et le playground font entrer dans le paquet

**Mesure** : `flutter build web --release` en local, avec les mêmes options que
`flutter-deploy.yml:148-157` (URL et clé Supabase factices, `GALERIE=false`, `PLAYGROUND=false`,
`AUTH_PAR_MOT_DE_PASSE=false`), une fois avec `ENVIRONNEMENT=production`, une fois avec
`staging`. Rien n'a été déployé. Recherche de texte dans tous les `.js` produits.

| Texte cherché | D'où il vient | Production | Aperçu (staging) |
|---|---|---|---|
| « Visiteur deconnecte » | playground (`_dev/playground/persona.dart:215`) | absent | absent |
| « Le corps de la page defile ici. » | galerie (`_dev/galerie/catalogue_galerie.dart:405`) | absent | absent |
| « demo-adab-talib » | démo (`demo/seance_demo.dart:508`) | absent | **présent** |
| « demo-tuteur » | démo | absent | **présent** |
| « entree-demonstration » (clé du bouton de démo) | `demo/racine_demonstrable.dart` | **présent** | présent |

`main.dart.js` : 10,0 Mo en production, 15,7 Mo en aperçu. Textes de la démo trouvés (sur 590
textes de `features/demo/`) : 310 en aperçu, 42 en production, presque tous des mots courants
présents aussi ailleurs.

Conclusion : **galerie et playground n'entrent dans aucun paquet ; la démo entre dans l'aperçu,
pas en production, sauf ce qui suit.** Trois imports ne sont pas gardés par une constante :

| Import | Ce qui entre en production | Que faire | Zone |
|---|---|---|---|
| `lib/features/connexion/connexion_page.dart:25` → `demo/racine_demonstrable.dart` | `const EntreeDemonstration()` (`connexion_page.dart:545`), sans garde. Il rend un `SizedBox.shrink` en production, mais son code est livré (mesuré : « entree-demonstration ») | entourer de `if (Env.demoCompilee)` | connexion |
| `lib/features/connexion/connexion_page.dart:24` → `demo/mode_demonstration.dart` | `environnementAutoriseDemo` (`connexion_page.dart:262-265`), lu par un provider et non par une constante : `_ouvrirDemonstration` et `SessionControleur.ouvrirDemo` sont livrés | précéder la garde de `Env.demoCompilee &&` | connexion, core/session |
| `lib/core/router/redirection.dart:1` → `demo/mode_demonstration.dart` | `environnementAutoriseDemo` (`redirection.dart:53`) | même correction | core/router |

Aucun de ces trois ne montre la démo en production : la garde d'exécution rend faux
(`demo/mode_demonstration.dart:131-132`). C'est du code livré pour rien.

## 4. Doublons d'un module branché

| Quoi | Preuve | Que faire | Zone |
|---|---|---|---|
| `politiqueReserveProvider` défini deux fois, même corps | `features/comptable/tresorerie/tresorerie_donnees.dart:75` et `features/admin_finance/reserve_delegation/politiques_direction.dart:21` | n'en garder qu'un, dans `core/capacites/port_politique_reserve.dart` | comptable, admin_finance |
| Chaîne importée, jamais lue : `portEtatPartageProvider`, `ServiceEtatPartage`, `reducteur_etat_partage.dart`, `portRealtimePedagogiqueProvider`, `portTransportDonneesProvider` | `grep -rlw portEtatPartageProvider lib test` : seulement sa définition (`core/tc_etat_partage/providers_tc_etat_partage.dart:29`) | **à proposer au directeur** (règle du 31/10). Le vérificateur ne la voit pas, car elle est importée | core/tc_etat_partage, core/tc_realtime (lu par Fable) |
| `portSessionPersistanteProvider` jamais lu | `core/tc_classe/session_persistante.dart:498`, seule occurrence | à proposer au directeur | core/tc_classe (Fable) |
| `portPositionDockProvider` jamais lu, seulement invalidé | `core/tc_outils/etat_outils.dart:77` ; `core/session/session_controleur.dart:234` | à proposer au directeur | core/tc_outils (Fable) |
| Thème et langue sur deux pages | relais de E ci-dessus | **P1+P4 (E)** | PROFILS (E) |
| Commentaire contraire au code | `features/compte/preferences_page.dart:25-27` dit « français seul », alors que `apparence_page.dart:63-74` propose la langue | P1+P4 (E) | PROFILS (E) |
| Deux constantes, un seul chemin | `Routes.compteProfils` et `Routes.compteProfilEnfant` valent `/compte/profils` (`core/router/routes.dart:1313`, `:1316`) ; `RoutesCoran.mushaf` (`features/tc_mushaf/routes_tc_c.dart:10`) double `Routes.tcMushaf` (`routes.dart:1342`) | n'en garder qu'une de chaque | core/router, tc_mushaf |
| À vérifier : `signalement_seance.dart` et `ouvrirSignalement` | signalé le 31/10, non tranché (`salle_seance/signalement_seance.dart`, `fiche_groupe/fiche_eleve_enseignant.dart`) | relire avec Fable | salle_seance (Fable) |

## 5. Routes inatteignables

| Route | Preuve | Que faire | Zone |
|---|---|---|---|
| `/enseignant/bienvenue` | `app_router.dart:1635-1638` ; aucun `go`, `push`, lien ni redirection dans `lib/` (seul `test/features/bienvenue_enseignant_test.dart:70` l'ouvre) | la relier (fin de recrutement, « Bienvenue dans l'équipe ») ou la retirer : décision produit | bienvenue_enseignant |
| `/tc/mushaf` | seul l'élève y a droit (`redirection.dart:503-505`), et l'élève est toujours renvoyé vers `/eleve/coran` (`redirection.dart:334-337`) : la page n'est jamais rendue par cette adresse | en faire une simple redirection vers `/eleve/coran` | tc_mushaf |
| `/compte/profils`, `/compte/profils/:profilId` | aucun lien hors de la page elle-même (`compte_page.dart:533`) ; le tuteur est renvoyé au Foyer (`redirection.dart:450-457`) | P1+P4 (E) | PROFILS (E) |

17 routes de compatibilité (`/bienvenue`, `/tuteur/accueil`, `/admin/tableau-de-bord`, et les
autres de `app_router.dart:533-536`, `:633-641`, `:890-939`, `:2579-2615`) n'ont aucun lien
interne : elles servent aux anciens signets et aux PWA installées. **À garder** (relais de E).
Aucune redirection ne mène à une route supprimée (contrôle par script).

## Résumé

| Section | Constat |
|---|---|
| 1. Tolérés | 4 fichiers ; 1 échéance dépassée (payout, traité par E) ; la mention « supprimé » est fausse ; le vérificateur ne lit pas les dates |
| 2. Démo et bouchons | 30 bouchons lus par un écran (déjà inventoriés) ; 2 sans écran ; 1 détour (notifications) ; 4 classes de démo rangées en production, dont 1 livrée dans le paquet (`OffresAdminDemo`, mesuré) |
| 3. Paquet | galerie et playground : absents des deux paquets (mesuré) ; démo : dans l'aperçu, pas en production, sauf 3 imports non gardés (connexion, redirection), dont un mesuré dans le paquet de production |
| 4. Doublons | 1 provider défini deux fois ; 1 chaîne et 2 providers jamais lus (à proposer au directeur) ; 2 constantes de chemin en double ; le doublon thème et langue revient à E |
| 5. Routes | 2 inatteignables (`/enseignant/bienvenue`, `/tc/mushaf`) ; 1 paire pour E ; 17 alias à garder |
| 6. Ports « indisponible » | 30 lus par un écran : 1 à brancher sur un serveur existant (`portAgeEleveProvider`), 1 à brancher avec une petite RPC (`foyerTitulaireProvider`), 28 à retirer, dont 11 visibles aujourd'hui avec un « indisponible » (à faire d'abord) |

## 6. Les 30 ports « indisponible » : brancher ou retirer

Demandé par le pilote le 11/11/2026 : c'est le vrai chantier du « 100 % opérationnel ». Règle :
**jamais un « indisponible » montré à un utilisateur.** Pour chaque port lu par un écran en
production : l'écran, la zone et son propriétaire, le serveur s'il existe dans les migrations du
dépôt (avec la preuve), et la décision proposée. Ensuite, un lot par zone. Ce tableau ne décide
rien : chaque retrait d'écran passe par le pilote et le directeur.

### Ce qui est faux, bloqué ou non prouvé pour ce tableau

- **Visible ne veut pas dire vu.** Je dis « visible » quand un bouton, un onglet ou une ligne y mène
  sans condition fausse dans le code. Je n'ai rien ouvert en production.
- **Installé en production : inconnu.** Pour le serveur, je dis seulement « présent dans les
  migrations du dépôt ».
- **Espace comptable : visibilité inconnue.** Les routes `/comptable/*` ne servent qu'un compte
  `accountant`. L'invitation existe et elle est branchée (`inviter_comptable`,
  `20261017160200_bf1_03_invitation_comptable.sql` ; `portInvitationsComptableProvider` lu par
  `admin_invitations/invitations_page.dart`). Je ne sais pas si un tel compte existe en production.
- **Aucun adaptateur `*_supabase.dart` caché.** Pour les 30 interfaces, la seule classe qui
  l'implémente sous `lib/` (hors `demo`, `_dev`) est la classe « Indisponible » du même fichier.
  Commande : `grep -rlnE "(implements|extends|with) [^{]*\bPortXxx\b" lib`. Les autres
  implémentations sont des faux dans `test/`.
- **Deux précisions sur le §2.1.**
  - `portPolitiquePiecesJointesProvider` : le seul lecteur est `EntreePieceJointe`
    (`core/widgets/carte_piece_jointe.dart:448-450`), posé seulement dans
    `com_communaute/composer_publication.dart:481`. `CartePieceJointe` ne le lit pas.
  - `portCartesClasseProvider` : il est aussi lu par `cartesClasseProvider`
    (`core/tc_groupe/cartes_classe.dart:287-290`), donc par `BlocCartesClasse`, posé sur quatre
    écrans. Pas seulement par la feuille.
- **Les 30 ports sont bien absents de `lib/main.dart` et de `lib/racine_reelle.dart`.**
  Commande : `grep -c "\bxxxProvider\b" lib/main.dart lib/racine_reelle.dart` = 0 pour chacun.

### Méthode

1. Pour chaque port : `grep -rn "\b<port>\b" lib` hors `features/demo` et `features/_dev`.
2. Pour chaque écran : remontée jusqu'à la route (`lib/core/router/app_router.dart`), puis jusqu'au
   bouton, à l'onglet ou à la ligne qui y mène, avec sa condition.
3. Serveur : liste des noms de toutes les `CREATE FUNCTION` (664) et `CREATE TABLE` (192) de
   `supabase/migrations/`, puis `grep -iE` par mots-clés sur ces listes, puis lecture du
   `CREATE` trouvé. Commandes exactes dans chaque ligne.
4. Propriétaire : celui de l'écran qui lit le port (c'est lui qui retire ou branche).
5. Règle tenue : aucun calcul financier de référence côté Flutter (CLAUDE.md). Un tableau de
   soldes ou de marges se calcule donc dans une RPC, jamais dans un adaptateur.

Légende de la colonne « Visible » :
- **OUI** : l'utilisateur voit aujourd'hui « pas encore disponible » (ou une phrase du même sens).
- **COMPTABLE** : visible seulement pour un compte comptable.
- **NON** : aucune entrée visible (capacité toujours fausse, ligne masquée, page jamais créée).

---

### Zone com_vocal (propriétaire : communications)

| Port | Écrans qui le lisent | Entrée et visibilité | Serveur (migrations du dépôt) | Décision |
|---|---|---|---|---|
| `portEnregistreurVocalProvider` `com_vocal/port_enregistreur_vocal.dart:218` | `com_vocal/composer_vocal.dart:179`, posé par `com_messages/fil_contextuel.dart:264` et `com_studio/canal_page.dart` | Messages (`app_router.dart:1070`, `:1564`). Le composer n'apparaît que si `vocalOuvert` (`envoi_vocal.dart:105-110`). La capacité `envoyer_vocal` est **toujours fausse** : `20261105400000_n1_capacites_communication.sql:26,81` ; absente de `20261119400100_messages_candidat.sql`. **NON** | Aucun. `grep -iE "vocal\|audio"` sur les noms de fonctions et de tables : 0 | **RETIRER**. Déjà invisible ; nettoyage sans urgence, aucun transport audio côté serveur. |
| `portLectureVocaleProvider` `port_enregistreur_vocal.dart:243` | `com_vocal/lecteur_vocal.dart:324` (`LecteurVocalRecu`), via `piecesDuMessage` (`lecteur_vocal.dart:342-350`), posé par `fil_contextuel.dart:222` et `canal_page.dart:467` | Ne s'affiche que pour une pièce jointe vocale. L'adaptateur réel des messages ne lit aucune pièce jointe (`grep -n "piece" com_messages/messages_metier_supabase.dart` : 0). **NON** | Aucun (même grep) | **RETIRER**. Aucun vocal ne peut arriver. |
| `portEnvoiVocalProvider` `com_vocal/envoi_vocal.dart:98` | `com_messages/messages_page.dart:330`, `com_studio/studio_page.dart:648` | Les deux passent par `vocalOuvert(ref)` (`messages_page.dart:493`, `studio_page.dart:992`), toujours faux. **NON** | Aucun (même grep) | **RETIRER**. Même raison. |

### Zone com_studio (propriétaire : communications)

| Port | Écrans qui le lisent | Entrée et visibilité | Serveur | Décision |
|---|---|---|---|---|
| `portStudioProvider` `com_studio/port_studio.dart:376` | `com_studio/studio_page.dart:518`, `aujourdhui_page.dart:239,287`, `brouillons_studio.dart:314` ; aussi `recherche/.../moteurs_finance_communications.dart:20` (toléré, non branché) | Route `/admin/studio` (`app_router.dart:1971-1984`). Bouton « Le Studio » dans l'en-tête de **toutes** les pages admin (`app_router.dart:3165`, `:3603` ; `core/widgets/admin_shell.dart:267,793-803`), et cible de la recherche admin (`core/admin/admin_domaine.dart:154`). **OUI** (directeur) | Aucun. `grep -iE "studio\|canal\|canaux"` sur les noms : seulement `canal_support` et `configurer_canal_support` (canal du support, autre sujet) | **RETIRER** le bouton, la cible de recherche et la route. Le directeur voit un écran vide « pas encore disponible ». Aucune table de canaux. |
| `portActiviteStudioProvider` `com_studio/port_activite_studio.dart:366` | `com_studio/aujourdhui_page.dart:255,304` (vue « Aujourd'hui » du Studio, racine `/admin/studio`) | Même entrée. **OUI** | Aucun. `grep -iE "activite\|attention"` sur les noms de fonctions : 0 | **RETIRER** avec le Studio. |

### Zone com_communaute (propriétaire : communications)

| Port | Écrans qui le lisent | Entrée et visibilité | Serveur | Décision |
|---|---|---|---|---|
| `portCommunauteProvider` `com_communaute/port_communaute.dart:532` | `publication_detail.dart:194`, `composer_publication.dart:280`, fournisseurs `port_communaute.dart:584-621` | Route `/enseignant/communaute` (`app_router.dart:1526`). Seule entrée : `EntreeCommunaute` sur Ma journée, **masquée** si `CapaciteIndisponible` (`entree_communaute.dart:66-70`, décision R-27). URL tapée seulement. **NON** | Aucun. `grep -iE "communaute\|publication"` : seulement `accepter_accord_publication`, `mon_accord_publication`, `retirer_accord_publication` (accord photo), `evaluation_publications` (évaluations) | **RETIRER** la route et les pages. Aucune table de publications. |
| `choixPieceCommunauteProvider` `port_communaute.dart:540` | `composer_publication.dart:190` | Dans la Communauté. **NON** | Choix de fichier local, pas un port serveur. L'envoi R2 côté Communauté : aucun | **RETIRER** avec la Communauté. |
| `portGardePromotionProvider` `com_communaute/port_garde_promotion.dart:249` | `composer_publication.dart:255`, `reponses.dart:521` | Dans la Communauté. **NON** | Aucun. `grep -iE "promo\|lien"` sur les noms : seulement `progression_promouvoir` (pédagogie) | **RETIRER** avec la Communauté. |

### Zone core/communications (propriétaire : communications)

| Port | Écrans qui le lisent | Entrée et visibilité | Serveur | Décision |
|---|---|---|---|---|
| `portPolitiquePiecesJointesProvider` `core/communications/port_pieces_jointes.dart:247` | `EntreePieceJointe` (`core/widgets/carte_piece_jointe.dart:448-450`), posé seulement par `com_communaute/composer_publication.dart:481` | Dans la Communauté. **NON** | Aucun. `grep -iE "piece"` sur les noms : seulement les pièces d'identité (KYC) | **RETIRER** avec la Communauté. |
| `portModerationProvider` `core/communications/moderation.dart:217` | `com_annonces/file_moderation.dart:69,216` ; `com_communaute/publication_detail.dart:61,256` | Onglet « Modération » de l'Administration des communications, **sans condition** (`core/admin/admin_domaine.dart:346-349`), route `app_router.dart:1907`. `FileModeration` affiche `NatureEtat.indisponible` (`file_moderation.dart:271-275`). **OUI** (directeur) | Aucun. `grep -iE "moder\|signal"` sur les noms : `avis_moderer` (avis des familles), `signalements_ouverts_direction` (protection de l'enfance, `20261018160000_pe_protection_enfants.sql:280`), `signaler_horaire_insatisfait`. Rien pour les messages | **RETIRER** l'onglet. Il n'y a rien à modérer : la Communauté n'existe pas. |
| `portElementsEnregistresProvider` `core/communications/port_elements_enregistres.dart:108` | `com_studio/elements_enregistres_studio.dart:92`, `studio_page.dart:661,678` ; `publication_detail.dart:73,266` | Par le Studio (**OUI**) et la Communauté (NON) | Aucun. `grep -iE "enregistr\|favori\|signet"` : seulement des `enregistrer_*` d'autres domaines | **RETIRER** avec le Studio. |

### Zone salle (propriétaire : Fable ; port dans core/accessibilite)

| Port | Écrans qui le lisent | Entrée et visibilité | Serveur | Décision |
|---|---|---|---|---|
| `portAgeEleveProvider` `core/accessibilite/age_eleve.dart:44` | `features/salle/salle_page.dart:1923` (après la séance), `:2136` (salle) | `/salle` (`app_router.dart:2889`), atteinte par les quatre rôles. **Aucun « indisponible » affiché**, mais l'âge reste `inconnu`, donc **un enfant est vouvoyé** (`age_eleve.dart:6-8`). Visible, faux | **Présent** : colonne `student_profiles.student_type` (`0001_fondations.sql:32,102`), lecture famille `student_profiles_family` (`0001_fondations.sql:726`). Déjà lue par un adaptateur branché pour le même usage : `core/accessibilite/accueil_accessibilite_supabase.dart:66-70,102` (`tutoiement: student_type == 'minor'`) | **BRANCHER**, serveur existant. À vérifier : l'interface est synchrone, il faut une lecture préalable ; et la règle de lecture pour un compte élève enfant connecté (politique famille par `household_id`). |

### Zone tc_espace_groupe (propriétaire : tc_espace_groupe ; port dans core/tc_groupe)

| Port | Écrans qui le lisent | Entrée et visibilité | Serveur | Décision |
|---|---|---|---|---|
| `portCartesClasseProvider` `core/tc_groupe/cartes_classe.dart:281` | `tc_espace_groupe/feuille_carte_classe.dart:225,257` ; `cartesClasseProvider` (`cartes_classe.dart:287-290`) lu par `BlocCartesClasse` (`bloc_cartes_classe.dart:152`), posé dans `classe_tuteur/classe_tuteur_page.dart:184`, `fiche_groupe/fiche_groupe_page.dart:339`, `ma_classe_adulte/ma_classe_adulte_page.dart:335`, `tc_espace_groupe/espace_groupe_page.dart:489` | `/tuteur/classes/:classeId` (`app_router.dart:1019`), `/enseignant/groupe/:groupeId` (`app_router.dart:1652`), classe de l'adulte (`foyer/routes_n2_foyer_adulte.dart:57`). Le bloc affiche « pas encore ouvertes » sur `CapaciteIndisponible` (`bloc_cartes_classe.dart:167-172`). **OUI** (famille, enseignant, adulte) | Aucun. `grep -iE "carte\|card\|devoir"` sur les noms : 0. Le fichier lui-même dit « table `class_cards` à construire » (`cartes_classe.dart:6-10`) | **RETIRER** le bloc tant que la table n'existe pas. Trois rôles voient un bloc vide. Le brancher demande table, RLS, trois RPC et journal. |

### Zone finance (comptable et admin_finance ; ports dans core/capacites)

| Port | Écrans qui le lisent | Entrée et visibilité | Serveur | Décision |
|---|---|---|---|---|
| `portFinanceDirectionProvider` `port_finance_direction.dart:312` | `admin_finance/vue_globale_finance.dart:95,107` | Racine du domaine Finance du directeur, premier onglet « Vue globale » (`app_router.dart:2338` ; `admin_domaine.dart:205`). **OUI** (directeur) | Données présentes, **aucune RPC d'agrégat**. `grep -il "vue_globale\|finance_direction"` : 0. Tables utiles : `factures_mensuelles`, `wallet_entries`, `versements_paie`, `paiements_saisis` | **RETIRER** l'onglet (racine vers Paiements). Encaissé, revenu, paie, marge : un calcul financier interdit côté Flutter, donc une RPC à écrire d'abord. |
| `portDelegationFinanceProvider` `port_delegation_finance.dart:322` | `admin_finance/reserve_delegation/politiques_direction.dart:43,51`, `finance_delegation_policy_panel.dart:53` | Onglet « Réserve et délégation » (`app_router.dart:2367` ; `admin_domaine.dart:207-210`), sans condition. Le bloc de délégation affiche son erreur. **OUI** (directeur) | Aucun. `grep -il "delegation_finance\|seuil_delegation\|plafond_delegation"` : 0. `finance_validations` (`20261018090000_fac_d_01`) sert « À valider », déjà branché | **RETIRER** le panneau de délégation. Aucune politique de seuils côté serveur. |
| `portControleDelegationProvider` `port_delegation_finance.dart:399` | `controle_delegation.dart:114,148,184`, `sorties_en_attente.dart:76`, `politiques_direction.dart:59` | Rendu seulement quand la politique de délégation est lue (`finance_delegation_policy_panel.dart:41-62`), ce qui n'arrive jamais. **NON** | Aucun. `grep -il "sorties_en_attente\|sortie_en_attente"` : 0 | **RETIRER** avec le panneau. |
| `portPolitiqueReserveProvider` `port_politique_reserve.dart:224` | `admin_finance/reserve_delegation/politiques_direction.dart:27,35`, `strategic_reserve_policy_panel.dart:54` ; `comptable/tresorerie/tresorerie_donnees.dart:69` | Même onglet (**OUI**, directeur) ; Trésorerie (COMPTABLE) | **Partiel** : table `politique_allocation_coffres` (`20261012120101_x2_17_treasury_triggers.sql:83-104`), lecture admin, ajout admin en aal2. Elle ne porte qu'un taux (`taux_reserve_permille`). Le modèle demande objectif, montant cible, cadence, seuil d'alerte, validation des retraits (`port_politique_reserve.dart:79-115`) : absents | **RETIRER** le panneau. Avec lui l'onglet « Réserve et délégation » n'a plus rien : le retirer aussi. À écrire avant tout branchement : les colonnes manquantes. |
| `portPayoutProvider` `port_payout.dart:295` | `comptable/paiements/confirmation/confirmation_payout.dart:226,249,303,325`, ouvert par `paiements_page.dart:175` et `detail_paiement_page.dart:113` | Onglet « Paie enseignants » du directeur (`app_router.dart:2413`, `finance_page.dart:90-93`, même page `PaiementsAEffectuerPage`). Une ligne non partie se coche (`paiements_donnees.dart:154-156`) ; « Payer la sélection » s'affiche dès qu'une ligne est cochée (`paiements_page.dart:302-305`), sans filtre de permission. Puis `preflight` lève `CapaciteIndisponible`. **OUI, à vérifier à l'écran** | Table `payouts` (`0001_fondations.sql:273`), **aucune RPC** de vérification ni de soumission. La paie réelle passe par `versement_export_wise`, `versement_paie_noter`, `versement_paie_annuler`, déjà branchés (`portVersementsPaieProvider`, `main.dart`) | **RETIRER** l'action « Payer » de cette page. Le versement réel existe ailleurs ; ce bouton mène à un mur. |
| `portExportRapportsProvider` `port_export_rapports.dart:73` | `comptable/graphiques/action_export.dart:56`, posé dans `paiements_page.dart:296` et `rapports_page.dart:46` | Barre de sélection de « Paie enseignants » : la phrase « export indisponible » (`action_export.dart:85-91`). **OUI** (directeur, après une coche). Rapports comptable (`app_router.dart:2840`) : COMPTABLE | Aucun. `grep -il "export_rapport\|exporter_rapport\|rapport_export"` : 0. Voisin : `versement_export_wise` (export Wise de la paie) | **RETIRER** `ActionExport`. À vérifier : `versement_export_wise` couvre-t-il déjà ce besoin ? |
| `portBeneficiairesPaiementProvider` `port_beneficiaires_paiement.dart:178` | `comptable/beneficiaires/etat_beneficiaires.dart:24,35,45`, `profil_paiement_page.dart:125` ; `admin_finance/reserve_delegation/exceptions_delegation.dart:38` | Onglet Bénéficiaires du comptable (`app_router.dart:2722`) : COMPTABLE. Côté directeur, rendu seulement dans le panneau de délégation (`finance_delegation_policy_panel.dart:451`), jamais lu : NON | **Partiel** : `versement_coordonnees_direction`, `valider_coordonnees_versement` (`20261110700000_versement_wise_enseignant.sql:575,619`), déjà appelés par `core/capacites/coordonnees_versement_supabase.dart:234-281` (branché). Suspendre, reprendre, vérification requise : aucun (`grep -il "suspendre_beneficiaire\|beneficiaire_suspendu"` : 0) | **RETIRER**. Doublon de la vue des coordonnées déjà branchée ; le reste n'a pas de serveur. |
| `portAujourdhuiComptableProvider` `port_aujourdhui_comptable.dart:231` | `comptable/aujourdhui/aujourdhui_page.dart:65` | Première branche du comptable, `/comptable` (`app_router.dart:2640`) : c'est sa page d'arrivée. COMPTABLE | Aucun. `grep -il "aujourdhui_comptable\|comptable_aujourdhui"` : 0 | **RETIRER** ; la première branche du comptable devient Paiements (déjà branché). |
| `portTresorerieProvider` `port_tresorerie.dart:218` | `comptable/tresorerie/tresorerie_donnees.dart:22-63`, `transfert/transfert_interne.dart:199` | Branche Trésorerie (`app_router.dart:2779`). COMPTABLE | **Partiel** : table `tresorerie_mouvements` (`20261011203607_codex2_cpt_br_18_series.sql:7`), lecture finance (`:60-63`) ; `series_tresorerie` déjà branché (`portSeriesTresorerieProvider`). Soldes, prévision, mouvements permis, transfert : aucune RPC | **RETIRER** les blocs coffres, prévision et transfert ; garder les séries. Les soldes sont un calcul financier : RPC à écrire d'abord. |
| `portEncaissementsProvider` `port_encaissements.dart:237` | `comptable/encaissements/donnees_encaissements.dart:104-123`, `rapprochement/donnees_rapprochement.dart:47`, `rapprochement/remboursements_avoirs.dart:104` ; `recherche/.../moteurs_finance_communications.dart:17` (toléré) | Onglet Encaissements (`app_router.dart:2791`, détail `:2805`). COMPTABLE | **Partiel** : `wallet_entries` (`0001_fondations.sql:253`), `paiements_saisis`, `commandes_recharge`, fonctions `remboursement_*` (branchées pour le directeur). Aucune RPC de liste. `grep -iE "encaiss"` sur les noms : 0 | **RETIRER** l'onglet. Aucune liste servie au comptable. |
| `portRapprochementProvider` `port_rapprochement.dart:189` | `comptable/encaissements/rapprochement/panneau_rapprochement.dart:134`, `donnees_rapprochement.dart:19-40` | Onglet Rapprochement (`app_router.dart:2831`). COMPTABLE | Aucun. `grep -il "transactions_bancaires\|releve_bancaire\|bank_transaction"` : 0. `lister_rapprochements_candidats` concerne l'import des candidats (`20261022000600`), autre sujet | **RETIRER**. Aucune transaction bancaire en base. |
| `portObligationsContractuelsProvider` `port_obligations_contractuels.dart:274` | `comptable/contractuels/contractuels_commun.dart:68-101`, `obligation_contractuel_page.dart:84,107`, `nouvelle_obligation_page.dart:141` | Onglet Contractuels (`app_router.dart:2683`, `:2695`, `:2704`). COMPTABLE | Aucun. `grep -il "contractuel"` : seulement `0027_maj_profil_enseignant.sql`, sans rapport | **RETIRER**. |

### Zone foyer (propriétaire : foyer)

| Port | Écrans qui le lisent | Entrée et visibilité | Serveur | Décision |
|---|---|---|---|---|
| `portRecusProvider` `core/capacites/port_recus.dart:32` | `foyer/fiche/finances_page.dart:953` (`BoutonRecu`) | Fiche élève, Finances (`app_router.dart:1293`). Bouton « Télécharger le reçu » posé dès qu'une période est financée (`finances_page.dart:805-808`). L'appui affiche « reçu indisponible » (`:977-978`). **OUI** (famille ayant payé) | Aucun. Le serveur rend `'recu', NULL` (`20261017160100_bf1_02_finances_profil.sql:265`). `grep -iE "recu\|receipt"` sur les noms : 0 | **RETIRER** le bouton. Une famille qui a payé tombe sur un mur. Un vrai reçu demande une génération de document côté serveur. |
| `foyerTitulaireProvider` `foyer/place_adulte.dart:135` | `foyer/foyer_page.dart:182,195` ; invalidé dans `reprise_foyer.dart:582`, `invitation_conjoint.dart:429,782`, `sortie_forfait.dart:368` | Ma famille (`app_router.dart:1104`). Sur `CapaciteIndisponible`, la page montre le Foyer du tuteur **sans message** (`foyer_page.dart:181-202`). Seule perte : la ligne « Forfait famille » de l'adulte titulaire. **NON** | **Partiel** : `invitations_foyer` (`0053_invitations_foyer.sql`), `mon_role_foyer`, `inviter_conjoint`, `renvoyer_invitation_conjoint`, `annuler_invitation_conjoint` (branchés, `main.dart:799-806`). Aucune lecture de « titulaire et sa place ». `grep -il "foyer_titulaire\|titulaire_du_foyer"` : seulement une politique de `0053` | **BRANCHER**, petite RPC à écrire sur ces tables. Rien d'indisponible n'est montré aujourd'hui, mais l'invitation du conjoint, déjà servie, n'a pas d'entrée depuis Ma famille. À vérifier : une autre entrée vers `inviter` (`routes_n2_foyer_adulte.dart:81`). |
| `portSortieForfaitProvider` `foyer/sortie_forfait.dart:76` | `sortie_forfait.dart:344` (`_PageSortie`) | Ouvert par `PlaceConjointPage` (`:105`) et `ForfaitFamillePage` (`:181`), **jamais créées hors démo** (`grep -rn "PlaceConjointPage\|ForfaitFamillePage" lib` : seulement leur définition). **NON** | Aucun. `grep -il "sortie_forfait\|quitter_forfait\|sortir_du_forfait"` : 0 | **RETIRER**. Code non atteint, aucun serveur. |

### Zone classe_tuteur (propriétaire : classe_tuteur ; port dans core/capacites)

| Port | Écrans qui le lisent | Entrée et visibilité | Serveur | Décision |
|---|---|---|---|---|
| `portCatalogueClassesProvider` `core/capacites/port_catalogue_classes.dart:163` | `classe_tuteur/catalogue_classes_page.dart:72,199` ; entrées `suivi_famille/suivi_famille_page.dart:156`, `accueil_famille/accueil_famille_page.dart:468`, `foyer/fiche/inscription_page.dart:118` | Route `/tuteur/classes/catalogue` (`app_router.dart:1012`). Les trois entrées lisent `catalogueClassesOuvert`, **faux en production** (`port_catalogue_classes.dart:168-173`) ; elles mènent au parcours offre puis horaire. URL tapée seulement. **NON** | Aucun. `grep -il "classes_compatibles\|catalogue_classes\|classes_ouvertes"` : 0 | **RETIRER** la route et la page. Le parcours offre puis horaire remplace le catalogue (DECISION-OFFRES-GROUPES-2026-10-09, cité dans le fichier). |

### Zone admin_configuration_politique_kyc (propriétaire : admin_configuration_politique_kyc ; port dans core/capacites)

| Port | Écrans qui le lisent | Entrée et visibilité | Serveur | Décision |
|---|---|---|---|---|
| `portPolitiqueRevueKycProvider` `core/capacites/port_politique_revue_kyc.dart:58` | `admin_configuration_politique_kyc/politique_revue_kyc_page.dart:55` | Route `app_router.dart:2487`. L'onglet n'existe que si `peutReglerPolitiqueKycProvider` est vrai (`admin_domaine.dart:242-246` ; `port_politique_revue_kyc.dart:74-78`), toujours faux ici. URL tapée seulement. **NON** | **Partiel** : `private.super_admin_kyc`, `kyc_super_admin_exception_active()` (`0088_kyc_super_admin_gender_exception.sql:6,19`). Les RPC attendues `get_kyc_review_policy` et `set_kyc_review_policy` (`port_politique_revue_kyc.dart:1-3`) : absentes (`grep -il "kyc_review_policy"` : 0) | **RETIRER** la route. Déjà invisible ; la règle de genre est déjà appliquée par le serveur dans `read_kyc_documents` (`0088…sql:57-69` ; à vérifier : une migration plus récente a pu la redéfinir). |

---

### Résumé chiffré (30 ports)

| Décision | Nombre | Ports |
|---|---|---|
| **BRANCHER, serveur existant** | **1** | `portAgeEleveProvider` (`student_profiles.student_type`, déjà lu par `accueil_accessibilite_supabase.dart`) |
| **BRANCHER, serveur à écrire** | **1** | `foyerTitulaireProvider` (petite RPC sur `invitations_foyer` et `mon_role_foyer`) |
| **RETIRER** | **28** | tous les autres |

Les 28 à RETIRER, par urgence (11 + 6 + 11) :

- **Visibles aujourd'hui avec un « indisponible » : 11 ports, à faire d'abord.**
  - Pour le directeur : Studio (`portStudio`, `portActiviteStudio`, `portElementsEnregistres`),
    onglet Modération (`portModeration`), Vue globale de la Finance (`portFinanceDirection`),
    onglet Réserve et délégation (`portDelegationFinance`, `portPolitiqueReserve`),
    « Payer la sélection » (`portPayout`, à vérifier à l'écran) et « export indisponible »
    (`portExportRapports`) dans Paie enseignants.
  - Pour la famille, l'enseignant et l'adulte : bloc des cartes de classe (`portCartesClasse`).
  - Pour une famille qui a payé : bouton du reçu (`portRecus`).
- **Visibles seulement pour un compte comptable : 6 ports.** `portAujourdhuiComptable` (sa page
  d'arrivée), `portTresorerie`, `portEncaissements`, `portRapprochement`,
  `portObligationsContractuels`, `portBeneficiairesPaiement`. Urgents dès qu'un comptable est
  invité. Inconnu : en existe-t-il un en production ?
- **Déjà invisibles, simple nettoyage : 11 ports.** `portEnregistreurVocal`, `portLectureVocale`,
  `portEnvoiVocal`, `portCommunaute`, `choixPieceCommunaute`, `portGardePromotion`,
  `portPolitiquePiecesJointes`, `portControleDelegation`, `portCatalogueClasses`,
  `portSortieForfait`, `portPolitiqueRevueKyc`.

Deux ports sans message « indisponible » mais pas neutres pour autant :
`portAgeEleveProvider` fait vouvoyer un enfant dans `/salle` ; `foyerTitulaireProvider` cache la
ligne « Forfait famille » de l'adulte titulaire.

### Deux adaptateurs de Codex signalés par le garde-cap (TRI-CODEX B, 11/11/2026)

`DemandesHorairesSupabase` et `ResumeSeanceFamilleSupabase` existent seulement sur d'anciennes
branches de Codex (`docs/orchestration/BR1-CARTE-BRANCHEMENT.md:187` : « PRÊT À BRANCHER (fusion
codex) »). Sur `main`, **leurs ports n'existent plus** :

| Adaptateur | Port visé | État sur `main` | Qui sert déjà l'écran | Décision proposée |
|---|---|---|---|---|
| `DemandesHorairesSupabase` | `core/offres/port_demandes_horaires.dart` | supprimé, commit `fccd2f6b8` (PR 204, M1-SUPPR : doublon de `admin_regroupements`, `M1-MODULES-EN-DOUBLE-2026-11-03.md:51`) | parcours famille : `portFriseDemandesProvider` (`FriseDemandesSupabase`) et `portSuiviDemandesProvider` (`DemandesSuiviSupabase`), `lib/main.dart:471-478` ; regroupement côté direction : `admin_regroupements`, branché | **ni brancher ni retirer** : rien à faire sur `main`, l'adaptateur reste sur sa branche |
| `ResumeSeanceFamilleSupabase` | `core/capacites/port_resume_seance_famille.dart` | supprimé, commit `735ffd14a` (PR 388, feu vert du directeur du 08/11 : non importé en production) | aucun écran ne le lisait (`INVENTAIRE-NON-BRANCHE-2026-10-31.md:47`) | **ni brancher ni retirer** : rien à faire sur `main` |

Preuve : `git grep -l "DemandesHorairesSupabase\|ResumeSeanceFamilleSupabase" origin/main` ne rend que le
document BR1 ; `grep -rn "DemandesHoraires\|ResumeSeanceFamille" lib` ne rend rien.

### Réserves du garde-cap sur le §6 (11/11/2026)

**c) Le reçu : l'écran n'est PAS retiré, c'est une preuve de paiement.** Vérification faite par
lecture du dépôt (`main` `b86dbc9d9`), rien n'est lu en production :

- **Aucune RPC de lecture d'un reçu.** Le serveur rend `'recu', NULL` dans les mouvements du
  profil (`supabase/migrations/20261017160100_bf1_02_finances_profil.sql:265`). Les factures
  existent côté serveur (`factures_mensuelles`, `emettre_factures_mois`,
  `20261017171000_fac_b_01_factures_mensuelles.sql:369`, redéfinie par
  `20261102600000_b4_factures_et_relances_planifiees.sql:100`), mais aucune fonction ne les rend à
  une famille : `git grep -n "CREATE.*FUNCTION public\.[a-z_]*factur" origin/main -- supabase/migrations`
  ne trouve que `emettre_factures_mois`. **C'est une dette finance pour le directeur.**
- **Un e-mail existe, mais ce n'est pas un reçu.** Quand Stripe confirme un paiement
  (`checkout.session.completed` ou `async_payment_succeeded`, « paid »), une notification
  `paiement_recu` est créée, et le déclencheur `courriel_notification` met l'e-mail en file dans
  `courriels_sortants` (`20261103400000_paiement_recu_courriel.sql:1-3`, `:146-160`). Son texte :
  « Le paiement de {montant} est reçu. Le solde est à jour dans l'application. »
  (`supabase/functions/_shared/courriel/modeles_fr.ts:291-297`). C'est un avis de paiement, pas un
  reçu (ni facture, ni détail, ni pièce jointe). La migration le dit elle-même : « La page de
  paiement Stripe envoie son propre reçu seulement si l'option est activée dans le tableau de
  bord » (`:6-8`), ce que le dépôt ne peut pas prouver.
- **Envoi en production : jamais.** Le pilote a lu `courriels_sortants` en production le
  11/11/2026 : **aucune ligne `paiement_recu`, quel que soit le statut.** Aucun e-mail de paiement
  n'a donc jamais été envoyé en production à cette date (lecture du pilote, pas de A).
- **Conséquence, selon la règle du garde-cap : l'écran reste tel quel.** Il ne dit pas « Votre reçu
  vous est envoyé par e-mail ». Le bouton « Télécharger le reçu » et sa phrase « reçu
  indisponible » restent jusqu'à la RPC du reçu (dette finance, au directeur).

**d) Le comptable : on ne retire un écran que s'il ne sert à aucun geste réel aujourd'hui.** Les
six décisions « RETIRER » du comptable (Aujourd'hui, Trésorerie, Encaissements, Rapprochement,
Contractuels, Bénéficiaires) sont donc **à revoir écran par écran au lot comptable**, avec pour
chacun le geste réel qu'il sert ou non, et sans aucun calcul financier côté Flutter. Elles ne
sont pas des décisions arrêtées.

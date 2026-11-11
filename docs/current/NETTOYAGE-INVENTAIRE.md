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
| `lib/features/mon_espace_adulte/mon_espace_adulte_page.dart` | démo seulement ; 24 fichiers de test | 15/11 | brancher à l'étape 3 (FN-112) comme prévu | mon_espace_adulte |
| `lib/features/recherche/domaines/finance_communications/moteur_finances.dart` | `moteurs_finance_communications.dart:8` (toléré aussi) | 30/11 | étape Listes | recherche |
| `lib/features/recherche/domaines/finance_communications/moteurs_finance_communications.dart` | aucun dans `lib/` ; 2 tests | 30/11 | étape Listes | recherche |

Proposition (pour le pilote, pas pour ce relevé) : que `verifier_branchement` échoue sur une
échéance dépassée.

## 2. Démo et bouchons atteignables en production

Galerie et playground exclus.

### 2.1 Bouchons « indisponible » lus par un écran

`INVENTAIRE-NON-BRANCHE-2026-11-11.md` les liste déjà (lignes 53, 72-73, 84, 96-97, 123-139). Ils
restent tous des bouchons au 11/11 : 30 ports lus par un écran, aucun surchargé dans
`lib/main.dart`. Ce sont des lots serveur à finir, pas du nettoyage. Deux n'ont aucun écran :

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

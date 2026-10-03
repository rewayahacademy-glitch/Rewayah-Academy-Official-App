# VERIF-PREP : préparation des rôles Finance (FI-0) et Supports et tableau (TB-0), et leçons des rôles

Session 90248232, 03/10/2026, lecture seule (aucun commit, aucune écriture au tableau). Branche de pilotage `pilotage/tuteur-v1` @ `8e5f5ba3` au premier passage, @ `19b40563` à la reprise (aucun changement sur `17_finance`, `18_supports_tableau` ni `LECONS_DES_ROLES.md` entre les deux : `journal_reprise.txt:3`). Worktree `D:\RA_TUTEUR\pilotage-git`. Livraison contrôlée : commit `9855fb63` (« Ménage du 02/10 », 02/10 22:34). Les citations de code ont été relues dans `D:\RA _APP\RA -OFFICIAL-APP` aux commits nommés par les documents (`5629693` ui/eleves-adultes-v1, `a8dfcb3` ui/admin-v1, `0796f75` corrections/revue-directeur-2026-10, `7885b35` ui/accessibilite-v1), et `af9f408b` (ui/finance-v1, FI-1b) pour l'accent de profil.

## Verdict : VÉRIFIÉ AVEC DÉFAUTS (un moyen, deux mineurs), après reprise

FI-0 et TB-0 tiennent la promesse de leur fiche : les deux documents du directeur sont dans `V/` avec toutes leurs images, **identiques octet pour octet aux originaux** (17 fichiers sur 17), les 24 règles FI et les 30 règles TB renvoient toutes à un § qui existe dans la source, les **22 citations fichier:ligne** du tableau §3 (9 FI, 13 TB) disent ce que le document affirme, et aucune valeur commerciale (prix, remise, délai, taux, capacité) n'est inventée. Chacune des 15 leçons cite au moins une preuve qui existe.

Trois défauts, aucun dans les règles FI1 à FI24 elles-mêmes :
- **moyen** : FI-0 lit mal le guide sur l'accent de profil (inventaire §4 l. 57, RISQUE l. 185-186, découpage FI-2) ; l'erreur vit encore dans la note de l'étape FI-2 du tableau, et la ligne « TH-2 » où la revue FI-1a l'a envoyée est une autre étape (thème monochrome) qui ne la porte pas (FI-ACCENT-1) ;
- **mineur** : TB21 perd la condition « lorsque Écrire est actif » pour le stylet, et la revue TB-1a a validé ce texte sur la foi du code (TB-STYLET-1) ;
- **mineur** : « 12 conflits » au lieu de 14 pour une fusion qui n'aura plus lieu (TB-CONFLITS-1).

Le premier passage avait écrit « VÉRIFIÉ, avec un défaut mineur », « 29 citations » et laissé l'identité des copies « non prouvée » : ces trois points sont corrigés (voir « Reprise après contradiction »).

## Verrou

Sans objet : aucune commande Flutter (pilotage seulement). Les commandes git et leur sortie sont dans `journal_controles.txt` (premier passage) et `journal_reprise.txt` (reprise, dernier passage, 03/10).

| Commande | Résultat |
|---|---|
| `git diff --stat 9855fb63 HEAD -- <guide V4> <plan V2> FI-BR.md TB-BR.md LECONS_DES_ROLES.md` | vide : sources et leçons inchangées depuis la livraison |
| `git diff --stat 8e5f5ba3 19b40563 -- 17_finance 18_supports_tableau LECONS_DES_ROLES.md` | vide (`journal_reprise.txt:3`) |
| `git diff 9855fb63 HEAD -- 17_finance/00_REPRISE.md 18_supports_tableau/00_REPRISE.md` (lignes retirées) | 2 lignes de `17_finance/00_REPRISE.md` §4, réécrites par FI-1a pour ajouter « Contredit par la revue » ; les règles FI1 à FI24 et TB1 à TB30 ne bougent pas |
| `git hash-object --no-filters <original>` contre `git ls-tree -r 9855fb63 17_finance/V/ 18_supports_tableau/V/` | **17 / 17 identiques** (guide `93ad84b1…`, plan `2f7adaa5…`, 15 PNG) (`journal_reprise.txt:5-23`) |
| octets et CR des deux `.md` du worktree | guide 38 411 = 36 801 + 1 610 CR ; plan 69 351 = 68 678 + 673 CR ; `core.autocrlf=true` (`journal_reprise.txt:24-26`) |
| `git grep -i -E "accent.{0,12}profil\|profil.{0,12}accent\|teinte.{0,6}profil\|profile.?accent"` sur `5629693`, `a8dfcb3`, `0796f75`, `af9f408b` (lib) | aucun résultat : aucun accent de profil n'existe dans le code (`journal_reprise.txt:60-63`) |
| `git cat-file -t` sur 11 commits cités | 11 × `commit` |
| `git rev-list --count d44710a..a8dfcb3` / `..5629693` | 47 / 79 (FI §3 dit 47 et 79) |
| fichiers communs `d44710a→a8dfcb3` ∩ `d44710a→5629693` | 12, la même liste que FI §3:42 |
| `git grep -i -E "StoreKit\|Play ?Billing\|in_app_purchase\|taxe incluse\|J\+14\|balance *> *0"` sur `a8dfcb3`, `5629693`, `058c525` (lib, fr.i18n.json) | aucun résultat (FI §5 « CONFORME » tenu) |
| `git rev-list --count 0796f75..<tip au 02/10 21:35>` accessibilité / enseignant / contrôleur | 31 / 2 / 19 (TB §3 dit 31, 2, 19) |
| `git diff --shortstat 0796f75...39a702ae -- salle_page.dart` | 6 + 1 = 7 lignes (TB §3 dit 7 lignes) |
| `git merge-tree --write-tree 0796f75 7885b35b` | **14** `CONFLICT` (TB §3 dit 12) |

## 1. Sources copiées dans V/

| Rôle | Attendu (fiche de l'étape) | Constat |
|---|---|---|
| FI-0 | guide V4 + 7 maquettes du tuteur | `17_finance/V/REWAYAH_FINANCE_FRONTEND_GUIDE_V4_2026-10-02.md` (1 610 lignes, 36 801 octets dans git, 16 sections + §0) et `01` à `07_*.png` ajoutés par `9855fb63`. Les maquettes `08` à `10` sont arrivées après (`d9a83140`, FI). `00_REPRISE.md:16-27` liste chaque image avec son § du guide. |
| TB-0 | plan V2 + 8 planches | `18_supports_tableau/V/REWAYAH_PLAN_SUPPORTS_TABLEAU_V2.md` (673 lignes, 68 678 octets dans git, 69 351 dans le worktree à cause des fins de ligne CRLF ; 23 sections : `00_REPRISE.md:23` dit « 68 Ko, 23 sections ») et 8 PNG, tous ajoutés par `9855fb63`. |

**Prouvé à la reprise : les copies sont identiques octet pour octet aux fichiers reçus du directeur.** Originaux trouvés dans `C:\Users\dell\Downloads\à faire\finance - business plan rewayah\` (guide + 7 PNG) et `C:\Users\dell\Downloads\à faire\tableau et affichage supports\` (plan + 8 PNG). Le `git hash-object --no-filters` de chaque original est égal au blob de `9855fb63` ; tailles égales ; SHA-256 relevés (`journal_reprise.txt:6-23`). Les maquettes Finance ont seulement été renommées (« Image ChatGPT 2 oct. 2026, 21_30_46-1.png » → `01_mobile_sombre_paiement_confirme.png`, etc.).

## 2. Chaque règle renvoie-t-elle à un § qui existe ? (toutes les règles, pas un échantillon)

### Finance, FI1 à FI24 (`17_finance/00_REPRISE.md:228-253`)

Les § du guide existent tous (titres relevés : §0:11, §1.1:30 à §1.9:271, §2:281, §3:332 à §3.8:458, §4:474, §5.1:567 à §5.7:747, §6:809, §7:846, §8 lots F0 à F8:895-1185, §10:1297, §11.1:1347 à §11.7:1447, §12:1459, §13:1515, §14:1536, §15:1561, §16:1597). FIN4-02 à FIN4-17 : guide:35-55. « F4 », « F5 », « F8 » = lots du §8 (guide:1051, :1085, :1185).

| Règle | § cité | Le § dit-il la règle ? |
|---|---|---|
| FI1 | §1.1 FIN4-06, 07 ; §16 | oui, guide:39-40, :1603-1604 |
| FI2 | FIN4-08 ; §13 | oui, guide:41, :1529 |
| FI3 | FIN4-02 à 05, 09 | oui, guide:35-38, :42 |
| FI4 | FIN4-10 à 17 | oui pour 2 séances, gratuit, hors KPI (guide:48-53) ; l'affichage « n/2 » vient du lot F5 (guide:1099), non cité |
| FI5 | §1.3 ; §5.2 | oui, guide:72, :634, :647 |
| FI6 | §1.3 ; §7 ; §13 ; §14 | oui (guide:72, :1525, :1551) ; le §7 cité ne porte pas la règle, qui est aussi au lot F1 (guide:964) et au §1.8 (guide:269) |
| FI7 | §4 ; §5.3 | oui, guide:498-507 |
| FI8 | §1.6 ; §5.3 | oui, guide:199-206, :653-667 ; « le serveur l'arrête » est une décision de FI-0 (§5 ÉCART F12, `00_REPRISE.md:170-172`), pas une phrase du guide |
| FI9 | §1.6 ; §5.4 ; F4 | oui, guide:214-223, :698, :1078 |
| FI10 | §1.6 | oui, guide:180-184 |
| FI11 | §1.7 | oui, guide:229-240 ; « la durée de la politique » remplace les 7 jours (guide:238), sans valeur nouvelle |
| FI12 | §1.7 ; F5 | oui, texte enfant mot pour mot guide:250-251 ; guide:1113-1114 |
| FI13 | §1.8 | oui, guide:264-269 |
| FI14 | §7 ; §11.3 ; K-41.5 | oui, guide:883-887, :1389-1405 ; « unités mineures + code ISO » vient de K-41.5 et de l'ÉCART E2 |
| FI15 | §3 ; §11.5 | oui, guide:338-373, :433, :449 ; la règle dit bien « ni un statut, ni une classe, ni une alerte » (`00_REPRISE.md:244`). C'est l'inventaire du même document (l. 57) qui la contredit : défaut FI-ACCENT-1 |
| FI16 | §3.5 | oui, guide:417-425 |
| FI17 | §11.4 ; WCAG 1.4.1 | oui, guide:1409-1416 |
| FI18 | §7 ; K-55 | oui, guide:873-877 |
| FI19 | §6 ; §11.6 ; §11.7 | oui, guide:838-842, :1435-1455 |
| FI20 | §1.4 ; §5.5 | oui, guide:102-140, :709-725 |
| FI21 | §1.5 ; §5.6 | oui, guide:168, :739-745 ; « aucun graphique sans le nombre exact » vient du lot F7 (guide:1181), non cité |
| FI22 | §5.7 ; §8 F8 | oui, guide:749-805, :1205-1209 |
| FI23 | §4 ; §1.9 | oui, guide:561, :275-277 |
| FI24 | §2 ; §11.1 ; §11.2 ; K-61.4 | oui, guide:306-318, :1349-1385 |

### Supports et tableau, TB1 à TB30 (`18_supports_tableau/00_REPRISE.md:140-169`)

Les § du plan existent tous (§1:11 à §23:620 ; §4.1:75, §4.2:88, §4.3:109 ; §18.1:433, §18.2:458, §18.3:464 ; §19.1:476 à §19.6:523 ; UX-03, UX-12, UX-20, UX-21 : plan:628, :637, :645, :646). « §22.6 » (`00_REPRISE.md:90`) et « §9.5 » (`TB-BR.md:47`) sont des points numérotés de liste (plan:597, :212), pas des titres : ils existent.

| Règle | § cité | Le § dit-il la règle ? |
|---|---|---|
| TB1 | §1, §13, §21 | oui, plan:15-16, :291, :580-582 |
| TB2 | §2, §8 | oui, plan:36, :188-190 |
| TB3 | §2, §3 | oui, plan:42-44, :53 |
| TB4 | §3 | oui, plan:55-57 |
| TB5 | §2, §3 | oui, plan:44-47, :63 |
| TB6 | §3, §12 | oui, plan:69-71, :273-275 |
| TB7 | §4.1, §18.1 | oui, plan:77-81, :437, :450 |
| TB8 | §18.2, UX-03 | oui, plan:460-462, :628 |
| TB9 | §4.2, §17, §18.3 | oui, plan:90, :412, :466 |
| TB10 | §4.2, §7 | oui, plan:98-107, :169 |
| TB11 | §4.3, §19.6 | oui, plan:111-113 ; « cibles de 48 » est au §6 (plan:156), non cité |
| TB12 | §4.3, UX-12 | oui, plan:115, :637, :525 |
| TB13 | §1, §5, §8 | oui, plan:18, :202 |
| TB14 | §5, §19.3 | oui, plan:129-131, :501-503 |
| TB15 | §4.3, §12 | oui, plan:117, :277 |
| TB16 | §5, UX-21 | oui, plan:126-127, :646 |
| TB17 | §6, §18.3, §19.4 | oui, plan:146-150, :468, :509-511 |
| TB18 | §6, §18.1, §20 | oui, plan:435, :456, :547 |
| TB19 | §9 | oui, plan:208-215 |
| TB20 | §9 | oui, plan:219 |
| TB21 | §7 | **en partie** (corrigé à la reprise) : le doigt, les deux doigts et le balayage suivent plan:165, :167 ; mais plan:164 dit « stylet pour l'encre **lorsque Écrire est actif** », et TB21 écrit « le stylet écrit s'il est détecté (`PolitiqueSaisie`) » (`00_REPRISE.md:160`), sans la condition. Défaut TB-STYLET-1 |
| TB22 | §5, §20 | oui, plan:135, :529 |
| TB23 | §11, §12, §22 | oui, plan:253, :285, :606 ; la phrase « Les notes sont conservées dans cette séance uniquement. » est au §20 (plan:561), non cité |
| TB24 | §10, §12, §19.5 | oui, plan:245, :249, :279, :517-518 |
| TB25 | §6, §18.3 | oui, plan:156, :470 |
| TB26 | §3, §6, K-12 | oui, plan:65, :160 ; K-12 (150–300 ms, `YAADEN_RULES.md:44`) contient 180–250 ms |
| TB27 | §6, §11 | oui, plan:158, :259 |
| TB28 | §13 | oui, plan:310 |
| TB29 | §4.2 corrigé par MA-CMD-1 | oui, plan:107 ; MA-CMD-1 au tableau, note « 02/10 14:36 » |
| TB30 | §22 | oui, plan:586, :616 ; la liste des statuts omet « testé sur staging » et « déployé » (plan:616) |

## 3. Citations fichier:ligne recontrôlées (au hasard, pas les premières)

22 citations : 9 FI et 13 TB. Le journal `journal_controles.txt:49-162` contient 24 blocs de fichiers et une ligne `pubspec.yaml`. Les 22 citations s'appuient sur 20 de ces blocs (9 FI, 11 TB) et sur la ligne `pubspec` ; la 22e, `compaction_trait.dart:91` et `:17`, est relue dans `journal_reprise.txt` (« Objection 4 »). Les 4 blocs restants (`port_paiements_foyer.dart`, `app_router.dart:663` sur 5629693, `couche_annotation.dart`, `salle_seance.dart:161` sur 7885b35) ont servi à contrôler l'inventaire et ne sont pas comptés ici.

| Rôle | Citation | Ligne lue | Conforme |
|---|---|---|---|
| FI | `choice_card_group.dart:78` (FI §4:64) | `class ChoiceCardGroup` | oui |
| FI | `port_acces_foyer.dart:7`, `:39` (§4:54) | `enum EtatAccesAffiche`, `class AccesBeneficiaire` | oui |
| FI | `app_palette.dart:306`, `:309` (§4:57) | `teintesIdentite`, `teinteGroupe(int index)` ; le commentaire dit « 32 paires » | **ligne exacte, lecture fausse** (corrigé à la reprise) : `:308` dit « La teinte d'identite d'un groupe », `:312-315` donne la même table aux couvertures, et `palette_groupe.dart:21` l'emploie pour les classes. Ce ne sont pas des « accents de profils déjà présents » (guide:465). Défaut FI-ACCENT-1 |
| FI | `admin_domaine.dart:33`, `:99`, `:124`, `:153` (§3:39, §4:68) | `finance,` ; `finance … => null` ; 5e entrée ; `ongletsPedagogie()` | oui |
| FI | `port_recharge_foyer.dart:66-78`, `:147` (§5:165, :170) | « une offre, jamais un montant saisi (F11) » ; « jamais additionné dans Flutter » | oui |
| FI | `fr.i18n.json:4162-4169` (§5:175) | « 5,00 € (démonstration) » à « 40,00 € (démonstration) » | oui |
| FI | `ADMIN_FINANCE_CONFIGURATION.md:72` (§5:183, FI-BR-14) | `wallets`, `wallet_entries` (existent, sans interface) | oui |
| FI | `demo_adulte_page.dart:1248` (§4:52) | `EcranDemoAdulte.recharge => RechargeFoyerPage(` | oui |
| FI | `app_router.dart:1020-1024` sur a8dfcb3 (§4:72) | route `Routes.comptable` → `ComptePage()` | oui |
| TB | `zone_support.dart:759` (TB §4:59) | `class _RienPartage` | oui |
| TB | `panneau_eleves.dart:504` (§4:61) | `class _ActionsEleve` | oui |
| TB | `evenements_outils.dart:238`, `:268` (§4:70) | `EvenementMasquage`, `DiffusionOutils` | oui |
| TB | `annotation_layer.dart:11,46,82,126,247` (§4:68) | `PorteeAnnotation`, `OutilTrait`, `PointNormalise`, `TraitVectoriel`, `AnnotationLayer` | oui |
| TB | `0032_tc_catalogue.sql:404` (§6:107, TB-BR-13) | `create table public.session_shared_content` ; l. 410 `display_mode in ('page', 'verse', 'focus')` | oui |
| TB | `compaction_trait.dart:9-11` (§6:108) | RDP écrit à la main, `pubspec.yaml` gelé | oui |
| TB | `app_mouvement.dart:25,28,53` (§4:77) | 180, 220, 1200 ms | oui |
| TB | `salle_seance.dart:1250` (§4:54) | `class _BarreBasse` | oui |
| TB | `commandes_masquables.dart:48` sur 7885b35 (§4:55) | `delaiParDefaut = Duration(seconds: 4)` | oui |
| TB | `salle_page.dart:1000` (02_DECOUPAGE TB-11a) | `class _CommandesControle` | oui |
| TB | `catalogue_local.dart:15` (TB-BR-19) | « aucun bucket Storage n'existe en dehors de `kyc` et `avatars` » | oui |
| TB | `compaction_trait.dart:91`, `:17` (`00_REPRISE.md:69`) — remplace la ligne fausse du premier passage | `class TraitEnCours` ; `List<PointNormalise> simplifierTrait(` (`journal_reprise.txt`, « Objection 4 ») | oui. La valeur « 3 points » de TB-BR-02 (`TB-BR.md:8`, `TraitEnCours.pointsParPaquetParDefaut`, sans numéro de ligne) est bien `compaction_trait.dart:105` dans la classe ouverte en `:91` |
| TB | `pubspec.yaml:63` (TB-BR-09) | `livekit_client: ^2.12.0` | oui |

Planches regardées (outil Read sur le PNG) : planche 2 « Trois écrans, visio et outils au toucher » (onglets Support / Outils, outils Stylo, Surligner, Gomme, Annuler, sans Pointeur ni Terminer, caméra en appareil photo) et planche 6 « Commandes ouvertes » (« Page 24 », Bibliothèque sous Focus, avatar en grand rond hors capsule, caméra vidéo) : conformes à ce qu'en dit `18_supports_tableau/00_REPRISE.md:97` et `:101`. Maquette 02 « Mariam, Finances » : « 30 $ / mois », « Remise famille −5 $ », « 31 décembre 2024 », comme le dit `17_finance/00_REPRISE.md:31`.

## 4. Valeurs inventées

Aucune valeur commerciale inventée. Chaque valeur relevée dans les documents FI et TB est dans la source :
- FI : 50/60 USD, rangs 3 et 4 à −5 et −7, base 4 et plafond 7, capacités 5/6/4, minimum 4, groupes 3 et 4, 7 jours, 30/35/40 %, 8 USD « janvier », 2 essais (guide:34, :61-64, :102-109, :164-166, :238, :258, :48) ; K-12 « 150-300 ms » (`YAADEN_RULES.md:44`).
- TB : 4 s, 180 à 250 ms, 48 dp, 40 ms, 1 200 et 1 300 octets, 15 Kio (plan:437, :160, :156, :228, :241) ; 180/220/1200 ms et 3 points lus dans le code (ci-dessus).
- Faits de dépôt recomptés : 47 et 79 commits, 12 fichiers communs, 31/2/19 commits, 7 lignes, 32 paires, version `^2.12.0` : exacts. **Un seul faux : « 12 conflits » (14 en réalité).**

## 5. LECONS_DES_ROLES.md : chaque leçon a-t-elle sa preuve ?

| Leçon | Preuve contrôlée | Constat |
|---|---|---|
| 1 | `05_recette/c,e,o/RAPPORT.md:3` « Commits locaux, aucun push » ; commit `0b01297` (EN-RC final) ; dépôt `A-poste-B-eteint-2026-10-01` cité dans les étapes CT-7, EN-7c, MA-8 du tableau | oui |
| 2 | `05_recette/CL/RAPPORT.md:58` (CL-3 et CL-6 « marquées comme en cours, en réalité terminées ») | oui |
| 3 | `05_recette/AD/HL-A-5.md:1` (AD-6 à AD-10 = 5 étapes) ; `12_enseignant/EN-BR.md:97` (« K-47 … introuvable ») ; `REVUE_EA-R.md:9`, `:17`, `:37` (M1, M3 ANNULÉS) | oui |
| 4 | `05_recette/c/RAPPORT.md:148` (liste étirée sur 1 100 px) ; `05_recette/B/RAPPORT.md:95` (CTA sans flèche) | oui |
| 5 | `05_recette/B/RAPPORT.md:116` (§9 : planches « montrent encore l'état du 24/09 ») | oui |
| 6 | `05_recette/c/RAPPORT.md:69`, `o/RAPPORT.md:75`, `e/RAPPORT.md:89` (analyse et suite complètes, build web non lancés) | oui |
| 7 | `REVUE_CL-4.md:29` (M1) ; `REVUE_MA-R.md:16` (4 tests sautés) ; `AD/RAPPORT.md:10` (« volontairement sautés pour garder la suite verte ») ; `REVUE_EA-R.md:94` (m16) ; `REVUE_CT-R.md:31`, `:56` (B1) ; `P2-16/RAPPORT.md:66`, `:118` (images comptées par `pumpAndSettle`) | oui |
| 8 | `AD/RAPPORT.md:43` (6 commits), `:63-72` (8 écrans) ; `REVUE_EN-R.md:81` (M3) ; `REVUE_MA-R.md:30` (147 px), `:94` (« Mari / am ») ; `o/RAPPORT.md:69` (fenêtre de tablette) | oui |
| 9 | `REVUE_EA-R.md:54-57` (M5) ; `REVUE_CT-R.md:132` (m2) | oui |
| 10 | `REVUE_CL-4.md:36` ; `REVUE_CT-R.md:131` (m1) | oui |
| 11 | `REVUE_EN-R.md:44` (M1) ; `REVUE_MA-R.md:72` (M3) ; `A/RAPPORT.md:23` (consentements sans bouton) | oui |
| 12 | `REVUE_EN-R.md:160`, `:182` (m16, note 19), `:191` (« Amina », E20) ; `REVUE_CL-4.md:42` (M2) ; `REVUE_EA-R.md:82`, `:84` (m4, m6 « 60 jours ») | oui |
| 13 | `REVUE_EA-R.md:44-47` (M4, `_Carte`) ; `REVUE_AD-R.md:83` (M4, 57 pages), `:88-90` (M5, `LigneRubrique`), `:112-113` (m14, m15) ; `REVUE_MA-R.md:64` (M2), `:96`, `:122` (mineur 2, `setting_row`) | oui |
| 14 | `REVUE_EA-R.md:62` (M6) ; `REVUE_AD-R.md:74` (M3), `:111` (m13) ; `REVUE_EN-R.md:112` (M6) | oui |
| 15 | `REVUE_EA-R.md:30-33` (M2, F7) ; `REVUE_AD-R.md:60` (M1) ; `AD/RAPPORT.md:80` (« aucune URL de stockage ne part vers Sentry (corrigé) »), `:129` (purge des caches) ; `REVUE_CT-R.md:31` | oui |
| Annexe | commits `d7b006f` et `cef9fba` (sujet qui commence par un BOM), `ca841ef` (55 fichiers) ; `A/RAPPORT.md:36-41` (§2.1, « hors budget de temps ») ; `EA/RAPPORT.md:20` (« Méthode ») | oui |

Non vérifié ici (dépôts du tableau, que cette étape ne lit pas) : `A-q-20260927-323f1000`, `R-B-20261002-197748f8`, `R-B-20260927-4d0f6eb7`, `R-B-20260927-68274ea4`, `C-handoff-cloud`, `C-resultat-plan` (dont « 1377 libellés », « dix messages », « 23 boutons grisés »), « BENTO-1 demandé plus de 10 fois » (K-61.8). `B-style-reference` est confirmé par `12_enseignant/HANDOFF_POSTE_B.md:50` (« B-style-reference-2026-09-26 »). Chaque leçon garde au moins une preuve vérifiée en plus de ces dépôts.

## Captures

Aucune capture produite (pilotage seulement). Images des sources ouvertes pour le contrôle : `18_supports_tableau/V/Trois écrans, visio et outils au toucher-2.png`, `18_supports_tableau/V/Interface immersive, commandes pédagogiques ouvertes-6.png`, `17_finance/V/02_mobile_sombre_mariam_finances.png` (déjà dans le pilotage, pas recopiées).

## Défauts → étapes proposées

- **Moyen, FI-ACCENT-1 (proposée, voie FIN, pilotage seulement, à faire avant FI-2 ; aucune dépendance INTEG-RC-1, aucun code)** : l'accent de profil n'a aucune étape qui le porte, et le tableau dit encore le contraire de la revue.
  - Erreur de FI-0 : `17_finance/00_REPRISE.md:57` propose de prendre le bandeau du profil dans `teintesIdentite` par `teinteGroupe(index)` et écrit « Le guide §3.8 point 2 demande justement de réutiliser l'existant ». Même idée dans le RISQUE `:185-186` et dans `02_DECOUPAGE.md:32` (FI-2, « bandeau d'accent depuis `teintesIdentite` »). Or le guide dit que le bandeau « n'est PAS … une couleur de classe » (guide:366-371). Le §3.8 demande de réutiliser les accents « de profils » s'ils existent, sinon d'ajouter des jetons sémantiques (guide:465-466). Et le §0.4 approuve explicitement de nouvelles couleurs d'identité des profils (guide:22). Dans le code, `app_palette.dart:308` (5629693) appelle cette table « La teinte d'identite d'un groupe », `:312-315` la donne aux couvertures et `palette_groupe.dart:21` l'emploie pour les classes. Aucun accent de profil n'existe sur `5629693`, `a8dfcb3`, `0796f75` ni `af9f408b` (`journal_reprise.txt:60-63`). FI-0 se contredit lui-même : sa règle FI15 (`00_REPRISE.md:244`) dit que l'accent « n'est ni un statut, ni une classe ».
  - La revue FI-1a l'a vu (`UX_REVIEW_08_FINANCE.md:19`, C-6 `:152`, X-1 `00_REPRISE.md:139`, `02_DECOUPAGE.md:59`, `:75`) : « ne pas réutiliser `teinteGroupe` tel quel », « jusque-là, FI-2 ne pose aucune teinte de profil », et elle l'envoie « en TH-2 ». Mais :
    1. la note de l'étape **FI-2** au tableau (`a_faire`) dit toujours « Bandeau pris dans teintesIdentite par clé stable (aucune couleur nouvelle, K-37) » (`board/etapes/FI-2.json`, `journal_reprise.txt:64-81`). Une session qui prend FI-2 par K-60 lit cette note ;
    2. au tableau, **TH-2** est le « Thème 2 chrome / noir et blanc », en attente de « Fin de tous les rôles ». Ses relevés ne parlent pas de l'accent de profil (`board/etapes/TH-2.json`, `journal_reprise.txt:82-95`). `02_DECOUPAGE.md:75` l'appelle « NOUVELLE : TH-2 », alors que ce nom est déjà pris ;
    3. **FOY-COUL-1** (`a_faire`, CORR-2, demande du directeur du 01/10) donne une troisième version : « le tuteur choisit librement cette couleur », stockée par profil (BR-1) (`board/etapes/FOY-COUL-1.json`).
  - Remède proposé : (a) corriger la note de FI-2 au tableau dans le sens de la revue (aucune teinte de profil, jamais `teinteGroupe`) ; (b) poser la décision de l'accent de profil comme une ligne propre, ou comme un relevé daté sur TH-2, avec les trois options et leurs sources : jetons de profil distincts, guide §0.4 et §3.8 points 3 et 5 ; règle « profil et classe affichés ensemble ne partagent pas une teinte » ; couleur choisie par le tuteur, FOY-COUL-1. La décision revient au directeur, puisque §0.4 et K-37 se croisent ; (c) dans `17_finance/00_REPRISE.md:57`, barrer « Le guide §3.8 point 2 demande justement de réutiliser l'existant ». Aucune réouverture de FI-0 (K-38).
- **Mineur, TB-STYLET-1 (proposée, voie TB, pilotage seulement, à faire avant TB-7b ; aucune dépendance)** : TB21 (`18_supports_tableau/00_REPRISE.md:160`) écrit « le stylet écrit s'il est détecté (`PolitiqueSaisie`) ». Le plan dit « stylet pour l'encre lorsque Écrire est actif » (plan:164). Le code cité fait l'inverse : « **Le stylet ecrit toujours**, y compris avant que l'outil ne soit arme » (`couche_annotation.dart:38-39` sur 0796f75), et `appareilsDeDessin` rend toujours `stylus` (`:55-58`). La revue TB-1a a classé la ligne « Conforme (existant) » sur la foi de ce code (`UX_REVIEW_TB.md:198`). La note de TB-7b au tableau ne demande que « un doigt ne dessine qu'en Écrire » (`board/etapes/TB-7b.json`). Effet nul aujourd'hui : la couche est « dormant[e], jamais montée » (`00_REPRISE.md:66`). Effet probable demain : TB-7b gardera un stylet qui écrit en mode lecture. Remède : réécrire TB21 avec la condition du plan, corriger `UX_REVIEW_TB.md:198` en « Écart (existant) », et ajouter à TB-7b « le stylet n'écrit que si Écrire est actif » (test et capture). Comportement réel en salle non prouvé, puisque la couche n'est pas montée.
- **Mineur, TB-CONFLITS-1 (proposée, voie TB, sans dépendance)** : « 12 conflits » est faux, l'essai à blanc donne 14. `git merge-tree --write-tree 0796f75 7885b35b` (`journal_controles.txt:98-112`) : 14 fichiers, dont les 8 fichiers de code que `02_DECOUPAGE.md:59` nomme lui-même, les 2 slang et 4 tests. Erreur à trois endroits : `18_supports_tableau/00_REPRISE.md:39`, `QUESTIONS.md:14`, `02_DECOUPAGE.md:59`. Effet nul aujourd'hui : TB-F n'a plus de fusion à faire (décision de l'orchestrateur, `00_REPRISE.md:3-4`). Remède : écrire 14, ou barrer les trois lignes comme « sans objet depuis INTEG-RC-1 ».

## Remarques (aucune étape proposée)

1. Références de § incomplètes, sans valeur inventée : FI4 (« n/2 », lot F5 guide:1099), FI6 (§7 ne porte pas la règle ; lot F1 guide:964, §1.8 guide:269), FI8 (« le serveur l'arrête » vient de FI-0 §5), FI21 (lot F7 guide:1181), TB11 (48 dp au §6, plan:156), TB23 (phrase du §20, plan:561). À ajouter à la prochaine relecture des règles.
2. TB30 ne garde que cinq des sept statuts du plan (§22, plan:616) : « testé sur staging » et « déployé » manquent. C'est cohérent avec « le handoff n'autorise aucun déploiement », mais ce n'est pas écrit.
3. `17_finance/00_REPRISE.md:31` attribue « toute année 2024 » au guide §2 et §5.2 : le guide ne parle pas de 2024 ; l'année vient de la maquette 02 (« 31 décembre 2024 »). L'interdiction reste juste.
4. `LECONS_DES_ROLES.md` écrit `05_recette/b`, `05_recette/a` ; les dossiers s'appellent `B` et `A`. Sans effet sous Windows, mais un chemin cassé sous git ou Linux.
5. Identifiants absents de l'export du tableau (`board/etapes`), **résolus à la reprise** :
   - `PT-B-20260927-1ab2a969` (`18_supports_tableau/02_DECOUPAGE.md:168`) a été remplacée par CONTRASTE-SUPPORT-1. Preuve : `board/etapes/CONTRASTE-SUPPORT-1.json:9`, « — ancienne ligne PT-B-20260927-1ab2a969 ». Cette étape est `a_faire`, en attente de TH-2 ou HU-1, comme le dit `02_DECOUPAGE.md:168` (« Séparée (HU-1) »).
   - `EA-12a` (`LECONS_DES_ROLES.md:219`) n'est pas une étape du tableau (0 occurrence dans l'export). C'est une tâche de la recette EA : `05_recette/EA/RAPPORT.md:22` (« balayages transverses demandés par la tâche EA-12a ») et `:149` (« point ouvert #5 du rapport EA-12a »).
6. Le guide compte 1 610 lignes selon git ; `00_REPRISE.md:20` dit 1 611 (ligne vide finale). Sans effet.
7. (Ajoutée à la reprise.) FI-0 écrit « tuteur (6 maquettes sur 7) » (`17_finance/00_REPRISE.md:12`) et « 6 maquettes sur 7 sont des écrans tuteur » (`:40`). Or le guide range les 7 sous « Tuteur mobile dark » et « Tuteur desktop light » (guide:285-296). `QUESTIONS.md:7` dit lui-même « les 7 images du tuteur », et le tableau des sources de FI-0 (`00_REPRISE.md:21-27`) les rattache toutes au tuteur (§5.1 à §5.4). C'est un compte faux, sans effet sur le découpage : l'argument de `:40` (« les recréer violerait K-10 ») vaut aussi avec 7.

## Étapes couvertes

| Étape | Statut proposé | Pourquoi |
|---|---|---|
| FI-0 | **verifie** (avec le défaut moyen FI-ACCENT-1) | Ce que la fiche demande est tenu. Sources dans `17_finance/V/` (guide et 7 maquettes à `9855fb63`), identiques aux originaux (17 / 17). FI1 à FI24 renvoient toutes à un § existant et fidèle. Les 9 citations de code relues sont à la bonne ligne. Aucune valeur inventée. En revanche, FI-0 lit mal le guide pour l'accent de profil (§4 l. 57, RISQUE l. 185-186, FI-2 du découpage), et cette erreur vit encore dans la note FI-2 du tableau : défaut FI-ACCENT-1, sans réouverture (K-38). La phrase du premier passage « FI-BR et QUESTIONS cohérents avec le guide » est retirée : elle ne couvrait ni l'inventaire ni le découpage. Remarques 1, 3 et 7. |
| TB-0 | **verifie** (avec les défauts mineurs TB-STYLET-1 et TB-CONFLITS-1) | Sources dans `18_supports_tableau/V/` (plan et 8 planches), identiques aux originaux. TB1 à TB30 renvoient toutes à un § existant ; 29 sont fidèles, et TB21 perd la condition « lorsque Écrire est actif » (TB-STYLET-1). Les 13 citations de code relues sont conformes ; la citation mal attribuée du premier passage (`compaction_trait.dart:105`, « TB-BR-08 ») est remplacée par `:91` et `:17`. Comptes de commits exacts, aucune valeur commerciale inventée. TB-CONFLITS-1 : 12 au lieu de 14, sans effet depuis la décision du 02/10. |
| Leçons (`LECONS_DES_ROLES.md`) | vérifié | Les 15 leçons et l'annexe ont chacune au moins une preuve existante (fichier:ligne ou commit). Les 8 références à des dépôts du tableau ne sont pas lues ici. `EA-12a` est résolu (remarque 5). |

## Reprise après contradiction (03/10, session 90248232)

Un contradicteur indépendant a soulevé sept objections. Chacune a été recontrôlée sur pièces ; les sept sont **fondées**. Aucune n'a été jugée fausse.

| # | Gravité | Objection | Ce qui a été fait | Preuve |
|---|---|---|---|---|
| 1 | moyen | FI-0 lit mal le guide sur l'accent de profil ; le rapport l'avait passé « conforme », et le défaut reste actif dans la note FI-2 du tableau | **Fondée, et plus large que dit.** Le guide (l. 22, 366-371, 465-466) et le code (`app_palette.dart:308-315`, `palette_groupe.dart:21`) sont relus. Aucun accent de profil n'existe sur quatre commits, dont `af9f408b` (FI-1b). Deux faits en plus : « TH-2 », où la revue envoie la décision, est au tableau une autre étape (thème monochrome) qui ne la porte pas ; FOY-COUL-1 en donne une troisième version (couleur choisie par le tuteur). Défaut moyen **FI-ACCENT-1** proposé, ligne `app_palette` du §3 corrigée, phrase « FI-BR et QUESTIONS cohérents » retirée, verdict passé à « avec défauts ». | `journal_reprise.txt:28-114` ; `board/etapes/FI-2.json`, `TH-2.json`, `FOY-COUL-1.json` |
| 2 | mineur | Copies de `V/` laissées « non prouvées » alors que les originaux existent | **Fondée, favorable.** `git hash-object --no-filters` des 17 originaux est égal aux 17 blobs de `9855fb63`. Les écarts de taille du worktree (38 411 et 69 351 octets) viennent seulement des CR (1 610 et 673) ajoutés par `core.autocrlf=true`. §1 réécrit : identité prouvée ; taille du plan corrigée (68 678 octets dans git). | `journal_reprise.txt:5-26` |
| 3 | mineur | « 29 citations » dans le verdict contre 22 dans le tableau | **Fondée.** Le bon compte est 22 (9 FI, 13 TB). Le journal contient 24 blocs de fichiers plus une ligne `pubspec`, soit 25 lectures ; les lectures en plus ont servi à l'inventaire. Verdict et §3 corrigés. Le chiffre 29 ne se retrouve nulle part : erreur de rédaction. | `journal_controles.txt:49-162` ; RAPPORT §3 |
| 4 | mineur | `compaction_trait.dart:105 (TB-BR-08)` n'est pas une citation des documents TB | **Fondée.** TB-BR-08 ne cite aucun fichier (`TB-BR.md:14`). La valeur « 3 points » est dans TB-BR-02 (`TB-BR.md:8`), sans ligne. Aucun document TB ne cite `compaction_trait.dart:105`. Ligne remplacée par une vraie citation de `00_REPRISE.md:69` (`compaction_trait.dart:91`, `:17`), relue conforme. On note que la valeur de TB-BR-02 est juste (`:105` = 3, dans `TraitEnCours`). | `journal_reprise.txt:115-124` |
| 5 | mineur | TB21 jugé fidèle alors qu'il perd « lorsque Écrire est actif » | **Fondée, et le code cité fait l'inverse du plan.** `couche_annotation.dart:38-39` : « Le stylet ecrit toujours, y compris avant que l'outil ne soit arme ». L'imprécision est passée dans la revue TB-1a (`UX_REVIEW_TB.md:198`, « Conforme (existant) ») et dans la note de TB-7b. Ligne TB21 du §2 corrigée en « en partie » ; défaut mineur **TB-STYLET-1** proposé. | `journal_reprise.txt:125-147` |
| 6 | mineur | « 6 maquettes sur 7 » au lieu de 7 sur 7 | **Fondée.** Guide l. 285-296 : les 7 sont sous « Tuteur ». `QUESTIONS.md:7` dit « les 7 images du tuteur ». C'est un compte faux sans effet sur le découpage : ajouté en remarque 7, sans étape. | `journal_reprise.txt:148-170` |
| 7 | mineur | `PT-B-20260927-1ab2a969` laissé « non prouvé » | **Fondée.** `CONTRASTE-SUPPORT-1.json:9` dit « ancienne ligne PT-B-20260927-1ab2a969 ». En plus, `EA-12a` est aussi résolu : c'est une tâche de la recette EA (`05_recette/EA/RAPPORT.md:22`, `:149`), pas une étape du tableau. Remarque 5 réécrite. | `journal_reprise.txt:171-175` |

Fichiers du dossier : `RAPPORT.md`, `journal_controles.txt` (premier passage) et `journal_reprise.txt` (reprise). Aucun fichier temporaire hors de ce dossier. Rien n'a été écrit au tableau ni dans le code.

# CONTRACT_REQUEST_FABLE

Ce qu'il manque côté serveur, routeur et session pour que le frontend P0 livré sur
`core24/fable-frontend` cesse d'annoncer « capacité absente » et devienne le
produit. Destinataire : **Astra**, intégrateur unique.

**Règle tenue par Fable** : aucun faux n'est branché en production. Chaque port a
un adaptateur **réel** sur ce que la base rend déjà (`adaptateurs_existants.dart`),
et lève `EchecDomaine(MotifEchec.capaciteAbsente)` là où l'objet serveur n'existe
pas. L'écran le dit alors en une phrase, sans « Réessayer » : quand une RPC
arrive, **seul l'adaptateur change, jamais l'écran ni ses tests.**

Chaque demande nomme le port Dart consommateur, sa signature exacte, et ce que
l'adaptateur fait aujourd'hui à la place.

---

## 1. Intégration routeur — deux lignes, aucune redirection à changer

**Fichier** : `lib/core/router/app_router.dart`, dans la liste `routes`, à côté des
`...routesTcX()` :

```dart
import '../../features/classes/routes_core24.dart';
// ...
      ...routesCore24(),
```

Les deux chemins (`/enseignant/classes`, `/tuteur/classes`) vivent **sous le
préfixe de leur rôle** : `deciderRedirection` les laisse passer sans une ligne
de plus (`test/features/classes/routes_core24_test.dart` le prouve contre la
vraie fonction). Ce sont des poses hors coquille, comme `Routes.enseignantBienvenue` ;
chaque page porte son propre « Retour ».

Entrées de navigation déjà posées par Fable, dans son ownership :
`AccueilFamillePage` (« Classes disponibles »), `ProfilEnseignantPage`
(« Mes classes »), `BienvenueEnseignantPage` (« Voir les classes »). Aucune
destination de barre n'est ajoutée (`NavShell` plafonné, `ELV-02` gelé à 2 blocs).

**À trancher par Astra** : l'élève adulte autonome. ADR-009 en fait « son propre
tuteur », donc `/tuteur/classes` le sert (un foyer d'une personne, sélecteur
absent). Si un compte `student` adulte existe sans foyer, `ClassesFoyerPage`
est prête mais aucune route `/eleve/...` n'y mène (plafond `ELV-02`).

---

## 2. Création et publication de Classe — `PortClassesAdmin`

### 2.1 `publier(List<BrouillonClasse>)` — **BLOQUANT n°1**

**Aujourd'hui** : boucle sur `creer_groupe` (0019), qui **exige**
`p_teacher_profile_id`. Un brouillon sans enseignant lève `capaciteAbsente`
**avant** toute écriture (jamais de moitié de lot). Un échec au k-ième brouillon
remonte `EchecPublicationPartielle(faites, total)` et l'écran dit combien ont
abouti.

**Demandé** :

```sql
-- Une Classe peut être publiée sans enseignant (contrat §3, §P0.4).
-- creer_groupe : p_teacher_profile_id uuid DEFAULT NULL, p_timezone_iana text
-- DEFAULT NULL (validé contre pg_timezone_names), p_programme_niveau_id uuid
-- DEFAULT NULL, p_duree_minutes int DEFAULT NULL, p_seuil_minimal int DEFAULT NULL.
-- Résoudre l'ambiguïté PostgREST des surcharges actuelles (P0.1 d'Astra).

-- Un lot en une transaction, jamais 30 RPC côté Flutter (§P0.4) :
create or replace function public.creer_classes_lot(p_classes jsonb)
returns setof uuid ...  -- p_classes : tableau d'objets aux mêmes clés que ci-dessus
```

L'adaptateur passera de la boucle à `creer_classes_lot` en une méthode ;
`BrouillonClasse` porte déjà tous les champs (`libelle`, `publicClasse`,
`creneau{jourIso,heure,fuseauIana}`, `dureeMinutes?`, `capacite?`,
`seuilMinimal?`, `enseignantId?`, `niveauId?`).

### 2.2 `classes()` — ce que `groupes_admin()` ne rend pas

`ClasseVM` sait afficher, et laisse vide faute de colonne : `programme` /
`niveauHumain` (`nom_cours`, `programme_niveaux.nom_humain`, déjà demandés
§1.7 de `TC_CONTRACT_REQUEST_A.md`), `seuilMinimal`, `etat` (brouillon /
publiée / clôturée — aujourd'hui dérivé de `actif`), `duree` (lue de
`app_config.session_duration_minutes`, pas de la Classe), `creneau.fuseauIana`
(recodé `Europe/Paris`, §1.3 idem), `prochaineSeance.sessionId`.

**Demandé** : que `groupes_admin()` rende `timezone_iana`, `nom_cours`,
`niveau_humain`, `seuil_minimal`, `etat_publication`, `duree_minutes`,
`prochaine_seance_id`. Aucun renommage de table.

### 2.3 `enseignantsEligibles(BrouillonClasse)` — **jamais un champ d'identifiant**

**Aujourd'hui** : `comptes_admin()` filtré `role = teacher` et compte actif. La
**compatibilité** (créneau, public, contrat, KYC/dispense, plafond d'heures) est
une règle serveur que rien n'évalue.

**Demandé** :

```sql
create or replace function public.enseignants_eligibles(
  p_type_public text, p_weekday int, p_hour_local int, p_timezone_iana text
) returns table (profile_id uuid, nom_affichage text, titre text)
-- [admin] ; clearance = contrat accepté ET (kyc verified OU dispensé).
```

### 2.4 `regles()` — les défauts de l'académie

**Aujourd'hui** : seule `session_duration_minutes` est lue. Les capacités par
public et le seuil minimal restent `null` et l'écran dit « Défaut de
l'académie » (la base applique 5/6 dans `creer_groupe`). **Aucun nombre n'est
écrit côté client.**

**Demandé** : `app_config` : `class_capacity_children`, `class_capacity_adults`,
`class_min_threshold` (clés à votre main ; l'adaptateur les lit par clé).

### 2.5 `membres(classeId)`

Réel (`groupe_detail`). Rien à demander.

---

## 3. Marketplace — `PortMarketplaceClasses`

### 3.1 `mesClasses()` — réel, avec une limite

Enseignant : `mes_groupes_v` (réel). Famille : `PortGroupes.mesGroupes()` du
Teaching Core, dont le **défaut de production est encore
`GroupesDemonstrationLocale`** (`lib/core/tc_groupe/port_groupes.dart`, hors
ownership Fable, signalé par Agent A §1.2). `GroupSummaryVM` ne porte pas le
membre concerné : `ClassesFoyerPage` titre donc « Classes du foyer » plutôt que
« Classes de {prénom} ».

**Demandé** : `mes_groupes_famille_v` (déjà demandée) avec `student_id`, et un
adaptateur réel pour `portGroupesProvider`.

### 3.2 `classesDisponibles({membreId})` — **BLOQUANT n°2**

**Aujourd'hui** : `capaciteAbsente`. L'écran affiche « Aucune classe disponible
pour l'instant » + la phrase de capacité absente, et propose quand même
« Proposer un créneau ».

**Demandé** :

```sql
create or replace function public.classes_disponibles(p_membre_id uuid default null)
returns table (
  groupe_id uuid, libelle text, type_public text, weekday int, hour_local int,
  timezone_iana text, duree_minutes int, seuil_max int, nb_membres int,
  seuil_minimal int, etat_publication text, teacher_prenom text, teacher_titre text,
  nom_cours text, niveau_humain text, prochaine_seance_id uuid,
  deja_inscrit bool, candidature text  -- 'aucune'|'envoyee'|'acceptee'|'refusee'
)
-- Filtrage SERVEUR : rôle, clearance enseignant (contrat + KYC/dispense),
-- programme/placement, public, capacité, conflits horaires. Jamais le catalogue
-- entier au client (§P0.7). `p_membre_id` nul = l'appelant.
```

### 3.3 `candidater(classeId)`

**Demandé** : `candidater_classe(p_groupe_id uuid)` — refus si non cléaré, si
déjà candidat (`raise 'candidature deja ...'` : l'écran le classe déjà en
`dejaCandidat`), transactionnel à l'acceptation Admin (§P0.5). L'écran Admin
d'acceptation n'est **pas** dans ce lot (non listé dans l'ownership Fable).

### 3.4 `inscrire({classeId, membreId})`

**Demandé** : `inscrire_classe(p_groupe_id uuid, p_student_profile_id uuid)` —
idempotente, capacité impossible à dépasser, participant lié aux séances
futures, KYC élève **non** bloquant (§P0.6).

### 3.5 `proposerCreneau({membreId, creneau})`

**Demandé** : `proposer_creneau(p_student_profile_id uuid, p_weekday int,
p_hour_local int, p_timezone_iana text, p_programme_niveau_id uuid default null)`
+ l'agrégat Admin (§P0.8). L'écran Admin > Opérations des demandes agrégées et
« Créer la classe » depuis un agrégat ne sont **pas** dans ce lot ; le
préremplissage existe (`CreationClassePage` accepte un brouillon initial via
son état, à exposer en paramètre quand l'agrégat existera).

---

## 4. KYC V2 — `PortConformite`

### 4.1 `laMienne()` — projection réelle, dispense jamais inventée

**Aujourd'hui** : `etat_dossier()` : exigence = `requise` si `teacher`, sinon
`optionnelle` ; état depuis `piece_deposee`/`piece_statut` ; contrat depuis
`contrat_signe`. **`dispense` vaut toujours `null`** : aucune colonne ne la
porte. La clearance projetée = `contrat && (verifie || dispensee)`.

**Demandé** : que `etat_dossier()` (ou `ma_conformite()`) rende `kyc_exigence`
(`required|optional|waived`), `kyc_etat`
(`not_started|submitted|verified|correction_required|rejected|waived`),
`dispense_par` (nom d'affichage, jamais un id), `dispense_le`, `dispense_motif`,
`photo_identification_presente`. **Ne pas surcharger `account_status`** (§5.3).

### 4.2 `pourComptes()` — même projection depuis `comptes_admin()`

**Demandé** : les mêmes colonnes sur `comptes_admin()`.

### 4.3 `definirExigenceKyc({profilId, requise, motif})` — **BLOQUANT n°3**

**Aujourd'hui** : `capaciteAbsente` ; la feuille le dit après confirmation et
motif.

**Demandé** :

```sql
create or replace function public.definir_exigence_kyc(
  p_profile_id uuid, p_requise boolean, p_motif text
) returns void
-- [admin] ; refuse p_profile_id = auth.uid() (jamais le demandeur lui-même) ;
-- idempotente ; audit append-only (acteur, date, ancienne/nouvelle valeur, motif) ;
-- recalcule l'éligibilité ; revoke from public, anon, agent_ro (deux chemins
-- d'EXECUTE sur Supabase, cf. feedback_double_chemin_execute_supabase).
```

### 4.4 La porte du routeur — **auth core, hors ownership Fable**

`SessionState.porte` envoie tout `pending_kyc` sur `/attente`. Pour KYC V2,
un tuteur ou un élève avec pièce non déposée doit atteindre son espace :
« Faire plus tard » (`DepotPiecePage`) et « Continuer sans la pièce »
(`AttentePage`) mènent à `Routes.racinePour(role)` et **rebondiront sur
`/attente` tant que la porte n'a pas changé**. Décision serveur + session :
soit `account_status = active` dès l'inscription famille (contrat + accusé),
soit une porte qui lit l'exigence KYC. Fable n'a pas touché `session_state.dart`.

---

## 5. Précondition Salle — `PortPreconditionSalle`

**Aujourd'hui** : `profils_du_foyer_v` rend `avatar_storage_key` : la photo est
**réellement** présente ou absente. L'exigence est déduite du mode enfant
(`interface_mode = child`) : aucun blocage n'est inventé pour un adulte, mais
un mineur de 12 ans en mode standard n'est pas reconnu comme tel.

**Demandé** :

1. un drapeau serveur `photo_identification_requise` par membre (mineur au sens
   de l'académie), rendu par `profils_du_foyer_v` ;
2. `create-room-token` : pour un mineur sans photo, une **erreur domaine
   structurée** (`{ "error": "photo_requise" }`, statut 403) plutôt qu'un refus
   générique. `EchecDomaine.depuis(FunctionException)` classe aujourd'hui 403 en
   `refuse` ; l'adaptateur lira `details.error` dès qu'il existe ;
3. qu'un élève sur son propre appareil puisse lire sa propre ligne de
   `profils_du_foyer_v` (sinon la précondition reste inconnue côté enfant et le
   serveur tranche seul, ce qui est sûr mais moins explicite).

---

## 6. Présence — rien à demander, une limite à connaître

`SurfacePresence` et le planning de `ClassesFoyerPage` lisent
`presence_seance_v` (`ServiceSuivi`, `presenceSeanceProvider`), **jamais un
calcul local**. La présence automatique par webhooks LiveKit (P0.3) est
entièrement serveur : le jour où `etat_presence()` change, aucun écran Fable
ne change.

Non fait, faute de `prochaine_seance_id` dans `groupes_admin()` (§2.2) : la
présence de la prochaine séance dans la feuille de détail Admin.

---

## 7. Terminologie

Le mot visible est **Classe** partout dans l'ownership Fable (`fr.i18n.json`,
valeurs seules). Les clés `admin.groupes.*`, `tc.groupe.*` et les identifiants
Dart (`GroupesPage`, `LibellesGroupe`, `mesGroupesProvider`) sont **inchangés** :
aucun renommage de code, aucune migration.

Resté « Groupe » hors ownership : `lib/core/enseignant/**` (journée, fiche
`ENS-07`), `admin_domaine.dart` (« Groupes pédagogiques » en doc), le cahier
`ENS-04`. À aligner par Astra ou lot suivant, sans urgence produit.

---

## 8. Récapitulatif ordonné

| # | Demande | Bloque quoi |
| :--- | :--- | :--- |
| 1 | `...routesCore24()` dans `app_router.dart` | **Tout** : sans route, les deux écrans neufs n'existent pas |
| 2.1 | `creer_groupe` avec enseignant nullable + `creer_classes_lot` | Publier une Classe « enseignant à affecter », et le lot en une transaction |
| 3.2 | `classes_disponibles(p_membre_id)` | La marketplace enseignant et famille |
| 4.3 | `definir_exigence_kyc` | La dispense Admin (l'UI est prête, motif + confirmation + retour) |
| 4.4 | La porte de session pour `pending_kyc` famille | « Faire plus tard » réellement praticable |
| 3.3 / 3.4 / 3.5 | `candidater_classe`, `inscrire_classe`, `proposer_creneau` | Les trois gestes de la marketplace |
| 4.1 / 4.2 | Colonnes KYC V2 sur `etat_dossier()` et `comptes_admin()` | Afficher une dispense réelle et l'état « correction demandée » |
| 2.3 | `enseignants_eligibles(...)` | Une liste réellement compatible (aujourd'hui : enseignants actifs) |
| 2.2 / 2.4 | Colonnes de `groupes_admin()`, clés `app_config` | Programme, seuil, fuseau, état exacts sur les cartes Admin |
| 5 | `photo_identification_requise` + erreur structurée du jeton | La précondition exacte, mineurs en mode standard compris |
| 3.1 | `mes_groupes_famille_v` + adaptateur réel de `portGroupesProvider` | « Classes de {prénom} » et la fin du double de démonstration en production |

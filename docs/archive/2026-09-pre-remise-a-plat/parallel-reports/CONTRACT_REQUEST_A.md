# CONTRACT_REQUEST_A

Demandes de l'**Agent A** (Journée `ENS-02`, Fiche groupe `ENS-07`) à l'Agent Z.

Écrit le 20 septembre 2026. Rien ici n'a été contourné en touchant un fichier
partagé : chaque point est soit absorbé par une dette locale documentée, soit
laissé ouvert.

---

## 1. `seuilOuvertureSalle` n'est pas en `core` (bloquant à terme, contourné)

`TEACHER_SHARED_CONTRACTS.md` §4 et `TEACHER_DUPLICATES_AUDIT.md` §3 annoncent
que l'Agent Z remonte la constante en `core`. **Elle n'y est pas** :

```
grep -r "seuilOuvertureSalle" lib/
  lib/features/journee/journee_page.dart:61  (déclaration)
  lib/features/journee/journee_page.dart:296 (usage)
```

Conformément à la consigne, je ne l'ai **pas recopiée** : elle reste déclarée
dans `journee_page.dart`, avec un commentaire `ponytail:` qui nomme le plafond
(tout autre écran la redéclarerait) et le chemin de reprise. Dès qu'elle existe
en `core`, la ligne de `journee_page.dart` est à supprimer et l'import à poser.
Emplacement suggéré : à côté de `ResultatPreVol`, dans
`lib/core/video/pre_vol.dart`, avec le commentaire ADR-005 qui l'accompagne.

## 2. `EntreeJournee` et `TimelineRow` ignorent le groupe (contourné, visible)

`construireJournee(...)` prend `List<Seance>` et `TimelineRow` affiche
`entree.seance.elevePrenom` / `eleveIdentifiant` : les deux datent d'avant le
pivot du 19 septembre et raisonnent en élève unique. Or la Journée lit
désormais `SeanceEnseignant`, qui **ne porte aucun prénom**.

Contournement en place, dans mon périmètre seul : une fonction privée
`_versSeance(SeanceEnseignant)` traduit la séance de groupe dans le vocabulaire
de la journée partagée — `elevePrenom` reçoit le **nom du groupe**,
`eleveIdentifiant` son **effectif**, les six champs d'identité non repris
(`eleveId`, les trois de l'enseignant) ne sont lus par aucune des quatre
fonctions consommatrices. Le résultat est relu par identifiant pour retrouver
la séance riche.

**Demande** : soit un champ optionnel de groupe sur `EntreeJournee` (libellé +
effectif), soit un paramètre de `TimelineRow`. Les deux fichiers sont partagés
par trois rôles : l'évolution est un contrat, pas une retouche locale.

Conséquence tant que rien n'est fait : une ligne de colonne d'un cours
**individuel** (séance antérieure au pivot, `groupe_id` nul) s'affiche
« Cours avec Cours individuel ». C'est le seul libellé bancal du lot, et il
disparaît avec ce contrat.

## 3. Un helper de formatage `HH:MM` partagé

Deux copies existent (`journee_page.dart`, `core/widgets/timeline_row.dart`).
**Je n'en ai pas écrit une troisième** : `journee_page.dart` garde la sienne.
La fiche groupe formate une **heure pleine entière** (`Creneau.heure`), ce qui
n'est pas la même fonction et ne réutilise donc rien.

## 4. L'objectif commun de la séance, de bout en bout

Le protocole demande « l'objectif commun de la séance » sur `ENS-02`. Aucune des
trois couches ne l'a : ni colonne en base, ni champ sur `SeanceEnseignant`, ni
clé i18n. **L'écran se tait** plutôt que d'afficher un tiret à chaque cours.
Demande : colonne (`sessions.objectif` ou rattachement au programme de `0020`),
champ de modèle, clé.

## 5. Une lecture bornée des séances

`mes_seances_enseignant_v` n'est pas bornée en date : l'application télécharge
tout l'historique au démarrage, et le bornage au jour civil est fait en Dart.
« La lecture utile en moins d'une minute » ne devrait pas dépendre de la taille
de l'historique. Demande : `seancesEntre({debut, fin})` ou une RPC équivalente.

## 6. La prise `onRafraichir` de `PageShell`

Dette nommée par le catalogue (`08-catalogue-ecrans.md` l. 634-639). Je n'ai
pas touché `PageShell`. Pour que « la ligne de rapport disparaisse d'elle-même »
soit vraie, la ligne de rapport navigue par `push` et **invalide**
`cahiersEnRetardProvider` et `seancesEnseignantProvider` au retour. C'est le
seul chemin de relecture de l'écran : le reste n'est relu qu'au démarrage.

## 7. La fiche `ENS-02` du catalogue ne couvre pas le périmètre élargi

`docs/design/08-catalogue-ecrans.md` §6 décrit `ENS-02` tel que le lot R3 l'a
laissé : trois priorités, ni préflight, ni alertes individuelles, ni rapports en
attente, ni accès à la fiche groupe. La règle de `CLAUDE.md` (« aucun écran ne
s'implémente s'il n'est pas inscrit ») est tenue — l'écran **est** inscrit —
mais sa fiche est en retard sur ce qui est construit. `docs/` hors
`parallel-reports/` appartient à l'Agent Z : la mise à jour lui revient.

Écarts à inscrire, tous assumés dans ce lot :

- `loading` et `error` **existent** désormais (la fiche dit « pas d'état dédié ») ;
- ordre de priorité visuelle : prochain cours, colonne, exceptions, secondaire.
  Une entorse assumée : les alertes du cours dominant (absence, annulation) se
  posent **sous la carte dominante**, avant la colonne. À 390 de large, une
  absence annoncée sous la colonne serait lue après le cours ;
- le bloc dominant ne porte plus « prénom + identifiant immuable » mais le nom
  du groupe et son effectif : `SeanceEnseignant` ne porte aucun prénom, et cinq
  prénoms avant un cours seraient cinq choses à lire. Ils se lisent sur `ENS-07`.

## 8. Trois clés i18n deviennent orphelines

Le compteur du bloc secondaire passe de `BentoTile + Text` à `StatTile`, comme
`TEACHER_DUPLICATES_AUDIT.md` §1 l'exige. Les trois clés de phrase ne sont donc
plus appelées :

```
enseignant.journee.elevesEnAttente
enseignant.journee.unEleveEnAttente
enseignant.journee.aucunEleveEnAttente
```

Elles sont remplacées par `enAttenteTitre`, `enAttenteLibelle`,
`enAttenteLibelleUn` (dans `i18n_A.json`). **Décision à l'Agent Z** : les
retirer, ou les garder. Je ne touche pas `assets/i18n/`.

## 9. Deux libellés lus hors de leur rôle

`ENS-07` affiche le public d'un groupe avec `t.admin.groupes.typeEnfant` et
`typeAdulte` : les deux mots existent déjà, et en déclarer des jumeaux sous
`enseignant.*` donnerait deux clés pour « Enfants ». Ce n'est pas la convention
`role.ecran.element`. **Arbitrage demandé** : laisser, ou promouvoir sous
`commun.*`.

## 10. État réel des migrations, mesuré et non déduit

Vérifié sur le projet `gggmtelinlpseweouyav` le 20 septembre 2026 :

- **`0025_role_enseignant` et `0026_durcissement_execute_enseignant` sont
  APPLIQUÉES.** `mes_seances_enseignant_v`, `mes_groupes_v`, `teacher_roster_v`,
  `mon_groupe_detail`, `brouillon_cahier`, `mes_rapports_en_attente` et
  `sessions.groupe_id` existent. Les colonnes de `mes_seances_enseignant_v` et
  `mes_groupes_v` correspondent **exactement** à ce que
  `SeanceEnseignant.depuisJson` et `GroupeEnseignant.depuisJson` lisent. La
  réserve de `TEACHER_SHARED_CONTRACTS.md` §13 (« écrite mais pas appliquée »)
  est donc levée ;
- aucune fonction `deposer_cahier(...)` n'existe en base : le socle écrit dans
  `lesson_reports` par `insert`, ce qui est cohérent, mais `BASELINE.md` §5.1
  l'annonce comme une RPC. À corriger dans le document, ou à créer ;
- **les migrations `0020` à `0024` ne sont PAS appliquées** (versions absentes
  de `list_migrations`). Conséquence pour ce lot : `UniteCurriculum` sera nul en
  exécution réelle, ce qui est déjà le comportement documenté. Aucun écran de
  l'Agent A n'en dépend. Cela concerne surtout l'Agent C et le domaine
  Pédagogie.

Aucune migration n'a été écrite ni modifiée par l'Agent A.

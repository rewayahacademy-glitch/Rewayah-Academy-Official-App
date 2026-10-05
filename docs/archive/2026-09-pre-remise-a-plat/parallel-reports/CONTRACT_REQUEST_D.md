# CONTRACT_REQUEST_D — Agent D, `ENS-06` Créneaux

Ce que j'ai eu besoin d'avoir et que je n'avais pas. Rien de ce qui suit n'a été
contourné en écrivant hors de mon périmètre : chaque manque est soit contourné
**dans mes fichiers** avec un pis-aller documenté, soit laissé ouvert.

Destinataire : **Agent Z** (propriétaire de `lib/core/**`,
`lib/features/disponibilites/**`, `supabase/**`, `test/support/harnais.dart`).

---

## 1. Un contrat d'erreur métier fermé, à la place d'une phrase SQL — BLOQUANT à terme

**Ce qui manque.** `prendre_eleve()` et le trigger `guard_assignment_cap()`
rendent cinq **phrases** SQL non traduites, vérifiées sur le serveur le
20 septembre 2026 :

```
seul un enseignant au compte valide prend un eleve
ce creneau n'est pas propose par ce foyer
ce creneau ne figure pas dans vos disponibilites
cet eleve a deja un enseignant
cet eleve vient d'etre pris par un autre enseignant
plafond d'eleves atteint pour cet enseignant (%)
```

**Mon pis-aller, assumé.** `creneaux_page.dart` porte un `enum _Refus` privé et
une fonction `_refusDe(Object)` qui **reconnaît la phrase par sous-chaîne** puis
affiche une clé slang à moi, avec un repli qui recopie le message brut quand la
phrase n'est pas reconnue. C'est mesuré par quatre tests.

`ponytail:` plafond connu — une reformulation d'un `raise exception` en base
casse silencieusement la reconnaissance et fait retomber l'écran sur le repli
brut. Aucun test SQL ne relie les deux.

**Ce que je demande.** Un `errcode` ou un `error_detail` stable sur chaque
`raise exception` de `prendre_eleve()`, et un type fermé côté Dart
(par exemple `enum RefusPrise { compteInvalide, creneauNonPropose,
horsDisponibilites, dejaSuivi, dejaPris, plafond }`) exposé par
`ServiceMatching`. Les clés slang existent déjà de mon côté
(`enseignant.creneaux.refus*`) : seule la reconnaissance changerait.

---

## 2. Une constante unique de fuseau de repli

`'Europe/Paris'` est écrit à la main **six** fois dans le dépôt
(`disponibilites_page.dart:53`, `service_planning.dart:30` et `:259`,
`service_groupes.dart:69`, `admin_groupes/groupes_page.dart:390`).

**Je n'en ai pas ajouté un septième.** J'ai supprimé celui de
`creneaux_page.dart:208` en **n'affichant plus aucune heure avant que
`monFuseauProvider` ait répondu** (état `loading` de la grille, mesuré par le
test « aucune heure avant que le fuseau ait repondu »).

**Ce que je demande.** `static const String fuseauDefaut = 'Europe/Paris';` sur
`Creneau`, plus la règle écrite « n'affiche pas d'heure avant la réponse de
`monFuseauProvider` ». Les cinq autres occurrences restent.

---

## 3. Un contrat « conflit de case » pour `GrilleSemaine`

**Ce qui manque.** `GrilleSemaine` ne reçoit que `creneaux`, `fuseau`,
`enCours`, `onBasculer`. Une case qui porte déjà un élève est donc **peinte
exactement comme une case libre**. Je n'ai pas ajouté de paramètre : la
signature est partagée avec `TUT-04` et un paramètre de plus changerait
silencieusement l'écran du tuteur (`TEACHER_SHARED_CONTRACTS` §7).

**Mon pis-aller.** Le conflit est rendu **à côté** de la grille, pas dessus :
une ligne en registre `inkWarning` énumère les heures engagées
(`Vous avez déjà un élève sur jeudi 9 h. …`), et la confirmation d'un retrait
sur une heure engagée dit ce que le retrait ne fait pas.

**Ce que je demande.** Un paramètre optionnel, par exemple
`Set<Creneau> engagees = const <Creneau>{}`, que `GrilleSemaine` traduit en
décoration et en libellé sémantique de la case. Optionnel, donc `TUT-04` reste
inchangé.

---

## 4. Une décision produit que je n'ai pas le droit de prendre

**Retirer une disponibilité sur laquelle un élève est engagé : refusé, averti,
ou silencieux ?**

Fait vérifié : `weekly_availability` et `teacher_student_assignments` sont deux
tables, et retirer une ligne de la première **n'annule aucun cours**. J'avais
d'abord **bloqué** le geste, puis je l'ai retiré : refuser serait une règle
métier qu'aucun document du dépôt ne pose, et elle empêcherait un enseignant de
cesser de proposer une heure tout en finissant le cours en cours.

**Ce que j'ai livré** : le geste passe, et la confirmation dit exactement ce
qu'il fait et ce qu'il ne fait pas (`enseignant.creneaux.retraitEngage`).

**Ce que je demande.** Une ligne dans la fiche `ENS-06` du catalogue qui tranche.
Si la réponse est « refusé », le blocage se remet en trois lignes et le test
existe déjà sous une autre assertion.

---

## 5. Un état de vue asynchrone réutilisable

J'ai réécrit à la main, dans mes deux panneaux, la discrimination
`hasValue` / `hasError` / `isLoading` + `Skeleton` + `EmptyState` + le
recouvrement du message de refus au-dessus de la gate de chargement. Quatre
autres agents écrivent la même chose en ce moment.

**Ce que je demande.** Le composant annoncé dans l'audit de zone (propriétaire
Agent Z), posé une fois dans `lib/core/widgets/`. Je le consommerai sans
résistance : mon découpage est déjà exactement `loading / content / empty /
error / offline`.

---

## 6. Un libellé de niveau

`creneaux_page.dart` rend `t.creneaux.niveau(niveau: eleve.niveau!)` avec la
valeur SQL brute de `student_profiles.level` (`'debutant'` dans les fixtures).
**Vérifié** : `lib/core/widgets/selecteur_niveau.dart` n'aide pas — il porte
`SelecteurNiveauProgramme`, qui parle du niveau **du programme**
(`UniteCurriculum.nomHumain`), pas de ce texte libre, et
`TEACHER_SHARED_CONTRACTS` §3 interdit explicitement de présenter l'un pour
l'autre.

**Ce que je demande.** Une conversion `student_profiles.level -> libellé
traduit`, ou la confirmation que ce champ est un texte libre à afficher tel
quel. **Je n'ai rien changé** : afficher un libellé inventé serait pire que la
valeur brute.

---

## 7. Deux ajouts au harnais, pour mesurer ce que je mesure par contournement

`FauxServiceMatching` n'a **ni délai ni compteur de lectures**. Conséquences
dans `test/features/creneaux_test.dart` :

- l'état `loading` du feed ne se mesure pas par le faux : je l'obtiens en
  surchargeant `elevesEnAttenteProvider` avec un `Completer` jamais complété ;
- l'invariant « tout échec d'une prise relit le feed » ne se mesure pas
  directement : je le prouve **indirectement**, en mutant `matching.feed` avant
  le tap et en constatant que l'écran a changé.

**Ce que je demande** (Agent Z, `test/support/harnais.dart`) :
`Duration delai` et `int lectures` sur `FauxServiceMatching`, comme
`FauxServiceEnseignant.delai` les a déjà. Les tests actuels restent valides.

---

## 8. Le namespace des chaînes : `t.creneaux.*` ou `t.enseignant.creneaux.*` ?

`ENS-06` portait déjà **19 clés sous `t.creneaux.*`** (racine), alors que
`TEACHER_FILE_OWNERSHIP` §4 impose `enseignant.<ecran>` **pour ce lot**. J'ai
suivi la consigne : mes **20 nouvelles** clés sont sous
`enseignant.creneaux.*`, et je n'ai renommé aucune clé existante (elles sont
lues par les tests et, pour `t.disponibilites.joursLongs`, par sept écrans).

**Résultat** : un écran, deux namespaces. C'est une dette, pas une intention.
**Ce que je demande** : qu'Agent Z tranche à la fusion — soit il migre les 19
anciennes sous `enseignant.creneaux`, soit il note l'exception. Je ne l'ai pas
fait moi-même : `assets/i18n/*.json` n'est pas à moi.

---

## 9. L'ADR sur la coexistence 1-à-1 / groupes — pas un blocage pour moi, un blocage pour le lot

`supabase/migrations/0017` dit noir sur blanc que `ENS-06` **n'est pas**
rebranché sur les groupes. Vérifié sur le serveur le 20 septembre 2026 :
`teacher_student_assignments` et son index unique partiel
`assignments_one_active_teacher_uidx` sont bien là, `mes_groupes_v` aussi, et
**aucune RPC groupe n'est ouverte à l'enseignant**.

`prendre_eleve()` crée donc toujours une relation 1-à-1, pas une place dans un
groupe. J'ai construit sur le modèle existant, parce que c'est le seul qui
existe côté enseignant — et je le signale pour que personne ne croie que
`ENS-06` a été « migré ».

**Ce que je demande.** L'ADR annoncée par l'audit de zone, tranchée avant le
lot G-02. Tant qu'elle n'existe pas, `ENS-06` consolide le modèle que le pivot
du 19/09 doit remplacer.

---

## 10. Un écart de documentation à corriger (Agent Z, `docs/`)

`TEACHER_SHARED_CONTRACTS.md` §13 affirme : « **La migration `0025` est écrite
mais n'est pas appliquée** : l'accès en écriture à la base de production est
fermé dans cette session. »

**C'est périmé.** Vérifié en lecture seule sur le projet
`gggmtelinlpseweouyav` le 20 septembre 2026 :

| Migration appliquée | Version |
| :--- | :--- |
| `role_enseignant` | `20260919224503` |
| `durcissement_execute_enseignant` | `20260919224844` |

et les objets qu'elle pose existent : `mes_seances_enseignant_v` (`v`),
`mes_groupes_v` (`v`). Les agents A, B et C peuvent donc compter sur
`seancesEnseignantProvider` et `groupesEnseignantProvider` en exécution réelle.

En revanche `0021`–`0024` (Pédagogie) ne sont **pas** appliquées : la dernière
version Pédagogie sur le serveur est `0020_programme_pedagogique`.

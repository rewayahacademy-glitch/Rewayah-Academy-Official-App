# PED-APRES · Contrat du port `PortPartagePedagogique` (pour la carte PED-APRES-BACK)

**Fichier :** `lib/core/capacites/port_partage_pedagogique.dart` · **Statut :** `présent dans le code`, `testé localement` (double `test/fixtures/ped_apres/faux_partage_pedagogique.dart`). **Aucun adaptateur Supabase** n'existe. Production = `PartagePedagogiqueIndisponible` (`CapaciteIndisponible('PED-APRES-BACK')`). Démonstration = `PartagePedagogiqueDemonstration`, branchée seulement par `portPartagePedagogiqueSelon(demo: Env.playgroundActif)`.

**Relation avec l'existant.** `PortResumeSeanceFamille.resume()` (une chaîne, RPC `resume_seance_famille` de Codex F2, migration 0054) est **inchangé** : sa signature est implémentée par l'adaptateur de la PR #21. Il ne suffit pas pour l'écran (aucun état partagé / désactivé / en attente / révoqué / corrigé, aucun champ structuré). `compteRenduFamille` ci-dessous le remplace pour le détail de séance ; Codex doit rapprocher les deux.

## Règles transverses (toutes méthodes)
- Autorisation **serveur** (RLS / contrôle de rôle) ; l'interface ne déduit aucun droit. Refus : `PermissionInsuffisante`. Source absente : `CapaciteIndisponible`. Jamais de faux succès.
- Écritures : `versionAttendue` (concurrence optimiste) et `cleIdempotence` (une par geste). Version périmée : `ConflitPartage`, **aucune écriture**. Rejouer la même clé ne duplique pas l'effet.
- Aucune note interne, aucun autre élève, aucune donnée de paie dans une projection (le type `CompteRenduFamille` n'a pas de champ pour cela).
- La projection familiale est **indépendante du cahier brut** `lesson_reports` ; elle est construite à partir des évaluations déjà saisies dans K-45, **sans nouvelle saisie**.

## Méthodes

| Méthode | Entrée | Sortie | Erreurs |
| :--- | :--- | :--- | :--- |
| `compteRenduFamille` | `seanceId`, `eleveId` | `CompteRenduFamille` | `PermissionInsuffisante` (accès familial non autorisé à cet élève), `CapaciteIndisponible`, réseau |
| `partageClasse` | `classeId`, `page` (≥1), `recherche?` | `PartageClasse` (règle de classe, `version`, page d'élèves, `total` réel, `modifieLe/Par` si connus) | `PermissionInsuffisante`, `CapaciteIndisponible` |
| `definirPartageClasse` | `classeId`, `actif`, `versionAttendue`, `cleIdempotence` | `PartageClasse` confirmé | `ConflitPartage`, `PermissionInsuffisante`, `CapaciteIndisponible` |
| `definirRegleEleve` | `classeId`, `eleveId`, `regle` (`regleClasse` / `toujours` / `jamais`), `versionAttendue`, `cleIdempotence` | `PartageClasse` confirmé | idem |
| `comptesRendusEleve` | `classeId`, `eleveId` | `List<LigneCompteRendu>` (séance, date, `EtatDiffusion`), du plus récent | `PermissionInsuffisante`, `CapaciteIndisponible` |
| `comptesRendusClasse` | `classeId`, `page` (≥1), `filtreEtat?` (`EtatDiffusion`) | `PageCahiersClasse` (`lignes` : séance, élève, prénom, date, `EtatDiffusion` ; `total` réel du filtre ; `page`), du plus récent au plus ancien, **pagination serveur** | `PermissionInsuffisante`, `CapaciteIndisponible` |
| `lireCahierAdmin` | `seanceId`, `eleveId` | `CahierAdmin` (lecture seule, voir ci-dessous) | `PermissionInsuffisante` (tout rôle autre qu'admin), `CapaciteIndisponible` |
| `apercuFamilial` | `seanceId`, `eleveId` | `ApercuAdmin` | idem |
| `publier` | `seanceId`, `eleveId`, `versionAttendue`, `cleIdempotence` | `ApercuAdmin` à jour | `ConflitPartage`, `PermissionInsuffisante`, refus si cahier non confirmé ou aucun champ partageable |
| `revoquer` | idem | `ApercuAdmin` à jour | `ConflitPartage`, `PermissionInsuffisante` |

## États

**`EtatCompteRendu`** (famille) : `partage` (champs présents) · `nonPartage` (partage désactivé **ou** révoqué : la famille ne distingue pas) · `enAttente` (cahier non confirmé / en file / échec) · `aucunChamp` (confirmé, rien de partageable). Annulé / non tenu : l'écran n'appelle pas le port.

**`EtatDiffusion`** (direction, un compte rendu) : `nonValide`, `confirmeNonPartage`, `partageAuto`, `partageManuel`, `revoque`, `corrigeApresPartageManuel`.

**Règle effective** (priorité) : décision ciblée sur le compte rendu > exception élève > classe > défaut **activé**. `SourceRegle` : `exceptionEleve` / `classe` / `defaut`.

Tableau de vérité servi par le serveur (spec §2.3) : cahier non confirmé → `enAttente` ; auto actif et éligible → visible ; classe off sans exception → `nonPartage` ; élève forcé on → visible si éligible ; élève forcé off → masqué ; publication manuelle → visible malgré la règle jusqu'à révocation ; révocation → masqué même classe activée ; aucun champ → `aucunChamp`.

## Garanties temporelles demandées au serveur
1. Désactivation : masque **immédiatement** à toutes les lectures famille (liens directs inclus), sans effacer cahier ni preuve de séance.
2. Réactivation : seuls les comptes rendus **déjà** partagés automatiquement redeviennent lisibles ; **aucune publication rétroactive en masse** (`autoPartage` fixé à la validation).
3. Publication manuelle conservée malgré une classe désactivée ; révocation ciblée conservée malgré une classe activée.
4. Correction du cahier après publication manuelle : la famille garde la **dernière version approuvée** (`corrigeLe` renseigné), la nouvelle attend une décision ; jamais d'envoi silencieux.
5. Changement de classe : l'historique reste rattaché à la classe et aux droits à la date de séance ; jamais de transfert vers une autre famille.
6. Validation du cahier et paie : **aucun effet** de ces méthodes.
7. Historique des actions (`ApercuAdmin.historique`) : `null` si la source n'en a pas ; jamais inventé.
8. Pagination serveur des élèves (`taillePage` choisie par le serveur) et recherche côté serveur.

## Tests de contrat à écrire côté backend
Rejouer A01 à A22 de la spec contre le vrai serveur (le double `FauxPartagePedagogique` en donne l'oracle fonctionnel).

## ADM-CAHIER-LECTURE : lecture administrative du cahier (extension du 11/10/2026)

Décision de l'orchestrateur, par délégation du directeur : la **direction (rôle admin)** lit le cahier brut **en lecture seule** (supervision pédagogique, établissement des responsabilités).

**`CahierAdmin` est un type distinct de `CompteRenduFamille`, sans conversion implicite dans un sens ni dans l'autre.** Champs : `seanceId`, `eleveId`, `elevePrenom`, `classeLibelle`, `seanceLe`, `confirme`, `enseignant?`, `evaluation` (rubriques saisies par l'enseignant pour **cet élève**, base de la projection familiale), `detailsInternes` (rubriques **internes**, libellé + texte), `corrigeLe?`.

Exigences serveur (à implémenter par Codex 2) :
1. **Rôles** : seul l'admin actif peut appeler `lireCahierAdmin`. Comptable, tuteur, élève : **jamais**. Contrôleur : **non** dans ce lot. Refus : `PermissionInsuffisante`, sans aucune donnée.
2. **Journalisation** : chaque lecture du cahier brut est inscrite côté serveur (**qui, quand, quelle séance**, et l'élève). Une lecture refusée n'est pas une lecture.
3. **Périmètre** : le résultat ne contient que l'élève demandé. **Jamais** la décision d'un autre élève de la classe, **jamais** une donnée de paie ni de rémunération.
4. **Aucune copie** du texte interne vers `ApercuAdmin.apercu` ni vers `compteRenduFamille` : la projection familiale se construit à partir des seuls champs partageables approuvés.
5. `comptesRendusClasse` ne retourne que des cahiers de la classe demandée, avec le nom de l'élève selon les droits admin ; jamais d'effectif fictif ; `total` = effectif réel du filtre.
6. Aucun effet sur la validation du cahier K-45 ni sur la paie.

À l'écran : la lecture est étiquetée **« Interne, jamais montré à la famille »** pour les détails internes ; l'aperçu familial et publier / révoquer restent ceux d'ADM-PED-APR-03.

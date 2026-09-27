# Audit final de placement UX — panneau Admin

**Statut :** audit de contrôle, pas une nouvelle décision de cartographie. Les
routes canoniques et le périmètre par domaine restent ceux de
`docs/architecture/ADMIN_IA_AUDIT.md`, `docs/architecture/ADMIN_FINANCE_CONFIGURATION.md`
et `docs/architecture/ADMIN_SECURITE_DIRECTION.md`. Ce document ne les refait
pas : il vérifie que le code livré depuis leur écriture s'y conforme encore,
élément par élément, et corrige ce qui ne s'y conforme pas.

**Origine :** mission reçue le 19 septembre 2026 (soir), « Contrôle final UX —
AUDIT FINAL DE PLACEMENT UX DU PANNEAU ADMIN ».

**Instantané audité :** `main` au commit `4e222731cc98fb6807db398de4be4725130aa80e`,
plus le correctif de ce lot (`lib/features/admin_demandes/demandes_page.dart`,
voir § Violation prouvée et corrigée).

**Méthode :** lecture des 16 écrans du panneau Admin (Accueil, Groupes,
Attribution, Demandes, Dossiers, Comptes, les cinq écrans Pédagogie, les trois
écrans Configuration, Journal, Accès agents), de `AdminShell`,
`admin_domaine.dart`, `app_router.dart` et `redirection.dart`, classés selon
la grille donnée par la mission (domaine global / sous-domaine / vue du même
objet / configuration / donnée opérationnelle / résumé-KPI / action sur un
objet / filtre / action critique), puis vérifiés contre les dix critères
transverses de la mission.

## Résultat en une phrase

**Une seule violation prouvée**, localisée et corrigée dans ce lot. Les neuf
autres critères transverses sont tenus. Deux écarts supplémentaires sont
relevés mais délibérément **non corrigés** : l'un est une décision
d'architecture déjà actée par écrit ailleurs, l'autre est hors du périmètre
Admin de cette mission.

## Vérifications transverses

| Critère | Résultat |
| :--- | :--- |
| Zéro route dupliquée pour la même fonctionnalité | **OK** — 16 routes `/admin/...`, chacune vers un widget distinct (`app_router.dart:320-517`) ; les 7 anciennes routes plates sont des `redirect:`, jamais une seconde page (`app_router.dart:484-517`). |
| Zéro réglage présent à plusieurs endroits | **OK** — le seul candidat sérieux rencontré (`max_participants_per_session` de Configuration &gt; Fonctionnalités contre `seuil_max` de Groupes) s'avère être deux réglages distincts : un plafond technique visio (7, dont l'enseignant) contre un plafond pédagogique par groupe (5/6) — voir `supabase/migrations/0017_groupes_pedagogiques.sql:428-436` et `service_groupes.dart:177`. Configuration &gt; Règles (`ADM-15`) édite le défaut de plateforme, jamais la surcharge par profil d'`ADM-06`/`rule_overrides` — vérifié par lecture du code, pas seulement par le commentaire (`regles_page.dart:19-26`). |
| Zéro fonctionnalité métier perdue dans Settings | **OK** — `compte/reglages` (`ReglagesComptePage`) n'expose que des préférences personnelles locales (bascule silencieuse, thème, réduction d'animation), déjà tranché hors périmètre par `ADMIN_FINANCE_CONFIGURATION.md`. Aucune fonction métier n'y a été ajoutée depuis. |
| Zéro page métier transformée en Dialog | **OK une fois corrigé** — aucun `AlertDialog` trouvé sur les 16 écrans ; la seule confirmation destructive (révocation d'un jeton, `ADM-07`) passe par `ConfirmDestructive.demander` → `AppBottomSheet.ouvrir` (`confirm_destructive.dart:75`), jamais une boîte Material. Voir la violation ci-dessous pour l'exception trouvée et corrigée. |
| Zéro sous-fonction devenue destination globale sans justification | **OK** — les 8 domaines de la sidebar restent les 8 du gel d'architecture ; aucune sous-fonction (Groupes, Dossiers, Journal, etc.) n'a sa propre entrée de premier niveau. |
| Aucun onglet contenant un domaine qui devrait avoir sa propre section | **OK** — les onglets de `SousNavigationDomaine` (Pédagogie ×5, Configuration ×3) sont des fonctions pairs d'un même domaine, jamais un domaine entier réduit à un onglet. Le filtre « Certifications » d'Évaluations (`ADM-12`) est explicitement une vue filtrée des mêmes lignes, pas un second objet (`evaluations_page.dart:24-26`) — bonne classification délibérée du piège que ce critère vise. |
| Aucune sidebar différente selon les écrans | **OK** — une seule liste `domainesAdmin()` consommée identiquement par les trois formes adaptatives d'`AdminShell` (tiroir/rail/barre latérale, `admin_shell.dart:124-182`) ; chaque route Admin passe par `_CoquilleAdmin`, `/compte*` bascule aussi vers `AdminShell` pour un admin (`app_router.dart:651-658`). |
| Aucun système de navigation concurrent | **OK** — `destinationsPour`/`secondairesPour` (le système de `NavShell` des quatre autres rôles) retournent des listes vides pour `AppRole.admin` (`nav_shell.dart:134,174`) : aucune seconde coquille de navigation ne peut apparaître pour ce rôle. |
| Permissions respectées | **OK** — garde unique par préfixe de chemin dans `deciderRedirection` (`redirection.dart:104-107`, `Routes.prefixePour(AppRole.admin) == '/admin'`), appliquée globalement à chaque route avant son builder (`app_router.dart:80-86`). Les 16 écrans étant tous sous `/admin/...`, aucun n'y échappe. |
| Desktop, tablet et mobile cohérents | **OK** — chrome adaptatif à trois formes avec seuils fixes (600/1200, `admin_shell.dart`) ; grille des 6 compteurs de l'Accueil pilotée par `AppGabarit` (2 colonnes mobile/tablette, 4 desktop, `tableau_de_bord_page.dart:302-320`) ; Attribution a un repli mobile explicite (`attribution_page.dart:138,270-287`). Aucun écran à mise en page fixe cassante trouvé. |

## Violation prouvée et corrigée

**CURRENT.** `Operations > Demandes` (`ADM-06`), la feuille qui pose ou clôt
une règle (`FeuilleRegle`, dans `lib/features/admin_demandes/demandes_page.dart`),
s'ouvrait par un appel direct à `showModalBottomSheet<void>`
(ancien `_ouvrir()`, lignes 479-484), au lieu de passer par
`AppBottomSheet.ouvrir()`. C'était le seul cas sur les 16 écrans du panneau
Admin : Groupes (6 feuilles), Pédagogie (11 feuilles au total), Configuration
(3 feuilles) et la révocation d'`ADM-07` utilisent tous
`AppBottomSheet.ouvrir()` sans exception. Conséquence mesurable : cette
feuille précise n'avait ni poignée de glissement, ni les courbes/durées du
budget de mouvement du produit (`04-systeme-mouvement.md`), ni le voile ni
`useSafeArea` garantis par le point d'entrée commun — une incohérence visible
d'un geste à l'autre dans le même domaine, contraire au critère « desktop,
tablet et mobile cohérents » et à la règle documentée dans
`lib/core/widgets/app_bottom_sheet.dart:12` (« Seul point d'entrée d'une
surface modale »).

**EXPECTED.** Une seule mécanique d'ouverture de feuille pour tout le panneau
Admin, celle qu'`AppBottomSheet.ouvrir()` centralise déjà — y compris le
correctif de fermeture animée qu'elle documente en tête de fichier.

**ACTION — appliquée dans ce lot.**
`lib/features/admin_demandes/demandes_page.dart` :
- `_ouvrir()` appelle maintenant `AppBottomSheet.ouvrir<void>()`.
- Le titre, auparavant recopié en double (une fois dans `FeuilleRegle.build()`,
  une fois porté nulle part ailleurs), est maintenant un getter
  `FeuilleRegle.titre` lu par l'appelant et rendu une seule fois par
  `AppBottomSheet` — jamais redit dans le corps de la feuille.
- Le `Padding` manuel de marge et de retrait clavier a été retiré du corps de
  la feuille : `AppBottomSheet` les porte déjà pour tout appelant (même motif
  que `_FeuilleMotif` dans `admin_groupes/groupes_page.dart`, qui n'en avait
  pas non plus). Le garder aurait doublé les marges une fois enveloppé par
  `AppBottomSheet`.
- Vérifié : `dart analyze` (aucune alerte, y compris sur l'import
  `app_metriques.dart` devenu inutile et retiré) et
  `flutter test test/features/demandes_admin_test.dart` (14/14, y compris les
  deux tests qui ouvrent cette feuille et vérifient son titre et son
  formulaire).

## Écarts relevés, non corrigés

### Asymétrie de sous-navigation locale entre domaines — décision déjà actée, pas une violation

Pédagogie (5 fonctions pairs) et Configuration (3 fonctions livrées sur 7)
affichent leurs fonctions pairs via `SousNavigationDomaine`, un onglet par
fonction, navigable sans repasser par l'Accueil. Opérations (3 fonctions :
Groupes, Attributions, Demandes), Personnes (2 : Dossiers, Comptes) et
Sécurité et audit (2 : Journal, Accès agents) n'ont **aucune** navigation
locale équivalente : une fois sur `/admin/operations/attributions`, la seule
façon d'atteindre Groupes ou Demandes est de repasser par l'Accueil, la
sidebar (qui ne descend pas sous le domaine), ou une saisie d'URL/recherche.

Passé au filtre strict de la grille de cette mission (« SOUS-DOMAINE ? →
navigation locale de la section »), ceci ressemblerait à une violation. Ce
n'en est pas une par omission : c'est une décision délibérée, écrite trois
fois — dans `ADMIN_IA_AUDIT.md` (cartographie `ADM-05/06/07/08`), dans le
commentaire de tête d'`admin_domaine.dart:85-91`, et dans celui de
`sous_navigation_domaine.dart:6-12` (« Operations, Personnes et Securite et
audit n'en ont que deux ou trois, atteintes depuis l'Accueil sans chrome de
sous-navigation »). La corriger unilatéralement reviendrait à annuler un
arbitrage déjà rendu par l'opérateur, pas à réparer un oubli — voir
[[feedback_verifier_document_officiel_avant_audit]]. **Aucune correction
appliquée.** Si l'opérateur souhaite uniformiser (par exemple : `Attribution`
et `Demandes` rejoignent aussi une sous-navigation locale d'Opérations,
comme Pédagogie), cela reste une décision à prendre explicitement, pas un
correctif de placement.

### Réutilisation du composant `SettingRow` pour des raccourcis de navigation — cosmétique, pas un défaut de placement

Les deux raccourcis contextuels de l'Accueil vers Comptes et Accès agents
(`tableau_de_bord_page.dart:221-234`) utilisent le widget `SettingRow`. Son
nom évoque un réglage, mais sa propre documentation le définit comme une
primitive de présentation générique, sans contrat de navigation ni de
réglage couplé (`setting_row.dart:9-10`) : l'utiliser pour un raccourci
d'action est dans son contrat, pas un détournement. Rien à corriger ; noté
pour mémoire seulement.

## Hors périmètre — signalé, non traité

`Routes.compteProfils` et `Routes.compteProfilEnfant` sont deux constantes
identiques (`/compte/profils`, `lib/core/router/routes.dart:244` et `:247`).
C'est un défaut potentiel côté **Tuteur** (profils d'enfants du foyer), pas
Admin : hors du périmètre de cette mission (« panneau Admin »), donc non
corrigé ici. Signalé pour qu'un futur lot Tuteur le reprenne.

## Ce que cet audit n'a pas revérifié

Les décisions déjà actées et non remises en cause par du code nouveau depuis
leur écriture : le statut d'activation par fonction de Sécurité et audit et
de Direction (`ADMIN_SECURITE_DIRECTION.md`), et de Finance/Configuration
(`ADMIN_FINANCE_CONFIGURATION.md`). Aucun écran nouveau ne les contredit.

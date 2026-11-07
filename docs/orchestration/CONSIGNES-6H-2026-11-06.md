# Consignes des 6 heures (06/11/2026, à partir de 21:45 UTC)

Ordre du directeur, 06/11 vers 21:45 UTC : « 6 h à compter de maintenant, tu lances un agent par lot, toi
vérifie tout par ordre, toi et le pilote vous gérez bien pour que rien ne dérape […] le plus dur sera de
tout harmoniser ». Ce fichier est la règle de **chaque** agent, du pilote et du garde-cap pendant ces
6 heures. Il s'ajoute à `CLAUDE.md` et à `CONSIGNES-DIRECTEUR-EN-VIGUEUR.md` ; il ne les remplace pas.

## 1. Les lots, un agent chacun, zones séparées

| # | Lot (PLAN-LOTS §7) | Zone exclusive | Migration |
|---|---|---|---|
| 1 | CANDIDATS-FLUX PR B (22 k, CAND-04) | `lib/features/candidature`, inscription candidat, 3 lignes de routeur | aucune |
| 2 | REVENUS-VERITE point 5 (22 j) | revenus de l'enseignant, primes et missions de la direction | 20261110200000-299999 |
| 3 | WEB-BUREAU (22 n), **plus le rang 23, harmonisation** | `lib/core/widgets` (coquilles, `PageShell`, composants partagés), `lib/core/router`, page de paiement | aucune |
| 4 | PREFERENCES-WEB (22 a) | `lib/core/preferences`, `lib/core/i18n` (langue au démarrage), ligne des Réglages | aucune |
| 5 | COULEUR-PROFIL (22 i) | `lib/features/foyer/fiche` (couleur), adaptateur | 20261110500000-599999 |
| 6 | LINK-CHOIX (22 o) | `supabase/functions/_shared/stripe.ts`, `recharge-payer` | aucune |
| 7 | FINITION (22 b, sans coquille ni `PageShell`) | les écrans et textes nommés en 22 b | aucune |
| 8 | CAHIER-C2 puis C3 à C8 (22 f) | `lib/features/fiche_groupe`, cahier, programme | 20261110600000-699999 |
| 9 | FINANCE-ENSEIGNANT (22 h) | `lib/features/paiements_recus`, ports de versement | 20261110700000-799999 |
| 10 | A11Y-1 (rang 13 : UX-004, 010, 021, 027) | écrans nommés ; un composant de `lib/core/widgets` passe par l'agent 3 | aucune |
| 11 | SALLE-UX (rang 15) | `lib/features/salle` seulement | aucune |
| 12 | FOYER-UX (rang 16) | écrans du foyer, contenu et non mise en page | aucune |
| 13 | FN-DIVERS (rang 21 : FN-102, 101, 018, 111, 027) | candidature, pièces, points nommés | 20261110800000-899999 |

Un fichier hors de sa zone : l'agent s'arrête, écrit au garde-cap, et attend sa réponse **en continuant le
reste de son lot**. Deux lots ne touchent jamais le même fichier.

## 2. La méthode de chaque agent, dans cet ordre

1. **Ce qui existe déjà.** `INVENTAIRE-NON-BRANCHE-2026-10-31.md`, puis une recherche dans le dépôt et les
   branches non fusionnées. Le directeur : « le code existe déjà, il suffit de brancher, corriger,
   adapter ». Aucune ligne écrite avant cette recherche ; le bilan dit ce qui a été réutilisé.
2. **La règle de l'interface** : `docs/current/DEFINITION-PAGE-ORDINATEUR-2026-11-06.md` (branche
   `claude/web-bureau` tant qu'elle n'est pas sur `main`) pour tout écran, à 1440 comme à 390 ; les
   composants partagés de `lib/CLAUDE.md`, jamais recomposés ; les textes passent par `mots-rewayah`.
3. **Travailler sans attendre.** On attend pour pousser, jamais pour travailler. Un merge de `main` avant
   la poussée ; les fichiers générés (`strings_*.g.dart`) se régénèrent par `dart run slang` puis
   `build_runner`, jamais à la main.
4. **Un seul push par lot**, après `dart analyze --fatal-infos`, la suite complète si le lot touche
   `lib/core`, sinon les tests de sa zone, `verifier_jetons`, `verifier_branchement`, `verifier_revue`.
   Aucune PR : le pilote fait les trains.
5. **La preuve** : le robot de la pile locale, captures 390 et 1440, FR et AR, dans
   `docs/current/captures/E2E/<lot>/`.
6. **Le rendu** au pilote et au garde-cap : SHA complet relu par `git rev-parse`, fichiers touchés,
   ce qui est faux ou non prouvé **en premier**.

## 3. Ce que fait le garde-cap

- Il vérifie chaque rendu **dans l'ordre d'arrivée** : zone, existant réutilisé, définition de la page
  d'ordinateur, captures contre la demande, serveur (RLS, `SECURITY DEFINER`, `search_path` vide, aucun
  effacement sans la page du directeur).
- Verdict en une ligne : conforme, ou la correction exacte.
- Toutes les 3 heures, et plus souvent pendant ces 6 heures : chaque agent tourne-t-il vraiment ? Un agent
  arrêté sans blocage écrit est relancé aussitôt.

## 4. Ce que fait le pilote

- Il monte les trains avec les lots jugés conformes, deux au plus par jour UTC sauf ordre du directeur,
  en isolant les lots qui touchent les composants partagés (lot 3).
- Il installe les migrations après la relecture du garde-cap et vérifie leur empreinte en production.
- Il surveille le plafond de chaque session ; au premier avertissement, il le dit au garde-cap.

## 5. L'harmonisation (le plus dur, rang 23 confié au lot 3)

- **Une seule source de vérité** : la définition de la page d'ordinateur et les composants partagés.
  Aucun lot ne règle une marge, une couleur, un en-tête ou un menu dans son écran : il signale le défaut
  à l'agent 3, qui le corrige une fois dans le composant.
- **Le garde-fou de l'agent 3** joue chaque route à 1440 dans la suite de tests : un lot qui casse la
  définition ne passe pas la CI.
- **Ordre des trains** : les lots de contenu d'abord, puis l'étape du lot 3 qui les harmonise, puis on
  remesure « pages conformes sur 309 ».
- **Mêmes mots, même place** : déconnexion dans le menu du compte (ordinateur) et en bas du Compte
  (téléphone) ; actions de ligne par `MenuActions` ; filtres par `RangeeFiltres` ; choix par
  `ChoiceCardGroup` ; feuille du bas au téléphone seulement.

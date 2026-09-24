# LA-1 — Bienvenue, connexion, recuperation d'acces

Sous-paquet A1 (05_LOTS_PHASE1.md section A). Branche `ui/tuteur-v1-a`,
dernier commit `30918a0`.

## Ecrans

| Ecran | Route | Fichier |
|---|---|---|
| Bienvenue | `/bienvenue` | `lib/features/bienvenue/bienvenue_page.dart` |
| Connexion | `/connexion` | `lib/features/connexion/connexion_page.dart` |
| Recuperation d'acces | `/connexion/recuperation` | `lib/features/connexion/recuperation_page.dart` |

## Carte des fonctions publiques (recuperation_page.dart)

- `motifDepuisUrlRetour(String?)` : lit `error_code` dans le fragment ou la
  requete d'une URL de retour -> motif expire/refuse/null.
- `cheminRecuperation(String? motif)` : construit `/connexion/recuperation?motif=...`.
- `issueEchecEnvoi(Object erreur)` : classe une erreur d'envoi (trop tot,
  hors ligne, autre).
- `phraseEchecEnvoi(IssueEchecEnvoi)` : phrase utilisateur associee.

## Statut par ecran

- Bienvenue : fait. Atteignable depuis `lib/main.dart` (graphe_imports,
  `r1_atteignables_30918a0.txt`). Deux boutons (« Commencer », « J'ai deja un
  compte ») menent a `/connexion` ; deux colonnes des 900 px.
- Connexion : fait. Atteignable depuis `lib/main.dart`. Etats saisie /
  envoi / lien envoye / erreurs (trop tot, hors ligne, autre) ; redirection
  automatique vers la recuperation si l'URL de retour porte `error_code` ;
  liens discrets « Lien expire ou jamais recu ? » et « Decouvrir Rewayah
  Academy ».
- Recuperation d'acces : fait. Atteignable depuis `lib/main.dart`. Motifs
  expire/refuse/aucun, etats saisie / envoi / envoye / erreur / trop tot /
  hors ligne, retour visible (`DisqueRetour`).

## Maquettes

Aucune maquette du directeur ne couvre bienvenue/connexion/recuperation
dans les references listees pour le lot A (`01_visuel/00_MANIFESTE.md`,
dossier `lancement/tutuor image/`) : les cinq images disponibles (onboarding
mobile 1/2, onboarding Mble, onboarding Mble d, tuteur observation mobile
light) sont un assistant de creation de compte en plusieurs etapes (« Pour
qui creez-vous ce compte ? », genre, age) et l'ecran d'observation M6, pas
les trois ecrans de LA-1. Aucune planche maquette | rendu n'a donc ete
produite ; le rendu est derive de la carte de connexion existante (deja
note par la session precedente dans `etat/B.md`). Si une maquette dediee
existe ailleurs, `demandes/A.md` reste le canal pour la demander.

## Captures

Dossier `C:\RA\pilotage\05_recette\A\captures\` (via
`test/capture/la1_bienvenue_connexion_capture_test.dart`, vrai routeur,
visiteur deconnecte) :

- `la1_bienvenue_390x844_{light,dark}.png`, `la1_bienvenue_1440x900_{light,dark}.png`
- `la1_connexion_390x844_{light,dark}.png`, `la1_connexion_1440x900_{light,dark}.png`
- `la1_connexion_recuperation_390x844_{light,dark}.png`,
  `la1_connexion_recuperation_1440x900_{light,dark}.png`

12 captures, examinees visuellement : aucun chevauchement, aucun debordement,
vocabulaire conforme (« Sayyid ou Sayyida », pas de terme interdit). Aucun
ecart de placement a corriger (pas de maquette de reference), donc aucun
commit de correction necessaire au dela du test de capture lui-meme
(`30918a0`).

## Tests

- `dart analyze --fatal-infos test/capture/la1_bienvenue_connexion_capture_test.dart` : No issues found.
- `flutter test --no-pub test/capture/la1_bienvenue_connexion_capture_test.dart --reporter expanded` : 12 passed (3 skips sur les groupes « maquette | capture », sans `CAPTURE_MAQUETTE_LA1` — attendu, aucune maquette disponible).
- Heritage des taches 1/3 et 2/3 (commits `fbb603d`, `efbe5e2`) : `flutter test test/features/connexion_test.dart test/features/bienvenue_connexion_navigation_test.dart test/router/navigation_test.dart` : +98, All tests passed (deja verifie, non rejoue ici pour tenir le budget de temps).

## graphe_imports

`graphe_imports.ps1 -Repo C:\RA\lot-a -Ref 30918a0` : les trois fichiers
(`bienvenue_page.dart`, `connexion_page.dart`, `recuperation_page.dart`)
figurent dans `r1_atteignables_30918a0.txt` (atteignables depuis
`lib/main.dart`).

## Definition de « fait »

Remplie pour les trois ecrans : atteignable depuis `lib/main.dart`, boutons
testes depuis la navigation reelle (tache 2/3), etats couverts, vocabulaire
conforme, retour visible, captures clair/sombre 390x844 et 1440x900. Seul
point non rempli au sens strict : pas de planche maquette | rendu, faute de
maquette de reference pour ces trois ecrans (constat, pas un defaut de
code). LA-1 est donc marque **fait** avec ce constat explicite.

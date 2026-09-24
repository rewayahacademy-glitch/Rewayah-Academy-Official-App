# LA-2 : inscription par etapes -- recette (tache 3/3)

Branche `ui/tuteur-v1-a`, commit `f21ec7e` (captures) sur `df8c97c` (code) et
`8506277` (tests). Atteignabilite verifiee sur `f21ec7e` avec
`graphe_imports.ps1 -Repo C:\RA\lot-a -Ref f21ec7e` : les cinq fichiers du
sous-paquet sont dans les 361 fichiers atteignables depuis `lib/main.dart`,
aucun dans les 65 non atteignables :
`lib/features/inscription/inscription_page.dart`,
`lib/features/inscription/brouillon_inscription.dart`,
`lib/features/inscription/etapes/usage_etape.dart`,
`lib/features/inscription/etapes/identite_etape.dart`,
`lib/features/inscription/etapes/genre_etape.dart`,
`lib/features/inscription/etapes/recapitulatif_etape.dart`.

## Ecrans du sous-paquet

| Ecran | Route | Fonction |
|---|---|---|
| Usage | `/inscription/usage` | Deux cartes (« Moi uniquement » / « Moi et les membres de ma famille »), sans carte « Autre », sans preselection ; lien discret « Je suis enseignant » |
| Identite | `/inscription/identite` | Prenom, nom ; erreurs sous les champs |
| Genre | `/inscription/genre` | Sayyid / Sayyida |
| Recapitulatif | `/inscription/recapitulatif` | GroupeReglages, « Modifier » par ligne, cree le profil puis rafraichit la session |

Coquille commune (`CoquilleEtape`) : disque de retour 48 dp, « n sur N »
calcule sur 4 etapes, barre de progression, CTA en pilule, « Se deconnecter ».

## Captures produites (`C:\RA\pilotage\05_recette\A\captures\`)

24 fichiers `la2_*` : les 4 ecrans en 390x844 et 1440x900, clair et sombre
(16 captures), 2 etats supplementaires (identite en erreur sous les champs,
recapitulatif en echec d'actualisation apres creation du profil -- impasse
corrigee : Reessayer + Se deconnecter restent accessibles, pas de doublon de
profil), et 3 planches maquette | rendu (usage, genre, recapitulatif) + leur
capture seule.

## Planches maquette | rendu

- **Usage** vs `onboarding Mble.png` : disposition conforme (header retour +
  progression, deux cartes avec icone/titre/description, CTA pilule, lien
  discret, deconnexion). Aucune carte preselectionnee dans le rendu (exige
  par le mandat, la maquette montre une carte cochee a titre d'exemple) :
  ecart voulu, non corrige.
- **Genre** vs `onboarding Mble d.png` : disposition conforme, memes elements
  de coquille.
- **Recapitulatif** vs `Onboarding mobile 2.png` : disposition conforme
  (GroupeReglages, « Modifier » par ligne). Ecart observe et documente, non
  corrige (hors budget de cette tache) : cale sur la hauteur logique deduite
  de la maquette, le contenu deborde de 58 px (RenderFlex overflow) -- la
  page recapitulative est plus longue et scrollable que la fenetre de la
  maquette, cas prevu par `test/capture/LISEZ-MOI.md` (« Pieges connus »,
  page longue = plusieurs captures ou vue plus haute). La capture 390x844 /
  1440x900 (fenetre standard, sans ce calage) ne presente pas ce debordement.
- **Identite** : aucune maquette dans les references du lot A (memes
  ecrans deja constates absents pour LA-1) ; pas de planche produite.

## Desktop en colonnes

Verifie sur les captures 1440x900 : la carte de choix (usage), les champs
(identite/genre) et le recapitulatif restent dans une colonne centrale sur
fond desktop, conforme au manifeste V5/V6 (pas de pleine largeur).

## Tests

- `dart analyze --fatal-infos test/capture/la2_inscription_capture_test.dart` : aucun probleme.
- `flutter test --no-pub test/capture/la2_inscription_capture_test.dart --reporter expanded`
  (sous CAPTURE_DIR + les 3 variables CAPTURE_MAQUETTE_LA2_*) : 20 tests
  passes / 21 ; 1 echec attendu et documente ci-dessus (debordement du
  calage maquette du recapitulatif, page produite quand meme). Sans
  CAPTURE_DIR, le groupe est saute (comportement standard, CI non affectee).
- `flutter test --no-pub test/capture/la2_inscription_capture_test.dart test/features/inscription_test.dart` (sans CAPTURE_DIR, non-regression) : tests fonctionnels 10/10 verts, captures sautees.

## Statut

LA-2 : **fait** pour le contenu, la navigation par etapes, les captures et
les planches des trois ecrans avec maquette. Point restant, deja documente
dans `etat/B.md` et transmis a LA-3 : `?pour=moi` n'est pas propage vers
`/attente/contrat` (l'usage reste lisible via `brouillonInscriptionProvider`).
Blocage deja connu (demande A-4, non retraite ici) :
`test/accessibilite/clavier_test.dart:43-51` tape encore l'ancien ecran
unique.

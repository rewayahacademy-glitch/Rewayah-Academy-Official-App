# Revue du directeur des 01 et 02/10/2026 : table des règles et des preuves

Remplace la table §4 BIS de `docs/design/README.md`, absent de la branche `integration/essai-fusion` (déplacé dans `docs/archive/2026-09-pre-remise-a-plat/design/README.md` à la remise à plat). Les règles écrites sont dans `lib/CLAUDE.md`, section « Interdits d'interface (revue directeur 01-02/10) ». Source : consignes K-54 à K-59 du tableau « Suivi Rewayah ».

Principe : corriger la cause (composant partagé de `lib/core`), recenser tous les écrans au même défaut ou à un défaut équivalent, écrire la règle et son contrôle, noter le chiffre avant et après.

| Règle | Consigne | Composant partagé | Contrôle automatique | Test de garde |
|---|---|---|---|---|
| Contenu de bouton centré, sans débordement | K-54 | `ActionPrincipale` | `bouton-recompose` | `verifierBoutonCentre` |
| Jamais de cartes collées (cartes séparées, ou une carte à lignes fines) | K-55 | `AppCard`, `Ecart`, `GroupeReglages` | `cartes-collees` | `verifierEcartCartes` |
| Un seul bouton plein par écran, secondaires en lien flèche | K-56 | `ActionPrincipale`, `LienFleche` | `bouton-grise` (alias `bouton-desactive`) | revue d'écran |
| Formulaires déduit > choisi > saisi | K-57 | `ChoiceCardGroup` | revue de fiche (FORM-AUTO-1) | |
| Tout choix : contexte, quand, conséquence, carte entière cliquable | K-58 | `ChoiceCardGroup` | revue de fiche | |
| Message d'erreur : cause et action | K-59 | `EtatSysteme`, `BlocAsynchrone` | `erreur-sans-action`, `affirmation-reseau` | |
| Bouton principal d'une séance selon son moment, jamais grisé | CTA-FIN-1 | `ctaSeance`, `EmplacementEntree`, `LienFleche` | `bouton-grise` | `test/core/enseignant/cta_seance_test.dart`, `test/features/journee_test.dart` |
| Aucun élément ne recouvre un contenu | déduite | | | `verifierSansChevauchement` |
| Hiérarchie de titres stricte | déduite | `EnteteDePage`, `SectionHeader` | revue d'écran | |
| État jamais par la couleur seule | déduite | `StatusPill` | revue d'écran | |
| Alerte urgente en tête | déduite | | revue d'écran | |
| Libellé sans ambiguïté (qui, quoi) | déduite | | `libelle-ambigu` | |
| Aucun mot interne chez le client | déduite | | `mot-interne` | |

## Chiffres au 02/10/2026 (branche `corrections/revue-directeur-2026-10`, base `integration/essai-fusion` 55a5235)

Avant correction, par contrôle (`dart run tool/verifier_revue.dart --regle=<nom> --detail`) :

| Contrôle | Occurrences avant | Après |
|---|---|---|
| `cartes-collees` | 5 | |
| `bouton-recompose` | 2 | |
| `libelle-ambigu` | 5 | |
| `mot-interne` | 4 | |
| `erreur-sans-action` | 27 | |
| `bouton-grise` | 73 (53 dans le socle hérité de `main`) | |
| `affirmation-reseau` | 10 (6 dans le socle hérité de `main`) | |
| `libelle-sans-source` | 1377 (1023 dans le socle hérité de `main`) | |
| `verifier_jetons` | 36 | |

Limites connues des contrôles (heuristiques de texte) : `cartes-collees` ne voit que des appels voisins dans une liste `children` sans `spacing:` (pas les `ListView.builder` sans séparateur) ; `bouton-recompose` ne voit que les boutons Material, `InkWell`, `GestureDetector` et un `Pressable` qui peint lui-même fond arrondi et `Text`. Ce que ces contrôles ne voient pas se mesure par les tests de géométrie et par les captures à 320 px et 1440 px.

## CTA-FIN-1 : le bouton principal d'une séance selon son moment (02/10/2026)

Demande du directeur (commentaire du 01/10) : le bouton d'une séance n'est jamais désactivé, il change de sens.

| Moment | Bouton | Avant la correction |
|---|---|---|
| Avant l'ouverture de la salle | « Préparer la séance » | idem |
| Salle ouverte, jusqu'à la fin et au-delà tant que la salle est ouverte | « Rejoindre la salle » (+ pastille « En direct » dès l'heure de début) | « Préparer l'entrée » |
| Temps écoulé, cahier non déposé | « Remplir le cahier de transmission » + rappel « Obligatoire » | carte absente (« Aucune séance à venir »), cahier seulement dans « À terminer » |
| Cahier déposé | « Voir le cahier » en lien discret | carte absente |
| Séance annulée ou absence déclarée | « Voir la Classe » | idem |

Cause corrigée dans le composant partagé : `lib/core/enseignant/cta_seance.dart` (fonctions pures `ctaSeance` et `seanceDeLaCarte`, fenêtre d'accès et grâce lues de la base, jamais redéclarées), `EmplacementEntree` (libellé enseignant unique pour la Journée et la fiche de la Classe), `EmplacementEntreeVue` (un bouton de bureau ne déborde plus de sa carte en texte agrandi).

Chiffres (avant, après) : états du bouton de la carte « Prochaine séance » de l'enseignant, 4 libellés dont 1 hors des moments demandés, puis 5 états tous nommés ; libellés différents pour la même action « entrer en salle » côté enseignant, 2 (« Préparer l'entrée » en Classe, rien en Journée pendant le cours) puis 1 (« Rejoindre la salle ») ; débordements mesurés à 320 px en texte ×2 sur la carte de séance, 1 (en-tête nom et pastille) puis 0 ; débordements mesurés à 1440 px en texte ×2 (bouton « Remplir le cahier de transmission »), 1 puis 0 ; tests de transitions, 0 puis 18 (unitaires) et 24 (widget).

Recensé, non repris ici (autre lot) : le bouton « Rejoindre » de l'élève hors ligne reste présent et inerte (`accueil_eleve_page.dart`, décision documentée dans le code), compté par `bouton-grise`.

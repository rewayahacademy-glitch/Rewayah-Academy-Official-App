# Matrice des rôles - salle de classe (fait foi)

Date : 25/09/2026. Sources : spec `02_CLASSE_ET_VISIO.md` (S, numéros de ligne), `02_DIRECTION_VISUELLE.md` (DV), `09_consentements/CHARTE.md` (CH), `V/00_SYNTHESE_RECTIFICATIONS.md` (SY).
Règle mère : chaque écran part du **rôle effectif** ; un composant partagé n'affiche que ce que ce rôle a le droit de voir (DV §2 point 10, S §1). Aucune maquette ne donne à un élève un élément marqué « non » ici.

Colonnes : **ES** = élève standard (CLV-04), **IG** = Interface guidée, enfant (CLV-05), **EN** = enseignant (CLV-06 à 08, 10).

## 1. En-tête et mentions

| Élément | ES | IG | EN | Référence |
|---|---|---|---|---|
| Titre | « Séance en direct » | « Ma séance » | « Séance en direct » | S l.583, 728, 848 |
| Sous-titre Classe · enseignant | oui | non prévu (titre court seul) | nom de Classe | S l.829, 728 |
| Durée restante | non | non | oui | S l.829 ; absente de S l.597, 613-635, 741-759 |
| « La séance se poursuit. » | oui, texte sur la ligne d'état, jamais bandeau vert | non (absent des textes CLV-05) | oui, texte, jamais bandeau vert | S l.623, 671, 859, 893 ; DV D4 |
| Pastille « En ligne » | oui | oui | oui | état de connexion commun, SY I-1 |
| Mention d'enregistrement | oui, si serveur confirme | oui | oui | S l.36, 619, 783, 860, 891 ; CH §1.10, §1.13 ; SY I-1 |
| Notice de visite | **seulement l'élève dont le parent observe** : « Votre parent observe la séance. » | **seulement l'enfant concerné** : « Ton parent observe la séance. » (S l.752 : « regarde », unifié par SY I-2) | toujours : « Tuteur de {prénom} observe. » (S l.855), ou « Le tuteur de {prénom} observe la séance. » si Q4 = oui | S l.34, 253-255, 600, 667, 887, 1432 ; SY I-2 |
| Présence contrôleur ou admin incognito | jamais | jamais | jamais | S l.65, 889, 914, 1434 |
| Compte en haut à droite | son propre compte | son propre compte | **le compte de l'enseignant** | SY I-6 ; DV §2 vérif. point 10 |
| Barre latérale d'app | masquée en salle ; si gardée : Accueil, Classes, Progression, Compte | aucune barre dense | masquée ; si gardée : Journée, Classes, Ressources, Profil | S l.111, 117, 121, 611, 844 ; DV D7 |

## 2. Zone centrale

| Élément | ES | IG | EN | Référence |
|---|---|---|---|---|
| Vidéo de l'enseignant | oui, vignette si support | oui, grande vignette | sa propre vignette si caméra active | S l.598-599, 730, 831 ; SY I-3 |
| Sa propre vidéo | vignette ou masquée selon politique | idem | oui | S l.598 |
| Vidéos des autres élèves | non prévu dans CLV-04 : ne pas afficher | **jamais** (« données des autres élèves ») | oui, « vidéo de la Classe » sans support | S l.81, 598, 830 |
| Support partagé | oui, suit l'enseignant | oui, suit l'enseignant | oui, le pilote | S l.62, 769, 99 ; P07 l.239-248 |
| Annotations, pointeur (affichage) | oui, en lecture | oui, en lecture | oui, les crée | S l.248 |
| « Choisir un support » (rien partagé) | non ; texte « {Titre} {Prénom} n'a rien partagé pour l'instant. » | non ; même texte | oui | DV D3 |
| Pagination ‹ 1/12 › active (change la page de tous) | **non** | **non** | oui | S l.1366 (publication réservée à l'enseignant), l.99 |
| Indicateur de page, zoom local | permis s'il ne publie rien (« contrôles de lecture permis ») | non | oui | S l.67, 599 ; IG : l.77, 789 |
| « Aucun élève n'est encore connecté. » | non | non | oui | S l.875 |
| « Votre enseignant n'est pas encore arrivé. » | oui | « Ton professeur arrive. » | non | S l.617, 745 |

## 3. Commandes

| Élément | ES | IG | EN | Référence |
|---|---|---|---|---|
| Micro | « Micro » | « Parler » | « Micro » | S l.625, 746, 851 |
| Caméra | seulement si autorisée | seulement si autorisée, sinon aucun bouton | oui | S l.31, 268-273, 779, 852 |
| Agrandir / focus | « Agrandir le support » | « Agrandir » | non prévu au dock enseignant | S l.627, 750, 835 |
| Bouton « Réseau » | non (texte d'état seulement si faible) | non | oui | S l.835, 853 ; DV D5 |
| Quitter | oui ; confirmation « Vous pourrez revenir si la séance est encore ouverte. » | oui, vers fin guidée | oui ; « Quitter et ouvrir le cahier » | S l.629, 720, 861-863 |
| Bouton « Élèves x/y », compteur | **jamais** | **jamais** | oui | S l.602, 81, 832, 849 |
| Bouton « Supports » | **jamais** | **jamais** | oui | S l.833, 1007 |
| Outils d'enseignement (Pointeur, Marquer, Masquer, Annoter) | **jamais** | **jamais** | oui, seulement si câblés et support actif | S l.591, 801, 834 ; DV D8 |
| Présenter un support (CLV-08) | **jamais** | **jamais** | oui | S l.147, 999-1012 |
| Prolonger la séance | personne : le serveur décide | personne | personne (aucun bouton) | S l.275-281 |
| Terminer la séance pour tous | personne | personne | non ; « Terminer pour moi » seulement | S l.154, 821 |
| Main levée | hors spec : ne pas ajouter | hors spec | hors spec | absent de S |

## 4. Panneau Élèves (CLV-07) : enseignant uniquement

Liste des présents, statuts « Connecté / Pas encore connecté / Connexion interrompue », fiche (Niveau, Objectif actuel, Dernière séance, À reprendre, Présence récente, Travail actuel), actions Rappeler, Choisir pour réciter, Noter, Signaler un besoin : **EN seul** (S l.922-976). Jamais « Absent » avant consolidation (S l.877, 980). Retards : aucun affichage en salle, la présence est calculée par le serveur (S l.28, 1373). Notes : enseignant seul (S l.974) ; ES et IG ne voient jamais de notes internes (S l.65, 81). Le panneau se pose **dans un cadre enseignant** : dock Micro, Caméra, Réseau, Quitter ; aucune notice « Votre parent… » ; compte de l'enseignant (DV §2 point 10).

## 5. Fin de séance

| Élément | ES | IG | EN | Référence |
|---|---|---|---|---|
| Écran | CLV-09 « Séance terminée » + « Retour à la Classe » | « La séance est terminée. » + « Retour à l'accueil » | CLV-10 + « Ouvrir le cahier » | S l.1089-1101, 1150-1157 |
| Récapitulatif (Classe, heure de fin, élèves connectés, « Cahier à compléter ») | **jamais** | **jamais** | oui | S l.1148 |
| Présent / Absent | jamais | jamais | pas avant consolidation | S l.1113, 1109 |
| Mention d'enregistrement | non (séance finie) | non | non | SY I-1 |

## 6. Ce que chaque rôle ne doit JAMAIS voir

- **Élève standard** : compteur ou liste d'élèves, fiches, notes, boutons Élèves, Supports, Réseau, outils d'enseignement, pagination qui pilote, durée restante, récapitulatif enseignant, cahier, notice de visite d'un autre enfant, « Tuteur de… », contrôleur incognito, coordonnées d'autres familles, identifiants techniques, navigation « Foyer » ou « Journée », compte d'une autre personne (S l.65, 602).
- **Interface guidée** : tout ce qui précède, plus zoom, indicateur de page, vidéos d'autres élèves, réglages de Classe, détails techniques, explication longue de caméra, bandeau « La séance se poursuit. », barre de navigation dense (S l.81, 117, 779, 789).
- **Enseignant** : téléphone, e-mail, adresse, identité complète des tuteurs, paiements, KYC, géolocalisation, identifiants d'appareil, présence d'un contrôleur incognito, formulation élève « Votre parent observe… », compte ou navigation d'un élève ou d'un tuteur (S l.97, 889, 974 ; SY I-6).

## 7. Écarts des maquettes à corriger au nom de cette matrice

1. CLV-04 et CLV-05 desktop : barre latérale avec « Foyer » (destination tuteur) et compte « Mariam » dans un cadre qui doit être celui du rôle effectif (V01 l.22, V02 l.27).
2. CLV-04 desktop : flèches ‹ 1/12 › actives côté élève ; à rendre non pilotantes (S l.1366). SY I-5 ne s'applique pleinement qu'à la vue enseignant.
3. CLV-06, 07, 08, 10 desktop : compte « Mariam » et « Foyer » (DV §2 ; SY I-6).
4. CLV-07 mobile et web étroit : cadre élève (notice « Votre parent… », dock sans Réseau) autour d'un panneau enseignant.
5. SY I-2 met une notice de visite sur l'élève standard : conforme seulement pour l'élève concerné (S l.667) ; S §3 l.151 et l.1370 omettent CLV-04, S l.600 prime.

À trancher : Q4, zoom local ES, vidéos des autres élèves en ES.

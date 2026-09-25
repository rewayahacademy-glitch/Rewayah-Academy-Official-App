# Classe et visio : direction visuelle (avis du directeur + décisions de conception)

Date : 25/09/2026. Rédacteur : poste B (coordinateur). S'applique à **toute** salle de classe, quel que soit le rôle (élève standard, Interface guidée, enseignant, tuteur observateur, contrôleur plus tard). Ce document prime sur les 10 images reçues quand ils se contredisent.

## 1. Les images reçues (bibliothèque de référence)

Rangées dans `projet/ressources` : `lancement/classe image/` (10 fichiers, renommés). Spec : `specs/02_classe_et_visio/02_CLASSE_ET_VISIO.md`.

| Fichier | Contenu |
|---|---|
| `CLV-04-05-06_mobile_sombre.png` | Salle élève, guidée, enseignant (mobile) |
| `CLV-07-08-10_mobile_sombre.png` | Panneau Élèves, panneau Supports, fin de séance enseignant (mobile) |
| `CLV-04-05-06_web_etroit_sombre.png` | Les trois salles, web étroit |
| `CLV-07-08-10_web_etroit_sombre.png` | Élèves, Supports, fin, web étroit |
| `CLV-04_eleve_desktop_sombre.png` | Salle élève, desktop |
| `CLV-05_guidee_desktop_sombre.png` | Salle guidée, desktop |
| `CLV-06_enseignant_desktop_sombre.png` | Salle enseignant, desktop |
| `CLV-07_eleves_desktop_sombre.png` | Panneau Élèves, desktop |
| `CLV-08_supports_desktop_sombre.png` | Panneau Supports, desktop |
| `CLV-10_fin_desktop_sombre.png` | Fin de séance, desktop |

Toutes sont en mode sombre ; la spec demande aussi le clair (on le dérive des jetons, pas de maquette à demander).

**Ce qu'on garde des images** : les textes (ils suivent la spec §6), la sémantique des couleurs (vert = en ligne, ambre = observation, rouge = quitter), le contenu des fiches Élèves (six champs pédagogiques, quatre actions), la structure du panneau Supports (Reprendre, Récents, Ressources de la Classe, Voir toute la bibliothèque), l'écran Fin de séance (bon tel quel, à aérer légèrement).

**Ce qu'on NE reproduit PAS** : la mise en page, la densité, la taille des bandeaux et des contrôles, la navigation. Voir §2.

## 2. Avis du directeur (25/09, texte fidèle résumé)

1. Tout est trop **compact, congestionné**. La vision de l'académie : **simplicité et facilité**.
2. Des éléments d'information sont **trop grands** : « Cours enregistré, visite de contrôle possible », « Votre parent observe la séance ».
3. Des **contrôles trop grands** alors qu'on n'est pas en mode d'affichage accessible.
4. Le **contenu partagé** ne prend pas assez de place et tout est collé contre lui ; il doit **respirer** pour ne pas distraire, surtout les enfants.
5. Il manque un **mode focus** : tout disparaît sauf le contenu et les quelques contrôles nécessaires.
6. Il manque l'écran **« rien n'est partagé »** (partager n'est pas obligatoire).
7. Le **style du layout** n'est pas approuvé : appliquer les standards UX qui mettent le besoin humain en premier.
8. Aucune interface qui demande une **formation** : l'app automatise les activités de l'académie.
9. La **navigation**, surtout sur web, n'est pas approuvée.
10. **CLV-07** (web et mobile) montre des options réservées à l'enseignant dans un cadre d'élève.
11. Beaucoup d'éléments sont **communs à plusieurs rôles** : la salle n'appartient pas à un seul rôle.

### Vérification du point 10 (faite le 25/09)

Le directeur a raison. La spec dit que CLV-07 est un panneau **enseignant uniquement** (parent : CLV-06). Le contenu du panneau est juste, mais il est posé dans un **cadre d'élève** :
- bandeau élève « Cours enregistré, visite de contrôle possible » et « Votre parent observe la séance » (mobile, web étroit) ;
- barre Micro / Caméra / Agrandir sans « Réseau », c'est la barre élève (mobile, web étroit) ;
- sur desktop, le compte affiché est **« Mariam »** (une élève) avec la navigation **« Foyer »** (tuteur). Même défaut sur CLV-06, CLV-08 et CLV-10 desktop.
Conséquence : chaque écran doit être construit à partir du **rôle effectif** ; un composant partagé reçoit le rôle et n'affiche que ce que ce rôle a le droit de voir (spec §1 « Ne doit jamais voir »).

## 3. Décisions de conception (poste B, à valider par le directeur sur planches, lot CL-1)

Standards appliqués : Nielsen (minimalisme, reconnaissance plutôt que rappel), divulgation progressive, loi de Fitts et de Hick (peu de choix, cibles à la bonne taille), WCAG 2.2 AA, ICO Children's Code (enfants), charte des consentements `09_consentements/CHARTE.md` (information d'enregistrement toujours visible, jamais cachée).

**D1. Le support est roi.** Quand un support est partagé, il occupe tout l'espace utile : au moins 75 % de la surface sur desktop, pleine largeur sur mobile. Marge autour du support : 24 px mobile, 40 px desktop. Rien ne touche le support.

**D2. La vidéo de l'enseignant devient une vignette flottante** (coin haut droit, déplaçable, réductible en pastille avec le nom). Plus de colonne latérale permanente.

**D3. Rien de partagé = la vidéo au centre.** La vidéo de l'enseignant prend le centre, avec un texte calme en dessous : « {Titre} {Prénom} n'a rien partagé pour l'instant. » (élève) ; côté enseignant, un seul bouton doux « Choisir un support » en plus. Aucun écran vide, aucun gris mort.

**D4. Informations obligatoires en pastilles discrètes.** « Cours enregistré » et « observation » deviennent de petites pastilles dans l'en-tête (icône + 2-3 mots, taille libellé). Toucher la pastille ouvre la phrase complète. L'enregistrement reste **toujours visible** (obligation légale), même en mode focus (pastille minimale). Supprimés : le bandeau vert « La séance se poursuit », les doubles bandeaux.

**D5. Contrôles à taille normale.** Cible tactile 48 px, icône 24 px, un seul dock centré en bas : Micro, Caméra, Plus, Quitter. Les grands boutons colorés (72 px) sont réservés à l'**Interface guidée** (CLV-05) et au réglage « affichage accessible ». Réseau n'est pas un bouton : c'est un indicateur qui ne s'affiche que si la connexion faiblit.

**D6. Mode focus.** Un bouton « Focus » (icône agrandir) : tout disparaît sauf le support, la pastille d'enregistrement et un dock réduit (Micro, Quitter, Sortir du focus). Sur desktop, le dock s'efface après 3 s sans mouvement et revient au moindre geste (sauf si « réduire les animations » ou lecteur d'écran actif : il reste). Proposition : l'Interface guidée démarre en focus par défaut (à confirmer par le directeur).

**D7. Navigation en salle.** Dans la salle, **pas de barre latérale de l'app ni de barre du haut** (ni sur web, ni sur mobile) : la salle est plein écran. En-tête minimal : retour (« Revenir à la Classe », la salle reste active), titre de la séance, pastilles. Une seule façon de sortir : Quitter. Ailleurs dans l'app, un rappel « Revenir à la séance » reste visible (spec §2.4).

**D8. Outils de l'enseignant à la demande.** Élèves et Supports s'ouvrent en panneau (tiroir latéral 320 px sur desktop, feuille du bas sur mobile) depuis deux boutons du dock enseignant, jamais ouverts par défaut. Les outils d'enseignement (Pointeur, Marquer, Masquer, Annoter) forment une petite barre flottante contre le support, visible seulement quand un support est partagé. Pagination et zoom : attachés au support, discrets.

**D9. Un seul modèle, plusieurs rôles.** La salle = un gabarit unique `SalleSeance` paramétré par le rôle effectif. Composants partagés à créer une fois (lot CL-3) : `ChromeSeance` (en-tête minimal), `ZoneSupport` (+ état vide + focus), `VignetteVideo`, `DockSeance` (variantes standard / guidée / enseignant), `PastilleSeance` (enregistrement, observation, réseau), `BandeauConnexion` (reconnexion), `PanneauSeance` (tiroir desktop / feuille mobile), `ResultatSeance` (fin de séance). Réutilisés par : élève, Interface guidée, enseignant, observation tuteur, contrôleur.

**D10. Zéro formation.** Un seul chemin par action, libellés en mots (pas d'icône seule sans libellé sauf dans le dock réduit, qui a une infobulle et un libellé accessible), aucune option avancée visible par défaut.

Ces décisions complètent `01_visuel/GABARITS.md` (gabarits G1-G9) : la salle devient le gabarit **G10 « Salle de séance »** une fois validée.

## Mise à jour du 25/09 au soir : les maquettes du directeur priment

Le directeur a rejeté les planches redessinées selon D1-D10 : coins surchargés, chevauchements, support tassé, avatars étirés. **Ses 10 maquettes priment désormais sur ce document.** On les garde et on ne rectifie que leurs erreurs, selon la méthode du rôle tuteur (relevés `V/`, synthèse `V/00_SYNTHESE_RECTIFICATIONS.md`, règles R1-R9 et invariants I-1 à I-8). Les décisions D1-D10 ne s'appliquent que si elles vont dans le sens de ces rectifications.

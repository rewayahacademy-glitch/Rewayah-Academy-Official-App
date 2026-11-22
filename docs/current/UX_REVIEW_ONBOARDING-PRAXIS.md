# UX_REVIEW ONBOARDING-PRAXIS (22/11/2026)

Lot ONBOARDING-PRAXIS : le questionnaire avant le compte, guidé par Praxis, d'après la maquette validée
par le directeur le 22/11/2026 (`docs/current/maquettes/onboarding-praxis/prototype.html`, décisions
datées dans `docs/current/ONBOARDING-PRAXIS-2026-11-22.md` §0). La maquette fixe le parcours, les textes
et les branches ; cette note justifie seulement la disposition (DESIGN-GOV §4) et chaque écart. Elle ne
change ni permission, ni état serveur, ni règle métier (§4.3).

| # | Règle | Source | Conclusion | Modification |
| :-: | :-- | :-- | :-- | :-- |
| 1 | Une question par écran, progression visible | Nielsen n° 1 « Visibilité de l'état du système » ; Baymard, formulaires en étapes | Quatre chapitres nommés et une barre à quatre segments disent où l'on est et ce qui reste, sans compteur qui change de total d'un écran à l'autre | `CoquilleOnboarding` : chapitre « n/4 · nom » et `remplissageOnboarding` (chapitres faits pleins, chapitre courant à la part de ses écrans) |
| 2 | Disposition par taille de fenêtre ; jamais une carte de téléphone étirée sur ordinateur | Material 3, *Window size classes* ; directeur, 21/11/2026 (règle répétée) | Sous 840 dp : une colonne, la page défile. À 840 et plus : deux colonnes bornées à 1040, Praxis et sa bulle (360) au début de ligne, la question et ses réponses (640 au plus) à côté | Test : à 1280 et 1440, le groupe de réponses ne dépasse pas 640 ; à 320, rien ne déborde |
| 3 | Bouton principal au bas du formulaire ; pas de bouton pleine largeur sur ordinateur | DESIGN-GOV contrats B et C ; K-56 | Un seul bouton plein par écran, pleine largeur au téléphone, à sa largeur et au bord de fin sur ordinateur | `verifierUnSeulBoutonPlein` dans les tests de l'écran |
| 4 | Un bouton qui ne peut pas aboutir n'est pas grisé | lib/CLAUDE.md (BOUTONS-GRISES-1) ; contrôle `bouton-grise` | **Écart daté à la maquette** : la maquette grise « Continuer » tant qu'il n'y a pas de réponse. Ici, il reste actif et dit sous la question « Réponse requise » (règle du dépôt, plus récente pour le code) | `_continuer(pret:)` et `questionnaire-reponse-requise` |
| 5 | Tout choix s'explique ; toute la carte est cliquable | K-58 ; Fitts | Les cartes reprennent le libellé et la précision de la maquette (`ChoiceCardGroup`, `description`) ; les choix courts (âge, juz, sourates, langues, source) sont des puces `FilterPill` | Aucun bouton recomposé ; `Wrap` de puces déclaré « choix de formulaire » |
| 6 | Déduit > choisi > saisi | K-57 | Hafs présélectionnée ; « Mémoriser » présélectionné pour qui a mémorisé ; langue de l'appareil proposée ; fuseau déduit ; prénom du titulaire jamais redemandé après la connexion | Seuls le prénom, le nom, « une autre lecture » et « une langue absente » sont saisis (rien d'autre ne les connaît) |
| 7 | Messages d'erreur utiles | K-59 ; Nielsen n° 9 | Un prénom refusé : Praxis dit pourquoi (« Seulement des lettres… »), la même phrase sous le champ | `prenomValide` (lettres de toute écriture, 2 à 30) |
| 8 | Mouvement réduit = rien, toute l'information reste | DECISION-MOUVEMENT §3.12 ; WCAG 2.3.3 | Les mots de la bulle apparaissent un à un (35 ms d'écart, jetons) ; la courbe du chemin se trace une fois ; la barre glisse. Sous « Réduire les effets » : tout est posé d'emblée, Praxis immobile, yeux ouverts | `BullePraxis`, `CourbeChemin`, `_Segment`, `PraxisGuide` |
| 9 | Le lecteur d'écran lit le sens, pas le décor | WCAG 1.1.1, 4.1.3 | Praxis est décoratif (exclu) ; sa bulle est une région vivante qui lit la phrase entière ; la courbe a un libellé (« Durée prévue 15 semaines, date limite 20 semaines ») ; la barre est lue par son chapitre | `Semantics(liveRegion)` |
| 10 | RTL | Material 3, *Bidirectionality* | Les rangées, la barre et la courbe suivent la direction (la courbe se miroite en arabe) | `Directionality` dans `_PeintreCourbe` |

## Écarts à la maquette, et pourquoi

- **Gestes de Praxis** (salut, montrer, main sur le cœur, réfléchir) : le Praxis de l'application
  (`PraxisVivant`) n'a pas encore ces gestes ; seule son humeur suit l'expression (joie : heureux ;
  réflexion, étonnement : curieux ; attente, sourire : calme). On ne redessine pas Praxis
  (`praxis-rewayah` §10) : le lot PRAXIS-CANON les apportera.
- **« Continuer » jamais grisé** : voir ligne 4.
- **Retour** : disque retour de 48 (`DisqueRetour`) au lieu du texte « ← Retour ».
- **« Continuer avec Google »** : bouton secondaire avec le logo, comme partout dans l'application, au lieu
  d'un lien souligné (règles de marque de Google).
- **Indice de l'écran « lien envoyé »** sur une candidature d'enseignant existante : non affiché, car le
  refus serveur `deja_candidat_enseignant` n'est pas codé (ce serait une promesse fausse).
- **« Se déconnecter »** reste en lien sous « Envoyer ma demande » (sortie de sécurité déjà présente).
- **« Objectif »** devient « Objectif choisi » au récapitulatif (contrôle `libelle-ambigu`).
- **Soussou** : absent de la maquette, donc absent de la liste (point ouvert).

## Ce qui n'est pas prouvé

- Rien n'a été vu par le directeur en production. La migration `20261130979000_onboarding_praxis.sql`
  n'est pas installée : elle doit l'être **avant** la fusion (sinon une source choisie ou l'objectif
  « prière » ferait échouer l'envoi de la demande).
- Captures R3 : `docs/current/captures/E2E/onboarding-praxis/`, rendues par les tests de widgets
  (polices du dépôt), pas par un navigateur.

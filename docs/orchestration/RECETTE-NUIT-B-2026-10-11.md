# RECETTE-NUIT-B — relevé (10/10/2026)

Branche `claude/recette-nuit-b`, depuis `origin/ccr-1b1bfa0b-m1kvkk` (f3a0680a). Rôles : administration, contrôleur, comptable, plus `/compte`.

## Méthode

`test/recette/recette_nuit_b_test.dart` monte chaque écran atteint depuis `app_router` (56 routes sans paramètre) sur le vrai routeur, à 360 px, en trois cadrages : français ×1, français ×2, arabe (RTL) ×1. Il vérifie : aucune exception ni débordement, aucun mot coupé ou tronqué (`motsCoupes`, vraies polices), cibles tactiles ≥ 48 (`androidTapTargetGuideline`, à ×1). 168 cas.

Statuts : spécifié / présent dans le code / testé localement. Rien n'est testé sur staging ni déployé.

## Défauts trouvés et corrigés (test rouge avant, vert après)

| Écran | Défaut | Correction |
| :--- | :--- | :--- |
| `/admin/operations/groupes` (`ChampRecherche`, partagé) | L'aide du champ (« Nom, numéro, code ou enseignant de la classe ») était tronquée à ×1 ; l'étiquette l'était à ×2 (elle restait dans le champ au-delà de ×1,3) | L'aide passe à la ligne (6 lignes), l'étiquette sort du champ dès qu'elle ne tient pas, à toute échelle |
| `/admin/securite-audit/acces-agents` | Deux colonnes « Ce qu'il pourra / ne pourra pas » : mot « l'application, » coupé à ×2 | Colonnes empilées quand la largeur est inférieure à 480 px × échelle |
| `/compte` | « Consentements » (un mot de 13 lettres) coupé dans la rubrique à ×2 | Rangée libellée « Visites des parents » (fr) / « زيارات أولياء الأمور » (ar), clé `compte.tuteur.securite.consentements`, source déclarée |

## Sans défaut mesuré

Les 56 routes passent sans exception, sans mot coupé en arabe ×1, et les cibles ≥ 48 à ×1. Les 5 états sont couverts par les tests de chaque écran et par `BlocAsynchrone` ; le balayage monte l'état « port indisponible » de production (EtatSysteme), pas les cinq états un par un.

## Limites

- Le balayage ne couvre pas l'arabe ×2, ni les routes à paramètre (`/compte/profils/:id`, `/admin/studio/canaux/:canalId`).
- Les couleurs en dur restent mesurées par `verifier_jetons` (18, base inchangée) ; pas de contrôle visuel de contraste dans ce lot.
- Favicon : `assets/brand/logo/violet/symbole-plein.svg` n'existe pas sur ccr. Rien copié, `web/index.html` inchangé.

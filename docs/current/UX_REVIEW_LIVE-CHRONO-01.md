# UX_REVIEW LIVE-CHRONO-01 : chrono discret de la salle de classe

Lot demandé par l'orchestrateur (11/10/2026, ordre du directeur de finir le tableau).
Disposition `PROPOSITION` confrontée aux référentiels (DESIGN-GOV §4). Aucune règle
métier modifiée : le chrono ne donne ni droit, ni preuve, ni décision.

## Ce qui est livré

Une ligne compacte dans l'en-tête de la salle de classe (`ChromeSeance`, celle de
`/salle` et de `/tc/classe`), sous ou à côté de la ligne d'état :
`00:12:34 écoulé · 00:32:26 restant`. Au dépassement : `Temps prévu écoulé`, jamais
un temps négatif. Avant T0 : rien. Enseignant et élève en interface standard ;
**jamais en Interface guidée**. Sans horodatages dans la source : aucune ligne.

## Règles et conclusions

| Règle | Source (consultée le 11/10/2026) | Conclusion | Modification |
| :--- | :--- | :--- | :--- |
| Un minuteur qui annonce chaque seconde est inutilisable au lecteur d'écran | WCAG 2.2 AA, 4.1.3 (messages d'état) et 2.2.2 (mettre en pause, arrêter, masquer) ; Material 3 accessibilité | Le texte visible est exclu de la sémantique ; un seul nœud `liveRegion` annonce la durée **en minutes**, donc une annonce par minute | `ChronoSalle` : `ExcludeSemantics` + libellé `annonce` ; minutes restantes dérivées des minutes écoulées (un seul changement par minute) |
| Une valeur qui change vite ne doit pas faire bouger la mise en page | Material 3 (typographie), Apple HIG (chiffres tabulaires) | Chiffres tabulaires, deux chiffres par champ, largeur stable | `FontFeature.tabularFigures`, `HH:MM:SS` |
| Charge de pression et de comparaison à éviter pour un enfant | Children's Code (ICO), Apple HIG (calme), Nielsen 8 (design minimaliste) | Le chrono ne s'affiche pas en Interface guidée ; en standard il reste de la couleur d'encre atténuée, sans alerte ni couleur d'urgence | `VueSeance.voitChrono` faux en guidée ; `inkMuted` |
| Un temps négatif est une fausse information | `docs/current/` (SessionClockVM, invariant 3) | `Temps prévu écoulé`, aucun signe moins, aucun compte après la fin | `ChronoSeance` : restant borné à zéro |
| Un compteur qui dérive ment après un retour d'arrière-plan | Fiabilité des horloges Flutter (minuteurs suspendus en arrière-plan) | Aucun compteur : tout est recalculé depuis les horodatages UTC à chaque tic, au retour d'arrière-plan et au rétablissement de la connexion | `ChronoSeance.a` pure ; `WidgetsBindingObserver` ; recalcul au changement de `ConnexionSeance` |
| Bidirectionnel : des chiffres dans une phrase arabe | Unicode UAX 9, WCAG 1.3.2 | Chiffres latins isolés de gauche à droite dans la phrase arabe | isolats `U+2066 U+2069` autour de `HH:MM:SS` |
| Durée insécable (DUREE-INSECABLE-1) | Décision du directeur, 05/10 | Espace insécable entre le temps et son mot | `{temps} écoulé`, `{temps} restant` |

## Choses à ne pas faire croire

Le chrono compte **la séance**, pas la personne : aucun libellé ne parle de présence,
de ponctualité ni d'assiduité (test de non-régression sur les mots). Entrer tôt ou
tard ne le change pas. T0 est le début de séance servi par l'horloge de la séance
(`SessionClockVM.debutUtc`), pas l'heure d'entrée de l'utilisateur. La donnée du
« début réel » du serveur, si elle diffère un jour du début prévu, entrera par les
mêmes bornes sans changer l'écran.

## Preuves

`test/core/tc_horloge/chrono_seance_test.dart` (fonction pure, dérive, fuseaux, jamais
négatif) ; `test/features/salle_seance/chrono_salle_test.dart` (horloge factice : tic,
retour d'arrière-plan, reconnexion, annonce par minute, dépassement, guidée, 320 à
1440 px, texte ×1 et ×2, clair et sombre, fr et ar) ; captures clair et sombre à 390
et 1440 dans `docs/current/captures/LIVE-CHRONO-01/`. Arabe à relire par un locuteur
natif.

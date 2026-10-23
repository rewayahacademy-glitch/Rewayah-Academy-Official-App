# UX_REVIEW LIVE-PAUSE-01 : pause programmée par l'enseignant

Décision F3 du directeur (27/09/2026). Disposition `PROPOSITION` confrontée aux
référentiels (DESIGN-GOV §4). Aucune règle métier modifiée : la pause ne donne ni droit,
ni preuve de présence. Rien côté famille.

## Ce qui est livré

1. **Réglage** dans la fiche de la classe de l'enseignant (aucune route nouvelle) : un
   interrupteur « Pause programmée », le moment (15, 30, 45, 60, 90 min après le début)
   et la durée (5, 10, 15, 20, 30 min). « Enregistrer la pause » n'est rendu que
   lorsque le brouillon diffère du réglage lu (jamais un bouton grisé). Le réglage vaut
   de séance en séance.
2. **En séance**, dans la ligne du chrono : « Pause dans 5 min » ; pendant la pause
   « Pause, reprise à 18:40 » ; un lien « Démarrer la pause » / « Terminer la pause »
   pour l'enseignant. Après la pause : « Pause prise ».
3. **Récapitulatif de fin** (enseignant) : « Pause prise, N min » ou « Pause prévue, non
   prise ». Rien si aucune pause n'était prévue.
4. **Production** : le port rend `CapaciteIndisponible` ; le bloc dit « pas encore
   disponible ». Démonstration derrière `PLAYGROUND` (`/demo/salle?...&chrono=1`).

## Choix justifié : le chrono et la pause

Temps écoulé = temps depuis T0 **moins** la pause ; temps restant = fin prévue −
maintenant, **inchangé**. Raison : le « restant » répond à « jusqu'à quand sommes-nous
dans la salle ? », qui est une heure de fin fixée par l'horaire de la classe ; la pause
ne la déplace pas, sinon la famille et l'élève suivant seraient trompés. Le « écoulé »
répond à « combien de temps avons-nous travaillé ? » ; y compter la pause serait
faux. Pendant la pause l'écoulé est donc figé et le restant continue de baisser, ce qui
dit honnêtement que la pause consomme de la séance. Alternative écartée : rallonger le
restant de la durée de pause (décale la fin sans décision de l'enseignant ni de
l'horaire).

## Règles et conclusions

| Règle | Source (consultée le 11/10/2026) | Conclusion | Modification |
| :--- | :--- | :--- | :--- |
| Un état qui change doit être annoncé sans surcharge | WCAG 2.2 AA 4.1.3 | Une annonce par minute et une annonce à chaque changement d'état de la pause, région vive, texte visible exclu | `ChronoSalle` : `annonceDans`, `annonceEnCours` |
| Pas de bouton grisé | DESIGN-GOV, Nielsen 5 (prévention des erreurs) | Commandes rendues seulement si le serveur les accorde et si l'action a un sens | `peutPiloter`, `peutModifier`, « Enregistrer » conditionnel |
| Un widget lit une capacité, jamais un rôle | `00_LIRE_D_ABORD` | Le client ne déduit rien d'un rôle | `PauseSeance.peutPiloter`, `ReglagePause.peutModifier` |
| Durée insécable (DUREE-INSECABLE-1) | Décision du directeur, 05/10 | Espace insécable entre le nombre et « min » | `LibellesGroupe.insecable` partout |
| Chiffres dans une phrase arabe | Unicode UAX 9, WCAG 1.3.2 | Heures et nombres isolés de gauche à droite | `isolerSens`, isolats U+2066 U+2069 |
| Cibles tactiles et zoom du texte | WCAG 2.2 2.5.8, 1.4.4 | 320 px à texte ×2 sans débordement | `Wrap` de la ligne chrono, `ControleSegmente` |
| Pas de pression sur un enfant | Children's Code (ICO) | Rien en Interface guidée | `voitChrono` faux en guidée |
| Contrôle à la minute près, pas à la seconde | Material 3 accessibilité | Aucun compte à rebours de pause à la seconde | texte à la minute |

## Choses à ne pas faire croire

La pause compte du temps de séance, pas une personne : aucune présence, aucun retard,
aucune facturation (`CONTRAT_PORT_PAUSE_SEANCE.md` §4). L'heure de reprise est une
indication, pas une obligation : l'enseignant décide quand terminer.

## Preuves

`test/core/pause_seance`, `test/core/tc_horloge/chrono_seance_test.dart` (groupe
pause), `test/features/salle_seance/pause_salle_test.dart`,
`test/features/salle_seance/recap_pause_test.dart`,
`test/features/fiche_groupe_pause/bloc_pause_classe_test.dart` (cinq états, production,
lecture seule sans capacité, conflit de version, 320 et 1440 px, ×1 et ×2, clair et
sombre, fr et ar). Captures dans `docs/current/captures/LIVE-PAUSE-01/`. Arabe à
relire par un locuteur natif.

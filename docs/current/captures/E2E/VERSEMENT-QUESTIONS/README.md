# VERSEMENT-QUESTIONS (directeur, 16/11/2026)

« oui pour le paiement, corrige sa réponse et lance le lot. mais les modifications s'arrêtent après la
validation du dossier ». Source : `docs/current/DECISION-QUESTIONS-VERSEMENT-2026-11-16.md`.

Le vrai portail du candidat (`LienPaysVersement`), 360 de large, données de test
(`test/features/candidature/pays_versement_portail_test.dart`, groupe « VERSEMENT-QUESTIONS captures »,
`CAPTURE_DIR=docs/current/captures/E2E`).

- `panneau-360-fr.png`, `panneau-360-ar.png` : le panneau ouvert, « non » au compte bancaire, un pays, les services de
  paiement sur téléphone de ce pays (l'arabe de droite à gauche).
- `ferme-360-fr.png`, `ferme-360-ar.png` : le dossier est validé, le bloc est fermé : une phrase et le renvoi
  vers la messagerie.

Limites connues : le parcours (compte bancaire d'abord) n'a pas de capture dans ce dossier, il est prouvé par les
tests (`candidature_page_test`, `controleur_parcours_test`) ; le geste de la direction « Débloquer le versement »
n'a pas d'écran (serveur seul pour l'instant).

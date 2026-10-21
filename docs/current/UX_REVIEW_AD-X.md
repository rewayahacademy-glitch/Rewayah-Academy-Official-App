# UX_REVIEW_AD-X : revue UX des trois écrans AD-X (05/10/2026)

- **Cadre** : DESIGN-GOV-2026-09-26 §4.2 ; découpage `docs/current/AD-X_DECOUPAGE.md`.
- **Sources** : celles de `11_admin/UX_REVIEW_03_ADMIN_DOSSIERS.md` (pilotage), consultées le
  26/09/2026 par la session A, **non reconsultées le 05/10** (aucune navigation web dans cette
  session) ; les règles citées sont celles qu'elle a relevées. GOV.UK exclu.
- **Limite §4.3** : aucune ligne ne change une permission, un état serveur, une vérification
  ni l'effet d'une décision ; l'Espace de traitement ne décide rien.
- **K-63** : seule la composition des images est reprise ; thème, composants et jetons
  existants.

| Proposition | Source | Règle utile | Conclusion | Modification | Dérogation |
|---|---|---|---|---|---|
| ADM-01 : colonne « Activité récente » à côté des tuiles sur bureau, dessous ailleurs | Android list-detail et window size classes ; Flutter best practices (adaptive) | Décider sur l'espace disponible, jamais sur l'appareil | Ajustée | `LayoutBuilder` : deux colonnes si largeur ≥ 336 + 24 + 600 (Bento à 4 colonnes) et texte < 200 % | 336 = file du contrat D, aucune valeur nouvelle |
| ADM-01 : 3 lignes d'activité puis « Voir tout le journal » | NN/g (liste bornée) ; DASH D6 | Liste de tableau de bord bornée, lien vers la page dédiée | Conforme | Lien placé **sous** la carte : titre et lien ne tiennent pas sur 336 (débordement mesuré de 40 px avec `SectionHeader` à action) | Écart de place avec l'image (lien en tête) |
| ADM-01 : pas de « Charge du jour », pas de « Calendrier », pas de liste « Éléments à traiter » | DASH D1, D7 ; décision « planning-dir » du 05/10 | Une information une fois ; pas de liste non bornée ; pas de lien vers une page absente | Ajustée | Non construits ; besoins AD-X-BR-03/04 | Écart avec l'image, dit au découpage |
| ADM-18 : file + détail 336 / 24 / 728 à partir de 1088 utiles, feuille sinon | Contrat D ; Android list-detail | Compact : un volet ; large : deux | Conforme | Mêmes constantes que ADM-02 (`dossiers_page.dart`) | Aucune |
| ADM-18 : premier élément choisi en maître-détail, sans déplacer le focus | WCAG 3.2.1 On Focus | Pas de changement de contexte au focus | Conforme | Sélection de l'affichage seulement | Aucune |
| ADM-18 : puces Tous / Dossiers / Demandes avec nombre, tri en menu | Baymard filtres appliqués ; Hick ; FILTRES-1 | Filtres visibles, compteurs, saisie minimale | Conforme | `FilterPill` (passent à la ligne, jamais une rangée qui défile, ONGLETS-1) et `MenuFiltre` | Pas de recherche libre ni de filtre de statut : aucune donnée serveur |
| ADM-18 : un seul bouton plein « Ouvrir le dossier de… » à 16 sous la carte, bord de fin | Contrat B ; Fitts ; NN/g libellés | Action près de son objet ; libellé exact | Conforme | La décision reste dans ADM-02 / ADM-06 | Pas de « Refuser / Valider » de l'image (§4.3) |
| ADM-18 : pas d'avatar dans les lignes | Relevé AD-3R 02A (§9.4) | La ligne montre nom, nature, ancienneté, état | Ajustée | `LigneRubrique` sans avatar ; pastille seulement pour un état de pièce explicite | Écart avec l'image |
| ADM-18 : erreur par source | DASH D11 ; Nielsen n°9 ; K-59 | Dire quoi, pourquoi, quoi faire | Conforme | `EtatSysteme` par source + Réessayer, l'autre source reste | Aucune |
| ADM-09 : onglets d'état en puces avec nombre, « Créer » au bord de fin | Contrat B (CTA trailing) ; Hick | Une rangée, action principale à la fin | Conforme | Toutes / Actives / Clôturées | « En pause », « Archivées » : AD-X-BR-08 |
| ADM-09 : inspecteur 336 au bord de fin, sélection marquée | WCAG 1.4.1 ; 4.1.2 | Jamais la couleur seule ; état exposé | Conforme | Fond `washAccent`, contour `inkAccent` 2, `Semantics(selected)` (composant `DataCollection`) | Aucune |
| ADM-09 : croix « Fermer l'inspecteur » | WCAG 2.5.8 ; contrat B | Cible ≥ 48, libellé accessible | Conforme | `BoutonIcone` | Aucune |
| ADM-09 : inspecteur sans progression, niveau ni connexion | DESIGN-GOV §1 | Aucune donnée inventée | Ajustée | Non affichés (AD-X-BR-05 à 07) | Écart avec l'image |

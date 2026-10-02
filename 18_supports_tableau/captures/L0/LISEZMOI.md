# Captures « avant » de la salle (lot L0, TB-1a)

- Date : 03/10/2026.
- Commit de l'app : `corrections/revue-directeur-2026-10` @ `0796f75` (la salle est identique sur `98e3f9d` : `git diff --stat 0796f75 98e3f9d -- lib/features/salle_seance/` est vide).
- Recette : test de capture temporaire (vrai routeur `routesDemoSalle('dev')`, polices du dépôt, thème clair, densité 1), sous le verrou avec `CAPTURE_DIR`, 20/20 passés. Détail et lecture de chaque image : `../../UX_REVIEW_TB.md` §0 bis et §0 ter.
- Noms : `tb0_<profil>_<largeur>_<avec|sans>[_panneau_<nom>].png` ; profil = eleve, guidee, enseignant ; largeur = 390 (×844), 768 (×1024), 1440 (×900) ; « avec » = `?etat=repos`, « sans » = `?etat=rienPartage`.

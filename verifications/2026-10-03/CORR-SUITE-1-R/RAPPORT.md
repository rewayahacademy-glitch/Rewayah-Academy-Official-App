# CORR-SUITE-1-R : revue croisee (session 31184e36, poste A, 03/10)

Branche corrections/revue-directeur-2026-10 @ 98e3f9d (commits 4ef4e59, a8bcb00, 98e3f9d), copie detachee, aucun code modifie.

- Tests cibles (ad11_criteres, parcours_ad10, mes_classes, catalogue_galerie) : 53/53 verts (releve.txt, derniere ligne).
- A. PASS : AD-11 monte RewayahApp, tape la barre laterale AdminShell puis la vraie tuile AppCard (onPress -> Routes.adminPersonnesDossiers) ; T5 fait ensureVisible puis tap sur les vrais textes Passeport, Choisir, Envoyer. Aucun raccourci.
- B. FAIL : 12 captures (320/390/1280, x1/x2, LTR/RTL). Aucune exception ni RenderFlex ; Wrap OK, le cahier passe a la ligne sans coupure ; RTL : marques et chevrons a la bonne place. DEFAUT : a texte x2, la pastille StatusPill « Remplacement » se coupe au milieu du mot (« Remplacem / ent ») a toutes les largeurs (mes_classes_320_x2_ltr.png et releve.txt). Le test du commit ne controle que le mot du cahier et le bord droit, il n'a donc pas vu la coupure.
- C. FAIL : la galerie GrilleBento n'utilise pas les vraies tuiles (_TuileCompteur et _TuileDouble sont privees) : chiffre en texte simple et non en titre tabulaire, sans phrase de detail, et l'etat « compteurs calmes regroupes » montre un seul compteur au lieu de la tuile double Incidents + Acces echus (galerie_bento_*_1280.png comparee a vrai_centre_commande_1280.png).
- D. Captures faites : ce dossier.

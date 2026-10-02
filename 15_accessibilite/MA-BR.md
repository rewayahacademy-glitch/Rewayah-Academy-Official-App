# MA-BR : besoins serveur du Mode Accessibilité (à brancher à BR-1)

| Ligne | Besoin | Né de | Écran |
|---|---|---|---|
| MA-BR-1 | Demande de présentation standard d'un élève mineur : le serveur reçoit la demande (`PortDemandePresentation.demanderPresentationStandard`), la transmet au tuteur, qui l'accepte ou la refuse ; l'acceptation change `interface_mode` du profil. Côté élève : états « en cours », « envoyée », « envoi non confirmé » (D5). Page d'acceptation du tuteur : MA-9. | MA-8, décision S7 = b (27/09) | Mon espace (Mariam) |
| MA-BR-2 | Bascule de l'adulte entre Mode Accessibilité et présentation standard : écriture relue de `interface_mode` sur son propre profil, jamais optimiste ; aujourd'hui la bascule n'agit que dans la démonstration. | MA-8, MA24 | Mon espace (Idriss) |
| MA-BR-3 | Salle : reconnexion et réseau coupé réels (état « reconnexion » du direct, bandeau hors ligne branché sur la vraie connexion) ; la démonstration ne peut pas les simuler honnêtement ; aucun faux « en direct ». | MA-12 | Salle (Mariam, Idriss) |

| MA-BR-4 | Brancher les écrans MA en production dans main.dart : remplacer EcranAccessibiliteDemo par la coquille réelle choisie selon InterfaceMode du profil, avec les vrais ports (PortDemandePresentation, préférences, session). | Au branchement BR-1. Preuve : test de routage (mineur et adulte, Mode Accessibilité et standard), captures MA 390/768/1440, suite complète verte. Source : MA-RC-MINEURS (02/10). |

# MA-BR : besoins serveur du Mode Accessibilité (à brancher à BR-1)

| Ligne | Besoin | Né de | Écran |
|---|---|---|---|
| MA-BR-1 | Demande de présentation standard d'un élève mineur : le serveur reçoit la demande (`PortDemandePresentation.demanderPresentationStandard`), la transmet au tuteur, qui l'accepte ou la refuse ; l'acceptation change `interface_mode` du profil. Côté élève : états « en cours », « envoyée », « envoi non confirmé » (D5). Page d'acceptation du tuteur : MA-9. | MA-8, décision S7 = b (27/09) | Mon espace (Mariam) |
| MA-BR-2 | Bascule de l'adulte entre Mode Accessibilité et présentation standard : écriture relue de `interface_mode` sur son propre profil, jamais optimiste ; aujourd'hui la bascule n'agit que dans la démonstration. | MA-8, MA24 | Mon espace (Idriss) |

# VERIF-CORR-3 : BENTO-1 et libellés du lot 3

- Étape : VERIF-CORR-3 (K-03, K-61). Étapes couvertes : BENTO-1, FOYER-ADMIN-1, LIB-ABS-1, LIB-CAHIER-1, LIB-OBJ-1, LIB-ERR-1, KYC-PHOTO-1.
- Code : `D:\RA_TUTEUR\corrections`, branche `corrections/revue-directeur-2026-10` @ **98e3f9d**. Lecture seule ; aucun fichier suivi n'a été modifié.
- Date : 03/10/2026, vers 01 h 50.
- Production : test de capture temporaire `test/capture/verif_corr3_capture_test.dart`, lancé une fois par le verrou (journal `D:\RA_TUTEUR\yaaden-cache\verif-0310\verif-corr-3-captures.log`), puis supprimé. `git status` après suppression : seuls les trois fichiers `windows/flutter/generated_*` sont modifiés.
- Polices : celles du dépôt (`chargerPolicesDuDepot`). Densité 1, la largeur en pixels est donc la largeur logique.
- Hôte : le **vrai routeur** (`routeurProvider` avec la démonstration admin, `?demo=admin`, sur `/admin`), et les vraies routes de la démonstration enseignant (`routesDemoEnseignant`, `/demo/enseignant?ecran=...`). Exceptions, toutes en hôte isolé : `journee_charge_*` (coquille de démonstration enseignant, avec en plus 4 cahiers en retard et une lecture des prières qui échoue) et `kyc_*` (`DepotPiecePage` seule).
- Les échecs « MissingPluginException getTemporaryDirectory » du journal viennent de drift ou de path_provider sous `flutter test` : c'est l'environnement, pas l'écran. Le seul vrai défaut relevé par le journal est un **RenderFlex overflowed by 31 pixels on the right** (`journee_page.dart:875`) dans `journee_charge_320x2`.

## Images

| Fichier | Contenu | Ouverte |
|---|---|---|
| centre_demo_320x1_light.png | Centre de commande, démonstration, 320 px, texte ×1, clair. Grille Bento : grande tuile large « 9 Dossiers à valider », tuile haute « Demandes à trancher », deux carrés (« Élèves sans enseignant », « Cahiers manquants »), une tuile large double (Incidents, Accès échus). Aucun damier. Aucun débordement sur les 4 bords. | oui |
| centre_demo_320x1_dark.png | La même, en sombre. Formes identiques, contraste lisible, aucun débordement. | oui |
| centre_demo_320x2_light.png | 320 px, texte ×2 : la grille passe en une colonne (tuiles pleine largeur, de hauteurs différentes, pas de damier). **Le titre est coupé en plein mot : « Centre / de com / mande ».** | oui |
| centre_demo_1440x1_light.png | 1440 px, ×1 : à gauche la grande tuile 2×2 avec l'aperçu des 3 plus anciens dossiers (Omar, Amina, Yanis), au centre la tuile haute « Demandes », à droite deux carrés, puis une tuile large double sur toute la largeur. Aucun débordement. | oui |
| centre_demo_1440x1_dark.png | 1440 px ×1, sombre. | **non vu** |
| centre_demo_1440x2_light.png | 1440 px, texte ×2 : la grille passe en **une colonne** de 5 bandes pleine largeur (environ 900 px chacune), bien que la largeur permettrait 2 ou 4 colonnes. Pied de la barre latérale : « Administrat / eur » coupé. | oui |
| centre_rempli_320x1.png | 320 px, ×1, compteurs non nuls (12, 4, 7, 3, 2, 5). Incidents et Accès échus séparés en deux carrés. Grille variée, aucun débordement. | oui |
| centre_rempli_320x2.png | 320 px, ×2, compteurs non nuls. | **non vu** |
| centre_rempli_1440x1.png | 1440 px, ×1, compteurs non nuls : grande, haute, deux carrés, puis deux tuiles larges (Incidents 2, Accès échus 5). Aucun débordement. | oui |
| centre_rempli_1440x2.png | 1440 px, ×2, compteurs non nuls. | **non vu** |
| journee_320x1.png | Aujourd'hui, enseignant, 320 px, ×1 : « Signaler mon absence à cette séance » avec la ligne « Un remplaçant sera recherché pour vos élèves. » ; « À terminer » avec le point rouge et la pastille « Obligatoire » ; ligne « Cahier de transmission d'Al-Badr ». Dans la barre du bas : « Disponibilité / s » coupé. | oui |
| journee_320x2.png | 320 px, ×2, un seul cahier : **« À te / rmi / ner »** est coupé en plein mot (la pastille « Obligatoire » prend la place du titre), et le titre donne aussi « Aujourd'hu / i » et « remplacem / ent ». Aucun ruban de débordement. | oui (recadrée) |
| journee_1440x1.png | 1440 px, ×1 : « À terminer », le point rouge et la pastille « Obligatoire » tiennent sur une ligne ; la carte de la prochaine séance montre le lien d'absence et sa ligne de contexte. | oui |
| journee_charge_320x1.png | 320 px, ×1, 4 cahiers (le lien « Voir tout » apparaît) et une erreur de lecture des prières : **« À te / rmi / ner » est coupé même à ×1**. Le message LIB-ERR-1 apparaît sous les alertes ; le bouton « Réessayer » est plus bas. | oui (recadrée) |
| journee_charge_320x2.png | 320 px, ×2, même situation : **le titre « À terminer » ne garde qu'une lettre par ligne, le ruban jaune et noir de débordement apparaît sur le bord droit (31 px), et « Voir tout » est rogné.** Plus bas, le texte de l'erreur partielle tient en entier, suivi du bouton « Réessayer ». | oui (recadrée) |
| cahier_320x1.png | Cahier de transmission d'Al-Badr, 320 px, ×1 : pastille « Obligatoire », puis « Obligatoire après chaque séance », puis la description (sourate, verset, remplaçant). Le bouton dit « Valider le cahier de transmission ». Aucun débordement. | oui |
| cahier_320x2.png | 320 px, ×2 : **titre coupé « Cahier de trans / mission »**, et « d'Al- / Badr ». | oui (recadrée) |
| cahier_ajuster_320x1.png | Feuille « Ajuster · Aya » : « La suite pour Aya », « Objectif de Aya » (titre et champ), « Ce que Aya doit atteindre… ». **L'élision manque : il faudrait « Objectif d'Aya » et « Ce qu'Aya ».** | oui |
| cahier_ajuster_320x2.png | La feuille à ×2 : « Ajuster · / Aya », « La suite pour Aya ». Aucun débordement dans la zone ouverte. | oui (recadrée, haut) |
| photo_320x1.png | Feuille « Photo professionnelle » (profil, démonstration) : texte obligatoire avec le point rouge à droite de sa première ligne, la phrase sur le voile intégral, puis la notice. | oui |
| photo_320x2.png | Même feuille à ×2 : la colonne de texte, serrée entre le portrait et le point, donne **« obligatoir / e »** coupé en plein mot. | oui (recadrée) |
| kyc_320x1.png | Dépôt de la pièce d'identité, 320 px, ×1 : phrase de confidentialité (« jamais publique, seule la direction la consulte… protection de l'enfance »). Aucun débordement. | oui |
| kyc_320x2.png | Même écran, ×2 : la nouvelle phrase tient. Coupures plus anciennes ailleurs : « d'identit / é » dans le titre, « Passepor / t » dans un choix. | oui |

Variantes : 320 et 1440, texte ×1 et ×2, clair, plus le sombre pour le Centre de commande (seul `centre_demo_320x1_dark` a été ouvert). La variante « avec ou sans vidéo » ne concerne aucune de ces étapes.

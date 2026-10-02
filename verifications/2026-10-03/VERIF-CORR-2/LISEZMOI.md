# VERIF-CORR-2 : captures de vérification (K-03, K-61)

- Étape : VERIF-CORR-2, « K-03 corrections salle et séance (dont VIDEO-TUILE-1, demande répétée) ».
- Étapes couvertes : VIDEO-TUILE-1, ON-AIR-1, CTA-FIN-1, ANNUL-VIS-1, AVATAR-1, ETATS-BTN-1, NAV-FLECHES-1, CTRL-SALLE-1, BUG-PROG-1, SALLE-200-1.
- Code : `D:\RA_TUTEUR\corrections`, branche `corrections/revue-directeur-2026-10`, commit **98e3f9d**.
- Date : 03/10/2026.
- Production : test de capture temporaire `test/capture/verif_corr2_capture_test.dart` (vrai thème `AppTheme`, polices du dépôt via `chargerPolicesDuDepot`, faux services de `test/support/harnais.dart`), lancé par `flutter-verrou.ps1` (journal `D:\RA_TUTEUR\yaaden-cache\verif-0310\vc2-captures.log`, 54 tests, « All tests passed »), puis supprimé (`git status` revenu à : seuls `windows/flutter/generated_*` modifiés).
- Densité 2 pour les tailles de téléphone (une capture de 320 px fait 640 px de large), 1 pour 1400 px. Les tailles sont en points logiques : 320×700, 390×844.
- « avec vidéo » : le faux moteur rend un aplat bleu à la place de l'image de la caméra (aucune vraie vidéo en test).
- Le journal imprime pour chaque capture l'exception de mise en page éventuelle (`EXCEPTION <nom> : null` = aucune).

## Salle (`SallePage`), par rôle : VIDEO-TUILE-1, SALLE-200-1, CTRL-SALLE-1, ETATS-BTN-1

| Fichier | Ce qu'il montre |
|---|---|
| `salle_ctrl_320_x1_sansvideo.png` | Contrôleur, 320, texte ×1. Trois tuiles sans image : petit cercle d'initiales, nom centré dessous (micro barré à côté, nom resté sur l'axe du cercle), tuiles à 16 px des bords et entre elles, la galerie s'arrête au-dessus du rappel. Pas de mention « Cours enregistré, visite de contrôle possible » : seul le rappel « Visite de contrôle. Vous n'êtes ni vu ni entendu… ». Pastille « En direct ». Commandes : « Son reçu » (actif) n'a aucun disque visible ; « Agrandir » (inactif) : contour clair, icône sombre presque invisible sur le fond sombre. |
| `salle_ctrl_320_x1_avecvideo.png` | Même chose avec image : l'étiquette du nom reste en bas à gauche, sur la vidéo seulement. |
| `salle_ctrl_320_x2_sansvideo.png` | Contrôleur, 320, ×2 : le titre « Contrôle Rewayah » n'est plus visible, « Quitter » devient une icône, le rappel du contrôleur devient une bande avec la seule icône de bouclier, sans texte. Tuiles : rien ne déborde sur les 4 bords. Commandes en icônes seules, mot d'état absent. |
| `salle_ctrl_320_x2_avecvideo.png`, `salle_ctrl_390_x1_*`, `salle_ctrl_390_x2_*` | Variantes 390 et avec vidéo (produites, non toutes ouvertes une à une ; voir journal : aucune exception). |
| `salle_ctrl_320_x1_sansvideo_sombre.png` | Contrôleur, thème sombre : la salle passe sur fond clair, tuiles sombres ; l'icône d'« Agrandir » est invisible (clair sur clair) dans son contour. |
| `salle_ens_320_x1_sansvideo.png` | Enseignant, 320, ×1 : **débordement de 8 px à droite** (bande jaune et noire), « Quitter » coupé au bord droit. Textes sombres sur fond sombre, presque illisibles : « Présenté : page 42 sur 604 · 2:255 », titre « Cette page n'a pas pu être lue », position « 42 / 604 », mots « Micro coupé », « Caméra éteinte ». Navigation : flèche, position, flèche. Bandeau « Cours enregistré… » : le point rouge touche le bord gauche. |
| `salle_ens_320_x1_avecvideo.png` | Même débordement de 8 px (journal). |
| `salle_ens_320_x2_sansvideo.png` | Enseignant, 320, ×2 : aucune exception ; commandes en icônes ; bandeau sur deux lignes, le point à environ 4 px du bord gauche, le texte à environ 7 px du bord droit. |
| `salle_ens_390_x1_sansvideo.png` | Enseignant, 390, ×1 : mêmes textes sombres sur fond sombre ; tuile « Yasmine » à 16 px, nom centré ; la 2e tuile est coupée par le bas de la zone qui défile. |
| `salle_eleve_320_x1_sansvideo.png` | Élève, 320, ×1 : tuiles pleine largeur à 16 px, cercle et nom centré ; « Votre présence », « Micro coupé », « Quitter » sombres sur fond sombre. |
| `salle_eleve_320_x2_sansvideo.png` | Élève, 320, ×2 : rien ne déborde ; mot d'état des commandes absent ; bandeau à 4 px du bord gauche. |
| `salle_eleve_390_x2_avecvideo.png` | Élève, 390, ×2, avec image : étiquettes en bas à gauche, rien ne déborde. |
| `salle_eleve_390_x2_sansvideo_sombre.png`, autres `salle_eleve_*` | Variantes produites (journal : aucune exception). |
| `salle_tuteur_320_x2_sansvideo.png` | Tuteur observateur, 320, ×2 : trois tuiles correctes ; son rappel replié sur l'icône seule ; la mention « Cours enregistré… » reste (normal hors contrôleur). |

## Contrôleur, démonstration : CTRL-SALLE-1

| Fichier | Ce qu'il montre |
|---|---|
| `demo_ctrl_salle_320_x1.png` | Salle de démonstration du contrôleur : quatre tuiles (cercle et nom centré), aucune mention « visite de contrôle possible », rappel du contrôleur seul. |
| `demo_ctrl_salle_320_x2.png` | Même écran à ×2 (produit ; journal sans exception). |
| `demo_ctrl_deja_controlee_320_x1.png` | Carte de mission : « Un contrôle est déjà en cours dans cette classe. Un seul contrôle à la fois par classe… », pastille « En direct », avatar en petit cercle. |

## Salle de séance (`SalleSeance`) : ETATS-BTN-1, AVATAR-1, VIDEO-TUILE-1

| Fichier | Ce qu'il montre |
|---|---|
| `seance_ens_320_x1.png` | Dock : « Micro ouvert », « Caméra allumée » en disque plein, avec icône et mot ; vignette de l'enseignant sans image : cercle, nom centré, barres de signal en coin. |
| `seance_ens_320_x2.png` | ×2 : titre « Séan / ce … » coupé au milieu du mot avec points de suspension ; mots d'état et libellés d'outils absents (icônes seules) ; la vignette remplit la zone visible du support, « Ibrahim » coupé par le bas de la zone qui défile. |
| `seance_eleve_320_x2.png` | Élève ×2 : même titre coupé « Séan / ce … » ; dock : micro et caméra pleins, « Agrandir » en contour. |
| `seance_panneau_eleves_320_x1.png`, `_x2.png` | Panneau Élèves : avatar « M » en petit cercle, nom et état sur le même axe ; à ×2 les barres de signal touchent presque « Ibrahim » dans la vignette. |
| `seance_ens_390_x1_sombre.png` | Sombre, 390 : dock lisible, trois signaux (plein clair pour micro et caméra, contour pour Supports et Réseau), mots visibles. |
| `seance_ens_1440_x1.png`, `seance_eleve_320_x1.png` | Produits (journal sans exception), non décrits ici. |

## Ma journée de l'enseignant : CTA-FIN-1, ON-AIR-1, ANNUL-VIS-1

| Fichier | Ce qu'il montre |
|---|---|
| `journee_avant_320_x1.png` | « Prochaine séance » An-Nour, « Dans 1 h 30 », bouton « Préparer la séance ». |
| `journee_endirect_320_x1.png` | « Séance en direct », pastille « En direct » dans l'en-tête, seconde pastille « Séance en direct » au-dessus du bouton « Rejoindre la salle ». |
| `journee_endirect_320_x2.png` | ×2 : le titre d'écran se coupe « Aujourd'hu / i ». |
| `journee_cahier_320_x1.png` | « Dernière séance », rappel « Obligatoire : le cahier de transmission d'An-Nour… », bouton « Remplir le cahier de transmission » (deux lignes, centré). |
| `journee_depose_320_x1.png` | « Séance terminée », lien « Voir le cahier de transmission d'An-Nour → », aucun bouton plein. |
| `journee_annulee_320_x1.png` | Prochaine séance vide (« Aucune séance à venir »), « Rien de prévu aujourd'hui » ; « Alertes utiles » : carte enfoncée, pastille « Annulée » avec icône, horaire barré, « Motif non communiqué ». La carte ne nomme pas la classe et ne propose pas « Voir la Classe ». |
| `journee_annulee_320_x2.png` | ×2 : « Aujourd'hu / i » coupé ; la carte annulée est hors de la vue (défilement). |
| `journee_endirect_390_x1_sombre.png` | Sombre : pastilles et bouton lisibles. |
| `journee_*_320_x2.png` restants | Produits (journal sans exception). |

## Programmes de la direction : BUG-PROG-1

| Fichier | Ce qu'il montre |
|---|---|
| `programmes_avant_390.png`, `programmes_avant_1400.png` | Page vide, bouton « Créer une version ». |
| `programmes_feuille_390.png` | Après **une** frappe : feuille du bas « Créer une version vide », bouton « Enregistrer la version » ; un seul « Créer une version » à l'écran (journal : `NB creerVersion visibles : 1`). |
| `programmes_feuille_1400.png` | Bureau : boîte de dialogue « Créer une version vide », bouton « Enregistrer la version ». |

Les captures `docs/current/captures/l1-pastilles/*_apres_*` du dépôt (composant `PastilleEtatSeance` isolé, commit 192aae0, avant la relecture 2c7f431) ont aussi été ouvertes : pastille « En direct », carte annulée à heure barrée.

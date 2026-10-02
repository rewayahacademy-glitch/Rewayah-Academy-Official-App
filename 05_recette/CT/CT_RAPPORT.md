# CT-12 : recette de la vague Contrôleur

Dépôt : `C:\RA\controleur`, branche `ui/controleur-v1`. Recette faite en mode démonstration, sans serveur, sur la vraie route `/demo/controleur`. Les 32 scénarios viennent du document 08, §16.

Décisions du directeur appliquées : la visite se fait PENDANT le cours ; le rapport est transmis automatiquement ; pas de filigrane en V1 (décision S4 = b).

## Résultat en un coup d'œil

- Réussi : 30
- Attend BR-1 : 2 (scénarios 10 et 29)
- Attend le directeur : 0
- Échoue : 0

Un point de vigilance, hors des 32 scénarios : le sens de lecture de droite à gauche (RTL) est correct pour la mise en page, mais le texte français forcé en RTL mélange l'ordre des chiffres (voir « Ce qui reste », point 3).

## Les 32 scénarios

Les tests sont dans `test/features/controleur/` (« ctrl/ » ci-dessous) et `test/features/controleur_recette/` (« rec/ »). Les captures sont dans `build/captures`.

| N° | Scénario en mots simples | Résultat | Preuve |
|---|---|---|---|
| 1 | Un contrôleur externe ouvre son espace | Réussi | ctrl/espaces_controleur_test : « controleur externe : Controle seul, aucun selecteur » ; ctrl/controle_page_test : « en direct : on tape Commencer le controle… » |
| 2 | Un enseignant passe en Contrôle sans second compte | Réussi | ctrl/espaces_controleur_test : « Enseignant-Controleur : Controle actif, Enseignant propose… » |
| 3 | Un administrateur passe en Contrôle et n'a plus ses actions d'administrateur dans la salle | Réussi | ctrl/espaces_controleur_test : « Admin-Controleur : Admin et Controle, aucune action Admin en Controle » |
| 4 | Quelqu'un sans droit de contrôle ne voit pas l'espace | Réussi | ctrl/espaces_controleur_test : « le Compte d un tuteur ne propose pas Controle » ; « le tuteur, l eleve et le comptable n ont jamais Controle » |
| 5 | Le droit est retiré pendant la navigation : sortie en sécurité | Réussi | ctrl/espaces_controleur_test, groupe « Acces revoque pendant la navigation » (Historique, Échanges, adresse de démo) |
| 6 | Aucune mission : écran vide correct | Réussi | ctrl/controle_page_test : « aucune mission : le texte du doc, aucun bouton » ; captures ct2_controle_aucune_* |
| 7 | Mission proposée : le bon bouton | Réussi | ctrl/controle_page_test : « en direct : on tape Commencer le controle… » (bouton seulement quand c'est en direct) |
| 8 | Salle pas ouverte : aucune entrée anticipée | Réussi | ctrl/controle_page_test : « pas encore en direct : ligne calme, aucun bouton (R4) » ; « mission indisponible : le message generique seul » |
| 9 | En observation : ni micro, ni caméra, ni discussion | Réussi | ctrl/salle_controleur_test : « Commencer, observer sans commande interdite, puis Quitter » |
| 10 | Reconnexion : jamais de faux « en direct » | Attend BR-1 | L'état de reconnexion vient du vrai direct (LiveKit), absent de la démo. Aucun test factice. Le compte rendu relève bien le nombre de reconnexions (ctrl/compte_rendu_controleur_test). |
| 11 | Quitter mène au compte rendu | Réussi | ctrl/salle_controleur_test (même test, fin) ; ctrl/compte_rendu_controleur_test : « Quitter puis Plus tard : les faits de la visite sont partis » |
| 12 | « Rien à signaler » envoie le rapport | Réussi | ctrl/compte_rendu_controleur_test : « Rien a signaler, puis Envoyer le compte rendu : resultat » |
| 13 | Une observation structurée envoie le rapport | Réussi | ctrl/observation_controleur_test : « Parcours complet : cinq etapes, envoi, resultat » |
| 14 | Remarque ciblée sur l'enseignant | Réussi | ctrl/observation_controleur_test : « Point important : texte obligatoire, sans nature choisie » (cible « L'enseignant ») |
| 15 | Remarque ciblée sur un élève, avec l'identité minimale (prénom seul) | Réussi | ctrl/observation_controleur_test : « Parcours complet… » (liste de prénoms, sans recherche) ; ctrl/frontiere_donnees_controleur_test : « aucun eleve de la demonstration controleur n a de nom de famille » |
| 16 | Le canal avec l'administration garde le contexte de la mission | Réussi | ctrl/echanges_controleur_test : « resultat du compte rendu : Ecrire a l administration ouvre le fil de la mission » ; ctrl/historique_controleur_test : « Historique -> rapport -> detail -> fil de la mission » |
| 17 | Un rapport envoyé ne peut plus être modifié | Réussi | ctrl/historique_controleur_test : « Historique -> rapport -> detail… » (aucun champ de saisie) ; « CTR-03B : le rapport parent reste intact » |
| 18 | Un complément peut être ajouté | Réussi | ctrl/historique_controleur_test : « CTR-03B : complement envoye, visible dans le detail » ; captures ct8_complement_* |
| 19 | L'historique filtre correctement | Réussi | ctrl/historique_controleur_test : « le filtre Etat ne garde que les rapports choisis » |
| 20 | Mobile 390 px | Réussi | Captures ct1b à ct9, suffixe `_390_` ; ctrl/compte_rendu_controleur_test : « empiles pleine largeur sur mobile » |
| 21 | Tablette 768 px | Réussi | Captures ct1b à ct9, suffixe `_768_` |
| 22 | Ordinateur 1440 px | Réussi | Captures ct1b à ct9, suffixe `_1440_` ; ctrl/compte_rendu_controleur_test : « cote a cote sur ordinateur » ; ctrl/controle_page_test : « aucun debordement a 800x600 » |
| 23 | Thème clair | Réussi | Toutes les captures `_light` |
| 24 | Thème sombre | Réussi | Toutes les captures `_dark` |
| 25 | Texte à 200 % | Réussi | rec/recette_ct12_test : groupe « Scenario 25 » (Contrôle : rien ne déborde, bouton atteignable en faisant défiler ; Détail de l'Historique : rien ne déborde) ; captures ct12_texte200_controle_390 et ct12_texte200_historique_detail_390 |
| 26 | Clavier complet | Réussi | rec/recette_ct12_test : « Tab atteint chaque choix et le bouton, Entree choisit » (compte rendu : Tab, Maj+Tab, Entrée, jusqu'à l'envoi). Le clavier sur les autres écrans n'est pas parcouru dans ce test (voir « Ce qui reste », point 2). |
| 27 | Lecteur d'écran | Réussi (étiquettes) | rec/recette_ct12_test : « Commencer, choix du compte rendu : etiquette et role » ; ctrl/frontiere_donnees_controleur_test lit aussi les étiquettes. Un essai avec un vrai lecteur reste à faire (point 1). |
| 28 | Écriture de droite à gauche (structure) | Réussi | rec/recette_ct12_test : groupe « Scenario 28 » (barre de navigation retournée, aucun débordement) ; captures ct12_rtl_controle_390 et ct12_rtl_historique_detail_390 |
| 29 | Hors ligne | Attend BR-1 | Quand l'envoi ne part pas, l'écran le dit honnêtement et garde la saisie (prouvé : « Sans serveur, l envoi echoue… » dans compte rendu, observation, échanges, complément). Mais aucun bandeau « hors ligne » n'est branché dans l'espace Contrôleur : il dépend de la vraie connexion. |
| 30 | Accès refusé | Réussi | ctrl/espaces_controleur_test : « un enseignant sans Controle : refus generique, aucun contenu » ; « la garde reelle refuse une session enseignant » |
| 31 | Aucun contenu privé dans les captures de contrôle qualité | Réussi | ctrl/frontiere_donnees_controleur_test : groupe « C8 : aucune donnee interdite sur les ecrans de demonstration » (chaque écran, 3 largeurs) et « le filtre detecte ce qu il doit refuser ». Pas de filigrane en V1 (S4 = b). |
| 32 | Aucune donnée de démonstration en production | Réussi | ctrl/frontiere_donnees_controleur_test : « Recette 32 » : « la porte ferme chaque adresse de demonstration en production » ; « les fournisseurs reels sont neutres par defaut » |

## Ce que j'ai vu sur les captures 200 % et RTL (390 px)

- 200 % Contrôle en direct : la carte de mission passe sur plusieurs lignes, rien n'est coupé. Le bouton « Commencer le contrôle » se trouve sous la barre du bas et s'atteint en faisant défiler. Les mots de la barre du bas (Historique, Échanges) se touchent presque, mais restent lisibles.
- 200 % Détail de l'Historique : le titre prend quatre lignes à côté de la flèche de retour, la page défile, rien ne déborde.
- RTL Contrôle : titre, carte, avatar et icône d'information passent à droite. La barre du bas est inversée (Compte à gauche, Contrôle à droite). Les flèches de retour pointent du bon côté.
- RTL Détail de l'Historique : libellés à droite, valeurs à gauche, flèche de retour à droite. L'ordre des chiffres et des petits mots est mélangé (voir point 3), parce que le texte reste en français.

## Ce qui reste

1. Lecteur d'écran réel (scénario 27) : tester avec TalkBack sur le téléphone du directeur. Les tests ne prouvent que les étiquettes et le rôle des boutons.
2. Clavier (scénario 26) : le parcours clavier est prouvé sur le compte rendu. Les autres écrans (Contrôle, Historique, Échanges, complément) restent à parcourir à la main sur ordinateur.
3. Défaut à confier à la revue CT-R (RTL, `build/captures/ct12_rtl_historique_detail_390.png`) : avec un texte français forcé en RTL, les valeurs mêlant chiffres et mots s'affichent dans le désordre : « min observées 18 » (au lieu de « 18 min observées »), « sur 4 4 », « à 17:45 17:00 », « min de retard 8 ,17:08 », et un point en début de phrase sur la carte de mission. Les lignes concernées sont les valeurs de la carte « Faits automatiques » et de « Mission » du Détail, et la ligne d'horaires de la carte de mission du Contrôle. Exemple repéré : `lib/features/controleur/historique_controleur_page.dart:368` (durée observée, texte assemblé par `h.duree(minutes: …)`) ; les autres valeurs viennent de `compte_rendu_controle_page.dart` (carte des faits, autour de la ligne 584). Aucune correction faite. Ce n'est probablement pas un défaut en arabe réel, mais à vérifier quand les textes arabes arrivent (LG-1) : mieux vaut isoler les nombres et horaires dans le texte (marques de direction) avant ce moment.
4. Scénario 10 (reconnexion) et scénario 29 (hors ligne, bandeau) : à brancher puis recetter à BR-1.
5. Pas de défaut trouvé dans le code de l'app sur les autres points. Aucune correction faite.

## Les chiffres

- `dart analyze --fatal-infos lib test tool` : aucun problème (0).
- Tests de la recette CT-12 : 6 verts (4 captures sautées sans CAPTURE_DIR, 4 images produites avec).
- Suite complète (`flutter test`, sans CAPTURE_DIR) : 3508 réussis, 0 échec, 1571 sautés (les captures et tests réservés). Journal : `build/suite_ct12.log` dans le dépôt contrôleur.

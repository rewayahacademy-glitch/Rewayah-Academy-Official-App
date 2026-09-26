# Maquettes Admin fournies par le directeur (26/09/2026)

Le directeur a fourni ces maquettes le 26/09/2026. Elles font foi pour la mise en page. Le directeur aime ce layout.

On ne redessine rien, on applique la méthode tuteur : relever ce que montre l'image, puis corriger ses erreurs par écrit.

**Ordre de priorité** : règles gelées (DESIGN-GOV) > textes exacts de la spec 03 V1.2 > libellés réels du code (AD-1) > image.

## Les 6 images de l'étape AD-3 (complètes)

| Fichier | Écran |
|---|---|
| `IMG-ADM-02A_desktop_sombre.png` | 02A, file des dossiers, en maître-détail avec la revue 02B à droite |
| `IMG-ADM-02C_desktop_sombre.png` | 02C, visionneuse de pièce (modale) |
| `IMG-ADM-02D_desktop_sombre.png` | 02D, motif du refus (modale) |
| `IMG-ADM-02A-02B-02E_mobile.png` | 02A mobile clair, 02B mobile sombre, 02E confirmation de validation, mobile clair |

## Coque admin (`coque/`)

- `ADMIN-SHELL-01` : Accueil (vue d'ensemble).
- `ADMIN-SHELL-02` : liste-détail des opérations.
- `ADMIN-SHELL-03` : collection et inspecteur.

**Pour ce lot**, seule la coque visible sur 02A est mise en place :
- barre latérale de 288, avec « Rewayah » en tête et le pied « Admin · Administration » ;
- élément actif sur fond discret ;
- en-tête de page : titre, sous-titre, bouton thème et bouton profil à droite ;
- tiroir sur mobile, jamais de barre basse (spec l.1520).

**Entrées de la barre latérale**, celles de 02A : Accueil, Opérations, Personnes, Pédagogie, Finance, Configuration, Sécurité et audit.
- Elles pointent vers les routes existantes.
- Aucune page nouvelle n'est créée derrière.
- Tout écart avec le code existant (entrée absente, autre libellé) est noté dans le relevé et soumis au directeur. On n'invente rien.

**On ne construit pas le contenu des images SHELL** : ni le tableau d'accueil, ni l'espace de traitement, ni la collection pédagogie. Ce sont des références pour la suite du rôle admin (étape AD-X, plus tard).

## Explorations (`exploration/`) : non retenues

**Une seule exception** : la fenêtre « ADM-02.4 · Paramètre Super Admin » (EXPLO-2, en bas à droite). Elle sert de référence de disposition pour AD-9, le réglage de genre. Les textes restent ceux de la spec (§15, l.1197).

**Tout le reste est exclu** :
- les onglets Familles / Enseignants ;
- la recherche et les filtres ;
- les onglets Documents / Historique ;
- le téléchargement de la pièce ;
- les boutons radio Conforme / Non conforme ;
- la barre basse mobile.

**Interdit** : les photos de personnes et les fausses cartes d'identité réalistes (« République française »).

## Rectifications relevées (à appliquer, sans redessiner)

1. **02A, bureau** : les dates de la file passent à la ligne (« 25 sept. / 2026 »). Elles doivent tenir sur une ligne. Si la largeur de 336 manque, la pastille d'état passe sous le nom.
2. **02A et 02B** :
   - le titre « Dossier de Aïcha Benali » doit faire l'élision : « Dossier d'Aïcha Benali » ;
   - la règle d'élision vaut pour tout prénom commençant par une voyelle ;
   - sinon, reprendre le texte exact de la spec.
3. **Vérifications 1, 2, 3** : les barres grises sont volontaires. Elles sont remplacées par les 3 libellés réels relevés en AD-1. Aucun libellé inventé (les libellés des explorations ne comptent pas).
4. **02B, mobile** :
   - le bouton « Refuser le dossier » est coupé au bord gauche. Les deux boutons doivent être entiers, dans la marge de 16 ;
   - « Valider le dossier » se place au bord de fin (trailing) ;
   - si la largeur manque, les deux boutons passent sur deux lignes, sans pleine largeur sur ordinateur (contrat B).
5. **02C** :
   - la pièce de démonstration porte la mention visible « Document fictif » ;
   - la croix et « Fermer » ramènent toutes deux le focus sur « Voir la pièce » (spec l.1030) ;
   - Échap ferme la fenêtre.
6. **02D** :
   - le texte d'aide répète le texte indicatif du champ ;
   - le texte indicatif ne doit porter aucune information obligatoire ; garder l'aide sous le champ ;
   - erreur si le champ est vide : « Indiquez le motif du refus. » (spec l.1056).
7. **02E** : le titre est « Valider ce dossier ? » (spec l.1106). Le texte explicatif est celui de la spec, pas celui de l'image s'ils diffèrent.
8. **Tous les écrans** : les données visibles sont synthétiques, avec la mention « Démonstration ». Aucune vraie identité.
9. **Tous les écrans** : les états absents des images (chargement, vide, erreur, résultat inconnu…) suivent la spec et les composants partagés. Pas de nouvelle image.

L'étape AD-3R complète cette liste après AD-1. La confrontation se fait avec les libellés réels et les textes de la spec, sans aucun redessin.

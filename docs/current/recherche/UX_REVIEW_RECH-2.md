# UX_REVIEW RECH-2 : l'écran de recherche, tous formats

Lot RECH-2 (voie RECH), branche `claude/recherche`. Écran : `lib/features/recherche/ecran/`,
route unique `/recherche`. Données : port de démonstration (milliers d'éléments par domaine),
**aucun serveur** : `testé localement` seulement, jamais `testé sur staging`.
Captures : `docs/current/captures/RECH-2/` (19 PNG, vrai routeur, vraies polices, vrai thème,
générées par `test/capture/rech2_capture_test.dart` avec `CAPTURE_DIR`).

## 1. Règles appliquées (règle, source, conclusion, modification)

| Règle | Source | Conclusion | Modification |
| :--- | :--- | :--- | :--- |
| Une seule surface de recherche, aucun onglet « Recherche » | spec RECH-03 §4.1, §9 | Une route commune `/recherche` ; l'espace se lit dans la session (jamais le rôle dans l'écran : l'écran lit les domaines servis par le port) | Route dans le routeur unique, redirection « espace commun » |
| Rien ne part sans saisie ; 3 caractères ; 160 caractères, 8 termes | §5, §6.2 | Appliqué avant tout appel, testé | `RequeteNormalisee`, délai de saisie 250 ms, Entrée immédiate |
| Une phase, un texte ; jamais « Aucun résultat » pour une panne | §0.2, §5 | Douze phases, chacune son texte ; vide = `ok` et aucun élément dans chaque domaine | `PhaseRecherche`, `phaseDesDomaines` |
| Retours partiels ; un domaine lent n'attend personne | §6.1, §8.3 | Le domaine en panne montre son bloc et « Réessayer ce domaine » ; les autres restent | `EtatDomaine`, `reessayerDomaine` |
| Cartes groupées : un seul rectangle à filets internes (K-55) | `lib/CLAUDE.md`, §11 | `CarteLignes` + `SettingRow`, aucun composant parallèle | — |
| Filtres : une seule `RangeeFiltres` qui défile (FILTRES-1) | `lib/CLAUDE.md` | Puces servies par le port (jamais codées), absentes en Interface guidée et dans une recherche contextuelle | `porteesRechercheProvider` |
| Un bouton qui ne peut pas aboutir n'est pas rendu (K-56) | `lib/CLAUDE.md` | Un résultat sans route réelle n'a ni geste ni chevron ; aucun bouton plein sur l'écran (`verifierUnSeulBoutonPlein`) | `cheminPourCible` |
| Colonnes seulement si la place le permet ; jamais écrasées à texte ×2 | §4.3, §4.4 | Deux colonnes dès 560 px de contenu et texte < ×1,5 (`AppGabarit.choixEnColonnes`), une sinon | `_Sections` |
| Interface guidée : « Trouver un support », un domaine, pas de filtre, ni finance ni annuaire | §4.5 | Domaine borné aux supports ; tutoiement ; mention « Seulement tes supports et tes leçons. » | `domaineCible` forcé par la page |
| Hors ligne se dit une fois (K-42) | décision du 04/10 | Le bandeau de page dit le réseau ; le bloc dit « La recherche en ligne est indisponible. » | écart voulu avec le texte §5 |
| WCAG 2.2 : 2.5.8 cibles, 1.4.4 texte ×2, 1.4.10 reflow à 320, 2.4.7 focus, 4.1.3 messages d'état | W3C | Lignes de 48 au moins ; zéro mot coupé à 320 ×2 (testé) ; focus visible ; `liveRegion` sur le seul message d'état, jamais par frappe | — |

## 2. Comparaison aux sept maquettes (captures Flutter réelles)

| Maquette | Capture | Écarts écrits |
| :--- | :--- | :--- |
| IMG-RECH-01-M famille 390 | `rech2_famille_390_clair` | (1) Titre de page « Rechercher » + contexte « Dans votre espace Tuteur » (texte §5) au lieu de « Recherche » et du fil « Retour à l'accueil ». (2) Puces « Tout / Classes / Supports » reprises. (3) Pas de pastille de couleur ni de lettre (« C », « L ») : icône de type du jeu Phosphor, aucune teinte nouvelle (K-37). (4) « Voir tout » devient « Voir davantage » (curseur, aucun total, §5). (5) Pied de page « limités aux éléments autorisés dans votre foyer » devient une phrase générique, sans nommer le foyer. (6) Barre basse Accueil · Foyer · Historique · Compte : conservée, c'est celle du code. |
| IMG-RECH-02-M guidée 390 | `rech2_guidee_390_clair` | (1) « Trouver un support » en titre, un seul domaine, pas de puces « Tous / Coran / Mes leçons » : le filtre par type n'existe pas au contrat. (2) Pas de bloc « Besoin d'aide ? / Écouter l'aide » : aucun composant d'aide audio n'est relié à cet écran ; non inventé. (3) Pas de bouton « Retour à ma classe » en pied : le retour est le disque de la page (un seul geste, K-56). (4) Barre guidée du code (Accueil · Ma classe · Coran · Mon espace). |
| IMG-RECH-03-D enseignant sombre 1440 | `rech2_enseignant_1440_sombre` | (1) La navigation vient de la coque réelle (Aujourd'hui, Classes, Disponibilités, Profil), pas de la maquette (Mes classes, Bibliothèque, Messages). (2) Pas d'encart « Confidentialité » : une phrase de portée sous les résultats (aucune liste de ce qui est exclu : ne pas trahir l'existence d'objets invisibles, §3). (3) Les supports ne s'ouvrent pas depuis la recherche de l'enseignant : le routeur n'ouvre pas `/tc/bibliotheque` à son rôle (il passe par le dock de la salle) ; les lignes sont lisibles et sans geste. |
| IMG-RECH-04-D admin clair 1440 | `rech2_admin_1440_clair` | (1) Le bloc « Actions disponibles » n'existe pas : une navigation de fonctions est une autre fonction (§1, intention 3), à coder avec des routes vérifiées, hors de cette fiche. (2) La puce « Période » et « Personnes » attendent leurs domaines (D2, D3). (3) La coque admin porte déjà sa loupe d'en-tête : branchement à RECH-D5. |
| IMG-RECH-05-D comptable 1440 | non faite | Domaine Finance = RECH-D4 (attend CPT-COM et COM-FUS). Aucune table financière n'est simulée ici. |
| IMG-RECH-06-M états | `rech2_etat_*` (9 captures) | La planche montre six états ; l'écran en rend douze : ajouts « Saisissez au moins 3 caractères », « session expirée », « recherche indisponible pour le moment », « chargement de page suivante », « page en échec », « domaine en panne parmi des résultats ». « Accès retiré » (ouverture) appartient à l'écran propriétaire de l'objet (réautorisation à l'ouverture), pas à la liste. |
| IMG-RECH-07-T tablette Classe | non faite | Fichiers de la salle (`salle`, `tc_classe_live`, `tc_dock`) réservés ; le panneau de recherche contextuelle de la Classe est dans RECH-D1, sa pose dans la salle attend une fiche qui nomme ces fichiers. Le rectangle « Support coranique » n'est pas reproduit (rendu du Coran interdit). |

## 3. Mesures et preuves

- 5 formats (320 ×2, 390, 768, 1024, 1440) × 3 espaces (famille, enseignant, administration) :
  aucun débordement, aucun mot coupé, un seul bouton plein (`test/features/recherche/recherche_formats_test.dart`).
- Arabe et RTL à 320 ×2, 390 et 1440 ; colonnes inversées à 1440 ; texte ×2 : une colonne.
- Interface guidée : 390 et 320 ×2.
- Clavier : Entrée lance sans attendre ; « Modifier la recherche » rend le focus au champ.
- Clair et sombre : captures 390 clair/sombre, 1440 clair/sombre.
- Réserve : les 19 captures sont celles du build Flutter en test (polices réelles) ; pas de capture sur appareil ni sur
  navigateur réel. La mesure de performance perçue (p95 ≤ 1 s) n'est pas faite : il n'y a pas de serveur.

## 4. Restes

1. Lecteur d'écran réel (TalkBack, VoiceOver) non essayé : seules la sémantique et une région d'état sont posées.
2. Aide audio de l'Interface guidée : à relier quand un composant d'aide existera pour cet écran.
3. Surlignage du terme trouvé : non fait ; si ajouté, segmenter le texte, jamais d'HTML (SEC-R11).
4. Le jeu de polices ne dessine pas les lettres savantes « ḥ » et « ṣ » (case vide constatée à la première capture) :
   les noms de démonstration sont donc écrits sans diacritiques ; à signaler avant de servir de vrais titres translittérés.

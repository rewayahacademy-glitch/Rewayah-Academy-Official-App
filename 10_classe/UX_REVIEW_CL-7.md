# UX_REVIEW_CL-7 : écrans de secours de la salle de classe

Date : 26/09/2026. Lot : CL-7 (P05, P06, P09, P10, P11, P12). Preuve exigée par `DESIGN-GOV-2026-09-26` §4.2, appliquée sans assouplissement.
Aucune maquette du directeur pour ce lot ; feu vert pour construire avec les gabarits et composants existants (§4 bis.3). Détail des états, textes et tâches : `07_SECOURS.md`.
Référentiels exclus : GOV.UK Design System (décision du directeur, §4.1). La mention « GOV.UK langage simple » de la spec CLV-09 n'est donc pas utilisée comme justification ici.

## 0. Sources et dates de consultation

| Réf. | Source | Consultation |
|---|---|---|
| W1 | WCAG 2.2, critère 4.1.3 « Status Messages » (w3.org/WAI/WCAG22/Understanding/status-messages) : « Status messages can be programmatically determined … without receiving focus. » | lue en ligne le 26/09/2026 |
| W2 | WCAG 2.2 : 1.4.1 Utilisation de la couleur, 2.4.3 Parcours du focus, 2.4.11 Focus non masqué (minimum), 2.5.8 Taille de cible (minimum), 3.2.2 Changement au moment de la saisie, 3.3.1 Identification des erreurs | texte normatif connu ; non rechargé dans cette session |
| M3 | Material Design 3 : bannières (message persistant tant que la condition dure), snackbars (bref, non critique), bottom sheets, dialogues | page m3.material.io injoignable par l'outil le 26/09/2026 (« socket hang up ») ; règles connues, à relire en recette T-S6 |
| AH | Apple HIG, Privacy (demander l'accès au moment où il sert ; en cas de refus, expliquer et orienter vers Réglages sans insister) | page non lisible par l'outil le 26/09/2026 ; règle connue, à relire en recette T-S6 |
| FL | Flutter, « Adaptive and responsive design » et « Accessibility » (`Semantics.liveRegion`, focus, `SemanticsService.announce`) | règles connues ; non rechargé |
| EN | EN 301 549 V3.2.1 (2021-03), chapitre 9 = WCAG 2.1 AA ; aucune « version 2026 » supposée | édition connue ; portée : web et application |
| NI | Nielsen, heuristiques 1 (visibilité de l'état), 3 (contrôle et liberté), 5 (prévention des erreurs), 9 (diagnostiquer et récupérer) | référence stable |
| LO | Fitts (cible 48 / 72 dp), Hick (deux choix au plus en secours), proximité Gestalt (§4 bis.1 : objet → CTA 16 dp) | référence stable |

Réserve honnête : seules W1 a été relue en ligne pendant cette session (délai < 35 min, deux sites injoignables par l'outil). La recette T-S6 relit M3 et AH et met à jour la colonne « Consultation » ; si une règle diffère, la ligne concernée passe à « ajustée ».

## 1. Propositions contrôlées

| # | État (parcours) | Disposition proposée | Règle utile (source) | Conclusion | Modification / conséquence concrète |
|---|---|---|---|---|---|
| U1 | Reconnexion en cours (P05) | Bandeau non modal pleine largeur sous `ChromeSeance`, au-dessus du support ; le support reste affiché ; Micro et Caméra rendus mais désactivés. Aucun déplacement du focus. | W1 : message d'état annoncé sans focus → `Semantics(liveRegion: true)`. M3 bannière : persiste tant que la condition dure. NI-1. Contrat E : état `disabled` défini. | ajustée | La spec parle de « bandeau » ; on retient un bandeau (pas un snackbar) car l'état dure. Les commandes de publication sont **désactivées** (pas masquées) pour éviter un saut de mise en page ; le libellé d'accessibilité dit pourquoi (PROPOSITION de texte). |
| U2 | Connexion rétablie (P05.6) | `LocalFeedback` bref posé sous le bandeau qui disparaît, sans action. | W1 ; M3 snackbar : bref, non critique ; spec « sans toast permanent ». Contrat E : durées existantes de `LocalFeedback`, aucune minuterie locale. | conforme | Aucun `SnackBar` Material ajouté : le composant maison couvre le besoin (réduction de mouvement = fondu seul). |
| U3 | Reconnexion impossible, hors ligne confirmé (P05.8) | `EtatSysteme(portee: bloc)` à la place du bandeau, entre en-tête et support ; action `Réessayer` au bord trailing, `Quitter la séance` au leading ; la salle reste montée. | NI-3, NI-9 ; Hick : deux choix ; §4 bis.2 : poursuite trailing, sortie leading, 16 dp sous l'objet ; W2 3.3.1. | ajustée | Pas d'écran plein ni de dialogue : la spec dit « Page de salle conservée ». `Quitter la séance` repasse par la confirmation existante (`Quitter la séance ?` / cahier pour l'enseignant) : aucune sortie sans confirmation (NI-5). |
| U4 | Réseau faible (P06) | Même bandeau que U1, ton avertissement, pastille « En ligne » inchangée ; commandes actives. | W2 1.4.1 : texte + icône, jamais la couleur seule ; spec P06.5 : aucun faux « hors ligne ». | conforme | La pastille d'état n'est pas remplacée par « Hors ligne » tant que la room est connectée. |
| U5 | Micro bloqué (P09) | Feuille `AppBottomSheet` (feuille du bas < 600, dialogue centré au-delà) ouverte **au geste Micro** ; texte + `Continuer sans micro` (secondaire, leading) + `Ouvrir les réglages` (principal, trailing) **seulement si la plateforme le permet**. Fermeture → focus rendu au bouton Micro. | AH : demande contextuelle, orientation vers Réglages ; W2 2.4.3 (retour du focus) ; M3 : feuille modale pour une décision courte ; §4 bis.2 : un seul CTA dominant. | ajustée | Sans paquet de permission (pubspec interdit, `permission_handler` non retenu C05 §6), `onOuvrirReglages` reste `null` → bouton non rendu ; `Continuer sans micro` devient la seule action. Le bouton Micro reste « coupé » : aucun état « micro actif » simulé (P09.6). |
| U6 | Caméra interdite (P10) | Élève standard : pas de bouton Caméra (déjà fait) ; `StatusPill` ton neutre, non interactive, « Caméra désactivée pour ce profil. » posée dans la barre basse (à la place du bouton, 768/1440) ou au-dessus du dock, alignée start, 8 dp (390). Guidée : rien. | Spec P10.3 « statut non interactif … pas dans le contenu principal » ; W2 : pas de contrôle factice ; Nielsen 1. | ajustée (Q-S1) | La spec parle de « détails média », que ni la matrice ni les maquettes du directeur ne montrent : la barre basse est retenue comme zone média. Choix soumis au directeur (Q-S1 dans `07_SECOURS.md`). |
| U7 | Séance prolongée (P11) | Texte simple dans la ligne d'état (déjà fait pour ES et EN), jamais bandeau vert ; guidée : rien (matrice). Minuteur jamais négatif. | Matrice + DV D4 ; NI-1 ; minimalisme. | conforme | Aucun changement visuel ; ajout de situations démo et d'un test « minutes ≥ 0 ». |
| U8 | Salle terminée (P12) | `ResultatSeance` (élève, guidée) et `FinSeanceEnseignant` existants ; focus initial sur le titre. | NI-1 ; W2 2.4.3 ; §4 bis.2 : résultat, 16 dp, CTA trailing. | conforme (existant) | Aucun changement ; écart d'anatomie éventuel consigné pour HU-1, pas corrigé ici (§4 bis.8). |
| U9 | Accès retiré (P12) | Nouvelle issue de `ResultatSeance` (`accesRetire`) : titre « Votre accès à cette séance a pris fin. », CTA `Retour à la Classe` ; guidée : écran de fin guidé existant. Aucune tentative de reconnexion. | NI-9 ; spec P12.5 ; W2 3.3.1. | conforme | Pas de nouveau composant : une valeur d'énumération de plus et ses textes. |
| U10 | Mobile 390 / tablette 768 / desktop 1440 | Bandeaux pleine largeur de la colonne salle, gouttière 16 / 16 / 32 (valeurs du gabarit existant) ; bloc U3 borné par `EtatSysteme` ; feuille U5 = feuille du bas < 600, dialogue ≥ 600. | Contrat D : pas d'étirement mécanique, largeur bornée par le composant ; FL adaptive. | conforme | Aucune largeur ad hoc. Zoom 200 % : bandeau sur plusieurs lignes, jamais tronqué (W2 1.4.4 / 1.4.10). |
| U11 | Mouvement | Apparition/disparition des bandeaux avec `AppMouvement.apparition` (180 ms) et courbes existantes ; réduction de mouvement = 0. | Contrat E. | conforme | Aucune durée locale. |

## 2. Dérogations

Aucune dérogation aux contrats A à E. Une tension documentée : la règle de `lib/CLAUDE.md` « un bouton qui ne peut pas aboutir n'est pas rendu » est respectée pour les actions **impossibles** (Ouvrir les réglages, caméra interdite) ; pour une indisponibilité **temporaire** (reconnexion), l'état `disabled` du contrat E est employé, comme l'exige la spec CLV-04 (« Commandes de publication désactivées jusqu'à reprise »).

## 3. Limites (§4.3)

Rien ici ne change une permission, un état serveur ni la présence : détection réelle de la qualité, échec durable, révocation, permission OS et publication vidéo restent côté serveur et SDK (BR-1).

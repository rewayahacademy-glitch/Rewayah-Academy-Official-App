# UX_REVIEW_ONBOARDING : revue UX de l'onboarding (admission, lot B, 29/10/2026)

- **Cadre** : DESIGN-GOV-2026-09-26 §4.2 ; fiche `docs/current/FICHE-ONBOARDING-2026-10-29.md` (validée le 29/10 par le pilote, sur délégation du directeur).
- **Sources** : Material Design 3 (chips, boutons, progression), Apple Human Interface Guidelines (Onboarding), Baymard Institute (formulaires sur mobile, création de compte), WCAG 2.2 AA, Nielsen. **Non reconsultées en ligne le 29/10** (session sans navigation web) : les règles citées sont celles connues et déjà relevées dans les revues précédentes du dépôt. GOV.UK exclu.
- **Limite §4.3** : aucune ligne ne change une permission, un état serveur ni l'effet de la décision de la direction. La famille attend toujours cette décision (Q1).
- **Composants** : `PageEtape`, `ActionPrincipale`, `ChoiceCardGroup`, `FilterPill`, `GroupeReglages` ; aucun composant nouveau, aucune couleur ni valeur d'espacement nouvelle.

| Proposition | Source | Règle utile | Conclusion | Modification | Écart |
|---|---|---|---|---|---|
| Une question par écran, « n sur N » en tête | Baymard (formulaires longs sur mobile) ; NN/g (progression visible) | Découper, montrer où l'on en est | Conforme | `PageEtape` : rangée d'étape, barre continue, « n sur N » calculé des réponses | Avant « Pour qui », N vaut celui de « pour moi » (5) : le total réel ne se connaît qu'après |
| Compte en dernier : les questions avant l'adresse | Baymard (création de compte tardive) ; Apple HIG (Onboarding : ne demander que ce qui sert) | Faire voir la valeur avant de demander un compte | Conforme | `/commencer` public ; « Créer un compte » y mène tant qu'il n'est pas répondu ; la langue du cours aussi, lue sans compte (`langues_cours_publiques`) | Aucun |
| Un seul bouton plein « Continuer », en bas ; liens discrets | Material 3 (une action principale) ; contrat K-56 | Une action pleine par écran | Conforme | « J'ai déjà un compte », « J'ai un code d'invitation » en boutons tertiaires ; `verifierUnSeulBoutonPlein` dans le test | Aucun |
| Âge en puces (5 à 17 ans, « 18 ans ou plus ») | Material 3 (chips de choix) ; Fitts ; Hick | Choix court et visible d'un geste, cibles de 48 | Ajustée | `FilterPill` dans un `Wrap` déclaré « choix de formulaire, pas un filtre » | 5 ans au lieu de 4 (première cohorte du serveur) |
| « 18 ans ou plus » dit la suite au lieu de bloquer en silence | Nielsen n°9 ; K-59 | Dire ce qui ne va pas et quoi faire | Conforme | Phrase annoncée (`liveRegion`) : s'inscrire soi-même avec « Je m'inscris pour moi » ; « Continuer » reste sans action | Aucun |
| Genre, « le parent aussi » : deux choix en ligne, sans illustration | Material 3 (segmented, chips) ; fiche §2 (« sans gros rectangles ») | Choix binaire court, compact | Conforme | `ChoiceCardGroup(enLigne: true)` | Aucun |
| Niveau et objectif en liste de cartes | Fiche §2 ; K-58 | Une réponse qui demande d'être lue | Conforme | Mêmes libellés et même phrase de raison que le parcours existant | Pas d'exemple par niveau (aucun texte décidé) |
| Moments, plusieurs réponses | Material 3 (filter chips) | Choix multiple dit comme tel | Conforme | `ChoiceCardGroup(selectionMultiple)`, « Plusieurs réponses possibles » | Aucun |
| Récapitulatif avant l'envoi, chaque ligne avec « Modifier » | Baymard (relecture avant soumission) ; Nielsen n°3 | Contrôle et retour arrière | Conforme | `GroupeReglages`, « Ajouter un autre profil élève », « Envoyer ma demande » | Modifier un enfant repasse par ses quatre écrans, puis revient |
| Réponses gardées si le lien s'ouvre dans un autre onglet | Baymard (ne jamais perdre une saisie) | Pas de ressaisie | Conforme | `localStorage` sur le web, effacé à l'envoi | Sur un autre appareil, la famille reprend les questions (dit au récapitulatif) |
| Ordinateur, deux volets et lettres A, B, C au clavier (fiche §2) | Fiche §2 ; WCAG 2.1.1 | Tout au clavier | Non fait | La colonne de `PageEtape` reste centrée ; le clavier passe par Tab et Entrée | À faire, lot suivant |

## UX-046 (ONBOARDING-FIN, pilote, 02/11/2026)

- **Cadre** : constat UX-046 du directeur (01/11, aucun changement de style visible), ordre du pilote du 02/11 ; UX-047 (page des accords) est livré à part, PR 148, fiche du 29/10 §2, `DECISION-QUATRE-AGENTS-2026-11-02.md`.
- **Sources** : Material 3 (chips de choix, une action principale, fenêtre « expanded » dès 840), Apple HIG (Onboarding), Baymard (une question par écran, erreurs à côté du champ), WCAG 2.2 AA (2.1.1 clavier), Nielsen n°9. **Non reconsultées en ligne le 02/11** : les règles citées sont celles déjà relevées dans les revues du dépôt.
- **Limite §4.3** : aucune ligne ne change une permission, un état serveur ni une règle de consentement.
- **Composants** : `CoquilleEntree` (nouveau mode `volet`), `ChoiceCardGroup` (nouveau mode `lettres`, dont la marque `LettreChoix`), `FilterPill` (sa place `apercu`, existante), `RangeeEtape`, `ActionPrincipale(affirmee)`, `ChampEntree`, `LienEntree`. Aucun composant nouveau hors ces modes ; aucune couleur ni valeur d'espacement nouvelle.

| Proposition | Source | Règle utile | Conclusion | Modification | Écart |
|---|---|---|---|---|---|
| Même habillage que la connexion | Fiche §2 (« comme la connexion ») ; décisions du 25/10 sur l'entrée | Un parcours d'entrée, un habillage | Conforme | `CoquilleEntree(volet:)` : sur ordinateur, la marque au début de ligne porte l'étape et la question, le parchemin porte les réponses ; sur téléphone, une page sur la marque, logo en haut | La porte de la connexion n'est pas reprise dans le questionnaire : la question prend sa place |
| Deux volets dès 840, question au début de ligne | Fiche §2 ; Material 3 (expanded) | Lire la question pendant qu'on répond | Conforme | Le seuil est celui de la connexion (`AppGabarit.seuilEtendu`, en largeur utile) | Aucun |
| Lettres A, B, C au clavier | Fiche §2 ; WCAG 2.1.1 | Choisir sans souris | Conforme | La lettre est dessinée devant chaque réponse (ordinateur seulement), une phrase le dit sous la question ; une touche de commande ou une saisie en cours n'est jamais prise | Le prénom n'a pas de lettres (champ de saisie) ; sur un clavier en disposition arabe, les touches donnent des lettres arabes, qui ne sont pas prises : seules A, B, C latines choisissent |
| Puces pour les réponses courtes ; cartes légères pour niveau et objectif | Fiche §2 ; Material 3 (chips) | Un geste par réponse courte | Conforme | Âge, genre, « vous aussi », langue, moments en `FilterPill` ; « Pour qui », niveau, objectif en cartes de liste sans illustration | « Pour qui » garde des cartes : son explication aide (« Votre profil élève est créé avec votre compte ») |
| « Continuer » plein | Constat du directeur (lilas pâle lu comme éteint) ; Material 3 | Une action principale qui se voit active | Conforme | `ActionPrincipale(affirmee: true)`, comme « Recevoir le lien » : violet sur le parchemin, blanc sur la marque | Aucun |

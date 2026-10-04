# Devoir de regard Finance : Comptable V1 (spec §4)

Écrit le 04/10/2026 par l'étape CPT-0 (FIN-L0), avant toute ligne de code, sur `origin/ui/finance-v1` @ `5198107f` et les planches `V/CPT-H00` à `CPT-H08`. Les voies suivantes **ajoutent** leurs constats à la fin (DR-26 et suivants), au même format, sans effacer ceux-ci.

Format imposé par la spec §4 : constat, preuve, risque, proposition, alternative, impact UX, impact sécurité, impact futur backend, décision requise ou non. Aucune règle commerciale, salariale ou de sécurité n'est modifiée ici : quand une proposition en touche une, la décision est demandée (`QUESTIONS.md`).

**Résumé** : 25 constats. Un seul attend le directeur avant que la boucle soit complète : **CPT-Q1** (où la Direction valide les opérations sensibles, et ce qu'elle voit d'un bénéficiaire ; DR-03, DR-04). Il ne bloque aucune voie. Tous les autres ont une proposition appliquée par défaut, que le directeur peut reprendre.

| N° | Sujet | Étape touchée | Décision requise |
|---|---|---|---|
| DR-01 | Shell : 4 destinations + onglets, pas une barre à 10 entrées | CPT-F | Non (confirmable) |
| DR-02 | « Même Finance » ou bureau propre | CPT-F, toutes | Non |
| DR-03 | L'admin ne peut pas ouvrir `/comptable/*` (R-FIN-12) | CPT-DIR-1 | **Oui : CPT-Q1** |
| DR-04 | « Validation supplémentaire » sans écran pour valider | CPT-PAY-2, CPT-TRES-2, CPT-CTR-1, CPT-DIR-1 | **Oui : CPT-Q1** |
| DR-05 | Confirmation mobile H08 avec montant masqué | CPT-PAY-2 | Non |
| DR-06 | Masque : longueur fixe, fuites par tri et lecteur d'écran, portée | CPT-F | Non |
| DR-07 | Métriques en double (Disponible / Trésorerie libre, Réservée / Réserve) | CPT-JOUR, CPT-TRES-1 | Non |
| DR-08 | KPI qui n'aident pas l'opérateur | CPT-JOUR | Non |
| DR-09 | Graphiques des planches | CPT-JOUR, CPT-TRES-1 | Non |
| DR-10 | « À traiter » et « Alertes » : deux listes du même contenu | CPT-JOUR | Non |
| DR-11 | Payer depuis Aujourd'hui, lot sans préflight | CPT-JOUR, CPT-PAY-2 | Non |
| DR-12 | Payer un contractuel : W06 ou W03 | CPT-CTR-1, CPT-PAY-1 | Non |
| DR-13 | Fractionnement de lot, doublon, recalcul pendant la confirmation | CPT-PAY-2, CPT-BR | Non (serveur) |
| DR-14 | Revenus estimés de l'enseignant contre obligation calculée | après CPT-FUS | Oui, non bloquante |
| DR-15 | Transfert entre coffres : montant, interdits §10.4 | CPT-TRES-2 | Non |
| DR-16 | Contractuel sans rôle | CPT-BEN-2, CPT-CTR-1 | Non |
| DR-17 | Rapports, exports | — | Non |
| DR-18 | Recherche globale, cloche | CPT-F | Non |
| DR-19 | Auto-payout : qui le détecte | CPT-PAY-2, CPT-BR | Non |
| DR-20 | Relancer : objet « Profil de paiement » absent de Communications | CPT-BEN-1, CPT-COM | Non |
| DR-21 | Logos et noms de prestataires | CPT-JOUR, CPT-PAY-2 | Non |
| DR-22 | Un seul fichier de libellés pour sept voies | CPT-F, CPT-FUS | Non |
| DR-23 | Change et frais | CPT-PAY-2, CPT-ENC-1 | Non |
| DR-24 | Démonstration et captures des montants | CPT-F, CPT-CAPT | Non |
| DR-25 | Échéances « Abonnement Vercel », « Facture Cloudflare » | CPT-JOUR | Non |

---

## DR-01 Shell du Comptable : quatre destinations et des onglets

- **Constat** : les onze planches montrent une barre latérale de 7 à 10 entrées (Aujourd'hui, Paiements, Encaissements, Trésorerie, Bénéficiaires, Contractuels, Rapprochement, Rapports, parfois Classes, Apprenants, Administration). Le rôle n'a aujourd'hui aucune coquille.
- **Preuve** : `nav_shell.dart:217` (aucune destination), assertion `maxDestinations` dans `destinationsPour` ; spec §45 « bottom navigation réelle » ; planche H01 : barre du rôle **plus** onglets dans la page.
- **Risque** : une barre de 10 entrées ne tient pas en barre basse (mobile cassé ou menu caché) et ferait du Comptable le seul rôle hors règle.
- **Proposition** (appliquée par CPT-F) : `NavShell` à quatre destinations Aujourd'hui / Paiements / Trésorerie / Compte ; onglets `SousNavigationDomaine` dans Paiements (À effectuer, Contractuels, Bénéficiaires) et Trésorerie (Coffres, Encaissements, Rapprochement). Détail : `UX_REVIEW_FINANCE_COMPTABLE_L0.md` §3.
- **Alternative** : une coquille propre de type `AdminShell` (domaines sans plafond). Coût : une seconde coquille à maintenir, pas de barre basse, `AdminShell` est typé `AdminDomaine` et ne se réutilise pas.
- **Impact UX** : même place des fonctions sur mobile et bureau ; deux appuis au plus vers tout écran.
- **Impact sécurité** : aucun ; toutes les routes restent sous le préfixe réservé `/comptable`.
- **Impact futur backend** : aucun.
- **Décision requise** : non. Le directeur peut demander une autre répartition des onglets ; elle ne change que `nav_shell.dart` et les listes d'onglets posées par CPT-F.

## DR-02 Bureau propre, données communes

- **Constat** : FI23 dit « le comptable lit la même Finance que la Direction, jamais un second système » ; la spec §0 remplace cette définition par un « véritable bureau de Finance opérationnelle ».
- **Preuve** : `17_finance/00_REPRISE.md:254` (FI23) ; spec §0, §5.1, §37.
- **Risque** : deux lectures du même chiffre (encaissé du mois, paie due) qui divergent entre Vue globale (Direction) et Aujourd'hui (Comptable).
- **Proposition** : écrans différents (questions différentes), **sources communes** : chaque port Comptable qui lit une donnée déjà servie à la Direction le dit dans `CPT-BR.md` (« même source que FI-BR-12 ») ; Aujourd'hui ne montre ni revenu académique, ni marge, ni impayés foyer (DR-08), qui restent à la Vue globale.
- **Alternative** : faire du Comptable un onglet de plus de l'`AdminShell`. Refusé : préfixe de rôle, et le Comptable n'est pas admin.
- **Impact UX** : chaque rôle voit la question qui le concerne.
- **Impact sécurité** : séparation des rôles conservée.
- **Impact futur backend** : un adaptateur par source, pas deux schémas (même règle que COM-BR-14).
- **Décision requise** : non.

## DR-03 L'admin et les écrans du Comptable

- **Constat** : R-FIN-12 suppose qu'un admin « consulte un enseignant » côté paiement ; or toute route `/comptable/*` est refusée à l'admin par le préfixe réservé, et la spec §37 ne donne à la Direction que deux panneaux de politique.
- **Preuve** : `redirection.dart:226`, `routes.dart:735` ; spec §37, §52 R-FIN-12.
- **Risque** : soit R-FIN-12 n'a pas d'écran où se vérifier, soit on duplique W07 sous `/admin`.
- **Proposition** : la Direction voit un bénéficiaire **dans le détail d'une demande de validation** (CPT-Q1) : même `BeneficiaryPaymentProfileCard`, en lecture, sans « Modifier coordonnées ». R-FIN-12 se prouve là, et sur la fiche Personnes existante de l'admin (`lib/features/admin_comptes/`) qui ne doit porter aucun bouton de coordonnées financières.
- **Alternative** : un onglet « Bénéficiaires » sous `/admin/finance` qui rend le même widget que W07 (un widget, deux coquilles).
- **Impact UX** : la Direction n'a pas un second bureau Finance.
- **Impact sécurité** : aucun accès admin aux actions du Comptable (payer, relancer).
- **Impact futur backend** : lecture du profil de paiement masqué ouverte à la Direction (CPT-BR-06).
- **Décision requise** : **oui, CPT-Q1**. En attendant, CPT-DIR-1 ne fait que ses deux panneaux.

## DR-04 « Validation supplémentaire » sans écran pour valider

- **Constat** : la spec demande « Demander validation » (paiement sensible §21.4, §40), « Validation supplémentaire requise » (retrait de Réserve §9.5, §10.3), « Traitement par un autre responsable requis » (payout du Comptable §20), un « approbateur si requis » (obligation ponctuelle §22.3). Aucun écran ne dit **qui** valide ni **où**.
- **Preuve** : spec §20, §21.4, §22.3, §37 (les deux panneaux ne valident rien), §40.
- **Risque** : des demandes envoyées dans le vide ; ou un Comptable qui « valide » ses propres demandes faute de destinataire.
- **Proposition** : un onglet « À valider » dans le domaine Finance de l'admin (`/admin/finance/validations`) : liste des demandes, détail avec montant exact, bénéficiaire (profil masqué, DR-03), raison de la sensibilité, Valider / Refuser avec motif. Fait par CPT-DIR-1 si le directeur dit oui (CPT-Q1).
- **Alternative** : ne rien montrer côté Direction dans cette vague ; le Comptable voit « Validation demandée » (état rendu par le port), la validation arrive avec BR-1.
- **Impact UX** : boucle complète visible en démonstration.
- **Impact sécurité** : séparation des tâches réelle (le demandeur ne valide jamais).
- **Impact futur backend** : file de validations, décision tracée (CPT-BR-09).
- **Décision requise** : **oui, CPT-Q1**. Les voies du Comptable n'attendent pas : elles affichent l'état « Validation demandée » rendu par leur port.

## DR-05 Confirmation mobile avec montant masqué (H08 M03)

- **Constat** : la feuille « Confirmer le paiement » de H08 M03 affiche `Montant $•••••• USD`.
- **Preuve** : `V/CPT-H08_multicanal.png`, troisième téléphone de M03 ; spec §7.5 « On ne confirme jamais `Payer $••••••` », R-FIN-04.
- **Risque** : confirmer un paiement dont on ne voit pas le montant.
- **Proposition** : `PayoutConfirmationSheet` rend toujours `MontantArgent` (jamais `SensitiveAmount`), quel que soit l'état de la bascule ; le bouton dit le montant (« Confirmer le paiement de 212 USD »). Test R-FIN-04 sur la feuille avec montants masqués.
- **Alternative** : aucune.
- **Impact UX** : la seule surface où le montant s'affiche malgré le masque, ce qui la rend reconnaissable.
- **Impact sécurité** : évite une confirmation à l'aveugle.
- **Impact futur backend** : aucun.
- **Décision requise** : non (la spec tranche).

## DR-06 Masque des montants : longueur, fuites, portée

- **Constat** : les planches masquent avec des longueurs variables (`$•••••`, `$•• •••,••`, `$••••••••`). Trois fuites possibles en plus : un tri de table par montant révèle l'ordre ; une sémantique (lecteur d'écran, info-bulle) qui lit le vrai chiffre ; un état de visibilité conservé.
- **Preuve** : toutes les planches ; spec §7.1 (longueur fixe), §7.3 (session), §46 (« Montant masqué »).
- **Risque** : l'ordre de grandeur se devine ; un lecteur d'écran annonce le montant masqué.
- **Proposition** (CPT-F) : `SensitiveAmount` rend un gabarit fixe **par devise** (même nombre de points, quelle que soit la valeur), sémantique « Montant masqué » ; aucune colonne de montant triable tant que les montants sont masqués ; un seul état de visibilité pour tout l'espace Comptable (pas un par écran, spec §7.4), en mémoire Riverpod, remis à « masqué » à chaque nouvelle session et à la déconnexion, jamais écrit par `PortPreferencesPersistantes`. Les yeux locaux des planches (un œil par tuile) sont refusés : ils créent l'état incohérent que la spec §7.4 interdit.
- **Alternative** : un état par surface (Aujourd'hui, Paiements, Trésorerie). Plus de manipulations pour le même résultat.
- **Impact UX** : un geste, partout.
- **Impact sécurité** : aucune fuite par longueur, tri ou sémantique.
- **Impact futur backend** : aucun (purement local).
- **Décision requise** : non.

## DR-07 Métriques en double

- **Constat** : plusieurs planches montrent à la fois « Disponible » et « Trésorerie libre » (H03, H05b, H06), « Réservée » et les coffres qui la composent (H00, H01, H05b), « Réservée (3 mois) » qui mêle Réserve stratégique et total protégé (H01, H02, H03).
- **Preuve** : planches citées ; spec §11 (« Trésorerie libre » est le chiffre central), §8.1 (sept coffres).
- **Risque** : deux chiffres pour la même question, dont l'un est faux (« Disponible » = solde brut moins quoi ?).
- **Proposition** : un seul vocabulaire, celui de la spec : Trésorerie détenue, Fonds protégés (somme des coffres protégés, rendue par la source), En transit, **Trésorerie libre** ; puis les sept coffres en W04 seulement. « Disponible » et « Réservée » ne s'affichent nulle part.
- **Alternative** : garder « Disponible » comme synonyme. Refusé : spec §11 « ne pas présenter le solde bancaire brut comme argent dépensable ».
- **Impact UX** : un chiffre par question.
- **Impact sécurité** : moins de risque de dépenser de l'argent protégé.
- **Impact futur backend** : les agrégats (protégés, libre) sont **rendus par la source**, jamais additionnés dans Flutter (CPT-BR-04).
- **Décision requise** : non.

## DR-08 KPI qui n'aident pas l'opérateur

- **Constat** : « Total détenu +12 % vs mois dernier », « Revenu réellement acquis », « x % du total » par coffre, sélecteur de date « Aujourd'hui / Octobre 2026 » sur Aujourd'hui.
- **Preuve** : H00, H01, H03, H04, H05b, H06, H07 ; spec §12.2 (chaque KPI répond à décider, payer, rapprocher, sécuriser, prévoir, détecter).
- **Risque** : bruit ; et des pourcentages calculés par Flutter (interdit pour l'argent, FI6).
- **Proposition** : Aujourd'hui garde les métriques qui mènent à une action (Trésorerie libre, Paie à décaisser, En transit, Réserve stratégique, compteurs de la file). « Revenu acquis » reste à la Vue globale de la Direction (déjà là, `VueGlobaleFinance.revenuAcademique`) ; les variations ne s'affichent que si la source les rend ; la part d'un coffre est rendue en pour mille par la source (comme `margeProjeteePourMille`) ; pas de sélecteur de date sur un écran qui s'appelle Aujourd'hui (la période vit dans les filtres de W02 et W05).
- **Alternative** : afficher « Revenu acquis » en W04 pour le Comptable. Possible si le directeur le veut ; doublon avec la Vue globale.
- **Impact UX** : un écran qui dit quoi faire.
- **Impact sécurité** : aucun.
- **Impact futur backend** : `partPourMille` par coffre et variations éventuelles dans le contrat (CPT-BR-04).
- **Décision requise** : non.

## DR-09 Graphiques

- **Constat** : histogrammes « Flux de trésorerie », anneaux « Répartition par coffre », barres empilées « Vue d'ensemble », sparklines, courbe « Évolution » (H00, H02, H03, H03b, H05b, H06, H07, H08 W04).
- **Preuve** : aucune bibliothèque de graphiques dans `pubspec.yaml` (modification interdite, K-19) ; `vue_globale_finance.dart:7-8` « Aucun graphique : un graphique ne remplace jamais un nombre » ; FI21 ; spec §29 « Ne pas saturer de graphiques ».
- **Risque** : un `CustomPainter` maison par écran, des couleurs inventées (K-37), des anneaux en pourcentages sans montant.
- **Proposition** : aucun graphique dans cette vague. Répartition des coffres = liste ordonnée avec montant et part en texte ; la seule jauge est la progression de la Réserve stratégique (`LinearProgressIndicator` du thème, déjà employé) avec son pourcentage écrit ; prévision = lignes datées.
- **Alternative** : un graphique par notion, plus tard, quand une bibliothèque sera décidée (ligne pour le directeur, hors de cette vague).
- **Impact UX** : chiffres exacts lisibles masqués ou non ; un graphique masqué ne dit rien.
- **Impact sécurité** : aucun.
- **Impact futur backend** : séries temporelles inutiles en V1.
- **Décision requise** : non.

## DR-10 « À traiter » et « Alertes » : deux listes

- **Constat** : spec §29 pose « à traiter aujourd'hui » (zone 3) et « alertes » (zone 7) ; les planches y mettent les mêmes lignes (« Informations manquantes », « Paiements échoués » dans les deux, H01, H02, H05b). La M02 de la spec prévoit un écran « Alertes / relances » de plus.
- **Preuve** : spec §28, §29, §36 ; planches citées.
- **Risque** : deux compteurs différents pour le même problème.
- **Proposition** : « À traiter » = ce qui attend une action du Comptable (payer, relancer, rapprocher, approuver), chaque ligne ouvre l'écran canonique filtré ; « Alertes » = les risques sans action immédiate (solde prestataire insuffisant, méthode modifiée récemment, doublon potentiel, Réserve sous l'objectif, fournisseur indisponible). Une ligne n'apparaît que dans une des deux listes ; le type d'alerte (spec §28) porte sa liste dans le contrat. L'écran mobile « Alertes / relances » est le « Voir tout » de ces listes (même route), pas une troisième liste.
- **Alternative** : fusionner en une seule file. Plus simple, mais la spec nomme deux zones.
- **Impact UX** : un problème = un endroit.
- **Impact sécurité** : aucun.
- **Impact futur backend** : champ `liste` (aTraiter | alerte) sur chaque élément (CPT-BR-03).
- **Décision requise** : non.

## DR-11 Payer depuis Aujourd'hui

- **Constat** : H02 met « Payer » sur chaque ligne d'Aujourd'hui ; H07 met « Payer maintenant » sur « 14 enseignants à payer » ; H03 coche des tâches.
- **Preuve** : planches citées ; spec §5.1 (« les raccourcis ouvrent toujours l'écran canonique »), §41 (préflight obligatoire), §13.3 (détail explicable).
- **Risque** : payer 14 personnes sans préflight ni détail ; deux endroits pour payer.
- **Proposition** : Aujourd'hui n'a aucun bouton Payer. La ligne « 14 enseignants à payer » ouvre W02 filtré sur « prêts » ; la ligne d'un bénéficiaire ouvre W03. Les cases n'existent qu'en W02.
- **Alternative** : « Payer » sur Aujourd'hui qui ouvre la même `PayoutConfirmationSheet`. Refusé : le montant serait payé sans que son détail ait été vu.
- **Impact UX** : un appui de plus pour payer, en échange d'une seule façon de le faire.
- **Impact sécurité** : préflight toujours passé.
- **Impact futur backend** : aucun.
- **Décision requise** : non.

## DR-12 Payer un contractuel

- **Constat** : H08 W06 a « Payer » dans la table des obligations de contractuels ; W02 liste aussi les contractuels (filtre, H04, H05b).
- **Preuve** : spec §22.4 (« Le Comptable voit `Payer 350 USD` »), §30 (W02 inclut les contractuels), §5.1.
- **Risque** : deux tunnels de paiement, deux préflights, deux voies (CTR et PAY) qui écrivent la même feuille en parallèle.
- **Proposition** : une obligation de contractuel approuvée devient une ligne de W02 ; « Payer » dans W06 ouvre W03 de cette obligation (`/comptable/paiements/obligation/:obligationId`). CPT-CTR-1 n'écrit aucun composant de paiement.
- **Alternative** : feuille de confirmation partagée posée par CPT-F. Refusé : la feuille est le cœur de CPT-PAY-2.
- **Impact UX** : le même écran de paiement pour tout le monde.
- **Impact sécurité** : un seul endroit à auditer.
- **Impact futur backend** : un seul type « obligation payable » côté serveur (CPT-BR-01).
- **Décision requise** : non.

## DR-13 Fractionnement, doublon, recalcul pendant la confirmation

- **Constat** : le frontend ne peut pas empêcher seul un fractionnement de lot pour passer sous un plafond (spec §47) ; un double appui ou deux sessions peuvent soumettre deux fois ; un recalcul à la source (R-FIN-18) peut arriver entre l'ouverture de la feuille et la confirmation.
- **Preuve** : spec §21.2 (plafond par lot), §41, §47, §54 R-FIN-18.
- **Risque** : payer deux fois, ou payer un ancien montant.
- **Proposition** : côté écran, le préflight affiche ce que la source rend (prêts, exclus avec raison, plafonds de délégation) ; la confirmation porte l'identifiant **et la version** de chaque obligation ; si la source répond « version changée », la feuille dit « Le montant a été recalculé » et montre le nouveau détail, sans envoyer. Le bouton est désactivé dès l'envoi. Côté serveur (CPT-BR-02) : clé d'idempotence par obligation et version, cumul des plafonds par Comptable, par bénéficiaire et par période (pas par lot).
- **Alternative** : aucune côté frontend.
- **Impact UX** : un état de plus, honnête.
- **Impact sécurité** : élevé ; la vraie barrière est serveur.
- **Impact futur backend** : CPT-BR-02.
- **Décision requise** : non (contrat serveur).

## DR-14 Revenus estimés contre obligation calculée

- **Constat** : l'enseignant voit « Revenus estimés » (FI-10) ; le Comptable paie une obligation calculée (spec §13). Pour le même mois, deux montants peuvent différer (remplacement, bonus approuvé).
- **Preuve** : `revenus_enseignant_page.dart:56`, `port_revenus_enseignant.dart:56` ; spec §13.1.
- **Risque** : l'enseignant voit 212 estimés, reçoit 205, sans explication.
- **Proposition** : quand l'obligation existe, la page Revenus affiche « Montant arrêté » avec les mêmes lignes que W03 et l'état du versement. Hors de cette vague (on ne rouvre pas FI-10) : une étape après CPT-FUS, si le directeur l'accepte.
- **Alternative** : « Recevoir mes paiements » (CPT-BEN-2) montre seulement l'état du prochain versement, sans montant.
- **Impact UX** : un seul chiffre pour l'enseignant une fois la paie arrêtée.
- **Impact sécurité** : aucun.
- **Impact futur backend** : lecture par l'enseignant de sa propre obligation (CPT-BR-01, lecture « moi »).
- **Décision requise** : oui, **non bloquante** (après CPT-FUS).

## DR-15 Transfert entre coffres

- **Constat** : H08 W04 propose un transfert avec un champ montant vide ; la spec interdit de vider les Fonds clients, d'utiliser les Taxes pour une dépense, de retirer de la Réserve sans workflow, et de « modifier une allocation pour masquer un déficit ».
- **Preuve** : spec §10.2-10.4 ; K-57.
- **Risque** : un formulaire libre qui permet tout.
- **Proposition** : `TreasuryInternalTransfer` propose les seuls couples permis par la politique rendue par la source ; le montant est prérempli (manque à compléter pour la Réserve, allocation de la politique) et modifiable ; une sortie d'un coffre protégé passe en « Validation supplémentaire requise » ; Fonds clients et Taxes n'apparaissent jamais comme origine vers Libre pour le Comptable ; aucun écran ne modifie une allocation existante (on ne fait que des mouvements journalisés). Tests des quatre interdits.
- **Alternative** : aucune.
- **Impact UX** : un geste, montant déjà proposé.
- **Impact sécurité** : les interdits sont visibles, mais la règle est serveur.
- **Impact futur backend** : CPT-BR-05.
- **Décision requise** : non.

## DR-16 Contractuel sans rôle

- **Constat** : la spec §38 parle d'« enseignant / contractuel avec compte » ; `AppRole` n'a pas de contractuel.
- **Preuve** : `enums.dart:9-26` ; spec §18, §38.
- **Risque** : inventer un rôle (serveur, auth : hors vague).
- **Proposition** : dans cette vague, un contractuel est un **bénéficiaire externe** : côté Comptable, états « Invitation envoyée », puis ceux du profil de paiement rendus par la source ; son action de relance est « Renvoyer l'invitation », pas un fil Messages (il n'a pas de compte). « Recevoir mes paiements » sert l'enseignant et le Comptable (et tout rôle payé qui a un compte).
- **Alternative** : un rôle contractuel avec un portail minimal. Hors vague (serveur).
- **Impact UX** : aucun écran fictif.
- **Impact sécurité** : aucun compte créé hors serveur.
- **Impact futur backend** : invitation sécurisée (CPT-BR-08).
- **Décision requise** : non.

## DR-17 Rapports et exports

- **Constat** : « Rapports » dans toutes les barres, « Exporter le rapport », « Générer un rapport », « Exporter la sélection ».
- **Preuve** : planches ; la spec ne fiche aucun écran Rapports (§29-35) et met la comptabilité légale hors périmètre (§60).
- **Risque** : un écran vide, ou un export qui sort des montants masqués en clair.
- **Proposition** : ni entrée Rapports, ni export dans cette vague.
- **Alternative** : un export CSV de W02 / W05 plus tard, avec sa fiche d'écran.
- **Impact UX** : aucune promesse non tenue.
- **Impact sécurité** : aucun fichier de montants hors de l'app.
- **Impact futur backend** : aucun.
- **Décision requise** : non.

## DR-18 Recherche globale et cloche

- **Constat** : barre « Rechercher une personne, un paiement, une référence… ⌘K » et cloche dans toutes les planches.
- **Preuve** : `NavShell` n'a pas de recherche globale ; la cloche des coquilles est posée par Communications (COM-F, Q5).
- **Risque** : une recherche qui doublonne les filtres de W02 / W05.
- **Proposition** : recherche dans W02, W05, W06, W07 (champ de la table), pas globale. La cloche viendra avec Communications dans la coquille du Comptable (CPT-COM), pas avant.
- **Alternative** : recherche globale du Comptable plus tard.
- **Impact UX** : une recherche là où on cherche.
- **Impact sécurité** : aucun.
- **Impact futur backend** : aucun.
- **Décision requise** : non.

## DR-19 Auto-payout

- **Constat** : « Le Comptable ne voit pas Payer pour lui-même » (R-FIN-15). Comparer dans un widget l'identifiant du bénéficiaire à la session, c'est lire un rôle ; et « bénéficiaire lié à l'opérateur » (§21.4) ne se voit pas côté app.
- **Preuve** : spec §20, §21.4 ; règle du dépôt « un widget lit une capacité, jamais un rôle ».
- **Risque** : un contournement (autre compte, proche) que l'écran ne voit pas.
- **Proposition** : chaque obligation arrive avec ses actions permises et, sinon, la raison (`autoPaiement`, `validationRequise`, `infosManquantes`, ...) ; l'écran affiche la raison, il ne la calcule pas. Pour « autoPaiement » : libellé « Traitement par un autre responsable requis », aucun bouton.
- **Alternative** : calcul local (identifiant égal) en plus. Refusé : deux sources de vérité.
- **Impact UX** : aucun.
- **Impact sécurité** : la règle est serveur.
- **Impact futur backend** : CPT-BR-01 (`actionsPermises`, `raisonBlocage`).
- **Décision requise** : non.

## DR-20 Relancer et Communications

- **Constat** : la spec Communications n'autorise entre Administration et Enseignant que les objets « affectation, Classe, planning, support, dossier professionnel » et dit « toute extension exige une nouvelle décision produit » ; la spec Finance, du même jour, fixe l'objet « Profil de paiement ». Le Comptable n'a, dans Communications, aucun écran Messages.
- **Preuve** : `19_communications/V/REWAYAH_COMMUNICATIONS_FRONTEND_V1.md` §3.2 ; spec Finance §27.3 ; `19_communications/UX_REVIEW_COMMUNICATIONS_L0.md:39` (« Comptable : aucun écran »).
- **Risque** : un Relancer branché sur un objet que le serveur refuse ; un « Voir le fil » sans page.
- **Proposition** : la spec Finance est la décision (autorité 1) : objet `profilPaiement` ajouté à COM-BR-01 (CPT-BR-11). CPT-F pose un port de relance mince au dessin de `PortMessagesMetier.filPourObjet` ; en démonstration, « Relancer » rend « Relance préparée (démonstration) », jamais « envoyée » ; CPT-COM branche le vrai fil et pose la page de fil dans la coquille du Comptable.
- **Alternative** : messagerie Finance. Interdite (R-FIN-21).
- **Impact UX** : aucun faux « envoyé ».
- **Impact sécurité** : aucun.
- **Impact futur backend** : CPT-BR-11.
- **Décision requise** : non.

## DR-21 Prestataires : noms, logos, état

- **Constat** : logos Stripe, Verto, PawaPay, Orange Money, Wave dans les planches.
- **Preuve** : H00, H04, H05b, H08 ; spec §1.2 (« aucun fournisseur codé comme obligatoire », « un fournisseur non activé n'apparaît jamais comme opérationnel en production »).
- **Risque** : marques dans le dépôt, prestataire affiché « Normal » alors qu'il n'est pas branché.
- **Proposition** : `FinanceProvider` générique : nom et état rendus par la source, sans logo ni couleur de marque ; en production, sans source, l'état est « Indisponible » (port neutre) ; la démonstration utilise des noms neutres marqués « (démonstration) ».
- **Alternative** : aucune.
- **Impact UX** : un prestataire se lit par son nom et son état.
- **Impact sécurité** : aucune fausse disponibilité.
- **Impact futur backend** : CPT-BR-10.
- **Décision requise** : non.

## DR-22 Un seul fichier de libellés pour sept voies

- **Constat** : tous les textes vivent dans `assets/i18n/fr.i18n.json` ; les fichiers générés `lib/core/i18n/strings*.g.dart` changent à chaque ajout ; `tool/libelles_sources.json` aussi.
- **Preuve** : `slang.yaml` (un seul fichier d'entrée par langue) ; même cas en Communications (`19_communications/02_DECOUPAGE.md:161`).
- **Risque** : conflits git à chaque fusion.
- **Proposition** : CPT-F pose un bloc `comptable` avec un sous-bloc par voie (`aujourdhui`, `paiements`, `tresorerie`, `encaissements`, `beneficiaires`, `contractuels`, `direction`, plus `socle`), espacés ; chaque voie n'écrit que dans son sous-bloc ; les fichiers générés et `libelles_sources.json` ne se fusionnent pas à la main : CPT-FUS fait l'union et relance `dart run slang`. `ar.i18n.json` n'est pas touché.
- **Alternative** : un fichier par module (slang avec espaces de noms). Change `slang.yaml` et toute la base : hors vague.
- **Impact UX** : aucun.
- **Impact sécurité** : aucun.
- **Impact futur backend** : aucun.
- **Décision requise** : non.

## DR-23 Change et frais

- **Constat** : la spec §43 demande taux, frais, montant envoyé et reçu « quand disponibles », et interdit une conversion fictive.
- **Preuve** : spec §43, §60 (FX réel hors périmètre).
- **Risque** : un montant reçu calculé dans Flutter.
- **Proposition** : les lignes de change n'apparaissent que si la source les rend ; sinon la feuille dit « Frais et change communiqués par le prestataire au moment de l'envoi ». Aucun calcul.
- **Alternative** : aucune.
- **Impact UX** : honnête.
- **Impact sécurité** : aucun montant inventé.
- **Impact futur backend** : CPT-BR-02 (devis du prestataire).
- **Décision requise** : non.

## DR-24 Démonstration et captures des montants

- **Constat** : les montants de démonstration se voient en capture ; la bascule est remise à « masqué » à chaque session.
- **Preuve** : spec §44 (« montant masqué / affiché »), §50 R-FIN-01 à 03.
- **Risque** : une capture prise montants affichés présentée comme l'état d'entrée.
- **Proposition** : la démonstration entre masquée (comme la production) ; un paramètre de démonstration `?montants=affiches` existe seulement hors production, pour CPT-CAPT ; chaque capture dit son état dans son nom (`_masques`, `_affiches`). Les montants de démonstration sont réalistes et marqués (démonstration), sans les valeurs des planches (21 000 USD, 3 000 USD).
- **Alternative** : aucune.
- **Impact UX** : aucun.
- **Impact sécurité** : aucun.
- **Impact futur backend** : aucun.
- **Décision requise** : non.

## DR-25 Échéances de fournisseurs (Vercel, Cloudflare)

- **Constat** : H00 met « Abonnement Vercel » et « Facture Cloudflare » dans les échéances.
- **Preuve** : H00 ; la spec ne connaît que deux familles d'obligations payables : enseignants (§13) et contractuels (§22). Les charges d'infrastructure vivent dans le coffre « Charges essentielles » (§8.1).
- **Risque** : une troisième famille de paiements sans spec, avec des noms de prestataires réels dans le dépôt.
- **Proposition** : les échéances d'Aujourd'hui ne montrent que des obligations (enseignants, contractuels, remboursements) ; une charge récurrente d'un fournisseur se représente comme une obligation de contractuel récurrent si la Direction le décide un jour ; la démonstration n'utilise aucun nom réel de fournisseur.
- **Alternative** : une famille « Charges » dans W06. À fiche, plus tard.
- **Impact UX** : aucun.
- **Impact sécurité** : aucun.
- **Impact futur backend** : aucun.
- **Décision requise** : non.

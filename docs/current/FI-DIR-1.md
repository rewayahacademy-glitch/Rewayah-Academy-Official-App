# FI-DIR-1 : décisions du 05/10 appliquées à la Finance

Session de la vague du 05/10 (orchestrateur 01B8we8b). Branche `ui/fi-dir-1`, base
`origin/ui/finance-v1` @ 728c34c5 (FI-VAGUE-CORR). Rapport source :
`origin/pilotage/tuteur-v1:17_finance/FI-VAGUE-CORR.md`, revue
`docs/revues/REVUE_FI-VAGUE-R.md` (branche `revues/2026-10-04-01MrLWqB`).

Statuts au sens de `00_LIRE_D_ABORD.md` : tout ce qui suit est **présent dans le code et
testé localement**. Rien n'est testé sur staging ni déployé (aucune PR, aucune fusion).

## Décisions appliquées

| Décision | Ce qui change | Où | Preuve (test) |
|---|---|---|---|
| FI-Q1 (a) | Sans source de paiement (production, chargement, erreur), « Ajouter un profil élève » est le bouton plein ; avec finances rendues, « Recharger plusieurs profils » l'est. Comportement déjà en place, commentaires mis à jour (la question est close). | `foyer_page.dart`, `finances_foyer.dart` | `foyer_finances_test` « un seul bouton plein », « sans source (production) » ; capture `fidir1_foyer_production_*` |
| FI-Q2 (a) | « Vue financière du foyer » gardée, sur le mois en cours, sans sélecteur. | `finances_foyer.dart` (commentaire) | `foyer_bureau_test` « Vue financière du foyer sur le mois courant » |
| FI-Q3 (b) | Titre « Profils élèves » pour tous les titulaires ; la clé `foyer.membresEnfants` (« Enfants du foyer ») est retirée, le paramètre `titulaireAdulte` devenu inutile aussi. | `foyer_page.dart`, `fr.i18n.json` | `foyer_finances_test` (« Profils élèves », jamais « Enfants du foyer »), `foyer_page_test` |
| FI-Q4 (a) | « Voir tout » ouvre l'historique du foyer. Déjà en place, commentaire mis à jour. | `transactions_foyer.dart` | `foyer_bureau_test` « Voir tout vers l'historique du foyer » |
| FI-Q5 (a) | Le ruban « Démonstration » suffit, aucune marque par montant. Commentaire de `finance_demo.dart` corrigé. | `finance_demo.dart` | (aucun code ne change) |
| FI-Q7 (a) | « Télécharger le reçu » (secondaire) sous les actions de la fiche Finances, seulement quand une période a été financée ; l'appui appelle un port neuf `PortRecus` (FI-BR-05) qui rend `CapaciteIndisponible` en production **et** en démonstration ; l'écran dit « Le reçu n'est pas encore disponible ». Même composant pour l'adulte autonome (Mes finances). | `core/capacites/port_recus.dart`, `fiche/finances_page.dart` (`BoutonRecu`) | `fiche_eleve_finances_test` groupe « FI-DIR-1 » (390, 1440, essai sans reçu) |
| FI-Q12 (b) | L'enfant ne voit que l'état « fermé ». Comportement gardé, commentaire écrit. | `accueil_eleve_page.dart` | tests d'accès existants (`acces_finance_test`) |
| FI-Q16 (a) | Titre « Revenus estimés » (écran et ligne du Profil). | `fr.i18n.json` | `revenus_enseignant_test` « FI-Q16 » |
| FI-Q18 (a) | Choix du mois sur les Revenus et la Vue globale. Il ne propose **que** les mois rendus par la source (`moisDisponibles()`, FI-BR-11 et FI-BR-12) ; sans source, aucun choix. La démonstration ne rend que le mois de référence (octobre 2026) : aucun mois inventé avant l'entrée en vigueur de la politique. Composant commun `SelecteurMois` (habit de `MenuFiltre`, axe ouvert). | `core/widgets/selecteur_mois.dart`, ports, `revenus_enseignant_page.dart`, `vue_globale_finance.dart`, `finance_demo.dart`, pages de démo | `revenus_enseignant_test` « FI-Q18 » (deux mois, mois vide, production), `vue_globale_finance_test` « R6-03 et FI-Q18 » |
| FI-Q21.1 | Marge de référence (objectif, forte, stretch) en trois champs, pourcentage entier, rendue en pour mille ; cohérence : 100 % au plus, forte ≥ objectif, stretch ≥ forte. Paiement web : interrupteur dans le brouillon. | `politiques_commerciales.dart` | `politiques_commerciales_test` groupe « FI-DIR-1 » |
| FI-Q21.2 | « Achat intégré iOS » et « Facturation Google Play » : « Préparé (inactif) », lus, jamais un réglage. | idem | idem (brouillon et lecture) |
| FI-Q21.3 | Édition directe, aucun bouton « Modifier » par carte (déjà le cas). | idem | idem |
| FI-Q21.4 | Date d'effet réglable dans le brouillon (calendrier à partir du lendemain, jamais rétroactive), envoyée avec le brouillon ; la phrase dit qu'elle s'applique à la publication, au branchement. | idem | idem |
| FI-R6 (a) 1 | Vue globale : « État des paiements » (profils par état et leur part rendue), « Top classes » (encaisse par classe, ordre rendu), « Dernières opérations » (mouvements des profils, heure, état). Données de démo calculées dans `finance_demo.dart` sur les mêmes sièges que le revenu ; production : `CapaciteIndisponible('FI-BR-12')`. | `port_finance_direction.dart`, `vue_globale_finance.dart`, `finance_demo.dart` | `vue_globale_finance_test` « R6-02 » (contenu, ordre non trié par l'écran, vide) |
| FI-R6 (a) 2 | Choix du mois sur la Vue globale (voir FI-Q18). | | |
| FI-R6 (a) 3 | Politiques : sections lues rangée par rangée (plus de `i += 2` en deux colonnes) ; en-tête de version sur une rangée sur ordinateur ; historique en fin de page. | `politiques_commerciales.dart` | `politiques_commerciales_test` « R6-08 : 1440 » |
| Libellé | `ficheEleve.finances.noteAbsences` → « Les absences ordinaires n'entraînent pas de réduction sur le mois une fois celui-ci financé. » | `fr.i18n.json` | `fiche_eleve_finances_test` (texte exact) |
| fi-elision | Déjà fait dans la Finance ; rien n'est touché hors Finance (étape LIB-DIR-1). | | |

## Points suspendus du rapport FI-VAGUE-CORR

| # | Constat | État après FI-DIR-1 |
|---|---|---|
| 1 | R1-01, cas sans source | Fait : FI-Q1 (a). |
| 7 | R1-02, Q-FI-8 | Fait : FI-Q2 (a). |
| 9 | R1-09, « Enfants du foyer » | Fait : FI-Q3 (b), « Profils élèves ». |
| 11 | R1-13, marque par montant | Fait : FI-Q5 (a), le ruban suffit. |
| 15 | R2-03, texte de la note | Fait : libellé tranché le 05/10 (sans renvoi à un onglet inexistant). |
| 16 | R2-04, reçu | Fait : FI-Q7 (a). |
| 29 | R4-03 | Fait : FI-Q12 (b), comportement gardé. |
| 32 | R4-08 hors Finance | Hors de cette étape : LIB-DIR-1 (élision dans toute l'application). |
| 36 | R5-04, R5-05 | Fait : FI-Q16 (a), FI-Q18 (a). R5-06 était déjà fait. |
| 41 | R6-06, édition en brouillon | Fait pour la marge et le paiement web (FI-Q21.1). **Relances et budgets restent lus** : FI-Q21 ne les nomme pas ; décidé par délégation le 05/10 (choix prudent : pas de règle de relance ni de budget saisissable sans contrat serveur). |
| 42 | R6-02, R6-03, R6-08 | Fait : FI-R6 (a). |

## Choix faits par délégation le 05/10 (non couverts mot à mot)

- Le reçu est proposé aussi à l'adulte autonome (même composant `VueFinancesProfil`), seulement quand une période a été financée ; il n'est jamais proposé en essai ni sans paiement.
- Le reçu se place sous « Voir les mouvements » (mobile) ou sous « Recharger » (bureau à trois colonnes) : l'ordre R2-04 (bouton plein, puis lien à 8 px) reste intact.
- La démonstration ne rend qu'un mois : le choix du mois y montre un seul mois. Un second mois aurait été un historique inventé (règle R6-01) ; le changement de mois est prouvé par des doubles de test à deux mois.
- Pas de « Voir tout » sur « Top classes » ni « Dernières opérations » : aucune page de la direction ne porte encore ces listes complètes (un lien sans cible distincte est refusé, leçon 11).
- Pas de variation « vs mois précédent » (maquette 09) : aucun contrat ne la rend.
- Le paiement web peut être désactivé dans un brouillon (FI-Q21.1) ; iOS et Android restent non réglables (guide §1.6 : aucun bouton App Store ou Play Billing au lancement).
- Bornes du calendrier de la date d'effet : du lendemain à la fin de l'année N+5 (borne technique du sélecteur, pas une règle commerciale).

## Mesures (chiffres mesurés sur la branche)

- `dart analyze --fatal-infos` (projet entier, sous verrou) : No issues found.
- Suites demandées, une seule passe sous verrou (`admin_finance`, `revenus_enseignant`, `foyer`, `finance`, `finance_recette`, `mon_espace_adulte`, `demo`, `acces_finance`) : **+1081 ~650 (captures sautées sans `CAPTURE_DIR`), 0 échec**, « All tests passed! ».
- Contre-épreuve (mutations, une passe) : 5 mutations posées ensemble, 5 tests rouges, puis code restauré :
  - `_TopClasses` inverse l'ordre rendu → « R6-02 : État des paiements… » échoue ;
  - `lireRevenus` ignore le mois choisi → « FI-Q18 : le choix du mois… » (revenus) échoue ;
  - rangée de Politiques privée de sa section de gauche → « R6-08 : 1440 » échoue ;
  - `BoutonRecu` traite `CapaciteIndisponible` comme un succès → « FI-Q7 : … visible » échoue ;
  - marge saisie sans conversion en pour mille → « Q21.1 : la marge… » échoue.
- `dart run tool/verifier_jetons.dart` : 39 → 39 (aucune ligne dans un fichier touché).
- `dart run tool/verifier_revue.dart` : 1649 avant la déclaration des libellés neufs (36 lignes, toutes de cette étape), 1613 après ; aucune violation de cette étape ne reste (la base n'a pas été mesurée à part).
- Captures : 36 PNG, `docs/current/captures/FI-DIR-1/` (`fidir1_<écran>_<390|1440|320_200pc>_<light|dark>.png`), écrans : Foyer (démo à régulariser, production sans source), fiche Finances de Mariam, Revenus estimés, Vue globale, Politiques. Ouvertes et vérifiées : Vue globale 1440 clair et 320 ×2 sombre, Politiques 1440 clair et 320 ×2 clair, Finances 390 sombre, Revenus 390 clair, Foyer production 390 clair et Foyer 1440 sombre.
- Hors périmètre vérifié : aucun fichier de `lib/core/theme`, `pubspec.yaml`, `supabase/`, `.github/` n'est modifié.

## Restes

- Hors de cette étape : la page « Groupes » renommée « Classes » et l'élision hors Finance (LIB-DIR-1).
- `SoldesFoyerSection` reste dans le code, non posée (vague ultérieure, inchangé).
- Le contrat FI-BR-05 (reçu), FI-BR-11 et FI-BR-12 (mois disponibles, lecture par mois, état des paiements, classement, derniers mouvements) est à inscrire dans `17_finance/FI-BR.md` côté pilotage (non écrit ici : le prompt range le rapport sur la branche).

## Contre-revue du 08/10 (vérificateur croisé, puis revue FI-VAGUE-CORR-R)

Statut : présent dans le code et testé localement. Rien sur staging, rien déployé.

### Bloquants FI-DIR-1

| Point | Ce qui change | Preuve |
|---|---|---|
| Galerie | `SelecteurMois` a son entrée (trois états : un mois, plusieurs mois, un mois ancien choisi) et sa ligne au catalogue. | `catalogue_galerie_test` vert (test/widgets +234). |
| Démo de la Vue globale | Une seule population : les sièges des classes et le foyer `jeuVueGlobale` (= `unARegulariser`, Ibrahim à régulariser à Al-Huda, Mariam et Aïcha financées à An-Nour). Essais, soldes créditeurs, dernières opérations, alerte et impayés lisent la même. « En essai » vaut 0. | `finance_demo_test`, groupe « une seule population » (aucune personne à la fois en essai et dans un paiement ; essais de la tuile = état des paiements ; alerte = profil à régulariser ; classe de chaque opération dans Top classes ; soldes = population). |
| `etatPaiementsDemo`, `topClassesDemo` | Parts calculées au plus fort reste (`partsPourMille`) : 929 + 71 + 0 + 0 = 1000. Top classes : 250 + 240 + 200 = encaisse. | groupe « etatPaiementsDemo et topClassesDemo ». Mutation `n * 100 ~/ total` : 2 tests rouges. |
| K-61 | Captures pleine hauteur `fidir1cr_admin_vue_globale_{390_haut,320_200pc_haut}_{light,dark}.png` et `fidir1cr_admin_politiques_…` (320 ×2 sur 22 000 px, page entière). | Ouvertes : Vue globale 390 clair et sombre, 320 ×2 sombre (État des paiements, Top classes, Dernières opérations) ; Politiques 390 clair et sombre, 320 ×2 clair et sombre (groupe « Marge de référence », trois champs, page jusqu'à l'historique). |

### Mineurs FI-DIR-1

- Q21.4 : la date cible se calcule depuis `DateTime.now()` (plus de 15 janvier 2027 en dur).
- `_changerDate` : date initiale bornée entre le lendemain et la borne, borne étendue à la date déjà posée ; test « au-delà de la borne technique, sans assertion ».
- `pol.marge` : titre visible « Marge de référence », annoncé comme titre, au-dessus des trois champs (`margeKey`) ; test.
- Une date d'effet changée compte dans « différences » ; décidé par délégation le 08/10 : comparée à la date lue du brouillon, pas à la version active (un brouillon a toujours une date postérieure, ce ne serait jamais « aucune différence »).
- Heure non réelle : un horodatage à minuit pile s'affiche sans heure (« 1er octobre 2026 ») ; décidé par délégation le 08/10 (la règle R2-05 « deux recharges du même jour se distinguent » reste vraie pour les heures réelles).
- Parts : somme exacte de 1000 (plus fort reste), calcul de démonstration seulement.
- « Classe As-Salam » : trait d'union insécable (`nomSansCoupure`) dans Top classes, aucun mot coupé à 320 ×2 (capture ouverte).
- Revenus : sans choix du mois (production), l'intro dit « du mois en cours » (clé `introSansChoix`, source déclarée) ; tests.
- Reçu : test du chemin « échec » (message « réessayez », le bouton reste et relance).

### Revue FI-VAGUE-CORR-R (ajout de l'orchestrateur)

- **R3-02 (majeur)** : la recharge reprend les trois colonnes de la maquette 07 dès 1200 px (profils 5, aide 3, paiement 4). La colonne d'aide porte l'explication du paiement unique et les trois faits du bas de la fiche Finances (`faitSeance`, `faitPeriode`, `noteAbsences`), aucun texte neuf ; décidé par délégation le 08/10 (DIR-REP-1, option prudente = la maquette). `recharge_multi_profils_test` exige trois colonnes à 1200, 1280 et 1440 ; **contre-épreuve** : sur l'ancienne composition à deux colonnes, les 3 tests échouent. `recette_fi_test` mesure désormais les trois colonnes (profils, aide, récapitulatif). Captures `fidir1cr_recharge_{1200,1280,1440}_{light,dark}.png`, ouvertes (1200 clair, 1280 sombre, 1440 clair). Le rapport `FI-VAGUE-CORR.md` n'est pas dans ce dépôt (branche de pilotage) : sa ligne R3-02 reste à corriger par l'orchestrateur.
- **R7-04** : `accesFoyerProvider`, `paiementsFoyerProvider`, `soldesFoyerProvider` et `politiqueActiveProvider` sont liés à la personne connectée ; quatre cas ajoutés à `lectures_session_test`. Contre-épreuve : sans la liaison de `accesFoyerProvider`, son test échoue. Les hôtes de test de la démo adulte posent désormais la source de session, comme `main.dart`.
- Espace insécable avant « : » dans la phrase de répartition ; « Voir tout » commence le nom lu de la fiche (« Voir tout : mouvements {dePrenom} »).
- Non traité (non local) : « Pas encore de classe » sur la carte du Foyer contre « Classe Al-Huda » sur la fiche, en démo Finance. La carte lit le port des classes (`ClassesFoyerDemo`, données de `DonneesDemo`), qui ne connaît pas les profils de la démo Finance ; l'aligner demanderait d'inventer une classe complète (enseignant, couleur, effectif).

### Mesures (08/10, sous verrou)

- `dart run slang` : rien d'autre que les fichiers générés de la clé neuve.
- `dart analyze --fatal-infos` : No issues found.
- test/widgets +234, test/core +716, test/router +279, test/features +3074 ~2695 (captures sautées) avec 1 échec d'hôte (`mon_espace_adulte_page_test`, source de session absente), corrigé puis rejoué : `mon_espace_adulte` et `recette_fi_roles_test` +120, 0 échec. Dossiers finance dans la passe précédente : admin_finance +105, revenus_enseignant +47, foyer +525, finance +60, demo +106, acces_finance +71, compte +47.
- `verifier_jetons` : 39 (base 728c34c5 : 39).
- `verifier_revue` : base 728c34c5 1611, tête 1605.

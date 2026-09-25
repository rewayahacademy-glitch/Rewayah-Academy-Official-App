# Lot T : revue adversariale (LT-R)

Diff : `origin/ui/tuteur-v1...ui/tuteur-v1-t` (HEAD `895e601`, LT-1 à LT-12). Lecture seule, rien corrigé. 25/09/2026.

## Règles du mandat : vérification

| Règle | Verdict | Preuve |
|---|---|---|
| Frontière vide (`supabase .github vercel.json pubspec.yaml lib/core/theme`) | OK | `git diff --stat` vide |
| Démonstration isolée | OK | `surchargesDemoTuteur` lève une erreur en production (`mode_demonstration.dart`) ; appliquée seulement dans `main.dart:80` (garde `demoTuteurActiveIci`) et `racine_demonstrable.dart:72` (garde `_autorisee`) ; `FinanceFoyerDemo` garde devis, paiement et annulation indisponibles |
| Production : finance derrière des ports « indisponible » | OK | `FinanceFoyerIndisponible` (DB-FIN-01 à 06), paiements DB-CPT-03, notifications DB-CPT-04 ; « Recharger », « Payer », « Arrêter l'accès », « Voir les mouvements associés » ne s'affichent que sur une lecture réussie |
| Aucun calcul d'argent côté Flutter | OK, avec réserves 7 et 9 | `format_montant.dart` ne fait que placer la virgule ; totaux fournis par le serveur |
| Montant inconnu jamais « 0 » | OK, avec réserve 5 | `ResumeSolde`, `LigneBeneficiaire.texteSolde`, `resumeTotalSoldes` |
| `?retour=` filtré | OK | toutes les lectures passent par `cheminRetourValide` (recharge, arrêt, soldes, mouvements, paiement) |
| Codes serveur jamais bruts | OK | nature, statut, motif et effets passent par des listes fermées avec une valeur neutre par défaut |
| Idempotence et double tap (Payer, Confirmer) | OK | garde `_enCours` avant `await`, clé gardée au réessai, tests `double tap : un seul appel ; reessai avec la meme cle` |
| localStorage web | OK | seule la clé `apparence.theme` ; les exceptions (y compris l'accès refusé à `localStorage`) remontent en `Future` et sont captées par `try` dans `preferences_locales.dart:259-278` |
| Composants partagés | OK, avec réserve 11 | `SelectionProfils` (plusieurs profils) complète `SelecteurProfils` (un seul) sans le dupliquer ; `BasculeTheme` remplacée par `SelecteurTheme` |
| Chaque écran atteint par un vrai bouton, avec un test qui le tape | OK | clés d'entrée tapées dans `soldes_test`, `solde_profil_test`, `recharge_test`, `arret_acces_test`, `mouvements_test`, `mouvements_seance_test`, `paiements_test` |

**Aucun constat bloquant.**

## Constats

| # | Gravité | Fichier:ligne | Constat | Correction proposée |
|---|---|---|---|---|
| 1 | majeur | `lib/features/compte/arret_acces_page.dart:45-69` ; `compte/acces_page.dart:48` ; `foyer/fiche/acces_page.dart:164` | La sonde `apercuPossible` et S10 partagent le même `apercuAnnulationProvider` (autoDispose). La page Accès, qui est sous `/arreter` dans la pile, ou la fiche, gardée vivante par la branche du `StatefulShellRoute`, garde l'aperçu en vie. S10 réutilise alors l'aperçu lu au moment de la sonde (même clé si « Tout sélectionner » ou `?profil=`), ce qui contredit « relu à chaque ouverture ». La confirmation peut s'appuyer sur une référence et une date d'effet périmées. | Dans `ArretAccesPage`, `initState` doit invalider `apercuAnnulationProvider(cleApercu(ids))` (et le faire aussi au passage à l'étape 2), ou bien la sonde doit lire un provider distinct. |
| 2 | majeur | `lib/features/compte/verifier_recharge_page.dart:109-112` | Point 1 (LT-8) : l'horloge locale décide qu'un devis a expiré et masque « Payer ». C'est une règle locale : une horloge en avance bloque le paiement, une horloge en retard ne protège de rien. | **Corriger** : garder « Payer » tant que le devis est présent, afficher « valable jusqu'au » à titre d'information, et laisser le refus du serveur (code d'expiration, à ajouter au contrat DB-FIN-04) ouvrir l'état `_Reprendre`. |
| 3 | majeur | `lib/features/compte/arret_acces_page.dart:562-567` | Point 2c (LT-9) : S11 titre « Demande transmise » avec l'icône d'attente, même si tous les profils sont `echouee`. L'écran ne ment pas, mais il laisse croire qu'une suite est en cours. | **Corriger** : choisir titre et ton d'après les issues rendues (toutes échouées : « Aucun accès arrêté », ton alerte ; mélange : « Arrêt partiel » ; sinon « Demande transmise »), en simple lecture de l'énumération, sans règle métier. |
| 4 | majeur | `lib/features/compte/arret_acces_page.dart:55-69` | Point 2b (LT-9) : on sonde DB-FIN-05 pour décider d'afficher « Arrêter l'accès ». Chaque affichage déclenche une lecture serveur, un échec réseau cache l'action en silence, et la sonde provoque le constat 1. | **Corriger** (lié au constat 1) : exposer la disponibilité par le port (`bool get annulationDisponible`, `false` dans `FinanceFoyerIndisponible`, `true` dans la démo) et supprimer la sonde. Sinon, garder la sonde en provider séparé en `bool`. |
| 5 | majeur | `lib/features/compte/soldes_page.dart:39-53` (utilisé à `foyer_page.dart:117` et `accueil_famille_page.dart:164`) | `resumeTotalSoldes` ignore `complet` : sur le Foyer et l'Accueil, un total partiel s'affiche comme le total du foyer. S01 le signale, ces lignes non. | Si `!complet`, ajouter la mention « incomplet » (clé `finance.totalIncomplet` en version courte) ou rendre `aucunTotal`. |
| 6 | majeur | `lib/core/finance/format_montant.dart:14-29` | Point 6 : la table est juste pour les devises qu'elle contient, mais incomplète. Des devises à exposant 0 manquent, dont plusieurs francophones (XPF, GNF, KMF, DJF, ainsi que BIF, RWF, UGX, PYG, VUV, UYI), de même que CLF et UYW à exposant 4. Une devise absente est lue avec deux décimales, ce qui affiche un montant 100 fois trop petit. Pour EUR, MAD, DZD, TND, XOF, XAF, USD, GBP, CAD, CHF, SAR et AED, le résultat est correct. | Compléter la table à partir d'ISO 4217 (liste ci-contre) et garder le `ponytail` : l'exposant fourni par le serveur (DB-FIN-01) la remplacera. |
| 7 | majeur (à trancher) | `lib/features/compte/recharge_page.dart:314-319` ; `verifier_recharge_page.dart:267-273` | La quantité de solde (« Ajoute … ») est écrite dans la devise du prix, alors que le port la dit « distincte du prix (F4) ». L'écran présume que 1 unité de solde vaut 1 unité de devise, sans que le serveur l'ait dit. | Ajouter `deviseSolde` (ou une unité) à `OffreRecharge` et `LigneDevis` dans le contrat DB-FIN-03 ; en attendant, afficher la quantité sans devise ou demander l'arbitrage du directeur (`demandes/T.md`). |
| 8 | mineur | `lib/features/compte/arret_acces_page.dart:92-107` | Point 2a (LT-9) : la définition locale d'un aperçu « complet » ne calcule rien. Elle ferme la confirmation tant qu'une conséquence est inconnue, ce qui est conforme au tri §1 (S10). | **Garder** comme garde-fou d'affichage ; ajouter au contrat DB-FIN-05 un indicateur `confirmable` rendu par le serveur, qui remplacera la fonction (commentaire `ponytail:` à poser). |
| 9 | mineur | `lib/features/compte/mouvements_page.dart:115,195-201` | Point 4 (LT-6) : le filtre de profil (`_profil`, état local) se perd au retour du détail. Le `?retour=` propre à S07 se perd aussi (séance → mouvements → détail → retour : S07 renvoie ensuite aux Soldes, plus à la séance). | Porter le filtre dans `?profil=` de S07, et passer `GoRouterState.of(context).uri.toString()` comme `retour` du détail (déjà filtré par `cheminRetourValide`, qui accepte la requête). |
| 10 | mineur | `lib/core/widgets/page_shell.dart:109-150,186-195` | Point 5 (LT-10, préexistant) : la « tête » (titre, sous-titre, actions) ne défile pas. À 390 px avec le texte à 200 %, elle dépasse la hauteur disponible sur Soldes, Accès, Mouvements… | Correction minimale : `final bool teteDefile = defilante && MediaQuery.textScalerOf(context).scale(1) > 1.3;` ; si vrai, placer `...tete` en tête de la `Column` du `SingleChildScrollView` au lieu de la zone fixe. Rien ne change à 100 %, donc les captures restent identiques. |
| 11 | mineur | `lib/features/foyer/fiche_eleve_page.dart:144` ; importé par `compte/soldes_page.dart:25`, `acces_page.dart`, `arret_acces_page.dart:31`, `verifier_recharge_page.dart:23` | Point 3 (LT-10) : `ColonnesFiche` est devenu un gabarit partagé, mais il vit dans une fonctionnalité (dépendance Compte → Foyer). | **Corriger** : le déplacer tel quel dans `lib/core/widgets/colonnes_fiche.dart` (sans le renommer, pour limiter le diff) et mettre à jour les 5 imports. |
| 12 | mineur | `lib/features/suivi_foyer/detail_seance_page.dart:139,248-252` | « Voir les mouvements associés » s'affiche dès qu'un mouvement quelconque se lit, puis ouvre la liste complète : le libellé promet une association qui n'est pas vérifiée. | N'afficher le lien que si un mouvement lu porte `seanceId == seanceId` ; ouvrir directement son détail s'il est unique, sinon la liste. |
| 13 | mineur | `lib/features/foyer/fiche_eleve_page.dart:457` | Dans la fiche, « Recharger » s'affiche même si le profil n'est pas dans `lus.profils`. S03 s'ouvre alors sans sélection possible (`?profil=` filtré par les soldes). | Afficher « Recharger » seulement si le profil figure dans les soldes lus. |
| 14 | mineur | `lib/features/compte/recharge_page.dart:82-86,212` | `_verifier` n'a pas de garde `_enCours`, et le réessai de `EtatSysteme` peut relancer pendant qu'une demande est en cours. C'est une simple lecture, sans effet sur l'argent. | Ajouter `if (_enCours) return;` en tête, comme `_payer`. |
| 15 | mineur | `lib/features/compte/verifier_recharge_page.dart:71` | La clé d'idempotence est liée à l'instance d'écran et non au devis. Si S05 est rouvert avec le même `extra` (historique du navigateur), une nouvelle clé part pour le même devis. | Dériver la clé de `devis.reference` (par exemple une table en mémoire référence → clé) ; le serveur reste l'ultime garde (référence du devis). |
| 16 | mineur | `lib/features/compte/mouvements_page.dart:52-63` ; `arret_acces_page.dart:77-87` ; `paiements_page.dart:101-105` | Les codes `demo_*` sont traduits dans le code de production. C'est inoffensif (les codes réels tombent dans la valeur neutre), mais le vocabulaire de la démo entre dans le produit. | Garder jusqu'à ce que les contrats DB-FIN-02/05 et DB-CPT-03 soient fixés ; les remplacer alors par les codes réels (le `ponytail:` est déjà posé). |
| 17 | mineur | `lib/features/compte/recharge_page.dart:243` ; `arret_acces_page.dart:410` | `_Question` est dupliqué à l'identique dans deux fichiers. | Le factoriser dans `PageEtape` (titre et phrase de l'étape) ou dans un widget de `lib/core/widgets`. |

Devises ISO 4217 à ajouter (constat 6) : exposant 0 : `BIF, DJF, GNF, KMF, PYG, RWF, UGX, UYI, VUV, XPF` ; exposant 4 : `CLF, UYW`.

## Points signalés : décision

1. LT-8, expiration jugée par l'horloge locale : **corriger** (constat 2).
2. LT-9 : aperçu « complet » **à garder** (constat 8) ; sonde « Arrêter l'accès » **à corriger** (constats 4 et 1) ; titre S11 **à corriger** (constat 3).
3. LT-10, `ColonnesFiche` : **corriger**, le déplacer dans `lib/core/widgets` (constat 11).
4. LT-6, filtre perdu : **corriger**, le porter en `?profil=` et transmettre l'URI complète en `retour` (constat 9).
5. LT-10, débordement à 200 % : **corriger** dans `page_shell.dart`, la tête ne défile qu'avec un grand texte (constat 10).
6. Formateur : **juste pour les devises courantes**, table à compléter (constat 6).

## Corrections pour LT-F, dans l'ordre

1. Constats 1 et 4 : disponibilité de l'annulation via le port (ou provider distinct) et invalidation de l'aperçu à l'entrée de S10, avec un test qui prouve un second appel à `apercuAnnulation` en ouvrant S10 depuis Accès.
2. Constat 2 : retirer le masquage local de « Payer » ; adapter le test d'expiration pour qu'il passe par un refus du serveur.
3. Constat 5 : mention « incomplet » dans `resumeTotalSoldes`, avec un test Foyer/Accueil pour `complet: false`.
4. Constat 3 : titre et ton S11 d'après les issues, avec un test « toutes échouées ».
5. Constat 6 : compléter la table d'exposants, avec un test par exposant (0, 3, 4).
6. Constat 7 : arbitrage du directeur, puis quantité sans devise en attendant le contrat.
7. Constat 11 : déplacer `ColonnesFiche` dans `lib/core/widgets`.
8. Constat 10 : tête défilante à grand texte dans `PageShell`, avec un test à 390×844 et `textScaler` 2.0 sans débordement.
9. Constat 9 : filtre et retour de S07 conservés, avec un test qui tape le détail puis Retour.
10. Constats 12, 13, 14 : lien vers les mouvements de la séance, « Recharger » dans la fiche, garde de `_verifier`.
11. Constats 15, 16, 17 : au choix de LT-F, sinon à consigner comme dette.

# FI-VAGUE-CORR : corrections de la revue FI-VAGUE-R

Session C-2026-10-04-cloud-01MrLWqB, 2026-10-05.
Rapport source : `docs/revues/REVUE_FI-VAGUE-R.md` (branche `revues/2026-10-04-01MrLWqB` @ a343e9db). Il compte 0 bloquant, 22 majeurs, 24 mineurs et 11 cosmétiques. Sa section « Suivi proposé / FI-VAGUE-CORR » liste 48 points.

## Branche

| Élément | Valeur |
|---|---|
| Base | `ui/finance-v1` @ 5198107f |
| Travail | `fi-corr/a` (Foyer, fiche, recharge, transverse), puis fusion de `fi-corr/b` (accès, adulte, enseignant, direction), puis `fi-corr/c` (restes de l'audit et contre-revues) |
| Tête livrée | `fi-corr/c` @ 728c34c5, avancée en avance rapide sur `ui/finance-v1` |
| Volume | 23 commits, 100 fichiers, +9316 / −1858 |
| Hors périmètre, vérifié | `git diff 5198107f..HEAD -- lib/core/theme pubspec.yaml supabase .github` est vide |

## Mesures (chiffres, pas appréciations)

- `dart analyze --fatal-infos` : No issues found (sur 728c34c5).
- `dart run tool/verifier_jetons.dart` : 39, le même chiffre que la revue. Les deux lignes situées dans des fichiers touchés sont antérieures à la vague (blame du 26/09 et du 27/09).
- Suite complète sur cb50a32f, dossier par dossier (script reprenable) : 67 dossiers, tous à exit=0, plus la racine `test/` à exit=0.
- Rejeu final sur 728c34c5 des dossiers touchés après cb50a32f, tous exit=0 et « All tests passed! » : foyer +520 ~37, mon_espace_adulte +111, finance_recette +73 ~567, finance +47, admin_finance +90, revenus_enseignant +44, demo +106 ~10, acces_finance +71, test/router +279, test/widgets +234. Total : 1575 passés, 0 échec.
- Mutations : chaque commit de correction a été contre-revu par un agent à contexte neuf, et les preuves de mutation sont décrites dans les messages de commit. Dernière preuve en date : avec `enLigne = place`, les tests 1200 et 1280 de la recharge échouent (« Solde actuel : 12 $ » sur 3 lignes), et 1440 passe.

## Points du suivi : état et preuve

L'audit a été fait en lecture seule sur cb50a32f, puis complété par 29196608, 7971c4e4 et 728c34c5. Abréviations des fichiers de test, tous sous `test/features/` :

- ff = `foyer/foyer_finances_test.dart`
- fb = `foyer/foyer_bureau_test.dart`
- fef = `foyer/fiche_eleve_finances_test.dart`
- fem = `foyer/fiche_eleve_mouvements_test.dart`
- rmp = `foyer/recharge_multi_profils_test.dart`
- rr = `foyer/resultat_recharge_test.dart`
- af = `acces_finance/acces_finance_test.dart`
- re = `revenus_enseignant/revenus_enseignant_test.dart`

| # | Constat | État | Preuve |
|---|---|---|---|
| 1 | R1-01 | Fait. Le cas sans source attend Q-FI-2 (question 1). | ff « un seul bouton plein » (390 et 1440), ff « sans source (production) » |
| 2 | R1-03 | Fait | ff « 1440 (FI-5, R1-03) : quatre blocs » |
| 3 | R1-04 | Fait | fb « 768 (tablette, R1-04) : cartes en deux colonnes » |
| 4 | R1-05 | Fait | `lib/core/finance/periode_a_financer.dart`, ff « a regulariser (R1-05) » |
| 5 | R1-06 | Fait | `SoldesFoyerSection` n'est plus posé nulle part. `paiements_foyer_adulte_test` (E-11, FI-5b, R1-06) |
| 6 | R1-08 | Fait | ff « Voir le détail (R1-08) » |
| 7 | R1-02 | Fait. Q-FI-8 n'a pas de réponse, donc le choix par défaut (mois courant) est écrit. | fb « Vue financière du foyer sur le mois courant » |
| 8 | R1-07, R1-12 | Fait. X-12 reste à confirmer. | fb « Voir tout vers l'historique du foyer » |
| 9 | R1-09 | Partiel | Les libellés sont faits. « Enfants du foyer » pour un titulaire adulte attend la question 3. |
| 10 | R1-11 | Fait | ff « une seule date d'échéance par carte », `ligne_membre_test` |
| 11 | R1-13 | Reporté (question 5) | Seul le commentaire de démo est corrigé. |
| 12 | R1-10 | Fait | ff « Recharger Ibrahim » (nom lu) |
| 13 | R2-01 | Fait | fef « R2-01 : 1440, trois colonnes », fil d'Ariane |
| 14 | R2-02 | Fait | fef « R2-02 : Général ramène à la fiche » |
| 15 | R2-03 | Fait. Le texte est soumis au directeur (voir les restes). | fef « R2-03 et R2-04 : 390 » |
| 16 | R2-04 | Partiel | L'ordre bouton puis lien à 8 px est prouvé. « Télécharger le reçu » attend la question 7. |
| 17 | R2-05 | Fait | fem : icône par nature, heure, avatar du filtre |
| 18 | R2-06 | Fait | fef « R2-06 : période financée une seule fois » |
| 19 | R2-07 | Fait | fef, cas 2 et 3 du lot F3 (`rang`) |
| 20 | R3-01 | Fait | rmp : une seule page, pas de « Tout sélectionner », réponse dépassée ignorée. « Payer {total rendu par le port} » est prouvé par `_PortRemise` (29196608). |
| 21 | R3-02 | Fait | rmp « 1200, 1280 et 1440 : colonnes, note dans le récapitulatif, bandeau sans croix » (7971c4e4, 728c34c5) |
| 22 | R3-03 | Fait | rr « les huit états » (marges) |
| 23 | R3-04 | Fait | rr : coche « Crédité » et « + » à `termine` seulement |
| 24 | R3-05 | Fait | fr « Paiement par le web. Aucun débit avant votre confirmation. » |
| 25 | R3-06 | Fait | rr |
| 26 | R4-04 | Fait | af, groupe « R4-04 : place libérée et réactivation » |
| 27 | R4-01 | Fait | `rejoindreSelonAcces` sur 4 écrans, af et `accueil_adulte_page_test` |
| 28 | R4-02 | Fait | af « R4-02 : foyer fermé, le sien ouvert », relu au changement de session |
| 29 | R4-03 | Reporté (question 12) | Comportement gardé |
| 30 | R4-07 | Fait | af |
| 31 | R4-05, R4-06 | Fait | af (`autoDispose`), rmp (un seul bénéficiaire au singulier) |
| 32 | R4-08 | Partiel | `deDevant` est fait pour la Finance. Il reste 57 chaînes « de {prenom} » hors Finance : le rapport ne dit pas si elles sont dans le périmètre. |
| 33 | R5-02 | Fait | re « 1440 : tableau compact, type par Classe, ligne de total » |
| 34 | R5-03 | Fait | Relevé au port (FI-BR-11), indisponible en démo comme en production. La démo enseignant surcharge `releveEnseignantProvider` (7971c4e4). |
| 35 | R5-01 | Fait | re : essai, absent, remplacement |
| 36 | R5-04, R5-05, R5-06 | Partiel | R5-06 et le taux moyen de R5-05 sont faits. Le sélecteur de mois attend la question 18. R5-04 attend Q-FI-10. |
| 37 | R5-08 | Fait | re (`valeurEnFin`) |
| 38 | R6-01 | Fait | `vue_globale_finance_test` : un graphique par notion, un seul mois de démo (aucun historique inventé) |
| 39 | R6-04 | Fait | « R6-04 : chaque alerte a un seul lien » |
| 40 | R6-05 | Fait | « R6-05 : Classes partout » |
| 41 | R6-06 | Fait. L'édition en brouillon attend la question 21. | trois tests R6-06, `BudgetPilotage.pourMille` en entier |
| 42 | R6-02, R6-03, R6-08 | Reporté (directeur) | Aucun changement |
| 43 | R8-02 | Fait | `test/widgets/page_shell_coupure_test.dart` |
| 44 | R6-10 | Fait | « R6-10 : Publier la version » |
| 45 | R8-03 | Fait | `finance_recette/mots_coupes_fi_test.dart` : 32 cas, vraies polices, 320 px à 200 %. La barre basse est exclue (R5-07/R8-01, hors vague). |
| 46 | R7-04 | Fait, étendu | `surveillerPersonneConnectee` sur les lectures Foyer, adulte et enseignant, et sur la vue globale et les politiques de la direction (29196608). `finance/lectures_session_test.dart` |
| 47 | R7-07, R8-05, R2-08 | Fait | Les ports neutres rendent `FI-BR-xx`, « 1er », fem (R2-08) |
| 48 | Captures | Fait | 45 captures ci-dessous |

Total : 37 points faits, 4 partiels (9, 16, 32, 36) et 3 reportés au directeur (11, 29, 42). Les 4 autres points sont faits, avec une question au directeur encore ouverte dessus (1, 7, 15, 41).

## Infractions aux règles du dépôt

Aucune n'a été trouvée sur le diff :

- argent en entier ;
- aucune lecture de rôle ajoutée (`carte_session.dart:215` est antérieure et seulement ré-indentée) ;
- aucune chaîne en dur ;
- aucune valeur visuelle inventée ;
- tous les ports de production rendent `CapaciteIndisponible('FI-BR-xx')`.

## Captures

Elles sont dans `captures/FI-VAGUE-CORR/` (45 PNG). Les tailles sont 1440 clair, 390 sombre et 390 clair à 200 %, plus 768 et 1024 pour le Foyer.

- Écrans couverts : Foyer, fiche Finances, Mouvements, Recharge, Résultat, accès sur la fiche et sur l'enfant, paiements de l'adulte, Revenus de l'enseignant, vue globale et politiques de la direction.
- Les captures de la recharge et des revenus ont été refaites après 7971c4e4.
- Les largeurs 1200 et 1280 de la recharge sont couvertes par un test, pas par une capture.

## Questions au directeur encore ouvertes

| Question | Ce qui en dépend |
|---|---|
| question 1, Q-FI-2 | Le Foyer sans source de paiement |
| question 3 | Le libellé du titulaire adulte |
| question 5 | La marque par montant (R1-13) |
| question 7 | « Télécharger le reçu » : état honnête (FI-BR-05) ou retrait écrit |
| question 12 | R4-03 |
| question 18 | Le sélecteur de mois des revenus |
| question 21 | L'édition des politiques en brouillon |
| Q-FI-8 | Le défaut « mois courant » de la vue financière |
| Q-FI-10 | « Mes revenus » |
| X-12 | À confirmer |
| R6-02, R6-03, R6-08 | Tranchés par le directeur |
| R4-08 hors Finance | Les 57 chaînes sont-elles dans le périmètre ? |

## Restes relevés, hors des points du rapport

- La note R2-03 renvoie à « l'onglet Historique », qui n'existe pas sur la fiche (fr:1166). Le texte est laissé au directeur.
- « Ouvrir les classes » (fr:1788) mène à une page titrée « Groupes ». C'est un écart de vocabulaire hors Finance.
- `SoldesFoyerSection` n'est plus posé mais reste là avec ses tests. Son retrait est renvoyé à une vague ultérieure.
- Des commentaires de démo citent encore EA-BR-24 et EA-BR-25 (`adulte_demo.dart`, `demo_adulte_page.dart`).
- La barre basse coupe ses mots à 200 % (R5-07/R8-01), et R8-04 et R7-05 restent ouverts. Ces points sont hors de la vague.

## Priorités pour la revue FI-VAGUE-CORR-R

Elle doit être faite par une autre session, en VERIF.

1. La recharge en 3 tailles de bureau (1200, 1280, 1440) et sur mobile à 200 % : colonnes, note, bandeau, « Payer {total rendu} ».
2. L'accès borné à la session (R4-02, R7-04) : changer de personne connectée et vérifier que chaque lecture d'argent est relue.
3. La fiche Finances à 1440 (trois colonnes) et sous 1200 (onglets).
4. La direction : un mois de démo seulement, aucun historique inventé, alertes à un seul lien.
5. La production honnête : chaque port Finance rend FI-BR-xx, y compris le relevé de l'enseignant en démo.
6. Les partiels 9, 16, 32 et 36 : confirmer qu'ils sont bien bloqués par une question, et pas oubliés.

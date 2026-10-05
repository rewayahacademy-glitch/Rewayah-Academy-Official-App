<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Relecture adverse : ALERTE-1 (branche corrections/c2-alerte, d387e91a)

## Verdict : ACCEPTEE_AVEC_RESERVES

Je n'ai trouvé aucun défaut majeur. La partie client demandée pour cette étape est livrée et prouvée. La partie serveur est consignée, comme l'a ordonné le directeur le 04/10. Il reste quatre réserves mineures : trois tests qui ne gardent pas ce qu'ils annoncent, et des captures manquantes.

Ce que j'ai examiné : les trois commits 1ba28df4, b1b67c9b et d387e91a, soit 42 fichiers. J'ai travaillé dans un worktree jetable détaché, plus un second pour les mutations. Les deux ont été retirés à la fin. Je n'ai rien poussé.

## Ce que j'ai vérifié par preuves

### Outils
| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | aucun problème |
| `tool/verifier_jetons.dart` | 39 violations, identique à la base (parent de 1ba28df4) ; sortie comparée ligne à ligne |
| `tool/verifier_revue.dart` | 1568 violations, identique à la base ; sortie identique |
| Tests des dossiers touchés (`test/core/alertes`, `test/features/alertes`, `tableau_de_bord_test`, `admin_shell_test`) | 89 sur 89 passent |
| Non-régression large (`test/widgets`, `test/features`, `test/core`, `--concurrency=2`) | 3820 passent, 2126 ignorés, 0 échec |

### Fiche
La fiche est dans `DASH_STRATEGIE.md` :
- §3.9 : décision datée du 05/10, déléguée par le directeur, avec les trois gravités définies et des exemples, et les règles A1 à A6.
- §3.1 : la section Alertes d'ADM-01.
- Annexe A : fiches ADM-ALERTES et ADM-BANDEAU-URGENT.
- §5 bis : besoins serveur DASH-BR-03 (gravité, tri, RLS), BR-04 (Realtime par profil), BR-05 (Web Push avec VAPID côté serveur, abonnements par appareil, puis natif) et BR-06 (délai mesuré, objectif proposé de moins de 5 s).

Tout ce que la demande exige est présent.

### Code
- **Tri.** `trierAlertes` trie par gravité, puis de la plus récente à la plus ancienne, puis par identifiant. Il est appliqué au flux, donc une alerte qui arrive en queue est quand même retriée.
- **Port neutre.** En production, il rend `CapaciteIndisponible('DASH-BR-03')` : la page affiche « indisponible », jamais une liste vide. La démonstration ne s'active qu'avec `avecAlertes` (seulement dans `main.dart`, sous la garde de la démo). La minuterie de démonstration est annulée avec le flux.
- **Capacité, jamais un rôle.** `alertesUrgentesProvider` vaut `null` tant que la source ne rend rien. Sans capacité, ni cloche ni bandeau (Q5 respecté en production).
- **Centre de commande.** La section passe au-dessus des tuiles dès qu'une alerte urgente est ouverte, et suit les tuiles sinon. Toutes les urgentes s'affichent, jamais plafonnées à 3, puis « Voir toutes les alertes » s'il en reste.
- **Bandeau.** Il est posé par `PageShell`, au-dessus du titre, sur les 17 autres pages admin : j'ai vérifié qu'elles passent toutes par `PageShell`. Il ne s'affiche pas sous l'Accueil (règle D7). Quand il est présent, la tête de page défile avec le corps, ce qui garde la vue utilisable à 320 x 640.
- **Hors ligne (K-42).** Le bandeau de `PageShell` est le seul signal ; une liste déjà lue reste affichée.

### Mutations (chacune annulée après le test)
| Mutation | Résultat |
|---|---|
| M1 : gravité ignorée dans le tri | échec, tests rouges |
| M2 : date inversée | échec (trierAlertes A1) |
| M3 : section jamais en tête | échec |
| M4 : bandeau retiré de la tête de `PageShell` | échec |
| M5b : cloche toujours absente | 2 échecs |
| M6 : production rend une liste vide | échecs |
| M7 : `Text` au lieu de `TexteSansCoupure` dans LigneAlerte | échec (320 x2 RTL) |
| M8 : bandeau aussi sous l'Accueil | échec |
| M10 : urgentes plafonnées à 3 | 2 échecs |
| M11 : phrase calme qui ignore les alertes | 7 échecs |
| M14 : trait d'union insécable retiré des titres | 5 échecs |
| **M9 : point de la cloche à 0** | **survit**, 80 sur 80 passent |
| **M12 : `Text` au lieu de `TexteSansCoupure` dans SignalRow** | **survit** |
| **M13 : liveRegion à false sur le bandeau** | **survit** |

### Captures ouvertes et relues
- `coque_390` et `coque_1440` : bandeau rose en tête, au-dessus du titre ; point visible sur la cloche.
- `coque_320x2` : bandeau sans mot coupé ; il occupe une grande partie de la hauteur, mais il défile avec le reste.
- `tableau_390_clair` : section Alertes en tête, urgente d'abord alors qu'elle n'est pas la plus récente, puis les tuiles.
- `tableau_320x2_clair_rtl` : aucun mot coupé, sens RTL respecté.
- `page_320x2_sombre` : ordre urgente, importante, importante, information ; aucun mot coupé.

Sur les captures RTL, des points apparaissent en début de phrase (« .ancien en premier »). C'est l'effet du texte français affiché de droite à gauche, et il existe déjà ailleurs : ce lot ne l'introduit pas.

## Réserves (mineures, à lever sans bloquer la fusion de la branche)
1. Ajouter un test sur le point de la cloche (sa présence, ou la valeur de `nonLues`), car la mutation M9 survit. Ce point est une exigence explicite de la demande.
2. Rendre discriminant le test « bandeau à 320 x2 sans mot coupé » : utiliser un titre dont un mot dépasse la largeur disponible, pour que la mutation M12 échoue.
3. Vérifier par test que le bandeau est bien une région vivante, car la mutation M13 survit.
4. Ajouter les captures de la coque en sombre et en RTL, et une capture en Interface guidée.

## Reste hors étape (consigné, non fait)
La demande ALERTE-1 n'est remplie que pour sa partie client. Le temps réel Supabase, le push avec l'application fermée (Web Push puis natif), la colonne `gravite` côté base et la mesure réelle du délai attendent BR-1 (DASH-BR-03 à 06). L'objectif de délai de moins de 5 s reste à confirmer par le directeur.

Statuts : **spécifié** et **présent dans le code**, **testé localement** (client) ; non testé sur staging, non déployé.

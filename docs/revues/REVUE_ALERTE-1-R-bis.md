<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Relecture adverse ALERTE-1 (partie client) — `corrections/c2-alerte` @ d387e91a

**Verdict : ACCEPTEE_AVEC_RESERVES.** Je n'ai trouvé aucun défaut majeur. La partie client demandée est faite et prouvée. Il reste quatre réserves mineures, détaillées plus bas. La partie serveur est seulement consignée, comme l'ordre l'exige : Realtime, Web Push, colonne gravité et mesure du délai (DASH-BR-03 à 06).

Revue faite en lecture seule, dans un worktree détaché, retiré à la fin, avec un second worktree pour les mutations, retiré lui aussi. Je n'ai rien poussé.

## Périmètre relu
- 3 commits : 1ba28df4, b1b67c9b et d387e91a.
- 42 fichiers. Rien n'est touché dans `supabase/`, `.github/`, `pubspec.yaml`, le thème ou le rendu du Coran.

## Mesures refaites par moi
| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | aucun problème |
| `tool/verifier_revue.dart` | 1568, égal à la base HEAD~3 que j'ai mesurée moi-même |
| `tool/verifier_jetons.dart` | 39, égal à la base HEAD~3 |
| `flutter test --concurrency=2` sur test/core/alertes, test/features/alertes, tableau_de_bord_test et admin_shell_test | 89 réussis |
| Régression `flutter test --concurrency=2 test/widgets test/features test/core` (appelants de PageShell, AdminShell, ClocheNotifications et SignalRow) | **3820 réussis, 2126 ignorés, 0 échec** |

## Conformité à la demande
- **Fiche avant le code.** DASH_STRATEGIE.md contient :
  - le §3.9 avec la décision du 05/10 déléguée par le directeur (urgente, importante, pour information, avec définitions et exemples) et les règles A1 à A6 ;
  - la section Alertes de ADM-01 au §3.1 ;
  - les fiches ADM-ALERTES et ADM-BANDEAU-URGENT ;
  - la ligne ALERTE-1 au §5 ;
  - DASH-BR-03 à 06 au §5 bis, qui consignent bien la colonne gravité, Realtime par profil sous RLS, Web Push avec VAPID côté serveur puis natif, et l'horodatage serveur pour la mesure.
  - L'objectif de moins de 5 s est proposé et reste « à confirmer ».
- **Tri gravité, puis date, puis identifiant.** `trierAlertes` le fait. `alertesProvider` retrie à chaque émission du flux.
- **Une urgente toujours en tête.**
  - Sur le Centre de commande, la section passe au-dessus des tuiles. Je l'ai vu sur la capture `alerte1_tableau_390_clair`.
  - `alertesDuTableau` montre toutes les urgentes, et « Voir toutes les alertes » s'affiche quand il en reste.
  - Sur la page `/admin/alertes`, l'urgente vient en premier. Je l'ai vu en sombre à 1440.
- **Bandeau en haut de l'écran ouvert.**
  - Il est au-dessus du titre de la page : je l'ai vu sur les captures de la coque à 390, 1440 et 320 x2.
  - Il apparaît sans recharger quand l'alerte arrive : c'est testé avec l'arrivée simulée à 20 s.
  - Il n'apparaît pas sous l'Accueil (D7).
- **Cloche.** Elle porte un point et le libellé « Alertes, une urgente », sur les trois formes de la coquille.
- **Capacité, jamais un rôle.** `alertesUrgentesProvider` vaut null tant que la source ne rend rien. En production, le port est `AlertesIndisponibles` (`CapaciteIndisponible('DASH-BR-03')`) : il n'y a alors ni cloche ni bandeau, et la section affiche « indisponible » sans « Réessayer ». Aucun faux contenu.
- **Démonstration.** Les 4 alertes de démo sont activées seulement par `main.dart`, sous la garde `surchargesDemoAdmin`, qui lève une erreur en production. La minuterie est annulée quand on quitte le flux.
- **Cinq états.**
  - Chargement : squelette.
  - Contenu.
  - Vide.
  - Erreur, avec un « Réessayer » qui relit.
  - Hors ligne selon K-42 : `expectHorsLigneUneFois`, et une liste déjà lue reste affichée.

## Contre-épreuves (mutations refaites par moi, chacune annulée)
| Mutation | Résultat |
|---|---|
| M2 : section toujours après les tuiles | 2 échecs |
| M7 : bandeau posé sous le titre dans PageShell | 1 échec |
| M8 : coquille en `ref.read` (bandeau et cloche figés à l'arrivée) | 3 échecs |
| M9 : bandeau aussi sous l'Accueil (D7 retiré) | 1 échec |
| M10 : `titreAffiche` sans trait d'union insécable | 5 échecs (aucun mot coupé à 320 x2) |
| M11 : `TexteSansCoupure` remis en `Text` dans SignalRow | **0 échec**, voir la réserve 1 |

Les mutations M1 et M3 à M6 annoncées par le rédacteur sont cohérentes avec les tests que j'ai lus.

## Captures ouvertes
J'ai ouvert : `coque_390`, `coque_1440`, `coque_320x2`, `tableau_390_clair`, `tableau_320x2_clair_rtl` et `page_1440_sombre`.
- Aucun mot coupé dans les éléments ALERTE-1. Les titres composés comme « An-Nour » et « Al-Falaq » restent entiers.
- La gravité est toujours écrite, pas dite par la seule couleur.
- Les teintes sont douces, et je n'ai vu aucun bouton grisé.
- Dans la capture RTL, le point qui passe à gauche des phrases françaises vient des tuiles existantes : ce n'est pas un défaut de ce lot.

## Réserves (mineures, non bloquantes)
1. **SignalRow, composant partagé.** Le passage à `TexteSansCoupure` n'est prouvé par aucun test : la mutation M11 ne casse rien. Il faut un test où `Text` coupe réellement un mot et où `TexteSansCoupure` l'empêche.
2. **Bandeau sans RTL, coque sans sombre.** Le bandeau n'a ni capture ni test en RTL, et la coque n'a aucune capture en sombre.
3. **Interface guidée sans capture.** Ce mode est couvert par les tests 320 x2, mais par aucune capture.
4. **Choix de mise en page à confirmer par le directeur.** Tant qu'une urgente est ouverte, le titre de toutes les pages admin défile avec le contenu. Le bandeau peut donc sortir de la vue au défilement, alors que la cloche reste visible.

## Reste hors de cette étape (consigné, normal)
DASH-BR-03 à 06 : gravité côté serveur, Realtime, Web Push puis natif, et mesure du délai. La validation de l'objectif de 5 s et de la liste des gravités revient au directeur.
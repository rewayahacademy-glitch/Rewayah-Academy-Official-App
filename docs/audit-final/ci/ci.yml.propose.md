# Modifications proposees pour `.github/workflows/` (lot L1-09, arbitrage A-10)

Document, pas du code : seul le directeur peut poser ces blocs dans `.github/`. Rien n'a ete execute contre GitHub. Les mesures citees viennent d'un rejeu local sur PostgreSQL 17 neuf, avec le stub de `supabase/tests/stub_auth.sql` modifie par ce lot.

Mesures qui fondent les blocs :

- 199 migrations rejouees sans erreur sous le nouveau stub.
- Les 15 scenarios de `ci.yml`, dans l'ordre, sur une meme base : 15 PASS.
- Les 60 autres scenarios (59 anciens plus `scenarios_af_liste_blanche_volatiles.sql`), chacun sur sa propre copie de la base migree : 60 PASS.
- Les 75 fichiers enchaines sur UNE SEULE base : 5 echecs (`b09_notifications`, `b15_assignations_annotations`, `c29_mission_engine`, `contrats_remplacements`, `imm_back_1_registrations`), 7 sur l'ancien stub. Ce sont des etats partages, pas des defauts de droits. D'ou le bloc (a) : une base neuve par scenario hors CI, et jamais la boucle a base unique.

## (a) `.github/workflows/ci.yml`, job `migrate-check`

Les 15 scenarios actuels restent tels quels, dans leur ordre, sur la base `postgres` (le commentaire de la ligne 160, `hook_jeton` apres `etape3`, et celui de `adm04` en dernier restent vrais). Deux ajouts.

1. Une etape qui fige un gabarit, a coller juste apres l'etape « Stub les roles et les fonctions Supabase, puis applique les migrations » et AVANT « Scenarios d'acceptation SQL des etapes 1 et 3 » (le gabarit doit etre pris avant que les 15 scenarios ecrivent dans `postgres`) :

```yaml
      # Gabarit des scenarios hors suite : la base migree, avant tout scenario.
      # `create database ... template` exige qu'aucune autre session ne soit
      # ouverte sur la source ; aucune ne l'est a ce stade.
      - name: Fige le gabarit de base migree
        shell: bash
        run: psql -h postgres -U postgres -v ON_ERROR_STOP=1 -c "create database gabarit template postgres"
```

2. Une etape finale, a coller apres « Scenarios negatifs B-18 (SECURITY DEFINER) » (derniere etape du job, avant `edge-r2:` ligne 205) :

```yaml
      # Tous les scenarios que la suite ci-dessus ne rejoue pas (60 au
      # 16/10/2026), chacun sur une copie neuve du gabarit : enchaines sur une
      # seule base, 5 d'entre eux echouent par etat partage, sans defaut de
      # droits. Un fichier ajoute dans supabase/tests/ est rejoue sans toucher
      # ce fichier.
      - name: Scenarios SQL hors suite (une base neuve chacun)
        shell: bash
        run: |
          suite=" etape3 c21_kyc_access_verdict etape4 etape5 adm05 n2 n4 n5 ctr01 agt01 hook_jeton r2 c35_library_read adm04 b18_security_definer "
          echec=0
          n=0
          for f in supabase/tests/scenarios_*.sql; do
            nom=$(basename "$f" .sql); nom=${nom#scenarios_}
            case "$suite" in *" $nom "*) continue;; esac
            n=$((n+1))
            psql -h postgres -U postgres -q -c "drop database if exists courant" -c "create database courant template gabarit"
            if ! psql -h postgres -U postgres -d courant -v ON_ERROR_STOP=1 -q -f "$f" > /tmp/scenario.log 2>&1; then
              echo "--- ECHEC $f"; tail -20 /tmp/scenario.log; echec=$((echec+1))
            fi
          done
          echo "$n scenarios hors suite, $echec en echec"
          [ "$echec" -eq 0 ]
```

Attendu avec le depot au 16/10/2026 : « 60 scenarios hors suite, 0 en echec ». Le scenario `scenarios_af_liste_blanche_volatiles.sql` est dans ce lot de 60 ; il suppose le nouveau stub, donc ce bloc ne se pose qu'apres le merge de L1-09.

## (b) `.github/workflows/ci.yml`, job `flutter`, ligne 278

Remplacer la ligne `if:` et le commentaire de la ligne 277 :

```yaml
  flutter:
    # Toute PR vers une branche de livraison execute le build Flutter, y compris
    # les PR backend : un changement de contrat SQL peut casser un adaptateur.
    if: github.event_name != 'pull_request' || github.base_ref == 'main' || github.base_ref == 'ccr-1b1bfa0b-m1kvkk' || github.base_ref == 'claude/backend-reprise'
```

Pour que le workflow se declenche sur ces PR, le bloc `on.pull_request.branches` (lignes 7 a 9) doit aussi contenir la branche :

```yaml
  pull_request:
    branches: [main, 'ccr-1b1bfa0b-m1kvkk', 'claude/backend-reprise', 'ui/**']
```

Sans cette seconde modification, la premiere ne sert a rien. Les jobs `migrate-check` (ligne 17) et `edge-r2` (ligne 207) ont le meme `if:` : y ajouter `|| github.base_ref == 'claude/backend-reprise'`, sinon une PR backend n'a aucun scenario.

## (c) `.github/workflows/deploy.yml`

Les jobs de ce fichier sont `fonctions` (« Edge Functions », ligne 43) et `migrations` (« Migrations (manuel uniquement) », ligne 94). `needs:` ne traverse pas les fichiers : `needs: [migrations, flutter]` n'est pas ecrivable tel quel, car `flutter` vit dans `ci.yml` et `migrations` est un job de `deploy.yml` lui-meme (manuel, apres le deploiement des fonctions, pas avant). Ce qui tient : un job `ci-verte` qui interroge l'API de GitHub, et dont dependent les deux jobs existants.

A coller sous `jobs:` (ligne 42), avant `fonctions:` :

```yaml
  ci-verte:
    name: La CI est verte sur ce commit
    runs-on: ubuntu-latest
    permissions:
      checks: read
      contents: read
    steps:
      - name: Exige les contrôles de CI en succes sur le commit deploye
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          attendus=("Migrations applicables (Postgres 17)" "Fonctions Edge -- stockage R2 (Deno)" "Flutter (web)" "Flutter (apk)" "Flutter (windows)")
          for tentative in $(seq 1 30); do
            runs=$(gh api "repos/$GITHUB_REPOSITORY/commits/$GITHUB_SHA/check-runs?per_page=100" --jq '.check_runs')
            manque=0
            for nom in "${attendus[@]}"; do
              etat=$(echo "$runs" | jq -r --arg n "$nom" '[.[] | select(.name==$n)] | sort_by(.started_at) | last | .conclusion // "absent"')
              case "$etat" in
                success) ;;
                absent|null) manque=1 ;;
                *) echo "ECHEC : $nom = $etat"; exit 1 ;;
              esac
            done
            [ "$manque" -eq 0 ] && { echo "CI verte sur $GITHUB_SHA"; exit 0; }
            sleep 60
          done
          echo "Aucun resultat de CI complet pour $GITHUB_SHA apres 30 minutes."
          exit 1
```

Puis ajouter `needs: [ci-verte]` aux deux jobs existants :

```yaml
  fonctions:
    name: Edge Functions
    needs: [ci-verte]
    runs-on: ubuntu-latest
```

```yaml
  migrations:
    name: Migrations (manuel uniquement)
    needs: [ci-verte]
    if: github.event_name == 'workflow_dispatch' && inputs.appliquer_les_migrations
    runs-on: ubuntu-latest
```

Precautions a lire avant de coller : (1) `ci.yml` ne se declenche que sur `pull_request` et `workflow_dispatch`, pas sur `push` : un commit de fusion sur `main` n'a des check-runs que si la fusion garde le SHA de la tete de PR (fusion « fast-forward » ou « rebase »). Avec une fusion « squash » ou « merge commit », le SHA de `main` n'a aucun check-run et `ci-verte` echouerait. Dans ce cas, ajouter `push: branches: [main]` au bloc `on:` de `ci.yml`. (2) Les noms des contrôles sont ceux des `name:` de `ci.yml` (lignes 14, 206, 279) ; les changer casse `ci-verte`. (3) `flutter-deploy.yml` a son propre job `deploy` (ligne 49) : meme `needs`, meme job `ci-verte` a recopier si le directeur veut la meme garantie pour le Web.

## (d) `.github/workflows/ci.yml`, etape « Aucun secret R2 versionne », ligne 268

Deux empreintes SHA-256 legitimes tombent sous la garde des 64 hexadecimaux. Chemins reels, relus au 16/10/2026 (la fiche citait `supabase/functions/bibliotheque-upload/bibliotheque_upload_test.ts`, qui n'existe pas) :

- `supabase/functions/_shared/r2/bibliotheque_upload_test.ts`, ligne 43 : `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad` (SHA-256 de « abc », vecteur de test connu).
- `supabase/migrations/20261011072525_f70_review_insert_acl_and_hash.sql`, ligne 36 : `5114057583bd85a0988876867b752b63ff5f621c9e4784e61e7cb93168bb27df`.

Remplacer le bloc des lignes 268 a 272 par une liste blanche par valeur (pas par fichier : un secret ajoute dans l'un de ces deux fichiers serait vu) :

```yaml
          # Empreintes de test, pas des secrets : un SHA-256 de vecteur connu et
          # l'empreinte d'une fixture de migration. Liste blanche par VALEUR.
          if git grep -nIE '\b[0-9a-f]{64}\b' -- \
             supabase/functions supabase/migrations docs/architecture \
             | grep -v -e 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad' \
                       -e '5114057583bd85a0988876867b752b63ff5f621c9e4784e61e7cb93168bb27df' ; then
            echo "Une chaine de 64 caracteres hexadecimaux ressemble a un secret R2."
            exit 1
          fi
```

Semantique, verifiee en local : `if` reussit seulement s'il reste une correspondance hors liste blanche. Sans correspondance du tout, `git grep` rend 1 ; si tout est filtre, `grep -v` rend 1 ; dans les deux cas le pipeline rend 1 (pipefail est actif sous `shell: bash`) et la garde ne se declenche pas. A rejouer sur une PR de test avant de s'y fier.

# CANDIDATURES · Correctifs hors module proposés (`CAND-Q15`)

Statut : **proposition, rien n'est appliqué**. Aucun fichier de `supabase/`, de
`lib/` ou de `test/` n'a été modifié pour ce document.

Ce document détaille les cinq défauts que la revue a trouvés en dehors du module
(`REVUE_CRITIQUE_CANDIDATURES_2026-10-21.md`, section 3.2). Il les expose pour
que le directeur puisse répondre à `CAND-Q15` en connaissance de cause.

**Comment il a été établi.**
- Base : lecture seule de la pointe de la pile (`claude/youthful-davinci-raugwe`,
  commit `9cf88561` du 21/10).
- Une analyse par défaut, puis une relecture critique indépendante des cinq
  propositions. Ses corrections sont intégrées ci-dessous et signalées
  « (relecture) ».
- Les citations les plus lourdes ont été revérifiées à la main. Par exemple :
  - `0079_c11bis_admin_wrappers.sql:126-129` ;
  - `scenarios_etape3.sql:640` ;
  - `format_montant.dart:36-39` ;
  - `x2_17_treasury_triggers.sql:142-144` ;
  - les deux branches `:299` et `:403` de `20261011121958`.
- **Rien n'a été rejoué** : ni migration, ni scénario, ni test Flutter.
- **Aucune base distante n'a été lue.**

Tout chiffre de production ci-dessous est donc « non mesuré ». Chaque lot fournit
la requête de mesure en lecture seule à faire passer par l'opérateur.

## 0. En bref

| Lot | Défaut | Aujourd'hui | Bloque | Décision attendue |
| :--- | :--- | :--- | :--- | :--- |
| **langue** | La langue de l'enseignant est enregistrée par son **nom** (« Français ») et comparée à un **code** (`francais`) | Latent : masqué par le lot `c11bis` | Toute affectation à une classe issue d'un regroupement, dès que `c11bis` est réparé | Enregistrer par code (recommandé) ; code d'une langue ajoutée au référentiel |
| **c11bis** | `affecter_enseignant_classe_c11bis` lève toujours une erreur : aucune classe **en attente d'enseignant** ne peut en recevoir un | Bloquant | Les classes nées d'un regroupement : pas de séance, pas de notification, familles arrêtées à « classe validée » | Aucune sur le principe (les décisions du 09/10 et du 10/10 exigent l'affectation) |
| **creer_groupe** | `creer_groupe` pose un enseignant sur une classe active sans vérifier pièce d'identité, accès, genre, plafond ni collisions | Actif : seul chemin qui écrit `groupes.teacher_id` | Rien, au contraire : il laisse passer | Prédicat strict ou règles D3 et D4 de `UX_REVIEW_CLASSE-FORM-1.md` |
| **gnf** | Le franc guinéen a 0 décimale côté client et 2 côté serveur : la trésorerie le divise par 100 | Latent : aucun taux GNF vers USD n'existe | Trésorerie et paie en GNF dès qu'un taux est saisi | Table ISO complète ; liste fermée des devises acceptées (facultatif) |
| **conduite** | Le code de conduite validé le 19/10 n'est exigé par aucune garde serveur | Latent : les migrations PE ne sont pas appliquées à distance (d'après `08:94`) | Rien, au contraire : un enseignant peut recevoir des élèves sans l'avoir accepté | Signature sur `/attente/accords` avant l'activation (recommandé) |

Lien avec le module : l'écran « Prêts à être affectés » n'a de chemin serveur
fiable qu'avec **langue** et **c11bis**. **conduite** fait partie des contrôles
`accords_signes` du modèle (revue, section 6). La sorte d'accord de l'engagement
religieux (`CAND-BR-11`) étend la même garde après ce lot.

## 1. Ce que chaque lot attend avant d'exister

1. **`CAND-Q15`** : le feu vert du directeur sur ce découpage.
2. **Autorisation explicite pour `supabase/`.**
   - La phase est « frontend only » (spécification, section 1.2) : aucune
     migration, RLS ni RPC sans autorisation explicite.
   - `supabase/` n'est pas dans la liste du garde-fou (`.claude/hooks/garde.py:22-27`) :
     c'est la phase qui l'impose, pas le garde-fou.
   - La réponse à `CAND-Q15` doit donc dire si elle couvre `supabase/migrations`
     et `supabase/tests`.
3. **Contrat commun.** Toucher un port existant (`port_*.dart`) demande une ligne
   dans l'onglet Contrats et la mention « accepté » (`AGENTS.md:41-43`).
4. **Application à distance.** La préproduction, puis la production, chacune avec
   inventaire, sauvegarde et feu vert explicite de l'opérateur sur la liste précise.
5. **Ajout d'un scénario à la CI.**
   - Il faut un ordre du directeur : `.github/` est une zone interdite aux agents.
   - Sans cet ordre, le scénario se rejoue en local avec `tool/rejouer_scenarios.sh`,
     comme `scenarios_c04_teacher_title.sql` aujourd'hui.
6. **Jamais par `main`.** Aucun de ces lots ne passe par `main` : branche, PR
   d'aperçu, fusion décidée par le directeur.

## 2. Ordre et dépendances

```
langue  ──►  c11bis  ──►  creer_groupe
conduite      (après les migrations PE 20261018160000 et 20261019100000)
gnf           (indépendant)
```

- **langue avant c11bis.**
  - Toute classe née d'un regroupement porte un `langue_code` non nul
    (`20261012100000_c11bis_gender_enum_fix.sql:144-149`).
  - Le prédicat le compare à `teacher_profiles.languages` (`0082:64`).
  - Sans le lot langue, la réparation de `c11bis` refuserait donc chaque
    affectation réelle avec « enseignant indisponible ou genre inconnu ».
- **c11bis avant creer_groupe** (relecture).
  - `creer_groupe` remplace `tc_verifier_affectation_enseignant(uuid,uuid)` par une
    version à trois arguments.
  - Le contrôle final de `c11bis` appelle `has_function_privilege` sur l'ancienne
    signature, et lèverait « function does not exist » si `creer_groupe` passait
    d'abord.
  - Appliquer `c11bis` d'abord, et écrire ce contrôle avec `to_regprocedure`.
- **Horodatages distincts** (relecture).
  - Les trois premières analyses proposaient le même préfixe `20261021090000`.
    Supabase indexe `schema_migrations` sur ce préfixe : la deuxième migration
    échouerait.
  - Chaque lot prend un horodatage propre, postérieur à la dernière migration de
    la pointe au moment de l'écrire, et dans l'ordre ci-dessus.
  - Les noms ci-dessous sont indicatifs.

---

## 3. Lot langue : enregistrer le code, afficher le nom

### Constat

**Écriture.**
- `lib/features/profil_enseignant/declaration_choix.dart:202-218` met
  `valeur: nom`, avec le commentaire « On enregistre le nom, pas le code ».
- La valeur part par `service_declaration.dart:38-41` (`p_languages`).
- `0027_maj_profil_enseignant.sql:66` l'écrit telle quelle. C'est la seule
  définition en vigueur.

**Référentiel.**
- `langues_cours` a pour clé `code` (`poular`, `francais`, `english`) et pour
  libellé `nom_humain` (`0043:67-78`).
- `nom_humain` n'est pas unique, et la direction peut le modifier (`0043:131-134`).
- `groupes.langue_code` est une clé étrangère vers `langues_cours(code)`
  (`0043:450`).

**Comparaison.**
- `tc_verifier_affectation_enseignant` (`0082:64`) et `enseignants_pour_classe`
  (`0083:111`) comparent par code.
- Toutes les fixtures stockent des codes (par exemple
  `scenarios_c04_teacher_title.sql:39-41`) : les scénarios passent, alors que la
  production n'aurait pas les mêmes valeurs.

**Non concernés.**
- `enseignants_pour_public` et `creer_groupe` ne comparent aucune langue.
- `remplacement_enseignant_compatible` (`b09:42-65`) n'en compare aucune : c'est un
  défaut distinct, à traiter après ce lot avec la même condition que `0083:111`.

### Impact

**Aujourd'hui, rien de visible.** Aucun écran n'appelle `enseignants_pour_classe`,
et la seule affectation encore ouverte lève toujours (lot `c11bis`).

**Dès que `c11bis` est réparé.**
- Les enseignants invités ont `languages = '{}'`.
- Ceux qui ont rempli ENS-05 ont des noms ou du texte libre.
- Aucun ne passe donc le filtre, et toute affectation est refusée avec un message
  qui parle de genre.

Mesure en lecture seule, à faire lancer par l'opérateur :

```sql
select v.valeur,
       exists (select 1 from public.langues_cours c where c.code = v.valeur) as est_code,
       exists (select 1 from public.langues_cours c
                where lower(btrim(c.nom_humain)) = lower(btrim(v.valeur))
                  and c.code <> v.valeur) as est_nom,
       count(*)
  from public.teacher_profiles tp
  cross join lateral unnest(tp.languages) v(valeur)
 group by 1 order by 4 desc;
```

### Correctif proposé

**Direction : on stocke le code, on affiche le nom par le référentiel.** Aucune
fonction de comparaison ne change. Comparer par nom casserait toutes les
éligibilités en silence au premier renommage d'un libellé.

« Autre » en texte libre reste permis.
- La décision du 18/10 cite « ou autre langue selon la disponibilité des
  enseignants » (`OFFRE_ET_TARIFS_2026-10-18.md:33`).
- Une saisie libre n'égale aucun code. Elle ne rend donc l'enseignant éligible à
  aucune classe tant que la direction n'a pas ajouté la langue au référentiel.
- On refuse plutôt que d'affecter à tort.

**Migration** (nom indicatif `…_ens_l8_langues_par_code.sql`). Un déclencheur
normalise à l'écriture. Il couvre ainsi :
- `maj_profil_enseignant` ;
- le futur import des candidatures ;
- les clients PWA encore en cache qui enverront des noms.

Il ne touche aucune fonction protégée par une empreinte.

```sql
BEGIN;

CREATE FUNCTION public.teacher_profiles_langues_par_code()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
BEGIN
  -- Code connu -> lui-meme ; nom connu (casse et espaces ignores) -> son code ;
  -- autre texte -> garde tel quel (« Autre »). Vides et doublons retires,
  -- ordre de saisie conserve.
  NEW.languages := coalesce((
    SELECT pg_catalog.array_agg(n.valeur ORDER BY n.rang)
      FROM (
        SELECT DISTINCT ON (r.valeur) r.valeur, r.rang
          FROM (
            SELECT coalesce(
                     (SELECT lc.code FROM public.langues_cours lc
                       WHERE lc.code = pg_catalog.lower(pg_catalog.btrim(v.brut))
                          OR pg_catalog.lower(pg_catalog.btrim(lc.nom_humain))
                             = pg_catalog.lower(pg_catalog.btrim(v.brut))
                       -- (relecture) un code exact passe avant un nom homonyme
                       ORDER BY (lc.code = pg_catalog.lower(pg_catalog.btrim(v.brut))) DESC,
                                lc.ordre, lc.code
                       LIMIT 1),
                     pg_catalog.btrim(v.brut)) AS valeur,
                   v.rang
              FROM pg_catalog.unnest(NEW.languages) WITH ORDINALITY AS v(brut, rang)
             WHERE pg_catalog.btrim(coalesce(v.brut, '')) <> ''
          ) r
         ORDER BY r.valeur, r.rang
      ) n
  ), '{}'::text[]);
  RETURN NEW;
END;
$function$;
ALTER FUNCTION public.teacher_profiles_langues_par_code() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.teacher_profiles_langues_par_code()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER teacher_profiles_langues_par_code
  BEFORE INSERT OR UPDATE OF languages ON public.teacher_profiles
  FOR EACH ROW EXECUTE FUNCTION public.teacher_profiles_langues_par_code();

COMMENT ON COLUMN public.teacher_profiles.languages IS
  'Codes de public.langues_cours. Une valeur hors referentiel est une saisie libre conservee, qui ne correspond a aucune classe. Apres ajout d''une langue au referentiel, rejouer : update public.teacher_profiles set languages = languages where languages <> ''{}''.';

-- Reprise : le declencheur reecrit chaque ligne non vide ; NOTICE des valeurs
-- hors referentiel avec leur nombre, sans identite.
-- Postflight : aucun nom du referentiel encore stocke ; fonction non executable
-- par anon, authenticated, agent_ro.
COMMIT;
```

Le bloc de reprise et le contrôle final sont décrits en commentaire ci-dessus. Ils
suivent l'idiome de `remplacements_seance_immutable` (`b09:31-37`).

**Client.**

`lib/features/profil_enseignant/declaration_choix.dart` :
- les langues publiées ont `valeur: l.code` et `libelle: l.nom`. La clé de carte
  reste `FeuilleLangues.carteKey(l.nom)`, pour que les tests ne bougent pas ;
- (relecture) une valeur déclarée dont la forme réduite (`lower`, `trim`) égale un
  code ou un nom publié **ne crée pas de seconde carte**. Elle est convertie en
  code dans `_initiale`, comme le fait le déclencheur.
  - Sinon deux cartes porteraient la même clé (`choice_card_group.dart:267`) :
    assertion « Duplicate keys », et la carte du référentiel décochée.
  - Le cas arrivera dès qu'on ajoutera l'arabe au référentiel.

Une nouvelle fonction rend le nom à afficher.
- (relecture) Elle s'appelle `nomLangueCours`, et non `libelleLangue`, déjà pris
  par `libelles_bibliotheque.dart:26`.
- Le profil (`profil_enseignant_page.dart:474`) l'utilise à la place de
  `profil.langues.join(', ')`.

(relecture) Lire les libellés **sans** le filtre `actif` :
- `ServiceOffres.langues()` filtre `.eq('actif', true)` (`service_offres.dart:114`),
  alors qu'une langue retirée doit rester lisible sur les profils qui la portent ;
- la policy `langues_cours_lecture` (`0043:126-127`) laisse déjà lire toutes les
  lignes ;
- pendant le chargement ou en cas d'erreur, la ligne montre son état de chargement
  (ou le cache local), **jamais un code** comme « francais »
  (`docs/current/00_LIRE_D_ABORD.md:18`, `lib/CLAUDE.md:103`).

Démonstration : `enseignant_demo.dart:543` passe à des codes. Aucune clé i18n
nouvelle et aucun jeton nouveau.

### Reprise des données

Elle est faite dans la migration : `UPDATE … SET languages = languages`.
- 0 ligne sur une base neuve.
- Toutes les lignes non vides en préproduction et en production.

Les noms deviennent des codes, les doublons disparaissent, l'ordre est conservé et
le texte libre est gardé. Aucune perte.

### Recette

**Nouveau scénario `scenarios_ens_l8_langues_par_code.sql`, sur base neuve.**
1. `maj_profil_enseignant(p_languages => ARRAY['Français','Arabe',' francais '])`
   stocke `{francais,Arabe}`.
2. `enseignants_pour_classe` rend l'enseignante pour une classe `francais`.
3. `tc_verifier_affectation_enseignant` ne lève rien pour elle.
4. Après `ARRAY['Wolof']`, la ligne vaut `{Wolof}` et la classe ne la propose plus.
5. Un `INSERT` direct de `ARRAY['English','Poular','']` donne `{english,poular}`.
6. La fonction n'est exécutable ni par `anon`, ni par `authenticated`, ni par
   `agent_ro`.

Contre-épreuve : sans la migration, les contrôles 1 et 2 doivent échouer.

**Flutter.**
- `form_l8_test.dart:113-137` : valeurs en codes, libellés en noms.
- `profil_enseignant_test.dart` : fixture `:57`, attentes `:353` et `:509`.
- Ajouter la surcharge `languesCoursProvider` dans les trois tests qui montent
  `ProfilEnseignantPage` : `navigation_reelle_test.dart:95`,
  `revenus_enseignant_test.dart:105` et `parcours_enseignant_test.dart:91`.
- Tests nouveaux :
  - `nomLangueCours` ;
  - pas de carte en double ;
  - référentiel en erreur, sans aucun code à l'écran.

### Risques

- **Ordre de déploiement : migration d'abord, client ensuite.** Un ancien client
  qui envoie des noms reste sans conséquence, puisque le déclencheur les convertit.
- **Export des données personnelles.** `mes_donnees_export` (`20261018150000:211`)
  exportera des codes. Les traduire touche une fonction protégée par une empreinte :
  lot séparé si on le veut.
- **Collation.** `lower()` sur des lettres accentuées dépend de la collation. Les
  noms écrits par FORM-L8 sont des copies exactes de `nom_humain`, donc retrouvés.

### Cohérence avec le mappage de l'import

`MAPPAGE_IMPORT_FORMULAIRES.md` (section 3.2) enregistre hors référentiel un code
ISO 639 : `ar` pour l'arabe, `ha` pour le haoussa, etc. Deux règles en découlent :

- **Le code d'une langue ajoutée à `langues_cours` est celui du mappage.**
  - Exemple : l'arabe entre avec le code `ar`, et le libellé de la direction.
  - Ainsi le déclencheur rattache à la fois les saisies importées (`ar`, par le
    code) et les saisies libres « Arabe » (par le nom).
  - Les trois codes existants (`poular`, `francais`, `english`) ne changent pas : ce
    sont des clés étrangères.
- **Un code hors référentiel ne s'affiche jamais tel quel.** Le module des
  candidatures porte la table de libellés des codes ISO 639 du mappage, en
  français et en arabe.

---

## 4. Lot c11bis : rendre l'affectation possible

### Constat

**La fonction lève sans condition.**
- `affecter_enseignant_classe_c11bis` (`0079:90-131`) rend `deja_affecte` si un
  enseignant est déjà posé.
- Elle lève `classe indisponible` hors de l'état `en_attente_enseignant`.
- Puis elle lève **sans condition** :
  `compatibilite enseignant non verifiable : source titre public absente`
  (`0079:126-129`, revérifié).
- F86 (`20261012110500:42-58`) n'a changé que sa garde.

**Les deux motifs du refus sont levés depuis `0082`.**
- Motifs écrits : titre public C-05 et collisions C-07 (`0079:126-128`).
- `0082` dérive le titre public de `profiles.gender` (`:2`).
- Il crée aussi `tc_verifier_affectation_enseignant` (`:13-235`), qui vérifie :
  - le verrou par enseignant ;
  - la pièce d'identité, le statut et la langue ;
  - le genre ;
  - le plafond ;
  - la couverture par les disponibilités ;
  - les collisions par instant ;
  - les séances ponctuelles.
- `0082` a rebranché `affecter_enseignant_classe` sur cette vérification, mais pas
  `_c11bis`.

**L3-06 a fermé la seule voie qui affectait.**
- `20261017120600:19-20` révoque `affecter_enseignant_classe` en croyant `_c11bis`
  porteuse du verrou par enseignant (`:8`). Elle ne l'est pas.
- Le même énoncé figure dans `docs/audit-final/lots/L3-06.md:9` et
  `docs/AUDIT-FINAL-2026-10.md:233`.
- `MATRICE-CONFORMITE.md:123` (D-06) déclare « CONFORME » à tort.

**À l'écran.**
- **Page Regroupements.**
  - `regroupements_c11bis_admin` code la capacité à `false` en dur, dans deux
    branches : `20261011121958:299` (classe déjà existante) et `:403` (classes en
    attente), revérifié.
  - La carte affiche une phrase qui renvoie à « un membre de la direction qui en a
    le droit ». Personne ne l'a.
- **Pilotage, section attente.**
  - Le bouton « Choisir l'enseignant » est actif (`contrats_classes_admin.sql:212`).
  - L'erreur est rattrapée par `on Object` et affichée comme « la réponse du
    serveur n'est pas arrivée. Pressez de nouveau. » : faux, et sans fin.
- **Démonstration.** Elle masque le défaut (`regroupements_demo.dart:278`, `:313-322`).

### Impact

**Aucune classe en attente d'enseignant ne peut en recevoir un.** (Précision :
une classe créée depuis l'écran Classes reçoit son enseignant à la création, par
`creer_groupe`, sans contrôle ; voir le lot suivant.)

Pour toute classe née d'un regroupement :
- elle reste en attente ;
- aucune séance n'est générée (`0055:22-40`) ;
- les demandes restent à `classe_validee` (`0085:74-87`) ;
- la notification `enseignant_affecte` ne part jamais ;
- l'enseignant ne voit pas la classe.

Décisions contredites : `DECISION-OFFRES-GROUPES-2026-10-09.md:38-39` et `:49`,
`DECISION-CLASSES-SIMULTANEES-2026-10-10.md` R7 et R8 (`:28-29`), et la preuve
exigée en `:48`.

Aucune donnée corrompue : la fonction lève avant toute écriture.

Mesure en lecture seule :

```sql
select count(*) from public.groupes
 where etat = 'en_attente_enseignant' and ended_at is null;
```

### Correctif proposé

**A. La fonction délègue au prédicat et affecte** (nom indicatif
`…_c11bis_affectation_verifiee.sql`). Elle reprend :
- la garde F86 au mot près ;
- les sorties `deja_affecte` et `classe indisponible` ;
- puis le chemin de `0082:282-317`.

```sql
BEGIN;
CREATE OR REPLACE FUNCTION public.affecter_enseignant_classe_c11bis(
  p_groupe_id uuid, p_teacher_profile_id uuid)
RETURNS text LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_groupe public.groupes%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false)
     OR p_groupe_id IS NULL OR p_teacher_profile_id IS NULL THEN
    RAISE EXCEPTION 'affectation reservee a l''administration' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_groupe FROM public.groupes WHERE id = p_groupe_id FOR UPDATE;
  IF NOT FOUND OR v_groupe.ended_at IS NOT NULL THEN
    RAISE EXCEPTION 'classe indisponible';
  END IF;
  IF v_groupe.teacher_id IS NOT NULL THEN
    RETURN 'deja_affecte';
  END IF;
  IF v_groupe.etat <> 'en_attente_enseignant' THEN
    RAISE EXCEPTION 'classe indisponible';
  END IF;
  -- C-04, C-05, C-07 et verrou par enseignant (R8) ; leve sur refus.
  PERFORM public.tc_verifier_affectation_enseignant(p_groupe_id, p_teacher_profile_id);
  -- Declencheurs : seances (0055:22-40) ; demandes -> enseignant_affecte (0085:74-87),
  -- qui previent aussi l'eleve adulte (0078:80-170).
  UPDATE public.groupes SET teacher_id = p_teacher_profile_id, etat = 'active'
   WHERE id = p_groupe_id;
  PERFORM public.log_sensitive_access('enseignant_affecte_classe', 'groupes',
    p_groupe_id::text, pg_catalog.jsonb_build_object('teacher_id', p_teacher_profile_id));
  -- Notification au tuteur principal, fuseau du foyer, premiere seance future
  -- (correctif M-b de 0075:170-189, perdu par 0082:301 et :312-315).
  INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
  SELECT DISTINCT h.primary_guardian_id, h.id, 'enseignant_affecte',
         pg_catalog.jsonb_build_object('groupe_id', p_groupe_id,
           'debut_local', pg_catalog.to_char(s.started_at AT TIME ZONE h.timezone,
                                             'YYYY-MM-DD"T"HH24:MI:SS')),
         '/tuteur/demandes'
    FROM public.groupe_membres gm
    JOIN public.profiles p ON p.id = gm.student_id
    JOIN public.households h ON h.id = p.household_id
    JOIN public.sessions s ON s.groupe_id = gm.groupe_id AND s.deleted_at IS NULL
   WHERE gm.groupe_id = p_groupe_id AND gm.left_at IS NULL
     AND h.primary_guardian_id IS NOT NULL
     AND s.started_at = (SELECT min(s2.started_at) FROM public.sessions s2
                          WHERE s2.groupe_id = p_groupe_id AND s2.deleted_at IS NULL
                            AND s2.started_at > pg_catalog.now());
  RETURN 'affecte';
END;
$function$;
```

La garde ci-dessus est condensée pour la lecture. Le lot reprend celle de F86 **au
mot près** : deux `IF` successifs, même message, même code. Sinon les attentes
42501 de `scenarios_offres_personnalisees.sql` (`:378-386`, `:456-461`,
`:489-494`) changeraient.

(relecture) L'élève adulte est déjà prévenu.
- Le passage des demandes à `enseignant_affecte` déclenche
  `demandes_horaires_notification_adulte` (`0078:80-170`).
- Il n'y a pas de doublon : `0078` s'abstient quand le tuteur est l'élève.

**B. Capacité alignée** (même migration). Remplacer `'peut_affecter_enseignant', false`
par la capacité que le serveur calcule déjà (`0071:20`).
- La technique est celle de F86 et de `0075` : `pg_get_functiondef`, contrôle
  préalable du texte attendu, puis `replace`.
- (relecture) Il y a **deux** branches : `:403` (classes en attente) et `:299`
  (regroupement encore ouvert qui correspond à une classe déjà en attente).
- Corriger seulement `:403` ferait apparaître la même classe deux fois, dont une
  fois sans bouton. Les deux branches sont à traiter dans le lot.

**Droits, empreintes, contrôle final.** Même idiome que
`20261019120000_avis_publics.sql:366-399` :
- propriétaire `postgres` ;
- `REVOKE ALL` puis `GRANT EXECUTE TO authenticated` ;
- empreinte md5 recalculée en commentaire.

Le contrôle final lève si :
- le corps contient encore le refus ;
- le corps n'appelle pas le prédicat ;
- `affecter_enseignant_classe` redevient exécutable (L3-06 doit tenir) ;
- les droits ne sont pas conformes.

(relecture) Il teste les signatures avec `to_regprocedure`.

Ni `DROP`, ni `DELETE`, ni `TRUNCATE`.

**C. Client** (même lot, recommandé). Après A, le serveur refusera légitimement :
chevauchement, disponibilité, plafond, genre, langue.

L'adaptateur (`regroupements_c11bis_supabase.dart:74-83`) :
- traduit ces refus en une erreur typée ;
- relit la classe créée pour prendre sa capacité au serveur.

La feuille (`feuille_classe_regroupement.dart:211-226`) affiche une phrase par
motif, avant le `on Object`.

(relecture) **Jamais le motif SQL brut.**
- « enseignant non disponible: jour %, heure %, fuseau %… » (`0082:158-159`) est
  du texte technique, en français même dans l'interface arabe.
- Chaque motif connu devient une clé i18n (idiome `messageLisible` de
  `offres_admin_supabase.dart`).
- Un motif inconnu donne une phrase générique honnête : « L'enseignant n'est pas
  confirmé. Choisissez-en un autre. »

(relecture) L'erreur typée touche `port_regroupements_admin.dart`, un port
existant. Deux voies :
- une ligne « Contrats » acceptée ;
- ou placer l'erreur hors d'un fichier `port_*`.

### Reprise des données

Aucune. Les classes en attente sont dans un état valide. La direction les
affectera par l'écran une fois le correctif en place. La mesure ci-dessus dit
combien.

### Recette

**Nouveau scénario `scenarios_c11bis_affectation.sql`, sur base neuve.**

Fixtures :
- T1, un enseignant, et T2, une enseignante, pièces validées ;
- G1, une classe en attente, lundi à 18 h, Paris, public hommes ;
- G2, une classe en attente au même instant (Londres, 17 h) ;
- G3, une classe en attente, public hommes ;
- (relecture) chaque classe porte un `langue_code` valide, et les enseignants
  l'ont dans `languages`. Sinon le contrôle 5 ne trouve aucune ligne : la jointure
  de `20261011121958:405` est interne.

Contrôles :
1. `_c11bis(G1, T1)` rend `affecte` :
   - la classe est active ;
   - des séances existent au nom de T1 ;
   - une ligne d'audit existe ;
   - une notification existe, avec une date future.
2. `_c11bis(G1, T2)` rend `deja_affecte` et ne change rien.
3. `_c11bis(G2, T1)` lève le chevauchement : c'est la preuve exigée par
   `DECISION-CLASSES-SIMULTANEES:48`.
4. `_c11bis(G3, T2)` lève l'incompatibilité de genre.
5. `regroupements_c11bis_admin()` rend la capacité vraie pour une classe en
   attente, dans les deux branches.
6. `affecter_enseignant_classe(uuid,uuid)` reste fermé à `authenticated`.

Doivent rester verts :
- `scenarios_offres_personnalisees.sql`, `scenarios_af_l3_06_rpc_uniques.sql`,
  `scenarios_af_liste_blanche_volatiles.sql` ;
- `scenarios_c11bis_f74_partition.sql:122-131`, `scenarios_contrats_classes.sql`,
  `scenarios_b18_security_definer.sql` ;
- le rejeu complet.

La concurrence à deux sessions se teste à la main, avec deux `psql`.

### Risques et suites

- **Refus réels.** La liste proposée vient de `enseignants_pour_public`, établie
  par public et non par classe. Des refus réels apparaîtront, d'où la partie C.
- **Documents à corriger dans le même lot.** `MATRICE-CONFORMITE.md:123`,
  `lots/L3-06.md:9` et `AUDIT-FINAL-2026-10.md:233`.
- (relecture) **`creer_classe_depuis_regroupement_c11bis` n'est pas « morte » :**
  elle est supprimée (`DROP`, `20261011121958:674`).

---

## 5. Lot creer_groupe : un seul prédicat pour poser un enseignant

### Constat

**La version en vigueur.** C'est `0045_disambiguate_creer_groupe_overloads.sql:9-68`.
`0067`, les balayages `0074` et `0084`, et L3-06 n'en changent que la garde ou les
droits.

**Ce qu'elle vérifie côté enseignant** (`0045:24-32`) : seulement le rôle,
l'absence de suppression et le statut `active` ou `provisional_active`.

**Ce qu'elle fait ensuite.**
- Elle insère une classe **active** avec son enseignant (`0045:54-59`).
- Le déclencheur matérialise aussitôt les séances à son nom (`0055:22-40`).

**Ce qu'elle ne vérifie pas** (et que `tc_verifier_affectation_enseignant`
vérifie, `0082:13-235`) :
- la pièce d'identité validée ;
- la date d'accès ;
- le profil enseignant présent ;
- le genre ;
- la langue ;
- le plafond hebdomadaire ;
- les collisions par instant ;
- les séances ponctuelles ;
- le verrou par enseignant.

**Les fixtures le prouvent.** `scenarios_af_l3_06_rpc_uniques.sql:24-28,114-115` et
`scenarios_af_l3_02_matching_ferme.sql:9-11,55-56` obtiennent une classe pour un
enseignant à la pièce non validée, ou sans profil enseignant.

**C'est le seul chemin vivant qui écrit `groupes.teacher_id`.**
- `affecter_enseignant_classe` est fermée.
- `_c11bis` lève toujours.
- `modifier_groupe` ne touche pas à l'enseignant.

L'appelant est la feuille « Créer une classe » (`groupes_page.dart:1162-1189`),
par `PortCreationClasse` puis `ServiceGroupes.creer`.

### Impact

**Une classe active peut porter un enseignant** :
- à la pièce `pending` ou `rejected` ;
- à l'accès expiré ;
- sans profil enseignant ;
- de genre inconnu ;
- au-delà de son plafond ;
- en double réservation.

Deux créations simultanées ne sont pas sérialisées. Les séances sont générées à
son nom.

**Production.** D'après l'instantané du 10/10
(`docs/backend/PROD_SECURITY_SNAPSHOT_2026-10-10.md:978-1005`, `:43`), la même
version tourne en production. Des classes réelles peuvent donc déjà porter un
enseignant non éligible. Non vérifié.

Requête de diagnostic en lecture seule, avec le feu vert de l'opérateur :

```sql
select g.id, g.teacher_id, p.account_status, p.access_until,
       tp.kyc_status, tp.deleted_at as tp_supprime, p.gender, g.genre_public, g.langue_code
  from public.groupes g
  join public.profiles p on p.id = g.teacher_id
  left join public.teacher_profiles tp on tp.profile_id = p.id
 where g.ended_at is null and g.etat = 'active'
   and not coalesce(p.role = 'teacher' and p.deleted_at is null
       and p.account_status in ('active','provisional_active')
       and (p.access_until is null or p.access_until > now())
       and tp.deleted_at is null and tp.kyc_status = 'approved' and p.gender is not null
       and (g.langue_code is null or g.langue_code = any(tp.languages)), false);
```

### Correctif proposé

**Principe.**
- La classe naît `en_attente_enseignant`.
- `creer_groupe` appelle le prédicat, puis passe la classe à `active` par la même
  mise à jour que `0082:286-288`.
- Aucune séance n'existe donc avant le contrôle (`0055:1-2`).

**Un drapeau sur le prédicat** (nom indicatif `…_creer_groupe_predicat_affectation.sql`).
- `tc_verifier_affectation_enseignant(p_groupe_id, p_teacher_id,
  p_exiger_disponibilites boolean DEFAULT true)`, par `DROP` puis `CREATE` dans la
  même transaction (idiome `0045`).
- Le corps de `0082:23-234` est recopié à l'identique, sauf la boucle de
  couverture des disponibilités (`0082:128-163`), entourée de
  `IF p_exiger_disponibilites`.
- Les deux appelants positionnels (`0082:282`, `0083:117`) tombent sur `true` :
  comportement inchangé.
- `creer_groupe` passe `false`.

Variante possible : garder la signature et déplacer le corps dans `app_private`,
comme `app_private.deplacer_membre_classe`.

```sql
-- creer_groupe : meme signature, memes defauts, memes droits (0045:69-71).
  -- 0045:20-52 inchanges (garde, existence de l'enseignant, fuseau, seuil).
  insert into public.groupes
    (teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, couleur_jeton)
  values
    (null, 'en_attente_enseignant', p_type_public, v_seuil, p_libelle, p_weekday, p_hour_local,
     coalesce(p_timezone_iana, 'Europe/Paris'), p_couleur_jeton)
  returning id into v_id;

  perform public.tc_verifier_affectation_enseignant(
    p_groupe_id => v_id, p_teacher_id => p_teacher_profile_id,
    p_exiger_disponibilites => false);

  update public.groupes set teacher_id = p_teacher_profile_id, etat = 'active'
   where id = v_id;
  -- 0045:61-66 inchanges (journal, return v_id).
```

Le contrôle final vérifie :
- l'ancienne signature disparue ;
- la nouvelle non exécutable par `authenticated`, `anon` ni `agent_ro` ;
- `creer_groupe` qui appelle bien le prédicat ;
- ses droits inchangés.

Aucun fichier Dart ne change : la signature est la même, et le refus s'affiche déjà
par `creerErreur` (`groupes_page.dart:871-877`).

### Ce que le directeur doit trancher (relecture)

La première analyse annonçait une conformité à D4 qu'elle n'a pas.
`UX_REVIEW_CLASSE-FORM-1.md` dit :
- D3 (`:125-128`) : un enseignant de genre inconnu « reste proposable » ;
- D4 (`:32`, `:129-131`) : « seul un conflit certain (genre, collision avec une
  classe active) bloque ».

Le prédicat bloque pourtant aussi :
- un genre inconnu, même sur une classe au public `indetermine` (`0082:65-66`) ;
- le plafond hebdomadaire (`0082:122-124`) ;
- une pièce d'identité non validée et une date d'accès dépassée.

D3 prend en outre le genre dans `teacher_profiles.titre`, alors que le serveur le
lit dans `profiles.gender` (`0082:2`).

**Recommandation : retenir le prédicat strict, sauf la couverture des
disponibilités.**
- Une personne à la pièce non validée ou à l'accès expiré ne reçoit pas d'élèves.
- Le cloisonnement femmes et hommes se décide en base.
- Le plafond est une règle de la direction.
- La couverture des disponibilités reste un simple avertissement : c'est D4, et le
  texte de l'écran « vous pouvez quand même faire ce choix »
  (`genre_classe_libelles.dart:116-130`).

D3, D4 et les textes de l'écran sont alors réécrits dans le même lot. Un
enseignant de genre inconnu devient « visible, non choisissable, avec sa raison ».

Autre voie : ne pas exiger le genre pour une classe `indetermine`. Elle demande un
second drapeau, et laisse un enseignant de genre inconnu face à un public qui ne
l'est pas moins.

### Reprise des données

Aucune reprise automatique. Retirer un enseignant d'une classe active est une
décision de la direction.

La requête ci-dessus donne la liste. Les collisions et le plafond se vérifient
classe par classe, dans un `BEGIN … ROLLBACK`.

### Recette

**Nouveau scénario `scenarios_creer_groupe_predicat.sql`, sur base neuve, sous une
direction active.**

Fixtures :
- E1 : éligible, sans aucune disponibilité ;
- E2 : pièce `pending` ;
- E3 : accès expiré ;
- E4 : genre inconnu ;
- E5 : profil enseignant supprimé ;
- E6 : déjà en classe au même instant ;
- E7 : plafond 1, déjà atteint ;
- E8 : une séance ponctuelle au même instant. (relecture) La colonne est
  `sessions.status`, pas `statut`.

Attendus :
- E1 réussit : classe active, séances créées. Cela prouve que D4 tient sur les
  disponibilités.
- E2 à E8 sont refusés avec leur motif.
- Après chaque refus, aucune classe ni séance n'existe.
- Non-régression : le prédicat appelé à deux arguments exige toujours les
  disponibilités.

Fixtures existantes à corriger, puisqu'elles reposent sur le défaut :
- `scenarios_af_l3_06_rpc_uniques.sql:27-28` : pièce `approved` ;
- `scenarios_af_l3_02_matching_ferme.sql:9-11` : genre et profil enseignant.

Doivent rester verts : toute la liste de la CI, en particulier
`scenarios_b18_security_definer.sql:33-37` ; `scenarios_c04_teacher_title.sql` ;
`scenarios_af_liste_blanche_volatiles.sql:82`.

### Risques

- **Refus nouveaux, voulus, sur l'écran Classes.**
  - Le message serveur s'affiche aujourd'hui brut par `creerErreur`.
  - La même règle que pour `c11bis` s'applique : une phrase par motif, jamais le
    texte SQL.
  - C'est un lot client à part, ou inclus si le directeur le veut.
- **`modifier_groupe` peut toujours déplacer une classe vers une collision.**
  - CF1-B6 le vise aussi.
  - Il faut le même appel après sa mise à jour, dans un lot à part.
- **Production.** Le registre de production s'arrêtait à `0042` le 10/10. Ce lot
  ne s'y applique qu'après toute la chaîne qui porte `etat`, `genre_public` et
  `0082`.

---

## 6. Lot gnf : une seule table des décimales

### Constat

**Côté client** (`lib/core/finance/format_montant.dart:36-39`, revérifié).
- 0 décimale pour `XOF`, `XAF`, `GNF`, `JPY` et `KRW`.
- 2 pour toutes les autres.
- Toutes les conversions client passent par `decimalesDe`.

**Côté serveur** (`x217_montant_ref`, `x2_17_treasury_triggers.sql:142-144`,
revérifié).
- 0 décimale pour `JPY`, `XOF`, `XAF` et `KMF`.
- 3 pour `KWD`, `BHD`, `TND` et `OMR`.
- 2 pour les autres, **dont `GNF` et `KRW`**.
- Appelée par toute la trésorerie de `x2_17` et par `fac_e_02:128` (paie par
  séance).

**ISO 4217** donne au GNF 0 décimale.
- Le serveur se trompe sur `GNF` et `KRW`.
- Le client se trompe sur `KMF` et sur les devises à 3 décimales.

**Exemple** (taux de démonstration : 1 USD = 8 600 GNF).
- 1 823 200 GNF valent 2,12 $ au lieu de 212,00 $.
- 4 000 GNF arrondissent à 0 et partent en file `montant_invalide`.

### Impact

**Chaîne atteignable.**
1. Une politique en GNF : `fac_politique_lue` accepte tout code `^[A-Z]{3}$`
   (`fac_e_01:474`).
2. Le portefeuille du foyer prend cette devise.
3. Un paiement saisi.
4. La référence USD est écrite cent fois trop petite.

**Mêmes effets ailleurs.**
- La paie par séance et les versements en GNF, alors que le GNF est la devise de
  versement visée (`07_MEMOIRE_PEDAGOGIE_FINANCE.md:20`).
- Les graphiques de trésorerie du Comptable.

**Aujourd'hui, latent.**
- Les politiques semées sont en USD.
- `fx_rates` n'a ni RPC d'écriture ni ligne GNF.
- Sans taux, le mouvement part en `taux_change_absent` : pas de faux montant.
- Le faux montant apparaît dès qu'un taux GNF vers USD est saisi.

### Correctif proposé

**Le serveur fait foi** (`00_LIRE_D_ABORD.md:19`).
- Une seule fonction SQL porte la table.
- Le client en garde un miroir, parce que le formatage est synchrone et doit
  marcher hors ligne.
- Un test compare le miroir à la migration.

**Migration** (nom indicatif `…_fi_devises_decimales_iso4217.sql`).

```sql
BEGIN;
CREATE FUNCTION private.devise_decimales(p_devise text)
RETURNS integer LANGUAGE sql IMMUTABLE SECURITY INVOKER SET search_path = ''
AS $function$
  SELECT CASE
    -- (relecture) table ISO 4217 complete, et pas seulement l'union des deux tables
    WHEN p_devise IN ('BIF','CLP','DJF','GNF','ISK','JPY','KMF','KRW','PYG',
                      'RWF','UGX','VND','VUV','XAF','XOF','XPF') THEN 0
    WHEN p_devise IN ('BHD','IQD','JOD','KWD','LYD','OMR','TND') THEN 3
    ELSE 2 END;
$function$;

CREATE OR REPLACE FUNCTION public.x217_montant_ref(p_minor bigint, p_devise text, p_a timestamptz)
RETURNS bigint LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_taux numeric;
BEGIN
  IF p_devise = 'USD' THEN RETURN p_minor; END IF;
  SELECT f.rate INTO v_taux FROM public.fx_rates f
   WHERE f.from_currency = p_devise AND f.to_currency = 'USD' AND f.effective_at <= p_a
   ORDER BY f.effective_at DESC, f.id DESC LIMIT 1;
  IF v_taux IS NULL THEN RETURN NULL; END IF;
  RETURN pg_catalog.round(p_minor::numeric * v_taux * pg_catalog.power(10::numeric,
    private.devise_decimales('USD') - private.devise_decimales(p_devise)))::bigint;
END;
$function$;

ALTER FUNCTION private.devise_decimales(text) OWNER TO postgres;
ALTER FUNCTION public.x217_montant_ref(bigint, text, timestamptz) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.devise_decimales(text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.x217_montant_ref(bigint, text, timestamptz)
  FROM PUBLIC, anon, authenticated, agent_ro, service_role;
-- Postflight : GNF 0, USD 2, KWD 3.
COMMIT;
```

La signature, le propriétaire et les droits de `x217_montant_ref` sont repris à
l'identique (`x2_17:537`, `:548`). Les appelants ne changent pas.

**Client.** `decimalesDe` lit une table constante `decimalesHorsDefaut`, miroir exact
de la fonction SQL, et rend 2 par défaut. Aucun appelant ne change.

**Contrat.** `docs/current/CONTRAT-CPT-BR-18-19.md:166-169` cesse de recopier une
liste. Il renvoie à `private.devise_decimales` pour le futur export.

**Question au directeur.** Faut-il, en outre, n'accepter dans une politique
commerciale qu'une **liste fermée** de devises, celles que l'académie utilise
réellement ? La table ISO complète suffit à corriger le défaut. La liste fermée
évite d'ouvrir une devise que ni Stripe ni la comptabilité n'ont prévue.

Avant d'ouvrir une recharge dans une devise hors USD, vérifier dans la
documentation Stripe ses écarts avec ISO (`_shared/stripe.ts:65-66` transmet
l'unité mineure telle quelle).

### Reprise des données

Aucune reprise au tip : aucune donnée GNF, aucun taux, `seed.sql` vide.

À vérifier en lecture seule à distance :

```sql
select from_currency, count(*) from public.fx_rates
 where from_currency in ('GNF','KRW','KMF','BHD','KWD','OMR','TND') group by 1;
select devise, count(*) from public.tresorerie_mouvements
 where devise in ('GNF','KRW','KMF','BHD','KWD','OMR','TND') group by 1;
select devise, count(*) from public.politiques_commerciales group by 1;
select currency, count(*) from public.wallets group by 1;
select source_type, raison, count(*) from public.tresorerie_a_reprendre
 where traite_le is null group by 1, 2;
```

**Si des mouvements GNF ou KRW existent.**
- `tresorerie_mouvements` est en ajout seul : on écrit des écritures
  compensatoires `source_type = 'correction'`, avec motif, par une migration de
  reprise dédiée et son feu vert.
- (relecture) L'écart se calcule **ligne par ligne** : nouvelle valeur de
  `x217_montant_ref(montant_minor, devise, date)` moins `montant_ref_minor`.
- Ce n'est pas `montant_ref_minor × 99`, à cause de l'arrondi. Exemple : 4 000 GNF
  donnent 0 aujourd'hui et 47 une fois corrigé.
- Les encaissements partis en `montant_invalide` ne sont pas rejoués par
  `reprendre_alimentation_tresorerie` : ils se traitent un par un.

### Recette

**Nouveau scénario `scenarios_fi_devises_decimales.sql`.**
- 1 500 000 GNF à 0,0001 donnent 15 000 (150,00 $).
- 5 000 GNF donnent 50.
- `KMF`, `KWD`, `EUR` et `USD` donnent les valeurs attendues.
- Un taux absent rend `NULL`.
- Avant le correctif, le premier contrôle doit échouer.

**Flutter.** Nouveau `test/core/finance/decimales_devises_test.dart`.
- Il lit la dernière migration qui définit `private.devise_decimales` (idiome
  `test/support/cahier_sourates.dart:20-38`).
- Il compare les deux tables.
- (relecture) Il vérifie `formaterMontant(Montant(1823200, 'GNF'))` avec les
  caractères exacts de `format_montant.dart:26-29` : U+202F entre les milliers,
  U+00A0 avant le code.

Doivent rester verts :
- `format_montant_test.dart`, `montant_sensible_test.dart`, `paiements_test.dart` ;
- `contractuels_commun_test.dart`, `saisie_politique_test.dart`,
  `politiques_commerciales_test.dart`, `pastilles_comptable_test.dart` ;
- `scenarios_codex2_tresorerie.sql`, `scenarios_fac_e_paie_par_eleve.sql`,
  `scenarios_bf1_finance_backend.sql`, `scenarios_b18_security_definer.sql`.

### Risques

- **Changement voulu.**
  - Les nouveaux mouvements GNF et KRW valent 100 fois plus en référence USD.
  - Côté client, `KMF` passe à 0 décimale et les devises à 3 décimales passent à 3.
- **Hors périmètre.** `private.fac_prix_prepaiement` (`fac_e_01:248`, « arrondi au
  dollar ») suppose 2 décimales. Ce n'est pas une erreur d'argent : lot ultérieur.
- **Deux zones.** La migration et le miroir client vivent dans deux zones. Le test
  casse si l'un bouge sans l'autre, et c'est voulu.

---

## 7. Lot conduite : le code de conduite avant l'activation

### Constat

**La garde ignore le code.** `guard_teacher_activation_signatures()` (une seule
définition, `0089:24-82`) n'exige que le contrat (`teacher_nda`) et l'avis de
contrôle.

**L'omission était voulue, sous condition.** L'en-tête de
`20261018160000_pe_protection_enfants.sql:20-23` repousse le code à la validation
du texte. Elle est faite le 19/10 (`20261019100000_pe_code_conduite_v2.sql:3-4`).
Aucune migration postérieure ne l'a ajouté.

**Le directeur a décidé** :
- règle 9 du texte validé, « refuser veut dire pas d'élèves »
  (`fr.i18n.json:958`) ;
- une seule page d'accords, sans retour en arrière pour cocher après coup
  (`DECISION-ENTREE-2026-10-17.md:28-32`).

**L'ajout tel quel bloquerait tout.**
- La policy restrictive `contract_acceptances_code_conduite_enseignant`
  (`pe:363-374`) exige `app_account_valid()`, qui n'admet que `active` et
  `provisional_active`.
- L'enseignant invité naît `pending_kyc`.

**Côté application.**
- Le code ne s'accepte qu'au profil, donc après l'activation.
- `/attente/accords` ne le propose pas.
- `etat_dossier()` ne le connaît pas.

### Impact

Un enseignant invité :
1. voit sa pièce validée par la direction ;
2. devient actif ;
3. peut recevoir une classe ou un remplacement, **sans avoir accepté les règles de
   protection des enfants**.

Rien ne le signale à la direction.

D'après le journal (`08:94`), les migrations PE ne sont appliquées ni en
préproduction ni en production. Le défaut deviendra réel le jour où elles le
seront sans ce correctif.

### Correctif proposé

**Décision proposée.**
- Le code se signe sur `/attente/accords`, avant l'activation.
- La garde d'activation l'exige.
- Pas de garde « avant la première classe ».

Pourquoi :
- c'est la page unique de DECISION-ENTREE ;
- l'en-tête PE désignait déjà cette garde comme cible ;
- une seule garde centrale tient la règle 9 « quelle que soit la voie ». Une
  vérification à chaque RPC d'affectation laisserait passer un enseignant au
  premier oubli.

**Migration** (nom indicatif `…_pe_code_conduite_avant_activation.sql`, après les
deux migrations PE).

```sql
BEGIN;
-- 1. L'enseignant en attente accepte la version requise (enveloppe de depot
--    d'af_l1_08 : role enseignant, compte ni desactive ni supprime).
ALTER POLICY contract_acceptances_code_conduite_enseignant
  ON public.contract_acceptances
  WITH CHECK (
    contract_kind <> 'teacher_conduct_code'
    OR coalesce(
      (SELECT public.app_role()) = 'teacher'::public.app_role   -- (relecture) enveloppe L1-08
      AND version = public.code_conduite_version_requise()
      AND EXISTS (SELECT 1 FROM public.profiles p
                   WHERE p.id = auth.uid()
                     AND p.role = 'teacher'::public.app_role
                     AND p.deleted_at IS NULL
                     AND p.account_status IN ('pending_kyc'::public.account_status,
                       'provisional_active'::public.account_status,
                       'active'::public.account_status)),
      false));

-- 2. La garde exige aussi le code (corps 0089:33-70 recopie, puis) :
--    SELECT r.version INTO v_conduite_version FROM public.contract_required_versions r
--     WHERE r.contract_kind = 'teacher_conduct_code';
--    IF v_conduite_version IS NULL OR NOT EXISTS (
--      SELECT 1 FROM public.contract_acceptances c
--       WHERE c.profile_id = NEW.id AND c.contract_kind = 'teacher_conduct_code'
--         AND c.version = v_conduite_version) THEN
--      RAISE EXCEPTION USING ERRCODE = '23514',
--        MESSAGE = 'contract_not_signed_current:teacher_conduct_code';
--    END IF;
--    (SECURITY INVOKER, owner postgres, search_path '', REVOKE ALL ; declencheur inchange)

-- 3. etat_dossier() (corps l5_01:59-128 recopie) rend aussi 'code_conduite_signe',
--    vrai pour tout compte qui n'est pas enseignant. DEFINER, owner postgres,
--    search_path '', EXECUTE a authenticated seul.

-- 4. Postflight sur le modele de 0089:159-196.
COMMIT;
```

Facultatif, recommandé : une clé `code_conduite` dans `teacher_signature_statuses`
(`0089:88-153`). Ainsi la fiche de la direction dit pourquoi la validation d'une
pièce échoue.

**Client.** Aucune clé i18n nouvelle : `t.codeConduite.*` existe
(`fr.i18n.json:945-966`).

`etat_dossier.dart` :
- `codeConduiteSigne` (vrai si la clé est absente) ;
- `PieceManquante.codeConduite` ;
- `==` et `hashCode` mis à jour ;
- aucune lecture de rôle.

`attente_page.dart:225-227` : le code manquant mène aux accords.

`code_conduite.dart` : l'intro et les règles sortent dans un widget partagé par le
profil et par les accords.

`accords_page.dart` :
- une section et une case de plus ;
- (relecture) `_envoyer` reçoit un paramètre `codeConduite`, transmis par l'appel ;
- l'envoi du code se place avant `ref.invalidate(etatDossierProvider)` (`:587`).

### Reprise des données

Aucune écriture : une acceptation ne se fabrique jamais (ADR-011).

Liste en lecture seule à remettre au directeur : les enseignants en attente,
provisoires ou actifs sans le code `2026-10-19`.

```sql
select p.id, p.immutable_id, p.account_status
  from public.profiles p
 where p.role = 'teacher' and p.deleted_at is null
   and p.account_status in ('pending_kyc','provisional_active','active')
   and not exists (
     select 1 from public.contract_acceptances c
       join public.contract_required_versions r
         on r.contract_kind = c.contract_kind and r.version = c.version
      where c.profile_id = p.id and c.contract_kind = 'teacher_conduct_code');
```

### Recette

**Nouveau scénario `scenarios_pe_code_conduite_activation.sql`.**
- Un enseignant `pending_kyc` accepte la version requise. L'ancienne version est
  refusée.
- La validation de sa pièce est refusée sans le code, et le compte reste en attente.
- Elle passe après acceptation.
- L'insertion est refusée pour un compte désactivé et pour une famille.
- `etat_dossier()` rend faux puis vrai, et vrai pour un tuteur.
- Un enseignant déjà actif n'est pas bloqué dans ses mises à jour.

**Fixtures existantes (relecture).** **28** fichiers de scénarios signent puis
activent un enseignant : tous ceux qui contiennent `recording_and_control_notice`.
Dans chacun, il faut ajouter l'acceptation du code avant l'activation.

**`scenarios_etape3.sql` en fait partie** (signature `:618-637`, activation `:640`,
revérifié).
- C'est le **premier scénario de la CI** (`.github/workflows/ci.yml:55`).
- L'oublier ferait virer la CI au rouge.

Les deux contrôles d'inventaire des policies (`scenarios_af_l1_08_compte_suspendu.sql:168-183`,
`scenarios_af_l1_v_contournements.sql:563-578`) passent de 8 à 9.

**Flutter.**
- `dossier_accords_test.dart` : section, case, ordre des envois, cas « seul le code
  manque ».
- `attente_test.dart`.
- `dossier_test.dart`.

### Risques et suites

- **Ordre.** La migration suppose les deux migrations PE, à appliquer dans le même
  lot, dans l'ordre. Appliquée seule, elle échoue de façon visible (policy inconnue).
- **Inventaire de sécurité.** Une neuvième policy admet des comptes `pending_kyc`,
  dans des limites étroites :
  - enseignant seulement ;
  - son propre profil ;
  - version requise ;
  - comptes désactivés ou supprimés exclus.

  La revue de sécurité doit acter ce passage de 8 à 9.
- **Ce que le lot ne couvre pas.**
  - Les enseignants déjà actifs ou provisoires.
  - Un compte passé à la main en `provisional_active` : la garde ne joue que vers
    `active`, et ce trou existe déjà pour le contrat.
  - Une future version du code.

  Si le directeur veut « pas d'élèves » pour eux aussi, il faut un second lot. Deux
  voies :
  - la vérification aux frontières d'affectation ;
  - une redirection de re-signature, sur le modèle Q-2=a.
- **Lien avec `CAND-BR-11`.** L'engagement religieux étend la même garde. Il se
  construit après ce lot, sur la fonction redéfinie ici.

---

## 8. Ce qui n'a pas été fait

- **Rien n'a été rejoué.**
  - Aucune migration proposée n'a tourné sur un Postgres, même local.
  - Aucun scénario ni test Flutter n'a été lancé.
  - Les comptes de fixtures et les attendus sont à mesurer dans le lot, sur base
    neuve, avec les commandes de `docs/HANDOFF.md`.
- **Aucune base distante n'a été lue.** Toutes les affirmations sur la préproduction
  ou la production viennent du dépôt (instantané du 10/10, journal `08`), et non
  d'une mesure.
- **Aucune donnée personnelle** n'entre dans ce document. Les requêtes de mesure
  rendent des identifiants : elles se lancent chez l'opérateur, et leurs résultats
  ne se versent pas au dépôt.

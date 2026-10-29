# Admission, lot B : une famille et un élève adulte naissent en attente, rapport du 29/10/2026

Décision : `docs/current/DECISION-ADMISSION-2026-10-27.md`, §2 (règles 1, 2, 4, 5) et §7 (lot B).
Branche `claude/admiring-brown-r6ai72-admission-b`, depuis `origin/main` (0278546).

## Ce qui est bloqué, inconnu ou non prouvé (à lire d'abord)

1. **Le cœur du lot est côté serveur.** Correction du 29/10 : le garde-fou n'interdit que `.github/`, `vercel.json`, `pubspec.yaml` et ses propres fichiers ; la migration (`supabase/migrations/20261029120000_admission_lot_b_famille_en_attente.sql`), son scénario (`supabase/tests/scenarios_admission_lot_b.sql`), les scénarios mis à jour et le modèle d'e-mail sont donc **dans la branche**. Rejoués sur Postgres 16 local (la CI tourne en 17), **non appliqués, non testés sur staging**. Rien de ce lot n'est vrai en production tant que la migration n'est pas appliquée. Le nouveau scénario n'est pas ajouté à `.github/workflows/ci.yml` (zone interdite) : ligne à ajouter par le directeur, à côté des autres.
2. **Le type `personnel` n'est pas créé.** `candidature_types.role_compte` est obligatoire et ne porte qu'un rôle ; le personnel en a plusieurs (comptable, contrôleur, direction). Il faut une décision : un type par rôle (`personnel_comptable`, `personnel_controleur`, `personnel_direction`), ou une colonne de plus. Sans enjeu pour le lot B : le personnel entre toujours sur invitation.
3. **La confirmation d'e-mail** (`enable_confirmations`) est un réglage du tableau de bord Supabase : c'est au directeur de l'allumer (Authentication, Sign In / Providers, Email, « Confirm email »).
4. **Le plafond d'inscriptions par heure** (`candidatures.inscriptions_par_heure` = 60 en production) n'est lu par aucune des deux fonctions d'inscription des familles. Je ne l'ai pas branché : à décider avec ce lot ou au suivant.
5. **Scénarios serveur mis à jour** (rejoués chacun sur une base neuve, Postgres 16) : `scenarios_tuteur_nait_actif.sql` et `scenarios_af_l1_11_inscription_enseignant_invitation.sql` (D4 annulé : le tuteur naît en attente ; la famille est admise à la main dans la fixture avant de créer l'enfant) ; `scenarios_etape3.sql` (idem, et la fixture retire la demande de la famille pour dérouler l'ancien parcours de pièce) ; `scenarios_l5_usage_inscription.sql` et `scenarios_imm_back_1_registrations.sql` (le genre est désormais exigé) ; `scenarios_cand_l1_socle.sql` et `scenarios_cand_l2a2_gestes_direction.sql` passent tels quels, la migration mettant à jour les empreintes F86 des fonctions recréées. Bilan : 127 scénarios verts ; 7 rouges, qui l'étaient déjà sans la migration (Postgres 16 local ou scénario dépendant d'un autre).
6. Une famille en attente ne peut pas encore créer les profils de ses enfants (`creer_profil_enfant` exige un tuteur actif). **Tranché le 29/10 (Q2)** : les enfants partent avec la demande (`candidature_apprenants`, ci-dessous) ; leurs profils seront créés à l'acceptation (lot C). Aucun écran de la direction ne lit encore ces lignes (lot C).
7. Les compteurs du tableau de bord de la direction qui comptent les candidatures sans filtre de type compteront aussi les familles. Non vérifié un par un.

## Refonte de l'onboarding (fiche `FICHE-ONBOARDING-2026-10-29.md`, validée le 29/10 par le pilote sur délégation du directeur)

### Ce qui n'est pas vrai, ou pas prouvé, d'abord

1. **Rien n'est prouvé en production ni sur staging** : tests locaux seulement. La nouvelle migration (`20261029150000_admission_lot_b_apprenants.sql`) contient un `DROP FUNCTION` (remplacement de la signature de `inscrire_titulaire`) : le directeur la colle dans l'éditeur SQL de staging, après celle du 29/10 matin (page de collage à fabriquer au moment de la mise en staging).
2. **La langue du cours est avant le compte** (directeur, 29/10 au soir, par le pilote : toutes les questions avant la création du compte). La liste des langues de cours actives est lue sans compte par `public.langues_cours_publiques()` (migration `20261029180000_langues_cours_publiques.sql`) : code et libellé des seules langues actives, rien d'autre ; la table `langues_cours` reste fermée à `anon`. Une fonction plutôt qu'une politique RLS : la RLS borne les lignes, pas les colonnes, et la lecture filtre et trie sur deux autres colonnes, qu'`anon` aurait alors pu lire. Scénario : `supabase/tests/scenarios_langues_cours_publiques.sql`.
3. **L'âge commence à 5 ans, pas 4** : la première cohorte du serveur est `enfant_5_7` ; un âge de 4 ans ne correspondrait à aucune classe.
4. **Sur le web, les réponses attendent la connexion dans le stockage du navigateur** (`localStorage`) : c'est ce qui permet au lien de connexion, souvent ouvert dans un nouvel onglet, de les retrouver. Le prénom et l'âge d'un enfant y restent jusqu'à l'envoi de la demande, puis sont effacés. Sur un autre appareil, ou si le navigateur a effacé ses données, la famille reprend les premières questions (le récapitulatif le dit).
5. **Le pays et le fuseau** (ligne « détectés de l'appareil » de la fiche) ne sont pas une étape : le fuseau reste celui que le serveur pose aujourd'hui. Non fait.
6. **« Classes non mixtes »** : le genre de chaque enfant et du titulaire est demandé et rangé avec la demande ; le regroupement ne s'en sert pas encore (réglage de mixité par classe : lot « créneaux », décision D1 du 29/10).
7. **La revue UX détaillée** est dans `docs/current/UX_REVIEW_ONBOARDING.md`.

### Le parcours, tel qu'il est codé

- **Avant le compte** (`/commencer`, une question par écran, « n sur N », un seul bouton plein « Continuer », retour en disque) : « Pour qui créez-vous ce compte ? » (deux choix égaux ; liens « J'ai déjà un compte » et « J'ai un code d'invitation ») ; pour chaque enfant, son prénom, son âge (puces de 5 à 17 ans, et « 18 ans ou plus », qui dit de s'inscrire soi-même), son genre (« Un garçon », « Une fille »), son niveau ; « Suivez-vous aussi des cours ? » ; le niveau du titulaire s'il apprend ; l'objectif ; les moments de la journée. Chaque enfant de plus ajoute quatre écrans (Q5).
- **Créer un compte** passe d'abord par ces questions (`/connexion?mode=creer` y renvoie tant qu'elles ne sont pas répondues), sauf avec un code d'invitation.
- **Avant le compte, aussi** : la langue du cours (après « Suivez-vous aussi des cours ? »). « Pour moi » : cinq écrans ; une famille d'un enfant : neuf.
- **Après la connexion** : « Comment vous appelez-vous ? », « Vous êtes » (genre du titulaire), puis « Voici ce que nous avons compris » : pour qui, le parent, chaque apprenant et son niveau, la langue, l'identité, le genre, chaque ligne avec « Modifier » ; « Ajouter un autre profil élève » ; « Envoyer ma demande ».
- **Envoi** : `inscrire_titulaire` reçoit les apprenants (`p_apprenants`) et les range avec la demande dans la même transaction ; les réponses quittent l'appareil.
- **Page d'attente** : « Votre demande porte sur : Yasmine, 9 ans · Vous. » (relu par `mes_apprenants_demande()`).
- L'enseignant et le comptable gardent leur chemin (étape « usage », code d'invitation), inchangé.

### Serveur (`supabase/migrations/20261029150000_admission_lot_b_apprenants.sql`)

- `public.candidature_apprenants` : une ligne par apprenant (rang, titulaire ou non, prénom, âge de 5 à 17 ans pour un enfant, genre, niveau déclaré, objectif, moments, langue). RLS active, **aucune politique ni aucun droit client** : on la lit par fonction, comme les autres tables des candidatures.
- `public.inscrire_titulaire(..., p_apprenants jsonb)` : 6 apprenants au plus ; « pour moi » n'a que le titulaire ; une famille a au moins un enfant ; le titulaire porte son prénom et son genre de compte, jamais ceux du JSON. Un refus ne laisse rien.
- `public.mes_apprenants_demande()` : le titulaire relit prénom, âge et rang des apprenants de **sa** demande.
- Scénario `supabase/tests/scenarios_admission_lot_b_apprenants.sql` (vert, Postgres 16 local) ; `scenarios_l5_usage_inscription.sql` et `scenarios_af_liste_blanche_volatiles.sql` suivent la nouvelle signature. La liste blanche reste rouge pour deux fonctions qui ne sont pas de ce lot (`ajouter_creneau_classe_admin`, `seance_a_rejoindre`), comme avant.

### Tests (Flutter)

- `test/features/inscription/questionnaire_test.dart` : l'ordre et le nombre des écrans (Q5), la relecture des réponses, ce qui part au serveur, le parcours complet d'une famille jusqu'à la création du compte, « 18 ans ou plus », une adresse ouverte trop tôt, le retour qui retire un enfant ajouté vide, « J'ai déjà un compte », la règle « créer un compte passe par le questionnaire ».
- `test/features/inscription_test.dart` : après la connexion, langue, identité, genre, récapitulatif ; les apprenants partent avec la demande (« pour moi », famille avec et sans parent qui apprend).
- `test/features/attente_test.dart` : « Votre demande porte sur ».
- `test/features/connexion_test.dart` : la création suit le questionnaire.

### Ce que le directeur vérifie, après fusion et migration (en gestes simples)

1. Sur un téléphone, ouvrir l'application sans être connecté, toucher « Créer un compte » : la question « Pour qui créez-vous ce compte ? » s'affiche.
2. Choisir « J'inscris mon enfant », répondre : prénom, âge, « Une fille », niveau, « Non », langue du cours, objectif, « Le soir ». Compter les écrans : neuf.
3. Saisir son adresse, ouvrir le lien reçu (même dans un autre onglet) : l'application demande seulement le nom et le genre, sans reposer les premières questions.
4. Finir (nom, genre) : le récapitulatif montre l'enfant, son âge et son niveau. Toucher « Envoyer ma demande » : la page « Votre demande est en cours » dit « Votre demande porte sur : (prénom), (âge) ans ».
5. Recommencer avec « Je m'inscris pour moi » : cinq écrans avant l'adresse.

## Ce que fait ce lot dans l'application (codé, testé localement)

### Ajout du directeur du 29/10 : l'entrée de l'élève adulte

Constat du 28/10 : une élève adulte s'est perdue à l'onboarding ; elle a choisi « Moi et ma famille », puis a dû ajouter un profil élève pour être placée dans une classe.

- **Premier écran** : « Pour qui créez-vous ce compte ? », deux grands choix égaux, côte à côte, en haut : « Je m'inscris pour moi » (« Vous suivez les cours vous-même. Votre profil élève est créé avec votre compte. ») et « J'inscris mon enfant » (« Vous inscrivez un ou plusieurs enfants et suivez leurs progrès. Vous pouvez aussi suivre des cours vous-même. »). Le parcours enseignant reste dessous, à part (« J'ai un code d'invitation »). Le composant commun `ChoiceCardGroup` gagne `choixEgaux` : jamais le bento inégal pour ce choix, à toutes les largeurs ; à 320 points en texte ×2, les cartes s'empilent plutôt que de couper un mot.
- **Profil élève titulaire** : déjà créé par le serveur pour « pour moi » (`inscrire_titulaire('moi')` pose `p_parent_suit_des_cours`, fiche `autonomous`). Rien à écrire côté serveur.
- **Le tuteur qui suit lui-même des cours** : la question « Suivez-vous aussi des cours ? » existe déjà sous « J'inscris mon enfant », sans faux enfant. Rien à changer.
- **Atterrissage, lacune trouvée** : un titulaire « pour moi » admis arrivait sur l'accueil du **tuteur** (`/tuteur`, racine du rôle) ; seul `/eleve` menait à l'accueil adulte. Désormais, un titulaire élève autonome inscrit « pour moi » (usage lu par `etat_dossier()`) atterrit sur l'accueil adulte (`/eleve/adulte`), et l'accueil du tuteur l'y renvoie. Le parent qui suit aussi des cours garde l'accueil du tuteur.
- **Non fait, dit au pilote** : la barre « Aujourd'hui · Apprendre · Suivi · Profil » n'existe nulle part dans le code. Sous `/eleve`, l'adulte a la barre de l'élève (Accueil, Ma classe, Coran, Mon espace). La créer change la coquille de navigation commune et l'ordre de ses branches : lot à part, sur décision.

Tests : `test/features/inscription_choix_egaux_test.dart` (390 et 1440 côte à côte, 320 en texte ×2 empilées), `test/features/inscription_test.dart` (textes du mandat ; « pour moi » envoie l'usage `moi` et le profil élève), `test/core/widgets/choice_card_group_bento_test.dart` (à 1440, les deux cartes de même taille), `test/features/accueil_adulte/atterrissage_adulte_test.dart` (vrai routeur : « pour moi » sur l'accueil adulte, parent qui suit des cours sur l'accueil du tuteur ; règles de redirection).

- La page d'attente d'un tuteur (famille ou élève adulte) dit : « Votre demande est en cours », « La direction lit chaque demande avant d'ouvrir un compte. », « Vous n'avez rien à envoyer. Nous vous écrivons à votre adresse e-mail dès que la direction a répondu. » Avant : « L'ouverture de votre compte n'est pas encore automatique », et « joignez l'académie ».
- La page d'attente d'un tuteur ignore la demande d'admission pour son affichage : elle ne montre jamais les salles d'examen, la tuile de partage ni « Vos autres talents », qui ne concernent que les enseignants.

## La migration (`supabase/migrations/20261029120000_admission_lot_b_famille_en_attente.sql`)

Le texte ci-dessous est la première version ; celle du dépôt y ajoute la mise à jour des empreintes F86, et la file ADM-20 y écarte les seuls types `famille` et `eleve_adulte` (au lieu de ne garder que `enseignant`, ce qui cachait aussi d'autres types).

Écrite à partir des définitions **lues en production le 29/10/2026** (`private.creer_profil_inscription_interne`, `public.inscrire_titulaire`, `public.lister_candidatures`, `public.courriel_enfiler`). Aucun `DELETE`, `DROP` ni `TRUNCATE`.

```sql
-- ADMISSION lot B (decision du directeur du 27/10/2026,
-- docs/current/DECISION-ADMISSION-2026-10-27.md §2 et §7) : personne n'entre
-- sans decision de la direction. Annule D4 (20261024160000_tuteur_nait_actif).
--
-- 1. Deux types de demande : famille et eleve_adulte (compte tuteur).
-- 2. private.creer_profil_inscription_interne : le tuteur nait en attente
--    (pending_kyc) avec sa demande (etape recue), et l'e-mail « demande
--    recue » part par la file. Le reste est identique a la version du 24/10.
-- 3. public.inscrire_titulaire : « Moi » fait de la demande une demande
--    d'eleve adulte.
-- 4. public.lister_candidatures : sans type demande, la file reste celle des
--    enseignants (ADM-20 n'envoie aucun type) ; les listes des familles
--    viendront au lot C.
-- Les tuteurs deja actifs ne changent pas.

BEGIN;

INSERT INTO public.candidature_types (code, role_compte)
VALUES ('famille', 'guardian'), ('eleve_adulte', 'guardian')
ON CONFLICT (code) DO NOTHING;

CREATE OR REPLACE FUNCTION private.creer_profil_inscription_interne(
  p_role text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL::public.gender,
  p_timezone text DEFAULT 'Europe/Paris'::text,
  p_parent_suit_des_cours boolean DEFAULT false
)
RETURNS public.profiles
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
declare
  v_uid uuid := auth.uid();
  v_role public.app_role;
  v_household uuid;
  v_profile public.profiles;
  v_candidature public.candidatures;
begin
  if v_uid is null then raise exception 'aucune session'; end if;
  if p_role not in ('guardian', 'teacher') then
    raise exception 'role non ouvert a l''inscription publique : %', p_role;
  end if;
  v_role := p_role::public.app_role;
  if v_role <> 'guardian' and coalesce(p_parent_suit_des_cours, false) then
    raise exception 'profil apprenant personnel reserve au titulaire';
  end if;
  if exists (select 1 from public.profiles p where p.id = v_uid) then
    raise exception 'ce compte a deja un profil';
  end if;
  if coalesce(btrim(p_first_name), '') = '' or coalesce(btrim(p_last_name), '') = '' then
    raise exception 'prenom et nom sont requis';
  end if;
  -- La demande recopie le genre du compte (candidatures.genre, NOT NULL).
  if v_role = 'guardian' and p_gender is null then
    raise exception 'genre requis' using errcode = '22023';
  end if;

  if v_role = 'guardian' then
    insert into public.households (timezone)
    values (coalesce(nullif(btrim(p_timezone), ''), 'Europe/Paris'))
    returning id into v_household;
  end if;
  -- Admission (27/10) : tout compte nait en attente de la decision.
  insert into public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, gender, account_status)
  values (v_uid, null, v_role, v_household,
    btrim(p_first_name), btrim(p_last_name), p_gender, 'pending_kyc')
  returning * into v_profile;

  if v_role = 'guardian' then
    update public.households set primary_guardian_id = v_uid where id = v_household;
    if coalesce(p_parent_suit_des_cours, false) then
      insert into public.student_profiles
        (profile_id, titulaire_profile_id, student_type, interface_mode,
         camera_policy, cohorte)
      values (v_uid, v_uid, 'autonomous', 'standard', 'forbidden', 'adulte_18_plus');
      perform public.log_sensitive_access(
        'profil_eleve_titulaire_cree', 'student_profiles', v_uid::text,
        jsonb_build_object('student_type', 'autonomous', 'source', 'inscription')
      );
    end if;
    -- La demande d'admission, une par compte et par type.
    insert into public.candidatures (type_code, profile_id, genre, nom_complet, source)
    values ('famille', v_uid, p_gender,
      btrim(p_first_name) || ' ' || btrim(p_last_name), 'lien_public')
    returning * into v_candidature;
    perform public.courriel_enfiler(
      'inscription', 'admission_recue', public.courriel_adresse_profil(v_uid), v_uid,
      jsonb_build_object('reference', v_candidature.reference),
      'admission_recue:' || v_candidature.id::text);
  else
    insert into public.teacher_profiles (profile_id) values (v_uid);
  end if;
  perform public.log_sensitive_access('profil_cree', 'profiles', v_uid::text,
    jsonb_build_object('role', v_role::text));
  return v_profile;
end;
$function$;

CREATE OR REPLACE FUNCTION public.inscrire_titulaire(
  p_usage text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL,
  p_timezone text DEFAULT 'Europe/Paris',
  p_suit_des_cours boolean DEFAULT false
) RETURNS public.profiles
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_profile public.profiles;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'aucune session'; END IF;
  IF NOT coalesce(p_usage IN ('moi', 'famille'), false) THEN
    RAISE EXCEPTION 'usage inconnu : %', p_usage USING ERRCODE = '22023';
  END IF;
  v_profile := private.creer_profil_inscription_interne(
    'guardian', p_first_name, p_last_name, p_gender, p_timezone,
    p_usage = 'moi' OR coalesce(p_suit_des_cours, false));
  UPDATE public.households h
     SET usage_inscription = p_usage
   WHERE h.id = v_profile.household_id;
  -- « Moi » : la demande est celle d'un eleve adulte (liste separee, lot C).
  IF p_usage = 'moi' THEN
    UPDATE public.candidatures c
       SET type_code = 'eleve_adulte'
     WHERE c.profile_id = v_profile.id AND c.type_code = 'famille';
  END IF;
  RETURN v_profile;
END;
$function$;

-- La file des enseignants reste celle des enseignants : sans type demande,
-- lister_candidatures lit le type « enseignant ». Une seule ligne change ; le
-- bloc refuse de continuer si elle n'est pas trouvee telle quelle.
DO $do$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(
    'public.lister_candidatures(jsonb,text,integer)'::pg_catalog.regprocedure);
  v_avant text := 'v_type := v_filtre ->> ''type'';';
  v_apres text := 'v_type := coalesce(v_filtre ->> ''type'', ''enseignant'');';
BEGIN
  IF pg_catalog.strpos(v_def, v_avant) = 0
     OR pg_catalog.strpos(pg_catalog.substr(v_def, pg_catalog.strpos(v_def, v_avant) + 1), v_avant) <> 0 THEN
    RAISE EXCEPTION 'lister_candidatures : la ligne du type a change, migration a revoir';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);
END;
$do$;

COMMIT;
```

Points relus : `CREATE OR REPLACE` garde les droits et les commentaires des trois fonctions ; la règle `private.candidature_compte_conforme` accepte un tuteur `pending_kyc` rattaché à une demande `famille` à l'étape `recue` (rôle du type `guardian`, compte ni `active` ni `provisional_active`) ; le déclencheur `candidatures_genre_du_compte` recopie le genre du compte ; `courriel_enfiler` rend `NULL` sans adresse et ne lève jamais, il ne bloque donc pas l'inscription ; la clé d'idempotence empêche un second e-mail.

## Rejoué en local

Postgres 16 local (la CI tourne en 17 ; pas de démon Docker ici) : `supabase/tests/stub_auth.sql`, les 269 migrations du dépôt, puis celle-ci, sans erreur. Le scénario ci-dessous, à poser dans `supabase/tests/scenarios_admission_lot_b.sql` et dans `.github/workflows/ci.yml`, passe :

```
NOTICE:  ADM-B OK : famille et eleve adulte en attente, demandes recues, e-mails en file, activation refusee
NOTICE:  ADM-B OK : sans genre, refus net
NOTICE:  ADM-B OK : la file sans type lit les enseignants
```

```sql
-- ADMISSION lot B (decision du 27/10/2026) : une famille et un eleve adulte
-- naissent en attente avec leur demande ; l'e-mail « demande recue » est en
-- file ; la file des enseignants ne montre pas les familles.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Fixtures sans donnee personnelle ; tout est annule a la fin. Un echec leve
-- 'ADM-B ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('ab000000-0000-4000-8000-000000000001', 'adm-b-famille@example.test'),
  ('ab000000-0000-4000-8000-000000000002', 'adm-b-adulte@example.test'),
  ('ab000000-0000-4000-8000-000000000003', 'adm-b-sansgenre@example.test');

-- Une famille s'inscrit.
SELECT set_config('request.jwt.claim.sub', 'ab000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'ab000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Famille', 'female', 'Europe/Paris', false);
RESET ROLE;

-- Un eleve adulte s'inscrit (« Moi »).
SELECT set_config('request.jwt.claim.sub', 'ab000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'ab000000-0000-4000-8000-000000000002', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('moi', 'Fixture', 'Adulte', 'male', 'Europe/Paris', false);
RESET ROLE;

DO $controles$
DECLARE
  v_n integer;
BEGIN
  IF (SELECT p.account_status FROM public.profiles p
       WHERE p.id = 'ab000000-0000-4000-8000-000000000001') <> 'pending_kyc' THEN
    RAISE EXCEPTION 'ADM-B ROUGE : la famille ne nait pas en attente';
  END IF;
  IF (SELECT p.account_status FROM public.profiles p
       WHERE p.id = 'ab000000-0000-4000-8000-000000000002') <> 'pending_kyc' THEN
    RAISE EXCEPTION 'ADM-B ROUGE : l''eleve adulte ne nait pas en attente';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.candidatures c
                  WHERE c.profile_id = 'ab000000-0000-4000-8000-000000000001'
                    AND c.type_code = 'famille' AND c.etape = 'recue'
                    AND c.issue = 'en_cours' AND c.source = 'lien_public'
                    AND c.genre = 'female') THEN
    RAISE EXCEPTION 'ADM-B ROUGE : la demande de la famille manque';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.candidatures c
                  WHERE c.profile_id = 'ab000000-0000-4000-8000-000000000002'
                    AND c.type_code = 'eleve_adulte' AND c.etape = 'recue') THEN
    RAISE EXCEPTION 'ADM-B ROUGE : la demande de l''eleve adulte manque ou n''a pas son type';
  END IF;
  SELECT count(*) INTO v_n FROM public.courriels_sortants s
   WHERE s.modele = 'admission_recue' AND s.categorie = 'inscription'
     AND s.destinataire_profil IN ('ab000000-0000-4000-8000-000000000001',
                                   'ab000000-0000-4000-8000-000000000002');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'ADM-B ROUGE : % e-mail(s) « demande recue » en file, 2 attendus', v_n;
  END IF;
  -- Un compte en attente avec sa demande ne s'active pas avant la decision.
  BEGIN
    UPDATE public.profiles SET account_status = 'active'
     WHERE id = 'ab000000-0000-4000-8000-000000000001';
    RAISE EXCEPTION 'ADM-B ROUGE : la famille a pu etre activee sans decision';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
  RAISE NOTICE 'ADM-B OK : famille et eleve adulte en attente, demandes recues, e-mails en file, activation refusee';
END
$controles$;

-- Sans genre, l'inscription est refusee (la demande en exige un).
SELECT set_config('request.jwt.claim.sub', 'ab000000-0000-4000-8000-000000000003', true);
SELECT set_config('test.uid', 'ab000000-0000-4000-8000-000000000003', true);
DO $sans_genre$
BEGIN
  PERFORM public.inscrire_titulaire('famille', 'Fixture', 'SansGenre', NULL, 'Europe/Paris', false);
  RAISE EXCEPTION 'ADM-B ROUGE : inscription sans genre acceptee';
EXCEPTION WHEN invalid_parameter_value THEN
  RAISE NOTICE 'ADM-B OK : sans genre, refus net';
END
$sans_genre$;

-- La file des enseignants (sans type demande) ne montre pas les familles.
DO $file$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(
    'public.lister_candidatures(jsonb,text,integer)'::pg_catalog.regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, 'coalesce(v_filtre ->> ''type'', ''enseignant'')') = 0 THEN
    RAISE EXCEPTION 'ADM-B ROUGE : lister_candidatures ne borne pas la file aux enseignants';
  END IF;
  RAISE NOTICE 'ADM-B OK : la file sans type lit les enseignants';
END
$file$;

ROLLBACK;
```

## Le modèle d'e-mail (posé : `modeles_fr.ts`, `modeles_ar.ts`, traduit à l'envoi vers les autres langues ; `deno test` : 24 verts)

Dans `MODELES`, après `demande_recue` :

```ts
  admission_recue: (d) => avis(d, 'Votre demande est bien reçue', 'Votre demande est en cours',
    'Nous avons bien reçu votre demande. La direction lit chaque demande avant d’ouvrir un compte. Vous n’avez rien à envoyer : nous vous écrivons à cette adresse dès que la direction a répondu.',
    'Voir ma demande', '/attente'),
```

et l'ajouter à `TRADUITS_A_L_ENVOI` (`['attente_candidat', 'admission_recue']`) pour qu'il parte traduit dans la langue de la personne. Le test `courriel_test.ts` liste les modèles : l'y ajouter. Sans ce modèle, la ligne reste dans la file en échec, l'inscription n'est pas bloquée.

## Ce que le directeur fait pour prouver le lot B, après fusion et migration

Les inscriptions restent fermées en production (décision, §6) : la preuve se fait avec une famille test.

1. Allumer « Confirm email » dans Supabase.
2. S'inscrire comme famille test, confirmer l'adresse.
3. Après les conditions à accepter, la page dit « Votre demande est en cours » ; aucune autre page n'est atteignable (taper `/tuteur` dans l'adresse ramène à la page d'attente) : vrai. Sinon : faux, capture.
4. L'e-mail « Votre demande est bien reçue » arrive : vrai. Sinon : faux, capture.
5. S'inscrire comme élève adulte test : le premier écran montre « Je m'inscris pour moi » et « J'inscris mon enfant », côte à côte. Choisir « pour moi ». Après l'admission (lot C, ou à la main en attendant), la connexion ouvre l'accueil de l'élève adulte, sans « Ajouter un profil élève » : vrai. Elle ouvre l'accueil du tuteur : faux, capture.

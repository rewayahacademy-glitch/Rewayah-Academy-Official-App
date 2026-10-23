# L1-02-reprise - `profils_du_foyer_v` : un enfant lit le profil de ses frères et soeurs

Vague 1, reprise ouverte par L1-V (vérification croisée, nuit du 16 au 17/10/2026). Défaut signalé par l'agent L1-02 sous le nom de `student_profiles_family` ; L1-V l'a reproduit, mais par la vue, pas par la table.

## 1. But et pourquoi (P0-2 partie fratrie, doc maître 28.1 : l'enfant ne voit rien de sa fratrie)

- Ce que l'agent L1-02 a écrit : « student_profiles_family laisse un enfant lire le profil de ses frères (type, caméra, niveau) ». Réfuté pour la table : la policy `student_profiles_family` filtre par une sous-requête sur `profiles`, elle-même soumise à la RLS de l'enfant (`profiles_self_select` seulement), donc la ligne de la soeur est invisible. Preuve : `scenarios_af_l1_v_contournements.sql`, bloc C8, « L1-V OK C8 : student_profiles de la soeur invisible par la table ».
- Ce qui fuit réellement : la vue `public.profils_du_foyer_v` (propriétaire `postgres`, donc sans RLS sous-jacente) ne filtre que par `household_id = app_household_id()` et `role = 'student'`, sans rôle de l'appelant ni `app_account_valid()`. Un enfant y lit pour chaque frère ou soeur : prénom, matricule (`immutable_id`), `interface_mode`, `camera_policy`, `avatar_storage_key`, `access_until`. Preuve : bloc C9, « L1-V DEFAUT C9 : enfant lit profils_du_foyer_v de sa soeur (prenom, matricule, camera, interface, fin d'acces) : 1 ligne ».
- Classement : P2. Même règle que P0-2 fratrie (l'enfant ne voit rien de sa fratrie), mais lecture seule, à l'intérieur du foyer, sans finances, sans séances, sans cahier ; l'enfant ne peut rien en écrire (bloc C5 et C7 : 0 ligne, 42501).
- Un compte suspendu du foyer lit aussi cette vue (aucune garde de compte).

Point à arbitrer, même reprise (constat C12, pas un défaut de la vague) : la branche tuteur des policies de foyer fait confiance au claim `household_id` signé, sans recouper `profiles.household_id` ; si l'administration change le foyer d'un tuteur, l'ancien jeton (une heure au plus) lit encore l'ancien foyer. La branche élève adulte recoupe déjà, par la sous-requête `student_profiles` (bloc C11).

## 2. Critère de réussite

C'est fini quand :

1. une migration horodatée recrée `profils_du_foyer_v`, mêmes colonnes dans le même ordre, `security_barrier` conservé, avec la clause d'accès : `public.app_account_valid() and (public.app_role() = 'guardian' or (public.app_role() = 'student' and p.id = auth.uid()))` en plus de l'appartenance au foyer ;
2. dans `scenarios_af_l1_v_contournements.sql`, la NOTICE « L1-V DEFAUT C9 » devient une exception et le scénario passe ;
3. un tuteur du foyer lit toujours ses enfants dans la vue (ajouter le contrôle au même scénario : 2 lignes pour le tuteur F1) ;
4. l'écran d'appairage (`lib/core/appairage/service_appairage.dart:202`, appelé par le tuteur) n'a rien à changer : vérifié par lecture ;
5. 15 scénarios CI PASS, chaque scénario PASS sur base neuve, liste blanche PASS.

Facultatif après décision du directeur : ajouter `public.app_role() = 'guardian'` à `student_profiles_family` (défense en profondeur, sans changement visible aujourd'hui) ; recouper `household_id` avec `profiles` pour la branche tuteur (C12).

## 3. Ce qu'il faut lire

- `docs/audit-final/verifications/L1-V-2026-10.md` (défaut D-2).
- `supabase/tests/scenarios_af_l1_v_contournements.sql`, bloc C.
- `pg_get_viewdef('public.profils_du_foyer_v', true)` dans la base rejouée (dernière définition : `0014_acces_agent.sql:828`, masquage d'agent à conserver).
- `lib/core/appairage/service_appairage.dart` (seul lecteur côté client).

## 4. Fichiers autorisés et interdits

Autorisés : `supabase/migrations/2026101712xxxx_af_l1_02_reprise_*.sql` (nouveau), `supabase/tests/scenarios_af_l1_v_contournements.sql` (C9 en exception, contrôle tuteur).

Interdits : toute migration existante, `lib/`, `.github/`.

## 5. Étapes

1. Base neuve ; exporter la définition actuelle de la vue (avec `agent_identite_masquee()`).
2. Migration : `create or replace view` par copie exacte, une clause ajoutée ; `begin;`/`commit;` ; postflight qui vérifie que la définition contient `guardian` et `app_account_valid`.
3. Rejouer ; scénario L1-V : C9 en « OK ».
4. C9 en exception ; contrôle tuteur ajouté ; vérifier que le scénario ÉCHOUE sans la nouvelle migration.

## 6. Vérifications

- `\d+ public.profils_du_foyer_v` identique avant et après.
- 15 scénarios CI, chaque scénario sur base neuve, liste blanche.
- `git diff --stat` limité aux fichiers autorisés.

## 7. Pièges connus

- Ne pas ajouter de sous-requête sur `student_profiles` dans une policy de `student_profiles` (récursion) ; ici c'est une vue, la question ne se pose pas.
- `agent_ro` lit la vue avec le rôle de son jeton : la clause par rôle s'applique aussi à lui, comme dans `mes_seances_v` (L1-04).
- Une affirmation d'agent (« la table fuit ») se vérifie avant de devenir une fiche : ici c'était la vue.

## 8. Quand s'arrêter et demander

- Si un écran d'élève lit `profils_du_foyer_v` (grep) : s'arrêter, nommer l'écran.
- Le recoupement du claim `household_id` (C12) change toutes les policies de foyer : ne pas le faire sans décision datée du directeur.

## 9. Commit

- Branche : `lots/L1-02-reprise-profils-foyer`, partie de `claude/backend-reprise` après fusion de la vague 1.
- Message : `fix(securite): profils_du_foyer_v reserve au tuteur et a l eleve lui-meme (L1-02-reprise, P0-2)`.
- Jamais de push sur `main`. PR brouillon vers `claude/backend-reprise`.

## 10. Modèle conseillé

Zone backend. Difficulté : Haiku suffit (copie exacte, une clause).

Esprit : la RLS ne protège pas une vue propriété de `postgres` ; c'est la vue qui porte la règle.

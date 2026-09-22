# Contrat serveur — onboarding, offres horaires vitrines, intentions

**22 septembre 2026.** Tout ce que décrit ce document est **livré** dans
`supabase/migrations/0043_offres_horaires_et_intentions.sql`. Ce n'est donc pas
une demande adressée à un autre agent : c'est le contrat de ce qui existe, à
lire avant d'y toucher.

⚠️ **La migration n'est pas appliquée à la production.** Tant qu'elle ne l'est
pas, l'application appelle des RPC absentes et l'écran des horaires reste en
erreur.

---

## 0. Ce qui a été réutilisé plutôt que recréé

Le brief demandait explicitement de ne pas imposer une table nouvelle quand un
modèle équivalent existe. Bilan :

| Besoin | Ce qui existait | Décision |
| :--- | :--- | :--- |
| Signal de demande non satisfaite | `matching_requests` + `ADM-06` | **Réutilisé.** `CHECK` élargi d'une sorte, table à 0 ligne |
| Capacités, minimum, durées | `app_config` + `app_config_int()` | **Réutilisé.** 8 clés ajoutées |
| Journalisation | `log_sensitive_access()` | **Réutilisé** par les 5 RPC d'écriture |
| Conversion jour + heure + fuseau → instant | `instant_creneau()` | **Réutilisé** par `offres_compatibles` |
| Création d'un groupe, ajout d'un élève | `creer_groupe`, `ajouter_eleve_groupe` | **Réutilisés** par `publier_groupe_depuis_offre` |
| Rôle et foyer depuis le jeton | `app_role()`, `app_household_id()` | **Réutilisés** |
| Carte d'horaire à l'écran | `ScheduleOption` | **Réutilisé** |
| Motif d'offre vitrine | *rien* | **Créé** — voir §2 pour les trois obstacles mesurés |
| Préférence d'horaire d'un élève | *rien* | **Créée** — intégrité référentielle vers l'offre |
| Trois séances hebdomadaires d'un groupe | *rien* | **Créée** — `groupes.weekday` est un jour unique |

---

## 1. La porte d'accès : `compte_en_parcours()`

**Le problème mesuré.** `app_account_valid()` refuse `pending_kyc`, et les
policies d'écriture de `student_profiles` l'exigent. Le foyer qui s'onboarde est
par construction `pending_kyc`. Sans correction, ce lot aurait refusé en silence
toute écriture à sa population cible.

```sql
create or replace function public.compte_en_parcours()
returns boolean language sql stable security definer set search_path = ''
as $function$
  select coalesce((
    select p.deleted_at is null
       and p.account_status in ('pending_kyc','active','provisional_active')
       and (p.access_until is null or p.access_until > now())
    from public.profiles p where p.id = auth.uid()), false);
$function$;
```

**Ce qu'elle ouvre** : décrire un apprenant de son propre foyer, lire les
offres compatibles, enregistrer une préférence.

**Ce qu'elle n'ouvre pas** : un groupe, une séance, un jeton vidéo, un autre
foyer, une colonne académique. `ajouter_eleve_groupe` exige toujours
`active`/`provisional_active`.

**Aucune policy ni fonction antérieure n'a été modifiée.**

`peut_decrire_apprenant(p_profile_id uuid)` ajoute la portée : le profil est
celui de l'appelant, ou celui d'un membre de son foyer.

---

## 2. Pourquoi trois tables nouvelles, et pas zéro

| Obstacle mesuré le 22/09/2026 | Conséquence |
| :--- | :--- |
| `groupes.teacher_id` est `NOT NULL` | Une offre sans enseignant ne peut pas être un groupe. Relâcher la colonne traverse toute policy et RPC qui tient un groupe pour enseigné |
| `groupes.weekday` est **un** jour | Trois séances hebdomadaires = trois lignes = un roster coupé en trois et un plafond compté trois fois |
| `groupes` n'a pas de langue d'enseignement | Le critère dur d'ADR-029 n'a nulle part où vivre |

→ `offres_horaires`, `intentions_horaire`, `groupe_creneaux`.

---

## 3. Les objets livrés

### 3.1 Référentiels

| Table | Contenu | RLS |
| :--- | :--- | :--- |
| `langues_cours` | `poular`, `francais`, `english` | lecture `authenticated` + `agent_ro` ; écriture `admin` |
| `cohortes_age` | `enfant_5_7`, `enfant_8_10`, `ado_11_14`, `ado_15_17`, `adulte_18_plus` | idem |

`cohortes_age` porte `type_public`, `student_type` et `interface_mode` :
**c'est le serveur qui déduit**, jamais le client.

### 3.2 `offres_horaires` — la vitrine

```
id, type_public, langue_code, programme_niveau_id (NULLABLE),
jours smallint[], heure_locale, fuseau_iana, duree_minutes, rythme,
etat ('brouillon' | 'publiee' | 'retiree'), …
```

**Ce que cette table n'a pas, et n'aura pas** : `teacher_id`, `nombre_inscrits`,
`places_restantes`, `groupe_id`. L'interdiction d'affichage est tenue par
l'absence de colonne, pas par une règle d'écran.

Index unique partiel `offres_horaires_motif_unique … where etat <> 'retiree'` :
deux offres identiques ne peuvent pas coexister, une offre retirée ne bloque pas
sa recréation.

`programme_niveau_id` est nullable parce que `programme_niveaux` est vide en
production ; une offre sans niveau est compatible avec tout le monde.

### 3.3 `intentions_horaire` — la préférence

Porte **la preuve de ce qui a été montré** au moment du choix :
`fuseau_affiche`, `heure_affichee`, `jours_affiches`. Sans elle, impossible de
détecter plus tard qu'un déménagement a décalé l'heure perçue.

Index unique partiel : **une seule intention vivante par élève**, en miroir de la
règle « un seul groupe actif par élève ».

`groupe_id` reste `NULL` jusqu'à l'affectation réelle.

### 3.4 `groupe_creneaux` + trigger `groupe_creneau_ancre()`

Le trigger maintient `groupes.weekday`/`hour_local` en accord avec le premier
créneau. **Aucun code existant qui lit `groupes.weekday` ne change.**

### 3.5 `app_config`

| Clé | Valeur |
| :--- | :--- |
| `groupe.capacite_enfant` | 5 |
| `groupe.capacite_adulte` | 6 |
| `groupe.minimum_lancement` | **3** |
| `groupe.seances_par_semaine` | 3 |
| `seance.duree_minutes_enfant` | 60 |
| `seance.duree_minutes_adulte` | 90 |
| `seance.pause_minutes_enfant` | 6 |
| `seance.pause_minutes_adulte` | 0 |

Posées en `ON CONFLICT DO NOTHING` : une valeur déjà réglée par l'exploitation
n'est jamais écrasée. **Aucune n'est écrite dans un widget.**

---

## 4. L'API

### 4.1 Lecture

| RPC / vue | Rend | Droits |
| :--- | :--- | :--- |
| `regles_academie()` | jsonb des 8 clés | `authenticated`, `agent_ro` |
| `offres_compatibles(p_membre_id, p_fuseau_vue)` | les offres compatibles, **dans le fuseau demandé** | `authenticated`, `agent_ro` |
| `v_parcours_onboarding` | un apprenant par ligne, `security_invoker` | `authenticated`, `agent_ro` |
| `langues_cours`, `cohortes_age` | select direct | `authenticated`, `agent_ro` |

**`offres_compatibles` rend deux tableaux parallèles** : `jours_locaux[i]` se
tient à `heures_locales[i]`. Ce n'est pas une complication gratuite — pendant une
semaine de changement d'heure, une offre de 18:00 à Paris se lit 19:00 le lundi
et 20:00 le mercredi ailleurs. Une heure unique aurait menti un jour sur trois,
deux fois par an.

**Le filtrage est serveur.** Le client ne reçoit jamais le catalogue entier : un
filtre client se contourne, et un catalogue entier révélerait les créneaux
ouverts à d'autres publics.

**`v_parcours_onboarding` déduit deux états au lieu de les stocker** — stockés,
ils deviendraient faux en silence :

- `offre_indisponible` : l'offre choisie n'est plus publiée ;
- `fuseau_change` : le fuseau du foyer n'est plus celui qui était affiché.

**Elle ne porte aucun compteur.** Sous `security_invoker`, la RLS le réduirait à
« 1 » par foyer — trompeur, et contraire à l'interdiction d'afficher des
compteurs. Le compteur vit dans `offres_admin()`.

### 4.2 Écriture — toutes `revoke … from agent_ro`

| RPC | Effet | Ce qu'elle ne fait PAS |
| :--- | :--- | :--- |
| `enregistrer_profil_apprentissage(membre, langue, cohorte, niveau, objectif, fuseau)` | écrit 5 colonnes + `households.timezone` ; **déduit** `student_type` et `interface_mode` | ne touche ni `level`, ni `diagnostic_statut`, ni `camera_policy` |
| `choisir_offre_horaire(membre, offre, fuseau)` | crée une intention `enregistree`, passe le diagnostic à `a_planifier` | **n'affecte aucun groupe, n'appelle aucun enseignant, ne réserve aucune place** |
| `renoncer_intention_horaire(membre, motif)` | passe l'intention à `retiree` | — |
| `signaler_horaire_insatisfait(membre, detail)` | une ligne `matching_requests` de sorte `horaire_insatisfait` | ne crée pas de groupe, ne cherche pas d'enseignant, ne promet aucun horaire, **n'enregistre aucun créneau souhaité** |

`choisir_offre_horaire` **rejoue la compatibilité côté serveur** : un client
pourrait poster n'importe quel identifiant d'offre.

### 4.3 Administration — `app_role() = 'admin'` uniquement

| RPC | Rôle |
| :--- | :--- |
| `offres_admin()` | toutes les offres **avec leur vivier** — c'est ici, et nulle part ailleurs, que les compteurs vivent |
| `creer_offre_horaire(...)` | crée en `brouillon` |
| `publier_offre_horaire(offre)` | rend l'offre visible aux familles |
| `retirer_offre_horaire(offre, motif)` | retire ; les intentions basculent en `offre_indisponible` côté vue |
| `pool_offre(offre)` | le vivier éligible d'une offre |
| `publier_groupe_depuis_offre(offre, enseignant, libelle, eleves[])` | **vérifie minimum et plafond**, réutilise `creer_groupe` + `ajouter_eleve_groupe`, déploie tous les jours de l'offre dans `groupe_creneaux` |

---

## 5. Sécurité — les trois pièges de ce dépôt, tous évités

1. **`EXECUTE` arrive par deux chemins sur Supabase.** Chaque fonction reçoit
   `revoke … from public` **et** `revoke … from anon`. Aucun des deux ne suffit
   seul, et seul `has_function_privilege` le voit.
2. **`agent_ro` ne doit jamais avoir `EXECUTE` sur une RPC d'écriture.** Les cinq
   RPC d'écriture familiales et les six d'administration le révoquent
   explicitement (ADR-025).
3. **Une porte SQL s'écrit en exigence positive.** `if not cond then raise`,
   jamais `if role <> 'x' then raise` — qui s'ouvre pour `NULL`, donc pour
   `anon`.

À quoi s'ajoute :

4. **La RLS borne les lignes, pas les colonnes.** Le `GRANT UPDATE` sur
   `student_profiles` est nominatif, colonne par colonne.
5. **Toute fonction est `security definer set search_path = ''`**, tout objet
   qualifié `public.`.
6. **`v_parcours_onboarding` est `security_invoker`.** Une vue sans lui
   s'exécuterait avec les droits de son propriétaire et ignorerait la RLS — le
   défaut déjà payé au lot N4.

---

## 6. Ce qui reste à l'exploitation

| Action | Qui | Bloquant pour le premier cours |
| :--- | :--- | :--- |
| Appliquer `0043` | opérateur | **oui** |
| Créer et publier au moins une offre | admin | **oui** — sans offre, l'écran affiche honnêtement son état vide |
| Déployer sur Vercel (manuel) | opérateur | **oui** |
| Importer le curriculum dans `programme_niveaux` | académie | non — une offre sans niveau reste compatible avec tout le monde |
| Écran d'administration des offres | lot suivant | non — les RPC suffisent |

---

## 7. Si un autre agent possède ce périmètre

Aucun fichier existant de Supabase n'a été modifié. La migration `0043` est
**additive** ; le seul objet antérieur touché est le `CHECK` de
`matching_requests.kind`, **élargi** (les trois sortes existantes restent
valides) sur une table à zéro ligne.

Si un agent souhaite que ce socle vive ailleurs, ou sous d'autres noms, il peut
renommer sans rien casser côté client à une condition : `ServiceOffresSupabase`
(`lib/core/offres/service_offres.dart`) est le **seul** point du client qui
nomme ces RPC. Neuf appels, un seul fichier.

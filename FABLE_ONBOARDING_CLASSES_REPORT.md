# Lot « onboarding personnalisé + offres horaires vitrines + parcours d'inscription »

**Rapport de livraison — 22 septembre 2026.**
Branche `lot/onboarding-offres`, worktree `D:\RA_ONBOARD`, baseline `ae61eb6`
(= `origin/main` au démarrage).

> Le brief nommait FABLE. Ce lot a été exécuté par Claude Code, Codex
> travaillant en parallèle sur le même dépôt — d'où le worktree isolé et
> l'absence totale de modification des fichiers d'un autre chantier.

---

## 1. Audit de l'existant — ce qui a changé la conception

L'audit a porté sur le dépôt réel et sur la base de production, pas sur la
documentation. **Cinq constats ont modifié ce qu'il fallait construire**, et un
sixième a été trouvé en cours de route.

### 1.1 Une offre vitrine ne peut pas être une ligne `groupes`

`groupes.teacher_id` est `NOT NULL` : un groupe n'existe pas sans enseignant
affecté. Relâcher cette colonne aurait traversé toute policy et toute RPC qui
tient un groupe pour enseigné — jeton vidéo, observation, `mes_groupes_v`.
**Coût : une refonte de sécurité. Gain : nul.**

→ Table séparée `offres_horaires`, sans aucune colonne d'enseignant.

### 1.2 `groupes.weekday` est *un* jour, la mission en demande trois

Trois lignes `groupes` pour trois séances hebdomadaires auraient découpé un même
roster en trois et compté le plafond trois fois.

→ Table fille `groupe_creneaux`, plus un trigger `groupe_creneau_ancre()` qui
empêche `groupes.weekday`/`hour_local` et `groupe_creneaux` de diverger.
**Aucune ligne de code existant ne change.**

### 1.3 `programme_versions` et `programme_niveaux` sont vides en production

Aucun niveau officiel n'existe. Le filtre « niveau académique compatible » n'a
donc aucune donnée.

→ `offres_horaires.programme_niveau_id` est **nullable**, et une offre sans
niveau est compatible avec tout le monde. Inventer un référentiel aurait été
inventer une règle académique.

### 1.4 ⚠️ Le constat le plus important : `app_account_valid()` refuse `pending_kyc`

Les policies d'écriture de `weekly_availability` et de `student_profiles`
l'exigent toutes deux. Or **le foyer qui s'onboarde est par construction
`pending_kyc`**.

**Sans correction, ce lot aurait refusé en silence toute écriture à exactement la
population qu'il vise.** C'est le piège déjà payé sur
`peut_deposer_piece_identite` (mémoire du 21 septembre).

→ Nouvelle porte `compte_en_parcours()`, utilisée **uniquement** par les RPC
d'onboarding, qui n'écrivent **que** des données d'onboarding. Elle n'ouvre rien
vers un groupe, une séance, un jeton vidéo ou un autre foyer.
`ajouter_eleve_groupe` continue d'exiger `active`/`provisional_active`.
**Aucune policy ni fonction existante n'a été affaiblie.**

### 1.5 `student_profiles` : la RLS borne les lignes, pas les colonnes

`authenticated` a `INSERT` mais pas `UPDATE` sur `level`. Le nouveau `GRANT` est
donc **colonne par colonne** :

```sql
grant update (langue_cours, cohorte, niveau_declare, objectif, onboarding_fait_le)
  on public.student_profiles to authenticated;
```

`level`, `diagnostic_statut`, `student_type` et `riwaya` restent fermés **au
niveau du GRANT**, pas seulement de l'écran. Une famille ne peut pas se
promouvoir.

### 1.6 `ScheduleOption` existait déjà, et n'était branché nulle part

`lib/core/widgets/schedule_option.dart`, avec la bonne doctrine dans sa propre
doc : « Presentation-only administrative schedule proposal. It deliberately has
no free date/time inputs and no reservation action. » Il n'était référencé que
par la galerie de développement.

→ **Réutilisé tel quel.** Aucun composant de carte d'horaire n'a été créé.

De même, `ChoiceCardGroup.autoriserSaisieLibre` portait déjà le commentaire
« New scheduling choices use closed administrative proposals and pass false ».
Le mécanisme de l'exception à ADR-013 existait avant ce lot.

---

## 2. Contradictions détectées, et comment elles sont tranchées

| # | Contradiction | Résolution |
| :--- | :--- | :--- |
| 1 | **ADR-015 retire le poular** de l'application ; la mission **impose le poular** comme langue de cours | **ADR-029** : deux axes distincts. ADR-015 gouverne la locale de l'interface et **tient** ; le poular revient comme langue d'**enseignement** |
| 2 | **ADR-013 impose** une carte « Autre » en saisie libre partout ; la mission **l'interdit** sur l'horaire | **ADR-030** : exception bornée à la seule question d'horaire, parce qu'une réponse libre y serait inexploitable. L'issue reste offerte par un repli qui ne promet rien |
| 3 | `PhaseEnfant.enRecherche` de l'accueil famille suppose une recherche d'enseignant ; le nouveau modèle a cinq états avant qu'un groupe existe | **Non fusionné.** Les cinq phases existantes décrivent la vie d'un cours affecté ; le nouveau bloc décrit ce qui se passe avant. Fondre les deux aurait obligé à réécrire un écran couvert par ses tests, pour un gain nul. Le bloc est **additif**, posé au-dessus, et disparaît quand chaque apprenant a son groupe |

---

## 3. Décisions améliorées plutôt qu'appliquées telles quelles

Le brief demandait explicitement de ne pas exécuter aveuglément. Trois points
ont été retenus autrement, sans jamais affaiblir une règle de sécurité ni une
règle académique.

### 3.1 « Disponibilité générale » : classer, jamais filtrer

**Le problème.** L'étape G demandait une « disponibilité générale ». Mais
`offres_compatibles` filtre sur la langue, le public et le niveau — pas sur la
disponibilité. Poser la question sans s'en servir en aurait fait une question
décorative ; s'en servir pour filtrer aurait caché des horaires ouverts ; s'en
servir pour promettre un créneau aurait violé l'interdiction du sur-mesure.

**La solution retenue.** Trois moments (matin / après-midi / soir) qui
**classent** les offres compatibles. L'offre qui tombe dans un moment coché
remonte en tête et devient la « recommandation principale » ; **toutes les
autres restent visibles juste en dessous**.

**Pourquoi c'est mieux.** C'est la seule lecture qui ne fasse aucun des trois
défauts. Elle rend la recommandation principale réelle au lieu d'être la
première ligne d'une liste arbitraire.

**Impact technique.** Aucun. La réponse **n'est envoyée à aucun serveur**, ne
crée aucune attente, et n'est stockée nulle part. Fonction pure `classerOffres`,
testée.

### 3.2 L'âge se demande en tranche, jamais en date de naissance

**Pourquoi c'est mieux.** Sur un téléphone tenu d'une main, une réponse au doigt
bat un sélecteur de date. Et surtout : **le produit ne stocke de date de
naissance nulle part**. En collecter une ici créerait une donnée sensible
nouvelle pour un usage qui n'existe pas.

**Ce qui est déduit par le serveur, jamais par le client** : `type_public`,
`student_type`, `interface_mode`. Un client qui déciderait qui est mineur
pourrait se déclarer adulte autonome.

**Ce qui n'est pas déduit** : `camera_policy`. ADR-012 la confie au parent, dans
un écran qui l'explique. La déduire d'une tranche d'âge ouvrirait une caméra que
personne n'a demandée.

### 3.3 Le signal de demande non satisfaite réutilise `matching_requests`

**« Réutilise ce qui existe »** : la table que l'académie dépouille déjà en
`ADM-06` reçoit une nouvelle sorte, `horaire_insatisfait`. La contrainte `CHECK`
est **élargie, pas remplacée** — les trois sortes existantes restent valides.

**Ce qui n'est pas réutilisé** : la fonction `demander()`. Son `p_rule_value` est
un `integer`, incapable de porter un motif structuré. La table est réutilisée,
la fonction ne l'est pas.

**Ce que le signal ne porte jamais** : un créneau souhaité. Le détail envoyé
contient le fuseau, la langue et la cohorte. Enregistrer un vœu d'horaire aurait
créé exactement l'attente que la mission interdit.

### 3.4 Un foyer déjà personnalisé ne répond pas deux fois

Trouvé en construisant : une famille revient changer d'horaire longtemps après
son inscription. Lui reposer six questions déjà répondues aurait violé la règle
« ne jamais redemander une information connue ».

→ Le parcours s'ouvre directement sur les horaires quand le profil est rempli ;
« Retour » redescend vers les questions, **déjà remplies**.

---

## 4. Ce qui a été construit

### 4.1 Serveur — `supabase/migrations/0043_offres_horaires_et_intentions.sql`

Dix sections, ~1200 lignes. **Additive** : aucun objet existant n'est supprimé ni
redéfini, à l'exception du `CHECK` de `matching_requests.kind`, qui est élargi
sur une table à zéro ligne.

| Section | Contenu |
| :--- | :--- |
| 1 | `langues_cours` (poular, francais, english), `cohortes_age` (5 tranches) |
| 2 | `compte_en_parcours()`, `peut_decrire_apprenant(uuid)` — la porte étroite du §1.4 |
| 3 | 5 colonnes sur `student_profiles`, `CHECK` sur les listes de codes, `GRANT` colonne par colonne |
| 4 | `offres_horaires` + index unique partiel sur le motif publié + RLS vitrine |
| 5 | `intentions_horaire` (avec la **preuve de ce qui a été montré** : `fuseau_affiche`, `heure_affichee`, `jours_affiches`) + unicité d'une intention vivante par élève |
| 6 | `groupe_creneaux` + trigger d'ancrage |
| 7 | 8 clés `app_config` + `regles_academie()` |
| 8 | `enregistrer_profil_apprentissage`, `offres_compatibles`, `choisir_offre_horaire`, `renoncer_intention_horaire`, `signaler_horaire_insatisfait` |
| 9 | `v_parcours_onboarding` en `security_invoker` |
| 10 | Côté administration : `offres_admin`, `creer_offre_horaire`, `publier_offre_horaire`, `retirer_offre_horaire`, `pool_offre`, `publier_groupe_depuis_offre` |

**Trois défauts trouvés dans ma propre migration et corrigés avant livraison :**

1. Du code mort dans `creer_offre_horaire` — supprimé.
2. `offres_compatibles` calculait **une** heure locale par `min(...)`. Faux
   pendant une semaine de changement d'heure, qui décale certains jours et pas
   d'autres : une offre de 18:00 à Paris se lit 19:00 le lundi et 20:00 le
   mercredi ailleurs. → Deux tableaux **parallèles** `jours_locaux` /
   `heures_locales`, via `unnest(...) with ordinality`.
3. `v_parcours_onboarding` portait un compteur `intentions_sur_offre`. Sous
   `security_invoker`, la RLS l'aurait réduit à « 1 » pour chaque foyer — à la
   fois trompeur et contraire à l'interdiction d'afficher des compteurs. →
   Supprimé ; le compteur vit dans `offres_admin()` et nulle part ailleurs.

**Sécurité, trois pièges connus de ce dépôt tous évités :**

- `revoke ... from public` **et** `from anon` sur chaque fonction (deux chemins
  d'`EXECUTE` sur Supabase, aucun ne suffit seul) ;
- `revoke ... from agent_ro` sur **toutes** les RPC d'écriture ;
- portes écrites en **exigence positive** (`if not cond then raise`), jamais
  `if role <> 'x'` qui s'ouvre pour `NULL`.

### 4.2 Client

| Fichier | Rôle |
| :--- | :--- |
| `lib/core/offres/offre_horaire.dart` | Le modèle, et la fonction pure `etapeParcours` |
| `lib/core/offres/service_offres.dart` | Interface, implémentation Supabase, 5 providers |
| `lib/features/parcours_offres/parcours_offres_page.dart` | Les 6 questions + l'écran des horaires |
| `lib/features/parcours_offres/bloc_parcours.dart` | Le bloc d'état, à l'accueil famille |
| `lib/features/parcours_offres/libelles_parcours.dart` | Libellés et logique pure testable |

**Branchements** (un écran sans navigation qui l'expose n'existe pas) :

- `Routes.tuteurParcours` + `Routes.parcoursPour(eleveId)` ;
- `GoRoute` dans `app_router.dart`, sous le préfixe `/tuteur` ;
- `BlocParcours` **posé dans `accueil_famille_page.dart`**, au-dessus des cartes
  d'enfants.

**UI/UX** : `PageParcours`, `ChoiceCardGroup`, `ScheduleOption`, `BentoTile`,
`SectionHeader`, `ActionPrincipale`, `Skeleton`, `PageShell` — **tous existants**.
Aucun HEX local, aucun composant nouveau, aucun « mode enfant » séparé.

### 4.3 Documentation

| Fichier | Contenu |
| :--- | :--- |
| `docs/produit/onboarding-questions-expliquees.md` | **Chaque question expliquée**, en particulier les trois qui prêtent à confusion : langue du cours ≠ langue de l'interface, niveau déclaré ≠ grade, « moments » qui classent sans filtrer |
| `docs/produit/badges-et-grades.md` | ⛔ **PROPOSITION NON VALIDÉE, rejetée en l'état le 22/09/2026** — voir la bannière en tête du fichier. La politique retenue compte **cinq** niveaux (Certifié Rewayah, Bronze, Argent, Or, Platine), pas huit grades, et **`student_profiles.level` ne doit jamais porter le grade professionnel d'un enseignant** : c'est le niveau académique d'un élève. La recommandation de rattachement qui figurait ici est **retirée**. Rien ne doit être implémenté avant validation d'un modèle métier dédié |
| `docs/architecture/decisions.md` | ADR-029, ADR-030, ADR-031 |
| `FABLE_BACKEND_CONTRACT_ONBOARDING_CLASSES.md` | Le contrat serveur |

---

## 5. Tests

`test/parcours/parcours_offres_test.dart` — **32 tests**, tous verts.

| Ce qui est mesuré | Pourquoi |
| :--- | :--- |
| Les 7 états de `etapeParcours`, et leur **ordre** | Une offre retirée doit primer sur « en formation » |
| `classerOffres` ne retire jamais une offre | C'est tout le point du §3.1 |
| `fuseauSuggere` : connu > horloge, et **rien** au-delà de 2 h d'écart | Une case fausse serait validée sans être lue |
| Deux heures affichées quand un changement d'heure décale un jour et pas l'autre | Le défaut corrigé du §4.1 |
| **La carte vitrine ne porte ni enseignant, ni compteur, ni identifiant** — vérifié sur les 4 chaînes que `ScheduleOption` peut rendre | L'interdiction absolue |
| Le repli affiche sa limite **avant** le clic, et ne crée aucune intention | ADR-030 |
| Les 6 réponses partent **ensemble**, jamais à moitié | Une fiche à moitié écrite paraîtrait « personnalisée » |
| « En formation » annonce le minimum serveur, et jamais « réservé » | L'interdiction de mentir |
| Une lecture en échec **ne dit rien** plutôt que « à personnaliser » | Une famille inscrite croirait qu'il lui manque quelque chose |
| Un foyer déjà personnalisé n'est pas renvoyé aux questions | §3.4 |

Le faux `ServiceOffres` vit dans `test/parcours/faux_service_offres.dart` et
**non** dans `test/support/harnais.dart` : ce lot est construit en parallèle d'un
autre agent, et un faux ajouté au harnais commun aurait été un point de
collision pour un gain nul.

---

## 6. Ce qui n'est PAS fait, et pourquoi

| Point | Raison |
| :--- | :--- |
| **La migration `0043` n'est pas appliquée** | Action d'exploitation. Elle doit l'être **avant** tout déploiement : le client appelle des RPC qui n'existent pas encore en production |
| Le **système de badges** | Le brief l'interdit explicitement dans ce lot. Il est **spécifié**, pas construit |
| L'**affectation automatique** à un groupe | `pool_offre` et `publier_groupe_depuis_offre` existent, mais restent déclenchés à la main par l'administration. Une affectation automatique qui se trompe met un enfant dans le mauvais groupe, et rien dans le produit ne sait encore la défaire proprement |
| L'**écran d'administration des offres** | Les RPC sont livrées, l'écran ne l'est pas. Une offre se crée aujourd'hui par `creer_offre_horaire` + `publier_offre_horaire`. **C'est le chemin critique pour lancer le premier cours** — voir §7 |
| `test/support/harnais.dart` | Non modifié, volontairement (voir §5) |
| Les fichiers de `core24/fable-frontend` et `observation/lot-2026-09-21` | **Aucun n'a été touché.** READ ONLY, conformément au brief |

---

## 7. Pour lancer le premier cours après ce déploiement

Dans l'ordre :

1. **Appliquer `0043`** en production.
2. **Créer au moins une offre** et la publier :
   ```sql
   select public.creer_offre_horaire(
     p_type_public   => 'enfant',
     p_langue_code   => 'francais',
     p_fuseau_iana   => 'Europe/Paris',
     p_jours         => array[1,3,5]::smallint[],
     p_heure_locale  => 18::smallint
   );
   select public.publier_offre_horaire('<id rendu>');
   ```
   `p_jours` doit contenir exactement `groupe.seances_par_semaine` jours (3) ;
   `p_duree_minutes` est facultatif et se déduit du public.
3. Déployer l'application (manuellement sur Vercel — `main` ne déclenche rien).
4. Les familles choisissent leur horaire ; l'académie lit `offres_admin()` et
   `pool_offre(<id>)`.
5. Quand le vivier atteint `groupe.minimum_lancement` (3) :
   `publier_groupe_depuis_offre(offre, enseignant, libelle, eleves[])`.

**Sans l'étape 2, l'écran des horaires affiche honnêtement « Aucun horaire
ouvert ne correspond encore ».** Ce n'est pas un bug : c'est l'état vide, et il
est conçu.

---

## 8. Liste exacte des fichiers modifiés

**Créés**

```
supabase/migrations/0043_offres_horaires_et_intentions.sql
lib/core/offres/offre_horaire.dart
lib/core/offres/service_offres.dart
lib/features/parcours_offres/parcours_offres_page.dart
lib/features/parcours_offres/bloc_parcours.dart
lib/features/parcours_offres/libelles_parcours.dart
test/parcours/parcours_offres_test.dart
test/parcours/faux_service_offres.dart
docs/produit/badges-et-grades.md
docs/produit/onboarding-questions-expliquees.md
FABLE_ONBOARDING_CLASSES_REPORT.md
FABLE_BACKEND_CONTRACT_ONBOARDING_CLASSES.md
```

**Modifiés**

```
assets/i18n/fr.i18n.json           (clé « parcours » ajoutée)
lib/core/i18n/strings.g.dart       (régénéré par slang)
lib/core/router/routes.dart        (2 constantes ajoutées)
lib/core/router/app_router.dart    (1 import, 1 GoRoute)
lib/features/accueil_famille/accueil_famille_page.dart  (1 import, 1 widget)
docs/architecture/decisions.md     (ADR-029, ADR-030, ADR-031)
```

**Non modifiés, et c'est délibéré** : `test/support/harnais.dart`, toute policy
ou fonction SQL antérieure, `app_account_valid()`, `camera_policy`,
`PhaseEnfant`, et l'intégralité des fichiers appartenant à un autre chantier.

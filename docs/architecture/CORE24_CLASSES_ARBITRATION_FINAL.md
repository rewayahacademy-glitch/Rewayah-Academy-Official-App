# Arbitrage canonique Core24 Classes / Groupes / Dispatch

> Document normatif de reprise du chantier Classes. Il fixe la cible à
> implémenter à partir de la base Fable `9a3ff0d`. Il ne constitue pas une
> preuve de code livré, de migration exécutée, de test global ou de déploiement.

## 1. VERDICT

Fable et Core24 sont complémentaires et doivent être reliés par le chaînon
académique manquant. Il n'y a pas de troisième domaine Classes.

```text
Offre horaire vitrine
  -> Intention d'inscription
  -> Personnalisation / pré-diagnostic
  -> Diagnostic si nécessaire
  -> Pool compatible
  -> Dispatch automatique
  -> Groupe DRAFT
  -> Enseignant titulaire
  -> Validation Admin
  -> READY / PUBLISHED / ACTIVE
  -> Session
  -> Classe Live
```

Les objets sont strictement distincts :

- `offre` est un objet d'acquisition/commercial ;
- `groupe` est l'objet pédagogique permanent ;
- `session` est une occurrence planifiée ;
- `classe live` est l'état temps réel d'une session.

Le lot Fable conserve l'acquisition, l'onboarding, les intentions et les
offres. Core24 conserve le domaine pédagogique Classes, ses ports, ses
adaptateurs et ses surfaces enseignant/famille. Le dispatch, la formation des
groupes et l'affectation du titulaire sont construits entre les deux.

## 2. KEEP / ADAPT / MERGE / DEPRECATE

| Élément | Décision | Règle |
| --- | --- | --- |
| `offres_horaires` | KEEP | Offre vitrine sans enseignant, sans élèves, sans capacité affichée et sans identifiant de groupe public. |
| `intentions_horaire` | ADAPT | Conserver la préférence, le choix montré et le signal « aucun horaire ». Ajouter les états/verrous nécessaires au dispatch idempotent. |
| `cohortes_age` | ADAPT | Les cohortes actives deviennent `6-9`, `10-13`, `14-17`, `18+`. Ne pas supprimer les anciennes références. |
| `student_profiles` | ADAPT | Pour un mineur, `date_naissance` est la source canonique ; âge et cohorte sont dérivés. `cohorte` peut rester une projection/index. |
| `groupes` | KEEP + ADAPT | Seul objet Groupe permanent. Ajouter/adapter l'état réel, la cohorte et les garanties de titulaire/publication. |
| `groupes.teacher_id` | KEEP | Sémantique figée : titulaire permanent du Groupe. Nullable uniquement dans les états pré-publication autorisés. |
| `sessions` / `session_participants` | KEEP | Le remplaçant est l'enseignant effectif d'une session, jamais le titulaire du Groupe. |
| `ReglesClasse` / `regles_academie()` | MERGE | Une seule source serveur/configurable pour capacité, durée, minimum et fréquence. Aucun hardcode métier dans Flutter. |
| Ports/adaptateurs Classes | KEEP + ADAPT | Réutiliser les ports et brancher les RPC réelles ; ne pas réécrire le frontend Fable. |
| Marketplace famille Core24 | DEPRECATE | Une famille choisit une Offre, pas une Classe réelle. Garder les surfaces enseignant/admin utiles. |
| `proposerCreneau()` | MERGE | Utiliser le signal Fable « aucun de ces horaires ne me convient » ; ne créer aucun groupe ni enseignant recherché. |
| Badges / grades | DEPRECATE / HORS PÉRIMÈTRE | Préparer uniquement l'entitlement `max_primary_groups`, sans UI de badge ni leaderboard. |
| Presence Core24 | PROTÉGER | Le commit `730b7b74aef6e63aa298aec5895412be7f28935a` est intégré plus tard ; aucune réécriture ou ré-audit dans ce lot. |

Les offres enfant peuvent rester génériques aux mineurs. Une restriction de
cohorte n'est ajoutée que lorsqu'elle est réellement nécessaire ; le pool et
le dispatch séparent toujours les cohortes. Cette règle évite de multiplier
artificiellement le catalogue.

## 3. MODÈLE DE DONNÉES FINAL

### Offre et intention

`offres_horaires` porte le public enfant/adulte, la langue, les jours, l'heure,
la durée et le fuseau/localisation pertinents. Elle ne porte pas de professeur,
de photo de professeur, de nombre d'inscrits, de places restantes ou d'id de
groupe exposable.

`intentions_horaire` conserve l'intention de la famille et sa préférence. Une
préférence sert au classement ; une indisponibilité dure sert à exclure. Le
fallback « Aucun de ces horaires ne me convient » crée seulement un signal
de demande de nouveaux horaires.

### Académique

- Le niveau officiel provient d'un résultat académique structuré côté serveur.
- Un pré-diagnostic d'onboarding ne suffit jamais à écrire le niveau officiel.
- Les structures existantes `levels`, `assessments`, `assessment_results` ou
  leur équivalent sont réutilisées avant toute nouvelle table.
- Le `placement_basis` doit rendre explicite une entrée débutant déclarée, par
  exemple `self_declared_beginner`.

### Groupe et lifecycle

Un Groupe peut exister en `DRAFT` sans titulaire. Toute transition vers
`READY`, `PUBLISHED` ou `ACTIVE` exige un `teacher_id` non nul, le minimum,
la capacité, la compatibilité, la conformité et un titulaire admissible.
L'implémentation réutilise la machine d'état existante au lieu d'ajouter une
seconde notion de publication ; `groupes.actif` ne doit pas rester l'unique
source d'un lifecycle qui nécessite plusieurs états.

Les appels historiques sont conservés lorsqu'ils restent compatibles, mais
le nouveau flux ne demande pas à l'Admin de saisir une liste arbitraire d'UUID.
Le serveur prépare les groupes proposés et l'Admin contrôle les exceptions.

### Capacités

Les valeurs sont centralisées et configurables :

| Population | Maximum | Fréquence | Durée | Pause |
| --- | ---: | ---: | ---: | ---: |
| Enfants | 5 | 3 séances/semaine | 60 min | 5 à 7 min configurable |
| Adultes | 6 | 3 séances/semaine | 90 min | selon la policy |

Le minimum initial de lancement est 3. Les anciennes valeurs enfant 4, adulte
5 et enfant 45 minutes sont obsolètes et ne doivent pas revenir.

## 4. ÂGE / COHORTES

Les cohortes de dispatch sont :

- `6-9` ;
- `10-13` ;
- `14-17` ;
- `18+`.

Pour les profils mineurs, la date de naissance gérée par le tuteur est la
source fiable de l'âge, de la cohorte et de l'éligibilité à la demande
« Demander l'affichage standard » à partir de 10 ans révolus. Il ne faut pas
créer trois vérités indépendantes (`date_naissance`, âge manuel, cohorte
manuelle).

Si aucune date fiable n'existe, les données legacy sont conservées sans
invention ; le tuteur est sollicité une seule fois et l'auto-demande
d'affichage standard reste masquée. Une ancienne tranche `8-10` ne permet
jamais d'inventer une date.

Un profil de moins de 6 ans est hors dispatch standard et relève du mécanisme
Admin/waitlist existant. Les adultes forment une population unique en V1.
Un anniversaire 9→10 ne déclenche aucun transfert automatique de groupe.

La cohorte est une contrainte dure du dispatch mineur, mais elle reste
indépendante de l'Interface guidée. `child_ui_mode_max_age` ne détermine ni la
cohorte, ni le pool, ni le dispatch.

La date de naissance est protégée par RLS, non publique et non visible à un
enseignant sauf nécessité métier explicitement justifiée.

## 5. ONBOARDING / DIAGNOSTIC

Le profilage est progressif : une information est demandée lorsqu'elle devient
utile, pas seulement parce qu'une colonne est vide.

### Débutant

La carte est intitulée **« Je débute »** et explique, avec une formulation
équivalente au besoin :

> Je ne peux pas encore lire seul des mots ou des versets en arabe, même si je
> connais déjà quelques lettres.

Ce choix entraîne un placement débutant explicite, le niveau initial réel du
curriculum et l'éligibilité au pool débutant, sous réserve des autres
contraintes. Aucun diagnostic D0 n'est imposé. `diagnostic_status` ne doit pas
être falsifié en `completed` ; la provenance reste traçable.

### Non-débutant

Le pré-diagnostic comporte 2 à 4 questions adaptatives maximum. Il prépare le
diagnostic, mais ne fixe aucun niveau officiel. Le parcours est :

```text
diagnostic_required
  -> entrée normale dans l'application
  -> tâche « Finaliser mon niveau »
  -> file Diagnostics
  -> enseignant qualifié diagnosticien
  -> grille Rewayah + résultat structuré
  -> validation serveur
  -> niveau officiel et pool
```

Le diagnostic bloque seulement l'affectation académique définitive ; il ne
bloque pas l'accès général à l'application. Le diagnosticien n'est pas
nécessairement le futur titulaire. L'Admin orchestre et traite les exceptions,
mais ne diagnostique que s'il est lui-même qualifié.

## 6. DISPATCH

Le backend est la source de vérité. Deux intentions ne sont compatibles que
si elles partagent :

1. la même offre horaire ;
2. la même langue de cours ;
3. la même population enfant/adulte ;
4. la même cohorte pour les mineurs ;
5. un cycle/niveau opérationnel compatible ;
6. des prérequis et un corridor compatibles.

Le corridor est distinct de l'égalité stricte :

- la création automatique reste conservatrice et ne mélange pas deux cycles
  voisins seulement pour remplir une classe ;
- le placement dans un Groupe existant peut tolérer le même cycle ou le cycle
  immédiatement voisin seulement si le rattrapage est possible en deux
  semaines maximum sans charge durable particulière ;
- la santé d'une cohorte après inscription est traitée séparément (support,
  transfert recommandé ou revue de transfert supérieur selon le décalage).

Le FIFO (`created_at`) ne s'applique qu'après les contraintes de compatibilité.
Le moteur est déterministe, transactionnel, idempotent lorsque nécessaire,
sûr en concurrence, sans double affectation et sans dépassement de capacité.

Le moteur remplit d'abord les Groupes DRAFT compatibles existants. Avec une
capacité enfant de 5 et un minimum de 3 : `7 → 5 + 2 en attente`,
`8 → 5 + 3`, `12 → 5 + 5 + 2 en attente`, `13 → 5 + 5 + 3`.
Le reliquat sous le minimum reste dans le pool.

L'application du dispatch crée ou complète le Groupe DRAFT, crée les créneaux,
affecte les intentions dans la même transaction et protège l'idempotence. Des
verrous de transaction, une contrainte unique et/ou le mécanisme PostgreSQL
équivalent doivent empêcher deux workers d'affecter deux fois la même
intention. Une intention déjà affectée ne crée jamais un second Groupe.

## 7. TITULAIRE / REMPLAÇANT

`groupes.teacher_id` reste le titulaire permanent. L'admissibilité réutilise
`core24_private.enseignant_autorise()` puis contrôle, côté serveur :

- langue enseignée ;
- qualification/niveau ;
- disponibilité sur tous les créneaux récurrents ;
- chevauchement réel tenant compte de la durée, du fuseau IANA et du DST ;
- charge hebdomadaire ;
- entitlement `max_primary_groups`, défaut 2.

La capacité vient d'une policy/configuration/entitlement, jamais d'un badge
Flutter ni de `student_profiles.level`. Les badges sont hors périmètre.

Le remplacement est lié à une Session :

```text
standby_requested
  -> invitations
  -> première acceptation atomique
  -> invitations concurrentes révoquées
  -> un seul enseignant effectif sur la session
```

Réutiliser `session_participants_one_teacher_uidx` et les notifications
existantes. L'acceptation remplace la ligne enseignant de la session, sans
modifier `groupes.teacher_id`. Le paiement de la séance suit la policy
existante ; aucune nouvelle politique de rémunération n'est inventée dans ce
lot.

## 8. COLLISIONS

| Collision | Arbitrage |
| --- | --- |
| Brouillon Claude : aucune date de naissance | Le présent prompt gagne : date fiable pour les mineurs, âge et cohorte dérivés, RLS stricte. |
| Brouillon Claude : offres enfant cohort-specific obligatoires | Le présent prompt gagne : offre enfant générique par défaut, cohorte dure dans le pool/dispatch, restriction optionnelle seulement si nécessaire. |
| Brouillon Claude : questions 1 à 3 bloquantes | Le présent prompt fournit les décisions : interface guidée indépendante, diagnostic par enseignant qualifié, corridor conservateur explicite. |
| Fable 0043 et Core24 | Fable reste acquisition/onboarding/offres ; Core24 reste Classes ; aucun troisième domaine. |
| `EtatPublication` dérivé d'`actif` | Adapter la source au lifecycle réel tout en réutilisant le vocabulaire et la compatibilité existants. |
| `groupes.teacher_id` obligatoire à la création | Nullable en DRAFT seulement ; obligatoire et admissible avant READY/PUBLISHED/ACTIVE. |
| Remplacement de professeur | Modifier `session_participants`, jamais `groupes.teacher_id`. |
| Cohortes historiques `5-7`, `8-10`, `11-14`, `15-17` | Les désactiver ou projeter selon une migration forward ; ne pas remapper destructivement sans date fiable. |
| Migration `20260922000200` citée dans d'anciens échanges | Le nom réel correct est `20260921000200_core24_conformite.sql`. |
| Presence protégée | Ne pas la réauditer ni la réécrire ; intégrer seulement le commit `730b7b74aef6e63aa298aec5895412be7f28935a` plus tard. |
| Disponibilité famille | Préférence = ranking ; indisponibilité dure = exclusion ; aucun horaire sur mesure. |

## 9. PATCH PLAN

Chaque étape est réalisée et testée isolément. Les noms de nouvelles migrations
sont attribués après vérification de l'ordre réel ; aucune migration historique
n'est réécrite inutilement.

### Étape 1 — Réconciliation âge, cohorte et RLS

- **Fichiers** : migration forward Classes, tests SQL ciblés, politiques de
  profil et projections concernées.
- **Modification** : ajouter une source canonique `date_naissance` pour les
  mineurs si aucune n'existe, dériver âge/cohorte, activer `6-9`, `10-13`,
  `14-17`, `18+`, sans fabriquer les legacy.
- **Acceptation** : tests 6/9/10/13/14/17/18, `<6`, date inconnue et RLS
  tuteur/enseignant/public.

### Étape 2 — Onboarding et diagnostic progressifs

- **Fichiers** : `lib/features/parcours_offres/`, `lib/core/offres/`, i18n et
  tests de parcours ; RPC/colonnes directement concernées.
- **Modification** : conserver Fable, ajouter la question utile d'âge, la carte
  débutant et le pré-diagnostic court ; relier le diagnostic réel au workflow
  enseignant qualifié.
- **Acceptation** : débutant sans D0 ni faux `completed`, non-débutant avec 2–4
  questions, accès à l'application conservé, niveau officiel écrit seulement
  par le serveur.

### Étape 3 — Offres, intentions et pool compatible

- **Fichiers** : migration forward 0043/Core24, RPC `offres_compatibles`,
  `pool_offre`, intentions et adaptateurs associés.
- **Modification** : garder l'offre enfant générique par défaut, distinguer
  préférence/indisponibilité et exposer langue, population, cohorte et état
  académique nécessaires au pool.
- **Acceptation** : les offres ne révèlent ni professeur ni capacité ; langues,
  cohortes et populations ne sont jamais mélangées ; fallback sans Groupe.

### Étape 4 — Lifecycle Groupe et publication

- **Fichiers** : migration forward `groupes`, RPC de création/transition,
  `lib/features/classes/` et tests SQL.
- **Modification** : DRAFT sans titulaire ; READY/PUBLISHED/ACTIVE avec
  titulaire admissible, minimum, capacité, compatibilité et conformité.
- **Acceptation** : DRAFT sans titulaire accepté ; publication/READY sans
  titulaire refusés ; états et projection client cohérents.

### Étape 5 — Dispatch transactionnel

- **Fichiers** : RPC/migration de dispatch, contraintes uniques, tests SQL de
  concurrence et d'idempotence.
- **Modification** : partition stricte, remplissage des DRAFT existants, FIFO
  après compatibilité, transaction complète et verrous adaptés.
- **Acceptation** : jeux 7/8/12/13 conformes ; deux transactions simultanées
  sans double affectation ; rejeu sans doublon.

### Étape 6 — Titulaire et capacité professionnelle

- **Fichiers** : `enseignant_admissible`, `enseignants_eligibles`, policy/config
  `max_primary_groups`, planning réutilisé, surface Admin minimale.
- **Modification** : composer `core24_private.enseignant_autorise()` avec
  langue, niveau, disponibilité complète, chevauchement, charge et plafond 2.
- **Acceptation** : KYC/non-conformité, langue, niveau, disponibilité, conflit
  et dépassement de plafond refusés côté serveur.

### Étape 7 — Remplacement de session

- **Fichiers** : structures minimales d'astreinte si absentes, RPC d'invitation
  et d'acceptation, surface Classes enseignant, tests SQL.
- **Modification** : acceptation atomique, révocation des concurrents, une
  seule ligne enseignant effective par session, titulaire du Groupe inchangé.
- **Acceptation** : deux acceptations simultanées donnent un seul gagnant et
  `groupes.teacher_id` reste inchangé.

### Étape 8 — Interface guidée, Admin et validation globale

- **Fichiers** : réglages enfant/tuteur, Admin offres/pools/groupes proposés,
  tests accessibilité et scénario global local.
- **Modification** : bouton disponible à 10 ans révolus seulement, demande au
  tuteur, notice persistante non alarmiste, Admin valide des propositions et
  choisit parmi les enseignants admissibles.
- **Acceptation** : 9 ans sans bouton, 10 ans avec demande sans changement
  direct, acceptation/déclinaison tuteur correctes, RLS complète, replay
  PostgreSQL neuf sans échec.

## 10. BLOCKERS

**Aucun blocker métier restant pour commencer l'implémentation.** Les décisions
normatives nécessaires sont fixées dans le prompt de reprise et dans ce
document : source d'âge, cohortes, diagnostic, corridor, capacités, dispatch,
titulaire, remplacement, interface guidée et disponibilité famille.

Restent des gates techniques obligatoires, qui ne sont pas des décisions à
réinventer :

- inspecter uniquement les RPC, tables, policies et call-sites directement
  concernés avant chaque patch ;
- tester toute migration sur une base PostgreSQL locale neuve avec replay
  complet ;
- vérifier les tests Flutter ciblés et l'analyse statique du lot ;
- ne jamais appliquer de migration distante, modifier Supabase production,
  pousser `main` ou déployer Vercel dans ce chantier.

Le legacy Classes est sauvegardé séparément sur
`astra/core24-classes-legacy-snapshot` (`3e2b53c`). Cette sauvegarde ne doit pas
être fusionnée aveuglément.

# Plan d'exécution - Étapes 0 et 1
## Rewayah Academy App - Spécification à destination de l'agent de code

Ce document décrit **ce qui doit exister** et **comment on vérifie que c'est correct**. Il ne contient pas d'implémentation. Les migrations, fonctions et tests sont écrits par l'agent de code à partir de cette spécification.

---

# ÉTAPE 0 - Socle d'exploitation

Objectif : rendre le projet réparable. Durée visée, 2 à 3 jours.

| # | Tâche | Livrable | Critère d'acceptation |
| :-- | :--- | :--- | :--- |
| 0.1 | Dépôt Git | Structure `supabase/`, `lib/`, `test/`, `docs/` avec les 4 fichiers de specs dans `docs/` | `main` protégée, aucun secret versionné, `.gitignore` couvrant `.env` et les clés |
| 0.2 | Projets Supabase | Un projet `staging`, un projet `prod` | Les deux répondent, chaînes de connexion stockées hors dépôt |
| 0.3 | Migrations versionnées | Supabase CLI, dossier `supabase/migrations/` | Une base vide reconstruite intégralement par la seule application des migrations, sans intervention manuelle |
| 0.4 | Sauvegardes | PITR activé sur `prod` | Une restauration à un instant T testée au moins une fois |
| 0.5 | Secrets | Secrets Supabase pour LiveKit, R2, service role | Recherche des clés dans le dépôt : zéro résultat |
| 0.6 | Supervision | Sentry côté Flutter et côté Edge Functions | Une erreur volontaire remonte dans le tableau de bord |
| 0.7 | Intégration continue | GitHub Actions : analyse statique, tests, build | La CI échoue sur une erreur d'analyse volontairement introduite |
| 0.8 | Variantes Flutter | `dev`, `staging`, `prod` | Trois identifiants d'application distincts, installables côte à côte |
| 0.9 | Stockage média | Bucket R2 privé, règle de cycle de vie à 30 jours | Un objet de test disparaît après expiration simulée |
| 0.10 | LiveKit | Projet Cloud, clés en secrets Supabase, endpoint de webhook déclaré | Un événement de test atteint l'endpoint et est vérifié en signature |
| 0.11 | Configuration applicative | Table `app_config` et son mécanisme de lecture | Une clé modifiée en base change le comportement sans redéploiement |

**Point d'attention 0.3** : la reconstruction complète depuis zéro est le seul critère qui compte. Un projet dont la base ne peut pas être recréée par les migrations est un projet non sauvegardé, quelles que soient les sauvegardes.

---

# ÉTAPE 1 - Fondations données et sécurité

Objectif : le modèle de données, la sécurité et les invariants métier. Aucune interface. C'est l'étape la plus coûteuse à corriger plus tard, donc la plus lente à écrire.

## 1. Principes non négociables

Ces règles s'appliquent à chaque fichier produit. Toute exception doit être justifiée par écrit.

1. **RLS activée sur toutes les tables**, sans exception, y compris celles jugées anodines. Refus par défaut, autorisation explicite.
2. **Le rôle et le foyer sont lus dans le JWT**, alimentés par un hook de jeton d'accès. Aucune policy ne doit interroger `profiles` pour connaître le rôle de l'appelant.
3. **Toute fonction en `SECURITY DEFINER`** fixe un chemin de recherche vide et qualifie chaque objet. Sans exception.
4. **La clé de service n'existe que dans les Edge Functions.** Jamais dans Flutter, jamais dans une variable compilée. Toute fonction qui l'utilise revérifie l'autorisation métier explicitement.
5. **L'argent est un entier** en unités mineures, avec devise explicite par ligne. Aucun flottant. Aucune colonne de solde modifiable : le solde se dérive des écritures.
6. **Suppression logique** par `deleted_at` sur toutes les tables métier, et **filtrée dans chaque policy**. Une suppression logique non filtrée est une fuite.
7. **Tous les horodatages** en `timestamptz`, stockés en UTC. Le fuseau est une donnée d'affichage.
8. **Toute table exposée au client passe par une vue** dès qu'une partie seulement de ses colonnes doit être visible. On ne durcit pas une policy pour cacher une colonne.

## 2. Dictionnaire de données

### Identité et foyer

| Table | Rôle | Colonnes clés | Notes |
| :--- | :--- | :--- | :--- |
| `households` | Foyer, unité de facturation et de rattachement | identifiant, tuteur principal, fuseau, statut | Un élève appartient à un et un seul foyer. **Un élève adulte autonome est un foyer d'une personne dont il est son propre tuteur**, voir ADR-009. Aucun cas particulier dans les policies |
| `profiles` | Tout utilisateur, quel que soit le rôle | identifiant `auth.users`, rôle, identifiant immuable, prénom, nom, foyer, statut de compte, `access_until`, `deleted_at` | `access_until` remplace le portefeuille en MVP-0 |
| `devices` | Appareil appairé à un profil | profil, empreinte d'appareil, plateforme, date d'appairage, révocation | Support de l'authentification enfant |
| `teacher_profiles` | Données propres à l'enseignant | profil, pays, langues, plafond horaire hebdomadaire, statut KYC | |
| `student_profiles` | Données propres à l'élève | profil, type d'élève, mode d'interface, niveau, riwaya, politique caméra, avatar | Type d'élève : mineur sous tutelle ou autonome. Mode d'interface : enfant ou standard. La politique caméra est un attribut de profil fixé une fois, pas une autorisation par séance, voir ADR-009 |
| `kyc_documents` | Références aux pièces déposées | profil, type, clé d'objet, statut, validé par, date de purge | Le fichier est dans le stockage, jamais en base |

### Planning et session

| Table | Rôle | Colonnes clés | Notes |
| :--- | :--- | :--- | :--- |
| `availability_slots` | Créneaux proposés par les enseignants | enseignant, plage horaire, récurrence, statut | Alimente le matching inversé |
| `recurrence_rules` | Règle de répétition | heure locale, fuseau IANA, règle de récurrence, date de fin | **Ne pas stocker de récurrence en UTC absolu**, voir audit O3 |
| `sessions` | Une séance de cours | enseignant, début, fin, statut, salle, type, `deleted_at` | **Aucune colonne `student_id`**, voir ADR-004 |
| `session_participants` | Qui participe à quoi | session, profil, rôle dans la séance, entrée, sortie | Table pivot, cœur du modèle et des policies |
| `session_events` | Faits observés | session, profil, type d'événement, horodatage serveur, source | Alimentée **uniquement** par les webhooks LiveKit |
| `session_recordings` | Métadonnées d'archive | session, clé d'objet, durée, taille, codec, statut, expiration | Jamais de binaire, voir ADR-006 |

Rôles possibles dans `session_participants` : enseignant, élève, tuteur observateur, contrôleur masqué.

### Pédagogie

| Table | Rôle | Notes |
| :--- | :--- | :--- |
| `lesson_reports` | Cahier de transmission | Une ligne par session, clé d'idempotence pour le rejeu hors ligne |
| `makharij_findings` | Constats phonétiques | Rattachés au rapport, jeu de paires extensible |

### Finance, schéma seulement

Créées sans interface, voir ADR-003.

| Table | Rôle |
| :--- | :--- |
| `wallets` | Un portefeuille par foyer |
| `wallet_entries` | Écritures signées, entiers, devise par ligne |
| `payout_methods` | Coordonnées de versement, avec date de dernière modification pour le verrou 48 h |
| `payouts` | Ordres de versement |
| `fx_rates` | Taux historisés |
| `webhook_events` | Idempotence des webhooks entrants |

### Système

| Table | Rôle | Notes |
| :--- | :--- | :--- |
| `audit_logs` | Journal immuable | Partitionnée par mois, chaînage de hash |
| `id_sequences` | Compteurs des identifiants immuables | Incrément atomique |
| `app_config` | Configuration administrable | Voir section 8 |
| `rate_limits` | Compteurs de limitation | Seau à jetons |
| `device_tokens` | Jetons de notification push | |

## 3. Contraintes et index attendus

| # | Objet | Exigence |
| :-- | :--- | :--- |
| C1 | `profiles.immutable_id` | Unicité, plus interdiction de modification après création |
| C2 | Chevauchement de sessions | Un même profil ne peut pas participer à deux sessions dont les plages se recoupent. Contrainte d'exclusion en base, pas de vérification applicative |
| C3 | Plafond de participants | Tant que `allow_multi_participant_sessions` est faux, deux participants maximum par session. Vérifié en base |
| C4 | Composition de session | Exactement un enseignant par session |
| C5 | Transitions d'état | Toute transition non prévue par la machine à états est refusée en base |
| C6 | `audit_logs` | Modification et suppression révoquées et refusées par déclencheur, pour tous les rôles applicatifs |
| C7 | Index de planning | Index partiels sur les sessions à venir uniquement, par enseignant et par participant |
| C8 | Index de journal | Index par plage sur la date, index d'inclusion sur la charge utile, index sur l'acteur |
| C9 | Idempotence | Unicité sur la référence externe dans `webhook_events` et sur la clé d'idempotence dans `lesson_reports` |
| C10 | Une seule séance active par profil | Aucun token de séance n'est délivré si un token actif existe déjà pour ce profil, quel que soit l'appareil. Voir ADR-010 |
| C11 | Appareils appairés | Deux appareils actifs au maximum par élève, révocables par le tuteur |

**Sur C2 et C3** : ces deux règles sont les plus tentantes à implémenter côté application et les plus dangereuses à y laisser. Deux enseignants qui cliquent au même instant, ou un administrateur qui désactive le multi-participants pendant qu'une session en cours en compte trois, produisent des états incohérents impossibles à réparer. La base doit refuser, pas l'écran.

## 4. Matrice d'accès

Lecture notée L, écriture notée E, tiret pour aucun accès. Toutes les lectures sont bornées par la suppression logique.

| Table | Admin | Comptable | Contrôleur | Enseignant | Tuteur | Élève |
| :--- | :-: | :-: | :-: | :-: | :-: | :-: |
| `profiles` | L E | L partiel | L partiel | L via vue | L foyer | L soi |
| `households` | L E | L | - | - | L sien | - |
| `devices` | L E | - | - | - | L E foyer | L sien |
| `kyc_documents` | L E, filtre genre | - | - | E sien | E foyer | - |
| `availability_slots` | L E | - | L | L E siens | L | - |
| `sessions` | L E | L | L | L E siennes | L foyer | L siennes |
| `session_participants` | L E | - | L | L siennes | L foyer | L via vue |
| `session_events` | L | - | L | L siennes | L foyer | - |
| `session_recordings` | L | - | L | L siennes | L foyer | - |
| `lesson_reports` | L | - | L | L E siens | L foyer | L le concernant |
| Tables finance | L E | L E | - | L sien | L foyer | - |
| `audit_logs` | L | - | L | - | - | - |
| `app_config` | L E | - | - | - | - | - |

Aucun rôle ne dispose de suppression physique. Aucun rôle n'écrit dans `audit_logs` ni dans `session_events` : ces deux tables ne sont alimentées que par des fonctions serveur.

## 5. Vues d'exposition restreinte

| Vue | Exposée à | Contenu exact | Raison |
| :--- | :--- | :--- | :--- |
| `session_peers_v` | Élève | Prénom, identifiant immuable | Décision ADR-004. Deux colonnes, jamais plus |
| `teacher_roster_v` | Enseignant | Prénom, nom, identifiant, niveau, riwaya des seuls élèves de ses sessions | Cloisonnement, l'enseignant n'atteint jamais `profiles` |
| `family_sessions_v` | Tuteur | Sessions des enfants du foyer avec statut en direct | Alimente le suivi famille sans exposer l'enseignant au-delà du nécessaire |

Principe : ces vues sont la seule surface de lecture inter-utilisateurs de l'application. Une colonne ajoutée demain à `profiles` n'apparaît nulle part tant qu'elle n'est pas explicitement ajoutée ici.

## 6. Fonctions et déclencheurs attendus

| Nom | Entrée | Sortie | Garantie exigée |
| :--- | :--- | :--- | :--- |
| Hook de jeton d'accès | Utilisateur authentifié | Jeton enrichi du rôle et du foyer | Le rôle ne provient jamais du client |
| Attribution d'identifiant immuable | Code de rôle, initiales | Identifiant formaté | Atomique sous concurrence. Aucun `max` plus un. Pas de trou exploitable |
| Refus de modification d'identifiant | Déclencheur | Exception | L'immuabilité est appliquée, pas seulement déclarée |
| Chaînage du journal | Déclencheur à l'insertion | Empreinte liée à la précédente | Permet de détecter une altération faite avec la clé de service |
| Refus de modification du journal | Déclencheur | Exception | Complète la révocation des droits |
| Plafond de participants | Déclencheur | Exception | Lit `app_config` au moment de l'insertion |
| Validation de transition d'état | Déclencheur | Exception | Applique la machine à états de la section 7 |
| Écriture d'événement de présence | Charge utile de webhook vérifiée | Ligne `session_events` | Rejette toute source non signée |
| Journalisation d'accès sensible | Contexte d'appel | Ligne `audit_logs` | Appelée à chaque lecture KYC et à chaque écoute d'archive |

## 7. Machine à états de session

États : planifiée, pre-flight, en cours, terminée, absence enseignant, absence élève, échec technique, annulée tardivement, annulée.

| Depuis | Vers | Déclencheur | Effet en V1 |
| :--- | :--- | :--- | :--- |
| planifiée | pre-flight | Rapport de pre-flight enregistré | - |
| pre-flight | en cours | Premier événement d'entrée reçu du serveur média | - |
| planifiée ou pre-flight | absence enseignant | Aucune entrée de l'enseignant à T+5, détecté côté serveur | Crédit rendu au foyer |
| planifiée ou pre-flight | absence élève | Aucune entrée de l'élève à T+5 | Séance décomptée, enseignant payé |
| en cours | terminée | Fin de plage ou sortie de tous les participants | Séance décomptée, paie due |
| en cours | échec technique | Rupture réseau qualifiée | Aucune imputation de faute |
| planifiée | annulée tardivement | Annulation sous préavis minimal | Règle de pénalité à définir |
| planifiée | annulée | Annulation dans les délais | Crédit rendu |

Les colonnes d'effet financier sont créées dès maintenant, non utilisées en MVP-0.

**Aucune transition ne peut être déclenchée par le client.** La détection d'absence est un travail planifié côté serveur, pas un bouton.

## 8. Configuration administrable

| Clé | Défaut | Point d'application |
| :--- | :--- | :--- |
| `allow_multi_participant_sessions` | faux | Déclencheur en base sur `session_participants` |
| `max_participants_per_session` | 2 | Même déclencheur |
| `camera_auto_allow_min_age` | 11 | Valeur initiale de la politique caméra à la création du profil : autorisée au-dessus, interdite à partir de 10 ans et moins. Modifiable ensuite par le tuteur, par enfant |
| `child_ui_mode_max_age` | à trancher | Détermine le mode d'interface à la création du profil |
| `absence_threshold_minutes` | 5 | Travail planifié de détection |
| `recording_retention_days` | 30 | Purge planifiée et cycle de vie du bucket |
| `video_active_provider` | livekit_cloud | Émission du token |
| `video_ws_url_override` | vide | Émission du token, voir ADR-001 |
| `video_canary_percentage` | 0 | Émission du token |
| `max_devices_per_student` | 2 | Fonction d'appairage |
| `max_concurrent_sessions_per_profile` | 1 | Émission du token de séance |

Toute valeur modifiée est journalisée avec l'ancienne valeur, le nouvel opérateur et l'horodatage.

## 9. Scénarios de test d'acceptation

Ces scénarios sont la véritable définition de fin d'étape. Ils passent avant toute interface.

**Cloisonnement**
1. Un enseignant ne lit aucune ligne d'un élève avec lequel il ne partage aucune session.
2. Un élève ne lit aucune ligne d'un autre élève, sauf les deux colonnes de `session_peers_v` et uniquement pour une session partagée.
3. Un tuteur ne lit rien en dehors de son foyer.
4. Un compte non actif ne lit rien du tout, quel que soit son rôle.
5. Un profil supprimé logiquement n'apparaît dans aucune lecture, dans aucun rôle.

**Concurrence**
6. Deux réservations simultanées du même créneau : une seule aboutit, l'autre reçoit une erreur explicite.
7. Deux attributions simultanées d'identifiant immuable : deux valeurs distinctes, aucune collision, aucun blocage.
8. Insertion d'un troisième participant alors que le multi-participants est désactivé : refusée.

**Immuabilité**
9. Modification d'un identifiant immuable : refusée.
10. Modification ou suppression d'une ligne de journal, y compris avec la clé de service : refusée ou détectable par le chaînage.

**KYC**
11. Un membre du personnel masculin ne peut lire aucun document d'un dossier féminin.
12. Toute lecture d'un document produit une ligne de journal nommant le lecteur.

**États**
13. Toute transition hors machine à états : refusée.
14. Une absence d'enseignant est détectée sans aucune action du client.

**Appareils et caméra**
15. Un profil déjà en séance sur un appareil se voit refuser un second token depuis le deuxième appareil.
16. Un troisième appairage d'appareil pour un même élève : refusé.
17. Un profil dont la politique caméra vaut interdite reçoit un token sans droit de publier la vidéo, vérifié sur le token lui-même et non sur l'interface.
18. Un élève adulte autonome, foyer d'une personne, accède exactement aux mêmes ressources qu'un élève mineur accède dans son foyer, sans branche de code distincte.

**Migration**
19. Un profil en `provisoire_actif` accède aux mêmes ressources qu'un profil `actif`.
20. Aucune route d'inscription publique ne peut produire un profil en `provisoire_actif` : seul un import déclenché par un rôle Admin le peut.

## 10. Définition de fin d'étape

L'Étape 1 est terminée quand, et seulement quand :

- une base vide se reconstruit intégralement par les seules migrations ;
- les quatorze scénarios ci-dessus passent en automatisé ;
- aucune table n'est sans RLS ;
- aucune fonction en `SECURITY DEFINER` n'est sans chemin de recherche fixé ;
- aucune clé sensible n'apparaît dans le dépôt ;
- le dictionnaire de données ci-dessus correspond à ce qui existe réellement en base.

---

## Ce qu'il me faut avant de spécifier l'Étape 2

Rien de bloquant. La cible est désormais fixée : **toutes les plateformes pour tous les rôles**, filigrane abandonné, anti-pillage déplacé côté serveur (ADR-008). Le routeur de l'Étape 2 sera donc unique, sans branche par plateforme.

Une valeur par défaut reste à choisir, décidable pendant l'écriture de l'Étape 1 :

1. `child_ui_mode_max_age` : l'âge en dessous duquel le mode enfant s'applique. Vous évoquez 7 à 8 ans comme seuil d'autonomie sur le micro et la caméra.

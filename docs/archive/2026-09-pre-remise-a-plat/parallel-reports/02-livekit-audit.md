# Audit 02 — chaîne LiveKit et exploitation

Date de l’audit : 14 septembre 2026. Périmètre : lecture seule du checkout
D:/RA _APP/RA -OFFICIAL-APP, sans création de compte, secret demandé,
écriture applicative ni déploiement.

## Conclusion

Le socle N2 est présent dans le dépôt : migration 0010, émission de jeton,
vérification de webhook, aiguillage Cloud/self-hosted et module Flutter
lib/core/video/. La salle N3 et ses tests existent également.

La chaîne LiveKit réelle n’est toutefois pas démontrée aujourd’hui. Aucun
compte LiveKit, endpoint WebSocket réel, webhook fournisseur effectivement
déclaré, événement signé reçu, ni parcours authentifié dans une salle n’est
confirmé par cet audit. Les documents de suivi contiennent des affirmations
historiques contradictoires ; elles ne remplacent pas une vérification
courante.

Egress et R2 ne sont pas opérationnels dans le périmètre livré. Le schéma
contient seulement les métadonnées d’enregistrement et une rétention cible de
30 jours. Aucun producteur Egress, dépôt R2, cycle de vie, URL signée ou
parcours de lecture n’est présent dans le code.

## 1. État du checkout et méthode

- Checkout inspecté : D:/RA _APP/RA -OFFICIAL-APP.
- HEAD : cbc4ff8dca794762a57ce25ae44ddebd48c4cf56 sur main.
- Le worktree contient des modifications concurrentes, notamment dans
  pubspec.yaml, pubspec.lock, docs/HANDOFF.md et docs/PROGRESS.md. Aucun fichier
  de supabase/functions/, lib/core/video/ ou de la migration 0010 n’est
  modifié dans l’état observé.
- Les fonctions et le module vidéo sont présents dans l’historique Git ; le
  lot N2 apparaît comme e76a14e.
- Le paquet Flutter verrouillé est livekit_client 2.12.0 ; sa dépendance WebRTC
  transitive est flutter_webrtc 1.6.0.
- La vérification CLI distante n’a pas produit de résultat : supabase
  functions list et supabase secrets list ont été bloqués avant réponse par
  une tentative d’écriture de télémétrie hors workspace (EPERM). Les sondes
  HTTPS non authentifiées ont également été bloquées par le proxy/TLS du poste.

Les lignes « déployée » ou « ACTIVE » de la documentation sont donc rapportées
comme documentation historique, pas comme une preuve distante produite par cet
audit.

## 2. create-room-token

Fichiers : supabase/functions/create-room-token/index.ts et
supabase/functions/_shared/livekit.ts.

Chaîne observée :

1. OPTIONS est traité pour la PWA.
2. videoConfiguree() est appelé avant l’authentification. Il vérifie qu’au
   moins une paire clé/secret LiveKit existe, mais ne vérifie ni URL WebSocket
   ni format wss://.
3. appelant() valide le Bearer Supabase par auth.getUser() ; l’identité n’est
   pas lue dans le JSON.
4. Le corps doit contenir session_id.
5. La fonction appelle uniquement le RPC service autoriser_jeton_video, avec
   l’identité issue du JWT et les URLs des deux fournisseurs lues côté Edge.
6. Le RPC décide l’appartenance, la fenêtre horaire, le rôle, les capacités, le
   fournisseur et la salle. TypeScript ne décide donc pas des droits.
7. signerJeton() signe le jeton avec le SDK serveur officiel et retourne ws_url,
   token, room_name, provider, rôle, expiration et capacités.

Constats :

- Le contrôle métier est bien placé en base et les RPC sensibles sont révoqués
  pour anon, authenticated et public dans 0010.
- Les capacités sont restrictives par défaut : micro, caméra, données et
  invisibilité viennent du résultat SQL ; l’élève n’a pas de caméra par défaut
  et le contrôleur masqué ne publie rien.
- Le contrôle de configuration avant auth révèle à un appelant non authentifié
  la différence entre « vidéo non configurée » (503) et configuration présente
  (401). C’est utile pour le diagnostic historique, mais c’est une divulgation
  d’état d’exploitation à traiter avant une ouverture publique.
- Si les clés existent mais que l’URL du fournisseur retenu manque ou est
  invalide, l’appel SQL échoue et la fonction peut répondre 403 accès à la salle
  refusé, ce qui masque une panne de configuration comme un refus d’accès.
- CORS est * dans le helper commun. Le Bearer reste requis côté code, mais la
  surface d’appel navigateur est volontairement large.

## 3. livekit-webhook

Fichier : supabase/functions/livekit-webhook/index.ts.

Comportement observé :

- La fonction n’accepte que POST.
- Elle ne dépend pas d’un JWT Supabase ; elle vérifie l’en-tête Authorization
  comme signature LiveKit via WebhookReceiver.
- Les deux trousseaux (CLOUD puis SELFHOST) sont essayés.
- L’identité participant n’est utilisable pour la présence que si elle est un
  UUID. La salle est résolue par session_video_route, jamais par une donnée
  personnelle reçue par le client.
- Seuls participant_joined et participant_left deviennent des événements de
  présence. Les autres événements restent dans
  livekit_webhook_deliveries.
- L’idempotence repose sur la clé primaire event_id et le RPC
  enregistrer_webhook_livekit. Une erreur de base renvoie 500 pour provoquer un
  rejeu ; un rejet de signature renvoie 401.
- Sans identifiant LiveKit, le fallback
  sans_id:type:salle:identité:timestamp peut fusionner deux événements distincts
  à la même seconde. Cette voie de dégradation ne constitue pas une
  idempotence complète.

Le webhook ne prouve pas à lui seul qu’un fournisseur l’appelle. Il faut encore
un endpoint déclaré côté fournisseur et une livraison signée correspondant à
une salle réellement routée.

## 4. lib/core/video

Le module contient :

- video_session_provider.dart : contrat abstrait, accès, capacités, états,
  participants et qualité ; aucune URL LiveKit en dur.
- service_video.dart : appel Supabase de create-room-token, inscriptions du
  tuteur/contrôleur et annonce de sortie volontaire.
- pre_vol.dart : énumération des périphériques via le SDK et règle « le micro
  suffit ». Le pré-vol reste un contrôle local, pas une preuve de connexion
  serveur.
- livekit_session_provider.dart : création/connexion/déconnexion de Room,
  écoute des événements, publication des participants, audio seul, baisse
  automatique de la caméra sur qualité dégradée et libération des ressources.

Le commentaire « seul fichier autorisé à importer livekit_client » n’est pas
exact : livekit_session_provider.dart et pre_vol.dart l’importent. Les tests
existants utilisent principalement des faux : modeles_video_test.dart (13 cas),
vue_salle_test.dart (23 cas) et features/salle_test.dart (25 cas). Ils couvrent
les contrats et l’interface, pas une négociation WebRTC réelle, une permission
OS réelle ou le cycle de vie d’une salle LiveKit réelle.

## 5. Variables attendues

| Variable | Consommateur | Observation | Statut prouvable ici |
|---|---|---|---|
| SUPABASE_URL | helper Edge | URL du projet pour les clients Supabase | nécessaire ; valeur distante non inspectée |
| SUPABASE_ANON_KEY | appelant() | validation du JWT utilisateur | nécessaire ; aucune valeur affichée |
| SUPABASE_SERVICE_ROLE_KEY | clientService() | RPC métier côté serveur | nécessaire ; aucune valeur affichée |
| LIVEKIT_CLOUD_API_KEY | signature Cloud | paire avec le secret Cloud | présence historique seulement selon handoff |
| LIVEKIT_CLOUD_API_SECRET | signature Cloud/webhook | secret serveur | présence historique seulement selon handoff |
| LIVEKIT_CLOUD_WS_URL | routage Cloud | URL remise au client à chaque salle | non validée dans videoConfiguree() ; non confirmée |
| LIVEKIT_SELFHOST_API_KEY | signature self-host | paire optionnelle du second fournisseur | non confirmée |
| LIVEKIT_SELFHOST_API_SECRET | signature self-host | secret serveur | non confirmée |
| LIVEKIT_SELFHOST_WS_URL | routage self-host | URL du second fournisseur | non confirmée |

STUDENT_EMAIL_DOMAIN existe pour une autre fonction Edge et n’est pas une
dépendance LiveKit. Aucune variable R2, Egress, S3 ou Cloudflare n’est
référencée par le code.

## 6. État du fournisseur

Le dépôt versionne une configuration de routage, pas l’état du fournisseur :

- video_config a par défaut active_provider = cloud, canari nul/0 et TTL de
  jeton de 900 secondes.
- session_video_route fige fournisseur, URL et nom de salle lors de la première
  émission ; ce mécanisme évite qu’un changement de canari sépare les
  participants d’une même séance.
- video_config_lire() est réservé à l’administration ; aucune lecture publique
  ne permet de conclure depuis le dépôt à la valeur courante de la base réelle.

Le handoff affirme qu’un appel historique non authentifié à create-room-token
avait renvoyé 401 authentification requise plutôt que 503 vidéo non configurée,
ce qui indique que les clés API/secret étaient présentes au moment de cette
mesure puisque le test de configuration précède l’authentification. Le même
handoff dit toutefois qu’aucun compte LiveKit n’est confirmé ; PROGRESS.md et
MISE-EN-SERVICE.md conservent aussi l’ancien état 503. L’état réel actuel du
fournisseur doit donc être classé **non confirmé**, pas « opérationnel ».

La configuration Edge des fonctions n’est pas versionnée par fonction dans
supabase/config.toml. Le workflow .github/workflows/deploy.yml utilise
supabase functions deploy ... --no-verify-jwt globalement. C’est compatible
avec le webhook qui vérifie sa propre signature et avec create-room-token qui
valide son utilisateur dans le code, mais cela désactive aussi la protection
JWT de toute future fonction déployée par ce job. La configuration historique
verify_jwt = true documentée pour d’autres fonctions est donc en tension avec
ce workflow et doit être réconciliée avant exploitation.

## 7. Egress et R2

### Ce qui existe

- session_recordings existe depuis 0001 comme table de métadonnées : clé
  objet, durée, taille, codec, statut et expiration.
- recording_retention_days = 30 existe dans app_config.
- Les policies de lecture sont présentes pour administration/contrôle,
  enseignant et foyer ; aucun chemin d’écriture opérationnel n’est trouvé dans
  la chaîne LiveKit auditée.
- Les buckets Supabase kyc et avatars sont distincts du stockage audio R2.

### Ce qui manque

La recherche du checkout ne trouve aucun code Egress, aucune configuration
Cloudflare/R2, aucun secret R2, aucun cycle de vie de bucket, aucune fonction de
démarrage Egress, aucun callback de fin d’Egress, aucune écriture des
métadonnées session_recordings, aucune URL signée de lecture et aucun audit de
lecture audio. Le fichier partagé LiveKit importe seulement AccessToken et
WebhookReceiver ; il n’expose pas le startEgress() annoncé par l’ADR-001.

La présence du modèle SQL et de la décision ADR-002/ADR-006 ne constitue donc pas
une preuve d’enregistrement actif.

### Prérequis R2 avant activation

À fournir et vérifier dans un lot d’exploitation autorisé :

1. compte Cloudflare et bucket R2 privé ;
2. règles de cycle de vie à 30 jours, avec traitement explicite d’un litige
   qui gèle la pièce ;
3. configuration LiveKit Egress audio_only, format et destination R2 ;
4. credentials/binding nécessaires côté Egress, conservés hors dépôt ;
5. chiffrement, séparation des accès et journalisation des écoutes ;
6. insertion serveur des métadonnées dans session_recordings, cohérente avec
   object_key, durée, taille, codec, statut et expiration ;
7. génération serveur d’une URL de lecture courte, annoncée à 60 secondes par
   les ADR, sans exposition de credentials ;
8. notice d’information et consentement correspondant à l’enregistrement audio
   systématique.

Aucun de ces prérequis n’a été créé ou activé par cet audit.

## 8. Prérequis LiveKit et recette suivante

Avant une recette bout en bout, il faut au minimum :

- un compte/projet LiveKit confirmé et un fournisseur cible explicitement
  choisi pour la recette ;
- une URL WebSocket wss:// vérifiée, les deux secrets du fournisseur retenu
  dans les secrets Supabase, et la configuration de routage correspondante ;
- le webhook déclaré côté fournisseur vers
  https://gggmtelinlpseweouyav.supabase.co/functions/v1/livekit-webhook ;
- quatre comptes de test autorisés (enseignant, élève, tuteur, contrôleur) avec
  accès OTP/lien ;
- une séance réellement attribuée et dans sa fenêtre d’ouverture ;
- deux navigateurs ou appareils pour vérifier entrée, audio, caméra selon
  policy, présence, sortie, reconnexion et observation masquée ;
- Egress/R2 activés et une procédure de vérification de l’objet, de sa rétention
  et de sa lecture signée.

La recette doit ensuite vérifier la livraison d’un webhook signé, l’idempotence
d’un rejeu, le routage stable de la séance, l’absence de publication à
l’entrée, la politique caméra, la libération des tracks et la non-fuite du
contrôleur. Elle n’est pas exécutable complètement avec le contexte actuel.

## 9. Ce qui est prouvable sans compte LiveKit

### Prouvable par inspection/tests locaux

- présence et forme du contrat Flutter ;
- séparation des appels Supabase, de la décision SQL et de la signature Edge ;
- capacités attendues et règles de refus dans les fixtures ;
- mapping des événements webhook, UUID et idempotence SQL ;
- routage Cloud/self-hosted et TTL dans le SQL ;
- absence d’URL LiveKit en dur dans lib/ ;
- absence actuelle de code Egress/R2 ;
- analyse statique, tests Flutter et scénarios SQL déjà documentés, sous
  réserve de ne pas les confondre avec une séance réelle.

### Non prouvable sans compte, secrets et comptes de test

- existence et état du projet LiveKit Cloud ou du serveur self-hosted ;
- validité, connectivité TLS/TURN et quota de l’URL WebSocket ;
- acceptation du JWT par LiveKit et création/rejointure d’une room ;
- publication/réception audio-vidéo et permissions réelles du navigateur/OS ;
- événements participant_joined/left, ordre, retry et signature réellement
  livrés par le fournisseur ;
- comportement de reconnexion, qualité, audio seul et libération de ressources
  après plusieurs cycles ;
- invisibilité réelle du contrôleur sur toutes les surfaces ;
- déclenchement Egress, dépôt R2, chiffrement, expiration et lecture signée ;
- parcours authentifiés enseignant/élève/tuteur/contrôleur et recette
  responsive/RTL/clavier/texte à 200 % en navigateur réel.

## 10. Contradictions documentaires à corriger ultérieurement

- MISE-EN-SERVICE.md §8 décrit encore create-room-token en 503 vidéo non
  configurée, alors que le handoff récent rapporte 401 avec clés présentes.
- PROGRESS.md reprend simultanément « secrets à poser » et l’historique du 401 ;
  il ne permet pas de conclure à l’état courant.
- ADR-001 conserve les anciens noms LIVEKIT_WS_URL, LIVEKIT_API_KEY,
  LIVEKIT_API_SECRET et annonce startEgress(), tandis que l’ADR-023 et le code
  utilisent des préfixes fournisseur et n’implémentent pas Egress.
- Les documents annoncent un seul import Flutter du SDK, mais pre_vol.dart
  l’importe également.
- Le commentaire Env décrit les secrets LiveKit comme hors Flutter, ce qui est
  correct ; le fichier local dart_define.json observé contient cependant des
  valeurs de développement et GALERIE/PLAYGROUND activés. Il ne doit pas être
  utilisé pour une preuve de production.

## Verdict

**Code N2 : inspecté, cohérent sur le chemin nominal, testé surtout par
fixtures.**

**Edge Functions et fournisseur distant : documentés comme déployés, mais non
vérifiés couramment par cet audit.**

**Salle LiveKit réelle : non prouvée.**

**Egress/R2 : modèle documentaire/SQL présent, exploitation absente.**

La prochaine action autorisée est une confirmation opérateur du fournisseur, des
secrets et des comptes de test, suivie d’une recette d’intégration séparée. Ce
rapport n’a créé aucun compte, demandé aucun secret et effectué aucun
déploiement.

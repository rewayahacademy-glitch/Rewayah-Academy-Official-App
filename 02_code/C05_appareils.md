# C05 - Appareils et association QR : cartographie (lecture seule)

Date : 24/09/2026. Dépôt `D:\RA _APP\RA -OFFICIAL-APP`, branche `c0/configuration-baseline-2026-09-23` (non modifiée, rien créé dans le dépôt). Autres branches lues par `git diff main...<branche>` uniquement.

Méthode : lecture intégrale de `lib/core/appairage/*`, `lib/features/appareils/*`, `lib/features/eleve_connexion/*`, `lib/core/widgets/pin_pad.dart`, `lib/core/cache/secure/stockage_securise.dart`, `test/appairage/*`, `test/features/appareils_test.dart`, `test/features/eleve_connexion_test.dart`, des migrations `0001`, `0004`, `0014`, `0038` (parties appairage), des fonctions Edge `session-enfant` et `_shared/clients.ts`, des scénarios SQL `scenarios_etape3.sql`, des manifestes plateformes, de `pubspec.yaml`/`pubspec.lock`, de la source `functions_client-2.7.1` du cache pub. Pub.dev consulté pour `mobile_scanner`.

Limites : **aucun test Flutter ni build exécuté** dans cette phase (lecture seule, machine partagée). Aucune requête sur la base distante. Tout ce qui suit est « présent dans le code » sauf mention contraire. Les scénarios SQL d'appairage existent mais le rejeu CI des migrations est `BLOCKED_INFRA` (`docs/current/CONFIGURATION_BASELINE_2026-09-23.md:18`) : garanties serveur **écrites, non rejouées**.

---

## 0. Synthèse en 12 points

1. **Sens du protocole** : l'appareil **du tuteur (authentifié, rôle `guardian`)** affiche un QR et un code de 6 caractères pour **un élève choisi avant la demande** ; l'**appareil de l'élève (sans session)** saisit ce code. Le QR n'est lu par rien : **aucun scanner n'existe** (`eleve_connexion_page.dart:331-334`, `feuille_appareil_eleve.dart:17-19`).
2. Le QR ne porte que le code brut (`appairage_page.dart:160-174`), jamais une URL ni un identifiant de foyer.
3. Côté serveur, la sécurité du code est réelle et bornée : TTL configurable 10 min (`0004:116-119`, `:628-629`), empreinte SHA-256 seule stockée (`:634`), usage unique sous verrou `for update` (`:666-679`, `:709-711`), un seul code vivant par élève (`:617-621`), lien au foyer vérifié à la création (`:597-606`), plafond d'appareils vérifié à la création ET à la consommation (`:608-615`, `:684-692`), journal (`:639`, `:713`). **Pas de limitation de débit** sur `session-enfant` (assumé, `session-enfant/index.ts:16-20`).
4. **L'écran émetteur ne sait jamais que le code a été consommé ni remplacé** : il n'interroge rien après la création. Il n'a que 4 états (chargement, actif, expiré, erreur). Manquent validation, confirmé, révoqué/remplacé, réseau, reprise.
5. **Aucune dépendance de scan caméra** dans `pubspec.yaml` ni sur aucune branche locale. **Aucune permission caméra** déclarée (Android `main` vide, iOS sans `NSCameraUsageDescription`, pas d'en-tête web).
6. **Défaut probable de course après appairage** : `ServiceEnfant.appairer` ouvre la session (`verifyOTP`, `service_enfant.dart:73`, `:109-114`) avant que la page n'ait écrit le profil local et fait créer le code personnel ; le routeur renvoie alors un élève actif hors de `/connexion` (`redirection.dart:81-86`). À prouver par un test, mais le mécanisme est lisible dans le code.
7. **Appareil partagé bloqué après le premier profil** : l'écran « Qui es-tu ? » n'offre aucun moyen de saisir un nouveau code (`eleve_connexion_page.dart:339-375`). Le serveur accepte pourtant plusieurs enfants sur une même tablette (scénario S6, `scenarios_etape3.sql:354-373`).
8. **Échecs silencieux côté élève** : les messages d'erreur posés pendant le pavé (`_message`) ne sont jamais affichés (`_pave`, `:377-392`) ; un appareil révoqué voit le pavé ne rien faire. `oublierAppareil` / `effacerEmpreintePin` ne sont appelés nulle part en production.
9. **Tous les refus serveur deviennent un seul message** côté élève (« Ce code ne marche pas ») alors que le serveur distingue inconnu / expiré / déjà utilisé / plafond : `functions.invoke` lève `FunctionsHttpException` sur statut non 2xx (`functions_client-2.7.1/lib/src/functions_client.dart:255-270`), la branche `error` de `_corps` (`service_enfant.dart:96-99`) est donc morte pour les refus.
10. **Retrait** : bouton « Retirer » sans confirmation (clé `revoquerConfirmation` inutilisée hors galerie), sans état d'attente, erreur perdue (`unawaited`, `appareils_page.dart:151`). Serveur : `revoquer_appareil` efface le jeton (`0004:757-759`) mais **ne ferme pas une session déjà ouverte** sur l'appareil (le hook JWT ne regarde pas `devices`, `0038:50-98`).
11. **Limites affichées en dur** (2 appareils, 10 minutes, `appareilsParEleve = 2`) alors que le tuteur ne peut pas lire `app_config` (policy admin seule, `0001:969-970`).
12. **Recommandation scan** : `mobile_scanner` 7.4.2 (pub.dev, publié il y a 9 jours au 24/09) : Dart min 3.7, Flutter >= 3.29, Android minSdk 23, iOS 12, Web oui, **Windows non**. Compatible avec Flutter 3.47.2 / Dart 3.13.2 / minSdk 24 / iOS 15.0 du dépôt, **non installé, non vérifié par `pub get`**.

---

## 1. Protocole exact, tel que le code le fait

### 1.1 Acteurs

| Rôle | Appareil | Authentifié ? | Route | Fichier |
|---|---|---|---|---|
| Tuteur | le sien | oui, session Supabase, rôle `guardian`, compte valide (`0004:593-595`) | `/tuteur/foyer` puis `/tuteur/foyer/appairer/:eleveId` (`routes.dart:68`, `:77-80`, `app_router.dart:278-290`) | `appareils_page.dart`, `appairage_page.dart` |
| Élève | tablette/téléphone/PC de l'élève, éventuellement partagé | **non** au moment du code ; `/connexion/*` n'est ouvert qu'à une porte `deconnecte` (`redirection.dart:39-49`) | `/connexion/eleve` (`routes.dart:21`, `app_router.dart:116-120`) | `eleve_connexion_page.dart` |
| Serveur | RPC SQL + fonction Edge | clé de service dans l'Edge (`_shared/clients.ts:34-41`) | - | `0004_inscription_kyc_appairage.sql`, `session-enfant/index.ts` |

### 1.2 Séquence d'appairage (premier appareil)

1. **Choix de l'élève (tuteur)** : sur `/tuteur/foyer`, une carte par élève (`appareils_page.dart:71-88`) ; « Ajouter un appareil » navigue vers `Routes.appairerPour(eleve.id)` (`:164-168`). L'identifiant de l'élève est dans l'URL, pas un secret.
2. **Création du code (tuteur)** : à l'ouverture, `initState` appelle `creerCode(eleveId)` (`appairage_page.dart:43-50`) -> RPC `creer_code_appairage(p_student_profile_id)` (`service_appairage.dart:216-232`).
   Serveur (`0004:580-647`) : rôle `guardian` + compte valide (`:593-595`) ; élève du même foyer, rôle `student`, non supprimé (`:597-606`) ; plafond actif `max_devices_per_student` défaut 2 (`:608-615`) ; **périme tout code vivant de l'élève** (`deleted_at = now()`, `:617-621`) ; tirage 6 caractères dans `23456789ABCDEFGHJKLMNPQRSTUVWXYZ` sans biais (`:585-587`, `:623-626`) ; expiration `now() + pairing_code_ttl_minutes` (10 par défaut, `:628-629`) ; stocke `sha256(code)` seulement (`:631-637`) ; journal `appairage_code_cree` (`:639-640`) ; rend `(code, expires_at)` (`:642`), **sans l'id du code**.
3. **Affichage (tuteur)** : QR 224 px (`AppSpacing.xxxl * 7`, `appairage_page.dart:175`) aux couleurs de `surfaceCanvas`, code espacé « A B 2 3 C D », compte à rebours `Expire dans m:ss` recalculé chaque seconde sur l'horloge locale (`:46-49`, `:86-87`, `:109-121`).
4. **Saisie (élève)** : depuis `/connexion`, bouton « Connecter l'appareil d'un élève » -> feuille adressée au tuteur -> « Saisir le code » -> `/connexion/eleve` (`connexion_page.dart:165-170`, `feuille_appareil_eleve.dart:24-46`). Champ 6 caractères, majuscules, filtre `[A-Z2-9]` (`eleve_connexion_page.dart:310-322`).
5. **Consommation** : `ServiceEnfant.appairer(code, empreinteAppareil, plateforme)` -> Edge `session-enfant` (`service_enfant.dart:58-80`). L'empreinte est un aléa de 32 octets rangé dans `flutter_secure_storage` (`stockage_securise.dart:91-99`), forgeable et reconnu comme tel (`:44-48`).
   Edge (`session-enfant/index.ts:41-57`) : plateforme parmi 4 valeurs (`:44`) -> RPC `consommer_code_appairage` (service_role seul, `0004:720-722`) : recherche par empreinte `upper(btrim(code))` sous `for update` (`:659`, `:666-669`) ; refus `code inconnu` / `code deja utilise` / `code expire` (`:671-679`) ; plafond re-vérifié en excluant l'appareil présent (`:684-692`) ; upsert `devices` sur `(profile_id, device_fingerprint)` avec nouveau `token_hash`, `revoked_at = null` (`:694-707`) ; code marqué consommé (`:709-711`) ; journal (`:713-714`) ; rend `(profile_id, device_id, device_token)` en clair **une seule fois**.
   Puis l'Edge génère un lien magique (`:76-87`) et rend `profile_id`, `first_name`, `token_hash`, `device_token` (`:95-100`).
6. **Session élève** : le client échange `token_hash` par `verifyOTP(magiclink)` (`service_enfant.dart:109-114`) **dans `appairer`, avant de rendre la main à l'écran** (`:72-73`).
7. **Persistance locale** : jeton d'appareil par profil dans le coffre (`eleve_connexion_page.dart:132-135`, clé `jeton_appareil_<profilId>`, `stockage_securise.dart:60-70`), puis profil `{id, prenom, identifiantImmuable: ''}` dans Drift (`eleve_connexion_page.dart:136-141`, `profils_locaux.dart:77-89`).
8. **Code personnel** : moment `creationCode` (`:143-149`) : PIN 4 chiffres saisi deux fois (`:179-198`), scellé `sel:sha256(sel|code)` (`code_local.dart:35-38`, `:58-59`) et rangé dans le coffre (`:202-204`), puis moment `saisieCodePersonnel` (`:206-210`).

Résultat de chaque côté :
- Élève : session Supabase élève ouverte, jeton d'appareil + empreinte de PIN locales, profil local.
- Tuteur : **rien**. L'écran continue d'afficher QR et code jusqu'à l'expiration locale. La liste des appareils ne se met à jour que si le tuteur revient sur `/tuteur/foyer` (le provider est relu à la reconstruction, `service_appairage.dart:299-302`).

### 1.3 Appareil partagé : reconnexion, choix de profil, PIN

1. `/connexion/eleve` lit les profils Drift (`eleve_connexion_page.dart:99-113`). Base vide ou illisible -> saisie du code ; sinon « Qui es-tu ? » (`:339-375`) : tuiles prénom + initiales (pas d'avatar, `cleAvatar` jamais rempli au moment de l'appairage, `:136-140`).
2. Choix d'un profil (`:162-177`) : pas d'empreinte de PIN -> création ; sinon saisie.
3. Vérification **locale** du PIN (`:214-228`, `code_local.dart:41-52`, comparaison à durée constante). Aucun plafond de tentatives (`pin_pad.dart:50-65`).
4. PIN correct -> jeton lu (`:230`) -> `ouvrirSession(jeton)` -> Edge `session-enfant` branche `device_token` -> RPC `profil_du_jeton_appareil` (`0004:794-818`, refuse si révoqué ou inconnu, met à jour `last_used_at`) -> lien magique -> `verifyOTP` (`service_enfant.dart:83-89`).
5. Session élève active -> le routeur quitte `/connexion` vers `/eleve` (`redirection.dart:81-86`). Aucun accès au compte tuteur : la session est celle du profil élève, rôle `student` injecté par le hook (`0038:88-97`).

Point structurant : **tant qu'une session élève est ouverte, `/connexion/eleve` est inatteignable** (`redirection.dart:81-86`). Changer de profil sur une tablette partagée exige « Se déconnecter » dans `/compte` (`compte_page.dart:103-109`), puis de repasser par la feuille « réservée aux tuteurs » (`fr.i18n.json` `connexion.feuilleAppareil.pourQui`). La session Supabase persiste au redémarrage de l'app (comportement par défaut de `supabase_flutter`, aucun `signOut` automatique dans `lib`, seul appel `service_auth.dart:67`) : le PIN ne protège que le changement de profil après déconnexion.

### 1.4 Retrait (révocation)

- UI : « Retirer » par appareil actif (`appareils_page.dart:206-211`) -> `revoquer(id)` puis `invalidate(appareilsDuFoyerProvider)` (`:83-86`).
- Serveur `revoquer_appareil` (`0004:731-769`) : rôle `guardian` ou `admin` (`:738-740`), appareil du foyer de l'appelant (`:742-755`), `revoked_at = now(), token_hash = null` (`:757-759`), journal `appareil_revoque` (`:763-764`). Le tuteur d'un autre foyer est refusé (scénario `scenarios_etape3.sql:494-509`).
- Effet réel : l'appareil ne peut plus **rouvrir** une session par son jeton. **Une session déjà ouverte reste valide** jusqu'à sa déconnexion : ni `revoquer_appareil` ni le hook JWT (`0038:50-98`) ne touchent aux sessions/refresh tokens. Côté appareil, le jeton local n'est jamais effacé (`oublierAppareil` jamais appelé hors `_dev/playground/faux.dart:675`).

### 1.5 Garanties serveur : matrice

| Garantie | Où | Statut de preuve |
|---|---|---|
| Durée de validité bornée, configurable | `0004:116-119`, `:628-629` ; contrôle `:677-679` | code + scénario S8b (`scenarios_etape3.sql:439-457`), non rejoué CI |
| Usage unique / anti-rejeu | `for update` `:666-669`, `consumed_at` `:674-676`, `:709-711` | code + S8a (`:425-437`), non rejoué CI |
| Code non stocké en clair | `:631-637` ; vue sans empreinte `:298-316` | code + I4 (`:375-382`) et vue (`:515-525`) |
| Un seul code vivant par élève | `:617-621` | code, pas de scénario dédié |
| Lien au foyer | création seulement `:597-606` ; la consommation ne connaît pas le foyer de l'appareil | code |
| Plafond d'appareils | création `:608-615`, consommation `:684-692`, triggers `0001:791-813`, `0004:78-106` | S7a/S7b (`:384-419`) |
| Révocation efface le jeton | `:757-759` | scénario (`:475-492`) |
| Révocation ferme la session ouverte | **absent** | - |
| Limitation de débit | **absent**, assumé `session-enfant/index.ts:16-20` ; table `rate_limits` existe (`0001:342-346`) mais non utilisée ici | - |
| Annulation d'un code par le tuteur | **absent** (seul moyen : en demander un autre, qui reste valide) | - |
| Appareil déjà lié à un autre foyer | **non contrôlé** : unicité `(profile_id, device_fingerprint)` seulement (`0004:59-63`) | - |
| Une seule séance à la fois (texte UI) | clé `max_concurrent_sessions_per_profile` semée (`0001:966`), **lue nulle part dans `supabase/`** | non garanti par une règle explicite |

### 1.6 Le sens actuel est-il sûr ?

Oui dans ses bornes : l'émetteur est authentifié et lié au foyer, le secret vit 10 minutes, sert une fois, et un nouveau code périme l'ancien. Le récepteur est anonyme par construction. Risques résiduels à documenter, sans les « corriger » par animation : photo/lecture par un tiers pendant la fenêtre (le code donne une session élève à qui le saisit), pas de limitation de débit, pas d'annulation explicite, pas de confirmation côté tuteur. **Recommandation : conserver le sens** (le tuteur montre, l'appareil élève scanne ou saisit), libellé « Sur l'appareil de l'élève » (aujourd'hui « Sur l'appareil de l'enfant », `fr.i18n.json:212`).

Conséquence de routage : **le scanner vit sur l'appareil élève non connecté**, donc sous le sous-arbre public `/connexion/eleve/...`. Une route `/appareils/scanner` ou `/appareil/pin` à la racine serait renvoyée vers `/connexion` pour un appareil déconnecté (`redirection.dart:47-49`) et vers `/tuteur` pour un tuteur (`:114-115`).

---

## 2. Ce que le code fait vs ce que les commentaires ou docs prétendent

| Affirmation | Source | Réalité dans le code |
|---|---|---|
| « Le message reste court et ne dit jamais pourquoi une valeur est invalide » | `_shared/clients.ts:26-28` | `session-enfant` renvoie `error.message` de la RPC : `code inconnu`, `code deja utilise`, `code expire`, `plafond d'appareils atteint` (`index.ts:53-55`, `0004:671-691`). |
| La branche `error` de la réponse est traitée | `service_enfant.dart:96-99` | Sur 403/400, `functions.invoke` lève `FunctionsHttpException` avant (`functions_client.dart:255-270`) : branche morte pour les refus. |
| « Le tuteur a révoqué cet appareil : le profil ... disparaît dès qu'on l'apprend » | `eleve_connexion_page.dart:232-233` | Ne se produit que si le jeton local est **absent** (`:230-231`). Une révocation serveur laisse le jeton local ; l'échec d'`ouvrirSession` pose `_message` (`:253-256`) que le pavé n'affiche pas (`:377-392`). Le profil n'est jamais oublié. |
| « Sur un appareil déjà appairé, l'écran de code ne réapparaît jamais » | `eleve_connexion_page.dart:45-47` | Vrai, et c'est un défaut : impossible d'ajouter un deuxième élève sur la tablette partagée depuis l'UI. |
| « C'est ce qui fait que ELV-01 ne redemande jamais de code » | `profils_locaux.dart:39-40` | Seulement si l'écriture Drift a abouti ; elle peut être perdue par la course du point 3.1. |
| « Les profils du foyer que l'appareil de l'enfant met en cache local » | commentaire de vue `0004:907-909` | L'appareil élève ne lit jamais `profils_du_foyer_v` ; le cache ne reçoit que le prénom rendu par l'Edge. |
| Coffre « du système » | `stockage_securise.dart:18-20` | Vrai sur Android/iOS ; sur le web, `flutter_secure_storage` repose sur le stockage du navigateur (à confirmer sur la version 11) : pas un coffre système. Effacer les données du site crée une nouvelle empreinte et donc un nouvel appareil compté dans le plafond. |
| « Deux appareils au maximum par enfant, un seul en cours à la fois » | `fr.i18n.json:209`, `appareils_page.dart:58-60` | Le « 2 » est une constante client (`service_appairage.dart:189`) ; le second membre n'a pas de règle serveur lue (voir 1.5). |
| « Il reste valable dix minutes » | `fr.i18n.json:148` | Durée réelle = `pairing_code_ttl_minutes`, modifiable par l'admin. |
| Test « le code personnel ne quitte jamais l'appareil » | `test/appairage/code_local_test.dart:67-139` | Contrôle **lexical ligne par ligne** : une ligne contenant `.rpc(`, `functions.invoke`, `.from(`, `.insert(`, `.update(`, `.uploadBinary(` ne doit pas contenir `CodeLocal`, `empreintePin`, `enregistrerEmpreintePin`, `onCodeComplet` ; les services ne déclarent pas `String pin`/`codePersonnel` ; le coffre reçoit une empreinte. Il ne suit pas les flux (variable renommée, appel sur plusieurs lignes comme `service_enfant.dart:63-70`, `.upsert(`, realtime, Sentry). Il couvre tout `lib/` récursivement, donc un futur écran scanner y sera soumis. Il reste une barrière utile, pas une preuve de non-transmission. |

---

## 3. Défauts constatés (priorisés)

### 3.1 Bloquants pour le parcours

1. **Course session / PIN après appairage** (probable, à prouver par test widget avec `SourceSession` simulée). `appairer` ouvre la session avant le retour (`service_enfant.dart:72-73`). L'événement `onAuthStateChange` (`source_session.dart:38-40`) fait passer la porte à `actif` (compte enfant hérité actif, `0004:856`, `:878-888`) ; le routeur, qui écoute `sessionProvider` (`app_router.dart:82-84`), renvoie de `/connexion/eleve` vers `/eleve` (`redirection.dart:81-86`). Selon la latence, la page est détruite avant l'écriture Drift (`eleve_connexion_page.dart:141`, `ref.read` après démontage lève) et avant la création du PIN (`:143-149`). Correctif frontend possible sans backend : séparer « consommer le code » et « ouvrir la session » (l'Edge rend `token_hash`, on peut n'appeler `verifyOTP` qu'après jeton + profil + PIN), ou porter l'opération dans un contrôleur hors widget.
2. **Deuxième élève impossible sur un appareil partagé** : aucune action « Ajouter un profil » ni « J'ai un nouveau code » sur `_choixProfil` (`:339-375`).
3. **Appareil révoqué ou jeton refusé : silence**. `_message` jamais rendu dans `_pave` ; `_enCours` non plus (pas d'indicateur pendant `ouvrirSession`, `:247-261`).
4. **Émetteur aveugle** : pas de confirmation, pas de détection du remplacement du code (un second écran tuteur, un rafraîchissement web, un retour arrière créent un nouveau code et périment le précédent, `0004:617-621`, alors que le premier écran l'affiche encore comme valide).
5. **Aucun scanner** alors que l'écran émetteur montre un QR : le QR est aujourd'hui décoratif.

### 3.2 Importants

6. Erreurs de consommation indifférenciées (« Ce code ne marche pas », `fr.i18n.json:313`) ; `codeExpire` (`:314`) n'est jamais affiché pour un code expiré, seulement pour un jeton refusé.
7. Retrait sans confirmation, sans attente, sans retour d'erreur (`appareils_page.dart:83-86`, `:151`, `:206-211`) ; libellé sans avertir qu'une session ouverte continue.
8. Régénération après expiration : si elle échoue (ex. plafond atteint entre temps), l'erreur est masquée car la branche `expire` passe avant `_erreur` (`appairage_page.dart:122-149`).
9. QR illisible probable en thème sombre : paire `surfaceCanvas` sombre = modules `#F5F2FA` sur fond `#111014` (`app_palette.dart:120-123`), soit un QR inversé que beaucoup de lecteurs ne décodent pas. Marge de silence ~1 module (padding par défaut de `QrImageView`, 10 px sur 224 px) au lieu des 4 recommandés, compensée en clair seulement parce que le fond de page est identique.
10. Taille fixe 224 px (`:175`), non adaptative.
11. `Semantics(liveRegion: true)` sur un texte qui change chaque seconde (`:114-121`) : annonce vocale continue.
12. Pas de gestion du cycle de vie (reprise d'arrière-plan : aucune revérification), pas d'état réseau propre à l'écran (seul `OfflineBanner` de `PageShell`, `page_shell.dart:119`), compte à rebours sur l'horloge locale (dérive possible).
13. PIN oublié : aucune récupération. Re-appairer réinitialiserait le PIN (upsert même ligne `0004:703-706`, puis `creationCode`), mais l'entrée « code » est inaccessible (point 2).
14. Plafond et durée codés en dur (`service_appairage.dart:189`, `fr.i18n.json:148`, `:150`, `:209`, `:211`) ; le tuteur ne peut pas lire `app_config` (`0001:969-970`).
15. Appareil partagé non représentable : `mes_appareils_v` rend une ligne par couple (profil, empreinte) sans exposer l'empreinte (`0014:848-866`) : impossible de regrouper « iPhone de Mariam, disponible pour Salam, Mariam, Fatimah » (capture historique `mobile/Foyer Member.png`). `label` est exposé mais non lu (`service_appairage.dart:47-62`) et aucune RPC ne permet de l'écrire.

### 3.3 Mineurs

16. Plateforme affichée brute (« android », `appareils_page.dart:193`) ; date formatée à la main (`:218-220`).
17. `_plateforme()` rend `windows` pour macOS et Linux (`eleve_connexion_page.dart:440-451`), la base n'accepte que 4 valeurs (`0001:130`).
18. Le filtre de saisie accepte `I` et `O`, absents de l'alphabet (`:319` vs `0004:587`).
19. `creerCode` remplace une date illisible par `DateTime.now()` (`service_appairage.dart:228-230`) : affiche « expiré » immédiatement (prudent, mais date inventée).
20. Vocabulaire « enfant » partout (`t.enfant.*`, `appareils.codeTitre`) alors que le mandat parle de profil élève (proches adultes possibles).

---

## 4. Écran émetteur : états actuels vs mandat §7

| État mandat | Aujourd'hui | Fichier:ligne | Réalisable en frontend sur contrat existant ? |
|---|---|---|---|
| Préparation | texte « Chargement » centré | `appairage_page.dart:150-151` | oui (squelette, pas de faux QR) |
| Actif | QR + code + compte à rebours | `:109-121` | oui (taille adaptative, paire dédiée clair-sur-sombre fixe, marge 4 modules, halo hors modules, mouvement réduit) |
| Validation en cours | absent | - | **non détectable** : le serveur ne signale pas « un appareil est en train de consommer ». Ne pas simuler. |
| Association confirmée | absent | - | **oui, sous réserve** : `mes_codes_appairage_v` expose `consumed_at` et `expires_at` pour les codes du foyer (`0004:298-312`). Faute d'id rendu par la RPC, on peut identifier le code par `(student_profile_id, expires_at)`. Scrutation courte et bornée (pas de realtime sur une vue). Droit `select` du rôle `authenticated` sur la vue **non accordé explicitement dans les migrations** (repose sur les privilèges par défaut Supabase) : à vérifier avant de brancher. Alternative : diff de `mes_appareils_v`. Dès `consumed_at` non nul : retirer QR ET code de l'arbre et de l'état, afficher « Appareil connecté », invalider `appareilsDuFoyerProvider`, destination = élève concerné. |
| Expiré | message + « Générer un nouveau code » | `:122-135` | oui ; retirer aussi le code de l'état (aujourd'hui `_code` reste en mémoire). |
| Révoqué / remplacé | absent | - | oui par la même vue : la ligne disparaît (`deleted_at`) quand un autre code est demandé (`0004:617-621`, filtre `:309`). |
| Erreur | message générique + réessayer | `:136-149`, `:70-73` | oui ; distinguer plafond / élève hors foyer / compte non valide exige de lire le message SQL (fragile, pas de code d'erreur stable : dépendance backend B6). |
| Réseau interrompu | seulement `OfflineBanner` global | `page_shell.dart:119` | oui : masquer le QR tant que le statut n'est pas revérifié. |
| Reprise app | aucune | - | oui : `WidgetsBindingObserver`, cacher puis revérifier avant réaffichage ; ne jamais restaurer depuis un cache (aujourd'hui rien n'est restauré, correct). |
| Sortie de l'écran | le code reste valide jusqu'à expiration | - | **non** : aucune RPC d'annulation (B1). Dire honnêtement « Ce code restera valable jusqu'à HH:MM » ou ne rien promettre. |

---

## 5. Scanner, dépendances, permissions

| Élément | Constat |
|---|---|
| Dépendance de scan | **aucune** : `pubspec.yaml:10-66` ; `pubspec.lock` ne contient ni scanner, ni zxing, ni mlkit, ni camera (seul `string_scanner`, sans rapport). Aucune branche locale n'en déclare (parcours de tous les `pubspec.yaml`). |
| Génération QR | `qr_flutter: ^4.1.0` (`pubspec.yaml:52`) |
| Android | `android/app/src/main/AndroidManifest.xml:1-45` : **aucune** `uses-permission` (ni CAMERA, ni RECORD_AUDIO, ni INTERNET) ; INTERNET seulement en `debug` (`src/debug/AndroidManifest.xml:6`). Le manifeste de `flutter_webrtc-1.6.0` n'en déclare aucune. Le manifeste fusionné n'a pas pu être vérifié (pas de `build/`). `minSdk`/`compileSdk` = valeurs Flutter (`android/app/build.gradle.kts:9`, `:22-23`) soit 24 / 36 pour Flutter 3.47.2 (`FlutterExtension.kt`). |
| iOS | `ios/Runner/Info.plist:1-70` : **pas de `NSCameraUsageDescription`** (ni micro). Cible 15.0 (`project.pbxproj:363`, `:490`, `:542`). |
| Web | `web/index.html` sans politique ; `vercel.json` et `web/vercel.json` sans `Permissions-Policy` ni CSP : la caméra est permise par défaut en contexte sécurisé (HTTPS Vercel, localhost en dev). |
| Windows | `windows/runner/runner.exe.manifest` présent ; aucun scanner Windows possible avec `mobile_scanner`. |
| Chaînes existantes | `eleveConnexion.scanner` « Scanner le carré » (`fr.i18n.json:311`) inutilisée. |

Remarque hors domaine mais bloquante pour la recette : l'absence d'INTERNET et de CAMERA/RECORD_AUDIO dans le manifeste principal pourrait aussi toucher LiveKit et le réseau en build release Android. À vérifier sur le manifeste fusionné par le coordinateur (seul propriétaire des configurations plateforme).

---

## 6. Recommandation de dépendance (non installée)

**`mobile_scanner` ^7.4.2** (pub.dev, consulté le 24/09/2026) :
- Version 7.4.2 publiée il y a 9 jours ; « Min Dart SDK 3.7 » ; « Requires Flutter 3.29.0 or higher » (changelog 7.0.0) ; Android minSdk 23 (7.1.3), compileSdk 34, Java 17 ; iOS 12 ; macOS 10.15 ; licence BSD-3-Clause.
- Plateformes : Android, iOS, macOS, Web ; **pas Windows, pas Linux**.
- Web : API native `BarcodeDetector` si disponible, sinon `zxing-wasm` (~2 Mo) **chargé depuis jsDelivr au premier usage** ; URL surchargeable par `MobileScannerPlatform.instance.setBarcodeLibraryScriptUrl(...)`, lecteur choisi par `setWebBarcodeReader(...)`. Donc : réseau requis au premier scan, script tiers, à auto-héberger dans `web/` comme `sqlite3.wasm` si l'on veut éviter le CDN (décision coordinateur).
- Android : ML Kit groupé (+3 à 10 Mo) par défaut, ou non groupé (~600 Ko, via Google Play Services, absent des appareils sans GMS) par `dev.steenbakker.mobile_scanner.useUnbundled=true`.
- Cycle de vie documenté : `MobileScannerController(autoStart: false)`, `WidgetsBindingObserver`, `start()` à `resumed`, `stop()` à `inactive` ; codes d'erreur `permissionDenied`, `unsupported`, `genericError`, `controllerAlreadyInitialized`, `controllerUninitialized`, `controllerInitializing`, `controllerNotAttached`, `controllerDisposed` ; option `invertImage`.
- Compatibilité dépôt : Flutter 3.47.2 / Dart 3.13.2 (`C:\flutter\bin\cache\flutter.version.json`), minSdk 24, iOS 15.0 : **compatible sur le papier**, à confirmer par `flutter pub get` et un build par plateforme (coordinateur).

Configuration à la charge du coordinateur : `NSCameraUsageDescription` (texte : scanner le code affiché par le tuteur, distinct de la caméra en cours), `uses-permission android.permission.CAMERA` + `uses-feature android.hardware.camera android:required="false"`, décision CDN/auto-hébergement web.

Non retenu sans demande : `permission_handler` (seul intérêt : distinguer le refus durable et ouvrir les réglages). Sans lui, un refus affiche l'explication, la marche à suivre dans les réglages et la saisie manuelle.

Règles d'implémentation (agent D) :
- Port `LecteurQr` injectable (tests sans caméra, fixtures dans `test/`).
- Plateforme Windows/Linux, ou `unsupported` : pas de bouton scanner, saisie seule (un bouton qui ne peut aboutir n'est pas rendu, `lib/CLAUDE.md`).
- Validation stricte du contenu : `^[2-9A-HJ-NP-Z]{6}$` après `trim().toUpperCase()` ; tout autre contenu (URL comprise) est refusé sans être ouvert.
- Première lecture valide : `stop()` immédiat, une seule requête en vol, garde de génération contre les réponses tardives après navigation, libération à `dispose` et à l'arrière-plan.
- Aucun code dans les journaux, l'URL, Sentry ou les captures de recette.
- Correspondance des refus serveur (`FunctionsHttpException.details['error']`) : inconnu / expiré / déjà utilisé / plafond / appareil non décrit -> messages simples avec reprise ; jamais le texte brut.

---

## 7. Mapping des routes du mandat

| Mandat | Existant | Constat / proposition (le routeur appartient au coordinateur) |
|---|---|---|
| `/tuteur/foyer/appareils` | `/tuteur/foyer` = `AppareilsPage` (`app_router.dart:278-281`), hors barre | à scinder avec le Foyer (agent B, voir C04) |
| `/tuteur/foyer/:eleveId/appareils` | absent | filtre par élève de la même source `mes_appareils_v` |
| `/appareils/connexion` (émetteur) | `/tuteur/foyer/appairer/:eleveId` (`routes.dart:77-80`) | conserver l'identifiant ; un alias sous `/tuteur/...` seulement (préfixe de rôle, `redirection.dart:114-115`) |
| `/appareils/scanner` | absent | **doit être public** : `/connexion/eleve/scanner` |
| `/appareils/code` | `/connexion/eleve` moment `saisieCode` | `/connexion/eleve/code` ou conserver |
| `/appareil/profils` | `/connexion/eleve` moment `choixProfil` | idem, public |
| `/appareil/pin` | `/connexion/eleve` moments `creationCode` / `saisieCodePersonnel` | idem ; le PIN n'est jamais dans l'URL |

Entrées existantes vers les appareils côté tuteur : Accueil « Appareils du foyer » (`accueil_famille_page.dart:445-450`), Compte « Foyer » (`compte_page.dart:74-82`, `:340-348`). Côté élève : `/connexion` -> feuille tuteur -> `/connexion/eleve` (`connexion_page.dart:165-170`). **Aucune entrée « Choisir mon profil » directe** pour un appareil déjà appairé : `/connexion` ne consulte pas les profils locaux.

---

## 8. Dépendances backend (hors périmètre, à documenter, ne rien simuler)

| # | Service attendu | Entrée / sortie | Impact si absent |
|---|---|---|---|
| B1 | Annuler un code vivant | `annuler_code_appairage(p_student_profile_id)` -> void | Le code reste valable jusqu'à 10 min après la sortie de l'écran. |
| B2 | Statut de code fiable | `creer_code_appairage` rendant aussi `id` ; ou flux de consommation | Contournable par `(student_profile_id, expires_at)` sur `mes_codes_appairage_v` si le `select` est accordé (à vérifier). |
| B3 | Révocation qui ferme les sessions ouvertes | lier session et appareil, révoquer les refresh tokens à `revoquer_appareil` | « Retirer » n'éjecte pas un appareil connecté ; l'UI doit le dire. |
| B4 | Politique effective lisible par le tuteur | `max_devices_per_student`, `pairing_code_ttl_minutes` | Chiffres en dur à retirer des libellés. |
| B5 | Appareil physique partagé et nom | clé pseudonyme par foyer dans `mes_appareils_v` + RPC `nommer_appareil` | « Appareil familial, disponible pour ... » irréalisable. |
| B6 | Codes d'erreur stables | `errcode` ou `code` machine dans la réponse `session-enfant` et des RPC | Correspondance par texte libre, fragile. |
| B7 | Limitation de débit sur `session-enfant` | seau `rate_limits` existant | Risque accepté par commentaire, à réévaluer si TTL allongé. |
| B8 | Appareil lié à un seul foyer (décision produit) | contrôle à la consommation | Prénoms de deux foyers possibles sur une même tablette. |
| B9 | Profil élève du parent | `creer_code_appairage` exige `role = 'student'` (`0004:602`) | Pas d'appairage pour « mon profil élève » tant que ce modèle n'existe pas (voir C04). |
| B10 | « Une seule séance à la fois » | lecture de `max_concurrent_sessions_per_profile` | Phrase `appareils.regle` non garantie. |

---

## 9. Tests existants et recette

Existants (non exécutés dans cette phase) :
- `test/features/appareils_test.dart:64-210` : plafond (bouton remplacé par message), appareil révoqué hors plafond, règle affichée, foyer vide, révocation par le service, code affiché avec délai, expiration, refus serveur -> erreur + réessayer.
- `test/features/eleve_connexion_test.dart:51-77` : base locale indisponible -> saisie ; profil connu -> choix.
- `test/appairage/code_local_test.dart` : scellement, comparaison, forme, contrôle lexical réseau (voir §2).
- SQL `scenarios_etape3.sql:354-525` : S6, I4, S7a/b, S8a/b/c, révocation, foyer, vue. Rejeu CI bloqué.

Non couvert : succès d'appairage -> PIN -> session ; course de redirection ; jeton révoqué ; `FunctionsHttpException` ; deuxième profil sur appareil partagé ; cycle de vie ; thème sombre du QR ; scanner.

Recette proposée (simulation vs réel séparés) : scan valide, contenu invalide, URL dans le QR, double lecture, code expiré, déjà utilisé, remplacé, plafond, permission refusée, caméra absente, Windows, web sans `BarcodeDetector`, arrière-plan pendant le scan et pendant l'affichage, retrait avec confirmation, disparition du QR et du code de l'arbre sémantique après confirmation (`find.bySemanticsLabel`), deuxième élève sur la même tablette, PIN oublié. Association réelle : uniquement sur staging, jamais prouvée par un test widget.

---

## 10. Propriété de fichiers proposée

| Fichier | Propriétaire |
|---|---|
| `lib/features/appareils/appairage_page.dart`, nouveau `.../scanner_*`, `lib/features/eleve_connexion/*`, `lib/core/appairage/service_enfant.dart`, `code_local.dart`, `profils_locaux.dart`, `test/appairage/*`, `test/features/eleve_connexion_test.dart` | D - Appareils |
| `lib/features/appareils/appareils_page.dart` (liste + retrait) | D, en coordination avec B qui refait le Foyer (C04) : isoler un widget « appareils d'un élève » réutilisable |
| `lib/features/appareils/ajouter_enfant_page.dart` | B - Foyer (domaine d'ajout de profil, malgré son dossier) |
| `lib/core/appairage/service_appairage.dart` | partagé (élèves, réglages, appareils) : coordinateur, ou scission `service_appareils` / `service_foyer` avant la phase parallèle |
| `lib/core/widgets/pin_pad.dart`, `stockage_securise.dart`, `app_palette.dart` (paire QR), `pubspec.yaml`, manifestes, `Info.plist`, `web/`, routeur | coordinateur |

Branches : `integration/core24-classes-v2` modifie `service_appairage.dart` (Interface guidée, RPC nouvelles) : branche CORE24 non conforme, **ne pas intégrer**. `v0/verite-produit` ne change que des chemins de commentaires sur `pin_pad.dart`, `appareils_page.dart`, `eleve_connexion_page.dart`.

---

## 11. Questions ouvertes pour le directeur

1. Confirmer le sens : le tuteur montre, l'appareil élève scanne (recommandé, conforme au code).
2. Accepter d'afficher honnêtement que « Retirer » n'éjecte pas une session ouverte tant que B3 n'existe pas ?
3. Web : autoriser le chargement de `zxing-wasm` depuis jsDelivr, ou exiger l'auto-hébergement ?
4. Faut-il interdire qu'un même appareil porte des profils de deux foyers (B8) ?

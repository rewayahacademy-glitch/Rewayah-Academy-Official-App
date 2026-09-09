# Audit 360, Architecture optimisée et Roadmap full-stack
## Rewayah Academy - Application MVP

Version 1.0 - Rapport d'architecte. Aucune ligne de code avant validation.

---

## Verdict global en 60 secondes

Le cahier des charges est ambitieux et bien structuré sur le plan métier. Il contient cependant **4 contradictions bloquantes** qui invalident des pans entiers de l'architecture si on code en l'état, et **1 angle mort majeur** qui n'est pas technique mais existentiel pour le produit.

| # | Blocage | Impact si non traité |
| :-- | :--- | :--- |
| **B1** | Aucune politique de protection de l'enfance (adulte seul en visio 1-to-1 avec un enfant de 6 ans, plus tchat privé et vocaux) | Risque existentiel. Un seul incident ferme la société. Prioritaire sur tout le volet anti-pillage. |
| **B2** | Flutterwave ne documente **pas** le payout Mobile Money vers la **Guinée (GNF)** | Les professeurs guinéens ne peuvent pas être payés. Le Domaine 6 ne fonctionne pas. |
| **B3** | Google Meet est incompatible avec 4 exigences dures des specs simultanément | Watermark, heartbeat, infiltration incognito et split-screen sont irréalisables. |
| **B4** | Le Pre-Download Guard est contourné par l'architecture "exports natifs Dart" | Le séquestre protège le fichier alors que la donnée est déjà sortie. Sécurité théâtrale. |
| **B5** | Le PIN à 4 chiffres comme mécanisme d'authentification serveur | 10 000 combinaisons brute-forçables donnant accès à des données d'enfants. |

Le reste du document détaille ces points, corrige l'architecture, puis découpe l'exécution.

---

# ÉTAPE 1 - AUDIT CRITIQUE ET CORRECTIONS D'ARCHITECTURE (360°)

## 1.1. Erreurs et omissions structurantes

### B1. Protection de l'enfance : l'angle mort du cahier des charges

Les specs consacrent une architecture entière au risque de **pillage commercial** (watermark, séquestre, NDA, siloing) et **zéro ligne** au risque numéro un d'une plateforme qui met un adulte seul, en visio privée et en tchat privé, avec un enfant de 6 ans, trois fois par semaine, sans témoin.

Ce que les specs demandent aujourd'hui et qui aggrave ce risque :
- Visio 1-to-1 sans enregistrement ni témoin.
- Tchat confiné 1-to-1 post-match avec vocaux Opus (`init_prompt.txt`, Domaine 1 des médias).
- Anonymisation de l'évaluateur.
- Contrôleur qui passe en "infiltration inopinée", donc une couverture statistique faible et aléatoire.

Corrections à intégrer avant tout code :
1. **Enregistrement systématique** des sessions (ou au minimum enregistrement audio), conservation courte (30 à 90 jours), accès restreint et journalisé, information explicite des deux parties. C'est aussi votre meilleure preuve anti-litige, bien supérieure au heartbeat.
2. **Suppression du canal privé prof-élève.** Le tchat doit être **prof - tuteur**. Tout message adressé à l'élève doit être visible du tuteur et conservé.
3. **Accès parent au direct.** Le tuteur doit pouvoir rejoindre la session de son enfant en observateur à tout moment. C'est une fonctionnalité de confiance ET la meilleure défense.
4. **Vérification d'antécédents** des enseignants au-delà de la CNI (l'équivalent local du DBS britannique, ou à défaut attestations et références vérifiées, documentées dans le dossier KYC).
5. **Bouton de signalement** accessible au tuteur, distinct du "signaler l'absence", avec escalade admin immédiate.
6. **DPIA** (analyse d'impact) obligatoire. Voir 1.3.

Sans ce socle, le reste est secondaire.

### B2. Flutterwave ne couvre pas la Guinée

La documentation officielle des payouts Mobile Money de Flutterwave (API v4) fournit des exemples pour GHS, KES, TZS, XAF (Cameroun), XOF (Côte d'Ivoire et Sénégal), RWF, MWK, ETB, UGX et ZMW. **Le GNF n'apparaît pas.** Côté collecte, le support marchand officiel liste le Nigeria, le Ghana, le Kenya, l'Afrique du Sud, l'Ouganda, la Tanzanie, le Royaume-Uni, les États-Unis et l'Europe.

Conséquences directes :
- Une UK Ltd peut collecter et détenir un solde. Le problème est la **jambe sortante vers la Guinée**.
- Les specs citent l'endpoint **Bulk Transfer v3 et le header `verif-hash`**. C'est l'API legacy. La v4 utilise `POST /direct-transfers` avec `action: instant | deferred | scheduled`, un header **`X-Idempotency-Key` natif** et des webhooks de forme `{webhook_id, timestamp, type, data}`. Coder sur la v3 en 2026 est une dette immédiate.

Corrections :
1. Créer une abstraction **`PayoutProvider`** exactement comme `VideoSessionProvider`. Aucun code métier ne doit connaître Flutterwave.
2. Router par pays et devise : Flutterwave pour XOF (CI, SN), un agrégateur local pour GNF (**CinetPay**, que vous avez déjà exploré et qui couvre la Guinée via MTN Mobile Money), virement bancaire en filet de sécurité.
3. **Action préalable au dev** : demander par écrit au support Flutterwave la confirmation GNF sur votre compte marchand UK. La réponse conditionne l'architecture du Domaine 6.
4. Utiliser l'idempotence native v4 plutôt que de la réimplémenter.

### B3. Google Meet ne peut pas tenir le cahier des charges

Votre question dans `init_prompt.txt` était la bonne. La réponse est non, et pas seulement pour une question de licences.

Sur la délégation domain-wide : chaque utilisateur impersonné doit exister et être licencié dans le domaine Workspace. Créer 20 événements Calendar avec `conferenceData` depuis un compte unique est techniquement possible, mais en l'absence de l'hôte dans la salle vous héritez des salles d'attente, du "knocking", d'aucun contrôle d'hôte et de rapports de présence différés et non exploitables en temps réel.

Le vrai problème est ailleurs. Meet rend **quatre exigences dures impossibles** :

| Exigence spec | Avec Google Meet |
| :--- | :--- |
| `WatermarkedView` sur le flux | Impossible. Le flux est hors de votre application. |
| Heartbeat, seconde exacte de déconnexion | Impossible côté client. `url_launcher` met Flutter en arrière-plan, iOS et Android tuent le socket. |
| Infiltration incognito du Contrôleur | Impossible. Meet affiche toujours les participants. |
| Split-screen Coran pendant le cours | Impossible. Deux applications distinctes. |

**Recommandation : LiveKit** (Cloud pour démarrer, self-host possible ensuite), SDK Flutter officiel. Ce qui débloque, point par point :
- `hidden: true` dans le token d'accès : le Contrôleur est réellement invisible des autres participants. C'est nativement votre besoin d'infiltration.
- **Webhooks serveur** `participant_joined` / `participant_left` avec horodatage serveur : votre preuve anti-litige devient **non falsifiable**, contrairement à un heartbeat client qu'un professeur peut spoofer.
- Rendu des tracks dans un widget Flutter : le watermark et le split-screen redeviennent possibles.
- Egress pour l'enregistrement safeguarding (B1).
- Simulcast et adaptation de débit natifs pour le fallback réseau.

Gardez l'abstraction `VideoSessionProvider`, mais avec LiveKit par défaut, Jitsi self-host en repli souverain et Meet comme mode dégradé de secours uniquement.

### B4. Le Pre-Download Guard protège le mauvais objet

Les specs imposent des exports "100% natifs Dart, package `pdf` et package `excel`". Si le fichier est généré dans Flutter, alors **les lignes de données sont déjà sur le poste du comptable** avant que le pop-up de séquestre n'atteigne l'admin. Il suffit d'ouvrir les outils de développement, de lire la réponse réseau, ou de patcher le binaire. Le guard bloque un fichier, pas une fuite.

Correction : inverser la responsabilité.
1. Toute génération d'export multi-lignes passe par une **Edge Function serveur**. Le client envoie une demande, pas une requête de données.
2. La demande crée une ligne `export_requests` en statut `pending`. L'admin approuve. Alors seulement la fonction lit les données, produit le fichier, le dépose dans un bucket privé et renvoie une **URL signée de 60 secondes**, à usage unique et journalisée.
3. Le package `pdf` natif Dart reste légitime pour un seul cas : le **reçu individuel du tuteur**, portant sur ses propres données, donc sans intérêt d'exfiltration.
4. La vraie menace résiduelle est le **scraping écran par écran**. Elle se traite par la pagination serveur, le rate limiting en lecture, le masquage par défaut des colonnes sensibles (les numéros Mobile Money ne s'affichent qu'au moment du payout, tronqués) et la détection d'anomalie de volume lu par heure.

### B5. Le PIN à 4 chiffres n'est pas un mécanisme d'authentification

Le piège classique serait de créer un compte Supabase `email/password` où le mot de passe est le PIN. Cela donne 10 000 combinaisons pour accéder aux données d'un enfant, et cela expose l'ensemble des politiques RLS.

Architecture correcte, en trois couches :
1. **Appairage** : le tuteur génère un code à 6 caractères ou un QR contenant un jeton à usage unique, TTL 15 minutes, lié à son `household_id`. Le scan appelle une Edge Function qui échange le jeton contre une session Supabase de longue durée, **liée à l'appareil** (`device_id` plus secret stocké en `flutter_secure_storage`, Keychain sur iOS et Keystore sur Android).
2. **Déverrouillage local** : le PIN 4 chiffres ne sert **qu'à choisir un profil enfant sur un appareil déjà appairé**, exactement comme un code Face ID. Il ne voyage jamais vers le serveur. Il est vérifié localement contre un hash (Argon2id) en secure storage.
3. **Défense** : 5 tentatives puis verrouillage progressif, notification push au tuteur, révocation d'appareil à distance depuis `[TUT-02]`.

### Autres omissions fonctionnelles

| Réf | Manque | Correction |
| :-- | :--- | :--- |
| O1 | Aucune **machine à états de session** | `scheduled → preflight → live → completed / no_show_teacher / no_show_student / tech_failure / cancelled_late`. Chaque état porte une règle de crédit et une règle de paie. Sans cela, "signaler l'absence" n'a aucune conséquence exploitable. |
| O2 | Aucune **notification push** | Tout le produit repose sur "cours dans 5 minutes". Il faut FCM et APNs dès l'étape 3, plus un canal WhatsApp Business API (templates pré-approuvés et opt-in, ce n'est pas un simple lien) pour les relances comptables. |
| O3 | **Récurrence et DST** | Stocker en UTC absolu casse les cours récurrents au changement d'heure. Il faut `local_time` + `timezone` IANA + `RRULE`, puis matérialiser les occurrences en UTC via un job. L'alerte DST à 30 jours devient un simple dérivé. |
| O4 | **Crédits mal définis** | 50 dollars valent combien d'heures ? Quel taux ? Le portefeuille est en dollars, les payouts en GBP puis XOF ou GNF. Il faut une devise de référence unique et une table de taux historisés. |
| O5 | **Expiration à 60 jours** | Une clause d'expiration de crédits prépayés est attaquable au titre du UK Consumer Rights Act 2015. À faire valider, ou à transformer en "suspension" réversible plutôt qu'en perte sèche. |
| O6 | **Blocage brutal au 1er du mois** | Un enfant perd son cours sans préavis. Prévoir relances J-7, J-3, J-1, puis 3 jours de grâce, puis suspension. |
| O7 | **Paie conditionnée au cahier de transmission** | Un rapport en retard doit mettre la paie **en attente**, jamais l'annuler. Sinon vous fabriquez du contentieux. Vérifier aussi le statut des enseignants (prestataires indépendants) pour éviter une requalification. |
| O8 | **Rien sur l'exploitation** | Pas d'environnements dev/staging/prod, pas de migrations SQL versionnées, pas de PITR, pas de monitoring d'erreurs, pas de CI/CD, pas de feature flags, pas de stratégie de tests. Pour un opérateur solo, c'est ce qui fait la différence entre une app maintenable et une app qui meurt au premier incident. |
| O9 | **i18n absente** | Français, poular et arabe RTL dans une application LTR. À décider maintenant, car cela structure tout le layout. |
| O10 | **Riwaya du Coran non spécifiée** | Le public ouest-africain lit majoritairement en **Warsh 'an Nafi'**, pas en Hafs. Livrer un mushaf Hafs à des élèves guinéens et peuls serait une erreur produit de premier ordre. À trancher, avec vérification de la licence du mushaf retenu. |

### Réalisme de périmètre

Huit domaines fonctionnels, six rôles, WebRTC, paiements transfrontaliers, KYC et moteur de formulaires dynamiques : c'est un périmètre d'équipe sur 12 à 18 mois. Vous opérez en solo avec assistance IA, et l'académie tourne déjà avec 6 professeurs de Coran et 9 enseignants au total.

Proposition : découper en **MVP-0** puis **V1**.

- **MVP-0** (ce qui est strictement nécessaire pour donner un cours payé et traçable) : Auth et rôles, appairage enfant, planning et matching, visio avec preuve serveur, cahier de transmission, portefeuille de crédits en lecture, dashboards Élève et Enseignant.
- **V1** : Contrôleur et audit, Pre-Download Guard, exports, payouts automatisés, moteur de formulaires dynamiques, bibliothèque coranique complète.

En MVP-0, les payouts se font manuellement. Vous avez 9 enseignants, pas 900. Automatiser un virement pour 9 personnes avant d'avoir 100 élèves est une inversion de priorité.

---

### Questions d'arbitrage - section 1.1

1. **Safeguarding** : acceptez-vous l'enregistrement systématique des sessions, ou préférez-vous un enregistrement déclenché sur incident uniquement ? Cette réponse change le coût d'infrastructure et le fournisseur visio.
2. **Payouts Guinée** : voulez-vous que je conçoive le `PayoutProvider` multi-fournisseurs dès le départ, ou attend-on la réponse écrite de Flutterwave sur le GNF avant de trancher ?
3. **Périmètre** : validez-vous le découpage MVP-0 puis V1, ou tenez-vous au périmètre complet en un seul lot ?

---

## 1.2. Accessibilité et UX "Child-First" (élèves de 6 ans)

### Le problème fondamental des maquettes actuelles

Les écrans `[ELV-01]` à `[ELV-05]` sont conçus pour un lecteur. "REJOINDRE MON COURS", "Mes Évaluations", "Saisir mon Code PIN", "Signaler l'absence du prof" : **un enfant de 6 ans ne lit pas ces phrases.** L'ergonomie annoncée est "zéro-lecture", mais l'interface décrite est textuelle.

Corrections, alignées sur les Apple HIG et sur ce que l'on sait des interfaces enfants :

**Cibles tactiles.** Les 44x44pt des HIG sont un **minimum adulte**. Pour un enfant de 5 à 7 ans, la motricité fine n'est pas établie : viser **72pt minimum** pour toute action primaire, avec **16pt d'espacement** entre deux cibles pour absorber les erreurs de visée. Le bloc "Rejoindre" doit occuper au moins un tiers de la hauteur d'écran.

**Un seul geste : le tap.** Pas de swipe, pas d'appui long, pas de double tap, pas de pincement. Le glisser-déposer est hors de portée fiable à cet âge.

**Zéro-lecture réel.** Chaque bloc porte un pictogramme dominant, une couleur constante et un **libellé audio** joué au tap et rejouable via une icône haut-parleur. Le français et le poular sont tous deux nécessaires ici, puisqu'une partie du public ne lit ni l'un ni l'autre. Le texte devient un support secondaire pour l'adulte présent.

**Feedback immédiat, façon Apple.** Sur chaque appui : réduction d'échelle à 0.96 en 120 ms courbe `easeOutCubic`, retour haptique `mediumImpact`, son court et non stressant. Sur succès : animation d'encouragement de 800 ms maximum. Jamais de spinner nu de plus d'une seconde sans animation de contexte.

**Rien d'anxiogène.** Le bouton rouge `#FF385C` "Signaler l'absence du prof" est à la fois incompréhensible et culpabilisant pour un enfant de 6 ans. **Supprimez-le côté élève.** L'absence du professeur doit être détectée **côté serveur** (aucun `participant_joined` du professeur à T+5) et notifiée automatiquement au tuteur et à l'admin. Zéro charge cognitive sur l'enfant.

**Pas de piège temporel.** Aucun écran ne se ferme tout seul, aucun compte à rebours stressant. Le "minuteur animé brandé" doit être une progression joyeuse, pas une pression.

**Support système.** Respect de Dynamic Type jusqu'à 200% sans casse de layout, de Reduce Motion (les animations d'encouragement deviennent des fondus), et labels VoiceOver corrects même si l'enfant ne l'utilise pas, car les tuteurs peuvent en avoir besoin.

### Audit de contraste de la palette (WCAG 2.2)

J'ai calculé les ratios réels de votre charte. Trois combinaisons échouent.

| Combinaison | Ratio | Verdict |
| :--- | :--- | :--- |
| `#1C1D21` sur `#F1E3E4` | **13.6:1** | Excellent |
| `#1C1D21` sur `#70EE9C` | **11.6:1** | Excellent |
| `#1C1D21` sur `#FFB703` | **9.7:1** | Excellent |
| Blanc sur `#8652E6` | **4.78:1** | Passe AA texte normal, juste |
| `#1C1D21` sur `#FF385C` | **4.83:1** | Passe AA |
| `#8652E6` (texte) sur `#F1E3E4` | **3.83:1** | **Échec AA** en texte courant. Réservé au texte large 18pt+ gras. |
| Blanc sur `#FF385C` | **3.51:1** | **Échec AA.** Assombrir le rouge pour tout texte blanc. |
| Blanc sur `#FFB703` | **1.75:1** | **Échec grave.** Jamais de blanc sur l'ambre. |
| Blanc sur `#70EE9C` | **1.46:1** | **Échec grave.** Jamais de blanc sur le vert. |
| `#CCBCBC` (bordure) sur `#F1E3E4` | **1.47:1** | **Échec du 3:1** exigé pour les composants d'interface. Vos bordures sont quasi invisibles. |

Corrections proposées :
- `#70EE9C` et `#FFB703` deviennent des fonds **exclusivement** associés au texte charbon. Règle à encoder dans `app_theme.dart` via des paires `(background, onBackground)` typées, pour rendre l'erreur impossible.
- Ajouter un `#8652E6` assombri (variante `onSurface`) pour tout texte violet sur fond clair.
- Ajouter un `#FF385C` assombri pour le texte blanc sur rouge.
- Remonter `BorderNeutral` d'environ deux crans de luminance, ou porter les bordures à 2px avec une teinte plus soutenue.

### Cohérence de marque

La palette violet et rose de cette application ne correspond ni à l'identité de Rewayah Academy (vert islamique profond `#1B6B5A`, or `#C9A84C`, beige `#F7F5F1`) ni à celle de PISI (fluor `#C8FF00` et crème). Vous allez avoir trois identités visuelles pour une seule marque, vues par les mêmes familles. C'est une décision à prendre consciemment, pas par défaut.

---

### Questions d'arbitrage - section 1.2

1. **Identité visuelle** : on garde le violet `#8652E6` propre à l'app, ou on réaligne sur le vert et or de Rewayah Academy ?
2. **Audio** : je prévois des libellés audio en français **et** en poular pour l'espace élève, ou français seulement en MVP-0 ?
3. **Signalement d'absence côté élève** : je le supprime au profit d'une détection serveur automatique, ou vous le voulez conservé ?

---

## 1.3. Sécurité Zero-Trust et anti-fuite

### RLS Supabase : les trois pièges qui vous attendent

**Piège 1 - la récursion sur `profiles`.** Une policy qui fait `SELECT role FROM profiles WHERE id = auth.uid()` pour protéger `profiles` provoque une récursion infinie, et sur les autres tables elle exécute une sous-requête **par ligne**. Correction : placer le rôle et le `household_id` dans le **JWT** via un Auth Hook (custom access token), puis lire `auth.jwt() -> 'app_metadata' ->> 'role'`. Coût nul, pas de récursion.

**Piège 2 - `SECURITY DEFINER` sans `search_path`.** Toute fonction `SECURITY DEFINER` sans `SET search_path = ''` et sans schéma explicite sur chaque objet est un vecteur d'élévation de privilèges. Règle absolue sur toutes les fonctions du projet.

**Piège 3 - la `service_role` key.** Elle contourne intégralement la RLS. Elle ne doit exister que dans les Edge Functions, jamais dans le client Flutter, jamais dans une variable d'environnement compilée. Toute Edge Function qui l'utilise doit re-vérifier l'autorisation métier explicitement.

### KYC, niqab et filtrage par genre

Le principe (dossiers féminins réservés au staff féminin) est réalisable via une policy sur `storage.objects`. Deux pièges :

1. **Les URLs signées survivent à la RLS.** Une fois générée, l'URL est valable jusqu'à expiration, quel que soit le rôle du porteur. Donc : TTL de 60 secondes maximum, génération **interdite côté client**, uniquement via une Edge Function qui journalise chaque accès dans `audit_logs` avec l'identité du consultant.
2. **Le genre est une donnée sensible.** Le stocker pour piloter un contrôle d'accès demande une base légale documentée. Ce n'est pas bloquant, cela demande d'être écrit dans le registre des traitements.

Le chiffrement AES-256 annoncé : préciser où sont les clés. Un chiffrement applicatif avec la clé dans la même base n'apporte rien face au risque principal, qui est l'accès abusif d'un compte légitime. Le vrai contrôle ici, c'est la RLS plus la journalisation plus la durée de rétention (purger les pièces d'identité après validation, ne conserver que la preuve de vérification).

### `WatermarkedView` : dissuasion, pas protection

Il faut nommer les choses. Un overlay Flutter :
- ne bloque **ni** la capture d'écran, **ni** l'enregistrement d'écran, **ni** une caméra pointée sur l'écran ;
- est **trivialement supprimable** sur Flutter Web via les outils de développement.

Ce qu'il apporte réellement : la **traçabilité forensique**. Une capture qui fuite désigne son auteur. Pour que cela fonctionne :
- Contenu : identifiant immuable + `session_id` + horodatage à la minute.
- Position **variable** (déplacement lent), opacité 6 à 10%, rotation légère, pour survivre au recadrage.
- Renforts natifs : `FLAG_SECURE` sur Android, détection de capture d'écran sur iOS avec journalisation dans `audit_logs`.
- **Corollaire fort** : puisque rien de tout cela n'existe sur le Web, restreindre la cible Web aux rôles back-office (Admin, Comptable, Contrôleur) et imposer l'application native aux Élèves, Enseignants et Tuteurs. Cela réduit d'un coup la surface d'attaque, le coût de développement et le poids du bundle.

### Webhooks financiers

L'API v4 fournit `X-Idempotency-Key`. Côté réception, il faut malgré tout : une table `webhook_events` avec contrainte d'unicité sur l'identifiant d'événement, un rejet des horodatages hors fenêtre pour bloquer le rejeu, une vérification de signature, et **aucune mutation de solde hors transaction**. Le contournement du verrou 48h que vous redoutiez se traite en base : la date de dernière modification du RIB est une colonne, et la fonction de payout la lit dans la même transaction que le débit. Pas de vérification côté client.

### Conformité, à traiter avant le lancement et non après

Vous êtes une UK Ltd, vous traitez des données d'enfants, des pièces d'identité et des flux transfrontaliers. Les éléments manquants :
- **DPIA** obligatoire (traitement à grande échelle de données de mineurs).
- **UK Children's Code de l'ICO** : paramètres par défaut au niveau de protection maximal, minimisation, pas de nudge. C'est contraignant et applicable à un service destiné aux enfants.
- **Consentement parental** explicite et traçable, distinct des CGU.
- **DPA** signés avec Supabase, le fournisseur visio et le prestataire de paiement.
- **Conflit droit à l'effacement contre `audit_logs` immuable.** À résoudre par la **pseudonymisation** : les logs référencent un `subject_id` qui peut être dissocié de l'identité réelle, préservant l'intégrité de la chaîne tout en honorant une demande d'effacement.
- **Rétention** documentée pour chaque catégorie : enregistrements, pièces KYC, logs, messages.

---

### Questions d'arbitrage - section 1.3

1. **Cible Web** : je restreins le Web au back-office et j'impose le natif aux élèves, professeurs et tuteurs ? Cela simplifie beaucoup et améliore la sécurité, mais exclut la famille qui n'a qu'un PC partagé.
2. **Pièces d'identité** : purge après validation avec conservation de la seule preuve de vérification, ou conservation intégrale pendant toute la durée du contrat ?
3. **Conformité** : voulez-vous que je produise le squelette de la DPIA et le registre des traitements en parallèle du développement, ou est-ce traité en dehors de ce chantier ?

---

## 1.4. Performance, visioconférence et temps réel

### Le heartbeat à 10 secondes est à supprimer

Deux raisons, dont la seconde est celle que vous aviez pressentie.

**Il est falsifiable.** Un client peut envoyer des pings depuis un appareil où personne n'assiste au cours. Comme ce heartbeat conditionne la paie, il devient une cible d'attaque.

**Il ne survit pas au multitâche mobile.** iOS suspend l'exécution en arrière-plan en quelques dizaines de secondes, Android Doze coupe les sockets. Vous génériez donc des **faux positifs de déconnexion** massifs, à chaque fois qu'un élève regarde une notification.

Remplacement : les **webhooks serveur du SFU**. LiveKit émet `participant_joined`, `participant_left` et l'état des tracks avec un horodatage **serveur**. C'est plus précis, non falsifiable, gratuit en bande passante côté client, et insensible à l'arrière-plan. Le client ne fait plus que de l'affichage.

Budget Realtime évité au passage : 200 sessions simultanées à 6 messages par minute et par participant, ce sont 2400 messages par minute que vous n'envoyez plus dans Supabase Realtime, lequel n'est pas dimensionné pour de la télémétrie haute fréquence.

### Qualité média : l'audio prime sur la vidéo

Point souvent manqué et central ici. L'enseignement des **Makharij** est un exercice **phonétique**. En cas de dégradation réseau, la logique par défaut de WebRTC (protéger la vidéo) est contraire à votre besoin.

Politique à imposer :
- Opus mono, 32 à 48 kbps, **FEC activé**, priorité absolue.
- Vidéo en simulcast avec profil bas par défaut côté élève (360p), 480p côté professeur (l'élève doit voir la bouche du professeur).
- Sous un seuil de bitrate, **couper la vidéo avant de toucher à l'audio**, avec bascule automatique en audio seul et bannière explicite.
- Ne jamais activer un DTX agressif : il tronque les fins de mots, ce qui est exactement ce que le professeur doit entendre.

### Split-screen Coran

Sur un téléphone de 6 pouces, un split-screen visio plus mushaf est inutilisable, a fortiori pour un enfant de 6 ans. Le PiP WebRTC sur iOS demande par ailleurs des entitlements spécifiques et ne fonctionne pas depuis une WebView.

Proposition : trois modes selon la taille d'écran.
- **Téléphone** : le Coran s'ouvre en feuille modale plein écran, la visio bascule en vignette flottante audio prioritaire.
- **Tablette et desktop** : vrai split 50/50.
- **Idéal pédagogique** : c'est le **professeur** qui pousse la page courante à l'élève ("suivre le professeur"), synchronisée via Realtime. Un enfant de 6 ans ne cherche pas une page dans 604 pages.

Rendu du mushaf : ne pas composer le texte arabe à la volée. Pré-rendre les pages en WebP ou SVG, les servir depuis un CDN, les mettre en cache disque, et virtualiser la liste. Le texte à la volée avec une police de qualité (Warsh ou Hafs) coûte trop cher en rendu Flutter et donne des résultats typographiques instables.

---

### Questions d'arbitrage - section 1.4

1. **Fournisseur visio** : je pars sur LiveKit Cloud (rapide, coût variable) ou LiveKit self-host (coût fixe faible, exploitation à votre charge) ?
2. **Coran** : quelle riwaya, Warsh ou Hafs, et acceptez-vous le mode "suivre le professeur" en remplacement de la navigation libre pour les jeunes élèves ?
3. **Preuve de présence** : validez-vous le remplacement du heartbeat client par les webhooks serveur du SFU comme source de vérité unique pour la paie ?

---

# ÉTAPE 2 - SPÉCIFICATIONS TECHNIQUES OPTIMISÉES

## 2.1. Caching et mode hors ligne (objectif : ouverture en moins d'une seconde)

**Choix du moteur local.** Isar connaît des incertitudes de maintenance. Recommandation :
- **Drift** (SQLite) pour toutes les données structurées et interrogeables : profils, sessions, planning, historique pédagogique. Requêtes réactives, migrations propres, robuste.
- **`flutter_cache_manager`** plus stockage disque pour les médias : pages du mushaf, avatars, audios.
- **`flutter_secure_storage`** pour les secrets : tokens, hash du PIN, `device_id`.

**Stratégie par type de donnée.**

| Donnée | Politique | TTL |
| :--- | :--- | :--- |
| Pages du mushaf | Cache-first permanent, préchargement du juz' courant | Illimité, invalidé par version |
| Profil et rôle | Cache-first, revalidation au démarrage | 24 h |
| Planning des 7 jours | Stale-while-revalidate, poussé par Realtime | 15 min |
| Solde du portefeuille | **Toujours réseau**, jamais de valeur monétaire en cache affichée comme vraie | 0 |
| Cahier de transmission en brouillon | **Écriture locale d'abord**, file de synchronisation | Jusqu'à synchronisation |

**Le point critique du hors ligne** : un professeur en Guinée finit un cours et perd le réseau. Le cahier de transmission doit être **écrit localement puis rejoué**, avec une clé d'idempotence, sinon il perd sa paie sur une coupure. C'est le seul vrai besoin offline en écriture du produit, et il est non négociable.

Premier écran affiché : **squelette depuis le cache** immédiatement, jamais un spinner plein écran.

## 2.2. Robustesse réseau et rate limiting

| Surface | Limite | Mécanisme |
| :--- | :--- | :--- |
| Tentative d'appairage (code 6 caractères) | 5 par heure et par IP, 10 par tuteur et par jour | Token bucket Postgres |
| Vérification du PIN | 5 tentatives, verrouillage progressif | Local plus journalisation serveur |
| Demande d'export | 3 par 10 minutes, puis blocage et alerte | Table `rate_limits` |
| Webhook payout | Idempotence stricte, fenêtre d'horodatage | `webhook_events` |
| Lecture de données sensibles | Plafond de lignes par heure et par rôle | Compteur plus alerte |
| Edge Functions | Plafond global par utilisateur | Middleware commun |

Implémentation : un token bucket en PostgreSQL suffit au volume du MVP et évite une dépendance. Vous utilisez déjà **Upstash Redis** sur PISI : c'est le chemin de migration naturel si le volume grimpe.

**Dégradation réseau.** Politique en trois paliers : nominal (vidéo plus audio), dégradé (vidéo coupée, audio Opus seul, bannière explicite), rupture (fin de session automatique côté serveur avec statut `tech_failure`, aucune imputation de faute à l'une ou l'autre partie). Retry client en backoff exponentiel avec jitter, et jamais de retry sur une opération financière sans clé d'idempotence.

## 2.3. Optimisation PostgreSQL

Index et contraintes essentiels :

```sql
-- Identifiants immuables
CREATE UNIQUE INDEX idx_profiles_immutable_id ON profiles (immutable_id);

-- Planning : index partiel sur ce qui est réellement interrogé
CREATE INDEX idx_sessions_teacher_upcoming ON sessions (teacher_id, starts_at_utc)
  WHERE status IN ('scheduled','preflight','live') AND deleted_at IS NULL;
CREATE INDEX idx_sessions_student_upcoming ON sessions (student_id, starts_at_utc)
  WHERE status IN ('scheduled','preflight','live') AND deleted_at IS NULL;

-- Anti double-réservation au niveau base, pas au niveau applicatif
CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE sessions ADD CONSTRAINT no_teacher_overlap
  EXCLUDE USING gist (
    teacher_id WITH =,
    tstzrange(starts_at_utc, ends_at_utc) WITH &&
  ) WHERE (status <> 'cancelled' AND deleted_at IS NULL);

-- audit_logs : partitionnement mensuel + BRIN sur le temps + GIN sur le payload
CREATE INDEX idx_audit_created_brin ON audit_logs USING brin (created_at);
CREATE INDEX idx_audit_payload_gin ON audit_logs USING gin (payload jsonb_path_ops);
CREATE INDEX idx_audit_actor ON audit_logs (actor_id, created_at DESC);
```

La contrainte `EXCLUDE` règle la race condition du matching inversé **en base**. Deux professeurs qui cliquent au même instant : l'un passe, l'autre reçoit une erreur propre. Aucun verrou applicatif à écrire.

**Identifiants immuables thread-safe** : jamais `MAX(seq)+1`. Une table `id_sequences (role_code, year, seq)` avec un `INSERT ... ON CONFLICT DO UPDATE SET seq = id_sequences.seq + 1 RETURNING seq` est atomique par nature. Ajouter un trigger `BEFORE UPDATE` qui lève une exception si `immutable_id` change, sinon "immuable" n'est qu'un adjectif.

**`audit_logs` réellement append-only** : `REVOKE UPDATE, DELETE` sur la table pour tous les rôles applicatifs, plus des triggers `BEFORE UPDATE OR DELETE` qui lèvent une exception, plus un **chaînage de hash** (`hash_prev`) pour détecter a posteriori une altération faite avec la clé de service. Sans le chaînage, un administrateur de la base peut réécrire l'histoire.

**Ledger financier** : aucune colonne `balance` mutable. Un `wallet_entries` en écritures signées, montants en **entiers** (unités mineures), devise explicite par ligne, solde calculé ou matérialisé par trigger. Jamais de `float` sur de l'argent.

---

### Questions d'arbitrage - Étape 2

1. **Base locale** : je pars sur Drift, ou vous avez une préférence pour Hive CE ou ObjectBox ?
2. **Rate limiting** : Postgres seul en MVP, ou on branche Upstash Redis dès le départ pour mutualiser avec PISI ?
3. **Ledger** : devise de référence unique, GBP ou USD, pour toute la comptabilité interne ?

---

# ÉTAPE 3 - ROADMAP D'EXÉCUTION FULL-STACK

Structure de dépôt proposée : `supabase/` (migrations et fonctions), `lib/` en architecture par feature (`core/`, `features/<domaine>/{data,domain,presentation}`), `test/`.

---

## Étape 0 - Socle d'exploitation (nouvelle, 2 à 3 jours)

**Objectif** : ne pas construire sur du sable. Un opérateur solo sans environnements ni migrations versionnées perd plus de temps en incidents qu'il n'en gagne à sauter cette étape.

**Livrables** : projets Supabase staging et production, CLI Supabase et migrations versionnées dans Git, PITR activé, Sentry Flutter et Deno, GitHub Actions (analyse, tests, build), `flutter_flavors` pour dev, staging et prod, table `feature_flags`.

**Questions** :
1. Vous avez déjà un compte Sentry ou une préférence pour un autre outil de supervision ?
2. Deux projets Supabase (staging et prod) ou un seul en MVP pour limiter les coûts ?

---

## Étape 1 - Fondations DB, RLS, fonctions, triggers et audit

**Objectif** : le modèle de données et la sécurité. Tout le reste en dépend. **Valeur** : aucune fonctionnalité visible, mais chaque erreur ici coûte dix fois plus tard.

**Back-end**
- `001_extensions.sql` (`pgcrypto`, `btree_gist`, `pg_cron`)
- `002_enums.sql` (`user_role`, `account_status`, `session_status`, `payout_status`, `ledger_entry_type`)
- `003_core_tables.sql` (`households`, `profiles`, `devices`, `teacher_profiles`, `student_profiles`)
- `004_scheduling.sql` (`availability_slots`, `sessions` avec la contrainte `EXCLUDE`, `recurrence_rules`)
- `005_pedagogy.sql` (`lesson_reports`, `makharij_findings`, `evaluations`)
- `006_finance.sql` (`wallets`, `wallet_entries`, `payout_methods`, `payouts`, `webhook_events`, `fx_rates`)
- `007_audit.sql` (`audit_logs` partitionnée, chaînage de hash, `REVOKE`, triggers de refus)
- `008_id_sequences.sql` (fonction `next_immutable_id`, trigger d'immuabilité)
- `009_rls_policies.sql` (toutes les policies, lecture du rôle depuis le JWT)
- `010_auth_hook.sql` (custom access token avec `role` et `household_id`)
- `011_rate_limits.sql`
- Fonction `_shared/authz.ts` pour les Edge Functions

**Sécurité** : `SET search_path = ''` sur chaque fonction ; RLS activée sur **toutes** les tables sans exception, y compris celles jugées inoffensives ; policy `DENY` par défaut.

**Tests** : `pgTAP` avec un scénario par rôle vérifiant qu'un professeur ne peut lire aucune ligne d'un élève non attribué. C'est le test le plus important du projet.

**Questions**
1. Un élève peut-il avoir plusieurs professeurs (par matière), ou la relation est-elle strictement 1-1 ?
2. Un tuteur peut-il avoir des enfants rattachés à des foyers différents (familles recomposées, grand-parent payeur) ?
3. La rétention : je fixe la purge des pièces KYC à 30 jours après validation, ou vous avez une contrainte différente ?

---

## Étape 2 - Core Flutter, thème, cache local et routeur

**Objectif** : la coquille technique et le design system. **Valeur** : toutes les étapes suivantes deviennent de l'assemblage.

**Front-end**
- `lib/core/theme/app_theme.dart`, `app_colors.dart` (paires `(background, onBackground)` typées pour rendre les échecs de contraste impossibles), `app_typography.dart`, `app_spacing.dart`, `app_motion.dart`
- `lib/core/widgets/bento_grid.dart`, `bento_tile.dart` (variantes full, half, third, quarter)
- `lib/core/widgets/pressable.dart` (échelle 0.96, 120 ms, haptique, son)
- `lib/core/widgets/watermarked_view.dart` (position variable, `FLAG_SECURE`, détection de capture iOS)
- `lib/core/router/app_router.dart` (go_router, redirection par rôle et par `account_status`)
- `lib/core/db/` (Drift), `lib/core/network/` (client Supabase, retry, backoff)
- `lib/core/i18n/` (fr, poular, ar)

**UX** : `Pressable` centralise tout le retour tactile ; aucun widget de l'application n'a le droit de gérer un `onTap` nu. C'est ce qui garantit la cohérence "Apple-grade".

**Performance** : budget de démarrage à froid inférieur à 1,5 s ; `--split-debug-info` ; polices en sous-ensembles.

**Questions**
1. Web restreint au back-office (voir 1.3), ou Web complet pour tous les rôles ?
2. Poular en MVP-0, ou français seul avec les fichiers de traduction préparés ?
3. Mode sombre : je le construis dès maintenant, ou clair uniquement pour aller plus vite ?

---

## Étape 3 - Auth, KYC, appairage tuteur et portails d'attente

**Objectif** : faire entrer les utilisateurs, avec la bonne architecture d'authentification enfant. **Valeur** : premier parcours complet de bout en bout.

**Back-end**
- `functions/pair-device/` (échange du jeton QR contre une session liée à l'appareil)
- `functions/generate-pairing-code/` (6 caractères, TTL 15 min, à usage unique)
- `functions/revoke-device/`
- `functions/kyc-signed-url/` (TTL 60 s, journalisation, contrôle du genre)
- `012_kyc_storage_policies.sql`
- Notifications FCM et APNs (table `device_tokens`, fonction `send-push`)

**Front-end**
- `features/auth/` : `[ELV-01]` refondu (QR dominant, PIN en repli), `[ENS-01]`, `[TUT-01]` connexion Google
- `features/onboarding/` : portail d'attente, signature NDA, téléversement de pièce
- `features/household/` : `[TUT-02]`, génération de QR, gestion des appareils

**Sécurité** : le PIN ne quitte jamais l'appareil ; hash Argon2id en secure storage ; le portail d'attente est appliqué **côté serveur** par la RLS, pas seulement par une redirection du routeur.

**UX enfant** : `[ELV-01]` doit être scannable par un adulte et compréhensible sans lecture. Prévoir un mode "l'adulte scanne, l'enfant tape sur son avatar".

**Questions**
1. La signature électronique du NDA : signature manuscrite au doigt avec horodatage et empreinte du document, ou case à cocher plus preuve d'acceptation ?
2. Combien d'appareils simultanés autorisés par enfant ?
3. Les avatars enfants : photo (avec les implications de conservation d'image de mineur) ou illustrations à choisir dans une bibliothèque ? Je recommande fortement la seconde option.

---

## Étape 4 - Dashboards Bento Grid

**Objectif** : les 6 espaces. **Valeur** : le produit devient démontrable.

**Front-end** : `features/dashboard/student/` `[ELV-02]`, `teacher/` `[ENS-02]`, `tutor/` `[TUT-01]` avec `FamilyLiveMonitoringCard`, `accountant/` `[CPT-01]`, `controller/` `[CTR-01]`, `admin/` `[ADM-01]`.

**Back-end** : vues matérialisées pour les métriques admin (rafraîchies par `pg_cron`, jamais calculées à la volée), canaux Realtime par foyer pour le suivi famille.

**UX** : la grille Bento s'adapte par points de rupture (1 colonne sous 600 px, 2 jusqu'à 1024, 4 au-delà) ; sur l'espace élève, un seul bloc primaire dominant, les autres nettement secondaires.

**Performance** : `FamilyLiveMonitoringCard` s'abonne à **un** canal par foyer, pas un par enfant.

**Questions**
1. L'espace Contrôleur et l'espace Comptable en MVP-0, ou reportés en V1 comme je le recommande ?
2. Le bandeau d'annonces : rédigé par l'admin en texte libre, ou modèles pré-formatés ?
3. Sur `[ENS-02]`, les horaires de prière : calculés localement (méthode de calcul à choisir) ou saisis par l'enseignant ?

---

## Étape 5 - Visio, preuve de présence, split-screen Coran

**Objectif** : le cœur du produit. **Valeur** : le cours a lieu et il est prouvé.

**Back-end**
- `functions/create-room-token/` (rôles LiveKit, `hidden: true` pour le Contrôleur, TTL court)
- `functions/livekit-webhook/` (`participant_joined`, `participant_left`, écriture de la vérité de présence)
- `functions/session-state-machine/` (transitions, détection automatique du no-show à T+5)
- `013_session_events.sql`
- Egress d'enregistrement si l'option B1 est retenue

**Front-end**
- `features/session/` : `[ELV-03]`, `[ENS-03]`, `[CTR-02]`
- `preflight_check.dart` (micro, débit, TURN, batterie ; batterie indisponible sur Web)
- `features/quran/` : `[ELV-04]`, viewer paginé, cache disque, mode "suivre le professeur"

**Sécurité** : le token de salle est généré serveur après vérification que l'appelant est bien participant de **cette** session ; le mode caché du Contrôleur est journalisé dans `audit_logs` à chaque usage.

**Performance** : audio prioritaire, simulcast, bascule audio seul automatique (voir 1.4).

**Questions**
1. Enregistrement : audio seul (léger, peu coûteux, suffisant pour l'essentiel du safeguarding et des litiges pédagogiques) ou audio et vidéo ?
2. Le Contrôleur invisible : le professeur en est-il informé au moment de la signature du NDA ? Je recommande oui, pour des raisons juridiques et de confiance.
3. Le tuteur peut-il rejoindre la session en observateur, et le professeur le voit-il ?

---

## Étape 6 - Suivi pédagogique, cahier de transmission, Makharij

**Objectif** : la traçabilité pédagogique et le déclencheur de paie. **Valeur** : la qualité devient mesurable.

**Back-end** : `functions/submit-lesson-report/` (idempotente, rejouable hors ligne), `014_evaluation_grids.sql`, `015_attribution_algo.sql` (imputabilité présence contre méthode).

**Front-end** : `features/pedagogy/` `[ENS-04]` (matrice Makharij en puces géantes, 3 taps maximum), `[ELV-05]`, `[CTR-03]`.

**UX** : le cahier doit être remplissable en moins de 45 secondes sur un téléphone d'entrée de gamme, en une seule main, hors ligne. C'est la contrainte de conception dominante de cet écran.

**Métier** : rapport en retard implique paie **en attente**, pas paie perdue (voir O7).

**Questions**
1. La matrice Makharij se limite-t-elle aux 4 paires citées, ou faut-il un jeu extensible administrable ?
2. L'anonymat de l'évaluateur : levé pour l'admin, ou opaque pour tout le monde ?
3. Quel délai maximum après le cours pour déposer le rapport avant escalade ?

---

## Étape 7 - Finances, portefeuille, payouts et facturation

**Objectif** : encaisser et payer. **Valeur** : le modèle économique fonctionne.

**Back-end**
- `functions/topup-intent/` (collecte, redirection ou notification push selon l'opérateur, pas de "push USSD" garanti)
- `functions/payment-webhook/` (idempotence, signature, transaction unique)
- `functions/initiate-payout/` (abstraction `PayoutProvider`, routage par pays, contrôle du verrou 48 h dans la même transaction)
- `functions/generate-invoice/` (PDF **serveur**)
- `016_ledger_functions.sql`, `017_credit_expiry.sql` (`pg_cron`, relances J-7, J-3, J-1, grâce de 3 jours)

**Front-end** : `features/wallet/` `[TUT-03]`, `[ENS-05]`, `[CPT-02]`.

**Sécurité** : aucune écriture de solde hors fonction serveur ; le montant n'est jamais transmis par le client ; les identifiants Mobile Money sont masqués par défaut à l'affichage.

**Questions**
1. Confirmation nécessaire : quelle est la couverture réelle GNF sur votre compte Flutterwave ? Sans réponse, je conçois d'emblée le multi-fournisseurs avec CinetPay pour la Guinée.
2. Le pack unique à 50 dollars, ou plusieurs paliers ? Et combien d'heures pour 50 dollars ?
3. Les payouts en MVP-0 : manuels avec export de la liste à payer (recommandé pour 9 enseignants), ou automatisés dès le départ ?

---

## Étape 8 - Pre-Download Guard, exports serveur et tests de charge

**Objectif** : le contrôle anti-exfiltration, correctement placé. **Valeur** : la donnée devient défendable.

**Back-end** : `functions/request-export/`, `functions/approve-export/`, `functions/generate-export/` (XLSX et PDF côté **serveur**), `018_export_requests.sql`, `019_anomaly_detection.sql`.

**Front-end** : `features/exports/` avec sélecteur de colonnes, `[ADM-03]` panneau de séquestre temps réel, `[ADM-04]` journal d'audit en lecture seule.

**Tests de charge** : k6 sur les Edge Functions, montée à 200 sessions simultanées sur le SFU, vérification qu'aucune policy RLS ne dégrade en scan séquentiel sous volume.

**Questions**
1. Le séquestre s'applique-t-il aussi à l'admin lui-même, ou l'admin est-il exempté ? Un guard qu'un seul compte contourne ne protège que contre les autres.
2. Que se passe-t-il si aucun approbateur n'est en ligne : expiration silencieuse, ou file d'attente avec notification ?
3. Combien de temps conserve-t-on les fichiers exportés dans le bucket ?

---

# Questions sur la vision globale

Avant de générer la moindre ligne de code, cinq points que vous seul pouvez trancher.

1. **Périmètre.** Validez-vous le découpage MVP-0 puis V1 ? Vous avez 9 enseignants et une académie qui tourne déjà. Le MVP-0 tel que défini est atteignable ; le périmètre complet en un lot ne l'est pas dans un délai raisonnable en solo.

2. **Safeguarding.** C'est la décision la plus lourde du projet. Enregistrement systématique, enregistrement sur incident, ou aucun enregistrement avec un contrôle humain renforcé ? Tout le reste en découle : fournisseur visio, coût de stockage, conformité, rédaction du NDA et des CGU.

3. **Visio.** LiveKit, ou vous tenez à Google Meet en acceptant d'abandonner watermark, preuve de présence exacte, infiltration incognito et split-screen ?

4. **Guinée.** Les enseignants sont-ils tous en Guinée, ou répartis entre plusieurs pays ? La réponse détermine si le multi-fournisseurs de payout est indispensable dès le départ ou reportable.

5. **Marque.** Trois identités visuelles pour Rewayah (académie, PISI, cette application) : choix assumé ou dérive à corriger maintenant, tant que rien n'est codé ?

Dès réception de vos réponses, je génère l'Étape 0 puis l'Étape 1 (migrations SQL complètes, policies RLS, fonctions, triggers et tests pgTAP) fichier par fichier.

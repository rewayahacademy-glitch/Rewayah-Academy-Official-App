# REWAYAH ACADEMY - RECH-03
## SPÉCIFICATION CANONIQUE V3 - Recherche transversale, UX/UI, sécurité, performance et intégration Flutter + Supabase

**Version :** V3.0 - 8 octobre 2026  
**Statut :** SPÉCIFICATION CONSOLIDÉE PRÊTE POUR AUDIT R0 ET VALIDATION DES MAQUETTES. **NI CODE NI PERFORMANCE VALIDÉS.**  
**Autorité :** dernière décision explicite du Directeur du 8 octobre 2026 : **frontend ET backend dans la même verticale**, sans contournement de sécurité, sans modification PROD ni fusion `main` implicite.  
**Exécutant :** Claude Code, coordinateur/intégrateur unique avec agents spécialisés et ownership disjoint.  
**Périmètre :** Flutter Android, iOS, Web, tablette et bureau ; façade de recherche et moteurs métier PostgreSQL/Supabase compatibles avec l'existant.  
**Nature :** source de vérité de **la fonctionnalité Recherche**. Les contrats métier, l'autorisation et les décisions contemporaines continuent à primer sur toute hypothèse dans ce document.

> **Règle de livraison :** une recherche qui semble rapide mais donne accès à un champ interdit, ou une recherche sûre dont les résultats arrivent trop tard, **échoue**. Aucune activation utilisateur n'est approuvée par la rédaction de ce document. Le programme recherche peut être exécuté en parallèle des autres lots **uniquement avec séparation des fichiers, branches et migrations**.

## 0. Autorité, fusion et décisions de réconciliation

### 0.1 Les trois documents fusionnés

1. `REWAYAH_SPEC_RECHERCHE_TRANSVERSE_UX_SECURITE_PERFORMANCE_V1.md` (RECH-01, 08/10) : UX, matrice acteurs/corpus, états, **SEC-R01 à SEC-R22**, performances et recette.
2. `REWAYAH_RECH_02_HANDOFF_FRONT_BACK_INTEGRE_V2.md` (RECH-02, 08/10) : **sept maquettes**, écran → port → domaine, retour partiel, tâches d'intégration frontend/backend et gates.
3. `REWAYAH_COMPLEMENT_RECHERCHE_ET_PLAN_RESTANT_V0_1.md` (07/10) : recherche serveur par domaine, projections, rétention, **REC-01 à REC-14**, R0-R7 et points à prouver.

Autres sources **non remplacées** : BR0B V0.2, complément Immatriculation V0.1, Bible Frontend V2, contrats à jour FI/CPT, COM/Studio, TB/Bibliothèque, EN/EA, CT, AD/Direction et code effectif. Ce document est autonome pour le chantier Recherche, mais **ne remplace pas** ces politiques métiers et leur sécurité.

### 0.2 Résolution explicite des contradictions

| Sujet | Constat antérieur | Décision V3 faisant autorité |
|---|---|---|
| Périmètre technique | RECH-01 disait « FRONTEND ONLY » ; RECH-02 disait « frontend et backend intégrés ». | **Backend et frontend développés et recettés par domaine dans un même lot vertical.** Autorisation explicite avant toute mutation distante de PROD. |
| Source des maquettes | RECH-01 : maquettes à produire ; RECH-02 : sept PNG produits. | **Sept références visuelles disponibles mais non validées et non issues de Flutter**. Claude compare aux captures réelles et aux tokens gelés, puis soumet les différences. |
| Recherche des messages | Certaines fonctions COM ont des recherches spécialisées. | **Texte des messages uniquement dans Messagerie ou Studio** ; barre commune = fils et objets lisibles sans corps. |
| Indicateur « aucun résultat » | `items=[]` peut représenter une panne ou une liste vide selon mauvaise implémentation. | **Vide confirmé uniquement si état `ok` + `items=[]` pour le domaine consulté**. Erreur, refus, domaine absent et timeout sont distincts. |
| Réponses multi-domaines | Façade globale synchrone peut attendre le domaine le plus lent. | Retours **progressifs/partiels**, réponses indépendantes par domaine ou protocole adéquat ; un domaine en panne ne bloque pas les autres. |
| Immatriculation | Ancienne DB a `immutable_id` ; nouveau RA proposé. | UUID et ancien identifiant conservés jusqu'à migration additive validée ; RA exact **après R3**, jamais prérequis pour Classe/Supports. EV limité à son évaluation. |
| Observations du 07/10 | STAGING vide, 0039-0042 absents de Git inspecté, 0043 non appliquée PROD, permissions à durcir. | Photographie datée, **pas vérité garantie au 08/10**. Claude rafraîchit les SHA, versions, objets et contrôles **en R0 lecture seule**. |
| Publication | « Implémenter tout ensemble » pourrait être pris pour feu vert PROD. | **Aucun feu vert automatique** : staging synthétique, revue sécurité, benchmarks, snapshots, accord explicite du Directeur pour PROD et `main`. |

### 0.3 Hiérarchie et statut des exigences

Instruction récente et droits applicables → politique de sécurité/confidentialité → décisions métier actuelles et contrats serveur vérifiés → présent V3 pour le module Recherche → Bible Frontend V2/tokens et maquettes déjà validées → standards Flutter/Material 3/WCAG. Les maquettes RECH-02 sont des **candidates** et ne supplantent jamais une high-fi ou un token déjà approuvé.

Chaque exigence est : **SOURCE** (explicitement présente dans un des trois documents), **PROPOSITION V3** (choix de rédaction/architecture à vérifier) ou **PREUVE À FOURNIR** (code/mesure/test absent). Aucun rôle, champ ou droit nouveau n'est accordé par cette spec.

### 0.4 Limite d'intervention

**Autorisé dans le cadre de la commande de réalisation ultérieure :** inventaire, revue et développement coordonné de Flutter et des composants backend de la recherche **après étapes préalables et sur environnement de test isolé**. **Non autorisé sans instruction séparée :** écriture/migration PROD, activation sur utilisateurs réels, fusion `main`, déploiement production, modification de modules ou worktrees d'un autre agent, refonte auth/routeur/LiveKit/R2 ou création de second système financier/messagerie.

---

## 1. Promesse utilisateur et architecture d'information

La recherche répond à trois intentions **différentes**, non confondues :

| Intention | Exemple d'usage | Traitement |
|---|---|---|
| **Retrouver un objet** | « Ma classe », la fiche d'un élève autorisé, une facture accessible | Recherche commune contextualisée ou recherche métier ; résultat ouvrant la route canonique |
| **Chercher dans un contenu** | Passage coranique, titre/contenu d'un support autorisé, texte d'un message | Recherche spécialisée du lecteur, de la bibliothèque, de Messagerie ou du Studio ; respecter licence, règles de lecture et périmètre |
| **Trouver une fonction** | Recharger un solde, consulter des présences, ouvrir une rubrique | Raccourcis de navigation statiques, issus des **capacités réellement disponibles** ; aucune action métier exécutée par recherche |

Une même requête peut retourner des types différents, mais **les résultats sont groupés par domaine**, pas dans une liste géante de pertinence opaque. La recherche commune montre au plus quelques correspondances par domaine et propose « Voir tous les résultats » uniquement pour un domaine autorisé et opérationnel. Les résultats de chaque domaine ouvrent le **seul** écran propriétaire de l'objet.

**Espaces isolés :** Tuteur/Foyer, Élève standard, Élève en Interface guidée, Enseignant, Contrôle, Comptabilité, Administration/Direction, et espaces internes activés par des capacités effectives. Changer d'espace vide la requête et les résultats privés associés : aucune fusion automatique entre fonctions personnelles et professionnelles. Un adulte autonome peut conserver le rôle technique historique `guardian` : son périmètre dérive de ses capacités réelles, jamais de l'étiquette UI.

**Navigation :** conserver toutes les destinations existantes et `/bienvenue`, Connexion et les écrans métier inchangés. Le domaine Recherche est un *surface* transverse et non un second tableau de bord. Proposer un chemin canonique interne dans le routeur existant, par exemple `recherche` avec contexte d'espace et paramètres sans texte sensible dans l'URL ; **Claude vérifie d'abord les routes effectives et choisit une seule route réelle**. Un raccourci Ctrl/Cmd+K ouvre la même surface sur desktop lorsque le contexte l'autorise ; il n'invente pas une recherche supplémentaire.

---

## 2. Matrice complète des parcours par rôle / capacité

**Lecture impérative :** « cherchable » veut dire *si et seulement si le contrat serveur du domaine autorise déjà la lecture de cet objet ET des champs effectivement indexés/interrogés*. Toute catégorie non autorisée est **absente**, sans bandeau suggérant son existence.

| Rôle / espace | Entrée UX prioritaire | Domaines autorisés à proposer (sous droits courants) | Exclus / garde-fous | Destination canonique |
|---|---|---|---|---|
| **Élève, Interface guidée** | « Trouver un support » depuis Bibliothèque ou Classe, aide audio si prévue | Ses supports attribués, sourates/pages autorisées, ses classes/séances, annonces pour lui, sa progression lisible | Aucun annuaire, aucune finance, KYC, note privée d'un camarade ou recherche générale de personnes ; quelques résultats simples seulement | Bibliothèque, lecteur, espace Classe ou sa progression |
| **Élève adulte, interface standard** | Loupe dans la coquille élève | Ses classes, séances, supports, tâches, résultats propres, annonces et fils explicitement accessibles | Aucun autre élève ou foyer ; l'interface standard ne change pas les droits ; fonds et données privées selon capacités exactes | Fiche de Classe, travail, Coran, Messagerie, Finances personnelles si autorisées |
| **Tuteur titulaire** | Loupe dans Accueil/Foyer (même recherche canonique) | Profils enfants liés, classes des enfants, catalogue des classes réellement publié, planning, historique, supports, messages/fils autorisés, solde/mouvements du foyer selon droits | Pas d'autres familles, notes des camarades, fichiers identité hors parcours dédié, état d'un autre foyer | Foyer, Classe, historique, fiche solde, messagerie |
| **Second adulte du foyer** | Loupe de son espace familial | Objets du foyer **délégués** effectivement, paiements consultables si délégation FI, classes autorisées | Lecture financière ≠ recharge/gestion ; pas d'accès illimité à chaque enfant | Mêmes routes canoniques avec actions permises seulement |
| **Enseignant permanent** | Recherche dans Mes classes/Journée ou coquille | Ses classes et séances, élèves **projection pédagogique seulement**, travaux/cahiers autorisés, supports, annonces/fils, ses revenus autorisés | Pas d'identité/KYC des familles ni de leurs coordonnées privées, classe étrangère ou données comptables administratives | Liste de classes, fiche élève pédagogique, cahier, bibliothèque, revenu personnel |
| **Enseignant remplaçant** | Même point d'entrée enseignant | Classe et élèves de mission pendant la période et le périmètre de remplacement ; informations historiques seulement si contrat explicite | Retrait dès expiration/révocation ; ne pas perpétuer par cache ou ancien JWT | Fiches du remplacement autorisé |
| **Contrôleur** | Recherche contextualisée à ses missions | Missions confiées, séances associées, roster minimal, ses rapports, fil de mission | Pas KYC, foyer complet, coordonnées, autre mission ; ne pas recouper anonymat du rapport avec une vue élargie | Missions, observation, rapport, fil de mission |
| **Contrôleur invité à mission limitée** | Recherche au sein de la mission uniquement si son contrat l’autorise | Éléments expressément rattachés à sa mission et à sa fenêtre d’accès | Aucun accès à la recherche transverse de l’administration ni aux autres missions ; droits expirés refusés | Vue canonique de sa mission |
| **Comptable** | Champ de recherche en haut du bureau Comptabilité | Références/écritures/obligations, bénéficiaires dans la projection comptable, états de validation et documents financiers du périmètre | Pas pédagogie/KYC, détails bancaires complets hors capacité, recherche générale de profils par curiosité | Encaissement, rapprochement, versement, dossier financier autorisé |
| **Administration / Direction** | Recherche dans la coquille ou listes Personnes/Opérations | Personnes, classes, affectations, dossiers, finance, contrôles, supports et communications **par capacité granulaire** | Un badge « Admin » n'accorde pas tous les champs ; KYC uniquement dans viewer sécurisé ; séparation des tâches CPT ; pas de lecture automatique Direction si CPT-Q1 non résolu | Routes existantes de Personnes, Opérations, Pédagogie, Finances, Sécurité |
| **Studio interne** | Recherche au sein du Studio | Canaux, publications, messages et objets du Studio autorisés | N'inclut aucun canal non membre ; respect des restrictions et de la rétention | Canal/message du Studio |
| **Messagerie métier** | Recherche dans la Messagerie | Ses fils, messages lisibles et métadonnées autorisées | Ne pas indexer dans le moteur commun le texte des messages ; permissions de participation courantes | Fil unique métier concerné |
| **Agent observateur IA / invité borné** | Aucune recherche transverse par défaut | Uniquement les fonctions explicitement prévues par son contrat d'accès temporaire | Ne jamais hériter de la recherche du profil observé, ne pas élargir accès via token ou ancienne session | Destination bornée de sa mission |
| **Visiteur non connecté** | Aucun annuaire dans l'app ; recherche limitée aux modules publics déjà publiés, s'ils existent | Offres et contenus explicitement publics, résultats d'évaluation publiés avec code EV dans l'événement concerné | Jamais de profil RA, foyer, matricule permanent, dossier, notes privées, contenu non publié | Page publique autorisée ou résultat public de l'événement |

**Point frontière :** la recherche *pendant une séance live* s'ouvre comme panneau/bottom sheet selon format, sans couper audio/vidéo, remplacer arbitrairement le support dirigé, modifier le focus commun ou activer le microphone. L'élève n'obtient pas de commande professorale en ouvrant une ressource personnelle. Le contenu du cours conserve la priorité visuelle.

---

## 3. Inventaire des corpus et champs recherchables

Le backend doit distinguer pour chaque corpus **champs où une correspondance peut se produire**, **champs renvoyés**, **actions ouvrables** et **règles de conservation**. Un objet visible ne peut pas être trouvé à partir d'un champ invisible. Les combinaisons ci-dessous sont des **projections candidates**, à comparer aux contrats de domaine ; elles ne valent pas création de nouveaux droits.

| Corpus | Correspondances envisageables | Format du résultat | Interdictions / spécificité |
|---|---|---|---|
| Classes proposées | Nom public, programme, niveau affichable, langue, récurrence publiée, enseignant public | Nom, jours/heures locaux, statut/places si authentifiés | Pas d'offres DRAFT ni intent privé, pas de valeur simulée ; catalogue versus classes inscrites distincts |
| Classes inscrites et séances | Nom, date, enseignant public, matière | Prochaine séance ou séance passée, accès à la classe | Relation d'inscription/affectation actuelle ; fuseau IANA, DST exact |
| Personnes et foyer | Matricule RA exact, nom/prénom **si déjà autorisé dans l'espace**, badge métier séparé | Nom autorisé, matricule autorisé, sous-titre sans donnée sensible | Pas de date de naissance, email, téléphone, adresse par défaut ; homonymes non fusionnés |
| Élèves pour enseignant | Nom/prénom/RA permis par la projection de classe | Avatar public autorisé, élève, classe | Ne pas indexer motif de paiement, diagnostic médical, KYC, contact parental |
| Supports / Bibliothèque | Titre, auteur/source publié, type, langue, niveau, sourate/page, texte validé si permission de contenu | Couverture, titre, type, ressource/capacité hors ligne | Licence, version, visibilité, retraits ; viewer recontrôle droits |
| Coran | Sourate, numéro de verset/page/juz, texte de recherche canonique séparé | Localisation vérifiée et extrait permis | Ne jamais modifier le texte sacré ni générer une « page Mushaf fidèle » par simple retour à la ligne ; réutiliser l'index existant après audit |
| Progression et tâches | Titre d'objectif/devoir, date/cycle lisible, état autorisé | Objet propre à l'élève, action de consultation | Jamais de notes privées d'un camarade ; enfant voit son seul contenu |
| Présence, historique | Séance, date, statut lisible | Ligne historique autorisée | Ne pas inférer présence par recherche libre sur autre classe ; calendrier plutôt que scan |
| Annonces, communauté | Titre, corps **si publié pour l'audience**, catégorie | Titre + extrait court autorisé | Contenus retirés, modérés ou non destinés au compte exclus |
| Fils, recherche commune | Titre du fil, objet rattaché, participants d'affichage autorisés | Lien vers fil | **Jamais le corps des messages ni leur texte masqué** |
| Messages, Studio dédié | Corps textuel lisible dans canal/fil, métadonnées d'objet autorisées | Message lisible, date, contexte de fil | Permissions, archivage, rétention, suppression ; pas d'OCR ni transcription vocale déduite |
| Finance | Référence facture/opération, bénéficiaire autorisé, période, statut, catégorie | Référence, libellé, montant uniquement si capacité explicite | Aucune coordonnée de paiement brute, motif sensible ni montant caché trouvé indirectement |
| Contrôle | Numéro/mission, date, périmètre, état; rapports uniquement dans module autorisé | Mission ou rapport minimal | Anonymat, séparations rapport brut/synthèse/fil ; pas de recherche KYC |
| KYC / dossiers personnels | Référence technique autorisée et métadonnées de dossier dans file métier | File de revue de dossier, viewer sécurisé | **Pas d'index transversal des pièces, OCR ou contenu brut** ; revue via capacités Direction actuelles |
| Évaluations publiques | Code EV pour une évaluation précise et champs explicitement publiés | Code ou nom autorisé selon politique publication | Aucun RA, UUID, photo, lien foyer, nom caché ou correspondance EV inter-évaluations |
| Notifications et activités | Libellé/objet de notification consultable lorsque source réelle existe | Ouvre objet ou notification canonique | Ne pas créer un deuxième historique ; états lu/non lu selon source ; pas d'agrégat de contenu interdit |
| Préférences et actions | Libellés d'actions **réellement disponibles** pour l'espace courant | Navigation rapide vers écran canonique | Ne pas lancer directement « recharger », « approuver », « payer », « retirer » depuis un résultat |

**Filtre sécurisé de corpus :** domaines accessibles, types de résultats autorisés, période, classe, statut métier et langue uniquement si autorisés. **Les options et facettes elles-mêmes ne doivent pas trahir l'existence d'objets invisibles**. Compteur global exact optionnel et déconseillé en version initiale ; préférer « Voir davantage » et `has_more`.

---

## 4. Recherche : UX détaillée par support

### 4.1 Une seule surface canonique de recherche

**Point d'entrée commun :** icône Loupe avec libellé accessible « Rechercher dans [espace] » dans le header ou l'action de page prévue par la navigation existante. Ne pas remplacer une des 4 destinations tuteur ni gonfler le menu. Les modules avec recherche de contenu spécialisée conservent un champ **« Rechercher dans [module] »**, mais utilisent leurs propres capacités autorisées, non une copie locale d'un moteur universel.

**Avant saisie :** titre « Rechercher », contexte explicite (« Dans votre espace Tuteur » ou libellé effectif), champ vide, éventuelles destinations fréquentes **non personnalisées par des requêtes d'autrui**, liste minimale des catégories autorisées et disponibles. Pas d'historique personnel de requêtes sensibles persistant. Les suggestions de fonction sont fixes et soumises aux capacités ; les suggestions de contenu, si présentes, viennent d'une projection autorisée.

**Pendant saisie :** clavier direct sur mobile lorsque surface de recherche ouverte par geste explicite ; texte inchangé tant que l'utilisateur écrit ; bouton Effacer ; indicateur discret après délai ; anciens résultats privés masqués/remplacés selon nouvelle requête (pas d'ancienne réponse présentée comme actuelle) ; requêtes obsolètes ignorées à réception. Retour restaure la page d'origine, son scroll et ses filtres.

**Après résultat :** sections « Classes », « Supports », « Élèves autorisés », etc. **uniquement selon capacités**, maximum 5 cartes/entrées par section au premier écran, ordre stable, titre principal et contexte court. Un seul tap/clic ouvre la route autorisée ; réautorisation serveur de l'objet. Aucun bouton qui modifie une donnée depuis la liste.

**États :** voir §5 ; erreur d'un seul fournisseur ne doit pas supprimer les résultats des autres. Si un domaine n'est pas encore branché dans ce frontend, ne pas présenter le module comme opérationnel ni afficher « Aucun résultat ».

### 4.2 Mobile (360-430 logical px, scénario de base 390×844)

- Coquille mobile existante, navigation retour atteignable et barre basse préservée lorsque design/bottom sheet le permet ; éviter deux navigations concurrentes.
- Écran ou sheet étendue selon profondeur et composition de la coquille existante : en-tête « Rechercher », bouton Retour, champ sur une ligne extensible si texte agrandi, effacement tactile, catégorie en filtres horizontaux non cachés, résultats verticaux.
- Chaque résultat : icône/type ou miniature autorisée, titre sur 1-2 lignes accessibles (contenu complet vocalisé/consultable), bref contexte et chevron ; **pas une carte indépendante pour chaque métadonnée**.
- Pas de mosaïque de quinze modules, pas de filtres complexes ouverts par défaut. Si des filtres avancés existent : bottom sheet courte, appliqués au domaine propriétaire.
- Clavier ouvert : ne pas masquer le premier résultat et le bouton retour ; fermeture explicite ou par navigation, sans perdre la requête.

### 4.3 Tablette (env. 768 logical px, largeur disponible décisive)

- Rail de navigation existant + contenu principal ; recherche dominante sur surface principale.
- Vue résultats et volet aperçu facultatif **uniquement si l'objet autorise un aperçu** ; sinon liste pleine largeur lisible. Pas de colonnes écrasées à texte 200 %.
- Panneau contextuel de recherche en séance lorsque possible, connexion et support pédagogique maintenus.

### 4.4 Desktop / Flutter web (cible de contrôle 1440×900)

- Navigation latérale existante, champ de recherche accessible dans l'espace de travail, **pas une version mobile étirée**.
- Largeur de lecture maîtrisée ; colonne de catégories et filtres autorisés facultative, colonne de résultats centrale dominante, aperçu à droite seulement si permission claire et valeur pratique réelle.
- **Ctrl+K Windows/Linux ou Cmd+K macOS** : ouvrir/focaliser la même recherche si une permission de navigation active le permet ; `Esc` ferme panneau ou efface modal selon état, sans perdre les données ; `Tab`, `Shift+Tab`, flèches et `Enter` suivent le comportement du composant réellement retenu ; focus visible, hover non exclusif.
- Raccourci ne fonctionne pas si l'utilisateur est dans une saisie dont le système considère le raccourci conflictuel, ou si une modale critique a la priorité ; ne jamais intercepter de touches d'édition comme effet secondaire.
- Dans la Classe en direct, recherche documentaire = tiroir latéral ; ouverture de fichier ne doit pas interrompre la séance ; distinction claire support consulté individuellement / support présenté par l'enseignant.

### 4.5 Interface guidée

- Point d'entrée spécialisé « Trouver un support » ; ne pas afficher une « recherche globale » abstraite.
- Gros contrôles, 1 domaine pédagogique à la fois, au plus quelques résultats visibles ; titre simple, miniature reconnue, aide audio du composant existant si nécessaire.
- Pas de filtre par identité, pas de finance, pas de messages personnels ou export. Interface guidée est une présentation, non une autorisation.

### 4.6 Langues, RTL, accessibilité

- DM Sans **titres** ; Plus Jakarta Sans autres textes ; police arabe existante ; tokens gelés (valeurs du code, pas de HEX ni dimensions inventées localement).
- Français, anglais, arabe, poular selon locales réellement prévues ; messages localisés, sens RTL du contenu et des contrôles directionnels ; codes RA/EV et nombres toujours lisibles en LTR même en interface arabe.
- Text scaling 200 %, cibles tactiles Rewayah **48 dp** visées, sémantique des résultats et filtres, focus visible, lecteur d'écran ; ne pas annoncer chaque frappe via live region ; annoncer état chargé et nombre de catégories affichées de façon non intrusive.
- États différenciés autrement que par couleur ; navigation clavier et touch ; respect de la réduction de mouvement ; pas d'animation d'attente décorative sans fin.
- Tester étroitesse 320 px, tablette, landscape, desktop, souris, clavier, lecteur d'écran, mode clair/sombre.

---

## 5. Machine d'états et textes UI exacts (français)

| État | Texte primaire exact | Action / comportement |
|---|---|---|
| Initial | « Rechercher dans votre espace » | Champ focalisable ; aucun balayage serveur sans requête |
| Domaine spécialisé | « Rechercher dans les supports » (adapté au module propriétaire) | Entrée dans contexte borné |
| Requête trop courte pour recherche large | « Saisissez au moins 3 caractères. » | Pas d'appel global ; les références exactes et mots arabes courts ont un parcours borné |
| Chargement court | « Recherche en cours… » | Indicateur discret, annulation implicite si saisie change |
| Résultat disponible | « Résultats pour « {requête} » » | Sections autorisées uniquement ; un résultat ouvre une route |
| Aucun résultat **confirmé** | « Aucun résultat pour cette recherche. » | « Modifier la recherche » ; aide « Essayez un autre mot ou un filtre. » |
| Filtre vide confirmé | « Aucun résultat avec ces filtres. » | « Effacer les filtres » ; conserve requête |
| Domaine indisponible | « La recherche dans ce domaine est indisponible. » | « Réessayer » uniquement ce domaine ; pas « 0 résultat » |
| Erreur globale | « Impossible d'effectuer la recherche. » | « Réessayer » après délai ; accès et session revérifiés |
| Délai dépassé | « La recherche prend trop de temps. » | « Réessayer » / proposer de préciser le domaine, sans nouvelle recherche illimitée |
| Hors ligne | « Vous êtes hors ligne. La recherche en ligne est indisponible. » | « Réessayer » lors du retour réseau ; pas de résultats privés périmés |
| Session expirée | « Votre session a expiré. » | « Se reconnecter » vers flux existant, effacer cache privé en cours |
| Permission retirée / objet inaccessible à l'ouverture | « Cet élément n'est plus accessible. » | « Retour aux résultats » ; pas de détails ni justification confidentielle |
| Domaine non raccordé dans ce lot | « Recherche indisponible pour le moment. » | Action « Retour » ; pas de recherche factice en production |
| Nouvelle requête saisie | « Rechercher » | Effacer résultats précédents non cohérents ; nouvelle requête différée |
| Trop de résultats | **Pas de total spéculatif** | « Voir davantage » ; curseur, domaine maintenu |
| Chargement de page suivante | « Chargement de résultats supplémentaires… » | Anciennes lignes conservées seulement si contexte/droits courants toujours valides |

**Important :** les textes avec variable doivent venir de l'i18n, être échappés comme texte, non injectés dans HTML. Le résultat « Aucun » n'apparaît **que** si l'API a confirmé `success + items=[]`. Toute panne, droit manquant, source non déployée ou expiration de cache a son propre état.

### Transitions d'état requises

`idle -> input -> debounce -> loading -> partial|success|empty|error|timeout` ; `loading -> cancelled/outdated` quand nouvelle saisie ; `success -> paginating -> appended|page_error`; `any -> context_changed / logout / revoked -> purge + idle`; `success -> open -> route | denied_stale`. Les retours tardifs sont ignorés si le *generation token* de requête ne correspond plus. Une annulation Flutter n'implique pas automatiquement l'arrêt effectif de la requête SQL ; appliquer aussi des limites serveur côté serveur dans le lot intégré.

---

## 6. Garde-fous de performance : la recherche ne doit jamais « explorer Windows »

### 6.1 Principes non négociables

1. **Pas de scan client** de tous les élèves, classes, factures, documents ou messages. Un champ Flutter ne charge jamais une liste entière avant de filtrer. Un filtre local n'est admissible que sur un petit corpus intégralement chargé, déjà autorisé, identifié et non présenté comme une recherche complète.
2. **Pas de recherche sans bornes** : nombre de domaines sollicités limité, champs autorisés, taille de requête, pages et concurrence bornées, pagination **par curseur** ; jamais `SELECT *`, `OFFSET 100000` ou `ILIKE '%a%'` global.
3. **Unité de mesure = temps perçu ET temps backend** : déclenchement après saisie, latence réseau, disponibilité des résultats, taux d'erreurs, précision/rappel sur jeu d'essai. Une moyenne rapide cache un p95 catastrophique.
4. **Recherche contextualisée d'abord** : dans Bibliothèque, chercher les supports ; dans Comptabilité, chercher les opérations ; dans Espace Classe, chercher ses ressources. Ne pas lancer tous les domaines pour une simple action de lecture.
5. **Désamorçage d'un domaine lent** : résultat des autres domaines affiché sans attendre celui qui bloque, statut d'indisponibilité par domaine, possibilité de retry ciblé, limite de concurrence.
6. **Fail fast, graceful degradation** : délai contrôlé et message exploitable ; aucun spinner sans fin ; ne pas élargir l'audience pour obtenir des résultats.

### 6.2 Paramètres de départ **PROPOSÉS** (ajustables uniquement par mesures de recette)

| Dimension | Budget initial proposé | Justification et condition de preuve |
|---|---|---|
| Déclenchement de recherche | ~250 ms après dernière frappe, immédiat sur validation explicite | Réduire réseau sans sensation de lenteur ; annuler/ignorer la requête précédente |
| Recherche textuelle large | min 3 caractères ; max 160 caractères et 8 termes | Éviter scans de lettres isolées ; exceptions structurées (matricule/code EV) et arabe court dans domaine borné |
| Fenêtre commune | maximum **5 résultats par domaine**, seulement domaines réellement autorisés/branchés | First meaningful results rapides ; pas de classement interdomaines artificiel |
| Liste spécialisée | **20 résultats/page**, cap technique serveur **50** | Scrolling borné, curseur opaque, « Voir davantage » |
| SQL sous RLS | objectif **p95 ≤150 ms** | Mesurer sur environnement représentatif, RLS et droits activés, index et plans relevés |
| API (hors réseau client) | objectif **p95 ≤400 ms, p99 ≤1 s** | Traces depuis gateway, inclut droits + agrégation ; objectifs non garantis |
| Perçu en réseau de test convenu | cible initiale **p95 ≤1 000 ms** entre dernière frappe et premiers résultats utiles | Inclut debounce, réseau, décodage, premier rendu ; retenir réseau et appareil mesurés |
| Fin d'attente normale UI | **2 s** : indiquer qu'une recherche dure plus que prévu sans bloquer les autres sections | Ne signifie pas « aucun résultat » ; feedback d'état |
| Timeout fonctionnel de la recherche | **3 s** de budget par demande cliente dans le scénario nominal (à calibrer avec latence réelle) | Afficher timeout/retry ciblé, pas spinner prolongé ; le backend doit posséder son propre timeout plus court, proposé 1,5 s SQL |
| Nombre de domaines interrogés simultanément | budget de concurrence explicite (proposition : 3 à la fois, priorité au contexte et aux plus pertinents) | Éviter fan-out incontrôlé ; file d'attente bornée ; ne jamais monopoliser une connexion par onglet |
| Paramètres UX | aucune requête serveur pour champ vide ; pas de suggestions cross-utilisateurs | Sécurité, coût et performance |

**Clarification :** le p95 ressenti proposé doit être mesuré sur un profil réseau de référence préenregistré (Wi-Fi/4G stable, appareil représentatif). Sur des connexions dégradées, publier des mesures séparées et privilégier une sortie d’attente explicite. Les délais ne sont pas des garanties contractuelles à ce stade. À l'étranger, un réseau mobile lent peut dépasser 800 ms ; mesure par catégorie réseau et région, puis réponse dégradée explicite. 1,5 s SQL n'est pas un timeout Flutter. Le budget de 3 s est une proposition de comportement client avec cancel/erreur, pas une garantie que la base s'arrête sans réglage serveur.

### 6.3 Plan d'indexation **dans le chantier intégré, après les gates R0-R2 sur STAGING**

- **Exact references :** B-tree sur identifiant normalisé et sur les clés de relation d'autorisation ; RA et EV recherche exacte, jamais fuzzy avec sélection automatique.
- **Texte métier :** `tsvector` avec configuration de langue explicite + GIN adapté, ou index équivalent selon corpus ; l'index ne remplace pas la vérification d'accès aux colonnes et aux lignes.
- **Fautes, nom court :** `pg_trgm` sur champs autorisés, longueur minimale et domaine restreint ; index déjà présent pour `verset.texte_recherche` à **examiner** et éventuellement réutiliser, pas dupliquer mécaniquement.
- **Relations d'accès :** index réellement utiles sur affiliation, foyer, délégation, classe, remplacement, mission, participation, droit actif/date, publication et suppression ; RLS sous identité réelle.
- **Tri/pagination :** score local du domaine + date/identifiant de départage stable ; curseur opaque lié à identité, espace, filtres, requête et version de corpus si nécessaire.
- **Fonction de recherche commune :** orchestrer plusieurs requêtes spécialisées, chacune bornée ; interdire un index unique contenant des champs de confidentialité hétérogène.
- **Capacité réelle :** profiler requêtes, taux de cache, buffers, GIN updates, concurrence, pool et verrouillage. Ajuster index depuis `EXPLAIN (ANALYZE, BUFFERS)` uniquement sur staging synthétique, jamais sur des dossiers réels de production.
- **Pas d'Elasticsearch/Meilisearch « par principe »** : mesurer PostgreSQL d'abord. Migration vers une solution dédiée seulement après étude des volumes, coûts, synchronisation, lag, autorisation et révocation ; pas de synchronisation brute de données sensibles vers un moteur public.

### 6.4 Résilience et qualité de résultat

- Exact match RA/EV prime sur un mot libre ; nom/titre précis avant texte libre ; recent/accessible selon contexte, sans faire apparaître un contenu interdit.
- Recherche FR/EN par configuration adaptée ; arabe vocalisé/non vocalisé sur représentation de recherche distincte, sans modifier le Coran canonique ; Poular : diacritiques/orthographes contrôlés, pas de promesse de stemming exhaustif.
- Les petits corpus locaux ne deviennent pas des « résultats d'ensemble » quand l'API est indisponible. Documenter source, couverture et fraîcheur.
- La page initiale doit rester réactive même si une catégorie est longue ; éviter N+1 et les métadonnées lourdes, miniatures chargées séparément avec fallback.
- Ne pas récupérer un PDF complet ou une photo de pièce pour produire un snippet. Les images et assets sont chargés par destinations autorisées, pas par recherche globale.
- Mesurer qualité sur 30 à 50 requêtes représentatives par domaine, rédigées avec le métier. Un moteur rapide mais incapable de retrouver « Al-Fātiḥa », une facture exacte ou une classe autorisée **échoue aussi**.

---

## 7. Modèle de menace et règles de sécurité obligatoires

### 7.1 Invariants d'autorisation serveur (OBLIGATOIRES AVANT ACTIVATION)

Le serveur obtient l'identité depuis une session vérifiée, constate l'espace/capacité/relation/état réels, puis calcule le sous-ensemble de documents/champs interrogables. Il ne fait **jamais** confiance à `user_id`, `role`, `household_id`, `can_view`, `is_admin`, `classe_id` ou `espace` reçus du client pour accorder un droit. Un paramètre d'espace est un **choix d'interface**, à intersecter aux capacités courantes, non une preuve d'autorisation.

Enchaînement conceptuel de sécurité : `caller courant -> espace/capabilities actifs -> relations & états -> corpus autorisé -> champs matchables -> matching/score/facettes -> champs projetés -> ouverture réautorisée`. L'ordre conceptuel ne prescrit pas un ordre de jointure SQL ; il prescrit l'absence de toute divulgation d'objets non autorisés.

Sur PostgreSQL/Supabase : `RLS` sur lignes **et** projections de colonnes explicites, grants minimaux, vues `security_invoker` ou voie serveur sécurisée, fonctions privilégiées à justifier. Pas de service_role exposé ou utilisé comme raccourci de filtrage. Définitions `SECURITY DEFINER` soumises à revue des grants, `search_path`, identité effective et usages indirects. Contrôles actuels des claims JWT et révocations documentés comme risques P0 dans BR0B ; ne jamais déclarer « sécurisé » parce que le frontend masque des données.

### 7.2 Menaces spécifiques à couvrir

| Référence | Scénario hostile | Exigence vérifiable |
|---|---|---|
| SEC-R01 | Foyer A recherche prénom, RA, classe, nom privé du foyer B | Aucun hit, suggestion, facet, compteur, snippet ni destinataire d'un lien |
| SEC-R02 | Enseignant recherche terme présent **uniquement** dans note financière d'un élève autorisé | La fiche n'apparaît pas à cause de ce terme ; matching restreint aux champs pédagogiques |
| SEC-R03 | Code RA aléatoire d'une autre personne | Aucun annuaire global ni résolution de code sans lien autorisé |
| SEC-R04 | Code EV public utilisé hors de son évaluation | Aucun mapping global vers RA ou vers identité ; code événement borné |
| SEC-R05 | Requête changée après 3 frappes, ancienne réponse réseau plus lente | Ancienne réponse abandonnée, jamais affichée comme réponse à la nouvelle saisie |
| SEC-R06 | Suppression de publication, fin de droit, classe remplacée/mission expirée | Nouvelles requêtes et ouvertures refusées ; caches en mémoire invalidés ; aucun accès prolongé par résultat obsolète |
| SEC-R07 | Changement de compte A -> B sur même appareil/PWA | Purge complète du cache privé, suggestions, curseurs, requêtes in-flight, previews, thumbnails sensibles et mémoire d'UI |
| SEC-R08 | Changement d'espace Tuteur -> Personnel | Ne pas afficher liste de résultats du précédent espace, aucun cache commun cross-space |
| SEC-R09 | API filtre lignes mais calcule total global / facettes globales | Aucun total/facet de corpus interdit ; éviter message « X résultats masqués » |
| SEC-R10 | API retourne JSON contenant champ caché malgré UI neutre | DTO en liste blanche, champ jamais sérialisé ; test réponse brute, pas capture seule |
| SEC-R11 | HTML/Markdown malveillant dans texte source | Échapper/segmenter le surlignage côté UI ; jamais insertion HTML/`ts_headline` brut |
| SEC-R12 | Paramètre URL, deep link, `document_id` ou curseur forgé | Autorisation refaite, curseur lié au contexte, destination en liste blanche et sans données sensibles dans URL |
| SEC-R13 | Accès à Storage/R2 via résultat trouvé | URL signée courte au moment d'ouvrir, auth propre et vérification des droits ; pas d'URL brute dans résultat |
| SEC-R14 | Dossier KYC / rapport Contrôle / coordonnées bancaires cherchés en global | Recherches dans module dédié avec projection minimale, pas d'OCR ni d'index global |
| SEC-R15 | Recherche sous JWT périmé après révocation | Permissions serveur fraîches ; ancien JWT ne rétablit pas affectation retirée |
| SEC-R16 | Observateur IA avec lien temporaire se fait passer pour enseignant observé | Aucune recherche par héritage de rôle/sujet ; identité propre, mission bornée |
| SEC-R17 | Exhaustivité de listing via énumération de pages/termes ou appels rapides | Rate limit / anti-énumération côté API/gateway et contrôle d'accès ; pas de fuite par différence évident de message |
| SEC-R18 | Offline et cache privé obsolète | Pas de recherche « serveur confirmée » hors ligne ; respect d'autorisation et politique du cache métier |
| SEC-R19 | Données retirées mais réplique/index en retard | Recontrôler source avant affichage/ouverture, traiter index/cache dérivés selon la rétention |
| SEC-R20 | Journalisation de termes « cancer », enfant, IBAN, KYC, etc. | Pas de journal de requête brut, de résultats personnels ou de contenu sensible en télémétrie par défaut |
| SEC-R21 | Ralentissement provoqué par input énorme/wildcards/opérateurs | Limites taille/termes, requêtes paramétrées, quotas, timeout réel, pas d'interpolation SQL |
| SEC-R22 | Mécanismes de traduction/autocomplete sur corpus privé via fournisseur externe | Aucun envoi de requêtes ou contenus privés à un service tiers sans contrat et décision explicite |

**Sécurité par défaut :** échec de vérification des droits = résultat non livré. Mais l'UI affiche un état de panne/droit, pas une « liste vide » mensongère. Les différences de statut et latence permettant l'énumération d'une personne sensible sont à examiner en test négatif ; la réaction de l'UI ne doit pas révéler un secret.

### 7.3 Cache, session et confidentialité

- **V1 : pas de cache partagé de résultats privés, pas de stockage persistant de requêtes sensibles.** Un cache de catalogue public est possible sous politique d'invalidation.
- Les listes/filtres/aperçus sont *scopés* par identité, espace, domaine, paramètres de recherche, session et version des autorisations ; purge au changement de compte/espace, fermeture de session ou révocation détectée.
- Ne pas mettre les matricules/PII dans URL, logs analytiques, clipboard sans action explicite, notification système, erreur technique ou crash report.
- Ne pas compter sur une purge distante d'une capture d'écran déjà effectuée par l'utilisateur ; limiter la divulgation dès l'origine.
- Le stockage et la recherche hors ligne appartiennent à chaque module autorisé : aucune indexation globale de documents privés pour « accélérer » la première version.

---

## 8. Contrat API intégré, à réconcilier avec les ports et RPC existants

### 8.1 Capacités de recherche

`availableSearchScopes(contextRequested)` reçoit l'identité via **session vérifiée** et renvoie **uniquement** les domaines, sous-filtres et modes réellement accessibles et opérationnels. Ne renvoie jamais de catégorie confidentielle avec `enabled:false` à un acteur qui ne doit même pas en connaître l'existence.

### 8.2 Recherche métier

`searchDomain(domain, query, context, filters, cursor, limit)` : le paramètre de rôle, profil, foyer, groupe, mission ou espace provenant du client est une **demande de contexte**, jamais une preuve de permission. Le serveur fait autorité avec identité réelle, état de compte, capacités à jour, relation et durée de l'affectation, ligne ET colonne.

**Réponse logique recommandée :**

```json
{
  "query_id": "opaque-request-id",
  "domain": "library",
  "status": "ok",
  "items": [
    {
      "type": "support",
      "reference": "opaque-resource-reference",
      "title": "Leçon de lecture",
      "context_label": "Support de votre classe",
      "excerpt": null,
      "target": {"kind": "library_resource", "ref": "opaque-resource-reference"}
    }
  ],
  "next_cursor": null,
  "has_more": false
}
```

`items` est une **liste blanche**, jamais un dump du modèle DB. Les `target.kind` appartiennent à une liste de destinations prévues et vérifiées. Une chaîne de texte issue de la DB ne devient pas une URL d'ouverture arbitraire. Aucun lien signé R2 n'est renvoyé par la recherche commune.

**États internes contractuels :** `ok` (avec `items=[]` pour un vide confirmé), `temporarily_unavailable`, `timeout`, `rate_limited`, `session_expired`, `context_revoked`, `invalid_query`, `stale_cursor`. L'UI convertit ces états vers les textes de V3 §5 sans révéler l'existence d'un objet privé ou d'un domaine non autorisé. Les réponses aux ressources non trouvées et interdites doivent éviter l'énumération. L'opération de *navigation* revalide l'accès.

**Pagination :** curseur opaque, intègre la forme canonique de requête, le domaine, filtres, ordre total, contexte/session et version utile. Signature/tamper detection côté serveur si exposé au client. Ne porte ni privilège ni autorisation durable. Revalider chaque page et gérer ordre modifié par insertions/révocations.

### 8.3 Agrégateur UI et retours partiels

**Choix d'architecture :** Flutter orchestre au plus les moteurs de domaines autorisés utiles à la requête, au besoin par une façade serveur commune. L'orchestration ne doit pas rendre tous les domaines atomiques : si Bibliothèque répond et Finance échoue, Bibliothèque s'affiche, Finance indique sa panne si l'utilisateur y est autorisé. Si un endpoint de façade synchrone ne permet pas ce rendu partiel sans attendre le plus lent, préférer des réponses indépendantes par domaine ou un protocole de résultats partiels, **sans exposer de nouvelles données ni dupliquer la logique métier**.

Aucune réponse tardive ne remplace une requête récente : `request generation token` côté Flutter, abandon des anciennes réponses et annulation réseau lorsque possible. **Annuler Flutter ne garantit pas l'arrêt SQL** : timeout et limites serveur propres à chaque opération.

---

## 9. Anti-doublons et carte des fonctions

| Fonction | Propriétaire unique | Points d'entrée autorisés | Ne pas créer |
|---|---|---|---|
| Recherche commune contextualisée | Surface Recherche dans routeur existant | Header espace actif, raccourci clavier si disponible | Une page de recherche par rôle ou un cinquième onglet |
| Recherche dans une classe/support | Bibliothèque/Classe propriétaire | Champ ou bouton contextuel du module | Un deuxième catalogue ou moteur Coran |
| Lecture d'un message | Messagerie/Studio propriétaire | Résultat fils en global, recherche texte en module | Index global des corps de messages |
| Consultation d'un élève | Fiche pédagogique ou Foyer selon espace | Résultat vers route métier | Une fiche « élève de recherche » avec droits supplémentaires |
| Recherche d'une facture | Module Finance autorisé | Barre domaine ou catégorie Finances | Un second registre financier |
| Voir une pièce KYC | Viewer KYC habilité | Uniquement file/dossier autorisé | Aperçu de pièce dans la liste globale |
| Recherche RA/EV | Mécanisme identité/événement propriétaire | Recherche autorisée de personne ; page événement EV | Annuaire de vérification RA public |
| Commande métier | Écran métier canonique | Lien de navigation statique autorisé | Paiement, approbation, retrait ou annulation dans la palette de recherche |

**Une seule sémantique partagée**, mais plusieurs *contextes de recherche spécialisés*. Ne pas confondre une fonctionnalité métier et son raccourci de navigation. Toute surface de recherche doit retrouver dans le dépôt ses chemins et permissions réels avant wiring.

---

## 10. Programme de tests de sécurité, rapidité et UX

### 10.1 Matrice de recette sécurité (bloquante avant utilisateurs réels)

- **REC-S01 à S06 :** foyers A/B, enfant mineur, élève adulte autonome/role technique guardian, second adulte lecture versus écriture, enseignant permanent versus extérieur, remplaçant actif versus expiré.
- **REC-S07 à S11 :** contrôleur mission autorisée versus autre, administration limitée, séparation Direction/KYC, Comptable sans pédagogique, agent observateur temporaire.
- **REC-S12 à S16 :** RA exact non autorisé, EV inter-évaluation, homonyme, résultat masqué par champ interdit, note sensible matchable uniquement si projetée.
- **REC-S17 à S21 :** recherches avec JWT ancien, suppression/dépublication, changement de compte/espace, cache PWA, absence de messages privés dans recherche commune.
- **REC-S22 à S27 :** JSON brut et champs cachés, suggesteurs/facettes/compteurs, deep links forgés, pagination curseur altéré, export non autorisé, URL Storage expirée.
- **REC-S28 à S32 :** texte hostile, contrôle SQL/rate limits, timeout/multi-domaines, index/replica obsolète, journaux/télémétrie sans termes sensibles.

Pour chaque cas : prouver **la requête** sous identité réelle de staging, la réponse brute, le résultat Flutter, l'ouverture refusée ou réussie, puis la mise à jour du cache. Ne pas se contenter de « la loupe a disparu ». Aucune donnée réelle dans STAGING.

### 10.2 Recette performance non négociable

Scénarios d'échelle à exécuter sur **corpus synthétique** représentatif et chiffrer par rôle, données, requête, hardware, plan et concurrence :

| Profil de charge | Dataset proposé à tester | Ce qu'on prouve |
|---|---|---|
| Baseline | ~10 000 objets répartis en domaines | Fonctionnement, pertinence, autorisation, p50/p95/p99 |
| Croissance | ~100 000 objets | Utilisation des index, no full scan anormal, mémoire, stabilité des curseurs |
| Cible ambitieuse | ~1 000 000 d'objets si projet et environnement permettent la simulation | Stabilité sous droits réels, coût, limites de PostgreSQL et points de bascule potentiels |
| Concurrence | 25, 100 puis 300 utilisateurs synthétiques actifs **selon ressources disponibles**, pas en PROD | Pool, requêtes/s, erreurs, rate limiting, saturation, isolation des domaines |
| Réseau client | Wi-Fi normal, 4G dégradée, latence élevée et coupure | Temps perçu, état de timeout, retry sans doublons, absence de spinner infini |
| Input adversarial | 1 caractère, 160+, répétition rapide, wildcards, mots arabes courts, référence structurée, code incomplet | Rejet borné, pas de scan de table ni de fuite |

**Budget d'échec :** un seul domaine lent ne doit pas empêcher l'affichage des autres ; si la limite cliente est dépassée, la surface quitte l'état `loading` et montre un message et une action. Tout résultat qui arrive après annulation/changement d'espace est ignoré.

**Preuve attendue** : graphes p50/p95/p99 end-to-end, p95 SQL/API par domaine sous RLS, latence p95 décomposée (debounce/réseau/API/rendu), plan des requêtes responsables, volume de réponse, nombre de requêtes par recherche, taux de timeouts, impact d'index, taux de résultat utile sur requêtes métier, revue coût. **Une capture fluide ne vaut pas benchmark.**

### 10.3 Recette visuelle et opérationnelle

- 320, 390, 768, 1024, 1440 logical px ; portrait/paysage ; mode clair/sombre ; localisations FR/EN/arabe/Poular selon disponibilité ; 200 % texte ; clavier et lecteur d'écran.
- Navigation depuis chacun des espaces concernés en touchant le **vrai bouton** : ouvrir recherche, saisir, filtrer, rechercher, sélectionner, revenir ; scroll et contexte restaurés.
- Interface guidée : recherche de support accessible, sans annuaire/finances, grosses cibles et aides prévues.
- LiveKit (dans le raccordement intégré) : entrée dans recherche de support sans couper audio ni interrompre support dirigé ; pendant le lot frontend, vérifier la continuité de la structure UX sans feindre un média réellement connecté.
- Mode de démonstration : aucun endpoint de production ; scénario d'erreur/vide/permission/timeout ; identité fictive visible comme démo dans l'aperçu non-prod.
- Actions sensibles : résultats ne déclenchent aucune action d'écriture ; navigation vers écran canonique, confirmation métier propre si requise.
- Aucun doublon : audit des recherches existantes, noms de widgets, port et chemins ; un résultat dont la route est manquante ne doit pas être clickable vers le néant.

---

## 11. Références high-fi, maquettes existantes et critères de validation

**Les 7 PNG livrés avec ce document sont des maquettes statiques de validation. Ce ne sont PAS des captures du build Flutter réel, ni la preuve que les comptes, routes, filtres, tokens, polices ou données existent tels quels.** Toutes les données d'exemple sont synthétiques. La composition et le texte guident la revue ; Claude doit vérifier les tokens gelés, composants et navigations réels, et produire ses **propres captures Flutter**, avant de déclarer la fidélité acquise.

| Référence livrée | Format | Usage et décisions visuelles | Ajustement obligatoire avant intégration |
|---|---|---|---|
| `IMG-RECH-01-M.png` | 390 × 844 | Famille : champ unique, résultats par Classes puis Supports, raccourci de retour | Conserver exactement Accueil · Foyer · Historique · Compte ; photo publique enseignant si la carte réelle la requiert ; ne pas exposer les profils étrangers |
| `IMG-RECH-02-M.png` | 390 × 844 | Interface guidée : « Trouver un support », quelques grosses lignes, aide | Aucun annuaire, finance ou filtre technique ; respect aides vocales et capacités effectives |
| `IMG-RECH-03-D.png` | 1440 × 900 | Enseignant dark : Classes/élèves pédagogiques/supports par groupes | Réutiliser coquille de rôle, noms et droits exacts ; toute recherche Élève reste projection pédagogique |
| `IMG-RECH-04-D.png` | 1440 × 900 | Direction/admin light : filtres proches du contenu et résultats métier | Pas de KYC dans recherche commune ; vérifier les droits de revue Direction, CPT-Q1 et intitulés réels du menu |
| `IMG-RECH-05-D.png` | 1440 × 900 | Comptable light : références/états, table lisible, aucune action de paiement directe | Reprendre les écrans canoniques CPT/FI et le masquage précis ; ni donnée financière simulée comme réelle ni mouvement déclenché |
| `IMG-RECH-06-M.png` | planche 1440 × 900 | Chargement, vide, hors ligne, panne ciblée, timeout, accès retiré | Respecter tous les textes et transitions de V3 §5 ; adapter visuellement à la surface mobile réelle |
| `IMG-RECH-07-T.png` | 1024 × 768 | Tablette Classe : document dominant, recherche dans panneau droit, room préservée | Utiliser le vrai moteur de support et la vraie salle ; le rectangle schématique n'est pas un Muṣḥaf ni une capture canonique |

### Direction visuelle impérative

- Accent lavande, surface ardoise en sombre, clair sobre, pas de nouvelle palette ; DM Sans titres, Plus Jakarta Sans autres textes, police arabe actuelle.
- Réutiliser `Pressable`, `AvatarTile`, cartes groupées **un seul rectangle avec filets internes**, champ de recherche partagé, chips et navigation existants. Aucun composant parallèle si un équivalent existe.
- **La donnée principale prime** : ne pas convertir la recherche en dashboard décoratif, n'ajouter ni navigation primaire « Recherche » ni écran de détail concurrent. Sur ordinateur, vraie sidebar et colonnes. Sur mobile, champ et résultats accessibles au pouce, pas une page desktop rétrécie.
- Afficher les résultats valides au fur et à mesure ; aucune recherche globale sur saisie vide, ni « historiques récents » privés persistants non prévus.
- Tester 320/390/768/1024/1440, light/dark, 200 % texte, clavier, lecteur d'écran, arabe RTL ; le matricule garde sa direction LTR.
- Chaque maquette doit être comparée à une capture **réelle** de l'app dans l'état considéré. Les décisions exactes du code et du directeur priment sur les détails illustratifs de ces PNG.

### Flux UI (une seule route canonique)

**Famille, enseignant, admin, comptable :** coquille existante → loupe contextualisée → même surface Recherche pour l'espace actif → saisie/filtres → sections autorisées reçues du serveur → résultat → destination métier réautorisée → retour aux résultats avec filtres et scroll restaurés si droits toujours valides. Sur desktop, Ctrl/Cmd+K ouvre cette même surface si aucune modalité n'a priorité et si le raccourci ne gêne pas la saisie.

**Interface guidée :** Classe/Bibliothèque → `Trouver un support` → uniquement ses ressources pédagogiques → ouvrir le support autorisé → retour. Le libellé accessible et l'éventuelle aide audio suivent le composant existant.

**En salle :** Enseignant → Bibliothèque du Teaching Dock → recherche contextualisée à la Classe → ouvrir localement un support autorisé → action distincte de présentation collective *uniquement là où les capacités existantes le prévoient*. Audio, vidéo, connexion et autorité de l'enseignant restent inchangés.

---

## 12. Matrice écran → port Flutter → domaine serveur → autorisation

**Ce tableau est une cible de raccordement, pas une déclaration d'existence du backend. Les vrais chemins/noms sont à vérifier en R0.**

| UI canonique / domaine | Port logique à réutiliser ou adapter | Contrat serveur spécialisé | Condition d'autorisation et donnée exclue | Test de bout en bout |
|---|---|---|---|---|
| Entrée Recherche, tous espaces actifs | `PortRechercheCommune` orchestrateur de résultats typés | Capacités/domaines autorisés et appels bornés aux moteurs métiers | Espace choisi intersecté au serveur avec acteur, capacités, relations et état actuel | UI n'affiche jamais d'onglet non autorisé ; changement espace purge |
| Classes et séances | Port Classes/planning existant | recherche classes/offres/séances selon audience | Inscrit vs catalogue publié vs enseignant affecté ; fuseaux horaires locaux, remplacements datés | Classe étrangère absente ; mission expirée refusée |
| Familles / élèves | Foyer, roster, Personnes selon contexte | match nom ou RA exact sur **projection de la relation autorisée** | Aucun annuaire, email privé, KYC, autre foyer, niveau/paiement non autorisé | Homonymes autorisés, mot secret seulement dans note privée ne matche pas |
| Supports / bibliothèque | Ports Library/Quran existants | recherche metadata et texte validé autorisé | Licence, version, niveau, groupe, publication ; jamais URL R2 brute | Un support retiré n'apparaît ni dans suggestion ni à l'ouverture |
| Coran | Lecteur existant | projection de recherche séparée du texte canonique | Respect Ḥafṣ, sourate, page, verset, diacritiques ; ne jamais modifier source canonique | Requête arabe vocalisée/non vocalisée, page et ordre corrects |
| Annonces et Communauté | Ports COM existants | lecture annonces/pub visibles, filtres par audience | Uniquement annonces visibles, état publication et canal autorisé | Annonce retirée non retrouvée |
| Fils Messagerie/Studio, barre commune | `PortMessagesMetier` / `PortStudio` via adaptateur existant | liste de fils autorisés, titres/métadonnées seulement | **Aucun corps de message indexé dans l'agrégateur** | Mot présent seulement dans message ne matche pas en global |
| Corps des messages | recherche interne COM/Studio | recherche texte dans fils/canaux accessibles | Participation, confidentialité, suppression et rétention ; autorisation à chaque page | Fils étrangers refusés, aucun ancien message effacé |
| Élève : travail / progression | ports pédagogiques existants | recherche strictement personnelle ou pédagogique | Aucun cahier de camarade ni note interne | Élève A ne retrouve rien de B |
| Contrôle | Port missions/rapports existant | recherche sur missions assignées et extraits permis | KYC exclu ; anonymat contrôleur et rapport brut préservés | Contrôleur sans mission n'obtient aucun indice |
| Finance foyer | FI existant | référence/solde/mouvements projetés selon titulaire/délégation | Second adulte lecture si autorisée, recharge uniquement titulaire | Pas de « recharge » exécutable depuis recherche |
| Comptabilité | CPT existant | références et statuts dans obligations/factures accessibles | Données bancaires et approbations selon capacité ; pas de droits pédagogiques hérités | Tentative de lire détail masqué refusée côté API |
| Direction | ports admin/direction effectifs | recherches de domaines seulement si habilités | Domaine KYC et contrôle sensible dans leur file dédiée ; revue Direction seule si règle actuelle confirmée | Compteur/facette global ne révèle rien |
| Public / visiteur | ports publications publiques explicites | pages/offres réellement publiques seulement si moteur disponible | Aucun index privé, aucune résolution RA; EV limité à l'événement publié | EV hors événement et RA n'identifient personne |

**Interdiction :** inventer un `SearchEverything` qui stocke dans la même projection noms de mineurs, messages, KYC, adresses et informations bancaires, même avec un filtre sur `role`. Les moteurs spécialisés portent chacun leur autorité de lecture et la liste exacte des champs indexables.

---

## 13. Architecture backend et performance réelle - contrat de réalisation

### 13.1 Pipeline d'une recherche autorisée

```text
Flutter : saisie + espace actif demandé + génération de requête
  → liste des domaines autorisés et prêts (droits serveur ACTUELS)
  → fan-out borné, priorité au domaine de la page ouverte
  → chaque recherche métier utilise sa propre projection autorisée :
     session vérifiée → capacités et relations fraîches → champs matchables
     → index/requête paramétrée → tri par domaine → curseur → DTO liste blanche
  → réponses PARTIELLES indépendantes par domaine
  → rendu des premiers résultats autorisés et état de chaque domaine
  → clic : route canonique + NOUVELLE autorisation sur l'objet/fichier
```

Le serveur **ne fait jamais confiance** aux filtres/labels du client pour ouvrir un droit. L'espace, la relation foyer, la mission de remplacement, la délégation financière et la date d'expiration sont résolus côté serveur. **Ni recherche transversale de tous les textes ni agrégateur avec `service_role` contournant RLS.** Les champs indexés et scannés doivent être ceux que l'acteur a le droit d'utiliser pour une correspondance, pas simplement ceux qu'il peut ensuite afficher.

### 13.2 Architecture PostgreSQL/Supabase et scalabilité

1. Références exactes RA/EV/factures/classes : index **B-tree** normalisés et indexes des relations d'accès, matching par égalité ; RA et EV ne se résolvent pas publiquement, EV a un scope d'évaluation.
2. Recherche FR/EN : index **GIN `tsvector`** sur colonnes éligibles à un corpus et une audience déterminés, configuration de langue explicite. Ne jamais constituer un `tsvector` global concaténant notes privées et noms visibles.
3. Tolérance aux fautes limitée : `pg_trgm` lorsque mesuré utile, sur les titres/noms autorisés et avec requêtes assez longues ; homonymes et résultats proches ne se sélectionnent jamais automatiquement.
4. Arabe/Poular : forme de recherche séparée du texte source, normalisation testée diacritiques/harakāt/apostrophes ; Coran canonique et pagination Hafs inchangés ; examiner `verset.texte_recherche` et son GIN trigram **observé le 07/10**, sans supposer qu'il existe toujours.
5. Identities, affectations, foyer, missions, publication, délégations, date de validité : index de clés et conditions de filtrage **pilotés par les requêtes réelles** ; éviter un index lourd inutile sur les insertions.
6. Pagination **keyset/curseur opaque**, tri stable par domaine, `has_more` préférable au comptage total, curseur protégé et lié à l'appelant/espace/requête/filtre/tri ; vérifier les droits à chaque page et réinitialiser si le corpus rend le curseur périmé.
7. `SELECT *`, N+1, OFFSET profond, full scans génériques, récupération d'un PDF/image pour fabriquer un extrait, requête `%a%` sur toutes les tables : **interdits comme stratégie du moteur**. L'analyse d'un plan peut justifier un scan sur un corpus minuscule, mais pas un moteur linéaire non borné.
8. `EXPLAIN (ANALYZE, BUFFERS)` **sur staging synthétique**, avec rôle applicatif, RLS, grants et taille de corpus réalistes ; suivi pool, index, write amplification, p95/p99 et coûts de transfert.
9. PostgreSQL d'abord ; moteur externe seulement sur preuve de nécessité, approbation de la Direction et dispositif complet de réplication, effacement, révocation, autorisation des champs, délais d'indexation et coûts. Aucun catalogue privé envoyé à un service tiers pour autocomplete/traduction sans décision formelle.
10. Les clients Flutter passent par les interfaces/ports déjà définis, jamais une connexion PostgreSQL directe. Réutiliser les adaptateurs par domaine, router commun n'est pas un second modèle métier.

**Avertissement issu du complément du 7 octobre :** `GIN + LIMIT 20` ne suffit pas à garantir un p95 correct si le terme est fréquent et déclenche un classement énorme ; keyset évite les grandes pages OFFSET mais ne rend pas gratuit le classement dynamique. Identifier les candidats, les index sur relations et le coût réel sous RLS. Distinguer volume d'objets, utilisateurs actifs, recherches/s, sessions LiveKit simultanées et saturation DB ; un nombre de comptes ne mesure pas la capacité.

### 13.3 Délais, requêtes et circuit d'échec

Tous les budgets ci-dessous sont **PROPOSÉS, non mesurés**, puis soumis à recettage sur configuration documentée :

| Segment | Cible initiale | Modalité d'échec / garde |
|---|---|---|
| Saisie | ~250 ms de debounce, Enter immédiat | Chaque nouvelle saisie invalide `generationId` et ignore les anciennes réponses ; cancel HTTP lorsque possible |
| Entrée texte large | 3 caractères min ; 160 caractères max et 8 termes | Exemptions bornées code structuré/arabe court ; requête vide sans appel serveur global |
| Agrégateur | 3 domaines simultanés **au départ**, 5 items maximum par domaine commun | Prioriser contexte, queue bornée, rendu partiel, chaque domaine peut échouer isolément |
| Domaine détaillé | 20 items/page, cap de requête 50 | Curseur, interdiction de demander une liste entière |
| SQL sous RLS | p95 ≤ 150 ms | `statement_timeout` proposé ~1,5 s, à mesurer et calibrer sans impact sur autres opérations |
| API hors réseau client | p95 ≤ 400 ms ; p99 ≤ 1 s | Deadline par domaine, rate limit, validation session, erreur contrôlée |
| Premier résultat perçu | p95 ≤ 1 000 ms dans réseau/appareil de référence | Mesurer debounce + réseau + API + rendu, pas seulement SQL |
| Feedback de lenteur | à ~2 s | Message explicite sans supprimer résultats déjà reçus |
| Timeout interface de recherche | ~3 s nominal **par demande client** | Transition vers timeout/retry ciblé ; **n'arrête pas SQL à lui seul** |

**PROPOSITION DE RÉSILIENCE :** une réponse d'une source en panne n'est jamais `ok/[]`. Chaque domaine utile fournit `ok + items`, `ok + []`, `temporarily_unavailable`, `timeout`, `rate_limited`, `session_expired`, `context_revoked`, `invalid_query` ou `stale_cursor`. Les statuts sont distingués côté transport, sans révéler à un acteur interdit l'existence d'un domaine. Un domaine interdit est **absent de la liste**, pas affiché désactivé avec son nom.

### 13.4 Fraîcheur, données locales, journalisation et export

- Pas de cache partagé de résultats privés ni d'historique sensible permanent de recherches en V1 ; caches de démonstration isolés et synthétiques ; cache public possible selon politique de publication.
- Scope obligatoire des résultats par session réelle, personne, espace actif, domaine, requête, filtres et capacité courante ; purge à `logout`, changement de compte/espace et révocation détectée. Aucun ancien résultat rendu « vrai » après modification des droits.
- Retrait, suppression, fin de conservation : traiter source, projections d'index, extraits, pièces, miniatures, export et caches contrôlés. Revalider source et droits avant rendu/ouverture si projection asynchrone.
- Pas de texte de recherche brut, nom d'élève, RA, IBAN, motif KYC, PII dans logs, URL, télémétrie, erreur, analytics, captures ou crash reports ; métriques agrégées (durées, statut, volume par domaine, taille de requête non sensible).
- Offline : ne pas feindre une réponse serveur ; les recherches locales de documents téléchargés restent à leur propriétaire métier et suivent leur politique de cache, sans promettre la révocation en temps réel.
- Révocation : ne pas se fier uniquement aux claims JWT historiques ; vérifier relations/capacités actuelles sur chaque opération sensible et à l'ouverture.

### 13.5 Benchmark et protocole de mesures

Jeux **synthétiques à relations réalistes** : deux foyers isolés, homonymes, second adulte délégué, enseignant titulaire/remplaçant expiré, différentes cohortes, communiqués retirés, missions Contrôle, obligations FI/CPT, corpus arabe/Poular/FR/EN, code EV, versions des supports, cache invalide. Étapes d'échelle suggérées : **10 000 → 100 000 → 1 000 000 d'objets** si la capacité staging le permet ; charge **25 → 100 → 300 utilisateurs synthétiques** sous réserve de ressources et en **aucun cas sur PROD**.

Mesurer cache chaud/froid, pages tardives, recherches exactes/populaires/fautes, changement de requête, révocation, première réponse partielle, API p50/p95/p99, SQL p95, réseau Wi-Fi/4G/dégradé, tail latency, erreurs, saturation pool, ratios de résultats pertinents et coûts. Constituer **30 à 50 requêtes métier par domaine** quand le domaine est lancé. Chaque benchmark cite SHA, version du schéma, matériel/plan et corpus, méthode, outil, nombres, plans/buffers, droits simulés et limites. **Ne jamais afficher « 1 million testé » ou « sous la seconde » sans relevé réel.**

---


---

## 14. Recette croisée REC-01 à REC-14 : couverture obligatoire

| Référence | Scénario et preuve attendue |
|---|---|
| REC-01 Foyers | A ne retrouve aucune donnée du foyer B par nom, matricule, référence ou mot privé ; vérifier API, suggestions, compteurs, exports et liens directs. |
| REC-02 Classes | Enseignant affecté vs autre enseignant ; remplacement actif puis expiré ; aucun résultat de la Classe étrangère. |
| REC-03 Champs | Nom ou mot présent seulement dans une note privée : ne fait pas remonter une ligne autrement visible à l'appelant. |
| REC-04 Contrôle | Roster, rapport et fil gardent leurs projections distinctes ; mission étrangère et KYC refusés. |
| REC-05 Finance | Comptable, bénéficiaire, Direction et second adulte obtiennent exactement leurs projections/actions autorisées. |
| REC-06 Publications | ID uniquement sans nom caché dans index/extrait/JSON/HTML ; alias EV d'une autre évaluation non résolu ; publication retirée absente. |
| REC-07 Session | A → logout → B ; changement d'espace ; JWT ancien après retrait de capacité ; aucun résultat ancien réutilisé. |
| REC-08 Pagination | Curseur altéré ou d'une autre session/requête refusé ; droits revérifiés entre deux pages ; tri déterministe. |
| REC-09 Messages | Barre commune ne matche pas le corps des messages ; module dédié retrouve seulement messages et canaux lisibles, selon conservation. |
| REC-10 Langues | FR/EN/Poular/arabe, saisies proches, diacritiques, sourate/verset/page ; source Coran inchangée et correspondance correcte. |
| REC-11 Robustesse | Input très long, opérateurs spéciaux, texte HTML hostile, requête fréquente, timeout, surcharge et réponse obsolète : erreur contrôlée, aucune injection ni résultat inventé. |
| REC-12 Disponibilité | Domaine non implémenté ou en panne rendu indisponible ; zéro correspondance réellement autorisée rendu sans résultat ; pas de faux succès. |
| REC-13 Charge | Dataset synthétique représentatif, RLS réelle, droits complexes et charge mixte ; plans et p95/p99 documentés sur le SHA et la configuration testés. |
| REC-14 Cycle de vie | Suppression, archivage selon contrat, retrait de publication et purge : copies de recherche et caches traités, sans supprimer un droit historique prévu par erreur. |

Exécuter les tests d'autorisation sous les identités applicatives réelles de staging, et ceux de charge sur données synthétiques. Ne pas lancer des requêtes coûteuses `EXPLAIN ANALYZE` ou des publications de test sur des dossiers réels de PROD.

---

## 15. Lots intégrés frontend/backend et ownership des agents

| Lot | Travail / ownership | Sortie et gate |
|---|---|---|
| **R0, obligatoire** | Intégrateur, lecture seule : SHA, branches/worktrees/owners, routes, ports, contrats, migrations 0039-0043, permissions, indexes et environnement disponibles. Ajouter inventaire manques vs déjà codé. | Matrice de vérité `exigence → source → état code → serveur → preuve → bloqueur`; pas de nouvelle table sans cet inventaire |
| **RECH-UX** | Agent frontend UX : revisiter les **sept références** à l'aune des vraies captures Flutter et tokens, avec 4 revues critiques Produit / Sécurité / UX / Performance. | High-fi comparées et accord directeur ; aucun nouveau parcours métier inventé |
| **R1 Baseline** | Intégrateur DB, seul propriétaire des migrations communes : réconcilier Git/PROD, construire STAGING isolé sur données synthétiques. | Replay propre, copie neutre, aucune migration PROD, tests anti-PROD et schéma cohérent |
| **R2 Sécurité commune** | Agent sécurité + intégrateur : fermer écarts P0 BR0B sur les contrats utilisés, JWT/capabilities fraîches, vues/DEFINER, KYC/Contrôleur, grants, cache. | Tests négatifs sous identités applicatives synthétiques. Si échec, aucune activation du domaine en cause |
| **RECH-D1** | Binôme frontend/backend, **Classes et Supports** : même contrat DTO, endpoints sécurisés, recherche contextuelle + résultats partiels Flutter + index utiles. | Du vrai clic de loupe aux résultats SQL autorisés en staging ; p95 mesuré ; comparaison high-fi ; P0/P1 ciblés |
| **RECH-D2** | Binôme frontend/backend, **Familles/Élèves, RA exact**, après immatriculation autorisée et compatibilité ; préserver UUID et legacy. | Cross-foyer, famille second adulte, homonymes, recherche RA non énumérable, cache purge |
| **RECH-D3** | Binôme frontend/backend, **Enseignant, remplacement, pédagogie, Contrôle** selon capacités. | Mission expirée refuse, champ privé non matchable, pas de fuite roster / rapport |
| **RECH-D4** | Binôme frontend/backend, **Finance FI/CPT + Communications/Studio**, uniquement après contrats intégrés de ces modules. | Recherche des fils sans messages globaux ; texte interne au module ; pas de droit FI/CPT supplémentaire |
| **RECH-D5** | Intégrateur Flutter : accès universel aux domaines **réellement prêts**, desktop/tablette, Interface guidée, i18n, accessibilité, états et tests. | Aucun mode démo en production, routes/ports uniques, tous les formats testés |
| **RECH-REC** | QA séparé + sécurité/performance : REC-01..14, SEC-R01..22, tests flutter/routes, charge, données d'entrée adversariales, reprise après panne et continuité live. | Verdict par domaine : `spécifié`, `codé`, `test local`, `test staging`, `prêt à activer`, `bloqué` |
| **RECH-REL** | Release manager sous accord du directeur : candidate identifiée par SHA, plan rollback, monitoring/alertes, activation progressive par domaine. | Pas de migration ni déploiement PROD sans feu vert explicite sur cible et preuves |

**Coordination multi-agents :** chaque agent réserve ses fichiers, les ports/routes/fondations et migrations sont intégrés par un seul owner, pas de modification d'un worktree actif par autre agent. En cas de contrat partagé, ouvrir une proposition plutôt que dupliquer. Codex travaillant sur le site public : exclure sa branche/fichiers du présent chantier sans coordination.

---

### 15.1 Correspondance avec le plan R0-R7 du complément du 7 octobre

Pour que le chantier de recherche ne fasse pas disparaître les travaux communs de BR0B :

| Plan initial | Couverture V3 | Statut / garde |
|---|---|---|
| R0 Inventaire | `R0` | Toujours en premier, lecture seule, actualisation des SHA et des contrats |
| R1 Baseline / STAGING | `R1 Baseline` | Rejeu et vérification des environnements, **aucune PROD** |
| R2 Droits et identité | `R2 Sécurité commune` | Permissions fraîches, identité/foyers/appareils/cache, cas négatifs |
| R3 Matricules | Prérequis ciblé de `RECH-D2` | À coordonner avec le complément Immatriculation ; pas un nouveau registre local |
| R4 Recherche serveur | Backend de `RECH-D1` à `RECH-D4` | Projections, index, pagination, RLS, délai/quotas, availability par domaine |
| R5 Recherche frontend | Flutter dans `RECH-D1` à `RECH-D5` | Même verticale et DTO ; pas de deuxième lot de code séparé non raccordé |
| R6 Parcours métier restants | Dépendances de chaque `RECH-D*` | Ne pas coder à nouveau FI/CPT, COM, classes, livre ou contrôle ; brancher leurs vrais ports quand prêts |
| R7 Release / recette | `RECH-REC` + `RECH-REL` | Gates par domaine, canary/promotion avec accord du Directeur |

## 16. Gates finaux : sécurité, performance et UX avant activation

### Sécurité P0 (aucune tolérance)

- Foyer A ne retrouve aucun détail B par nom, RA, mot caché, compteur, suggestion, page suivante, cache, API directe ou fichier.
- Enseignant ne retrouve pas une fiche par mot privé financier, KYC ou note interne ; remplaçant expiré ne retrouve plus son ancienne Classe.
- Contrôleur n'accède pas au KYC ; Comptable n'obtient aucun cahier pédagogique privé ; second adulte ne gagne pas une action de recharge.
- Agent observateur ne profite pas du rôle de la personne observée.
- `logout → autre compte` et `espace tuteur → espace personnel` suppriment résultats, curseurs et requêtes en cours.
- Exact RA/EV borné, pas de résolution publique, anti-énumération ; JWT périmé après révocation, accès à URL/RPC/Storage restreint.
- Recherche commune n'explore jamais le contenu des messages ; module propriétaire uniquement dans fils autorisés ; effacement respecté.
- Aucune donnée secrète dans logs de requête, analytics, erreurs, crash, captures de test ou sorties d'agents.

### Performance et robustesse P1

- Entrée courte ne déclenche pas de scan ; une requête lente est stoppée/signalée et ne bloque pas les résultats des autres domaines.
- Pagination déterministe à curseur, aucun nombre total fictif, aucun double affichage, aucune réponse obsolète.
- Requêtes exactes et cas avec fautes pertinents FR/EN/Poular/arabe, Coran canonique préservé.
- p95 et p99 enregistrés avec profil réseau, taille de base et identités réelles de staging ; timeout client 3 s ne cache pas une requête SQL interminable.
- Recherche support pendant visio : connexion/média conservés, enseignant maître de la présentation.

### UX/UI et qualité

- Écran réel capturé au 390/768/1440 et stress 320 px, clair/sombre, titre DM Sans/Jakarta, contraste, zoom 200 %, clic depuis entrée réelle, retour, filtres, focus clavier.
- États `loading`, `empty`, `unavailable`, `forbidden`, `revoked`, `timeout`, `offline`, `pagination`, `partial` tous recettés ; **aucun faux succès**.
- 7 captures de référence, 7 captures Flutter et un rapport d'écarts (structure, interactions, textes, tokens). Dérogations validées avant intégration.
- Preuve de la même fonctionnalité unique accessible depuis plusieurs raccourcis, sans seconde copie.

**Une fonctionnalité n'est « terminée » que si l'utilisateur peut la joindre dans le build réel, que l'API serveur protège effectivement les données et que la recette montre la performance attendue.** Un écran de démonstration ou un port compilé mais jamais appelé ne constitue pas une livraison.

---

## 17. Registre des éléments non prouvés et dépendances extérieures

| Référence | Ce qui était observé/supposé | Ce que Claude doit prouver avant intervention |
|---|---|---|
| R0-DB | Le 07/10, STAGING sans tables applicatives et migrations PROD 0039-0042 absentes des arbres Git inspectés ; `0043` non appliquée PROD. | SHA courant, migrations appliquées, différences Git/PROD/STAGING, rollback, safe replay et verrou unique d'intégration. |
| R0-SEC | Plusieurs vues publiques sans `security_invoker`, fonctions `SECURITY DEFINER` à qualifier ; JWT historique et lecture KYC/Contrôleur identifiés en risque. | Corriger seulement avec preuve et contrôle des grants, vues, RPC/Edge/Storage, permissions actuelles et tests négatifs. |
| R0-ROLES | Certains rôles historiques ne reflètent pas la capacité du profil autonome ; Contrôle et Comptabilité ont des projections spéciales. | Vérifier matrices métier actuelles et routes. Pas de migration multirôle déduite d'une maquette. |
| R0-IMM | Code RA et code EV proposés dans un complément séparé ; legacy `immutable_id` en usage. | Ne créer aucune dépendance RA dans la première livraison Classes/Supports ; terminer R3 avant recherche RA réelle. |
| R0-COM | Ports de fils et de Studio définis, comportement serveur à raccorder. | Recherche des corps des messages seulement en COM/Studio, permissions, rétention et suppression prouvées. |
| R0-CPT | Question CPT-Q1, visibilité Direction sur Finance et délégations à vérifier contre décision actuelle. | Aucun affichage financier élargi sous prétexte de rôle admin ; test séparation des tâches. |
| R0-UX | Sept PNG sont des références **non validées**, certaines cartes peuvent différer de la navigation réelle. | Captures Flutter vraies et revues des placements par les high-fi et tokens gelés. |
| R0-QA | Aucune mesure SQL/API/perçue du nouveau moteur n'a été fournie pendant cette consolidation. | Benchmarks sous utilisateurs applicatifs sur staging, p50/p95/p99, précision, sécurité et route UI accessible depuis vraie navigation. |

Les décisions non retrouvées (politique de conservation des archives, filtres permis, publicité d'une évaluation, champs exacts Direction/CPT, accès des invités, langues effectivement activées, profondeur du passé accessible au remplaçant) doivent être recherchées **dans les sources en vigueur avant d'interroger le Directeur**. En attendant, ne pas exposer la catégorie ni inventer l'autorisation ; poursuivre les lots indépendants.

### 17.1 Jalons et jalons d'arrêt explicites

- **Gate A : INVENTORIÉ** - commit SHA, matrice complète `exigence → source → écran/port → DB/permission → test → état` et ownership par agent ; aucune hypothèse sur l'existant.
- **Gate B : PRÊT STAGING** - chaîne de migration rejouable, environnement isolé sans données réelles, fonds et permissions réconciliés, revue diff sécurité.
- **Gate C : DOMAINE INTÉGRÉ** - navigation Flutter réelle + source PostgreSQL autorisée + DTO liste blanche + états + erreurs + fermeture d'accès et tests négatifs.
- **Gate D : PERFORMANCE VALIDÉE** - p95/p99 et pertinence sous profils de charge/latence représentatifs, aucun spinner sans fin, résultats partiels prouvés ; écarts motivés et correction avant activation.
- **Gate E : RELEASE AUTORISABLE** - captures 390/768/1440 + 320 et texte ×2, tests Flutter et sécurité signés, observabilité, sauvegarde/rollback, approbation écrite sur cible exacte par le Directeur.

Ne pas dire « recherche terminée » en cas de seul écran, mock, widget test, port déclaré ou index créé. Statuts autorisés : `SPECIFIÉ`, `MAQUETTÉ`, `FRONTEND CODÉ`, `BACKEND CODÉ`, `TEST LOCAL`, `TEST STAGING`, `PRÊT À ACTIVER`, `BLOQUÉ`. Chaque domaine reçoit son statut propre et la preuve associée.

---

## 18. Prompt opérationnel unique pour Claude Code

> **MISSION RECH-03, source unique.** Implémente la Recherche transversale de Rewayah **frontend et backend ensemble**, par domaine, sans créer un moteur universel contenant des champs privés. Commence obligatoirement par R0 lecture seule : lis cette V3, BR0B V0.2, le complément Immatriculation, les contrats BR actuels et le design system gelé. Rafraîchis SHA, agents/worktrees, routes, ports, permissions, recherches existantes, migrations Git/PROD/STAGING et index. Livre le registre précis, puis répartis les agents sur des fichiers disjoints. Propose d'abord les maquettes vérifiées à partir des **vrais écrans Flutter** et du pack RECH-02 ; signale tout écart et fais valider. Sécurise corpus **ET CHAMPS MATCHABLES**, suggestions, compteurs, extraits, curseurs, télémétrie, cache et destination avant de demander une activation. Priorité d'intégration : Classes + Supports → Famille/élèves et RA après R3 → Enseignant/Contrôle → FI/CPT + Communications/Studio. Retours partiels par domaine sans attendre le plus lent, pas d'action d'écriture depuis un résultat. Respecte Messagerie/Studio dédié pour le corps des messages, forme canonique RA/EV et couverture FR/EN/arabe/Poular. Mesure SQL p95, API p95/p99 et ressenti, charge et pertinence, sur STAGING synthétique. Conserve vrais ports/routes et connexion LiveKit lorsque la recherche documentaire s'ouvre en classe. Les migrations sont sous intégrateur unique, **pas de migration/déploiement PROD, pas de merge `main`, pas d'accès réel sans accord écrit ciblé du Directeur**. Pour chaque lot, remets un tableau `source → fichiers → contrat → permissions → tests négatifs → mesures → captures → SHA → statut → blocages → étape suivante`, puis fais la contre-revue Produit/Sécurité/UX/Performance. Tu n'es pas autorisé à ignorer un contrôle sous prétexte du délai.

---

## 19. Revue critique et auto-contrôle

Quatre **revues de conception distinctes à exécuter par Claude et ses agents**, sans présenter un comité externe fictif :

| Revue | Questions de contrôle | Condition de sortie |
|---|---|---|
| Produit/pédagogie | Les résultats correspondent-ils à l'intention réelle du rôle ? Les classes, supports, Coran et messages respectent-ils leur propriétaire métier ? | Matrice usages/fonctions/routes, tests de pertinence par corpus, absence de doublon. |
| Sécurité/confidentialité | Un champ caché peut-il faire matcher un objet ? Une suggestion/compteur/cache/cursor dévoile-t-il un droit ? Les invités héritent-ils indûment d'un rôle ? | SEC-R01..22 + REC-01..14 pertinents, tests sous JWT anciens, accès refaits à l'ouverture. |
| Performance/scalabilité | La recherche dépend-elle d'un scan non borné ? Les domaines partiels répondent-ils ? Le p95 cache-t-il une file longue ? | Graphes et budgets complets, profils réseau/rôle, coût du plan SQL et limites documentés. |
| UX/accessibilité | Un enfant comprend-il « Trouver un support » ? Le focus est-il visible ? Vraie navigation 390/768/1440 ? | Captures réelles, comparaison 7 maquettes, RTL/LTR, lecteur d'écran, réduction mouvement, ×2 texte. |

**Contrôles quantitatifs de cette V3 :**
- 22 menaces `SEC-R01` à `SEC-R22` conservées.
- 14 recettes `REC-01` à `REC-14` conservées.
- 7 identifiants de maquettes `IMG-RECH-01-M` à `IMG-RECH-07-T` conservés.
- Matrices de rôle, de corpus, de ports, états UI, budgets chiffrés, indexations, sorties partielles, cache, contexte et rétention conservés.
- Décision frontend+backend intégrés explicite, **sans prétendre avoir exécuté le backend ni la migration**.
- Différences RECH-01/RECH-02/document du 07/10 présentées en §0.2 et non arbitrées silencieusement.

**Non prouvé par cette V3 :** sécurité effective des policies/RPC, code utilisé par le build, latences mesurées, état présent de STAGING/PROD et approbation des PNG. Claude doit en fournir les preuves réelles.

### 19.1 Références techniques pour contrôle Claude

- Supabase RLS : https://supabase.com/docs/guides/database/postgres/row-level-security
- PostgreSQL recherche : https://www.postgresql.org/docs/17/textsearch-indexes.html ; https://www.postgresql.org/docs/17/pgtrgm.html
- PostgreSQL gestion de requête : https://www.postgresql.org/docs/17/textsearch-controls.html
- OWASP API Security : https://owasp.org/API-Security/ ; https://cheatsheetseries.owasp.org/cheatsheets/Insecure_Direct_Object_Reference_Prevention_Cheat_Sheet.html
- Flutter responsive : https://docs.flutter.dev/ui/adaptive-responsive/large-screens
- WCAG 2.2 : https://www.w3.org/TR/WCAG22/

**FIN - REWAYAH RECH-03 V3.0.**

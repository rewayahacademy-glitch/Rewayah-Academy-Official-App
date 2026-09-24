# Rewayah - implémentation verticale du frontend Tuteur

Prompt d'exécution à transmettre à Claude Code avec les nouvelles maquettes high-fi.

## 1. Mandat immédiat

Tu es Claude Code, responsable de l'orchestration et de l'intégration dans le dépôt Flutter existant de Rewayah. Commence maintenant l'implémentation des nouveaux visuels du rôle Tuteur et des parcours qui y conduisent. Organise tes agents par parcours complets, avec un propriétaire unique par fichier.

Le gel qui empêchait de commencer le perfectionnement UI est levé pour ce périmètre. Cela n'autorise ni l'intégration d'une branche précédemment déclarée non conforme, ni une migration distante, ni une mise en production.

La démarche est verticale à l'intérieur du frontend : entrée du parcours, écrans principaux et secondaires, formulaires, routes, retours, validations locales, états et responsive. Il ne s'agit pas de produire cinq pages isolées ni de commencer maintenant un chantier backend.

Perfectionne l'existant. Refais seulement les parties absentes, trop mauvaises ou incompatibles avec les nouvelles maquettes. Ne réécris ni l'application, ni l'authentification, ni le routeur, ni le moteur de classe. Préserve les fonctions déjà utilisables.

## 2. Sources et arbitrage

Lis les instructions actives du dépôt et `docs/current/00_LIRE_D_ABORD.md`, puis les sources pertinentes `01_PRODUIT_ET_PARCOURS.md`, `02_ARCHITECTURE_ET_SECURITE.md`, `03_DESIGN_SYSTEM_ET_UX.md`, `06_SPEC_FONCTIONNELLE_MVP.md`. Consulte `04` pour la coordination Git et `07` pour les contenus utiles, sans lancer les moteurs avancés. Recherche les décisions canoniques plus récentes, notamment Classes V2 et onboarding. Les documents académiques et Teaching Core servent à retrouver un détail métier manquant, pas à relancer leurs anciens chantiers multi-agents.

Ordre d'arbitrage pour ce lot :

1. Demande explicite actuelle du directeur, dont ce prompt formalise le périmètre.
2. Sécurité et contrats d'accès existants, qui ne peuvent être affaiblis pour reproduire une image.
3. Nouvelles maquettes high-fi fournies par le directeur pour le rendu visuel.
4. Décisions métier canoniques les plus récentes pour le contenu et les comportements.
5. Bible frontend V2, tokens et composants existants pour l'exécution cohérente.
6. Anciennes captures et documents historiques, uniquement comme contexte identifié.

Une maquette peut omettre une fonction, contenir du faux texte, une ancienne appellation, une date incohérente ou un questionnaire incomplet. Reproduis son langage visuel, pas ses erreurs métier. Complète les contenus avec le code et les specs applicables en conservant son style.

Si le code contredit une décision explicite, le code n'a pas raison par défaut. Corrige la présentation et la logique frontend quand le contrat existant le permet. Si la correction exige le backend, isole cette dépendance et continue les autres travaux. Ne tranche pas silencieusement une contradiction métier non résolue.

### Références visuelles : obligation de lecture réelle

Construis un manifeste court : fichier exact, écran représenté, état, thème, format, statut « nouveau high-fi » ou « ancienne capture ». Ouvre effectivement chaque image. Ne prétends pas l'avoir inspectée si elle est inaccessible ; demande uniquement le fichier manquant et poursuis les parties indépendantes.

Les pièces historiques nommées `Accueil.png`, `Foyer Member.png`, `Historique.png`, `Classe Details.png`, `Profil.png` ne deviennent pas automatiquement les nouvelles références approuvées. Les nouvelles images jointes par le directeur les remplacent pour le visuel correspondant. Attention : dans les captures historiques, `Profil.png` représente la fiche d'une élève, pas le compte personnel du tuteur. Le nom du fichier ne suffit pas à déterminer sa route.

La planche de direction onboarding est un design system visuel ; les écrans high-fi qui en découlent sont les références de composition. Ne transforme pas toute la planche en écran utilisateur.

Pour chaque écran de référence, relève : composition, ordre des sections, alignements, proportions, typographie, palette, densité, surfaces, iconographie, rayons, CTA, navigation, états. Centralise les valeurs dans les tokens. Ne remplace pas les maquettes par un dashboard Flutter générique ou une mosaïque de cartes. N'utilise jamais une capture aplatie comme interface interactive.

À taille et thème comparables, produis une capture de l'implémentation et compare-la à l'image source. Corrige les écarts visibles avant de déclarer l'écran conforme. Pour un écran absent des maquettes, dérive sa composition des composants approuvés et consigne la référence utilisée. L'absence de maquette ne permet pas d'inventer une nouvelle direction artistique.

## 3. Frontière frontend / backend

Autorisé : widgets, thème, assets, routes et guards existants consommés correctement, états de présentation, formulaires, validation locale, accessibilité, caméra et décodage QR côté appareil, permissions plateforme, branchement aux services déjà disponibles, tests frontend, jeux de données de démonstration isolés.

Hors périmètre : migrations SQL, tables, RLS, RPC, Edge Functions, émission de tokens, politiques serveur, finance, stockage R2, webhooks et logique LiveKit centrale. Pas de modification opportuniste du backend pour débloquer une page.

Réutilise les contrats réels et les services existants. Pour une capacité absente, crée seulement le port/adaptateur frontend nécessaire avec une signature fondée sur les besoins identifiés. Les fixtures restent dans les tests ou un environnement de démonstration explicitement isolé, jamais comme fallback silencieux de production. Une action sans backend disponible affiche un état indisponible compréhensible, jamais un faux succès.

Distingue dans la livraison : « UI réalisée », « branchée au service existant », « testée en simulation », « vérifiée réellement », « dépendance backend ». Un écran terminé n'atteste pas un parcours métier opérationnel.

## 4. Arbre cible et routes

Les chemins ci-dessous sont des noms logiques de référence. Commence par les mapper aux routes existantes et conserve leurs identifiants lorsque possible. Un alias ou une redirection vaut mieux qu'une deuxième route concurrente. Les routes sensibles ne transportent jamais de secret dans l'URL.

Navigation principale cible : **Accueil · Foyer · Historique · Compte**. Même ordre et mêmes destinations partout. Les anciennes captures à trois destinations ne justifient pas une navigation variable. Si les nouveaux high-fi approuvés prescrivent explicitement un autre shell global, conserve leur shell cohérent et garde toutes les destinations accessibles.

| Parent | Destination / titre utilisateur | Route logique | Contenu ou sorties |
|---|---|---|---|
| Public | Bienvenue | `/bienvenue` | Commencer, connexion existante |
| Public | Connexion | `/connexion` | Connexion, récupération, accès appareil élève |
| Public | Récupérer mon accès | `/recuperation` | Saisie, attente, retour, lien expiré selon auth existante |
| Admission | Votre compte | `/inscription` | Auth et consentements requis, sans double création |
| Admission | Pour qui souhaitez-vous utiliser Rewayah ? | `/onboarding/usage` | Usage personnel ou familial | sans oublier inscription enseignant | formulaire KYC et consentement trop bizarre avec beaucoup de CTA et trop de rectangles les uns sur les autres (à banir).
| Admission | Questionnaire | `/onboarding/...` | Identité, élève(s), langue, objectif, niveau et branches existantes |
| Admission | Récapitulatif | `/onboarding/recapitulatif` | Modifier, confirmer, état de dossier, prochaine action réelle |
| Accueil | Accueil | `/tuteur/accueil` | Élève sélectionné, prochaine séance, préparation, dernière séance |
| Transversal | Notifications | `/tuteur/notifications` | Liste, détail, destination liée |
| Foyer | Foyer | `/tuteur/foyer` | Membres, ajout, appareils partagés |
| Foyer | Ajouter un profil élève | `/tuteur/foyer/ajouter` | Pour moi / pour un enfant ou proche autorisé |
| Foyer | Prénom de l'élève | `/tuteur/foyer/:eleveId` | Identité, classe, accès, préférences autorisées, appareils |
| Fiche élève | Informations de l'élève | `.../informations` | Identité, date de naissance, photo, champs permis |
| Fiche élève | Parcours et inscription | `.../inscription` | Questionnaire repris, dossier, choix de classe, attente |
| Fiche élève | Interface | `.../interface` | Interface guidée / standard selon politique |
| Fiche élève | Caméra en cours | `.../camera` | Autorisation métier existante, distincte du scanner QR |
| Fiche élève | Accès Rewayah | `.../acces` | Statut, dates, motif utile, action autorisée |
| Fiche élève | Appareils | `.../appareils` | Appareils associés, connexion, retrait autorisé |
| Foyer | Appareils du foyer | `/tuteur/foyer/appareils` | Appareil partagé, profils autorisés, gestion |
| Appareils | Connecter un appareil | `/appareils/connexion` | Émetteur QR/code ou scanner selon protocole existant |
| Appareils | Scanner le QR code | `/appareils/scanner` | Caméra réelle, saisie manuelle alternative |
| Appareils | Saisir le code | `/appareils/code` | Code, validation, erreurs, confirmation |
| Appareil élève | Choisir mon profil | `/appareil/profils` | Profils autorisés et PIN si prévu |
| Appareil élève | Entrer mon code PIN | `/appareil/pin` | Vérification existante, récupération assistée |
| Inscription | Choisir une classe | `/tuteur/classes/catalogue` | Catalogue réel, détails, sélection, confirmation/attente |
| Accueil / élève | Nom de la classe | `/tuteur/classes/:classeId` | Élève concerné, enseignant, séance, planning, travail, ressources |
| Classe | Planning | `.../planning` | Séances datées, exceptions, fuseau local |
| Classe | Travail à préparer | `.../travail` | Consignes, détails, supports et statuts existants |
| Classe | Bibliothèque | `.../ressources` | Ressources autorisées et lecteur existant |
| Classe / élève | Progression | `.../progression` | Progrès et observations partageables |
| Classe | Observer la séance | `.../observer` | Vue tuteur bornée, entrée et sortie existantes |
| Historique | Historique | `/tuteur/historique` | Élève, classe, période, statut, séances |
| Historique | Détail de la séance | `/tuteur/seances/:seanceId` | Présence, horaires, résumé, travail et incident utile |
| Compte | Mon compte | `/tuteur/compte` | Identité du titulaire et rubriques ci-dessous |
| Compte | Informations personnelles | `.../informations` | Identité et coordonnées autorisées |
| Compte | Connexion et sécurité | `.../securite` | Méthodes existantes, mot de passe, sessions, déconnexion |
| Compte | Abonnement et accès | `.../acces` | Bénéficiaires, accès et échéances réels |
| Compte | Paiements | `.../paiements` | Historique réel, détail, justificatif disponible |
| Compte | Préférences | `.../preferences` | Langue, apparence, fuseau, notifications selon contrats |
| Compte | Aide et support | `.../aide` | Aide, contact disponible, suivi si existant |
| Compte | Informations légales | `.../informations-legales` | Documents réellement disponibles |
| Transversal | Page introuvable / accès impossible | Route de fallback | 404, accès refusé, session expirée, ressource indisponible |

Cette arborescence consolide les besoins du présent mandat. Vérifie les sous-fonctions dans les specs et le dépôt : elle n'autorise pas à créer des règles métier ou permissions nouvelles. Les notifications/messages renvoient aux modules existants ; ne crée pas une nouvelle messagerie. Une fonction prévue mais sans service reçoit son écran frontend honnête et sa dépendance documentée.

Conserve sélection d'élève, filtres, brouillons non sensibles et position de retour quand approprié. Sur web : retour/avance, refresh et liens directs autorisés. La salle éphémère et les secrets d'association ne deviennent pas des liens publics. Un identifiant de route ne vaut jamais une autorisation. Un lien profond inexistant ne doit pas crasher.

## 5. Contenu et emplacement par écran principal

### Accueil

Ordre de lecture : titre et notifications ; sélecteur des profils élèves ; prochaine séance du profil sélectionné ; éventuelle action bloquante ; préparation ; résumé de dernière séance.

- Sélecteur : prénom, portrait/fallback, état réel compréhensible. Inclure le propre profil du parent s'il existe, sans l'appeler « enfant ». Un changement de profil met à jour tous les blocs concernés.
- Bloc classe : nom de classe, parcours/niveau compréhensible, nom ET photo publique de l'enseignant, titre Sayyid/Sayyida. Ne confonds pas portrait élève et photo enseignant.
- Séance : jour, date, heure locale et fuseau utile, durée effective. Jour J : « Cours dans 3 h 28 » ; ouverture selon fenêtre existante/configurable, généralement T-20 ; séance prolongée : « Cours toujours en cours », jamais compteur négatif.
- CTA principal : « Voir la classe ». L'observation se fait dans la classe selon autorisation. Le tuteur qui veut étudier passe par son propre espace élève, pas par un privilège tuteur.
- Blocage utile : photo requise, dossier à compléter ou appareil non prêt, seulement si confirmé par les données. Action unique contextualisée.
- « Avant le prochain cours » : jusqu'à trois actions visibles, lien vers le travail complet. Marquer fait ne signifie pas compétence acquise.
- « Dernière séance » : date, présence confirmée, résumé ; lien Historique. N'affiche « réseau bon » que si une donnée réelle l'établit. Aucune absence déduite d'une simple déconnexion.
- Vide : première inscription ou ajout de profil, pas une fausse classe. Ne duplique pas toutes les fonctions du Foyer sur cet écran.

### Foyer

Titre « Foyer », description courte si utile. Action « Ajouter un profil élève ». Liste des membres avec identité, classe ou inscription en cours, état d'accès et appareils si utile. Évite les compteurs décoratifs et les CTA doublons. Utilise lignes ou surfaces sobres selon le high-fi.

Un parent sans profil élève reste un titulaire du compte, pas un élève fictif. Affiche l'option discrète « Créer mon profil élève » tant que ce profil n'existe pas ; après création, afficher son profil réel et « Ouvrir mon espace élève » selon accès.

Appareils partagés : nom, profils autorisés et lien de gestion. Les limites d'appareils viennent du contrat, pas du « 1/2 » d'une capture. Une restriction de retrait pendant la séance n'est appliquée que si elle existe dans la politique.

Les disponibilités éventuelles ne réintroduisent pas le matching individuel abandonné : inscription courante par classes précréées. Ne confonds pas disponibilité horaire d'un appareil et disponibilité pour suivre des cours.

### Fiche d'un élève

En-tête : prénom, photo, âge si disponible et utile, classe ou état d'inscription. Puis lignes regroupées : informations, parcours/classe, interface, caméra en cours, accès, appareils. Les données pédagogiques renvoient aux vues dédiées plutôt qu'à une immense fiche.

Photo : sélection, aperçu, upload existant, progression, échec/reprise ; ne mélange pas portrait et pièce d'identité. Respecte les règles réelles de photo avant première visio, sans inventer une nouvelle obligation KYC.

Interface guidée : libellé neutre, accessible également aux adultes. Reprends la politique canonique actuelle, dont demande de standard à partir de 10 ans et activation par le tuteur si confirmées dans le dépôt. Une préférence affichée ne contourne pas le serveur. Ne crée pas de bascule locale permettant d'élever les droits.

Les proches adultes ne sont pas automatiquement des mineurs sous tutelle : vérifie les liens, consentements et droits déjà définis. Ne permets pas au titulaire de consulter ou modifier leurs données au-delà des droits réels.

### Classe

En-tête : nom de classe et élève concerné. Zone principale : enseignant avec photo, parcours, prochaine séance et action contextuelle. Puis planning habituel, exceptions datées, préparation, ressources, progression et historique accessibles sans empilement de cartes imbriquées.

Planning : tous les jours récurrents de la classe, même enseignant permanent, heure locale, durée. La conversion dépend des dates et fuseaux IANA ; aucun décalage UTC fixe. Classe annulée/reportée, absence d'enseignant et remplacement ne se présentent pas comme un cours normal.

Observation : « Observer la séance », durée disponible et motif d'indisponibilité si nécessaire. Politique serveur par classe ; référence historique 1 visite et 120 secondes cumulées, pas des constantes frontend. Aucun micro/caméra ni publication ; pas de roster privé. Affiche temps restant et fin de visite, respecte la sortie existante. Sans garantie serveur disponible, ne rends pas l'observation réelle accessible par simulation.

Catalogue : afficher parcours, public/niveau, langue, enseignant, toutes les séances hebdomadaires, durée, fuseau et places réelles. Confirmer la même classe et le même enseignant sur la semaine. Prévoir aucune classe compatible, liste d'attente existante, dernière place perdue et confirmation refusée. Ne crée aucune réservation locale mensongère.

### Historique et détail de séance

Titre, sélecteur élève, filtres proches de la liste : classe, période, statut. Lignes lisibles avec date, horaire, classe, enseignant, présence/retard validé. La qualité réseau est secondaire et uniquement disponible si mesurée.

Détail : identité de la séance, présence et durée pertinentes, résumé destiné à la famille, travail et ressources autorisés. Distingue durée du cours et temps connecté si tous deux existent. État « En cours de vérification » pour preuve ambiguë. Ne livre jamais notes internes, coordonnées privées ou télémétrie brute.

### Mon compte

Le compte concerne le titulaire ; la fiche élève concerne l'apprentissage. Le tuteur peut être titulaire sans étudier.

Ordre : identité et modification ; abonnement/accès ; paiements ; connexion et sécurité ; informations personnelles ; préférences ; accès au foyer ; aide et support ; informations légales ; déconnexion clairement séparée. Adapte l'ordre exact au nouveau high-fi approuvé tout en conservant ces destinations.

Chaque rubrique est une ligne ou un groupe sobre avec résumé utile. Pas un catalogue de grandes cartes. Le raccourci Foyer mène au Foyer existant. « Créer mon profil élève » reste possible ici aussi, mais ouvre le même flux.

Paiements et accès : affiche uniquement montants, devises, statuts et dates fournis. Accès offert, accès daté et paiement externe validé ne deviennent pas automatiquement un abonnement récurrent. N'ajoute pas un prestataire, des tarifs fixes ou un faux paiement réussi. Les actions financières absentes du service sont indisponibles proprement.

## 6. Onboarding complet, même quand les maquettes sont partielles

Inventorie d'abord le questionnaire actuel : questions, branchements, champs obligatoires, consentements, reprise et sorties. Rapproche chaque étape du code et des specs. Complète les étapes manquantes dans le langage visuel high-fi ; ne raccourcis pas le questionnaire au seul nombre d'images fournies.

### Choix d'usage : décision explicite du directeur

Garde de préférence deux choix et clarifie leur description. Texte conseillé :

- **Moi uniquement** : « Je souhaite suivre les cours avec mon propre profil élève. »
- **Moi et ma famille** : « Inscrivez vos enfants ou vos proches, avec ou sans vous. Vous pourrez créer votre propre profil élève à tout moment. »

Ne crée pas un troisième choix « Mes enfants uniquement » par défaut : la description lève l'ambiguïté. Si le high-fi utilise un titre légèrement différent, conserve la composition et assure exactement cette compréhension.

Choisir l'usage familial ne crée PAS automatiquement un profil élève pour le parent et ne l'oblige pas à choisir un cours, un niveau ou à payer pour lui-même. Le compte gestionnaire existe séparément des profils élèves.

Des années plus tard, le parent doit pouvoir choisir « Créer mon profil élève » dans Foyer ou Compte, compléter son propre parcours et rejoindre une classe. Même compte, même foyer, historique des enfants conservé, aucun doublon de titulaire. Le choix initial n'est pas un verrou permanent. L'adulte initialement seul peut accéder à l'ajout de proches si le modèle de droits existant le permet.

### Complétude et branches

- Réutiliser identité et coordonnées déjà connues, ne pas les redemander sans raison.
- Déterminer pour qui chaque question est posée : titulaire ou élève nommé. Afficher ce prénom dans le contexte lorsqu'il y a plusieurs élèves.
- Reprendre les questions de langue, objectif, lecture de l'arabe/Coran, mémorisation et expérience prévues, uniquement dans leurs branches utiles. Aucun code académique interne à l'écran.
- Débutant déclaré : appliquer la dernière décision canonique de parcours débutant direct et de suppression du diagnostic inutile ; vérifier notamment les décisions Classes V2 plus récentes que les anciens documents. Non-débutant : pré-diagnostic court et décision pédagogique selon le processus existant. Ne transformer aucune autodéclaration en certification.
- Les cohortes et dates de naissance suivent la politique actuelle, notamment 6-9, 10-13, 14-17, 18+ si confirmée par les décisions en vigueur. Prévoir anniversaire pendant le flux, âge manquant, borne et politique non disponible ; ne pas deviner un âge.
- Préserver consentements et pièces réellement requis. Si dépôt et specs se contredisent, consigner la source, la correction frontend et l'éventuelle dépendance serveur.
- Choix de classe avec toutes les séances ; pas de disponibilités libres qui promettent un enseignant différent chaque jour.
- Retour sans perte, progression adaptée aux branches, erreurs sous les champs, correction depuis le récapitulatif, double soumission empêchée, reprise selon mécanisme existant. Aucun stockage persistant nouveau de secrets ou pièces sensibles.

Recette obligatoire : parent inscrivant seulement un enfant ; parent ajoutant plusieurs enfants ; parent et enfant élèves ; adulte seul ; parent ajoutant son profil après une longue période ; profil personnel déjà existant ; débutant ; non-débutant ; reprise interrompue. Ne force pas un parent sans profil élève à répondre aux questions pédagogiques pour lui-même.

## 7. Connexion des appareils : parcours complet des deux côtés

Avant de coder, trace le protocole existant : appareil affichant le QR, appareil qui scanne, utilisateur authentifié, sélection de l'élève, validation serveur et résultat de chaque côté. Ne suppose pas le sens du scan. Conserve ce sens s'il est sûr ; nomme les instructions « Sur l'autre appareil » avec une explication contextualisée.

### Écran affichant le QR et le code

L'écran actuel constitue une base à améliorer, pas à remplacer systématiquement. Grand QR central lisible, fond contrasté, marges libres de scan, code manuel lisible, consigne courte, état textuel et durée de validité réelle si disponible. Taille adaptative avec QR prioritaire, sans débordement ni décoration sur ses modules.

Un léger halo extérieur ou indicateur d'attente peut signaler l'activité. Prévoir apparition douce, changement de code, validation et disparition. Respecter mouvement réduit, contraste et performance. Aucun effet qui empêche le scan.

États : préparation ; actif ; validation en cours ; association confirmée ; expiré ; révoqué ; erreur ; réseau interrompu. Dès confirmation valide de l'association par le service autoritatif, retirer immédiatement QR ET code de l'écran, de l'arbre sémantique et des états restaurables. Puis afficher « Appareil connecté » avec destination utile. Ne laisse pas le code derrière un panneau de succès.

Un simple décodage caméra ne prouve pas une association réussie. Pendant validation, masquer/neutraliser la présentation si prévu par le protocole ; ne déclarer le code consommé qu'après réponse autoritative. Après expiration ou révocation confirmée, aucun code utilisable ne reste affiché. À la reprise de l'app, vérifier le statut avant de réafficher ; ne pas restaurer un ancien QR depuis un cache.

Invalider réellement un code, empêcher son rejeu, borner sa durée et l'associer au bon foyer exigent le serveur. Audite la capacité existante sans modifier le backend. Si elle manque, documente le contrat nécessaire et empêche une association réelle présentée comme sûre. Le frontend ne doit jamais prétendre garantir l'usage unique par une simple animation.

### Écran scanner

Implémente effectivement l'accès caméra et le décodage QR, en utilisant une dépendance déjà compatible ou une dépendance justifiée intégrée par le coordinateur. Une illustration de caméra n'est pas une fonctionnalité.

Mobile : vraie page de scan, viseur suffisamment grand, retour accessible et « Saisir le code » en alternative. Desktop/tablette : page centrée ou panneau adapté, aperçu vidéo confortable. Aucun bottom sheet mobile étiré sur desktop.

Demander la permission au moment d'ouvrir la caméra. Prévoir caméra absente, refus, refus durable, caméra occupée, erreur de démarrage, contexte web ne permettant pas la caméra, sélection de caméra si nécessaire. La saisie manuelle reste accessible. Ne pas confondre permission caméra pour scanner et droit d'activer la caméra de l'élève en cours.

Après lecture : suspendre les lectures répétées, valider le format attendu, ne jamais ouvrir une URL arbitraire contenue dans un QR, appeler le service existant, montrer progression puis succès réel ou erreur. QR inconnu, expiré, déjà utilisé, révoqué ou mauvais foyer : message simple et reprise possible. Ne pas révéler les données d'un autre foyer.

Arrêter/libérer la caméra à la sortie, à la mise en arrière-plan et après traitement selon cycle de vie. Gérer reprise, requêtes tardives après navigation, scans concurrents, rotation du code et reconnexion sans double association. Aucun token dans les logs, URLs, analytics ou captures de recette.

### Après association

Mettre à jour les appareils via source existante ; retour vers l'élève concerné. Appareil partagé : choix parmi profils autorisés puis PIN selon protocole existant, sans accès au compte tuteur. Retrait avec confirmation et réponse du service ; ne pas faire croire à une révocation distante sur suppression locale seulement.

## 8. États système et erreurs

Construis une famille visuelle commune, déclinée au bon endroit : erreur de bloc conserve le reste de la page ; erreur globale occupe la page. Un titre humain, une phrase utile, une action principale, éventuellement un lien secondaire. Pas de code technique exposé.

| État | Présentation et reprise |
|---|---|
| Chargement initial | Skeleton adapté ou progression ; aucune fausse donnée métier |
| Chargement prolongé | « La connexion prend plus de temps que prévu » ; réessayer ou revenir selon contexte |
| Hors ligne | « Vous êtes hors ligne » ; contenu en cache identifié si autorisé, action de reprise |
| Reconnexion | État discret, progression bornée, pas de boucle infinie ni multiplication des requêtes |
| Échec serveur | « Impossible de charger… » ; réessayer en conservant le contexte |
| 404 | « Cette page est introuvable » ; retour à l'accueil ou connexion selon session |
| Accès refusé | « Vous n'avez pas accès à cette page » ; retour sûr, sans fuite de données |
| Session expirée | Reconnexion avec retour vers la destination autorisée, sans boucle |
| Dossier en attente / suspendu | Statut exact et prochaine action permise, pas un écran vide |
| Aucun résultat / aucun cours | Explication pertinente, réinitialisation des filtres ou action d'inscription |
| Permission refusée | Explication contextuelle et alternative, notamment code manuel |
| Ressource supprimée / expirée | Message et retour contextualisé ; aucune page qui tourne indéfiniment |

Les seuils de timeout proviennent de la politique réseau du projet ou d'une configuration frontend centralisée explicitement documentée. Une tentative échouée ne devient jamais un succès. Annuler les opérations à la sortie et empêcher leur réponse tardive de rouvrir un écran.

## 9. Règles visuelles transversales

- Un objectif et un CTA dominant par écran/étape, actions secondaires discrètes mais accessibles.
- Moins de cartes imbriquées ; listes, séparateurs, espaces et typographie pour structurer selon high-fi.
- M3 et adaptation iOS pertinente ; pas de remplacement de la direction fournie par le thème Flutter par défaut.
- Tokens sémantiques, composants réutilisés, aucun style arbitraire répété dans les écrans.
- Clair/sombre complets. Si une seule variante est fournie, dériver l'autre sans inverser naïvement toutes les couleurs et documenter cette dérivation.
- Mise en page selon espace disponible : mobile, tablette, desktop ; navigation persistante adaptée, largeur de lecture raisonnable. Préserver clavier et scroll quand un champ prend le focus.
- Cibles tactiles au moins 48 dp, focus visible, lecteur d'écran, texte agrandi sans coupure, RTL pour les contenus concernés et formats locaux. Ne pas encoder un statut seulement par couleur.
- Animations discrètes, désactivables/réduites ; aucune animation ne remplace le texte d'un état.
- Employer Classe, Sayyid, Sayyida, Interface guidée. Pas de jargon interne, de codes de compétences ou de « mode enfant ».
- Noms, tarifs, photos, dates, capacités et métriques illustratifs des maquettes ne deviennent jamais des constantes métier.

## 10. Orchestration demandée à Claude

### Lot 0 : coordinateur, avant délégation d'écriture

Inspecte branche, état Git, agents actifs et instructions locales. Identifie la base réellement utilisable, sans reprendre aveuglément un ancien hash. Réserve les fichiers des autres chantiers. Aucun reset, stash du travail d'autrui ou écrasement.

Produis un dossier de pilotage compact avec :

- mapping existant -> cible des routes et fonctionnalités ;
- manifeste des high-fi et composants/tokens ;
- ownership de fichiers exacts ;
- interfaces consommées, fixtures isolées et dépendances backend ;
- tableau des contradictions et recette.

Le coordinateur possède seul le routeur global, le shell, le thème partagé, les exports communs, le point d'injection, les dépendances et les configurations caméra plateforme. Il prépare les composants et contrats partagés nécessaires avant la phase parallèle. Les agents métier soumettent une demande courte s'ils ont besoin d'un changement partagé.

### Lots délégués

| Agent | Parcours à livrer | Frontière |
|---|---|---|
| A - Admission | Auth visuelle et onboarding complet, branches, récapitulatif, reprise | Utilise le flux commun d'ajout d'élève, sans doublon |
| B - Foyer | Foyer, fiche élève, ajout personnel/proche, paramètres élève autorisés | Possède le formulaire élève partagé avec A après contrat stable |
| C - Cours | Accueil, classe, catalogue, planning, travail, ressources/progression, observation UI | Réutilise les services de classe/LiveKit existants |
| D - Appareils | Émetteur QR/code, scanner caméra, saisie, succès/erreurs, appareils partagés/PIN | Coordinateur seul pour dépendances/config globale |
| E - Compte et suivi | Mon compte et sous-pages, Historique et détail, notifications/support existants | Utilise les composants et services partagés |
| Q - Revue indépendante | Fidélité high-fi, parcours/routes, responsive/accessibilité, frontière sécurité | Lecture du code de production, défauts confiés au propriétaire |

Adapter le nombre d'agents aux capacités réelles ; les lots peuvent être séquencés. Aucun agent imaginaire ni validation de comité inventée. Q peut mener séparément les revues spécialisées UX/UI, navigation/accessibilité et appareil/sécurité ; préciser preuves et limites de chaque revue.

Un fichier = un propriétaire. Chaque agent reçoit : mandat, fichiers autorisés, références exactes, interfaces, sorties et critères de recette. Worktrees/branches isolés si adaptés au dépôt. L'agent ne modifie pas les fichiers partagés pour se débloquer. Pas de dépendances circulaires entre lots : stabiliser d'abord le formulaire élève, le contexte de sélection, les modèles de séance et les composants d'état.

Chaque lot livre un parcours navigable avec ses sous-écrans et erreurs. Le coordinateur intègre progressivement, vérifie routes et régressions, puis poursuit. Il ne redessine pas les contributions conformes lors de l'intégration. Pas de demande de validation à chaque détail réversible ; remonter uniquement les ambiguïtés qui changent réellement le produit ou une action externe non autorisée.

## 11. Recette et preuves exigées

La recette couvre tous les écrans de l'arbre, pas uniquement les cinq principaux. Tenir une matrice avec référence visuelle, route réelle, contenu, états, responsive, service, preuve et statut.

1. Toutes les destinations et CTA visibles conduisent au bon écran, état ou résultat réel. Aucun bouton décoratif, route orpheline, `TODO` maquillé ou impasse.
2. Parcours : inscription familiale sans parent élève -> ajout enfant -> choix classe -> accueil -> classe -> travail/historique ; puis création ultérieure du propre profil du parent sans altération des enfants.
3. Appareils : caméra réelle lorsque plateforme testable, alternative manuelle, expiration, scan invalide, double scan, succès confirmé, disparition immédiate QR/code, reprise après arrière-plan et retrait. Séparer preuve frontend simulée et association serveur réelle.
4. Navigation : changement de profil sans données croisées, retour stable, refresh web, liens directs autorisés, 404, accès refusé, session expirée.
5. États temporels : avant ouverture, T-20 selon politique, début, en cours, prolongation, fin, report/annulation, changement de fuseau et DST.
6. Fidélité : comparaison image source/capture à viewport identique pour chaque high-fi. Les golden tests ne suffisent pas à prouver la fidélité s'ils ont été générés depuis une UI incorrecte.
7. Responsive : petit mobile, mobile courant, tablette, desktop ; clair/sombre, texte agrandi, clavier, permissions refusées, réseau lent/coupé. Images QA sans secrets ni données personnelles réelles.
8. Exécuter analyse Flutter, tests significatifs ciblés puis builds accessibles des plateformes concernées. Mentionner iOS ou appareil physique non testable si environnement indisponible, jamais inventer PASS.
9. Vérifier que le diff n'introduit aucune modification backend et aucune régression des autres rôles via thème/routeur partagés. Les modifications globales restent limitées et justifiées.

Une simulation démontre un état frontend, pas l'autorisation serveur. Le retrait visuel du QR ne prouve pas l'invalidation. Un build réussi ne prouve pas le parcours caméra. Mentionne ces distinctions dans le bilan, sans bloquer les livrables indépendants.

## 12. Livraison et fin de mission

Livre le code sur la branche de travail autorisée, les captures comparatives, la matrice écrans/routes et une liste précise des dépendances backend restantes avec service attendu, entrée/sortie et impact. Pas de merge main, déploiement, migration distante ou nettoyage irréversible sans autorisation spécifique.

Rapport au directeur, bref : écrans/parcours réalisés ; conformité aux high-fi et écarts résiduels ; fonctions réellement branchées ; tests réellement exécutés ; blocages restants. Ne déclare pas « rôle tuteur terminé » si des sous-écrans du périmètre sont oubliés ou si une dépendance simulée est présentée comme fonctionnelle.

Commence par l'inventaire et le mapping, puis exécute les lots frontend autorisés. Ne t'arrête pas après avoir seulement rédigé un plan.



##Prompt étape obeservation tuteur:

Tu poursuis le chantier frontend Tuteur de Rewayah. Ce complément ajoute le parcours Observation aux lots déjà préparés et corrige certaines instructions précédentes. Intègre-le au plan commun, puis commence l’exécution. Ne recrée pas un chantier concurrent.

**1. Priorité absolue : mettre à jour les jetons de design avant les écrans**

La typographie officielle est :

* **DM Sans pour les titres en français** : titres de page, de section et autres styles de titres.
* **Jakarta pour les autres textes** : paragraphes, libellés, boutons, champs, navigation, légendes et statuts.

Jakarta est déjà déclarée dans les jetons : retrouve son nom technique exact et conserve cette déclaration. N’ajoute pas une seconde famille équivalente.

Inspecte les assets et le thème existants, puis corrige les styles sémantiques centralisés. Les widgets doivent consommer les jetons, sans `fontFamily` dispersé dans les pages. Préserve les polices dédiées à l’arabe et au Coran.

Vérifie les graisses disponibles, les accents français, le redimensionnement du texte et les thèmes clair/sombre. Ne réinitialise pas les autres jetons déjà conformes aux maquettes.

Le coordinateur est seul propriétaire de cette modification partagée. Il stabilise les jetons avant l’implémentation visuelle parallèle, puis contrôle leurs conséquences sur les autres rôles.

**2. Sources visuelles et corrections prioritaires**

Les trois planches jointes couvrent :

1. Parcours mobile et consentement.
2. Observation sur ordinateur et historique.
3. États particuliers et notices de présence.

Ouvre réellement les images et utilise fidèlement leurs compositions, composants et proportions. Complète les états absents avec le même langage visuel.

Les règles écrites ci-dessous prévalent sur les erreurs ou raccourcis éventuels des images :

* Le libellé **« Cours en cours » est interdit**. Employer « Séance en direct », « En direct » ou « En séance » selon le contexte.
* Deux visites maximum par séance, de deux minutes maximum chacune, par défaut.
* Aucun compteur illustratif, nom, date ou quota ne devient une constante métier.
* La typographie doit respecter DM Sans/Jakarta, même si une image générée semble employer une autre police.
* Les commandes montrées côté enfant ou enseignant ne sont jamais celles du tuteur observateur. Ces vignettes ne constituent pas un mandat de reconstruire leurs salles.

**3. Périmètre : frontend uniquement**

Conserve la frontière du prompt principal : UI, navigation, états, caméra déjà prévue dans les autres lots, adaptateurs et consommation des services existants.

Aucune migration, modification RLS/RPC, émission de token, nouvelle politique serveur ou refonte LiveKit dans ce lot.

Inspecte les capacités existantes. Si une règle ci-dessous exige une évolution backend absente, documente précisément cette dépendance. Réalise et teste les états frontend avec des fixtures isolées, mais n’active pas une fonctionnalité réelle avec une protection uniquement locale.

**4. Règles d’observation à remplacer dans les instructions actives**

La règle précédente « une visite et 120 secondes cumulées » est obsolète.

Valeurs par défaut :

* Maximum **2 visites** par séance.
* Maximum **120 secondes par visite**.
* Maximum **240 secondes au total**, sans possibilité de faire une seule visite de quatre minutes.
* Paramètres configurables par l’administration ; l’interface consomme la politique effective.

Le tuteur peut observer seulement si son enfant est présent dans la séance. Ne confonds pas caméra désactivée, coupure temporaire et absence. Une présence incertaine affiche une vérification, pas une absence inventée.

Le tuteur :

* Entend l’enseignant et tous les élèves dont le micro est actif.
* Voit le support partagé, l’enseignant et son propre enfant selon les médias autorisés.
* Ne dispose ni de micro, caméra, chat, réactions, annotations ou commandes pédagogiques.
* Ne voit pas le roster complet ni les fiches des autres élèves.

L’enseignant et l’enfant concerné voient une notice discrète de sa présence. Les autres élèves ne reçoivent aucune notification de cette visite. Employer « Votre maman… » uniquement si le lien familial est connu ; sinon « Votre parent… ».

Les autorisations, quotas et fins de visite doivent être garantis par le serveur existant. Le timer visuel ne constitue pas cette garantie.

**5. Parcours complet à raccorder**

Classe de l’enfant → disponibilité de l’observation → explication de première utilisation → connexion → observation → sortie → retour à la classe → historique et détail.

Prévoir :

* Deux visites disponibles, une visite restante, visites épuisées.
* Enfant absent, présence en vérification.
* Séance non commencée, terminée, observation désactivée.
* Chargement, connexion prolongée, échec, reconnexion.
* Caméra désactivée, aucun support partagé, support indisponible.
* Sortie volontaire, durée atteinte, fin de séance.

Aucun bouton sans destination ni état explicatif. Conserve le contexte de l’enfant au retour.

Avant l’entrée : afficher les visites disponibles et leur durée.
Pendant : afficher par exemple **« Visite 1/2 · 01:42 »**, correspondant à la visite actuelle.
Après : afficher le nombre réel de visites restantes.

Le compteur ne démarre pas pendant la lecture de l’explication ou une simple vérification préalable.

**6. Explication et consentement**

L’aide accessible depuis « Comment ça marche ? » explique :

« Vous disposez de deux visites de deux minutes par séance. Si un autre élève récite lors de votre première visite, vous pourrez revenir plus tard pour écouter votre enfant. Votre micro et votre caméra restent désactivés pour ne pas interrompre la classe. »

Adapter les chiffres à la politique effective.

Dans l’onboarding, compléter le consentement existant avec cette information :

« Les parents des élèves présents peuvent observer brièvement la séance. Ils entendent l’enseignant et les élèves qui prennent la parole, y compris votre enfant. Ces visites permettent de suivre l’apprentissage sans interrompre la classe : les observateurs ne peuvent ni parler ni activer leur caméra. »

Prévoir les formulations adaptées au responsable légal et à l’élève adulte. Accord explicite, non précoché, enregistré par le mécanisme existant. La présence en classe ne remplace pas un accord effectivement recueilli.

Pour les comptes existants, vérifier le mécanisme de mise à jour des consentements. Ne pas les considérer automatiquement comme ayant accepté cette nouvelle information. Documenter toute dépendance backend.

**7. Salle d’observation**

Le support pédagogique domine. Les deux vignettes enseignant/enfant restent secondaires et ne couvrent jamais le document.

Commandes du tuteur uniquement :

* Couper/rétablir le son reçu.
* Agrandir le support.
* Quitter.

Le zoom est local et ne modifie pas le document partagé. Aucune fausse page du Coran : réutiliser les ressources vérifiées.

Adapter réellement mobile, paysage, tablette et ordinateur. Pas de bottom sheet mobile étiré sur desktop. Respecter clavier, lecteur d’écran, texte agrandi et réduction des animations.

Une interruption réseau ne doit ni simuler du direct ni remettre automatiquement le compteur à zéro.

**8. Historique des observations : obligatoire**

L’historique doit être conservé et consultable par le tuteur et l’administration. Ce n’est pas un enregistrement audio/vidéo.

Réutilise le style de l’Historique déjà conçu : sélecteur d’élève, filtres, lignes séparées, statuts discrets, accès au détail. Ajoute la distinction **« Séances / Observations »**, sans créer un second système d’historique.

Vue tuteur :

* Uniquement les observations auxquelles ses droits donnent accès.
* Regroupement lisible par séance et enfant.
* Date, classe, nombre de visites, durée totale et état.
* Détail : tuteur observateur, enfant, enseignant, entrée/sortie de chaque visite, durée et motif de fin.
* Fuseau horaire explicite et cohérent.

Vue administration :

* Consultation des observations autorisées.
* Recherche et filtres par tuteur, élève, classe, période et statut.
* Accès aux mêmes détails factuels.
* Réutilisation de la navigation et des composants admin existants ; coordonner les fichiers avec tout agent déjà actif sur ce rôle.

Aucune suppression ou édition de traces dans ce périmètre. Ne décide pas arbitrairement d’une durée de conservation. Une actualisation ou reconnexion ne doit pas faire perdre l’historique réel.

Consomme le journal persistant existant s’il est disponible. Sinon, livre l’UI avec la dépendance de persistance explicitement signalée : ne présente pas une liste locale ou fictive comme un historique enregistré.

**9. Orchestration avec les lots en attente**

* Coordinateur : jetons d’abord, contrats partagés, routeur, intégration.
* Agent Admission : consentement et aide de première utilisation.
* Agent Cours : entrée depuis la classe, observation, états et notices contextuelles.
* Agent Compte/Historique : liste et détail tuteur, consultation administrative coordonnée.
* Agent QA : fidélité aux planches, typographie, parcours et distinction simulation/service réel.

Un fichier a un seul propriétaire. Stabiliser les modèles partagés de politique et de visite avant les écritures parallèles.

Ne tranche pas silencieusement les points encore ouverts : quota partagé ou individuel entre responsables, plusieurs enfants dans une même séance, traitement exact d’une visite écourtée ou d’une déconnexion de l’enfant. Retrouve une décision canonique ; sinon isole le point sans bloquer les travaux indépendants.

**10. Recette avant livraison**

Prouver notamment :

* DM Sans sur les titres français, Jakarta sur les autres textes.
* Absence du libellé interdit.
* Première puis seconde visite ; troisième entrée refusée selon réponse serveur.
* Enfant absent : observation indisponible.
* Aucun moyen d’émettre du son ou de la vidéo côté tuteur.
* Notices réservées à l’enseignant et à l’enfant concerné.
* Sortie et reconnexion sans remise à zéro frauduleuse du quota.
* Historique, filtres et détail cohérents, sans données d’un autre foyer.
* Captures comparatives des écrans avec les high-fi.
* Aucun changement backend dans le diff.

Distingue clairement UI réalisée, simulation testée, service branché et fonctionnement réellement vérifié.

Ce complément débloque la préparation commune attendue : mets d’abord les jetons à jour, puis exécute les lots frontend autorisés. Aucun merge main, déploiement ou migration distante n’est autorisé par ce prompt.

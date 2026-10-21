# REWAYAH ACADEMY - DOSSIER MAÎTRE CONSOLIDÉ DES SPÉCIFICATIONS PRODUIT

**Version de consolidation : 14 octobre 2026**  
**Destinataire principal : Claude Code / agents de revue**  
**Objet : référentiel de contexte complet pour comparer les exigences produit au code réellement présent**  
**Nature : produit, métier, pédagogie, UX/UI, opérations, finance, gouvernance et technique**

---

## 0. Mandat de lecture : ce dossier n'est pas un simple backlog de code

Ce document regroupe les décisions métier, règles d'exploitation, curriculum, contraintes UX, écrans, rôles, états, parcours, finance, exceptions, validations humaines et contrats techniques qui ont été définis au fil du projet. Il existe volontairement des exigences qui ne se traduisent pas par un widget ou une API : elles restent obligatoires pour comprendre le comportement attendu, vérifier la cohérence de l'application, rédiger les textes visibles et éviter de remplacer une politique réelle par une simplification de code.

**Le problème à éviter est précisément le suivant :** ne retenir d'une spécification que ce qui paraît directement codable, puis jeter le reste. Une règle sur la date d'échéance, le calcul d'un mois de Ramadan, la décision d'un enseignant, les prérequis d'un cycle, le sens d'une absence, le recours d'une famille ou la condition d'attribution d'une bourse fait partie du contrat produit même si elle ne correspond pas à un écran autonome.

### Instructions impératives à Claude

1. **Ne pas réimplémenter par défaut.** Le produit existe déjà. Auditer le dépôt, les branches, les tests, les routes, les contrats et les versions des spécifications avant toute modification. Ce dossier est un référentiel de comparaison, pas une autorisation de refonte.
2. **Lire l'intégralité du dossier**, y compris les annexes. Ne jamais s'arrêter au contrat API, aux modèles de données ou aux sections que l'agent estime « codables ».
3. **Créer une matrice de conformité par exigence**, avec une ligne par règle ou comportement significatif et les colonnes : identifiant/source, exigence métier exacte, portée UI, portée serveur/données si applicable, preuve dans le code (chemin/symbole), état (`présent`, `partiel`, `absent`, `contradictoire`, `non vérifié`), test/preuve, risque et action minimale.
4. **Séparer le statut de l'exigence de celui de son implémentation.** Une règle peut être obligatoire mais pas encore codée ; une règle codée peut être obsolète ; un écran visible peut n'être qu'une maquette non raccordée.
5. **Ne pas effacer les détails non codables.** Les conserver dans la documentation active du domaine : politique financière, calendrier, contrat de service, doctrine pédagogique, critères de validation humaine, règles de communication, droits et procédures.
6. **Ne pas convertir une hypothèse en politique.** Marquer explicitement `DÉCISION DOCUMENTÉE`, `PROPOSITION`, `HISTORIQUE`, `CONFLIT À ARBITRER`, `À VALIDER SCIENTIFIQUEMENT`, `À VÉRIFIER DANS LE DÉPÔT` ou `ÉTAT DE PRODUCTION NON PROUVÉ`.
7. **Ne pas résoudre silencieusement les divergences.** Les documenter, identifier les sources et dates, proposer la modification minimale et demander au directeur uniquement les vrais arbitrages encore ouverts. Une source récente ne prouve pas à elle seule qu'une politique a été adoptée si elle est marquée proposition ou snapshot.
8. **Aucune déclaration de réussite sans preuve.** Distinguer `spécifié`, `présent dans le code`, `testé localement`, `testé en staging`, `déployé en production`. Ne jamais déclarer qu'un paiement, un payout, un enregistrement, une notification ou une décision académique fonctionne sur la seule base d'une interface.
9. **Frontend only quand la verticale l'indique.** En particulier, le lot Évaluations du 12/10 est frontend only. Ne pas lancer de migration, modifier Supabase/RLS/RPC, LiveKit, serveur ou paiement réel sans mandat explicite.
10. **Une fonction = un emplacement canonique.** Réutiliser les modules, ports, composants et routes existants. Les écrans des rôles Enseignant, Tuteur, Contrôleur et Comptable ont déjà été travaillés : inspecter et corriger les écarts, pas reconstruire sans preuve.

### Résultat attendu de Claude

- Inventaire des sources et des contradictions rencontrées.
- Matrice d'écart complète par rôle, écran, état et règle métier.
- Liste des éléments déjà présents et conformes, des éléments incomplets et des absences prouvées.
- Liste séparée des règles métier non codables qui doivent rester dans les politiques et guides opératoires.
- Plan d'intervention minimal, vertical et ordonné, avec critères de recette et preuves attendues.
- Liste des décisions réellement bloquantes pour le directeur, sans lui redemander les informations déjà documentées ici.

---

## 1. Hiérarchie des sources et état de preuve

Appliquer en priorité la hiérarchie suivante, sans écraser les règles de sécurité ni l'état réel de production :

1. Sécurité, confidentialité, obligations légales et droits réels.
2. Décision explicite la plus récente du directeur, lorsqu'elle est effectivement documentée comme décision.
3. Spécifications canoniques récentes, dont la consolidation du 12 octobre 2026, et documents verticaux adoptés.
4. Contrats et migrations effectivement présents, après inspection du dépôt et de l'environnement concerné. Le code établit l'état implémenté, pas la vérité métier.
5. Référentiel académique, Teaching Core, politique financière et décisions d'exploitation qui portent les règles de fond.
6. Bible UI/UX et tokens validés pour la représentation frontend.
7. Documents plus anciens et prompts, conservés comme historique de décisions et source de détails omis, mais non prioritaires lorsqu'une décision plus récente les remplace clairement.
8. Hypothèses, recommandations d'experts et propositions : jamais adoptées automatiquement.

**Règle de prudence :** si la source la plus récente expose une photographie métier sans régler tous les cas détaillés par une source antérieure, conserver les détails antérieurs comme contexte et les inscrire au registre de réconciliation. Ne pas les supprimer du dossier ni les coder automatiquement comme s'ils étaient définitivement confirmés.

## 2. Carte du produit global

Rewayah est une application d'apprentissage du Coran et de gestion d'académie, Flutter Android/iOS/Web, avec Supabase, LiveKit et stockage R2 selon les contrats existants. La Classe est l'unité durable d'enseignement : elle rassemble des élèves, un programme/niveau, une langue, un enseignant attitré, des jours/heures récurrents, une capacité et un historique. Une séance est une occurrence temporaire de cette Classe. Le foyer organise l'accès et les paiements familiaux, mais chaque élève garde son identité, sa progression et son solde individuel.

Le produit couvre : site public et inscription, identité et admissions, foyer/tuteur/second adulte, adulte autonome, Interface guidée enfant, enseignant, administration/direction, contrôleur, comptable, classe LiveKit, bibliothèque et moteur Coran, cahier et transmission après cours, progression académique, évaluations et jury habilité, communication/recherche, solde et encaissements, dette et payout enseignant, rapprochements, coffres/réserves et audit.

La classe en direct et la présence/assiduité sont centrales. Le contenu pédagogique est prioritaire sur les contrôles secondaires. Le texte canonique du Coran n'est jamais éditable par l'administration ; une annotation est une couche séparée.

## 3. Registre de divergences à ne pas masquer

Ce registre est intentionnel : les annexes conservent les formulations complètes de leurs sources. Il évite que Claude choisisse un chiffre parce qu'il est plus facile à coder.

### 3.1 Prix familial et remise

- **Snapshot du 12/10/2026, spécification finale, section G10.2 :** prix de référence enfant 50 USD/mois, adulte 60 USD/mois ; rangs 1 et 2 : 0 USD de remise, rang 3 : 5 USD, rang 4 et plus : 7 USD par personne éligible. Exemples : deux enfants 100 USD ; trois enfants 145 USD ; quatre 188 USD ; cinq 231 USD ; deux enfants + un adulte 155 USD.
- **Document de décisions économiques V3 du 30/09/2026 :** remise familiale de 5 USD par personne à deux bénéficiaires payants éligibles et 10 USD par personne à partir de trois, avec exemples deux enfants + adulte = 130 USD. Un autre document expert décrit aussi une remise de 5 %/10 % comme hypothèse antérieure.
- Ces règles ne sont pas équivalentes. Le snapshot du 12/10 semble être la référence tarifaire publique la plus récente, mais Claude doit vérifier s'il s'agit de la politique effectivement adoptée et publiée, puis conserver les anciens calculs dans l'historique. Aucun tarif historique ne doit être réécrit rétroactivement.

### 3.2 Rémunération des enseignants

- La source de référence de septembre décrit comme propositions 20 USD par élève enfant/mois et 30 USD par adulte/mois pour refléter les durées 60/90 minutes, avec éventuelle garantie de classe et bonus internet.
- Une source de politiques financières plus récente mentionne 20 USD enfant et 26 USD adulte.
- La spécification du 12/10 dit explicitement de ne pas coder une paie fixe issue d'une ancienne conversation sans lire la version du contrat enseignant en vigueur ; le payable dépend notamment de la prestation et du cahier validé.
- **Consigne :** préserver ces valeurs et leur statut dans la matrice, vérifier le contrat et les décisions effectives ; ne pas en choisir une silencieusement.

### 3.3 Échéance de paiement et renouvellement

- L'historique opérationnel de Rewayah évoque des demandes de paiement autour du 25 du mois et des rappels de paiement récurrents. Ce fait d'exploitation ne suffit pas à démontrer que tous les contrats ont une échéance universelle au 25.
- Les sources financières décrivent aussi une vitrine ordinaire avec réservation initiale sans dépôt obligatoire, recharge demandée dès la date confirmée et avant le cours ; pour une demande personnalisée, un dépôt égal au tarif mensuel individuel est décrit dans la source opérationnelle. À la confirmation, afficher nom/photo enseignant, première date, calendrier, prix exact du premier mois et prochaine échéance. L'entrée en cours de période est proratisée selon la formule de la politique applicable. Le paiement non confirmé reste en attente ; le retour de navigateur ou une capture d'écran ne suffit pas. Un devis doit exposer montant, devise, régime, calendrier, remise, date de début, absences, compensation, résiliation et moyen de paiement réellement accepté. Les documents ne doivent pas être réduits à un bouton « Payer ».
- **Consigne :** retrouver la règle effectivement applicable aux élèves historiques et la politique de renouvellement adoptée ; représenter les échéances, rappels, retards, paiement en transit, échec, nouvelle tentative, suspension/reprise d'accès et reçus. Ne pas appliquer rétroactivement une date nouvelle.

### 3.4 Ramadan, Tabaski et calcul du mois

- La politique d'exploitation financière du 30/09 documente une fermeture institutionnelle du **20 Ramadan au 7 Shawwal inclus**, normalement 17 ou 18 jours selon la durée du mois lunaire, jamais plus de 20 ; les dates grégoriennes sont publiées par la direction. La Tabaski est indiquée du **9 au 18 Dhu al-Hijja inclus**, dix jours. L'application ne décide pas elle-même de l'observation lunaire.
- La même source donne un calcul mensuel tenant compte des séances théoriques `T`, séances ouvertes après congés `O` et séances accessibles depuis la date d'entrée `E`, avec planchers de 25 USD enfant et 30 USD adulte pour un mois complet touché par congé, prorata d'entrée sans réappliquer le plancher. Formule documentée : mois normal complet = `P`; mois touché par congé = `M = min(P, max(plancher, P × O/T))`; premier mois incomplet = `M × E/O` (le plancher n'est pas réappliqué au prorata d'entrée). Si `T=0` ou `O=0`, montant nul. L'absence individuelle ordinaire ne retire aucune séance accessible. Exemple source : 13 séances théoriques, 6 ouvertes, enfant familial à 40 USD = plancher de 25 USD pour un mois complet ; si l'entrée donne accès à 3 des 6 séances ouvertes = 12,50 USD. Adulte familial à 50 USD = 30 USD pour mois complet ; entrée avec 3 séances = 15 USD. Une fermeture couvrant tout le mois donne zéro. Les aides partielles ont leur propre régime.
- La spécification finale du 12/10 exige que le devis et le simulateur soient cohérents avec la politique publiée, mais son snapshot tarifaire ne répète pas toute cette formule.
- **Consigne :** ne pas omettre le calendrier, le calcul, les dates grégoriennes publiées, les corrections après facturation, les avoirs explicites, l'absence de redébit rétroactif et le cas d'une fermeture couvrant tout le mois. Confirmer la version financière active avant de rendre la formule exécutoire.

### 3.5 Solde individuel vs mensualité

- Les sources de conception décrivent un « solde » par élève, un total de foyer purement informatif, recharge d'un ou plusieurs profils et allocation immuable par bénéficiaire. Pas de caisse familiale librement transférable.
- Des documents experts recommandent un solde monétaire fermé prépayé, tandis que le document d'exploitation expose une vitrine à prix mensuel, un devis et un débit de période. Le choix juridique/commercial du prépaiement doit être vérifié pour la société et les territoires servis.
- **Consigne :** ne jamais confondre montant encaissé, solde disponible, mensualité due, revenu acquis, dette de cours, remboursement dû et trésorerie libre. Le retour navigateur n'est pas une preuve de paiement.

### 3.6 Capacités, durées et fréquence des classes

- Le référentiel académique recommande des plafonds de cinq enfants/60 minutes et six adultes/90 minutes, trois séances par semaine.
- Les contrats d'exploitation et décisions antérieures ont aussi indiqué quatre enfants et cinq adultes selon les profils, avec six uniquement après pilote spécifique. Les documents disent de ne pas fusionner ces valeurs en une seule règle.
- **Consigne :** la capacité effective est celle de la Classe publiée et de la politique versionnée applicable, non une constante globale inventée. Préserver la configuration par âge/niveau/exigence pédagogique et vérifier les décisions validées avant ouverture de nouvelles classes.

### 3.7 Observation du tuteur

- Le dossier de décisions source indique deux visites de deux minutes par parent et par séance, une visite écourtée consommée, avec bandeau pleine largeur et compteur seconde par seconde.
- Certains contrats plus anciens de Teaching Core parlent d'une visite unique avec 120 secondes cumulées héritées d'une politique précédente.
- **Consigne :** la règle exacte dépend de la décision la plus récente confirmée. Vérifier le code et le document de décision ; ne pas réduire à un simple bouton d'observation ni exposer l'identité du contrôleur.

### 3.8 Référentiel académique et validations

- Le référentiel RA-CUR-2026.1 formalise D0, F1-F4, G0, T1-T6, H0-H6 et I1, compétences, tajwid, travail à domicile, évaluations, certifications et gouvernance versionnée.
- Deux validations scientifiques restent expressément nécessaires avant publication externe : corpus de Ṣalāh/invocations et correspondance exacte avec l'édition Nour al-Bayân retenue. La revue pédagogique de certains seuils et grilles doit être effectuée par des enseignants habilités.
- **Consigne :** ne pas présenter une proposition de seuil comme une règle universelle ni produire automatiquement une promotion/certification. Le paiement ne valide jamais une compétence.

### 3.9 Fournisseurs et état réel de production

Les noms Stripe, PayPal, Wise, pawaPay, Paystack, Onafriq, Mobile Money ou autres ne sont pas la preuve qu'un corridor est ouvert. Toute méthode visible doit correspondre à un compte, un pays, une devise, des frais, un contrat et un test réels. Aucun paiement réel, remboursement ou payout ne doit être exécuté par ce dossier seul.

---

## 4. Référentiel des domaines et rôles à auditer

Le document source du 12/10 et le dossier d'inventaire détaillent les parcours et écrans. Claude doit les cartographier au code, y compris les fonctions transverses et les états :

- Identité, connexion, récupération, portails d'attente, consentements, pièces sensibles et habilitations.
- Tuteur/titulaire, foyer multi-enfants, choix de l'enfant actif, second adulte et délégation.
- Élève adulte autonome, sans faux parent ni faux enfant.
- Élève enfant, Interface guidée, accès limité et protection des mineurs.
- Enseignant : KYC, profil professionnel/public, classes, journée, préparation, salle, cahier, progression, disponibilité, remplacement et paie selon droits.
- Administration/direction : dossiers, personnes, offres, intentions, regroupements, Classes, exceptions, pédagogie, évaluations, politiques, finance autorisée, sécurité et audit.
- Contrôleur : MFA, mission active, observation silencieuse, données minimales, rapport, contestation et audit.
- Comptable : obligations, encaissements, rapprochements, soldes, remboursements, validations, payouts, coffres, exports et journal.
- Évaluateur/juré : capacités temporaires et limitées, occurrence, passage, quorum, avis indépendants, décision autorisée, résultat, attestation/certificat et recours.
- Groupe/Classe, LiveKit, présence, reconnexion, bibliothèque, Mushaf, document partagé, annotations et après-cours.
- Pédagogie : diagnostic, curriculum versionné, compétences, progression, travail, reprise, évaluations et certifications.
- Finance : barème, simulateur, devis, échéance, paiement en transit/confirmé/refusé, allocation, solde, avoir, remboursement, dette enseignant, préflight payout et rapprochement.
- Communication, notifications, recherche globale et liens profonds autorisés.
- Site public : offre vitrine, parcours d'inscription, tarifs, simulateur, conformité, recrutement, support et contenus.
- Design system, responsive mobile/tablette/desktop, thème clair/sombre, accessibilité, états d'erreur et recette.

Les annexes ci-dessous préservent les documents source, les écrans identifiés, les règles détaillées et les prompts de contrôle. Les doublons ne doivent pas être supprimés avant d'avoir identifié ce qu'ils conservent d'unique.

---

## 5. Inventaire des annexes consolidées

Les annexes sont incluses en texte intégral lorsque le fichier source est disponible dans l'espace de travail. Les documents Word ont été extraits en conservant les paragraphes, titres et tableaux sous une forme Markdown lisible ; la mise en page et les illustrations originales ne sont pas reproduites dans cette extraction. Les fichiers visuels restent des références séparées dans les sources du projet.



---

# ANNEXE 01 - Contrat documentaire canonique et hiérarchie

_Source : `00_LIRE_D_ABORD.md`. Contenu conservé pour ne pas perdre les détails métier._


# Rewayah - contrat documentaire canonique
Version : 22 septembre 2026. Portée : spécification cible pour achever l'application existante. Ces documents ne prouvent pas que les fonctionnalités sont déjà livrées.

## Lecture en moins de cinq minutes
1. Lire ce fichier.
2. Lire uniquement le document du domaine touché : `01_PRODUIT_ET_PARCOURS.md`, `02_ARCHITECTURE_ET_SECURITE.md` ou `03_DESIGN_SYSTEM_ET_UX.md`.
3. Lire `04_EXECUTION_GIT_CI_ET_MIGRATION.md` seulement pour intégration, ménage documentaire, branches ou déploiement.
4. Inspecter le code, les migrations, les tests et le journal Git du périmètre. Le code atteste l'état réel, pas la validité d'une décision métier.
5. Avant de coder, produire : fichiers prévus, dépendances, critères de succès, points incertains. Travailler par un lot limité.

## Autorité et désaccords
La demande explicite la plus récente du directeur prévaut sur ces documents. Ensuite : décisions canoniques ici, contrats effectivement migrés et vérifiés, documents historiques conservés en archive, suppositions d'agent. Une migration en production impose un plan compatible et réversible, même si ces specs décrivent un modèle différent. En cas de conflit réel, noter le conflit et proposer la modification minimale ; ne pas choisir silencieusement.

## Invariants
- Conserver Flutter Android, iOS, Web ; Supabase ; LiveKit ; stockage R2 distinct et privé selon les quatre groupes réellement configurés. Claude Code est l'agent de développement. Vercel concerne le déploiement web effectivement configuré ; confirmer le projet dans le dépôt.
- Préserver l'existant utile. Pas de recréation de l'app, de schéma, de thème, d'auth ou de routeur pour chaque lot.
- Une classe est un groupe stable, avec horaire récurrent et enseignant attitré. Le tuteur choisit parmi les classes proposées ; l'admin affecte et gère les exceptions.
- L'interface présente une tâche et une action principales ; noms simples. Les codes internes restent internes.
- Autorisation contrôlée côté serveur : RLS, rôles, capacités et accès LiveKit. Aucun secret ou calcul financier de référence côté Flutter.
- Aucun déploiement, migration distante, publication, suppression de branche ou de mémoire avant inventaire, sauvegarde et feu vert explicite de l'opérateur sur la liste précise. Ne jamais effacer une branche contenant un travail non intégré.

## Statuts de preuve
Chaque tâche et bilan distingue `spécifié`, `présent dans le code`, `testé localement`, `testé sur staging`, `déployé`. Ne jamais qualifier d'achevé un parcours UI dont le backend, le branchement, la sécurité ou le test réel manque.

## Contradictions résolues
- L'ancien « matching » individuel par disponibilités est remplacé pour l'inscription courante par le choix d'une classe précréée avec un même enseignant et ses séances récurrentes. Les disponibilités servent à proposer des options, gérer exceptions et liste d'attente.
- Les anciens plafonds génériques de 6 personnes et capacités supposées de 5 cèdent aux capacités configurées par catégorie : par défaut 4 élèves enfants et 5 élèves adultes, enseignant en sus ; affichage de la capacité réelle.
- « Mode enfant » devient `Interface guidée`, activable selon les besoins, y compris par un adulte. Dans l'espace cours : `Sayyid` / `Sayyida`.
- Le document économique du 13 septembre développe la finance et l'IA ; il n'annule pas les parcours indispensables à une première cohorte réelle. Les moteurs financiers avancés restent des lots séparés. Les chiffres de scénario ne deviennent jamais des vérités de production.
- Les quotas et prix anciens de fournisseurs ne sont pas des paramètres fiables de 2026 : vérifier contrats et consoles avant arbitrage de coût.
- Ne pas interpréter la documentation académique comme un mandat de réécrire l'enseignement ou le Coran. Les validations pédagogiques restent humaines.

## Questions à résoudre sur le dépôt, sans blocage du travail indépendant
État exact de CORE24 Classes V2 et de son audit ; quatre noms/contrats R2 en production ; état des migrations ; statut LiveKit Cloud ou hébergé ; branche principale et configuration Vercel ; référentiel académique actuel et version approuvée. Documenter la preuve et la personne qui tranche une divergence. L'audit CORE24 communiqué par le directeur indique explicitement « non prêt pour intégration » : aucun merge sur ce seul fondement.


---

# ANNEXE 02 - Produit, rôles et parcours

_Source : `01_PRODUIT_ET_PARCOURS.md`. Contenu conservé pour ne pas perdre les détails métier._


# Rewayah - produit, rôles et parcours
Version : 22 septembre 2026. La première cohorte réelle sert de priorité de livraison ; la vision complète demeure modulaire.

## Objectif
Une famille choisit une classe compatible avec son fuseau et son parcours. L'élève suit durablement le même enseignant, assiste aux séances et poursuit son travail entre les cours. Les équipes administrent, enseignent, contrôlent et suivent ce cycle dans une application simple.

## Rôles et vues
| Rôle | Accueil et actions majeures | Restrictions |
|---|---|---|
| Élève enfant ou adulte | Prochain cours, groupe, rejoindre, bibliothèque, travail, progression lisible | Données des autres familles interdites |
| Tuteur | Foyer, inscription/choix de classe, horaires, présence, progression, appareils, paiements quand disponibles | Accès limité à ses élèves ; observation bornée |
| Enseignant | Journée, groupes, cours, supports, cahier de transmission, progrès, disponibilité | Aucun contact privé des familles ni documents d'identité |
| Admin | Centre opérationnel, personnes, classes, admissions, affectations, sécurité, paramètres, finance autorisée | Journaliser les actions sensibles |
| Contrôleur | Planning, observation discrète autorisée, compte rendu | Aucun micro ni caméra ; entrée auditée |
| Comptable | Encaissements, rapprochement, rémunération et exports selon modules livrés | Aucun accès au contenu pédagogique privé par défaut |

## Admission et classes
- Admin définit un catalogue limité de classes stables : parcours, niveau, public, enseignant attitré, jours et heures récurrents, durée, fuseau de référence, capacité, état et date de début. Construire les plages autour des populations Europe, Amérique du Nord et autres régions servies ; ne pas inventer les horaires exacts sans calendrier et disponibilités des enseignants.
- Diagnostic pédagogique à l'entrée. Débutant : parcours de base. Élève avancé : placer au groupe existant le plus proche du niveau évalué ; exception documentée si aucun groupe approprié. Respecter les décisions humaines du référentiel académique.
- Exposer à la famille les classes réellement ouvertes, horaires locaux avec dates et changements d'heure, fréquence, niveau, enseignant, places disponibles. Montrer les séances de la même classe avant validation.
- Une inscription atomique réserve ou place en attente suivant capacité et prérequis. Protection contre doubles inscriptions, places fantômes et collisions d'enseignant. L'admin valide affectation et exceptions. Un changement de professeur est un événement exceptionnel avec historique et information de la famille ; aucune rotation automatique selon la séance.
- Enseignant responsable d'un groupe sur toutes ses séances récurrentes, sauf remplacement temporaire tracé. Annulations, reports, jours fériés, DST et remplacements modifient des occurrences, pas silencieusement le contrat de classe.

## Espace Groupe
Carte : nom courant, cours/niveau, photo publique de l'enseignant, `Sayyid`/`Sayyida`, places X/Y réelles, prochaine séance (jour, date, heure locale, durée), timer. Une page de groupe rassemble séance, travail, bibliothèque et progression utile. À environ T-20 configurable, `Rejoindre` devient disponible ; présence académique à partir du début et selon événements serveur. Si séance prolongée, afficher « Cours toujours en cours », jamais un temps négatif. Montrer les deux fuseaux utiles à l'enseignant ; avertir en amont des changements d'heure.

## Classe et supports
LiveKit transporte audio/vidéo et événements temps réel ; Supabase décide droits, affectations et présence. Micro/caméra initialement coupés selon politique de session ; qualité audio prioritaire, bascule sur réseau faible, reconnexion avec continuité de salle. Support partagé natif et synchronisé, pas un partage vidéo de PDF. Bibliothèque hors et dans la classe : Coran structuré Hafs de source validée, rendu Mushaf fidèle si prouvé, lecture agrandie, texte structuré, leçons, PDF et images. Version publiée immuable, source et licence vérifiées. Enseignant choisit, pointe, marque, masque, annote sur couche distincte et fixe le travail. L'élève suit l'enseignant pendant la présentation tout en gardant ses préférences personnelles sans modifier la vue commune. Session persistante lors de la navigation.

Roster limité aux données pédagogiques nécessaires, sans coordonnées familiales. Tuteur observateur silencieux : politique serveur par groupe, défaut hérité de la dernière décision documentée (activé, une visite, 120 secondes cumulées par séance), configurable et audité ; vérifier la compatibilité avec les protections des mineurs avant ouverture réelle. Admin peut observer en mode visible ou incognito, contrôleur incognito seulement, avec journalisation et information générale des usagers. Aucun déclenchement distant de microphone.

Après séance : cahier de transmission court prérempli, présence avec corrections auditables, travail à préparer, position de reprise, exception ou signalement. Le retour élève ne nécessite pas de formulaire obligatoire. Enregistrement audio et rétention contrôlés seulement une fois consentement, infrastructure, accès audités et règle de conservation opérationnels ; ne pas feindre la conformité par un simple drapeau UI.

## Académie et pilotage
Parcours de base lecture de l'arabe et Coran, salat et invocations essentielles, puis orientation lecture autonome ou hifz selon objectif. Diagnostic, progression individuelle dans une cohorte, évaluations et délivrance de certificats restent soumis à approbation académique. Codes de compétences invisibles dans l'interface.

Tarifs, salaire enseignant de référence (4 USD/h dans la spécification économique), capacités, durée, exceptions, bourses et politiques de crédits : données configurables, versionnées et décidées humainement. La finance complète, prévision, paie, payouts et conseiller IA sont des chantiers séparés ; premier onboarding doit pouvoir fonctionner avec paiement hors application consigné par l'admin et accès daté. Ne jamais afficher une facture ou un paiement simulé comme réglé. Objectif de résultat de 2 000 USD/mois dans l'ancien document : cible de scénario, jamais garantie ni formule codée en dur.

## Recette de première cohorte
Créer tuteur et élève réels, diagnostiquer et choisir une classe réellement disponible, confirmer le même enseignant sur plusieurs jours, ouvrir une séance, vérifier accès et absence de fuite entre foyers, rejoindre en tuteur/élève/enseignant, partager une page du Coran, perdre et retrouver le réseau, enregistrer présence et travail, retrouver le cours suivant. Exécuter sur mobile et web avec fuseaux Europe et Amérique du Nord et changement DST. Sans parcours complet raccordé et constaté, statut : non prêt.


---

# ANNEXE 03 - Contrats techniques et sûreté

_Source : `02_ARCHITECTURE_ET_SECURITE.md`. Contenu conservé pour ne pas perdre les détails métier._


# Rewayah - contrats techniques et sûreté
Version : 22 septembre 2026. Avant toute migration, inspecter le schéma réel et les données. Ne pas réappliquer mécaniquement les anciens plans SQL.

## Domaines et frontières
| Domaine | Vérité | Contrat minimal |
|---|---|---|
| Identité, foyer, rôles | Supabase Auth + DB | Enfant lié au tuteur, autorisation par capacité et état de compte |
| Académie | DB versionnée | Référentiel, diagnostic, compétence, objectif, niveau, historique de placement |
| Classes et planning | DB + RPC transactionnelles | Classe stable, maître enseignant, occurrences, exceptions, capacité, fuseaux IANA et DST |
| Salle | LiveKit via tokens serveur | Participation limitée à une séance autorisée ; client reçoit URL/token, aucun secret serveur |
| Présence | Événements LiveKit validés + DB | Dédupliquer webhooks, distinguer connexion, présence académique et incident réseau |
| Ressources | Métadonnées DB + R2 privé | Version, licence, type, autorisation de lecture, URL signée courte |
| Finance | Registres déterministes DB | Politique versionnée, opérations idempotentes, séparation des rôles |
| Audit | Journal append-only | Actions sensibles, accès aux enregistrements, rôle de contrôle, changements de politique |

## Règles d'implémentation
1. Inventorier tables, RPC, policies, edge functions, migrations et clients Flutter existants ; aligner le contrat aux noms réellement présents. Ajouter des migrations additives avec stratégie de retour arrière ou de correction, jamais modifier une migration déjà appliquée comme si elle était neuve.
2. Réservation de place concurrente et affectation via transaction serveur avec contrainte d'unicité pertinente ; vérifier chevauchement d'enseignant, capacité, occurrences et changement de fuseau. Réponse explicite pour attente ou conflit.
3. RLS sur toutes les tables exposées. Tester en contexte réel : famille A n'accède pas à B, enseignant voit uniquement ses groupes et la projection nécessaire, contrôleur n'accède pas aux contacts, enfant ne voit ni finances ni KYC. Une UI cachée ne remplace jamais une policy.
4. Le serveur délivre tokens LiveKit par session et par permission, expiration courte. Webhooks signés et idempotents. Le transport de document partagé doit être révisable, rejouable à la reconnexion et distinct des préférences individuelles. Pas d'événements temps réel qui contournent RLS ou l'autorité métier.
5. Stockage R2 : quatre groupes de secrets/buckets validés séparément ; récupérer leurs noms et scopes de l'environnement autorisé avant branchement. Ne jamais deviner un quatrième nom ni faire transiter KYC vers le bucket de ressources publiques. Vérifier upload, relecture, effacement et droits par famille de données. Aucun secret dans le dépôt ou les logs.
6. Protection des mineurs : identité/KYC séparés des photos publiques d'enseignants et portraits visibles en classe ; accès restreint, consentements et retenues configurables ; accès aux enregistrements tracé ; politique de suppression et gel pour litige. Les exigences légales et de localisation doivent être validées avant ouverture réelle des mineurs.
7. Client local : cache borné et effaçable, données sensibles protégées, file hors ligne seulement pour écritures conciliables et idempotentes. Ne pas mettre des autorisations persistantes en cache comme source de vérité. Fuseaux IANA en stockage, UTC pour les instants.
8. Observabilité : corrélation de séance, métriques sur token, webhook, RPC, reconnexion, enregistrement et déploiement ; logs sans secrets ni données privées. Repli visible lorsque visio, présence ou document échoue ; reprise sans double comptage.

## Contrat CI et déploiement web
Établir la chaîne réelle `push main -> workflow GitHub ou intégration Git Vercel -> build Flutter web -> artefact -> URL de production`. Contrôler repo connecté, branche de production, droits Git App, variables d'environnement par environnement, répertoire racine, commandes d'installation/build, artefact `build/web`, configuration SPA/deep links, protection et statuts requis. Ne pas stocker `service_role`, LiveKit secret ni clés R2 dans le bundle public. Reproduire d'abord l'échec à partir d'un commit identifié et des logs ; corriger la cause prouvée puis tester un push inoffensif sur branche de test et un déploiement main autorisé. Un build local réussi n'atteste pas un déploiement automatique.

## Tests probants
Migrations sur DB neuve et copie anonymisée si possible ; RLS inter-foyers et rôles ; concurrence sur dernière place ; récurrence + DST ; enseignant permanent et remplacement ; token refusé hors séance ; webhook dupliqué et hors ordre ; reconnexion ; contrôle de stockage et URL expirée ; parcours multi-rôles ; vérification CI et URL déployée. Rendre les résultats et limites lisibles, aucun `PASS` inventé.


---

# ANNEXE 04 - Charte UX/UI canonique

_Source : `03_DESIGN_SYSTEM_ET_UX.md`. Contenu conservé pour ne pas perdre les détails métier._


# Rewayah - charte UX/UI canonique
Version : 22 septembre 2026. Condensé opérationnel de la Bible V2 ; inspection du thème Flutter existant obligatoire avant migration des tokens.

## Langage visuel
Material Design 3 comme système de composants et comportements ; adaptation iOS pertinente et cohérente. Style calme, contemporain, aéré, profondeur discrète, ombres légères, animation courte qui sert la compréhension. Palette douce et presque monochrome ; violet fortement atténué, jamais primaire par défaut. Les documents fournis ne fixent pas de valeurs HEX officielles : ne pas inventer de palette chiffrée « approuvée ». Auditer les tokens et les dernières maquettes approuvées, proposer au directeur les tokens précis s'ils manquent, puis les centraliser. Des touches pédagogiques de couleur sont possibles dans l'Interface guidée et les groupes, sans coder l'information par la seule couleur. Mode clair et sombre complets, contraste vérifié.

Interdire dans les widgets métiers `Color(0x...)`, HEX et dimensions arbitraires répétées. Utiliser `ThemeData`, `ColorScheme`, tokens sémantiques de typographie, espace, rayon, élévation et états. Reprendre et améliorer les composants existants (`Pressable`, `BentoTile`, `ChoiceCardGroup`, `AudioLabel`, `PermanentNotice`, `AvatarTile`) au lieu de multiplier les copies. Une grande carte ne doit pas devenir une collection de petites boîtes.

## Structure par écran
Un titre compréhensible, une tâche dominante, un CTA principal proche de l'usage du pouce sur mobile, puis les détails secondaires accessibles par divulgation progressive. Les préférences vont dans Paramètres ; les filtres à côté du contenu ; les actions irréversibles près de leur objet avec confirmation adaptée. Mobile : barre basse avec peu de destinations, retour visible dans la zone accessible au pouce lorsque le flux le demande, grandes zones tactiles. Tablette : deux panneaux si utiles. Desktop : navigation latérale et contenu centré ; ne pas agrandir le mobile uniformément.

Rôle élève : prochain cours immédiatement, classe et travail ; enseignant : journée, prochaine classe, accès au support et roster ; tuteur : foyer, inscription et échéances ; admin : recherche, opérations et exceptions, densité progressive. Aucun code interne tel que `F1-PHO-01` ou `CORE24` dans les textes visibles. `Sayyid` et `Sayyida` en salle ; `Interface guidée` accessible aussi aux adultes. Photos publiques d'enseignants distinctes des pièces d'identité.

## Salle pédagogique
Sur petit écran le document/Coran est le contenu principal ; vidéo secondaire ajustable, roster en panneau temporaire, dock des outils compact et atteignable. En paysage et sur tablette, utiliser la largeur pour document, participants et contexte sans réduire le texte du Coran. Afficher état micro/caméra, enregistrement réel, réseau, reconnexion et présence sans alarme visuelle permanente. Commandes enseignant au bon niveau : suivre, pointer, marquer, masquer, stylet, devoir ; paramétrage rare ailleurs. Le contenu en cours survit aux changements d'écran.

Lecteur Coran : source vérifiée, fidélité Mushaf en mode page quand disponible, mode verset agrandi, zoom, RTL, contrôles sobres, aucune génération trompeuse d'un « Mushaf fidèle » par simple retour à la ligne. Une annotation reste dans sa couche, pas dans le texte canonique.

## Accessibilité et QA
Cibles tactiles d'au moins 48 dp, agrandissement du texte sans écrêtage, libellés sémantiques, focus clavier et lecteur d'écran, ordre de lecture, RTL arabe, locales et fuseaux, contrastes WCAG 2.2 pertinents, mode mouvement réduit. Vérifier écran étroit, tablette, desktop web, clair/sombre, chargement, vide, erreur, hors ligne et permissions refusées. Captures comparatives et test sur appareil réel ou simulateur pour tout écran livré. Animations légères ; retour haptique facultatif, sans dépendance fonctionnelle. Mesurer le temps et le nombre d'actions pour rejoindre une séance et reprendre le support.


---

# ANNEXE 05 - Protocole Git, CI et intégration

_Source : `04_EXECUTION_GIT_CI_ET_MIGRATION.md`. Contenu conservé pour ne pas perdre les détails métier._


# Rewayah - protocole d'exécution, nettoyage et publication documentaire
Version : 22 septembre 2026. À appliquer sur le dépôt réel par l'agent chargé de l'intégration ; aucun acte Git distant n'a été accompli en rédigeant ce fichier.

## 1. État initial prouvé
Collecter `git status`, worktrees, `remote -v` en masquant les secrets, branche par défaut, branches locales et distantes, commits ahead/behind, PR ouvertes, workflows, hooks et déploiements Vercel récents. Identifier tous les agents actifs et leurs ownerships. Obtenir les preuves des audits, notamment CORE24 Classes V2 branche `integration/core24-classes-v2`, commit `e8beeb7a` contre `9a3ff0d` et rapport de non conformité. Ne jamais le fusionner sur la foi d'un nombre de fichiers présents.

## 2. Remplacement documentaire
Créer une branche dédiée depuis la base stable, copier les cinq fichiers `00` à `04` dans `docs/current/` ; adapter `CLAUDE.md` racine en index court vers `00` et le document utile à la tâche. Adapter les instructions locales qui pointent vers les vieux fichiers. Rechercher les références à `docs/`, `CLAUDE.md`, `.clauderules`, mémoires, prompts et anciens ADR dans le dépôt et la CI ; classifier chaque cible : active / historique / privée / générée / inconnue. Mettre les anciens documents en archive Git clairement exclue des lectures courantes, si la conservation est nécessaire pour audit. Éviter l'effacement aveugle d'une mémoire d'agent qui porte des décisions, accès, traces ou travail inédit. Les fichiers produits par d'autres agents restent sous leur ownership jusqu'à leur fin et leur intégration.

## 3. Branches Git
Produire un tableau nom, dernier commit, auteur, date, PR, merge-base, unique commits, fichiers uniques, agent actif, état des tests, décision proposée. Conserver `main`, les branches protégées, branches de PR ouvertes, celles avec commits uniques, celles d'agents actifs et toute branche requise pour rollback. Consolider seulement les branches terminées, intégrées et vérifiées. Rédiger la liste exacte des suppressions envisagées avec hash et méthode de restauration. Faire valider explicitement cette liste par le directeur avant `git push --delete`, `git branch -D`, reset forcé ou effacement de mémoires. Ne jamais forcer un push vers `main`.

## 4. Réparation CI et Vercel
Depuis les logs du dernier push `main` non déployé, isoler : événement Git absent, workflow non déclenché, job en erreur, build en erreur, upload absent, mauvais projet/branche, domaine ou runtime en erreur. Vérifier les permissions GitHub/Vercel et secrets côté provider via procédures sûres. Corriger dans branche dédiée, exécuter le même build et ses tests, vérifier l'aperçu, puis intégrer suivant protections et autorisations du dépôt. Déclencher un commit `main` traçable ; constater webhook, build, deployment ID et URL avec version attendue. Si besoin d'un accès externe ou d'une permission indisponible, livrer diagnostic exact et action requise sans déclarer la panne résolue.

## 5. Conditions d'intégration
Un agent modifie seulement ses fichiers attribués, évite le worktree des autres, signale une interface partagée plutôt que créer un service rival. Intégrateur unique des migrations, routeur, dépendances et CI. Pour chaque lot : diff restreint, tests significatifs, RLS quand pertinent, preuve fonctionnelle et revue UX. Laisser CORE24 bloqué tant que ses écarts de parcours, raccordement et exécution ne sont pas résolus. Reporter le nettoyage irréversible après état prouvé et validation humaine sur les cibles exactes.


---

# ANNEXE 06 - Prompt intégrateur Claude

_Source : `05_PROMPT_AGENT_INTEGRATEUR.md`. Contenu conservé pour ne pas perdre les détails métier._


# Prompt prêt à transmettre à Claude Code - remise à plat contrôlée

Tu es l'intégrateur du dépôt Rewayah existant. D'autres agents peuvent encore travailler sur des branches ou worktrees. Ta mission : installer les cinq spécifications canoniques jointes (`00` à `04`), raccourcir les instructions d'agent, inventorier et traiter les références historiques, clarifier les branches et réparer la chaîne de déploiement automatique Vercel après les push sur `main`.

## Directives impératives
1. Commence par `00_LIRE_D_ABORD.md`, puis `04_EXECUTION_GIT_CI_ET_MIGRATION.md`. Lis les autres documents uniquement par besoin du lot. Inspecte le dépôt réel avant toute modification et annonce les conflits entre les specs et le code ; n'efface jamais un fait historique utile ni le travail d'un agent actif.
2. Fais un inventaire lisible des worktrees, branches, PR, fichiers d'instructions, mémoires, docs, workflows, projet Vercel et état de CORE24. Identifie chaque élément par chemin ou branche et statut. Le rapport CORE24 indique que `integration/core24-classes-v2` à `e8beeb7a` n'est pas prêt à l'intégration ; retrouve le rapport et vérifie l'état depuis.
3. Crée une branche documentaire depuis la base stable. Ajoute les cinq specs sous `docs/current/`, remplace `CLAUDE.md` et les mémoires d'instructions actives par des index concis. Répare leurs liens entrants. Archive ou retire seulement les anciens documents clairement identifiés, après avoir vérifié qu'ils n'apportent aucune décision inédite. Ne supprime pas « TOUT » littéralement : préserve code, migrations, secrets configurés, historique Git, logs utiles et travail non fusionné. Une ancienne règle qui contredit `00` à `04` ne doit plus être chargée comme instruction active.
4. Analyse la cause précise du non déploiement `main -> Vercel` dans les logs et paramètres effectifs. Corrige le workflow, l'intégration Git, le build ou la configuration réellement fautive. Prouve le build local, l'aperçu puis le déploiement d'un commit `main` lorsque l'accès et le flux d'intégration le permettent. Si le dépôt ou la console n'est pas accessible, rédige la preuve manquante et la commande ou action minimale ; ne prétends pas avoir corrigé.
5. Produis le tableau complet des branches candidates au nettoyage. Aucune suppression distante, aucun `reset --hard`, aucun force push et aucun effacement de mémoire non sauvegardée avant mon accord explicite sur la liste exacte des cibles. Si tu as déjà une autorisation spécifique et vérifiable dans cette session, applique-la à son seul périmètre. Après accord, supprime uniquement les branches prouvées intégrées et conservées par l'historique de `main`, puis vérifie l'état final.
6. Ne fusionne aucune feature hors périmètre. Priorité à l'application existante, au parcours fonctionnel et à l'absence de régression. Ne recopie aucun secret dans un rapport. Un agent propriétaire d'un fichier ne doit pas être contourné pendant son travail.

## Livrables attendus
- PR ou diff documentaire avec index court et documents canoniques, liens réparés et inventaire des historiques archivés.
- Diagnostic CI fondé sur commit et logs, correctif, tests, preuve du déploiement ou blocage nommé.
- Tableau de branches classées « conserver », « intégration à terminer », « suppression proposée après accord ».
- Rapport final : ce qui était déjà présent, ce qui a changé, preuves, risques, actions en attente ; chaque état distingué entre spécifié, codé, testé et déployé.

Arrête-toi avant toute suppression irréversible dont la liste n'a pas été approuvée. N'attends pas cette approbation pour finir les inventaires, la documentation, le correctif CI testable et les autres opérations réversibles.


---

# ANNEXE 07 - Inventaire fonctionnel et recette MVP

_Source : `06_SPEC_FONCTIONNELLE_MVP.md`. Contenu conservé pour ne pas perdre les détails métier._


# Rewayah - inventaire fonctionnel du MVP et recette
Version : 22 septembre 2026. Cette liste est une cible de livraison, pas un constat d'implémentation. Statuts à renseigner par l'agent sur le dépôt : spécifié / codé / intégré / testé / déployé.

## Frontière de livraison
`MVP opérationnel` signifie pouvoir enregistrer les élèves actuels, leurs foyers et enseignants, les placer dans des classes réelles à enseignant permanent, enseigner, suivre la présence et transmettre un travail. `MVP complet` ajoute tous les modules marqués M ci-dessous. Le premier périmètre ne doit jamais se faire passer pour le second.

| Domaine | Fonction et comportement attendu | Priorité | Recette déterminante |
|---|---|---|---|
| Fondations | Environnements séparés, migrations, RLS, sauvegarde, journaux, CI web et déploiement, contrôle des secrets | M | Installation neuve, accès entre foyers refusé, push main effectivement déployé |
| Identité | Connexion, récupération de compte, rôles admin/comptable/contrôleur/enseignant/tuteur/élève, compte en attente, activation/suspension | M | Routage selon autorisation serveur et état de compte |
| Foyer | Tuteur et plusieurs enfants, adulte autonome en foyer d'une personne, profil par élève, gestion des appareils | M | Deux foyers isolés ; adulte autonome sans faux parent |
| Inscription | Onboarding court, consentements et pièces nécessaires en coffre privé, statut et validation admin ; migration encadrée des élèves/enseignants existants | M | Famille existante intégrée sans perte et accès refusé avant validation requise |
| Diagnostic | Pré-diagnostic déclaratif, diagnostic pédagogique humain, proposition de cycle/groupe, décision tracée | M essentiel | Débutant en F1 ; élève avancé dans groupe compatible ou attente |
| Catalogue classes | Classes créées par admin, enseignant attitré, curriculum/niveau, capacité, jours, heure, durée, fuseau IANA et récurrence | M essentiel | Aucun professeur différent par séance ordinaire ; aucune collision |
| Choix familial | Voir les classes avec toutes leurs séances, horaire local, enseignant, places, liste d'attente si rien ne convient | M essentiel | Dernière place réservée une fois ; DST Europe/USA exact |
| Exceptions planning | Annulation, congés, absence, remplacement temporaire et transfert documentés | M | Séance déplacée sans perdre groupe, enseignant permanent ni historique |
| Accueil par rôle | Tuteur : enfants et prochaines séances ; élève : classe et travail ; enseignant : journée ; admin : exceptions et opérations ; contrôleur : planning | M | Une action principale, états vide/erreur/hors ligne |
| Espace Groupe | Carte et page : identité lisible, photo publique enseignant, capacité réelle, prochaine séance datée, durée, décompte, travail et bibliothèque | M essentiel | `Rejoindre` selon fenêtre serveur ; session prolongée sans timer négatif |
| LiveKit | Salle par séance, token limité serveur, micro/caméra selon politiques, réseau faible, audio prioritaire, reconnexion, aucun lien public | M essentiel | Professeur + élève rejoignent et retrouvent support après coupure |
| Visiteurs | Tuteur observateur borné ; admin visible/incognito ; contrôleur incognito audité, sans micro/caméra | M | Serveur refuse publication et dépassement de durée |
| Présence | Webhooks signés et idempotents, retard, temps connecté distinct du temps de cours, correction administrative auditée | M essentiel | Double webhook ne double pas présence ; incident réseau identifié |
| Bibliothèque | Catalogue hors/en cours ; Coran Hafs structuré de source approuvée, Mushaf fidèle vérifié, texte, leçon, PDF et image versionnés | M essentiel | Prof choisit et affiche un passage natif chez l'élève sans vidéo de l'écran |
| Outils enseignant | Suivi partagé, pointeur, sélection, marqueur, masquage, annotation séparée, reprise, travail court | M | État partagé cohérent après reconnexion ; texte coranique inchangé |
| Après cours | Cahier prérempli, résultat individuel et exceptions, résumé tuteur, préparation du prochain cours | M essentiel | Enseignant valide rapidement ; élève retrouve son travail |
| Pédagogie minimale | Programme/cycle/unité en base versionnable, état actuel de l'élève, progrès basique, compétence à renforcer ; pas d'évaluation automatisée | M essentiel | Continuité enseignant et progression non perdue |
| Communications | Annonces et messages utiles famille/enseignant/admin selon droits ; notification cours, changement et validation ; archivage approprié | M | Pas de coordonnées familiales exposées à l'enseignant |
| Contrôle et administration | Recherche et gestion personnes/classes, anomalies, revue d'accès, journal d'audit, grille de contrôle et exports serveur autorisés | M | Export accessible uniquement au rôle autorisé, journal consultable |
| Paiement transitoire | Encaissement externe saisi/vérifié par admin, état d'accès daté et relance humaine ; aucune fausse intégration paiement | M essentiel | Dossier payé/hors paiement identifiable, accès autorisé ou bloqué correctement |
| Mode hors ligne | Planning et supports autorisés en cache, reprise de file d'attente pour notes conciliables ; entrée visio requiert le réseau | M | Aucun accès à une autre famille via cache |
| Qualité | Modes clair/sombre, `Interface guidée`, mobile/tablette/web, RTL arabe, clavier, lecteur d'écran, grosses cibles | M | Tests visuels, sémantiques et parcours sur petits écrans |

## Enregistrement de cours : arbitrage explicite
ADR-002 ancien inclut audio systématique, stockage R2 et rétention 30 jours ; le Control System V2 plus récent dit « aucun enregistrement audio/vidéo par défaut ». Ne pas activer automatiquement sur de vrais élèves avant décision écrite sur finalité, consentement, politique de rétention, chiffrement, accès et conformité. Le système de salle doit pouvoir porter un état d'enregistrement réel et visible, jamais une indication fictive. Ce seul arbitrage ne bloque pas l'enseignement en direct non enregistré si les règles de protection applicables sont respectées.

## Livrer sans tromper
Un écran maquetté, un service inutilisé ou une migration non appliquée n'est pas une fonctionnalité livrée. Pour chaque ligne M, noter propriétaire du code, preuve, état et blocage. La branche CORE24 déjà auditée « non prête » doit repasser la recette complète avant fusion. Regrouper les lots par parcours vertical, pas par nombre de fichiers.


---

# ANNEXE 08 - Mémoire pédagogie et finance

_Source : `07_MEMOIRE_PEDAGOGIE_FINANCE.md`. Contenu conservé pour ne pas perdre les détails métier._


# Rewayah - mémoire produit pour pédagogie avancée et finance
Version : 22 septembre 2026. Ce document garde les décisions et dépendances des modules après la première cohorte. Il ne demande pas à l'agent de construire ces moteurs pendant un lot MVP.

## Pédagogie - cible après socle MVP
Le référentiel académique du 18 septembre 2026 est la source de détail pour la doctrine, sous réserve des deux validations explicitement requises : corpus de Salat/invocations et correspondance avec une édition précise de Nour al-Bayân. Conserver curriculum versionné, immuable après publication et dates d'effet. Texte canonique du Coran non modifiable par admin.

### Parcours et décisions
- Diagnostic D0 en deux temps : déclaratif, puis lecture/récitation réelle. F1-F4 : lettres et voyelles, décodage + récitations de prière, lecture appliquée et invocations, immersion Mushaf Hafs avec sourates 99 à 114 et Al-Fatiha. Gate avant orientation ; enfant proposé vers Hifz si prérequis stables et choix familial ; adulte choisit Tilawah ou Hifz sur information et recommandation.
- Tilawah T1-T6 : lecture complète du Coran en 6 tranches de 5 ajza, tajwid appliqué en couches J0-J6, examen sur trois passages non préparés de zones différentes. Hifz H0-H6 : Juz 30 puis autres ajza, avec trois flux visibles `Nouveau`, `À consolider`, `Révision longue`. I1 : rotation intégrale, contrôles aléatoires, certification seulement après consolidation ; certificat non équivalent à ijazah.
- Groupe : enseignement commun, progression individuelle bornée. Si majorité maîtrise une unité, le groupe avance ; renforcement ciblé, alerte si 40 % en difficulté, transfert humain si écart durable. Capacités et durées recommandées par le référentiel académique : enfants 5 élèves maximum/60 minutes dont pause, adultes 6/90 minutes, trois fois par semaine. L'ancien Control System indiquait enfants 4/45 et adultes 5/90 : NE PAS coder les deux comme une seule règle ; capacité/durée configurables par version de produit et validation opérationnelle avant publication de nouvelles classes.
- Compétences : `À renforcer`, `Acquis`, `Stable`. La stabilité exige observations espacées ; erreurs E1 mineures, E2 majeures, E3 critiques selon grille. L'enseignant décide de la qualité réelle, peut réduire ou suspendre le nouveau Hifz, motive brièvement une exception ; la famille peut demander réévaluation, sans imposer promotion ou rythme.
- Maison : carte `Avant le prochain cours`, au plus trois actions. Tuteur soutient la régularité, sans devenir professeur. Cliquer `fait` n'atteste aucune maîtrise. Présence, contenu affiché et file de récitation préremplissent le compte rendu ; enseignant corrige les seules exceptions. Pas de rapport narratif hebdomadaire imposé.
- Quatre Majalis annuels encouragent et étalonnent ; ils ne promeuvent pas automatiquement. Attestation au terme F4, certificat de lecture après T6, certificat Hifz après I1. Traces d'évaluation, contestation et jury autorisé. Contrôle enseignant par échantillon et anomalies sans classement public des élèves ni bonus fondé sur leur vitesse brute.
- Versionner cycles, unités, prérequis, plans individuels, état de cohorte, progression, tâches, évaluations et certificats. Les décisions humaines survivent aux changements d'enseignant et de groupe. Une modification de curriculum ne réécrit pas les anciens élèves.

### Limites et dépendances
Le référentiel sert à la lecture, récitation, mémorisation, prière et invocations nécessaires ; il ne crée pas un LMS de fiqh ou de sciences islamiques générales. Déployer la notation avancée seulement après tests inter-enseignants et validation scientifique du corpus. La « mémoire » conserve objectifs et architecture ; le MVP ne peut afficher que cycle actuel, travail, observations et progression simple correctement câblés.

## Finance - cible progressive, hors premier MVP opérationnel
Le Control System V2 du 13 septembre 2026 décrit la cible, mais les décisions de paiement plus récentes privilégient moins d'intermédiaires et des payouts Mobile Money en Afrique. Aucun prestataire unique n'est imposé. Pour diaspora Europe/Amérique du Nord, ne jamais créer une dépendance permanente à Stripe ; choisir fournisseurs sur faisabilité réelle (UK Ltd, pays, devises, frais, repli), couverture des payouts GNF/XOF, webhooks et contrats. Flutterwave a été écarté dans l'ancien ADR. Paiement initial : hors application enregistré/validé manuellement ; pas de débit ni payout inventé.

### Moteurs à conserver
1. Catalogue et politiques versionnées : prix par public/capacité/durée, validité, remises famille, bourse orphelin, personnel, partenariat, gratuité, motifs et approbation. La cible économique ancienne donne 50 USD mensuels, 90 USD pour deux et 40 USD par personne à partir de trois ; valeurs initiales à confirmer avant publication, jamais constantes dans Flutter. Un élève gratuit conserve coût et subvention visibles.
2. Facture et collecte : facture et lignes conservant les règles et arrondis, événement fournisseur signé/idempotent, paiement, remboursement, rapprochement, frais et FX daté. Séparer montant facturé, argent encaissé, revenu reconnu et trésorerie. Prévoir repli fournisseur selon disponibilité et pays sans forcer une chaîne de tiers inutile.
3. Crédits : ancien scénario 50 USD -> 30 unités -> 12 séances à 2,5 ; n'est pas une vérité universelle pour des séances enfants de 60 minutes. Valider l'équivalence prix/temps avant activation. Registre immuable grant/réserve/consomme/libère/expire/compense/reverse ; absence élève et cours assuré suivent politique versionnée ; absence enseignant sans remplacement donne compensation définie. Aucun solde corrigé par écrasement.
4. Salaire : taux initial de référence 4 USD/h, configurable et daté ; minutes payables prouvées, remplaçant payé pour séance assurée, professeur non pénalisé par le faible remplissage commercial. Bonus possibles pour fiabilité et obligations pédagogiques, jamais performance brute des élèves. Paie en brouillon, contrôle humain puis versement traçable.
5. Pilotage : résultat net visé de 2 000 USD mensuels pour l'académie après frais et salaires, avant distribution aux trois fondateurs. Cible de simulation, pas garantie. KPI de groupe, marge, occupation, rétention, recouvrement, charge enseignants, bourses, trésorerie ; chaque chiffre remonte aux écritures source avec fraîcheur affichée.
6. Prévision, scénarios, décisions, conseiller IA : moteurs déterministes pour calculer ; IA explique des snapshots autorisés et n'agit pas sur l'argent, les contrats, les sanctions ou les promotions. Simuler avant décision, montrer hypothèses, effet social et incertitude ; validation humaine des décisions sensibles. Historique des décisions et résultats.

### Dépendances et découpage après MVP
A : politiques et produits versionnés -> B : facturation et fournisseurs abstraits -> C : crédits avec revue des unités et durées -> D : rémunération -> E : registre de coûts et clôture -> F : métriques/forecast/scénarios -> G : recommandation et IA sous contrôle. Chaque lot teste idempotence, RLS, exactitude en unités monétaires, non-rétroactivité et reçus d'événements. Ne pas créer d'écritures financières factices dans la production pour « montrer » un tableau de bord.

## Arbitrages ouverts avant codage avancé
1. Capacités/durées commerciales pour les classes réellement ouvertes : recommandation académique 5/60 et 6/90 ; document économique plus ancien 4/45 et 5/90.
2. Activation d'enregistrement audio et conservation : anciens documents contradictoires.
3. Prix, unités, compensation et salaire selon l'offre réelle ; cohérence économique de la durée enfant retenue.
4. Texte et source des invocations/Salat ; édition et licence du contenu Nour al-Bayân ; source Mushaf Hafs vérifiée.
5. Fournisseur(s) collecte et payout effectivement admissibles et leur circuit de repli. Ces arbitrages se documentent dans la version de politique appropriée avant activation, sans bloquer les lots indépendants.


---

# ANNEXE 09 - Bible frontend UI/UX V2 complète

_Source : `REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md`. Contenu conservé pour ne pas perdre les détails métier._


# REWAYAH — FRONTEND / UI/UX / INTERACTION BIBLE V2
## Contrat d'exécution pour Claude Code — Flutter, Android, iOS, Web/Desktop

**Version:** 2.0  
**Statut:** NORME OBLIGATOIRE DU FRONTEND  
**Nature:** Design System + UX Governance + Interaction Contract + Adaptive Product Experience  
**Application:** Rewayah  
**Stack cible:** Flutter cross-platform  
**Agent d'exécution:** Claude Code

---

# 0. STATUT ET AUTORITÉ DU DOCUMENT

Ce fichier est un **contrat d'exécution frontend**.

Claude Code doit considérer les règles de cette Bible comme des contraintes obligatoires pour toute décision frontend, UI, UX, interaction, responsive et présentation des données.

## 0.1 Hiérarchie des sources de vérité

L'ordre de priorité est :

1. Contraintes de sécurité, conformité et confidentialité.
2. Spécifications métier officielles existantes de Rewayah.
3. Contrats backend/API/data models existants.
4. Présente Bible Frontend V2 pour toute décision d'expérience utilisateur et d'implémentation UI.
5. Design tokens, composants et conventions déjà présents dans le projet.
6. Documentation officielle Flutter / Material 3 / standards d'accessibilité.
7. Préférence utilisateur explicite validée dans le projet.
8. Jamais une intuition personnelle de Claude.

**Règle absolue :** si une spécification métier existante contredit une préférence visuelle, la règle métier prévaut.

**Règle absolue :** Claude ne doit jamais inventer une règle métier absente des spécifications. Il doit cependant appliquer les meilleures pratiques UX reconnues pour représenter correctement cette règle.

## 0.2 Interdiction d'improvisation

Claude ne doit jamais, sans justification et validation appropriée :

- supprimer une capacité métier ;
- masquer une action critique ;
- fusionner deux fonctions différentes pour « simplifier » ;
- changer la hiérarchie d'une information métier ;
- remplacer un composant partagé existant par un composant local ;
- inventer une couleur ;
- inventer un spacing ;
- inventer une taille de texte ;
- inventer un comportement de navigation ;
- inventer une stratégie responsive ;
- créer un nouveau pattern lorsque le design system possède déjà un pattern équivalent.

**Simplifier signifie réduire la charge cognitive, pas supprimer des fonctionnalités.**

## 0.3 Obligation de justification

Chaque dérogation doit être documentée dans le code ou le journal de décision :

- règle concernée ;
- raison de la dérogation ;
- impact ;
- alternative écartée ;
- portée exacte de l'exception.

Aucune exception silencieuse.

---

# 1. NORTH STAR UX DE REWAYAH

Rewayah est une application d'apprentissage du Coran et de gestion pédagogique dont le noyau d'expérience repose sur deux piliers :

1. **Classe en direct**
   - visioconférence ;
   - outils pédagogiques pour l'enseignant ;
   - document partagé interactif ;
   - Coran intégré nativement ;
   - bibliothèque documentaire ;
   - synchronisation des actions de l'enseignant avec les élèves.

2. **Présence et assiduité**
   - détection et gestion des états de présence ;
   - absence ;
   - retard ;
   - déconnexion / reconnexion ;
   - finalisation ;
   - historique et représentation pédagogique claire.

## 1.1 Principe de priorité

Dans une séance de cours :

**Contenu pédagogique primaire > contrôle pédagogique > chrome UI > configuration secondaire.**

Dans le lecteur Coran :

**Coran > focus de l'enseignant > navigation documentaire > contrôles secondaires.**

Dans la présence :

**État actuel > compréhension de l'état > justification > historique > configuration.**

---

# 2. USER ROLES ET CAPABILITIES

Claude doit utiliser les rôles définis par les spécifications existantes. Ne jamais déduire un rôle uniquement à partir de l'UI.

L'autorisation finale provient du système d'autorisation métier.

## 2.1 Principes

Un rôle n'est pas une permission unique.

Une capability peut dépendre simultanément de :

- rôle ;
- âge ;
- contexte de séance ;
- statut du compte ;
- statut de la session ;
- permissions de la classe ;
- permissions du document ;
- politique de confidentialité ;
- état réseau ;
- état du média.

## 2.2 UX adaptée aux rôles

L'interface doit être adaptée au besoin du rôle sans dupliquer inutilement le système de routage.

### Enfant

Priorité :

- lisibilité ;
- cibles tactiles très grandes ;
- faible densité ;
- forte réduction du chrome ;
- audio / feedback ;
- orientation pédagogique ;
- navigation minimale.

### Élève adulte

Priorité :

- lecture ;
- suivi de cours ;
- progression ;
- autonomie ;
- reprise rapide ;
- accès aux documents.

### Tuteur / parent

Priorité :

- visibilité ;
- progression ;
- cours ;
- présence ;
- informations essentielles.

### Enseignant

Priorité :

- contrôle du cours ;
- document partagé ;
- gestion des apprenants ;
- présence ;
- communication ;
- efficacité opérationnelle.

### Admin

Priorité :

- densité maîtrisée ;
- recherche ;
- tableaux ;
- filtres ;
- actions massives ;
- gestion avancée.

---

# 3. ARCHITECTURE D'INFORMATION

La structure des écrans doit être définie avant leur codage.

## 3.1 Chaque écran doit appartenir à un domaine fonctionnel

Exemples de domaines :

- Authentification ;
- Accueil / Dashboard ;
- Cours ;
- Classe en direct ;
- Bibliothèque ;
- Lecteur ;
- Progression ;
- Présence ;
- Profil ;
- Paramètres ;
- Administration.

Les spécifications existantes sont l'autorité pour le nommage final et l'arbre complet des écrans.

## 3.2 Data vs configuration

Ne jamais mélanger dans une même zone :

- données fréquemment consultées ;
- préférences ;
- configuration ;
- administration ;
- actions destructives.

### Données

Doivent vivre dans :

- écran de contenu ;
- dashboard ;
- page métier ;
- cartes / listes ;
- panneaux contextuels.

### Préférences

Doivent vivre dans :

- Profil ;
- Paramètres ;
- sous-pages de configuration.

### Filtres de contexte

Doivent rester proches du contenu qu'ils filtrent.

### Actions critiques

Doivent être proches de l'objet concerné ou dans un menu d'actions contextuel, avec confirmation adaptée si nécessaire.

---


# 3 BIS. ROUTAGE ET CONTINUITÉ DE SESSION

Le projet utilise un système de routage déclaratif cohérent, idéalement centralisé dans un routeur unique déjà défini par l'architecture du projet.

Ne pas créer plusieurs systèmes de navigation concurrents.

Les règles d'authentification, d'autorisation, de rôle et d'état du compte doivent être appliquées au niveau approprié du routage et des guards existants.

Ne jamais considérer la seule présence d'un token comme suffisante pour autoriser l'accès à une destination.

Les routes de salle de cours en direct qui sont définies comme éphémères par les spécifications ne doivent pas devenir des destinations partageables ordinaires.

Une sortie de session ne doit pas provoquer une perte silencieuse du contexte restaurable.

# 4. ARCHITECTURE DE NAVIGATION

## 4.1 Principe adaptatif

La navigation ne doit pas être déterminée par `Platform.isAndroid`, `Platform.isIOS` ou `isTablet` seuls.

Le layout doit être déterminé par **l'espace disponible**.

Le pattern de navigation doit pouvoir passer d'une NavigationBar à une NavigationRail ou à une navigation latérale lorsque l'espace augmente.

## 4.2 Mobile

Pour les destinations de haut niveau réellement prioritaires :

- NavigationBar / Bottom Navigation ;
- nombre de destinations limité ;
- ordre stable ;
- destination active clairement identifiable.

Ne jamais mettre dans la navigation principale :

- une préférence ;
- une option rare ;
- une fonction administrative isolée ;
- une action ponctuelle ;
- un réglage système.

## 4.3 Tablet

Utiliser une navigation plus persistante lorsque la largeur le justifie :

- NavigationRail ;
- rail étendu si pertinent ;
- contenu principal conservé comme zone dominante.

## 4.4 Desktop/Web

Utiliser selon le contexte :

- NavigationRail ;
- navigation latérale ;
- sidebar persistante ;
- top-level destinations.

Le menu ne doit pas réduire inutilement l'espace accordé au contenu principal.

---

# 5. CONTAINER DECISION MATRIX

Claude doit choisir le conteneur en fonction de la nature de l'action.

## 5.1 Page complète

Utiliser une page lorsque :

- l'information constitue un objectif principal ;
- l'utilisateur doit se concentrer ;
- la tâche est multi-étapes ;
- la tâche a besoin de navigation propre ;
- le contenu doit être partageable / restaurable / deep-linkable ;
- le contenu exige un grand espace vertical ou horizontal.

Exemples :

- profil détaillé ;
- bibliothèque ;
- lecteur ;
- historique de présence ;
- paramètres complexes.

## 5.2 Bottom Sheet

Utiliser une Bottom Sheet lorsque :

- le contexte courant doit rester visible ;
- l'utilisateur sélectionne ou ajuste quelque chose temporairement ;
- la tâche est courte ;
- la sélection s'applique immédiatement ou quasi immédiatement.

Exemples :

- filtres simples ;
- options d'affichage ;
- sélection courte ;
- actions secondaires.

## 5.3 Dialog

Utiliser un Dialog lorsque :

- l'action est critique ;
- la confirmation doit être explicite ;
- l'information exige l'attention immédiate ;
- le contexte ne peut pas attendre ;
- l'utilisateur doit faire un choix avant de continuer.

Éviter les Dialogs pour les tâches longues.

## 5.4 Menu / Popup contextuel

Utiliser un menu contextuel pour :

- actions secondaires ;
- options simples ;
- actions peu fréquentes ;
- choix contextuels attachés à un objet.

## 5.5 Card / Progressive Disclosure

Utiliser une Card extensible pour :

- détails secondaires ;
- informations optionnelles ;
- explications ;
- historique ;
- données supplémentaires dont la lecture n'est pas indispensable immédiatement.

## 5.6 Interdictions

Ne pas utiliser :

- un Dialog comme page miniature ;
- une Bottom Sheet pour une tâche complexe ;
- une Card pour cacher une capacité critique ;
- un dropdown pour remplacer un processus multi-étapes ;
- un écran entier pour une action ponctuelle triviale.

---

# 6. ZONING PHYSIQUE

Chaque écran doit être cartographié avant implémentation.

## 6.1 Zone AppBar / Header

Autorisé :

- navigation ;
- contexte ;
- titre ;
- action primaire ;
- action contextuelle ;
- identité ;
- statut bref.

Interdit :

- formulaires complexes ;
- longues listes ;
- plusieurs actions critiques concurrentes ;
- informations secondaires massives.

## 6.2 Zone de contenu principal

Doit contenir l'objet principal de la tâche.

Le contenu primaire doit avoir la plus grande priorité visuelle.

## 6.3 Zone secondaire

Peut contenir :

- metadata ;
- informations auxiliaires ;
- outils secondaires ;
- navigation contextuelle.

## 6.4 Zone d'action basse

Autorisé :

- action primaire persistante si nécessaire ;
- CTA contextuel ;
- navigation secondaire.

Ne pas y empiler toutes les actions disponibles.

## 6.5 Desktop à deux ou trois panneaux

Quand l'espace le permet :

```text
Navigation | Contenu primaire | Contexte / outils
```

Le panneau de contexte doit rester secondaire.

---

# 7. DESIGN TOKENS — RÈGLE ABSOLUE

## 7.1 Aucun hardcoding visuel dans les widgets

Interdit dans les écrans et composants métier :

- `Color(0xFF...)` ;
- HEX ;
- RGB manuel ;
- `fontSize: ...` arbitraire ;
- `fontWeight: ...` arbitraire ;
- spacing arbitraire ;
- radius arbitraire ;
- shadow arbitraire.

Les valeurs primitives doivent vivre dans les foundations / theme / token layer.

## 7.2 Couleurs

Utiliser prioritairement :

```dart
Theme.of(context).colorScheme
```

et les rôles sémantiques du thème.

Exemples de rôles :

- primary ;
- onPrimary ;
- primaryContainer ;
- onPrimaryContainer ;
- secondary ;
- onSecondary ;
- surface ;
- onSurface ;
- surfaceContainer* ;
- outline ;
- error ;
- onError.

Les couleurs métier supplémentaires doivent être exposées via un thème contrôlé, par exemple `ThemeExtension`, et jamais comme constantes locales dispersées.

## 7.3 Light et Dark

Il doit exister un véritable :

- `lightTheme` ;
- `darkTheme`.

Aucun composant ne doit connaître directement la palette Light ou Dark.

Le composant demande un rôle sémantique.

### Interdictions

- fond sombre dans un composant supposé neutre ;
- texte clair codé en dur ;
- shadow importée d'un ancien thème ;
- opacity arbitraire répétée partout ;
- contraste différent selon la page sans justification.

## 7.4 Tonalités et états

Les états :

- default ;
- hover ;
- focus ;
- pressed ;
- selected ;
- dragged ;
- disabled ;
- loading ;
- error ;
- success

doivent être dérivés du système de thème / composants.

---

# 8. TYPOGRAPHIE

La typographie passe par `TextTheme`.

Utiliser les rôles sémantiques plutôt que des tailles arbitraires :

- display ;
- headline ;
- title ;
- body ;
- label.

Exemples :

- titre de page → rôle headline approprié ;
- titre de section → rôle title ;
- corps → rôle body ;
- bouton → rôle label.

Toute exception doit être justifiée au niveau du composant design system.

---

# 9. SPACING, GRID ET DENSITÉ

Le système doit utiliser une échelle cohérente de spacing.

Base recommandée :

- 4 ;
- 8 ;
- 12 ;
- 16 ;
- 20 ;
- 24 ;
- 32 ;
- 40 ;
- 48 ;
- 64.

Claude ne doit pas créer systématiquement des valeurs telles que 13, 17, 19 ou 27 sans nécessité documentée.

Le spacing doit être basé sur le rôle :

- padding de page ;
- gap entre sections ;
- gap entre composants ;
- padding interne ;
- densité de tableau.

La densité doit diminuer lorsque l'utilisateur est un enfant ou lorsque la lisibilité prime.

---

# 10. SHAPE SYSTEM

Les formes doivent venir du système de thème / composant.

Utiliser les niveaux M3 de manière cohérente :

- ExtraSmall ;
- Small ;
- Medium ;
- Large ;
- ExtraLarge ;
- Full lorsque pertinent.

Ne pas utiliser un même rayon pour toute l'application.

## 10.1 Principes

- champs et petits contrôles → shapes petits ;
- cards → shapes intermédiaires ;
- surfaces immersives / dialogs / sheets → shapes plus grands ;
- avatar → shape full ;
- composants critiques → forme stable et prévisible.

## 10.2 M3 Expressive

L'expressivité est un accent, pas une obligation universelle.

Plus expressive :

- interfaces enfants ;
- moments pédagogiques ;
- cartes de progression ;
- surfaces de découverte.

Plus sobre :

- tableaux ;
- paramètres ;
- administration ;
- paiement ;
- actions destructives ;
- workflows à forte charge cognitive.

Une forme expressive ne doit jamais réduire :

- lisibilité ;
- affordance ;
- accessibilité ;
- cohérence ;
- densité utile.

---

# 11. COMPOSANTS ET RÉUTILISATION

Avant de créer un widget :

1. rechercher s'il existe déjà dans le projet ;
2. rechercher un composant M3 standard approprié ;
3. vérifier les composants partagés ;
4. seulement ensuite proposer une extension.

Un composant métier réutilisable doit être créé au niveau approprié.

Exemple de hiérarchie :

```text
Foundations
  ↓
Primitives
  ↓
Components
  ↓
Patterns
  ↓
Feature Components
  ↓
Screens
```

Ne pas enfouir du design system dans une page unique.

---


# 11 BIS. BIBLIOTHÈQUE DE COMPOSANTS PARTAGÉS EXISTANTS

Lorsque les composants suivants existent dans le projet, ils doivent être considérés comme les implémentations de référence et réutilisés avant toute création locale :

- `Pressable` : interaction standard de type tap/click ;
- `BentoTile` : conteneurs / grilles lorsque le pattern Bento fait partie du design system ;
- `ChoiceCardGroup` : choix structurés lorsque prévu par les spécifications ;
- `AudioLabel` : interfaces enfant nécessitant une aide audio ou une lecture accessible ;
- `PermanentNotice` : notices persistantes lorsqu'elles sont requises par la spécification ;
- `AvatarTile` : représentation d'identité avec fallback approprié.

Claude doit vérifier les interfaces réelles de ces composants avant de les utiliser.

## Pressable

Pour les interactions utilisateur ordinaires, `Pressable` doit remplacer les implémentations ad hoc par `GestureDetector` ou `InkWell` lorsque sa responsabilité couvre le même besoin.

Les comportements de scale, feedback tactile, focus, hover et pressed doivent rester centralisés dans le composant partagé.

Le haptic feedback ne doit pas être forcé sur toutes les plateformes ni sur toutes les interactions. Il doit respecter le composant, la plateforme et l'accessibilité.

`GestureDetector` reste acceptable pour une interaction gestuelle qui n'est pas sémantiquement un bouton ou une action pressable standard : dessin, geste de navigation, interaction pointer/drag ou autre cas explicitement justifié.

## BentoTile

Ne pas utiliser Bento comme décoration universelle.

Les variantes et gaps doivent respecter le design system existant.

## ChoiceCardGroup

Utiliser ce pattern lorsque plusieurs choix doivent être présentés comme décisions de produit ou de configuration.

Ne pas transformer un choix simple en formulaire inutilement complexe.

## AudioLabel

Pour les interfaces enfant, le recours à des libellés / aides audio doit suivre les besoins réels du produit et les règles d'accessibilité.

## PermanentNotice

Si une notice est définie comme permanente par les spécifications, ne pas ajouter au niveau UI une logique locale permettant de la supprimer arbitrairement.

## AvatarTile

Les données privées et les URLs sensibles doivent suivre les règles de sécurité du backend et du projet.

# 12. ÉTATS D'INTERACTION

Tout composant interactif doit prévoir les états pertinents :

- default ;
- hovered ;
- focused ;
- pressed ;
- selected ;
- disabled ;
- loading ;
- error ;
- success ;
- unavailable.

L'état doit être perceptible :

- visuellement ;
- sémantiquement ;
- au clavier ;
- au lecteur d'écran lorsque pertinent.

---

# 13. ACCESSIBILITÉ

L'accessibilité est une contrainte fonctionnelle.

## 13.1 Cibles

Minimum général adulte recommandé : 44 logical pixels / points selon le contexte.

Mode enfant : utiliser des cibles sensiblement plus grandes lorsque cela améliore la sécurité d'interaction.

La taille réelle doit rester compatible avec les contraintes du composant, du système et du device.

## 13.2 Text scaling

L'interface doit survivre à un agrandissement du texte.

Interdit :

- hauteur fixe fragile ;
- texte coupé ;
- overflow masqué pour « faire tenir » ;
- boutons non adaptatifs.

## 13.3 Semantics

Chaque contrôle important doit avoir :

- nom accessible ;
- rôle clair ;
- état ;
- valeur lorsque pertinente ;
- action compréhensible.

## 13.4 Clavier

Web/Desktop :

- ordre de focus cohérent ;
- focus visible ;
- navigation clavier ;
- Escape pour sortir des surfaces modales lorsque pertinent ;
- piège de focus correctement géré dans les Dialogs ;
- raccourcis cohérents.

## 13.5 Motion

Respecter les préférences de réduction de mouvement lorsque disponibles.

Une animation ne doit jamais être requise pour comprendre une information critique.

---

# 14. RTL / L10N / I18N

Rewayah doit être structurellement capable de gérer RTL et LTR.

Interdit lorsque le comportement peut être directionnel :

- `left` / `right` codés en dur ;
- icônes directionnelles non adaptées ;
- ordre des contrôles non réfléchi en RTL.

Préférer :

- start / end ;
- `EdgeInsetsDirectional` ;
- `AlignmentDirectional` ;
- comportements conscients de la direction.

Tester au minimum :

- arabe ;
- français ;
- anglais.

Prévoir les textes plus longs, nombres, dates, heures, pluriels et contenus mixtes arabe/latin.

---

# 15. RESPONSIVE / ADAPTIVE SYSTEM

Le layout est déterminé par l'espace disponible.

## 15.1 Principes

Le responsive doit adapter :

- navigation ;
- nombre de colonnes ;
- largeur du contenu ;
- densité ;
- disposition des panneaux ;
- visibilité des outils secondaires ;
- taille des Dialogs ;
- position des contrôles.

## 15.2 Largeurs

Utiliser des familles de largeurs plutôt qu'une logique rigide de device :

- compact ;
- medium ;
- expanded ;
- large / extra-large selon les besoins du produit.

Les seuils exacts doivent être centralisés dans une configuration du design system et jamais dupliqués dans les pages.

## 15.3 Content max width

Sur desktop, ne pas étirer indéfiniment le contenu de lecture ou les formulaires.

Utiliser des largeurs maximales cohérentes.

---

# 16. MOTION

Les transitions doivent :

- indiquer la relation spatiale ;
- confirmer une action ;
- révéler une conséquence ;
- réduire l'incertitude.

Éviter les animations décoratives répétitives.

Les animations critiques doivent être :

- courtes ;
- cohérentes ;
- interruption-safe ;
- accessibles.

---

# 17. NOTIFICATIONS ET FEEDBACK

## SnackBar

Pour :

- feedback bref ;
- confirmation non critique ;
- résultat d'une action ;
- information temporaire.

## Banner

Pour :

- problème contextuel persistant ;
- information importante nécessitant visibilité ;
- état réseau ;
- état système affectant plusieurs actions.

## Badge

Pour :

- contenu non lu ;
- compteurs ;
- statut nécessitant une attention légère.

## Dialog

Pour :

- confirmation critique ;
- action destructive ;
- interruption nécessaire.

Ne pas utiliser un SnackBar pour une information que l'utilisateur doit obligatoirement voir et comprendre.

---


# 17 BIS. FEEDBACK TACTILE ET INTERACTION MULTI-PLATEFORME

Le feedback tactile est une capacité adaptative.

Règles :

- ne pas supposer qu'un haptic existe sur Web/Desktop ;
- ne pas imposer une intensité uniforme à toutes les actions ;
- réserver les feedbacks tactiles forts aux actions qui bénéficient réellement d'une confirmation ;
- ne pas utiliser l'haptique comme substitut à une information visuelle ou sémantique ;
- respecter les différences de plateforme.

# 18. EMPTY / LOADING / ERROR / OFFLINE

Chaque écran métier doit définir :

- normal ;
- loading ;
- empty ;
- error ;
- degraded/offline lorsque pertinent.

## Empty

Doit expliquer :

1. ce qui manque ;
2. pourquoi c'est vide ;
3. ce que l'utilisateur peut faire.

Inclure une action primaire lorsque pertinente.

## Loading

Utiliser un skeleton fidèle à la structure réelle de l'écran lorsqu'une attente substantielle est attendue.

Éviter le spinner seul au centre pour tout le contenu.

## Error

Une erreur doit être récupérable lorsque possible.

Afficher :

- problème compréhensible ;
- conséquence ;
- action de récupération ;
- détails techniques seulement si nécessaires.

## Offline

Ne pas désactiver arbitrairement toute navigation.

Les fonctions réseau peuvent :

- se mettre en attente ;
- utiliser un cache ;
- afficher leur dégradation ;
- demander une reconnexion.

Toutes les opérations mises en file doivent respecter les règles métier d'idempotence et de cohérence.

---

# 19. LIVE CLASSROOM — MODÈLE UX

La salle de cours n'est pas un écran vidéo ordinaire.

Elle est composée de sous-systèmes :

```text
Live Session
├── Media
├── Shared Document Stage
├── Teacher Controls
├── Attendance
├── Participant Context
└── Session State
```

Chaque sous-système doit pouvoir se dégrader indépendamment lorsque techniquement possible.

Exemples :

- vidéo indisponible → document encore utilisable ;
- document indisponible → vidéo encore utilisable ;
- connexion faible → afficher la dégradation sans détruire les fonctions locales ;
- reconnexion → restaurer l'état cohérent.

---

# 20. LIVE CLASSROOM — HIÉRARCHIE VISUELLE

## Mobile portrait

Priorité :

1. média actif selon le contexte ;
2. contenu partagé / pédagogique ;
3. action essentielle ;
4. contrôles secondaires.

Ne jamais laisser une toolbar permanente couvrir une zone importante du Coran.

## Mobile landscape

Autoriser une disposition plus riche :

- vidéo ;
- document ;
- contrôles contextuels.

## Tablet

Permettre un véritable split lorsque l'espace le permet.

## Desktop

Pattern privilégié :

```text
┌──────────────┬──────────────────────────────┐
│              │                              │
│ VIDEO /      │     SHARED DOCUMENT STAGE   │
│ TEACHER TOOLS│                              │
│              │                              │
├──────────────┴──────────────────────────────┤
│ SESSION / CONTROLS / PARTICIPANTS           │
└─────────────────────────────────────────────┘
```

L'implémentation exacte dépend des contraintes techniques et des spécifications existantes.

---

# 21. SHARED DOCUMENT STAGE

Le document partagé est un **espace pédagogique interactif**, pas un simple fichier affiché.

Il doit être traité comme un sous-système possédant son propre état.

Nom architectural recommandé :

`SharedDocumentStage`

## 21.1 Fonctionnalités attendues

Le stage doit pouvoir gérer selon les spécifications :

- document courant ;
- type de document ;
- bibliothèque ;
- page ;
- verset ;
- focus ;
- pointer ;
- annotation éventuelle ;
- zoom ;
- navigation précédente / suivante ;
- mode page ;
- mode focus ;
- mode immersif.

## 21.2 Priorité

Le document devient le **contenu primaire** lorsque la pédagogie de la séance porte sur celui-ci.

---

# 22. READER IMMERSIVE MODE

Le mode immersif est obligatoire pour les expériences de lecture où le document constitue la tâche principale, particulièrement sur mobile.

## 22.1 Règle fondamentale

Le Coran ne doit pas être traité comme une petite Card entourée de contrôles.

En mode lecture :

```text
CONTENT > CHROME
```

## 22.2 Mobile

Le mode immersif doit pouvoir utiliser presque toute la surface disponible.

Les contrôles secondaires :

- se masquent ;
- peuvent être révélés par une interaction familière ;
- n'obstruent pas durablement le texte.

## 22.3 Contrôles visibles

Lorsqu'ils sont révélés :

- retour ;
- position ;
- navigation minimale ;
- action liée au contexte ;
- bouton de sortie du mode immersif si nécessaire.

Les contrôles avancés doivent être secondaires et ne doivent pas rester superposés au texte en permanence.

## 22.4 Desktop

Les contrôles peuvent être plus persistants lorsque l'espace le permet.

---

# 23. QURAN READER — PRINCIPE STRUCTUREL

Le Coran intégré dans Rewayah ne doit pas être modélisé comme un PDF.

Il doit être traité comme un contenu structuré :

```text
Quran
├── Mushaf
├── Edition / Script
├── Chapter
├── Juz
├── Page
├── Verse
├── Word
└── Layout Metadata
```

La couche UI ne doit pas dépendre d'un fichier PDF.

Le rendu doit être découplé du modèle de données.

## 23.1 Mushaf / pagination

La pagination dépend du Mushaf choisi.

Le système doit conserver la relation entre :

- Mushaf ;
- page ;
- verset ;
- éventuellement ligne / mot.

Les références externes sur les APIs Quran montrent notamment que plusieurs Mushafs disposent de mappings page/verset différents et que certaines représentations sont conçues pour obtenir un rendu fidèle du Mushaf.

---

# 24. QURAN READER — ÉTATS PERSONNELS VS PARTAGÉS

Cette distinction est obligatoire.

## 24.1 Shared Classroom State

Exemples :

- document sélectionné par l'enseignant ;
- page présentée ;
- verset ciblé ;
- focus pédagogique ;
- pointer ;
- annotation partagée ;
- mode d'affichage pédagogique.

## 24.2 Student Personal State

Exemples :

- dernière position de lecture ;
- page personnelle ;
- verset personnel ;
- scroll offset si pertinent ;
- zoom personnel ;
- préférences de lecture ;
- dernier point confirmé.

## 24.3 Règle critique

Une action partagée de l'enseignant ne doit pas détruire silencieusement le progrès personnel de l'élève.

---

# 25. TEACHER FOLLOW MODE

L'élève doit pouvoir suivre la position de l'enseignant lorsque le cours l'exige.

État recommandé :

`FOLLOWING_TEACHER`

Lorsque l'élève quitte temporairement cette position :

`FOLLOWING_TEACHER` → `STUDENT_EXPLORING`

L'UI doit alors pouvoir proposer :

`Retour au point de l'enseignant`

Lorsque l'élève utilise cette action :

`STUDENT_EXPLORING` → `FOLLOWING_TEACHER`

Ne pas imposer une téléportation silencieuse si cela détruit l'action locale de l'élève.

---

# 26. TEACHER DOCUMENT CONTROLS

Les outils doivent être organisés selon la fréquence d'usage.

## Niveau 1 — contrôle pédagogique immédiat

- page précédente ;
- page suivante ;
- aller à une page ;
- pointer / focus ;
- affichage approprié.

## Niveau 2 — interaction pédagogique

- verse focus ;
- annotation si supportée ;
- mode de lecture ;
- affichage détaillé.

## Niveau 3 — configuration

- préférences ;
- édition ;
- options avancées.

## Règle

Le professeur ne doit jamais avoir besoin d'ouvrir trois menus pour effectuer une action qu'il répète toutes les minutes.

Inversement, les outils rares ne doivent pas saturer la barre principale.

---

# 27. RESUME / RESTAURATION DE POSITION

La reprise de lecture est une fonctionnalité de premier ordre.

Le système doit distinguer :

- document ouvert ;
- document réellement consulté ;
- dernière position confirmée.

Une position peut comprendre :

```text
document_id
edition_id
mushaf_id
page_number
chapter_number
verse_number
word_position lorsque pertinent
scroll_offset lorsque pertinent
zoom_level
timestamp
```

L'état exact dépend du modèle métier existant.

## 27.1 Règle de restauration

À la prochaine ouverture :

1. restaurer le contexte documentaire ;
2. restaurer la position ;
3. restaurer les préférences compatibles ;
4. afficher un accès explicite à la reprise ;
5. éviter de réinitialiser inutilement l'utilisateur à la première page.

---

# 28. RESUME UX

La reprise doit pouvoir être exposée directement dans les points d'entrée appropriés :

```text
Continuer
Sourate ...
Page ...
Verset ...
[Reprendre]
```

Ne pas cacher une fonction aussi fréquente dans Paramètres.

---

# 29. ATTENDANCE UX

Les règles métier d'assiduité existantes sont l'autorité.

La Bible impose principalement leur **représentation UX**.

## 29.1 États possibles à représenter

Selon le moteur métier, une UX robuste peut devoir représenter des états tels que :

- scheduled ;
- waiting ;
- joining ;
- present ;
- late ;
- disconnected ;
- reconnecting ;
- reconnected ;
- left ;
- absent ;
- excused ;
- pending confirmation ;
- manually overridden ;
- finalized.

Ne jamais inventer ou supprimer un état métier existant.

## 29.2 Machine à états

L'interface doit représenter les transitions, pas seulement une couleur finale.

Exemple :

```text
Present
  ↓
Network lost
  ↓
Reconnecting
  ↓
Reconnected
  ↓
Present
```

## 29.3 Information de contexte

Quand une information est nécessaire à la compréhension de l'état, présenter :

- état actuel ;
- heure utile ;
- contexte ;
- action possible ;
- historique lorsque nécessaire.

Une simple couleur ne doit jamais être l'unique représentation d'un état critique.

---

# 30. ATTENDANCE — ENSEIGNANT

L'enseignant doit comprendre rapidement :

- qui est présent ;
- qui est en retard ;
- qui est absent ;
- qui a perdu la connexion ;
- ce qui est provisoire ;
- ce qui est finalisé.

Les détails doivent être consultables sans surcharger la vue principale.

---

# 31. ATTENDANCE — ÉLÈVE

L'élève doit comprendre :

- son état ;
- si une reconnexion est nécessaire ;
- si une action est requise ;
- si le cours est encore actif.

Ne pas afficher des détails administratifs inutiles.

---

# 32. GRACEFUL DEGRADATION

Chaque sous-système doit définir son comportement en cas de défaillance.

### Media failure

Conserver autant que possible les fonctions pédagogiques non dépendantes du média.

### Document failure

Conserver la séance et les fonctions indépendantes.

### Attendance service failure

Ne pas présenter un état final faux si la source de vérité n'est pas disponible.

### Network failure

Afficher la dégradation clairement.

### Reconnection

Restaurer l'état métier et visuel autant que possible sans recréer inutilement tout l'écran.

---

# 33. SÉCURITÉ ET CONFIDENTIALITÉ UX

Les données sensibles ne doivent apparaître que dans les contextes autorisés.

Ne pas afficher :

- email ;
- téléphone ;
- données personnelles ;
- métadonnées privées

simplement parce qu'elles sont disponibles dans le backend.

La disponibilité d'une donnée dans une API n'est pas une autorisation d'affichage.

---

# 34. MEDIA UX

Caméra et microphone doivent respecter les politiques métier.

Pour la séance :

- état clair ;
- état off facilement compréhensible ;
- permission système séparée de l'état applicatif ;
- feedback de connexion ;
- récupération lors d'erreur.

Une caméra interdite par policy ne doit pas être simplement « cachée par hasard ».

Le comportement doit être déterministe.

---

# 35. NAVIGATION DANS LA CLASSE

La salle de cours doit protéger la continuité de la session.

Avant de quitter :

- avertir seulement lorsque nécessaire ;
- distinguer navigation temporaire et sortie définitive ;
- préserver les états restaurables ;
- éviter de détruire une session active par un simple tap accidentel.

---

# 36. TASK DEPTH — MAXIMUM 3 ACTIONS LORSQUE LE CONTEXTE LE PERMET

Pour les objectifs fréquents, viser :

```text
Entrée
→ destination
→ action
```

La limite de trois actions n'est pas une excuse pour supprimer des fonctionnalités.

Elle doit être atteinte via :

- bons points d'entrée ;
- contexte ;
- raccourcis ;
- actions primaires ;
- navigation adaptée ;
- progressive disclosure.

Chaque tâche fréquente doit avoir un chemin documenté.

---

# 37. DESIGN DES FORMULAIRES

Éviter les formulaires inutilement longs.

Principes :

- regrouper logiquement ;
- utiliser le bon type de champ ;
- valider au moment approprié ;
- afficher les erreurs près du champ ;
- conserver les valeurs valides ;
- éviter les resets accidentels ;
- utiliser la navigation clavier sur desktop.

---

# 38. TABLES ET DATA-DENSE UI

Pour l'administration :

- hiérarchiser les colonnes ;
- rendre les actions contextuelles ;
- conserver une densité lisible ;
- éviter la couleur comme seul indicateur ;
- prévoir tri et filtres conformément aux spécifications ;
- permettre un affichage adapté aux petits écrans.

Sur mobile, une table desktop ne doit pas être compressée artificiellement en une ligne illisible.

---

# 39. PERFORMANCE PERÇUE

La perception de vitesse est une partie de l'UX.

Obligatoire lorsque pertinent :

- skeleton fidèle ;
- conservation du layout ;
- cache ;
- restauration d'état ;
- pagination ;
- lazy loading ;
- images optimisées ;
- éviter les reconstructions inutiles ;
- ne pas charger tout un catalogue pour afficher un seul élément.

Mais la performance ne doit jamais dégrader la cohérence métier ou l'exactitude du Coran.

---

# 40. ÉTAT UI VS ÉTAT MÉTIER

Chaque state doit être classé.

### Business State

Exemples :

- présence ;
- session ;
- document partagé ;
- droits ;
- progression.

### UI State

Exemples :

- menu ouvert ;
- sheet ouverte ;
- focus visuel ;
- scrollbar ;
- mode compact.

### Personal Preference

Exemples :

- thème ;
- préférence de zoom ;
- préférences de lecture.

Ne pas stocker arbitrairement un état métier dans une variable d'UI locale.

---

# 41. RESTAURATION D'ÉTAT

Lorsqu'une application est interrompue puis reprise, restaurer lorsque pertinent :

- route ;
- session ;
- document ;
- position ;
- sélection ;
- mode d'affichage ;
- formulaire non soumis lorsque sûr.

Ne pas restaurer aveuglément :

- un état expiré ;
- une permission devenue invalide ;
- une session terminée ;
- une action déjà consommée.

---

# 42. ANTI-PARESSE / ANTI-SIMPLIFICATION

Claude doit considérer comme une violation :

> « J'ai simplifié l'écran en retirant cette fonction. »

si la fonction existe dans les spécifications et n'est pas réellement supprimée par une décision produit.

## 42.1 Remplacer la suppression par :

- progressive disclosure ;
- regroupement ;
- toolbar contextuelle ;
- menu secondaire ;
- adaptive layout ;
- mode focus ;
- mode immersif.

## 42.2 Avant de supprimer un élément

Claude doit se demander :

1. Est-il métier ?
2. Est-il critique ?
3. Est-il fréquent ?
4. Existe-t-il déjà ailleurs ?
5. Est-il contextuel ?
6. Peut-il être révélé progressivement ?
7. Son absence casse-t-elle un parcours ?

Si oui, ne pas supprimer sans validation.

---

# 43. ANTI-HALLUCINATION FRONTEND

Claude ne doit jamais inventer :

- une route métier ;
- une permission ;
- un statut ;
- une source de données ;
- une structure de document ;
- une action backend ;
- une règle de présence.

Lorsqu'une information n'est pas connue :

1. rechercher dans les fichiers/specs du projet ;
2. rechercher dans les composants existants ;
3. rechercher les contrats backend existants ;
4. seulement ensuite proposer une hypothèse explicitement marquée ;
5. ne jamais transformer l'hypothèse en règle silencieuse.

---

# 44. PROTOCOLE AVANT CODAGE

Avant d'écrire le code d'un nouvel écran :

## Étape 1 — comprendre

Identifier :

- rôle ;
- objectif ;
- contexte ;
- données ;
- actions ;
- états ;
- contraintes.

## Étape 2 — rechercher

Chercher :

- spec métier ;
- route existante ;
- composant existant ;
- token existant ;
- pattern existant.

## Étape 3 — zoning

Produire textuellement :

```text
SCREEN
├── Header
├── Primary Content
├── Secondary Content
├── Actions
└── Responsive Variants
```

## Étape 4 — interaction

Documenter :

- tap ;
- long press si pertinent ;
- hover ;
- keyboard ;
- focus ;
- loading ;
- error ;
- recovery.

## Étape 5 — validation

Le zoning et le modèle d'interaction doivent être validés avant implémentation lorsqu'une validation utilisateur est prévue dans le workflow.

## Étape 6 — implémentation

Seulement après accord.

---

# 45. COMMENTAIRES DE CONFORMITÉ

Le code doit documenter les décisions structurantes.

Exemple :

```dart
// [M3-COLOR]
// Uses semantic ColorScheme roles.
// No hardcoded color is permitted in feature UI.
//
// [A11Y]
// Focusable control with accessible semantics.
//
// [RESPONSIVE]
// Compact navigation pattern selected from available width.
//
// [QURAN-STAGE]
// Shared document state is separated from personal reading state.
```

Ne pas mettre de longs commentaires évidents partout.

Les commentaires doivent expliquer les règles importantes.

---

# 46. QA GATE — UN ÉCRAN N'EST PAS TERMINÉ TANT QUE

Claude doit vérifier :

## Architecture

- [ ] route correcte ;
- [ ] rôle correct ;
- [ ] bonne source de données ;
- [ ] aucune règle métier inventée.

## Design

- [ ] ColorScheme utilisé ;
- [ ] TextTheme utilisé ;
- [ ] spacing conforme ;
- [ ] shape conforme ;
- [ ] states définis ;
- [ ] aucune couleur hardcodée ;
- [ ] aucune taille arbitraire non justifiée.

## Responsive

- [ ] compact ;
- [ ] medium ;
- [ ] expanded ;
- [ ] orientation pertinente ;
- [ ] desktop ;
- [ ] navigation adaptée.

## Accessibility

- [ ] semantics ;
- [ ] focus ;
- [ ] clavier ;
- [ ] touch targets ;
- [ ] text scaling ;
- [ ] contraste ;
- [ ] reduced motion si pertinent.

## UX

- [ ] empty ;
- [ ] loading ;
- [ ] error ;
- [ ] offline ;
- [ ] recovery ;
- [ ] feedback ;
- [ ] max-depth des tâches fréquentes.

## Dark / Light

- [ ] Light réellement cohérent ;
- [ ] Dark réellement cohérent ;
- [ ] aucun mélange de surfaces ;
- [ ] aucun texte illisible ;
- [ ] aucun composant reposant sur une couleur d'un autre thème.

## États métier

- [ ] états transitoires ;
- [ ] erreurs ;
- [ ] reconnexion ;
- [ ] restauration ;
- [ ] permissions.

---

# 47. QA SPÉCIALE LIVE CLASSROOM

Pour chaque modification de la salle :

- [ ] mobile portrait ;
- [ ] mobile landscape ;
- [ ] tablet ;
- [ ] desktop ;
- [ ] vidéo active ;
- [ ] vidéo indisponible ;
- [ ] document actif ;
- [ ] document indisponible ;
- [ ] réseau faible ;
- [ ] déconnexion ;
- [ ] reconnexion ;
- [ ] enseignant ;
- [ ] élève ;
- [ ] sortie de session ;
- [ ] restauration.

---

# 48. QA SPÉCIALE QURAN READER

Vérifier :

- [ ] vrai contenu structuré ;
- [ ] Mushaf correct ;
- [ ] pagination cohérente ;
- [ ] RTL ;
- [ ] rendu sans PDF ;
- [ ] navigation page ;
- [ ] focus verset ;
- [ ] actions enseignant ;
- [ ] état partagé séparé de l'état personnel ;
- [ ] suivi enseignant ;
- [ ] sortie temporaire du suivi ;
- [ ] retour vers enseignant ;
- [ ] zoom ;
- [ ] mode immersif ;
- [ ] contrôles masquables ;
- [ ] restauration de position ;
- [ ] aucune destruction du progrès personnel par une action partagée.

---

# 49. QA SPÉCIALE ATTENDANCE

Vérifier selon les états définis par le métier :

- [ ] arrivée ;
- [ ] présent ;
- [ ] retard ;
- [ ] déconnexion ;
- [ ] reconnexion ;
- [ ] départ ;
- [ ] absence ;
- [ ] exception ;
- [ ] override ;
- [ ] finalisation.

L'affichage doit rester compréhensible même lorsque plusieurs élèves ont simultanément des états différents.

---

# 50. SELF-REVIEW OBLIGATOIRE DE CLAUDE

Avant de déclarer une feature terminée, Claude doit répondre silencieusement à cette liste :

1. Ai-je utilisé un composant existant ?
2. Ai-je inventé quelque chose ?
3. Ai-je supprimé quelque chose ?
4. Ai-je mis une donnée dans un mauvais endroit ?
5. Ai-je utilisé un hardcode visuel ?
6. Le layout fonctionne-t-il en Light et Dark ?
7. Que se passe-t-il sans données ?
8. Que se passe-t-il pendant le chargement ?
9. Que se passe-t-il si le réseau tombe ?
10. Que se passe-t-il si l'utilisateur revient ?
11. Que se passe-t-il au clavier ?
12. Que voit l'enfant ?
13. Que voit l'enseignant ?
14. Qu'est-ce qui est partagé ?
15. Qu'est-ce qui est personnel ?
16. Le contenu primaire est-il réellement prioritaire ?
17. Ai-je caché une capacité critique ?
18. La tâche fréquente est-elle trop profonde ?
19. Est-ce que le responsive est réellement adaptatif ?
20. Quel scénario d'erreur n'ai-je pas traité ?

---

# 51. PRINCIPLE DE NON-RÉGRESSION

Toute nouvelle feature doit préserver :

- navigation existante ;
- composants partagés ;
- tokens ;
- accessibilité ;
- dark mode ;
- light mode ;
- responsive ;
- état métier ;
- confidentialité ;
- restauration.

Une amélioration visuelle qui casse une fonctionnalité métier est une régression.

---

# 52. RÈGLE DE SOBRIÉTÉ INTELLIGENTE

Le design doit être :

- clair ;
- moderne ;
- expressif lorsque pertinent ;
- professionnel ;
- cohérent ;
- pédagogique.

Mais l'esthétique ne doit jamais prendre le dessus sur :

- exactitude ;
- lisibilité ;
- vitesse d'interaction ;
- compréhension ;
- accessibilité ;
- contenu religieux.

Pour le Coran en particulier :

**le texte et la lisibilité priment sur l'ornement.**

---

# 53. RÈGLE DE VÉRITÉ DU CORAN

Toute représentation du Coran doit privilégier l'exactitude du contenu et du rendu.

Interdit :

- reformater arbitrairement le texte pour « faire joli » ;
- couper un verset de façon ambiguë ;
- modifier le texte ;
- substituer un rendu approximatif lorsque les données fiables existent ;
- utiliser un fichier PDF comme substitut au modèle de contenu structuré lorsque le produit est conçu pour une lecture interactive.

La sélection d'une représentation du Mushaf et de ses ressources doit suivre les spécifications de Rewayah et les sources autorisées du projet.

---

# 54. PRINCIPLE DE CONTINUITÉ PÉDAGOGIQUE

Une action d'interface doit préserver la continuité du cours.

L'enseignant ne devrait pas devoir :

- reconstruire manuellement le contexte ;
- retrouver une page ;
- rechercher un élève ;
- rouvrir un outil complexe

pour une action répétitive.

L'élève doit pouvoir reprendre :

- la session ;
- le document ;
- son point de lecture ;
- son contexte pédagogique

avec un minimum de friction.

---

# 55. PRINCIPLE « PROGRESSIVE DISCLOSURE, NOT PROGRESSIVE HIDING »

Ne pas cacher une fonction simplement pour réduire l'encombrement.

La bonne progression est :

```text
Essentiel
↓
Contextuel
↓
Avancé
```

et non :

```text
Essentiel
↓
Menu
↓
Sous-menu
↓
Sous-menu
↓
Fonction
```

Les fonctions importantes doivent rester découvrables.

---

# 56. DÉCISIONS PAR CONTEXTE — EXEMPLES CANONIQUES

## « L'élève veut lire le Coran »

→ ouvrir le lecteur.

## « L'élève veut seulement ajuster le zoom »

→ contrôle contextuel / sheet appropriée.

## « L'enseignant veut pointer un verset »

→ outil direct dans le contexte de la séance.

## « L'enseignant veut modifier une préférence durable »

→ paramètres ou configuration appropriée.

## « L'utilisateur quitte une session critique »

→ confirmation seulement si une conséquence réelle existe.

## « Aucun cours n'est disponible »

→ Empty State utile, jamais écran blanc.

---

# 57. RÈGLE DE CONTEXTE

Une action doit apparaître là où son contexte est déjà compris.

Exemple :

- action du document → lecteur ;
- action de séance → salle de cours ;
- réglage global → paramètres ;
- préférence de lecture → lecteur ou paramètres selon fréquence ;
- configuration administrative → administration.

Éviter de déplacer une fonction vers un menu global si elle est intrinsèquement contextuelle.

---

# 58. RÈGLE DE COMPATIBILITÉ DES PLATEFORMES

Flutter partage le code, mais l'expérience n'a pas besoin d'être visuellement identique au pixel sur toutes les tailles.

La cohérence recherchée est :

**même modèle mental + même hiérarchie + adaptation de présentation.**

Ne pas forcer le desktop à imiter un téléphone.

Ne pas forcer le téléphone à afficher une UI desktop compressée.

---

# 59. SOURCES ET RÉFÉRENCES DE CONCEPTION

Les décisions doivent être alignées en priorité sur les documentations officielles et standards de référence.

## Flutter

- ThemeData / ColorScheme :
  https://api.flutter.dev/flutter/material/ThemeData-class.html
  https://api.flutter.dev/flutter/material/ThemeData/colorScheme.html
  https://api.flutter.dev/flutter/material/ThemeData/ThemeData.from.html

- Material 3 dans Flutter :
  https://api.flutter.dev/flutter/material/ThemeData/useMaterial3.html

- Adaptive / Responsive :
  https://docs.flutter.dev/ui/adaptive-responsive/general
  https://docs.flutter.dev/ui/adaptive-responsive/large-screens

## Material Design

- https://m3.material.io/
- https://m3.material.io/foundations/layout/understanding-layout
- https://m3.material.io/components/navigation-bar/overview
- https://m3.material.io/components/navigation-rail/overview
- https://m3.material.io/foundations/accessible-design/overview

## W3C / WCAG

- https://www.w3.org/TR/WCAG22/
- https://www.w3.org/WAI/standards-guidelines/wcag/new-in-22/

## Quran Foundation

- Page Layout :
  https://api-docs.quran.com/docs/tutorials/fonts/page-layout/

- Font Rendering :
  https://api-docs.quran.com/docs/tutorials/fonts/font-rendering/

- Mushaf Fonts and Images :
  https://api-docs.quran.com/legal/mushaf-fonts-and-images/

Ces ressources ne remplacent pas les spécifications officielles de Rewayah.

---

# 60. PROTOCOLE FINAL D'EXÉCUTION

Claude doit suivre cette boucle :

```text
RECEIVE TASK
    ↓
IDENTIFY ROLE
    ↓
IDENTIFY BUSINESS FEATURE
    ↓
SEARCH EXISTING SPECS
    ↓
SEARCH EXISTING COMPONENTS
    ↓
IDENTIFY SOURCE OF TRUTH
    ↓
MODEL BUSINESS STATE
    ↓
MODEL UI STATE
    ↓
DEFINE SCREEN ZONING
    ↓
DEFINE INTERACTIONS
    ↓
DEFINE RESPONSIVE VARIANTS
    ↓
DEFINE EMPTY / LOADING / ERROR / OFFLINE
    ↓
DEFINE ACCESSIBILITY
    ↓
VALIDATE ZONING WHEN REQUIRED
    ↓
IMPLEMENT
    ↓
SELF-REVIEW
    ↓
QA GATE
    ↓
DELIVER
```

## 60.1 Condition de sortie

Une feature frontend est « terminée » uniquement si :

- elle respecte les specs métier ;
- elle respecte cette Bible ;
- elle utilise les composants appropriés ;
- elle gère ses états ;
- elle est responsive ;
- elle fonctionne en Light et Dark ;
- elle respecte l'accessibilité ;
- elle ne détruit pas un état existant ;
- elle n'introduit pas d'improvisation silencieuse ;
- elle a passé la checklist de non-régression.

---

# 61. RÈGLE ULTIME

**Claude est l'implémenteur. Il n'est pas l'autorité produit.**

Son objectif n'est pas de produire le moins de code possible.

Son objectif est de produire la meilleure expérience conforme aux spécifications de Rewayah, au design system, aux standards de plateforme et aux contraintes d'accessibilité, sans supprimer de capacité métier et sans inventer de comportement.

Lorsqu'une interface semble trop complexe, Claude doit chercher à **mieux structurer** avant de chercher à **supprimer**.

Lorsqu'une interface semble trop dense, Claude doit chercher à **adapter la présentation** avant de supprimer une fonctionnalité.

Lorsqu'une interface semble difficile à comprendre, Claude doit chercher à **améliorer la hiérarchie et le contexte** avant de cacher une fonction.

Lorsqu'une décision est ambiguë, Claude doit revenir à la source de vérité, documenter l'incertitude et choisir la solution la plus cohérente avec ce contrat.

**FIN DE LA BIBLE FRONTEND / UI/UX / INTERACTION REWAYAH V2**


---

# ANNEXE 10 - Dossier source exhaustif : inventaire des rôles, écrans, routes, code observé, maquettes et décisions

_Source : `DOSSIER_POUR_CHATGPT.md`. Contenu conservé pour ne pas perdre les détails métier._


# DOSSIER POUR CHATGPT : faits vérifiés de Rewayah Academy

Préparé le 24/09/2026 par Claude Code (coordinateur), à partir du dépôt au commit `cefab7f` (branche `ui/tuteur-v1`) et des documents du directeur. Tout ce qui suit est sourcé ; ce qui n'a pas pu être prouvé est marqué « à vérifier ». Tu n'as pas accès au code : ce dossier est ta seule source sur l'existant.

## 0. L'essentiel, à lire en premier

1. **Application** : Flutter (Android, iOS, web), Supabase, LiveKit, stockage R2. Cours de Coran en visio par **classes stables** (groupe fixe, horaire récurrent, enseignant attitré). Rôles : tuteur (famille), élève adulte, élève enfant (Interface guidée), enseignant, administration, contrôleur, contrôleur invité, finance et comptable.
2. **Ordre des vagues** décidé par le directeur (section B) : Tuteur V1 (en cours de construction), puis **Classe et visio (priorité n° 1 : un élève et un enseignant se rencontrent et se voient)**, puis validation des dossiers par l'admin, backend, puis les autres rôles, le lecteur du Coran, la landing web, la publication.
3. **Système de design GELÉ** (section C) : palette, polices DM Sans (titres) et Plus Jakarta Sans (tout le reste), rayons, espacements, composants. Aucune nouvelle couleur ni police. Les maquettes existantes donnent la DISPOSITION, pas les couleurs.
4. **Règles du directeur** (section A, §1 bis et suivants) : une fonction = un seul endroit ; carte groupée = un seul rectangle à fins filets ; navigation, retour et déconnexion toujours accessibles ; web = vraie version ordinateur ; rien d'affiché comme fait sans garantie serveur ; plan fermé.
5. **Faits de produit tranchés par le directeur** : l'enregistrement audio des cours est RÉEL (bucket R2 dédié), la notice « Cours enregistré, visite de contrôle possible. » est conservée ; observation par le parent : 2 visites de 2 minutes par parent et par séance, une visite écourtée est consommée ; salle d'observation épurée avec un bandeau pleine largeur (décompte seconde par seconde, « 1/2 visite restante pour cette séance »).
6. **Deux points à signaler au directeur, pas à trancher seul** :
   - une règle d'éthique visuelle ancienne (archivée, section C) interdisait les images générées par une IA et recommandait vert et or pour les accents religieux. Le directeur te demande aujourd'hui de générer des maquettes : sa demande récente prime pour des MAQUETTES de travail, mais signale dans chaque document que les visuels destinés au public (icône, captures des stores, illustrations) doivent être validés contre cette règle ;
   - le dépôt ne contient **aucun logo** et l'icône de l'application est celle de Flutter par défaut : à prévoir dans le document de publication.

## Sommaire

- A. Décisions du coordinateur et réponses du directeur (fichier `03_DECISIONS_COORDINATEUR.md`)
- B. Vagues du projet et backlog de la vague Classe et visio
- C. Système de design gelé (valeurs réelles du code)
- D. Tuteur : écrans et états sans maquette, maquettes existantes et leurs erreurs
- E. Inventaire des écrans de tous les autres rôles, avec l'état réel du code
- F. Mandat original du directeur pour le rôle Tuteur (référence du niveau de détail attendu)

---



---


# A. Décisions du coordinateur et réponses du directeur

# 03 - Décisions du coordinateur (Lot 0)

Date : 24/09/2026. Statut : arbitrages RÉVERSIBLES pris pour ne pas bloquer le chantier, sur une branche locale non poussée. Chaque point marqué **[DIRECTEUR]** reste à confirmer avant toute fusion dans `main` ; il est repris dans le rapport final.

Sources : `01_visuel/00_MANIFESTE.md`, `02_code/00_*.md` (mapping, contrats, ownership, dépendances, contradictions).

## 1. Git et environnement

| Sujet | Décision |
|---|---|
| Base | `c0/configuration-baseline-2026-09-23` @ `3cf3544` (porte `docs/current`, `lib/` identique à `main` aux commentaires près). |
| Branche d'intégration | `ui/tuteur-v1`, worktree `D:\RA_TUTEUR\integration`. Commits locaux uniquement : **aucun push**, aucune PR, aucun merge `main`. |
| Branches de lot | `ui/tuteur-v1-<lot>` (a, b, c, cobs, d, e), worktrees `D:\RA_TUTEUR\lot-<lot>`, issues de `ui/tuteur-v1` après la phase 0. |
| Style de commit | Conventionnel en français, comme le dépôt : `feat(tuteur-foyer): ...`, `fix(...)`, `chore(...)`. Message sans emoji ni M-dash. |
| Commandes lourdes | Toujours via `D:\RA _APP\pilotage-tuteur-v1\outils\flutter-verrou.ps1` (verrou système). Analyse ciblée et tests ciblés dans les lots ; analyse complète, suite complète et build web réservés au coordinateur. |
| Frontière backend | `git diff --stat 3cf3544...HEAD -- supabase .github vercel.json web/vercel.json .firebaserc` doit rester vide. |
| i18n | Chaque lot committe **ses** clés dans `assets/i18n/fr.i18n.json` sous **ses** espaces de noms (`00_OWNERSHIP.md` §4), jamais une clé d'un autre espace ; il régénère (`dart run slang`) pour compiler. À l'intégration, le coordinateur résout les conflits JSON par union des espaces de noms et régénère. Les squelettes d'espaces de noms sont créés en phase 0 à des emplacements séparés du fichier. |

## 1 bis. RÉPONSES DU DIRECTEUR (24/09, elles PRIMENT sur le §2 ci-dessous)

1. **Classes factices ou réelles** : l'application n'est pas officiellement lancée ; le déploiement sert au directeur à voir le rendu. Des classes de démonstration sont acceptables. Conséquence : les adaptateurs réels restent le défaut, ET un **mode démonstration tuteur explicite et isolé** (données fictives, aucun appel serveur, repère discret « Démonstration ») est ajouté pour que le directeur voie le rendu complet sur l'aperçu. Jamais de repli silencieux d'un service réel vers des fixtures.
2. **Enregistrement audio : il est RÉEL** (bucket R2 dédié, Cloudflare). On **garde la notice** : `salle.bandeauPermanent` = « Cours enregistré, visite de contrôle possible. » (valeur de la base `3cf3544`), `contrat.pointEnregistrement` et `enseignant.profil.contratAccuse` inchangés. **Aucune** modification de libellé d'enregistrement issue de `33503fe` ne doit subsister (si elle a été reprise, la rétablir à la valeur de `3cf3544`).
3. **Consentement d'observation** : rédiger un paragraphe en mots clairs et bienveillants, pour que les familles comprennent réellement de quoi il s'agit (qui peut observer, ce qu'il entend et voit, ce qu'il ne peut pas faire, pourquoi, limites de visites). Nouvelle version du texte signé = texte existant (notice d'enregistrement comprise) + ce paragraphe ; variantes responsable légal et élève adulte ; case non précochée.
4. **Quota de visites** : **par parent** (par compte observateur), **2 visites par défaut par séance** (par salle), que la salle contienne un ou plusieurs de ses enfants. **Une visite écourtée est consommée** et n'est pas reconduite : le parent n'a plus que la seconde et dernière. L'explication « Comment ça marche ? » le dit clairement. Valeurs toujours lues depuis la politique effective (jamais codées en dur).
5. **Salle d'observation** : visio moderne, épurée, **très peu de boutons ou d'options à l'écran**. En haut, un **bandeau pleine largeur** qui affiche au tuteur le **décompte du temps restant seconde par seconde** et le **nombre de visites restantes** (« 1/2 visite restante pour cette séance » ; accord au pluriel ; « Aucune visite restante pour cette séance » à 0). Commandes réduites au strict nécessaire (son reçu, agrandir le support, quitter).
6. **Notices côté enseignant et élève** : **hors périmètre** de ce chantier ; elles seront conçues avec les rôles enseignant et élève. Ne pas étendre ce qui existe (reprise de la branche observation conservée telle quelle).

## 1 ter. RÉPONSES DU DIRECTEUR (24/09, soir, dans le document « Rewayah — Audit de méthode ») : elles PRIMENT

1. **Les high-fi font AUTORITÉ pour le layout et le placement des fonctions ; pas pour la palette.** Pour la composition, suivre les maquettes de près : ordre des sections, colonnes, proportions, regroupements, emplacement exact de chaque fonction, de chaque bouton et de chaque action, et la route qu'ils ouvrent. Un écart de placement est un défaut, au même titre qu'un bug. Pour les couleurs seulement, la direction reste celle des jetons (Bible) : des maquettes on ne prend qu'une **idée générale** de la palette, jamais une recopie à 100 %.
   - **Une fonction = un seul endroit.** Chaque action a une place unique, celle de la maquette, ou à défaut celle de l'arbre du mandat §4. **Aucun doublon** : pas la même action dans deux écrans, pas deux écrans pour la même fonction, pas deux routes concurrentes. Seule exception : les raccourcis que le mandat prévoit explicitement (ex. « Créer mon profil élève » depuis Foyer ET Compte), qui ouvrent **le même** flux, jamais une copie.
   - Contrôle obligatoire par lot et en revue Q : une **carte des fonctions** (fonction → écran unique → route → emplacement dans la maquette) ; toute fonction placée ailleurs que prévu ou présente deux fois est corrigée avant intégration.
2. **Design system GELÉ** : la palette ajustée et les polices DM Sans (titres) + Plus Jakarta Sans (le reste) de cette vague deviennent **immuables jusqu'à nouvel ordre du directeur**. Tout changement de jeton exige une décision datée. Un test doit figer les valeurs des jetons.
3. **Carte groupée = UN SEUL rectangle** qui regroupe les éléments d'un même sujet, séparés par une **fine ligne horizontale** (filet en retrait) qui traverse la carte. **Interdit** : un rectangle par ligne, ou des rectangles collés entre eux pour imiter une carte. Un seul composant partagé porte ce motif ; tout écran l'utilise.
4. **Navigation et sortie toujours possibles** : barre de navigation présente, retour visible sur chaque écran de niveau 2 et chaque tâche focalisée, **déconnexion** accessible sur tous les formats. Aucune impasse (le directeur a dû désinstaller la PWA faute de pouvoir revenir en arrière). Testé automatiquement.
5. **Web = vraie version desktop**, jamais la version mobile étirée : rail à partir de 600, barre latérale à partir de 1200, compositions en colonnes dérivées des high-fi desktop. Capture 1440 obligatoire pour chaque écran.
6. **Voir le rendu sans compte ni KYC** : un **mode démonstration par rôle** (sessions fictives, aucune donnée réelle, aucun appel serveur, sélecteur de rôle), activé seulement hors production ; le tuteur d'abord, les autres rôles ensuite. Les captures maquette/rendu de chaque lot sont publiées au fil de l'eau dans `05_recette/` et dans une page artefact.
7. **Frontend d'abord, backend ensuite** (le directeur préfère finir le frontend Tuteur, puis câbler). Chaque écran déclare son contrat serveur (ports K6, identifiants DB-xxx) pour que le câblage se fasse sans refonte. Le lot Backend T1 est reporté après le frontend Tuteur.
8. **Composants réutilisables** : ce qui est construit ici doit servir tels quels aux rôles suivants (admin, enseignant, élève adulte, élève enfant avec mode accessibilité, contrôleur, finance, comptable, contrôleur invité, salle, bibliothèque, Coran). Aucun composant spécifique au tuteur quand un composant partagé peut faire le travail.
9. **À venir côté tuteur (ne pas construire, laisser la place)** : recharge de solde, **chaque enfant consomme son propre solde**, parcours d'ajout d'un nouvel enfant revu. Les visuels viendront plus tard. Compte > Paiements et Foyer > fiche élève doivent pouvoir accueillir un solde par enfant sans refonte.
10. **Coran** : le rendu actuel « se lit en marche arrière et du bas vers le haut ». Hors périmètre de ce chantier, proposé comme étape parallèle (fichiers disjoints : `lib/features/tc_mushaf`, `lib/core/tc_coran`, `lib/core/coran`).

## 1 ter bis. LEÇONS DU REGISTRE DU CODE NON LIVRÉ (`06_registre/00_REGISTRE.md`), obligatoires pour tous les lots

1. **Définition de « fait » (registre §5 bis).** Une fonction n'est « faite » que si : (a) son fichier est atteignable depuis `lib/main.dart` (`D:\RA _APP\pilotage-tuteur-v1\06_registre\outils\graphe_imports.ps1 -Ref <commit>`) ; (b) un bouton, un onglet ou un lien y mène, trouvé hors routeur et hors tests ; (c) après publication de l'aperçu, un de ses textes figure dans le `main.dart.js` servi. **Un test qui appelle `routeur.go(...)` ne prouve pas l'accès** : chaque parcours du lot est aussi testé en touchant les boutons (tap), depuis la navigation.
2. **Tri PostgREST.** `postgrest` trie en DÉCROISSANT quand on n'écrit rien (cause du Coran lu à l'envers). Tout `.order(...)` écrit ou touché par un lot précise `ascending: true` ou `false`, avec un test qui vérifie l'ordre. Les lots relisent les `.order(` des services qu'ils consomment (séances, appareils, présence, historique) et signalent tout tri sans sens.
3. Les 21 fichiers de contrats de la phase 0 non encore atteignables doivent l'être à la fin de la phase 1 (sinon : justification écrite ou suppression sur accord).

4. **Coran : NE PAS CORRIGER dans ce chantier** (ordre du directeur, 24/09 soir). Aucun lot ne modifie `lib/core/coran`, `lib/core/tc_coran`, `lib/features/tc_mushaf`, même pour un défaut évident. Les défauts sont consignés dans `08_BACKLOG_VAGUE_CLASSE_VISIO.md`. La vague suivante (« Classe et visio ») a pour priorité n° 1 la rencontre élève-enseignant en visio. Tout défaut hors périmètre découvert par un agent est consigné dans ce backlog, jamais corrigé en passant.

## 1 quater. AUTORISATION DU DIRECTEUR (24/09, soir)

Le directeur **autorise**, à la fin de la phase 0 puis à la fin de chaque lot : `git push` de la branche `ui/tuteur-v1` vers `origin`, et l'ouverture (puis la mise à jour) d'une **pull request brouillon** `ui/tuteur-v1 -> main` pour obtenir l'URL d'aperçu Vercel. **Toujours interdit sans nouvel accord explicite** : fusion dans `main`, déploiement en production, `workflow_dispatch`, migration distante, push de toute autre branche. Avant chaque push : vérification complète verte ou échecs listés, frontière backend vide, aucun secret dans le diff.

Fait vérifié (`flutter-deploy.yml:89-90, 128-133`) : l'aperçu de PR utilise **les mêmes secrets Supabase que la production** (même base, vraies données, vraie connexion) avec `ENVIRONNEMENT=staging`, et force `PLAYGROUND=false` et `GALERIE=false` sur tous les builds. Conséquence pour le mode démonstration : il s'active sur `ENVIRONNEMENT != production` (aperçu, local), jamais via `PLAYGROUND`, et reste impossible en production. Rythme proposé au directeur : aperçu par lot, puis fusion dans `main` le jour même après sa validation (fusion = nouvel accord explicite à chaque fois).

## 2. Points directeur : défauts retenus (remplacés par le §1 bis là où ils divergent)

| # | Question | Défaut retenu (réversible) | Justification |
|---|---|---|---|
| P1 | Catalogue : vraies classes ou offres sans enseignant ? | **Vraies classes** (enseignant avec photo, toutes les séances, fuseau, places réelles) comme l'exige le mandat du 24/09. `PortCatalogueClasses` sans source en production : écran honnête « le choix de classe en ligne n'est pas encore ouvert », aucune réservation locale. **[DIRECTEUR]** | Le mandat est la demande explicite la plus récente (§2, rang 1) ; l'arbitrage Classes V2 du 22/09 vit sur des branches gelées. |
| P2 | Consentement d'observation et textes signés | Nouvelle **version** de texte signé côté front (`VersionsContrat`) qui ajoute le paragraphe d'observation exact du mandat (variantes responsable légal / élève adulte) ; case **non précochée** ; enregistrement par le mécanisme existant (`contract_acceptances`, insertion self) avec la nouvelle version. Comptes existants : invite `/tuteur/compte/consentements` qui lit les acceptations et propose la nouvelle version ; **aucun compte considéré comme ayant accepté**. Le serveur n'exige pas la version (`etat_dossier`) : dépendance backend consignée. **Remplacé par §1 bis-2 et 3 : l'enregistrement audio est réel, la notice est conservée telle quelle dans la nouvelle version** ; l'ancienne version reste intacte (jamais réécrite). **[DIRECTEUR : valider le texte avant fusion]** | Mandat observation §6 ; ne jamais réécrire un texte déjà signé (X10, X40). |
| P3 | Observation réelle | Interrupteur de compilation `OBSERVATION_TUTEUR_REELLE` (défaut **false**, forcé false en production tant que présence enfant, fin de visite et jeton vidéo ne sont pas garantis par le serveur). En production : bloc Observation avec motif « pas encore ouverte » (`garantieServeurAbsente`). Parcours complet démontré en simulation (tests, playground). **[DIRECTEUR]** | Mandat observation §3 : « n'active pas une fonctionnalité réelle avec une protection uniquement locale » ; DB-OBS-01/02/03/05. |
| P4 | Quota par parent ou par foyer, plusieurs enfants, visite écourtée | **Tranché par le directeur (§1 bis-4)** : par parent, 2 visites par séance quel que soit le nombre de ses enfants dans la salle ; visite écourtée consommée. L'UI affiche les valeurs rendues par le serveur ; tout écart entre ce comportement et le serveur est une dépendance backend. | Réponse du directeur du 24/09. |
| P5 | Décrire les élèves avant validation du dossier | Suivre le serveur : l'ajout d'élève reste après validation (porte `actif`). L'admission l'annonce honnêtement et enchaîne sur le formulaire commun dès l'arrivée en porte `actif`. Dépendance DB-ADM-04. **[DIRECTEUR]** | Pas de contournement serveur. |
| P6 | « Photo requise avant la première visio » | Aucune règle sur la base : **aucun** blocage photo affiché. | Mandat §5 : seulement si confirmé par les données. |
| P7 | Décisions Classes V2 (cohortes 6-9/10-13/14-17/18+, date de naissance, débutant direct, demande d'interface standard à 10 ans) | Pas de constante côté front : l'UI consomme les cohortes, règles et branches rendues par le serveur (`regles_academie`, 0043) ; quand le serveur ne les fournit pas, état indisponible. Libellés métier alignés sur Classes V2 quand ils ne créent aucune règle. **[DIRECTEUR : intégrer ces décisions à `docs/current`]** | Décisions datées mais hors `docs/current`, backend non appliqué. |
| P8 | Reprise du front de `33503fe` (vraies classes) et de `observation/lot-2026-09-21` | **Oui**, en deux commits séparés, nommés et réversibles, **partie `lib/ test/ assets/` uniquement**, sans aucune migration, sans fichiers générés (régénérés), et **sans** les clés signées `contrat.pointEnregistrement` et `enseignant.profil.contratAccuse` de `33503fe`. **[DIRECTEUR]** | Le mandat interdit les fixtures servies en production (`port_groupes.dart:37-39`, `port_horloge_seance.dart:54-55`) et impose la politique 2 x 120 s déjà en production (0036). |
| P9 | Palette sombre ardoise pour tous les rôles | **Oui**, un seul système de jetons ; contrôle de non-régression (contrastes, captures des autres rôles). | Toutes les maquettes sombres s'accordent ; un seul thème. |
| P10 | Planche 3 « États particuliers et notices de présence » | Demandée au directeur ; états dérivés en attendant (manifeste §6.3). | Mandat §2. |

## 3. Arbitrages visuels (manifeste §6.4)

1. Palette : ajustements du manifeste §3.1 appliqués (clair : `inkStrong #110E20`, `inkFaint #6A687E`, `inkAccent #6538E4`, `washWarning #FEF5E4`, `inkAlert #C21D3D` ; sombre : ardoise `#1A1A25` / `#22222E` / `#2B2B39` / `#262534` / `#32323F`, `inkMuted #AEB1CE`, `inkFaint #9194B0`, `surfacePrimary #BA98FB` encre `#25113F`, `inkAlert #F4777D`). Ajouts : paires `surfaceMiseEnAvant` (`#F7F5FE` / `#2B2B39`), `surfaceActionDouce` (clair `#DCCAFD` + `inkStrong` ; sombre = `surfacePrimary`), groupe de points de statut (succès, attention, alerte, neutre). Chaque valeur est vérifiée en contraste (texte 4,5:1, composants 3:1) par test.
2. Boutons et champs : rayon `AppRadius.sm` (12). Exception : CTA des étapes d'admission en pilule (`AppRadius.full`), comme les high-fi d'admission.
3. CTA dominant : `surfaceActionDouce` (lavande doux en clair, lavande plein en sombre), libellé + flèche ; un seul par écran.
4. Typographie : DM Sans pour `display*` de titre, `headline*`, `title*` ; Plus Jakarta Sans pour tout le reste ; style `chiffre` Jakarta tabulaire pour horaires, codes, PIN, chronomètre, initiales (DM Sans n'a pas de chiffres tabulaires). Graisse des titres de page 700. Polices arabes inchangées. `BricolageGrotesque` et `InstrumentSans` retirées des assets (4 familles, pas une de plus).
5. Bascule clair/sombre de l'en-tête (tablette et desktop) : pilote la même préférence qu'Apparence (Système / Clair / Sombre) ; la préférence est enfin appliquée au `MaterialApp`.
6. Navigation tuteur : **Accueil · Foyer · Historique · Compte**, identique sur tous les formats (barre basse flottante < 600, rail replié 600-1199, barre latérale dépliée ≥ 1200, Compte épinglé en bas). Historique confirmé comme 3e destination (manifeste §4.3).
7. Libellés : « Cours en cours » interdit partout dans le périmètre tuteur ; séance prolongée = « Séance toujours en direct » ; « Session » -> « Séance » / « Cours » ; « Ajouter enfant » -> « Ajouter un profil élève ».
8. Choix d'usage : deux cartes (« Moi uniquement », « Moi et ma famille ») **sans carte « Autre »** (`ChoiceCardGroup.autoriserSaisieLibre: false`), lien discret « Je suis enseignant ». Écart assumé à la règle ADR-013 : décision explicite du directeur.
9. Détail d'observation : `/tuteur/seances/:seanceId/observations?eleve=`.

## 4. Alertes sécurité à remonter (hors périmètre, aucune correction dans ce chantier)

- Policy `student_profiles_family_update` sans contrôle de rôle : un élève pourrait modifier caméra, mode, photo (`0005:535-564`, `0033:1723-1730`). Lecture, non exécuté.
- `lesson_reports` d'une séance de groupe lisible en entier par un foyer (`0001:1070-1078`).
- `flutter-deploy.yml` (sur `main`) : `workflow_dispatch` déploie en production quelle que soit la branche.
- Hooks `.claude` actifs seulement sur l'outil Bash, pas PowerShell.
- `0042` (appliquée) refuserait tout jeton vidéo (affirmation d'archive, non remesurée).


---


# B1. Vagues du projet

# Vagues du projet Rewayah Academy

Ordre décidé par le directeur (24/09/2026). Une vague = une branche de base, un dossier de pilotage, des lots, des lignes dans le tableau de suivi. La vague suivante ne commence qu'après accord du directeur.

| Vague | État | Branche de base | Dossier de pilotage | Objectif |
|---|---|---|---|---|
| Tuteur V1 (frontend) | en cours | `ui/tuteur-v1` | branche `pilotage/tuteur-v1` | Tous les écrans et parcours du rôle Tuteur, fidèles aux maquettes, honnêtes sur ce que le serveur ne fait pas encore |
| Classe et visio | prévue | à créer | à créer | **Priorité n° 1 : un élève et un enseignant se rencontrent et se voient** (salle unique, visio, jeton serveur, entrée depuis la classe, présence) ; validation des dossiers enseignants par l'admin ; puis lecteur du Coran fidèle |
| Backend T1 | prévue, après le frontend Tuteur | à créer | à créer | Garanties serveur du tuteur, sécurité, CI verte (prompt prêt dans le document « Rewayah — Audit de méthode ») |
| Rôles suivants | à planifier | - | - | Enseignant, élève adulte, élève enfant (Interface guidée, accessibilité), administration, contrôleur, contrôleur invité, finance et comptable, bibliothèque et ressources, solde par enfant et recharge, landing page web, publication iOS, Play Store, Windows |

Backlog consigné pour la vague Classe et visio : `pilotage/tuteur-v1` : `08_BACKLOG_VAGUE_CLASSE_VISIO.md`.


---


# B2. Backlog de la vague Classe et visio

# Backlog : vague « Classe et visio » (après le chantier frontend Tuteur V1)

Consigné le 24/09/2026 sur ordre du directeur : **ne rien corriger maintenant**, ne pas sortir du chantier Tuteur en cours.

## Priorité n° 1 de la vague suivante

**Permettre à un élève et à un enseignant de se rencontrer et de se voir** : une seule salle, visio LiveKit fonctionnelle, jeton vidéo délivré par le serveur, entrée depuis la classe pour l'élève et pour l'enseignant, présence. Tout le reste (outils pédagogiques, Coran fidèle) vient après que ce parcours marche réellement.

Prérequis connus (registre `06_registre/00_REGISTRE.md`, dépendances `02_code/00_DEPENDANCES_BACKEND.md`) :
- Migration `0042` appliquée en production qui refuserait tout jeton vidéo (affirmation du correctif non committé `D:\RA_OBS\...\0043_autoriser_jeton_video_verifie_le_bon_compte.sql`, sauvegardé ; à vérifier en base, puis renuméroter au prochain numéro libre).
- Deux salles concurrentes (`/salle` et `/tc/classe`) : arbitrage du directeur pour une salle unique.
- Synchronisation en direct (`lib/core/tc_realtime`), reprise après coupure (`lib/core/tc_etat_partage`) : présents sur `main`, jamais branchés.
- La page du Coran présentée par l'enseignant n'est reçue par aucun écran élève.

## Coran : défauts connus (rendu en production), à traiter dans cette vague, après la visio

Constatés par le directeur le 24/09 :
1. **Ordre inversé** : les versets s'affichent du dernier au premier, lecture du bas vers le haut. Cause prouvée : `lib/core/coran/service_coran.dart:309, 329, 330, 459, 460`, `.order(...)` sans `ascending: true` (postgrest 2.9.1 trie en décroissant par défaut). Même cause : la recherche renvoie les 50 **dernières** occurrences.
2. **Voyelles (harakat) absentes** : la fatha et les autres signes ne s'affichent pas sur presque tous les mots.
3. **Espacement** : mots trop éloignés les uns des autres, interligne trop large.
4. **Mise en forme non officielle** : ne respecte pas le Mushaf du complexe du roi Fahd (Madinah) : pas de pages standard (604 pages, 15 lignes), pas de marquages hizb, juz', rub', sajda, début de sourate, numéros de verset dans leur ornement.
5. **Résumé du directeur** : la version en production n'affiche que des mots bruts éparpillés.
6. **Commandes absentes** pour gérer le Coran (navigation page, sourate, juz', verset agrandi, suivi de la classe, zoom).

Pistes à instruire (sans décision) : police et données de mise en page officielles (KFGQPC / QPC, données de lignes par page), vérification du corpus chargé (6 236 versets, `0013`) et de sa normalisation Unicode (les harakat peuvent être perdus à l'import ou par la police), `layout_lignes_indisponible.dart:51-52` (mise en page fidèle désactivée), gestes de page et boutons en sens contraires (registre §4). Règle permanente : le texte canonique n'est jamais modifié ; sans mise en page de référence, afficher honnêtement le mode verset, jamais une fausse page « Mushaf ».

## Réponses du directeur sur le registre (24/09, soir)

- **Vocabulaire** : à l'écran on dit « Classe », jamais « groupe » (règle déjà imposée aux lots du chantier Tuteur).
- **Deux salles** (`/salle` et `/tc/classe`) : garder la plus complète, y combiner le meilleur de l'autre, puis supprimer le doublon (vague Classe et visio).
- **Lecteur du Coran en double** (`/tc/mushaf` et `/eleve/coran`) : même règle : compléter, combiner, supprimer le doublon.
- **Anciens lots Codex (13-15/09)** : abandon autorisé, mais examiner d'abord ce qui est récupérable comme inspiration (Codex jugé meilleur dans certains domaines).
- **Décision « badges à cinq niveaux »** : OUI, à intégrer aux specs (`docs/current`).

## Points du directeur restés sans réponse dans l'audit (à traiter)

- **Rôle enseignant inaccessible** : bloqué par le KYC, car l'administration n'a pas d'écran pour revoir et accepter les dossiers. À traiter en tête de la vague Classe et visio (sans enseignant validé, pas de rencontre élève-enseignant).
- **Accès de test sans parcours complet** : voir chaque rôle sans créer plusieurs comptes. Réponse retenue : mode démonstration par rôle sur l'aperçu (jamais en production) pour VOIR ; pour tester en vrai, comptes de test par rôle créés et validés par l'admin une fois l'écran de validation livré.
- **Système de jetons d'accès pour agents (comme PISI)** : jamais fonctionnel ; remplacé par l'aperçu de PR, le mode démonstration et les captures ; à ne pas relancer sans décision.

## Autres points consignés pour les vagues suivantes

- Outils de classe de l'enseignant, après-cours, signalement, micro-avis élève, bibliothèque en classe : présents sur `main`, jamais branchés (registre, groupe A).
- Écran de bienvenue enseignant sans bouton ; liste des élèves de l'enseignant refusée par la porte d'accès ; Coran hors salle absent pour l'enseignant (registre, groupes B et C).
- 11 autres appels `.order(...)` sans sens écrit (appareils, séances, créneaux, offres) : à vérifier dans chaque lot qui les consomme.
- [lot C, 24/09] `mes_groupes_famille_v` (`0033:140-170`) : jointure `m` (tous les eleves du foyer) croisee avec `m2`, `count(m2.id)` probablement multiplie quand deux enfants d'un meme foyer sont dans la meme classe (effectif gonfle). Lecture seule, non mesure. Backend.
- [lot C, 24/09] `groupeDepuisLigne` (`groupes_supabase.dart:48-50`) replie un titre absent sur Sayyid : le mandat interdit de deviner le titre ; `EnseignantVM.titre` non nullable (fichiers du coordinateur, demande C-3).


---


# C. Système de design gelé

# Système de design GELÉ de Rewayah Academy : état réel du code

Date du relevé : 24/09/2026. Dépôt lu : `D:\RA_TUTEUR\integration`, branche `ui/tuteur-v1`, commit `cefab7f` (lecture seule, aucun fichier modifié).
Destinataire : ChatGPT, qui n'a pas accès au code. Tout ce qui suit est relevé dans le code ou dans un document cité par `fichier:ligne`. Ce qui n'a pas pu être prouvé porte la mention **À VÉRIFIER**. Les écarts entre le code et les documents portent la mention **ÉCART**.

## 0. Règles de lecture

| Règle | Source |
|---|---|
| Le système de design est **gelé** : palette ajustée, DM Sans (titres) et Plus Jakarta Sans (le reste) sont immuables jusqu'à nouvel ordre du directeur. Tout changement de jeton exige une décision datée. | `pilotage-tuteur-v1/03_DECISIONS_COORDINATEUR.md:33` (§1 ter-2) |
| Les maquettes font autorité pour la **disposition** (ordre, colonnes, emplacement de chaque action), jamais pour la palette : on n'en prend qu'une idée générale. | `03_DECISIONS_COORDINATEUR.md:30` (§1 ter-1) |
| Quand un commentaire du code contredit la valeur du code, **la valeur du code fait foi** (c'est elle qui s'affiche). | constat de ce relevé |
| `docs/archive/` n'est pas une instruction ; une règle archivée qui contredit `docs/current/` est caduque. | `integration/CLAUDE.md:23-25` |
| La demande explicite la plus récente du directeur prévaut sur `docs/current`. | `docs/current/00_LIRE_D_ABORD.md:12` |
| Gel vérifié par test : **partiel**. Les tests figent 17 valeurs claires et 13 valeurs sombres (fonds, encres ajustées, CTA doux, Coran), pas toutes les paires. | `test/theme/contraste_test.dart:19-44`, `test/theme/contraste_sombre_test.dart:26-45` |
| ÉCART : `docs/current/03_DESIGN_SYSTEM_ET_UX.md:5` dit « les documents fournis ne fixent pas de valeurs HEX officielles » et « violet fortement atténué, jamais primaire par défaut ». La décision de gel du 24/09 (§1 ter-2) est plus récente et prime ; le violet plein n'est plus le CTA en clair, ce qui va dans le sens de `03`. | `docs/current/03:5` ; `03_DECISIONS:33` |

## 1. Palette (`lib/core/theme/app_palette.dart`)

Principe : le thème n'expose jamais une couleur seule. Il expose des **paires** (fond, encre) `AppColorPair`, des **encres** de premier plan `AppInkColor` (texte, trait, icône, jamais un fond), des **indicateurs** `AppIndicatorColor` (point plein seulement) et une **ombre** `AppShadowColor`. Source : `app_color_pair.dart:3-11`, `:56-64`, `:103-111`, `:159-166`. Aucune couleur hors de ce fichier n'est acceptée par `tool/verifier_jetons.dart` (`lib/CLAUDE.md:17-19`).

### 1.1 Surfaces (paires fond / encre)

Clair : `app_palette.dart:61-152`. Sombre : `:154-247`.

| Jeton | Clair fond / encre | Sombre fond / encre | Rôle (source) |
|---|---|---|---|
| `surfaceCanvas` | `#F8F7FA` / `#110E20` | `#1A1A25` / `#F5F2FA` | Fond de page (manifeste §3.1). En sombre : « ardoise bleu-violet », jamais noir pur ni gris neutre (`app_palette.dart:16-20`, manifeste §6.2) |
| `surfaceRaised` | `#FFFFFF` / `#110E20` | `#22222E` / `#F5F2FA` | Carte, carte groupée, barre basse, rail et barre latérale, zone d'action collée, feuille mobile, bouton secondaire (`nav_shell.dart:400`, `:633` ; `page_shell.dart:267` ; `action_principale.dart:258-260`) |
| `surfaceSunken` | `#F0EDF4` / `#110E20` | `#262534` / `#F5F2FA` | Zone imbriquée (bloc séance mobile, seule imbrication admise), fond de champ, piste de contrôle segmenté, squelette, en-tête de tableau, ton « neutre » des pastilles (`app_theme.dart:163` ; `controle_segmente.dart` ; `skeleton.dart` ; `status_pill.dart:42` ; manifeste §3.4) |
| `surfaceOverlay` | `#FFFFFF` / `#110E20` | `#2B2B39` / `#F5F2FA` | Boîte de dialogue, disque retour, bouton de repli du rail (`app_theme.dart:146` ; `entete_page.dart:115` ; `nav_shell.dart:707`). Menus : À VÉRIFIER (le commentaire `app_elevation.dart:59-60` le dit, le thème ne le fixe pas) |
| `surfaceMiseEnAvant` | `#F7F5FE` / `#110E20` | `#2B2B39` / `#F5F2FA` | Carte de séance mise en avant (Accueil desktop), un cran au-dessus de la carte ordinaire (`app_palette.dart:254-256`) |
| `surfaceActionDouce` | `#DCCAFD` / `#110E20` | `#BA98FB` / `#25113F` | **CTA dominant, un seul par écran** : lavande doux en clair, accent plein en sombre (même valeur que `surfacePrimary`). Aucune maquette claire ne montre de CTA violet plein (`app_palette.dart:258-261` ; test `contraste_sombre_test.dart:47-49`) |
| `surfacePrimary` | `#8652E6` / `#FFFFFF` | `#BA98FB` / `#25113F` | Accent plein : anneau de sélection d'avatar (2 px), point de non-lus, remplissage de progression, destination active du rail en sombre, point de la pastille « accent », CTA en Interface guidée (`selecteur_profils.dart` ; `entete_page.dart:188` ; `page_parcours.dart` ; `nav_shell.dart:801` ; `action_principale.dart:241-243`) |
| `surfaceSuccess` | `#70EE9C` / `#1C1D21` | `#70EE9C` / `#1C1D21` | Surface pleine de succès. Ne sert plus de point de statut (1,28:1 sur `washSuccess`) (`status_pill.dart:113-119`) |
| `surfaceWarning` | `#FFB703` / `#1C1D21` | `#FFB703` / `#1C1D21` | Surface pleine d'avertissement, réservée |
| `surfaceAlert` | `#B01B3C` / `#FFFFFF` | `#FFB1BD` / `#570D22` | Contour d'un champ en erreur (`colorScheme.error`, `app_theme.dart:206`). **Jamais un bouton rouge plein** (`action_principale.dart:28-30`, `:44-47`) |
| `surfaceInverse` | `#211E28` / `#F5F2FA` | `#F5F2FA` / `#211E28` | Fond du registre immersif « salle » (`page_immersive.dart:14-16`) |
| `surfaceQuran` | `#F3EAD9` / `#1C1D21` | `#2E2417` / `#F5F1E9` | Lecteur du Coran, registre immersif « lecture ». **Paire figée, jamais modifiée** (`app_palette.dart:5-7` ; tests `contraste_test.dart:41-43`) |

### 1.2 Fonds doux (« lavages ») et famille

| Jeton | Clair fond / encre | Sombre fond / encre | Rôle |
|---|---|---|---|
| `washAccent` | `#EEE6FA` / `#4E2983` | `#332643` / `#E8D8FF` | Destination active du rail en clair, segment actif, carte ou option retenue, cercle héros, encart d'écran résultat, monogramme, médaillon, survol d'un bouton secondaire ou tertiaire (`nav_shell.dart:802` ; `controle_segmente.dart:120` ; `app_card.dart:83-85` ; `ecran_resultat.dart:146`) |
| `washSuccess` | `#E4F4EB` / `#175D3A` | `#173B2B` / `#9DDEB5` | Pastille et signal de succès (« Présente », « Accès actif ») |
| `washWarning` | `#FEF5E4` / `#755200` | `#44361A` / `#F4D480` | Bandeau hors ligne, bandeau d'observation IA, bandeau de blocage ambre, carte « sans planning » (`offline_banner.dart:25-31` ; `bandeau_observation.dart:29-31`) |
| `washAlert` | `#FCE8ED` / `#921734` | `#4A2030` / `#FFD9E0` | Pastille « Interrompue », survol d'une action destructive, « Quitter » en pilule rouge douce (manifeste §3.4) |
| `washFamily` | `#F0EDF4` / `#110E20` | `#262534` / `#F5F2FA` | Domaine foyer : repli à initiales de l'avatar sans photo (`avatar_tile.dart:23-28`) |

Correspondance ton sémantique vers fond doux (`status_pill.dart:13-47`) : `neutre` = `surfaceSunken` (en attente, brouillon, non commencé) ; `accent` = `washAccent` (en cours, actif, retenu) ; `succes` = `washSuccess` (terminé, validé, en direct) ; `avertissement` = `washWarning` (à surveiller, en retard, incomplet) ; `alerte` = `washAlert` (refusé, échoué, annulé).

### 1.3 Encres et filets (premier plan uniquement)

| Jeton | Clair | Sombre | Emploi |
|---|---|---|---|
| `inkStrong` | `#110E20` | `#F5F2FA` | Texte principal, titres |
| `inkMuted` | `#655E70` | `#AEB1CE` | Texte secondaire, sous-titre, icône inactive, clé d'une ligne clé-valeur |
| `inkFaint` | `#6A687E` | `#9194B0` | Texte tertiaire, texte d'invite des champs (`app_theme.dart:165-171`) |
| `inkAccent` | `#6538E4` | `#C9AEFF` | Lien, icône porteuse de sens, libellé actif, anneau de focus, icône de rubrique. Le violet plein `#8652E6` ne s'écrit jamais en texte (4,15:1 sur `surfaceSunken`) |
| `inkSuccess` | `#175D3A` | `#9DDEB5` | Texte de succès, icône d'état vide « bonne nouvelle » |
| `inkWarning` | `#755200` | `#F4D480` | Texte d'avertissement |
| `inkAlert` | `#C21D3D` | `#F4777D` | Erreur sous un champ, action destructive (texte seul), « Se déconnecter » |
| `borderHairline` | `#E3DEE9` | `#32323F` | Filet des champs inertes, séparateur `Divider`, filet haut de la zone d'action collée, filet des feuilles (`app_theme.dart:85-89`, `:181` ; `page_shell.dart:268`) |
| `borderResting` | `#84798F` | `#95899F` | Contour de contrôle au repos, carte de choix non retenue, poignée de feuille (`choice_card_group.dart:210-212`) |
| `borderStrong` | `#84798F` | `#95899F` | **Seule bordure porteuse de sens** : sélection, focus fort, contour de champ actif, survol, bouton secondaire (2 px), bouton principal désactivé (3 px) (`app_card.dart:59-61` ; `action_principale.dart:220-225`, `:264`) |

Valeurs dérivées (`app_palette.dart:317-328`) :

| Dérivé | Valeur | Emploi |
|---|---|---|
| `contourCarte` | encre à 8 % : `#211E28` à 8 % en clair (≈ `#EDEDEE` sur blanc), blanc à 8 % en sombre (≈ `#34343F` sur `#22222E`) | Filet de 1 px de toute carte, carte groupée, filet en retrait entre lignes, barre basse, bord de la colonne latérale, disque retour. Les séparateurs du tuteur consomment `contourCarte`, pas `borderHairline` (manifeste §3.1, ligne « Contour de carte ») |
| `voile` | noir à 32 % (clair), 56 % (sombre) | Voile sous une feuille ou une boîte de dialogue |
| `calqueInteraction` | `inkAccent` à 4 % (survol, focus), 10 % (pressé) | Survol et pression des lignes et cartes |
| `ombre` | `#211E28` dans les deux thèmes | Couleur de toutes les ombres rendues à `cefab7f`. [critique] Une seconde couleur existe : `ombreDialogue` = noir `#000000` (`app_palette.dart:325`), consommée seulement par `AppElevation.dialogue()`, que rien n'appelle (voir §5) |

### 1.4 Points de statut (`app_palette.dart:144-149`, `:239-244`)

Toujours doublés d'un libellé textuel et d'une étiquette sémantique ; ils visent 3:1 contre leur surface (`app_palette.dart:466-471`).

| Point | Clair | Sombre | Sens (`app_palette.dart:482-491`) |
|---|---|---|---|
| `succes` | `#199C55` | `#70EE9C` | Succès, en direct, présent, salle ouverte |
| `attention` | `#B38000` | `#FFB703` | Attention, à venir |
| `alerte` | `#E0375A` | `#F9505E` | Alerte, interrompu |
| `neutre` | `#8685A5` | `#7F7D9E` | Neutre, inactif |

### 1.5 Teintes d'identité (32 paires, décoratives)

Rôle : teinte d'un groupe (classe) ou d'une couverture de ressource calculée, par index stable. **Jamais le seul identifiant** : toujours posée à côté d'un nom (invariant J7). Aucune ne reprend une teinte porteuse de sens (accent, succès, avertissement, alerte, Coran). Source : `app_palette.dart:290-315`, clair `:519-552`, sombre `:556-589`.

| # | Clair fond / encre | Sombre fond / encre | # | Clair fond / encre | Sombre fond / encre |
|---|---|---|---|---|---|
| 0 | `#EB7070` / `#5B1313` | `#2D1515` / `#CC6666` | 16 | `#F4C1AF` / `#903C1D` | `#573529` / `#D79B86` |
| 1 | `#7070EB` / `#0C0C3B` | `#15152D` / `#7878D2` | 17 | `#F8D9CE` / `#A44422` | `#6C4233` / `#E1B4A4` |
| 2 | `#E7CEF8` / `#8729C7` | `#55336C` / `#C6A0DF` | 18 | `#F4AFDF` / `#911E6E` | `#572949` / `#D88AC1` |
| 3 | `#A9EB70` / `#3C6915` | `#202D15` / `#67A035` | 19 | `#EB70A9` / `#5D1336` | `#2D1520` / `#CB6293` |
| 4 | `#D98FEF` / `#65197C` | `#3A1F42` / `#BC76D1` | 20 | `#CEE9F8` / `#1F6B97` | `#33576C` / `#A8CDE2` |
| 5 | `#70EBC2` / `#15684C` | `#152D25` / `#36A27E` | 21 | `#EF9F8F` / `#7B2A19` | `#42251F` / `#CF8070` |
| 6 | `#DDF4AF` / `#547217` | `#475729` / `#B2D174` | 22 | `#8F8FEF` / `#1D1D8C` | `#1F1F42` / `#8282D5` |
| 7 | `#EF8FC2` / `#78194C` | `#421F32` / `#D174A6` | 23 | `#EF8FDF` / `#771867` | `#421F3C` / `#D072C0` |
| 8 | `#EFB38F` / `#7A3C19` | `#422C1F` / `#CC8A65` | 24 | `#AFF4B8` / `#187424` | `#29572F` / `#7AD386` |
| 9 | `#AFF4EA` / `#177367` | `#295751` / `#77D2C6` | 25 | `#8FA9EF` / `#1C3888` | `#1F2842` / `#778FD2` |
| 10 | `#EB70C6` / `#5E1348` | `#2D1526` / `#CA60AA` | 26 | `#CEF8EA` / `#197A5A` | `#336C59` / `#BBE8D9` |
| 11 | `#E1AFF4` / `#7B209C` | `#4A2957` / `#C48BD8` | 27 | `#F8CECE` / `#B32525` | `#6C3333` / `#E0A2A2` |
| 12 | `#D270EB` / `#4E135D` | `#28152D` / `#B764CB` | 28 | `#F4B6AF` / `#952A1E` | `#572D29` / `#D8918A` |
| 13 | `#EB9570` / `#672E15` | `#2D1C15` / `#C57350` | 29 | `#F8CEED` / `#A92385` | `#6C335C` / `#E0A3D0` |
| 14 | `#F8F8CE` / `#737318` | `#6C6C33` / `#EDEDC8` | 30 | `#AFBFF4` / `#2444AE` | `#293457` / `#8A9DD8` |
| 15 | `#93EF8F` / `#196D16` | `#20421F` / `#43BD3F` | 31 | `#CEF8CF` / `#197B1D` | `#336C34` / `#B8E7BA` |

### 1.6 Contrastes mesurés (WCAG 2.x, recalculés pour ce relevé ; concordent avec les tests)

| Encre | Clair : fond / carte / zone imbriquée / mise en avant / `washAccent` | Sombre : fond / carte / zone imbriquée / superposition / `washAccent` |
|---|---|---|
| `inkStrong` | 17,77 / 18,96 / 16,37 / 17,56 / 15,65 | 15,56 / 14,19 / 13,58 / 12,58 / 12,65 |
| `inkMuted` | 5,81 / 6,20 / 5,35 / 5,74 / 5,12 | 8,19 / 7,47 / 7,15 / 6,62 / 6,66 |
| `inkFaint` | 5,05 / 5,39 / 4,65 / 4,99 / **4,45** | 5,80 / 5,29 / 5,06 / 4,69 / 4,71 |
| `inkAccent` | 6,07 / 6,48 / 5,60 / 6,00 / 5,35 | 9,01 / 8,22 / 7,86 / 7,29 / 7,33 |
| `inkAlert` | 5,56 / 5,94 / 5,12 / 5,50 / 4,90 | 6,39 / 5,82 / 5,57 / 5,16 / 5,19 |
| `borderStrong` (composant, seuil 3) | 3,85 / 4,11 / 3,55 / 3,80 / 3,39 | 5,22 / 4,76 / 4,55 / 4,22 / 4,24 |

Paires internes : CTA doux clair `#DCCAFD`/`#110E20` = 12,56 ; CTA sombre `#BA98FB`/`#25113F` = 7,29 ; `surfacePrimary` clair = 4,81 ; `washAccent` clair 8,80 ; Coran 14,10 (clair) et 13,50 (sombre).

**Paires interdites** (sous 4,5:1, aucun usage connu, à ne jamais créer) : clair `inkFaint` sur `washAccent` (4,45) ; sombre `inkFaint` sur `washSuccess`, `inkFaint` sur `washWarning`, `inkAlert` sur `washWarning` (4,35). Source : `test/theme/contraste_test.dart:11-17`, `contraste_sombre_test.dart:11-24`.

À savoir pour le dessin : le CTA doux clair ne se détache de sa carte qu'à 1,51:1 (1,41 sur le fond). C'est accepté pour l'adulte ; en **Interface guidée** le CTA garde l'aplat `surfacePrimary` (≥ 3:1) tant que le directeur n'a pas tranché sur capture (`action_principale.dart:235-243`).

### 1.7 Règles d'emploi de la couleur

| Règle | Source |
|---|---|
| **Une seule zone pleine par écran : l'action principale.** Alertes, badges, bandeaux prennent le registre doux (`wash*` + `ink*`). La pastille de 8 px est le seul aplat saturé toléré en plus. | `lib/CLAUDE.md:62-63` ; `status_pill.dart:56-59` ; `archive/design/01-systeme-visuel.md:60-73` |
| CTA dominant : lavande doux en clair, lavande plein en sombre, libellé plus flèche « → », un seul par écran. | `03_DECISIONS:76` (§3.3) |
| Un état n'est jamais porté par la couleur seule : pastille, icône, mot, au moins deux des trois. | `archive/design/01-systeme-visuel.md:210-212` ; `ligne_presence.dart:11-16` |
| Clair vers sombre n'est **pas une inversion** : les surfaces restent claires sur foncé, l'accent change de rôle, les conteneurs sémantiques s'assombrissent. Carte plus claire que le fond en sombre (l'élévation se lit par la clarté). | manifeste §6.2 |
| Contenu non chrome (support pédagogique, QR, photos, surface Coran) **inchangé** en sombre ; le QR reste noir sur blanc. | manifeste §6.2, dernière ligne |
| Un même arbre de widgets dans les deux thèmes : seul le format change la composition, jamais le thème. | manifeste §5 F |
| Barre basse sombre en gris neutre (`#4B4B4B`, `#5D5D5D`) : rejetée ; elle prend `surfaceRaised` + `contourCarte`. | manifeste §5 D |

## 2. Typographie (`lib/core/theme/app_typography.dart`)

### 2.1 Les quatre familles, pas une de plus (`app_typography.dart:17-43` ; `pubspec.yaml:107-153`)

| Famille | Fichier | Emploi |
|---|---|---|
| `DMSans` | `DMSans-Variable.ttf` (axes `opsz` 9 à 40, `wght` 100 à 1000) | Titres français : `headline*`, `title*`. Pas de chiffres tabulaires (aucune fonction `tnum`). |
| `PlusJakartaSans` | `PlusJakartaSans-Variable.ttf` (`wght` 200 à 800) | Tout le reste : corps, libellés, boutons, champs, navigation, pastilles, légendes, **tous les chiffres** (horaires, codes, PIN, chronomètre, initiales, statistiques), et les styles `display*`. |
| `UthmanTahaNaskh` | `UthmanTahaNaskh-Regular.otf` (KFGQPC, Complexe du Roi Fahd) | **Arabe document** : Coran, hadiths, livres, lettres, textes pédagogiques. Style `AppTypography.document()`, taille 28 et interligne 2 par défaut (`:229-235`). |
| `NotoSansArabic` | `NotoSansArabic-Variable.ttf` | **Arabe d'interface** : RTL, menus, boutons, libellés, navigation. Aujourd'hui posée seulement en **police de repli** de tous les styles latins (`:31-33`) ; aucun style d'interface arabe dédié n'existe. |
| Icônes (hors texte) | `Phosphor-Regular.ttf`, `Phosphor-Fill.ttf` | Voir §7. |

Polices retirées : Instrument Sans, Bricolage Grotesque (`:13-16`), Varela Round, Noto Sans (`lib/CLAUDE.md:27-28`). Toute maquette qui les emploie est fausse.

### 2.2 Échelle standard (rôles adultes) (`app_typography.dart:237-253`)

Crénage calculé par la taille (`:130-146`) : -0,02 em dès 32 ; -0,015 em de 24 à 31 ; -0,01 em de 18 à 23 ; 0 de 15 à 17 ; +0,01 em sous 15. Libellé en capitales de 12 px ou moins : +0,06 em (`:158-164`).

| Style | Famille | Taille / interligne (px) | Graisse | Crénage (px) | Emploi relevé |
|---|---|---|---|---|---|
| `displayLarge`, `displayMedium`, `displaySmall` | Jakarta tabulaire | 36 / 44 | 700 | -0,72 | Valeurs fortes seulement : compte à rebours, `StatTile`, heure « 13:45 » desktop |
| `headlineLarge` | DM Sans | 36 / 44 | 700 | -0,72 | Titre de page sans en-tête riche, mot-marque « Rewayah Academy » (`page_shell.dart:123` ; `marque_page.dart:22-31`) |
| `headlineMedium` | DM Sans | 32 / 40 | 700 | -0,64 | Titre de page à partir de 600 px (`entete_page.dart:52-54`) |
| `headlineSmall` | DM Sans | 28 / 36 | 700 | -0,42 | Titre de page sous 600 px, titre de feuille ou dialogue, question d'admission |
| `titleLarge` | DM Sans | 22 / 28 | 600 | -0,22 | Titre d'écran résultat, message d'état vide, mot-symbole « Rewayah » du rail (en 700) |
| `titleMedium` | DM Sans | 18 / 26 | 600 | -0,18 | Titre de section, de carte, de groupe, prénom sur carte enfant |
| `titleSmall` | DM Sans | 16 / 24 | 600 | 0 | Titre d'état système en bloc, titre de bandeau ambre |
| `bodyLarge` | Jakarta | 16 / 24 | 400 | 0 | Corps desktop, libellé de rubrique, sous-titre de page, libellé du rail |
| `bodyMedium` | Jakarta | 14 / 20 | 400 | 0,14 | Corps mobile, légende et valeur de rubrique, encart |
| `bodySmall` | Jakarta | 12 / 16 | 400 | 0,12 | Méta, sous-libellé d'avatar, bandeaux |
| `labelLarge` | Jakarta | 16 / 20 | 600 | 0 | Libellé de bouton, de lien fléché, de segment, d'onglet |
| `labelMedium` | Jakarta | 12 / 16 | 500 | 0,12 | Pastille de statut, libellé de barre basse (600 si actif) |
| `labelSmall` | Jakarta | 12 / 16 | 500 | 0,12 | Petits libellés |
| `chiffre()` | Jakarta tabulaire | défaut 32 / 40 (taille + 8) | 600 | selon taille | Horaires, codes d'appairage, PIN, chronomètre, initiales d'avatar (`:219-223`) |

### 2.3 Échelle Interface guidée (environ +20 %) (`app_typography.dart:110-123`)

Facteur 1,2, décidé dans ce seul fichier. Styles changés : `headlineSmall` 32/40 700 ; `titleLarge` 32/40 600 ; `bodyLarge` 20/28 400 ; `bodyMedium` 20/28 400 ; `labelLarge` 20/28 600 ; `bodySmall` 16/24 400. Les autres styles restent ceux du §2.2. Métriques liées (`app_metriques.dart:18-52`) : cible tactile 72 (48 en standard), rayon de surface 24 (16 en standard), marge interne 24 (16 en standard).

### 2.4 Règles typographiques

| Règle | Source |
|---|---|
| Titres de page en 700, titres de section et de carte en 600, corps 400, libellés et boutons 500 à 600, valeurs fortes 700. | `app_typography.dart:95-97` |
| Un titre DM Sans ne se retaille pas : une autre taille de titre se demande dans le fichier. Une graisse se change seulement par `AppTypography.graisse` (axe `wght`), jamais par un faux gras. | `:99-102`, `:185-210` |
| Chiffres tabulaires obligatoires dans toute colonne, compteur, minuteur, tuile de statistique. | `:166-183` |
| Onglets et sous-navigation en Jakarta `labelLarge`, pas en DM Sans. | `app_theme.dart:138-144` |
| Hiérarchie par la couleur des trois encres, jamais par une police amincie (pas de graisse « light »). | `archive/produit/design-tokens.md:241-244` |
| Typographie française imposée par le manifeste : apostrophe typographique U+2019, espace fine insécable U+202F avant « ? ». | manifeste §3.3 (remarques) et §5 A12 |
| **ÉCART** : `assets/i18n/fr.i18n.json` compte 555 apostrophes droites U+0027 contre 8 typographiques, aucune U+202F, et 31 « ? » précédés d'une espace ordinaire. La règle n'est pas encore appliquée aux chaînes existantes. | comptage de ce relevé |
| **Arbitrage ouvert** : en Plus Jakarta Sans, l'apostrophe (droite ou typographique) est plus large qu'une espace ; rendu lu « l 'heure ». | `04_phase0/revue_jetons_a11y.md:35` (D9) |

## 3. Espacements et gabarits (`app_spacing.dart`, `app_gabarit.dart`)

### 3.1 Échelle (`app_spacing.dart:13-57`)

`4 (xs) · 8 (sm) · 12 (md) · 16 (lg) · 20 (xl) · 24 (xxl) · 32 (xxxl) · 40 (section) · 48 (titreEcran) · 64 (respiration)`. Aucune autre valeur n'est acceptée (`lib/CLAUDE.md:22-23`).

### 3.2 Largeurs et hauteurs (`app_spacing.dart:63-96`, `:102-108`)

| Jeton | Valeur | Emploi |
|---|---|---|
| `largeurMaxContenu` | 1200 | Colonne de page, centrée au-delà (`page_shell.dart:239-251`) |
| `largeurGestion` | 1440 | Écrans de gestion (administration) |
| `largeurLecture` | 800 (et 68 caractères pour tout texte suivi) | Lecture, historique desktop |
| `largeurReglages` | 760 | Réglages, préférences |
| `largeurFormulaire` | 640 | Formulaires |
| `largeurDialogue` | 560 | Feuille bornée sur tablette, boîte de dialogue sur bureau, colonne d'admission (manifeste : 480 à 560) |
| `largeurEtatVide` | 400 | Écran résultat, état vide |
| `hauteurBouton` | 52 (72 en Interface guidée) | Bouton |
| `hauteurReglage` | 64 | Ligne de réglage à deux niveaux |
| `hauteurChoix` | 112 | Carte de choix |
| Cible tactile | 48 standard, 72 Interface guidée | Toute cible, même quand le dessin est plus petit |

### 3.3 Points de rupture et chrome (`app_gabarit.dart:10-121`)

| Gabarit | Largeur | Gouttière | Navigation |
|---|---|---|---|
| Mobile | < 600 | 16 | Barre basse flottante |
| Tablette | 600 à 1199 | 24 | Rail replié de 80 (icônes seules et infobulle pour le tuteur ; icône et nom dessous pour élève et enseignant, `nav_shell.dart:283-291`) |
| Desktop | ≥ 1200 | 32 | Barre latérale dépliée de 256 (admin : 288, `admin_shell.dart:100`) |

Seuils de contenu en plus : 840 (classe « étendue », densité seulement, `:62-63`), 560 (choix en deux colonnes si le texte est sous 150 %, `:70-71`, `:84-85`). **ÉCART** : le commentaire de `page_shell.dart:18-19` annonce des gouttières 20 / 32 / 48 ; le code applique 16 / 24 / 32 (`app_gabarit.dart:28-34`, `app_spacing.dart:65-71`).

Web = vraie version desktop, jamais le mobile étiré ; capture 1440 obligatoire pour chaque écran (`03_DECISIONS:36`, §1 ter-5).

## 4. Rayons (`app_radius.dart:13-77`)

| Jeton | Valeur | Emploi |
|---|---|---|
| `xs` | 8 | Pastilles, petits contrôles, vignettes |
| `sm` | 12 | Champs, boutons, bloc imbriqué, bandeau, item du rail, encart (`app_theme.dart:24-27`) |
| `md` | 16 | Cartes, carte groupée, barre basse flottante |
| `lg` | 24 | Tuiles Bento, carte de choix, boîte de dialogue, carte « dominante », surfaces en Interface guidée |
| `full` | 999 | Avatars, pilules d'état, contrôle segmenté, bascule de thème, **CTA des étapes d'admission (seule exception de bouton en pilule)** (`action_principale.dart:96-101` ; `03_DECISIONS:75`) |
| `arrondiFeuille` | 24 en haut seulement | Feuille de bas d'écran |

Règle : le rayon d'un enfant est plus petit que celui de son parent (`app_radius.dart:10-12`).

## 5. Élévation (`app_elevation.dart:32-88`)

| Niveau | Composition (couleur `#211E28`) | Emploi réel |
|---|---|---|
| `niveau0` | aucune ombre | **Défaut réel des cartes, cartes groupées, cartes de choix** : filet `contourCarte` de 1 px sans ombre (`app_card.dart:140-142` ; manifeste §3.2 : aucune maquette ne montre d'ombre de carte) |
| `niveau1` | y 2, flou 8, 4 % + y 8, flou 24, 6 %, étalement -4 | Barre basse flottante ; carte « dominante » en clair seulement |
| `niveau2` | y 4, flou 12, 8 % + y 16, flou 40, 10 %, étalement -8 | Zone d'action collée en bas, menus, popovers, retour local |
| `niveau3` | y 12, flou 32, 22 % | Feuille, boîte de dialogue |
| `dialogue()` | `niveau2` en clair (couleur `#000000`, `ombreDialogue`), **aucune ombre en sombre** | [critique] **Aucun emploi réel** : la fonction n'est appelée nulle part dans `lib/` à `cefab7f`. La feuille ET la boîte de dialogue d'`AppBottomSheet` rendent `niveau3` en `#211E28` dans les deux thèmes, sombre compris, avec le filet `borderHairline` ; la boîte de dialogue prend `surfaceOverlay`, rayon 24 (`app_bottom_sheet.dart:189-208`). À dessiner selon ce rendu, ou à trancher |

Règles : une carte n'est jamais posée sur une carte (deux plans suffisent) (`:18-20`). **ÉCART** : le commentaire annonce des opacités « remontées à 0,10 / 0,09 » (`:38-40`) et une règle « filet ET ombre » (`:21-23`) ; le code rend 0,04 / 0,06 et, par défaut, un filet sans ombre.

## 6. Mouvement et délais (`app_mouvement.dart:17-123`, `app_delais.dart:14-29`)

| Jeton | Valeur | Emploi |
|---|---|---|
| `retourTactile` | 100 ms | Pression (échelle 0,98, retour haptique moyen, `pressable.dart:159-166`) |
| `micro` | 120 ms | Bascule, case, pastille qui change d'état, survol |
| `apparition` | 180 ms | Ligne qui entre, bandeau, retour local ; aussi délai avant squelette |
| `navigation` | 220 ms | Passage de page (translation 16, inversée en RTL) |
| `feuilleOuverture` / `feuilleFermeture` | 180 / 120 ms | Feuille et dialogue (**ÉCART** : les commentaires de `app_bottom_sheet.dart:35-37` et `:150-154` disent 280 / 200 ms) |
| `plafond` | 400 ms | Aucune animation plus longue |
| `pulsation` | 1200 ms | **Un seul élément pulse dans tout le produit** : le bloc « cours dans moins de 5 minutes » de l'élève (ELV-02) |
| `retourLocalMaintien` | 3 s | Retour local (translation 12) |
| Courbes | entrée `easeOutCubic`, sortie `easeInCubic`, ressort sans rebond ; `linear` réservé aux progressions indéterminées ; aucun rebond, même en Interface guidée | `:65-85` |
| Mouvement réduit | durée 0, translation 0 ; la pulsation devient une bordure `borderStrong` fixe | `:101-122` |
| `chargementProlonge` | 8 s | Le squelette reste et une phrase dit que c'est long |
| `requeteMax` | 20 s | Tentative tenue pour perdue, « Réessayer » (3 fois au plus, `bloc_asynchrone.dart:75`) |

## 7. Iconographie (`lib/core/icons/app_icons.dart`)

- Une seule bibliothèque : **Phosphor**, deux graisses embarquées : `regular` (repos, contenu, navigation inactive) et `fill` (actif, sélectionné, médaillon, cercle héros). La paire est liée à la construction (`:3-20`). Zéro emoji, aucun Material ni Font Awesome (`:24-29`).
- 80 icônes au catalogue (`static const AppIcon`, comptage de ce relevé). Taille courante 24 (navigation, rubrique, disque retour), 20 (chevron, flèche de CTA, bouton de repli), 40 (cercle héros), 64 (état vide ; 96 en Interface guidée).
- Directionnelles miroitées en arabe : retour, flèche de CTA, chevron de ligne, repli et dépli du rail, se connecter. Non miroitées : horloge, progression du temps (`suivant`), menu déroulant (vers le bas), rotation (`:84-107`, `:347-380`, `:427-451`).
- Icônes de navigation du tuteur : Accueil `0xe2c2`, Foyer `0xe68e`, Historique `clock-counter-clockwise 0xe1a0`, Compte `0xe4c2` (`:46-50`, `:66-70`, `:84-92`, `:123-127`). « Un tuteur observe » = œil ouvert `0xe220` (`:599-615`). Prière `0xecee` (pictogramme compris sans lire, `:246-253`).
- Une icône ne porte jamais seule un état (`archive/produit/design-tokens.md:325-326`).

## 8. Navigation et coquilles (faits du code)

| Rôle | Destinations, dans l'ordre | Source |
|---|---|---|
| Tuteur | **Accueil · Foyer · Historique · Compte**, identiques sur tous les formats ; Compte épinglé en bas de la colonne latérale | `nav_shell.dart:91-120` ; `03_DECISIONS:79` (§3.6) |
| Élève (standard) | Accueil · Coran · Suivi · Compte | `nav_shell.dart:66-90` |
| Élève (Interface guidée) | aucune navigation | `:52-57` |
| Enseignant | Journée · Créneaux · Profil (exactement trois) | `:121-144` |
| Contrôleur, comptable | aucune coquille | `:145-157` |
| Administration | coquille propre, 8 domaines : Accueil, Opérations, Personnes, Pédagogie, Finance, Configuration, Sécurité et audit, Direction ; tiroir < 600, rail 600-1199, barre latérale ≥ 1200 ; jamais de barre basse ; barre supérieure = recherche, notifications, compte seulement | `admin_shell.dart:17-42` ; `core/admin/admin_domaine.dart:55-62` |

Anatomie :
- **Barre basse flottante** (< 600) : pilule `surfaceRaised`, rayon 16, filet `contourCarte`, `niveau1`, marges 12 à gauche et à droite, 8 au-dessus, au moins 12 sous elle dans la zone sûre ; hauteur minimale 64 ; icône 24 ; libellé `labelMedium` 500 (600 si actif) ; actif = icône pleine + libellé `inkAccent` + soulignement 40 x 3 `inkAccent` arrondi ; inactif = icône au trait + `inkMuted` ; texte borné à 150 % (`nav_shell.dart:361-507`).
- **Colonne latérale** (≥ 600) : `surfaceRaised`, filet `contourCarte` côté contenu ; en tête le mot-symbole « Rewayah » (`titleLarge` 700, `inkStrong`) et un bouton de repli (disque 40 `surfaceOverlay` dans une cible 48) ; items de 48 au moins, rayon 12, icône 24, libellé `bodyLarge` 500 (600 actif) ; actif clair = fond `washAccent` + `inkAccent` ; actif sombre = fond `surfacePrimary` + encre `#25113F` ; inactif = icône `inkMuted`, libellé `inkStrong`. Repli mémorisé par appareil (`:571-927`).
- **En-tête de page** : disque retour 48 (niveau 2 et tâche focalisée seulement) puis titre (`headlineSmall` 28 sous 600, `headlineMedium` 32 au-delà) et sous-titre `bodyLarge` `inkMuted` ; à droite, bascule clair/sombre (tablette et bureau seulement) puis cloche 48 (point de non-lus 8 `surfacePrimary` cerclé de 2, seulement pour de vrais non-lus) (`entete_page.dart:11-205`).
- **Page** (`page_shell.dart:41-199`) : 48 au-dessus du titre (24 si l'en-tête porte retour ou actions ; 64 en Interface guidée), 24 sous le titre, puis l'en-tête fixe éventuel (sélecteur, segment) suivi de 20 ; 40 de respiration en bas ; zone d'action collée en bas sur `surfaceRaised`, filet haut `borderHairline`, `niveau2`, marges 16.
- **Tâche focalisée** (ajout de profil, questionnaire, émetteur QR, sous-pages de préférences, consentement) : pas de barre basse sur mobile, disque retour obligatoire ; la colonne latérale reste sur tablette et bureau (`nav_shell.dart:276-281`).

## 9. Catalogue des composants partagés (`lib/core/widgets/`)

Colonne « Employé » : nombre de fichiers hors `core/widgets` et hors galerie de développement qui l'emploient à `cefab7f`. « 0 » = créé en phase 0, pas encore consommé par un écran sur cette branche (les lots peuvent l'employer sur leurs branches, À VÉRIFIER).

| Composant (fichier:ligne) | Rôle | Anatomie en une ligne | Employé |
|---|---|---|---|
| `ActionPrincipale` (`action_principale.dart:48`) | Seul point d'entrée d'un bouton ; 4 niveaux | Hauteur 52, marges 20 x 12, rayon 12, `labelLarge` ; **principale** = `surfaceActionDouce`, une par écran, flèche « → » facultative ; **secondaire** = `surfaceRaised` + filet `borderStrong` 2 (deux au plus) ; **tertiaire** = texte `inkAccent` ; **destructive** = texte `inkAlert`, jamais de fond rouge ; désactivé = `surfaceRaised` + filet 3 + `inkMuted` ; en cours = indicateur 20 | 48 |
| `PageShell` (`page_shell.dart:41`) | Gabarit de toute page | Voir §8 | 48 |
| `PageParcours` (`page_parcours.dart:26`) | Page de parcours : une question, une action | Progression en segments (« n sur N »), temps restant, retour, un seul bouton qui avance | 3 |
| `PageImmersive` (`page_immersive.dart:49`) | Plein cadre sans titre (salle, Coran) | Registre « salle » (`surfaceInverse`) ou « lecture » (`surfaceQuran`) ; ordre : en-tête, contenu, bandeau, commandes | 5 |
| `NavShell` (`nav_shell.dart:204`) | Navigation de premier niveau, 4 destinations au plus | Voir §8 | 1 |
| `AdminShell` (`admin_shell.dart:43`) | Coquille admin, 8 domaines | Tiroir, rail 80, barre 288 ; domaine sans fonction = visible mais atténué, inerte | 1 |
| `EntetePage`, `DisqueRetour`, `ClocheNotifications` (`entete_page.dart:25`, `:94`, `:139`) | En-tête, retour, cloche | Voir §8 | via `PageShell` |
| `BasculeTheme` (`bascule_theme.dart:30`) | Bascule clair/sombre de l'en-tête (≥ 600) | Pilule `surfaceRaised` + filet, segments soleil / lune de 48 ; actif clair `washAccent` + icône `inkAccent`, sombre `surfacePrimary` ; même préférence que Compte > Préférences > Apparence | 1 |
| `AppCard` (`app_card.dart:27`) | Seule surface de contenu | `surfaceRaised`, rayon 16, filet `contourCarte` 1, marge 20 (< 600) ou 24 ; retenue = `washAccent` + filet `inkAccent` 2 ; « dominante » = rayon 24 + `niveau1` en clair ; en-tête et actions facultatifs espacés de 16 | 32 |
| `GroupeReglages` + `LigneRubrique` (`groupe_reglages.dart:55`, `:13`) | **La carte groupée** (§1 ter-3) : un seul rectangle, lignes séparées par filets en retrait | Titre facultatif `titleMedium` au-dessus, 8 ; surface `surfaceRaised` rayon 16 filet `contourCarte` ; ligne ≥ 48 : icône 24 `inkAccent`, 12, libellé `bodyLarge` `inkStrong`, valeur ou légende `bodyMedium` `inkMuted`, chevron 20 `inkMuted` ou interrupteur ; filet `contourCarte` sous le texte (pas sous l'icône), absent sous la dernière ligne ; marges 16 et 12 | 0 |
| `SettingRow` (`setting_row.dart:11`) | Ancienne ligne de réglage | **Chaque ligne est son propre rectangle** (rayon 16, filet bas), icône `inkMuted`, titre `titleMedium` : contraire à §1 ter-3 pour une carte groupée ; retrait proposé quand les écrans seront migrés (`04_phase0/0c1_composants.md:75`) | 8 |
| `BentoTile` (`bento_tile.dart:42`) | Bloc de grille | Largeur pleine, demie, tiers ou quart ; `surfaceRaised` + filet | 13 |
| `ChoiceCardGroup` (`choice_card_group.dart:53`) | Tout choix proposé | Cartes ≥ 112, marge 20, rayon 24, filet `borderResting` ; retenue = `washAccent` + `borderStrong` + coche pleine ; libellé `titleMedium` ; carte « Autre » systématique sauf `autoriserSaisieLibre: false` (choix d'usage, décision du directeur, `03_DECISIONS:81`) | 12 |
| `ControleSegmente` (`controle_segmente.dart:35`) | 2 à 4 vues exclusives (« Séances / Observations ») | Piste `surfaceSunken` en pilule ; segment actif `washAccent` + filet `inkAccent` ; `labelLarge` ; segments ≥ 48, largeur égale | 0 |
| `SelecteurProfils` (`selecteur_profils.dart:74`) | Rangée de profils élèves (Accueil, Historique) | Avatar 56 (mobile) ou 72 ; initiale ou photo ; point de statut 12 cerclé du fond ; anneau 2 `surfacePrimary` si sélectionné ; prénom `labelLarge`, état `bodySmall` (`inkAccent` si sélectionné) ; dernier item « Ajouter » ; défilement horizontal sur mobile | 0 |
| `AvatarTile` (`avatar_tile.dart:29`) | Photo d'élève ou initiales | Diamètre par défaut 96 (144 guidée) ; repli `washFamily` + contour `borderStrong`, initiale en `chiffre` ; échec de chargement = même repli, jamais une icône d'erreur | 10 |
| `StatusPill` (`status_pill.dart:60`) | État nommé | Pilule, marges 12 x 4, point 8 + 8 + mot `labelMedium` ; fond doux du ton ; point pris dans `pointsStatut` | 34 |
| `EcranResultat` (`ecran_resultat.dart:31`) | Tout ce qui remplace le contenu (fin de visite, 404, accès refusé, session expirée, vide actionnable) | Colonne 400 centrée : cercle héros 96 (fond doux du ton, icône pleine 40), 24, titre `titleLarge`, 8, phrase `bodyLarge` `inkMuted`, 20, encart `washAccent` rayon 12, 24, CTA avec flèche, 8, lien tertiaire | 0 |
| `EtatSysteme` (`etat_systeme.dart:79`) | 12 natures d'état, portée bloc ou page | Bloc : carte à filet rayon 16, médaillon 40, titre `titleSmall`, phrase `bodyMedium`, action secondaire ; page : grammaire d'`EcranResultat`. Aucun code technique affiché | 2 |
| `EmptyState` (`empty_state.dart:46`) | Liste vide | Icône 64 (96 guidée) ; `titleLarge` ; invitation `bodyMedium` ; 3 registres : actionnable (accent + bouton), subi (neutre, sans bouton), bonne nouvelle (vert, ton neutre, sans félicitations) | 51 |
| `BlocAsynchrone` (`bloc_asynchrone.dart:40`) | Bloc qui charge | Squelette, puis phrase « long » à 8 s, puis erreur de bloc à 20 s, puis contenu ou vide ; « Réessayer » 3 fois au plus ; « indisponible » sans « Réessayer » | 0 |
| `Skeleton` (`skeleton.dart:27`) | Chargement | Blocs `surfaceSunken` à la forme du contenu final, rien avant 180 ms, ni scintillement ni pulsation | 42 |
| `OfflineBanner` (`offline_banner.dart:32`) | Hors ligne | Pleine largeur en tête de page, `washWarning` + `inkWarning`, filet fort en tête, dit ce qui continue de marcher | 1 (+ `PageShell`) |
| `LocalFeedback` (`local_feedback.dart:27`) | Retour d'une action | Bandeau `washAccent` rayon 12 posé sous la zone qui a changé, `niveau2`, 3 s ; jamais de boîte de succès ; « Annuler » préféré à une confirmation | 10 |
| `ConfirmDestructive` (`confirm_destructive.dart:27`) | Seule confirmation destructive | Question, conséquence en langage humain (obligatoire), « Annuler » d'abord, puis l'action qui nomme l'objet et l'acte (« Retirer Aicha ») | 4 |
| `AppBottomSheet` (`app_bottom_sheet.dart:40`) | Seule surface modale | Mobile : feuille pleine largeur, poignée 40 x 4, rayon 24 en haut ; tablette : bornée à 560 ; bureau : boîte de dialogue centrée 560, rayon 24, `surfaceOverlay` ; titre `headlineSmall` ; `niveau3` ; `Echap` ferme | 18 |
| `SectionHeader` (`section_header.dart:19`) | Titre de section, compteur, action tertiaire | Compteur tabulaire, zéro affiché | 20 |
| `LienFleche` (`lien_fleche.dart:20`) | « Voir tout → », « Voir l'historique → » | Texte `labelLarge` `inkAccent` + flèche 20, souligné au survol, cible 48, aucune surface | 0 |
| `LigneCleValeur` (`ligne_cle_valeur.dart:19`) | « Horaire : 18:00 (heure de Paris) » | Clé `inkMuted`, valeur `inkStrong` côte à côte ; empilées dès 150 % de texte ; lues en un seul nœud | 0 |
| `LignePresence` (`ligne_presence.dart:28`) | Présence d'une personne | Nom, pastille et mot, durée (« en salle depuis 12 min ») ; présence illisible = « État inconnu », jamais « Absence » | 5 |
| `SignalRow` (`signal_row.dart:21`) | Ligne « à traiter » | Icône, phrase, ancienneté, chevron ; mène toujours à une action | 2 |
| `StatTile` (`stat_tile.dart:22`) | Chiffre et libellé | `displaySmall` tabulaire + `labelMedium`, zéro affiché, mène à son écran | 3 |
| `TimelineRow` (`timeline_row.dart:20`) | Journée : cours, pause, prière | Même ligne pour les trois, libellé et icône décidés par le composant | 1 |
| `FilterPill` (`filter_pill.dart:25`) | Valeur de filtre d'un axe fermé | Pilule, compteur tabulaire | 12 |
| `MenuFiltre` (`menu_filtre.dart:54`) | Axe de filtre ouvert | Bouton pilule qui porte la sélection courante, menu dessous | 3 |
| `MenuActions` (`menu_actions.dart:36`) | Actions rares d'un objet | Menu contextuel, jamais un bouton permanent par ligne | 5 |
| `DataCollection` (`data_collection.dart:96`) | Tableau dense sur desktop, cartes ailleurs | Seuil desktop ; en-tête collé `surfaceSunken` ; colonne identifiante = titre de carte | 11 |
| `ChildCard` (`child_card.dart:100`) | Carte enfant de l'ancien Accueil famille (7 états) | Avatar, prénom `titleMedium`, détail, action ; imminent = liseré gauche 4 `borderStrong` ; « sans planning » = contour fort. Héritage du matching remplacé, À VÉRIFIER s'il survit au nouvel Accueil | 1 |
| `ScheduleOption` (`schedule_option.dart:13`) | Proposition d'horaire de l'administration | Carte rayon 16, aucune saisie libre de date | 1 |
| `SelecteurNiveauProgramme` (`selecteur_niveau_programme.dart:13`) | Niveaux du programme groupés par cycle | Nom humain seul, jamais le code | 3 |
| `SousNavigationDomaine` (`sous_navigation_domaine.dart:21`) | Onglets d'un domaine admin | Onglets = routes distinctes | 8 |
| `MarquePage` (`marque_page.dart:13`) | Marque du tunnel d'entrée | « Rewayah Academy » en `headlineLarge` `inkAccent` ; aucun logo n'existe | 6 |
| `PermanentNotice` (`permanent_notice.dart:25`) | Bandeau permanent de la salle | Aucun paramètre ; même ligne pour tous, contrôleur présent ou non : « Cours enregistré, visite de contrôle possible. » (`03_DECISIONS:22`) | 2 |
| `BandeauObservation` (`bandeau_observation.dart:35`) | Session d'observation par un agent IA | Registre doux `washWarning` ; dit lecture seule, prénoms masqués, heure d'expiration | 1 |
| `AudioLabel` (`audio_label.dart:23`) | Haut-parleur qui rejoue un libellé (zéro lecture) | Icône `inkAccent` ; clé audio, jamais un chemin libre | 1 |
| `PinPad` (`pin_pad.dart:25`) | Pavé numérique géant de l'élève | Le code ne quitte jamais l'appareil | 1 |
| `RosaceVerset` (`rosace_verset.dart:23`) | Numéro de verset | Cercle dessiné + chiffres arabo-indiens, muet pour le lecteur d'écran | 3 |
| `Pressable` (`pressable.dart:83`) | Seul retour tactile | Échelle 0,98, 100 ms, haptique moyen, survol et anneau de focus 2 `inkAccent` | 10 (+ tous les composants) |

Carte groupée : `GroupeReglages` ne sait pas encore porter un en-tête **dans** le rectangle (médaillon 48, titre, résumé, pastille) comme les cartes de Mon compte (V3) ; le lot E a posé une carte locale en attendant la promotion demandée (`demandes/E.md:34-42`). Deux défauts relevés au même endroit : valeur collée au libellé au lieu d'être calée à droite ; fond de survol qui recouvre le filet latéral.

## 10. Vocabulaire

| Imposé | Interdit | Source |
|---|---|---|
| « Interface guidée » | « Mode enfant », « mode enfant » | `docs/current/00:28` ; test `q09_interface_guidee_cibles_test.dart:119-138` |
| « Sayyid » / « Sayyida » (enseignants, dans l'espace de cours) | « Ustadh », « Sayda » | `docs/current/00:28`, `docs/current/03:12` ; manifeste §5 A5 ; clés `tc.groupe.enseignant.sayyid` (`fr.i18n.json:1838-1839`) |
| « Séance », « Cours » | « Session » (au sens de séance ; « session » d'authentification reste) | `03_DECISIONS:80` (§3.7) ; manifeste §5 A1 |
| « Séance toujours en direct », « En direct » (séance prolongée) | « Cours en cours », « Cours toujours en cours », compteur négatif | `03_DECISIONS:80` ; manifeste §5 A4 |
| « Ajouter un profil élève », « profils élèves », « Réglages de {prénom} » | « Ajouter enfant », « Ajouter un enfant », « Enfants », « Gérer tous les enfants », « Paramètres de l'enfant » | `03_DECISIONS:80` ; manifeste §5 A2 |
| « Avant le prochain cours » | « Avant / Après la séance » | manifeste §5 A3 |
| « Connexion et sécurité » | « Sécurité et connexion » | manifeste §5 A6 |
| « Pour qui souhaitez-vous utiliser Rewayah ? », « Moi uniquement », « Moi et ma famille » | « Quel type de compte… », « Pour qui créez-vous ce compte ? » | manifeste §5 A7 ; `03_DECISIONS:81` |
| « Détails de la séance » | « Détails et connexion » | manifeste §5 A8 |
| « En cours de vérification » (présence incertaine), « État inconnu » | « Absence » déduite d'une déconnexion | manifeste §5 A10, C7 ; `ligne_presence.dart:18-22` |
| Noms humains | Codes internes visibles (`F1-PHO-01`, `CORE24`, `DB-xxx`, codes de niveau) | `docs/current/03:12` ; `etat_systeme.dart:77-78` ; `selecteur_niveau_programme.dart:9-10` |
| Bouton = verbe et objet (« Poser un créneau », « Retirer Aicha ») | « Valider », « OK », « Supprimer » seuls | `action_principale.dart:62-63` ; `confirm_destructive.dart:22-23` |
| Titre qui nomme (« Aujourd'hui ») | Titre qui accueille (« Bienvenue sur votre tableau de bord ») | `page_shell.dart:58-60` |
| État vide = invitation (« Aucun cours aujourd'hui, ton prochain cours est jeudi ») | « Aucune donnée » | `empty_state.dart:34-37` |
| Ponctuation classique, deux-points | Emoji, tiret cadratin (U+2014) | `lib/CLAUDE.md:34` ; `archive/produit/design-tokens.md:319-322` |
| Phrases courtes et concrètes | « Dans le monde numérique d'aujourd'hui… », « Il est important de noter que… », « Révolutionnez… », « Sans plus attendre… », « Découvrez… », superlatifs | `archive/produit/design-tokens.md:386-412` (archive, non contredite) |
| « Classe » côté tuteur (« Voir la classe », routes `/tuteur/classes`) | À VÉRIFIER pour les autres rôles : à `cefab7f`, 71 chaînes visibles contiennent « groupe » et 4 « classe » ; `docs/current/06:18` dit « Espace Groupe » | manifeste §2 et §3.4 ; comptage de ce relevé |

**ÉCART** (chaînes existantes encore contraires, à remplacer dans les spécifications) : `enfant.titre` = « Ajouter un enfant » (`fr.i18n.json:336`) ; `compte.ajouterEnfant` = « Ajouter un enfant » (`:1297`) ; `compte.modeEnfant` = « Mode enfant » (`:1299`) ; `tc.groupe.temps.enCours` = « Cours en cours · {reste} » (`:1857`) ; `tc.groupe.temps.prolongee` = « Cours toujours en cours » (`:1859`).

Langue arabe : `assets/i18n/ar.i18n.json` ne contient qu'une vingtaine de clés (suivi élève et « Sayyid / Sayyida »). L'interface arabe n'existe donc pas encore au-delà de ces écrans. À VÉRIFIER avec le directeur avant de dessiner une maquette RTL complète.

## 11. Éthique visuelle trouvée dans le dépôt

| Règle | Statut | Source |
|---|---|---|
| Pas de femmes non voilées dans les illustrations, avatars ou images décoratives. | Archive, non contredite par `docs/current` : À CONFIRMER par le directeur | `docs/archive/2026-09-pre-remise-a-plat/produit/design-tokens.md:353-366` (§5 « Éthique islamique ») |
| Pas d'idoles ni de représentations de divinités. | idem | idem |
| Pas de caricatures obscènes ou malsaines. | idem | idem |
| Pas de représentation des prophètes ni des compagnons. | idem | idem |
| Pas de symboles religieux non musulmans (croix, étoile à six branches, etc.). | idem | idem |
| Recommandé : personnages masculins avec barbe et/ou kufi ou turban quand c'est approprié ; personnages féminins avec hijab ; motifs géométriques et calligraphiques islamiques pour la décoration. | idem | `design-tokens.md:368-374` |
| Recommandé : vert et or pour les accents religieux. **CONFLIT** avec le gel : aucun jeton or, le vert est réservé au succès. Le gel (§1 ter-2) prime tant que le directeur n'a rien décidé. | À TRANCHER | `design-tokens.md:373-374` ; `03_DECISIONS:33` |
| Illustrations : style Storyset / Rafiki, vectorielles, **ramenées à la palette** ; photos réelles réservées aux profils ; **« Pas de génération IA d'images »**. **CONFLIT** avec la demande de faire produire des images par ChatGPT : la règle vise les illustrations du produit ; une maquette est un document de travail. À TRANCHER : toute illustration visible dans une maquette reste un emplacement réservé, jamais un visuel destiné à la production. | À TRANCHER | `design-tokens.md:332-349`, `:376-382` |
| Photo d'élève : URL signée courte, jamais exposée à l'enseignant ni aux autres élèves ; repli identique au cas sans photo, jamais un triangle d'erreur. | Code | `avatar_tile.dart:8-22` |
| Photos publiques d'enseignants distinctes des pièces d'identité. | Canonique | `docs/current/03:12` |
| Le Coran ne se traite jamais comme une carte entourée de contrôles ; contenu avant chrome ; texte canonique jamais modifié ; aucun « Mushaf fidèle » simulé par retour à la ligne ; annotation dans sa couche, jamais dans le texte. | Code et canonique | `page_immersive.dart:29-32` ; `docs/current/03:17` ; `docs/current/00:31` |
| Chiffres de verset arabo-indiens dans une rosace dessinée, jamais un glyphe absent. | Code | `rosace_verset.dart:7-22` |
| Surface Coran figée dans les deux thèmes. | Code et test | `app_palette.dart:5-7` ; `contraste_test.dart:41-43` |
| Aucun texte arabe inventé ni approximatif dans une maquette (lettres confondues, voyelles manquantes relevées sur V8) : le support est un document vérifié, jamais un décor. | Manifeste | manifeste §5 C23 |
| Transparence de l'observation : la visite de contrôle est annoncée en permanence par une ligne identique pour tous ; une observation qui ne se voit pas est une observation cachée ; « un tuteur observe » s'affiche par un œil. | Code | `permanent_notice.dart:9-24` ; `bandeau_observation.dart:12-19` ; `app_icons.dart:599-611` |
| Ton jamais culpabilisant, jamais infantilisant, même en Interface guidée ; pas de félicitations sur un écran vu vingt fois par jour. | Archive et code | `design-tokens.md:407` ; `empty_state.dart:25-29` |
| Aucune règle trouvée sur la mixité ou la séparation des genres dans les visuels, ni sur les formules religieuses à l'écran. | À VÉRIFIER | recherche « éthique », « islamique », « voil », « hijab », « mixit » dans `lib/` et `docs/` |

Mise en garde : ce même fichier d'archive (`design-tokens.md`) porte les **anciennes valeurs** (fond crème `#F8F4EE`, Bricolage Grotesque, Instrument Sans, ombre `#3A302A`, gouttières 20 / 32 / 48). Elles sont périmées ; seules ses règles d'éthique et de rédaction sont citées ici. Même chose pour l'identité « vert `#1B6B5A`, or `#C9A84C`, beige `#F7F5F1` » d'un ancien audit (`archive/architecture/audit-initial.md:188`) : elle ne fait pas partie du système gelé.

## 12. Actifs visuels absents du dépôt (à connaître avant de dessiner)

| Actif | Constat | Source |
|---|---|---|
| Logo | Aucun fichier ; la marque est le texte « Rewayah Academy » (`commun.marque`) ou « Rewayah » (mot-symbole du rail) | `marque_page.dart:8-12` ; `fr.i18n.json:3` ; `nav` `motSymbole` |
| Icône d'application | `web/icons/Icon-192.png` est l'icône Flutter par défaut (vue) ; icônes Android et iOS de tailles typiques du gabarit Flutter, À VÉRIFIER à l'œil | `web/icons/`, `android/app/src/main/res/mipmap-*`, `ios/Runner/Assets.xcassets/AppIcon.appiconset` |
| Illustrations | Aucune image dans `assets/` (seulement `audio`, `fonts`, `i18n`) ; les états vides emploient une icône Phosphor de 64 | `assets/` ; `empty_state.dart:95-103` |
| Couleur de démarrage [critique] | **ÉCART** : le fond affiché pendant le chargement web vaut `#F8F4EE`, l'ancien crème archivé, et non `surfaceCanvas` `#F8F7FA` (`web/index.html:49` ; `web/manifest.json`, `background_color`), sans variante sombre : éclair clair au démarrage en thème sombre. `theme_color` = `#8652E6`. Android : fond de lancement du gabarit Flutter, couleur système `?android:colorBackground` (`android/app/src/main/res/drawable-v21/launch_background.xml:4`), pas un jeton | `web/index.html:40-49` (le commentaire renvoie à l'ancien `design-tokens.md`) |
| Maquettes existantes | 19 fichiers dans `docs de lancement/tutuor image/` ([critique] 9 dans `mobile/` et 10 à la racine, et non 10 dans `mobile/`), inventoriés et corrigés par le manifeste §1 et §5 ; écrans du tuteur encore sans maquette : `09_chatgpt/TUTEUR_ECRANS_SANS_MAQUETTE.md` | manifeste §1 |

## 13. Écarts et décisions en attente qui touchent le dessin

1. CTA en Interface guidée : aplat `surfacePrimary` gardé tant que le directeur n'a pas tranché sur capture (`action_principale.dart:235-240`).
2. Rail de tablette : icônes seules pour le tuteur, icône et nom pour élève et enseignant, en attendant une décision du directeur (`nav_shell.dart:283-291`).
3. Carte de choix : le code rend `washAccent` + filet `borderStrong` 1 + coche, rayon 24 ; le manifeste décrit bordure 2 `inkAccent` + radio 24 (manifeste §3.4, « Carte de choix ») ; extension radio, description et miniature demandée (`demandes/E.md:44-48`).
4. `lib/CLAUDE.md:45-46` dit encore « `inkFaint` interdit sur `surfaceSunken` (4,48) » : valeur périmée, mesure actuelle 4,65 (`04_phase0/0b_jetons.md:82`, `:121`).
5. Préférence clair / sombre non persistée sur le web : perdue à chaque rechargement (`revue_jetons_a11y.md:36`, D10).
6. Quatre commentaires du code annoncent des valeurs que le code n'applique pas : gouttières (§3.3), opacités d'ombre et « filet ET ombre » (§5), durées de feuille (§6). Les valeurs du code font foi.
7. [critique] Ombre des dialogues en sombre : la règle « aucune ombre en sombre » (`AppElevation.dialogue()`) n'est appliquée par aucun composant ; `AppBottomSheet` rend `niveau3` dans les deux thèmes (§5).
8. [critique] Fond de démarrage web `#F8F4EE` hors palette gelée, sans version sombre (§12). À aligner sur `surfaceCanvas` clair et sombre par décision, puisque le gel exige une décision datée pour toute valeur.


---


# D. Tuteur : écrans sans maquette

# Rôle Tuteur : écrans et états sans maquette high-fi (faits vérifiés)

Date : 24/09/2026. Destinataire : ChatGPT, pour le document `01_TUTEUR_COMPLEMENTS.md` et ses maquettes.
Statut : relevé en lecture seule, aucun fichier du dépôt modifié.

## 0. Comment lire ce document

**Sources** (toutes lues pour ce relevé) :
- `MANIFESTE` = `pilotage-tuteur-v1/01_visuel/00_MANIFESTE.md` (§1 inventaire des maquettes, §2 écrans sans maquette, §5 erreurs, §6 dérivations).
- `V1` à `V9` = rapports détaillés `pilotage-tuteur-v1/01_visuel/V*.md` (une maquette ou un groupe par rapport).
- `MANDAT` = `docs de lancement/REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md` (§4 arbre des routes, §5 contenu, §6 admission, §7 appareils, §8 états) ; `MANDAT-OBS` = sa seconde partie « Prompt étape observation tuteur » (§1 à §10).
- `DÉCISIONS` = `pilotage-tuteur-v1/03_DECISIONS_COORDINATEUR.md` (les §1 bis, §1 ter, §1 ter bis sont des réponses du directeur et priment).
- `MAPPING` = `pilotage-tuteur-v1/02_code/00_MAPPING_ROUTES.md` (numéros de ligne de son §3 : « l.n ») ; `C03` = `02_code/C03_admission.md`.
- `LOTS` = `pilotage-tuteur-v1/05_LOTS_PHASE1.md` ; `BACKLOG` = `pilotage-tuteur-v1/08_BACKLOG_VAGUE_CLASSE_VISIO.md`.
- `CODE` = dépôt `D:\RA_TUTEUR\integration`, branche `ui/tuteur-v1`, commit `cefab7f` (fin de la phase 0 : routeur, thème, composants partagés ; les écrans des lots sont encore des écrans réservés marqués « STUB PHASE 0 » dans 40 fichiers de `lib/`).
- `FINANCE` = `RA -OFFICIAL-APP/docs/current/07_MEMOIRE_PEDAGOGIE_FINANCE.md`.

**Conventions** :
- `#n` = numéro de la zone de maquette dans MANIFESTE §1 (33 zones dans 19 fichiers du dossier `docs de lancement/tutuor image/`). Le tableau du §1 ci-dessous les rappelle.
- `SM-nn` = identifiant d'un écran **sans maquette** dans ce document. ChatGPT peut le reprendre ou le remplacer par `TUT-nn`, à condition de garder la correspondance.
- `DB-xxx` = dépendance serveur manquante, recensée dans `02_code/00_DEPENDANCES_BACKEND.md`. En production, l'écran affiche alors l'état « indisponible » (texte existant : « Pas encore disponible » / « Cette fonction n'est pas encore ouverte. », `CODE assets/i18n/fr.i18n.json:56-59`).
- « À vérifier » = fait que je n'ai pas pu prouver.

**Règles du directeur qui s'appliquent à chaque maquette à produire** (DÉCISIONS §1 ter) :
1. Les maquettes font autorité pour la **disposition** (ordre des sections, colonnes, place exacte de chaque bouton et de la route qu'il ouvre), jamais pour la palette. Couleurs et polices viennent du système gelé : DM Sans pour les titres, Plus Jakarta Sans pour tout le reste, palette ajustée listée en DÉCISIONS §3.1.
2. Une fonction = un seul endroit, aucun doublon. Seul raccourci admis : « Créer mon profil élève » depuis Foyer ET Compte, qui ouvre le même flux.
3. Carte groupée = UN seul rectangle, lignes séparées par un filet fin en retrait. Jamais un rectangle par ligne.
4. Barre de navigation, retour visible sur chaque écran de niveau 2 et chaque tâche focalisée, déconnexion accessible sur tous les formats. Aucune impasse.
5. Web = vraie version ordinateur (rail dès 600 dp, barre latérale dès 1200 dp), jamais le mobile étiré.
6. Captures de recette exigées : **390 × 844 et 1440 × 900, clair ET sombre** pour chaque écran (LOTS §0).
7. Navigation tuteur : **Accueil · Foyer · Historique · Compte**, même ordre partout (DÉCISIONS §3.6).

---

## 1. Rappel : les maquettes qui existent déjà (ne pas les redessiner)

| # | Fichier | Écran réel | Thème | Format | Route retenue (CODE) |
|---|---|---|---|---|---|
| 1 | `acceuil tuteur desktop light.png` | Accueil | Clair | Ordinateur ≈ 1440 | `/tuteur` |
| 2 | `acceuil tuteur desktop dark.png` (moitié gauche) | Accueil, rail replié | Sombre | Tablette ≈ 690 | `/tuteur` |
| 3 | `acceuil tuteur desktop dark.png` (moitié droite) | Accueil, rail déplié | Sombre | Ordinateur étroit ≈ 1100 | `/tuteur` |
| 4 | `mobile/accueil  tuteur mobile light mode.png` | Accueil | Clair | Mobile | `/tuteur` |
| 5 | `mon compte tuteur desktop light mode.png` | Mon compte | Clair | Ordinateur | `/tuteur/compte` |
| 6 | `mobile/mon compte tuteur mobile light mode.png` | Mon compte | Clair | Mobile | `/tuteur/compte` |
| 7 | `mobile/mon compte tuteur desktop dark mode.png` | Mon compte (nom de fichier faux : c'est un MOBILE) | Sombre | Mobile | `/tuteur/compte` |
| 8 | `réglages tutor mobile dark mode.png` (écran 01) | Réglages (hub des préférences du titulaire) | Sombre | Mobile | `/tuteur/compte/preferences` |
| 9 | idem (écran 02) | Apparence | Sombre | Mobile | `/tuteur/compte/preferences/apparence` |
| 10 | `onboarding Mble.png` | Choix d'usage | Sombre | Mobile | `/inscription/usage` |
| 11 | `onboarding Mble d.png` | Genre (« d » ne veut pas dire dark) | Sombre | Mobile | `/inscription/genre` |
| 12 | `onboarding mobile 1.png` E1 | Choix d'usage (autre version) | Sombre | Mobile | `/inscription/usage` |
| 13 | idem E2 | Genre | Sombre | Mobile | `/inscription/genre` |
| 14 | idem E3 | Âge (champ libre) | Sombre | Mobile | questionnaire `/tuteur/parcours/:eleveId` |
| 15 | `Onboarding mobile 2.png` E4 | Langue de l'application | Sombre | Mobile | relève de `/tuteur/compte/preferences`, pas de l'admission |
| 16 | idem E5 | Objectif | Sombre | Mobile | questionnaire `/tuteur/parcours/:eleveId` |
| 17 | idem E6 | Récapitulatif « Tout commence ici. » | Sombre | Mobile | `/inscription/recapitulatif` |
| 18 | `mobile/tuteur observation mobile light.png` M1 | Classe de l'enfant + bloc Observation | Clair | Mobile | `/tuteur/classes/:classeId` |
| 19 | idem M2 | Explication de première utilisation | Clair | Mobile | `/tc/observation/:seanceId` (étape avant « Entrer ») |
| 20 | idem M3 | Salle d'observation, visite 1/2 | **Sombre** | Mobile | `/tc/observation/:seanceId` |
| 21 | idem M4 | Salle d'observation, visite 2/2 | Clair | Mobile | `/tc/observation/:seanceId` |
| 22 | idem M5 | Fin de visite (écran résultat) | Clair | Mobile | retour `/tuteur/classes/:classeId` |
| 23 | idem M6 | Consentement « Les visites des parents » | Clair | Mobile | `/attente/contrat` et `/tuteur/compte/consentements` |
| 24 | `tuteur observation desktop light.png` D1 | Salle d'observation | Clair | Ordinateur | `/tc/observation/:seanceId` |
| 25 | idem D2 | Historique, segment Observations | **Sombre** | **Mobile** | `/tuteur/suivi/observations` |
| 26 | idem D3 | Historique des observations, ADMINISTRATION | Clair | Ordinateur | `/admin/securite-audit/observations` (hors rôle tuteur) |
| 27 | idem D4 | Détail d'une observation | Clair | **Mobile** | `/tuteur/seances/:seanceId/observations?eleve=` |
| 28 | `tutor observation map.png` | Logigramme du parcours Observation | - | - | aucune (planche de direction, aucune valeur visuelle réutilisable) |
| 29 | `mobile/Accueil.png` | ANCIENNE capture de l'Accueil (remplacée par #4) | Sombre | Mobile | contenu seulement |
| 30 | `mobile/Foyer Member.png` | ANCIENNE capture du Foyer | Sombre | Mobile | contenu seulement |
| 31 | `mobile/Historique.png` | ANCIENNE capture de l'Historique des séances | Sombre | Mobile | contenu seulement |
| 32 | `mobile/Classe Details.png` | ANCIENNE capture de la Classe | Sombre | Mobile | contenu seulement |
| 33 | `mobile/Profil.png` | ANCIENNE capture de la FICHE ÉLÈVE (pas le compte) | Sombre | Mobile | contenu seulement |

Sources : MANIFESTE §1 ; routes vérifiées dans `CODE lib/core/router/routes.dart` (lignes citées plus bas) ; route du détail d'observation tranchée en DÉCISIONS §3.9.

Les anciennes captures #29 à #33 ne servent qu'au **contenu et à l'ordre** des informations, jamais au rendu (MANDAT §2).

---

## 2. Écrans du rôle Tuteur sans AUCUNE maquette high-fi

Pour chaque écran : route exacte (constante du CODE), contenu attendu (MANDAT §4-§8 et MANDAT-OBS), états à dessiner, maquette la plus proche à imiter (MANIFESTE §2, MAPPING §7.2). Les états système communs (chargement, hors ligne, échec, etc.) sont détaillés une seule fois au §2.8 et s'appliquent à tous les écrans.

### 2.1 Public et admission

| Id | Route (CODE `routes.dart`) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-01 | `/bienvenue` (`:35`) | Bienvenue | Titre, sous-titre, CTA « Commencer », lien secondaire « J'ai déjà un compte ». Les deux mènent à `/connexion` : c'est le lien envoyé par courriel qui crée le compte, pas de double création (MAPPING l.1). Remplace l'écran actuel qui affiche « Écran à construire ». | Nominal ; chargement prolongé | #17 (colonne centrée) + #22 (CTA ancré en bas, lien secondaire) |
| SM-02 | `/` (`app_router.dart:156-159`, `EcranDemarrage`) | Démarrage neutre | Écran affiché le temps de vérifier la session. Aucun texte de chantier. | Attente ; attente prolongée ; hors ligne au démarrage (texte existant : « Rewayah a besoin d'Internet pour vérifier votre compte. Reconnectez cet appareil, puis réessayez. », `fr.i18n.json:61`) | #22 |
| SM-03 | `/connexion` (`:15`) | Connexion | En production : **lien de connexion à usage unique par courriel** et **Google** seulement ; le mot de passe n'existe qu'en démonstration locale (`CODE lib/core/auth/service_auth.dart:12-24`). « Renvoyer le lien », état « lien expiré ou déjà utilisé », lien discret « accès appareil élève » vers `/connexion/eleve` (MAPPING l.2). | Saisie ; envoi en cours ; lien envoyé (attente) ; lien expiré ou déjà utilisé ; erreur sous le champ ; échec Google | #14 (champ encadré à étiquette, erreur sous le champ, CTA ancré) |
| SM-04 | `/connexion/recuperation` (`:32`) | Récupérer mon accès | Récupérer = redemander un lien (pas de mot de passe en production). | Saisie ; attente ; retour ; lien expiré ; erreur | #14 + #22 |
| SM-05 | `/inscription/identite` (`:49`) | Identité du titulaire | Texte existant : « Comment vous appelez-vous ? » ; « Ce nom doit être celui de votre pièce d'identité. » ; champs « Prénom », « Nom » (C03 §3.2). Préremplir ce que Google fournit déjà (MANDAT §6 « ne pas redemander sans raison » ; aujourd'hui rien n'est prérempli). | Vide (CTA désactivé) ; erreur sous chaque champ ; rempli | #14 : deux champs empilés, écart 12 dp |
| SM-06 | `/attente` (`:58`) | Portail du dossier | Quatre états calculés par le serveur : incomplet, en vérification, refusé (avec motif serveur), suspendu (C03 §3.3). Afficher le statut exact et **une seule** prochaine action. « Se déconnecter » accessible. Interdit : cartes empilées et jusqu'à 3 CTA pleins (MAPPING l.7 ; MANDAT §4 : « trop de CTA et trop de rectangles… à bannir »). « Contacter l'académie » reste non actionnable tant que DB-CPT-07 manque. | Incomplet (liste des pièces manquantes dans l'ordre accusé, contrat, pièce) ; en vérification ; refusé ; suspendu | #17 + #22 |
| SM-07 | `/attente/accuse` (`:64`) | À savoir avant de commencer | Deux points : notice d'enregistrement et notice de contrôle. **L'enregistrement audio est réel** : garder mot pour mot les clés `contrat.pointEnregistrement` et `salle.bandeauPermanent` = « Cours enregistré, visite de contrôle possible. » (DÉCISIONS §1 bis-2). Action « J'ai compris ». | Nominal ; envoi ; erreur | #23 (lignes icône + texte, CTA) |
| SM-08 | `/attente/contrat` (`:67`) | Ce que vous signez | Nouvelle version du texte signé = texte existant (notice d'enregistrement comprise) + paragraphe d'observation clair et bienveillant : qui peut observer, ce qu'il entend et voit, ce qu'il ne peut pas faire, pourquoi, limites de visites. Variantes « responsable légal » et « élève adulte ». Case **non précochée** (DÉCISIONS §1 bis-3 ; MANDAT-OBS §6). Seule la partie observation a une maquette (#23), avec un texte à corriger (voir §6). | Case non cochée (CTA désactivé) ; cochée ; envoi ; erreur ; variante responsable légal ; variante élève adulte | #23 |
| SM-09 | `/attente/piece` (`:70`) | Votre pièce d'identité | Choix du type (Carte d'identité, Passeport, Titre de séjour, Autre), « Choisir la photo », aperçu, « Envoyer ma pièce », plafond 8 Mo vérifié avant envoi (C03 §3.3). Jamais confondue avec le portrait de l'élève. | Aucun fichier ; aperçu ; envoi avec progression ; fichier trop lourd ; échec avec reprise ; envoyé | Cartes de choix #12 + champ #14 |
| SM-10 | `/tuteur/parcours/:eleveId` (`:159-165`) | Questionnaire pédagogique, par élève nommé | Sept étapes existantes (C03 §3.5), prénom de l'élève dans chaque question : 1) âge par **tranche** fournie par le serveur ; 2) langue **du cours** (pas celle de l'application) ; 3) lieu, pour l'heure locale ; 4) niveau (« Où en est {prénom} aujourd'hui ? », 5 réponses) ; 5) objectif ; 6) moments de la journée ; 7) horaires ou classes proposés. Branches débutant / non-débutant selon les règles rendues par le serveur, aucun code interne (MANDAT §6). En production le serveur de ce questionnaire n'est pas déployé : état indisponible honnête (MAPPING l.6, DB-ADM-01). | Chaque étape vide / remplie / erreur ; « n sur N » calculé selon la branche ; reprise ; indisponible ; aucune proposition compatible (« Aucun horaire ouvert ne correspond encore », avec « Me prévenir si de nouveaux horaires ouvrent ») | Étapes 1 et 5 : #14 et #16 existent mais sont en conflit (voir §6) ; étapes 2, 3, 4, 6, 7 : lignes de choix #15 / #16 |

Remarques admission :
- CONFLIT à ne pas trancher en silence : le high-fi #14 demande un âge exact (« 28 ans ») alors que le code propose des tranches serveur et que MANDAT §6 parle de cohortes 6-9, 10-13, 14-17, 18+ et de date de naissance (C03 §3.5, V6 E3, MANIFESTE §5 C13).
- CONFLIT : étape 7, classe réelle ou « offre horaire » (DÉCISIONS §2 P1 : défaut retenu « vraies classes », à confirmer par le directeur).
- La langue de l'application (#15) n'est pas une étape d'admission : elle relève des préférences (MANIFESTE §5 C14).

### 2.2 Accueil et Classe

| Id | Route (CODE) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-11 | `/tuteur/notifications` (`:260`) | Notifications | Liste, détail, destination liée (MANDAT §4). Aucune source de notifications n'existe : en production, écran indisponible et **cloche sans pastille** (MAPPING l.9, DB-CPT-04). Pas de route de détail tant que la source manque (MAPPING §7.1). | Indisponible ; vide ; liste (non lues / lues) ; chargement ; erreur | Lignes de #25 + en-tête de #1 / #4 |
| SM-12 | `/tuteur/classes/catalogue?eleve=` (`:204`) | Choisir une classe | Une carte par classe : parcours, public ou niveau, langue, enseignant avec photo et Sayyid / Sayyida, **toutes** les séances de la semaine, durée, fuseau, places réelles. Confirmer la même classe et le même enseignant sur toute la semaine. Aucune réservation locale (MANDAT §5 Classe). En production : « le choix de classe en ligne n'est pas encore ouvert » (DÉCISIONS §2 P1). | Liste ; aucune classe compatible ; liste d'attente ; dernière place perdue ; confirmation refusée ; confirmation en cours ; confirmée ; indisponible | Carte classe de #1 (colonne gauche) + cartes de choix #12 |
| SM-13 | `/tuteur/classes/:classeId/planning` (`routes.dart:216-225`) | Planning | Tous les jours récurrents de la classe, même enseignant, heure locale, durée, **fuseau explicite** ; exceptions datées (annulée, reportée, absence d'enseignant, remplacement) jamais présentées comme un cours normal. Aucun décalage UTC fixe (MANDAT §5 Classe). Le service du planning complet n'existe pas : le créneau connu s'affiche dans le fuseau de la classe avec un libellé explicite (MAPPING l.27, DB-CRS-03 à 06). | Planning ; exception annulée ; reportée ; remplacement ; indisponible ; vide | Lignes de #25 |
| SM-14 | `/tuteur/classes/:classeId/travail` | Travail à préparer | Consignes, détails, supports, statuts. « Marquer fait » n'atteste aucune maîtrise (FINANCE l.12) et n'existe pas côté serveur (DB-CRS-10) : aucune coche locale. | Liste complète (sans la limite de 3 de l'Accueil) ; vide ; indisponible | Liste de tâches à cercles de #1 / #4 |
| SM-15 | `/tuteur/classes/:classeId/ressources` | Bibliothèque | Ressources autorisées, ouverture dans le lecteur existant `/tc/bibliotheque/:resourceId`. Aucun lecteur PDF (MAPPING l.29). | Liste ; vide ; ressource retirée ; erreur | Lignes de #6 + carte du support de #20 / #24 |
| SM-16 | `/tuteur/classes/:classeId/progression` | Progression | Séances et présences réelles, observations partageables. Jamais les comptes rendus internes des enseignants (MAPPING l.30, DB-CRS-11, DB-TRV-02). | Contenu ; vide ; indisponible | Ligne « Dernière séance » de #1 + lignes de #6 |

La Classe elle-même (`/tuteur/classes/:classeId`) a une maquette mobile claire (#18) : ses variantes manquantes sont au §3, ses états d'observation au §4.

### 2.3 Foyer et fiche élève (aucune maquette high-fi : seulement les anciennes captures #30 et #33 pour le contenu)

| Id | Route (CODE) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-17 | `/tuteur/foyer` (`:102`) | Foyer | Titre « Foyer », description courte si utile, action « Ajouter un profil élève » (vers `/tuteur/foyer/ajouter`), une carte groupée des membres (avatar ou initiale, prénom, classe ou « inscription en cours », statut d'accès en texte, chevron vers la fiche), section « Appareils partagés » (ligne vers `/tuteur/foyer/appareils`), option discrète « Créer mon profil élève » tant que ce profil n'existe pas. Pas de compteurs décoratifs, pas de CTA doublon (MANDAT §5 Foyer ; LOTS B-1). | Foyer vide (aucun profil) ; un profil ; plusieurs profils ; profil du titulaire présent ; chargement ; erreur | Contenu #30 ; rendu : lignes de #5 / #6 + avatars du sélecteur de #1 / #4 |
| SM-18 | `/tuteur/foyer/ajouter` (`:110`), `?pour=moi` (`:119`) | Ajouter un profil élève | Parcours plein écran sans barre de navigation, retour 48 dp. Même flux depuis Accueil, Foyer et Compte. Choix « pour un enfant ou mineur » disponible ; « proche adulte » et « moi-même » visibles mais indisponibles et expliqués (DB-FOY-01, DB-FOY-02). Champs existants : prénom, nom, âge entier de 3 à 18 ans (constante du client ; C03 §3.4). Enchaînement vers la fiche puis le questionnaire. Refusé tant que le dossier du titulaire n'est pas validé (DB-ADM-04). **Le directeur annonce une refonte de ce parcours** (voir §5). | Formulaire vide ; erreurs sous les champs ; envoi ; création incertaine (réponse perdue) ; succès ; option indisponible expliquée ; dossier non validé | Gabarit d'étape de #12 / #14 |
| SM-19 | `/tuteur/foyer/:eleveId` (`:126`) | Fiche élève | En-tête : photo, prénom, âge si disponible, classe ou état d'inscription. Puis une carte groupée de six lignes, dans l'ordre du CODE (`routes.dart:134-141`) : Informations, Parcours et inscription, Interface, Caméra en cours, Accès Rewayah, Appareils. Onglet actif : **Foyer**. **Place réservée à un futur solde par élève** (DÉCISIONS §1 ter-9). | Nominal ; élève sans classe ; accès expiré ; identifiant inconnu (« introuvable ») ; chargement | Contenu #33 ; rendu : carte d'identité + groupes de lignes de #5 / #6 |
| SM-20 | `.../informations` | Informations de l'élève | Prénom et nom affichés, non modifiables (DB-FOY-07) ; date de naissance absente du serveur (DB-ADM-05) ; photo : choisir, aperçu, envoi, progression, échec avec reprise. Portrait jamais mélangé avec une pièce d'identité. | Sans photo ; aperçu ; envoi ; échec ; photo enregistrée | Lignes de #6 + champs #14 |
| SM-21 | `.../inscription` | Parcours et inscription | Synthèse : questionnaire, dossier, choix de classe, attente ; liens vers `/tuteur/parcours/:eleveId` et le catalogue. | Questionnaire à faire ; en attente ; inscrit ; indisponible | Récapitulatif #17 + lignes de #6 |
| SM-22 | `.../interface` | Interface | « Interface guidée » ou interface standard selon la politique réelle ; demande d'interface standard par l'élève à partir de 10 ans seulement si confirmée (DB-FOY-04). Aucune bascule qui élève les droits (MANDAT §5 Fiche). | Guidée active ; standard active ; demande en attente ; indisponible | Cartes d'option à radio de #9 |
| SM-23 | `.../camera` | Caméra en cours | Autorisation métier de la caméra de l'élève pendant les séances ; l'effet s'applique à la séance suivante ; confirmation avant changement. Distincte de la permission caméra du scanner QR (MAPPING l.16). | Autorisée ; non autorisée ; confirmation ; enregistrement ; erreur | Lignes à interrupteur de #9 |
| SM-24 | `.../acces` | Accès Rewayah | Statut, dates réelles, « expiré » si la date est passée, motif seulement s'il est fourni (DB-FOY-05). | Actif ; expiré ; sans date ; indisponible | Carte « Abonnement et accès » de #5 / #6 |
| SM-25 | `.../appareils` | Appareils de l'élève | Appareils associés, action « Connecter un appareil » (vers l'émetteur QR), retrait avec confirmation et réponse du service. Dire que le retrait ne ferme pas une session déjà ouverte (DB-APP-03). Aucune limite d'appareils codée en dur. | Liste ; vide ; confirmation de retrait ; retrait en cours ; retiré ; échec | Contenu #33 ; rendu : lignes de #6 + pastille |
| SM-26 | `/tuteur/foyer/appareils` (`:123`) | Appareils du foyer | Nom de l'appareil, profils autorisés, gestion. Un appareil partagé n'est pas encore représentable côté serveur (DB-APP-05). Aucun « 1/2 » ni « un seul en cours à la fois » (MAPPING l.19). | Liste ; vide ; indisponible | Lignes de #6 |
| SM-27 | `/tuteur/foyer/ajouter?pour=moi` | Créer mon profil élève (indisponible) | Écran honnête : la création du profil élève du titulaire n'existe pas encore (DB-FOY-01). Même écran depuis Foyer et Compte. | Indisponible | #22 |

### 2.4 Appareils (parcours des deux côtés, MANDAT §7)

Sens existant, vérifié : **le téléphone du tuteur AFFICHE le QR, l'appareil de l'élève, sans session, le LIT** (LOTS D ; MAPPING §2).

| Id | Route (CODE) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-28 | `/tuteur/foyer/appairer/:eleveId` (`:147-150`) | Connecter un appareil (émetteur) | Grand QR **noir sur fond blanc dans les deux thèmes**, marges libres, code manuel lisible, consigne « Sur l'autre appareil », durée de validité réelle. Dès la confirmation du serveur, QR ET code retirés de l'écran, puis « Appareil connecté ». Aucune décoration sur les modules du QR (MANDAT §7). | Préparation ; actif ; validation en cours ; association confirmée ; expiré ; remplacé ou révoqué ; erreur ; réseau interrompu | #22 (colonne centrée). [critique] Pas de maquette, mais le rendu du lot D existe en captures 390 et 1440, clair et sombre, pour 9 états (préparation, actif, déjà actif, confirmé, expiré, remplacé, plafond, erreur, hors ligne) : `D:\RA_TUTEUR\pilotage-git\05_recette\D\captures\emetteur_*.png`, avec deux comparaisons à #22 (`emetteur_*_contre_M5*.png`). État du code d'une branche de lot, pas une cible : à regarder avant de dessiner |
| SM-29 | `/connexion/eleve/scanner` (`:26`) | Scanner le QR code (appareil élève) | Mobile : viseur plein écran, retour 48 dp, « Saisir le code ». Ordinateur et tablette : panneau centré, jamais une feuille mobile étirée. Jamais ouvrir une URL contenue dans un QR. Sur Windows et Linux : pas de bouton scanner (MAPPING l.21). | Demande d'autorisation ; refus ; refus durable ; caméra occupée ; caméra absente ; navigateur sans caméra ; erreur de démarrage ; lecture en cours ; succès ; QR inconnu ; expiré ; déjà utilisé ; révoqué | #20 (plein cadre sombre) ; #24 (version ordinateur centrée) |
| SM-30 | `/connexion/eleve/code` (`:29`) | Saisir le code | Champ unique de 6 caractères (format serveur `^[2-9A-HJ-NP-Z]{6}$`, MAPPING l.21), chiffres tabulaires. Refus différenciés : inconnu, expiré, déjà utilisé, révoqué (DB-APP-06). | Vide ; saisie ; erreur sous le champ ; validation ; succès | #14 |
| SM-31 | `/connexion/eleve` (`:21`), état « choix du profil » | Choisir mon profil (appareil partagé) | Grille à deux colonnes d'avatars des profils autorisés, repli en une colonne à 200 % de texte ; « J'ai un nouveau code ». Aucun accès au compte du tuteur. | Un profil ; plusieurs profils ; aucun profil | Grille de #11 / #13 + avatars du sélecteur |
| SM-32 | `/connexion/eleve`, états « code personnel » | Créer / entrer mon code PIN | Création puis saisie du code personnel ; le code ne quitte jamais l'appareil ; erreurs du pavé visibles ; récupération = le tuteur retire l'appareil et le reconnecte (MAPPING l.24). | Création ; confirmation ; saisie ; erreur ; trop d'essais (à vérifier : règle non relevée) | #14 |

À vérifier : le registre de langue des écrans SM-29 à SM-32, vus par l'élève (tutoiement de l'Interface guidée pour un enfant, vouvoiement pour un adulte) n'est tranché dans aucune source lue.

### 2.5 Historique

| Id | Route (CODE) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-33 | `/tuteur/seances/:seanceId` (`:185-188`) | Détail de la séance | Identité de la séance (classe, date, heure avec fuseau, enseignant), présence et durée, résumé destiné à la famille (DB-CRS-12), travail et ressources autorisés. Distinguer durée du cours et temps connecté si les deux existent (DB-HIS-03). « En cours de vérification » pour une présence incertaine. Réseau seulement si mesuré. Jamais de notes internes, coordonnées privées ou télémétrie brute (MANDAT §5 Historique). | Présent ; absent validé ; retard validé ; en cours de vérification ; séance annulée ; identifiant inconnu ; résumé indisponible | #27 (détail d'observation) |

### 2.6 Mon compte : sous-pages

| Id | Route (CODE `routes.dart:233-257`) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-34 | `/tuteur/compte/informations` | Informations personnelles | Identité et coordonnées du titulaire. Modification impossible côté serveur (DB-CPT-01) : lecture seule honnête. Le fuseau lu par le serveur retombe sur Europe/Paris par défaut : ne pas le présenter comme un choix (MAPPING l.35). | Lecture ; donnée absente ; indisponible pour modification | Carte d'identité et lignes de #5 / #6 + champs #14 |
| SM-35 | `/tuteur/compte/securite` | Connexion et sécurité | Méthodes réelles du compte (lien à usage unique, Google), adresse courriel, sessions actives (DB-CPT-02), déconnexion. Aucun écran de mot de passe en production. | Nominal ; sessions indisponibles ; confirmation de déconnexion | Carte « Sécurité et connexion » de #5 / #6 (titre à corriger) |
| SM-36 | `/tuteur/compte/acces` | Accès (titre à trancher) | Bénéficiaires, accès et échéances réels. Accès offert, accès daté et paiement externe validé ne sont pas un abonnement récurrent (MANDAT §5 Mon compte). CONFLIT de titre : MANDAT §4 « Abonnement et accès » contre MAPPING l.37 « jamais « abonnement » ». | Actif ; expiré ; suspendu ; offert ; en attente ; indisponible | Carte « Abonnement et accès » de #5 / #6 |
| SM-37 | `/tuteur/compte/paiements` | Paiements | Historique réel, détail, justificatif disponible ; montants, devises, statuts et dates fournis seulement. Aucun service en production (DB-CPT-03) : indisponible. « Moyen de paiement » masqué ou indisponible ; une seule entrée vers cette page. **Place réservée à la recharge et au solde par élève** (DÉCISIONS §1 ter-9). | Indisponible ; vide ; liste ; détail | Liste de #25 + détail de #27 |
| SM-38 | sous-page de `/tuteur/compte/preferences` (route à créer, à vérifier) | Langue et région | Langue de l'interface : seul le français est traduit (l'arabe compte 32 lignes contre 2 366 [critique] : et non 2 208 ; `fr.i18n.json` compte 2 366 lignes non vides à `cefab7f`), donc « Français » en lecture seule (MAPPING §7.1 l.39, DB-CPT-10). Fuseau en libellé humain (ville), jamais un identifiant technique brut ni un décalage fixe (V4 fiche 01). | Nominal ; fuseau indisponible | [critique] Le choix de langue a déjà une maquette : #15 (E4 « Langue de l'application », que le §1 range dans les préférences), à reprendre sans English ni العربية non traduits ; fuseau : lignes à radio de #9 |
| SM-39 | sous-page de `/tuteur/compte/preferences` (route à créer, à vérifier) | Notifications | Seulement les réglages qui ont un effet réel ; les interrupteurs sans effet sont retirés ou câblés (MAPPING l.39). | Nominal ; indisponible | Lignes à interrupteur de #9 |
| SM-40 | sous-page de `/tuteur/compte/preferences` (à créer ou ligne informative) | Taille du texte ; Cours et données | « Taille du texte » suit le réglage du système (pas d'impasse derrière un chevron). Les réglages existants « Cours et données » (économie de données, lecture agrandie du Coran) sont à préserver (V4 fiche 01). | Nominal | Lignes de #9 |
| SM-41 | `/tuteur/compte/aide` | Aide et support | Aide, contact disponible, suivi si existant. Canal de contact à fournir par le directeur (DB-CPT-07) : indisponible sinon. | Indisponible ; contenu | Lignes de #5 / #6 |
| SM-42 | `/tuteur/compte/informations-legales` | Informations légales | Documents réellement disponibles ; acceptations déjà signées lisibles ; « Document non disponible » sinon (DB-CPT-08). | Liste ; document indisponible | Lignes de #5 / #6 |
| SM-43 | `/tuteur/compte/consentements` (`:256-257`) | Consentement aux visites d'observation (comptes existants) | Lit les acceptations, propose la nouvelle version ; aucun compte considéré comme ayant accepté (DÉCISIONS §2 P2 ; MAPPING §4 C2). | Non accepté ; accepté ; envoi ; erreur | #23 |
| SM-44 | dialogue depuis `/tuteur/compte` | Confirmation de déconnexion | Déconnexion clairement séparée des autres rubriques, avec confirmation (LOTS E-1). | Ouvert ; déconnexion en cours | Aucune ; surface modale de bureau du CODE (commit `42feded`) |

### 2.7 Pages transversales

| Id | Route (CODE) | Écran | Contenu attendu | Maquette la plus proche |
|---|---|---|---|---|
| SM-45 | `errorBuilder` (`app_router.dart:154`) | Page introuvable | Titre humain, phrase utile, action principale, lien secondaire. Texte existant : « Cette page est introuvable » / « Le lien est peut-être incomplet, ou la page n'existe plus. » (`fr.i18n.json:28-31`) | #22 |
| SM-46 | redirection + notice | Accès refusé | « Vous n'avez pas accès à cette page » / « Ce contenu n'est pas ouvert à votre compte. » (`:32-35`) ; retour sûr, sans fuite de données | #22 |
| SM-47 | `/connexion?retour=<chemin validé>` | Session expirée | « Votre session a expiré » / « Reconnectez-vous pour continuer. » (`:36-39`) ; retour vers la destination autorisée, sans boucle | #22 |
| SM-48 | aucune (hors production seulement) | Mode démonstration | Repère discret « Démonstration » et sélecteur de rôle ; données fictives, aucun appel serveur ; impossible en production (DÉCISIONS §1 bis-1, §1 ter-6, §1 quater). À vérifier : aucun fichier dédié trouvé dans le CODE à `cefab7f`. | Aucune |

### 2.7 bis [critique] Parcours indispensables à la publication, absents de la liste

Vérifié à `cefab7f` : les sous-pages de Compte sont `informations`, `securite`, `acces`, `paiements`, `preferences`, `aide`, `informations-legales`, `consentements` (`routes.dart:231-257`) ; aucune route ni aucune chaîne de suppression de compte (`lib/`, `supabase/`) ; aucun envoi d'e-mail ni de push (`supabase/functions/`, `pubspec.yaml`).

| Id | Route | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-49 | à créer sous `/tuteur/compte` (à trancher) | Supprimer mon compte | Conséquences en langage humain : profils élèves du foyer, appareils associés, classes, données conservées pour obligation légale et durée (`ADM-17`) ; confirmation par `ConfirmDestructive` ; demande traitée par l'académie tant qu'aucune suppression serveur n'existe. Exigé par Apple et Google (règles en vigueur **à vérifier**). Accès séparé de la déconnexion | Explication ; confirmation ; demande envoyée ; indisponible ; échec | Lignes de #5 / #6 ; résultat #22 |
| SM-50 | depuis la fiche élève `/tuteur/foyer/:eleveId` | Retirer un profil élève | Retrait du profil d'un mineur et de ses données, conséquence sur sa classe et ses appareils, confirmation nommée (« Retirer Aicha ») | Confirmation ; en cours ; retiré ; refusé (séance en cours, à vérifier) | Carte groupée de la fiche + `ConfirmDestructive` |
| SM-51 | à trancher (Historique ou Classe) | Messages de l'académie sur l'élève | Signalements d'un enseignant transmis par l'administration : seulement le résumé famille, jamais les détails internes. Le serveur existe : vue `concern_famille_v` (`supabase/migrations/0033_tc_vues_rpc.sql:267-282`), statut `transmis` (`0032_tc_catalogue.sql:567-591`). **Place à confirmer par le directeur** | Liste ; vide ; détail ; indisponible | Lignes de #25 + détail #27 |
| SM-52 | avant la demande système (mobile) | Autoriser les notifications | Écran d'amorce qui dit ce que l'on recevra (rappel de séance, changement, dossier) avant la demande d'iOS ou d'Android 13+ ; seulement quand une source de notifications existe (DB-CPT-04) | Proposé ; accepté ; refusé (renvoi aux réglages de l'appareil) | #19 (explication de première utilisation) |

Hors écran, à spécifier pour le tuteur : **e-mails transactionnels** (lien de connexion, dossier incomplet, validé ou refusé, rappel et changement de séance, accès qui arrive à échéance, suppression confirmée). Le dépôt n'a ni modèle personnalisé ni SMTP de production (`supabase/config.toml:239-258` commentés) : en l'état, les e-mails Supabase par défaut, en anglais. **Acceptation des conditions et de la politique de confidentialité** avant la création du compte : aucune case ni lien dans `/inscription` (à ajouter à SM-05 ou au récapitulatif). **Export de mes données** : absent, à trancher avec le directeur.

### 2.8 États système communs à tous les écrans

Composant du CODE : `lib/core/widgets/etat_systeme.dart:19-66`, deux portées : **bloc** (le reste de la page reste en place) ou **page** (grammaire de l'écran résultat #22). Textes existants (`fr.i18n.json:11-70`) :

| État | Titre existant | Phrase existante | À dessiner |
|---|---|---|---|
| Chargement initial | - | - | Squelette de la carte, mêmes dimensions (MANIFESTE §6.3) |
| Chargement prolongé | « La connexion prend plus de temps que prévu » | « Vous pouvez patienter encore un peu ou réessayer. » | bloc et page |
| Hors ligne | « Vous êtes hors ligne » | « Vérifiez votre connexion. Ce qui est déjà affiché reste consultable. » | bandeau et page |
| Reconnexion | « Reconnexion en cours » | « Une nouvelle tentative de connexion est en cours. » | bandeau discret |
| Échec serveur | « Impossible de charger ces informations » | « Le chargement n'a pas abouti. Réessayez dans un instant. » | bloc (la carte garde son cadre + « Réessayer ») et page |
| Dossier en attente | « Votre dossier est en attente » | « Une étape reste à franchir avant d'ouvrir cet espace. » | page |
| Aucun résultat | « Aucun résultat » | « Rien ne correspond pour le moment. » | bloc, avec « Réinitialiser les filtres » |
| Autorisation refusée | « Autorisation refusée » | « Sans cette autorisation, cette fonction ne peut pas s'ouvrir. Vous pouvez la modifier dans les réglages de votre appareil. » | page, avec alternative (code manuel) |
| Ressource expirée | « Ce contenu n'est plus disponible » | « Il a été retiré, ou son accès a pris fin. » | page |
| Indisponible | « Pas encore disponible » | « Cette fonction n'est pas encore ouverte. » | bloc et page, sans « Réessayer » |

ChatGPT peut proposer de meilleurs textes (marqués PROPOSITION), en gardant un seul texte par état pour toute l'application.

---

## 3. Écrans qui ont une maquette, mais seulement dans un thème ou un format

Formats exigés en recette : 390 × 844 et 1440 × 900, clair et sombre (LOTS §0) ; tablette 768 dans le prompt ChatGPT. Source : MANIFESTE §6.1, complété par V3, V4, V8.

| Écran | Route | Existe | Manque | Règle de composition du manquant |
|---|---|---|---|---|
| Accueil | `/tuteur` | Mobile clair #4 ; ordinateur clair #1 ; tablette sombre #2 ; ordinateur étroit sombre #3 | **Mobile sombre** ; tablette claire | Composition de #4, couleurs de #3 (MANIFESTE §6.3) |
| Mon compte | `/tuteur/compte` | Ordinateur clair #5 ; mobile clair #6 ; mobile sombre #7 | **Ordinateur sombre** ; tablette | Composition de #5, couleurs de #7 |
| Réglages (hub des préférences) | `/tuteur/compte/preferences` | Mobile sombre #8 | **Clair** ; ordinateur ; tablette (colonne de 760 dp) | Un seul groupe à filets au lieu de quatre cartes (V4) |
| Apparence | `/tuteur/compte/preferences/apparence` | Mobile sombre #9 | **Clair** ; ordinateur ; tablette | Composition de #9 ; indice de rendu clair dans ses miniatures |
| Admission : usage, genre, âge, langue, objectif, récapitulatif | `/inscription/*`, `/tuteur/parcours/:eleveId` | Mobile sombre #10 à #17 | **Clair** ; ordinateur et tablette (colonne centrée de 480 à 560 dp, CTA en bas de colonne) | Gabarit d'étape de V6 ; CTA en pilule réservé à l'admission (DÉCISIONS §3.2) |
| Classe + bloc Observation | `/tuteur/classes/:classeId` | Mobile clair #18 | Sombre ; **ordinateur et tablette** | Deux colonnes de #1 : carte séance à gauche (enseignant avec photo, prochaine séance, « Observer la séance », visites disponibles, « Comment ça marche ? »), lignes Planning, Travail, Bibliothèque, Progression, Historique à droite |
| Explication de première utilisation | étape de `/tc/observation/:seanceId` | Mobile clair #19 | Sombre ; ordinateur (colonne centrée ou dialogue) | Pas de feuille étirée |
| Fin de visite | retour classe | Mobile clair #22 | Sombre ; ordinateur ; variantes de fin (voir §4) | Écran résultat |
| Consentement observation | `/attente/contrat`, `/tuteur/compte/consentements` | Mobile clair #23 | Sombre ; ordinateur | Colonne centrée |
| Salle d'observation | `/tc/observation/:seanceId` | Mobile sombre #20 ; mobile clair #21 ; ordinateur clair #24 | Ordinateur sombre ; **mobile paysage** ; tablette ; **et refonte de l'en-tête pour tous les formats** (voir §4.3) | Un seul style de barre de commandes par format |
| Historique | `/tuteur/suivi` et `/tuteur/suivi/observations` | Mobile sombre #25 (segment Observations seulement) | **Clair** ; **ordinateur** ; **segment Séances** (contenu de #31) ; vide ; filtré sans résultat | Composition de #25 ; ordinateur : liste limitée à la largeur de lecture, rail de #1 |
| Détail d'une observation | `/tuteur/seances/:seanceId/observations?eleve=` | Mobile clair #27 | Sombre ; ordinateur ; motifs « Fin de séance » et « Interrompue » | Même ligne de visite que #27 |
| Historique des observations, administration | `/admin/securite-audit/observations` | Ordinateur clair #26 | Sombre (rôle administration, hors tuteur) | Navigation admin existante, pas la barre latérale de #26 |

États absents des maquettes existantes, à dessiner avec les mêmes compositions (V1 §6, V2 §8, V3 n°22, V6) :
- **Accueil** : vide (première inscription ou ajout de profil, jamais une fausse classe) ; chargement ; erreur de bloc ; hors ligne ; avant ouverture de la salle ; salle ouverte (fenêtre donnée par le serveur, en général 20 minutes avant) ; séance en direct ; séance prolongée « Séance toujours en direct » sans compteur négatif (DÉCISIONS §3.7) ; terminée ; annulée ; reportée ; changement d'heure ; horaire incertain sans horloge serveur (état `horaireIncertain` du contrat K2, MAPPING §7.1) ; présence « En cours de vérification » ; profil du titulaire dans le sélecteur (jamais appelé « enfant ») ; photo de l'enseignant (absente de #1 à #4).
- **Mon compte** : rubriques absentes de #5 à #7 : Préférences (engrenage muet), Informations légales, « Créer mon profil élève », ligne Foyer, déconnexion séparée avec confirmation (V3 n°9 ; MAPPING §7.1) ; place pour le futur solde ; chargement, erreur, hors ligne.
- **Admission** : état initial vide sur chaque étape (CTA désactivé ou erreur sous le groupe) ; lien discret « Je suis enseignant » sous les cartes d'usage (DÉCISIONS §3.8) ; raison de la question du genre en sous-titre ; correction par ligne au récapitulatif ; double soumission bloquée.

---

## 4. Planche 3 manquante : « États particuliers et notices de présence »

Fait : MANDAT-OBS §2 annonce trois planches ; la planche 3 est **introuvable** dans le dossier des maquettes (MANIFESTE §1 l.79-80 ; V8 §5 ; DÉCISIONS §2 P10, demandée au directeur). À produire par ChatGPT.

### 4.1 Règles d'observation qui fixent le contenu (priment sur toutes les maquettes)

- Par défaut : 2 visites maximum par séance, 120 secondes maximum par visite, 240 secondes au total, jamais une visite unique de 4 minutes ; valeurs configurables par l'administration, l'écran lit la politique effective (MANDAT-OBS §4).
- Quota **par parent** (par compte observateur), 2 visites par séance quel que soit le nombre de ses enfants dans la salle ; **une visite écourtée est consommée** (DÉCISIONS §1 bis-4).
- Observation possible seulement si l'enfant est présent. Ne pas confondre caméra désactivée, coupure temporaire et absence. Présence incertaine = vérification, jamais une absence inventée (MANDAT-OBS §4).
- Le tuteur entend l'enseignant et les élèves dont le micro est actif, voit le support partagé, l'enseignant et son propre enfant ; il n'a ni micro, ni caméra, ni chat, ni réactions, ni annotations, ni liste des autres élèves (MANDAT-OBS §4).
- Le compteur ne démarre qu'à l'entrée confirmée, jamais pendant l'explication ou la vérification (MANDAT-OBS §5). Une reconnexion ne simule pas du direct et ne remet pas le compteur à zéro (MANDAT-OBS §7).
- En production, l'observation réelle reste fermée (interrupteur `OBSERVATION_TUTEUR_REELLE` à faux, DÉCISIONS §2 P3) : le bloc affiche un motif « pas encore ouverte ». Le parcours complet se montre en démonstration.

### 4.2 États à dessiner, par emplacement (MANIFESTE §6.3 ; V7 §4 et §6 ; LOTS O-3)

| Emplacement | État | Texte existant dans le CODE (`fr.i18n.json`) | Remarque |
|---|---|---|---|
| Bloc Observation de la Classe (#18) | 2 visites disponibles | aucun (« 2 visites disponibles • 2 min par visite » sur #18, valeurs illustratives) | Nombre et durée lus dans la politique |
| idem | 1 visite restante | aucun | Accord au singulier |
| idem | Visites épuisées | `refus.quotaVisites` « Vous avez déjà utilisé vos visites pour cette séance. » (`:2221`) ; `refus.tempsEpuise` (`:2222`) | CTA retiré ou désactivé avec motif |
| idem | Enfant absent | aucun texte dédié | Seulement sur présence validée |
| idem | Présence en cours de vérification | aucun | Troisième issue absente du logigramme #28 (V7 §6) |
| idem | Séance non commencée | `refus.seanceNonActive` « La séance n'est pas en cours. » (`:2224`) ; `refus.horsFenetre` (`:2225`) | |
| idem | Séance terminée | aucun texte de refus dédié | |
| idem | Observation désactivée pour cette classe | `refus.politiqueDesactivee` « L'observation est désactivée pour ce groupe. » (`:2220`) | Texte à corriger : « classe », jamais « groupe » à l'écran (BACKLOG, réponses du directeur) |
| idem | Tuteur non rattaché à un élève de la séance | `refus.lienTuteur` (`:2223`) | |
| idem | Observation pas encore activée (production) | `refus.capaciteAbsente` (`:2227`) | |
| idem | Lien « Comment ça marche ? » toujours visible | - | Même après la première utilisation (V7 §6) |
| Avant la salle (#19 et suivant) | Explication de première utilisation | `entree.tuteurIntro` (`:2207`), à remplacer par le texte de MANDAT-OBS §6 complété par la règle « visite écourtée consommée » | Compteur arrêté ; « Pas maintenant » ramène à la classe |
| idem | Connexion et vérification | aucun | Compteur arrêté |
| idem | Connexion prolongée | texte commun « La connexion prend plus de temps que prévu » | Absent du logigramme (V7 §6) |
| idem | Connexion impossible | `refus.indisponible` (`:2226`) | « Réessayer » ; ne décrémente rien localement |
| idem | Annuler pendant l'explication ou la vérification | aucun | Retour sans consommer de visite (V7 §6) |
| Dans la salle (#20, #21, #24) | Reconnexion | `visite.budgetIncertain` « Temps restant non confirmé par le serveur. » (`:2237`) | Surimpression discrète, pas de faux direct |
| idem | Caméra de l'enfant désactivée | `visite.enfantAbsent` « Votre enfant n'a pas d'image ouverte. » (`:2236`) | Le nom de clé mélange absence et caméra (V7 §7.4) : le texte doit dire « caméra », pas « absent » |
| idem | Aucun support partagé | `visite.supportIndisponible` (`:2233`) | |
| idem | Vidéo de la séance non ouverte | `visite.videoIndisponible` (`:2238`) | |
| idem | Son reçu coupé / rétabli | - | Jamais par la couleur seule |
| idem | Sortie non confirmée | `visite.sortieNonConfirmee` (`:2239`) | |
| Fin de visite (variantes de #22) | Sortie volontaire | `fin.sortieVolontaire` (`:2244`) | Avec visites restantes réelles |
| idem | Durée de visite atteinte | `fin.quotaAtteint` « Votre temps d'observation est écoulé. » (`:2245`) | |
| idem | Fin de séance | `fin.seanceTerminee` (`:2246`) | |
| idem | Observation interrompue | `fin.revocationServeur` (`:2247`) ; `fin.deconnexion` (`:2248`) | |
| idem | Plus aucune visite | « Aucune visite restante pour cette séance » (DÉCISIONS §1 bis-5) | Lien « Voir mes observations » vers `/tuteur/suivi/observations` |

Les lignes `:22xx` renvoient à `CODE assets/i18n/fr.i18n.json` au commit `cefab7f`, dans le bloc `observation` (lignes 2204 à 2255).

### 4.3 Salle d'observation : décision du directeur qui change les maquettes existantes

DÉCISIONS §1 bis-5 : « visio moderne, épurée, très peu de boutons » ; **en haut, un bandeau pleine largeur** qui affiche le **décompte du temps restant seconde par seconde** et le **nombre de visites restantes** (« 1/2 visite restante pour cette séance », accord au pluriel, « Aucune visite restante pour cette séance » à 0) ; commandes : son reçu, agrandir le support, quitter.

Or #20, #21 et #24 placent « Visite 1/2 · 01:42 » dans une pastille de l'en-tête, sans bandeau, et montrent trois styles différents de barre de commandes et deux icônes « Quitter » (V8 M4). Conséquence : **la salle doit être redessinée** (en-tête et barre de commandes) en mobile portrait, mobile paysage, tablette et ordinateur, clair et sombre. Le reste de la composition (support dominant, deux vignettes secondaires qui ne couvrent jamais le support) est conservé. Le décompte tranche l'ambiguïté « décompte ou temps écoulé » relevée en MANIFESTE §5 C9.

### 4.4 Notices de présence (côté enseignant et côté enfant)

- Règle : l'enseignant et l'enfant concerné voient une notice discrète ; les autres élèves ne reçoivent rien ; « Votre maman… » seulement si le lien familial est connu, sinon « Votre parent… » (MANDAT-OBS §4).
- **Hors périmètre du chantier Tuteur** : à concevoir avec les rôles enseignant et élève (DÉCISIONS §1 bis-6). Elles relèvent donc de `02_CLASSE_ET_VISIO.md`, pas des écrans du tuteur.
- Textes existants à corriger (CODE `fr.i18n.json:2250-2255`) : côté enfant « Ton tuteur regarde le cours » (contredit la règle ci-dessus) ; côté enseignant « Tuteur de {prenomEnfant} observe », « {nombre} tuteurs observent ».

---

## 5. Fonctions du tuteur annoncées pour plus tard (DÉCISIONS §1 ter-9)

Texte exact de la décision : « À venir côté tuteur (ne pas construire, laisser la place) : recharge de solde, chaque enfant consomme son propre solde, parcours d'ajout d'un nouvel enfant revu. Les visuels viendront plus tard. Compte > Paiements et Foyer > fiche élève doivent pouvoir accueillir un solde par enfant sans refonte. »

| Fonction | Emplacement décidé | Faits qui encadrent la spec | État dans le CODE |
|---|---|---|---|
| Recharge de solde | Compte > Paiements (`/tuteur/compte/paiements`) | Paiement initial hors application, enregistré et validé manuellement ; pas de débit ni de versement inventé ; aucun prestataire unique imposé ; pas de dépendance permanente à un seul prestataire pour la diaspora (FINANCE §Finance l.20). Prix jamais écrits dans l'application ; valeurs anciennes 50 USD par mois, 90 USD pour deux, 40 USD par personne à partir de trois, **à confirmer** (FINANCE l.23). | Aucun écran, aucun contrat serveur (DB-CPT-03 pour les paiements) : CONTRAT À CRÉER |
| Solde par élève (« chaque enfant consomme son propre solde ») | Foyer > fiche élève (`/tuteur/foyer/:eleveId`) ; résumé possible dans Paiements (une seule fonction par endroit : la recharge dans Paiements, le solde de chaque élève dans sa fiche) | Registre de crédits immuable (attribution, réserve, consommation, libération, expiration, compensation, annulation) ; aucun solde corrigé par écrasement ; équivalence prix / temps à valider avant activation (ancien scénario 50 USD, 30 unités, 12 séances, non universel) ; absence de l'élève et cours assuré selon une politique versionnée ; absence d'enseignant sans remplacement = compensation (FINANCE l.25). | Aucun |
| Parcours d'ajout d'un nouvel enfant revu | `/tuteur/foyer/ajouter` (même flux depuis Accueil, Foyer, Compte) | Actuel : un écran, prénom, nom, âge 3 à 18 ans (C03 §3.4) ; serveur : création d'un profil mineur, âge 3 à 99, mode d'interface et caméra déduits de l'âge (C03 §3.4). Contraintes : cohortes 6-9, 10-13, 14-17, 18+ et date de naissance si confirmées (MANDAT §6 ; DB-ADM-05) ; proche adulte et profil du titulaire à prévoir (DB-FOY-01, DB-FOY-02) ; ajout seulement après validation du dossier (DB-ADM-04) ; idempotence (DB-FOY-06) ; enchaîner vers le questionnaire puis le choix de classe. | Écran réservé au lot B (STUB) |

Ces trois fonctions n'ont ni maquette ni visuel annoncé : ChatGPT les spécifie et les dessine en PROPOSITION, marquées « à venir, ne pas construire avant accord du directeur ».

---

## 6. Erreurs à ne pas reproduire, maquette par maquette

Une ligne par maquette (MANIFESTE §5 ; V1 à V9). Valable pour toutes : prénoms, dates, heures, durées, quotas, compteurs et noms de classe sont illustratifs et ne deviennent jamais des constantes (MANIFESTE §5 B) ; ne pas dessiner la barre d'état iOS ni les étiquettes de planche (MANIFESTE §5 G) ; cibles d'au moins 48 dp et contraste AA (MANIFESTE §5 E).

| # | Erreurs à ne pas reproduire |
|---|---|
| 1 | « Ajouter enfant » ; « Session 18:00 » ; « Adam / Absente » (accord faux, absence par la seule couleur) ; « Dernière séance 1 h » ambigu ; initiale de l'élève à la place de la photo de l'enseignant ; « Détails et connexion » (dire « Détails de la séance ») ; « Avant / Après la séance » (dire « Avant le prochain cours ») ; « Salle ouverte » à T-13 figé ; bascule de thème sans mode Système ; cadre arrondi sur fond lavande (mise en scène). |
| 2 | Mêmes erreurs de texte que #1 ; « 1 tâche + 2 autres activités » (afficher 3 tâches partout) ; « + » en pointillé (contour plein) ; rail replié sans infobulle ni étiquette pour le lecteur d'écran. |
| 3 | Mêmes erreurs de texte que #1 ; colonne droite en trait vertical au lieu d'une carte : un seul arbre d'écran, seul le format change la composition, jamais le thème (MANIFESTE §5 F). |
| 4 | Barre à 3 onglets (4 exigés) ; « Ajouter enfant » ; « Session dans 13 min » ; Mariam « En séance » dans le sélecteur mais « dans 13 min » dans la carte ; deux blocages simultanés (photo et appareil) ; « Réseau élève / enseignant Bon » ; dates incohérentes (lundi 21 et jeudi 18 septembre) ; carte « Dernière séance » cachée sous la barre ; accent lavande pâle illisible (2,8:1) ; bouton « Connecter un appareil » coupé sur deux lignes. |
| 5 | CTA dominant « Gérer les paiements » et doublons vers Paiements ; « Moyen de paiement » ; « Compte vérifié » sans statut serveur ; « Sécurité et connexion » (dire « Connexion et sécurité ») ; « Appareils connectés · 2 appareils » ; « disponibilités » ; téléphone affiché deux fois ; « Email et mot de passe » (méthodes réelles seulement) ; Préférences, Informations légales, « Créer mon profil élève » absents ; lignes d'« Aide et support » indentées ; contenu étiré sur 1096 dp. |
| 6 | Mêmes erreurs de contenu que #5 ; bande « Se déconnecter » trop basse (moins de 48 dp) ; légendes et textes verts sous AA. |
| 7 | Mêmes erreurs de contenu que #5 ; le nom du fichier dit « desktop » mais c'est un mobile ; apostrophes mélangées. |
| 8 | Quatre cartes séparées (un seul groupe à filets) ; « Français · Asia/Riyadh » en dur et identifiant de fuseau brut ; ligne « Sécurité » qui doublonne `.../securite` ; titre « Réglages » contre « Préférences » du mandat (à trancher, sans collision avec les réglages de l'élève) ; rubrique « Cours et données » supprimée. |
| 9 | « Appliqué sur cet appareil. » alors que le choix est perdu au rechargement sur le web ; « Taille du texte » avec chevron sans destination ; piste d'interrupteur désactivé à 1,77:1 ; légende rétrécie pour tenir sur une ligne ; marges de 8 dp au lieu de 16 dp. |
| 10 | Titre « Quel type de compte souhaitez-vous créer ? » (dire « Pour qui souhaitez-vous utiliser Rewayah ? ») ; « Moi et les membres de ma famille » (dire « Moi et ma famille ») ; descriptions à remplacer par celles du directeur ; promesse « les paiements » ; option présélectionnée ; « 2 sur 5 » en dur ; pas de lien enseignant ; artefact « per sonne ». |
| 11 | « Homme » présélectionné ; « Sélectionnez une option. » à la place de la raison de la question ; « 3 sur 5 » et barre à 54 % pour 3/5 ; pictogramme féminin à faire arbitrer par le directeur. |
| 12 | « Pour qui créez-vous ce compte ? » ; descriptions différentes du texte imposé ; promesse « les paiements de la famille » ; aucune entrée enseignant ; option présélectionnée ; « 1 sur 6 » figé. |
| 13 | Pas de sous-titre expliquant la question ; pictogrammes genrés stéréotypés ; présélection ; étape « prénom, nom » absente mais obligatoire. |
| 14 | Âge exact libre « 28 ans » (CONFLIT avec les tranches serveur) ; aide « Pour adapter votre parcours. » plus vague que la raison réelle ; question au « vous » au lieu du prénom de l'élève. |
| 15 | Langue de l'application demandée dans l'admission (elle remplace à tort la langue du cours) ; English et العربية proposés alors qu'ils ne sont pas traduits ; icône « personne » pour une langue. |
| 16 | Options différentes du code (« Je ne sais pas encore » supprimée, « Apprendre les bases de l'islam » ajoutée sans parcours réel) ; question de niveau absente ; pastille sélectionnée d'une autre teinte que #12 et #15. |
| 17 | « Vos préférences sont prêtes. » (faux succès) ; un seul lien « Modifier mes réponses » au lieu d'une correction par ligne ; état du dossier et prochaine action réelle absents ; « 6 sur 6 » figé. |
| 18 | « Temps restant » ambigu (séance ou visite) ; « Avant / Après la séance » ; Bibliothèque, Progression et Historique absents de la liste ; « Niveau 1 » qui ressemble à un code interne ; CTA de 40 dp. |
| 19 | Coquille « quii » ; « 2 visites de 2 minutes » en dur ; texte du mandat incomplet (et règle « visite écourtée consommée » absente) ; « son enseignant » sans Sayyid / Sayyida. |
| 20 | Pastilles d'en-tête au lieu du bandeau pleine largeur décidé (§4.3) ; « 01:42 » ambigu ; kasra manquante sous ب ; chevron retour qui ne passe pas par « Quitter » ; barre de commandes verticale propre à cet écran. |
| 21 | Même en-tête que #20 ; barre de commandes horizontale différente de #20 et #24 ; même erreur d'arabe. |
| 22 | « une visite de 2 minutes » en dur ; seule la variante « première visite terminée » existe (les autres fins sont au §4.2). |
| 23 | Texte différent de celui exigé par MANDAT-OBS §6 ; seulement « pour mon enfant » (variantes responsable légal et élève adulte absentes) ; case et CTA de moins de 48 dp ; CTA désactivé trop peu contrasté. |
| 24 | ث remplacée par ت dans le support ; avatar générique à la place du portrait de l'enfant ; effet « elle parle » sans signal réel ; icône « Quitter » en combiné téléphonique (une seule icône partout) ; pas de bandeau pleine largeur. |
| 25 | « Ajouter enfant » ; « Session 18:00 » ; « Dernière séance 1 h » ; « Terminées » contre « Terminée » ; fuseau absent de la liste ; barre de navigation gris neutre `#4B4B4B` hors palette. |
| 26 | Barre latérale admin inventée (réutiliser la navigation admin existante) ; filtre « Statut » sans colonne correspondante ; filtres tuteur et élève seulement par la recherche ; ligne du 18/09 absente (jeu de démonstration incohérent avec #25). |
| 27 | Horaire « 18:35 – 18:36:42 » au format incohérent ; « Heure de Paris » ici contre « Europe/Paris » en #26 ; lien retour de 29 dp ; deux motifs de fin seulement ; libellé du CTA en violet au lieu de l'encre foncée. |
| 28 | Styles du logigramme (crème, brun, Segoe UI, pointillés) à ne jamais transformer en jetons ; « Deux minutes écoulées » en dur ; décision « disponible ? » binaire sans « présence en vérification » ; reconnexion qui revient au direct ; accès direct à la salle sans vérification. |
| 29 | Ancienne capture : barre à 3 onglets grise ; mêmes erreurs que #4 ; libellés d'onglets sous AA. |
| 30 | Ancienne capture : « Ajouter un enfant », « Enfants », « Gérer tous les enfants » ; compteurs décoratifs « 3 enfants / 1 appareil / 2 alertes » ; « 1/2 appareils » ; « Diagnostic à terminer » ; « Configure un appareil » ; « iPhone de Mariam » comme appareil familial ; « Disponibilités du foyer » ; rubans colorés ; « Créer mon profil élève » absent. |
| 31 | Ancienne capture : pas de bascule Séances / Observations ; dates et année 2024 fausses ; « Sayda », « Ustadh » ; trois classes et trois enseignants pour une élève ; réseau au premier plan ; « Absente » avec « Réseau Bon ». |
| 32 | Ancienne capture : « Observer la session » proposé avant le début et sans quota ; photo de l'enseignant absente ; décalage fixe Paris / Abidjan ; « 13 : 45 » avec espaces ; ressources, progression, historique et exceptions absents. |
| 33 | Ancienne capture : onglet actif « Compte » (c'est la fiche élève : Foyer) ; « Accés » ; « Paramètres de l'enfant » (dire « Réglages de {prénom} ») ; « Indisponible pendant la séance » sans politique établie ; « Appareil actuel » non confirmé ; Informations et Parcours absents. |

---

## 7. Synthèse : nouvelles images à produire pour le rôle Tuteur

PROPOSITION de volume et d'ordre (mon estimation, à valider par le directeur) : pour chaque écran du §2, une maquette mobile 390 × 844 clair et une ordinateur 1440 × 900 clair ; le sombre est dérivé par les règles de MANIFESTE §6.2, sauf pour les écrans où le sombre change la lecture (salle d'observation, émetteur QR).

| Ordre | Groupe | Écrans | Pourquoi d'abord |
|---|---|---|---|
| 1 | Foyer et fiche élève | SM-17 à SM-27 | Aucune maquette high-fi, seulement d'anciennes captures |
| 2 | Appareils | SM-28 à SM-32 | Aucune maquette ; parcours sur deux appareils |
| 3 | Planche 3 et salle redessinée | §4.2, §4.3 | Planche manquante ; décision du directeur contraire aux maquettes |
| 4 | Admission sans image | SM-01 à SM-10 | Écrans publics, premier contact |
| 5 | Classe (sous-pages, catalogue), Historique (détail de séance), Compte (sous-pages), Notifications | SM-11 à SM-16, SM-33 à SM-44 | Dérivations simples de maquettes proches |
| 5 bis | [critique] Publication : suppression, retrait d'un profil, messages de l'académie, amorce des notifications | SM-49 à SM-52 (§2.7 bis) | Exigés par les stores ou déjà portés par le serveur |
| 6 | Variantes de thème et de format | §3 | Règles de dérivation déjà écrites |
| 7 | Fonctions à venir | §5 | Visuels annoncés « plus tard » par le directeur |

Points encore ouverts à signaler à ChatGPT comme CONFLIT, sans les trancher : âge exact ou tranches (§2.1) ; classe réelle ou offre horaire à l'étape 7 (§2.1) ; titre « Abonnement et accès » (SM-36) ; « Réglages » ou « Préférences » (#8) ; pictogramme féminin (#11) ; barre de progression continue ou segmentée et carte « Autre » de l'admission (MANIFESTE §6.4-8) ; registre de langue des écrans de l'appareil élève (§2.4).


---


# E. Inventaire des écrans des autres rôles

# Inventaire des écrans et des parcours, rôle par rôle (hors tuteur)

Date : 24/09/2026. Rédigé par Claude Code, en lecture seule, pour le dossier remis à ChatGPT.
Référence mesurée : dépôt `D:\RA_TUTEUR\integration`, branche `ui/tuteur-v1`, commit `cefab7f` (branche du chantier Tuteur V1, **non fusionnée** dans `main`). Aucun fichier du dépôt n'a été modifié.
Portée : tous les rôles **sauf le tuteur** (couvert par le chantier Tuteur V1). Un écran partagé avec le tuteur est cité quand il concerne un autre rôle.

---

## Comment lire ce document

- **Tu n'as pas accès au code.** Chaque fait porte sa preuve : `fichier:ligne` du dépôt, ou nom du document. Ces preuves servent aux agents qui coderont ; tu peux les citer, tu n'as pas à les vérifier. Ce qui n'est pas prouvé est écrit **« à vérifier »**.
- Une **route** est l'adresse interne d'un écran (exemple : `/eleve/coran`). Elle ne s'affiche jamais à l'utilisateur.
- Dans le code, une classe s'appelle souvent **« groupe »** (`groupe`, `/tc/groupes`, `ADM-09 Groupes`). À l'écran, le mot imposé est **« Classe »**. Ce document garde les noms du code entre accents graves et dit « classe » partout ailleurs.
- Les **codes d'écran** existants (`ELV-xx`, `ENS-xx`, `ADM-xx`, `CTR-xx`, `AGT-00`, `CPT-01`) viennent du catalogue d'écrans archivé. Réutilise-les. Un écran sans code est marqué « sans code » : propose-lui un identifiant.
- Trois lots du **chantier Tuteur en cours** construisent aussi des écrans partagés : **lot A** (bienvenue, connexion, récupération, inscription par étapes, dossier `/attente`), **lot D** (scanner et saisie du code sur l'appareil de l'élève), **lot E** (historique des observations côté administration). Ne les réécris pas : signale seulement leurs manques pour les autres rôles (`LOTS` §A, §D, §E).

### Légende des états du code

| État | Définition appliquée |
|---|---|
| **Atteignable** | Route déclarée, **et** au moins un bouton, lien, onglet ou la racine du rôle y mène dans le code (hors routeur, hors tests), **et** la garde d'accès laisse passer ce rôle. Ne veut **pas** dire « fonctionne » : la colonne dit ce qu'on voit. |
| **Atteignable (STUB)** | Atteignable, mais l'écran est un espace réservé provisoire qui affiche « indisponible » (commentaire `STUB PHASE 0` dans le fichier). |
| **Route sans bouton** | Route déclarée, mais aucun bouton ne mène le rôle visé : seule une adresse tapée (web) y mène, ou la garde refuse le seul rôle qui a le bouton. |
| **Code non branché** | Code présent mais monté par aucun écran atteignable (graphe d'imports), ou jamais instancié. |
| **Absent** | Ni route ni écran. |

### Abréviations des sources

| Code | Document |
|---|---|
| `00`, `01`, `02`, `03`, `06`, `07`, `08D` | `D:\RA _APP\RA -OFFICIAL-APP\docs\current\` : `00_LIRE_D_ABORD`, `01_PRODUIT_ET_PARCOURS`, `02_ARCHITECTURE_ET_SECURITE`, `03_DESIGN_SYSTEM_ET_UX`, `06_SPEC_FONCTIONNELLE_MVP`, `07_MEMOIRE_PEDAGOGIE_FINANCE`, `08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23` |
| `CAT` | `docs\archive\2026-09-pre-remise-a-plat\design\08-catalogue-ecrans.md` (registre §1, fiches §6 et §7) |
| `AI` | `docs\archive\2026-09-pre-remise-a-plat\design\03-architecture-information.md` |
| `PU` | `docs\archive\2026-09-pre-remise-a-plat\produit\parcours-utilisateurs.md` |
| `DEC` | `D:\RA _APP\pilotage-tuteur-v1\03_DECISIONS_COORDINATEUR.md` (réponses du directeur du 24/09) |
| `BKL` | `D:\RA _APP\pilotage-tuteur-v1\08_BACKLOG_VAGUE_CLASSE_VISIO.md` |
| `DEP` | `D:\RA _APP\pilotage-tuteur-v1\02_code\00_DEPENDANCES_BACKEND.md` (identifiants `DB-xxx`) |
| `MAP` | `D:\RA _APP\pilotage-tuteur-v1\02_code\00_MAPPING_ROUTES.md` |
| `MAN` | `D:\RA _APP\pilotage-tuteur-v1\01_visuel\00_MANIFESTE.md` (numéros `#n` des maquettes) |
| `LOTS` | `D:\RA _APP\pilotage-tuteur-v1\05_LOTS_PHASE1.md` |
| `R4` | `D:\RA _APP\pilotage-tuteur-v1\06_registre\R4_annonce_vs_atteignable.md` (mesuré sur `main` @ `4a7aa2b`, revérifié ici sur `cefab7f`) |

### Méthode et limites

- Routes lues dans `lib/core/router/routes.dart`, `app_router.dart`, `redirection.dart` et les cinq fichiers `routes_tc_{a,b,c,e,g}.dart`. Destinations lues dans `lib/core/widgets/nav_shell.dart` et `lib/core/admin/admin_domaine.dart`.
- Entrées de navigation : recherche de `Routes.`, `CheminsTcA.`, `RoutesTcB.`, `RoutesTcE.`, `RoutesTcG.`, `RoutesCoran.` dans `lib/` hors routeur ; aucune navigation par adresse littérale (`.go('/...')`) n'existe.
- Graphe d'imports rejoué sur `cefab7f` avec `06_registre\outils\graphe_imports.ps1` (sortie hors dépôt) : 422 fichiers Dart dans `lib/`, **356 atteignables** depuis `lib/main.dart`, **66 non atteignables**.
- Lecture statique seulement : aucune application lancée, aucune base interrogée, aucune capture neuve. « Atteignable » ne dit rien de ce que le serveur accepte.

---

## 0. L'essentiel en 15 constats

1. **Six rôles techniques seulement** : `admin`, `accountant`, `controller`, `teacher`, `guardian`, `student` (`lib/core/domain/enums.dart:9-26`). « Élève adulte », « contrôleur invité » et « agent IA » ne sont pas des rôles de l'application (l'agent utilise un rôle de base `agent_ro`).
2. **Élève adulte : parcours absent de bout en bout.** Choisir « Élève adulte » à l'inscription crée un compte **tuteur** sans profil élève (`lib/features/inscription/inscription_page.dart:38-41`). L'adulte ne peut ni étudier, ni choisir une classe, ni rejoindre une séance (`DEP` DB-FOY-01).
3. **Élève en Interface guidée : aucune navigation, aucune déconnexion, et le lecteur du Coran n'a aucun retour visible** (0 destination, `nav_shell.dart:67-68, 312-314` ; aucun retour dans `lib/features/tc_mushaf/mushaf_page.dart` ni `lib/core/widgets/page_immersive.dart`). Impasse probable, **à vérifier sur appareil**.
4. **Pour l'élève, la classe n'existe pas à l'écran** : Espace Classe, bibliothèque, seconde salle et travail à préparer n'ont aucune entrée pour lui. Il ne voit que : accueil, Coran, suivi, compte, salle.
5. **Trois fenêtres d'entrée en séance différentes** : élève à l'heure exacte du début (`accueil_eleve_page.dart:103-107`), enseignant 10 minutes avant (`journee_page.dart:16-31`), serveur 20 minutes avant (`join_window_minutes = 20`, `DEP` §0 ligne 24) ; la spec demande environ T-20 configurable (`01` Espace Groupe).
6. **Enseignant** : ses écrans quotidiens sont atteignables, mais « Premiers pas » (`ENS-01`) n'a aucun bouton, « Journée » et « Créneaux » reposent encore sur l'ancien modèle « prendre un élève » que `00:26` a remplacé par le choix d'une classe stable, et il n'a ni Coran hors salle, ni bibliothèque, ni envoi de sa photo publique.
7. **Salle** : `/salle` est la salle vivante (élève, enseignant, contrôleur) ; `/tc/classe`, seconde salle plus riche, n'a aucune entrée. Décision du directeur : **une salle unique** (`BKL`). La page du Coran présentée par l'enseignant n'est reçue par **aucun** écran élève. Outils de classe, synchronisation en direct et reprise après coupure : code non branché. Le jeton vidéo serait refusé à tous les rôles par la migration `0042` (**à vérifier**, `DEP` DB-OBS-01).
8. **Administration** : 16 écrans atteignables (`ADM-01`, `ADM-02`, `ADM-04` à `ADM-17`), plus une feuille de réglage d'observation, répartis sur 8 domaines. Mais la création d'une classe demande l'**identifiant brut** de l'enseignant, n'accepte **qu'un jour et une heure**, fige le fuseau à `Europe/Paris`, sans durée ni date de début (`lib/features/admin_groupes/groupes_page.dart:415-421, 452`) ; les comptes sont en lecture seule ; aucun paiement manuel, aucune exception de planning, aucune observation de séance.
9. **Validation des dossiers (`ADM-02`)** : l'écran existe, avec « Valider le dossier » et « Refuser ». Il se bloque si le **genre de l'administrateur** n'est pas renseigné (« Renseignez votre genre dans votre profil avant de consulter un dossier. », `dossiers_page.dart:444`), et **aucun écran** ne permet de le renseigner (profil en lecture seule). Cause possible du « rôle enseignant inaccessible » rapporté par le directeur (`BKL` ligne 37) : **à vérifier en base**.
10. **Contrôleur** : planning et observation invisible atteignables ; compte rendu, grille d'audit (`CTR-03`) et signalement **absents**.
11. **Contrôleur invité** : rôle **inexistant** et **jamais spécifié** (seulement nommé dans `AI` §2 et `DEC` §1 ter-8).
12. **Finance et comptable** : `/comptable` affiche seulement « Mon compte » ; le domaine Finance de l'administration est inerte ; aucune table de paiement des familles (`DEP` DB-CPT-03).
13. **Publication impossible en l'état** : aucune suppression de compte, aucun document légal, aucune notification (ni push, ni e-mail applicatif), pas de lien profond mobile pour le lien de connexion, permission micro non déclarée (manifeste Android principal, `Info.plist` iOS), nom Android « rewayah_academy », traduction arabe quasi vide (32 lignes contre 2 366). [critique] S'y ajoutent : aucune acceptation des conditions à l'inscription, aucun modèle d'e-mail transactionnel ni SMTP de production dans le dépôt, aucun traitement administratif des demandes de suppression ou d'export (section 14).
14. **Coran** : lecteur atteignable, défauts connus (ordre des versets inversé, voyelles absentes, mise en page non conforme au Mushaf de Médine, commandes manquantes) **consignés et non corrigés** par décision (`08D` §5 bis, 24/09).
15. **Maquettes hors tuteur** : seules existent les planches d'inscription (`MAN` #10 à #17), le consentement (`MAN` #23) et l'historique des observations côté administration (`MAN` #26). **Tout le reste : aucune maquette.**

---

## 1. Cadre commun à tous les rôles

### 1.1 Portes d'accès (ce que la garde décide avant tout écran)

| Porte (état de session) | Ce que voit la personne | Preuve |
|---|---|---|
| Chargement | Écran de démarrage neutre (`/`) | `redirection.dart:57-58` ; `etats_routeur.dart:125-137` |
| Hors ligne (profil illisible) | Page « hors ligne » seule | `redirection.dart:62-63` |
| Déconnecté | Seuls `/connexion` (et ses sous-pages), `/bienvenue`, `/agent` sont ouverts ; tout autre chemin renvoie à `/connexion?retour=...` | `routes.dart:528-532` ; `redirection.dart:71-91` |
| Inscription (compte sans profil) | Seul `/inscription` et ses sous-pages | `redirection.dart:97-100` |
| Attente ou suspendu | Seul `/attente` et ses sous-pages | `redirection.dart:106-110` |
| Actif | Racine du rôle ; `/compte` ouvert à tous ; `/tc/...` selon une table par sous-arbre ; une route d'un autre rôle renvoie à la racine (le tuteur seul voit « Accès refusé ») | `redirection.dart:112-195, 287-304` |

Racines par rôle : élève `/eleve`, tuteur `/tuteur`, enseignant `/enseignant/journee`, contrôleur `/controleur`, admin `/admin`, comptable `/comptable` (`routes.dart:535-542`).

### 1.2 Destinations de navigation par rôle (code actuel)

| Rôle | Destinations, dans l'ordre | Forme | Preuve |
|---|---|---|---|
| Élève, mode standard | Accueil · Coran · Suivi · Compte (4) | Barre basse < 600 ; rail à libellés 600-1199 ; barre latérale ≥ 1200 | `nav_shell.dart:66-90`. Écart : `AI` §5 et `PU` en prévoyaient 3 (sans Compte). |
| Élève, Interface guidée | Aucune (0) | Aucun chrome : l'écran occupe tout | `nav_shell.dart:67-68, 312-314` |
| Enseignant | Journée · Créneaux · Profil (3) | Idem, rail à libellés | `nav_shell.dart:128-144` |
| Contrôleur | Aucune (écran unique) | Pas de barre | `nav_shell.dart:155-157` ; `app_router.dart:737-741` |
| Comptable | Aucune | Pas de barre | `nav_shell.dart:155-157` |
| Administration | 8 domaines : Accueil · Opérations · Personnes · Pédagogie · Finance (inerte) · Configuration · Sécurité et audit · Direction (masqué) | Coquille propre `AdminShell` (barre latérale, tiroir sur mobile), barre supérieure : « Rechercher un écran », cloche, compte | `admin_domaine.dart:92-100, 118-128` ; `lib/core/widgets/admin_shell.dart` ; `session_state.dart:140` (`peutVoirDirection => false`) |

Règles déjà gelées par le directeur et valables pour tous les rôles (`DEC` §1 ter) : disposition des maquettes qui fait autorité, **une fonction à un seul endroit**, carte groupée = un seul rectangle à filets, navigation, retour et déconnexion toujours accessibles, web = vraie version ordinateur (captures 1440 obligatoires), système de design gelé (DM Sans pour les titres, Plus Jakarta Sans pour le reste), composants réutilisables pour tous les rôles, mode démonstration par rôle hors production.

### 1.3 Pages d'état transverses (déjà codées)

| Page | Route | État | Preuve |
|---|---|---|---|
| Démarrage | `/` | Atteignable | `app_router.dart:157-160` ; `etats_routeur.dart:125-137` |
| Page introuvable | toute adresse inconnue | Atteignable | `app_router.dart:154` ; `etats_routeur.dart:36-55` |
| Accès refusé | `/acces-refuse` | Atteignable **pour le tuteur seul** ; les autres rôles sont renvoyés en silence à leur racine | `redirection.dart:194` |
| Hors ligne du démarrage | `/hors-ligne` | Atteignable | `etats_routeur.dart:73-123` |

### 1.4 « Mon compte » commun (hors tuteur)

`/compte` (écran `ComptePage`) est partagé par l'élève, l'enseignant, le contrôleur, le comptable et l'administration. Le tuteur a son propre compte (`/tuteur/compte`).

| Écran | Route | Contenu actuel | État | Preuve |
|---|---|---|---|---|
| Mon compte | `/compte` | Carte d'identité (rôle), Profil, Réglages, « Confidentialité » (désactivé, « Bientôt disponible »), liste « Espaces », « Se déconnecter » | Atteignable (élève standard, enseignant via Profil, contrôleur, admin, comptable) | `compte_page.dart:30-117` |
| Profil | `/compte/profil` | Identifiant, contact « Non disponible », langue, fuseau « Non disponible », statut. **Lecture seule** | Atteignable depuis `/compte` | `compte_page.dart:59, 121-190` |
| Réglages | `/compte/reglages` | Thème (Système, Clair, Sombre), réduire animations et effets, langue (arabe « Bientôt disponible »), notifications (sans source), économie de données, grand texte du Coran. Préférences non conservées au redémarrage (`DEP` DB-CPT-09) | Atteignable depuis `/compte` | `compte_page.dart:65, 194-370` |
| Profils du foyer | `/compte/profils`, `/compte/profils/:id` | Réservé au tuteur, qui est redirigé vers son Foyer | Route sans bouton pour les autres rôles | `compte_page.dart:71, 648` ; `redirection.dart:246-254` |

---

## 2. Parcours publics et entrée dans l'application

**Destinations** : aucune (pas de coquille). Le visiteur sans session arrive sur `/connexion`, pas sur `/bienvenue` (`app_router.dart:196-199`).

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| Bienvenue (sans code) | `/bienvenue` | Accueil public avant connexion | **Route sans bouton + STUB** (`lib/features/bienvenue/bienvenue_page.dart:6-21`) ; lot A | `LOTS` A.1 ; `MAN` §2 | Aucune (dérivation prévue : `MAN` §2) |
| `TUT-00` Connexion | `/connexion` | Recevoir un lien par courriel, ou « Continuer avec Google » ; aucun mot de passe | **Atteignable** (destination par défaut sans session). Refonte en cours, lot A | `CAT` §6 `TUT-00` ; `06` Identité | Aucune (captures de l'existant : `02_code\capture_proto\out\01` à `04_connexion_*.png`) |
| Récupération d'accès (sans code) | `/connexion/recuperation` | Recevoir un nouveau lien | **Route sans bouton + STUB** : aucun lien depuis `/connexion` (`recuperation_page.dart:6-21`) ; lot A | `06` « récupération de compte » ; `LOTS` A.1 | Aucune |
| `ELV-01` Connexion de l'élève | `/connexion/eleve` | Code d'appairage à 6 caractères, choix du profil, code personnel à 4 chiffres | **Atteignable** par « Connecter l'appareil d'un élève » (`connexion_page.dart:168`) ; bloc « Scanner » non affiché (`eleve_connexion_page.dart:331`) | `CAT` §6 `ELV-01` ; `PU` §2 | Aucune |
| Scanner le QR (sans code) | `/connexion/eleve/scanner` | Lire le QR affiché chez le tuteur | **Route sans bouton + STUB** ; lot D | `LOTS` D.2 | Aucune |
| Saisir le code (sans code) | `/connexion/eleve/code` | Saisie manuelle du code | **Route sans bouton + STUB** ; lot D | `LOTS` D.2 | Aucune |
| `TUT-00c` Création de profil | `/inscription` | 4 pages : rôle (« Tuteur », « Élève adulte », « Enseignant »), prénom et nom, genre, récapitulatif | **Atteignable** par la porte « inscription » (`inscription_page.dart:25-173`) | `CAT` §6 `TUT-00c` | Planches d'inscription `MAN` #10 à #17 (cible du lot A) |
| Inscription par étapes (sans code) | `/inscription/usage`, `/identite`, `/genre`, `/recapitulatif` | Nouveau parcours : « Moi uniquement » ou « Moi et ma famille », lien discret « Je suis enseignant » | **Route sans bouton + STUB** (`inscription/etapes/*.dart`) ; lot A | `LOTS` A.2 ; `DEC` §3-8 | `MAN` #10 à #17 |
| `TUT-00b` Portail d'attente | `/attente` | État du dossier : incomplet (liste de pièces, un bouton chacune), en vérification, refusé (motif, « Corriger »), suspendu | **Atteignable** par la porte « attente » (`attente_page.dart:22-100`) ; partagé tuteur et enseignant ; refonte lot A | `CAT` §6 `TUT-00b` | Aucune |
| `TUT-00c/a` Accusé enregistrement et contrôle | `/attente/accuse` | Lire et accuser la carte « enregistrement audio et visite de contrôle » | **Atteignable** depuis `/attente` (`attente_page.dart:138-140`) | `CAT` §6 | Aucune |
| `TUT-00c/b` Contrat | `/attente/contrat` | Lire et signer le contrat **propre au rôle** | **Atteignable** (`attente_page.dart:143-145`) ; version famille avec paragraphe d'observation en cours (lot A) ; variante enseignant non redessinée | `CAT` §6 ; `DEC` §1 bis-3 | Consentement `MAN` #23 (famille seulement) |
| `TUT-00c/c` Dépôt de la pièce | `/attente/piece` | Déposer la pièce d'identité | **Atteignable** (`attente_page.dart:148-150, 201`) | `CAT` §6 | Aucune |
| `AGT-00` Entrée d'un agent | `/agent` | Voir section 10 | Atteignable avec un lien | `CAT` §6 | Aucune |
| Site public, landing web (sans code) | Aucune dans ce dépôt | Présenter l'académie, convaincre, mener à l'inscription | **Absent** : « le site public et l'application sont deux produits », `rewayahacademy.com` (`AI` §1). `web/index.html` n'est que l'hôte de l'application Flutter (titre « Rewayah Academy », description « Cours de Coran en visio, avec un enseignant attitre pour chaque eleve. ») | `AI` §1 | Aucune |
| Mentions légales, confidentialité, conditions (publiques) | Aucune | Pages lisibles sans compte | **Absent** : aucun document légal dans le dépôt (`DEP` DB-CPT-08) | Stores (section 14) | Aucune |

---

## 3. Élève adulte (et élève en mode standard)

**Destinations actuelles** :
- un adulte qui s'inscrit comme « Élève adulte » reçoit le rôle **tuteur** : Accueil · Foyer · Historique · Compte (`inscription_page.dart:38-41` ; `nav_shell.dart:98-120`), **sans aucun espace élève** ;
- un profil élève en mode standard (9 ans et plus, adulte compris selon `PU` §2) : Accueil · Coran · Suivi · Compte (`nav_shell.dart:66-90`). Un adulte ne peut pas l'atteindre aujourd'hui : tout profil élève créé est de type « mineur » (`DEP` DB-FOY-02) et le profil élève du titulaire n'existe pas (`DEP` DB-FOY-01).

Registre des textes actuels : l'accueil élève **tutoie** (« Ton cours a commencé », `eleve.accueil`), le suivi **vouvoie** (« Vos cours s'afficheront ici », `eleve.suivi`). Aucun texte n'est adapté à un adulte.

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| `ELV-02` Accueil élève | `/eleve` | Deux blocs : prochain cours (6 états : plus tard, imminent, en direct, aucun cours, annulé, hors ligne) et accès au Coran | **Atteignable** (racine, `routes.dart:536` ; barre). « Rejoindre » n'apparaît qu'une fois le cours commencé (`accueil_eleve_page.dart:103-107, 394-406`). Manquent la semaine à venir, les annonces, l'historique des cahiers promis au mode standard (`PU` §2 ligne 178) | `CAT` §6 `ELV-02` ; `01` Rôles ; `06` Accueil par rôle | Aucune (captures de l'existant : `04_phase0\captures_revue_a11y\apres_eleve_accueil_*.png`, `apres_eleve_direct_390_standard_clair.png`) |
| `ELV-04` Le Coran | `/eleve/coran` | Lecteur, voir section 13 | **Atteignable** (barre `nav_shell.dart:75-79` ; bloc de l'accueil `accueil_eleve_page.dart:564-566`) | `CAT` `ELV-04` | Aucune |
| Suivi de mes cours (sans code) | `/eleve/suivi` | Historique des séances : date, cours, enseignant, présence | **Atteignable** (barre). Aucune fiche au catalogue (`CAT` §2, lignes 178-186) ; présence seulement, pas de progression | `CAT` §1 ligne « Suivi élève » | Aucune |
| Mon compte, Profil, Réglages | `/compte`, `/compte/profil`, `/compte/reglages` | Voir §1.4 | **Atteignable** (barre) | `03` Structure | Aucune |
| `ELV-03` Salle, élève | `/salle` | Visio, voir section 11 | **Atteignable** par « Rejoindre » (`accueil_eleve_page.dart:394-404`) | `CAT` `ELV-03` | Aucune |
| Mes classes (sans code) | `/tc/groupes` | Liste des classes de l'élève | **Route sans bouton** : le seul appel (`accueil_famille_page.dart:469`) est côté tuteur | `01` Espace Groupe ; `06` Espace Groupe | Aucune |
| Espace Classe (sans code) | `/tc/groupes/:groupeId` | Page de classe : enseignant, prochaine séance, décompte, travail, bibliothèque | **Route sans bouton** (seule entrée : la liste ci-dessus, `mes_groupes_page.dart:183`) | `01` Espace Groupe | Aucune |
| Classe Live (sans code) | `/tc/classe` | Seconde salle, voir section 11 | **Route sans bouton** (seule entrée : « Rejoindre » de l'Espace Classe, `routes_tc_a.dart:63-83`) | `08D` §3 (salle unique) | Aucune |
| Bibliothèque (sans code) | `/tc/bibliotheque`, `/tc/bibliotheque/:resourceId` | Voir section 12 | **Route sans bouton** (seule entrée depuis l'Espace Classe, `espace_groupe_page.dart:262`) ; contenu toujours vide | `01` Classe et supports | Aucune |
| Avant le prochain cours (sans code) | Aucune | Au plus trois actions entre deux séances | **Code non branché** (`lib/features/tc_flux_academique/bloc_avant_prochain_cours.dart`, non atteignable) | `07` Maison ; `06` Après cours | Aucune |
| Avis de fin de séance (sans code) | Aucune | Micro-retour facultatif de l'élève | **Code non branché** (`tc_flux_academique/carte_feedback_seance.dart`) | `01` Classe (« retour élève sans formulaire obligatoire ») | Aucune |
| Signaler un problème (sans code) | Aucune | Signalement vers l'académie | **Code non branché** (`tc_flux_academique/feuille_signalement.dart`) | `06` Communications | Aucune |
| Ma progression (sans code) | Aucune | Cycle actuel, compétences « À renforcer », « Acquis », « Stable » | **Absent** : la progression n'est lisible que par l'administration (`DEP` DB-CRS-11) | `07` Compétences ; `06` Pédagogie minimale | Aucune |
| Créer mon profil élève (adulte titulaire) | `/tuteur/foyer/ajouter?pour=moi` | L'adulte crée son propre profil élève | **Route sans bouton**, écran d'indisponibilité (`app_router.dart:484-490` ; `creer_mon_profil_indisponible.dart`) ; capacité serveur absente (`DEP` DB-FOY-01) | `DEC` §3-8 ; `LOTS` B.1 | Aucune |
| Choisir une classe (adulte) | `/tuteur/classes/catalogue` | Voir les classes ouvertes, toutes leurs séances, s'inscrire | **Atteignable (STUB) côté tuteur** ; source serveur absente (`DEP` DB-CRS-07, DB-CRS-08) | `01` Admission ; `06` Choix familial | Aucune |
| Activer l'Interface guidée (adulte) | Aucune | Un adulte peut choisir l'Interface guidée | **Absent** : aucune bascule côté élève (`DEP` DB-FOY-04) | `00:28` ; `08D` §3 | Aucune |
| Mes appareils, mes réglages (adulte autonome) | Aucune côté élève | L'adulte gère ce qu'un tuteur gère pour lui-même | **Absent** côté élève (écrans tuteur seulement) | `PU` §2 ligne 182 | Aucune |

---

## 4. Élève enfant (Interface guidée)

**Destinations actuelles** : **aucune**. Le mode est porté par le profil (`InterfaceMode.enfant`, valeur stockée `child`, `enums.dart:85-90`) et ne change que l'affichage, jamais les routes (`routes.dart:5-9`). Les éléments grossissent (`AppMetriques.estEnfant`) et des haut-parleurs lisent les libellés (`AudioLabel`), **mais aucun fichier son n'existe** : `assets/audio/fr/` ne contient que `.gitkeep` (le texte reste affiché, `audio_label.dart:73-74`).

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| `ELV-01` Connexion de l'élève | `/connexion/eleve` | « J'ai un code », « Qui es-tu ? », « Choisis ton code secret », pavé numérique | **Atteignable** (voir section 2) | `CAT` `ELV-01` ; `PU` §2 | Aucune |
| Scanner, saisie du code | `/connexion/eleve/scanner`, `/code` | Voir section 2 | **Route sans bouton + STUB** (lot D) | `LOTS` D.2 | Aucune |
| `ELV-02` Accueil guidé | `/eleve` | Deux blocs seulement : prochain cours (décompte, « Avec {prénom} », pause prière en pictogramme) et « Le Coran » | **Atteignable** (racine) | `CAT` `ELV-02` ; `PU` §2 | Aucune (captures de l'existant : `captures_revue_a11y\apres_eleve_direct_390_guidee_clair.png`, `_sombre.png`) |
| `ELV-04` Coran guidé | `/eleve/coran` | Lecture libre ; sélecteur de sourates en gros, sans recherche (`PU` §2) | **Atteignable** par le bloc « Le Coran ». **Aucun retour visible** (0 destination, aucun bouton retour dans le lecteur) : impasse probable, **à vérifier** | `PU` §2 `ELV-04` | Aucune |
| `ELV-03` Salle guidée | `/salle` | Micro et sortie ; caméra seulement si la politique du profil l'autorise ; témoin « ton parent regarde » | **Atteignable** par « Rejoindre » à l'heure du début. Témoin enfant affiché (`salle_page.dart:508-511`). Textes de salle au **vouvoiement** (« Votre professeur n'est pas encore arrivé », `salle.*`) | `CAT` `ELV-03` ; `PU` §2 | Aucune |
| Retour après le cours (sans code) | vers `/eleve` | Retour automatique à l'accueil, animation d'encouragement de moins d'une seconde | Retour à la racine **codé** (`salle_page.dart:236-240`) ; animation d'encouragement **absente** (aucune occurrence) | `PU` §2 `ELV-03` | Aucune |
| Suivi | `/eleve/suivi` | Historique | **Route sans bouton** en Interface guidée (0 destination), conforme à la règle « l'enfant n'a aucune destination » | `AI` §5 | Aucune |
| Mon compte, déconnexion | `/compte` | Se déconnecter | **Route sans bouton** en Interface guidée : **aucune déconnexion possible** sur l'appareil de l'enfant. Contredit la règle du directeur « déconnexion accessible sur tous les formats » (`DEC` §1 ter-4) : **à trancher** | `DEC` §1 ter-4 | Aucune |
| Demande d'affichage standard (sans code) | Aucune | À partir de 10 ans, l'enfant demande l'affichage standard, le tuteur décide | **Absent** (`DEP` DB-FOY-04) | `DEC` P7 (décisions Classes V2) | Aucune |
| Mes classes, Espace Classe, Bibliothèque, Travail | Voir section 3 | | Mêmes états qu'en section 3 (sans entrée) | | Aucune |

---

## 5. Enseignant

**Destinations actuelles** : Journée · Créneaux · Profil (`nav_shell.dart:128-144`). Les écrans de séance et de classe sont des « poses » hors barre (`app_router.dart:702-732`). La déconnexion vit dans Profil (`profil_enseignant_page.dart:78, 616-641`).

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| Inscription, contrat, pièce | `/inscription`, `/attente/*` | Voir section 2 | Atteignable par les portes | `PU` §3 ; `CAT` §7 `ENS-01` | Aucune |
| `ENS-01` Premiers pas | `/enseignant/bienvenue` | Après validation : trois étapes, deux rappels (enregistrement, visite), « Déclarer mes disponibilités » ou « Aller à ma journée » | **Route sans bouton** : aucun appelant ; la racine du rôle est la Journée (`routes.dart:538`) ; texte fondé sur l'ancien modèle (« L'académie vous confie des élèves sur ces heures », `fr.i18n.json:1519`) | `CAT` §7 `ENS-01` ; `R4` n° 22 | Aucune |
| `ENS-02` Votre journée | `/enseignant/journee` | Prochain cours, colonne de la journée (cours, pauses, prières), rapports en attente, absences détectées, « Élèves en attente » | **Atteignable** (racine, barre). Blocs hérités du modèle remplacé : « Prenez un élève en attente : c'est ce qui remplit votre journée. » (`fr.i18n.json:1544`), « Cours individuel » (`:1556`) | `CAT` §6 `ENS-02` ; `00:26` | Aucune (captures de l'existant : `captures_revue_a11y\apres_enseignant_journee_*.png`) |
| `ENS-06` Créneaux | `/enseignant/creneaux` | Grille de disponibilités ; liste d'élèves en attente avec « Prendre {jour} à {heure} h » ; demande de hausse du plafond | **Atteignable** (barre ; `journee_page.dart:361, 372` ; `bienvenue_page.dart:224`). Modèle « matching » remplacé par le choix d'une classe (`00:26` ; `08D` §3) | `CAT` §6 `ENS-06` | Aucune (capture de l'existant : `apres_enseignant_creneaux_390_clair.png`) |
| `ENS-05` Profil | `/enseignant/profil` | Identité professionnelle, pays et langues modifiables, fuseau, plafond, statut du compte, contrats en lecture, « Mes réglages », déconnexion | **Atteignable** (barre). Aucun envoi de photo publique (seulement des initiales, `profil_enseignant_page.dart:180`) | `CAT` §7 `ENS-05` | Aucune |
| Profil personnel, Réglages | `/compte/profil`, `/compte/reglages` | Voir §1.4 | **Atteignable** depuis Profil (`profil_enseignant_page.dart:597, 603`) | | Aucune |
| `ENS-07` Fiche de la classe | `/enseignant/groupe/:groupeId` | Élèves (prénom et identifiant, jamais de coordonnées), rendez-vous, effectif | **Atteignable** depuis la Journée si la séance porte une classe (`journee_page.dart:491`) | `CAT` §7 `ENS-07` | Aucune |
| `ENS-08` Revue de la classe | `/enseignant/groupe/:groupeId/revue` | Anomalies produites par le système, sans décision | **Atteignable** depuis la fiche (`fiche_groupe_page.dart:156`) ; **toujours vide** : les données ne sont lisibles que par l'administration (en-tête de `revue_groupe_page.dart`) | `CAT` §7 `ENS-08` | Aucune |
| `ENS-03` Salle, enseignant | `/salle` | Visio, présence, présentation d'une page du Coran | **Atteignable** par « Lancer le cours » (`journee_page.dart:538-540`), de 10 min avant le début à la fin, après vérification du micro. Panneau de présentation **seulement si** le jeton porte le droit `can_publish_data` (`salle_page.dart:616-617`). Voir section 11 | `CAT` `ENS-03` | Aucune |
| `ENS-04` Cahier de transmission | `/enseignant/seance/:seanceId/cahier` | Prérempli ; l'enseignant ne corrige que les exceptions ; travail à la maison ; point de prononciation ; suspension du nouveau contenu ; file hors ligne | **Atteignable** : sortie obligatoire de la salle (`salle_page.dart:217-225`) et rappel de la Journée (`journee_page.dart:722`) | `CAT` §7 `ENS-04` | Aucune |
| Correction de présence (sans code) | Aucune | Corriger une présence avec motif | Panneau **atteignable** dans le cahier ; page propre `PresenceCorrectionPage` **jamais instanciée** (code non branché) | `R4` n° 30 ; `06` Présence | Aucune |
| Élèves de mes classes (roster) | `/tc/groupes/:id` | Liste pédagogique pendant et hors séance | **Refusé** à l'enseignant par la garde (`redirection.dart:288-291`) : renvoyé à la Journée | `R4` n° 25 ; `BKL` | Aucune |
| Coran hors salle | Aucune | Préparer un passage | **Absent** : `/eleve/coran` et `/tc/mushaf` réservés à l'élève | `CAT` `ELV-04` (« Élève, enseignant ») ; `R4` n° 23 | Aucune |
| Bibliothèque, choisir un support en classe | `/tc/bibliotheque` (refusé) | Choisir, afficher, masquer un support | **Refusé** par la garde ; sélecteur en classe **code non branché** (`tc_catalogue/class_library_picker.dart`) | `01` Classe et supports ; `06` Bibliothèque | Aucune |
| Outils de classe (sans code) | Aucune | Suivre, pointer, marquer, masquer, annoter, fixer le travail | **Code non branché** (`lib/features/tc_dock/*`, `lib/core/tc_outils/*`) | `06` Outils enseignant ; `03` Salle | Aucune |
| Après-cours et signalement (sans code) | Aucune | Préparer la suite, signaler à l'administration | **Code non branché** (`tc_flux_academique/panneau_post_cours.dart`, `lib/core/tc_parcours/*`) | `06` Après cours | Aucune |
| Envoyer ma photo publique (sans code) | Aucune | Photo visible des familles, distincte de la pièce d'identité | **Absent** (`DEP` DB-CRS-09 : la clé photo n'est jamais résolue) | `01` Espace Groupe ; `03` | Aucune |
| Déclarer une absence, demander un remplacement (sans code) | Aucune | Exception de planning tracée | **Absent** | `01` Admission et classes ; `06` Exceptions planning | Aucune |
| Voir mes deux fuseaux, notices de changement d'heure | Aucune | L'enseignant voit son heure et celle de la classe | **Absent** (aucune bibliothèque de fuseaux côté client, `DEP` DB-CRS-03) | `01` Espace Groupe | Aucune |
| Ma rémunération (sans code) | Aucune | Heures payables, paie | **Absent** (hors premier MVP, `07` Salaire ; `PU` §3 « pas de bloc solde ni de paie ») | `07` | Aucune |
| Notifications | Aucune | Rappels, changements, validation du dossier | **Absent** (`DEP` DB-CPT-04) | `06` Communications | Aucune |

---

## 6. Administration (tous les domaines)

**Destinations actuelles** : barre latérale à 8 domaines (Accueil, Opérations, Personnes, Pédagogie, Finance inerte, Configuration, Sécurité et audit ; Direction masqué), barre supérieure avec « Rechercher un écran » (navigation seulement, `admin_domaine.dart:138-146`), cloche qui ouvre une feuille vide (`admin_shell.dart:459-466` ; `DEP` DB-CPT-04 « faux état vide »), accès à « Mon compte ». Les fonctions secondaires d'Opérations, Personnes et Sécurité ne sont pas dans la barre : elles s'atteignent depuis l'Accueil (`app_router.dart:758-763`).

| Domaine | Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|---|
| Accueil | `ADM-01` Centre de commande | `/admin` | 6 compteurs (Dossiers à valider, Demandes à trancher, Foyers sans enseignant, Cahiers manquants, Incidents (24 h), Accès échus), « À traiter en premier », Outils (Comptes, Accès des agents IA) | **Atteignable** (racine). Deux compteurs **sans écran d'action** : Incidents et Accès échus (`tableau_de_bord_page.dart:284-291` ; texte « ils n'ont pas encore d'écran d'action ») | `CAT` §6 `ADM-01` ; `PU` §5 | Aucune |
| Opérations | `ADM-09` Groupes (classes) | `/admin/operations/groupes` (`/admin/operations` y redirige) | Créer une classe, ajouter ou retirer un élève, modifier le seuil, réglages d'observation, clôturer | **Atteignable** (barre). Création : nom, **identifiant brut de l'enseignant**, public (Enfants, Adultes), **un jour et une heure (0-23)**, seuil ; **fuseau figé `Europe/Paris`** ; ni durée, ni date de début, ni parcours, ni niveau, ni plusieurs jours (`groupes_page.dart:406-431, 445-495`). Ajout d'élève par **identifiant brut** (`:630`). Libellés « groupe » partout | `01` Admission et classes ; `06` Catalogue classes | Aucune |
| Opérations | Réglages d'observation d'une classe (feuille, sans code) | pas de route | Politique d'observation des tuteurs par classe | **Atteignable** (menu de la classe, `groupes_page.dart:78, 346-358`) ; message d'erreur qui cite « migration 0036 » à l'écran (`fr.i18n.json`, `admin.groupes.observationCapaciteAbsente`) | `01` Classe ; `DEC` §1 bis-4 | Aucune |
| Opérations | `ADM-05` Attribution manuelle | `/admin/operations/attributions` | Associer un élève sans enseignant à un enseignant | **Atteignable** depuis le compteur « Foyers sans enseignant » (`tableau_de_bord_page.dart:272`). « Écran de secours du matching inversé » : modèle remplacé (`00:26`) | `CAT` §6 `ADM-05` | Aucune |
| Opérations | `ADM-06` Demandes et règles | `/admin/operations/demandes` | Trancher une demande (changement d'enseignant, plafond, règle), règles individuelles d'un élève | **Atteignable** (`tableau_de_bord_page.dart:87, 267`) | `CAT` §6 `ADM-06` | Aucune |
| Personnes | `ADM-02` Dossiers à valider | `/admin/personnes/dossiers` (`/admin/personnes` y redirige) | Un dossier à la fois : pièce, trois vérifications, « Valider le dossier » ou « Refuser » avec motif | **Atteignable** (barre ; compteur `tableau_de_bord_page.dart:262`). Bloqué si le genre de l'administrateur manque (`dossiers_page.dart:444`) ; aucun écran pour le renseigner. Ne montre que les pièces **déposées** | `CAT` §6 `ADM-02` ; `PU` §5 ; `BKL` ligne 37 | Aucune |
| Personnes | `ADM-08` Comptes | `/admin/personnes/comptes` | Registre de toutes les personnes, ancienneté d'attente, pièce, contrats | **Atteignable** depuis Accueil > Outils (`tableau_de_bord_page.dart:225`). **Lecture seule** : ni activer, ni suspendre, ni changer de rôle, ni créer un compte du personnel | `CAT` §6 `ADM-08` ; `06` Identité (activation, suspension) | Aucune |
| Pédagogie | `ADM-10` Diagnostics | `/admin/pedagogie/diagnostics` (`/admin/pedagogie` y redirige) | Placer un élève sur un niveau d'un programme publié | **Atteignable** (barre, onglets `diagnostics_page.dart:94`) ; dépend d'un programme publié | `CAT` §6 `ADM-10` ; `07` Diagnostic | Aucune |
| Pédagogie | `ADM-11` Progression | `/admin/pedagogie/progression` | Niveau courant par classe et cycle, exceptions, blocages | **Atteignable** (onglets) | `CAT` §6 `ADM-11` | Aucune |
| Pédagogie | `ADM-12` Évaluations | `/admin/pedagogie/evaluations` | Évaluations et certifications | **Atteignable** (onglets) | `CAT` §6 `ADM-12` | Aucune |
| Pédagogie | `ADM-13` Programmes | `/admin/pedagogie/programmes` | Programme versionné (brouillon, publié immuable) | **Atteignable** (onglets) | `CAT` §6 `ADM-13` ; `07` | Aucune |
| Pédagogie | `ADM-14` Qualité | `/admin/pedagogie/qualite` | Anomalies calculées (cahiers manquants, blocages, évaluations en retard) | **Atteignable** (onglets ; compteur « Cahiers manquants » `tableau_de_bord_page.dart:282`) | `CAT` §6 `ADM-14` | Aucune |
| Finance | (domaine) | Aucune | Voir section 9 | **Absent** : libellé visible mais inerte (`admin_domaine.dart:99`) | `07` Finance | Aucune |
| Configuration | `ADM-15` Règles | `/admin/configuration/regles` (`/admin/configuration` y redirige) | Valeurs par défaut de la plateforme | **Atteignable** (barre, onglets `regles_page.dart:40-41`) | `CAT` §6 `ADM-15` | Aucune |
| Configuration | `ADM-16` Fonctionnalités | `/admin/configuration/fonctionnalites` | Interrupteurs de fonctions | **Atteignable** (onglets) | `CAT` §6 `ADM-16` | Aucune |
| Configuration | `ADM-17` Conservation des données | `/admin/configuration/conservation-donnees` | Durées de conservation (enregistrements, pièces d'identité) | **Atteignable** (onglets) | `CAT` §6 `ADM-17` | Aucune |
| Configuration | Académie, Classe en ligne, Notifications, Localisation (sans code) | Aucune | Réglages prévus par le contrat métier du 19/09 | **Absent** (`admin_domaine.dart:35-40` ; `ongletsConfiguration()` `:169-180`) | contrat `ADMIN_FINANCE_CONFIGURATION.md` (archive) | Aucune |
| Sécurité et audit | `ADM-04` Journal d'audit | `/admin/securite-audit/journal` (`/admin/securite-audit` y redirige) | Lecture seule, filtres, état de la chaîne d'empreintes | **Atteignable** (barre) | `CAT` §6 `ADM-04` | Aucune |
| Sécurité et audit | Historique des observations (sans code) | `/admin/securite-audit/observations` | Visites des tuteurs : qui, quelle séance, durée | **Route sans bouton + STUB** : `ongletsSecurite()` n'est appelé par aucun écran (recherche : seule sa définition `admin_domaine.dart:190`) ; écran en cours, lot E | `MAP` C4 ; `LOTS` E.3 | **Oui** : `MAN` #26 (D3, planche `tuteur observation desktop light.png`) |
| Sécurité et audit | `ADM-07` Accès des agents IA | `/admin/securite-audit/acces-agents` | Émettre un jeton de lecture borné dans le temps | **Atteignable** (`tableau_de_bord_page.dart:233`) ; système jugé « jamais fonctionnel » par le directeur (`BKL` ligne 39) | `CAT` §6 `ADM-07` | Aucune |
| Sécurité et audit | Sessions et appareils (`SEC-01`, `ADM-18` proposé) | Aucune | Sessions ouvertes, appareils | **Absent** (« prêt à construire », `HANDOFF.md:99-102` archive) | `ADMIN_SECURITE_DIRECTION.md:183` (archive) | Aucune |
| Sécurité et audit | Incidents sécurité (`SEC-02`, `ADM-19` proposé) | Aucune | Liste des incidents | **Absent** ; compteur « Incidents (24 h) » sans écran | idem `:186` | Aucune |
| Sécurité et audit | Exports et séquestre (`ADM-03`) | Aucune | Exports serveur autorisés | **Absent**, bloqué (contradiction de périmètre `ADM-03`/`CTR-03` non tranchée, `HANDOFF.md:2674-2683` archive) | `06` Contrôle et administration | Aucune |
| Direction | (domaine) | Aucune | Pilotage | **Absent**, masqué (`session_state.dart:140`) | `07` Pilotage | Aucune |
| Transverse | Observer une séance, visible ou incognito (sans code) | `/tc/observation/:seanceId` autorisée à l'admin ; `/salle` | Entrer dans une séance pour contrôle | **Absent** : aucun bouton côté administration (la garde l'autorise, `redirection.dart:298-301`) | `01` Classe (« Admin peut observer en mode visible ou incognito ») ; `06` Visiteurs | Aucune |
| Transverse | Paiements manuels et accès datés (sans code) | Aucune | Consigner un paiement hors application, dater l'accès, relancer | **Absent** (`DEP` DB-CPT-03) | `06` Paiement transitoire (M essentiel) ; `01` Académie et pilotage | Aucune |
| Transverse | Exceptions de planning (sans code) | Aucune | Annuler, reporter, remplacer, congés, jours fériés, changements d'heure | **Absent** (aucun écran d'action ; `DEP` DB-CRS-05) | `01` Admission et classes ; `06` Exceptions planning | Aucune |
| Transverse | Gestion de la bibliothèque (sans code) | Aucune | Importer, versionner, vérifier source et licence, publier | **Absent** | `01` Classe et supports ; `02` Ressources | Aucune |
| Transverse | Annonces et messages (sans code) | Aucune | Informer familles et enseignants | **Absent** | `06` Communications | Aucune |
| Transverse | [critique] Signalements des enseignants (sans code) | Aucune | Examiner un signalement, rédiger le résumé destiné à la famille, le transmettre au tuteur ou à l'élève adulte, clore | **Absent** côté administration, alors que le serveur porte le circuit complet : table `student_concern`, catégories (pédagogique, présence, technique, changement, autre), statuts `ouvert`, `en_examen`, `transmis`, `clos`, mise à jour réservée à l'admin (`supabase/migrations/0032_tc_catalogue.sql:567-619`) ; lecture famille par la vue `concern_famille_v` (`0033_tc_vues_rpc.sql:267-282`). Côté enseignant, la feuille existe mais écrit dans un double local (`lib/core/tc_parcours/port_signalement.dart:50`) | `06` Communications | Aucune |
| Transverse | [critique] Avis de fin de séance (sans code) | Aucune | Lire les retours des élèves après la séance | **Absent** : la table `session_feedback` n'est lisible que par l'admin (`0032_tc_catalogue.sql:560-561`) et aucun écran ne la lit | `01` Classe | Aucune |
| Transverse | [critique] Demandes de suppression de compte et d'export des données (sans code) | Aucune | Recevoir, exécuter ou refuser (conservation légale, `ADM-17`), tracer au journal | **Absent** (aucune occurrence dans `lib/` ni `supabase/`) ; indispensable dès que la suppression existe côté utilisateur (section 14) | Stores ; RGPD | Aucune |
| Transverse | Mon compte | `/compte` | Voir §1.4 | **Atteignable** (barre supérieure) | | Aucune |

---

## 7. Contrôleur

**Destinations actuelles** : aucune ; un seul écran, sans barre (`nav_shell.dart:145-157` ; `app_router.dart:734-741`). « Mon compte » par un bouton de l'écran (`planning_page.dart:168-172`).

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| `CTR-01` Planning du contrôle | `/controleur` | Toutes les séances en cours et à venir, heure locale et UTC, filtres (état, enseignant), rappel permanent « visite journalisée », « Observer » sur les seules séances en cours | **Atteignable** (racine) | `CAT` §6 `CTR-01` ; `PU` §4 | Aucune |
| `CTR-02` Observation invisible | `/salle` | Voir et entendre sans être vu, bandeau « Visite de contrôle. Vous n'êtes ni vu ni entendu, et votre passage est inscrit au journal. » | **Atteignable** par « Observer » (`planning_page.dart:133-138`) | `CAT` `CTR-02` ; `PU` §4 ; `01` Classe | Aucune |
| Porte d'observation `/tc/observation/:seanceId` | `/tc/observation/:seanceId` | Seconde porte (celle du tuteur) | **Route sans bouton** pour le contrôleur (autorisé par la garde, `redirection.dart:298-301`) | `08D` §3 | Aucune |
| `CTR-03` Grille d'audit, compte rendu (sans route) | Aucune | Noter et rendre compte d'une visite | **Absent**, reporté (`PU` §4 ; contradiction `ADM-03`/`CTR-03`) | `01` Rôles (« compte rendu ») ; `06` Contrôle | Aucune |
| Signaler une anomalie (sans code) | Aucune | Transmettre un constat à l'administration | **Absent** (« le contrôleur observe et signale », `PU` §4, sans écran) | `PU` §4 | Aucune |
| Flux d'anomalies (sans code) | Aucune | « Qu'est-ce qui nécessite une vérification ? » | **Partiel** : filtre « Incident » dans le planning ; pas de flux dédié | `AI` §6 | Aucune |
| Mon compte | `/compte` | Voir §1.4 | **Atteignable** (`planning_page.dart:172`) | | Aucune |

---

## 8. Contrôleur invité

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| Tout le rôle | Aucune | Inconnue | **Absent** : aucun rôle, aucune route, aucune spec. Le terme n'apparaît que comme hypothèse (« le jour où le contrôleur invité obtient une partie des droits admin », `AI` §2) et dans la liste des rôles à servir (`DEC` §1 ter-8) | Aucune | Aucune |

**Question au directeur, à poser avant toute spec** : qui est le contrôleur invité (inspecteur externe, parent référent, partenaire) ? Pour combien de temps ? Sur quelles classes ? Voit-il les noms des élèves ? Son accès est-il un compte ou un lien temporaire comme l'agent IA ?

---

## 9. Finance et comptable

**Destinations actuelles** : aucune. La racine `/comptable` rend l'écran « Mon compte » (`app_router.dart:959-963`). Le libellé du rôle dans « Mon compte » promet « Gère les paiements et les factures » (`fr.i18n.json:1320`), ce qu'aucun écran ne permet.

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| `CPT-01` Espace comptable | `/comptable` | Tableau de bord comptable | **Atteignable**, mais n'affiche que « Mon compte » ; `CPT-01` est « hors MVP-0 » (`CAT` §1) | `01` Rôles (Comptable) | Aucune |
| Encaissements et rapprochement (sans code) | Aucune | Paiements reçus, frais, taux de change datés | **Absent** ; aucune table de paiement des familles (`DEP` DB-CPT-03 : les tables de `0001:242-297` concernent la rémunération) | `07` Finance, moteur 2 | Aucune |
| Paiement transitoire saisi par l'admin (sans code) | Aucune | Voir section 6 | **Absent** | `06` (M essentiel) | Aucune |
| Portefeuille, solde par enfant, recharge (`TUT-03`, `CPT-02`) | Aucune | Crédits consommés par enfant | **Absent** ; place réservée côté tuteur (`DEC` §1 ter-9) | `07` Finance, moteur 3 | Aucune |
| Rémunération des enseignants (sans code) | Aucune | Minutes payables, paie en brouillon, versement | **Absent** | `07` Finance, moteur 4 | Aucune |
| Pilotage, prévisions, conseiller IA (sans code) | Aucune | KPI, scénarios | **Absent**, hors premier MVP | `07` Finance, moteurs 5 et 6 | Aucune |
| Exports comptables (sans code) | Aucune | Exports autorisés | **Absent** | `01` Rôles ; `06` Contrôle | Aucune |
| Domaine Finance de l'administration | Aucune | Voir section 6 | **Absent**, inerte | `07` | Aucune |

---

## 10. Agent IA

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| `AGT-00` Entrée d'un agent | `/agent` (`/agent?jeton=...`) | Ouvrir en lecture seule le parcours d'une personne ; sans jeton, un formulaire ; refus sans distinguer inconnu, révoqué, expiré | **Atteignable** avec le lien fabriqué par `ADM-07` (`acces_agents_page.dart:549`) | `CAT` §6 `AGT-00` | Aucune |
| `ADM-07` Accès des agents IA | `/admin/securite-audit/acces-agents` | Émettre, lister, révoquer les jetons | **Atteignable** (section 6) | `CAT` §6 `ADM-07` | Aucune |

Décision du directeur : ce système de jetons n'a **jamais fonctionné** ; il est remplacé par l'aperçu de pull request, le mode démonstration et les captures, et **ne doit pas être relancé sans décision** (`BKL` ligne 39). Conséquence proposée pour ChatGPT : le laisser « Hors périmètre, pour plus tard ».

---

## 11. Salle de classe et visio

**Entrées actuelles par rôle** : élève « Rejoindre » (accueil) → `/salle` ; enseignant « Lancer le cours » (Journée) → `/salle` ; contrôleur « Observer » (planning) → `/salle` ; tuteur « Assister » → `/tc/observation/:seanceId` (`accueil_famille_page.dart:192-193`) ; administration : **aucune**. La salle `/salle` n'est ni partageable ni mémorisable : le billet d'entrée ne passe pas par l'adresse (`routes.dart:449-454` ; `redirection.dart:163-166`).

| Écran ou fonction | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| `ELV-03` / `ENS-03` / `CTR-02` Salle unique actuelle | `/salle` | Un seul écran pour trois codes : visio, micro et caméra fermés à l'entrée, caméra absente si interdite, présence, réseau faible, reconnexion, bandeau permanent « Cours enregistré, visite de contrôle possible. » | **Atteignable** (élève, enseignant, contrôleur) ; **à vérifier** : le jeton vidéo serait refusé à tous (`DEP` DB-OBS-01 ; `BKL`) | `CAT` §6 ; `01` Classe ; `06` LiveKit | Aucune |
| Classe Live, seconde salle | `/tc/classe` | Salle plus riche (support dominant, entête de classe, fiche de séance, bibliothèque) | **Route sans bouton** ; décision : garder la plus complète, combiner, supprimer le doublon (`BKL` « Deux salles ») | `08D` §3 ; `BKL` | Aucune |
| Porte d'observation | `/tc/observation/:seanceId` | Entrée bornée du tuteur ; autorisée aussi à l'admin et au contrôleur | Atteignable **pour le tuteur seul** ; réelle désactivée en production (`OBSERVATION_TUTEUR_REELLE`, `DEC` P3) | `01` Classe | Maquettes tuteur `MAN` #18 à #24 |
| Pré-vol du matériel | dans `/enseignant/journee` et `/salle` | Vérifier le micro avant d'entrer | **Atteignable** côté enseignant (`journee_page.dart:503-556`) ; élève : vérification à l'entrée de salle (« Vérification de votre micro ») | `PU` §3 | Aucune |
| Présentation d'une page du Coran par l'enseignant | dans `/salle` | L'enseignant choisit une page, la classe la reçoit | Côté enseignant **atteignable sous condition** du droit signé ; côté élève **absent** : seul l'écran enseignant lit le flux (`salle_enseignant/presentation_coran.dart:55`) | `01` Classe et supports ; `06` Bibliothèque | Aucune |
| Bouton « Ouvrir le Coran » côté élève | Aucune | L'élève ouvre le Coran pendant la séance | **Absent** (`salle_page.dart:55-60`) | `PU` §2 `ELV-03` | Aucune |
| Barre « Séance en direct » persistante | Aucune | Revenir à la séance après avoir navigué | **Code non branché** (`tc_classe_live/barre_cours_en_cours.dart`) | `01` (« session persistante lors de la navigation ») | Aucune |
| Synchronisation en direct et reprise après coupure | Aucune | État partagé du support, rejoué à la reconnexion | **Code non branché** (`lib/core/tc_realtime/*`, `lib/core/tc_etat_partage/*`) | `02` règle 4 ; `06` Outils enseignant | Aucune |
| Outils de classe (dock) | Aucune | Pointer, marquer, masquer, annoter | **Code non branché** (`lib/features/tc_dock/*`) | `06` Outils enseignant | Aucune |
| Bibliothèque pendant la séance | Aucune | Choisir un support | **Code non branché** (`class_library_picker.dart`) | `06` Bibliothèque | Aucune |
| Notices d'observation dans la salle | dans `/salle` | L'enseignant voit qu'un tuteur observe ; l'enfant concerné voit un témoin | **Atteignable** (`salle_page.dart:508-518`). Conception des notices enseignant et élève **hors périmètre** du chantier Tuteur (`DEC` §1 bis-6) : à spécifier | `01` Classe | Aucune (planche 3 « États particuliers et notices de présence » manquante, `MAN` §1) |
| Sortie de salle | depuis `/salle` | Enseignant vers le cahier ; autres rôles vers leur accueil | **Atteignable** (`salle_page.dart:217-240`) | `AI` §5 | Aucune |
| Présence | dans `/salle` et cahier | Présence calculée par le serveur, jamais « absent » inventé | **Atteignable** (lecture) ; consolidation après séance absente (`DEP` DB-HIS-04) | `06` Présence | Aucune |
| Enregistrement audio | bandeau | Le directeur affirme l'enregistrement **réel** (bucket R2) et garde la notice (`DEC` §1 bis-2) ; `06` interdit de l'activer sans décision écrite. **Conflit à signaler** | Bandeau atteignable ; enregistrement serveur **à vérifier** | `06` Enregistrement ; `DEC` §1 bis-2 | Aucune |
| Fenêtre d'entrée | élève, enseignant, serveur | Moment où « Rejoindre » s'ouvre | Trois valeurs : élève au début, enseignant 10 min avant, serveur 20 min avant ; texte de refus « La salle s'ouvre dix minutes avant l'heure du cours, et se ferme un quart d'heure après sa fin. » (`salle.refusAccesDetail`) | `01` (environ T-20 configurable) | Aucune |

---

## 12. Bibliothèque et ressources

| Écran ou fonction | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| Bibliothèque | `/tc/bibliotheque` (`?groupe=` pour la section « Pour ce groupe ») | Catalogue des supports | Autorisée à l'élève et au tuteur seulement (`redirection.dart:288-291`). **Route sans bouton** pour l'élève ; tuteur via l'Espace Classe. **Toujours vide** : source locale sans contenu (`lib/core/tc_bibliotheque/donnees_catalogue.dart:28-34`), alors que la fonction serveur `ressources_du_groupe` existerait (`DEP` §0 ligne 25, **à vérifier**) | `01` Classe et supports ; `06` Bibliothèque | Aucune |
| Fiche d'une ressource | `/tc/bibliotheque/:resourceId` | Lire un PDF, une image, une leçon ; téléchargement hors ligne | Même état (entrée depuis la liste, `bibliotheque_page.dart:46`) | idem | Aucune |
| Ressources de la classe (tuteur) | `/tuteur/classes/:id/ressources` | Vue tuteur | STUB, lot C (hors portée de ce document) | `LOTS` C.2 | Aucune |
| Bibliothèque de l'enseignant | Aucune | Préparer et choisir ses supports | **Refusée** par la garde ; sélecteur en classe non branché | `01` | Aucune |
| Gestion par l'administration | Aucune | Importer, versionner (version publiée immuable), source et licence vérifiées, visibilité | **Absent** | `01` ; `02` Ressources ; `06` Bibliothèque | Aucune |
| Leçons, PDF, images : types de contenu | Aucune source | | **Absent** en production (catalogue vide) | `01` | Aucune |

---

## 13. Lecteur du Coran

| Écran ou fonction | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| `ELV-04` Lecteur | `/eleve/coran` (rend le moteur `MushafPage`) | Trois rendus (page, verset agrandi, focus), zoom, feuille de navigation, reprise personnelle et reprise de la classe, attribution Tanzil au pied | **Atteignable** pour l'élève (section 3). Défauts consignés, **non corrigés par décision** (`08D` §5 bis 24/09 ; `BKL` §Coran) : ordre des versets inversé (`lib/core/coran/service_coran.dart:309, 329-330, 459-460`, tri sans `ascending: true`), voyelles absentes, espacement trop large, mise en page non conforme au Mushaf de Médine (604 pages, 15 lignes, hizb, juz', rub', sajda), commandes manquantes ; gestes et boutons de page en sens contraires (`R4` §5.5) | `CAT` `ELV-04` ; `01` Classe et supports ; `03` Salle ; `BKL` | Aucune |
| Moteur en double | `/tc/mushaf` | Même écran | **Route sans bouton** ; décision : combiner puis supprimer le doublon (`BKL`) | `BKL` | Aucune |
| Suivre la classe dans le lecteur | Aucune | Position de la classe, « suivre le professeur » | **Code non branché** : l'identifiant de séance n'est jamais passé (`app_router.dart:322-323` construit `const MushafPage()`) | `01` Classe (« l'élève suit l'enseignant ») | Aucune |
| Mise en page fidèle ligne par ligne | Aucune | Pages identiques au Mushaf imprimé | **Absent** : port de mise en page désactivé (`lib/core/tc_coran/layout_lignes_indisponible.dart`) ; règle : sans référence, afficher le mode verset, jamais une fausse page « Mushaf » (`BKL`) | `03` Salle | Aucune |
| Coran pour l'enseignant hors salle | Aucune | Préparer | **Absent** (section 5) | `CAT` `ELV-04` | Aucune |
| Coran en Interface guidée | `/eleve/coran` | Sourates par nom et numéro en gros, sans recherche | Même écran que le mode standard ; pas de variante guidée repérée ; aucun retour visible (section 4) | `PU` §2 | Aucune |
| Marque-pages | dans le lecteur | Reprendre sa lecture | Reprise personnelle présente ; **décalée** par l'ordre inversé (`R4` §5.3) | `PU` §2 | Aucune |

---

## 14. Parcours transverses indispensables à la publication

| Parcours | Écrans et étapes actuels | État | Preuves | Ce qui manque pour publier |
|---|---|---|---|---|
| **Connexion** | `/connexion` : lien par courriel ou Google ; élève : `/connexion/eleve` | Web fonctionnel ; mobile natif : le retour du lien tombe sur le site web | `DEP` DB-ADM-07 (aucun `intent-filter` Android, aucun `CFBundleURLSchemes` iOS) ; `DEP` DB-TRV-04 (retour vers la page demandée). [critique] Aucun fichier `.entitlements` dans `ios/Runner` (donc ni Associated Domains ni push) ; Google est le seul fournisseur externe (`lib/core/auth/service_auth.dart:52, 64`) | Liens profonds Android et iOS ; retour à la page demandée après le lien ; refonte lot A. [critique] Sur iOS, la règle App Store 4.8 peut exiger, à côté de Google, une option de connexion équivalente qui protège l'adresse (type « Se connecter avec Apple ») : **à vérifier** avant la soumission |
| [critique] **Acceptation des conditions à l'inscription** | Aucune case ni lien dans `/inscription` ; seul un contrat de rôle est signé plus tard dans `/attente/contrat` | **Absent** | Aucune chaîne « conditions générales » ni « politique de confidentialité » dans `fr.i18n.json` (seule « Confidentialité », désactivée, `:1244-1245`) | Lien vers conditions et confidentialité avant création du compte, version acceptée conservée ; consentement parental pour les profils mineurs |
| **Récupération d'accès** | `/connexion/recuperation` | STUB, aucun lien | `recuperation_page.dart` | L'écran, le lien depuis la connexion, les états (lien expiré, déjà utilisé, renvoyer) ; lot A |
| **Inscription et choix du rôle** | `/inscription` (rôle, identité, genre, récapitulatif) | Atteignable ; étapes nouvelles en STUB | `inscription_page.dart` ; `LOTS` A.2 | Élève adulte réel (DB-FOY-01) ; lien « Je suis enseignant » ; migration des élèves et enseignants déjà inscrits ailleurs (onboarding de confirmation, comptes provisoires : `decisions.md:435` archive, `06` Inscription) |
| **KYC enseignant** | `/inscription` (rôle Enseignant) → `/attente` → `/attente/accuse` → `/attente/contrat` → `/attente/piece` → attente de validation | Atteignable ; après validation, arrivée sur la Journée, **jamais** sur « Premiers pas » | `attente_page.dart:138-150` ; `routes.dart:538` | Texte et maquette du contrat enseignant ; statut et délai annoncés ; bouton vers « Premiers pas » ; notification de validation |
| **Validation des dossiers par l'administration** | `ADM-02` (valider, refuser avec motif) ; `ADM-08` (lecture) | Atteignable ; bloqué si genre de l'admin manquant | `dossiers_page.dart:305-319, 444` | Moyen de renseigner le genre du personnel ; activation, suspension, compte provisoire ; création des comptes du personnel (enseignant, contrôleur, comptable, admin) : **à vérifier** (peut-être seulement par la console Supabase) |
| **Notifications** | Cloche admin (feuille vide), cloche tuteur (STUB), réglages de notifications sans effet | **Absent** | `DEP` DB-CPT-04 ; `pubspec.yaml` sans aucune dépendance de notification push ; `supabase/functions/` sans envoi d'e-mail ni de push ; table `device_tokens` créée (`0001_fondations.sql:348`) mais sans émetteur | Notifications de cours, de changement, de validation (push, e-mail) et leurs textes ; seuls les e-mails de connexion envoyés par Supabase Auth existent (**à vérifier** : modèle et langue). [critique] Dans le dépôt : aucun modèle d'e-mail personnalisé (`supabase/config.toml:249-258` commenté, aucun dossier `supabase/templates`), SMTP de production commenté (`:239-247`), lien valable 1 h (`otp_expiry = 3600`, `:237`) : les modèles Supabase par défaut sont en anglais, et le SMTP intégré a un quota d'envoi très bas (réglage du projet de production **à vérifier**). E-mails transactionnels à spécifier : lien de connexion, dossier incomplet, validé ou refusé, rappel et changement de séance, accès qui arrive à échéance, confirmation de suppression du compte. Permission `POST_NOTIFICATIONS` (Android 13+) absente ; écran d'amorce avant la demande système à prévoir |
| [critique] **Supervision des erreurs** | `sentry_flutter` 8.14.2 (`pubspec.yaml`), filtre `beforeSend` (`lib/core/observabilite/supervision.dart:72`) | Présent | idem | À déclarer dans la politique de confidentialité, Data safety et App Privacy ; compatibilité avec la catégorie Enfants et le programme Familles **à vérifier** |
| **Paiements manuels** | Aucun écran | **Absent** | `DEP` DB-CPT-03 ; seule la date `access_until` existe | Saisie admin d'un paiement hors application, accès daté, relance humaine, lecture famille ; jamais un paiement simulé comme réglé (`01`) |
| **Mentions légales et confidentialité** | Tuteur : `/tuteur/compte/informations-legales` (STUB) ; autres rôles : ligne « Confidentialité », sous-titre « Bientôt disponible », désactivée | **Absent** | `DEP` DB-CPT-08 (aucun document dans le dépôt) ; `compte_page.dart:87-92` | Textes (mentions légales, confidentialité, conditions, consentement parental), pages publiques et dans l'application pour tous les rôles |
| **Suppression de compte** | Aucune | **Absent** | Aucune occurrence dans `lib/` ni `supabase/` | Demande de suppression depuis l'application pour chaque rôle, conséquences sur le foyer et les enfants, conservation légale (durées de `ADM-17`) ; exigée par Apple et Google (**à vérifier** sur les règles en vigueur). [critique] Google Play demande aussi une adresse web de suppression utilisable sans l'application (**à vérifier**) ; traitement côté administration absent (section 6) ; export des données personnelles (droit d'accès et de portabilité) absent lui aussi |
| **Langue** | Français seul | Partiel | `assets/i18n/ar.i18n.json` : 32 lignes ; `fr.i18n.json` : 2 366 | Décision sur l'arabe au lancement ; sélecteur de langue |
| **Libellés audio (Interface guidée)** | Composant présent | Sans son | `assets/audio/fr/` : seulement `.gitkeep` | Enregistrer les fichiers de `lib/core/i18n/cle_audio.dart` |
| **Mode démonstration par rôle** | Seulement un mot de passe de démonstration (`DEMO_AUTH`) et un bac à sable de développement (`PLAYGROUND`) | **Absent** comme sélecteur de rôle | `connexion_page.dart:89-121` ; `DEC` §1 ter-6 | Sélecteur de rôle hors production, repère « Démonstration », aucun appel serveur |
| **Publication Android** | `applicationId` `com.rewayahacademy.rewayah_academy` ; version `0.2.0+1` | Non prêt | `android/app/build.gradle.kts:19` ; `pubspec.yaml:5` ; nom affiché « rewayah_academy » (`AndroidManifest.xml:11`) ; manifeste principal : seule la permission `CAMERA`. [critique] Correction : `RECORD_AUDIO` n'est déclarée **nulle part** (ni dans `src/debug`, ni dans `src/profile`, qui ne portent que `INTERNET`, ni dans les manifestes de `livekit_client` 2.12.0 et `flutter_webrtc` 1.6.0 du cache pub) ; `INTERNET` en version publiée : fusion par les paquets **à vérifier** ; `ACCESS_NETWORK_STATE` apporté par `connectivity_plus`. CI : construction apk en échec (`08D` §5 bis, run CI #4) | Nom, icône, permissions micro et réseau, fiche Play Store, programme Familles, Data safety |
| **Publication iOS** | `CFBundleDisplayName` « Rewayah Academy » | Non prêt | `ios/Runner/Info.plist` : `NSCameraUsageDescription` présent, **`NSMicrophoneUsageDescription` absent**. [critique] Aucun `UIBackgroundModes` (son de la visio quand l'application passe en arrière-plan : **à vérifier**), aucun `PrivacyInfo.xcprivacy` ni `.entitlements` dans `ios/Runner` | Texte d'usage du micro, fiche App Store, catégorie Enfants ou non, App Privacy, compte de démonstration pour la revue ; [critique] manifeste de confidentialité Apple (**à vérifier**) |
| **Publication web** | Application Flutter servie par Vercel | Chaîne réparée le 24/09 (aperçu par pull request, production sur `main`) | `08D` §5 bis ; `web/manifest.json` | Site public séparé (section 2), référencement |
| **Publication Windows** | Dossier `windows/` présent | Non prêt | CI Windows en échec (`08D` §5 bis) | Décision de publication, empaquetage |

---

## 15. Maquettes

### 15.1 Maquettes existantes utiles hors tuteur

Toutes les maquettes du dossier `D:\RA _APP\docs de lancement\tutuor image\` ont été dessinées pour le tuteur. Trois groupes servent aussi à d'autres rôles :

| Maquette (`MAN` §1) | Fichier | Écran | Rôles concernés |
|---|---|---|---|
| #10, #11 | `onboarding Mble.png`, `onboarding Mble d.png` | Inscription : usage, genre | Public, élève adulte (« Moi uniquement »), enseignant (lien discret) |
| #12 à #17 | `onboarding mobile 1.png`, `Onboarding mobile 2.png` | Inscription : usage, genre, âge, langue, objectif, récapitulatif | idem |
| #23 | `mobile\tuteur observation mobile light.png`, zone M6 | Consentement « Les visites des parents » | Contrat famille ; la variante enseignant n'existe pas |
| #26 | `tuteur observation desktop light.png`, zone D3 | Historique des observations, administration (ordinateur, clair) | Administration |

[critique] Maquettes du tuteur qui servent de **modèle le plus proche** (pas de maquette de l'écran lui-même) pour d'autres rôles : Mon compte #5 à #7 et Réglages / Apparence #8, #9 pour `/compte`, `/compte/profil`, `/compte/reglages` (mêmes fonctions : thème Système, Clair, Sombre ; langue ; notifications) ; écran résultat #22 pour les pages d'état transverses du §1.3 (introuvable, accès refusé, hors ligne), que `TUTEUR_ECRANS_SANS_MAQUETTE.md` SM-45 à SM-47 dérive déjà de #22 pour tous les rôles. Recherche faite le 24/09 : aucune autre image de maquette dans `D:\RA _APP` ni `D:\RA_TUTEUR` hors captures de code.

### 15.2 Captures de l'état actuel (pas des cibles)

Rendu actuel du code, utile pour voir ce qui existe, jamais comme direction visuelle :
- élève : `D:\RA _APP\pilotage-tuteur-v1\04_phase0\captures_revue_a11y\apres_eleve_accueil_390_clair.png`, `..._390_sombre.png`, `..._1440_sombre.png`, `..._390_clair_texte200.png`, `apres_eleve_direct_390_guidee_clair.png`, `..._guidee_sombre.png`, `apres_eleve_direct_390_standard_clair.png` ;
- enseignant : même dossier, `apres_enseignant_journee_390_clair.png`, `..._390_sombre.png`, `..._390_clair_texte200.png`, `..._1024_clair.png`, `apres_enseignant_creneaux_390_clair.png` ;
- connexion : `D:\RA _APP\pilotage-tuteur-v1\02_code\capture_proto\out\01_connexion_390x844@3_clair.png`, `02_..._sombre.png`, `03_connexion_1440x900@1_clair.png`, `04_..._texte200.png`.

### 15.3 Écrans hors tuteur sans aucune maquette (besoin d'une nouvelle image)

Tous les écrans des sections 3 à 13, **sauf** : l'inscription (#10 à #17), le consentement famille (#23), l'historique des observations admin (#26). Les écrans du lot A (bienvenue, connexion, récupération, dossier `/attente`) ont une **dérivation** écrite (`MAN` §2), pas une maquette. Priorités du directeur pour l'ordre des images : salle élève et enseignant (priorité n° 1, `BKL`), validation des dossiers par l'administration, puis les rôles dans l'ordre du prompt.

---

## 16. Vocabulaire et registre : écarts relevés dans les textes actuels hors tuteur

| Écart | Exemples exacts (`assets/i18n/fr.i18n.json`) |
|---|---|
| « groupe » au lieu de « Classe » | `admin.groupes.*` (lignes 589-640 : « Groupes », « Créer un groupe », « Nom du groupe ») ; enseignant « Voir le groupe » (1559), « Fiche du groupe » (1737), « Note pour le groupe » (1614) ; Espace Classe « Mes groupes » (1817) |
| « Cours en cours » | « Cours en cours · {reste} » (1857, Espace Classe) |
| « Mode enfant » au lieu de « Interface guidée » | « Mode enfant » (1299, 1811) |
| « Ajouter un enfant » | 336, 1297 |
| « session » | « Mettre fin à la session sur cet appareil » (1250) ; « Votre session a expiré » (37) |
| Promesse de date (« bientôt ») | « Bientôt disponible » (1245, 1278, 1891) ; « C'est bientôt » (126) |
| Ancien modèle « matching » | « Prendre {jour} à {heure} h » (404) ; « Prenez un élève en attente » (1544) ; « Cours individuel » (1556) ; « L'académie vous confie des élèves sur ces heures » (1519) |
| Code interne visible | « migration 0036 » dans `admin.groupes.observationCapaciteAbsente` |
| Registre incohérent pour l'élève | Accueil au tutoiement (`eleve.accueil`), suivi et salle au vouvoiement (`eleve.suivi`, `salle.*`) ; aucun texte propre à l'adulte |
| Rôle qui promet l'inexistant | « Gère les paiements et les factures » (1320, comptable) |

---

## 17. Points à vérifier et questions ouvertes

1. **Validation des dossiers** : le blocage vient-il du genre manquant de l'administrateur, d'une absence de pièce déposée, ou du serveur ? À mesurer en base avant de spécifier `03_ADMIN_VALIDATION_DOSSIERS.md`.
2. **Jeton vidéo** : la migration `0042` refuse-t-elle vraiment tout jeton (`DEP` DB-OBS-01) ? Sans jeton, aucune rencontre élève-enseignant. [critique] `0039` à `0042` n'existent dans aucune branche du dépôt (ni `cefab7f`, ni `origin/main` @ `4a7aa2b` : `supabase/migrations/` saute de `0038` à `0043`) ; elles ne sont connues qu'en production (`DEP` DB-OBS-13). La vérification se fait donc en base, pas dans le code.
3. **Fenêtre d'entrée** : quelle valeur unique (10 ou 20 minutes, configurable) pour tous les rôles ?
4. **Salle unique** : laquelle garder comme base (`/salle` ou `/tc/classe`) ?
5. **Élève adulte** : bascule d'un compte titulaire vers son espace élève (un seul rôle par session aujourd'hui, `DEP` DB-FOY-01) : deux comptes, ou une bascule dans le même compte ?
6. **Interface guidée** : l'enfant doit-il pouvoir se déconnecter ou revenir en arrière depuis le Coran, contre la règle « aucune destination » ?
7. **Contrôleur invité** : définition complète (section 8).
8. **Enregistrement audio** : conflit entre `06` (ne pas activer sans décision écrite) et la réponse du directeur (enregistrement réel, `DEC` §1 bis-2).
9. **Capacités et durées des classes** : 5 enfants / 60 min et 6 adultes / 90 min, ou 4/45 et 5/90 (`07` arbitrage 1) ; la création de classe actuelle ne porte pas de durée.
10. **Comptes du personnel** : comment l'administration crée-t-elle un compte contrôleur, comptable ou administrateur ? Aucun écran ne le fait.
11. **Agent IA** : confirmer « hors périmètre » (`BKL` ligne 39).
12. **Arabe au lancement** : oui ou non.

---

## Annexe : rejouer ces constats

```powershell
$r = "D:\RA_TUTEUR\integration"
git -C $r rev-parse --short HEAD                                   # cefab7f
# Routes et gardes
Get-Content "$r\lib\core\router\routes.dart", "$r\lib\core\router\app_router.dart", "$r\lib\core\router\redirection.dart"
# Entrees de navigation hors routeur
rg -o "(Routes\.[a-zA-Z]+|CheminsTcA\.[a-zA-Z]+|RoutesTc[A-Z]\.[a-zA-Z]+|RoutesCoran\.[a-zA-Z]+)" "$r\lib" -g "!**/core/router/**"
# Ecrans provisoires
rg -n "STUB PHASE 0 : propri" "$r\lib"
# Graphe d'imports (lecture seule, sortie hors depot)
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\RA _APP\pilotage-tuteur-v1\06_registre\outils\graphe_imports.ps1" -Repo $r -Ref cefab7f -OutDir <dossier hors depot>
```


---


# F. Mandat original du directeur pour le rôle Tuteur

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


---


---

# ANNEXE 11 - Spécification verticale Admin - validation des dossiers

_Source : `03_ADMIN_VALIDATION_DOSSIERS(1).md`. Contenu conservé pour ne pas perdre les détails métier._


# Rewayah Academy - 03_ADMIN_VALIDATION_DOSSIERS

**Version :** V1  
**Date :** 25/09/2026  
**Statut :** PROPOSITION À VALIDER PAR LE DIRECTEUR  
**Périmètre :** verticale de déblocage préalable au rôle Enseignant  
**Rôle principal :** Administration  
**Domaine :** Personnes  
**Écran canonique existant :** `ADM-02`  
**Route existante :** `/admin/personnes/dossiers`

---

# 0. Pourquoi ce document vient avant le rôle Enseignant

L'ordre de travail canonique place cette verticale immédiatement après `02_CLASSE_ET_VISIO.md` et avant `04_ENSEIGNANT.md`.

Ce lot est volontairement étroit. Il ne redessine pas toute l'administration. Il doit rendre réellement utilisable le parcours qui permet à une personne autorisée de l'administration de revoir un dossier d'inscription, consulter la pièce déposée, effectuer les vérifications déjà prévues par le produit, puis prendre une décision serveur traçable.

Le dépôt décrit actuellement `ADM-02` comme un écran atteignable, mais le parcours est fragile. Il peut se bloquer si le genre de l'administrateur n'est pas renseigné. Le profil commun est en lecture seule, donc l'administrateur n'a actuellement aucun moyen visible de corriger ce prérequis.

Cette verticale doit être terminée avant `04_ENSEIGNANT.md`, car un enseignant qui reste en attente de validation ne peut pas atteindre normalement son espace actif.

Ce document ne doit pas être interprété comme une autorisation de réécrire l'authentification, le routeur, le stockage KYC, les rôles ou l'ensemble du domaine Administration.

---

# 1. Autorité et hiérarchie des décisions

Claude Code applique les sources dans cet ordre :

1. sécurité, confidentialité, RLS, politiques de stockage et décisions serveur existantes ;
2. décisions explicites du directeur dans les documents courants ;
3. contrats backend existants ;
4. présent document pour le parcours et l'UX de `ADM-02` ;
5. Bible Frontend UI/UX V2 et design tokens gelés ;
6. composants partagés déjà présents dans le dépôt ;
7. documentation officielle Flutter et standards d'accessibilité ;
8. propositions UX marquées `PROPOSITION`.

Une maquette ne peut jamais élargir une permission.

Une proposition de ce document ne peut jamais remplacer silencieusement une règle serveur.

Une donnée absente du contrat serveur ne doit pas être inventée pour remplir une carte.

---

# 2. Faits source à préserver

Les faits ci-dessous sont considérés comme établis par le dossier fourni :

- l'application est Flutter, avec Supabase, LiveKit et stockage privé R2 ;
- l'administration possède une coquille propre avec domaines ;
- `ADM-02` existe sur `/admin/personnes/dossiers` ;
- `/admin/personnes` redirige actuellement vers cet écran ;
- le point d'entrée existe depuis le domaine Personnes et depuis le compteur `Dossiers à valider` du centre de commande ;
- le fonctionnement actuel traite un dossier à la fois ;
- le dossier présente une pièce d'identité déposée ;
- trois vérifications existent déjà dans le parcours actuel ;
- les actions existantes sont `Valider le dossier` et `Refuser`, avec motif pour le refus ;
- l'écran ne montre aujourd'hui que les pièces déposées ;
- l'écran se bloque si le genre de l'administrateur est absent ;
- le profil commun est actuellement en lecture seule ;
- le portail d'attente est partagé par les comptes tuteur et enseignant ;
- le portail d'attente peut afficher les états incomplet, en vérification, refusé avec motif et suspendu ;
- le dépôt de pièce propose Carte d'identité, Passeport, Titre de séjour ou Autre et contrôle un plafond de 8 Mo côté parcours existant ;
- la pièce d'identité est distincte de la photo publique d'un enseignant et distincte du portrait d'un élève ;
- l'enseignant actif et assignable doit posséder une photo publique professionnelle, mais cette photo publique ne devient pas une pièce KYC ;
- le système de notifications applicatives n'est pas actuellement garanti ;
- les dossiers et pièces sont des données sensibles et ne doivent jamais être exposés aux autres rôles ;
- les actions sensibles doivent être auditées ;
- le web doit être une vraie version ordinateur ;
- les titres sont en DM Sans et le reste en Plus Jakarta Sans ;
- une carte groupée est un seul rectangle séparé par des filets internes ;
- une fonction doit vivre à un seul endroit.

---

# 3. Points non prouvés par les sources

Les sources fournies ne donnent pas les libellés exacts des trois vérifications actuelles de `ADM-02`.

**INTERDICTION :** ne pas inventer trois contrôles métier sous prétexte de compléter l'UI.

Avant modification, Claude doit retrouver dans le code et l'i18n :

- les trois libellés visibles actuels ;
- leur source de données ;
- leur caractère obligatoire ou informatif ;
- leur mode actuel de validation ;
- l'effet serveur de chaque contrôle.

S'ils n'existent plus dans le code courant, Claude arrête la modification de cette sous-partie, documente la divergence et demande un arbitrage. Il peut continuer les éléments indépendants.

Les sources ne prouvent pas non plus la raison métier du prérequis `genre de l'administrateur`.

Claude doit donc vérifier :

1. si ce champ sert réellement à une politique d'autorisation ou de confidentialité ;
2. si le filtre est appliqué au serveur ou seulement dans le frontend ;
3. si l'absence de valeur est un défaut de migration ou d'onboarding personnel ;
4. si la règle est documentée ailleurs dans le dépôt.

**PROPOSITION P-ADM-02-01 :** si aucune règle métier ou de sécurité ne justifie le blocage par le genre de l'administrateur, traiter ce couplage comme un défaut technique et le supprimer du parcours de revue. Ne jamais supprimer une règle serveur prouvée.

**PROPOSITION P-ADM-02-02 :** si la règle de genre est effectivement requise, rendre le champ modifiable dans l'unique écran partagé `/compte/profil`, sans créer un deuxième profil propre à `ADM-02`. Le dossier affiche alors une dépendance claire qui renvoie vers ce profil.

---

# 4. Validation obligatoire des propositions UX/UI avec les standards 2026

Cette section est une instruction d'exécution à Claude Code.

Avant d'implémenter les propositions de disposition marquées `PROPOSITION`, Claude doit les confronter aux standards officiels et reconnus disponibles au moment de l'exécution.

## 4.1 Référentiels minimum à vérifier

Claude vérifie au minimum :

- documentation Flutter officielle sur les interfaces adaptive et responsive ;
- recommandations Flutter sur souris, clavier, hover, focus, scroll et raccourcis ;
- Material Design 3 pour hiérarchie, composants, feedback, dialogues, densité et états ;
- Apple Human Interface Guidelines pour les adaptations iOS réellement pertinentes ;
- WCAG 2.2 niveau AA ;
- version 2026 de EN 301 549 si applicable au web accessible ;
- heuristiques de Nielsen ;
- principes de Fitts, Hick, proximité, visibilité d'état et prévention des erreurs ;
- GOV.UK Design System pour erreurs, confirmations, formulaires sensibles et langage clair ;
- bonnes pratiques Baymard applicables aux formulaires, validation et prévention d'erreurs.

## 4.2 Preuve attendue

Claude produit avant intégration un court `UX_REVIEW_03_ADMIN_DOSSIERS.md` dans le dossier de pilotage du lot, contenant :

- proposition contrôlée ;
- standard ou source officielle consultée ;
- date de consultation ;
- règle utile ;
- conclusion : conforme, ajustée ou non applicable ;
- modification effectuée si nécessaire ;
- justification de toute dérogation.

Claude ne doit pas écrire seulement « conforme aux standards UX ». Il doit donner la règle et la conséquence concrète.

## 4.3 Limite de cette validation

Les standards UX/UI peuvent améliorer :

- la disposition ;
- la densité ;
- la lisibilité ;
- le focus clavier ;
- le positionnement des actions ;
- la confirmation d'une décision ;
- les messages d'erreur ;
- l'adaptation mobile, tablette et ordinateur.

Ils ne peuvent pas modifier :

- les permissions ;
- les règles KYC ;
- les états serveur ;
- les critères de validation métier ;
- la rétention des pièces ;
- la visibilité des données sensibles ;
- le nombre ou la nature des vérifications métier ;
- l'effet juridique d'une décision.

Si un standard UX suggère un comportement qui contredit une règle métier prouvée, la règle métier prévaut.

---

# 5. Fiche du rôle pour cette verticale

## 5.1 Utilisateur

Utilisateur principal : membre du personnel administratif autorisé à traiter des dossiers.

Contexte :

- utilisation fréquente sur ordinateur ;
- possibilité d'usage tablette ;
- usage mobile possible mais secondaire ;
- tâches répétitives, sensibles et à faible tolérance à l'erreur ;
- données personnelles et documents d'identité ;
- besoin de travailler rapidement sans sacrifier la vérification.

## 5.2 Tâches principales

Ordre de priorité :

1. identifier le prochain dossier réellement prêt à être revu ;
2. lire les informations nécessaires et la pièce déposée ;
3. exécuter les trois vérifications métier existantes ;
4. valider le dossier si le serveur confirme tous les prérequis ;
5. refuser avec un motif exploitable par la personne concernée si le dossier ne peut pas être accepté.

## 5.3 Ce que l'administrateur ne doit jamais voir ici

Cet écran ne doit pas devenir une fiche globale de la personne.

Ne pas afficher dans `ADM-02` :

- paiement du foyer ;
- solde ;
- coordonnées d'autres membres du foyer ;
- notes pédagogiques ;
- détails de classes non nécessaires à la validation ;
- télémétrie de visio ;
- identifiants techniques de stockage ;
- URL brute d'un objet R2 ;
- jeton de lecture de pièce ;
- secrets Supabase ;
- données d'un dossier non autorisé ;
- journal d'audit complet ;
- données internes sans rapport direct avec la décision.

Pour voir l'historique global d'une personne après décision, l'administration utilise le registre `ADM-08 Comptes`, pas `ADM-02`.

---

# 6. Navigation

Cette verticale n'invente aucune nouvelle destination principale.

Navigation admin existante à préserver :

- Accueil
- Opérations
- Personnes
- Pédagogie
- Finance
- Configuration
- Sécurité et audit
- Direction, seulement si la capacité existe réellement

Destination active pour `ADM-02` : **Personnes**.

## 6.1 Entrées autorisées

Entrée principale :

`Administration > Personnes > Dossiers à valider`

Raccourci autorisé :

`Accueil admin > compteur Dossiers à valider`

Les deux entrées ouvrent le même flux et la même route canonique.

## 6.2 Sorties

Depuis `ADM-02` :

- retour vers le centre de commande ;
- navigation vers les autres domaines via la coquille admin ;
- retour au prochain dossier après décision ;
- accès à `/compte/profil` uniquement si un prérequis personnel réel bloque la revue ;
- accès à `ADM-08 Comptes` seulement via la navigation normale, jamais comme doublon de la file.

---

# 7. Carte des fonctions, anti-doublon

| Fonction | Écran unique | Route / surface | Emplacement | Point d'entrée |
|---|---|---|---|---|
| Voir les dossiers prêts à être revus | ADM-02A | `/admin/personnes/dossiers` | colonne ou liste de file | Personnes, compteur Accueil |
| Ouvrir un dossier | ADM-02A -> ADM-02B | même route avec sélection stable ou route de détail existante si déjà présente | sélection dans la file | ligne du dossier |
| Voir les informations nécessaires | ADM-02B | détail du dossier | bloc Identité et dossier | dossier sélectionné |
| Voir la pièce déposée | ADM-02C | viewer local sécurisé | panneau document | action `Voir la pièce` |
| Exécuter les trois vérifications | ADM-02B | détail du dossier | bloc Vérifications | dossier sélectionné |
| Valider le dossier | ADM-02B + confirmation ADM-02E | même flux | zone décision fixe | bouton `Valider le dossier` |
| Refuser le dossier | ADM-02B + feuille ADM-02D | même flux | zone décision fixe | bouton `Refuser le dossier` |
| Renseigner un prérequis personnel admin | `/compte/profil` | écran partagé existant | profil personnel | dépendance affichée dans ADM-02 |
| Voir les comptes déjà décidés | ADM-08 | `/admin/personnes/comptes` | registre existant | navigation Personnes / Outils |

Aucun historique de dossiers décidés n'est créé dans `ADM-02`.

Aucun second écran de profil admin n'est créé.

Aucun second stockage KYC n'est créé.

---

# 8. Parcours de bout en bout

## P-ADM-01 - Ouvrir la file depuis Personnes

1. L'administrateur ouvre le domaine Personnes.
2. `Dossiers à valider` est la destination active.
3. Le serveur charge uniquement les dossiers accessibles à cet administrateur et prêts pour revue.
4. Si des dossiers existent, le premier élément peut être sélectionné automatiquement sur desktop seulement.
5. Sur mobile, aucune sélection automatique ne pousse l'utilisateur dans un dossier sans action. La liste reste visible.
6. L'administrateur ouvre un dossier.
7. Le détail charge ses données indépendamment de la liste.
8. Le retour restaure la position et les filtres de la file.

## P-ADM-02 - Ouvrir depuis le compteur Accueil

1. L'administrateur touche ou clique `Dossiers à valider`.
2. Le système ouvre `/admin/personnes/dossiers`.
3. La file utilise le même état que l'entrée par Personnes.
4. Aucun écran parallèle n'est créé.

## P-ADM-03 - Revoir un dossier enseignant

1. L'administrateur ouvre un dossier de type Enseignant.
2. L'écran montre le rôle, l'identité nécessaire, l'état du dossier et les éléments réellement soumis.
3. La pièce d'identité est ouverte dans le viewer sécurisé.
4. L'administrateur revient au dossier sans perdre sa progression.
5. Les trois vérifications métier existantes sont renseignées ou confirmées selon le contrat réel.
6. `Valider le dossier` reste indisponible tant que le serveur ne considère pas le dossier validable.
7. L'administrateur demande la validation.
8. Une confirmation explicite résume la conséquence.
9. Le client envoie une seule commande serveur idempotente avec version attendue du dossier.
10. Le succès n'est affiché que si le serveur confirme la nouvelle situation.
11. Le dossier disparaît de la file active.
12. L'écran sélectionne le dossier suivant sur desktop, ou revient à la file sur mobile.
13. Le parcours enseignant est ensuite géré par `04_ENSEIGNANT.md`. `03` ne choisit pas silencieusement sa page d'atterrissage.

## P-ADM-04 - Refuser un dossier

1. L'administrateur ouvre un dossier.
2. Il choisit `Refuser le dossier`.
3. Une feuille ou un dialogue demande le motif.
4. Le motif est obligatoire.
5. Le texte est rédigé pour pouvoir être affiché dans le portail d'attente, car l'état refusé montre un motif serveur.
6. La commande de refus n'est envoyée qu'après confirmation.
7. Le succès n'est annoncé que si le serveur confirme la décision.
8. Le dossier quitte la file active.
9. Le portail d'attente de la personne reçoit l'état refusé et le motif selon le mécanisme existant.
10. Aucun message `E-mail envoyé` ou `Notification envoyée` n'est affiché tant qu'un service réel ne le garantit.

## P-ADM-05 - Dossier déjà traité par un autre administrateur

1. Deux administrateurs peuvent avoir chargé le même dossier.
2. Le premier prend une décision.
3. Le second tente une action avec une version devenue obsolète.
4. Le serveur refuse la commande par conflit de version ou état déjà décidé.
5. L'UI affiche : `Ce dossier a été traité par un autre membre de l'équipe.`
6. Action : `Actualiser le dossier`.
7. Aucune seconde décision n'est envoyée automatiquement.

## P-ADM-06 - Pièce inaccessible

1. Le dossier charge.
2. Le document privé ne peut pas être lu ou l'URL signée a expiré.
3. Le bloc pièce affiche l'erreur sans faire tomber toute la page.
4. Action : `Recharger la pièce`.
5. Les actions de décision restent désactivées si la pièce est un prérequis serveur.
6. Aucune URL brute ou erreur de stockage n'est exposée.

## P-ADM-07 - Prérequis genre admin

1. Claude vérifie d'abord la raison réelle du prérequis.
2. Si la règle n'est pas justifiée, le blocage est corrigé comme défaut technique.
3. Si la règle est justifiée, `ADM-02` affiche un état bloquant clair.
4. Texte : `Votre profil doit être complété avant de consulter les dossiers.`
5. Action : `Compléter mon profil`.
6. L'action ouvre `/compte/profil`.
7. Après enregistrement serveur, le retour rouvre la file.
8. Aucun second formulaire de genre n'est créé dans `ADM-02`.

---

# 9. Écran ADM-02A - Dossiers à valider

**Identifiant :** ADM-02A  
**Nom visible :** Dossiers à valider  
**Route canonique :** `/admin/personnes/dossiers`  
**Écran parent :** domaine Personnes ou Accueil admin  
**Destination active :** Personnes

## 9.1 Objectif unique

Permettre à l'administrateur de choisir le prochain dossier réellement prêt à être revu.

## 9.2 Action principale

Aucune action pleine persistante.

L'interaction principale est la sélection d'un dossier dans la file.

## 9.3 Actions secondaires

- filtrer si le volume le justifie ;
- actualiser ;
- ouvrir un dossier.

## 9.4 Disposition mobile, 390 x 844

AdminShell en mode tiroir.

Ordre :

1. en-tête de page `Dossiers à valider` ;
2. sous-texte `Examinez les dossiers prêts pour une décision.` ;
3. compteur textuel si le serveur fournit un total fiable, format `12 dossiers en attente` ;
4. filtres compacts si utiles ;
5. liste groupée unique ;
6. chaque ligne montre seulement :
   - prénom et nom ;
   - type de dossier, `Enseignant` ou libellé réel du rôle ;
   - ancienneté lisible si fournie ;
   - état technique utile, jamais code interne ;
   - chevron ;
7. retour et coquille admin toujours accessibles.

Aucune grande carte par dossier.

Une seule carte groupée avec filets internes.

## 9.5 Disposition tablette, 768

Rail admin.

PROPOSITION :

- colonne file 300 à 340 dp ;
- panneau de détail vide à droite tant qu'aucun dossier n'est sélectionné ;
- si largeur insuffisante après agrandissement du texte, repasser en navigation liste -> détail ;
- ne jamais maintenir deux colonnes écrasées.

## 9.6 Disposition ordinateur, 1440

Barre latérale admin 288.

Vraie version bureau.

PROPOSITION validable selon standards 2026 :

- zone de contenu avec respiration 32 ;
- colonne file entre 320 et 360 ;
- détail sélectionné occupe le reste ;
- aucun contenu principal étiré au-delà d'une largeur lisible ;
- filtres en ligne avec cibles souris, hauteur compacte conforme au design system ;
- hover sur lignes ;
- focus clavier visible ;
- flèches clavier seulement si un pattern existant le supporte ;
- Tab traverse filtres, file et actions ;
- pas de boutons 72 dp conçus pour le pouce.

## 9.7 Textes visibles

Titre : `Dossiers à valider`

Sous-titre : `Examinez les dossiers prêts pour une décision.`

Chargement : `Chargement des dossiers…`

Vide : `Aucun dossier n'attend de validation.`

Aide vide : `Les nouveaux dossiers apparaîtront ici lorsqu'ils seront prêts.`

Erreur : `Impossible de charger les dossiers.`

Action erreur : `Réessayer`

Hors ligne : `Vous êtes hors ligne. Les dossiers ne peuvent pas être actualisés.`

Action : `Réessayer`

Permission refusée : `Vous n'avez pas accès aux dossiers à valider.`

Filtre rôle, PROPOSITION si utile : `Type de dossier`

Options : utiliser uniquement les valeurs réellement supportées par le serveur.

Aucune valeur fictive n'est ajoutée.

## 9.8 États

- chargement initial ;
- contenu ;
- vide ;
- erreur globale ;
- hors ligne ;
- permission refusée ;
- actualisation ;
- filtre sans résultat ;
- dossier devenu indisponible après chargement ;
- dépendance genre admin, uniquement si la règle réelle subsiste.

## 9.9 Données

CONTRAT À VÉRIFIER OU CRÉER : `list_reviewable_dossiers`

Entrée :

- curseur ;
- filtre de type si supporté ;
- limite ;
- identité admin déduite de la session, jamais envoyée comme permission client.

Sortie minimale :

- `dossier_id`
- `subject_display_name`
- `subject_role`
- `submitted_at`
- `review_status`
- `revision`
- `has_identity_document`
- total ou `has_more` si disponible

Ne pas livrer le document complet dans la liste.

## 9.10 Critères d'acceptation

- Étant donné un admin autorisé, quand il ouvre Personnes puis `Dossiers à valider`, alors la file réelle s'affiche.
- Étant donné aucun dossier, alors aucun faux dossier de démonstration n'apparaît en production.
- Étant donné 200 % de texte, alors aucune ligne importante n'est tronquée sans accès au contenu.
- Étant donné un clic sur un dossier, alors le détail du même `dossier_id` s'ouvre.
- Étant donné un retour, alors position et filtres sont restaurés.

## 9.11 Références UX à valider

- Flutter adaptive/responsive ;
- Material 3 ;
- WCAG 2.2 AA ;
- Nielsen, visibilité d'état ;
- Jakob, conventions de liste bureau ;
- Fitts pour cibles souris et tactiles selon format.

---

# 10. Écran ADM-02B - Revue du dossier

**Identifiant :** ADM-02B  
**Nom visible :** Dossier de {prénom} {nom}  
**Route :** conserver la route existante si le code sélectionne un dossier localement. Si une route de détail existe déjà, la réutiliser. Ne pas créer un doublon sans besoin.  
**Parent :** ADM-02A  
**Destination active :** Personnes

## 10.1 Objectif unique

Réunir les éléments strictement nécessaires pour prendre une décision fiable sur un dossier.

## 10.2 Action principale

`Valider le dossier`

## 10.3 Action secondaire sensible

`Refuser le dossier`

Le refus ne doit pas avoir le même poids visuel que l'action principale.

## 10.4 Disposition mobile

Ordre :

1. retour vers la file ;
2. en-tête avec nom et type de dossier ;
3. statut actuel ;
4. carte groupée `Identité et dossier` ;
5. carte groupée `Pièce d'identité` ;
6. carte groupée `Vérifications` ;
7. carte groupée `Accords et éléments soumis` uniquement si les données existent ;
8. zone de décision collée au bas de l'écran ;
9. `Valider le dossier` action pleine ;
10. `Refuser le dossier` action secondaire destructive.

Éviter de garder le document d'identité grand ouvert dans le flux vertical. L'ouverture du document se fait dans ADM-02C.

## 10.5 Disposition tablette

Deux zones seulement si la largeur le permet :

- contenu du dossier ;
- panneau décision ou document.

À 200 %, repasser en colonne.

## 10.6 Disposition ordinateur 1440

PROPOSITION :

- file persistante à gauche si l'écran est ouvert depuis ADM-02A ;
- contenu dossier au centre, largeur cible 640 à 760 ;
- panneau pièce / décision à droite, 360 à 420 ;
- au moins 32 de gouttière entre zones ;
- en-tête et actions restent visibles sans réduire le contenu ;
- la pièce peut être prévisualisée en vignette, mais le détail se fait dans le viewer ;
- les actions sont compactes, adaptées à la souris ;
- aucun grand bouton pleine largeur sur 1200 pixels.

## 10.7 Carte `Identité et dossier`

Un seul rectangle.

Lignes séparées par filets.

Afficher uniquement les champs réellement disponibles et nécessaires.

Libellés possibles selon données réelles :

- `Nom`
- `Prénom`
- `Type de dossier`
- `Date de dépôt`
- `État du dossier`

Si une donnée n'est pas fournie, ne pas inventer `Non renseigné` pour une donnée obligatoire. Utiliser un état bloquant si le serveur considère la donnée obligatoire.

## 10.8 Carte `Pièce d'identité`

Titre : `Pièce d'identité`

Contenu :

- type de pièce ;
- état de disponibilité ;
- aperçu neutre si autorisé ;
- action `Voir la pièce`.

Aucun chemin de stockage.

Aucune taille de bucket.

Aucune clé R2.

Aucun lien copiable exposant un token.

## 10.9 Carte `Vérifications`

Titre : `Vérifications`

Les trois vérifications existantes sont affichées dans l'ordre exact du code courant.

Chaque ligne comprend :

- libellé exact existant ;
- état ;
- contrôle ou indication appropriée ;
- éventuelle aide existante.

**AUCUN LIBELLÉ N'EST INVENTÉ DANS CE DOCUMENT.**

Claude remplit les textes exacts après lecture du code/i18n dans le journal du lot.

Si ces vérifications sont des cases administratives, elles ne sont jamais précochées localement.

Si elles sont calculées serveur, le frontend ne permet pas de les modifier.

## 10.10 Carte `Accords et éléments soumis`

Afficher seulement les preuves réellement disponibles :

- accusé de la notice ;
- contrat du rôle ;
- pièce reçue.

Ne pas reproduire le contrat intégral si un écran ou document dédié existe.

Utiliser un statut factuel.

Ne pas écrire `Signé` si le serveur ne fournit pas une acceptation versionnée.

## 10.11 Textes visibles

Titre dynamique : `Dossier de {prénom} {nom}`

Type : `Enseignant` ou valeur serveur traduite.

Section : `Identité et dossier`

Section : `Pièce d'identité`

Action : `Voir la pièce`

Section : `Vérifications`

Section optionnelle : `Accords et éléments soumis`

Action principale : `Valider le dossier`

Action secondaire : `Refuser le dossier`

Si validation impossible : `Ce dossier n'est pas encore prêt à être validé.`

Si détail indisponible : `Impossible de charger ce dossier.`

Action : `Réessayer`

Si déjà traité : `Ce dossier a déjà été traité.`

Action : `Retour aux dossiers`

Si traité ailleurs pendant la revue : `Ce dossier a été traité par un autre membre de l'équipe.`

Action : `Actualiser le dossier`

## 10.12 États

- chargement ;
- contenu nominal ;
- document en chargement ;
- document indisponible ;
- vérifications incomplètes ;
- accords manquants ;
- dossier non validable serveur ;
- décision en cours ;
- conflit concurrent ;
- dossier déjà décidé ;
- erreur de page ;
- permission refusée ;
- hors ligne ;
- prérequis admin manquant ;
- capacité serveur de décision indisponible.

## 10.13 Données

CONTRAT À VÉRIFIER OU CRÉER : `get_dossier_for_review`

Entrée :

- `dossier_id`

Sortie minimale :

- `dossier_id`
- `revision`
- identité minimale autorisée
- `subject_role`
- `submitted_at`
- `review_status`
- référence sécurisée vers la pièce
- type de pièce
- états des trois vérifications
- acceptations requises et versions si disponibles
- `can_validate`
- `validation_blockers[]`

Le serveur décide `can_validate`.

Le client ne reconstruit pas cette décision avec trois booléens locaux.

## 10.14 Critères d'acceptation

- Étant donné un dossier sélectionné, quand le détail est chargé, alors aucune donnée d'un autre dossier n'apparaît.
- Étant donné une pièce indisponible, alors `Valider le dossier` ne devient pas actif si le serveur exige cette pièce.
- Étant donné une vérification non satisfaite, alors le client n'autorise pas la validation si `can_validate=false`.
- Étant donné un dossier stale, alors le client ne remplace pas silencieusement la décision.
- Étant donné un admin sans permission, aucune donnée sensible n'est rendue.

---

# 11. Surface ADM-02C - Viewer sécurisé de pièce

**Identifiant :** ADM-02C  
**Nom visible :** Pièce d'identité  
**Type :** viewer local, modal plein écran ou panneau selon format  
**Parent :** ADM-02B

## 11.1 Objectif unique

Permettre la lecture de la pièce sans exposer son emplacement technique.

## 11.2 Disposition mobile

Plein écran focalisé :

- retour ;
- titre `Pièce d'identité` ;
- type de pièce ;
- zone d'image ou document ;
- zoom contrôlé ;
- action `Fermer`.

Pas de navigation globale au-dessus du document si elle réduit dangereusement la lisibilité.

## 11.3 Tablette

Viewer plein écran ou grand dialogue.

## 11.4 Desktop

Grand panneau ou dialogue centré avec :

- largeur suffisante ;
- fond neutre ;
- zoom ;
- rotation uniquement si le composant existant la supporte ;
- aucun téléchargement si ce droit n'est pas explicitement prévu ;
- focus piégé dans le dialogue ;
- Échap ferme le viewer si aucune action sensible n'est en cours.

## 11.5 Textes

Titre : `Pièce d'identité`

Chargement : `Chargement de la pièce…`

Erreur : `La pièce ne peut pas être affichée.`

Action : `Réessayer`

Action : `Fermer`

Lien expiré : `L'accès à cette pièce a expiré.`

Action : `Recharger la pièce`

## 11.6 Sécurité

- URL signée courte si l'architecture l'utilise ;
- pas de token dans logs ;
- pas de persistance locale non nécessaire ;
- pas de copie dans le bucket public ;
- pas d'image dans Sentry ;
- pas de données sensibles dans breadcrumbs ;
- cache navigateur désactivé si le service le permet ;
- RLS et politique storage contrôlées côté serveur ;
- le viewer n'est jamais accessible par URL publique autonome.

## 11.7 Critères d'acceptation

- Étant donné une pièce autorisée, quand l'admin ouvre le viewer, alors le document est lisible.
- Étant donné un token expiré, alors l'UI récupère une nouvelle autorisation sans révéler l'ancienne URL.
- Étant donné une fermeture, alors le focus revient à `Voir la pièce`.
- Étant donné un rôle non autorisé, alors aucun contenu du viewer n'est livré.

---

# 12. Surface ADM-02D - Refuser le dossier

**Identifiant :** ADM-02D  
**Nom visible :** Refuser le dossier  
**Type :** bottom sheet mobile, dialogue tablette et desktop  
**Parent :** ADM-02B

## 12.1 Objectif unique

Recueillir un motif clair avant une décision de refus.

## 12.2 Texte

Titre : `Refuser le dossier`

Corps : `Indiquez le motif qui sera affiché à la personne concernée.`

Champ : `Motif du refus`

Aide : `Expliquez ce qui doit être corrigé, sans donnée interne ni commentaire personnel.`

Erreur vide : `Indiquez le motif du refus.`

Action secondaire : `Annuler`

Action destructive : `Refuser le dossier`

Envoi : `Refus en cours…`

Erreur serveur : `Le dossier n'a pas pu être refusé.`

Action : `Réessayer`

Conflit : `Ce dossier a été traité par un autre membre de l'équipe.`

Action : `Actualiser le dossier`

## 12.3 Règles

Le motif est obligatoire.

Ne pas ajouter une taxonomie de motifs tant qu'elle n'existe pas dans le contrat.

Ne pas créer de note interne dans ce lot.

Ne pas écrire de motif automatique.

Ne pas inclure de détail médical, financier ou autre donnée non nécessaire.

## 12.4 Critères d'acceptation

- Étant donné un champ vide, quand l'admin tente de confirmer, alors le refus n'est pas envoyé.
- Étant donné un motif valide, quand le serveur confirme, alors le dossier quitte la file.
- Étant donné une erreur serveur, alors le motif saisi reste disponible pour reprise.
- Étant donné un conflit, alors aucune seconde décision n'est envoyée.

---

# 13. Surface ADM-02E - Confirmer la validation

**Identifiant :** ADM-02E  
**Nom visible :** Valider le dossier  
**Type :** dialogue de confirmation  
**Parent :** ADM-02B

## 13.1 Objectif unique

Éviter une validation accidentelle et rappeler la conséquence réelle.

## 13.2 Texte

Titre : `Valider ce dossier ?`

Corps enseignant, PROPOSITION : `Cette décision autorisera l'accès prévu pour ce compte lorsque le serveur l'aura confirmé.`

Ne pas promettre une notification.

Ne pas promettre une affectation de classe.

Ne pas promettre l'activation d'une photo publique.

Action secondaire : `Annuler`

Action principale : `Valider le dossier`

Envoi : `Validation en cours…`

Erreur : `Le dossier n'a pas pu être validé.`

Action : `Réessayer`

## 13.3 Règle atomique

La validation et l'effet d'accès correspondant doivent être traités par une commande serveur cohérente.

Le frontend ne doit pas :

1. marquer le dossier validé ;
2. puis exécuter une deuxième mutation indépendante pour rendre le compte actif ;
3. puis afficher un succès si la deuxième mutation échoue.

Si le backend actuel sépare ces actions, Claude doit documenter la dépendance et empêcher un faux succès.

## 13.4 Critères d'acceptation

- Étant donné `can_validate=false`, le dialogue ne peut pas être ouvert par un bouton actif.
- Étant donné un clic accidentel, `Annuler` ne modifie rien.
- Étant donné une réponse serveur confirmée, alors seulement l'UI affiche le succès.
- Étant donné un timeout sans résultat déterminable, l'UI n'affirme pas que le dossier est validé.

---

# 14. État de décision réussie

Il n'y a pas de page de succès autonome.

Une page autonome ajouterait une étape inutile dans un travail répétitif.

Comportement proposé :

- toast ou feedback non bloquant `Dossier validé.` ou `Dossier refusé.` seulement après confirmation serveur ;
- retrait du dossier de la file ;
- sélection du suivant sur desktop ;
- retour à la liste sur mobile ;
- compteur admin actualisé depuis le serveur.

Ne jamais afficher :

- `E-mail envoyé`
- `Notification envoyée`
- `Compte activé`
- `Enseignant prêt`
- `Classe attribuée`

sans réponse serveur qui garantit exactement cette conséquence.

---

# 15. Dépendance `genre de l'administrateur`

## 15.1 Vérification avant code

Claude doit retrouver :

- la condition exacte dans `dossiers_page.dart` ;
- le champ lu ;
- sa source ;
- toute RLS associée ;
- toute documentation métier associée ;
- le comportement en base pour un admin sans valeur ;
- le comportement pour un admin homme ou femme.

## 15.2 Si le prérequis est un bug frontend

PROPOSITION :

- supprimer le blocage ;
- ne pas demander de donnée personnelle inutile ;
- ajouter un test de non-régression ;
- documenter le défaut corrigé.

## 15.3 Si le prérequis est une règle métier réelle

Ne pas la modifier.

Rendre `/compte/profil` éditable pour ce seul champ si la sécurité l'autorise.

Dans ADM-02 afficher :

Titre : `Profil à compléter`

Texte : `Votre profil doit être complété avant de consulter les dossiers.`

Action : `Compléter mon profil`

Retour après succès : `/admin/personnes/dossiers`

Aucun formulaire duplicatif dans ADM-02.

---

# 16. Règles de confidentialité et sécurité

## 16.1 Séparation des identités

Une pièce KYC n'est jamais :

- photo de profil ;
- photo publique enseignant ;
- vignette de Classe ;
- portrait d'élève ;
- pièce jointe de messagerie ;
- ressource de bibliothèque.

## 16.2 Moindre privilège

L'API de revue ne retourne que les champs nécessaires.

L'administration n'accède pas aux pièces par un bucket public.

Les rôles enseignant, tuteur, élève, contrôleur et comptable ne peuvent pas utiliser le contrat de revue admin.

## 16.3 Audit

Chaque décision doit créer ou utiliser une trace serveur avec au minimum :

- dossier ;
- décision ;
- acteur autorisé ;
- date serveur ;
- version du dossier ;
- motif si refus ;
- résultat.

Ne pas journaliser le contenu de la pièce.

Ne pas journaliser le token de lecture.

## 16.4 Concurrence

Toute mutation sensible utilise :

- version attendue ;
- état attendu ;
- commande idempotente ou identifiant de commande si l'architecture le prévoit.

Erreur type : `stale_dossier`.

## 16.5 Déconnexion et retour

Une déconnexion ferme l'accès aux données immédiatement.

Le retour navigateur ne doit pas réafficher une pièce KYC depuis un cache persistant si la session n'est plus valide.

---

# 17. Contrats serveur proposés

Les noms sont des PROPOSITIONS. Claude doit préférer les RPC/services existants s'ils couvrent déjà le besoin.

## 17.1 `list_reviewable_dossiers`

Entrée :

- curseur ;
- limite ;
- filtre de rôle optionnel, seulement si supporté.

Sortie :

- éléments minimaux de file ;
- curseur suivant ;
- nombre total si fiable.

Erreurs :

- unauthorized ;
- forbidden ;
- temporarily_unavailable.

## 17.2 `get_dossier_for_review`

Entrée :

- dossier_id.

Sortie :

- détail minimal ;
- état ;
- version ;
- référence document ;
- trois vérifications ;
- accords ;
- `can_validate` ;
- blockers.

Erreurs :

- not_found ;
- forbidden ;
- stale ;
- temporarily_unavailable.

## 17.3 `request_kyc_document_view`

Entrée :

- dossier_id ;
- document_id.

Sortie :

- URL temporaire ou handle sécurisé ;
- expiration ;
- type MIME autorisé.

Erreurs :

- forbidden ;
- expired ;
- not_found ;
- unsupported_type ;
- temporarily_unavailable.

## 17.4 `decide_dossier`

Entrée :

- dossier_id ;
- expected_revision ;
- decision `approved|rejected` ;
- rejection_reason nullable uniquement si approved.

Sortie :

- final_review_status ;
- access_state si la commande est responsable de l'accès ;
- new_revision ;
- decided_at ;
- audit_event_id si exposable sans risque.

Erreurs :

- forbidden ;
- stale_dossier ;
- already_decided ;
- missing_required_check ;
- missing_required_acceptance ;
- document_unavailable ;
- cannot_activate ;
- temporarily_unavailable.

Règle : la réponse doit permettre au client de savoir ce qui est réellement acquis.

---

# 18. Copywriting du rôle

Registre : vouvoiement.

Ton : neutre, factuel, dense, sans froideur.

Les actions disent exactement l'effet.

## 18.1 Lexique retenu

Utiliser :

- Dossiers à valider
- Dossier
- Pièce d'identité
- Vérifications
- Valider le dossier
- Refuser le dossier
- Motif du refus
- En cours de vérification
- Profil à compléter

Éviter :

- KYC comme seul libellé visible si une formulation française suffit ;
- Approuver ;
- Rejeter ;
- OK ;
- Valider seul ;
- Refuser seul si le contexte peut être ambigu ;
- Erreur inconnue ;
- Opération réussie ;
- Notification envoyée sans preuve.

## 18.2 Avant / après

1. Avant : `Valider`  
   Après : `Valider le dossier`

2. Avant : `Refuser`  
   Après : `Refuser le dossier`

3. Avant : `Erreur`  
   Après : `Impossible de charger ce dossier.`

4. Avant : `Réessayez plus tard`  
   Après : `Réessayer`

5. Avant : `Aucune donnée`  
   Après : `Aucun dossier n'attend de validation.`

6. Avant : `Document`  
   Après : `Pièce d'identité`

7. Avant : `Utilisateur non autorisé`  
   Après : `Vous n'avez pas accès aux dossiers à valider.`

8. Avant : `Conflit`  
   Après : `Ce dossier a été traité par un autre membre de l'équipe.`

9. Avant : `Profil incomplet`  
   Après : `Votre profil doit être complété avant de consulter les dossiers.`

10. Avant : `Succès`  
    Après : `Dossier validé.`

---

# 19. Responsive et ergonomie par format

## 19.1 Mobile

- AdminShell en tiroir, jamais barre basse.
- Revue séquentielle.
- Liste puis détail.
- Viewer plein écran.
- Feuille basse pour refus.
- Confirmation modale pour validation.
- Cibles 48 dp minimum.
- Une seule action pleine.

## 19.2 Tablette

- rail admin ;
- file et détail si largeur utile réelle ;
- viewer latéral ou modal ;
- souris, clavier et tactile possibles ;
- ne pas supposer touch-only.

## 19.3 Web / ordinateur

Capture de référence obligatoire : 1440 x 900.

Web = vraie interface bureau.

Obligatoire :

- sidebar admin persistante 288 ;
- header avec recherche de navigation existante, notifications si réellement disponibles, compte ;
- gestion clair/sombre selon shell ;
- hover ;
- focus visible ;
- densité adaptée à la souris ;
- raccourcis seulement s'ils sont documentés ;
- larges zones de respiration ;
- colonnes exploitant la largeur sans étirer le texte ;
- file persistante + détail + viewer possible ;
- pas de composants mobiles géants ;
- pas de CTA pleine largeur si l'espace ne le justifie pas.

---

# 20. Accessibilité

Objectif : WCAG 2.2 AA.

Chaque écran doit respecter :

- contraste AA ;
- ordre de focus logique ;
- focus jamais masqué ;
- navigation clavier complète sur web ;
- labels accessibles sur icônes ;
- état jamais transmis par couleur seule ;
- messages d'erreur associés au composant ;
- texte à 200 % sans perte de fonctionnalité ;
- aucune information sensible uniquement dans une infobulle ;
- viewer accessible au clavier ;
- modal avec focus initial, boucle de focus, retour du focus ;
- réduction des animations ;
- taille de cible minimale compatible avec les standards actuels ;
- pas d'expiration client agressive pendant lecture d'une pièce. Seul le token peut expirer, avec mécanisme de renouvellement.

---

# 21. Maquettes à produire

Aucune maquette spécifique `ADM-02` n'existe dans les sources.

La verticale doit donc produire de nouvelles références, après validation des propositions UX.

## IMG-ADM-02A_desktop_sombre

Écran : file + détail de dossier sur desktop.  
Format : 1440 x 900.  
Thème : sombre.  
Priorité : obligatoire.

Doit montrer :

- coquille admin complète ;
- Personnes actif ;
- file à gauche ;
- dossier sélectionné au centre ;
- aperçu de pièce à droite ;
- vérifications ;
- zone de décision ;
- souris / web density ;
- beaucoup de respiration.

## IMG-ADM-02B_mobile_clair

Écran : file mobile.  
Format : 390 x 844.  
Thème : clair.

## IMG-ADM-02C_mobile_sombre

Écran : revue du dossier mobile.  
Format : 390 x 844.  
Thème : sombre.

## IMG-ADM-02D_desktop_sombre

Écran : refus avec dialogue, desktop.  
Format : 1440 x 900.  
Thème : sombre.

## IMG-ADM-02E_desktop_sombre

Écran : viewer KYC sécurisé, desktop.  
Format : 1440 x 900.  
Thème : sombre.

## Règle de réutilisation

Les composants de shell admin, boutons, champs, dialogue, grouped card, empty state, error state et viewer doivent être partagés.

Ne pas dessiner une nouvelle sidebar si la sidebar admin canonique existe déjà.

---

# 22. Recette fonctionnelle

Le lot n'est terminé que si tous les tests suivants sont prouvés.

## 22.1 Accès

- admin autorisé ouvre Personnes et atteint ADM-02 ;
- compteur Accueil ouvre la même route ;
- enseignant ne peut pas ouvrir ADM-02 ;
- tuteur ne peut pas ouvrir ADM-02 ;
- élève ne peut pas ouvrir ADM-02 ;
- contrôleur ne peut pas ouvrir ADM-02 ;
- comptable ne peut pas ouvrir ADM-02 sans permission explicite.

## 22.2 File

- file réelle ;
- vide réel ;
- pagination ou chargement progressif réel ;
- filtre ne fabrique pas de résultat ;
- position restaurée après retour.

## 22.3 Dossier

- bon dossier ;
- aucune fuite d'un autre dossier ;
- trois vérifications provenant du vrai contrat ;
- pièce correcte ;
- contrats/accusés uniquement si disponibles ;
- aucune donnée financière inutile.

## 22.4 Pièce

- lecture autorisée ;
- expiration gérée ;
- erreur gérée ;
- aucun secret dans URL visible/log ;
- aucun cache persistant après déconnexion.

## 22.5 Validation

- impossible si `can_validate=false` ;
- confirmation obligatoire ;
- double clic idempotent ;
- conflit concurrent géré ;
- succès uniquement après serveur ;
- file et compteur se mettent à jour.

## 22.6 Refus

- motif obligatoire ;
- motif conservé après erreur ;
- motif affichable dans portail d'attente ;
- aucune note interne inventée ;
- conflit concurrent géré.

## 22.7 Responsive

- 390 clair ;
- 390 sombre ;
- 768 ;
- 1440 clair ou sombre selon maquette ;
- 200 % texte ;
- clavier complet desktop ;
- hover et focus visibles.

## 22.8 Sécurité

- tests RLS ;
- tests storage ;
- tests d'expiration URL ;
- tests de session expirée ;
- tests de rôle ;
- tests d'audit ;
- aucune donnée KYC dans Sentry.

---

# 23. Given / When / Then de recette critique

## AC-01

Étant donné un administrateur autorisé,  
quand il ouvre `Personnes` puis `Dossiers à valider`,  
alors la file de dossiers réellement revue par le serveur apparaît.

## AC-02

Étant donné un dossier sans droit de lecture,  
quand l'identifiant est demandé directement,  
alors aucune donnée personnelle n'est livrée.

## AC-03

Étant donné une pièce KYC disponible,  
quand l'administrateur choisit `Voir la pièce`,  
alors un accès temporaire autorisé est utilisé et aucun chemin de stockage brut n'est affiché.

## AC-04

Étant donné `can_validate=false`,  
quand l'administrateur consulte le dossier,  
alors `Valider le dossier` n'envoie aucune mutation.

## AC-05

Étant donné un dossier validable,  
quand l'administrateur confirme `Valider le dossier`,  
alors le succès n'est affiché qu'après confirmation serveur.

## AC-06

Étant donné deux administrateurs sur le même dossier,  
quand le second agit après la décision du premier,  
alors il reçoit un conflit et aucune seconde décision n'est appliquée.

## AC-07

Étant donné un refus,  
quand aucun motif n'est saisi,  
alors aucune commande serveur n'est envoyée.

## AC-08

Étant donné une erreur réseau pendant une décision,  
quand le résultat serveur est inconnu,  
alors l'interface n'affirme pas que l'action a réussi.

## AC-09

Étant donné 200 % de texte sur desktop,  
quand l'utilisateur navigue au clavier,  
alors le focus reste visible et le contenu n'est pas masqué.

## AC-10

Étant donné un admin dont le genre est absent,  
quand Claude a prouvé qu'aucune règle métier ne dépend de cette donnée,  
alors l'absence du champ ne bloque plus la revue.

## AC-11

Étant donné une règle serveur réelle exigeant le genre,  
quand le profil est incomplet,  
alors ADM-02 renvoie vers l'unique `/compte/profil` au lieu de créer un formulaire local.

---

# 24. Ce que Claude doit absolument vérifier avant d'écrire du code

Checklist obligatoire :

- [ ] route réelle de `ADM-02` ;
- [ ] bouton réel depuis Personnes ;
- [ ] bouton réel depuis compteur Accueil ;
- [ ] trois libellés exacts des vérifications ;
- [ ] source de ces vérifications ;
- [ ] règle `can_validate` ou équivalent ;
- [ ] mécanisme actuel de décision ;
- [ ] atomicité validation + activation ;
- [ ] raison réelle du genre admin ;
- [ ] source et politique de stockage de la pièce ;
- [ ] méthode de lecture sécurisée ;
- [ ] RLS ;
- [ ] audit ;
- [ ] comportement concurrent ;
- [ ] portail d'attente après refus ;
- [ ] absence de notification réelle avant d'en promettre une ;
- [ ] distinction photo publique enseignant / pièce KYC ;
- [ ] composants existants réutilisables ;
- [ ] conformité 2026 documentée dans `UX_REVIEW_03_ADMIN_DOSSIERS.md`.

---

# 25. Hors périmètre

Ne pas construire ici :

- création globale de comptes du personnel ;
- suspension globale de comptes ;
- changement de rôle ;
- registre complet des personnes ;
- paiement ;
- diagnostic pédagogique ;
- attribution de classes ;
- photo publique enseignant ;
- onboarding enseignant complet ;
- messagerie ;
- push ;
- e-mails ;
- historique complet d'audit ;
- conservation des données ;
- suppression de compte ;
- rôle contrôleur ;
- finance ;
- administration complète.

Ces sujets appartiennent à leurs verticales.

---

# 26. Handoff vers `04_ENSEIGNANT.md`

Condition de sortie de ce lot :

un enseignant de test doit pouvoir avoir un dossier réellement revu et recevoir un état serveur exploitable par la porte d'accès.

`03` ne définit pas encore l'expérience complète après activation.

`04_ENSEIGNANT.md` définira :

- Premiers pas ;
- Journée ;
- marketplace / réservation de Classes ;
- Classes attribuées ;
- espace Classe ;
- préparation ;
- séance ;
- cahier ;
- travail ;
- signalements ;
- ressources ;
- photo publique ;
- absences et remplacement ;
- profil et préférences.

Claude ne doit pas anticiper ces écrans dans `03`.

---

# 27. Auto-contrôle

## 27.1 Surfaces spécifiées

1. ADM-02A Dossiers à valider
2. ADM-02B Revue du dossier
3. ADM-02C Viewer sécurisé de pièce
4. ADM-02D Refuser le dossier
5. ADM-02E Confirmer la validation
6. état intégré de décision réussie
7. dépendance intégrée de profil admin

## 27.2 Parcours couverts

1. entrée par Personnes
2. entrée par Accueil
3. revue enseignant
4. refus
5. conflit concurrent
6. pièce inaccessible
7. prérequis genre admin

## 27.3 Maquettes demandées

1. IMG-ADM-02A_desktop_sombre
2. IMG-ADM-02B_mobile_clair
3. IMG-ADM-02C_mobile_sombre
4. IMG-ADM-02D_desktop_sombre
5. IMG-ADM-02E_desktop_sombre

## 27.4 Règles vérifiées

- [x] aucune règle KYC non prouvée n'est inventée ;
- [x] les trois vérifications ne reçoivent pas de faux libellé ;
- [x] une fonction possède un endroit canonique ;
- [x] ADM-08 n'est pas dupliqué ;
- [x] `/compte/profil` n'est pas dupliqué ;
- [x] aucune notification inexistante n'est promise ;
- [x] aucun succès n'est local ;
- [x] KYC et photo publique restent séparés ;
- [x] le web est traité comme une vraie interface bureau ;
- [x] mobile, tablette et desktop sont explicités ;
- [x] clavier, souris, hover et focus sont couverts ;
- [x] WCAG 2.2 AA est imposé ;
- [x] Claude doit revalider les propositions contre les standards 2026 ;
- [x] les dérogations UX doivent être documentées ;
- [x] la sécurité prime sur la maquette ;
- [x] aucune URL de pièce sensible n'est exposée ;
- [x] la concurrence de décision est couverte ;
- [x] la décision serveur est attendue avant succès ;
- [x] le blocage genre admin est traité comme point à prouver, pas comme vérité métier ;
- [x] le handoff vers Enseignant est explicite ;
- [x] le périmètre est fermé.

---

# 28. Condition de définition de fini

Le lot `03_ADMIN_VALIDATION_DOSSIERS` est fini uniquement si :

1. un administrateur autorisé atteint la file depuis l'UI ;
2. un dossier réel est sélectionnable ;
3. la pièce réelle peut être lue selon une autorisation serveur ;
4. les trois vérifications réelles sont affichées ;
5. le dossier ne peut pas être validé contrairement au serveur ;
6. le refus exige un motif ;
7. les décisions sont atomiques ou leur dépendance backend est explicitement bloquante ;
8. la concurrence est gérée ;
9. l'audit existe ;
10. aucun autre rôle n'accède aux pièces ;
11. le blocage genre admin est soit justifié et résolu proprement, soit supprimé après preuve qu'il s'agit d'un défaut ;
12. les layouts 390, 768 et 1440 sont validés ;
13. le 1440 est une vraie interface desktop ;
14. l'audit UX 2026 est livré ;
15. les tests et preuves sont verts ou les dépendances bloquantes sont nommées sans faux succès.

Une fois ces quinze points atteints, on peut passer à `04_ENSEIGNANT.md` sans document de complétion pour `03`.


---

# ANNEXE 12 - Prompt maître des spécifications verticales

_Source : `PROMPT_MAITRE_CHATGPT.md`. Contenu conservé pour ne pas perdre les détails métier._


# PROMPT MAÎTRE : spécifications verticales de Rewayah Academy

# MISSION

Tu es à la fois directeur produit, designer UX/UI senior et rédacteur UX (copywriter) de Rewayah Academy : une application Flutter (Android, iOS, web) de cours de Coran en visio par classes stables (un groupe, un horaire récurrent, un enseignant attitré). Tu écris les SPÉCIFICATIONS VERTICALES de chaque rôle, puis tu dessines les maquettes qui manquent.

Tes documents seront exécutés à la lettre par des agents de développement (Claude Code) qui n'ont PAS d'autre source que toi et le dossier joint. Tout ce que tu omets ne sera pas construit. Tout ce qui est vague sera inventé par l'agent, ce qui a déjà causé plusieurs refontes complètes de l'application. Ton travail est donc la dernière barrière contre une nouvelle refonte.

# CONSIGNE D'AUTORITÉ (priorité absolue, relis-la avant chaque document)

1. EXHAUSTIVITÉ OBLIGATOIRE. Tu traites chaque rôle, chaque écran, chaque état, chaque bouton, chaque texte visible, ponctuation comprise. Interdits : « etc. », « et ainsi de suite », « similaire à l'écran X », « à définir », « par exemple » à la place d'un contenu réel, les résumés, les listes tronquées. Si un écran ressemble à un autre, tu le réécris en entier.
2. PAS DE COMPRESSION. Si tu approches la limite de longueur d'une réponse, tu t'arrêtes à la fin d'un écran complet et tu écris exactement : « SUITE AU PROCHAIN MESSAGE : <identifiant de l'écran suivant> ». Quand je réponds « continue », tu reprends à cet écran, avec le même niveau de détail que le premier écran. Le dernier écran d'un rôle est aussi détaillé que le premier.
3. AUTO-CONTRÔLE. Chaque document se termine par une section « Auto-contrôle » : nombre d'écrans, d'états, de textes, de maquettes, et la liste des règles de ce prompt cochées une à une. Une règle non respectée se corrige avant de livrer, elle ne se déclare pas.
4. HONNÊTETÉ. Tu ne connais pas le code. Tout fait sur l'existant vient du dossier joint, cité par sa section. Ce que tu proposes de nouveau est marqué « PROPOSITION ». Ce qui contredit une décision du dossier est marqué « CONFLIT : <décision> » avec ta justification, et n'est jamais appliqué en silence.
5. PLAN FERMÉ. Tes documents définissent la fin du travail pour chaque rôle. Toute idée hors périmètre va dans une section « Hors périmètre, pour plus tard », jamais dans les écrans.

# SOURCES ET ORDRE D'AUTORITÉ

1. Mes messages dans cette conversation.
2. Les décisions du directeur du dossier joint (sections « Décisions »).
3. Les spécifications canoniques résumées dans le dossier.
4. L'inventaire des écrans, des routes et de l'état du code du dossier.
5. Les référentiels reconnus de la communauté (liste plus bas).
6. Ton expertise.

Les maquettes existantes montrent la DISPOSITION (où se trouve chaque élément, chaque action, chaque route). Leurs couleurs ne font pas foi : la palette vient uniquement du système de design gelé. Leurs erreurs listées dans le dossier ne doivent jamais être reproduites.

# ORDRE DE TRAVAIL (un document par rôle, dans cet ordre)

0. Deux guides transverses, AVANT tout rôle : `00_GUIDE_UX_UI.md` et `00_GUIDE_COPYWRITING.md`.
1. `01_TUTEUR_COMPLEMENTS.md` : les écrans et états du tuteur qui n'ont pas encore de maquette (liste dans le dossier), les fonctions annoncées (recharge de solde, solde par enfant, ajout d'enfant revu), la planche « États particuliers et notices de présence ». Les écrans du tuteur déjà spécifiés sont EN COURS DE CONSTRUCTION : tu ne les réécris pas. Tu signales seulement leurs manques sous forme « PROPOSITION ».
2. `02_CLASSE_ET_VISIO.md` : priorité n° 1 du directeur. Un élève et un enseignant se rencontrent et se voient : entrée depuis la classe, salle unique, visio, présence, reconnexion, fin de séance, côté élève, côté enseignant, notices d'observation côté enseignant et côté enfant.
3. `03_ADMIN_VALIDATION_DOSSIERS.md` : l'administration revoit et valide les dossiers d'inscription (enseignants et familles), ce qui débloque le rôle enseignant.
4. `04_ENSEIGNANT.md`
5. `05_ELEVE_ADULTE.md`
6. `06_ELEVE_ENFANT.md` : Interface guidée, lecture limitée, gros éléments, libellés parlés.
7. `07_ADMINISTRATION.md` : tous les domaines du dossier.
8. `08_CONTROLEUR_ET_INVITE.md`
9. `09_FINANCE_ET_COMPTABLE.md`
10. `10_BIBLIOTHEQUE_ET_RESSOURCES.md`
11. `11_LECTEUR_DU_CORAN.md` : fidélité au Mushaf du complexe du roi Fahd (604 pages, 15 lignes, marques hizb, juz', rub', sajda, en-têtes de sourate, numéros de verset ornés), harakat toujours visibles, lecture de droite à gauche et de haut en bas, commandes de lecture, suivi de la classe. Le texte canonique n'est jamais modifié ni recopié par toi : tu décris l'interface, pas le texte sacré.
12. `12_PUBLIC_ET_LANDING.md` : pages publiques, landing web, référencement.
13. `13_PUBLICATION.md` : App Store, Play Store, web, Windows (voir la section Publication).

# MÉTHODE VERTICALE : STRUCTURE OBLIGATOIRE DE CHAQUE DOCUMENT DE RÔLE

## 1. Fiche du rôle
Qui il est (âge, situation, aisance numérique, langue, appareil), ce qu'il vient accomplir (les 3 à 5 tâches principales, classées), ce qu'il ne doit jamais voir, ses capacités (ce qu'il PEUT faire, jamais « parce qu'il a tel rôle »).

## 2. Navigation
Les destinations principales (4 au plus), identiques en nombre et en ordre sur mobile (barre basse), tablette (rail) et ordinateur (barre latérale). Chaque destination est justifiée par une tâche récurrente. Tout le reste est atteint depuis une destination, et le chemin est écrit.

## 3. Carte des fonctions (anti-doublon)
Un tableau : fonction | écran unique | route | emplacement exact dans l'écran | point d'entrée. Une fonction apparaît UNE fois. Les seuls raccourcis admis sont listés à part, avec le flux unique qu'ils ouvrent.

## 4. Parcours de bout en bout
Chaque parcours numéroté pas à pas : point de départ, action, écran suivant, retour possible, cas d'échec, sortie. Les parcours qui traversent plusieurs rôles (exemple : l'admin valide le dossier d'un enseignant, qui peut alors rejoindre sa classe) sont décrits des deux côtés.

## 5. Fiche écran (une par écran, SANS EXCEPTION, gabarit ci-dessous)
- **Identifiant** stable (`ROLE-NN`, exemple `ENS-04`), nom, route, écran parent, destination active dans la navigation.
- **Entrées** : quels boutons de quels écrans mènent ici. **Sorties** : où mène chaque action, y compris le retour.
- **Objectif unique** en une phrase ; **action principale** (libellé exact) ; actions secondaires.
- **Disposition mobile (390 x 844)** : liste ordonnée des blocs de haut en bas ; pour chaque bloc : composant du catalogue du dossier (jamais un composant inventé si un existant convient), contenu, alignement, espacement en jetons, position de chaque bouton.
- **Disposition tablette (768) et ordinateur (1440)** : colonnes, largeurs maximales, ce qui change. Jamais une version mobile étirée.
- **Textes** : TOUS les textes visibles, exacts, ponctuation comprise : titre, sous-titre, libellés, aides, placeholders, erreurs sous les champs, confirmations, textes d'accessibilité (lecteur d'écran).
- **États**, chacun avec ses textes exacts et son action : chargement, contenu, vide, erreur du bloc, erreur de la page, hors ligne, capacité serveur indisponible (jamais de faux succès), permission refusée, succès, et les états métier propres à l'écran.
- **Données** : chaque donnée affichée, sa source (contrat serveur nommé dans le dossier, ou « CONTRAT À CRÉER : entrée, sortie, erreurs »), son format (date, heure avec fuseau, durée, monnaie, nombre).
- **Règles** : ce que le serveur décide, ce que l'écran ne doit jamais afficher (données d'un autre foyer, d'un autre élève, notes internes, secrets).
- **Accessibilité** : ordre de lecture, cibles d'au moins 48 dp, texte agrandi à 200 % sans coupure, contraste AA, statut jamais porté par la couleur seule, contenu arabe de droite à gauche, mouvement réduit.
- **Critères d'acceptation** vérifiables sur capture, au format « Étant donné / Quand / Alors », dont au moins un qui part de la navigation et TOUCHE le bouton d'entrée.
- **Référence visuelle** : nom du fichier de maquette existant, ou identifiant de la nouvelle maquette (section 7).

## 6. Copywriting du rôle
Registre et ton (voir le plan imposé plus bas), lexique imposé et interdit propre au rôle, 10 exemples « avant / après » tirés du rôle, modèles de messages (erreur, confirmation, vide, attente, indisponible).

## 7. Maquettes
- Liste des maquettes EXISTANTES réutilisées (ne pas les redessiner).
- Liste des NOUVELLES maquettes, chacune avec : identifiant (`IMG-ROLE-NN`), écran et état, format (390 x 844 ou 1440 x 900), thème (clair, sombre), puis une DESCRIPTION TEXTUELLE complète (grille, blocs dans l'ordre, textes exacts, composants, états), puis l'image générée.
- Règles de dessin : uniquement les couleurs, polices (DM Sans pour les titres, Plus Jakarta Sans pour tout le reste), rayons et espacements du système gelé ; textes réels de la spec, jamais de faux texte ; jamais de texte arabe sauf s'il est fourni tel quel dans le dossier ; aucune donnée illustrative présentée comme une règle (noms, dates, prix, compteurs) ; respect des règles d'éthique visuelle du dossier ; aucune barre d'état ni décor de planche sur l'écran lui-même.
- Si tu ne peux pas générer une image avec exactitude (textes lisibles, bonne police), livre sa description textuelle complète et marque « IMAGE À PRODUIRE » : une description exacte vaut mieux qu'une image fausse.

## 8. Dépendances serveur
Chaque capacité serveur nécessaire au rôle : nom proposé, entrée, sortie, erreurs, règle d'accès, écran concerné.

## 9. Recette du rôle
La liste des vérifications de bout en bout qui prouvent que le rôle est terminé.

## 10. Hors périmètre, pour plus tard

## 11. Auto-contrôle

# LOGIQUES UX/UI À APPLIQUER ET À CITER

Appuie chaque choix de disposition sur un référentiel reconnu, cité par son nom dans la fiche écran quand il décide quelque chose : Material Design 3 (Android, web), Apple Human Interface Guidelines (iOS), WCAG 2.2 niveau AA, les 10 heuristiques de Nielsen, les lois de l'UX (Fitts, Hick, Jakob, proximité, Miller), les recherches Baymard sur les formulaires, le GOV.UK Design System (langage simple, une question par page quand c'est utile, messages d'erreur), les bonnes pratiques Nielsen Norman Group pour les états vides et les messages d'erreur. `00_GUIDE_UX_UI.md` rassemble ces règles une fois pour toutes, avec la règle appliquée à Rewayah pour chacune.

Règles du directeur, non négociables :
- un titre, une tâche et une seule action pleine par écran ;
- une carte qui regroupe plusieurs éléments est UN seul rectangle, séparé en lignes par de fins filets ; jamais un rectangle par ligne, jamais des rectangles collés ;
- navigation, retour et déconnexion toujours accessibles, aucune impasse ;
- le web est une vraie version ordinateur ;
- rien n'est affiché comme fait, réussi ou disponible sans que le serveur le garantisse ;
- une fonction a un seul endroit.

# PLAN DE COPYWRITING IMPOSÉ (écrit en détail dans `00_GUIDE_COPYWRITING.md`)

Langue : français, niveau de lecture simple (phrases de 20 mots au plus, un message = une idée), typographie française (espace fine insécable avant « ? ! : ; », guillemets « », apostrophe ’). Aucun emoji. Aucun tiret cadratin : utilise la virgule, les deux-points ou une nouvelle phrase. Aucun code interne visible.

Registres par rôle (à respecter, et à signaler en « CONFLIT » si tu penses devoir les changer) :
| Rôle | Registre | Ton |
|---|---|---|
| Tuteur, famille | vouvoiement | chaleureux, rassurant, concret, jamais culpabilisant |
| Élève adulte | vouvoiement | encourageant, respectueux, orienté progrès |
| Élève enfant (Interface guidée) | tutoiement bienveillant | phrases de 10 mots au plus, verbes d'action, pictogramme et libellé ensemble, libellé parlé disponible |
| Enseignant | vouvoiement | professionnel, précis, orienté action, vocabulaire pédagogique autorisé |
| Administration, contrôle, finance | vouvoiement | neutre, factuel, dense, termes métier exacts, conséquences des actions explicites |

Lexique imposé : « Classe » (jamais « groupe » à l'écran), « Séance », « Sayyid » / « Sayyida » pour les enseignants dans l'espace de cours, « Interface guidée », « Ajouter un profil élève », « Séance en direct ». Lexique interdit : « Session », « Cours en cours », « Ajouter enfant », « mode enfant », « matching », les codes internes. Un bouton dit exactement ce qu'il fait. Une erreur dit ce qui s'est passé et comment reprendre, sans excuse vague. Aucune promesse de date (« bientôt »). Formules religieuses : proposer, marquer « PROPOSITION », jamais imposer.

# PUBLICATION (`13_PUBLICATION.md`)

Tout ce qu'il faut pour publier : fiches App Store et Play Store (textes, captures à produire par format, mots-clés), catégorie et classement d'âge, règles spécifiques aux applications utilisées par des enfants (Apple Kids Category, programme Google Families, RGPD pour les mineurs et consentement parental, COPPA si des familles américaines sont visées), étiquettes de confidentialité (App Privacy, Data safety), suppression de compte depuis l'application (exigée par les deux stores), notes pour les relecteurs des stores (compte de démonstration, visio), mentions légales et politique de confidentialité à écrire, e-mails et notifications transactionnels (textes exacts), page web publique et référencement, publication Windows. Chaque exigence cite la règle du store ou du texte qui l'impose, et marque « À VÉRIFIER » ce qui peut avoir changé depuis ta date de connaissance.

# FORMAT DE LIVRAISON

- Un fichier Markdown téléchargeable par document, nommé comme dans l'ordre de travail, avec un en-tête : titre, version (V1), date, statut « PROPOSITION À VALIDER PAR LE DIRECTEUR ».
- Titres Markdown, tableaux, listes numérotées ; pas de HTML.
- Identifiants stables (`ROLE-NN`, `IMG-ROLE-NN`) réutilisés partout pour que les agents puissent cocher chaque élément.
- Les images générées sont livrées à part, nommées par leur identifiant (`IMG-ENS-04_mobile_clair.png`).
- Dans chaque conversation, tu produis SEULEMENT le document demandé dans le premier message, en suivant l'ordre de travail ci-dessus. Les guides 00 déjà livrés font partie des fichiers du projet et s'imposent aux documents suivants.


---

# ANNEXE 13 - Prompt multi-rôles et exigences d’exhaustivité

_Source : `PROMPT_CHATGPT_SPECS_VERTICALES.md`. Contenu conservé pour ne pas perdre les détails métier._


# Prompt pour ChatGPT : spécifications verticales de tous les rôles de Rewayah Academy

Mode d'emploi pour le directeur :
1. Ouvre une nouvelle conversation ChatGPT (le modèle le plus puissant disponible, avec génération d'images).
2. Joins le fichier `DOSSIER_POUR_CHATGPT.md` (même dossier que ce prompt) et, pour le rôle Tuteur, les maquettes existantes du dossier `lancement/tutuor image/`.
3. Colle tout le texte du bloc ci-dessous.
4. Quand ChatGPT s'arrête avec « SUITE AU PROCHAIN MESSAGE », réponds seulement : `continue`.
5. Télécharge chaque fichier Markdown et chaque image livrés, et range-les sur le poste A dans `D:\RA _APP\specs chatgpt\<numéro>_<rôle>\`. Préviens Claude : il les publie pour tous les agents et les transforme en étapes du tableau de suivi.

```text
# MISSION

Tu es à la fois directeur produit, designer UX/UI senior et rédacteur UX (copywriter) de Rewayah Academy : une application Flutter (Android, iOS, web) de cours de Coran en visio par classes stables (un groupe, un horaire récurrent, un enseignant attitré). Tu écris les SPÉCIFICATIONS VERTICALES de chaque rôle, puis tu dessines les maquettes qui manquent.

Tes documents seront exécutés à la lettre par des agents de développement (Claude Code) qui n'ont PAS d'autre source que toi et le dossier joint. Tout ce que tu omets ne sera pas construit. Tout ce qui est vague sera inventé par l'agent, ce qui a déjà causé plusieurs refontes complètes de l'application. Ton travail est donc la dernière barrière contre une nouvelle refonte.

# CONSIGNE D'AUTORITÉ (priorité absolue, relis-la avant chaque document)

1. EXHAUSTIVITÉ OBLIGATOIRE. Tu traites chaque rôle, chaque écran, chaque état, chaque bouton, chaque texte visible, ponctuation comprise. Interdits : « etc. », « et ainsi de suite », « similaire à l'écran X », « à définir », « par exemple » à la place d'un contenu réel, les résumés, les listes tronquées. Si un écran ressemble à un autre, tu le réécris en entier.
2. PAS DE COMPRESSION. Si tu approches la limite de longueur d'une réponse, tu t'arrêtes à la fin d'un écran complet et tu écris exactement : « SUITE AU PROCHAIN MESSAGE : <identifiant de l'écran suivant> ». Quand je réponds « continue », tu reprends à cet écran, avec le même niveau de détail que le premier écran. Le dernier écran d'un rôle est aussi détaillé que le premier.
3. AUTO-CONTRÔLE. Chaque document se termine par une section « Auto-contrôle » : nombre d'écrans, d'états, de textes, de maquettes, et la liste des règles de ce prompt cochées une à une. Une règle non respectée se corrige avant de livrer, elle ne se déclare pas.
4. HONNÊTETÉ. Tu ne connais pas le code. Tout fait sur l'existant vient du dossier joint, cité par sa section. Ce que tu proposes de nouveau est marqué « PROPOSITION ». Ce qui contredit une décision du dossier est marqué « CONFLIT : <décision> » avec ta justification, et n'est jamais appliqué en silence.
5. PLAN FERMÉ. Tes documents définissent la fin du travail pour chaque rôle. Toute idée hors périmètre va dans une section « Hors périmètre, pour plus tard », jamais dans les écrans.

# SOURCES ET ORDRE D'AUTORITÉ

1. Mes messages dans cette conversation.
2. Les décisions du directeur du dossier joint (sections « Décisions »).
3. Les spécifications canoniques résumées dans le dossier.
4. L'inventaire des écrans, des routes et de l'état du code du dossier.
5. Les référentiels reconnus de la communauté (liste plus bas).
6. Ton expertise.

Les maquettes existantes montrent la DISPOSITION (où se trouve chaque élément, chaque action, chaque route). Leurs couleurs ne font pas foi : la palette vient uniquement du système de design gelé. Leurs erreurs listées dans le dossier ne doivent jamais être reproduites.

# ORDRE DE TRAVAIL (un document par rôle, dans cet ordre)

0. Deux guides transverses, AVANT tout rôle : `00_GUIDE_UX_UI.md` et `00_GUIDE_COPYWRITING.md`.
1. `01_TUTEUR_COMPLEMENTS.md` : les écrans et états du tuteur qui n'ont pas encore de maquette (liste dans le dossier), les fonctions annoncées (recharge de solde, solde par enfant, ajout d'enfant revu), la planche « États particuliers et notices de présence ». Les écrans du tuteur déjà spécifiés sont EN COURS DE CONSTRUCTION : tu ne les réécris pas. Tu signales seulement leurs manques sous forme « PROPOSITION ».
2. `02_CLASSE_ET_VISIO.md` : priorité n° 1 du directeur. Un élève et un enseignant se rencontrent et se voient : entrée depuis la classe, salle unique, visio, présence, reconnexion, fin de séance, côté élève, côté enseignant, notices d'observation côté enseignant et côté enfant.
3. `03_ADMIN_VALIDATION_DOSSIERS.md` : l'administration revoit et valide les dossiers d'inscription (enseignants et familles), ce qui débloque le rôle enseignant.
4. `04_ENSEIGNANT.md`
5. `05_ELEVE_ADULTE.md`
6. `06_ELEVE_ENFANT.md` : Interface guidée, lecture limitée, gros éléments, libellés parlés.
7. `07_ADMINISTRATION.md` : tous les domaines du dossier.
8. `08_CONTROLEUR_ET_INVITE.md`
9. `09_FINANCE_ET_COMPTABLE.md`
10. `10_BIBLIOTHEQUE_ET_RESSOURCES.md`
11. `11_LECTEUR_DU_CORAN.md` : fidélité au Mushaf du complexe du roi Fahd (604 pages, 15 lignes, marques hizb, juz', rub', sajda, en-têtes de sourate, numéros de verset ornés), harakat toujours visibles, lecture de droite à gauche et de haut en bas, commandes de lecture, suivi de la classe. Le texte canonique n'est jamais modifié ni recopié par toi : tu décris l'interface, pas le texte sacré.
12. `12_PUBLIC_ET_LANDING.md` : pages publiques, landing web, référencement.
13. `13_PUBLICATION.md` : App Store, Play Store, web, Windows (voir la section Publication).

# MÉTHODE VERTICALE : STRUCTURE OBLIGATOIRE DE CHAQUE DOCUMENT DE RÔLE

## 1. Fiche du rôle
Qui il est (âge, situation, aisance numérique, langue, appareil), ce qu'il vient accomplir (les 3 à 5 tâches principales, classées), ce qu'il ne doit jamais voir, ses capacités (ce qu'il PEUT faire, jamais « parce qu'il a tel rôle »).

## 2. Navigation
Les destinations principales (4 au plus), identiques en nombre et en ordre sur mobile (barre basse), tablette (rail) et ordinateur (barre latérale). Chaque destination est justifiée par une tâche récurrente. Tout le reste est atteint depuis une destination, et le chemin est écrit.

## 3. Carte des fonctions (anti-doublon)
Un tableau : fonction | écran unique | route | emplacement exact dans l'écran | point d'entrée. Une fonction apparaît UNE fois. Les seuls raccourcis admis sont listés à part, avec le flux unique qu'ils ouvrent.

## 4. Parcours de bout en bout
Chaque parcours numéroté pas à pas : point de départ, action, écran suivant, retour possible, cas d'échec, sortie. Les parcours qui traversent plusieurs rôles (exemple : l'admin valide le dossier d'un enseignant, qui peut alors rejoindre sa classe) sont décrits des deux côtés.

## 5. Fiche écran (une par écran, SANS EXCEPTION, gabarit ci-dessous)
- **Identifiant** stable (`ROLE-NN`, exemple `ENS-04`), nom, route, écran parent, destination active dans la navigation.
- **Entrées** : quels boutons de quels écrans mènent ici. **Sorties** : où mène chaque action, y compris le retour.
- **Objectif unique** en une phrase ; **action principale** (libellé exact) ; actions secondaires.
- **Disposition mobile (390 x 844)** : liste ordonnée des blocs de haut en bas ; pour chaque bloc : composant du catalogue du dossier (jamais un composant inventé si un existant convient), contenu, alignement, espacement en jetons, position de chaque bouton.
- **Disposition tablette (768) et ordinateur (1440)** : colonnes, largeurs maximales, ce qui change. Jamais une version mobile étirée.
- **Textes** : TOUS les textes visibles, exacts, ponctuation comprise : titre, sous-titre, libellés, aides, placeholders, erreurs sous les champs, confirmations, textes d'accessibilité (lecteur d'écran).
- **États**, chacun avec ses textes exacts et son action : chargement, contenu, vide, erreur du bloc, erreur de la page, hors ligne, capacité serveur indisponible (jamais de faux succès), permission refusée, succès, et les états métier propres à l'écran.
- **Données** : chaque donnée affichée, sa source (contrat serveur nommé dans le dossier, ou « CONTRAT À CRÉER : entrée, sortie, erreurs »), son format (date, heure avec fuseau, durée, monnaie, nombre).
- **Règles** : ce que le serveur décide, ce que l'écran ne doit jamais afficher (données d'un autre foyer, d'un autre élève, notes internes, secrets).
- **Accessibilité** : ordre de lecture, cibles d'au moins 48 dp, texte agrandi à 200 % sans coupure, contraste AA, statut jamais porté par la couleur seule, contenu arabe de droite à gauche, mouvement réduit.
- **Critères d'acceptation** vérifiables sur capture, au format « Étant donné / Quand / Alors », dont au moins un qui part de la navigation et TOUCHE le bouton d'entrée.
- **Référence visuelle** : nom du fichier de maquette existant, ou identifiant de la nouvelle maquette (section 7).

## 6. Copywriting du rôle
Registre et ton (voir le plan imposé plus bas), lexique imposé et interdit propre au rôle, 10 exemples « avant / après » tirés du rôle, modèles de messages (erreur, confirmation, vide, attente, indisponible).

## 7. Maquettes
- Liste des maquettes EXISTANTES réutilisées (ne pas les redessiner).
- Liste des NOUVELLES maquettes, chacune avec : identifiant (`IMG-ROLE-NN`), écran et état, format (390 x 844 ou 1440 x 900), thème (clair, sombre), puis une DESCRIPTION TEXTUELLE complète (grille, blocs dans l'ordre, textes exacts, composants, états), puis l'image générée.
- Règles de dessin : uniquement les couleurs, polices (DM Sans pour les titres, Plus Jakarta Sans pour tout le reste), rayons et espacements du système gelé ; textes réels de la spec, jamais de faux texte ; jamais de texte arabe sauf s'il est fourni tel quel dans le dossier ; aucune donnée illustrative présentée comme une règle (noms, dates, prix, compteurs) ; respect des règles d'éthique visuelle du dossier ; aucune barre d'état ni décor de planche sur l'écran lui-même.
- Si tu ne peux pas générer une image avec exactitude (textes lisibles, bonne police), livre sa description textuelle complète et marque « IMAGE À PRODUIRE » : une description exacte vaut mieux qu'une image fausse.

## 8. Dépendances serveur
Chaque capacité serveur nécessaire au rôle : nom proposé, entrée, sortie, erreurs, règle d'accès, écran concerné.

## 9. Recette du rôle
La liste des vérifications de bout en bout qui prouvent que le rôle est terminé.

## 10. Hors périmètre, pour plus tard

## 11. Auto-contrôle

# LOGIQUES UX/UI À APPLIQUER ET À CITER

Appuie chaque choix de disposition sur un référentiel reconnu, cité par son nom dans la fiche écran quand il décide quelque chose : Material Design 3 (Android, web), Apple Human Interface Guidelines (iOS), WCAG 2.2 niveau AA, les 10 heuristiques de Nielsen, les lois de l'UX (Fitts, Hick, Jakob, proximité, Miller), les recherches Baymard sur les formulaires, le GOV.UK Design System (langage simple, une question par page quand c'est utile, messages d'erreur), les bonnes pratiques Nielsen Norman Group pour les états vides et les messages d'erreur. `00_GUIDE_UX_UI.md` rassemble ces règles une fois pour toutes, avec la règle appliquée à Rewayah pour chacune.

Règles du directeur, non négociables :
- un titre, une tâche et une seule action pleine par écran ;
- une carte qui regroupe plusieurs éléments est UN seul rectangle, séparé en lignes par de fins filets ; jamais un rectangle par ligne, jamais des rectangles collés ;
- navigation, retour et déconnexion toujours accessibles, aucune impasse ;
- le web est une vraie version ordinateur ;
- rien n'est affiché comme fait, réussi ou disponible sans que le serveur le garantisse ;
- une fonction a un seul endroit.

# PLAN DE COPYWRITING IMPOSÉ (écrit en détail dans `00_GUIDE_COPYWRITING.md`)

Langue : français, niveau de lecture simple (phrases de 20 mots au plus, un message = une idée), typographie française (espace fine insécable avant « ? ! : ; », guillemets « », apostrophe ’). Aucun emoji. Aucun tiret cadratin : utilise la virgule, les deux-points ou une nouvelle phrase. Aucun code interne visible.

Registres par rôle (à respecter, et à signaler en « CONFLIT » si tu penses devoir les changer) :
| Rôle | Registre | Ton |
|---|---|---|
| Tuteur, famille | vouvoiement | chaleureux, rassurant, concret, jamais culpabilisant |
| Élève adulte | vouvoiement | encourageant, respectueux, orienté progrès |
| Élève enfant (Interface guidée) | tutoiement bienveillant | phrases de 10 mots au plus, verbes d'action, pictogramme et libellé ensemble, libellé parlé disponible |
| Enseignant | vouvoiement | professionnel, précis, orienté action, vocabulaire pédagogique autorisé |
| Administration, contrôle, finance | vouvoiement | neutre, factuel, dense, termes métier exacts, conséquences des actions explicites |

Lexique imposé : « Classe » (jamais « groupe » à l'écran), « Séance », « Sayyid » / « Sayyida » pour les enseignants dans l'espace de cours, « Interface guidée », « Ajouter un profil élève », « Séance en direct ». Lexique interdit : « Session », « Cours en cours », « Ajouter enfant », « mode enfant », « matching », les codes internes. Un bouton dit exactement ce qu'il fait. Une erreur dit ce qui s'est passé et comment reprendre, sans excuse vague. Aucune promesse de date (« bientôt »). Formules religieuses : proposer, marquer « PROPOSITION », jamais imposer.

# PUBLICATION (`13_PUBLICATION.md`)

Tout ce qu'il faut pour publier : fiches App Store et Play Store (textes, captures à produire par format, mots-clés), catégorie et classement d'âge, règles spécifiques aux applications utilisées par des enfants (Apple Kids Category, programme Google Families, RGPD pour les mineurs et consentement parental, COPPA si des familles américaines sont visées), étiquettes de confidentialité (App Privacy, Data safety), suppression de compte depuis l'application (exigée par les deux stores), notes pour les relecteurs des stores (compte de démonstration, visio), mentions légales et politique de confidentialité à écrire, e-mails et notifications transactionnels (textes exacts), page web publique et référencement, publication Windows. Chaque exigence cite la règle du store ou du texte qui l'impose, et marque « À VÉRIFIER » ce qui peut avoir changé depuis ta date de connaissance.

# FORMAT DE LIVRAISON

- Un fichier Markdown téléchargeable par document, nommé comme dans l'ordre de travail, avec un en-tête : titre, version (V1), date, statut « PROPOSITION À VALIDER PAR LE DIRECTEUR ».
- Titres Markdown, tableaux, listes numérotées ; pas de HTML.
- Identifiants stables (`ROLE-NN`, `IMG-ROLE-NN`) réutilisés partout pour que les agents puissent cocher chaque élément.
- Les images générées sont livrées à part, nommées par leur identifiant (`IMG-ENS-04_mobile_clair.png`).
- Commence maintenant par `00_GUIDE_UX_UI.md`, puis `00_GUIDE_COPYWRITING.md`, puis `01_TUTEUR_COMPLEMENTS.md`. Avant d'écrire, résume en 10 lignes ce que tu as compris du dossier joint et liste les documents joints que tu n'arrives pas à lire.
```


---

# ANNEXE 14 - Guide de production des spécifications

_Source : `GUIDE_CHATGPT_PAS_A_PAS.md`. Contenu conservé pour ne pas perdre les détails métier._


# Faire produire toutes les spécifications par ChatGPT (web), pas à pas

ChatGPT web n'a pas accès à GitHub ni à ton ordinateur : tu lui donnes les fichiers une seule fois, il te rend des fichiers, tu les ranges dans un dossier, et Claude fait le reste (publication pour tous les agents, contrôle, transformation en étapes du tableau).

## 1. Préparer un « Projet » ChatGPT (une seule fois, 5 minutes)

Un Projet garde les fichiers et les instructions pour toutes ses conversations : tu n'as plus rien à recoller.

1. Dans ChatGPT (barre de gauche), clique **« Nouveau projet »**, nomme-le **Rewayah - Spécifications**.
2. Dans **Fichiers du projet**, ajoute :
   - `DOSSIER_POUR_CHATGPT.md` et `PROMPT_MAITRE_CHATGPT.md` (ce dossier) ;
   - les maquettes du dossier `D:\RA _APP\docs de lancement\tutuor image\` (et son sous-dossier `mobile`).
3. Dans **Instructions du projet**, colle exactement ceci :

```text
Tu travailles pour Rewayah Academy. Avant CHAQUE réponse, applique intégralement le fichier du projet PROMPT_MAITRE_CHATGPT.md (mission, consigne d'autorité, méthode verticale, gabarit de fiche écran, copywriting, maquettes, format de livraison) et appuie-toi uniquement sur DOSSIER_POUR_CHATGPT.md pour les faits sur l'existant.
Consigne d'autorité : exhaustivité totale (jamais « etc. », « similaire à », résumé ou liste tronquée) ; si la réponse devient trop longue, arrête-toi à la fin d'un écran complet et écris « SUITE AU PROCHAIN MESSAGE : <écran suivant> », puis reprends au même niveau de détail quand on te dit « continue » ; auto-contrôle chiffré à la fin de chaque document ; ce qui est nouveau est marqué PROPOSITION, ce qui contredit le dossier est marqué CONFLIT ; plan fermé.
Dans chaque conversation, tu ne produis QUE le document demandé dans le premier message. Tu le livres en fichier Markdown téléchargeable, et les maquettes en images nommées par leur identifiant.
```

Si ton offre ChatGPT n'a pas les Projets : ouvre une conversation par document, joins les deux fichiers et les maquettes utiles, et colle le texte ci-dessus avant le message du document.

## 2. Une conversation par document, dans cet ordre

Dans le Projet, ouvre une **nouvelle conversation pour chaque document** (une conversation trop longue fait oublier des consignes à ChatGPT). Colle le message de la ligne, puis réponds `continue` chaque fois qu'il écrit « SUITE AU PROCHAIN MESSAGE ».

| N° | Message à coller dans la nouvelle conversation | Ajoute ensuite aux fichiers du projet |
|---|---|---|
| 00 | `Produis 00_GUIDE_UX_UI.md puis, dans la même conversation, 00_GUIDE_COPYWRITING.md, selon PROMPT_MAITRE_CHATGPT.md. Commence par résumer en 10 lignes ce que tu as compris du dossier et liste les fichiers du projet que tu n'arrives pas à lire.` | les deux guides livrés |
| 01 | `Produis 01_TUTEUR_COMPLEMENTS.md (section D du dossier : écrans SM-01 à SM-52, planche 3, recharge et solde par enfant, ajout d'enfant revu), avec les nouvelles maquettes.` | - |
| 02 | `Produis 02_CLASSE_ET_VISIO.md : un élève et un enseignant se rencontrent et se voient (priorité n° 1 du directeur), côté élève et côté enseignant.` | - |
| 03 | `Produis 03_ADMIN_VALIDATION_DOSSIERS.md.` | - |
| 04 | `Produis 04_ENSEIGNANT.md.` | - |
| 05 | `Produis 05_ELEVE_ADULTE.md.` | - |
| 06 | `Produis 06_ELEVE_ENFANT.md (Interface guidée).` | - |
| 07 | `Produis 07_ADMINISTRATION.md (tous les domaines de la section E du dossier).` | - |
| 08 | `Produis 08_CONTROLEUR_ET_INVITE.md.` | - |
| 09 | `Produis 09_FINANCE_ET_COMPTABLE.md.` | - |
| 10 | `Produis 10_BIBLIOTHEQUE_ET_RESSOURCES.md.` | - |
| 11 | `Produis 11_LECTEUR_DU_CORAN.md.` | - |
| 12 | `Produis 12_PUBLIC_ET_LANDING.md.` | - |
| 13 | `Produis 13_PUBLICATION.md (stores, règles pour les applications utilisées par des enfants, logo et icône, e-mails, légal).` | - |

Tu peux lancer plusieurs conversations en parallèle une fois les guides 00 livrés et ajoutés au projet.

## 3. Rendre le travail à Claude

1. Télécharge chaque fichier `.md` et chaque image livrés.
2. Range-les sur le poste A dans `D:\RA _APP\specs chatgpt\<N°>_<nom>\` (exemple : `D:\RA _APP\specs chatgpt\04_ENSEIGNANT\`).
3. Écris à Claude : « specs 04 déposées ». Claude les contrôle (complétude, conflits avec les décisions, faisabilité), te signale les manques à redemander à ChatGPT, les publie pour tous les agents et coche la ligne correspondante du tableau de suivi (phase « Spécifications ChatGPT »).


---

# ANNEXE 15 - Spécifications finales des lots restants - 12 octobre 2026

_Source : `REWAYAH_SPECIFICATIONS_FINALES_LOTS_RESTANTS_2026-10-12.md`. Contenu conservé pour ne pas perdre les détails métier._


# REWAYAH ACADEMY
# CAHIER DES CHARGES CONSOLIDÉ - LOTS RESTANTS ET RECETTE INTÉGRALE

**Version :** 1.0 - 12 octobre 2026  
**Destination :** Claude Code, équipes frontend, intégration et revue ; coordination avec ChatGPT/Codex côté backend  
**Nature :** mandat global de conception et d'intégration par lots bornés, sans autorisation implicite d'intervenir en production  
**Statut :** spécifications consolidées ; les fonctionnalités ne sont pas réputées implémentées, raccordées ou recettées sans preuves.

> **Instruction de la direction :** ne plus fractionner la découverte produit en conversations interminables. Le présent dossier réunit les décisions connues, les écarts à vérifier et les scénarios permettant de terminer l'application. Les agents recherchent eux-mêmes les preuves dans les sources actives et résolvent les détails d'implémentation qui ne modifient pas une politique. **Un lot = une implémentation vérifiable ; ce document = une seule référence de mission.** Aucun retour au directeur pour des choix déjà tranchés.

---

## 00. Mandat exécutable et lignes rouges

### 00.1 Ce qui est commandé

Terminer et consolider les parcours restants de Rewayah Academy pour qu'une personne, une famille et les équipes puissent réellement accomplir leurs tâches, sans écran fictif, doublon fonctionnel, accès indu ou faux succès. La livraison couvre les rôles **tuteur/titulaire**, **second adulte autorisé**, **élève enfant (Interface guidée)**, **élève adulte autonome**, **enseignant**, **évaluateur et juré habilités**, **contrôleur**, **comptable**, **administration** et **direction habilitée**. Évaluateur et juré sont des **capabilities**, pas des rôles globaux à créer.

Comprend la mise en cohérence des modules transverses : identité, classes, visio et supports, pédagogie, progression, évaluations, attestations/certificats, communication, recherche, finance, catalogue public, site et opérationnalisation. La **priorité** va à la complétude des verticales réellement manquantes et aux chemins utilisateurs de bout en bout, non à la quantité de widgets produits.

### 00.2 Répartition des responsabilités en vigueur

La décision `docs/orchestration/COHABITATION.md` du 09/10/2026 prévaut sur les anciens prompts qui demandent à Claude de refaire tout le backend :

- **Claude Code :** audit et production UX/UI Flutter, routeur, ViewModels, états, réutilisation des composants, tests frontend, cohérence des parcours ; revue critique et validation contractuelle du backend à la fin de chaque verticale. Le lot Évaluations du 12/10 est **frontend only**.
- **ChatGPT/Codex backend :** migrations/RLS/RPC, Edge Functions, adaptateurs réels, projections métier, transactions, sécurité serveur, tests SQL et intégrations, selon branches réservées et accords de cohabitation.
- **Zone commune :** contrats de ports, schémas d'échange, erreurs, identifiants et dossiers de preuve ; chaque modification de frontière est enregistrée avant intervention.
- **Direction :** seule compétente pour ouvrir un périmètre de production, approuver une politique non décidée, autoriser un paiement réel, des données sensibles, un merge de production ou un lancement réel.

Aucune instruction de ce dossier n'autorise implicitement une écriture SQL distante, une migration PROD, une fusion vers `main`, un déploiement public, la suppression d'une branche, des données ou des sauvegardes. **Le push/merge sur `main` est traité comme une action de mise en production.** Toute PR doit éviter les branches concurrentes et préserver les worktrees en cours.

### 00.3 Sources d'autorité et résolution des conflits

1. Décision **explicite** du directeur la plus récente sur le sujet, datée et documentée.
2. `CLAUDE.md` de la branche de travail réelle et `docs/current/00_LIRE_D_ABORD.md` ; `08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md` avec ses addenda ; `DESIGN-GOV-2026-09-26.md` ; `03_DESIGN_SYSTEM_ET_UX.md` ; `COHABITATION.md`.
3. Décisions spécifiques datées : `DECISION-OFFRES-GROUPES-2026-10-09.md`, `DECISION-CLASSES-SIMULTANEES-2026-10-10.md`, référentiel académique RA-CUR-2026.1, Teaching Core, plan public et visuels du 09/10, pédagogie et évaluations du 10-12/10.
4. Spécifications de domaine les plus récentes et high-fi effectivement validées, puis code, tests et comportements observés au HEAD réel.
5. Sources antérieures archivées **seulement** pour retrouver l'origine d'une décision, jamais pour supplanter le présent état documentaire.

Les fichiers anciens peuvent présenter des contradictions (ancienne capacité 4/5, matching individuel, « mode enfant », remise à partir de deux personnes, certification automatique, enregistrement supposé). Les prescriptions plus récentes ci-dessous prévalent. **Ne jamais choisir silencieusement entre deux autorités réellement contradictoires encore actives : consigner une décision bloquante ciblée et avancer sur les lots indépendants.**

### 00.4 Classification obligatoire avant chaque modification

| Statut | Définition rigoureuse |
|---|---|
| `DÉCIDÉ` | Exigence métier tranchée et sourcée ; aucune preuve d'exécution. |
| `SPÉCIFIÉ` | États, actions, données, navigation et tests décrits. |
| `CODÉ` | Code présent sur un SHA identifié. |
| `ROUTÉ` | Atteignable depuis un point d'entrée réel, et pas seulement par URL. |
| `RACCORDÉ` | Consomme/écrit via le vrai contrat autorisé, sans doubles démo. |
| `TESTÉ_LOCAL` | Tests réellement exécutés, résultats et environnement. |
| `TESTÉ_STAGING` | Parcours multi-rôles démontré sur staging et traces fournies. |
| `DÉPLOYÉ` | Version et SHA servis et vérifiés dans l'environnement précisé. |
| `BLOQUÉ` | Dépendance nommée, propriétaire et contournement non trompeur. |

Un composant avec fixture et un service RPC non consommé **ne satisfont pas** `RACCORDÉ`. Une PR ouverte n'est ni une intégration ni une migration appliquée. Les statuts sont renseignés par **lot et fonctionnalité**, jamais attribués globalement par optimisme.

### 00.5 État de preuve connu au 12/10 : ne pas extrapoler

- GitHub accessible : `rewayahacademy-glitch/Rewayah-Academy-Official-App`. Branche d'intégration connue : `ccr-1b1bfa0b-m1kvkk`. La branche `main` et les PR de travail ont des états différents ; le HEAD doit être rafraîchi.
- Le 10/10, des PR backend en brouillon restaient ouvertes, notamment **#21** F2, **#29** F1 vers ccr, **#26** séparation CI staging ; **#31** sécurité admin et **#32** preuve de provenance SQL. **#33** a été fusionnée dans une branche backend intermédiaire, et **pas automatiquement dans ccr ou main**. Ce relevé est un instantané, pas l'état du jour au lancement des agents.
- Le dépôt contient déjà de nombreux écrans et ports : l'interface peut être codée sans raccordement ou inversement. Ne pas réimplémenter les verticales Enseignant, Tuteur, Contrôleur ou Comptable sans constater les écarts dans leur version actuelle.
- Les dossiers pédagogiques des **11 et 12 octobre** constituent des **cibles d'implémentation frontend**, non une preuve de livraison. En particulier, les Évaluations/Jury/Certifications décrites le 12/10 sont spécifiées mais non déclarées intégralement implémentées.
- Le site public a une PR d'aperçu historique **#8** ; son existence ne prouve ni l'intégration des visuels retenus le 09/10 ni la mise en production ni la conformité.
- Il reste des dépendances de réconciliation de migrations et de recette staging. Ne pas considérer les anciennes validations CI d'une autre tête Git comme une preuve du HEAD actuel.

---

## 01. Architecture produit cible et parcours complets

### 01.1 Principe unificateur

**La Classe est l'unité durable d'enseignement**, avec un enseignant attitré, des élèves, un programme/niveau, une langue, des jours/heures récurrents et un historique. Le foyer organise l'accès ; l'élève apprend ; l'enseignant conduit l'enseignement ; l'administration arbitre les exceptions ; les évaluateurs/jurés ne disposent que des capacités temporaires attribuées. Un même écran ou une même fonction a **un emplacement canonique** par domaine.

### 01.2 Chaînes verticales à démontrer

**Entrée familiale :** site public → inscription et compte → création des élèves autorisés → éventuels contrôles d'identité → catalogue d'offres publié → demande datée avec jours/heures → suivi d'état → regroupement par l'administration → Classe créée → enseignant confirmé → séances planifiées → accès enseignant/élève → cours en visio → cahier enseignant confirmé → suivi familial et travail → progression.

**Entrée adulte autonome :** inscription pour soi → profil étudiant autonome distinct → choix d'offre → confirmation Classe → séance → enseignement, travail et progression → solde de ce profil → factures et historique dans ses seuls droits. L'adulte n'a pas à créer un faux enfant ni un foyer parental fictif.

**Entrée enseignant :** validation du dossier/KYC → onboarding professionnel → disponibilités/Classes réellement proposées → réservation d'une Classe compatible selon politique → confirmation → Journée → préparation → salle → cahier K-45 → reprises et exceptions → proposition à l'évaluation → paie consultable sans données d'autres bénéficiaires.

**Évaluation :** proposition du professeur → orchestration de permanence/occurrence → fenêtre de salle → candidat appelé → passage → évaluation et avis éventuellement indépendants du jury → décision autorisée → prochaine action pédagogique ; le résultat n'émet ni promotion ni certificat par magie.

**Finance :** politique tarifaire publiée → estimation → engagement et solde individuel → demande d'encaissement → preuve prestataire → allocation par profil → consommation autorisée → dette enseignant après cahier validé → préflight → validation si nécessaire → payout → rapprochement → journal, réserves et tableaux de direction.

**Contrôle :** mission autorisée + MFA → observation sans publication media → rapport confidentiel → revue et réponse institutionnelle → synthèse selon politique → audit et clôture, sans exposition de l'identité de l'auteur ou de données scolaires inutiles.

### 01.3 Objets et identités à ne pas confondre

`compte/auth`, `personne`, `matricule RA`, `profil élève`, `foyer`, `tuteur titulaire`, `second adulte`, `enseignant`, `Classe`, `offre vitrine`, `intention horaire`, `séance`, `occurrence d'évaluation`, `meeting`, `passage`, `décision`, `cahier`, `projection familiale`, `solde`, `obligation`, `payout`, `mission de contrôle` sont des objets distincts. Un code public d'évaluation EV ne doit jamais devenir un identifiant donnant accès à l'identité d'un élève sans droit.

### 01.4 Architecture technique sans prolifération

- **Client :** Flutter mobile/tablette/web/PWA, routeur existant, navigation par capacités, ViewModels d'états, i18n, design system unique.
- **Backend :** Supabase PostgreSQL avec RLS, projections par contexte, RPC et fonctions Edge en cas de besoin avéré, transactions idempotentes, journalisation.
- **Média :** LiveKit comme transport de présence/média, sans faire transiter l'audio/vidéo dans Postgres ; les supports synchronisés par le Teaching Core déjà existant.
- **Fichiers :** Cloudflare R2 dans les buckets autorisés, URL signée et contrôle à chaque délivrance, aucune exposition du coffre KYC par un lien public.
- **Déploiement :** GitHub Actions/Vercel, staging distinct, environnement et SHA identifiables ; jamais de repli silencieux vers PROD lors d'un aperçu.
- **Recherche :** PostgreSQL et index existants comme première stratégie ; moteur externe uniquement après preuve de besoin et modèle de révocation équivalent.
- **Notifications :** projections d'événements métier avec liens contextuels, sans transférer à la notification l'autorité sur un état métier.

---

## 02. Matrice principale des dernières réalisations

**P0 = bloque un vrai parcours ou expose des données/argent ; P1 = nécessaire au périmètre complet ; P2 = amélioration non critique.** Les états `À vérifier` interdisent d'inférer qu'un module est à construire entièrement.

| ID | Domaine/lot | Mission attendue | Priorité | Périmètre d'implémentation |
|---|---|---|---|---|
| G00 | Vérité des branches/contrats | Réconcilier HEAD, PR, migrations, staging, preuves et ownership ; inventaire des fonctionnalités routées | P0 | Audit partagé, aucune PROD |
| G01 | Sécurité et identité | Matricules, comptes autonomes, relations foyer, KYC, délégations, droits courants et caches | P0 | Flutter + contrats/backend séparés |
| G02 | Offres et Classes CAP-19 | Demande → regroupement → création → enseignant → séance, simultanéité K-65 | P0 | Delta frontend + backend Codex |
| G03 | Classe Live & bibliothèque | Salle unique, supports fidèles, focus, reconnexion, présence, observations bornées | P0 | Reconnexion des moteurs existants |
| G04 | Élève enfant / guidée | Accueil simple, accès Classe, apprentissage, erreurs compréhensibles, protection | P0 | Delta frontend ciblé |
| G05 | Élève adulte | Profil autonome, accueil, apprendre, suivi, solde et accès à ses Classes | P0 | Delta frontend + contrats autonomes |
| G06 | Tuteur et foyer | Inscription, états des élèves, historique, observation, solde individuel, délégation | P0 | Vérification et corrections seulement |
| G07 | Enseignant | Journée/Classes/cahier/photo/remplacements, finitions et preuve du vrai câblage | P0 | Pas de refonte systématique |
| G08 | Pédagogie et rapports | Diagnostic D0, K-45, restitution ciblée, progression continue, exceptions | P1 | Specs PED du 10-12/10 frontend only ; backend via Contrats |
| G09 | Évaluations, jurys, certifications | Occurrences, salle d'évaluation, jury, résultat, document institutionnel uniquement si émis | P1 | Dossier Évaluations V2, frontend only |
| G10 | Finance et Comptable | Solde, prix, ledger, factures, remboursements, paie, coffres, délégation, audit | P0 pour exactitude ; P1 pour module complet | CPT/FI existants, raccordements séparés |
| G11 | Administration & Direction | Dossiers, Classes, pédagogie, finance, sécurité, politiques, qualité et recherche | P1 | Enrichir registres existants, pas de modules concurrents |
| G12 | Contrôleur | Mission, MFA, observation, rapport, confidentialité, historique, contestations | P1 | Vérifier l'existant puis compléter |
| G13 | Communications & recherche | Messages métier, notifications, Studio, recherche transverse sécurisée | P1 | Réutiliser COM + RECH ; contrats spécialisés |
| G14 | Site public & recrutement | 17 pages prévues, visuels finaux, identité légale, contenu, simulateur relié aux tarifs | P1 | PR site + frontend public + Finance backend |
| G15 | Recette, performance, conformité | E2E multi-rôles, scénario catastrophe, staging, accessibilité, publication gouvernée | P0 | Qualité + décision de go/no-go |

---

## 03. G00 - Socle d'intégration, migrations, qualité des branches

### 03.1 Inventaire initial non destructif

Claude et Codex consignent : SHA, branche, PR ouvertes, worktrees, zones modifiées/non commitées, contrats existants, routes effectives, mocks/demo, version des schémas et tests. Ne toucher à aucun fichier d'un autre agent avant revue `COHABITATION.md` et onglet `Contrats` de la feuille de liaison. Inventorier la cible PROD **en lecture seule**, pas pour rattraper les migrations au hasard.

### 03.2 Reconciliation backend obligatoire avant toute vraie cohorte

1. Cartographier chaque migration par nom, hash, contenu, dépendances, version locale et entrée dans le ledger distant. Identifier homonymes et numéros partagés ; ne jamais modifier rétroactivement une migration déjà appliquée.
2. Rejouer le schéma voulu **de zéro sur PostgreSQL propre**, avec migrations ordonnées, fixtures, RLS et scénarios. Examiner la divergence 0006-0008 et les preuves de provenance 0011 déjà documentées : aucune réparation opportuniste de ledger.
3. Établir un STAGING reproductible et isolé avec données synthétiques, connexion authentique des comptes de test et fichiers/visio non sensibles. Prendre en compte PR #26 qui sépare les secrets staging des aperçus.
4. Vérifier toutes les PR backend pertinentes et migrations F1/F2 dans leur branche cible ; **#33 fusionnée dans une branche intermédiaire ≠ #29 fusionnée dans ccr**. Aucun test ancien ne remplace un test sur l'intégration réelle.
5. Exécuter validation des grants, tests RLS négatifs, cycles de session, références de fichiers, restrictions membres, permissions suspendues, régénération des projections et alertes.
6. Produire un plan de promotion avec sauvegarde testée, fenêtre de migration, rollback applicatif, stratégie pour DDL irréversible, preuve des secrets et contrôle après déploiement.

### 03.3 Barrières absolues

Pas de `service_role` depuis Flutter ; pas de secrets en Git, logs, captures ou Markdown ; pas de déploiement d'aperçu compilé avec les credentials PROD ; pas de comptes réels d'élèves dans des fixtures ; pas de feature flag « succès fictif ». Toute dépendance backend manquante se traduit par **UI indisponible honnête**, contrat documenté et tâche Codex distincte.

### 03.4 Sortie G00

Un rapport diffable `00_INVENTAIRE_ET_GATES.md` avec matrice `élément → fichier → SHA → port → endpoint → migration → rôle test → statut → preuve → propriétaire`, et aucune collision de zone en cours. Il ne faut pas attendre d'avoir fini tous les modules pour établir cet inventaire.

---

## 04. G01 - Identité, habilitations, foyer et immatriculation

### 04.1 Identité durable

Chaque personne possède une identité stable, séparée du UUID technique et du rôle courant. Les matricules RA/classifications sont générés **uniquement côté serveur**, non prédictibles lorsqu'ils révèlent une classe d'individus, uniques, résistants à la concurrence et conservés après suspension ; les codes EV appartiennent à une évaluation, ne servent pas d'annuaire public et ne livrent jamais un dossier par seule connaissance du code. Ne pas changer les références historiques sans correspondance migratoire auditée. Toute recherche exacte par matricule est soumise aux droits de l'appelant.

### 04.2 Adultes et familles

Un étudiant autonome possède **son propre profil élève**, même si une ancienne structure de compte le nomme `guardian`. Le titulaire peut inscrire des mineurs ; le second adulte n'hérite pas de tous ses droits ; l'élève devenu majeur suit un chemin de transition documenté sans transfert automatique de données privées à l'ancien tuteur. Les changements d'âge, date de naissance manquante et frontières 9→10 / 13→14 / 17→18 sont testés en présence de Classes actives.

### 04.3 Dossiers sensibles

KYC enseignant selon politique validée, KYC élève non imposé uniformément à l'inscription, photo d'identité enfant avant sa première visio si requise par le contrat courant. Pièce KYC et photo publique enseignant sont deux fichiers et deux autorisations distinctes. Accès à la pièce d'identité limité au personnel explicitement habilité, **pas** au Contrôleur par simple rôle. Toute dérogation et lecture sensible est tracée ; les conservations effectives doivent être vérifiées contre les obligations légales, pas devinées d'un ancien document.

### 04.4 Sécurité des sessions

RLS et contrôles de relation serveur courants. Tester compte suspendu, révocation de capability, remplacement expiré, délégation retirée, déconnexion/reconnexion, changement d'enfant actif, session concurrente, reconnexion réseau, ouverture par deep link et cache après révocation. Les écrans ne portent que les actions `actionsPermises` réellement servies. Contrôleur : MFA impératif.

### 04.5 Recette

A ne consulte ni foyer ni pièces de B. Une recherche, un compteur, un avatar, un log d'erreur ou une ancienne réponse cache ne doivent pas dévoiler B. Le compte adulte autonome suit un cours et paie pour son profil ; aucun faux enfant n'est créé. Un second adulte ne recharge pas par le simple fait de lire le solde.

---

## 05. G02 - Offres, demandes, Classe stable et simultanéité

### 05.1 Doctrine d'octobre, fermée

- L'administration **seule** crée et publie des **offres vitrines** (jours, heures, public, durée, langue) ; **pas d'enseignant** affiché dans la vitrine et **pas de compteur de sièges fictif**.
- La famille choisit des créneaux publiés ou formule une demande hors offre selon les règles existantes ; aucun horaire ne peut être demandé sans **jour et heure explicites**. Ce geste exprime une intention, **pas** une réservation de place.
- Le système groupe les demandes compatibles ; l'administration constitue une **Classe stable**, y intègre les élèves selon transactions sécurisées, puis confirme/affecte un enseignant. Les enseignants peuvent prendre des Classes proposées via leur marketplace **dans les limites et confirmations de l'administration**. Ne pas revenir au vieux « prendre un élève ».
- Les familles connaissent l'état de leur demande jusqu'à la première séance ; les notifications suivent les événements réels.
- Références pédagogiques observées le 09/10 : **5 enfants maximum**, séance **60 min** avec **5 min de pause**, **3 séances/semaine** ; **6 adultes maximum**, séance **90 min**, **3 séances/semaine**. Ce sont des **valeurs de référence configurables** : toujours consommer la capacité/durée effective de la Classe, jamais les coder en dur.
- Cohortes : **6-9**, **10-13**, **14-17**, **18+** ; langues offertes : français, poular, anglais **selon publication réelle**. La cohorte, le programme et la disponibilité doivent rester compatibles durant toutes les occurrences de la Classe, changements saisonniers inclus.

### 05.2 Simultanéité K-65, non négociable

Plusieurs Classes de même créneau, catégorie, fuseau, niveau et genre peuvent être actives en parallèle. **L'identité est `classeId`, jamais une clé d'horaire.** Les unicités concernent notamment l'élève et l'enseignant sur une occurrence conflictuelle, **pas** la plage commune. Le regroupement sous concurrence est atomique et idempotent ; verrouiller la bonne clé, choisir/créer un compartiment sans dépasser la capacité, puis insérer les inscriptions en transaction. Conserver la séparation RLS **par Classe**, même entre deux Classes de 18h dans la même catégorie.

### 05.3 États et transitions UX

`Offre publiée → Intention reçue → En constitution → Classe créée / enseignant recherché → Enseignant confirmé → Classe confirmée → Séances visibles` ; états alternatifs `À préciser`, `Offre retirée`, `Demande annulée`, `Incompatible`, `Liste d'attente`, `Erreur temporaire`. Tout état dit **qui doit agir** et **ce qui est acquis** sans annoncer « Place réservée » lorsque ce n'est pas vrai.

### 05.4 Écrans existants à réemployer

`parcours_offres`, `suivi_demandes`, `admin_regroupements`, inspecteurs de Classes, `classe_tuteur`, `creneaux`/marketplace enseignant et la planification séance. Claude cartographie l'entrée réelle depuis foyer/admin et l'état du port `PortRegroupementsAdmin` avant de créer un écran. Conserver les autorisations réservées : une famille ne fabrique ni offre ni classe elle-même.

### 05.5 Recette de rupture

Deux demandes identiques simultanées ; 30 Classes au même horaire ; 500 puis 1 000 puis 10 000 élèves en dataset synthétique ; double tap ; attribution concurrente ; changement DST Europe/USA ; refus de quota ; retrait d'offre ; remplaçant ; annulation admin ; migration d'élève d'une Classe à l'autre ; interdiction de lecture inter-Classes ; impossibilité pour un professeur de prendre deux séances incompatibles ; enseignants stables dans la semaine. Mesurer transactions, plans SQL, verrouillages, retries et régénération des séances.

---

## 06. G03 - Une seule salle LiveKit et une bibliothèque partagée

### 06.1 Source fonctionnelle unique

Réconcilier `/salle` et l'ancien `/tc/classe` après inventaire du routeur. **Une seule salle média et un seul moteur de supports** pour classe habituelle, remplacement et évaluation ; les contextes métier modifient les capabilities et panneaux, pas le stack média. Aucun bouton « Suivre l'enseignant » : son support prend autorité automatiquement lorsque prêt.

### 06.2 Salle ordinaire

Hiérarchie : **support pédagogique dominant > élève actif et voix > commandes essentielles > mosaïque vidéo secondaire**. La page Coran HAFS ‘an ‘Asim et la pagination canonique ne doivent pas être altérées. Navigation page/sourate/juz/ayah, zoom, focus, masquage/révélation, marqueurs autorisés, stylet sur tablette et lecture versets selon moteur présent. Supports : Coran, Qaida, invocations, leçons, PDF/images autorisés, sans bibliothèques dupliquées par rôle.

L'enseignant est la source de l'état partagé : sélection d'une ressource/version/position, préchargement et confirmation avant bascule, ordre monotone par séance, snapshot/replay après coupure, annotations temporaires réactives et écritures durables coalescées. En cas d'échec de chargement chez un enfant, laisser le dernier support visible avec un vrai état d'erreur ; **ne pas promettre une synchronisation au pixel sans test de latence réseau**. Utiliser LiveKit pour l'audio/vidéo et sa signalisation disponible, pas un streaming des images pédagogiques au travers d'une vidéo codée par Flutter, sauf besoin distinct validé.

### 06.3 Commandes et focus

Mobile : toucher de l'écran révèle les contrôles principaux puis les masque après inactivité selon tokens d'animation ; desktop : mouvement de souris/clavier et focus révèlent les commandes ; toute commande indispensable reste retrouvable au clavier et lecteur d'écran. Le **mode focus** retire l'encombrement sans masquer sortie, micro/caméra si autorisés, état réseau ni les contrôles de support essentiels. Aucune animation insistante ; respect du mouvement réduit et safe areas.

### 06.4 Présence, accès, observations

Fenêtre de rejoignement **T-20 min** selon source/configuration. Présence issue d'événements LiveKit signés, sessions multiples et retours dédoublonnés, trous d'évidence signalés, corrections admin auditées. Un cours non tenu ne devient pas une absence élève. Pour le tuteur : **deux visites maximum par séance, deux minutes chacune**, micro/caméra interdits, audio autorisé, admission automatiquement encadrée, annonce à l'enfant concerné ; la notification de présence parentale ne doit pas révéler les autres enfants. Paramètre effectif administrable par Classe et historique d'observation consultable par tuteur et administration dans leurs droits. Contrôleur : observation seulement en mission, identité protégée suivant la politique existante.

### 06.5 Enregistrement et confidentialité

**Ne pas afficher « Cours enregistré » si aucun enregistrement réel n'existe.** Les sources anciennes divergent sur la captation automatique. Tant qu'aucun texte de politique, base légale, consentements, preuve LiveKit Egress/R2, chiffrement, accès et durée n'est validé, **ne pas activer la captation** et ne pas prétendre qu'elle est active. Ce point peut demeurer un gate d'enregistrement sans bloquer une visio non enregistrée conforme.

### 06.6 Performance

Tester une Classe enfant et adulte en conditions Wi-Fi, 4G/3G dégradée, appareils modestes, 300 ms RTT, perte réseau, perte audio, changement caméra, bascule hors focus et seconde reconnexion. Métriques : délai de jonction, latence d'affichage du nouveau support, taux de réussite de restauration, dérive de page et pertes d'annotations. Précharger, limiter le nombre de flux vidéo rendus et dégrader proprement. Ne pas annoncer une cible chiffrée de latence comme atteinte avant mesures.

---

## 07. G04 - Élève enfant : Interface guidée

### 07.1 Modèle d'interaction

L'Interface guidée est **une présentation du même produit**, pas un second système de droits, une nouvelle arborescence ou un « mode enfant » séparé. Elle est proposée par défaut aux mineurs selon la politique effective ; un adulte peut la choisir ; les demandes de bascule enfant utilisent l'autorité du tuteur/serveur. Ne pas imposer une frontière d'âge issue d'une ancienne configuration sans vérifier la décision la plus récente.

### 07.2 Accueil enfant

En premier : `Prochain cours` puis **un seul CTA dynamique** (`Voir ma Classe`, `Rejoindre`, `Reprendre`, `Voir le travail`). Ensuite deux accès simples : `Mon Coran / mes supports` et `Ce que je prépare`. La progression est secondaire ; aucune donnée financière, KYC, publicité, classement, calendrier professionnel ou nombre de sièges ne figure sur cet accueil.

### 07.3 Pendant/après

L'enfant suit automatiquement le support et la page du professeur, sans choisir de flux. Il voit clairement `Tu attends ton tour` / `C'est ton tour` si état réellement servi. Après la séance, `Travail à préparer` et `Ce que j'apprends` présentent uniquement les objectifs validés ; **`Fait` ≠ `Maîtrisé`**, ni examen réussi. Rejoindre doit rester plus évident que lire un historique.

### 07.4 Cas de sécurité

Une notification d'observation du parent n'est présentée qu'à son enfant. Aucun nom d'autres élèves ni rapport scolaire n'est affiché dans les vues personnelles. L'enfant ne peut pas activer une interface standard en contournant le serveur, changer ses droits, consulter le solde parental ou rechercher un annuaire. Si l'adulte responsable n'a pas encore finalisé l'accès, écran calme avec explication, jamais « vous n'avez pas payé ».

### 07.5 Accessibilité

Tutoiement, phrases courtes, icône et libellé, cibles tactiles confortables, lecteurs d'écran, clavier, agrandissement à 200 %, absence d'animations anxiogènes et contraste mesuré. L'Interface guidée ne doit pas simplement rapetisser l'interface adulte ni masquer les chemins de récupération.

---

## 08. G05 - Élève adulte autonome

### 08.1 Navigation canonique

`Aujourd'hui · Apprendre · Suivi · Profil`. Pas d'obligation de se déclarer parent ; pas de copie de la navigation Tuteur. Même Classe, lecteur, visio et progrès que l'enfant, avec langage adulte et commandes adéquates.

### 08.2 Aujourd'hui

Carte prioritaire : prochaine séance, horaire dans son fuseau, enseignant attitré **après confirmation**, état et CTA ; autres séances/annulations, devoir, accès support et notifications. Les champs absents restent absents : ne pas afficher un professeur fictif ou un statut `réussi` non confirmé.

### 08.3 Apprendre

Classe actuelle, bibliothèque, Coran, ressources, travail assigné, reprise et évaluation autorisée. Les supports téléchargés suivent les règles de droits et purge ; une suppression ou révocation ferme les accès, y compris via anciens deep links lorsque vérifiable.

### 08.4 Suivi

Vue académique personnelle : niveau humain fourni, jalons réels, points `À renforcer / Acquis / Stable` **seulement si décidés par une projection académique officielle**, historique de séances autorisées, évaluations et attestations réellement émises. Aucun indicateur de compétence dérivé d'un taux de présence ou du nombre de sessions.

### 08.5 Profil / finance personnelle

Identité et sécurité, appareils, préférences, mode d'affichage, statut de son inscription, historique et rechargement de **son propre solde**, moyens de paiement et factures selon capacités existantes. Pas de paiement de profil enfant inventé pour l'adulte solo, et pas de libre accès aux dossiers d'autres membres si un ancien rôle technique l'appelle `guardian`.

### 08.6 Recette

Compte adulte nouveau ; ancien compte `guardian` compatible ; adulte avec un seul profil ; adulte anciennement mineur ; plusieurs appareils ; réaffectation de Classe ; paiement validé / en transit / refusé ; changement de fuseau ; hors connexion ; documents révoqués. Vérifier la cohérence sur PWA et Android/iPad, sans déclarer le natif prouvé si non testé.

---

## 09. G06 - Tuteur, foyer et second adulte

### 09.1 Architecture et navigation

Conserver le shell validé : **`Accueil · Foyer · Historique · Compte`**. Une fonction = un emplacement ; `Progression` depuis **Classe**, résumé d'une séance depuis **Historique → Détail**, travail depuis **Classe → Travail à préparer**, répartition des crédits dans **Solde**, réglages personnels et apparence regroupés dans **Compte/Réglages**. Ne pas créer de nouvelle destination globale `Rapports` ou `Évaluations`.

### 09.2 Contexte élève fiable

Choix explicite de l'enfant ; le changement vide/invalide immédiatement les données de l'enfant précédent, et conserve le contexte dans les liens, historiques, notifications et retours. Vue foyer multienfants avec total informatif des soldes et sous-solde par enfant, **pas** portefeuille librement transférable. Le second adulte voit seulement les données déléguées : lecture de paiements ≠ autorisation de recharger ou d'approuver.

### 09.3 Observation et historique

La fonctionnalité `Observer` consomme les limites et preuves de la section G03 ; pas de micro/caméra, deux visites de deux minutes, annonce ciblée à l'enfant, historique dans son écran existant et l'administration. Proscrire le libellé « Cours en cours » déjà rejeté par la direction. Aucune présence ne peut dépasser son temps maximum par manipulation d'horloge cliente.

### 09.4 Abonnement/solde

Recharger un ou plusieurs profils revient à un seul paiement externe possible avec allocations **immuables par profil** vérifiées côté serveur ; la lecture des montants et la mise à jour ne valent pas confirmation de prestataire. Remises, absence professeur, pause, annulation d'accès, factures et retour de crédit suivent la version de politique financière effective. L'enfant ne voit pas la raison monétaire.

### 09.5 Recette

Un tuteur avec trois enfants, seconde personne du foyer, Classe différente par enfant, une demande en constitution, une séance annulée et une autre corrigée, observation complète, deux crédits distincts, paiement partiellement en cours, correction familiale et révocation de rapport. Aucun mélange de données lorsque le profil actif change.

---

## 10. G07 - Enseignant : terminer sans reconstruire

### 10.1 Référence

`04_ENSEIGNANT(1).md`, datée du 12/10, couvre les écrans **ENS-01 à ENS-13**. **C'est une spécification, pas une attestation d'intégration** : les agents doivent vérifier leurs routes, services et tests réels avant toute intervention. Éviter tout remplacement de la verticale Enseignant si la fonction marche déjà.

Navigation **`Journée · Créneaux · Profil`**, sans quatrième entrée ; Classe, Cahier, Ressources, Élève, Évaluations et Remplacement sont contextuels.

### 10.2 Complétude à prouver

- Onboarding après validation dossier et KYC ; **Journée** avec action prioritaire, prochaine séance et exceptions.
- **Créneaux** : disponibilités + marketplace de Classes proposées, **pas de matching individuel d'un élève**.
- Classe permanente : liste minimale des élèves autorisés, objectif, reprise, supports, évaluation et travaux, sans données financières/KYC familiales.
- Préparation : support, reprise, objectif, en moins d'une minute sur scénario courant ; accès Coran hors séance et partage dans la même salle.
- Séance : présence LiveKit, file de récitation, contrôles focus et reconnexion, corrections exceptionnelles tracées.
- **Cahier K-45** obligatoire et prérempli, cible **moins de 45 secondes pour la séance entière**, avec corrections d'exceptions seulement ; pas de deuxième rapport et pas de saisie mensuelle narrative.
- Absence/remplacement : déclaration rapide, état administratif, remplaçant provisoire à droits bornés ; professeur habituel rétabli ensuite.
- Photo professionnelle publique distincte KYC, visible sur la vraie carte de Classe seulement après affectation, et non dans l'offre vitrine.
- `Proposer à l'évaluation` depuis fiche élève, `Mes évaluations` depuis Journée uniquement en présence de la capability.
- Profil et objets financiers propres, sans accès aux bénéficiaires étrangers.

### 10.3 Test de clôture

Parcourir du nouveau dossier à la rémunération simulée par obligations réelles staging ; capturer les temps de préparation et de cahier, trois séances et une absence/remplacement. Si déjà conforme, **marquer vérifié sans changer le code**.

---

## 11. G08 - Pédagogie : entrée, cours, restitution, progression

### 11.1 Cycle de vie canonique

`Admission → D0/positionnement → programme/niveau → Classe → enseignement partagé et progression individuelle bornée → cahier K-45 → travail/reprise → évaluation de gate si applicable → consolidation/orientation/promotion distinctes`. Les statuts de compétences sont **À renforcer / Acquis / Stable**. L'autorité académique, et non Flutter, décide de la maîtrise ; ni paiement ni présence ne crée un acquis.

Référentiel RA-CUR-2026.1 : D0, F1-F4, gate G0, Tilāwah T1-T6, Ḥifẓ H0-H6, Itqān I1 ; échantillons et gates selon version officielle. Le débutant auto-déclaré peut entrer dans F1 sans épreuve lourde suivant la décision produit antérieure ; vérifier si le D0 obligatoire du référentiel impose une simple constatation administrative minimale ou un examen réel. **Ne pas réintroduire une épreuve inutile pour 95 % de débutants par interprétation unilatérale.** C'est une dépendance de doctrine ciblée, non une invitation à arrêter la conception UI des autres cas.

### 11.2 PED-01, positionnement

- **Élève/tuteur :** informations déclarées une fois, statut d'entrée humain, placement confirmé ou attente explicite, action suivante et absence de promesse de Classe.
- **Administration `ADM-10` :** file Diagnostics existante, preuve versionnée, proposition/validation, motif, avis, notification et renvoi au dossier/Classe.
- **Enseignant :** niveau d'entrée et objectifs nécessaires à la séance, aucune promotion administratrice.
- **Contrôleur :** lecture uniquement s'il en a besoin pour une mission, sans ouvrir les pièces KYC et l'ensemble de la fiche.
- **Recette :** débutant, non-débutant, cohorte vieillissante, âge manquant, aucun groupe, retour d'interruption, programme non publié, refus et réseau dégradé.

### 11.3 PED-APRÈS, restitution familiale du K-45

**Référence :** `REWAYAH_PED_APRES_SPEC_VERTICALE_V1_2026-10-11.md` et high-fi du 11/10. **Ne pas modifier le K-45.** Après validation métier, restituer **uniquement la projection partageable de l'élève** dans `Tuteur → Historique → Détail de séance`. Distinguer : informations générales de la séance ; observations pédagogiques partageables ; notes internes jamais diffusable. L'enseignant ne recopie pas son cahier pour la famille.

Politique de partage : défaut général **activé**, switch par **Classe**, exception par **élève**, publication/révocation **d'un compte rendu précis** par l'administration. Priorité : décision ciblée > exception élève > Classe > défaut général. Désactivation cache immédiatement les résumés automatiquement servis, pas le cahier ; une publication manuelle ciblée reste valide jusqu'à révocation ; une révocation ciblée prime sur toute politique. Réactivation ne publie pas rétroactivement en masse les rapports retenus pendant une période désactivée. La correction d'un texte déjà partagé ne déverse jamais une note interne sans nouvelle validation pertinente.

UX canonique : `ADM → Opérations → Classes → Inspecteur` pour les règles Classe/élève ; action contextuelle sur un compte rendu confirmé pour `Aperçu familial / Partager manuellement / Révoquer`. Ne pas construire un second module `Rapports`. **Port serveur indisponible = « Compte rendu non disponible »**, jamais extrapoler depuis le cahier brut.

### 11.4 PED-PROGRESSION, trajet sur plusieurs séances

**Référence :** `REWAYAH_PED_PROGRESSION_SPEC_VERTICALE_V1_2026-10-11.md`. Cinq objets distincts : cahier, résumé d'une séance, travail à préparer, progression continue et décision institutionnelle d'évaluation. Conserver **Classe → Progression** pour le tuteur, miroir sobre élève, Préparation/K-45 chez l'enseignant et `ADM-11` chez l'admin.

Projection actuelle minimale trouvée : `niveauHumain` et `jalons`. Enrichir compétences/objectif/date uniquement si un contrat autorisé les fournit. Pas de radar, barre à 80 % ou chronologie fictive. **Stable** exige la règle académique vérifiée et ses preuves sur la durée, mais **Flutter ne calcule aucun seuil**. Les codes `F1/H3` et erreurs académiques techniques ne sont pas montrés bruts à la famille. En cas de retrait du droit, purger ou refuser l'ancien cache.

### 11.5 Décisions humaines et exceptions

Le professeur peut réduire une quantité, renforcer et suspendre un nouveau passage Hifz selon règles ; il ne contourne pas les gates et ne certifie seul. L'administration peut gérer blocages/dérogations et une promotion formalisée dans son registre ; un bouton `Promouvoir` existant **ne prouve pas** que toutes les conditions pédagogiques soient réunies. Une exception reste auditée, avec ancienne et nouvelle situation explicites.

### 11.6 Recette transversale

K-45 validé mais pas partagé ; partagé puis révoqué ; tuteur avec deux enfants ; adulte autonome ; élève changeant de Classe ; cahier corrigé ; accès hors ligne ; compétences réévaluées ; absence de source académiques ; directeur modifiant la règle de partage d'une Classe ; session prolongée ; tuteur délégué retiré. Aucune information privée d'un autre élève ne quitte le serveur.

---

## 12. G09 - Évaluations, salles, jury, attestations et certifications

**Référence prioritaire du 12/10 :** `REWAYAH_EVALUATIONS_FINAL_SPEC_V2.md`, `REWAYAH_EVALUATIONS_HIGHFI_BRIEFS_V1.md`, `HANDOFF_CLAUDE_EVALUATIONS_FRONTEND_V1.md`, `REWAYAH_EVALUATIONS_QA_MATRIX_V1.md`. L'intégration demandée à Claude **reste frontend only** et ne relance pas une recherche de produit déjà faite. L'analyse multi-agents du handoff sert de contrôle contradictoire interne ; aucun faux « avis d'expert certifié » ne sera déclaré.

### 12.1 Machine métier

`Proposée par enseignant → candidature → occurrence/permanence planifiée par système/autorité → salle d'évaluation → appel → passage → évaluation + jury conditionnel → décision → action pédagogique`.

L'enseignant **propose, ne planifie pas** ; il peut proposer en lot avec erreurs individuelles non bloquantes. Les candidats poursuivent leurs cours pendant l'attente et ne reçoivent pas une heure inventée. Absence à l'appel ou coupure = `temporarily_skipped`/état technique, jamais échec académique.

### 12.2 Acteurs et permissions

- **Élève :** voit date si connue, CTA unique en fonction de la phase, assiste/écoute, est appelé, passe, consulte résultat privé et action. Interface guidée simple.
- **Tuteur :** reçoit statut/résultat propres à son enfant, demande de réévaluation si ce droit existe ; n'est ni évaluateur ni jury.
- **Enseignant référent :** propose, suit les candidats autorisés, applique l'action pédagogique ; n'attribue pas son propre grade institutionnel.
- **Évaluateur :** prépare, ouvre, appelle, évalue, passe au suivant, finalise selon habilitation.
- **Juré :** affectation, avis indépendant, réconciliation et quorum selon politique **configurable**, pas « trois jurés » hardcodé.
- **Administration `ADM-12` :** supervise occurrence, habilitations, visibilité, exceptions, décisions et contrôle qualité ; ne crée pas un autre module.

Capabilities conceptuelles (ne pas ajouter en backend par Claude) : `evaluation.assess`, `evaluation.jury_member`, `evaluation.jury_chair`, `evaluation.certify`, `evaluation.review_appeal`, `evaluation.manage_policy`. Chaque grant a scope, date d'effet, expiration, émetteur, retrait et audit ; le rôle global seul n'accorde rien.

### 12.3 Salle et confidentialité

Deux visibilités : `restricted` **par défaut** ; `community_open` seulement après acte explicite d'un administrateur habilité **confirmé serveur**. Une ouverture communautaire n'accorde que l'écoute/vision autorisée, jamais micro, caméra, contrôle de file, identité complète mineur, résultats, notes, grille ou délibération. Une audience de 1 000 comptes n'est pas un mur de 1 000 vidéos. Les candidats et le jury gardent la priorité sur la capacité technique.

Réutiliser le moteur de salle LiveKit existant, en ajoutant un **contexte métier d'évaluation** et un panneau privé si manque avéré ; pas de nouveau `EvaluationLiveKitService`. La salle de l'évaluateur diffère de celle du candidat par capabilities et contrôles privés ; aucun code E1/E2/E3 n'est exposé au candidat en audience. Un mineur ne devient jamais identifiable publiquement par simple changement de visibilité.

### 12.4 CTA et machine d'états

Un seul `EvaluationNextActionResolver` central : exemples `Voir mon évaluation`, `Rejoindre ma salle d'évaluation`, `Reprendre mon évaluation`, `Voir mon résultat`, `Voir ce que je renforce` ; évaluateur `Préparer l'évaluation`, `Ouvrir ma salle`, `Commencer`, `Reprendre`, `Finaliser`, `Rendre mon avis`. Les transitions consomment le serveur et la fenêtre réelle. Pas de bouton actif avant sa fenêtre ni de faux « Rejoindre » après fin.

Candidat en file : `present_waiting`, `called`, `candidate_active`, `temporarily_skipped`, `absent_at_call`, `returned`, `completed`. Décisions publiques individuelles préférées : **`Étape validée`**, **`Quelques points sont à renforcer`**, **`Une nouvelle vérification est nécessaire`**. Ne pas créer un état humiliant `Échec` pour une panne technique.

### 12.5 Résultats ≠ promotions ≠ documents

Distinguer observation pédagogique, évaluation structurée, gate, Majlis, orientation, promotion, attestation et certification. Une évaluation réussie n'est pas une promotion acquise. Dans l'ancien code `estCertificationReussie` ne prouve **pas** l'émission d'un certificat. Il faut un acte officiel distinct, habilité, document authentique avec état émis/non émis/révoqué, version et droit de consulter. Aucune fabrication locale de PDF de diplôme ni utilisation du mot « ijāzah » sans décision doctrinale et institutionnelle.

Référentiel produit envisagé : fin F4 attestation Fondations ; fin T6 certificat de lecture ; fin I1 certificat Hifz complet et consolidé. Récompenses intermédiaires ne sont pas des certificats automatiquement téléchargeables. Les règles détaillées du jury, des gates et de stabilité restent appliquées côté autorité académique versionnée, pas dans les widgets.

### 12.6 UI à raccorder sans doublon

Réutiliser `ADM-12` et le registre existant, enrichir seulement ses sous-surfaces : supervision, occurrence, habilitations, politiques, exceptions. `Évaluations en direct` est une **surface contextuelle**, non un nouvel item de navigation principale. Côté enseignant, `Mes évaluations` dans Journée si habilité ; côté tuteur carte enfant et détail ; côté élève son propre parcours. L'absence de contrat serveur de jury/certification produit un état non disponible et une dépendance Codex, pas une permission fictive.

### 12.7 Contrats frontend et tests

Ports conceptuels : `EvaluationRepository`, `EvaluationAdminRepository`, `EvaluationRoomController`, `EvaluationPolicyProjection`, `EvaluationCapabilityProjection` et `EvaluationNextActionResolver`, seulement après vérification des ports déjà présents. Le lot de 45 scénarios `REWAYAH_EVALUATIONS_QA_MATRIX_V1.md` est le **minimum**, dont double tap, jury sans quorum, jurés divergents, audience sans média, mineur en meeting ouvert, date DST, 100 candidats/1 000 auditeurs, reconnection, habilitation expirée, route directe refusée, demo isolée, délibération non visible, compatibilité de la Classe ordinaire.

---

## 13. G10 - Finance, solde, Comptable et Direction

### 13.1 Une seule vérité monétaire

Argent stocké et calculé en **entiers d'unités mineures**, devise explicite, politique datée et versionnée. Ledger opérationnel en ajout seul et équilibré par devise ; corrections par écriture inverse, preuves auditées. Séparer encaissement, avance client par profil, taxes, revenus reconnus, dette enseignant, payout en transit, fonds protégés et trésorerie libre. **Le total du foyer est indicatif, jamais dépensable comme une caisse commune.**

L'enseignant ne devient payable que selon les règles de prestation et après **cahier validé**. Garder les différences de séance (60 vs 90 min), sièges éligibles, absences, remplacements, bonus Internet éventuel et contrat actuel d'enseignant. Aucune règle fixe de salaire issue d'une ancienne conversation n'est codée sans lecture de sa version en vigueur. Les commissions, réserves, remises et exemptions restent cohérentes avec la politique commerciale signée.

### 13.2 Contrat tarifaire public d'octobre, non hardcodé

**Snapshot métier actuellement documenté :** enfant **50 USD/mois**, adulte **60 USD/mois** ; remise individuelle de rang : rangs 1 et 2 **0 USD**, rang 3 **5 USD**, rang 4+ **7 USD** par personne. Cela s'applique aux inscriptions et catégories éligibles selon politique active. **Jamais** une remise uniforme sur tous les membres ; **jamais** la grille plus ancienne des deux premiers membres remisés.

Tests d'exemples d'un mois normal : deux enfants **100 USD** ; trois enfants **145 USD** ; quatre **188 USD** ; cinq **231 USD** ; deux enfants + un adulte **155 USD**. Un foyer existant et un mois partiel suivent les règles de l'application, pas celles d'une démo publique.

### 13.3 Simulateur tarifaire du site et de la page Tarifs

Un unique composant : bouton secondaire bordé transparent **`Simuler mon tarif`** ouvre un **petit modal** `Estimez le tarif de votre foyer`. Champs `Nombre total d'élèves`, `Enfants`, `Adultes`, initialement `1,1,0`, entiers non négatifs, somme obligatoirement cohérente ; calcul automatique dès validation, sans bouton « Calculer ». Résultat `Total mensuel` + remise, ventilation et détail replié. Si composition incohérente : expliquer sans corriger automatiquement. Mois normal complet, régime normal, non contractuel, taxes éventuelles mentionnées sans taux inventé.

**Branchement obligatoire à la politique admin publiée** : projection publique non sensible, simulation côté service canonique avec version, date d'effet, catégorie, remise, total, devise et statut fiscal. Une modification admin actualise cartes, exemples et modal sans publication de nouveau build ; cohérence d'un seul snapshot et pas de mélange de versions. Si politique absente, afficher `Le calcul est momentanément indisponible`, **jamais** anciens chiffres hardcodés. Le devis réel de l'inscription calcule taxes, prorata, rangs effectifs, pauses et aides via le moteur financier, non la démo. Ne pas montrer coût enseignant, marge ou dossiers dans la projection publique.

### 13.4 Solde et encaissements

Recharge par profil et allocations vérifiées serveur ; retour de navigateur de paiement n'est pas une preuve d'encaissement. Idempotence des webhooks et unicité prestataire/environnement/opération. Une somme en transit ne devient pas « disponible ». Mensualité non débitée par fraction involontaire ; factures payées non réécrites par modification de politique. Gestion contrôlée : pause/arrêt, exonérations et bourses selon quotas et décision admin. Quota institutionnel retenu dans les décisions financières : **au plus 3 bourses pour 100 élèves payants**, puis d'autres aides particulières suivent leur politique, sans publication de situation sensible.

### 13.5 Payouts et droits du Comptable

La verticale Comptable **existe comme spécification et a du code sur des branches dédiées** ; lire le vrai `ui/comptable-v1`, les ports `CPT-BR-01` à `CPT-BR-17`, `CPT-Q1` et l'intégration réelle avant de reconstruire. Centre opérationnel : `Aujourd'hui`, obligations/payables, bénéficiaires/méthodes masquées, encaissements/rapprochements, trésorerie et coffres, contractuels, validations, remboursements, journal.

Le Comptable ne crée pas librement le montant d'un enseignant. Préflight serveur d'un payout : bénéficiaire, obligation/version, montant, frais/corridor réel, statut, plafonds par opération/batch/période, exclusions et validation indépendante si sensible. **Même obligation/version jamais payée deux fois, même avec une nouvelle clé d'idempotence**. Une modification de coordonnées ou recalcul rend le préflight caduc. Paiement soumis ≠ paiement réussi : succès uniquement sur preuve prestataire. Tout remboursement, transfert de coffre protégé ou approbation sensible utilise un grant et un journal. Jamais d'auto-approbation, d'auto-payout illégitime, de contournement par fractionnement ni de lecture de compte bancaire complet.

### 13.6 Coffres et Réserve

Les **sept coffres** et leurs règles existantes sont conservés depuis les specs Finance : ne pas redéfinir leurs noms/affectations sans la source. Fonds des clients et taxes restent protégés, la trésorerie libre est calculée séparément. Réserve stratégique : politique cible montant ou mois de charges, cadence, alimentation, historique, indicateurs, retrait sensible à validation. La Direction peut publier une nouvelle politique selon son droit, sans reclassifier rétroactivement des flux passés.

### 13.7 Essai, accès et prestataires

Le contrat antérieur prévoit jusqu'à **2 séances d'essai**, une séance ouverte non honorée peut être consommée et une séance annulée par Rewayah n'est pas consommée ; conservation de place **7 jours** selon configuration. Ne pas déclarer l'essai *gratuit* sans preuve commerciale. Le droit d'entrer en salle est un **entitlement serveur**, pas `solde >= prix` en Flutter. N'afficher Stripe, Wise, Onafriq, Paystack, Mobile Money ou tout autre prestataire comme utilisable que si son corridor pays/devise/opérateur est effectivement activé et testé.

### 13.8 Recette finance anti-catastrophe

Double webhook ; paiement partiel ; double clic recharge ; deux profils sur paiement externe unique ; remboursement après débit ; professeur absent ; cahier non validé ; remplacement ; carte expirée ; montant changé après approbation ; coordonnées bénéficiaire remplacées ; payout déjà soumis avec autre clé ; transfert coffre protégé refusé ; délégué suspendu ; comptable bénéficiaire de son propre paiement ; devis public politique v1 et v2 ; arrondi/fuseau/date d'effet ; données de deux organisations et deux foyers. Montrer écritures comptables équilibrées, états réconciliés et preuves d'accès.

---

## 14. G11 - Administration et Direction : cockpit réel, sans second système

### 14.1 Navigation canonique

Réutiliser le shell admin existant et ses domaines : **Opérations**, **Personnes**, **Pédagogie**, **Finance** selon capacités, **Configuration**, **Sécurité et audit**, **Direction** seulement pour les capacités effectivement accordées. Les écrans de diagnostics/progression/évaluations/programmes/qualité `ADM-10..14` existent en référence ; les améliorer sur place.

### 14.2 Capacités administratives nécessaires

- Dossiers et identité : inscription, enseignant KYC, élève et tuteur, personnes et habilitations, refus motivés, historique et notifications.
- Offres/Classes : publier créneaux, voir intentions, regroupements, créer Classe, confirmer enseignant, remplacement, transfert, capacités et conflits.
- Pédagogie : décisions d'entrée, programme versionné publié, corrections autorisées, exceptions, revue qualité, habilitations d'évaluation et jury.
- Finance : prix/remises/version/date d'effet, exonérations, bourses, politique de partage, accès aux opérations selon délégation, sans remplacer le Comptable.
- Communications : annonces et fils métier avec permissions, Studio si autorisé, file d'envoi et preuve d'état.
- Sécurité : journal d'accès sensible, sessions/appareils, incidents, exports légitimes et empreinte d'audit ; ne pas créer de « Direction » visible sans capability serveur.
- Recherche : par périmètre, sans dévoiler pièces KYC ou membres d'une autre Classe en réponse.

### 14.3 UX de décision

L'accueil est un **centre d'attention**, pas une page d'actions mortes. Chaque compteur ouvre l'objet, son filtre et sa capacité réelle ; si la destination/contrat est absent, ne pas afficher comme CTA fonctionnel. Les écrans volumineux sont paginés et filtrables. Toute action irréversible : portée, avant/après, motif lorsque prévu, éligibilité, préflight et accusé serveur. Aucun écran Settings ne devient le refuge d'une fonctionnalité métier.

### 14.4 Politique d'accès

Même un compte global `admin` suspendu ne lit pas l'historique ou ne rejoint pas une observation avec des claims JWT périmés. Réauthentification/MFA pour accès sensible selon politique ; `SECURITY DEFINER` minimaux, `search_path` fixé, grants et audit. Les mises à jour de tarif et de partage ne sont pas des interrupteurs optimistes sans confirmation serveur.

---

## 15. G12 - Contrôleur : mission, preuve, confidentialité

### 15.1 Ne pas réécrire le module déjà travaillé

Le Control cockpit historique comporte le shell **`Contrôle · Historique · Échanges · Compte`** et des expériences de mission/observation déjà conçues. Inspecter `ui/controleur-v1` / branche effective et les ports CT/CTR avant tout changement. Ne pas réintroduire le **planning global** que la refonte a volontairement éliminé de l'accueil : une **carte de mission** avec `Commencer le contrôle` lorsqu'une séance est réellement ouverte.

### 15.2 Invariants métier

MFA obligatoire. Le contrôleur ne devient pas un élève, ne diffuse ni micro ni caméra en observation, ne reçoit pas le contenu KYC ou les finances. Il accède uniquement au roster **minimal autorisé** et au périmètre d'une mission active. Son identité n'est pas divulguée aux familles/enseignants au-delà de la politique ; vérifier les annonces de présence spécifiques, les notifications et les exports. Rapport brut réservé à son auteur et à l'administration habilitée, transmission et audit suivant contrat ; les fils de contrôle ne portent pas par inadvertance le prénom de l'élève si le contrat l'interdit.

### 15.3 Suivi et rétention

Conserver la durée du rapport brut prévue par décision du 02/10 : **12 mois après envoi**, prolongée si un dossier ou une mesure demeure ouvert, sous réserve de conformité légale ; délai de contestation **7 jours après publication de la synthèse mensuelle** dans le workflow validé. L'UI présente la source de ces délais et la date effective, pas une date de suppression calculée approximativement sur l'appareil.

### 15.4 Recette

Mission non assignée, expirée ou annulée ; appareil non MFA ; session suspendue ; observation sans média publié ; rapport hors ligne en brouillon ; envoi idempotent ; rapport corrigé ; échange sur un cas ; contestation recevable/tardive ; recherche dans ses seuls rapports ; export administrateur uniquement ; tentative d'ouverture d'une mission d'un autre contrôleur ; reprise après perte réseau. Les données de mineurs restent cloisonnées jusque dans les erreurs.

---

## 16. G13 - Communications, Studio, notifications et recherche

### 16.1 Une messagerie métier, pas un réseau social improvisé

Réutiliser COM-BR-01..16 : fils rattachés à des objets métier et paires d'acteurs autorisées, vocaux et pièces dans les limites prévues, annonces, communauté d'enseignants et Studio. Les messages envoi/reçu/lu ne sont pas des preuves d'un changement de Classe, de paiement ou de décision académique. Toute communication sensible, suppression et conservation suit la politique active ; objectif historique de **60 jours maximum** pour certains contenus doit être vérifié contre la politique finale et les obligations, pas imposé à tous les journaux.

### 16.2 Notification utile

Événements : demande reçue, Classe constituée, enseignant confirmé, cours déplacé/annulé, rappel T-20, évaluation planifiée/appelée/décidée, compte rendu familial publié/révoqué, écart du solde, rapprochement/payout, mission de contrôle, demande de support. Chaque notification comprend `objet`, `contexte`, `destinataire autorisé`, `état confirmé`, lien canonique et version. Sur ouverture, **revalider les permissions** ; pas de noms ni motifs sensibles dans les notifications d'écran verrouillé si confidentialité l'exige. Une notification perdue ne casse jamais la machine métier.

### 16.3 Recherche commune RECH

Contrat de recherche spécialisé **par domaine et contexte**, pas un index universel de toutes les notes et personnes. `rechercherApp` répartit vers `rechercherDomaine` dans les seuls périmètres permis par le serveur. Les champs interrogés doivent être **des champs que l'appelant est autorisé à lire** ; un champ caché ne doit même pas influencer suggestions, score, count ou snippet. Matricules RA et codes EV en égalité exacte selon scope. Recherche message **dans son module Messagerie/Studio**, barre globale limitée aux fils et objets autorisés ; chercher un autre mot privé ne doit pas « révéler l'existence » du fil.

### 16.4 Projection par rôle

- Guidée : quelques supports propres, sans annuaire.
- Adulte : ses Classes, supports, évaluations, annonces et fils.
- Tuteur : enfants liés, cours, foyer autorisé, offres et communications.
- Enseignant : Classes/élèves effectivement affectés, y compris remplacement **pendant validité seulement**.
- Contrôleur : missions, rapports et fils sans KYC.
- Comptable : obligations, bénéficiaires masqués, références autorisées, sans dossiers pédagogiques.
- Admin : champs du domaine qu'il gère et pour lesquels il possède une capacité, KYC en surface dédiée.
- Public : publications et offres réellement publiques, jamais l'annuaire interne.

### 16.5 Architecture et recette RECH

Départ PostgreSQL avec indexes B-tree/GIN/`pg_trgm` sur corpus autorisés et représentation de recherche du Coran **séparée du texte canonique**. Pagination par curseur lié à l'appelant/contexte/filtre, anti-rejeu, annulation des requêtes obsolètes, debounce autour de 250 ms et vingt résultats/page comme **cibles initiales non mesurées**. p95 SQL ≤150ms et API ≤400ms sont des **objectifs de performance à mesurer** sur staging représentatif, non un résultat. Ne pas multiplier les appels n+1 ni utiliser un taux de pertinence calculé avec contenu inaccessible.

Tests : foyers A/B, Classes parallèles, remplacement expiré, champ privé, compte suspendu, curseur croisé, pagination et droits révoqués en cours, texte FR/EN/Poular/arabe, translittération et diacritiques, recherche du Coran vocalisé/non vocalisé, XSS SQL, surcharge et panne d'un domaine. Aucun cache privé partagé. La page de destination contrôle **à nouveau** l'accès.

---

## 17. G14 - Site public : identité, visuels, tarifs, conformité

### 17.1 Direction visuelle figée au 09/10

Construire **un seul site**, pas huit headers ni huit pseudo-pages de landing. Thème sombre retenu pour la landing : **fond continu `#1A1A25`** suivant jeton effectif, sans gradients ni nouveaux aplats ; sections transparentes ; logo officiel **SVG blanc**, navigation à droite `Cours · Familles · Tarifs · Articles · Se connecter`, logo à gauche, même marge. CTA principal `Commencer mon inscription` lavande modérée ; secondaire bordé transparent `Voir comment ça marche`. Désencombrer le hero : enfant à son bureau face à enseignant **uniquement dans l'écran de l'ordinateur**, sans fragment du foyer flottant au hero. Extraits de l'application inclinés et anonymisés dans les sections appropriées, lisibles et non trompeurs.

Dossiers sources Windows fournis par la direction : `C:\Users\dell\Downloads\RA logo 2026\visuels site public` et `C:\Users\dell\Downloads\RA logo 2026\RA logo SVG`. Claude doit **inspecter les vrais fichiers sur son poste**, copier les assets valides en ressources versionnées, vérifier les droits, dimensions, formats et hashes ; **ne pas capturer des personnages à partir de maquettes composites**. Le pack autonome `REWAYAH_ASSETS_PERSONNES_2026-10-09.zip` a aussi été préparé. S'il manque un asset sur sa machine, déclarer précisément le fichier manquant, ne pas le remplacer par une invention.

### 17.2 Section et parcours publics

Landing en huit temps : **Hero → Foyer → Cours → Suivi parental → Inscription/horaires → Tarifs → Académie/confiance → Articles/FAQ/footer** selon structure canonique du plan du site. Cours : enseignants réels selon preuve, public enfant/adulte, fréquence, horaires, durées, capacité, programme ; le parcours d'achat explique qu'une demande de créneau ne réserve pas une Classe. Les familles ne « choisissent pas leur professeur » dans une offre vitrine. Recrutement enseignants et personnel, contact et aide fonctionnels, pas de formulaire qui prétend avoir envoyé une candidature s'il n'existe aucune réception.

### 17.3 Barème et modal

Appliquer intégralement G10 et la **section 6.1** du plan site du 09/10. Afficher la même version des tarifs dans carte, page Tarifs et simulateur. Les exemples doivent être recalculés après modification admin, les taxes non inventées. La modal ne nécessite pas compte et ne crée ni réservation ni paiement.

### 17.4 Identité légale et conformité

Lancement académique **01/05/2024**, distinct de l'immatriculation ultérieure. Société **REWAYAH ACADEMY LTD**, numéro **16624644**. Adresse de siège retrouvée dans les justificatifs : **71–75 Shelton Street, Covent Garden, London, WC2H 9JQ** ; contrôler l'extrait Companies House courant et le droit d'usage avant publication définitive. Contacts publics : **contact@rewayahacademy.com**, **support@rewayahacademy.com**, **recrutement@rewayahacademy.com** et **invoice@rewayahacademy.com** selon contexte ; **jamais l'adresse privée de connexion**. **Aucun numéro de téléphone public**. Ne pas publier un UTR ou numéro de bureau fiscal comme numéro de TVA.

Conformité à tester avant ouverture commerciale : mentions, conditions de service et de vente territorialisées si nécessaire, remboursements et annulation, confidentialité et mineurs, cookies réels, accessibilité, consentements, TVA/statut fiscal vérifié, mode de règlement effectif, descriptions d'essai honnêtes, support et droits des consommateurs. Ne pas affirmer `certifié`, `garanti`, `100 % sécurisé`, `gratuit`, partenariats bancaires ou chiffres de clientèle sans preuve.

### 17.5 UX et performance

Vrai mobile 390, tablette et desktop 1440/1920 ; fond fixe, défilement natif, aucune interception souris, sticky seulement si la lecture reste possible, mouvement réduit, focus/contraste/zoom, poids d'assets et taille de rendu contrôlés. Vérifier les liens entre `/fr/...`, `/connexion` et les routes Flutter sans boucles. La PR de prévisualisation #8 n'autorise pas la publication ; comparer la prévisualisation à la version validée du 09/10 et aux assets exacts.

---

## 18. G15 - Design system transverse et écrans : règles de fabrication

### 18.1 Tokens et composants

Matériel Flutter existant, Material 3 et comportements Cupertino pertinents. Typographie actuellement décidée : **DM Sans** pour titres français, **Plus Jakarta Sans** pour reste du latin, police arabe existante ; pas de police substituée sans validation. Palette quasi monochrome calme, accents lavande limités, clair et sombre consistants. **Vérifier les tokens existants au HEAD** ; un chiffre de couleur du site n'autorise pas à repeindre les écrans internes. Le thème n'est pas reconstitué dans chaque widget.

Une **carte groupée** porte une fonction principale et des lignes séparées par de faibles filets. Une seule action principale pleine par zone. Navigation stable, retour touchable en bas si requis par les visuels validés, vraies compositions tablette/desktop au lieu d'un mobile élargi ; respecter safe areas. Photo enseignant obligatoire sur les cartes réelles de Classe vues par famille, jamais dans l'offre vitrine ; si photo absente, état prévu par la politique, pas un portrait inventé.

### 18.2 Aucun écran sans états

Chaque écran et chaque module : `loading`, `content`, `empty`, `error`, `offline`, `permission denied` si pertinent, `stale`, `submitting`, `pending confirmation`, `conflict`, `success confirmed` et `retry`. Un skeleton ne remplace pas l'état vide. Une action bloquée indique **pourquoi** et la marche suivante autorisée, sans faux succès. Aucun spinner perpétuel.

### 18.3 Accessibilité et internationalisation

Français professionnel clair, arabe conforme à son sens, anglais et poular selon périmètre effectivement traduit. Pas de traduction automatique de versets. RTL correct sans inverser le texte canonique arabe ; alignements et retour adaptés aux écritures. WCAG 2.2 AA visé, contraste ≥4,5:1 sur texte courant, ≥3:1 pour composants graphiques pertinents, cibles tactiles cible produit au moins 48 dp, lecteur d'écran, ordre de focus, clavier desktop, zoom 200 %, orientation, réduction du mouvement. Les erreurs critiques ne sont jamais uniquement colorées.

### 18.4 High-fi et confiance visuelle

Les fichiers visuels validés guident la retouche **du code existant**, sans réinvention libre ; ne pas créer une maquette nouvelle lorsqu'un écran est déjà conforme. Avant tout nouvel écran, catalogue de routes/fiches et audit des composants. Tests de capture light/dark, 390 / tablette / 1440, erreurs et longueurs de langue ; comparer aux références par zones clés et non à une note de goût.

---

## 19. Validation contradictoire spécialisée : protocole sans fausse caution

Claude orchestre des **revues contradictoires internes** par spécialisations, à effectifs d'agents disponibles et sans prétendre qu'un expert humain externe a approuvé le produit. Tous lisent les décisions en vigueur, le code et les tests ; leur sortie est traçable.

| Relecteur spécialisé | Question à fermer | Preuve exigée |
|---|---|---|
| Produit / parcours | Chaque tâche trouve-t-elle sa vraie destination, sans doublon ? | Carte routes → actions → états → rôle |
| Pédagogie coranique | Enseignement, niveaux et gates respectent-ils le référentiel versionné ? | Décision source + scénario niveau/exception |
| Psychométrie / jury | Résultat, quorum, réévaluation et certification évitent-ils les faux verdicts ? | Transitions + cas incomplet/divergent |
| UX/HCI, enfance | Charge cognitive raisonnable, guidée et adulte distincts ? | Parcours chronométrés, captures et heuristiques |
| Accessibilité | Clavier, RTL, contraste, lecteurs d'écran, zoom ? | Tests et captures 200 % |
| Sécurité / mineurs | Un refus cache-t-il réellement données, résultats, pistes et compteurs ? | Tests d'accès positifs **et négatifs** |
| Systèmes distribués | Concurrence, idempotence, reprise et mise à jour multi-appareils ? | Tests de courses, versions, webhook doublé |
| LiveKit / temps réel | Supports et média restent cohérents après reconnexion ? | Tests de coupure + logs anonymisés |
| Finance / conformité | Flux équilibrés, prêts/dettes séparés, preuves prestataires et droits ? | Ledger + tests fraude/double paiement |
| DBA / performance | Index, RLS, plan SQL, pagination, capacité cohérente ? | Benchmarks sur staging représentatif |
| Juridique / privacy | Politique contractuelle/retention/cookies/mineurs fondée sur faits ? | Liste de vérifications et validation compétente si nécessaire |
| QA / chaos | Scénarios de rupture reproduits et non régressions ? | Résultats horodatés sur SHA |
| Red team simplicité | Quels écrans/services peut-on **ne pas construire** ? | Liste anti-doublon avec preuves |

Chaque relecteur classe ses observations : `preuve`, `contradiction`, `risque`, `correction demandée`, `accepté comme dépendance`, `sans action`. Aucun « comité valide à 100 % » sans tests exécutés et approbations pertinentes. Si les évaluations internes divergent, noter l'argument et appliquer la décision produit la plus récente ; ne solliciter la direction que pour un **véritable nouvel arbitrage commercial, pédagogique, juridique ou sécuritaire** impossible à déduire.

---

## 20. Recette maître multi-rôles et critères de fin

### 20.1 Scénarios E2E prioritaires

| ID | Enchaînement à démontrer | Critère de réussite |
|---|---|---|
| E2E-01 | Tuteur nouveau, 2 enfants → choix d'offres → intentions → Classe → enseignant | Source réelle, pas de faux siège ni fuite |
| E2E-02 | Plusieurs intentions concurrentes → Classes parallèles → séances | Idempotence, capacités et horaires corrects |
| E2E-03 | Adulte autonome → inscription → Classe → visio → progression → solde | Aucune fiction de profil enfant |
| E2E-04 | Enseignant validé → Classe réservée → préparation → trois séances → K-45 | Même professeur, cahier 45s cible, présence prouvée |
| E2E-05 | Élève guidé rejoint, suit support, récite, prépare travail | Visio autorisée, UX simple et résiliente |
| E2E-06 | Tuteur observe deux fois et lit historique | 2×2 minutes côté autorité, micro/caméra off |
| E2E-07 | Cahier confirmé → projection partageable → tuteur lit → admin révoque | Aucune lecture après révocation, historique gardé |
| E2E-08 | Élève consolide → candidat proposé → passage → jury optionnel → action | Aucun échec lié à réseau ou faux certificat |
| E2E-09 | Évaluation annoncée ouverte → audience active et candidat mineur | Permissions média/résultat/cloisonnement inchangés |
| E2E-10 | Tarif admin changé → site + modal + devis contractuel | Version de politique cohérente, factures payées stables |
| E2E-11 | Recharge de deux profils → preuve prestataire → solde → facture | Allocation vérifiée, pas de double crédit |
| E2E-12 | Cahier validé → dette enseignant → préflight → validation → payout | Aucune double obligation ni auto-approbation |
| E2E-13 | Contrôleur MFA → mission → observation → rapport → contestation | Identité protected, périmètre limité, dates fiables |
| E2E-14 | Recherche chaque rôle → résultat → deep link → suppression droit | Recherche et destination refusent identiquement |
| E2E-15 | Coupure réseau pendant cours/paiement/évaluation | Reprise ou état inconnu honnête, jamais double effet |
| E2E-16 | Site public → contact/recrutement/CGV → inscription | Routes et réception prouvées, droits et TVA vérifiés |
| E2E-17 | Deux foyers/Classes différentes → cross-account / cached data | 0 donnée croisée, y compris widgets et exports |
| E2E-18 | Suspension d'un compte staff en cours de session | Refus côté API et LiveKit, pas uniquement bouton caché |

### 20.2 Matrice d'appareils et d'états

Test au minimum sur téléphone étroit ~320 dp, téléphone ~390, tablette portrait/paysage, desktop 1024 et 1440+, Safari iPad/iOS si accessible, Chrome Android/Windows/PWA, clavier seul et lecteur d'écran. Modes clair/sombre, 200 % de texte, français long, arabe RTL, réseau intermittent et changement de fuseau ; préciser `NON TESTÉ` pour appareil non disponible. Aucun tableau horizontal impraticable sur mobile.

### 20.3 Métriques de performance à **mesurer**, pas à affirmer

Cold start/PWA, poids bundle, mémoire sur bas de gamme, latence d'accès salle, délai de synchro support, erreurs réseau, temps médian pour faire le cahier, % de missions accomplies, recherche p95/p99, requêtes SQL et contention des inscriptions, coûts visio/storage/egress. Ajouter métriques d'échec et alertes orientées actions, sans journaliser requêtes privées, tokens, identifiants sensibles ni contenu des enfants.

### 20.4 Gate de publication

**GO partiel** possible seulement sur une surface sûre réellement prouvée, avec feature flags ou refus honnêtes pour le reste. **NO-GO** si, sur le périmètre lancé, présence de Classes démo présentées comme réelles ; migration divergente ; staging connecté à PROD par erreur ; fuite inter-foyers ; lien KYC public ; payout duplicable ; faux succès paiement/évaluation ; enregistrement annoncé sans preuve ; LiveKit non sécurisé ; contrat tarifaire trompeur ; statut juridique/taxes non résolus pour un parcours payant ; absence de reprise/sauvegarde pour mutation sensible.

Le rapport GO/NO-GO liste expressément : fonctionnalités ouvertes, refusées et temporairement masquées, environnements, SHA, tests, limites et autorisations écrites. **On n'invite pas de familles réelles à tester une fonctionnalité critique en supposant qu'un échec serait une simple imperfection UI.**

---

## 21. Plan d'exécution anti-va-et-vient

**Le directeur reçoit un dossier unique et, à la fin, un compte rendu global.** Les agents peuvent faire leurs itérations internes, tests et corrections, mais ne reposent pas les mêmes questions métier. Travailler en lots petits, atomiques et intégrables, en respectant l'ownership.

### Vague 0 - Audit et contrats (lecture seule)

Comparer ce dossier aux `docs/current/` du HEAD, à la feuille de liaison et aux PR ; inventaire de tous les modules existants avec preuves ; produire les contrats d'écart réellement nécessaires. Pas de code métier tant que l'on ne sait pas quel module est déjà implémenté. Lister les changements bloquants d'API séparément pour Codex.

### Vague 1 - Sécurité et parcours d'inscription (P0)

G01, G02, contrôles G00 : adultes autonomes, identités, foyer, offre et Classe, permissions. Raccorder le chemin complet **sur staging**, protéger le serveur et valider les capacités. En parallèle côté frontend si zones séparées : finitions Tuteur/Élève enfant et adulte.

### Vague 2 - Salle et après-cours (P0)

G03, G07, G08 : réutilisation du Teaching Core, connexion LiveKit, K-45, observation, rapports partagés, progression. Préserver les décisions visuelles et test mobile + desktop.

### Vague 3 - Évaluations et contrôle (P1)

G09 et G12 : interfaces évaluateur/jury, administration ADM-12 et contexte salle, Interface guidée, contrôleur. Les dépendances backend sont des contrats sans nouveau serveur imaginé par Claude.

### Vague 4 - Finance, Communications, Recherche (P0/P1)

G10-G13 : corriger et raccorder les modules déjà conçus, isoler chaque effet sensible, simuler sans paiement réel. Si l'accès à la Classe dépend de la Finance, son **entitlement** minimal doit avoir été prouvé dès la Vague 1 ; on ne reporte pas cette sécurité.

### Vague 5 - Site, cohérence publique et recette

G14-G15 : nouvelles images et logo, simulateur lié à la politique, mentions contractuelles, parcours de recrutement, tests E2E, sécurité, QA, audit final de PR, rapport des limites. Aucune publication sans approbation de la direction.

### Parallélisme sûr

Frontend de plusieurs **écrans indépendants** peut avancer si les composants du shell/routeur/design system sont possédés par un intégrateur unique. Le backend des classes/finance/recherche peut avancer en parallèle uniquement sous ownership explicite des migrations et contracts. Tout changement de `supabase/migrations/`, `lib/core/capacites/`, des tokens, routeur ou `.github` passe par le responsable désigné ; **pas de commits croisés opportunistes**. Les revues de Code X/Claude sont dans le cahier d'intégration, pas dans une discussion sans preuve.

---

## 22. Définitions de terminé et livrables exacts

### 22.1 Par lot

Chaque lot doit fournir :

1. `SCOPE` : exigence source, comportement, critères et rôles.
2. `INVENTAIRE` : SHA, routes, écrans/ports/RPC déjà présents, preuves anti-doublon.
3. `DELTA` : fichiers modifiés, avant/après, éventuels migrations/contrats **dans la zone autorisée uniquement**.
4. `SECURITY` : permissions réelles, chemins de fuite testés, régressions inexistantes.
5. `UX` : états, messages, navigation depuis une vraie entrée, captures aux formats requis et test accessibilité.
6. `QA` : commandes réellement exécutées, sorties, comptages, environnement, SHA et échecs documentés.
7. `INTEGRATION` : adaptateur réel ou raison d'indisponibilité, preuves staging, feature flags si nécessaire.
8. `RESTE` : dépendance authentique, propriétaire, gate, sans question déjà résolue.

### 22.2 Dossier final attendu dans le dépôt

Le coordinateur maintient un dossier sous `docs/current/` (nom adapté après vérification de l'arborescence) contenant : `00_INVENTAIRE_ET_GATES.md`, `MATRICE_COUPLAGE_FRONT_BACK.md`, `RECETTE_E2E_RESULTATS.md`, `RISQUES_ET_GATES_PROD.md` et `BILAN_FIN_DE_LOTS.md`. **Ce sont des sous-produits de preuve, non des nouveaux cahiers des charges concurrents.** La présente spécification reste le mandat unique ; les rapports consignent l'exécution, pas de nouvelles décisions produit cachées.

### 22.3 Critère terminal

L'ensemble est livré quand les rôles atteignent leurs fonctions de bout en bout en staging, que les opérations sensibles sont garanties par le backend, que les montants et données affichés sont exacts, que les écrans sont conformes aux high-fi et accessibles, que tous les scénarios du périmètre lancé sont verts et qu'un rapport de production distinct conclut à GO sur les seules capacités prouvées.

---

## 23. Prompt maître à transmettre tel quel à Claude Code

> **MISSION : REWAYAH - EXÉCUTION CONSOLIDÉE DES LOTS RESTANTS**
>
> Tu es le tech-manager d'intégration UX/UI Flutter de Rewayah Academy. Le fichier `REWAYAH_SPECIFICATIONS_FINALES_LOTS_RESTANTS_2026-10-12.md` est le mandat global, et non une permission de recréer l'application. **Lis-le entièrement une fois**, puis suis `CLAUDE.md` et `docs/current/` du HEAD réellement actif. Vérifie en lecture seule ton arbre Git, tes worktrees, toutes les PR et la feuille `docs/orchestration/COHABITATION.md`. Les décisions datées du directeur et les spécifications de domaine récentes priment sur les documents archivés.
>
> **Interdit de commencer par du code.** Établis d'abord, à partir du dépôt, une matrice exhaustive par rôle et parcours : `décidé / codé / routé / raccordé / test local / test staging / bloqué`, avec fichier/ligne/commit/port/rôle. Ne te fie pas à l'ancien `HANDOFF` ni à une maquette pour déclarer terminé. N'annonce aucun blocage produit si la décision est déjà dans les documents datés.
>
> Charge des agents indépendants de critiquer l'architecture produit, l'UX/HCI, la pédagogie, l'évaluation/jury, les mineurs et la confidentialité, l'accessibilité, LiveKit, les systèmes distribués, la performance, la finance et les tests. Ils **ne modifient pas les sources pendant la revue**. Confronte leurs conclusions et élimine les doublons. Ce protocole interne ne vaut pas certification humaine externe.
>
> **Ensuite, implémente les deltas frontend seulement**, un lot atomique à la fois selon les Vagues 0-5. Réutilise obligatoirement les écrans, ports, services, composants, jetons et high-fi existants. Une fonction = un lieu. Ne touche pas aux migrations/RLS/RPC/Edge/LiveKit core ni aux zones Codex. Tout manque de contrat est décrit précisément à Codex via la liaison, et produit un état frontend honnête ; pas de fixture réelle, d'écran de succès artificiel ni de hack de permission. Les Évaluations V2 du 12/10 restent frontend only. Pas de PR vers `main`, merge, push PROD ni publication sans ordre explicite.
>
> **Priorité métier :** finaliser les passages famille/adulte → offre → Classe stable → professeur → séance → K-45 → progression ; puis évaluation/jury ; puis finance, contrôle, recherche, communications et site. Vérifie que le frontend Enseignant/Tuteur/Comptable/Contrôleur ne soit pas reconstruit s'il répond déjà aux besoins. Les fonctions absentes mais pertinentes doivent être réellement complétées, pas seulement dessinées.
>
> **Après chaque lot**, exécute les analyses/tests pertinents (`dart run slang`, `build_runner` si impacté, `dart analyze --fatal-infos`, `flutter test`, `tool/verifier_jetons.dart`, tests route/tap et captures) et fais relire les contrats côté serveur par leur propriétaire. Pour un backend raccordé, exige la preuve de scénarios RLS/SQL et staging sur SHA exact. Une fonction n'est dite terminée que si elle est atteignable, autorisée, raccordée, accessible, responsive et testée.
>
> **Rapport final unique** : matrice avant/après, tests par rôle, captures mobile/tablette/desktop clair-sombre, résultats E2E, liste de PR/commits/SHA, dépendances Codex et liste très courte des seuls arbitrages réellement nouveaux. N'envoie pas au directeur une question de confort, un choix de nom de variable ou une nouvelle maquette s'il en existe déjà une validée. **Ne substitue pas des affirmations à des preuves.**

---

## 24. Sources documentaires principales utilisées pour la consolidation

**GitHub (références accessibles à la lecture, état à rafraîchir) :**

- `https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App` ; `CLAUDE.md`, `docs/current/00_LIRE_D_ABORD.md`, `08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md`, `01_PRODUIT_ET_PARCOURS.md`, `06_SPEC_FONCTIONNELLE_MVP.md`, `DECISION-OFFRES-GROUPES-2026-10-09.md`, `DECISION-CLASSES-SIMULTANEES-2026-10-10.md`, `docs/orchestration/COHABITATION.md` (branche ccr consultée le 12/10).
- PR #8 site, #21 F2, #26 staging, #29 F1, #31 admin et #32 provenance migration, #33 fusion intermédiaire au relevé du 10/10 ; **ne pas conclure que leurs états sont restés inchangés**.

**Bibliothèque Rewayah App, spécifications récentes :**

- `REWAYAH_PED_00_CADRAGE_PARCours_MULTI_ROLES_2026-10-10.md`.
- `REWAYAH_PED_APRES_SPEC_VERTICALE_V1_2026-10-11.md` et visuels associés.
- `REWAYAH_PED_PROGRESSION_SPEC_VERTICALE_V1_2026-10-11.md` et visuels associés.
- `REWAYAH_PED_EVALUATIONS_SPEC_DELTA_V1_2026-10-12.md`.
- `REWAYAH_EVALUATIONS_FINAL_SPEC_V2.md`, `REWAYAH_EVALUATION_SYSTEM_REVIEW_PRECLAUDE_V1.md`, `REWAYAH_EVALUATIONS_HIGHFI_BRIEFS_V1.md`, `HANDOFF_CLAUDE_EVALUATIONS_FRONTEND_V1.md`, `REWAYAH_EVALUATIONS_QA_MATRIX_V1.md` (12/10).
- `04_ENSEIGNANT(1).md` (12/10), à **auditer**, pas à assimiler à un ticket de refonte.
- `REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_2.md` ; `REWAYAH_COMPLEMENT_RECHERCHE_ET_PLAN_RESTANT_V0_1.md` ; `REWAYAH_RECH_02_HANDOFF_FRONT_BACK_INTEGRE_V2.md`.
- `REWAYAH_PLAN_SITE_ET_CONFORMITE_2026-10-07.md` corrigé au 09/10 et `REWAYAH_PLAN_VISUELS_SITE_2026-10-08.md` mis à jour 09/10 ; `REWAYAH_ASSETS_PERSONNES_2026-10-09.zip`.
- `REWAYAH_AUDIT_PREPRODUCTION_2026.md` pour les axes de revue non fonctionnelle ; ses constats plus anciens ne l'emportent jamais sur une décision actuelle.

**Limites honnêtes :** le présent travail est une consolidation documentaire avec lecture ciblée de GitHub et de sources Rewayah, **pas** une exécution de tests Flutter/PostgreSQL, une inspection de tous les fichiers du HEAD local, une validation juridique ou une approbation de production. Toute recette annoncée dans ce document est un **scénario à prouver**, non un test déjà réussi.


---

# ANNEXE 16 - Vérité métier et arbitrages - 29 septembre 2026

_Source : `REWAYAH_01_VERITE_METIER_ET_ARBITRAGES_2026-09-29.md`. Contenu conservé pour ne pas perdre les détails métier._


# REWAYAH ACADEMY - vérité métier et arbitrages

**29 septembre 2026. Statut : dossier de transmission au jury de recherche.** Les corrections explicites les plus récentes du directeur priment sur les précédents rapports et mandats. Une proposition figurant dans un document de septembre ne prouve pas une pratique appliquée depuis 2024.

## 1. Situation réelle

- L'académie enseigne depuis le 1er mai 2024. Aujourd'hui : **20 élèves payants au maximum** ; nouvelles inscriptions refusées depuis environ deux mois parce que l'exploitation manuelle est saturée. Le directeur enseigne aussi à 4 élèves, chacun trois fois une heure par semaine, soit 12 heures hebdomadaires de cours, et poursuit un master avec mémoire.
- Trois fondateurs guinéens vivant en Arabie saoudite, chacun avec plus de dix ans d'expérience personnelle d'enseignement avant l'académie. Le directeur assure presque seul prospection, admissions, correspondance, horaires, paiements, plaintes, supports, enseignants et développement de l'outil. Les deux autres ont des compétences avancées dans d'autres domaines et ne souhaitent pas manipuler la technique.
- Fonctionnement actuel : recommandations, page Facebook peu animée (environ 1 700 abonnés déclarés), Google Forms/Sheets, WhatsApp, Meet, Drive, Orange Money et virements. Stripe et Verto ne sont **pas les moyens actuels de collecte C2B** ; les liens Wise directs sont bloqués selon le directeur. Il n'a jamais fait de publicité significative : il a consciemment évité un afflux que l'organisation manuelle n'aurait pas pu servir.
- Modèle actuel : cours individuels, trois fois une heure par semaine ; négociation manuelle d'horaires, adaptation demandée au professeur, rappels et réclamations dispersés. Le goulot immédiat est la **conversion et l'exploitation**, tandis que l'ampleur de la demande marginale et le coût d'acquisition doivent être mesurés.
- Cibles : **1 000 élèves payants actifs au 31 décembre 2026**, puis **5 000 par mois** à un horizon à planifier. Ambition prise comme objectif de dimensionnement ; probabilité et budget non démontrés.

## 2. Décisions, propositions et questions ouvertes

| Domaine | Directive actuelle | Arbitrage encore nécessaire |
|---|---|---|
| Offre | Classes stables d'environ **4, 5 ou 6 élèves** selon le cas ; trois séances hebdomadaires, même enseignant sur tous les jours ; plusieurs classes par professeur. | Capacité par âge/niveau, seuil d'ouverture, durée et transition des anciens cours particuliers. |
| Prix familles | Les élèves paient **40 à 60 USD par mois** selon tarifs et remises famille. Le titulaire du foyer paie les bénéficiaires, conjoint compris. | Grille exacte, devise, remises, formule enfant/adulte, prorata et nombre de séances. L'ancien 50/90/40 n'est pas un tarif final. |
| Paie professeurs | **Proposition** : environ **20 USD par élève enseigné et par mois** pour 60 minutes enfants, éventuel bonus internet de 20 USD par enseignant/mois. Cinq élèves = 100 USD par groupe avant bonus. | En adulte 90 minutes, **30 USD par élève/mois** est une hypothèse de parité horaire à challenger face au prix 40-60 USD ; définir éligibilité, prorata, gratuité, remplaçant et garantie éventuelle. L'ancien 4 USD/h n'est plus la base. |
| Solde | Crédit prépayé nommé **solde** ; un solde par élève, total familial informatif, recharge un ou plusieurs profils, adulte autonome, chacun consomme le sien ; titulaire payeur. Compensation pour absence du professeur sans remplacement. | Solde en argent/crédits, débit par séance ou droit mensuel, expiration, report, remboursement, transferts, FX et traitement des mois de 12/13/14 séances. L'exemple ancien 50 USD → 30 unités → 12 séances n'est pas adopté. |
| Pédagogie | Directeur titulaire d'une licence en sciences coraniques et d'ijazat ; il valide le fond. Hafs ʿan ʿAsim ; Nour al-Bayân, Mushaf, Fatiha et sourates courtes jusqu'à Az-Zalzalah, Salat/ablutions et invocations quotidiennes en priorité. | Référentiel F1-F4/T1-T6/H0-H6/I1 **en étude depuis septembre 2026**, non appliqué historiquement ; textes, édition et droits à valider avant publication. |
| Relation familiale | Respect mutuel et autorité pédagogique de l'enseignant ; écoute, informations et recours des familles, sans suivre tous les caprices de rythme, sourate ou horaire. | Charte, discipline, préparation, absences, réévaluation, transfert et traitement juste des plaintes. |
| Marketplace | Patterns hebdomadaires complets, horaires selon fuseaux et routines, professeur constant, choix familiaux. | Deux états à distinguer : offre/intention avant professeur, puis classe effectivement affectée et réservable. Quel prix et quelle promesse à chaque étape ? |
| Collecte/payout | Collecte simple pour diaspora et payouts Mobile Money pour professeurs africains, peu d'intermédiaires, repli indépendant. PawaPay envisagé. | Vérifier LTD UK, cartes EU/US/Canada, pays professeurs GN/CI/SN/autres, frais, change, contrat, continuité ; aucun corridor n'est présumé actif. |
| Société | Directeur seul actionnaire inscrit UK selon lui ; trois fondateurs se conçoivent associés à parts égales ; directeur veut diriger opérationnellement seul. | Inventaire des droits réellement documentés et des informations prestataires ; aucune obligation de faire inscrire les deux autres comme étape du plan. |
| Salaire et diversification | Salaire du directeur indexé en partie sur CA avec **plancher garanti** proposé ; après réserve suffisante, trois sociétés où le dirigeant de chacune détient 70 % et les deux autres 15 % chacun. | Taux, base encaissée/facturée, plancher, statut, réserves ; mécanisme juridique de financement et propriété. Tout cela reste à négocier. |
| Infrastructure | Application en construction, LiveKit self-hosted évoqué, état exact et capacité non prouvés. | Comparatif managé/auto-hébergé, pics parallèles, coût complet, résilience, charge de vidéo/enregistrement et secours. **Mission de recherche : aucun code.** |

## 3. Contexte métier que le jury ne doit pas perdre

### Enseignement

- Cohortes évoquées : 6-9, 10-13, 14-17, 18+ ; aucune taille de classe automatique. Séance enfant 60 minutes avec courte pause, adulte 90 minutes dans les propositions récentes. Tester le temps réel de récitation et l'attention à 4/5/6 élèves.
- Résultats visés : lecture arabe vocalisée autonome, lecture coranique fluide, Salat, invocations essentielles, Hifz/révision selon orientation. Passage par maîtrise, jamais par paiement. L'enseignant garde le jugement pédagogique ; la famille peut demander une revue. Enseignement commun et progression individuelle bornée, particulièrement pour Hifz.
- Priorité actuelle : offre compréhensible en **une page** et guide des premières semaines pour les enseignants. Le texte produit en chat n'est pas un programme déjà enseigné. Le corpus de sciences islamiques générales ne doit pas être ajouté d'office au premier parcours coranique.
- Si l'élève est absent et que la séance est assurée, le service suit la politique publiée ; si le professeur manque et qu'il n'y a pas de remplacement, compensation. Un incident réseau indéterminé ne permet pas d'attribuer automatiquement une faute.

### Foyer et solde

- Un titulaire paie tous les profils du foyer, conjoint inclus, avec un **solde individuel par bénéficiaire**. La somme du foyer n'autorise pas automatiquement les transferts. Un enfant qui devient adulte conserve identité, historique et solde ; définir précisément le changement de payeur et de droits.
- L'académie ne règle pas les comptes privés des conjoints lors d'une séparation. Décisions récentes sur profils/foyer : changement encadré de titulaire et émancipation à 18 ans, à relire avant de fixer les règles de paiement.
- Séparer paiement confirmé, attribution à un profil, réservation de droit, consommation, libération, avoir et remboursement. Aucun solde ne se « corrige » en écrasant l'historique. Faire examiner la qualification réglementaire du solde fermé avant de promettre retrait/transfert ou stockage monétaire assimilable à un service de paiement.
- Questions ouvertes : devise d'affichage et de compte, date et taux de FX, session payée versus accès mensuel, prorata, paiements échoués, cours reportés, vacances, gratuité/bourses, geste commercial, expiration, remboursement, séparation du foyer.

### Organisation humaine

- Le directeur garde vision, produit, doctrine et recrutement des responsables ; il doit quitter le rôle de guichet WhatsApp, support technique et arbitre quotidien. Le plan ne suppose pas que les deux autres fondateurs puissent ou veuillent exploiter la plateforme.
- Enseignants : sélection académique, disponibilité sur tous les jours d'un pattern, formation aux outils, supports, réponse aux incidents, remplaçant, paiement stable, contrôle qualité sans prime à « valider vite ».
- Parents/élèves : informations autonomes sur objectif, prix, remises, classe, professeur, fuseau, absence, progression, paiement et aide ; procédures de réclamation claires, pas de négociation illimitée.

## 4. Contradictions à résoudre avant politique définitive

| ID | Contradiction | Livrable attendu |
|---|---|---|
| C01 | 4 enfants/5 adultes anciens, 5/6 V1, maintenant 4-6 au cas par cas. | Capacité validée par format et tranche d'âge avec essai pédagogique et marge. |
| C02 | 4 USD/h ancien, maintenant environ 20 USD/élève/mois ; enfant 60, adulte 90 minutes. | Paie par durée, remplaçant, minimum, bonus, cas gratuits et seuil de rentabilité. |
| C03 | Prix mensuel 40-60 USD et solde crédité/consommé ; ancienne unité 30/12. | Contrat unique entre recharge, droits, consommation, reports et remboursement, avec exemples datés. |
| C04 | Parents choisissent une classe affectée ou expriment une intention avant professeur. | Parcours commercial à états distincts et promesses non trompeuses. |
| C05 | Référentiel académique écrit en septembre versus cours réellement enseignés depuis 2024. | V0 signé par le directeur, formation, date d'effet et communication de transition. |
| C06 | Stripe primaire dans ancienne discussion, puis préférence faible intermédiaires ; Verto non C2B. | Tableau de prestataires contractuellement faisables et repli indépendant. |
| C07 | LiveKit self-hosted visé, déploiement réel et capacité inconnus. | Étude de pics, coûts, benchmark, SLA, sauvegarde opérationnelle. |
| C08 | LTD un seul actionnaire inscrit, projet perçu à trois associés. | Clarification documentaire et gouvernance, sans mutation automatique du registre. |
| C09 | Écoute client et autorité coranique de l'enseignant. | Charte des droits/devoirs et procédure de recours qui protège le groupe. |
| C10 | 1 000 en décembre, 20 aujourd'hui, aucune publicité historique. | Funnel, budget, capacité, scénarios, critères hebdomadaires et plan de repli. |

## 5. Règle de preuve

Documents internes disponibles : 00_LIRE_D_ABORD, 01_PRODUIT_ET_PARCOURS, 06_SPEC_FONCTIONNELLE_MVP, 07_MEMOIRE_PEDAGOGIE_FINANCE, REWAYAH_REFERENTIEL_ACADEMIQUE_V1, REWAYAH_TEACHING_CORE_MULTI_AGENTS_V1, conversations de septembre. Étiqueter toute affirmation **ACTUEL OBSERVÉ, DÉCIDÉ, PROPOSÉ, REMPLACÉ ou À VÉRIFIER**, avec date et source. Les fichiers décrivent souvent la cible de l'app, pas le fonctionnement actuel de l'académie. La dernière correction explicite du directeur prime.


---

# ANNEXE 17 - Politiques d’exploitation, offre, classes, relation familiale et continuité

_Source : `03_POLITIQUES_EXPLOITATION.md`. Contenu conservé pour ne pas perdre les détails métier._


# Livre des politiques d'exploitation — Renaissance V1.1

29 septembre 2026. **PROPOSÉ pour adoption**, non publié aux familles. Ce livre constitue la règle intégrée recommandée du jury ; les avis indépendants en annexes gardent leurs hypothèses et dissidences. Le directeur conserve les décisions de stratégie, de prix et de fond religieux. Aucun compte, contrat, publicité, paiement ou recrutement n'a été exécuté dans cette mission.

## 1. Périmètre, langue et lancement

La renaissance démarre avec **zéro nouvel élève et zéro enseignant confirmé**. Elle construit une nouvelle offre, équipe, plateforme et identité de marque. Poular, français et anglais sont prioritaires ; espagnol et autres langues attendent. L'afflux massif de candidatures attendu n'est pas une capacité acquise. Ne pas multiplier d'emblée trois langues × quatre âges × plusieurs niveaux × tous les fuseaux : ouvrir d'abord les quelques patterns qui disposent simultanément d'un professeur qualifié et d'une demande compatible.

Un propriétaire d'offre tient une fiche versionnée : public/niveau, langue réellement enseignée, jours et fuseau de référence, durée, professeur affecté, capacité, dates, prix net et politique d'incident. Le logo et le branding clarifient cette promesse ; ils ne remplacent ni les enseignants ni le canal de paiement. La plateforme nouvelle doit réussir la recette commerciale et le cours pilote avant vente de masse. Le jury ne demande aucune modification technique.

Les engagements historiques déjà payés restent à honorer ou rembourser dans un registre séparé. Aucun ancien élève, enseignant, paiement ou contrat n'est transféré de force à la nouvelle offre. Ce traitement ne transforme pas le mandat en réparation de l'ancienne académie.

## 2. Offre unique proposée et prix

| Public | Fréquence | Durée par séance | Prix mensuel de référence | Capacité proposée |
|---|---|---:|---:|---|
| Enfant | 3 séances/semaine | 60 min, courte pause incluse | 50 USD | 4 débutants/jeunes ; 5 consolidés ; 6 seulement après pilote spécifique favorable |
| Adulte | 3 séances/semaine | 90 min | 60 USD | 4 si remédiation/Hifz exigeant ; 5 ordinaires ; 6 lecteurs autonomes après pilote |

Même enseignant sur les trois jours, sauf remplacement exceptionnel qualifié et annoncé. Le prix ne promet pas un nombre universel de12 séances : le calendrier exact est présenté avant la vente. Les mois de12/13/14/15 séances au pattern annoncé conservent le prix mensuel de référence.

Remise proposée selon bénéficiaires **payants simultanément pour la période** du même foyer : un0 %, deux5 %, trois ou plus10 % sur le prix de chaque profil, sans cumul. La remise est figée au devis de période. Une nouvelle entrée ne refacture pas rétroactivement les autres profils ; ses effets pour les autres commencent à leur prochain renouvellement. Un conjoint peut être bénéficiaire adulte ; il n'est pas automatiquement titulaire ni représentant des autres adultes.

| Composition | Affectation par profil | Total mensuel |
|---|---|---:|
| 1 enfant | 50 | 50 USD |
| 2 enfants | 47,50 +47,50 | 95 USD |
| 3 enfants | 45 +45 +45 | 135 USD |
| 1 adulte | 60 | 60 USD |
| 1 enfant +1 adulte | 47,50 +57 | 104,50 USD |
| 2 enfants +1 adulte | 45 +45 +54 | 144 USD |

Ces nombres sont des **propositions de prix totaux affichés**. Les taxes territoriales et éventuels frais obligatoires doivent être réglés avant publication du devis final ; aucun supplément surprise au paiement. Le modèle teste une TVA absorbée dans ces prix. Si le directeur choisit un prix TTC supérieur, il adopte une nouvelle grille explicite. Les frais du processeur supportés par Rewayah ne diminuent jamais le solde promis à l'élève.

La facture porte une devise unique. Le calcul de recherche utiliseUSD ; commercialiser une autre devise exige une grille/devis daté, pas une conversion fluctuante du solde après achat. L'ancien50/90/40 et les30 unités/12 cours ne sont pas adoptés pour la renaissance. Les20 USD sont une **proposition de rémunération professeur**, jamais le prix familial.

## 3. Pattern, intention, classe et place

| État | Promesse permise | Condition pour avancer | Responsable |
|---|---|---|---|
| Pattern d'offre | Jours/langue/niveau/durée envisagés ; prix indicatif signalé | Besoin mesuré et vivier compatible | Coordinateur |
| Intention | Inscription gratuite en attente, aucune place garantie | Accord d'être recontacté ; disponibilité sur tous les jours | Admissions |
| Classe affectée | Professeur confirmé sur tout le calendrier, remplaçant/couverture définis | Qualification, disponibilité, contrat, marge et matériel vérifiés | COO + académique |
| Place proposée | Devis ferme et calendrier, date limite de validité | Diagnostic compatible et capacité libre | Admissions |
| Option temporaire | Place tenue au maximum48h proposées, sans paiement capturé d'avance | Confirmation puis paiement réel ; libération explicite à échéance | Admissions |
| Place payée/active | Cours du calendrier acheté avec droits définis | Paiement rapproché et affecté, contrat accepté | Finance + admissions |
| Attente/transfert | Pas de date vendue tant qu'aucune classe compatible | Nouvelle proposition, acceptation distincte | Coordinateur |

Pas d'encaissement définitif pour un professeur/créneau non garanti. Si une confirmation dépend d'un minimum commercial, recueillir des intentions gratuites ; offrir un devis ferme seulement après décision de tenir la classe. Si Rewayah ouvre une classe sous le minimum, elle finance sa garantie professeur et son déficit. On ne promet pas une place sous prétexte qu'un professeur a candidaté.

L'administration publie les horaires ; la famille choisit un pattern existant ou exprime une intention sur les options. Elle ne négocie pas une modification individuelle des trois jours. Les heures locales et changements d'heure sont montrés avec des dates réelles. Une option expirée n'autorise aucun débit ultérieur sans accord.

## 4. Capacité, maîtrise et qualité

Le programme [V0](02_CHARTE_PROGRAMME_V0.md) décrit les apprentissages. Passage par maîtrise observée, jamais par paiement ou délai marketing. L'enseignant garde son jugement pédagogique ; le responsable académique traite les divergences. Le directeur signe textes, variantes et supports religieux.

Le référentiel de septembre réserve environ25 minutes aux passages enfant : à4/5/6,6,25/5/4,17 minutes **brutes** chacun. La nouvelle organisation peut proposer36 minutes, mais cette amélioration doit être testée, pas affichée comme déjà obtenue. Pilote de quatre semaines, au moins deux classes du format si disponibles : consigner temps vocal utile, transitions, attente, erreurs persistantes et progrès. Les seuils initiaux proposés sont une alerte si plus de20 % des élèves n'ont pas obtenu l'occasion de correction prévue, ou si40 % restent en difficulté sur la même unité après renforcement. Ils déclenchent une revue humaine, pas une promotion/sanction automatique.

Six élèves ne sont pas un moyen de sauver une marge insuffisante. Pas de mélange poular/français/anglais dans une classe si la compréhension de l'enseignement n'est pas démontrée pour chacun. Les rythmes Hifz sont bornés par la révision ; une famille ne choisit pas chaque semaine une sourate ou un programme différent pour le groupe.

## 5. Solde fermé, mensualité et revenu

**Une seule doctrine recommandée :** solde monétaire de cours par élève, non transférable librement, utilisable pour ses propres cours vendus par Rewayah. Le total foyer est informatif. Pas de retrait à vue général, prêt, change entre profils ou paiement de tiers. La qualification de ce montage reste à faire vérifier ; si elle ne convient pas, utiliser facture mensuelle et avoirs traçables sans recharge libre. Les droits de remboursement restent intacts.

Ordre métier : paiement confirmé → affectation au profil → solde disponible → **un seul débit à l'ouverture du mois/de l'entrée partielle** → droit d'accès daté → suivi des séances fournies → avoir/remboursement si nécessaire. Les séances ne débitent pas une deuxième fois le solde. Une provision de prestation restant à fournir est un suivi de responsabilité comptable, pas une deuxième somme retranchée au parent.

`solde_final = solde_initial + recharges_confirmées + avoirs − débit_unique_de_période − remboursements_exécutés − extournes_justifiées`.

Pour la période achetée, `P` est son montant net après remise/prorata et `N` le nombre de séances vendues dans cette période ; fraction de service `q=P/N`. Conserver les fractions exactes puis arrondir les montants d'opération au centime ; la dernière fraction absorbe le reliquat pour que la somme soit exactementP. Le relevé ne promet pas que14×3,57=50 : il expose le total et l'ajustement de centimes. Aucun historique n'est réécrit pour corriger une erreur ; écrire une extourne motivée.

Le prix de référence correspond aux trois jours hebdomadaires du calendrier. Une entrée au milieu du mois paie `prix_net_mensuel × séances_restantes / séances_du_pattern_du_mois`. Une fermeture annoncée **avant vente** réduit également le prix au prorata du calendrier normal ; elle ne permet pas de vendre six cours au prix présenté comme trois séances par semaine. Une fermeture **après vente** donne remplacement/rattrapage accepté ou avoir. Un mois sans séances vendues ne déclenche aucun débit. Cette règle précise le traitement des vacances laissé ouvert dans E04.

La trésorerie encaissée, le solde disponible, les prestations vendues non fournies, le revenu de service et la paie sont cinq grandeurs distinctes. La politique comptable formelle et les taxes sont approuvées par le professionnel compétent. Le modèle de gestion reconnaît la prestation au rythme du service, y compris place mise à disposition selon contrat en cas d'absence élève ; l'ouverture du mois ne rend pas automatiquement tout le prépaiement distribuable.

## 6. Cinq factures et leur contrôle

| Cas daté | Calcul | Résultat auditable |
|---|---|---|
| Enfant, novembre2026, mardi/jeudi/samedi,12 séances | Recharge50 ; débit mensuel50 ; service12×50/12 | Solde0, pas de débit par cours |
| Enfant, octobre2026, lundi/mercredi/vendredi,13 séances | Recharge50 ; débit50 ; fraction50/13 | Prix50, fraction3,84615… ; une annulation entière sans service→avoir3,85 |
| Adulte, octobre2026, mardi/jeudi/samedi,14 séances | Recharge60 ; débit60 ; fraction60/14 | Une annulation→avoir4,29 ; revenu service net55,71 sous réserve comptable |
| Enfant, octobre2026, jeudi/vendredi/samedi,15 séances | Recharge50 ; débit50 ; fraction50/15 | Aucun supplément pour la15e séance ; total réparti exactement50 |
| Enfant rejoint le17octobre, mardi/jeudi/samedi | 7 séances restantes sur14 ; prix50×7/14=25 ; recharge25 puis débit25 | Une annulation entière→avoir25/7=3,57 ; ne pas diviser25 par14 |

Exemple foyer : trois enfants rechargés45 chacun, total135, trois débits45. Novembre12 séances : enfantA absent mais cours assuré→aucun avoir ; professeur absent à la classeB sans remplacement→avoir45/12=3,75 **uniquement à B** ; remplaçant qualifié pourC→aucun avoir. Soldes finaux0/3,75/0, total foyer3,75 ; ce total ne peut pas payer automatiquement le prochain mois deA. Finance peut rembourser un avoir éligible au payeur légitime, en préservant facture et bénéficiaire.

Cas vacances avant vente : enfant50, mois normal14 séances,2 fermetures annoncées→prix42,86 pour12 séances. Les dates et le montant sont acceptés avant débit. On n'abaisse pasN après la vente pour augmenter la valeur prétendument fournie par les autres cours.

## 7. Présence, retard et incident : une règle par cas

| Situation | Droit famille | Traitement professeur / opération |
|---|---|---|
| Élève absent/retard, cours disponible | Pas d'avoir automatique ; préparation et résumé autorisé, pas de cours particulier dû | Paie maintenue pour service assuré ; absence tracée sans jugement de maîtrise |
| Prof absent, remplaçant qualifié même séance/durée | Service fourni, aucun avoir | Paie séance affectée au remplaçant ; droits contractuels du titulaire traités séparément |
| Prof absent, aucun cours | Rattrapage proposé sous7jours à date acceptée ; à défaut avoir de la séance | Coordinateur décide, finance trace ; aucune double facturation |
| Panne académie démontrée | Minutes non fournies et non récupérées compensées au prorata `q×minutes_manquantes/durée`, maximumq | Incident qualité ; aucune faute enseignante déduite du seul journal réseau |
| Panne famille démontrée, cours correctement disponible | Règle absence élève ; aide technique et résumé possible | Service prouvé, pas de pénalité professeur |
| Réseau indécidable | Statut « à examiner », revue sous2jours ouvrés ; rattrapage accepté ou avoir si absence de preuve/service | Pas de faute attribuée automatiquement ; rémunération litigieuse examinée séparément, financée par réserve si nécessaire |
| Retard professeur | Rattraper les minutes avec accord, sinon compensation prorata du temps non fourni | Signaler, examiner répétition ; paie selon temps assuré et droits du contrat |
| Changement durable de professeur/horaire | Nouvelle proposition expliquée ; acceptation, transfert compatible ou remboursement de prestation future non fournie | Pas de rotation silencieuse ou de report imposé |
| Incident de protection/sécurité | Interrompre la situation à risque, protéger les personnes, canal confidentiel | Responsable protection désigné ; directeur seulement pour gravité/obligation légale, pas traitement par groupe WhatsApp |

Le délai de7jours et la revue2jours sont des engagements **proposés à financer**. Le parent peut préférer l'avoir à un horaire de rattrapage incompatible. Un rattrapage remplace la séance identifiée ; il ne crée ni nouvelle consommation ni deuxième avoir pour la même perte. Les droits impératifs de remboursement ou recours priment toujours sur ces règles commerciales.

## 8. Résiliation, remboursement et comptes familiaux

Pas de renouvellement/débit sans mandat valable. La famille peut arrêter avant la période suivante ; une demande en cours de période est traitée avec arrêt prospectif à date convenue, service fourni conservé et valeur future non fournie libérée/remboursée selon contrat et droits applicables. Ne pas bloquer le remboursement légal derrière un avoir obligatoire.

Les recharges non utilisées et avoirs monétaires n'expirent pas automatiquement. Le **droit mensuel** finit à sa date, le **solde monétaire** subsiste. Un dossier inactif fait l'objet d'une relance puis d'un traitement conforme aux règles applicables, pas d'une reprise automatique en bénéfice. Rembourser en principe vers le moyen d'origine et la devise du contrat, après contrôle ; changement de canal uniquement avec vérification du destinataire. Les frais initiaux non rendus par un PSP sont un coût Rewayah, sous réserve d'une politique licite explicitement acceptée ; pas de retenue improvisée.

Séparation du foyer : pas d'arbitrage des comptes privés des conjoints. Conserver bénéficiaire, provenance de paiement, droits académiques déjà achetés et factures du payeur historique. Ne pas déplacer un solde ni partager les données d'un autre adulte. Un changement de titulaire contesté suspend seulement les nouvelles opérations sensibles jusqu'à vérification des droits ; la continuité de cours déjà payé est préservée si elle est licite et sûre.

Passage à l'autonomie : préserver identité, historique académique et crédit attaché à l'élève. Nouveau contrat et moyen de paiement personnel avant les futures factures ; aucune carte parentale copiée. Le fichier historique du rôle élève est contradictoire sur le veto du tuteur (§6.4 contre§7.6). Ce veto n'est **pas adopté** ici. La procédure respecte le droit d'autonomie applicable et la vérification d'identité ; la revue juridique tranche la portée du rôle parental, sans dupliquer le dossier ni confisquer le solde. L'âge18 du dossier initial est un repère commercial à vérifier selon territoire, pas une règle mondiale automatique.

Chargeback : isoler le montant contesté et sa provenance, conserver les preuves, traiter le droit d'accès futur sans punir les autres enfants ni effacer les cours passés. Ne jamais rembourser à la fois par PSP et par virement le même litige ; contrôle croisé obligatoire.

## 9. Enseignants : contrat et paie

Avant affectation : maîtrise académique vérifiée humainement, langue de travail, aptitude enfant/adulte, disponibilité **sur les trois jours**, audition, référence, maîtrise de l'outil, réseau de secours, protection des mineurs et contrat. Le diplôme seul ou un grand nombre de candidatures ne prouve pas cette combinaison.

Paie proposée pour une classe standard : enfant `20×max(élèves actifs financés,4)` ; adulte `30×max(élèves actifs financés,4)` par mois entier tenu. Boursier financé compte comme élève payé pour le professeur, avec subvention explicite ; élève gratuit ne devient pas une recette. La décision commerciale de maintenir une classe sous4 est financée par Rewayah. L'impayé découvert après autorisation de cours n'est pas automatiquement transféré au professeur.

Prorata d'entrée/sortie/ouverture par séances dues sur calendrier réel. La fraction professeur d'une séance = rémunération de la classe de période / nombre de séances de cette période ; titulaire et remplaçant se partagent les séances effectivement assurées, sans double paie ordinaire. Les congés, maladie, minimum légal ou autres garanties du contrat local peuvent créer un surcoût licite : il est budgété, pas effacé par la formule.

| Classe entière, aucune remise paie | 4 élèves | 5 élèves | 6 élèves |
|---|---:|---:|---:|
| Paie enfants | 80 | 100 | 120 USD |
| Recettes enfants sans remise | 200 | 250 | 300 USD |
| Paie adultes | 120 | 150 | 180 USD |
| Recettes adultes sans remise | 240 | 300 | 360 USD |
| Reste avant bonus/frais/support/CAC/taxes | 120 | 150 | 180 USD |

Exemple classe5 enfants, novembre12 séances : enveloppe100 ; un remplacement ordinaire vaut100/12=8,33 avec ajustement de centimes, titulaire91,67/remplaçant8,33. Si la famille de chaque élève reçoit un avoir pour une séance non fournie, le total famille dépend du prix payé ; il n'est pas égal automatiquement à la paie perdue. Ne pas financer l'écart en supprimant une rémunération contractuellement due.

Bonus internet proposé20USD **par professeur éligible et mois**, condition de fiabilité et justificatif d'activité, jamais par classe ni par vitesse de progression. Paie validée mensuellement, date de versement proposée au10 du mois suivant, détail transmis et contestation possible. Le corridor Mobile Money, le montant/devise reçu, le FX et les frais sont convenus avant engagement. Ne promettre ni GN, ni CI, ni SN sans contrat et essai du corridor concerné.

## 10. Service, délégation et contrôle

Le premier responsable recruté est admissions/support, avec délégation sur les cas ordinaires et réponses approuvées. Accusé réception en1jour ouvré sur plages affichées ; problème d'entrée à un cours traité pendant ces plages en priorité. L'admissions n'est pas comptable habilité à effectuer seul un remboursement arbitraire ni juge de tajwid. Le coordinateur tient les patterns, remplaçants et charge ; le responsable académique assure formation et calibration ; finance rapproche et prépare les paiements. Le directeur garde doctrine, budget, recrutement des responsables et cas graves.

Double contrôle distinct pour nouveaux bénéficiaires de paie, changement de coordonnées et versements/remboursements sensibles. Dans une petite équipe, le second contrôleur peut être un professionnel externalisé ou responsable formellement désigné ; il ne dépend pas de la bonne volonté technique des deux autres fondateurs. La personne qui prépare ne peut être l'unique approbateur et conciliateur.

Tableau hebdomadaire : prospects qualifiés, conversion en payants, CAC complet, nouvelles places réellement servables par langue/niveau/fuseau, occupation payante, délai support, cours fournis/annulés, rattrapages/avoirs, départs/motifs, remplacements, plaintes, temps du directeur. Tableau mensuel : recettes et CA distincts, passifs élèves, paies dues/versées, réserve, résultat, cohortes30/60/90jours. Chaque indicateur porte définition, période, propriétaire et source ; valeur inconnue affichée comme inconnue.

## 11. Acquisition, trésorerie et pause

Expérience proposée14jours,1 600USD **tout compris acquisition** : média≤1 200, créations et travail acquisition≤400. Admissions et support sont comptés séparément dans exploitation ; pas de double compte. Aucun budget n'est dépensé dans ce mandat. Deux messages, même offre et audiences adultes autorisées ; pas d'inférence de religion ni ciblage des enfants. Partenariats et recommandation complètent les campagnes, sans devenir l'unique moteur vers1 000.

Le CAC40USD du scénario offensif est un plafond de simulation. Monter seulement si contribution de cohorte couvre le CAC en≤3mois, cours et paiement fonctionnent, support tient et caisse couvre **passifs élèves + deux mois de coûts récurrents** après dépense. L'expert growth préfère trois mois : dissidence prudente documentée, à adopter si le directeur souhaite un coussin plus fort. Les14premiers jours ne prouvent pas une rétention90jours.

Pause immédiate de nouvelles ventes sur un pattern sans professeur/remplaçant, prix/promesse trompeuse, paiement non rapprochable, risque de protection ou capacité dépassée. Pause du budget du canal si conversion/coût détruit la contribution ou si la réserve n'est plus financée. Maintenir les cours déjà vendus. Une liste d'attente honnête vaut mieux qu'une place fictive.

## 12. Version, adoption et changements

Le directeur adopte une version datée, une date d'effet et les délégataires nommés. En l'absence de signature, **aucune nouvelle règle n'est déclarée en vigueur**. Les changements de prix/durée/capacité/paie s'appliquent aux périodes futures après information et consentement requis ; les droits déjà payés ne sont pas réduits rétroactivement. Le [registre C01–C10 et D11](07_REGISTRE_DECISIONS.md) conserve alternative, preuve, risque et décision réservée. Le responsable d'exploitation tient un seul livre actif ; les annexes sont des avis, pas neuf règlements concurrents.


---

# ANNEXE 18 - Référentiel académique complémentaire et revue experte

_Source : `E01_academique.md`. Contenu conservé pour ne pas perdre les détails métier._


# Annexe E01 — Avis indépendant du directeur académique

**29 septembre 2026 — proposition de jury, sans certification de pratique interne.** Sources de vérité : [dossier 01](../sources/REWAYAH_01_VERITE_METIER_ET_ARBITRAGES_2026-09-29.md) et [mandat 02](../sources/REWAYAH_02_MANDAT_CODEX_JURY_RECHERCHE_2026-09-29.md), datés du 29 septembre. Le référentiel académique **RA-CUR-2026.1** et son complément opérationnel, datés du 18 septembre, sont des **propositions en étude**, jamais la preuve que l'académie les applique depuis 2024. Le directeur, diplômé en sciences coraniques et titulaire d'ijazat selon le dossier 01, garde la validation scientifique. Aucun texte sacré ni formule d'invocation n'est transcrit ici.

## Thèse et trois hypothèses risquées

**Thèse.** La classe stable doit protéger le temps de correction orale, la leçon commune et la confiance familiale. La capacité relève d'une décision pédagogique testée, pas du seul remplissage. Trois séances hebdomadaires avec le même enseignant sont **décidées** le 29 septembre ; durées de 60 minutes enfant et 90 adulte, capacités 4 à 6, restent **à arbitrer** par formule. Les cours particuliers actuels ne changent pas sans accord familial et diagnostic.

1. **Attention et voix utiles.** Six élèves ne sont pas prouvés équivalents à quatre en récitation en ligne. Chronométrer correction, reprises et attente. L'[Education Endowment Foundation](https://educationendowmentfoundation.org.uk/education-evidence/teaching-learning-toolkit/small-group-tuition), consultée le 29 septembre 2026, étudie surtout des groupes de deux à cinq ; ce n'est pas un plafond universel pour Rewayah.
2. **Hétérogénéité.** Un niveau déclaré cache des écarts de déchiffrage ou de rétention. Consolidation commune si 40 % peinent ; soutien puis réaffectation humaine si un élève décroche. Seuils de septembre **à calibrer**, sans sanction automatique.
3. **Promesse de maîtrise.** F1-F4, Tilāwah T1-T6, Ḥifẓ H0-H6 et I1 forment une architecture, mais corpus, droits et seuils restent à signer. Aucune durée garantie, ijazah implicite ou promotion achetée. L'[EEF](https://educationendowmentfoundation.org.uk/education-evidence/teaching-learning-toolkit/mastery-learning), consultée le 29 septembre, décrit objectifs constants et temps variable, sur des preuves qu'elle juge faibles.

## Audit de minutes et recommandation C01

Le protocole **proposé** dans RA-CUR-2026.1 du 18 septembre donne, pour les enfants, 5 min d'accueil, 12 de leçon, **25 de passages individuels**, 5 de pause, 10 de pratique collective, 3 de clôture. Pour les adultes, il prévoit **45 à 50 min de passages** dans 90 min. Le tableau divise simplement la plage par l'effectif : il inclut changement de lecteur, hésitations et corrections ; la voix utile est donc moindre.

| Effectif | Enfant 60 min, protocole V1 : 25 min / n | Enfant, variante à tester : 36 min / n | Adulte 90 min : 45–50 min / n |
|---:|---:|---:|---:|
| 4 | 6,25 min | 9 min | 11,25–12,5 min |
| 5 | 5 min | 7,2 min | 9–10 min |
| 6 | 4,17 min | 6 min | 7,5–8,33 min |

La variante de 36 minutes laisse 24 minutes à tout le reste, pause comprise ; elle peut appauvrir la leçon commune. Sur trois séances, le protocole V1 offre 18,75/15/12,5 minutes brutes hebdomadaires à 4/5/6 enfants. Les auditeurs suivent, repèrent une règle et préparent leur tour. Ce temps n'est pas un tutorat individuel garanti.

**Recommandation provisoire :** quatre débutants ou 6–9 ans en décodage ; cinq lecteurs consolidés de niveau proche ; six lecteurs autonomes, notamment adultes, seulement après pilote. L'âge ne suffit pas. Durant quatre semaines, comparer des classes de 4/5/6 au niveau initial proche : voix utile, reprises correctes, élèves sans passage, écoute active, préparation, assiduité, fatigue et recours. Réduire l'effectif si un élève présent manque régulièrement de passage corrigé ou si l'écart de maîtrise croît. Le directeur signe une capacité **par formule** ; transition des groupes existants avec accord.

## Texte de programme V0 à signer puis publier

> **Rewayah Academy — apprendre à lire et réciter le Coran avec un professeur attitré.** Trois cours par semaine dans une classe stable, avec un programme commun et un objectif personnel réaliste. Le parcours commence par un diagnostic oral : l'âge ou une auto-déclaration ne suffit pas à attribuer un niveau. Le débutant travaille lettres, voyelles et décodage avec Nour al-Bayân ; il apprend ensuite à lire un texte vocalisé, puis entre progressivement dans le Muṣḥaf en lecture Ḥafṣ ʿan ʿĀṣim. Al-Fātiḥa, les sourates 99 à 114, les récitations de la prière, les ablutions et un choix limité d'invocations quotidiennes sont abordés selon le niveau et les textes validés par la direction académique. Après le tronc commun, le parcours de lecture ou de mémorisation se choisit avec conseil de l'enseignant et accord du responsable de l'élève. Chaque élève reçoit un court travail de préparation et des retours sur ses progrès. Le passage d'étape dépend d'une maîtrise observée à plusieurs reprises ; sa durée varie. Une famille peut demander une réévaluation motivée. Le professeur conduit la séance et le programme ; l'académie traite les questions et les difficultés par une voie de recours claire.

**Condition de publication :** signature du directeur avec date d'effet, liste exacte des supports, durée et capacité de chaque formule, politique de transition et charte famille. Ce texte ne promet ni résultat à date fixe ni édition numérique de Nour al-Bayân avant vérification des droits. Le tarif, les absences et le paiement appartiennent à la même page commerciale mais requièrent la décision CFO/solde ; ne pas publier cette page isolément comme offre complète.

## Séquence scientifique proposée au directeur

| Étape | Objectif et preuve observable | Validation réservée |
|---|---|---|
| D0 | Déclaration courte, puis lecture/récitation réelle adaptative ; arrêt dès que le dernier prérequis stable est identifiable. Retour après interruption significative : nouveau diagnostic de placement, historique conservé. | Échantillons oraux, critères d'arrêt et équivalence entre enseignants. |
| F1 — commencer à lire | Lettres isolées et contextuelles, fatḥa/kasra/ḍamma, madd naturel, syllabes et mots vocalisés. Proposition V1 : deux séances distinctes, échantillons inconnus, au moins 90 % de décodage correct et au plus deux aides ; confusions de lettres récurrentes à traiter. | Seuil et grille de prononciation selon l'âge ; édition exacte de Nour al-Bayân et correspondance unité/page. |
| F2 — consolider | Sukūn, tanwīn, shadda ; talaqqī progressif d'Al-Fātiḥa, Al-Ikhlāṣ, Al-Falaq et An-Nās ; premières récitations de Ṣalāh. L'oral peut précéder la lecture écrite du corpus. | Texte, ordre, variantes et catégories de la prière ; aucune formule écrite sans source. |
| F3 — lire avec autonomie | Fin de la méthode retenue, fluidité sur textes vocalisés et introduction graduée d'invocations authentifiées comme supports de lecture. | Sélection et contexte des invocations ; droits de l'édition choisie. |
| F4 — lire dans le Muṣḥaf | Lecture directe du Muṣḥaf de Médine en Ḥafṣ ; Al-Fātiḥa et sourates 99 à 114 stabilisées ; révision de la Ṣalāh et des invocations ; tajwid appliqué par couches. | Version exacte du corpus, contrôle des signes, variantes, points d'arrêt et relecture par enseignant habilité en Ḥafṣ. |
| Orientation | Lecture Tilāwah : T1-T6, six tranches de cinq ajzāʾ avec lecture entière puis contrôles non préparés. Ḥifẓ : H0 (compléter Juz 30), H1-H6 puis I1 de consolidation intégrale ; trois flux « Nouveau / À consolider / Révision longue ». | Prérequis, charge réelle et choix familial/adulte ; aucun certificat Hifz assimilé à une ijazah. |

**Ablutions :** le dossier directeur du 29 septembre les place dans la priorité commerciale, tandis que le référentiel du 18 septembre détaille surtout les récitations de Ṣalāh. Ajouter dans V0 une démonstration pratique guidée et une vérification de la séquence retenue, **sans** publier ici de prescriptions juridiques, de variantes ou de texte. Le directeur choisit le périmètre et l'enseignant habilité valide la grille. Ne pas ajouter de fiqh, sīra ou sciences islamiques générales au parcours initial.

La plateforme officielle du [Complexe Roi Fahd pour les développeurs](https://qurancomplex.gov.sa/en/techquran/dev/) décrit un contenu coranique authentifié en Ḥafṣ, consultée le 29 septembre ; le [guide technique officiel du Complexe](https://qurancomplex.gov.sa/wp-content/uploads/isdarat/booklets/complextechguide.pdf) décrit un Muṣḥaf numérique pour les applications. Cela oriente le choix de la source, sans prouver que Rewayah possède la version, l'intégration ou tous les droits d'usage nécessaires. Pour Nour al-Bayân, auteur, édition, titulaire des droits, licence de reproduction et pagination numérique restent **à vérifier** auprès d'une source autorisée ; un PDF trouvé en ligne ne vaut pas licence. Utiliser l'ouvrage acquis en cours présentiel/visio selon l'usage autorisé et préparer des exercices originaux distincts tant que ce point n'est pas conclu.

## Diagnostic, maîtrise et manuel des premières semaines

**Mesurer peu, mais réellement.** Pour chaque compétence, l'enseignant note « À renforcer », « Acquis » ou « Stable », avec un exemple de performance, l'aide fournie et la prochaine action. La proposition V1 exige trois observations espacées sur au moins deux semaines, dont une non préparée, pour « Stable » ; E1 (hésitation ou autocorrection), E2 (règle enseignée manquée), E3 (substitution, omission ou erreur critique) sont une grille de calibration à valider. Une auto-déclaration ou un devoir coché ne vaut aucune preuve de maîtrise. Échec à une gate : renforcement ciblé, pas retour automatique au début. La famille peut demander une contre-évaluation par une personne distincte ; motif et décision sont conservés. Un certificat final demande contrôle autorisé, pas seul avis du professeur habituel.

**Semaine 0 :** diagnostic oral individuel, test de connexion, attentes de la famille et du professeur, pattern complet et compatibilité de groupe ; expliquer que la progression du groupe et celle de l'élève se croisent. Aucun placement forcé pour remplir une place. **Semaine 1 :** trois séances d'installation : rituels d'entrée, prise de parole et d'écoute, première unité de lecture adaptée, passage de chaque élève, micro-actions avant le prochain cours (trois maximum). L'enseignant marque les confusions utiles sans étiqueter trop tôt « stable ». **Semaine 2 :** même structure, nouvelles tâches seulement si la précédente tient ; première observation espacée, retour familial bref sur objectif, présence et préparation. **Semaines 3–4 :** deuxième échantillon inconnu, décision « continuer / consolider / soutien individuel borné / revue de transfert » ; entretien de suivi seulement pour les exceptions. Les familles reçoivent un nom d'étape compréhensible et un travail court, pas des codes F1 ou une matrice d'erreurs.

**Fiche enseignant, chaque séance :** avant, lire objectif commun, passage et deux alertes utiles ; pendant, présenter, faire réciter chacun, corriger de façon audible, donner une mission aux auditeurs, réserver la pause enfant ; après, consigner unité réellement travaillée, chacun passé ou non, difficulté ciblée, prochaine préparation et incident éventuel. Dans l'académie actuelle sur Sheets/Drive, une fiche de groupe et un journal d'exception suffisent ; la cible « 45 secondes après cours » du document produit suppose un préremplissage qui n'est **pas vérifié opérationnel aujourd'hui**. Si 40 % peinent sur l'unité, consolider en commun ; un écart durable déclenche revue humaine, pas promotion forcée ni abandon.

**Formation initiale proposée :** deux blocs de 90 minutes sur doctrine/corpus signé et conduite de classe ; une classe simulée de 60 ou 90 minutes avec six rôles d'élèves possibles, dont débutant lent et incident réseau ; une séance observée puis retour ciblé. Tester au moins : prononciation et Ḥafṣ, diagnostic sans surclassement, correction courte, gestion de la file et des auditeurs, séquence de prière autorisée, incident technique sans faute présumée, recours d'une famille. Habilitation conditionnelle par le directeur ou son délégué scientifique ; nouveau contrôle après deux semaines. La formation est une **proposition**, non une formation déjà livrée.

## Objections croisées et arbitrages

**Au CFO :** le passage de 4 à 6 élèves améliore l'encaissement par heure seulement si la qualité et la rétention tiennent. À protocole enfant constant, il retire 2,08 minutes brutes de passage à chacun par séance (6,25 → 4,17). Chiffrer le coût d'un élève qui quitte faute de correction, le soutien de rattrapage et le temps professeur de remplacement avant de déclarer six rentables. Le tarif adulte à 40 USD avec paie hypothétique de 30 USD/élève laisse 10 USD avant tous frais : ne pas compenser cet écart par une capacité pédagogiquement abusive.

**Au COO :** le vivier d'enseignants doit être qualifié sur un pattern de trois jours **et** sur une démonstration de classe, avant l'ouverture de groupes. Prévoir un remplaçant formé au même corpus, le passage de relais du diagnostic et une file d'exceptions ; le directeur ne peut relire chaque compte rendu à 1 000 élèves. Le contrôle qualité échantillonne récitations, erreurs de placement et plaintes motivées, avec consentements et accès appropriés, sans classement public par vitesse des élèves.

**Aux familles :** le paiement achète des cours et un suivi, pas une sourate au choix, un diplôme, ni la promotion. Le professeur décide du contenu du jour dans le cadre signé ; la famille connaît l'objectif, le travail attendu, les règles d'absence et peut faire appel d'un diagnostic ou d'un incident à une personne autre que l'enseignant. Un désaccord de rythme déclenche explication et revue documentée ; ni caprice illimité ni autorité sans recours. La migration des vingt élèves actuels exige de leur présenter la nouvelle formule, son prix, sa taille et son professeur avant accord ; conserver leur parcours acquis.

**Dissidence raisonnable :** le référentiel du 18 septembre propose cinq enfants/60 minutes et six adultes/90 minutes ; il peut réussir avec tâches d'écoute solides et bons enseignants. Je refuse néanmoins d'en faire une capacité générale avant mesure du temps utile, des acquis et du taux de décrochage sur les premières cohortes. Décision réservée au directeur : approuver V0 et corpus, plafonds par formule, protocole de pilote, date d'effet et adaptation des clients existants.

## Traçabilité

- **DÉCIDÉ, 29/09/2026 :** classes stables, trois séances/semaine, même enseignant, 4/5/6 selon cas ; priorité Nour al-Bayân, Ḥafṣ, Al-Fātiḥa, sourates 99–114, Ṣalāh/ablutions, invocations. Source : dossier 01.
- **PROPOSÉ, 18/09/2026 :** RA-CUR-2026.1 et Référentiel pédagogique opérationnel V1, fichiers DOCX fournis dans `C:\Users\dell\Downloads`; F1-F4, gates, timings, T/H/I, états de maîtrise. Le mémoire pédagogique interne du 22/09 (`D:\RA _APP\RA -OFFICIAL-APP\docs\current\07_MEMOIRE_PEDAGOGIE_FINANCE.md`) les décrit comme cible ultérieure, avec deux validations de contenu encore ouvertes.
- **À VÉRIFIER, 29/09/2026 :** édition et droits de Nour al-Bayân ; identité/version et droits des supports du Complexe ; liste scientifique Ṣalāh/ablutions/invocations ; performances réelles des classes 4/5/6 ; état de l'application et pratique des vingt élèves. Aucun lien ou document cité ne certifie une mise en production ni un enseignement historique selon ce nouveau programme.


---

# ANNEXE 19 - Revue CFO - hypothèses de prix, coûts et paie

_Source : `E03_cfo.md`. Contenu conservé pour ne pas perdre les détails métier._


# E03 — Avis indépendant du CFO : prix, paie et trésorerie

**29 septembre 2026 — proposition au jury, non décision du propriétaire.** Périmètre : modèle économique de l’académie et règles financières testables, sans intervention sur l’application, les comptes ni les prestataires. Sources internes prioritaires : `REWAYAH_01_VERITE_METIER_ET_ARBITRAGES_2026-09-29.md` (vérité déclarée et contradictions C01–C10), `REWAYAH_02_MANDAT_CODEX_JURY_RECHERCHE_2026-09-29.md` (mission), `REWAYAH_03_PLAN_DIRECTEUR_20_1000_5000_2026-09-29.md` (plan de débat). Les chiffres ci-dessous sont **PROPOSÉS**, sauf les faits explicitement marqués **ACTUEL DÉCLARÉ**. Les montants sont en USD de calcul, avant toute décision de devise contractuelle, fiscalité ou change.

## Thèse et trois hypothèses à casser

**Avis historique indépendant, corrigé par la directive D11 du 30/09.** Ce texte conserve les calculs et objections CFO formulés avant que le propriétaire précise la **renaissance depuis zéro nouveau payant et zéro professeur confirmé**. Les passages partant des20 élèves actuels, le transfert individuel0/50/100%, le dernier mois à470 nouveaux, les2 350 prospects de décembre, le budget14 100USD àCAC30 et la réserve de trois mois **ne sont plus la doctrine du jury**. Le modèle V1.1 et le livre opérationnel retiennent0→200→540→1 000, soit200/350/487 nouveaux,2 435 prospects en décembre à20%, acquisition41 480USD au trimestre àCAC40, réserve de **deux mois de coûts plus passifs élèves**. Les avis CFO de prix50/60, remises0/5/10, garanties et prudence de TVA demeurent des propositions à approuver. Son exemple16,05USD de contribution utilise des postes hypothétiques différents du modèle V1.1 (remplacement1% CA, support5USD, visio2USD) et **ne doit pas remplacer** les postes3% paie, heures d'exploitation et visio100USD+variable de la simulation V1.1. Frais/FX/payout5% du CA est une enveloppe non vérifiée à stresser8% ; le payout a une autre assiette. Une recharge est un passif de cours jusqu'à service, non un résultat ; la garantie quatre et le remplaçant doivent être financés.

**Thèse.** Une offre de groupe à prix lisible peut financer une rémunération enseignante stable et un premier service d’admissions, sous quatre conditions simultanées : remplir des classes cohérentes, encaisser réellement les familles, maintenir la qualité pédagogique à la taille annoncée et acquérir les clients à un coût récupérable. Le passage de 20 à 1 000 élèves n’est pas un simple changement d’échelle d’un taux de marge. **ACTUEL DÉCLARÉ** : au plus 20 élèves payants, cours individuels de trois heures hebdomadaires, inscriptions gelées par surcharge manuelle ; ni les 20 prix réellement encaissés ni le coût complet de ces cours ne sont fournis. Toutes les marges de groupe qui suivent décrivent donc une **offre projetée**, jamais le résultat actuel.

1. **Remplissage.** « Cinq élèves par classe » est une moyenne fragile quand âge, niveau, langue et trois horaires fixes fragmentent les cohortes. Mesurer la distribution de classes à 2/3/4/5/6 payants et le délai entre intention et quatrième place ; ne compter aucune intention comme un élève actif. Une moyenne de cinq peut cacher plusieurs classes à deux qui consomment les mêmes professeurs et le même support.
2. **Acquisition et rétention.** Le bouche-à-oreille initial ne donne ni CAC ni taux de conversion. Mesurer par canal le coût jusqu’au **premier paiement confirmé**, la rétention à 30/60/90 jours, les avoirs et le nombre de familles arrivées à une classe réellement affectée. En test, un CAC de 30 USD est un plafond de travail, à réduire si la TVA, les remises ou l’attrition dégradent la contribution.
3. **Coût réel de service.** La paie par élève n’épuise pas remplaçants, bonus connexion, frais de collecte/change, support, vidéo, qualité, remboursement et direction. Suivre coût et charge du support par élève actif et par classe ; un solde créditeur prépayé améliore le cash disponible apparent, mais crée une obligation de service ou de remboursement, pas un bénéfice.

## Grille commerciale unique à soumettre au directeur

**PROPOSÉ V0 :** une formule de trois séances hebdomadaires, 60 minutes enfant à **50 USD par élève et mois**, 90 minutes adulte à **60 USD**. La hausse adulte de 20 % face à 50 % de durée supplémentaire comprime sa marge par minute et sert seulement d’hypothèse de test ; elle doit être confrontée à l’attention disponible, au prix accepté et au coût professeur. La plage déclarée de 40–60 USD n’autorise pas à promettre que toute variante est viable. Aucun ancien prix 50/90/40 ni unité « 30 crédits/12 cours » ne devient une politique par reprise documentaire.

| Bénéficiaires actifs payants d’un foyer, conjoint compris | Remise sur chaque formule | Enfant | Adulte | Exemple de total du foyer |
|---:|---:|---:|---:|---|
| 1 | 0 % | 50 | 60 | 1 enfant : 50 ; 1 adulte : 60 |
| 2 | 5 % | 47,50 | 57 | 2 enfants : 95 ; adulte + enfant : 104,50 |
| 3 ou plus | 10 % | 45 | 54 | 3 enfants : 135 ; adulte + 2 enfants : 144 |

La remise est uniforme pour les bénéficiaires actifs du même titulaire, recalculée à la prochaine période contractuelle, sans rétroactivité ni cumul avec une autre promotion. Un élève boursier a un coût enseignant réel ; une bourse reçoit une ligne de financement identifiée et ne compte pas comme place **payante**. Pour éviter qu’un troisième inscrit rende paradoxalement moins cher le foyer entier, vérifier les sauts de facture lors des entrées/sorties : deux enfants à 95 deviennent trois à 135, soit +40 ; le retour à deux ramène à 95. Le prix public doit préciser la date d’effet et ce que signifie « actif ». Le directeur garde le dernier arbitrage des prix, de la remise et de la prise en charge des clients historiques.

Sensibilité sans remise et par élève : en reprenant seulement 5 % frais/FX, 2 % compensation/pertes, 1 % remplacement, 5 USD support, 2 USD média et 1 USD de bonus ventilé, la contribution **avant CAC/fixes/direction** serait à prix 40 USD **8,80 enfant / −1,20 adulte**, à 50 USD **18 / 8**, à 60 USD **27,20 / 17,20**. Le prix adulte de 40 USD n’est donc pas une formule standard soutenable dans ce test ; six élèves ne répareraient pas la valeur pédagogique perdue. Ce tableau est une sensibilité, pas une liste de tarifs décidés.

## Paie, seuil de classe et remplacements

**PROPOSÉ :** paie mensuelle de base par bénéficiaire enseigné actif : **20 USD enfant ; 30 USD adulte**. Cela reflète 60 contre 90 minutes, sans prétendre mesurer toute la préparation. Une classe ouverte et maintenue sur décision de Rewayah garantit au professeur **quatre équivalents de paie** par mois : `paie_classe = taux × max(4, sièges_actifs_enseignés)`, avec prorata des jours d’activité si la classe ouvre en cours de période. Cette garantie n’autorise pas l’ouverture systématique à deux ou trois payants : l’écart `4 − payants` est une subvention de remplissage explicite, approuvée avec durée et source de trésorerie. Une classe n’ouvre normalement qu’avec quatre places payantes confirmées et un professeur couvert sur les trois jours ; sinon liste d’attente ou essai financé et daté. Le groupe peut rester à quatre pour débutants ou Hifz intensif, viser cinq en consolidation, et n’aller à six qu’après essai de récitation validé par l’académique. Le remplissage n’a pas autorité sur la qualité.

Le bonus connexion, s’il est retenu, vaut **20 USD par enseignant éligible et par mois**, une seule fois même s’il enseigne plusieurs classes. Éligibilité : affectation active, moyens testés, paiement documenté ; réexaminer son montant avec les coûts réels de connexion. À titre de ventilation analytique uniquement, quatre classes par enseignant feraient 5 USD par classe. La paie du remplaçant d’une séance assurée est `paie_mensuelle_normale_de_la_classe / nombre réel de séances programmées ce mois-là`, multipliée par les séances reprises et ajustée à la durée enfant/adulte ; 12, 13, 14 ou 15 séances changent le dénominateur. Le paiement du titulaire dépend du contrat et de la cause établie ; aucun incident réseau indécidable n’entraîne automatiquement sa perte. Pas de double paiement masqué : tout chevauchement autorisé est inscrit en coût de continuité.

| Classe intégralement payante, sans remise | 4 élèves | 5 élèves | 6 élèves |
|---|---:|---:|---:|
| Enfants : CA / professeur / reste avant autres coûts | 200 / 80 / **120** | 250 / 100 / **150** | 300 / 120 / **180** |
| Adultes : CA / professeur / reste avant autres coûts | 240 / 120 / **120** | 300 / 150 / **150** | 360 / 180 / **180** |
| Enfants si tous à remise 10 % : reste avant autres coûts | **100** | **125** | **150** |
| Adultes si tous à remise 10 % : reste avant autres coûts | **96** | **120** | **144** |

Ces restes sont **avant** bonus, support, remplacement, marketing, taxes et direction. Exemple de classe adulte de quatre à remise 10 % : 216 encaissés théoriques, 120 de paie, 5 de quote-part illustrative de bonus, soit 91 avant les autres dépenses. Si seulement trois adultes paient dans une classe garantie à quatre, 162 de tarif remisé moins 120 de paie garantie, soit 42 avant bonus et charges ; un deuxième siège vide peut rendre l’essai déficitaire. L’objection académique renforce le plafond de taille : dans 54 minutes de récitation/correction adulte, quatre, cinq et six élèves n’offrent que 13,5, 10,8 et 9 minutes brutes par personne ; avec 36 minutes enfant : 9, 7,2 et 6. Aucun calcul de marge ne transforme ces minutes brutes en qualité prouvée.

## Modèle mensuel commun au classeur du jury

Une ligne par mois d’octobre 2026 à décembre 2027, segmentée enfant/adulte et par bande de remise. Variables observables : `N début`, taux de départ, nouveaux payants, prospects qualifiés, conversion, places ouvertes, classes à 4/5/6, professeurs et classes par professeur, prix, remise, séances prévues/fournies, remboursements/avoirs, coût du support, frais de paiement/FX, vidéo, marketing, charges fixes et trésorerie initiale. Formules de contrôle :

- `N fin = N début × (1 − churn) + nouveaux payants` ; `nouveaux payants = prospects qualifiés × conversion`, sous contrainte des **places réellement attribuables**. Les nouveaux sont comptés après paiement confirmé : ne pas multiplier une seconde fois `N fin` par un taux d’encaissement. Les chiffres fractionnaires des scénarios sont des espérances, à arrondir seulement pour décider des places.
- `facturé TTC hypothétique = Σ actifs moyens du mois par segment,remise × prix × (1 − remise) × prorata`. Pour le flux nouveau, actifs moyens = survivants du mois + `0,5 × nouveaux` si l’inscription arrive en moyenne à mi-mois ; la capacité s’évalue, elle, sur `N fin`. `encaissé = paiements effectivement confirmés − remboursements encaissés`, en enregistrant séparément recharges anticipées et service rendu. `CA reconnu` suit la politique de mensualité activée puis les avoirs de séances non fournies ; **recharge de solde ≠ CA**. Le besoin de remboursement et les prestations restant dues figurent au passif de gestion.
- `classes nécessaires = Σ plafond(N cohorte / capacité validée cohorte)`, calculé par langue, niveau, âge et pattern, pas `plafond(N total / 5)` pour embaucher. `profs actifs = plafond(classes réellement affectées / classes viables par professeur)`, plafonné par les heures et fuseaux disponibles. `paie = Σ taux_segment × max(4, sièges enseignés par classe maintenue) + 20 × profs éligibles + remplacements − ajustements contractuels justifiés`.
- `contribution = CA hors TVA due − paie − frais collecte/FX − compensations/pertes − support − vidéo − réserve remplacement − CAC × nouveaux payants`. `résultat d’exploitation = contribution − fonctions fixes − direction − autres charges documentées`. `cash clôture = cash ouverture + encaissements − décaissements`, sans confondre avance de solde et fonds libres. Réconcilier chaque mois facturation, encaissement, droits et coût des cours. Un cash initial de **10 000 USD** peut servir de cellule illustrative du classeur, clairement marqué **non constaté**.

Pour rendre les ordres de grandeur vérifiables, **illustration de régime de croisière** : mix 70 % enfants/30 % adultes ; 50 % de bénéficiaires sans remise, 30 % à 5 %, 20 % à 10 %, donc remise moyenne pondérée 3,5 % ; cinq élèves par classe, quatre classes par professeur, tous les professeurs au bonus ; frais de collecte et change 5 % du CA, compensations/pertes 2 %, provision distincte de remplacement 1 %, support 5 USD et média 2 USD par actif ; TVA nulle **comme scénario**. Prix moyen = `(0,7×50 + 0,3×60)×(1−0,035) = 51,145` ; paie de base = `0,7×20 + 0,3×30 = 23` ; bonus ≈ 1/élève ; contribution **avant CAC, frais fixes et direction** = `51,145 − 23 − 1 − 2,55725 − 1,0229 − 0,51145 − 5 − 2 = 16,0534 USD/actif/mois`. Les taux, y compris le 1 % de remplacement, sont des hypothèses à remplacer par devis, livres et temps de support ; compensation et remplacement doivent être rapprochés des incidents réels sans double comptage. Si 20 % de TVA devait être absorbée dans ce même prix TTC, la recette hors taxe tomberait à 42,62 et la contribution à environ **7,53 USD**, sans compter l’effet éventuel sur la TVA déductible. La fiscalité peut donc inverser le seuil d’acquisition.

| Actifs projetés | CA mensuel illustratif | Paie base | Classes à 5 / professeurs à 4 classes | Bonus | Contribution avant CAC, fixes et direction |
|---:|---:|---:|---:|---:|---:|
| 20 | 1 023 | 460 | 4 / 1 | 20 | 321 |
| 100 | 5 114,50 | 2 300 | 20 / 5 | 100 | 1 605 |
| 300 | 15 343,50 | 6 900 | 60 / 15 | 300 | 4 816 |
| 1 000 | 51 145 | 23 000 | 200 / 50 | 1 000 | 16 053 |
| 5 000 | 255 725 | 115 000 | 1 000 / 250 | 5 000 | 80 267 |

La première ligne est **simulation groupe** et ne décrit pas les 20 élèves individuels existants. Un sous-tableau séparé doit conserver le flux individuel ancien : prix réellement encaissé de chacun, coût professeur inconnu, et **12 heures hebdomadaires du directeur** pour ses quatre élèves. À défaut de coût ancien, le classeur peut afficher **45 USD/élève/mois comme simple valeur provisoire modifiable**, jamais l’ancien 4 USD/heure comme donnée certaine. Hypothèse de conversion volontaire de l’ancien individuel vers le groupe : 0 % en octobre, 50 % en novembre, 100 % en décembre **uniquement pour tester la capacité**, avec une alternative de maintien individuel si les familles refusent. Les effectifs de 5 000 supposent précisément 1 000 classes viables et 250 enseignants capables d’en prendre quatre, à prouver. Un support à 5 USD/actif représenterait 25 000 USD/mois à cette taille ; ce budget n’est pas un effectif ou une qualité de service prouvés.

## Acquisition, direction, réserve et cinq scénarios

Avec la contribution illustrative de 16,05 USD, un retour CAC en trois mois donne un plafond arithmétique d’environ **48 USD** si l’élève reste et paie ; je recommande un **plafond expérimental de 30 USD par premier payant**, plus prudent face à l’attrition et à la cohorte incomplète. Chaque canal doit suivre `CAC = dépense attribuée / nouveaux payants réellement encaissés`, puis `marge de cohorte cumulée à 30/60/90 jours − CAC`. Suspendre la montée du budget quand la récupération dépasse trois mois, quand les places couvertes manquent ou quand la réserve se dégrade. En scénario 20 % de TVA incluse, le plafond arithmétique trois mois tombe autour de 23 USD ; le plafond de 30 devient insuffisamment prudent. Pour les **470** nouveaux de décembre dans la trajectoire offensive, un CAC de 30 demanderait **14 100 USD** ce mois-là et, à 20 % de conversion, **2 350 prospects qualifiés** ; ces coûts sont absents des « restes » de la table.

**Direction PROPOSÉE pour débat :** charge contractuelle mensuelle `max(plancher garanti 1 000 USD, 3 % du CA hors TVA effectivement encaissé et définitivement attribuable à la période)`. Le plancher et le taux sont des variables politiques, pas des engagements déjà conclus. La base exclut recharges non consommées, remboursements, taxes collectées, frais refacturés et dons affectés. À 1 000 actifs dans l’illustration, 3 % du CA = 1 534,35 ; à 20 actifs projetés, le plancher 1 000 dépasse largement la contribution. Le manque de cash **n’efface jamais la charge due** : dette salariale comptabilisée, financement ou renégociation formelle avant échéance. Aucun bonus du directeur ni diversification financée par les soldes des élèves.

**Réserve de gestion :** conserver séparément 100 % des montants prépayés correspondant à un service non encore rendu ou remboursable, puis viser une trésorerie libre couvrant trois mois de charges fixes essentielles **et** des engagements de paie garantis, plus un coussin incidents/remboursements calibré sur l’historique. Mesurer `couverture = cash libre / sorties essentielles mensuelles prévisibles` ; pause des campagnes si couverture prévisionnelle < 3 mois après le budget de la cohorte suivante. L’objectif est une proposition prudente de gouvernance, pas un seuil réglementaire. La réserve se construit avant tout financement de sociétés futures.

Scénarios d’**entrées payantes mensuelles**, proposés au classeur ; tous partent de 20 au 30 septembre 2026 et appliquent le churn avant les nouvelles entrées. Les entrées de 2027, la conversion, le CAC, les délais de classes et la capacité sont à paramétrer mois par mois jusqu’à décembre 2027, sans prolonger automatiquement le rythme de décembre 2026.

| Scénario | Churn/mois | Oct./nov./déc. 2026 : nouveaux | Actifs fin déc. attendus | Sens économique à tester |
|---|---:|---:|---:|---|
| Bas | 10 % | 15 / 20 / 25 | ~70 | Conversion ou capacité faible ; protéger engagements existants |
| Base | 5 % | 60 / 80 / 100 | ~247 | Premiers canaux reproductibles ; recrutement mesuré |
| Haut | 5 % | 150 / 200 / 250 | ~593 | Plusieurs canaux et classes remplies |
| Objectif offensif | 5 % | 200 / 350 / 470 | ~1 000 | ~470 nouveaux en décembre ; budget, admissions et professeurs à prouver |
| Exception positive | 5 % | 300 / 500 / 738 | ~1 501 | Ne vendre que les places couvertes ; attente au-delà |

Formule 2027 identique : `N_t = N_(t−1)×(1−churn_t)+nouveaux_t`; les douze mois doivent varier selon cohortes, budget, saison, disponibilité et qualité. En décembre offensif, à 10 % de conversion il faut **4 700 prospects qualifiés**, ou **2 350** à 20 %, et `470×CAC`. Le chiffre d’affaires futur n’est jamais une preuve que le recrutement initial est finançable.

## Questions contradictoires et décision réservée

**À l’académique :** démontrer par observation que cinq places maintiennent lecture, correction et progression ; les six places ne peuvent être justifiées par la seule marge de +25 à +30 USD par siège avant charges. **Au growth :** un prix de 50/60 et le CAC de 30 tiennent-ils après refus d’horaires, première facture réellement payée et rétention à 90 jours ? Un lead n’a aucune valeur comptable avant conversion. **Au solde :** retenir une seule mensualité par période et un avoir proportionnel `prix mensuel / nombre réel de séances prévues × séances non fournies sans remplacement`, selon politique de service signée ; réserver le crédit par bénéficiaire, conserver historique d’allocation/consommation/avoir, séparer le total familial informatif. Les mois de 12/13/14/15 séances changent la valeur d’avoir, non le prix public. Le traitement comptable exact du revenu et des remboursements reste à examiner, mais la trésorerie prépayée ne finance pas librement la croissance.

**TVA :** mettre en parallèle dans le classeur (A) exonération/hors champ si confirmée, (B) taxe applicable absorbée dans le prix public, (C) taxe ajoutée au prix public et effet sur conversion. La documentation HMRC précise que la formation en direct assurée par une personne en ligne n’est pas automatiquement un service numérique automatisé, que l’exonération éducative dépend notamment du statut du fournisseur et que le lieu de prestation doit être établi avant la taxation ; le taux standard UK est actuellement 20 %. Cela **ne tranche pas** la situation de la LTD ni des familles internationales : demander un avis qualifié sur statut, pays du client, contenu vendu, seuils et TVA récupérable. Sources officielles : [HMRC, éducation et formation](https://www.gov.uk/guidance/vat-on-education-and-vocational-training-notice-70130), [HMRC, cours humains en ligne](https://www.gov.uk/guidance/the-vat-rules-if-you-supply-digital-services-to-private-consumers), [HMRC, lieu de prestation](https://www.gov.uk/guidance/vat-place-of-supply-of-services-notice-741a), [taux UK](https://www.gov.uk/vat-rates).

**Arbitrages du directeur avant date d’effet :** prix et remise publics, périmètre de la garantie à quatre, paie contractuelle du titulaire/remplaçant, budget test d’acquisition, plancher/taux de direction, règle d’avoirs et transition consentie des cours individuels. Relever d’abord tarifs, encaissements et promesses des 20 dossiers actuels. Toute nouvelle grille reçoit version, date d’effet, exemple de facture et communication ; aucun élève individuel n’est basculé silencieusement vers un groupe ni facturé selon une hypothèse de ce rapport.


---

# ANNEXE 20 - Paiements, solde élève, échéances, incidents et contrôle interne

_Source : `E04_paiements.md`. Contenu conservé pour ne pas perdre les détails métier._


# E04 — Paiements, solde élève et contrôle interne

**Expert 4, avis indépendant au jury — 29 septembre 2026. Recherche et proposition, sans changement de l'application ni activation de fournisseur.** Les faits de l'académie viennent de `REWAYAH_01_VERITE_METIER_ET_ARBITRAGES_2026-09-29.md` ; les chiffres de prix ci-dessous sont des **hypothèses de décision**, coordonnées avec l'expert CFO, et non des tarifs déjà approuvés. Les capacités et frais externes sont ceux des pages officielles consultées le 29 septembre 2026 ; un catalogue public ne prouve jamais que le compte de la LTD est accepté, que le corridor est ouvert, ni qu'un paiement réel a réussi.

## Thèse et décision recommandée

Je recommande **un solde monétaire fermé par élève**, exprimé dans la devise de son contrat, utilisable seulement pour acheter ses propres cours Rewayah. Le titulaire du foyer peut payer plusieurs élèves et voir un total *informatif* ; chaque versement est affecté à un bénéficiaire avant de devenir disponible. Ni transfert entre élèves, ni retrait libre, ni paiement d'un tiers. Le terme commercial serait « solde de cours », avec contrat, relevé d'opérations et procédure de remboursement. La qualification juridique reste à confirmer : appeler un instrument « fermé » ne démontre pas à lui seul son exclusion du droit des paiements. La [FCA décrit la portée et les notifications de l'exclusion de réseau limité](https://www.fca.org.uk/firms/limited-network-exclusion) ; son [guide distingue aussi les cartes cadeaux d'un commerçant vendant ses propres prestations](https://www.fca.org.uk/publication/policy/ps18-24.pdf). Un conseil britannique doit qualifier **ce montage précis**, les prépaiements, les contrats élèves et les territoires consommateurs avant la publication de la politique.

La formule est **mensuelle à prix fixe**. Le premier jour d'une période, ou le premier cours d'une entrée partielle, le prix net convenu est débité **une seule fois** du solde élève. Ce débit ouvre l'accès à toutes les séances prévues dans la période : 12, 13, 14 et même 15 si le pattern hebdomadaire et le calendrier les produisent. Chaque séance ensuite reçoit un état de service et une fraction de contrôle `P/N`, mais **ne redébite pas** le solde. Si l'académie n'assure pas la séance et n'offre pas de remplacement équivalent selon le délai publié, elle crédite un **avoir monétaire** `P/N` au même élève. Il ne faut jamais afficher à la fois un montant « réservé » et un second « consommé » comme deux débits. La trésorerie distingue l'argent encaissé de la prestation acquise : à l'ouverture, une dette de service est suivie, puis libérée au rythme des séances dues/fournies et ajustée par les avoirs. Le traitement comptable final et les taxes sont à valider par le comptable.

L'autre option plausible est la vente de chaque séance à `P/N`, débitée après preuve de service. Elle rend les avoirs intuitifs, mais produit un prix variable par cours (50/12 contre 50/15), davantage d'écritures et un risque de décalage entre la promesse « 50 par mois » et le solde affiché. Une règle de prix constant *par séance* changerait, elle, le prix mensuel selon le calendrier. Je rejette ces deux variantes pour l'offre proposée de trois cours hebdomadaires à prix mensuel annoncé. L'ancienne conversion « 50 USD → 30 unités → 12 séances » est **REMPLACÉE**, non une règle historique démontrée.

**Trois hypothèses les plus risquées.** (1) Le prestataire autorise effectivement la société et ses familles EU/US/Canada, puis règle les encaissements sans réserve imprévue : à tester par contrat, dossier KYB, petits paiements réels consentis et rapprochement, avant acquisition à volume. (2) Les corridors de paie africains, surtout Guinée Conakry, sont effectivement disponibles pour les bénéficiaires et volumes visés : aucun logo de couverture ne suffit. (3) Le prix mensuel et les avoirs restent soutenables quand les séances annulées, remboursements, litiges, frais de carte et change se cumulent. La règle testable est : pour chaque élève et période, `solde final = solde initial + paiements confirmés affectés + avoirs - unique débit de période - remboursements exécutés - extournes justifiées`. Chaque terme porte identifiant, date, source, auteur et preuve ; les deux côtés doivent coïncider au centime. Nombre de débits de formule `≤ 1` par élève/période/version de prix ; nombre d'avoirs `≤` nombre de séances éligibles sans service ; aucun paiement incertain n'ouvre une place « payée ».

## Contrat opérationnel à publier, sous arbitrage du directeur

1. **Devis et consentement.** Afficher durée enfant 60 minutes/adulte 90 minutes, trois jours, professeur affecté ou état d'intention, nombre de dates du mois, prix total net, devise, remises, début, absence, compensation, résiliation et moyen de paiement. Une intention sans professeur affecté ne doit pas encaisser comme une place garantie. Hypothèses de travail CFO : enfant **50 USD/mois**, adulte **60 USD/mois**, remise foyer **0 %** pour un, **5 %** pour deux, **10 %** pour trois bénéficiaires payants ou plus, appliquée au prix de chacun et **non cumulable**. Ainsi deux enfants coûteraient `2 × 50 × 0,95 = 95 USD` ; deux enfants et un adulte `2 × 50 × 0,90 + 60 × 0,90 = 144 USD`. Les prix existants 40–60 USD sont observés comme plage déclarée, pas remplacés rétroactivement par ces exemples. Le directeur décide la grille et la transition individuelle avant effet.
2. **Encaissement puis affectation.** Un ordre externe possède un identifiant unique. Tant que le PSP ou le virement ne confirme pas de façon rapprochable, la transaction est « en attente » ; pas de recharge disponible et pas de succès optimiste. Une fois confirmée, l'écriture crédite seulement le ou les élèves désignés sur le reçu : exemple 95 USD → 47,50 USD chacun. Les frais du PSP sont un coût de l'académie, jamais une réduction silencieuse du crédit promis. Un paiement non attribuable reste en compte d'attente, avec investigation et remboursement possible, sans inventer un élève bénéficiaire.
3. **Ouverture et preuve de service.** La période est le mois civil du fuseau de la classe publié au contrat. `N` compte les séances réellement programmées selon le pattern, avant ouverture ; les vacances ou pauses **annoncées avant vente** sont exclues de `N` et du contrat affiché. Le calendrier et le montant net sont figés pour la période achetée. Une entrée en cours de mois paie `P × R/N`, où `R` est le nombre de séances restantes au moment de l'entrée ; arrondi au centime sur le total, puis répartition interne des fractions avec dernier centime résiduel sur la dernière séance. Aucun nouveau prix implicite si l'administration déplace un cours. Une mensualité impayée ne renouvelle pas automatiquement l'accès ; notifier et offrir une nouvelle tentative autorisée ou un autre moyen réellement accepté.
4. **Absences et incidents.** Élève absent : si la classe a été tenue et l'accès fourni dans les conditions annoncées, la fraction de service est acquise ; l'assiduité n'est pas une seconde facture. Enseignant absent mais remplaçant qualifié sur la même durée et séance : service fourni, aucun avoir. Enseignant absent sans service de remplacement : proposer une séance équivalente à une date acceptée dans la fenêtre publiée, sinon avoir `P/N`. Une panne réseau attribuée avec preuve à l'académie suit la même règle ; une panne attribuée à la famille avec accès réel suit la règle d'absence ; **cause indéterminée** reste en examen, avec fraction non reconnue, proposition de rattrapage sans nouveau débit et décision documentée sous délai. À défaut de preuve et de rattrapage acceptable, faire l'avoir, sans attribuer une faute. La paie du professeur/remplaçant suit un registre séparé et ne change pas le droit de l'élève.
5. **Résiliation, avoir et remboursement.** Une séance future non fournie après résiliation acceptée reçoit son prorata ou la somme prévue par le droit applicable, selon le cas le plus favorable aux droits impératifs. Un avoir et toute recharge non dépensée demeurent au même élève ; aucune expiration automatique de cette valeur monétaire. Le droit d'assister au mois acheté se clôt à la fin de ce mois, distinct du solde en argent. Après inactivité, demander une instruction au payeur habilité et maintenir une piste de remboursement ; aucune « reprise » des soldes comme profit. Sur demande de remboursement éligible, rembourser vers le moyen d'origine quand il est possible et approprié, sinon par canal vérifié après contrôle de propriété. La différence de change entre achat et remboursement doit être explicitée : l'académie rembourse le montant **dans la devise contractuelle** ; le montant reçu par la carte peut varier selon le taux et les frais de l'émetteur. Un chargeback bloque la réutilisation de la somme contestée, ouvre un dossier de preuve et une écriture de régularisation ; ne pas ponctionner le solde d'un autre enfant ni effacer les cours déjà fournis.
6. **Foyer et majorité.** Le crédit suit **l'identité de l'élève**, y compris à 18 ans, sans transfert automatique à un autre bénéficiaire. Le payeur initial garde accès à ses reçus et à ses demandes de remboursement selon les droits établis ; le nouveau payeur fournit son propre mandat et moyen de paiement. Aucune carte n'est copiée à l'élève adulte. Lors d'une séparation, l'académie ne répartit pas les créances privées des conjoints : elle gèle les changements de payeur litigieux, continue seulement les services déjà payés si les droits le permettent, puis exige l'instruction de la personne habilitée pour une nouvelle période. Le document de rôles retrouvé contient une tension entre acceptation du tuteur et autonomie de l'adulte ; **le veto éventuel n'est pas arbitré ici**. Faire décider par le responsable juridique/produit sur base des documents de foyer et du droit applicable, sans suspendre l'identité ni effacer l'historique.

## Sept exemples datés, prix hypothétique sans taxes ni frais du payeur

| Situation | Écritures et résultat pour l'élève |
|---|---|
| **1er–31 octobre 2026, enfant à 50 USD, mardi/jeudi/samedi : 14 séances.** | Paiement confirmé de 50,00 USD le 30 septembre, affecté à l'élève ; ouverture du 1er octobre `−50,00`. Les 14 séances incluses sont suivies à `50/14 = 3,5714…` USD de provision chacune ; **aucun autre débit**. Solde 0,00 si tout est fourni. Un mois à 15 séances, par exemple jeudi/vendredi/samedi d'octobre 2026, reste 50,00 USD selon la même règle. |
| **1er–30 novembre 2026, même pattern : 12 séances.** | Recharge et débit uniques de 50,00 USD. L'enseignant manque le 12 novembre mais un remplaçant qualifié tient 60 minutes : 0 avoir. Le 21 novembre, absence sans remplacement ni rattrapage accepté : avoir `50/12 = 4,17` USD au solde élève. Valeur finale 4,17 ; revenu net de la période 45,83 USD sous réserve de validation comptable. |
| **1er–31 décembre 2026, mardi/jeudi/samedi : 14 séances.** | Débit unique 50,00 USD. L'élève manque le 8 décembre alors que le cours est disponible : 0 avoir. Le 15 décembre, réseau indéterminé : garder la fraction `50/14` en litige, proposer un rattrapage documenté. Sans preuve ni rattrapage dans la fenêtre annoncée, créditer **3,57 USD** et clore le dossier ; ne pas proclamer que la famille ou l'enseignant est fautif. |
| **Entrée le 16 octobre 2026, avant la prochaine séance du 17 octobre.** | Sept séances mardi/jeudi/samedi restent du 17 au 31 octobre sur les 14 du mois. Prix d'entrée `50 × 7/14 = 25,00` USD ; recharge 25,00 puis unique débit 25,00. Si le cours du 24 octobre est annulé sans remplacement, avoir `50/14 = 3,57` USD, car la fraction unitaire du contrat complet est préservée. |
| **1er octobre 2026, trois bénéficiaires d'un foyer.** | Deux enfants à 45,00 USD chacun et un adulte à 54,00 USD, total 144,00 USD confirmé et affecté 45/45/54 ; chaque profil subit son unique débit. Le total familial vaut alors 0,00. Le 10 octobre, séparation des parents : aucune réaffectation ni transfert ; les reçus restent attribués à l'ancien payeur. Pour novembre, le titulaire autorisé et les nouvelles modalités doivent être établis avant paiement ; aucun droit de prélèvement sur l'ex-conjoint n'est présumé. |
| **18e anniversaire le 20 octobre 2026 d'un des deux enfants payés par le tuteur.** | Solde de 4,17 USD issu d'un avoir antérieur : il reste sur le **même identifiant élève**. Le tuteur conserve le reçu du paiement d'origine. Pour novembre, le contrat et le consentement du payeur sont réévalués ; le compte adulte ne reçoit pas la carte du tuteur. Ni le crédit ni l'historique pédagogique ne sont effacés. |
| **Fin de service le 31 décembre 2026, recharge restante 10,00 USD.** | Le droit mensuel finit le 31 décembre ; les 10,00 USD de solde non débités ne disparaissent pas le 1er janvier 2027. À résiliation et vérification du payeur, remboursement de 10,00 USD dans la devise de contrat ou application au prochain mois avec consentement. Pas de frais caché ni d'expiration inventée. |

Ces exemples sont une **politique proposée**, non une reconstruction des contrats individuels des 20 élèves. Les remises pour 2/3 élèves se figent au devis de la période et ne sont pas recalculées au milieu du mois au détriment d'un enfant déjà payé. Un nouveau tarif/remise ne s'applique qu'à une période future avec notification et consentement requis.

## Fournisseurs : faisabilité publique, inconnus contractuels et repli

| Flux | Ce que confirme une source primaire | Ce qui reste à prouver pour Rewayah |
|---|---|---|
| **Cartes familles EU/US/CA → UK LTD : Stripe, candidat principal.** | [Stripe accepte les cartes étrangères via une entreprise d'un pays pris en charge](https://stripe.com/global) ; le Royaume-Uni est éligible. [Tarif UK public](https://stripe.com/gb/pricing) : 2,5 % + 20 pence pour cartes EEE, 3,15 % + 20 pence pour cartes internationales (US/Canada), **+2 % si conversion Stripe requise**. Dispute received 20 GBP, dispute countered manuellement 20 GBP récupérés si gain. Sur prix standard, frais initiaux de traitement/FX non restitués en cas de remboursement ; l'absence de frais supplémentaires de remboursement pour carte n'en fait pas un remboursement gratuit. | KYB de **cette** LTD, activité éducation religieuse admise, pays de résidence des dirigeants, compte bancaire, réserves et délai de règlement, devises de présentation/règlement, 3-D Secure/SCA, taux d'acceptation et conditions particulières. [Conditions d'ouverture dans un pays distinct du pays principal](https://support.stripe.com/questions/requirements-to-open-a-stripe-account-in-another-country?locale=en-GB) à examiner compte tenu du domicile saoudien déclaré. Aucun compte Stripe Rewayah actif n'est confirmé. |
| **Repli C2B indépendant : PayPal Business UK**, à vérifier et tester en parallèle. | [Tarifs marchands UK officiels, version du 15 juillet 2026](https://www.paypal.com/uk/business/paypal-business-fees) : transaction commerciale domestique ordinaire 2,9 % + fixe ; supplément transfrontalier EEE **1,29 %**, hors EEE **1,99 %** ; frais fixes selon devise, p. ex. 0,30 GBP ou USD. Cartes invitées, offres et FX peuvent relever d'un barème distinct : ne pas réduire toute facture PayPal à 2,9 %. Les litiges standard en GBP sont 12 GBP ; chargeback carte hors PayPal/guest selon barème, 14 GBP, et conditions de remboursement à lire. | Admissibilité de la société, disponibilité du checkout carte dans les pays clients, frais finaux et FX par devise, réserve, cycle des remboursements et règlement. Tester avec cartes réelles consenties et rapprochement ; aucune activation démontrée. Repli fonctionnel : un lien PayPal émis indépendamment du processeur primaire, pas un bouton PayPal routé par Stripe qui conserverait le même point de panne. |
| **Wise Business : non retenu comme repli carte.** | Wise indique expressément que [la réception par carte est actuellement indisponible aux *nouveaux* clients Wise Business](https://wise.com/help/articles/2ns36RddtM1kAb5vbWxGMx/getting-paid-to-your-wise-business-by-card-apple-pay-or-google-pay). Un [lien Wise](https://wise.com/help/articles/4qr3kkvIQlHNiD8BegEB4u/getting-paid-to-your-wise-business-by-payment-link) peut demander un virement/Wise selon les coordonnées ouvertes et le mode permis ; ce n'est pas une preuve de checkout carte disponible. Le directeur signale que ses liens directs Wise sont bloqués : **ACTUEL DÉCLARÉ**, à vérifier par l'historique des échecs. | Rôle possible uniquement de virement/FX si compte et corridor effectivement autorisés. Ne pas promettre Wise pour débloquer les familles. |
| **Verto : trésorerie B2B éventuelle, pas preuve de collecte C2B par carte.** | La [documentation Verto](https://support.vertofx.com/en/articles/6255261-how-to-open-local-and-global-accounts) décrit des coordonnées de comptes professionnels recevant via rails locaux ou SWIFT. Ses [API](https://www.vertofx.com/core-api) et liens de paiement sont présentés pour entreprises, comptes multidevises, FX et payouts ; aucun de ces textes ne démontre un checkout carte consommateur EU/US/CA pour Rewayah. | Vérifier par contrat qui peut payer (particulier ou société), quelles cartes, seuils, spread FX, frais et voies de sortie. Ne pas appeler Verto « collecteur primaire familial » sur la seule foi du mot payment link. |
| **Payout enseignants : pawaPay, candidat par corridor.** | [pawaPay distingue payout vers portefeuille Mobile Money et settlement vers banque](https://www.pawapay.io/plans). Sa [page des frais](https://www.pawapay.io/fees) affiche pour **CI/XOF** MTN 1,3 %, Orange 2 %, Wave 2 %, Moov 1,5 % de *disbursement* public ; Orange est cependant signalé « coming soon »/exigences Enterprise sur la [page des plans](https://www.pawapay.io/plans), donc **ne pas le traiter ouvert**. Pour **SN/XOF**, YAS 1,5 %, Orange 1,8 %, Wave 2 %. Les devises XOF pour CI/SN correspondent à l'[union monétaire BCEAO](https://www.bceao.int/fr/content/presentation-de-lumoa). [Les entités pawaPay](https://www.pawapay.io/payment-providers) comprennent **Guinée Conakry**, mais sa liste publique de marchés tarifés et opérateurs ne présente pas **GN/GNF** : **aucun opérateur GN ni taux GN n'est confirmé ici**. Ne pas confondre GN et Guinée-Bissau. | Contrat marchand UK, accès à chaque opérateur et pays, KYC des enseignants, préfinancement, limites de portefeuille, ordre de taux FX USD→XOF/GNF, taxes, frais de dépôt/banque, échecs et SLA. Les taux publics sont **indicatifs**, présentés « tiered » et hors taxes ; le tarif négocié peut différer. Le simple statut d'une entité locale ne prouve pas le corridor de la LTD. |

Le schéma de repli limite les dépendances : **PSP A Stripe → PSP B PayPal direct**, deux accès et rapprochements distincts. Si les deux échouent, seul un **virement bancaire documenté** vers un compte appartenant à la société, avec référence unique et confirmation effective, peut être offert pour les familles qui y ont accès ; ne jamais afficher « payé » sur capture d'écran ou promesse de virement. Le payout ne dépend pas du même PSP que la collecte. **pawaPay → virement bancaire ou rail Mobile Money local distinct vérifié par enseignant et pays**, après consentement et contrôle d'identité. À défaut de corridor vérifié, aucune promesse de paiement mobile ; inscrire la dette enseignante et réserver la trésorerie, puis convenir d'un canal réellement disponible. Les coordonnées et frais sont validés par deux personnes distinctes avant premier versement ; la preuve de débit chez Rewayah et l'avis de réception enseignant se rapprochent sans écraser les échecs.

Pour le **FX**, le devis famille fixe la devise et le prix avant paiement ; le solde élève porte la même devise et n'est pas recalculé à chaque cours. Les livres de la LTD peuvent exiger une valorisation comptable en GBP, distincte du droit client. Rewayah supporte/annonce séparément frais de carte, taux à la conversion du règlement, spread du payout et frais Mobile Money ; `coût complet payout = montant local promis + frais fournisseur + coût FX + éventuels frais bancaires/taxes`. Un enseignant est payé selon la devise et le montant **contractés avec lui**, pas selon un taux imaginaire au moment de la vente. Consigner taux horodaté, source, montant envoyé, montant reçu et écart. Obtenir un devis réel pour 20/100/1 000 paiements avant de chiffrer une marge certaine.

## Contrôle, objections et verdict demandé

**Objection CFO : « Le prépaiement finance la croissance, pourquoi le neutraliser en dette ? »** Parce que la caisse reçue le 30 septembre sert encore quatorze cours d'octobre, et qu'un chargeback ou une séance non fournie peut la reprendre. Le tableau hebdomadaire sépare `encaissement brut`, `soldes non dépensés`, `mensualités ouvertes non servies`, `avoirs`, `remboursements dus`, `litiges`, `revenu acquis`, `frais PSP/FX` et `trésorerie disponible après réserve`. Calculer la réserve au moins sur prestations restant à fournir et remboursements probables, puis tester le stress : 10 % de chargebacks/avoirs sur une cohorte, frais de carte internationaux, 2 % FX si applicable, pawaPay + spread, coût de remplacement. Les coûts de paie enfant 20 USD et adulte 30 USD par élève/mois restent des **propositions** ; une classe maintenue sous quatre élèves sur décision de Rewayah et la garantie professeur doivent être provisionnées séparément. Le CFO peut contester le prix 60 adulte si ces coûts absorbent la marge, mais ne peut financer la différence en consommant deux fois le solde.

**Objection juridique : « Solde en USD, fermeture par élève : est-ce déjà de la monnaie électronique ? »** Inconnu. Le contrat interdit transferts/retraits libres et limite l'usage aux services propres de Rewayah, mais la qualification dépend des faits et du territoire. La [FCA rappelle les services régulés et l'exclusion limitée](https://www.fca.org.uk/firms/limited-network-exclusion). Demander un avis ciblé sur : principal vendeur du cours (LTD ou enseignants tiers), portée géographique, valeur prépayée, remboursements, droits des mineurs, titulaire des fonds, seuil éventuel de notification et traitement de la rétractation/résiliation par pays client. Si le montage n'est pas admissible, repli commercial : **facture mensuelle payée à l'ouverture, avoirs/remboursements contractuels tracés**, sans présenter un solde rechargeable général. Cette variante garde le prix et la règle de service, mais retire la recharge libre. L'avis ne doit pas retarder la tenue manuelle de reçus et dettes de cours des vingt élèves actuels.

**Décision réservée au directeur :** adopter ou rejeter la mensualité fermée, fixer 50/60 et remises, durée de rattrapage et date d'effet ; faire signer les conditions avant toute vente nouvelle. Pour les clients actuels, inventorier prix encaissé, bénéficiaire et cours dus ; préserver leur contrat jusqu'au terme payé, proposer la nouvelle règle pour une période future avec consentement, créditer ou rembourser le trop-perçu sans conversion arbitraire en « unités ». **État de preuve :** aucune activation Stripe, PayPal, Verto ou pawaPay, aucun corridor GN/CI/SN propre à Rewayah, aucun taux FX contractuel, aucune qualification réglementaire, aucun paiement ni remboursement test n'ont été constatés dans cette mission de recherche.


---

# ANNEXE 21 - Plan d’implémentation et recette financière

_Source : `05_PLAN_IMPLEMENTATION_APP.md`. Contenu conservé pour ne pas perdre les détails métier._


# 05 - PLAN D'IMPLÉMENTATION REWAYAH V3

30 septembre 2026. Spécification arrêtée ; implémentation non exécutée. S'appuyer sur les cinq documents métier V3, puis sur `06` pour les coûts externes. Les règles ne doivent pas être recopiées sous forme de calculs divergents dans chaque écran.

## 1. Architecture des règles

Un service de calcul déterministe produit devis, calendrier facturé, aide, paie et explications. Les interfaces consomment ces résultats avec leur version. La logique de référence, les autorisations et la validation des écritures financières sont contrôlées côté serveur. Le frontend peut prévisualiser, jamais décider seul d'un prix ou crédit réel.

Objets métier requis, à mapper sur l'existant avant de créer quoi que ce soit : version de politique avec date d'effet ; offre vitrine ; demande d'inscription ; groupe et pattern/fuseau ; affectation enseignant ; séance planifiée et séance d'origine d'un rattrapage ; place élève et régime de prix ; facture mensuelle et détail ; journal de solde ; dossier d'aide confidentiel ; engagement de bourse ; lignes de paie ; attribution de bonus mensuel ; barème de frais par corridor ; budget/version de prévision ; événement d'audit.

Chaque devis conserve les entrées utilisées : catégorie/format, foyer éligible, T/O/E, dates de congé, aide, taxe, frais, version et expiration. Toute opération financière autoritaire recalcule ou vérifie le devis côté serveur avant validation. Une modification de règle n'altère jamais un devis accepté ni une écriture clôturée.

## 2. Codé dans le moteur et non modifiable par un écran

| Invariant | Comportement obligatoire |
|---|---|
| Autorisation | Vérifier côté serveur identité, capacité et périmètre à chaque lecture/écriture ; refus par défaut |
| Solde | Écritures append-only et corrections compensatrices ; aucune modification directe d'un montant historique |
| Unicité | Un débit de service par élève, mois et engagement ; changer de version ne crée pas un deuxième débit, mais une écriture compensatrice si nécessaire ; une paie par prestation validée ; un bonus mensuel par bénéficiaire |
| Idempotence | Réexécution d'une demande, d'un job ou d'un événement prestataire sans double crédit/débit/versement |
| Prix | Calcul en unités monétaires précises, devise explicite, arrondi final ; pas de nombres flottants approximatifs pour le ledger |
| Congés | O=0 donne zéro ; appliquer le tarif congé avant prorata d'entrée E/O ; pas de second plancher sur le prorata |
| Cohorte | Un calendrier commun ; absence ordinaire ne crée pas de consommation gratuite ; pas d'échéance individuelle glissante |
| Bourses | Réserver quota et budget atomiquement ; compter les engagements ; préserver une bourse existante malgré baisse de N |
| Remplacements | Une séance ne peut pas être payée deux fois ; aucun transfert rétroactif de paie acquise au gagnant du bonus |
| Dossiers sensibles | Motif orphelin/conversion non accessible aux enseignants, élèves tiers, support général ou IA |
| Preuve paiement | Retour de navigateur ou capture utilisateur ne suffit pas à créditer ; confirmation prestataire ou rapprochement autorisé |
| Secrets | Identifiants API et secrets de paiement absents du client et des journaux utilisateur ; référence sécurisée seulement dans la configuration |
| Version | Les changements prennent effet à une date publiée ; aucune modification rétroactive silencieuse |
| Limites | Capacité pédagogique, quote-part et droits doivent être contrôlés en concurrence, pas seulement au clic UI |

Le mois civil et l'algorithme de cumul/bonus sont des politiques implémentées et versionnées. Ils ne disposent pas d'un simple interrupteur permettant de revenir au mode 30 jours. Un changement de modèle requiert spécification et migration contrôlée. Les nombres suivants restent configurables.

## 3. Paramètres dynamiques de lancement

| Paramètre | Valeur V3 | Modification autorisée |
|---|---|---|
| Prix enfant/adulte | 50 / 60 USD | Directeur, date d'effet et notification |
| Remise familiale | seuils 2/3, montants 5/10 USD individuels | Directeur ; simulation foyer avant publication |
| Base paie enfant/adulte | 20 / 26 USD | Directeur, contrat/version future |
| Bonus incomplet/plein ou multiclasses | 10 / 20 USD, multiclasses à partir de 2 | Directeur |
| Capacité enfant/adulte | 5 / 6, débutants 4 | Directeur ; responsable académique choisit le profil approuvé |
| Minimum d'ouverture | 4 | Directeur ; ouverture sous seuil par autorisation et budget tracés |
| Plafond classes/enseignant | 2 | Directeur via le dispositif de badge |
| Préavis de démarrage | 48 heures | Directeur |
| Attente formation | 14 jours + une extension de 7 jours consentie | Directeur |
| Mise à jour demande | J7 au plus tard et à chaque événement important | Admin opérationnel selon règle |
| Pause personnelle | mois complet, préavis 7 jours | Directeur pour règle ; famille pour sa demande |
| Absence titulaire | 14 jours calendaires maximum | Directeur pour règle ; admin pour affectation |
| Quota gratuit | 3 par tranche complète de 100 payants | Directeur, simulation et engagements conservés |
| BDD | orphelins 12 mois/limite 18 ans ; convertis 6 mois | Directeur ; dossier individuel contrôlé |
| Conversion récente | 24 mois avant demande | Directeur, sans automatiser un jugement religieux |
| Contribution aide partielle | 10 % minimum après coûts directs | Directeur, contrôle global obligatoire |
| Marge nette globale | plancher 40 % | Directeur uniquement par nouvelle version explicite ; aucune dérogation ponctuelle cachée |
| Congés | dates grégoriennes publiées, Ramadan ≤20 jours, Tabaski 10 jours | Admin prépare, directeur publie |
| Plancher mois congé | 25 enfant / 30 adulte | Directeur |
| Sponsoring / API / LiveKit | maxima 300 / 50 / 500 USD mensuels | Directeur ; frais réellement observés séparés |
| Barèmes externes | pourcentage, fixe, devise, taxe, FX, minima/maxima | Comptable prépare, directeur approuve l'activation |
| Régime fiscal | dossier réel par territoire, période et taxe | Comptable renseigne, directeur valide la publication des prix |
| Prévisions et coût de personnel | charges engagées, estimées documentées et réelles distinctes | Comptable ; directeur pour engagement |

Aucune valeur non connue n'est remplacée par zéro afin de faire passer un contrôle. Les prix publics et les plafonds de budget sont des décisions ; leur activation opérationnelle dépend des données de coût et des comptes réellement habilités.

## 4. Permissions par rôle

Le directeur est un administrateur possédant des capacités privilégiées ; ne pas déduire ce statut d'un nom, d'une adresse email dans le client ou d'un champ modifiable par l'utilisateur.

| Action | Directeur | Admin opérationnel | Comptable | Contrôleur | Enseignant | Tuteur / adulte |
|---|---|---|---|---|---|---|
| Publier prix, règles, budgets | Oui | Non | Préparer coûts | Lire | Non | Lire son devis |
| Modifier calendrier de cours | Approuver changement structurel | Préparer/exécuter autorisé | Lire effet financier | Lire | Proposer | Accepter changement concernant sa place |
| Affecter/remplacer un professeur | Oui | Oui, groupes autorisés | Lire paie | Lire | Disponibilités seulement | Lire son groupe |
| Valider niveau/capacité pédagogique | Oui ou délégation académique | Si capacité académique accordée | Non | Lire décision sans notes privées inutiles | Groupes confiés, selon habilitation | Demander réévaluation |
| Instruire une aide | Oui | Uniquement délégation confidentielle explicite | Coûts/montants, pas motif religieux détaillé | Audit restreint | Non | Son dossier ou enfant représenté |
| Accorder aide gratuite/partielle | Oui, contrôle automatique préalable | Non par défaut | Préparer calcul | Lire résultat | Non | Accepter son offre |
| Créditer après paiement manuel | Approuver ou capacité financière dédiée | Non | Rapprocher et soumettre | Lire | Non | Déposer référence/preuve |
| Corriger facture / restituer | Approuver action motivée | Signaler | Préparer écriture compensatrice | Lire | Non | Demander |
| Clôturer paie / envoyer paiement | Autoriser lot final | Non | Préparer et rapprocher | Lire | Lire sa paie/contester | Non |
| Consulter soldes | Périmètre nécessaire | État payé/non payé nécessaire au service | Données financières | Lecture audit | Pas de solde familial | Son solde et enfants autorisés |
| Accorder droits privilégiés | Oui, contrôle renforcé | Non | Non | Non | Non | Non |

Le contrôleur ne devient pas éditeur par le fait de détecter une anomalie. Le support général voit uniquement le contexte utile à la demande. Un enseignant voit une place autorisée et les besoins pédagogiques, pas le montant payé ni le motif d'une aide. À la majorité, ne pas prolonger automatiquement les droits de représentation du tuteur sur les données personnelles et pédagogiques ; le paiement par un parent ne donne pas accès à tout le dossier d'un adulte.

Au lancement avec une seule personne administrative, le directeur peut assumer les tâches opérationnelles et financières avec réauthentification renforcée, motif, preuve et audit. Ne pas prétendre qu'un double contrôle indépendant a eu lieu. Dès délégation, séparer préparation et approbation des versements ; aucun comptable ne s'accorde ses propres droits. Ne pas bloquer la maquette pour créer artificiellement un deuxième employé.

L'IA n'a aucun droit d'écriture financière ou d'attribution. Elle lit seulement les règles publiques et un contexte minimal autorisé ; les dossiers religieux, KYC et secrets sont exclus. Elle transmet un besoin à un humain sans décider du résultat.

## 5. Surfaces et états UI

| Surface canonique | Contenus et actions |
|---|---|
| Classes | Vitrines, compatibilité, choix du pattern, demande personnalisée secondaire |
| Ma demande | Étapes réelles, prochaine mise à jour, échéance, date confirmée quand connue, alternatives et annulation |
| Détail de classe | Professeur affecté et photo, première date, calendrier, fuseaux, statut de la place, règles de reprise |
| Solde et paiements | Solde par élève et total foyer, facture détaillée, prochain débit, recharge, avoir/restitution, échec paiement |
| Absences et pauses | Absence ordinaire sans gratuité, pause mensuelle gratuite, préavis, impact sur le foyer, retour non garanti |
| Aides | Demande confidentielle, durée, montant dû, couverture, échéance et renouvellement ; motif jamais public |
| Enseignant - rémunération | Séances, base, division T, titulaire/astreinte, bonus unique expliqué, mois acquis et mois payé |
| Admin - groupes | Formation, échéances à traiter, affectation, ouverture et exception financée, pauses, capacité |
| Admin - politiques | Paramètres, historique, aperçu avant/après, date d'effet, droits d'approbation |
| Finance | Rapprochements, passifs clients, paies, engagements bourses, budget, marge observée/prévue, alertes capacité |

Une fonction possède un écran de référence ; les autres écrans affichent un résumé avec lien. Éviter plusieurs formulaires contradictoires de pause, remise ou remboursement.

Chaque parcours couvre chargement, vide, succès, erreur, accès interdit, données incomplètes, état périmé et action concurrente. Une aide impossible pour budget insuffisant est expliquée sans exposer les finances de tiers. Une politique modifiée pendant un devis provoque un nouveau devis explicite, pas un montant changé au dernier clic.

Respecter mobile/tablette/vrai desktop, clair/sombre, accessibilité clavier et lecteur d'écran, contrastes, annonces de statut ; les dates et erreurs ne reposent pas sur la couleur seule. DM Sans pour titres français, Plus Jakarta Sans pour texte latin. Préserver les maquettes validées lorsqu'elles correspondent à V3.

## 6. Lots de réalisation

1. **Contrats fonctionnels et fixtures** : rapprocher l'existant des règles CAL/PRIX/AIDE/PROF/CONG/FIN ; identifier les anciens écrans, libellés et calculs de 30 jours. Préparer les données de démonstration et les décisions de version, sans exécuter de migration.
2. **Parcours famille et adulte** : Classes → Ma demande → Confirmation → Solde → Pauses/Aides. Perfectionner l'existant et réaliser les états manquants. Montrer calcul mensuel et congés sur données contrôlées.
3. **Parcours enseignant** : affectation, remplacement, séances, calcul de paie, attribution du bonus et contestation. Empêcher les actions hors périmètre dans l'UI.
4. **Administration et finance** : politiques datées, simulation avant publication, réservations de quota/budget, rapprochements et lots de paiement. Matrice des capacités visible en recette.
5. **Enforcement et intégration financière** : après autorisation d'implémentation correspondante, appliquer les invariants côté serveur, validations prestataires et tests d'isolation. Les écrans des lots précédents ne sont pas une sécurité suffisante pour l'argent réel.
6. **Recette et bascule** : scénario complet par rôle, calculs, droits, incidents et restauration. Activer seulement les corridors avec compte opérationnel et barème approuvé. Aucun débit réel sur la seule base de fixtures.

La préparation UI peut avancer immédiatement. Ce document est un plan ; il n'autorise pas par lui-même un push, une migration, un envoi de paiement ou un déploiement. La reprise des dossiers existants conserve soldes et droits acquis ; aucune re-facturation pour aligner arbitrairement une famille au 1er. La bascule d'un éventuel ancien cycle actif nécessite un devis de transition sans double service facturé et une date d'effet acceptée.

## 7. Recette attendue

| Cas | Résultat attendu |
|---|---|
| Deux enfants + adulte, régime familial | 40 + 40 + 50 = 130 USD pour mois complet normal |
| Un enfant gratuit + un adulte | 0 + 60, le gratuit ne crée pas le palier familial |
| Deux normaux + une aide partielle | Les deux normaux reçoivent 5 USD chacun ; aide calculée à part et non cumulée |
| Deux entrées simultanées dans un foyer | Un même instantané familial cohérent pour les deux devis |
| Nouvelle cohorte démarrant le 12 | Même premier cours et calendrier pour tous ; prorata puis renouvellement commun le 1er |
| 13 séances normales, E=8, enfant 50 | Débit initial 30,77 USD |
| Congé T=13 O=6, enfant familial 40 | Mois complet 25 USD ; entrée E=3 → 12,50 USD |
| Congé T=13 O=6, adulte familial 50 | Mois complet 30 USD ; entrée E=3 → 15 USD |
| O=0 | Aucun débit et aucune division par zéro |
| Absence élève à une séance disponible | Pas de réduction du débit ni de la paie attachée à la place |
| Pause complète annoncée dans le délai | Aucun débit de service sur ce mois ; effet familial annoncé |
| Demande de pause de quelques jours | Information sur absence ordinaire payante ; aucun gel à la séance |
| 99/100/199/200 payants | Plafonds gratuits 0/3/3/6 |
| Quota tombe sous engagements existants | Maintien de la couverture promise ; nouvelles attributions bloquées |
| Deux demandes sur dernière bourse | Une seule attribution finale, quota/budget non dépassés |
| Bourse se termine à 18 ans | Fin à la date annoncée ; devis de continuation accepté, pas de débit surprise |
| Astreint 8 séances / titulaire 5 | Chacun sa paie de séances ; bonus de cette classe attribué à l'astreint |
| Deux classes incomplètes attribuées au même bénéficiaire | Un bonus total de 20 USD |
| Une classe complète à capacité pédagogique de 4 | Bonus 20 USD au bénéficiaire |
| Égalité des séances | Départage déterministe défini dans `03`, pas deux bonus |
| Rattrapage dans mois suivant | Même prestation d'origine ; pas de second débit ni de double paie |
| Webhook répété et réponse navigateur falsifiée | Un seul crédit vérifié ; faux retour sans effet financier |
| Famille tente l'identifiant d'une autre famille | Lecture et modification refusées côté serveur |
| Enseignant modifie bonus/prix dans la requête | Refus côté serveur, montant recalculé à partir de la politique |
| Comptable tente auto-approbation du lot | Refus sans capacité d'approbation ; action tracée |
| Contrôleur / IA tente une mutation | Refus ; aucun contournement par un écran caché |
| Frais manquants ou devise différente | Contrôle financier incomplet visible ; aucun faux coût nul |
| Budget LiveKit approche plafond | Alerte et contrôle des nouvelles ouvertures ; aucune coupure automatique des cours vendus |

Ces tests sont des critères à implémenter. Les exemples arithmétiques du dossier ont été vérifiés ; les permissions et transactions de l'application ne sont pas déclarées testées sans exécution réelle.


---

# ANNEXE 22 - Source financière et règles opérationnelles récentes - lire en premier

_Source : `00_LIRE_EN_PREMIER.txt`. Contenu conservé pour ne pas perdre les détails métier._


# REWAYAH - STRATÉGIE DE LANCEMENT V3

Décisions arrêtées le 30 septembre 2026 sur mandat du directeur. Cette version remplace les règles incompatibles de V2, V2.1 et des anciens dossiers. Les arbitrages de ce périmètre sont clos. Une nouvelle modification doit produire une version datée et expliciter son impact sur les engagements existants.

Les règles métier ci-dessous sont décidées. Un tarif fournisseur publié ne vaut pas contrat Rewayah ; un budget plafond ne vaut pas facture ; une recette de test écrite ne vaut pas test exécuté. Ces distinctions protègent les décisions contre de fausses certitudes.

## Décisions essentielles

| Référence | Règle arrêtée |
|---|---|
| CAL-01 | Une nouvelle classe démarre dès qu'elle est prête, à une date commune à tous ses premiers élèves. Pas d'obligation d'attendre le 1er |
| CAL-02 | Facturation au mois civil, renouvellement commun le 1er ; premier mois au prorata des séances accessibles. Remplace les périodes glissantes de 30 jours |
| CAL-03 | Une entrée ultérieure dans une classe existante se fait au début d'un mois et après placement pédagogique. Aucun cycle de facturation individuel |
| PRIX-01 | Enfant 50 USD ; adulte 60 USD par mois normal complet |
| PRIX-02 | Remise par personne : deux membres éligibles = 5 USD chacun ; trois ou plus = 10 USD chacun |
| PRIX-03 | Boursiers gratuits et bénéficiaires d'une aide sociale partielle exclus du seuil familial ; aucun cumul des deux remises |
| AIDE-01 | Plafond simultané : trois bourses gratuites par tranche complète de 100 payants actifs. Attribution sous contrôle financier et pédagogique |
| AIDE-02 | BDD : orphelins 12 mois, sans dépasser le 18e anniversaire ; nouveaux convertis 6 mois. Renouvellement examiné avant échéance. BDI non ouverte au lancement |
| AIDE-03 | Après épuisement du quota, aide partielle possible avec au moins 10 % de contribution après coûts directs, et contrôle de la marge globale |
| PROF-01 | Bases mensuelles : 20 USD par enfant, 26 USD par adulte. Paie acquise par séance assurée ; règlement en fin de mois |
| PROF-02 | Bonus unique par enseignant bénéficiaire : deux classes ou plus = 20 USD ; une classe pleine = 20 USD ; une classe incomplète = 10 USD |
| PROF-03 | Dans une classe partagée, le bonus revient au professeur ayant assuré le plus de séances dans le mois. La paie des séances reste à leur réalisateur |
| PROF-04 | Retour du titulaire dans les 14 jours calendaires : affectation conservée ; au-delà : retrait de cette classe |
| ATT-01 | Formation du groupe : 14 jours maximum, point à J7 ; une prolongation de 7 jours exige l'accord du demandeur |
| ABS-01 | Absence ordinaire : période payante conservée. Pause personnelle gratuite : mois civil complet annoncé au moins 7 jours avant son début |
| CONG-01 | Ramadan : fermeture du 20 Ramadan au 7 Shawwal inclus, dans la limite de 20 jours ; Tabaski : du 9 au 18 Dhu al-Hijja inclus, 10 jours |
| CONG-02 | Débit mensuel réduit selon les séances ouvertes, avec plancher mensuel de 25 USD enfant / 30 USD adulte ; aucune séance ouverte = aucun débit |
| FIN-01 | Plancher de pilotage : 40 % de marge nette après charges et impôts. Le quota de bourses n'est pas une preuve de rentabilité |
| FIN-02 | Sponsoring : 300 USD/mois maximum ; LiveKit : budget cible plafonné à 500 USD/mois ; assistance IA : 50 USD/mois au lancement |
| SEC-01 | Valeurs commerciales configurables et versionnées ; invariants de sécurité codés et contrôlés côté serveur |

## Cap et exécution

Renaissance de l'académie : nouveaux enseignants qualifiés et nouveaux élèves, priorité poular/français/anglais. Les obligations de l'ancien service restent dues et suivies séparément. La cible de 1 000 payants fin 2026 reste un objectif, non une prévision garantie ; 5 000 est un palier de capacité à financer.

Ordre : règles V3 → qualification enseignants et supports → plan d'implémentation → parcours testés → ouverture de groupes viables → sponsoring progressif. Aucun code, compte fournisseur ou déploiement n'a été modifié par ces documents.

## Lecture

1. `01_OFFRE_ET_PEDAGOGIE.md` : service et pédagogie.
2. `02_PARCOURS_ET_SERVICE.md` : dates, attente, débit, congés, absences.
3. `03_RECRUTEMENT_CROISSANCE_TECH.md` : équipe, paie, bonus, budget, capacité.
4. `04_ECONOMIE_ET_DECISIONS.md` : remises, aides, calculs et contrôle financier.
5. `05_PLAN_IMPLEMENTATION_APP.md` : écrans, configuration, permissions, lots et recette.
6. `06_TARIFS_PRESTATAIRES_ET_BUDGET.md` : sources officielles et règles de coûts.

Les anciennes maquettes restent des références visuelles. Les règles V3 priment pour les montants, calendriers et états. DM Sans pour les titres français, Plus Jakarta Sans pour le reste latin, police arabe existante ; préserver l'existant utile et les parcours par rôle.


---

# ANNEXE 23 - Référentiel académique complet RA-CUR-2026.1 - 18 septembre 2026

_Source : `REWAYAH_REFERENTIEL_ACADEMIQUE_V1(1).docx`. Extraction du document Word : paragraphes et tableaux conservés en texte ; les images et la mise en page originale ne sont pas incorporées._


REWAYAH ACADEMY

# Référentiel académique complet

Du débutant complet à la lecture autonome du Coran et au Ḥifẓ complet

Version RA-CUR-2026.1  |  18 septembre 2026

Principe directeur

Exigence forte sur les résultats. Simplicité maximale dans l’expérience quotidienne.

# 1. Objet et doctrine académique

Ce document définit le noyau académique de Rewayah Academy. Il complète le vide laissé dans la V1 de l’application : les structures de programmes, niveaux, compétences, évaluations et passeport pédagogique existaient déjà dans l’architecture, mais le curriculum normatif qui leur donne un sens n’était pas défini.

Le principe de maîtrise adopté est simple : les résultats attendus restent fixes, le temps nécessaire peut varier. Un élève n’achète jamais un passage de niveau. Les frais donnent accès au service pédagogique, pas à une validation académique.

# 2. Méthode de construction et niveau de preuve

Décisions de direction : les arbitrages exprimés par Rewayah dans les échanges de conception sont considérés comme les politiques fondatrices du produit.

Sources internes : Rewayah Control System V2, Parcours Utilisateurs MVP-0, Audit Architecture, Frontend/UIUX Bible V2, décisions d’architecture et spécifications LiveKit.

Références externes : preuves générales sur mastery learning, petit groupe, apprentissage collaboratif, feedback, engagement parental, devoirs, assiduité et charge administrative des enseignants.

Tradition pédagogique du Ḥifẓ : distinction entre nouveau, révision récente et révision ancienne, reprise sous une terminologie simple dans Rewayah.

Quand aucun standard universel n’existe pour une académie coranique en ligne, le document le dit explicitement et crée une politique Rewayah versionnée au lieu de présenter une préférence comme une norme universelle.

# 3. Architecture générale du parcours

Orientation par défaut : enfant = Ḥifẓ après validation du tronc commun, sauf demande explicite du tuteur ou contre-indication pédagogique. Adulte = choix éclairé entre Tilāwah et Ḥifẓ après le gate d’orientation.

# 4. Système d’objectifs

# 5. Diagnostic, admission et placement en groupe

## 5.1 Diagnostic en deux temps

Pré-diagnostic dans l’onboarding : auto-déclaration courte sur lecture, mémorisation, âge, expérience et disponibilité. Aucun niveau officiel n’est attribué ici.

Diagnostic académique après création du compte : lecture ou récitation réelle, adaptative, qui s’arrête dès que le niveau est clairement identifié.

Règle débutant : si le candidat reste dans la zone de début de F1, il reprend F1 depuis le début du prochain groupe compatible. Rewayah évite les micro-placements artificiels qui complexifient l’exploitation pour un gain faible.

Critères pour rejoindre un groupe existant : même cycle ou cycle immédiatement voisin compatible, écart rattrapable en deux semaines au maximum sans charge spéciale durable pour l’enseignant, compatibilité d’âge raisonnable pour les enfants, place disponible et horaires compatibles.

# 6. Cycle Fondamental Rewayah

## 6.1 Principe de priorité unique et tuilage

Une seule priorité domine à la fois. Le rapport 70/30 sert à la planification du cycle, pas au chronométrage rigide de chaque séance. L’enseignant n’a jamais à calculer des minutes de matière.

* Durées indicatives, non contractuelles. Elles supposent 3 séances par semaine, assiduité correcte et travail maison régulier. Le passage dépend de la maîtrise, pas du calendrier.

## 6.2 F1 - Fondations de lecture

Reconnaissance des lettres isolées et de leurs formes en début, milieu et fin de mot.

Articulation correcte des lettres à un niveau adapté au débutant, avec correction immédiate des confusions qui changent la lettre.

Fatḥa, kasra, ḍamma.

Madd naturel simple de deux temps avec alif, wāw et yāʾ.

Lecture de syllabes puis de mots entièrement vocalisés.

## 6.3 F2 - Décodage consolidé et récitation essentielle

Poursuite de Nour al-Bayân : sukūn, tanwīn, shadda et combinaisons associées.

Talaqqī oral : Al-Fātiḥa, Al-Ikhlāṣ, Al-Falaq et An-Nās, une par une, avec validation avant ajout de la suivante.

Corpus pratique de la Ṣalāh : takbīr, adhkār de rukūʿ et sujūd, redressement, assise entre les prosternations, tashahhud, ṣalawāt et salām selon le référentiel scientifique Rewayah.

La lecture écrite n’est pas encore exigée pour tout le corpus : l’objectif est d’abord la récitation correcte et la confiance dans la prière.

## 6.4 F3 - Lecture appliquée et invocations essentielles

Finalisation des éléments restants de la méthode Nour al-Bayân retenue par Rewayah et exercices de fluidité.

Les textes authentifiés d’invocations servent progressivement de supports de lecture afin de transférer les mécanismes appris vers de vrais textes utiles.

Corpus initial recommandé : sommeil/réveil, repas, toilettes, entrée/sortie de la maison, entrée/sortie de la mosquée, voyage ou déplacement court. Le texte exact et les variantes sont verrouillés par validation scientifique.

Rewayah n’ajoute pas ici de cours de fiqh, sīra, ʿaqīda ou hadith autonome : ces domaines restent dans PISI.

## 6.5 F4 - Immersion Muṣḥaf

Lecture directe sur le Muṣḥaf de Médine Ḥafṣ ʿan ʿĀṣim intégré nativement dans l’app.

Mémorisation et stabilisation de Al-Fātiḥa et des sourates 99 à 114.

Murājaʿah systématique des éléments de Ṣalāh et des invocations apprises.

Introduction du tajwid sous forme appliquée, couche par couche, sans cours théorique lourd.

## 6.6 Gate de sortie du cycle fondamental

# 7. Tajwid progressif - grille d’avancement

Le tajwid est introduit comme une succession de couches. Une règle peut être corrigée lorsqu’elle apparaît avant son enseignement formel, mais elle ne devient exigence de passage qu’à partir de sa couche officielle.

Cette séquence est un standard Rewayah V1, pas une prétention d’universalité. Elle doit être revue une fois par un enseignant habilité en Ḥafṣ avant publication externe, puis versionnée.

# 8. Mesure de maîtrise et erreurs

# 9. Modèle de groupe et progression de cohorte

Le groupe partage un niveau de compétence et une leçon commune, mais chaque élève peut avoir un passage, une vitesse ou une quantité individuelle. Rewayah adopte donc : enseignement commun + progression individuelle bornée.

## 9.1 Corridor de cohorte

## 9.2 Protocole enfant - 60 minutes

Pendant qu’un élève récite, les autres ont une mission active : suivre le verset, repérer la règle du jour, préparer leur tour, écouter une lettre cible ou répondre à une correction collective. Le temps d’un camarade n’est jamais du temps mort.

## 9.3 Protocole adulte - 90 minutes

5 minutes : ouverture, présence, objectif.

15 à 20 minutes : leçon commune ou tajwid appliqué.

45 à 50 minutes : passages individuels avec missions actives pour le groupe.

10 à 15 minutes : correction collective, démonstration, plan de révision.

5 minutes : clôture et objectifs individuels.

# 10. Travail à domicile et micro-learning

Une carte unique « Avant le prochain cours » avec au maximum trois actions.

Exemples : écouter un modèle, relire 5 lignes, répéter une sourate, revoir une règle, préparer une portion de mémorisation.

Chez l’enfant, le tuteur veille à l’environnement, au rappel et à la régularité. Il n’a pas à devenir professeur.

Le bouton « fait » peut exister comme aide d’organisation, mais n’est jamais une preuve académique.

La preuve est la différence observable au cours suivant. L’enseignant juge le résultat, pas la surveillance domestique.

Si la préparation est régulièrement insuffisante, l’app signale une tendance et peut proposer la suspension du nouveau contenu.

# 11. Orientation après le tronc commun

# 12. Parcours Tilāwah - lecture complète et fluide

Objectif : lire le Coran entier sans assistance, avec fluidité et intégration progressive du tajwid. Le parcours implique au moins une lecture intégrale du Muṣḥaf suivie dans l’app ; le professeur ne doit pas entendre chaque verset, mais des échantillons représentatifs sont contrôlés à chaque cycle.

## 12.1 Certification de lecture autonome

Lecture de trois passages non préparés provenant de zones différentes du Coran.

Durée recommandée : 5 à 7 minutes par passage.

Aucune erreur E3 non corrigée dans les échantillons finaux.

Maximum V1 : deux erreurs E2 par échantillon ; auto-corrections E1 brèves tolérées.

Règles J0-J6 appliquées selon le niveau final attendu.

Si l’élève échoue, il reçoit une prolongation ciblée. Aucun redoublement global.

# 13. Parcours Ḥifẓ - mémorisation complète et rétention

Le Ḥifẓ Rewayah n’est jamais défini par la quantité de nouveau seule. Chaque élève gère simultanément trois flux : nouveau, révision récente et révision ancienne. Cette logique correspond à une pratique largement répandue sous les noms Sabaq, Sabqi et Manzil, mais Rewayah utilise des libellés simples dans l’app.

## 13.1 Quantité de nouveau - bandes de départ

Les versets ne sont pas une bonne unité de charge, car leur longueur varie fortement. Rewayah mesure la quantité de Ḥifẓ principalement en lignes/pages du Muṣḥaf de Médine, dont les éditions du Complexe Roi Fahd utilisent 15 lignes par page.

* L’accélération n’est autorisée que si la révision récente et ancienne reste stable. L’enseignant peut réduire ou suspendre le nouveau à tout moment.

## 13.2 Règle de protection du Ḥifẓ

## 13.3 Cycle d’Itqān final

Commence seulement après mémorisation initiale des 30 ajzāʾ.

Aucun certificat final immédiat au dernier verset mémorisé.

Au moins une rotation complète de révision de l’ensemble du Coran selon un plan défini avec l’enseignant.

Contrôles aléatoires couvrant l’ensemble des zones, pas seulement les dernières parties.

Examen final réparti en plusieurs séances afin de réduire l’effet d’un seul jour et de vérifier la stabilité.

Le certificat final atteste le Ḥifẓ complet et consolidé selon le standard Rewayah ; il ne constitue pas automatiquement une ijāzah.

# 14. Pouvoir pédagogique de l’enseignant

## 14.1 Suspension de progression

Déclencheurs automatiques possibles : assiduité faible, plusieurs statuts « à renforcer », révision ancienne qui se dégrade, retard persistant.

Déclencheur professionnel : l’enseignant peut suspendre même si aucun seuil automatique n’est franchi, avec un motif court.

Statuts simples : Continuer / Renforcer / Suspendre le nouveau.

La suspension est pédagogique, jamais disciplinaire. Elle est visible au tuteur avec une explication concise.

# 15. Évaluation

## 15.1 Les quatre Majālis annuels

Quatre fenêtres par année civile, dates publiées par l’académie.

Une fenêtre majeure juste après ʿĪd al-Fiṭr, après la période de révision de Ramadan.

Participation attendue sauf motif accepté.

Pas de classement public humiliant, pas de promotion automatique de niveau.

Les résultats peuvent déclencher une vérification si un écart important apparaît entre performance publique et suivi quotidien.

# 16. Attestations, certificats et identité académique

Les jalons 5, 10, 15, 20 et 25 ajzāʾ peuvent produire des reconnaissances internes dans l’app, mais pas des certificats téléchargeables. Le prestige du certificat vient de sa rareté et de critères publiés à l’avance.

Nomenclature proposée : Ṭālib / Ṭāliba pendant le parcours. Le titre Qāriʾ peut être réservé à la certification de lecture, et Ḥāfiẓ au Ḥifẓ complet consolidé. Pour les enseignants, Muʿallim/Muʿallima ou Ustādh/Ustādhah décrit mieux la fonction académique que Sayyid/Sayyida, qui peut rester une formule de courtoisie si Rewayah le souhaite.

# 17. Assiduité, retard, maladie, pause et abandon

La politique économique reste séparée : une place réservée peut rester due même si l’élève est absent ; une séance non assurée par Rewayah donne lieu à compensation pédagogique selon le module financier. Le présent document ne fixe pas les mécanismes de paiement.

# 18. Discipline et comportement

Les incidents graves peuvent sauter des étapes. Inversement, la faiblesse scolaire, la lenteur ou la maladie ne sont jamais des fautes disciplinaires.

# 19. Contrat d’attentes par rôle

## 19.1 Ṭālib / Ṭāliba

Être présent et prêt à l’heure.

Écouter activement même quand un autre élève récite.

Réviser et préparer le travail demandé entre les séances.

Accepter la correction et respecter le protocole de groupe.

Ne pas réclamer un passage de niveau sans validation des prérequis.

## 19.2 Tuteur

Garantir autant que possible la ponctualité, l’assiduité, un environnement calme et l’accès technique.

Veiller après le cours à ce que l’enfant revoie ce qui a été demandé, sans devoir enseigner le contenu à la place du Muʿallim.

Consulter les alertes réellement importantes : présence, niveau, prérequis manquants, conseil enseignant/admin.

Ne pas intervenir pendant le cours. L’observation en lecture seule reste possible selon les règles de la salle.

Peut demander une réévaluation ou une réorientation, mais ne peut pas imposer un curriculum particulier.

## 19.3 Enseignant / Muʿallim

## 19.4 Administration

Ne suit pas tous les élèves un par un. Elle gère une file d’anomalies et de décisions.

Intervient sur : blocage prolongé, assiduité à risque, écart de cohorte, transfert, discipline, recours, certification, qualité enseignant.

Dispose d’un cockpit pédagogique avec santé des groupes, taux de compétences stables, élèves hors corridor, gates à venir et anomalies.

Peut créer une nouvelle version de programme, unité, corpus ou seuil sans coder, mais ne peut pas modifier rétroactivement une version publiée.

L’admin est l’autorité de validation scientifique provisoire pour les éléments simples ; une gouvernance scientifique élargie pourra être ajoutée plus tard.

# 20. Ce que l’application automatise

# 21. KPI utiles sans bureaucratie

La vitesse brute d’apprentissage n’est jamais utilisée seule pour comparer les enseignants. Un système qui récompense « les élèves qui vont vite » inciterait à valider trop tôt ou à éviter les élèves difficiles.

# 22. Calendrier académique

Cursus continu par compétences : pas de « redoublement annuel » ni de remise à zéro en septembre.

Quatre Majālis annuels comme fenêtres institutionnelles de récitation publique et d’encouragement.

Ramadan : réduction du nouveau, priorité à la murājaʿah ; l’académie peut consacrer approximativement la seconde moitié à une période de révision sans progression normale, selon le calendrier annuel publié.

Premier Majlis majeur après ʿĪd al-Fiṭr.

ʿĪd al-Aḍḥā : environ une semaine de congé institutionnel.

Les vacances familiales hors calendrier Rewayah restent des pauses individuelles et peuvent avoir des conséquences de placement au retour.

# 23. Persona de validation : Binta, 8 ans, inscription le 20 septembre

Durée réaliste : Rewayah ne promet pas une date artificielle de Ḥifẓ complet. À 1,5 page de nouveau par semaine, un parcours complet prend plusieurs années ; à 3 pages par semaine, il peut être beaucoup plus rapide. La vitesse est un résultat de capacité + régularité + rétention, jamais une promesse marketing.

# 24. Persona de validation : Munir, enseignant avec deux groupes

# 25. Contrôle qualité enseignant

Le programme et les gates standardisent les attentes.

Le rôle Contrôleur déjà prévu dans l’app peut observer certaines séances sans intervenir, avec traçabilité complète.

Contrôle par échantillonnage et anomalie, pas surveillance de chaque cours.

Calibration périodique des évaluations : un petit nombre d’extraits ou de cas est revu pour vérifier que deux enseignants utilisent les mêmes seuils.

Les bonus enseignants déjà prévus dans Rewayah peuvent valoriser fiabilité, obligations pédagogiques, rétention de cohorte et qualité, mais jamais le score brut des élèves seul.

# 26. Cas exceptionnels et limites assumées

# 27. Gouvernance et versionnement du curriculum

Chaque version publiée est immuable : RA-CUR-2026.1, RA-CUR-2027.1, etc.

Une modification est créée en brouillon, revue, puis publiée avec date d’effet.

Les élèves déjà engagés restent sur leur version sauf migration explicite et documentée.

Les changements mineurs de texte UI ne créent pas une nouvelle version académique ; les changements d’ordre, prérequis, seuils, certificats ou corpus oui.

Le Quran text lui-même n’est jamais éditable par l’admin.

L’admin peut éditer sans code les éléments de politique : capacités, durées, gates, descriptions, corpus pédagogiques, seuils, calendrier, mais uniquement via une nouvelle version quand l’effet est académique.

# 28. Impact sur l’architecture de l’app - fermeture du trou V1

Les docs Rewayah prévoyaient déjà programmes, niveaux, compétences, résultats d’évaluation et passeport de compétences. Le présent référentiel fournit le modèle académique absent. Il implique cependant quelques objets supplémentaires afin d’éviter de coder le curriculum en dur.

Les tables existantes `programs`, `levels`, `competencies`, `student_competency_records`, `assessments` et `assessment_results` restent utiles. Le Lot 03 et surtout le Lot 14 du Rewayah Control System doivent être mis à jour avant implémentation pour intégrer ce référentiel.

# 29. Critères d’acceptation produit

Binta peut voir dès son inscription le parcours complet sans être noyée dans les micro-compétences.

Son tuteur sait quoi faire cette semaine, ce qu’il ne doit pas faire, et quand Rewayah prendra une décision.

Munir peut donner une séance sans créer manuellement la présence, le programme, le passage ou cinq rapports.

Une personne faible ne peut pas immobiliser durablement quatre ou cinq autres personnes.

Une personne très forte peut avancer sans attendre artificiellement le groupe.

La direction n’ouvre pas les dossiers de tous les élèves chaque jour : elle reçoit une file d’exceptions.

Aucun passage de niveau n’est acheté ou négocié par la famille.

Le Ḥifẓ ne peut pas augmenter si la révision ancienne se dégrade durablement.

Le certificat final ne peut pas être obtenu par simple durée d’inscription ou paiement.

Une modification future du curriculum n’efface pas l’historique des élèves déjà engagés.

# 30. Deux validations obligatoires avant publication externe

# 31. Références et sources de conception

## 31.1 Sources internes Rewayah

rewayah_control_system_v2.md - programmes, niveaux, compétences, passeport, groupes, rôles, bonus enseignants, versionnement des politiques.

PARCOURS_UTILISATEURS_MVP0.md - parcours tuteur/élève/enseignant, cahier de transmission, contrôle, navigation.

AUDIT_ARCHITECTURE_REWAYAH_APP.md - suivi pédagogique, contrainte du rapport <45 secondes, contrôle qualité et risques.

REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md - faible profondeur d’interaction, classroom, Quran Reader, attendance.

architecture live kit..md - présence, speaking activity, analytics et séparation signal technique / validation pédagogique.

DECISIONS_ARCHITECTURE_MVP0.md - structure many-to-many des sessions et règles de groupe.

## 31.2 Références externes

Education Endowment Foundation - Mastery learning

Education Endowment Foundation - Small group tuition

Education Endowment Foundation - Collaborative learning approaches

Education Endowment Foundation - Feedback

Education Endowment Foundation - Parental engagement

Education Endowment Foundation - Homework

Education Endowment Foundation - Attendance evidence

OECD - TALIS 2024, The demands of teaching

King Fahd Complex - Glorious Qur’an Platform for Developers

King Fahd Complex - digital Mushaf information

Journal of Indonesian Islamic Studies - Saba’, Sabqi, Manzil (2026)

King Saud University - example of Quran memorization program with scientific evaluation

# 32. Dix règles constitutionnelles de Rewayah

1.  Le paiement achète un service, jamais une validation.

2.  Le programme fixe les résultats ; le temps peut varier.

3.  Le groupe n’attend pas indéfiniment un seul élève.

4.  Un élève rapide n’est pas freiné artificiellement.

5.  Le nouveau Ḥifẓ s’arrête si l’ancien se dégrade.

6.  L’enseignant enseigne ; l’app absorbe la bureaucratie.

7.  Le tuteur soutient hors cours ; il ne dirige pas le cours.

8.  L’administration travaille par exception, pas par micro-surveillance.

9.  Les certificats sont rares et difficiles à obtenir.

10.  Toute règle académique importante est publiée, mesurable, contestable par une voie de recours et versionnée.


[Tableau extrait 1]

Statut : référentiel académique V1 prêt à être traduit en produit et en règles métier. Deux validations restent obligatoires avant publication externe : validation scientifique du corpus précis de la Ṣalāh et des invocations, et correspondance page par page avec l’édition exacte de Nour al-Bayân retenue.


[Tableau extrait 2]

Rewayah n’est pas un LMS généraliste et ne remplace pas PISI. Rewayah couvre ce qui est directement nécessaire à la lecture, la récitation, la mémorisation, la révision, la pratique de la Ṣalāh et les invocations quotidiennes essentielles, avec une pédagogie centrée sur le Coran.


[Tableau extrait 3]

Résultat terminal commun | Définition

Lecture arabe vocalisée | Lire de manière autonome un texte arabe entièrement vocalisé, sans épellation assistée. Rewayah n’enseigne pas ici la langue arabe non vocalisée ni la grammaire générale.

Lecture du Coran | Lire le Muṣḥaf de Médine en Ḥafṣ ʿan ʿĀṣim avec fluidité, autonomie et un taux d’erreurs très faible au niveau avancé.

Ṣalāh | Réciter correctement les éléments du corpus de prière adopté par Rewayah. Le statut juridique détaillé de chaque formule relève du référentiel scientifique, pas de l’interface pédagogique.

Invocations essentielles | Connaître, comprendre le contexte d’usage et réciter un noyau limité d’invocations quotidiennes authentifiées.

Autonomie de révision | Savoir entretenir seul ce qui a été appris, utiliser un plan de révision et reconnaître quand une partie doit être renforcée.

Orientation Hifẓ | Pour l’élève qui choisit ou reçoit cette orientation : mémoriser le Coran entier puis stabiliser le Ḥifẓ par une révision structurée avant certification finale.


[Tableau extrait 4]

Aucune institution coranique mondiale n’impose aujourd’hui un curriculum universel unique pour la vitesse de mémorisation, les seuils d’erreurs ou la taille des groupes. Les éléments quantitatifs ci-dessous sont donc des standards internes Rewayah V1, conçus pour être mesurés, pilotés puis versionnés.


[Tableau extrait 5]

Code | Cycle | Statut | Sortie principale

D0 | Diagnostic et placement | Obligatoire à l’entrée | Affectation au point d’entrée réel et au groupe compatible

F1 | Fondations de lecture | Tronc commun | Lettres, formes, voyelles courtes, madd naturel, décodage simple

F2 | Décodage consolidé et récitation essentielle | Tronc commun | Sukūn, tanwīn, shadda + premières récitations de Ṣalāh et sourates courtes

F3 | Lecture appliquée et autonomie | Tronc commun | Finalisation de Nour al-Bayân, invocations essentielles, lecture vocalisée autonome

F4 | Immersion Muṣḥaf | Tronc commun | Lecture directe sur le Muṣḥaf + Fātiḥa et sourates 99 à 114 stabilisées

G0 | Gate d’orientation | Obligatoire | Orientation Tilāwah ou Ḥifẓ, avec recommandation académique

T1-T6 | Parcours Tilāwah | Spécialité | Lecture complète et fluide du Coran avec tajwid appliqué progressif

H0-H6 | Parcours Ḥifẓ | Spécialité | Juz 30 puis mémorisation progressive du reste du Coran avec révision structurée

I1 | Cycle d’Itqān | Final Ḥifẓ | Révision complète, stabilité et certification finale


[Tableau extrait 6]

Horizon | Exemple Binta | Qui le fixe | Peut être modifié par

Terminal institutionnel | Lire le Coran sans assistance + maîtrise du corpus Ṣalāh/invocations | Rewayah | Nouvelle version du curriculum uniquement

Parcours | Ḥifẓ complet | Rewayah + choix du tuteur pour un enfant | Réorientation validée

Cycle | Terminer F2 | Curriculum | Jamais individuellement

Unité actuelle | Sukūn et lecture de mots associés | Curriculum + groupe | Enseignant dans la marge prévue

Objectif personnel | Renforcer la lettre ض et stabiliser Al-Falaq | Enseignant | Enseignant selon observation

Maison | Réviser le passage et écouter le modèle avant le prochain cours | App suggère, enseignant ajuste | Enseignant


[Tableau extrait 7]

Le tuteur peut demander une réévaluation ou une réorientation. Il ne peut pas imposer une sourate, un niveau, une vitesse ou un changement de programme parce qu’un autre enfant suit un parcours différent.


[Tableau extrait 8]

Cas | Décision

Débutant réel | Commence F1 depuis le début du cycle.

Intermédiaire | Diagnostic jusqu’au dernier gate stable, puis placement dans le groupe existant le plus proche en amont.

Avancé | Test adaptatif de lecture, tajwid et mémorisation ; placement direct en cycle supérieur si les prérequis sont stables.

Retour après pause courte | Retour au groupe si l’écart reste dans le corridor de cohorte.

Retour après interruption significative | Diagnostic de reprise obligatoire ; l’historique reste acquis, le siège et le niveau opérationnel ne le sont pas.

Aucun groupe compatible | Liste d’attente. Rewayah ne crée pas un groupe sur mesure pour une seule personne et ne force pas un placement mauvais.


[Tableau extrait 9]

Nom officiel proposé : « Cycle Fondamental Rewayah - Lecture, Ṣalāh et premiers repères coraniques ». Le terme commercial « Pack Salat » est abandonné.


[Tableau extrait 10]

Phase | Priorité | Secondaire | Résultat attendu | Durée indicative enfant*

F1 | Alphabet / décodage 100% | Aucune | Mécanismes fondamentaux | 6-10 sem.

F2 | Alphabet / décodage ~70% | Coran + Ṣalāh ~30% | Entrée orale contrôlée dans le Coran | 8-12 sem.

F3 | Lecture appliquée ~70% | Invocations ~30% | Autonomie sur texte vocalisé | 8-12 sem.

F4 | Coran ~70% | Révision ~30% | Immersion Muṣḥaf et corpus initial stabilisé | 12-20 sem.


[Tableau extrait 11]

Gate F1 -> F2 : sur deux séances distinctes, l’élève lit un échantillon inconnu de syllabes et mots vocalisés avec au moins 90 % de décodage correct et au plus deux aides directes de l’enseignant. Les confusions de lettres restent éliminatoires tant qu’elles sont fréquentes.


[Tableau extrait 12]

Épreuve | Critère V1

Lecture vocalisée | Lecture inconnue de 3 à 5 minutes sans assistance. Aucune confusion répétée de lettres ; hésitations compatibles avec une lecture autonome.

Lecture coranique | Passage inconnu du Muṣḥaf avec respect des règles déjà enseignées et sans correction mot à mot permanente.

Mémorisation | Al-Fātiḥa + sourates 99 à 114 stabilisées.

Ṣalāh | Corpus pratique de récitation exécuté dans l’ordre, sans dépendance au texte.

Invocations | Corpus essentiel validé selon une sélection aléatoire.

Autonomie | L’élève sait retrouver son passage, suivre une consigne de révision et revenir avec une préparation observable.


[Tableau extrait 13]

Couche | Contenu principal | Moment dominant | Validation

J0 | Makhārij fondamentaux des lettres, madd naturel, articulation claire | F1-F4 | Aucune substitution récurrente de lettres ; madd naturel stable

J1 | Ghunnah de nūn/mīm mushaddadah, qalqalah de base | F4 / début Tilāwah-Hifẓ | Reconnaissance et application sur passages variés

J2 | Nūn sākinah et tanwīn : iẓhār, idghām, iqlāb, ikhfāʾ | T1-T2 / H0-H2 | Application stable, sans rappel de la règle

J3 | Mīm sākinah, lām, rāʾ, tafkhīm/tarqīq essentiels | T2-T3 / H2-H3 | Application en lecture inconnue et révision

J4 | Madd farʿī : catégories utiles et durées retenues pour Ḥafṣ | T3-T4 / H3-H4 | Durées cohérentes dans plusieurs contextes

J5 | Waqf/ibtidāʾ, hamzat al-waṣl, signes de pause, reprise correcte | T4-T5 / H4-H5 | Arrêts non arbitraires et reprise correcte

J6 | Particularités de Ḥafṣ, saktāt retenues, intégration complète et performance | T5-T6 / H5-H6 | Lecture intégrée, sans rappel de procédure


[Tableau extrait 14]

État visible | Sens | Conséquence

À renforcer | La compétence n’est pas suffisamment fiable pour servir de prérequis. | Répétition ciblée ; pas de sanction.

Acquis | L’élève sait faire, avec quelques erreurs mineures ou une stabilité encore récente. | Le groupe peut continuer ; la compétence reste surveillée.

Stable | La compétence est correcte sur plusieurs contrôles espacés et ne s’effondre pas dans un autre contexte. | Pré-requis validé pour les gates concernés.


[Tableau extrait 15]

Type d’erreur | Exemple de catégorie | Poids

E3 - critique | Substitution de lettre, voyelle erronée, omission/ajout de mot ou erreur qui altère nettement la récitation | Bloquante dans une évaluation avancée

E2 - majeure | Règle déjà enseignée fréquemment manquée, makhraj instable, hésitation nécessitant un prompt | Compte fortement

E1 - mineure | Hésitation brève ou auto-correction rapide sans aide | Tolérée en petite quantité selon le niveau


[Tableau extrait 16]

Pour devenir « Stable », une compétence est observée au moins trois fois sur une période minimale de deux semaines, dont au moins une fois sur un exemple ou passage non préparé. L’app organise les rappels ; l’enseignant ne remplit pas trois formulaires.


[Tableau extrait 17]

Population | Capacité V1 | Durée | Fréquence standard | Remarque

Enfants | 5 maximum | 60 min dont 5 min de pause | 3 séances/semaine | Capacité plus basse autorisée à certains niveaux

Adultes | 6 maximum | 90 min | 3 séances/semaine | Autonomie plus grande ; même standard de sortie


[Tableau extrait 18]

Situation | Règle

4/5 enfants ou 5/6 adultes ont acquis l’unité | Le groupe peut avancer. L’élève restant reçoit du renforcement ciblé.

40 % ou plus du groupe reste à renforcer | Une séance de consolidation commune est déclenchée avant de poursuivre.

Un seul élève bloque | Le groupe ne peut être retardé de plus d’une séance uniquement pour lui.

Écart persistant de 2 unités ou environ 3 semaines | Revue de support et plan de rattrapage.

Écart persistant après environ 4 semaines malgré support | Recommandation de transfert vers groupe plus adapté.

Élève très avancé | Enrichissement individuel ; s’il est stable deux unités en avance, revue de transfert vers groupe supérieur.


[Tableau extrait 19]

Le transfert n’est ni une récompense ni une sanction. C’est un outil de protection du groupe et de l’élève.


[Tableau extrait 20]

Temps | Activité | Ce que l’app fait

0-5 | Accueil, présence, rappel oral court | Présence et contexte automatiquement chargés

5-17 | Leçon commune du jour | Affiche l’objectif, le support et les exemples

17-32 | Passages individuels 1 à 3 | File de récitation, changement automatique de passage

32-37 | Pause | Minuteur discret, aucun rapport

37-47 | Pratique collective / correction de règle | Affiche le même passage à tous ou une activité ciblée

47-57 | Passages individuels 4 et 5 | Même file de récitation

57-60 | Résumé et travail maison | Propose 1 à 3 micro-actions ; enseignant ajuste si besoin


[Tableau extrait 21]

Le travail maison est obligatoire, mais Rewayah ne fixe pas une durée quotidienne rigide. L’académie fixe ce qui doit être préparé ; la famille choisit le moment réaliste.


[Tableau extrait 22]

Public | Règle

Enfant | Orientation Ḥifẓ par défaut si les prérequis sont stables. Le tuteur peut demander Tilāwah. Rewayah peut différer le Ḥifẓ si la rétention ou la lecture n’est pas suffisante.

Adulte | Choix Tilāwah ou Ḥifẓ après présentation du diagnostic, de la charge réaliste et de la recommandation de l’enseignant.

Réorientation | Possible à un gate ou après revue pédagogique. Aucun changement impulsif au milieu d’une unité sans raison académique.


[Tableau extrait 23]

Cycle | Étendue de lecture personnelle | Couche tajwid dominante | Gate

T1 | Juz 1-5 | J0-J1 | Lecture inconnue + stabilité des makhārij fondamentaux

T2 | Juz 6-10 | J2 | Nūn sākinah / tanwīn appliqués

T3 | Juz 11-15 | J3 | Mīm sākinah, rāʾ, lām, tafkhīm/tarqīq

T4 | Juz 16-20 | J4 | Madd farʿī appliqué sans rappel constant

T5 | Juz 21-25 | J5 | Waqf et ibtidāʾ fonctionnels

T6 | Juz 26-30 + reprise aléatoire du Coran entier | J6 + intégration | Examen final de lecture autonome


[Tableau extrait 24]

Flux | Nom app | But

Nouveau | Nouveau | Ajouter une portion réaliste seulement si la révision reste saine.

Récent | À consolider | Revoir les dernières portions encore fragiles.

Ancien | Révision longue | Faire tourner tout le corpus déjà mémorisé afin qu’aucune zone ne disparaisse.


[Tableau extrait 25]

Cycle | Contenu | Sortie

H0 | Compléter Juz 30 à partir du corpus déjà mémorisé (sourates 99-114 acquises dans F4) | Juz 30 stable

H1 | Juz 1-5 | 5 ajzāʾ stabilisés + plan de révision fonctionnel

H2 | Juz 6-10 | 10 ajzāʾ stabilisés

H3 | Juz 11-15 | 15 ajzāʾ stabilisés

H4 | Juz 16-20 | 20 ajzāʾ stabilisés

H5 | Juz 21-25 | 25 ajzāʾ stabilisés

H6 | Juz 26-29 | 30 ajzāʾ mémorisés ; entrée en Itqān

I1 | Révision intégrale, rotations et contrôles aléatoires | Certification Ḥifẓ complet et consolidé


[Tableau extrait 26]

Profil | Départ prudent | Standard installé | Accéléré*

Enfant après H0 | 3-5 lignes par séance | 5-8 lignes par séance | Jusqu’à 1 page par séance

Adulte actif | 2-4 lignes par séance | 4-7 lignes par séance | Selon capacité démontrée


[Tableau extrait 27]

Si le nouveau progresse mais que l’ancien se dégrade, Rewayah réduit d’abord le nouveau. Si la dégradation persiste, le nouveau est suspendu jusqu’à récupération. « Plus mémorisé » n’est pas considéré comme « mieux mémorisé ».


[Tableau extrait 28]

L’enseignant peut | L’enseignant ne peut pas

Ajuster la quantité de nouveau dans la bande du cycle | Sauter un gate obligatoire

Changer exemples et exercices | Modifier seul le standard final du niveau

Suspendre le nouveau pour un élève | Promouvoir un élève parce que le tuteur insiste

Recommander un transfert ou une réorientation | Créer un curriculum parallèle personnel

Décider qu’une compétence doit être renforcée | Certifier un niveau institutionnel sans l’autorité prévue

Utiliser son jugement professionnel et motiver brièvement une exception | Transformer l’app en journal narratif quotidien


[Tableau extrait 29]

Type | But | Décide le passage ? | Charge enseignant

Observation continue | Ajuster et détecter les difficultés | Indirectement, via les compétences | Quasi nulle ; états préremplis

Gate de cycle | Valider les prérequis avant un carrefour | Oui | Évaluation structurée

Majlis Rewayah | Exposition aux pairs, confiance, encouragement, étalonnage | Non | Préparation légère

Certification finale | Attester une sortie majeure | Oui | Jury ou évaluateur autorisé


[Tableau extrait 30]

Jalon | Document | Rareté

Fin du Cycle Fondamental | Attestation Fondations Rewayah | 1 seule fois

Fin T6 | Certificat de lecture autonome du Coran - Ḥafṣ ʿan ʿĀṣim | Majeur

Fin I1 | Certificat Rewayah de Ḥifẓ complet et consolidé | Très majeur


[Tableau extrait 31]

Une absence peut être administrativement justifiée sans être pédagogiquement neutre. La maladie retire la faute, pas le retard d’apprentissage.


[Tableau extrait 32]

État | Effet académique V1

Arrivée >5 min après le début | Retard enregistré. L’élève rejoint sans interrompre le groupe.

Assiduité glissante <90 % | Vigilance et message de prévention.

Assiduité <85 % | Statut académique à risque ; vérification de la progression.

Assiduité <75 % | Revue obligatoire ; le maintien dans le groupe peut être remis en cause.

Maladie / absence justifiée | Pas de faute disciplinaire ; rattrapage ou repositionnement selon l’écart réel.

Pause courte jusqu’à 4 semaines | Retour au groupe si le corridor reste compatible.

Pause 1-3 mois | Mini-diagnostic de reprise.

Pause >3 mois ou abandon | Diagnostic de placement complet ; historique conservé, siège non garanti.


[Tableau extrait 33]

Niveau | Action | Responsable

0 - Comprendre | Contact avec l’élève adulte ou le tuteur, compréhension du problème | Enseignant ou admin selon cas

1 - Rappel | Rappel clair de la règle et de l’effet sur le groupe | Enseignant

2 - Avertissement | Avertissement formel + plan correctif simple sur période courte | Admin

3 - Suspension | Suspension temporaire si perturbation sérieuse ou refus persistant | Admin

4 - Radiation | Fin d’inscription si le comportement rend l’accompagnement impossible | Admin


[Tableau extrait 34]

Rythme | Attendu

Avant chaque cours | Ouvrir la carte séance, voir l’objectif commun et les rares alertes individuelles. Cible : moins d’une minute.

Pendant | Enseigner, corriger, gérer la file de récitation et exercer son jugement pédagogique.

Après | Valider un écran prérempli. Par défaut tout est « Continuer » ; il ne modifie que les exceptions. Cible : moins de 45 secondes pour la séance entière.

Hebdomadaire | Aucun rapport narratif obligatoire. L’app produit le résumé. L’enseignant n’intervient que si une anomalie est signalée.

Mensuel / cycle | Revue courte du groupe si nécessaire, gates planifiés, proposition de transfert ou réorientation.

Toujours | Respecter le curriculum, tout en gardant une marge sur quantité, exemples, rythme individuel et suspension du nouveau.


[Tableau extrait 35]

Principe anti-burnout : aucune donnée ne doit être saisie manuellement si elle peut être déduite de la présence, du curriculum, de la file de récitation, du contenu affiché ou des événements système.


[Tableau extrait 36]

Automatique | Humain nécessaire

Présence, durée, retard, reconnexion | Décision sur cas ambigu

Objectif du groupe et compétence du jour | Qualité réelle de la performance

Passage affiché et ordre de récitation | Correction pédagogique

Suggestion de travail maison | Ajustement ponctuel

Détection d’écart de cohorte | Transfert ou plan de support

Alertes d’assiduité | Comprendre la cause et décider

Pré-remplissage du rapport | Changer seulement les exceptions

Résumé tuteur | Message personnalisé si nécessaire

KPI et tendances | Sanction, promotion, certification


[Tableau extrait 37]

Niveau | KPI calculés | Qui les voit

Élève | Étape actuelle, prochain gate, statut de préparation | Élève / tuteur

Tuteur | Assiduité, cycle, prérequis manquants, conseil, prochaine décision | Tuteur

Groupe | Santé de cohorte, % dans le corridor, progression du cycle, absentéisme | Enseignant + admin

Enseignant | Ponctualité, séances assurées, anomalies de rapports, contrôle qualité | Enseignant + admin

Académie | Progression, blocages, transferts, abandons, certifications, groupes à risque | Admin / contrôleur


[Tableau extrait 38]

Moment | Binta | Tuteur | Système

20 sept. | Crée son profil avec aide | Donne disponibilités, accepte règles | Pré-diagnostic

Semaine 1 | Diagnostic oral/lecture | Observe le résultat | Place Binta en F1 ou autre cycle

Début | 3 x 60 min/semaine | Assure ponctualité et révision à la maison | Affiche parcours complet + étape actuelle

F2 | Commence Fātiḥa et sourates courtes par talaqqī | Aide à répéter, sans changer le programme | Micro-actions maison

Fin F4 | Passe le gate fondamental | Reçoit bilan clair | Propose Hifẓ par défaut + alternative Tilāwah

Ḥifẓ | Nouveau + récent + ancien | Protège la régularité | Ajuste la charge et surveille la rétention

Écart | Peut être renforcée ou transférée | Informé avec motif | Ne bloque pas le groupe entier

Fin | 30 ajzāʾ mémorisés puis Itqān | Soutient la révision | Certification seulement après consolidation


[Tableau extrait 39]

Moment | Ce que Munir fait | Ce qu’il ne fait pas

Avant sa journée | Consulte les groupes et alertes utiles | Ne prépare pas un curriculum complet

Avant séance | Lit l’objectif, le passage, les élèves à surveiller | Ne remplit pas une feuille de présence

Pendant | Enseigne et décide | Ne navigue pas dans trois menus

Après | Valide le préremplissage et change les exceptions | N’écrit pas cinq commentaires

Fin de semaine | Rien si tout va bien | Pas de rapport narratif hebdomadaire

Gate | Évalue selon grille standard | Ne change pas le seuil selon le parent

Problème | Suspend, renforce ou propose transfert | Ne porte pas seul les décisions disciplinaires finales


[Tableau extrait 40]

Cas | Règle V1

Connexion faible | La continuité audio prime ; les preuves de présence tiennent compte des reconnexions.

Changement d’enseignant | Le programme et l’état de progression restent ; le nouvel enseignant reprend sans reconstruire l’historique.

Enseignant absent | Astreinte/remplacement selon l’architecture Rewayah ; compensation commerciale séparée.

Difficulté de parole ou handicap spécialisé | Rewayah V1 ne revendique pas une expertise spécialisée. Accessibilité UI standard et orientation honnête si le besoin dépasse les compétences disponibles.

Élève très rapide | Accélération dans le plan individuel et transfert si l’écart devient durable.

Élève très lent | Renforcement et transfert éventuel ; le groupe n’est pas immobilisé indéfiniment.

Parent conflictuel | Réponse basée sur les règles publiées, possibilité de recours, mais pas de curriculum à la carte.

Réinscription externe pour certification | Hors V1 ; possible plus tard via diagnostic renforcé et règles anti-certification opportuniste.


[Tableau extrait 41]

Objet cible | Besoin

curriculum_versions | Version publiée, dates d’effet, statut brouillon/publié/retiré

curriculum_cycles | F1-F4, T1-T6, H0-H6, I1

curriculum_units | Unités ordonnées d’un cycle, objectif et contenu

competency_prerequisites | Dépendances entre compétences

learning_plans | Parcours personnel, orientation, objectif actuel

student_curriculum_state | Cycle/unité, statut, corridor

group_curriculum_state | Leçon commune, cadence et unité du groupe

progression_events | Gate, suspension, transfert, orientation, reprise

home_tasks | Micro-actions proposées ou ajustées

certifications | Attestations et certificats majeurs

curriculum_admin | Interface versionnée de contrôle sans code


[Tableau extrait 42]

Point | Pourquoi ce n’est pas encore figé | Action

Corpus Ṣalāh et invocations | Les formulations et catégories juridiques doivent être scientifiquement validées et harmonisées avec PISI. | Admin + enseignant habilité valident la liste finale et la version source.

Mapping Nour al-Bayân | Les éditions diffèrent par pagination et parfois présentation. Inventer des pages serait une erreur. | Choisir l’édition numérique exacte, puis mapper chaque unité F1-F3 à ses pages/chapitres dans `curriculum_units`.


[Tableau extrait 43]

But final : que chacun puisse se dire « c’est exigeant, mais c’est logique et faisable ». Ni burnout, ni laisser-aller, ni arbitraire.


---

# ANNEXE 24 - Teaching Core V1 - Groupes, bibliothèque, Coran, classe LiveKit et outils pédagogiques

_Source : `REWAYAH_TEACHING_CORE_MULTI_AGENTS_V1(2).docx`. Extraction du document Word : paragraphes et tableaux conservés en texte ; les images et la mise en page originale ne sont pas incorporées._


# REWAYAH ACADEMY
TEACHING CORE V1

Groupes - Bibliothèque - Coran - Classe LiveKit - Outils pédagogiques - Observation

Spécification complète + stratégie d'implémentation parallèle multi-agents + protocole immuable d'intégration

# 0. Résumé exécutif

Ce document fige le noyau pédagogique de Rewayah. Il transforme la Bibliothèque, le Groupe et la Classe Live en un système unique et cohérent. Le Groupe est l'espace pédagogique permanent. La Classe Live est un état temporaire du Groupe. La Bibliothèque est disponible hors classe et dans la classe sans interrompre la connexion. Le Coran reste une source canonique intacte, rendue de plusieurs façons selon le contexte. Les outils de cours s'ajoutent comme des couches temporaires ou persistantes sans modifier la source.

# 1. Autorité, sources et règles de réconciliation

Cette spécification consolide les documents existants et les décisions prises dans le cadrage actuel. Les agents ne doivent pas inventer de comportement lorsqu'un point est déjà défini.

## 1.1 Décisions nouvelles qui remplacent ou précisent l'ancien comportement

## 1.2 Contradictions neutralisées

Ancien rendu Coran pré-rendu vs Coran structuré : la source de vérité reste structurée. La fidélité de page est assurée par un moteur de layout ou des assets de layout dédiés. Un PDF ou raster ne devient pas la source canonique interactive.

Règle ancienne « rien ne se ferme tout seul » : elle reste vraie pour les écrans ordinaires. L'observation tuteur est une exception de sécurité/produit bornée serveur, donc elle se termine automatiquement à la limite autorisée.

Photo enseignant anciennement non tranchée : désormais obligatoire et visible dans les groupes autorisés.

Politique d'enregistrement audio contradictoire dans les anciens documents : ce chantier ne la redéfinit pas. Les agents doivent consommer la politique existante et ne pas créer une nouvelle règle.

# 2. Problème actuel à corriger

Le rendu actuel du Coran montre le problème à éviter : mots distribués selon la surface disponible, absence de géométrie de page familière, grande perte de repères visuels, hiérarchie insuffisante et boutons de navigation qui prennent une place disproportionnée.

État actuel à remplacer : le contenu ne respecte pas une page de Mushaf exploitable pédagogiquement.

# 3. Invariants produit non négociables

Contenu pédagogique primaire > contrôle pédagogique > chrome UI > configuration secondaire.

La source d'un support est immuable. Annotations, marqueurs, focus et révisions sont des couches séparées.

La classe ne doit jamais obliger l'enseignant à quitter la session pour ouvrir un support, consulter un élève ou signaler un problème.

LiveKit transporte le temps réel. Supabase reste la source durable. Flutter rend les contenus localement.

Naviguer dans Rewayah ne doit pas, à lui seul, couper la classe Live active.

Aucune donnée privée famille ne doit être cachée seulement par Flutter : elle ne doit pas être délivrée à l'enseignant.

Une action réussie qui est visuellement évidente ne déclenche pas de notification de confirmation.

Les erreurs et blocages doivent être explicites. Les succès évidents restent silencieux.

Le professeur enseigne. L'app absorbe la bureaucratie et les calculs.

Toutes les heures persistées sont en UTC. Les récurrences utilisent un fuseau IANA. Les interfaces affichent les conversions utiles.

Une fonctionnalité existe une seule fois. Les raccourcis pointent vers la route ou le service canonique.

# 4. Le Groupe : espace pédagogique permanent

Le Groupe existe avant, pendant et après le cours. Seuls les élèves inscrits, le tuteur légal d'un élève mineur, l'enseignant assigné et les rôles administratifs autorisés y accèdent. Le Contrôleur n'obtient pas un espace Groupe complet par défaut : il accède aux séances qu'il doit observer.

## 4.1 Les quatre niveaux d'interface

MES GROUPES
    |
    v
CARTE DU GROUPE
    | tap
    v
ESPACE DU GROUPE
    | Rejoindre
    v
CLASSE LIVE

## 4.2 Carte du Groupe

La carte doit être identifiable en un coup d'œil sans devenir un mini-dashboard. Toute la carte ouvre l'espace Groupe. Le bouton Rejoindre n'apparaît que lorsque la fenêtre d'accès est ouverte.

┌──────────────────────────────────────────┐
│ ▌                              4 / 5     │
│  [PHOTO]  Groupe Al-Fatiha               │
│           Sayyid Youssouf                │
│           Lecture du Coran · Niveau 2    │
│                                          │
│  Prochain cours                          │
│  Lundi 21 septembre · 18:00              │
│  Durée 1 h 30 · Cours dans 3 h 28       │
│                              [Rejoindre] │
└──────────────────────────────────────────┘

## 4.3 Espace Groupe - élève / tuteur

Pas de sidebar interne. Pas de cinq onglets. Une page verticale minimaliste et pure. L'ordre est stable.

Carte Session dominante.

Bloc « Avant le prochain cours » avec au maximum trois actions.

Bibliothèque du groupe avec couvertures reconnaissables.

Progression ou résumé utile uniquement si le rôle en a besoin.

Groupe Al-Fatiha
Sayyid Youssouf

[ SESSION ]
Lundi 21 septembre
Votre heure        18:00 Riyad
Chez Sayyid        15:00 Conakry
Durée              1 h 30
Cours dans         3 h 28
[ Rejoindre ]
💻 Tablette ou ordinateur conseillé

[ AVANT LE PROCHAIN COURS ]
maximum 3 actions

[ BIBLIOTHÈQUE ]
[Coran] [Qaida] [Invocations]  Voir tout

## 4.4 Espace Groupe - enseignant

Même identité de groupe et même Session Card.

Accès à la liste pédagogique des élèves assignés.

Accès direct à la Bibliothèque et aux supports récents du groupe.

Accès au travail avant prochain cours, progression de groupe et anomalies utiles.

« Reprendre le cours » n'est pas une section permanente : c'est une action contextuelle qui restaure la dernière position de groupe sur le support.

## 4.5 Espace Groupe - Admin

L'Admin a un besoin de gestion plus dense. Il utilise une navigation locale de l'objet Groupe :

Aperçu | Membres | Planning | Pédagogie | Ressources | Réglages

Réglages > Classe & observation : politiques tuteur, fenêtre de connexion, politiques live liées au groupe.

Ressources : supports autorisés/épinglés pour le groupe.

Planning : fuseau de référence, règles récurrentes, prochaines occurrences.

Aperçu : état du groupe, enseignant, capacité, prochaine séance, alertes.

## 4.6 Personnalisation du Groupe

Nom familier.

Programme/cycle/niveau.

Enseignant assigné.

Planning et fuseau de référence.

Ressources autorisées ou mises en avant.

Politique d'observation tuteur.

Couleur d'identification parmi une large palette contrôlée, cible 32 à 40 teintes/variantes accessibles.

Pas de thèmes personnalisés, fonds arbitraires, layouts différents ou sélecteur hex libre. La personnalisation sert à reconnaître le groupe, pas à créer 100 applications différentes.

# 5. Temps, countdown, accès et présence

## 5.1 Machine d'état UX

## 5.2 Présence automatique

Rejoindre à 17:42 pour un cours à 18:00 doit prouver que l'élève était prêt, mais ne doit pas lui créditer 18 minutes de présence académique.

session_participants / événements servent à reconstruire les intervalles réels de connexion.

attendance_records représente le résultat académique final.

Un reconnect court, un passage background ou un changement de réseau ne crée pas une nouvelle absence.

Le timer affiché est dérivé du serveur et de l'occurrence de session, pas de l'horloge locale seule.

## 5.3 Fuseaux horaires et DST

Chaque Groupe possède un fuseau de référence IANA. Exemple : Europe/Paris.

Chaque utilisateur possède son fuseau IANA.

L'élève voit son heure + l'heure de l'enseignant lorsque les fuseaux diffèrent.

L'enseignant voit son heure + l'heure de référence du groupe.

Le voyage d'un enseignant ne déplace jamais automatiquement l'horaire institutionnel du groupe.

Le backend matérialise chaque occurrence en UTC.

Les changements été/hiver sont calculés à partir des zones IANA, jamais via UTC+1/UTC+2 hardcodé.

Alerte anticipée lorsqu'une conversion future change. Conserver l'exigence historique d'anticipation jusqu'à 30 jours si l'occurrence est affectée, puis rappel visible proche de l'échéance, notamment J-7/J-1.

Admin > Opérations > Planning affiche les groupes affectés par une transition de fuseau.

# 6. Bibliothèque universelle

La Bibliothèque est un ensemble de supports accessibles hors classe. Elle doit donner une identité visuelle claire à chaque ressource grâce à des couvertures reconnaissables, des titres humains et une organisation simple. En classe, la même bibliothèque s'ouvre comme un panneau sans quitter LiveKit.

## 6.1 Expérience hors classe

Continuer : dernière ressource et dernière position.

Pour ce groupe : ressources épinglées ou assignées au groupe.

Récents.

Tous les supports avec filtres simples.

Recherche par titre, type, niveau, sourate/page lorsqu'applicable.

Couvertures persistantes et distinctes. Pas une grille d'icônes génériques identiques.

État offline clair : téléchargé, disponible en cache, à télécharger.

## 6.2 Expérience dans la classe

Le bouton Bibliothèque appartient au Teaching Dock.

Sur desktop/tablette : panneau latéral ou sheet contextuelle.

Sur mobile : sheet quasi plein écran.

Choisir une ressource remplace le support actif. La room LiveKit reste connectée.

Ordre de découverte : Récents > Ce groupe > Tous les supports > Recherche.

## 6.3 Types de ressources

## 6.4 Manifeste de ressource

LibraryResource
- id
- title
- short_title
- cover_asset
- resource_type
- edition
- language
- category
- level_scope
- access_policy
- offline_policy
- current_version_id
- capabilities:
    pageable
    searchable
    zoomable
    selectable
    focusable
    annotatable
    assignable
    presentable_in_class
    supports_stylus
    supports_offline

## 6.5 Téléchargement PDF

La source native interactive reste optimisée pour Rewayah.

Chaque version publiée peut avoir un download_asset PDF immuable.

Pour une ressource structurée/vectorielle, le PDF est généré une seule fois à la publication, puis réutilisé.

Pour un PDF importé, l'original est conservé comme artefact de téléchargement et Rewayah génère ses métadonnées/couverture/index.

Pour le Coran, la source canonique reste structurée. Le PDF téléchargeable correspond à l'édition retenue et à ses droits de distribution.

Le bouton utilisateur est « Enregistrer une copie » ou « Télécharger en PDF » et passe par le sélecteur de fichiers du système. Ne jamais bricoler un chemin /sdcard.

# 7. Quran Engine - rendu académique central

Le Coran ne peut pas être une simple zone Text Flutter qui wrappe les mots selon la largeur. L'utilisateur doit retrouver les repères visuels du Mushaf de Médine Hafs retenu par Rewayah.

## 7.1 Modes de rendu

## 7.2 Fidélité page

Même limites de page que l'édition standard retenue.

Même ordre de lignes et repères de sourate/ayah utiles.

Moteur explicite pageSide/spread pour respecter le côté gauche/droite dans une double page.

Sur téléphone : une page à la fois, ajustée sans déformer.

Sur tablette/desktop : double page lorsque la largeur le permet.

Golden tests sur un ensemble de pages de référence : début, milieu, changement de sourate, pages denses, dernière page.

Si les données disponibles ne permettent pas une fidélité suffisante, l'agent doit STOP et documenter le manque. Il ne doit pas improviser une composition.

## 7.3 Zoom et mode verset

Le zoom ne doit pas être un simple Transform.scale qui crée un overflow.

Le mode verset est reflowable et responsive : le renderer recalcule largeur, taille, hauteur et lignes.

L'élève peut garder un zoom local différent sans casser la position pédagogique partagée.

L'enseignant peut explicitement passer tout le groupe en affichage agrandi/focus.

## 7.4 Navigation Quran

Page précédente/suivante.

Sourate.

Juz.

Ayah.

Recherche rapide.

Dernière position personnelle.

Position de groupe pour « Reprendre le cours ».

# 8. Teaching Dock et outils de cours

Les outils fréquents sont regroupés dans un petit dock flottant, visible mais non distractif. Il ne doit jamais couvrir le texte actif. Position possible bas/gauche/droite, mémorisée localement.

[ Bibliothèque ] [ Focus ] [ Marquer ] [ Masquer ] [ Stylet ] [ Pointeur ] [ Révision ]

## 8.1 Interactions

## 8.2 Libellés pédagogiques simples

## 8.3 Annotations sans dupliquer la source

RESSOURCE ORIGINALE IMMUTABLE
        +
ANNOTATION LAYER
        +
SEMANTIC MARKERS
        =
RENDU À L'ÉCRAN

Un trait de stylet est stocké comme données vectorielles normalisées, jamais comme nouvelle copie du support.

Pendant le geste : paquets realtime légers. À la fin du trait : version compacte et stable.

Une annotation peut être temporaire, limitée à la séance ou enregistrée.

Les marqueurs « À revoir / À renforcer » sont des métadonnées de range, pas des dessins.

Sur mode Mushaf fixe, annotation libre possible. Sur mode verset reflowable, privilégier des ancrages sémantiques au mot/ayah pour éviter le décalage.

## 8.4 Stylet

Détecter PointerDeviceKind.stylus lorsque disponible.

Stylet = encre, doigt = pan/zoom par défaut.

Supporter pression/inclinaison uniquement si le matériel les fournit, sans rendre ces données obligatoires.

Toolbar courte : stylet, surligner, gomme, annuler, plus.

Pas de palette Photoshop. Couleurs sémantiques contrôlées.

# 9. Classe Live - layout et continuité

## 9.1 Principe de composition

Quand un support est actif, le support domine et la vidéo devient secondaire. Quand aucun support n'est présenté, la vidéo peut reprendre plus d'espace.

Desktop / tablette
┌─────────────────────────────────────────────────────────┐
│ Groupe Al-Fatiha · Sayyid Youssouf        Reste 47 min │
├──────────────┬──────────────────────────────────────────┤
│ ÉLÈVES       │                                          │
│ ● Amina      │            SUPPORT ACTIF                 │
│ ● Ilyas      │                                          │
│ ● Mariam     │        Quran / livre / leçon             │
│              │                                          │
│              │       [ Teaching Dock flottant ]         │
├──────────────┴──────────────────────────────────────────┤
│ 🎤  📹              état réseau                Quitter  │
└─────────────────────────────────────────────────────────┘

## 9.2 Mobile

Support plein écran ou quasi plein écran.

Roster en sheet/panneau, résumé par bouton du type « 4/4 ».

Teaching Dock compact.

Vidéo enseignant/élève en vignette selon contexte.

Aucune toolbar ne couvre le Coran.

## 9.3 Micro et caméra

Micro enseignant OFF à l'entrée, activation volontaire.

Caméra enseignant OFF à l'entrée, activation volontaire.

L'enseignant utilise ensuite le micro normal pour parler librement. Ne pas coder une commande dédiée pour chaque interaction humaine.

Micro élève OFF à l'entrée.

Caméra élève affichée uniquement si la politique de profil l'autorise.

Aucune commande vocale logicielle n'est à implémenter.

## 9.4 Session persistante pendant la navigation

Le contrôleur de room/session est au niveau applicatif, pas attaché au widget de la page Classe.

Retourner au Groupe, à l'Accueil ou ouvrir la Bibliothèque ne coupe pas volontairement LiveKit.

Afficher une barre compacte « Cours en cours » avec retour instantané.

Si l'OS suspend réellement le processus, appliquer la machine de reconnexion existante. Ne pas promettre une connexion impossible lorsque la plateforme tue le réseau.

## 9.5 Pré-cours et post-cours

# 10. Roster enseignant et confidentialité anti-concurrence

L'enseignant doit connaître très bien l'élève pédagogiquement et très peu la famille personnellement. C'est le principe de protection : connaissance pédagogique forte, connaissance privée minimale.

TeacherStudentProjection
- first_name
- academy_id
- level
- curriculum_path
- current_unit
- active_goals
- last_lesson
- resume_points
- recent_attendance
- current_assignments
- authorized_pedagogical_notes
- live_status

Ne jamais envoyer à cette projection :

Téléphone.

Email.

Adresse.

Identité complète des tuteurs.

Coordonnées de la famille.

Paiements.

Adresse précise / géolocalisation.

Identifiants privés d'appareil.

## 10.1 Fiche pédagogique de séance

Amina B.
RA-AB0012

Niveau
Décodage consolidé

Objectif actuel
Lecture fluide sans assistance

Dernière séance
Page 31

À reprendre
Confusion ص / س

Présence récente
8 / 9 cours

Travail actuel
Pages 29-32

[ Rappel discret ] [ Choisir pour réciter ] [ Noter ] [ Signaler un besoin ]

## 10.2 Rappel discret

Action ciblée sur un élève.

Vibration brève + son doux si autorisé + impulsion visuelle.

Texte simple : « Le professeur vous appelle ».

Pas de micro ouvert à distance.

Pas de boucle de notifications « envoyé / revenu / confirmé ».

L'action est silencieusement considérée réussie si le transport l'accepte. Un message n'apparaît que si l'envoi échoue.

Cooldown court pour éviter le spam.

Journaliser le fait technique si nécessaire, sans le transformer automatiquement en sanction.

## 10.3 File de récitation

Élève actif visible.

Liste courte des suivants.

Changer d'élève ne change ni la page, ni le focus, ni le stylet, ni le support.

Le professeur peut simplement parler au micro pour corriger, appeler ou guider l'élève.

# 11. Tuteur, Admin et Contrôleur dans la classe

## 11.1 Tuteur observateur

L'Admin peut choisir pour chaque groupe : hériter de la politique Académie, personnaliser ou désactiver. Le modèle doit supporter max_visits_per_session et max_total_observation_seconds. Un plafond par visite peut être ajouté si nécessaire sans contourner le plafond total.

## 11.2 Vue tuteur pendant la visite

Support partagé.

Enseignant.

Son propre enfant si le média est autorisé.

Aucun roster complet.

Aucune fiche d'un autre élève.

Aucun micro, caméra ou outil pédagogique.

Compte à rebours discret de son budget restant.

## 11.3 Annonce

L'enseignant voit « Tuteur d'Amina observe » puis un petit indicateur avec temps restant.

L'enfant concerné peut recevoir un indicateur discret.

Les autres élèves n'ont pas besoin d'être interrompus.

Pas de notification de sortie.

## 11.4 Enforcement serveur

Vérifier lien tuteur-enfant, session active, groupe, policy et quota avant token.

Le client ne peut pas prolonger sa visite en modifiant un timer.

À la limite, sortie client + révocation/expulsion serveur si nécessaire.

Chaque intervalle est journalisé avec entered_at, left_at, duration_seconds, visit_number et policy_version.

## 11.5 Admin

Admin autorisé peut accéder à n'importe quel groupe sans être membre.

Le mode est choisi avant l'entrée.

L'incognito est invisible aux participants mais jamais invisible à l'audit.

Le mode visible utilise un nom institutionnel clair, par exemple « Administration Rewayah ».

## 11.6 Contrôleur

Incognito uniquement.

Aucun micro, aucune caméra, aucune publication data.

Ne figure pas dans la liste participants visible.

Chaque visite est auditée avec identité, session, entrée, sortie et durée.

Ne pas lui donner le choix d'un mode visible dans ce chantier.

# 12. Feedback enseignant et signalements

## 12.1 Micro-feedback sur le cours

Le feedback doit être occasionnel, rapide et non anxiogène. Il ne s'affiche pas après chaque séance. Il doit aussi être dynamique et variable: afficher différentes questions pour avoir différents volets. La même question peut revenir après mais après avoir afficher les autres d’abord.

Comment était le cours aujourd'hui ?

😕        🙂        😀
Difficile  Bien     Très bien

Un tap, terminé.

Échantillonnage configurable, pas systématique.

Pas de commentaire obligatoire.

Pas de leaderboard public.

L'enseignant ne voit pas « tel élève m'a mis telle note ».

Le professeur peut voir une tendance agrégée seulement après un seuil minimum d'échantillons.

Les privilèges de fin d'année utilisent un ensemble de signaux. Le feedback élève/tuteur n'est qu'un signal faible parmi qualité, ponctualité, fiabilité, obligations et résultats de contrôle.

## 12.2 Signalement structuré

Depuis la fiche élève : Problème pédagogique, présence, technique, changement, autre.

Le contexte de session/groupe/élève/enseignant est prérempli.

L'Admin reçoit l'objet structuré, sans que le professeur retape les identifiants.

Séparer internal_details et family_summary.

Admin peut transmettre en un clic au tuteur pour un mineur ou à l'élève adulte.

Une note interne ne doit jamais partir automatiquement à la famille.

# 13. Contrats fonctionnels cibles

Ces noms sont des contrats cibles. Agent 0 doit d'abord mapper les objets existants. Aucune table ou migration ne doit être créée en doublon si un équivalent existe.

## 13.1 SharedContentState

SharedContentState
- session_id
- resource_id
- resource_version_id
- content_position
- content_range
- display_mode: page | verse | focus
- hidden_ranges[]
- semantic_markers[]
- group_resume_position
- revision
- updated_by
- updated_at

L'état durable minimal nécessaire à une reconnexion est persisté côté backend. Les mouvements éphémères du pointeur ou du stylet en cours de geste restent realtime.

## 13.2 LearningAssignment

LearningAssignment
- group_id
- student_id nullable
- resource_id
- resource_version_id
- content_range
- purpose: learn | review | reinforce | maintain | assessment
- instructions
- starts_at
- due_at nullable
- created_by
- status

# 14. Responsive, Interface guidée et accessibilité

## 14.1 Interface guidée

Grandes cibles tactiles.

Chrome réduit.

Navigation minimale.

Suivi automatique du contenu présenté.

Feedback visuel/audio utile.

Moins de texte et plus d'actions directes.

Peut être utilisée par un enfant, une personne âgée ou toute personne qui en bénéficie.

Ne jamais l'appeler « mode enfant » dans l'UI produit.

## 14.2 Responsive

## 14.3 Message appareil conseillé

Dans la Session Card, afficher discrètement : « Tablette ou ordinateur conseillé pour le cours. Le téléphone reste pris en charge. » Pas de popup, pas de blocage, pas de jugement sur l'appareil.

# 15. Critères de qualité et non-régression

Aucun support ne doit être dupliqué pour une annotation.

Aucune classe ne doit recréer un système WebRTC parallèle à LiveKit.

Aucune page Groupe ne doit inventer une deuxième bibliothèque.

Aucune vue enseignant ne reçoit de coordonnées famille.

Aucune visite tuteur ne dépasse la politique serveur.

Aucun Admin/Contrôleur incognito n'apparaît chez les participants.

Aucun participant visible ne peut obtenir des capacités supérieures à son token/permission serveur.

Le Coran est lisible sur téléphone, tablette et desktop, en page standard et en mode verset.

La page Mushaf conserve ses repères de layout.

Le stylet n'altère jamais la source.

La session reste cohérente après reconnect/background.

Le countdown et les heures sont corrects autour d'un changement DST.

L'entrée à T-20 ne fausse pas la présence académique.

La Bibliothèque peut s'ouvrir en classe sans couper la room.

Le feedback enseignant est anonyme/agrégé selon la politique et ne devient pas un classement public.

# 16. Stratégie multi-agents - exécution parallèle pendant l'Admin

## 16.1 Isolation Git obligatoire

Ne pas lancer plusieurs agents dans le même dossier de travail.

Utiliser des worktrees Git ou des clones de travail séparés.

L'agent Admin conserve son worktree actuel.

Agent 0 enregistre TEACHING_BASELINE_SHA à partir du dernier commit stable exploitable. Il ne reset/stash jamais le worktree Admin.

Chaque agent crée sa branche depuis TEACHING_BASELINE_SHA dans son propre worktree.

Quand l'Admin sera terminé, Agent Z créera la branche d'intégration depuis le TARGET_SHA le plus récent incluant l'Admin finalisé, puis intégrera les branches Teaching Core.

## 16.2 Fichiers partagés gelés

Routeur global.

Theme global et design tokens.

Auth core et guards globaux.

Supabase client global.

Modèles DB partagés existants.

Migrations existantes et nouvelle numérotation de migrations.

LiveKit core/provider existant.

pubspec.yaml, sauf décision Agent Z.

Fichiers actuellement modifiés/réservés par le chantier Admin.

Les agents de feature peuvent lire ces fichiers. Ils ne peuvent pas les modifier. Un besoin commun devient un CONTRACT_REQUEST_<AGENT>.md.

## 16.3 Matrice d'ownership

## 16.4 Règles de collaboration

Tous lisent les documents produits par Agent 0.

Un fichier n'a qu'un propriétaire pendant la phase parallèle.

Aucun agent ne merge vers main.

Aucun agent ne rebase sur une autre branche feature.

Aucun agent ne crée une migration partagée.

Aucun agent ne modifie pubspec.yaml sans passage par Agent Z.

Chaque feature expose son API publique minimale et compile avec mocks/adapters locaux.

Une dépendance manquante produit CONTRACT_REQUEST_X.md, pas un contournement.

Chaque agent produit un rapport de fin avec fichiers modifiés, tests, limites et demandes d'intégration.

Le merge final se fait uniquement par Agent Z après un contrôle pré-merge.

# PROMPT 0 - Agent coordinateur : gel, mapping et ownership

IMPORTANT - PROTOCOLE COMMUN À TOUS LES AGENTS
Tu travailles sur le Teaching Core de Rewayah pendant qu'un autre chantier Admin peut encore être en cours.
Tu n'utilises jamais le worktree de l'Admin.
Tu pars de TEACHING_BASELINE_SHA dans ton propre worktree/branche.
Tu lis TEACHING_CORE_BASELINE.md, TEACHING_CORE_FILE_OWNERSHIP.md, TEACHING_CORE_CONTRACTS.md et TEACHING_CORE_DECISIONS.md.
Tout fichier hors de ton ownership est READ-ONLY.
Routeur global, thème global, auth core, LiveKit core/provider, pubspec.yaml, migrations partagées et fichiers réservés par l'Admin sont READ-ONLY.
Si un contrat manque, crée CONTRACT_REQUEST_<AGENT>.md. Ne modifie pas le core pour te débloquer.
Ne recrée jamais une fonction déjà existante.
Ne change pas une décision métier pour simplifier ton code.

MISSION : PRÉPARER LE CHANTIER TEACHING CORE POUR UNE EXÉCUTION PARALLÈLE SANS COLLISION.

RÔLE :
Tu es Agent 0. Tu ne construis aucun écran métier.

1. Inspecte le dépôt réel et git status.
2. Identifie le worktree/branche actuellement utilisé par le chantier Admin et marque tous ses fichiers modifiés/réservés comme PROTECTED.
3. Ne stash, reset, checkout ou modifie jamais le worktree Admin.
4. Choisis le dernier commit stable exploitable comme TEACHING_BASELINE_SHA.
5. Lis les documents de référence Rewayah.
6. Cartographie ce qui existe déjà :
   - groupes
   - sessions
   - planning
   - bibliothèque
   - Quran
   - LiveKit
   - présence
   - teacher roster
   - tuteur live
   - contrôleur
   - annotations
   - cache/offline
7. Détecte les doublons avant toute nouvelle feature.

Décisions obligatoires :
- Groupe = espace permanent, Classe Live = état temporaire du Groupe.
- Bibliothèque accessible hors classe et dans la classe.
- Sayyid/Sayyida comme titres enseignants.
- photo enseignant publique obligatoire.
- Interface guidée remplace l'appellation mode enfant.
- pas de commandes vocales.
- join window par défaut 20 minutes, configurable.
- tuteur : observation automatique, bornée serveur, 1 visite et 120 s totales par défaut.
- Admin : incognito ou visible.
- Contrôleur : incognito uniquement.
- source Coran canonique structurée et immuable.
- PDF téléchargeable = artefact dérivé de version.

PRODUIS :
- TEACHING_CORE_BASELINE.md
- TEACHING_CORE_FILE_OWNERSHIP.md
- TEACHING_CORE_CONTRACTS.md
- TEACHING_CORE_DECISIONS.md
- TEACHING_CORE_EXISTING_MAPPING.md
- TEACHING_CORE_PROTECTED_FILES.md

TEACHING_CORE_FILE_OWNERSHIP.md doit attribuer chaque fichier modifiable à un seul agent.
Les chemins exacts doivent être ceux du dépôt réel.

TEACHING_CORE_CONTRACTS.md doit décrire sans implémenter :
GroupSummaryVM, GroupHomeVM, SessionClockVM, LibraryResource, ResourceVersion, DownloadAsset,
ContentPosition, ContentRange, SharedContentState, AnnotationLayer, LearningAssignment,
TeacherStudentProjection, GuardianObservationPolicy, GuardianSessionVisit, SessionFeedback, StudentConcern.

STOP :
Les agents A-H/Q ne démarrent pas tant que les documents ci-dessus n'existent pas et que l'ownership n'a aucun chevauchement.

# PROMPT A - Group Space, cartes, Session Card et fuseaux

IMPORTANT - PROTOCOLE COMMUN À TOUS LES AGENTS
Tu travailles sur le Teaching Core de Rewayah pendant qu'un autre chantier Admin peut encore être en cours.
Tu n'utilises jamais le worktree de l'Admin.
Tu pars de TEACHING_BASELINE_SHA dans ton propre worktree/branche.
Tu lis TEACHING_CORE_BASELINE.md, TEACHING_CORE_FILE_OWNERSHIP.md, TEACHING_CORE_CONTRACTS.md et TEACHING_CORE_DECISIONS.md.
Tout fichier hors de ton ownership est READ-ONLY.
Routeur global, thème global, auth core, LiveKit core/provider, pubspec.yaml, migrations partagées et fichiers réservés par l'Admin sont READ-ONLY.
Si un contrat manque, crée CONTRACT_REQUEST_<AGENT>.md. Ne modifie pas le core pour te débloquer.
Ne recrée jamais une fonction déjà existante.
Ne change pas une décision métier pour simplifier ton code.

MISSION : IMPLÉMENTER EXCLUSIVEMENT L'EXPÉRIENCE GROUPE ET LA PRÉSENTATION DU TEMPS.

OWNERSHIP :
Uniquement les fichiers attribués à Agent A.

À implémenter :
1. Carte Groupe dans Mes groupes :
   - couleur contrôlée
   - nom humain
   - photo enseignant
   - Sayyid/Sayyida
   - cours/niveau
   - X/capacité réelle
   - prochaine séance
   - durée
   - countdown
   - CTA Rejoindre uniquement lorsque join_opens_at est ouvert.
2. Espace Groupe élève/tuteur :
   - Session dominante
   - Avant le prochain cours
   - slot Bibliothèque via contrat, pas implémentation locale
   - progression secondaire.
3. Espace Groupe enseignant :
   - Session
   - accès roster via contrat
   - Bibliothèque via contrat
   - progression/anomalies via contrat.
4. Horloges :
   - heure utilisateur
   - heure enseignant ou heure Groupe lorsque utile
   - labels de ville/zone lisibles
   - jamais UTC+1 hardcodé.
5. DST :
   - afficher une notice fournie par SessionClockVM
   - ne calcule pas les règles timezone toi-même dans le widget.
6. Message discret :
   « Tablette ou ordinateur conseillé. Le téléphone reste pris en charge. »

Responsive :
- mobile : une colonne
- tablette : deux colonnes si utile
- desktop : contenu centré, pas étiré.

RÈGLE UX :
Aucune sidebar interne élève/tuteur.
Admin aura ses propres tabs lors de l'intégration, mais tu ne modifies pas l'Admin courant.

INTERDICTION :
Ne code pas le moteur countdown serveur, les tables DB, la Bibliothèque ou LiveKit.
Consomme des ports/mocks.

TESTS :
normal, sans groupe, hors ligne, T-20, T0, live, dépassement, session terminée, DST imminent, photo enseignant absente en état d'erreur/migration.

LIVRABLE :
AGENT_A_REPORT.md + tests + liste exacte des fichiers.

# PROMPT B - Library Core, covers, offline et PDF

IMPORTANT - PROTOCOLE COMMUN À TOUS LES AGENTS
Tu travailles sur le Teaching Core de Rewayah pendant qu'un autre chantier Admin peut encore être en cours.
Tu n'utilises jamais le worktree de l'Admin.
Tu pars de TEACHING_BASELINE_SHA dans ton propre worktree/branche.
Tu lis TEACHING_CORE_BASELINE.md, TEACHING_CORE_FILE_OWNERSHIP.md, TEACHING_CORE_CONTRACTS.md et TEACHING_CORE_DECISIONS.md.
Tout fichier hors de ton ownership est READ-ONLY.
Routeur global, thème global, auth core, LiveKit core/provider, pubspec.yaml, migrations partagées et fichiers réservés par l'Admin sont READ-ONLY.
Si un contrat manque, crée CONTRACT_REQUEST_<AGENT>.md. Ne modifie pas le core pour te débloquer.
Ne recrée jamais une fonction déjà existante.
Ne change pas une décision métier pour simplifier ton code.

MISSION : CONSTRUIRE LA BIBLIOTHÈQUE UNIVERSELLE SANS TOUCHER AU QURAN RENDERER.

OWNERSHIP :
Uniquement Library Core / catalog / download attribué à Agent B.

À implémenter :
- Resource catalog
- ResourceCard / cover
- Continue reading
- Récents
- Ce groupe
- Tous les supports
- recherche et filtres simples
- états offline/cache/downloaded
- Resource details minimale
- ClassLibraryPicker réutilisable comme surface, sans dépendre directement de LiveKit
- abstraction DownloadAsset
- abstraction file save/export via port plateforme.

Types :
QuranResource, StructuredTextResource, PDFResource, ImageResource, LessonResource.

IMPORTANT :
La même ressource est utilisée hors classe et en classe.
Ne crée pas LibraryOutsideClass et LibraryInsideClass comme systèmes séparés.

PDF :
- une version publiée possède éventuellement un download_asset immuable
- ne génère jamais un PDF à chaque clic
- un PDF importé peut rester l'artefact source téléchargeable
- une ressource structurée aura son PDF généré une fois hors de ce module
- bouton utilisateur : Télécharger en PDF / Enregistrer une copie
- stockage via sélecteur système, jamais chemin Android hardcodé.

Covers :
- visuellement reconnaissables
- fallback contrôlé
- pas d'icônes identiques pour tous les supports.

INTERDICTION :
Ne modifie pas Quran Engine, LiveKit, router global, pubspec ou migrations.
Si un package de file picker manque : CONTRACT_REQUEST_B.md.

TESTS :
catalogue vide, 1 ressource, centaines de ressources, offline, download indisponible, cover manquante, recherche, permissions.

LIVRABLE :
AGENT_B_REPORT.md + tests + fichiers.

# PROMPT C - Quran Engine et fidélité Mushaf

IMPORTANT - PROTOCOLE COMMUN À TOUS LES AGENTS
Tu travailles sur le Teaching Core de Rewayah pendant qu'un autre chantier Admin peut encore être en cours.
Tu n'utilises jamais le worktree de l'Admin.
Tu pars de TEACHING_BASELINE_SHA dans ton propre worktree/branche.
Tu lis TEACHING_CORE_BASELINE.md, TEACHING_CORE_FILE_OWNERSHIP.md, TEACHING_CORE_CONTRACTS.md et TEACHING_CORE_DECISIONS.md.
Tout fichier hors de ton ownership est READ-ONLY.
Routeur global, thème global, auth core, LiveKit core/provider, pubspec.yaml, migrations partagées et fichiers réservés par l'Admin sont READ-ONLY.
Si un contrat manque, crée CONTRACT_REQUEST_<AGENT>.md. Ne modifie pas le core pour te débloquer.
Ne recrée jamais une fonction déjà existante.
Ne change pas une décision métier pour simplifier ton code.

MISSION : REMPLACER LE RENDU CORAN ACTUEL PAR UN MOTEUR ACADÉMIQUE FIABLE.

OWNERSHIP :
Quran domain/data/layout/presentation attribué à Agent C.

OBJECTIF :
Un utilisateur doit reconnaître une page standard du Mushaf de Médine Hafs retenu par Rewayah.

Implémente trois rendus sur la même source canonique :
1. Mushaf page
2. Lecture agrandie / verset responsive
3. Focus class-ready

Exigences Mushaf :
- 604 pages selon l'édition retenue
- limites de page stables
- lignes et repères cohérents
- sourate/ayah correctement liés
- pageSide/spread explicites
- téléphone : page unique
- tablette/desktop : double page lorsque l'espace le permet
- pas de Text wrapping libre qui détruit la géométrie.

Mode verset :
- reflow responsive
- zoom fort sans overflow
- 1 ayah, petit range ou ligne pédagogique
- local zoom indépendant de SharedContentState.

Navigation :
page, sourate, juz, ayah, recherche, position personnelle, position groupe.

Source :
ne modifie jamais le texte canonique.
Pas de PDF comme source interactive.
Pas de screenshot/image envoyé comme substitut au renderer.

VALIDATION :
Créer des golden tests sur un ensemble de pages de référence, y compris transitions de sourate et pages denses.
Comparer la structure de layout à la référence de l'édition retenue.

STOP :
Si les assets/données existants ne permettent pas la fidélité demandée, ne fabrique pas une fausse page. Produis CONTRACT_REQUEST_C.md avec le manque exact.

LIVRABLE :
AGENT_C_REPORT.md + golden tests + tests navigation + fichiers.

# PROMPT D - Teaching Dock, focus, stylet et annotations

IMPORTANT - PROTOCOLE COMMUN À TOUS LES AGENTS
Tu travailles sur le Teaching Core de Rewayah pendant qu'un autre chantier Admin peut encore être en cours.
Tu n'utilises jamais le worktree de l'Admin.
Tu pars de TEACHING_BASELINE_SHA dans ton propre worktree/branche.
Tu lis TEACHING_CORE_BASELINE.md, TEACHING_CORE_FILE_OWNERSHIP.md, TEACHING_CORE_CONTRACTS.md et TEACHING_CORE_DECISIONS.md.
Tout fichier hors de ton ownership est READ-ONLY.
Routeur global, thème global, auth core, LiveKit core/provider, pubspec.yaml, migrations partagées et fichiers réservés par l'Admin sont READ-ONLY.
Si un contrat manque, crée CONTRACT_REQUEST_<AGENT>.md. Ne modifie pas le core pour te débloquer.
Ne recrée jamais une fonction déjà existante.
Ne change pas une décision métier pour simplifier ton code.

MISSION : CONSTRUIRE LES OUTILS PÉDAGOGIQUES COMME DES COUCHES SUR LE SUPPORT.

OWNERSHIP :
Teaching tools / annotations / assignments UI attribué à Agent D.

Teaching Dock :
Bibliothèque | Focus | Marquer | Masquer | Stylet | Pointeur | Révision

Règles :
- petit dock flottant
- bas/gauche/droite
- ne couvre jamais le contenu actif
- position mémorisée localement
- grandes cibles en Interface guidée
- aucune commande vocale.

Focus :
range actif + réduction du chrome.

Marquer :
intentions :
À apprendre
À revoir
À renforcer
À entretenir
Pour l'évaluation
La couleur est dérivée de l'intention, jamais l'inverse.

Masquer :
supporter hide/reveal d'une plage pour récitation et mémorisation.

Stylet :
- PointerDeviceKind.stylus lorsque disponible
- stylet écrit, doigt pan/zoom
- pression/inclinaison facultatives
- pen, surligner, gomme, undo, plus
- pas de palette graphique complexe.

Annotations :
- source immuable
- données vectorielles normalisées
- temporaire | session | saved
- mode reflow : ancrage sémantique préféré
- ne crée jamais une copie du support.

Révision :
depuis une sélection, créer un LearningAssignment sans formulaire long.

INTERDICTION :
Ne transporte pas toi-même les strokes via LiveKit core.
Expose seulement les events/ports attendus par Agent F.

TESTS :
stylet vs doigt, rotation, zoom, undo, annotation saved/session/temp, range marker, hide/reveal.

LIVRABLE :
AGENT_D_REPORT.md + tests + fichiers.

# PROMPT E - Classroom Shell, roster et session persistante

IMPORTANT - PROTOCOLE COMMUN À TOUS LES AGENTS
Tu travailles sur le Teaching Core de Rewayah pendant qu'un autre chantier Admin peut encore être en cours.
Tu n'utilises jamais le worktree de l'Admin.
Tu pars de TEACHING_BASELINE_SHA dans ton propre worktree/branche.
Tu lis TEACHING_CORE_BASELINE.md, TEACHING_CORE_FILE_OWNERSHIP.md, TEACHING_CORE_CONTRACTS.md et TEACHING_CORE_DECISIONS.md.
Tout fichier hors de ton ownership est READ-ONLY.
Routeur global, thème global, auth core, LiveKit core/provider, pubspec.yaml, migrations partagées et fichiers réservés par l'Admin sont READ-ONLY.
Si un contrat manque, crée CONTRACT_REQUEST_<AGENT>.md. Ne modifie pas le core pour te débloquer.
Ne recrée jamais une fonction déjà existante.
Ne change pas une décision métier pour simplifier ton code.

MISSION : CONSTRUIRE LA SALLE REWAYAH SANS RÉIMPLÉMENTER LIVEKIT.

OWNERSHIP :
Classroom shell / roster presentation / live session UI attribué à Agent E.

Layout desktop/tablette :
- header : groupe + Sayyid/Sayyida + nom enseignant + temps restant
- roster secondaire
- support pédagogique dominant
- Teaching Dock via port
- micro, caméra, état réseau, quitter.

Mobile :
- support dominant
- roster en sheet
- compteur participants compact
- média en vignette lorsque nécessaire.

Roster enseignant :
afficher uniquement TeacherStudentProjection.
Actions fréquentes :
- Choisir pour réciter
- Rappel discret
- Ouvrir contexte pédagogique
- Noter
- Signaler un besoin

Rappel discret :
- targeted event via port
- aucun dialogue
- aucun accusé de réception bavard
- message seulement en cas d'échec.

Micro/caméra :
- enseignant OFF à l'entrée
- élève OFF à l'entrée
- l'enseignant parle normalement au micro lorsqu'il l'active
- aucune commande vocale logicielle.

Session persistante :
- le shell ne possède pas le lifecycle de la room
- revenir Groupe/Accueil/Bibliothèque ne doit pas appeler disconnect
- barre compacte « Cours en cours » pour revenir.

Bibliothèque en classe :
utilise ClassLibraryPicker de B via contrat lors de l'intégration.
Ne navigue pas hors de la room.

INTERDICTION :
Ne modifie pas LiveKit core, permissions serveur, router global, TeacherStudentProjection backend.

TESTS :
mobile/tablette/desktop, support actif/inactif, roster 1/5/15, reconnecting, background, Library overlay, rappel failed.

LIVRABLE :
AGENT_E_REPORT.md + tests + fichiers.

# PROMPT F - Protocole realtime pédagogique

IMPORTANT - PROTOCOLE COMMUN À TOUS LES AGENTS
Tu travailles sur le Teaching Core de Rewayah pendant qu'un autre chantier Admin peut encore être en cours.
Tu n'utilises jamais le worktree de l'Admin.
Tu pars de TEACHING_BASELINE_SHA dans ton propre worktree/branche.
Tu lis TEACHING_CORE_BASELINE.md, TEACHING_CORE_FILE_OWNERSHIP.md, TEACHING_CORE_CONTRACTS.md et TEACHING_CORE_DECISIONS.md.
Tout fichier hors de ton ownership est READ-ONLY.
Routeur global, thème global, auth core, LiveKit core/provider, pubspec.yaml, migrations partagées et fichiers réservés par l'Admin sont READ-ONLY.
Si un contrat manque, crée CONTRACT_REQUEST_<AGENT>.md. Ne modifie pas le core pour te débloquer.
Ne recrée jamais une fonction déjà existante.
Ne change pas une décision métier pour simplifier ton code.

MISSION : CONSTRUIRE LA COUCHE DE PROTOCOLE FEATURE-LEVEL SANS TOUCHER AU LIVEKIT CORE EXISTANT.

OWNERSHIP :
Nouveaux fichiers de protocole/adapters feature-level attribués à Agent F.

Tu dois d'abord auditer les services LiveKit existants.
Si une capacité existe déjà, réutilise-la via adapter.
Ne recopie jamais l'implémentation interne du SDK.

Contrats à supporter :
- shared content state changed
- page/ayah/range changed
- display mode changed
- pointer ephemeral
- annotation stroke preview
- annotation stroke committed
- active student changed
- discreet nudge targeted
- session role/capability projection
- reconnect state restoration

Séparation transport :
- changements importants : reliable
- pointeur / preview stroke : lossy/éphémère
- état durable minimal : backend via port, pas LiveKit comme DB.

SharedContentState :
un late joiner/reconnect doit pouvoir récupérer l'état actuel sans dépendre de l'historique des messages realtime.

INTERDICTION :
- pas de nouveau provider WebRTC
- pas de nouveau système presence concurrent
- pas de migration
- pas de metadata sensible dans LiveKit
- pas de téléphone/email/famille dans participant metadata.

Si le core doit évoluer :
CONTRACT_REQUEST_F.md avec signature précise attendue.

TESTS :
ordre des revisions, duplicate packet, out-of-order, reconnect, late join, targeted nudge, lossy pointer.

LIVRABLE :
AGENT_F_REPORT.md + tests + fichiers.

# PROMPT G - Observation tuteur, Admin, Contrôleur et policies

IMPORTANT - PROTOCOLE COMMUN À TOUS LES AGENTS
Tu travailles sur le Teaching Core de Rewayah pendant qu'un autre chantier Admin peut encore être en cours.
Tu n'utilises jamais le worktree de l'Admin.
Tu pars de TEACHING_BASELINE_SHA dans ton propre worktree/branche.
Tu lis TEACHING_CORE_BASELINE.md, TEACHING_CORE_FILE_OWNERSHIP.md, TEACHING_CORE_CONTRACTS.md et TEACHING_CORE_DECISIONS.md.
Tout fichier hors de ton ownership est READ-ONLY.
Routeur global, thème global, auth core, LiveKit core/provider, pubspec.yaml, migrations partagées et fichiers réservés par l'Admin sont READ-ONLY.
Si un contrat manque, crée CONTRACT_REQUEST_<AGENT>.md. Ne modifie pas le core pour te débloquer.
Ne recrée jamais une fonction déjà existante.
Ne change pas une décision métier pour simplifier ton code.

MISSION : IMPLÉMENTER LES FLOWS D'OBSERVATION ET LE MODULE DE POLITIQUE SANS TOUCHER À LA NAVIGATION ADMIN EN COURS.

OWNERSHIP :
Observation UI/domain + policy module isolé attribué à Agent G.

Tuteur :
- entrée sans acceptation enseignant
- seulement si guardian lié à l'élève inscrit
- politique groupe active
- défaut : 1 visite, 120 s total par séance
- micro interdit
- caméra interdite
- publication data/chat interdite
- accès support + enseignant + son enfant
- pas roster complet
- countdown discret
- sortie bornée serveur via port.

Annonce enseignant :
« Tuteur d'Amina observe »
puis indicateur discret avec temps restant.
Pas de notification de sortie.

Admin :
deux choix avant entrée :
1. Observer discrètement
2. Rejoindre la classe
Incognito : pas micro/caméra, invisible aux participants.
Visible : apparaît comme Administration Rewayah, micro/caméra permis.

Contrôleur :
incognito uniquement, aucune option visible, pas micro/caméra.

Logs :
modèle GuardianSessionVisit et AuditVisit.
Les données doivent permettre date, nombre de visites, durée exacte et policy_version.

Admin settings module :
Construis un composant isolé pour :
- Hériter Académie
- Personnaliser
- Désactiver
- max visites
- temps total max
Ne l'insère PAS dans le routeur/admin courant.
Agent Z le branchera dans Groupe > Réglages après finalisation Admin.

INTERDICTION :
Ne crée pas de règle seulement côté client.
Ne modifie pas auth core/token issuer. Si nécessaire : CONTRACT_REQUEST_G.md.

TESTS :
policy disabled, quota, visite 1/1, temps restant, expiration, tuteur non lié, Admin modes, Contrôleur.

LIVRABLE :
AGENT_G_REPORT.md + tests + fichiers.

# PROMPT H - Flux académique Groupe, feedback et signalements

IMPORTANT - PROTOCOLE COMMUN À TOUS LES AGENTS
Tu travailles sur le Teaching Core de Rewayah pendant qu'un autre chantier Admin peut encore être en cours.
Tu n'utilises jamais le worktree de l'Admin.
Tu pars de TEACHING_BASELINE_SHA dans ton propre worktree/branche.
Tu lis TEACHING_CORE_BASELINE.md, TEACHING_CORE_FILE_OWNERSHIP.md, TEACHING_CORE_CONTRACTS.md et TEACHING_CORE_DECISIONS.md.
Tout fichier hors de ton ownership est READ-ONLY.
Routeur global, thème global, auth core, LiveKit core/provider, pubspec.yaml, migrations partagées et fichiers réservés par l'Admin sont READ-ONLY.
Si un contrat manque, crée CONTRACT_REQUEST_<AGENT>.md. Ne modifie pas le core pour te débloquer.
Ne recrée jamais une fonction déjà existante.
Ne change pas une décision métier pour simplifier ton code.

MISSION : IMPLÉMENTER LES WORKFLOWS ACADÉMIQUES AUTOUR DU GROUPE SANS RECONSTRUIRE LE GROUP SHELL.

OWNERSHIP :
before-course / resume / post-class / feedback / concern attribué à Agent H.

Avant le prochain cours :
- maximum 3 actions visibles
- utiliser LearningAssignment
- À apprendre / revoir / renforcer / entretenir / évaluation
- pas de formulaire narratif.

Reprendre le cours :
- position groupe proposée depuis la dernière séance
- action contextuelle, pas une section permanente.

Post-cours enseignant :
- prérempli depuis présence, durée, contenu présenté, position, ranges
- exceptions seulement
- cible <45 s
- proposition de position de reprise
- proposition de travail.

Feedback :
- occasionnel
- 3 choix rapides
- un tap
- aucun commentaire obligatoire
- anonymisé/agrégé
- pas de leaderboard
- pas de score brut utilisé seul.

Signalement :
StudentConcern avec :
- catégorie
- contexte session/groupe/élève/enseignant auto
- internal_details
- family_summary
- statut
Préparer l'action Admin future « Transmettre au tuteur / élève adulte » via port.
Ne touche pas au panneau Admin courant.

INTERDICTION :
Ne modifie pas Group UI structure d'Agent A.
Ne modifie pas lesson report core existant si une abstraction suffit.

TESTS :
aucune tâche, 1-3 tâches, range Quran, post-cours offline/queue, feedback sampled/non-sampled, concern family summary absent.

LIVRABLE :
AGENT_H_REPORT.md + tests + fichiers.

# PROMPT Q - QA parallèle et contrats de test

IMPORTANT - PROTOCOLE COMMUN À TOUS LES AGENTS
Tu travailles sur le Teaching Core de Rewayah pendant qu'un autre chantier Admin peut encore être en cours.
Tu n'utilises jamais le worktree de l'Admin.
Tu pars de TEACHING_BASELINE_SHA dans ton propre worktree/branche.
Tu lis TEACHING_CORE_BASELINE.md, TEACHING_CORE_FILE_OWNERSHIP.md, TEACHING_CORE_CONTRACTS.md et TEACHING_CORE_DECISIONS.md.
Tout fichier hors de ton ownership est READ-ONLY.
Routeur global, thème global, auth core, LiveKit core/provider, pubspec.yaml, migrations partagées et fichiers réservés par l'Admin sont READ-ONLY.
Si un contrat manque, crée CONTRACT_REQUEST_<AGENT>.md. Ne modifie pas le core pour te débloquer.
Ne recrée jamais une fonction déjà existante.
Ne change pas une décision métier pour simplifier ton code.

MISSION : CONSTRUIRE LA STRATÉGIE DE TEST PENDANT QUE LES FEATURES SONT CODÉES.

OWNERSHIP :
Tests, fixtures, test helpers attribués à Agent Q. Code production read-only.

Crée :
- fixtures GroupSummaryVM
- sessions T-30/T-20/T0/live/ended
- fuseaux Europe/Paris, Africa/Conakry, Asia/Riyadh
- scénario DST
- resources Quran/PDF/structured
- SharedContentState revisions
- guardian policies
- TeacherStudentProjection sans PII.

Tests contractuels attendus :
- aucune PII dans teacher projection
- join early ne change pas attendance window
- guardian quota
- Admin/Controller capabilities
- SharedContentState restore
- annotations n'altèrent pas resource_version
- Library picker ne disconnect pas session
- Quran page/spread golden contract
- Interface guidée grandes cibles
- teacher photo/title display
- PDF download abstraction
- session persistent navigation.

Tu peux écrire des tests qui ciblent les interfaces définies dans TEACHING_CORE_CONTRACTS.md.
Si une interface de production n'existe pas encore, utilise une fixture/mock sans modifier les features.

LIVRABLE :
TEACHING_CORE_TEST_PLAN.md
AGENT_Q_REPORT.md
tests/fixtures dans ton ownership.

# PROMPT PRE-MERGE - Contrôle de toutes les branches

MISSION : CONTRÔLER LES BRANCHES AVANT TOUTE INTÉGRATION.

Ne fusionne rien.

Pour A, B, C, D, E, F, G, H, Q :
1. Vérifie l'origine TEACHING_BASELINE_SHA.
2. Liste les fichiers modifiés.
3. Compare avec TEACHING_CORE_FILE_OWNERSHIP.md.
4. Toute modification d'un fichier PROTECTED ou hors ownership = BLOCKER.
5. Collecte CONTRACT_REQUEST_*.md.
6. Détecte services/providers/routes/modèles dupliqués.
7. Vérifie l'absence de nouvelle migration non autorisée.
8. Vérifie l'absence de pubspec modifié.
9. Vérifie les tests propres à chaque branche.
10. Vérifie que les branches n'ont pas réimplémenté LiveKit, Auth, Library ou Quran hors de leur domaine.

PRODUIS :
TEACHING_CORE_PREMERGE_REPORT.md
TEACHING_CORE_INTEGRATION_CONTRACT_PLAN.md

Pour chaque lot :
READY
READY WITH CONTRACT CHANGE
BLOCKED

Aucune intégration tant qu'un seul lot est BLOCKED.

# PROMPT IMMUABLE Z - Intégration finale du Teaching Core

CE PROMPT EST IMMUABLE.
IL EST LE SEUL PROTOCOLE AUTORISÉ POUR RÉUNIR LE TEACHING CORE.

RÔLE :
Tu es Agent Z, intégrateur. Tu branches les modules validés. Tu ne les redessines pas.

CONDITION :
TEACHING_CORE_PREMERGE_REPORT.md ne contient aucun BLOCKED.
Le chantier Admin doit être finalisé et avoir un commit TARGET_SHA connu.

PHASE 1 - BRANCHE D'INTÉGRATION
Créer integration/teaching-core depuis TARGET_SHA, pas depuis l'ancien TEACHING_BASELINE_SHA.
Ne jamais intégrer directement dans main.

PHASE 2 - RÉCONCILIER AVEC L'ADMIN TERMINÉ
Comparer TEACHING_CORE_PROTECTED_FILES.md avec les fichiers désormais modifiés par l'Admin.
Ne jamais écraser une décision Admin avec une ancienne version.
Adapter le wiring Teaching Core au shell final.

PHASE 3 - CONTRATS PARTAGÉS
Lire TEACHING_CORE_INTEGRATION_CONTRACT_PLAN.md.
Agent Z est le seul autorisé à modifier :
- router global
- DI/composition root
- pubspec.yaml
- shared exports
- shared DTO/interfaces
- migrations coordonnées
- token issuer / server capabilities
- LiveKit core wiring
- Admin route d'intégration Group > Réglages
- shared theme uniquement si nécessaire et documenté.

Avant migration :
mapper toute table/colonne existante.
Ne jamais créer un doublon sémantique.

PHASE 4 - ORDRE D'INTÉGRATION
1. Contrats partagés + dépendances approuvées
2. Agent B - Library Core
3. Agent C - Quran Engine
4. Agent A - Group Space
5. Agent H - Academic Flow
6. Agent D - Teaching Tools
7. Agent F - Realtime Protocol
8. Agent E - Classroom Shell
9. Agent G - Observation & Policies
10. Agent Q - QA final

Après CHAQUE intégration :
- flutter analyze
- tests concernés
- build ciblé
- contrôle des routes/wiring
- aucun redesign opportuniste.

Si une feature exige une réécriture importante :
STOP et produire INTEGRATION_REJECT_<AGENT>.md.

PHASE 5 - BRANCHEMENT END-TO-END
Prouver ces parcours :

A. Élève
Mes groupes
-> carte groupe
-> espace groupe
-> countdown
-> T-20 Rejoindre
-> attente
-> T0 cours
-> support poussé automatiquement
-> sortie
-> groupe mis à jour.

B. Enseignant
Journée/Groupe
-> preflight
-> salle
-> roster
-> choisir élève
-> Bibliothèque sans disconnect
-> Quran
-> focus/stylet/masquer
-> rappel discret
-> quitter
-> post-cours prérempli
-> reprise enregistrée.

C. Tuteur
Groupe enfant
-> Assister
-> validation policy
-> entrée automatique
-> vue limitée
-> timer
-> sortie serveur
-> log exact.

D. Admin
Groupe > Réglages
-> policy tuteur
-> sauvegarde versionnée
-> session live
-> choisir incognito ou visible
-> audit.

E. Contrôleur
Planning/entrée
-> incognito
-> aucune publication
-> audit.

PHASE 6 - INVARIANTS
Prouver :
- une seule Library
- un seul Quran source of truth
- un seul LiveKit provider
- un seul router
- aucune PII famille chez l'enseignant
- aucune annotation ne modifie la source
- aucune visite tuteur hors quota
- aucune entrée précoce fausse la présence
- aucun DST calculé par offset hardcodé
- aucun « mode enfant » visible dans le produit
- Sayyid/Sayyida partout dans le contexte cours
- aucune commande vocale implémentée.

PHASE 7 - QA RESPONSIVE
Mobile, tablette, desktop/web selon plateformes supportées.
Light/dark.
RTL/LTR si supporté.
Text scaling.
Interface guidée.
Stylet tablette.
Offline Library.
Reconnexion LiveKit.

PHASE 8 - RAPPORT FINAL
Produire TEACHING_CORE_INTEGRATION_REPORT.md :
- TEACHING_BASELINE_SHA
- TARGET_SHA
- branches/commits
- changements contrats
- migrations
- dépendances
- fichiers partagés touchés
- tests
- builds
- parcours E2E
- conflits
- décisions
- dettes.

PHASE 9 - MERGE
La branche integration/teaching-core ne peut rejoindre la cible qu'après :
- analyse verte
- tests verts
- build réussi
- E2E réussi
- zéro BLOCKER
- zéro duplication fonctionnelle connue
- vérification sécurité/PII.

INTERDICTION :
Ne jamais résoudre un conflit Git mécaniquement par ours/theirs.
Comprendre la propriété du fichier et préserver la décision la plus récente et normative.

FIN DU PROTOCOLE.

# 17. Ordre de lancement recommandé

Laisser l'agent Admin continuer dans son worktree actuel.

Lancer Prompt 0 dans un worktree séparé.

Quand Agent 0 a livré l'ownership, lancer A, B, C, D, E, F, G, H et Q dans des worktrees distincts.

Interdire toute modification des fichiers PROTECTED et du shared core.

Exécuter le Prompt PRE-MERGE lorsque les agents sont terminés.

Attendre la fin du chantier Admin uniquement pour l'étape d'intégration globale.

Après Admin finalisé : lancer le Prompt immuable Z depuis TARGET_SHA.

# 18. Checklist finale produit

La carte Groupe est informative mais compacte.

La Session Card est le CTA principal.

Le timer est descendant et cohérent serveur.

La fenêtre T-20 est configurable.

Le Groupe affiche les deux horloges utiles.

Les alertes DST existent avant le changement.

La photo enseignant est obligatoire.

Sayyid/Sayyida est utilisé dans le contexte cours.

La Bibliothèque est disponible hors et dans la classe.

Les supports ont de vraies couvertures.

Le PDF est un artefact de version et non une génération répétée.

Le Quran respecte une vraie géométrie Mushaf.

Le mode verset est fortement responsive.

Le Teaching Dock reste visible sans distraire.

Le stylet écrit sur une couche indépendante.

Le roster n'expose aucune coordonnée famille.

Le rappel discret n'ouvre jamais un micro à distance.

Le professeur peut parler normalement via son micro.

Le tuteur est borné, silencieux et audit-tracé.

L'Admin a deux modes d'entrée.

Le Contrôleur reste incognito.

Le feedback enseignant est occasionnel et non gamifié.

Le signalement peut être relayé à la famille/adulte par l'Admin.

La session Live ne dépend pas du lifecycle d'un écran.

Aucun agent ne modifie le shared core en parallèle.

# 19. Fichiers sources projet consultés

PARCOURS_UTILISATEURS_MVP0.md

DECISIONS_ARCHITECTURE_MVP0.md

REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md

architecture live kit..md

PLAN_ETAPE_0_ET_1.md

COUVERTURE_SPECS_ORIGINALES.md

rewayah_control_system_v2.md

REWAYAH_REFERENTIEL_ACADEMIQUE_V1(1).docx

Les points non explicitement présents dans ces fichiers mais décidés dans le cadrage actuel sont identifiés dans la section 1.1 comme décisions nouvelles normatives.


[Tableau extrait 1]

Principe directeur / Ici, il n'y a pas de réduction de capacité de type MVP. Le système doit être poussé à fond techniquement, mais rester simple à utiliser. La complexité appartient à l'architecture, jamais à la main de l'enseignant, de l'élève ou du tuteur.


[Tableau extrait 2]

Noyau | Responsabilité

Group Space | Identité du groupe, prochaine séance, countdown, accès au cours, tâches, bibliothèque, progression utile.

Library Core | Catalogue de supports, couvertures, recherche, offline, téléchargement PDF, versions de ressources.

Quran Engine | Mushaf 604 pages fidèle, mode verset responsive, focus, zoom, navigation, cache.

Shared Document Stage | Affichage du support actif dans la classe sans partage d'écran.

Teaching Tools | Focus, marqueurs, masquer/révéler, stylet, pointeur, révision, position de reprise.

Classroom Core | LiveKit média, roster, session persistante, pré-cours, post-cours, états réseau.

Observation & Control | Tuteur observateur limité, Admin visible/incognito, Contrôleur incognito uniquement.

Academic Workflow | Travail à préparer, reprise du cours, feedback rapide, signalement structuré.


[Tableau extrait 3]

Priorité | Source

1 | Sécurité, confidentialité, RLS, décisions métier et contraintes backend existantes.

2 | REWAYAH_REFERENTIEL_ACADEMIQUE_V1 - noyau académique, groupe, objectifs, charge enseignant.

3 | architecture live kit..md - séparation LiveKit / domaine / Quran / présence.

4 | REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md - hiérarchie UX, responsive, Material 3, accessibilité.

5 | PARCOURS_UTILISATEURS_MVP0.md et DECISIONS_ARCHITECTURE_MVP0.md.

6 | Décisions nouvelles figées dans ce document.


[Tableau extrait 4]

Sujet | Décision désormais normative

Interface | Ne plus employer « mode enfant » comme nom produit. Utiliser « Interface guidée ». L'âge peut suggérer un mode, jamais le définir à lui seul.

Titres enseignants | Dans l'espace cours : Sayyid / Sayyida. En arabe : سيد / سيدة. Pas de Ustaz/Ustazah.

Photo enseignant | Photo professionnelle publique obligatoire pour tout enseignant actif/assignable. Distincte des pièces KYC.

Coran | Source canonique structurée et immuable + moteur de layout Mushaf fidèle. Un PDF téléchargeable est un artefact dérivé, jamais la source interactive.

Suivi du professeur | Pendant une présentation dirigée, l'élève suit automatiquement l'état partagé. Aucun bouton « Revenir au professeur » requis.

Commandes vocales | NON. Ne pas construire de moteur de commandes vocales. Le professeur utilise le micro normal pour parler.

Observation tuteur | Accès automatique borné par politique serveur. Par défaut : activé, 1 visite, 120 secondes totales par séance. Configurable par groupe.

Fenêtre de connexion | Bouton Rejoindre activé environ 20 minutes avant la séance. Valeur configurable. L'attente avant T0 ne compte pas comme présence académique.

Admin live | Admin peut entrer incognito ou visible. Visible autorise micro/caméra. Incognito est silencieux et audité.

Contrôleur live | Incognito uniquement, aucun micro/caméra, entrée auditée.

Feedback enseignant | Micro-feedback occasionnel, ultra rapide, agrégé, jamais leaderboard public ni score brut utilisé seul pour un privilège.

Couleur groupe | Palette large et contrôlée, pas couleur arbitraire. La couleur n'est jamais le seul identifiant.


[Tableau extrait 5]

Élément | Règle UI

Couleur | Liseré/repère discret issu d'une palette administrée. Jamais seul moyen d'identifier le groupe.

Nom du groupe | Nom familier, lisible, sans code backend.

Enseignant | Photo obligatoire + Sayyid/Sayyida + prénom/nom d'affichage autorisé.

Cours / niveau | Nom humain du cours et niveau utile. Pas de codes académiques internes.

Capacité | Afficher X/capacité réelle, par exemple 4/5 ou 3/4. Ne jamais hardcoder 5.

Prochaine séance | Jour, date, heure, durée.

Countdown | Ex. « Cours dans 3 h 28 ». Devient compte à rebours de séance lorsqu'elle commence.

CTA | Rejoindre uniquement lorsque join_opens_at est atteint.


[Tableau extrait 6]

Période | UI | Accès

Avant la fenêtre | Date + heure + durée + countdown. | Rejoindre désactivé/absent.

À partir de T-20 par défaut | « Salle ouverte - cours dans 18 min ». | Rejoindre actif.

Connecté avant T0 | État d'attente. Aucun temps académique consommé. | Room connectée.

À T0 | « Cours en cours - reste 1 h 30 ». | Présence académique commence selon règles.

Pendant | Countdown descendant du temps restant. | Rejoindre/reconnecter actif.

Après fin prévue mais session encore ouverte | « Cours toujours en cours ». | Pas de faux countdown négatif.

Terminé | Retour à la prochaine séance. | Rejoindre fermé.


[Tableau extrait 7]

Type | Renderer

QuranResource | Mushaf + mode verset + focus + navigation Quran.

StructuredTextResource | Texte structuré, sections, recherche, zoom.

PDFResource | PDF natif/importé avec pages, zoom, annotations en couche.

ImageResource | Image pédagogique, zoom/pan, annotations.

LessonResource | Leçon Rewayah structurée avec blocs et navigation.


[Tableau extrait 8]

Mode | Usage

Mushaf | Lecture normale, mémorisation, repères spatiaux, 604 pages standards.

Lecture agrandie | Verset, petit groupe de versets ou ligne pédagogique avec zoom responsive fort.

Classe / Focus | Support dirigé par l'enseignant avec synchronisation, masquage, marqueurs, pointer/stylet.


[Tableau extrait 9]

Outil | Comportement

Focus | Mettre un ayah/range au centre, réduire le chrome, grossir si nécessaire.

Marquer | Associer une intention sémantique, pas une couleur brute.

Masquer | Masquer une plage pour récitation/mémorisation, avec révélation contrôlée.

Stylet | Écriture libre sur couche séparée. Doigt reste navigation/zoom lorsque possible.

Pointeur | Indication éphémère, non persistante par défaut.

Révision | Créer une plage de travail depuis la sélection courante.


[Tableau extrait 10]

Intention | Libellé utilisateur

Nouveau contenu | À apprendre

Révision normale | À revoir

Faiblesse | À renforcer

Maintien | À entretenir

Périmètre évalué | Pour l'évaluation


[Tableau extrait 11]

Rôle | Avant | Après

Enseignant | Preflight réseau/micro/sortie/caméra si utile + support/reprise + roster. | Cahier prérempli, position de reprise proposée, travail proposé, exceptions.

Élève | Vérifications silencieuses. Action uniquement si un problème bloque. | Retour Groupe, tâches mises à jour. Aucun formulaire obligatoire.

Tuteur | Autorisation serveur et politique d'observation. Aucun test micro/caméra. | Résumé de cours selon règles existantes.


[Tableau extrait 12]

Règle | Valeur par défaut

Observation | Activée

Visites max / séance | 1

Temps total max / séance | 120 secondes

Micro | Interdit

Caméra | Interdite

Publication data/chat | Interdite

Admission prof | Aucune

Entrée | Automatique après validation serveur


[Tableau extrait 13]

Mode | Visible | Micro | Caméra | Annonce

Observation incognito | Non | Non | Non | Non

Intervention visible | Oui | Oui | Oui | Oui


[Tableau extrait 14]

Contrat | Responsabilité

GroupSummaryVM | Carte groupe : identité, enseignant, photo, cours/niveau, capacité, prochaine séance, countdown, couleur.

GroupHomeVM | Espace Groupe par rôle.

SessionClockVM | Heures locale/groupe/enseignant, join_opens_at, countdown, DST notice.

LibraryResource | Ressource et capacités.

ResourceVersion | Version immuable publiée.

DownloadAsset | PDF/artefact téléchargeable.

ContentPosition | Position canonique dans un support.

ContentRange | Plage de pages/ayah/sections.

SharedContentState | Support + position + range + mode + revision.

AnnotationLayer | Couche indépendante du support.

LearningAssignment | À apprendre / revoir / renforcer / entretenir / évaluation.

TeacherStudentProjection | Vue pédagogique restreinte pour enseignant.

GuardianObservationPolicy | Activation, max visites, temps total, héritage groupe/Académie.

GuardianSessionVisit | Intervals d'observation réels et auditables.

SessionFeedback | Micro-feedback occasionnel.

StudentConcern | Signalement enseignant -> Admin -> famille/adulte.


[Tableau extrait 15]

Largeur | Groupe | Classe | Bibliothèque

Mobile | Une colonne, Session > tâches > Bibliothèque. | Support primaire, roster en sheet, dock compact. | Grille 2 colonnes ou liste visuelle selon largeur.

Tablette | Deux colonnes légères si utile. | Support + roster/contexte, excellent support stylet. | Covers plus larges, panneau latéral en classe.

Desktop/Web | Contenu centré, pas de stretching infini. | Roster + support + contexte secondaire. | Grille dense contrôlée, recherche et filtres.


[Tableau extrait 16]

Objectif / Permettre de démarrer ce chantier maintenant, alors que le chantier Admin est encore en cours, sans que les agents se marchent dessus.


[Tableau extrait 17]

Agent | Périmètre exclusif | Ne touche pas

0 - Coordinateur | Audit, baseline, mapping, contrats, ownership. | Écrans métier.

A - Group Space | Cartes groupe, espace groupe, session card, clocks UI. | Router global, migrations, Library internals.

B - Library Core | Catalogue, covers, browsing, cache/offline, download abstraction. | Quran layout, LiveKit, Group UI.

C - Quran Engine | Mushaf layout, verse renderer, navigation Quran, golden tests. | Library shell, LiveKit.

D - Teaching Tools | Teaching Dock, focus, markers, hide/reveal, stylus, annotation layers, assignments UI. | LiveKit core, Quran source.

E - Classroom Shell | Layout classe, roster, fiche pédagogique, rappel discret UI, session persistent UI. | Permissions serveur, Group UI.

F - Realtime Protocol | Contrats realtime feature-level, SharedContentState transport adapters, targeted events. | LiveKit core existant, DB migrations.

G - Observation & Policies | Tuteur/Admin/Contrôleur UX, policy consumption, logs models, admin policy module non routé. | Admin navigation actuelle, core auth.

H - Academic Flow | Avant prochain cours, reprise, post-cours, feedback, concern flow. | Group shell structure, Admin routes.

Q - QA | Tests contrats, fixtures, golden/integration plans. | Code production hors tests.

Z - Intégrateur | Wiring global, router, DI, pubspec, migrations coordonnées, résolution intégration. | Refonte opportuniste des features.



---

## 6. Checklist de clôture de l'audit Claude

Avant toute modification, Claude remet au directeur :

- [ ] La liste de toutes les sources lues et des fichiers du dépôt inspectés.
- [ ] La matrice de couverture des rôles et écrans avec routes, composants, états et preuves de code.
- [ ] Une matrice séparée des règles métier non codables ou seulement partiellement représentées dans le produit.
- [ ] Les règles financières détaillées conservées : prix, régime familial, échéance, période, calendrier, Ramadan/Tabaski, prorata, absences, annulation, avoirs, remboursement, solde par profil, bourses, rémunération et payout.
- [ ] Les règles académiques conservées : D0, cycles, gates, compétences, progression, devoirs, autorité humaine, contestations, versionnement et certificats.
- [ ] Le registre des conflits avec source, date, statut et arbitrage requis, sans choix silencieux.
- [ ] Les fonctions déjà codées et conformes exclues de toute reconstruction inutile.
- [ ] Les fonctions codées mais non prouvées par tests distinguées des fonctions réellement testées.
- [ ] Les dépendances backend et les limites frontend-only respectées.
- [ ] Les risques de régression, les tests de recette et la preuve finale attendue par verticale.

**Définition de terminé :** aucune exigence documentée n'est perdue simplement parce qu'elle ne correspond pas directement à une tâche de programmation. Chaque exigence possède soit une preuve de conformité, soit un écart explicite, soit une question d'arbitrage clairement identifiée.

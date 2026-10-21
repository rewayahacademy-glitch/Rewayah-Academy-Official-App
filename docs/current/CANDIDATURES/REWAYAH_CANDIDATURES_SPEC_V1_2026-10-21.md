# REWAYAH - Spécification produit/UX finale

## Module de gestion des candidatures et viviers de recrutement

**Version :** 1.0\
**Date :** 21 octobre 2026\
**Statut :** Spécification produit à auditer contre le dépôt avant
implémentation\
**Périmètre :** Frontend only pour la phase actuelle\
**Destinataire principal :** Claude Code\
**Produit :** Rewayah Academy / application Rewayah

------------------------------------------------------------------------

## 0. Objet et décision directrice

Créer un système intégré de gestion des candidatures qui soit utilisé
d'abord pour le recrutement des enseignants, mais dont le modèle puisse
s'adapter à d'autres types de candidatures : personnel administratif,
comptabilité, contrôle, recrutement temporaire, bénévolat, missions
ponctuelles ou autres catégories futures.

Le système doit être **générique dans sa structure, spécialisé par
configuration dans ses règles métier**. Il ne faut ni construire un
système limité aux enseignants, ni transformer le projet en constructeur
de formulaires complexe et prématuré.

Le système doit réutiliser les fonctions, composants, profils,
validations et permissions déjà présents dans Rewayah. Il ne doit pas
créer de deuxième source de vérité pour les identités, les dossiers
enseignants, le KYC, les validations administratives, les affectations
ou les paiements.

### Résultats attendus

1.  Un pipeline de candidatures configurable par type de recrutement.
2.  Trois étapes logiques pour le recrutement enseignant :
    préqualification, vérification/entretien, vivier confirmé et prêt à
    être affecté.
3.  Des critères obligatoires, critères préférentiels et règles de
    décision clairement séparés.
4.  Un portail candidat confidentiel, sans communication entre
    candidats.
5.  Une interface d'administration avec recherche, filtres, actions
    groupées contrôlées, historique et entretien vidéo.
6.  Un import contrôlé des candidatures existantes depuis Google Sheets.
7.  Un modèle extensible pour d'autres types de candidatures sans
    dupliquer le moteur.
8.  Des maquettes et états UI cohérents avec le design system existant.

------------------------------------------------------------------------

## 1. Contraintes, autorité et limites

### 1.1 Hiérarchie des sources de vérité

Claude doit respecter cet ordre de priorité :

1.  Sécurité, confidentialité et conformité.
2.  Spécifications métier officielles déjà présentes dans le projet.
3.  Modèles de données, contrats et mécanismes existants.
4.  Bible Frontend/UI/UX Rewayah V2.
5.  Design system, composants, routes et conventions du dépôt.
6.  Présente spécification pour les règles nouvelles ou les décisions
    explicitement confirmées ici.
7.  Documentation officielle des plateformes et standards
    d'accessibilité.

En cas de contradiction, Claude doit documenter le conflit et proposer
un arbitrage plutôt que choisir silencieusement.

### 1.2 Phase actuelle : FRONTEND ONLY

Sauf autorisation explicite du directeur, ne pas modifier : - Supabase,
schémas, migrations, RLS ou RPC ; - backend, serveurs, webhooks ou
contrats d'API ; - architecture ou configuration LiveKit ; - secrets,
infrastructure ou pipelines de déploiement.

Le frontend peut préparer les écrans, composants, états, modèles de
présentation et contrats attendus, en réutilisant les interfaces
existantes. Toute dépendance backend absente doit être signalée comme
blocage ou demande de contrat, et non contournée par des données
fictives en production.

### 1.3 Règle de non-duplication

Avant de créer une fonction, rechercher son équivalent dans le dépôt. En
particulier : - dossiers et profils enseignants ; - KYC et vérification
d'identité ; - validation administrative ; - gestion des comptes et
rôles ; - calendrier et sessions de visioconférence ; - affectations et
disponibilité des enseignants ; - paiements et données comptables ; -
recherche globale et filtres existants ; - composants de tableau,
formulaires, badges, dialogs, notifications et états UI.

Réutiliser ou étendre le mécanisme existant si cela est cohérent. Ne pas
créer un écran, une route, un service, un statut ou un modèle concurrent
sans justification et validation.

------------------------------------------------------------------------

## 2. Modèle générique de candidature

### 2.1 Principe

Le système est organisé autour d'un **type de candidature** et d'un
**pipeline configurable**. Le recrutement enseignant est le premier
profil de configuration, pas une implémentation isolée.

Chaque type de candidature peut définir : - nom et description ; -
public visé et équipe responsable ; - étapes et transitions permises ; -
champs du formulaire et règles de validation ; - critères éliminatoires
; - critères préférentiels et poids éventuels ; - pièces justificatives
requises à chaque étape ; - entretiens et évaluations ; - engagements ou
déclarations à accepter ; - permissions et visibilité des informations
; - règles d'entrée dans le vivier final ; - actions de clôture, refus,
retrait, mise en pause et réouverture ; - modèle de notification et
contenu communiqué au candidat.

Les champs doivent pouvoir être classés par étape : candidature
initiale, préqualification, vérifications, entretien, confirmation et
intégration après sélection. Ne pas demander à l'avance les données qui
ne sont nécessaires qu'après une sélection ou un début effectif de
mission.

### 2.2 Extension à d'autres candidatures

Le modèle doit permettre de créer de futurs types de candidatures sans
coder un nouveau pipeline complet. Exemple : - Enseignant : compétences
pédagogiques, lecture/mémorisation, KYC, entretien, compatibilité de
paiement, disponibilités et affectabilité. - Personnel administratif :
expérience pertinente, compétences, disponibilité, justificatifs et
entretien ; pas de critères de mémorisation du Coran sauf justification
métier explicite. - Comptable : compétences et expérience comptables,
évaluation et contrôles pertinents. - Contrôleur : compétences
d'audit/contrôle et périmètre d'accès futur. - Mission temporaire :
périmètre, dates, livrables, disponibilité et validations propres à la
mission.

Les critères d'un type ne doivent jamais s'appliquer automatiquement à
tous les autres types.

### 2.3 Architecture conceptuelle à préserver

Séparer les objets métier suivants, en réutilisant les modèles existants
lorsqu'ils existent :

1.  **Candidature** : identité de candidature, type, réponses, pièces,
    évaluations, historique et statut de pipeline.
2.  **Identité/compte** : compte authentifié et identité centrale
    existante. Une candidature ne crée pas automatiquement un compte
    opérationnel actif.
3.  **Profil métier validé** : par exemple profil enseignant ou profil
    de personnel, créé ou activé selon les règles existantes.
4.  **Disponibilité/capacité opérationnelle** : état évolutif,
    indépendant de l'avancement historique du recrutement.
5.  **Affectation/mission** : relation opérationnelle avec une classe,
    un rôle, une mission ou une période.

Ne pas confondre « candidature confirmée », « profil actif », «
disponible » et « déjà affecté ».

------------------------------------------------------------------------

## 3. Pipeline enseignant

Les « salles » sont des **étapes de recrutement et vues de travail**,
pas des communautés ni des salons collectifs. Il n'y a pas de messagerie
entre candidats.

### Salle 1 - Préqualification

Objectif : déterminer rapidement si la candidature mérite des
vérifications approfondies.

Données et contrôles : - identité et coordonnées essentielles ; - pays
de résidence et fuseau horaire ; - pays d'origine si utile au contexte,
sans en faire un critère éliminatoire automatique non justifié ; -
expérience et compétences déclarées ; - niveau de lecture, tajwid et
mémorisation déclarés ; - disponibilité et publics enseignables ; -
moyens de réception de paiement disponibles ; - confirmation du cadre
religieux et pédagogique de Rewayah ; - informations manquantes et
possibilité de compléter la candidature.

Sorties : - admissible pour la salle 2 ; - à compléter ; - refusée avec
motif enregistré ; - retirée par le candidat ; - mise en pause avec
motif et éventuelle date de reprise.

### Salle 2 - Vérifications et entretiens

Objectif : vérifier les déclarations et décider si le candidat est prêt
à rejoindre le vivier final.

Contrôles : - évaluations de lecture, tajwid et mémorisation selon le
référentiel existant ; - expérience et aptitude pédagogique ; - pièces
requises ; - KYC soumis, examiné et validé par le mécanisme existant ; -
engagement religieux accepté ; - entretien réalisé et décision
documentée ; - compatibilité de réception de paiement confirmée ; -
disponibilité et périmètre d'enseignement confirmés.

Sorties : - prêt pour décision finale ; - entretien à planifier ; - à
compléter ; - refusé ; - retiré ; - en pause.

### Salle 3 - Vivier confirmé, prêt à être affecté

**L'entrée en salle 3 signifie que tous les prérequis d'admission sont
validés.** Aucun contrôle obligatoire ne doit rester en attente.

Pour un enseignant, cela comprend : - KYC validé, pas seulement envoyé
; - évaluations et qualifications requises validées ; - entretien
terminé et décision finale humaine enregistrée ; - engagement religieux
accepté ; - moyen de réception de paiement compatible confirmé ; -
compétences, publics, fuseau horaire et disponibilités suffisamment
renseignés ; - profil enseignant existant prêt à être utilisé, sans
doublon ; - aucune suspension ou restriction bloquante.

Le candidat peut rejoindre ce vivier sans avoir encore renseigné ses
coordonnées financières personnelles (numéro de compte, numéro de
portefeuille ou équivalent). Ces données seront demandées par un
parcours sécurisé lorsque les cours commenceront et qu'un paiement devra
être préparé.

Si un prérequis devient invalide ou doit être réexaminé, le profil doit
quitter l'état « prêt à être affecté » ou être bloqué temporairement,
avec un motif traçable. Ne pas effacer son historique de recrutement.

### Statuts et dimensions distinctes

Les libellés exacts doivent être harmonisés avec les enums/statuts déjà
présents. Modèle conceptuel : - Invitation envoyée ; - Informations à
compléter ; - Préqualification ; - Vérifications ; - Entretien à
planifier ; - Entretien planifié ; - Décision finale en attente ; -
Confirmé / prêt à être affecté ; - Refusé ; - Retiré ; - En pause.

Les dimensions suivantes restent distinctes : - état du recrutement ; -
état KYC ; - état de compatibilité de paiement ; - état de disponibilité
; - état d'affectation ; - état des coordonnées financières.

Une indisponibilité temporaire ne doit pas rétrograder automatiquement
le candidat dans le pipeline. Un refus KYC ou l'absence de toute méthode
de paiement compatible bloque en revanche l'accès au vivier enseignant.

------------------------------------------------------------------------

## 4. Paiements des enseignants : préférence bancaire, sans exclusion automatique

### 4.1 Règle produit

Les candidats disposant d'un compte bancaire compatible doivent être
**favorisés dans le classement à qualité égale**, car le virement
bancaire peut faciliter la gestion. Toutefois, **l'absence de compte
bancaire ne constitue pas, à elle seule, un motif de rejet**.

La condition obligatoire est la suivante :

> Avant l'entrée en salle 3, il faut confirmer qu'au moins un moyen de
> réception déclaré par le candidat est effectivement compatible avec
> les moyens de décaissement que Rewayah peut utiliser pour son pays et
> sa situation.

Un candidat ne pouvant recevoir aucun paiement via une méthode validée
ne peut pas entrer dans le vivier prêt à être affecté. Un candidat qui
ne possède pas de compte bancaire, mais dispose d'un portefeuille mobile
compatible, reste admissible.

### 4.2 Déclaration en préqualification

Demander : - pays de résidence ; - pays dans lequel le candidat recevra
les paiements, si différent ; - possession d'un compte bancaire
permettant de recevoir des virements ; - moyens de réception mobile
money réellement accessibles : Wave, Orange Money, Moov Money ou autres
options pertinentes pour son pays ; - accord pour recevoir sa
rémunération par au moins un moyen validé par Rewayah.

Ne pas demander à cette étape : - numéro de compte ou IBAN ; - numéro
complet de portefeuille mobile ; - identifiants bancaires ; - codes,
mots de passe ou informations d'authentification.

Les coordonnées financières personnelles sont collectées uniquement au
moment opérationnel approprié, via un parcours sécurisé.

### 4.3 Classement et décision

La logique doit distinguer :

**Critère éliminatoire** - aucune méthode de paiement compatible
disponible ou confirmable pour ce candidat.

**Critère préférentiel** - compte bancaire compatible disponible, à
privilégier à qualité et adéquation comparables.

**Autres méthodes recevables** - portefeuille mobile ou autre canal
explicitement validé pour le pays et le compte marchand Rewayah.

La préférence bancaire ne doit pas annuler une meilleure adéquation
pédagogique ou professionnelle. Elle peut servir de critère secondaire
de départage, selon une règle transparente définie par la direction. Ne
pas afficher de score opaque ni éliminer automatiquement une candidature
sur un score.

### 4.4 Matrice de disponibilité des moyens

Le compte marchand pawaPay de Rewayah est indiqué par le directeur comme
confirmé et utilisable. Ne pas recommencer la procédure de validation
générale du compte.

En revanche, la couverture effective des méthodes doit être configurée à
partir des capacités de décaissement réellement activées pour Rewayah.
Ne pas supposer que tous les opérateurs sont disponibles dans tous les
pays.

Une matrice administrable ou référentielle doit contenir, selon les
capacités existantes : - pays ; - méthode ; - opérateur ; - type de
décaissement ; - état de disponibilité : confirmé, en vérification,
indisponible ; - date de vérification et responsable ; - notes ou
restrictions opérationnelles.

Les candidats ne doivent voir que les options confirmées. Une méthode «
en vérification » ne peut pas servir de preuve d'éligibilité au vivier.
L'administration et la comptabilité doivent pouvoir réviser la matrice
sans modifier les critères génériques de tous les types de candidature.

Les pays et opérateurs à examiner comprennent notamment le Nigeria, la
Côte d'Ivoire et le Sénégal, avec vérification des virements bancaires
et des options mobile money applicables. Ne pas présenter une méthode
comme garantie sur la seule base d'une liste marketing publique.

------------------------------------------------------------------------

## 5. Engagement religieux et valeurs de Rewayah

Le cadre religieux et pédagogique doit être annoncé avant la fin de la
préqualification, et accepté explicitement avant l'accès à la salle 2.

### Texte proposé

> **Engagement religieux, pédagogique et professionnel**
>
> Rewayah Academy est une institution d'enseignement du Coran et des
> valeurs islamiques. Ses enseignants sont tenus de respecter le Coran,
> la Sunna et le cadre religieux et pédagogique adopté par l'académie,
> notamment le respect des Compagnons du Prophète Muhammad ﷺ, en
> particulier Abou Bakr, Omar, Othman et Ali, qu'Allah les agrée.
>
> En poursuivant ma candidature, je confirme avoir pris connaissance de
> ce cadre et m'engage à le respecter dans mes enseignements, mes
> communications, mon comportement professionnel et toute activité menée
> au nom de Rewayah Academy.
>
> Je certifie que les informations et déclarations fournies dans le
> cadre de ma candidature sont sincères et exactes. Je comprends que
> toute fausse déclaration substantielle, tout manquement grave à mes
> engagements ou tout comportement incompatible avec les obligations
> pédagogiques et professionnelles de l'académie peut entraîner le refus
> de ma candidature, la suspension de ma participation ou la fin de ma
> collaboration, selon la situation et les règles applicables.
>
> Rewayah Academy se réserve le droit de prendre toute mesure
> appropriée, y compris d'engager les démarches légales permises par la
> législation applicable, lorsque des faits vérifiables le justifient,
> dans le respect des droits de chaque partie.
>
> Je confirme avoir compris ces exigences et accepte qu'elles
> constituent une condition de ma candidature et, le cas échéant, de ma
> collaboration avec Rewayah Academy.

Le texte doit être validé juridiquement avant publication. Les décisions
doivent reposer sur des éléments pertinents et vérifiables, une
procédure humaine et des motifs traçables, pas sur des rumeurs ou des
suppositions. Enregistrer la version du texte accepté, la date et
l'identité de la candidature.

Pour les autres types de candidature, l'engagement doit être
configurable selon le rôle. Ne pas imposer automatiquement le texte
spécifique aux enseignants à chaque candidat, sans décision explicite de
la direction.

------------------------------------------------------------------------

## 6. Entretiens et CTA de visioconférence

Dans la vue des candidats concernés par un entretien, le nom ouvre le
dossier du candidat. Un CTA séparé et immédiatement visible permet de
planifier ou rejoindre la visioconférence. Ne pas faire dépendre l'accès
à la visio du clic sur le nom.

États attendus : - **À planifier** : « Planifier un entretien ». -
**Planifié** : date, heure et fuseaux clairement affichés ; « Voir les
détails ». - **Session disponible** : CTA « Rejoindre la visio » au
moment autorisé par le système existant. - **En cours** : accès immédiat
à la session. - **Terminé** : résultat, compte rendu ou action de
suivi. - **Annulé / manqué** : état explicite et action de
reprogrammation. - **Lien absent / indisponible** : explication et
solution de secours, sans bouton inopérant.

L'administration doit voir le statut, la date, l'intervieweur, la durée
si disponible, le résultat et les actions restantes. Les informations
sensibles du candidat ne doivent pas être exposées dans une vue de
session non autorisée.

Avant d'ajouter une intégration, Claude doit auditer les mécanismes de
visioconférence déjà présents et proposer la solution la plus simple
réutilisant l'existant. Aucune refonte LiveKit n'est autorisée dans le
cadre actuel.

------------------------------------------------------------------------

## 7. Confidentialité, permissions et séparation des candidats

-   Un candidat ne voit que sa propre candidature, ses documents, ses
    entretiens et les communications qui lui sont destinées.
-   Aucune messagerie entre candidats et aucune liste de candidats
    visible publiquement.
-   Les messages de l'académie sont individuels ou segmentés sans
    divulguer les coordonnées d'autres personnes.
-   Les équipes internes n'accèdent qu'aux dossiers et champs
    nécessaires à leurs responsabilités.
-   La séparation femmes/hommes, si elle est appliquée au processus,
    doit être cohérente dans les données, les requêtes et les
    autorisations réelles. Un simple masquage visuel n'est pas une
    protection.
-   Les pièces KYC et données sensibles ne doivent pas être exposées
    dans les tableaux de liste ou les exports ordinaires.
-   Les changements de statut, décisions, accès exceptionnels et actions
    groupées doivent être traçables.
-   Le refus doit avoir un motif interne documenté ; le message envoyé
    au candidat doit rester professionnel et ne pas exposer de notes
    internes confidentielles.

Toute règle de sécurité nécessitant un changement backend doit être
inscrite comme dépendance et soumise à autorisation, pas simulée comme
si elle était sécurisée par le frontend.

------------------------------------------------------------------------

## 8. Administration, recherche et opérations à volume élevé

### 8.1 Liste de candidatures

La vue d'administration doit permettre : - recherche par nom, email,
identifiant de candidature et, selon les permissions, téléphone ; -
filtres combinables : type, étape, statut, pays, compétences,
disponibilité, KYC, paiement compatible, entretien, date et responsable
; - tri par date, étape, adéquation et priorité ; - sauvegarde des
filtres si une capacité équivalente existe déjà ; - pagination ou
chargement progressif adapté au volume ; - accès rapide au dossier, à
l'entretien et à l'historique.

### 8.2 Actions groupées

Les actions groupées doivent : - afficher le nombre et la liste des
candidatures ciblées ; - présenter les effets avant confirmation ; -
signaler les candidats non éligibles et pourquoi ; - demander une
confirmation explicite pour une action sensible ; - rapporter les
réussites et échecs individuels ; - éviter qu'un échec partiel fasse
perdre ou écrase l'état des autres dossiers.

Ne pas permettre de confirmer en masse un candidat dont les prérequis ne
sont pas tous satisfaits.

### 8.3 Historique et alertes

Tracer au minimum : - ancien et nouveau statut ; - auteur et horodatage
; - motif et commentaire si nécessaire ; - décision d'entretien ; -
acceptation de l'engagement et version ; - changements des contrôles
d'éligibilité ; - erreurs d'import et corrections.

Montrer les dossiers bloqués, les entretiens en retard, les informations
manquantes et les candidats confirmés mais temporairement indisponibles,
sans les confondre.

------------------------------------------------------------------------

## 9. Import contrôlé de Google Sheets

L'import initial des quelque 400 candidatures existantes doit être une
opération contrôlée, pas une création silencieuse de comptes.

Étapes UX : 1. sélectionner le fichier ou la source autorisée ; 2.
afficher l'aperçu des lignes ; 3. associer les colonnes source aux
champs cibles ; 4. détecter les doublons probables et les lignes
incomplètes ; 5. présenter les erreurs et avertissements avant import ;
6. confirmer le nombre de candidatures nouvelles, existantes, ignorées
et à corriger ; 7. lancer l'import seulement après validation ; 8.
produire un rapport final avec les erreurs ligne par ligne.

Conserver l'identifiant ou la référence source quand elle existe, pour
permettre la réconciliation. Ne jamais fusionner automatiquement deux
personnes sur une simple similarité de nom. Ne pas activer un compte
opérationnel, valider un KYC ou promouvoir une candidature vers une
salle supérieure à la suite d'un import.

Si le backend d'import n'existe pas ou n'est pas autorisé dans cette
phase, préparer le parcours frontend et documenter le contrat attendu
sans simuler une importation réelle.

------------------------------------------------------------------------

## 10. Visuels et design system

Les maquettes et l'implémentation doivent suivre la Bible Frontend/UI/UX
Rewayah V2 et les tokens existants. Ne pas inventer de nouveaux tokens.

Exigences : - DM Sans pour les titres ; Plus Jakarta Sans pour le reste,
conformément aux règles existantes. - Responsive réel : desktop large,
tablette et mobile, sans simple agrandissement d'une interface mobile. -
Support des thèmes clair et sombre. - Hiérarchie visuelle stable entre
statut, blocages, prochaines actions et données secondaires. - Les états
critiques ne reposent jamais uniquement sur la couleur. - États de
chargement, vide, erreur, hors ligne/dégradé, succès, accès refusé et
données partielles. - Navigation clavier, focus visible, libellés
accessibles, tailles de cible et contrastes conformes aux standards
appliqués par le projet. - Pas de PII superflue dans les tableaux. - Les
salles peuvent être présentées sous forme de vues de pipeline, colonnes
ou filtres selon le pattern déjà présent ; ne pas imposer un kanban si
un pattern Rewayah existant est meilleur. - Les listes de candidats
doivent rester efficaces à plusieurs centaines d'entrées et utilisables
avec des filtres combinés. - Les CTA d'entretien doivent être
immédiatement identifiables dans la vue de la salle d'entretien. - Les
visuels doivent montrer les états réels et les cas d'erreur, pas
seulement le scénario idéal.

Aucun visuel généré ne remplace la spécification des interactions et
états. Les composants doivent être documentés pour leur adaptation au
code existant.

------------------------------------------------------------------------

## 11. États UX obligatoires

Chaque écran ou composant métier doit documenter les états pertinents
: - initial / chargement ; - données présentes ; - aucun résultat ; -
recherche sans résultat ; - données partielles ; - erreur de validation
; - erreur serveur ou indisponibilité de dépendance ; - accès interdit
; - action en cours ; - succès ; - échec partiel d'action groupée ; -
candidature bloquée avec raison ; - candidature en pause ; - candidat
retiré ou refusé ; - entretien annulé, manqué ou sans lien ; - statut de
paiement inconnu, compatible ou incompatible.

Un état ne doit jamais donner l'impression qu'une action a réussi avant
la confirmation réelle du système.

------------------------------------------------------------------------

## 12. Revue critique obligatoire par Claude Code

**Cette revue est une étape bloquante avant toute implémentation.**
Claude doit s'appuyer sur le dépôt et le contexte d'implémentation les
plus récents, et non uniquement sur ce document.

### 12.1 Audit préalable

1.  Lire les instructions du dépôt, la Bible Frontend Rewayah V2, les
    specs métier actuelles, les décisions et les contrats pertinents.
2.  Cartographier les écrans, routes, modèles, enums, composants et
    mécanismes déjà disponibles pour candidatures, KYC, validation
    administrative, enseignants, comptes, entretiens, paiements,
    recherche, permissions et affectations.
3.  Distinguer les éléments confirmés par le code, les éléments
    documentés mais non vérifiés, et les hypothèses.
4.  Repérer les doublons et proposer les extensions minimales des
    capacités existantes.
5.  Vérifier que le modèle générique n'ajoute pas de complexité sans
    bénéfice réel et que les spécificités enseignant restent
    configurables.

### 12.2 Scénarios à examiner

Claude doit revoir au minimum les scénarios suivants et en ajouter s'il
en découvre d'autres : - candidature complète ou partielle ; - doublon à
l'import ; - candidat qui ne répond pas ; - KYC absent, en attente,
refusé ou expiré ; - engagement non accepté ; - candidat sans compte
bancaire mais avec portefeuille mobile compatible ; - candidat avec
compte bancaire mais méthode non compatible avec le pays ; - aucune
méthode de paiement confirmée ; - entretien à planifier, annulé, manqué,
en cours ou terminé ; - visio sans lien valide ; - décision positive
avec un prérequis manquant ; - enseignant confirmé mais indisponible ; -
profil suspendu après confirmation ; - réactivation après résolution du
blocage ; - affectation déjà occupée ou conflit de disponibilité ; -
changement d'un critère de recrutement après l'arrivée de candidatures
; - modification de la matrice de paiement ; - action groupée
partiellement échouée ; - accès à un dossier ou document sans permission
; - vue desktop, tablette et mobile ; - états de chargement, vide,
erreur et hors ligne.

### 12.3 Livrable de revue avant codage

Claude doit produire : - cartographie de l'existant réutilisable ; -
écarts entre le dépôt, les specs existantes et ce document ; - doublons,
risques, scénarios manquants et dépendances ; - matrice de transitions
et règles de blocage ; - alternatives étudiées et recommandation
argumentée ; - décisions nécessitant l'arbitrage du directeur ; - plan
d'écrans et composants à réutiliser ; - plan de recette et de
non-régression.

**Claude ne doit pas implémenter immédiatement après lecture.** Il doit
présenter cette revue et attendre les arbitrages nécessaires. Il peut
poursuivre sans attendre uniquement sur les points déjà explicitement
décidés et sans dépendance bloquante, si le directeur l'autorise.

### 12.4 Devoir de proposition

Claude ne doit pas se limiter à exécuter littéralement la proposition si
le dépôt révèle une solution meilleure. Il doit : - signaler les
incohérences ; - proposer l'alternative la plus robuste et la plus
simple ; - expliquer le compromis et les conséquences ; - ne pas
modifier une règle métier en silence ; - ne pas supprimer de fonction
utile pour simplifier ; - ne pas étendre le périmètre technique sans
autorisation.

------------------------------------------------------------------------

## 13. Recette et critères d'acceptation

La feature ne peut être considérée comme prête que si les points
applicables sont vérifiés :

### Modèle générique

-   Un type de candidature autre qu'enseignant peut être défini sans
    copier tout le pipeline.
-   Les critères propres à un type ne s'appliquent pas aux autres.
-   Les champs et étapes apparaissent au bon moment.
-   Les données postérieures à la sélection ne sont pas exigées
    prématurément.

### Salle 3 enseignant

-   Impossible d'entrer en salle 3 avec KYC non validé.
-   Impossible d'entrer en salle 3 sans décision finale et contrôles
    obligatoires.
-   Impossible d'entrer en salle 3 si aucune méthode de paiement
    compatible n'est confirmée.
-   L'absence de compte bancaire ne bloque pas si une méthode
    alternative compatible est confirmée.
-   À qualité et adéquation comparables, la préférence bancaire peut
    servir de critère secondaire documenté.
-   Les coordonnées financières personnelles ne sont pas exigées avant
    le démarrage effectif des cours.
-   Un profil confirmé mais indisponible reste distingué d'un profil
    prêt à être affecté.

### Entretiens

-   Le nom ouvre le dossier et un CTA séparé ouvre la planification ou
    la session.
-   Le CTA respecte l'état réel de l'entretien.
-   Un lien manquant ne produit pas une action silencieusement
    défaillante.
-   Le compte rendu et la décision sont traçables.

### Confidentialité et administration

-   Un candidat ne peut pas consulter les dossiers d'autres candidats.
-   Les documents KYC ne sont pas exposés dans les vues de liste.
-   Les actions groupées présentent leur portée et gèrent les erreurs
    partielles.
-   Les décisions sensibles sont traçables.
-   L'import ne crée pas automatiquement de comptes actifs ni ne valide
    des contrôles.

### Qualité UI

-   Les écrans sont cohérents avec la Bible et les tokens existants.
-   Les états loading, empty, error, offline/degraded et permission
    denied sont définis.
-   Les interfaces fonctionnent en thèmes clair et sombre et aux
    largeurs supportées.
-   La navigation clavier, le focus et les libellés sont vérifiés.
-   La non-régression des fonctionnalités existantes est vérifiée.

------------------------------------------------------------------------

## 14. Ordre de travail et livrables

Ordre obligatoire : 1. Audit de l'existant dans le dépôt. 2. Revue
critique Claude Code et analyse des scénarios. 3. Arbitrage du directeur
pour les contradictions et choix ouverts. 4. Spécification verticale
consolidée à partir de cette version et de l'audit. 5. Maquettes haute
fidélité des écrans et états principaux. 6. Contrôle des maquettes et
cohérence avec le design system. 7. Handoff frontend à Claude Code. 8.
Implémentation autorisée. 9. Recette et contrôle de non-régression.

Livrables : - rapport d'audit et de revue critique ; - matrice des types
de candidature et des transitions ; - maquettes high-fi desktop,
tablette et mobile ; - inventaire des composants réutilisés et éventuels
composants à étendre ; - spécification des états UI et permissions ; -
plan de tests et rapport de recette ; - liste des dépendances backend
éventuelles, sans les modifier sans autorisation.

------------------------------------------------------------------------

## 15. Décisions déjà prises à ne pas rouvrir sans nouvelle information

1.  Le système doit s'adapter à plusieurs types de candidatures, avec
    l'enseignant comme premier cas d'usage.
2.  Les salles sont des étapes logiques du pipeline, pas des communautés
    de candidats.
3.  Pas de messagerie entre candidats.
4.  Le candidat doit connaître les conditions de paiement et le cadre
    religieux avant d'avancer dans le processus.
5.  Pour les enseignants, la salle 3 signifie prêt à être affecté : KYC
    validé, évaluations et entretien terminés, décision finale prise et
    moyen de paiement compatible confirmé.
6.  Les coordonnées financières personnelles ne sont demandées qu'au
    moment opérationnel approprié, après le démarrage effectif des
    cours.
7.  Un compte bancaire est une préférence de classement, pas un critère
    éliminatoire. L'absence de compte bancaire ne doit pas exclure un
    candidat qui dispose d'une méthode de paiement alternative
    compatible.
8.  Le CTA de visioconférence doit être accessible directement dans la
    vue d'entretien de chaque candidat, séparément du lien vers son
    dossier.
9.  Les mécanismes KYC, validation administrative, profils,
    affectations, recherche et visioconférence existants doivent être
    audités et réutilisés.
10. Claude doit conduire une revue critique obligatoire avant
    l'implémentation et proposer une meilleure alternative lorsqu'elle
    est justifiée.
11. Phase actuelle frontend only ; aucun changement
    backend/Supabase/RLS/RPC/migration/serveur/LiveKit sans demande
    explicite.

**Fin de la spécification.**

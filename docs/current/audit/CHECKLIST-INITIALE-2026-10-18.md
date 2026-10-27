# REWAYAH ACADEMY

# CHECKLIST MAÎTRE D'AUDIT DE CONFORMITÉ SANS RÉGRESSION

## Document de passation à Claude Code

**Version :** 1.0\
**Date de préparation :** 18 octobre 2026\
**Objet :** auditer l'application réellement existante, réconcilier les
décisions historiques et récentes, récupérer les travaux dispersés, puis
corriger uniquement les écarts prouvés.\
**Statut :** mandat d'audit et de recette. Ce document n'est ni une
preuve que l'application est conforme, ni une autorisation de refonte,
de migration, de fusion ou de déploiement.

------------------------------------------------------------------------

# 0. MANDAT IMPÉRATIF

## 0.1 Résultat recherché

Amener Rewayah au niveau de conformité vérifiable le plus complet
possible avec **les décisions produit effectivement en vigueur**, les
spécifications actives et les contrats techniques applicables, sans
supprimer, dégrader, remplacer ou réinventer une capacité déjà validée.

Le travail doit distinguer et prouver :

1.  ce qui a été décidé ;
2.  ce qui est spécifié ;
3.  ce qui existe dans le code ;
4.  ce qui est relié au routeur et aux parcours ;
5.  ce qui fonctionne réellement ;
6.  ce qui est testé ;
7.  ce qui est livré dans l'environnement visé ;
8.  ce qui reste inconnu ou bloqué.

Une fonctionnalité n'est pas « terminée » parce qu'un widget existe,
qu'un écran est joli, qu'un test isolé passe ou qu'un rapport précédent
l'a déclarée terminée.

## 0.2 Règle de non-régression produit

**Ne jamais utiliser une ancienne spécification pour annuler une
décision plus récente prise par le directeur avec Claude ou un autre
agent.**

Les anciens documents sont des sources de traçabilité et de découverte
des fonctions oubliées. Ils ne constituent pas automatiquement la vérité
produit actuelle.

Avant toute modification, rechercher les décisions ultérieures qui
peuvent avoir changé : - les tarifs, remises, exemples, simulations,
contrats et calculs ; - les libellés, titres, CTA, textes d'aide,
erreurs et notifications ; - l'enregistrement audio ou audiovisuel, ses
déclencheurs, son stockage et sa disponibilité ; - les règles de classe,
groupes, horaires, capacités, admission et diagnostic ; - les
permissions, rôles, capacités temporaires, observation, évaluations et
jury ; - les parcours, routes, navigation, shell et composants ; - les
fonctions de recherche et de communication ; - les visuels, tokens,
thèmes et textes du site public ; - toute autre décision explicitement
révisée après les documents de référence historiques.

Si une décision récente a clos un arbitrage, **ne pas le rouvrir** au
motif qu'un ancien fichier dit autre chose. Si la preuve de la décision
récente n'est pas accessible ou si deux sources récentes se
contredisent, ne pas deviner : consigner le conflit, les sources exactes
et son impact, puis poursuivre les tâches indépendantes.

## 0.3 Règle de récupération avant reconstruction

Pour chaque fonction absente de l'écran observé : 1. chercher dans la
branche courante ; 2. chercher dans toutes les branches distantes et
locales disponibles ; 3. examiner commits, PR, worktrees, stash et
changements non commités ; 4. rechercher les anciens composants,
services, routes, ports, tests, migrations et contrats associés ; 5.
vérifier si le code est présent mais non routé, non appelé, masqué par
une condition, désactivé par un flag, déconnecté de son service,
inaccessible par permission ou cassé par une régression ; 6.
réutiliser/raccorder le travail existant si cela reste compatible avec
la décision actuelle ; 7. reconstruire uniquement après avoir prouvé que
la capacité manque réellement ou qu'elle est irrécupérable sans risque
disproportionné.

**Interdiction de créer une deuxième version d'une fonction avant
d'avoir recherché la première.** Préserver les travaux des autres agents
et toutes les branches/worktrees jusqu'à inventaire et décision
explicite.

## 0.4 Périmètre technique et cohabitation

Suivre la décision de cohabitation réellement active dans le dépôt,
notamment `docs/orchestration/COHABITATION.md` si elle est toujours
applicable. Le mandat frontend de Claude ne lui donne pas une
autorisation implicite de modifier le backend.

À respecter : - préserver l'application Flutter, le routeur, les
services, les composants, les tokens et les moteurs existants ; - ne pas
refaire l'authentification, la navigation, la classe LiveKit, les
modèles ou le design system sans preuve d'un défaut nécessitant une
correction ciblée ; - ne pas modifier les migrations, RLS, RPC, Edge
Functions, schémas distants, données de production ou le cœur LiveKit
hors mandat explicite et ownership autorisé ; - ne pas faire de
push/merge vers `main`, déploiement, publication, migration distante,
suppression de branche/worktree ou opération destructive sans
autorisation explicite ; - si un contrat backend manque, documenter le
contrat manquant pour son propriétaire et afficher une indisponibilité
honnête côté frontend. Aucun faux succès, fixture utilisée comme donnée
réelle ou hack de permission.

Le référentiel maître d'audit pré-production peut inclure des contrôles
techniques transverses. Leur présence dans la checklist ne constitue pas
une autorisation de modifier le backend ou la production.

------------------------------------------------------------------------

# 1. SOURCES ET HIÉRARCHIE DES DÉCISIONS

## 1.1 Inventaire préalable obligatoire

-   [ ] Lire entièrement `CLAUDE.md` et les instructions de projet
    réellement chargées.
-   [ ] Lire les documents actifs de `docs/current/`, en commençant par
    `00_LIRE_D_ABORD.md`.
-   [ ] Lire la feuille de cohabitation/orchestration actuelle et
    identifier l'agent propriétaire de chaque zone.
-   [ ] Lire le dernier cahier consolidé daté du 12 octobre 2026 :
    `REWAYAH_SPECIFICATIONS_FINALES_LOTS_RESTANTS_2026-10-12.md`, puis
    vérifier s'il a été supersédé après cette date.
-   [ ] Lire `REWAYAH_AUDIT_PREPRODUCTION_2026.md`, mais ne pas
    reprendre aveuglément les contradictions qui y étaient encore
    ouvertes à sa date de rédaction.
-   [ ] Lire les spécifications verticales et décisions métier les plus
    récentes, pas seulement les documents globaux.
-   [ ] Lire les derniers rapports d'agents, PR, commits et changements
    depuis le dernier audit connu.
-   [ ] Chercher les décisions du directeur dans les conversations
    accessibles, les notes, issues/PR et documents du dépôt.
-   [ ] Identifier les documents marqués `PROPOSITION`, `À VALIDER`,
    `BROUILLON`, `ARCHIVÉ`, `REMPLACÉ`, `EN VIGUEUR` ou équivalent.
-   [ ] Distinguer la date de création du document de la date de la
    décision qu'il contient.
-   [ ] Noter les sources inaccessibles au lieu de prétendre les avoir
    consultées.

## 1.2 Hiérarchie de réconciliation

Utiliser la hiérarchie suivante comme méthode d'enquête, et non comme
mécanisme aveugle :

1.  Décision explicite la plus récente du directeur, retrouvée avec sa
    source/date/contexte.
2.  Registre de décisions actif du dépôt, ADR et décisions métier
    datées, sous réserve de toute décision postérieure.
3.  Spécification active la plus récente du domaine concerné.
4.  Contrat technique réel et configuration active, pour déterminer ce
    que le système peut faire et ce qui est autorisé.
5.  Code, tests et comportement observé, qui prouvent l'implémentation
    mais ne remplacent pas une décision produit.
6.  Spécifications plus anciennes, maquettes historiques, prompts
    archivés et rapports précédents, uniquement pour la traçabilité et
    la recherche de capacités oubliées.

Si deux sources de niveau comparable se contredisent, utiliser la date
et la preuve de décision explicite. Ne pas déduire qu'un fichier est
prioritaire uniquement parce que son nom contient « final », « master »,
« canonical » ou « V2 ».

## 1.3 Registre de décisions à produire

Créer ou mettre à jour un registre unique, diffable, sans dupliquer
toute la documentation. Chaque décision doit comporter :

-   ID stable ;
-   domaine ;
-   formulation exacte de la règle actuelle ;
-   statut : `EN_VIGUEUR`, `REMPLACÉE`, `À_ARBITRER`, `INACCESSIBLE`,
    `NON_CONFIRMÉE` ;
-   date de décision (si connue) et date de vérification ;
-   source exacte : chemin, conversation/issue/PR/commit, auteur et
    passage pertinent ;
-   ancienne règle remplacée, si applicable ;
-   périmètre affecté : rôles, écrans, composants, calculs, routes,
    services, textes ;
-   tests qui doivent la protéger ;
-   décision/autorisation requise, seulement si un vrai conflit non
    résolu subsiste.

Ne jamais écrire une valeur inconnue comme si elle était validée. Ne pas
rouvrir un arbitrage clos.

------------------------------------------------------------------------

# 2. REGISTRE DES SUJETS À RISQUE DE RETOUR EN ARRIÈRE

Ces sujets doivent être comparés aux sources les plus récentes. Les
exemples ci-dessous sont des repères de recherche, pas une permission
d'ignorer une décision ultérieure.

## 2.1 Tarifs et remises

-   [ ] Retrouver la dernière grille de prix validée et la date d'effet.
-   [ ] Retrouver les tarifs enfants/adultes, devise, fréquence et
    périmètre exacts.
-   [ ] Retrouver la règle de remise par rang du membre, les exceptions
    et la manière dont elle s'applique au foyer.
-   [ ] Vérifier les prix affichés, calculateurs, simulations,
    onboarding, devis, factures, solde, finance, rapports et
    notifications.
-   [ ] Vérifier qu'aucune ancienne grille V3 du 30 septembre ou règle
    antérieure ne reste utilisée par un écran ou un test.
-   [ ] Vérifier que les textes marketing et les calculs contractuels ne
    se contredisent pas.
-   [ ] Vérifier les cas adulte/enfant mixtes, ajout ultérieur d'un
    membre, remise figée à la période, bourse, pause, entrée en cours de
    mois, annulation, avoir et remboursement selon les politiques
    actives.
-   [ ] Vérifier l'arrondi, la devise, le total avant/après remise, la
    période, les taxes et les frais éventuels.
-   [ ] Vérifier que le simulateur public est distinct du calcul
    contractuel existant lorsqu'il s'agit seulement d'une estimation.
-   [ ] Vérifier que le total est calculé à partir d'une seule règle
    partagée, et non recopié dans plusieurs composants.
-   [ ] Tester les exemples de référence et les limites (zéro élève, un
    élève, mélange, rangs 2/3/4+, valeurs invalides).
-   [ ] Ne pas inventer d'essai gratuit, d'offre, de remise, de taxe ou
    de promesse commerciale.

**Repère historique à contrôler, jamais à appliquer sans vérifier
l'absence de décision ultérieure :** le plan des visuels du site
actualisé le 9 octobre indique 50 USD par enfant et 60 USD par adulte ;
premier et deuxième membres sans remise ; troisième membre avec 5 USD de
remise ; quatrième et suivants avec 7 USD chacun. Il cite 2 enfants =
100 USD, 3 enfants = 145 USD, 4 enfants = 188 USD, 5 enfants = 231 USD.
La grille V3 du 30 septembre y est déclarée remplacée. Retrouver toute
décision postérieure avant d'en faire la vérité actuelle. En cas de
contradiction avec Finance ou une décision plus récente, ne pas trancher
au jugé.

## 2.2 Enregistrement audio/vidéo

-   [ ] Retrouver la décision la plus récente et explicite sur
    l'enregistrement, après avoir consulté les conversations, décisions,
    contrats et changements du dépôt.
-   [ ] Ne pas traiter les anciennes mentions contradictoires comme une
    décision encore ouverte si l'arbitrage a depuis été clos.
-   [ ] Déterminer le comportement actuellement décidé : types de séance
    concernés, déclenchement, contrôle utilisateur/enseignant,
    indicateur visible, arrêt, erreurs, accès, conservation, suppression
    et exceptions, seulement selon les sources réelles.
-   [ ] Comparer la décision avec l'UI, les services, les événements, le
    code LiveKit/Egress et les tests réellement présents.
-   [ ] Vérifier que les commandes visibles correspondent au vrai
    comportement et aux permissions.
-   [ ] Vérifier les états : indisponible, autorisation manquante,
    démarrage en cours, actif, arrêt en cours, échec, reconnexion,
    séance terminée.
-   [ ] Vérifier les textes d'information et de consentement seulement
    selon la politique actuelle ; ne pas en inventer.
-   [ ] Vérifier l'absence d'enregistrement caché ou de capture locale
    non décidée.
-   [ ] Vérifier que les enregistrements existants ne sont pas
    réimplémentés sous une autre forme et que le flux actif de stockage
    n'est pas remplacé.
-   [ ] Vérifier que les durées de rétention et règles de
    gel/suppression sont celles effectivement décidées.
-   [ ] Vérifier l'impact sur les mineurs et la confidentialité selon
    les décisions juridiques/produit actives.
-   [ ] Si la dernière décision ne peut pas être retrouvée, classer
    `À_ARBITRER` et ne pas réactiver une ancienne politique par défaut.

## 2.3 Libellés, contenus et terminologie

-   [ ] Construire l'inventaire des textes visibles depuis le code et
    les ressources de localisation.
-   [ ] Comparer chaque libellé important aux décisions/maquettes/specs
    récentes.
-   [ ] Rechercher les anciens titres, CTA, statuts, messages d'erreur,
    textes d'aide, notifications, emails et contenus publics.
-   [ ] Repérer les formulations interdites, notamment l'ancien libellé
    « Cours en cours » lorsqu'il est encore présent dans le contexte où
    il a été rejeté.
-   [ ] Respecter la terminologie validée : `Classe`, `Sayyid`,
    `Sayyida`, `Interface guidée`; employer « En séance » ou « Séance en
    direct » selon le contexte.
-   [ ] Respecter DM Sans pour les titres français, Plus Jakarta Sans
    pour les autres textes concernés, et préserver la police arabe/le
    rendu coranique existants.
-   [ ] Vérifier les traductions et pluralisations sans changer le sens
    métier.
-   [ ] Vérifier qu'un statut technique n'est pas traduit en résultat
    métier non confirmé.
-   [ ] Vérifier que les erreurs indiquent une action utile, sans
    exposer les données sensibles.
-   [ ] Ne pas réécrire massivement les textes simplement pour
    uniformiser le style ; préserver les formulations récentes
    approuvées.

## 2.4 Parcours, navigation et fonctions déjà développées

-   [ ] Inventorier les routes réellement enregistrées et leur
    destination.
-   [ ] Inventorier les actions et points d'entrée : accueil, listes,
    cartes, menus, notifications, recherche, liens profonds et CTA.
-   [ ] Vérifier qu'un même besoin n'a pas été implémenté à plusieurs
    endroits avec des comportements différents.
-   [ ] Vérifier les écrans existants dans les branches spécialisées
    avant de déclarer une fonction absente.
-   [ ] Vérifier le câblage réel entre UI, ViewModel, port, service,
    réponse et états.
-   [ ] Vérifier les fonctionnalités cachées derrière un feature flag,
    une permission, un état de dossier ou un paramètre.
-   [ ] Vérifier les destinations qui existent mais ne sont accessibles
    par aucun chemin utilisateur.
-   [ ] Vérifier les actions visibles sans destination, sans effet ou
    avec une fausse confirmation.
-   [ ] Vérifier que le retour conserve contexte, filtre, sélection,
    brouillon et position lorsque requis.
-   [ ] Vérifier que le changement de profil/enfant n'autorise jamais
    une réponse asynchrone de l'ancien contexte à contaminer le nouveau.
-   [ ] Ne pas créer un deuxième écran ou module quand le besoin doit
    enrichir un écran existant.

------------------------------------------------------------------------

# 3. INVENTAIRE GIT ET RÉCUPÉRATION

## 3.1 État initial en lecture seule

-   [ ] Enregistrer dépôt, remote(s), branche courante, HEAD, SHA
    complet, statut de travail et fichiers non suivis.
-   [ ] Enregistrer `git status --short --branch`,
    `git log --graph --decorate --oneline --all`, branches locales et
    distantes.
-   [ ] Inventorier toutes les branches, y compris les branches
    spécialisées dont le nom suggère un rôle ou une verticale.
-   [ ] Inventorier tous les worktrees et leur branche/SHA.
-   [ ] Inventorier les PR ouvertes, fermées, fusionnées, les commits
    non fusionnés et les changements en attente.
-   [ ] Inspecter les stashes sans les appliquer ni les supprimer.
-   [ ] Repérer les commits orphelins ou références utiles accessibles,
    sans réécriture d'historique.
-   [ ] Rechercher les fichiers modifiés par d'autres agents et
    consulter la feuille de cohabitation.
-   [ ] Produire une sauvegarde/inventaire approprié avant toute action
    à risque.
-   [ ] Ne pas supprimer, nettoyer, rebase, reset, cherry-pick ou
    fusionner avant que les changements concernés soient compris et que
    l'action soit autorisée.

## 3.2 Recherche d'une fonction

Pour chaque fonction déclarée absente : - \[ \] rechercher son nom
produit, ses anciens libellés, IDs de spécification et noms techniques
; - \[ \] rechercher les widgets/pages, routes, ViewModels, ports,
services, modèles, tests et commits liés ; - \[ \] comparer les versions
sur les branches pertinentes ; - \[ \] lire les diffs et leurs tests,
pas uniquement les messages de commit ; - \[ \] vérifier si le travail
est complet, partiel, obsolète, incompatible ou simplement non raccordé
; - \[ \] documenter le meilleur emplacement d'origine, les dépendances
et les risques de récupération ; - \[ \] privilégier une récupération
ciblée plutôt qu'une copie intégrale de branche ; - \[ \] éviter
d'écraser les changements plus récents de la branche cible ; - \[ \] si
une fonction a été remplacée volontairement, documenter le lien avec la
décision de remplacement.

## 3.3 Matrice de provenance obligatoire

Pour chaque lot/fonction, consigner :

`ID exigence | décision actuelle | source/date | rôle | écran/route | état initial | fichier/symbole | branche/SHA d’origine | dépendances/port | statut de raccordement | tests | preuve | delta nécessaire | risque de régression | propriétaire`

Ne pas conclure qu'un travail est récupérable sans examiner son diff et
sa compatibilité avec la décision actuelle.

------------------------------------------------------------------------

# 4. MATRICE DE STATUT ET CRITÈRES DE PREUVE

Utiliser un statut explicite pour chaque exigence :

-   `CONFORME` : comportement prouvé par code atteignable et tests
    pertinents réussis.
-   `PARTIEL` : une partie existe mais une condition, un état, un chemin
    ou un test manque.
-   `NON_CONFORME` : preuve d'un écart par rapport à la décision
    actuelle.
-   `ABSENT` : recherche dans les emplacements/branches pertinents
    effectuée et aucun travail réutilisable trouvé.
-   `NON_ROUTÉ` : code existant, mais inaccessible dans le parcours.
-   `NON_RACCORDÉ` : UI présente, mais service/port/contrat non relié.
-   `NON_TESTÉ` : code et chemin présents, mais preuve comportementale
    manquante.
-   `BLOQUÉ` : dépendance ou autorisation externe empêchant la
    vérification.
-   `À_ARBITRER` : conflit réel entre décisions actuelles non résolu.
-   `INCONNU` : preuve insuffisante.
-   `NON_APPLICABLE` : justification explicite, pas une omission.

Pour chaque exigence, fournir au moins une preuve pertinente : fichier
et symbole/lignes, SHA, route, test, capture, log expurgé, configuration
ou résultat de scénario. Un commentaire de code, une maquette ou un
rapport ancien ne prouve pas que le comportement marche.

Une fonctionnalité n'est validée que si elle est : - décidée et
compatible avec la règle active ; - implémentée ; - atteignable ; -
correctement autorisée ; - raccordée à sa source de vérité ; - correcte
dans les états normaux et d'erreur ; - accessible et responsive ; -
testée ; - non régressive ; - livrée dans l'environnement déclaré, si la
livraison fait partie du périmètre.

------------------------------------------------------------------------

# 5. CHECKLIST TRANSVERSE DE CHAQUE ÉCRAN

Appliquer cette checklist à **chaque écran, modal, panneau, menu, liste,
lecteur, formulaire et état**, pour chaque rôle concerné.

## 5.1 Identité, destination et navigation

-   [ ] L'écran possède un ID d'inventaire stable.
-   [ ] Le rôle/capability et le contexte d'accès sont documentés.
-   [ ] La route réelle et les points d'entrée sont identifiés.
-   [ ] L'écran est accessible depuis un chemin autorisé et le retour
    fonctionne.
-   [ ] Les paramètres de route et IDs sont validés.
-   [ ] Le changement de rôle, profil, foyer, enfant, classe ou session
    conserve le bon contexte.
-   [ ] Le lien profond, notification ou CTA n'expose pas un objet
    interdit.
-   [ ] Les destinations supprimées/expirées gèrent le retour sans
    boucle.
-   [ ] Les actions ne sont pas dupliquées dans plusieurs écrans sans
    raison fonctionnelle.
-   [ ] Les fonctions essentielles restent accessibles par une
    navigation stable ; les raccourcis dynamiques ne sont jamais le seul
    chemin.

## 5.2 Données et états

-   [ ] Chargement initial.
-   [ ] Chargement incrémental/pagination si applicable.
-   [ ] Succès réel confirmé par la source attendue.
-   [ ] Liste vide normale.
-   [ ] Recherche/filtre sans résultat.
-   [ ] Erreur de chargement.
-   [ ] Erreur d'action et possibilité de réessayer.
-   [ ] Hors ligne, connexion lente, timeout et reconnexion.
-   [ ] Données périmées ou statut provisoire signalés sans les
    présenter comme définitifs.
-   [ ] Permission refusée, expirée ou retirée.
-   [ ] Session expirée.
-   [ ] Donnée supprimée ou devenue inaccessible.
-   [ ] Double clic, réponse tardive et requêtes concurrentes.
-   [ ] Annulation sans perte inattendue de saisie.
-   [ ] Aucun faux succès sur simple clic ou retour navigateur.
-   [ ] Aucune fixture/donnée simulée présentée comme donnée réelle.

## 5.3 Actions et feedback

-   [ ] Chaque bouton/CTA a une action réelle et une destination
    définie.
-   [ ] Les boutons désactivés expliquent la condition si nécessaire.
-   [ ] Les actions longues ont un état de progression et empêchent les
    doubles soumissions.
-   [ ] Les mutations affichent succès seulement après confirmation
    adaptée.
-   [ ] Les actions destructrices/sensibles montrent portée, conséquence
    et confirmation selon la politique active.
-   [ ] Les erreurs conservent les saisies non sensibles.
-   [ ] Les actions qui nécessitent une permission la vérifient au
    moment de l'action, pas seulement au rendu.
-   [ ] Les actions impossibles faute de contrat sont honnêtement
    indisponibles, sans bouton fictif.
-   [ ] Les toasts/snackbars ne sont pas le seul moyen de transmettre
    une information essentielle.
-   [ ] L'action clavier, lecteur d'écran et tactile est possible.

## 5.4 UI, design system et accessibilité

-   [ ] Tokens existants réutilisés ; aucune palette parallèle inventée.
-   [ ] Composants partagés réutilisés lorsqu'ils conviennent.
-   [ ] DM Sans / Plus Jakarta Sans / police arabe existante préservées.
-   [ ] Modes clair et sombre vérifiés.
-   [ ] Responsive réel mobile, tablette et desktop.
-   [ ] Pas de layout overflow, texte coupé, bouton inaccessible ou
    contenu masqué par clavier.
-   [ ] Safe areas et orientation pertinentes vérifiées.
-   [ ] Focus visible, ordre clavier, semantics/labels et contraste
    vérifiés.
-   [ ] Agrandissement du texte et mouvement réduit pris en compte.
-   [ ] Les états ne reposent pas uniquement sur la couleur ou une
    animation.
-   [ ] Les médias et contenus ont un texte alternatif pertinent.
-   [ ] Le mode `Interface guidée` simplifie la présentation sans
    modifier les permissions ni supprimer des fonctions nécessaires.
-   [ ] La maquette est une référence de composition, pas une source de
    données métier ou de permissions.

## 5.5 Vérification visuelle

-   [ ] Capture desktop représentative (par exemple 1440 × 900).
-   [ ] Capture mobile représentative (par exemple 390 × 844).
-   [ ] Tablette vérifiée (par exemple 768 px).
-   [ ] Clair/sombre et états importants vérifiés.
-   [ ] Comparaison aux high-fi réellement approuvées et à la version de
    tokens active.
-   [ ] Les écarts sont classés : décision, bug, adaptation responsive
    justifiée ou défaut visuel.
-   [ ] Aucun visuel de référence ancien ne réintroduit un libellé,
    tarif ou comportement remplacé.

------------------------------------------------------------------------

# 6. CHECKLIST PAR RÔLE ET DOMAINE

**Important :** les listes ci-dessous sont des points de contrôle de
couverture. Elles ne déclarent pas que chaque fonction est absente ou
doit être reconstruite. Pour chaque item, rechercher l'existant et
déterminer son état réel.

## 6.1 Public, landing page et inscription

-   [ ] Routes publiques, redirections langue et navigation réelle.
-   [ ] Accueil, Cours, Familles, Tarifs, Articles/FAQ, connexion et
    pages légales prévues dans le périmètre actif.
-   [ ] Header et footer conformes aux décisions visuelles/textuelles
    les plus récentes.
-   [ ] Logo SVG officiel existant utilisé avec proportions/viewBox
    préservés.
-   [ ] Les contacts publics utilisent les alias validés pour le sujet ;
    aucune adresse privée de connexion n'est exposée.
-   [ ] Aucun faux témoignage, compteur, disponibilité, partenariat
    bancaire ou label non prouvé.
-   [ ] Les promesses publiques correspondent aux capacités réellement
    disponibles.
-   [ ] Tarifs et exemples issus de la politique tarifaire active.
-   [ ] Simulateur de prix : nombre d'enfants/adultes, validation,
    calcul exact, mise à jour immédiate, total et explication des
    règles, cas limites et accessibilité.
-   [ ] Le simulateur d'estimation n'altère pas le calcul
    contractuel/Finance existant.
-   [ ] Liens « Voir mon récapitulatif » et « Simuler mon tarif »
    pointent vers les destinations prévues par la décision active.
-   [ ] Aucun essai gratuit ou avantage inventé.
-   [ ] Parcours d'inscription : choix du foyer, adulte/enfant, compte
    existant, consentements, reprise, abandon, doublons et erreurs.
-   [ ] L'offre présente les horaires autorisés réellement publiés ; ne
    promet pas un professeur ou une classe avant confirmation.
-   [ ] Cohortes d'âge selon la politique active ; vérifier la date de
    naissance et le calcul d'âge sans seuil dupliqué.
-   [ ] Les dossiers incomplets mènent à l'étape réellement manquante.
-   [ ] Le visiteur ne peut pas lire des données privées par URL ou
    cache.
-   [ ] Les contenus légaux, confidentialité, enfants,
    annulation/remboursement et accessibilité reflètent les décisions et
    capacités réelles.
-   [ ] Le site ne présente pas les maquettes comme des captures de
    production vérifiées.
-   [ ] Les images de personnes sont les assets approuvés, sans
    extraction approximative de captures si les sources autonomes sont
    disponibles.

## 6.2 Tuteur / titulaire et foyer

-   [ ] Accueil du foyer et sélection de l'enfant actif.
-   [ ] Ajout/reprise d'un dossier sans double création.
-   [ ] Profil par enfant distinct du profil tuteur.
-   [ ] État d'admission, niveau, parcours, classe proposée/confirmée et
    étape suivante.
-   [ ] Choix de l'offre et des disponibilités selon les options
    publiées.
-   [ ] Présentation claire des jours, heures locales, fuseau, durée et
    récurrence.
-   [ ] État de la classe : intention, attente si elle existe
    réellement, proposée, confirmée, active, suspendue ou terminée selon
    le contrat actif.
-   [ ] Accès au prochain cours et à l'historique.
-   [ ] Fiche enfant : classe, enseignant, niveau, progrès, présence,
    travail et rapports autorisés.
-   [ ] Changer d'enfant ne réinitialise pas toute la navigation et ne
    mélange jamais les données.
-   [ ] Solde et historique financier par élève ; ne pas transformer le
    total du foyer en caisse commune si la règle active ne le permet
    pas.
-   [ ] Factures, paiements, remboursements, avoirs et reçus uniquement
    à partir de données réelles.
-   [ ] Afficher les statuts d'attente/échec seulement s'ils proviennent
    d'un état réel.
-   [ ] Appareils, QR/PIN, association et retrait selon le protocole
    existant.
-   [ ] Notifications ouvrent le bon enfant et le bon objet.
-   [ ] Préférences et interface guidée : choix appliqué selon le
    service actif, sans changement de permissions.
-   [ ] Observation parent : règles de durée/quotas selon la décision
    active, quota partagé entre appareils si prévu, fin effective
    d'accès, information de l'enfant, micro/caméra désactivés si exigé.
-   [ ] Le visionnage n'accorde pas de droit de parole, caméra,
    notation, jury ou accès aux résultats internes.
-   [ ] Second adulte autorisé : droits séparés et explicitement
    contrôlés, pas de copie automatique des droits du titulaire.
-   [ ] Déconnexion, récupération et changement de profil protègent les
    données privées.
-   [ ] Chaque action financière/sensible est traçable selon les
    contrats en vigueur.

## 6.3 Élève enfant - Interface guidée

-   [ ] Aucun onboarding indépendant ou permission nouvelle inventée.
-   [ ] Sélection du profil autorisé et PIN/protocole existant.
-   [ ] Accueil avec prochaine séance, état exact de disponibilité,
    préparation et accès aux supports.
-   [ ] Action Rejoindre visible uniquement si l'éligibilité réelle est
    confirmée.
-   [ ] Accès à la Classe et au support pédagogique.
-   [ ] Commandes audio/vidéo conformes aux permissions et à la décision
    d'enregistrement active.
-   [ ] Bibliothèque et lecteur du Coran accessibles selon les droits.
-   [ ] Reprise du travail/support sans perte de contexte.
-   [ ] Progression et historique personnels uniquement, avec données
    confirmées.
-   [ ] Aucun accès aux finances du foyer, documents KYC, comptes
    adultes ou données d'autres élèves.
-   [ ] Messages simples et compréhensibles, mais informations critiques
    toujours accessibles.
-   [ ] États réseau/erreur expliqués sans attribuer la faute à
    l'enfant.
-   [ ] Le retour vers le tuteur est protégé ; aucun cache d'un autre
    profil n'est exposé.
-   [ ] Le mode guidé n'est pas un rôle et ne change aucune autorisation
    serveur.

## 6.4 Élève adulte autonome

-   [ ] Accueil et prochaines séances.
-   [ ] Classes et sélection uniquement selon les possibilités réelles.
-   [ ] Planning local, reports/annulations et état exact.
-   [ ] Classe live et supports.
-   [ ] Bibliothèque, Coran, marque-pages et reprise, selon capacités
    déjà présentes.
-   [ ] Travail, consignes, progression et historique personnels.
-   [ ] Profil et préférences.
-   [ ] Paiements, solde et factures personnelles selon contrat actif.
-   [ ] Parcours autonome distinct du rôle tuteur.
-   [ ] Interface guidée possible si prévu, sans le transformer en
    enfant/tuteur.
-   [ ] Notifications et récupération d'accès.
-   [ ] Aucune donnée d'un autre adulte ou foyer accessible.

## 6.5 Enseignant

-   [ ] Onboarding, KYC et statut de dossier selon l'implémentation et
    le contrat existants.
-   [ ] Photo publique distincte de la pièce d'identité KYC.
-   [ ] Contrat, statut actif et permissions réels.
-   [ ] Accueil/journée, prochain cours et chronologie.
-   [ ] Préparation/pre-flight de séance.
-   [ ] Classes et groupes assignés, capacité et roster.
-   [ ] Remplacement exceptionnel uniquement selon règle active ; ne pas
    réaffecter silencieusement l'enseignant attitré.
-   [ ] Fiche élève contextuelle avec informations pédagogiques
    autorisées.
-   [ ] Outils pédagogiques et supports déjà existants.
-   [ ] Classe LiveKit : rejoindre/quitter, roster, présence, état
    réseau, micro/caméra, partage/support, commandes et erreurs.
-   [ ] Enregistrement : comportement exact de la dernière décision,
    indicateur, autorisation, état et stockage ; aucun retour au
    comportement ancien.
-   [ ] Rapport de fin de séance, préremplissage, sauvegarde, reprise et
    confirmation réelle.
-   [ ] Cahier de transmission et travail de suivi.
-   [ ] Disponibilités, matching et conflits d'horaire selon service
    existant.
-   [ ] Historique de séance et notes limitées aux droits.
-   [ ] Recherche d'élève/groupe dans le périmètre autorisé.
-   [ ] Paie et relevés uniquement si la verticale est activée et les
    données sont réelles.
-   [ ] Aucun écran ou bouton ne promet un paiement/rapport/notification
    qui n'a pas été effectivement traité.
-   [ ] Les outils de classe n'ont pas été recréés en doublon dans un
    autre module.

## 6.6 Classe, LiveKit, supports et présence

-   [ ] Une seule salle logique par séance selon le contrat existant.
-   [ ] Les moteurs LiveKit existants sont réutilisés ; pas de refonte
    sans mandat.
-   [ ] URL/token/capabilities fournis par le flux autorisé ; aucun
    secret serveur dans Flutter.
-   [ ] Préflight et fenêtre de rejoignement selon configuration/contrat
    actifs, pas une constante ancienne.
-   [ ] États connexion, permissions média, appareil absent, refus,
    coupure, reconnexion, timeout et sortie.
-   [ ] La reconnexion ne duplique pas la présence ni les événements.
-   [ ] Les événements de présence proviennent de la source autorisée ;
    trous de preuve signalés, pas transformés en absence.
-   [ ] Un cours non tenu n'est pas compté comme absence élève.
-   [ ] Les corrections administratives de présence sont auditées si
    cette capacité existe.
-   [ ] Roster, ordre de passage, tour, annotations, tableau, supports
    et focus sont cohérents avec la spécification active.
-   [ ] Partage d'écran/document et permission de modifier sont séparés.
-   [ ] Le mode focus n'efface pas les commandes essentielles, l'état
    réseau ou la sortie.
-   [ ] Contrôles clavier, lecteur d'écran et tactile.
-   [ ] Mobile/tablette/desktop et modes clair/sombre vérifiés.
-   [ ] Les commandes restent utilisables sur petit écran/texte agrandi.
-   [ ] Le tableau et les annotations gardent le contexte pendant le
    changement d'élève.
-   [ ] Aucune image ou page PDF ne remplace le modèle de Coran
    structuré/natif si ce dernier est le contrat actif.
-   [ ] Aucun flux d'enregistrement n'est changé sans vérifier la
    décision actuelle et le contrat réel.
-   [ ] Si une capacité dépend d'un backend non disponible, le frontend
    affiche l'état honnête et le contrat manquant.

## 6.7 Bibliothèque et lecteur du Coran

-   [ ] Bibliothèque et catégories/ressources autorisées.
-   [ ] Recherche, filtres et état sans résultat.
-   [ ] Lecteur natif/structuré conforme à la source de vérité coranique
    approuvée.
-   [ ] Récitation Hafs 'an 'Asim et contenu/version réellement validés.
-   [ ] Texte arabe, polices, direction RTL, signes diacritiques et
    rendu fidèle.
-   [ ] Navigation par sourate/verset/page selon les capacités
    actuelles.
-   [ ] Zoom, affichage plein écran mobile, marque-pages et reprise si
    déjà prévus.
-   [ ] Audio, contrôle de lecture et état de chargement/erreur.
-   [ ] Annotation pédagogique/tajwid si présente et conforme au corpus
    autorisé.
-   [ ] Ressource indisponible, offline, téléchargement et reprise.
-   [ ] Aucun PDF ou raster de page ne devient silencieusement la source
    canonique si le contrat actif impose des données structurées.
-   [ ] Pas d'invention de contenu coranique, d'annotation ou de
    correspondance de page.
-   [ ] Différencier support public, support de classe et contenu
    interne.
-   [ ] Les changements de version ne cassent pas les
    marque-pages/reprises.

## 6.8 Pédagogie, diagnostic, progression et rapports

-   [ ] Référentiel académique actif et versions publiées.
-   [ ] Parcours, niveau, objectifs, diagnostic, exceptions et
    progression selon les décisions actuelles.
-   [ ] Règle débutant : vérifier le raccourci validé et ne pas
    réintroduire un diagnostic obligatoire si la décision active le
    dispense.
-   [ ] Pour les autres niveaux, pré-diagnostic/diagnostic selon le
    contrat actif.
-   [ ] Cohortes d'âge actives et bornes vérifiées.
-   [ ] Programme, séquences et critères d'acquisition cohérents avec le
    référentiel académique.
-   [ ] Distinction entre participation, présence, récitation, maîtrise
    et évaluation.
-   [ ] Aucun score, acquis, classement ou certificat inventé.
-   [ ] Le rapport reflète les données confirmées et les permissions.
-   [ ] Les modifications de niveau/objectif sont historisées si le
    contrat le prévoit.
-   [ ] Supports, consignes et cahier de transmission raccordés au bon
    élève/classe.
-   [ ] État provisoire clairement distingué de l'état validé.
-   [ ] Erreurs de synchronisation ne détruisent pas les notes saisies.
-   [ ] Exceptions et corrections autorisées sont explicites et
    traçables.

## 6.9 Évaluations, évaluateurs, jury et attestations

-   [ ] Appliquer la spécification Évaluations V2 et ses artefacts
    prioritaires réellement actifs ; ne pas relancer une recherche
    produit déjà close.
-   [ ] Vérifier si le lot demeure frontend only conformément à la
    cohabitation active.
-   [ ] Les évaluateurs/jurés sont des capabilities/habilitations si
    c'est la règle active, pas des rôles globaux inventés.
-   [ ] Parcours proposé → candidature → occurrence planifiée → salle →
    appel → passage → évaluation → jury conditionnel → décision → suite
    pédagogique.
-   [ ] États de candidature, occurrence, présence, passage, quorum,
    résultat et contestation.
-   [ ] CTA dynamiques basés sur état réel et permissions.
-   [ ] Modes de visibilité restreinte/communautaire selon la décision
    active ; jamais d'ouverture publique à l'Internet sans décision
    explicite.
-   [ ] Visionnage/écoute n'accorde aucun droit de parler, caméra,
    noter, siéger au jury ou lire des résultats internes.
-   [ ] Gestion des mineurs, confidentialité, réactions, capacité,
    retards, pauses, absences, réseau et anti-répétition.
-   [ ] Le participant en attente n'est pas présenté comme puni
    passivement.
-   [ ] Les données internes du jury ne sont pas exposées au candidat ou
    à la communauté.
-   [ ] Attestation/certificat uniquement si la décision officielle a
    été émise et si la capacité existe.
-   [ ] Pas de faux certificat, badge ou mention institutionnelle.
-   [ ] Aucune modification backend hors mandat frontend et ownership.
-   [ ] Les états et textes ne promettent pas une décision de jury avant
    validation.

## 6.10 Contrôleur et observation

-   [ ] Mission attribuée, statut, périmètre et habilitation.
-   [ ] Accès limité aux sessions/rapports nécessaires.
-   [ ] MFA/step-up si requis par le contrat actif.
-   [ ] Observation distincte du rôle parent et de la présence
    enseignant.
-   [ ] Aucune permission supplémentaire durable créée par
    l'observation.
-   [ ] Grille d'audit, observations, signalements, rapport et
    historique.
-   [ ] Données sensibles masquées hors périmètre.
-   [ ] État de session et preuve réseau correctement représentés.
-   [ ] Contestations et corrections selon le workflow existant.
-   [ ] Aucune auto-approbation ou accès non justifié.
-   [ ] Journal des actions sensibles si prévu.
-   [ ] Les rapports internes ne sont pas visibles par les profils non
    habilités.

## 6.11 Comptable et Finance

-   [ ] Vérifier les verticales/branches spécialisées et ports CPT/FI
    avant toute reconstruction.
-   [ ] Encaissements, transactions, rapprochements, factures,
    remboursements, avoirs, payouts, clôtures, anomalies.
-   [ ] Solde individuel par élève selon le contrat ; total foyer
    informatif distinct des soldes individuels.
-   [ ] Devise, période, taux, frais, taxes et version de prix visibles
    lorsqu'ils sont pertinents.
-   [ ] Les prix/remises sont ceux de la décision active, pas une
    constante historique.
-   [ ] Le calcul du front ne remplace pas le ledger ou le résultat
    serveur.
-   [ ] Préflight des paiements/payouts et droits d'approbation selon
    les contrats existants.
-   [ ] Un payout soumis n'est pas présenté comme réussi sans preuve
    prestataire.
-   [ ] Idempotence et absence de double débit/double paiement vérifiées
    par les contrats et preuves existants.
-   [ ] Avoir, remboursement, crédit et expiration selon politique
    réelle, jamais inventée.
-   [ ] Rapprochement et drill-down vers l'écriture source.
-   [ ] Correction avec avant/après, motif et approbation si exigés.
-   [ ] Coffres et affectations existants préservés ; ne pas
    renommer/reclassifier sans source.
-   [ ] Données bancaires et moyens de paiement masqués selon
    permission.
-   [ ] Aucune action réelle de paiement sans autorisation et préflight
    requis.
-   [ ] Les simulations sont séparées des opérations réelles.
-   [ ] Écrans comptables existants récupérés depuis les branches
    dédiées, pas reconstruits à partir de zéro.

## 6.12 Administration et Direction

-   [ ] Centre de commande et compteurs liés à des destinations réelles.
-   [ ] Validation des dossiers : liste, détail, pièces, checks,
    décision, motif, activation, attente et refus.
-   [ ] Les libellés exacts des contrôles de validation viennent de la
    spécification actuelle.
-   [ ] Portrait public enseignant distinct du KYC.
-   [ ] Personnes, rôles, capabilities, délégations et statut réel.
-   [ ] Classes, créneaux, offres, capacité, affectation enseignant et
    remplacements.
-   [ ] Pédagogie, référentiels, versions, exceptions et revue qualité.
-   [ ] Finance : prix, remises, date d'effet, bourses et politiques
    selon droits.
-   [ ] Communications, annonces, Studio et recherche uniquement selon
    capacités existantes.
-   [ ] Sécurité, appareils, sessions, accès sensibles, audit et
    exports.
-   [ ] Aucun écran Settings ne devient un dépôt fourre-tout pour une
    fonction métier.
-   [ ] Les actions irréversibles présentent portée, conséquences,
    préflight et confirmation.
-   [ ] Les suggestions/raccourcis dynamiques ne remplacent pas
    l'arborescence stable.
-   [ ] Les permissions sont vérifiées au moment de l'action.
-   [ ] Recherche admin ne révèle pas KYC ou données d'une autre classe
    sans droit.
-   [ ] Aucun droit Direction/super-admin visible ne découle seulement
    d'un rôle UI.
-   [ ] Aucun compteur/rapport n'affiche des données obsolètes comme
    temps réel.

## 6.13 Messagerie, communications, notifications et recherche

-   [ ] Distinguer recherche globale d'objets autorisés et recherche de
    messages dans le module Messagerie/Studio selon la décision active.
-   [ ] Rechercher dans le dépôt la règle de recherche la plus récente
    avant de reprendre une architecture historique.
-   [ ] Recherche par rôle, domaine, filtres, pagination, absence de
    résultats et erreurs.
-   [ ] Résultats limités aux objets autorisés au moment de la requête
    et de l'ouverture.
-   [ ] Révocation de permission respectée dans les résultats/caches.
-   [ ] Pas de fuite de membres d'une autre Classe, KYC ou contenu
    privé.
-   [ ] Messagerie : fils, participants, pièces jointes, état d'envoi,
    échec, reprise et accès.
-   [ ] Les textes de messages se recherchent dans leur module si c'est
    la règle active ; ne pas les exposer globalement sans décision.
-   [ ] Notifications reflètent des événements métier réels et ouvrent
    l'objet autorisé.
-   [ ] Envoi et lecture ne sont pas annoncés avant confirmation réelle.
-   [ ] Pièce jointe supprimée ou permission retirée gérée proprement.
-   [ ] Aucune messagerie ou système de notification concurrent créé si
    le module existe.

## 6.14 Site, recrutement, publication et contenu éditorial

-   [ ] Reprendre les plans de site et visuels les plus récents et
    rechercher les décisions ultérieures.
-   [ ] Contrôler les pages réellement prévues et les routes réelles.
-   [ ] Utiliser les images originales autonomes approuvées et le SVG
    officiel.
-   [ ] Respecter le choix visuel actuel, les tokens et le fond exact
    s'il reste en vigueur.
-   [ ] Vérifier les CTA, le simulateur tarifaire et les liens
    d'inscription.
-   [ ] Les alias publics sont choisis selon l'objet (contact, support,
    recrutement, facturation) et validés.
-   [ ] Pas d'adresse privée, de secret ou de contact inventé.
-   [ ] Les textes reflètent l'offre, la durée, l'effectif, les langues
    et la fréquence actifs.
-   [ ] Pas de promesse de professeur, de place, de réservation, d'essai
    ou de partenariat non prouvée.
-   [ ] Pages légales, annulation/remboursement, confidentialité,
    cookies et accessibilité alignées sur la politique active et les
    capacités réelles.
-   [ ] Recrutement : dossier, contact, envoi, retour et statut
    honnêtes.
-   [ ] Aucun contenu de démonstration n'est confondu avec une donnée
    réelle.
-   [ ] Le déploiement public est hors périmètre sans autorisation
    explicite.

------------------------------------------------------------------------

# 7. CONTRÔLES TECHNIQUES TRANSVERSAUX À VÉRIFIER SANS DÉPASSER LE MANDAT

## 7.1 Contrats et dépendances

-   [ ] Cartographier UI → ViewModel → port → adaptateur/service →
    contrat → résultat/erreur.
-   [ ] Identifier le propriétaire de chaque port, contrat et fichier
    partagé.
-   [ ] Vérifier que les contrats réels et le code généré correspondent.
-   [ ] Vérifier les erreurs typées et les états de timeout/offline.
-   [ ] Vérifier qu'aucun fallback silencieux ne transforme une erreur
    en succès.
-   [ ] Si le backend manque, rédiger une fiche de contrat à transmettre
    à l'agent propriétaire ; ne pas bricoler une solution frontend qui
    imite la production.
-   [ ] Vérifier les feature flags et les limites de release scope.

## 7.2 Sécurité et permissions

-   [ ] Aucun secret, clé privée ou `service_role` dans Flutter, le
    dépôt, les logs ou les captures.
-   [ ] Aucun écran ne se fie à un simple masquage UI pour autoriser une
    action.
-   [ ] Vérifier la permission et la relation à l'objet pour chaque
    accès.
-   [ ] Vérifier les transitions de rôle, suspension, expiration,
    révocation et changement de foyer.
-   [ ] Vérifier les données d'enfants, KYC, paiements, enregistrements
    et messages sensibles.
-   [ ] Ne pas exposer les URL signées ou données privées dans les logs.
-   [ ] Aucun accès d'observation ne devient un accès durable.
-   [ ] Toute question backend est transmise au propriétaire sans
    modifier sa zone.

## 7.3 Performance et robustesse

-   [ ] Listes paginées/filtrées selon besoin.
-   [ ] Pas de chargement redondant évident à chaque rebuild/navigation.
-   [ ] Annulation/obsolescence des requêtes lors d'un changement de
    contexte.
-   [ ] Pas de perte de saisie sur erreur réseau.
-   [ ] Cache local cohérent avec les permissions et la révocation.
-   [ ] États offline visibles sans prétendre que l'action a été
    synchronisée.
-   [ ] Les changements ne créent pas de duplication d'événements ou de
    double soumission.
-   [ ] Vérifier la taille des écrans, le temps de rendu et les erreurs
    de console pertinents.
-   [ ] Les performances réelles restent à mesurer ; ne pas déclarer la
    charge production prouvée par des tests unitaires.

## 7.4 CI, qualité et artefacts

Selon le dépôt et la cohabitation active, vérifier sans modifier les
configurations partagées sans autorisation : - \[ \]
`dart format`/formatage selon la convention. - \[ \]
`dart analyze --fatal-infos` ou la commande canonique active. - \[ \]
`flutter test` et tests ciblés du lot. - \[ \] Tests de routes, taps et
parcours E2E lorsqu'ils existent. - \[ \] Génération/localisation
(`dart run slang`, `build_runner`) si le lot l'affecte. - \[ \]
Vérificateur des tokens, thème et conventions si présent
(`tool/verifier_jetons.dart` ou équivalent). - \[ \] Tests
visuels/captures pour les écrans touchés. - \[ \] Vérification de
non-régression du rôle précédent et des composants partagés. - \[ \]
Contrôle des dépendances et erreurs de build. - \[ \] Résultats liés au
SHA exact et à l'environnement déclaré. - \[ \] Ne pas présenter un test
local comme une preuve de staging ou de production. - \[ \] Ne pas
contourner les tests en supprimant/affaiblissant les assertions. - \[ \]
Tout échec doit être classé, attribué et expliqué.

------------------------------------------------------------------------

# 8. MATRICE DES PARCOURS DE BOUT EN BOUT

Tester chaque parcours sur données et comptes de test appropriés, sans
utiliser de données réelles d'élèves dans les fixtures.

-   [ ] Visiteur → offre → simulateur → onboarding → dossier
    créé/repris.
-   [ ] Titulaire → ajout enfant → choix du parcours → offre/créneau →
    proposition/confirmation de Classe selon workflow.
-   [ ] Adulte autonome → inscription → accès à son profil et à ses
    Classes.
-   [ ] Débutant → branche de diagnostic raccourcie conforme à la
    décision active.
-   [ ] Non-débutant → diagnostic/pré-diagnostic selon le contrat actif.
-   [ ] Dossier incomplet → étape manquante → reprise sans doublon.
-   [ ] Tuteur multi-enfants → changer d'enfant → historique/Classe
    correcte sans fuite.
-   [ ] Enseignant → journée → pre-flight → Classe live → support → fin
    de séance → rapport.
-   [ ] Élève → accueil → Classe → salle → support → fin de séance →
    reprise pédagogique.
-   [ ] Reconnexion LiveKit → retour de session sans double présence.
-   [ ] Classe annulée/reportée/remplacée → tous les rôles voient le
    même état autorisé.
-   [ ] Tuteur observe une séance → quota/expiration effectifs → aucune
    permission média ou jury indue.
-   [ ] Élève → Bibliothèque → lecteur → marque-page/reprise, selon les
    capacités existantes.
-   [ ] Enseignant → fiche élève → objectifs/notes autorisés → retour au
    contexte de Classe.
-   [ ] Évaluation → candidature/occurrence → passage → jury/décision,
    si dans le release scope.
-   [ ] Comptable → transaction → rapprochement →
    facture/avoir/remboursement/payout selon les permissions.
-   [ ] Admin → dossier → vérification → décision → activation/refus
    avec confirmation réelle.
-   [ ] Recherche globale → résultat autorisé → ouverture →
    révocation/accès refusé correctement traité.
-   [ ] Messagerie → fil → pièce jointe → suppression/permission
    retirée.
-   [ ] Notification → bon objet, bon profil, état périmé géré.
-   [ ] Erreur réseau pendant une mutation → saisie conservée, pas de
    faux succès, reprise contrôlée.
-   [ ] Session expirée en cours de navigation → retour sûr sans fuite
    de données privées.
-   [ ] Déconnexion/changement de profil → cache privé effacé ou isolé
    correctement.
-   [ ] Toute route de CTA est réellement atteignable et les liens morts
    sont identifiés.

------------------------------------------------------------------------

# 9. STRATÉGIE DE CORRECTION

## 9.1 Avant de corriger

-   [ ] Présenter le rapport d'audit initial avant toute modification.
-   [ ] Séparer les problèmes en : décision, UI, câblage, logique
    frontend, contrat manquant, défaut technique, régression, dette
    historique.
-   [ ] Identifier les dépendances et les fichiers partagés.
-   [ ] Définir un lot borné et les critères d'acceptation.
-   [ ] Vérifier qu'aucune fonction n'est en cours de modification par
    un autre agent.
-   [ ] Choisir la branche de travail autorisée et enregistrer son SHA
    de base.
-   [ ] Ne pas faire de refonte globale.

## 9.2 Ordre de traitement

1.  P0 : régressions de sécurité, permissions, fuite de données, tarifs
    erronés, action dangereuse, perte de données, parcours critique
    cassé.
2.  P1 : fonctionnalité métier attendue absente/non raccordée, erreurs
    de parcours, données ou états incorrects.
3.  P2 : accessibilité, responsive, états secondaires, cohérence
    visuelle et qualité d'interaction.
4.  P3 : amélioration non bloquante explicitement autorisée.

La priorité ne justifie jamais une modification hors ownership ou une
action de production non autorisée.

## 9.3 Un lot = une preuve

Pour chaque lot : - \[ \] noter la base (branche/SHA) ; - \[ \] lister
les exigences touchées ; - \[ \] faire le plus petit diff qui corrige
les écarts ; - \[ \] conserver les composants et fonctions utiles ; - \[
\] vérifier le diff pour les suppressions accidentelles et changements
de texte/tarif non liés ; - \[ \] exécuter les tests ciblés ; - \[ \]
exécuter les tests de non-régression du domaine et des composants
partagés ; - \[ \] prendre des captures des écrans touchés ; - \[ \]
faire une revue indépendante ; - \[ \] noter le SHA du résultat et les
preuves ; - \[ \] arrêter et rapporter tout conflit découvert au lieu de
prendre une décision produit implicite.

## 9.4 Pas de définition abusive de « terminé »

Ne pas déclarer terminé si : - le code n'est pas routé ; - le bouton ne
fait rien ; - l'UI est raccordée à une fixture ; - le service renvoie
une erreur non gérée ; - le comportement fonctionne seulement dans le
happy path ; - le rôle ou la permission n'est pas testé ; - le
tarif/texte provient d'une constante ancienne ; - le test ne correspond
pas au SHA livré ; - l'écran est inutilisable sur mobile/desktop ou au
clavier ; - la dépendance backend est simulée ; - le comportement réel
n'est pas vérifié dans l'environnement prétendu.

------------------------------------------------------------------------

# 10. LIVRABLES OBLIGATOIRES DE CLAUDE

## Livrable A - `00_INVENTAIRE_ET_GATES.md`

Inventaire du dépôt, branche/HEAD/SHA, statut du working tree, branches,
worktrees, PR, commits non fusionnés, zones appartenant aux autres
agents, instructions actives, fichiers canoniques et limites de
permission. Aucune suppression ni modification pendant la collecte.

## Livrable B - `01_REGISTRE_DECISIONS_ACTUELLES.md`

Décisions actuelles avec source/date, décisions remplacées, sujets non
confirmés, contradictions réelles et impact. Inclure obligatoirement les
tarifs, libellés, enregistrement audio, classe/diagnostic, navigation,
recherche et tous les arbitrages récents retrouvés. Ne pas créer un
registre concurrent si un registre actif équivalent existe :
l'actualiser et le lier.

## Livrable C - `02_MATRICE_CONFORMITE_PAR_ROLE_ET_ECRAN.md`

Une ligne par exigence atomique, pas une ligne vague par module.
Colonnes minimales :

`ID | domaine | rôle/capability | écran/route | exigence actuelle | source/date | statut | preuve code/fichier/symbole | branche/SHA | raccordement | test | preuve test | écart | priorité | action recommandée | dépendance/propriétaire`

Inclure toutes les actions visibles, options, états, variantes et
parcours décrits par les sources applicables.

## Livrable D - `03_MATRICE_RECUPERATION_GIT.md`

Pour chaque capacité recherchée : branches/SHA examinés,
fichiers/commits trouvés, statut de récupération, compatibilité avec la
décision actuelle, dépendances, raison de réutiliser ou non. Aucune
fonction ne doit être déclarée absente sans recherche documentée.

## Livrable E - `04_PLAN_CORRECTIF_PAR_LOTS.md`

Lots atomiques triés par priorité, dépendances, propriétaire, fichiers à
toucher, critères d'acceptation, tests, risque de régression et plan de
retour arrière. Séparer strictement le frontend de tout contrat/backend
appartenant à un autre agent.

## Livrable F - `05_RAPPORT_RECETTE_ET_NON_REGRESSION.md`

Résultats de tests, captures, scénarios passés/échoués, SHA exact,
environnement exact, bugs restants, inconnues, risques et verdict.
Distinguer local, CI, staging et production.

## Livrable G - registre des preuves de livraison

Réutiliser l'outil/document canonique existant s'il existe. Sinon, une
ligne par lot :

`Lot | SHA de base | SHA résultat | fichiers | exigences satisfaites | tests | captures | revue indépendante | environnement | rollback | statut`

Ne pas créer sept documents redondants si les artefacts actifs
contiennent déjà exactement ces informations. L'objectif est la
traçabilité, pas la prolifération documentaire.

------------------------------------------------------------------------

# 11. CRITÈRES DE SORTIE ET GO/NO-GO

## 11.1 Audit initial terminé lorsque

-   [ ] toutes les sources accessibles pertinentes sont inventoriées ;
-   [ ] les décisions récentes ont été recherchées, avec preuves ;
-   [ ] les décisions remplacées ne sont plus présentées comme actuelles
    ;
-   [ ] toutes les branches/worktrees/PR utiles ont été inventoriés ;
-   [ ] toutes les verticales et rôles applicables ont une matrice de
    conformité ;
-   [ ] chaque ligne a un statut explicite et une preuve ou une raison
    d'inconnu ;
-   [ ] chaque fonction suspectée absente a fait l'objet d'une recherche
    de récupération ;
-   [ ] les contradictions véritables sont isolées sans bloquer les
    tâches indépendantes ;
-   [ ] aucune source n'a été modifiée pendant la phase de collecte ;
-   [ ] un plan correctif borné est proposé.

## 11.2 Un lot est terminé lorsque

-   [ ] les exigences couvertes sont satisfaites ou les exceptions
    approuvées sont documentées ;
-   [ ] la fonction est présente, atteignable, raccordée et autorisée ;
-   [ ] les états d'erreur et limites sont traités ;
-   [ ] les tests ciblés et non-régression passent ;
-   [ ] le diff est revu ;
-   [ ] les captures/preuves correspondent au SHA testé ;
-   [ ] aucune régression connue n'est introduite ;
-   [ ] la documentation/traçabilité est mise à jour ;
-   [ ] aucune fusion/diffusion de production n'a été faite sans
    autorisation.

## 11.3 Application prête à être livrée

Ne pas déclarer « 100 % conforme » tant que : - toute exigence
applicable n'a pas un statut et une preuve ; - les P0 sont tous résolus
; - les décisions essentielles non résolues ne sont pas arbitrairement
supposées ; - les parcours critiques ne passent pas de bout en bout ; -
les tests pertinents ne passent pas sur le SHA exact ; - les limites de
release scope, environnement et publication ne sont pas clairement
déclarées.

Le verdict final doit distinguer : 1. conformité aux spécifications ; 2.
stabilité/intégration ; 3. préparation production ; 4. ce qui a été
réellement livré ; 5. ce qui reste bloqué ou hors périmètre.

------------------------------------------------------------------------

# 12. PROMPT D'EXÉCUTION À UTILISER PAR CLAUDE

Tu es le coordinateur technique d'intégration de Rewayah Academy.
Exécute ce document comme un audit de conformité sans régression, pas
comme une nouvelle refonte.

**Commence impérativement en lecture seule. Ne code rien et ne modifie
aucun document pendant la phase d'inventaire et de réconciliation.**

1.  Lis les instructions et références actives du dépôt, y compris
    `CLAUDE.md`, `docs/current/` et la feuille de cohabitation
    réellement en vigueur.
2.  Vérifie les documents récents et décisions prises après les
    documents historiques. Retrouve spécifiquement les dernières
    décisions du directeur avec Claude concernant les tarifs, les
    libellés/textes et l'enregistrement audio. Ne déduis pas ces
    décisions de ta mémoire et ne les remplace pas par les anciennes
    specs.
3.  Inventorie le Git complet en lecture seule : branche/HEAD, statut,
    branches, worktrees, commits, PR, stashes et changements des autres
    agents.
4.  Établis un registre de décisions actuel. Les décisions explicitement
    closes ne sont pas à rouvrir. En cas de conflit réellement non
    résolu, documente les sources et l'impact ; ne choisis pas
    silencieusement.
5.  Établis la matrice atomique de conformité pour chaque rôle, écran,
    action, option, état et parcours des spécifications applicables.
6.  Recherche chaque fonction manquante dans le code, les branches et
    l'historique avant de la déclarer absente.
7.  Livre l'audit initial, les preuves, les inconnues et un plan de
    correction par lots avant d'écrire du code.
8.  Après validation du plan et dans les zones autorisées,
    récupère/raccorde d'abord le code existant, puis corrige seulement
    les écarts prouvés. Un lot à la fois, tests et non-régression après
    chaque lot.
9.  Respecte le périmètre frontend et la cohabitation active. Ne touche
    pas aux zones backend, migrations, RLS/RPC, Edge, LiveKit core ou
    production sans mandat explicite et propriétaire autorisé.
10. Produis un rapport de recette lié aux SHA exacts et distingue code,
    routage, raccordement, test local, CI, staging et production.

**Interdictions absolues :** - aucune régression vers une ancienne
décision ; - aucune reconstruction d'une fonction avant inventaire de
l'existant ; - aucune refonte générale pour résoudre un écart local ; -
aucune suppression de branche, worktree, fonction ou fichier sans
inventaire et autorisation ; - aucun faux succès ou mock présenté comme
réel ; - aucune déclaration de conformité sans preuve ; - aucune
publication, migration distante, fusion vers `main` ou déploiement sans
autorisation explicite ; - aucune demande au directeur de répéter une
décision déjà retrouvée dans les sources accessibles ; - aucune
invention pour combler une information inaccessible.

Le résultat attendu n'est pas un nouveau plan théorique : c'est un état
vérifiable de l'application actuelle, une récupération des travaux
dispersés et un chemin de correction minimal, traçable et sans retour en
arrière.

------------------------------------------------------------------------

# 13. SOURCES DE DÉPART À VÉRIFIER, PAS À APPLIQUER AVEUGLÉMENT

Sources déjà identifiées dans le contexte projet. Claude doit vérifier
leur version active et les changements ultérieurs :

-   `REWAYAH_SPECIFICATIONS_FINALES_LOTS_RESTANTS_2026-10-12.md`
-   `REWAYAH_AUDIT_PREPRODUCTION_2026.md`
-   `REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md`
-   `00_LIRE_D_ABORD.md`
-   `01_PRODUIT_ET_PARCOURS.md`
-   `02_ARCHITECTURE_ET_SECURITE.md`
-   `03_DESIGN_SYSTEM_ET_UX.md`
-   `04_EXECUTION_GIT_CI_ET_MIGRATION.md`
-   `05_PROMPT_AGENT_INTEGRATEUR.md`
-   `06_SPEC_FONCTIONNELLE_MVP.md`
-   `07_MEMOIRE_PEDAGOGIE_FINANCE.md`
-   `REWAYAH_PLAN_SITE_ET_CONFORMITE_2026-10-07.md`
-   `REWAYAH_PLAN_VISUELS_SITE_2026-10-08.md` (actualisé le 9 octobre)
-   `REWAYAH_PASSATION_TUTEUR_ET_CADRAGE_ELEVE_V1.md`
-   `REWAYAH_PLAN_SUPPORTS_TABLEAU_V2.md`
-   `REWAYAH_EVALUATIONS_FINAL_SPEC_V2.md` et les artefacts QA/handoff
    actifs
-   les décisions `DECISION-OFFRES-GROUPES-2026-10-09.md`,
    `DECISION-CLASSES-SIMULTANEES-2026-10-10.md` et
    `docs/orchestration/COHABITATION.md`, sous réserve de versions plus
    récentes
-   les branches, PR, commits, tests et rapports réellement présents au
    moment de l'audit.

**Rappel final :** les sources de départ ne sont pas toutes au même
statut. Une ancienne décision peut être utile historiquement et fausse
aujourd'hui. Le registre de décisions et les preuves du dépôt doivent
déterminer ce qui est réellement applicable. La priorité est de
préserver les décisions les plus récentes, récupérer ce qui existe,
raccorder ce qui manque et ne reconstruire que les lacunes démontrées.

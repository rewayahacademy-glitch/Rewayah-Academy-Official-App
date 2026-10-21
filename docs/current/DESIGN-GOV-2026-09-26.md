# DESIGN-GOV-2026-09-26 : règles gelées du directeur

> **RÈGLE GELÉE JUSQU'À NOUVELLE DÉCISION DATÉE DU DIRECTEUR.** Texte recopié mot pour mot depuis `03_ADMIN_VALIDATION_DOSSIERS` V1.2 (26/09/2026) : §0 (directive de progression), §1 (autorité), §4 (validation UX 2026) et §4 bis (contrats A à E, skeletons, publication, progression).
> Aucun agent ne modifie, ne résume à sa façon ni n'assouplit ce fichier. Il s'applique à **toute nouvelle spécification, maquette ou lot visuel, tous rôles**, à partir du 26/09/2026. Il ne rouvre **aucune** étape déjà faite : l'application rétroactive se fera en une seule passe (étape HU-1 du tableau) après les visuels de tous les rôles.
> Pour chaque lot, le fichier de preuve du §4.2 se nomme `UX_REVIEW_<lot>.md`.
> Exception en vigueur : le thème reste chrome / violet (K-37) ; le monochrome est en réserve (TH-2).

---
**Directive de progression du 26/09/2026 :** cette révision formalise des règles transversales de design et une décision KYC, mais elle n'ordonne aucun retour arrière sur les étapes déjà terminées, vérifiées ou en cours de livraison. Les nouveaux standards sont publiés maintenant pour guider les nouvelles spécifications et les nouveaux visuels. Leur harmonisation rétroactive dans le code et dans les lots déjà livrés est différée jusqu'à ce que les visuels de tous les rôles soient implémentés, sauf demande explicite du directeur sur un écran ou un lot précis.

Exemple directeur : le lot **Tuteur - compléments** n'a pas atteint le niveau visuel attendu. Il ne doit pourtant pas être rouvert, réinitialisé ou recommencé maintenant pour cette seule raison. Les écarts sont consignés dans la future passe d'harmonisation UI. Le chantier continue d'abord vers les autres rôles et les visuels manquants.

---

# 1. Autorité et hiérarchie des décisions

Claude Code applique la hiérarchie canonique de `00_LIRE_D_ABORD.md` :

1. demande explicite la plus récente du directeur ;
2. décisions canoniques, notamment `DOSSIER_POUR_CHATGPT.md`, A §1 bis à §1 quater ;
3. contrats effectivement migrés et vérifiés, avec plan compatible en cas de divergence ;
4. présent document, pour les propositions du parcours ADM-02 ;
5. système de design gelé, composants partagés et référentiels UX applicables.

Le code prouve un état technique, pas la validité d'une décision métier. Une règle existante contestée est documentée, jamais supprimée silencieusement. Les protections d'accès restent effectives pendant toute correction.

**Portée de cette révision :** document uniquement. Aucun dépôt applicatif, environnement Supabase ou accès R2 n'a été audité ou modifié. L'inventaire source décrit le commit `cefab7f` du 24/09/2026, pas une preuve du code actuel. Le mandat frontend de la section F concerne le chantier Tuteur : ne pas le transformer en interdiction universelle, ni déduire de cette spécification une autorisation de migration ou de déploiement. Le coordinateur confirme le périmètre d'exécution applicable au lot Admin ; à défaut, spécifier les ports manquants sans modifier le backend distant.

Une maquette ne peut jamais élargir une permission.

Une proposition de ce document ne peut jamais remplacer silencieusement une règle serveur.

Une donnée absente du contrat serveur ne doit pas être inventée pour remplir une carte.

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
- EN 301 549 si applicable : vérifier l’édition publiée et sa portée ; ne pas inventer une « version 2026 » ;
- heuristiques de Nielsen ;
- principes de Fitts, Hick, proximité Gestalt, visibilité d'état et prévention des erreurs ;
- Atlassian Design System et IBM Carbon uniquement comme références complémentaires de tokenisation, spacing et cohérence de composants lorsque la Bible Rewayah ne tranche pas déjà ;
- bonnes pratiques Baymard applicables aux formulaires, validation et prévention d'erreurs.

**Exclusion décidée par le directeur :** GOV.UK Design System n'est pas une référence de design pour Rewayah. Aucun agent ne doit justifier une composition, un CTA, une densité ou une hiérarchie visuelle Rewayah par GOV.UK.

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

# 4 bis. Contrat transversal de design gelé - DESIGN-GOV-2026-09-26

Cette section formalise la décision du directeur issue de la revue des écrans web et des lots récents. Elle doit être propagée par l'agent orchestrateur dans les sources actives partagées. Elle reste gelée jusqu'à une nouvelle décision explicite et datée du directeur.

Elle ne remplace pas les composants déjà prouvés dans le dépôt. Lorsqu'une métrique existe déjà dans le thème ou un composant partagé, **la valeur existante prouvée prime**. Les règles ci-dessous donnent surtout le rôle sémantique des métriques pour empêcher chaque agent de choisir arbitrairement un nombre.

## 4 bis.1 Contrat A - Spacing & Layout

Échelle autorisée existante : `4, 8, 12, 16, 20, 24, 32, 40, 48, 64` logical pixels. Aucun widget métier ne choisit librement une valeur hors de cette échelle.

| Relation | Valeur Rewayah | Règle |
|---|---:|---|
| texte et aide/erreur immédiatement liée | 4 | relation micro, même composant |
| icône et libellé | 8 | sauf anatomie de composant existante plus précise |
| titre et sous-titre | 8 | même unité sémantique |
| titre de section et groupe/carte qu'il introduit | 8 | le groupe reste perceptuellement lié |
| champs successifs d'un même formulaire | 12 | valeur par défaut de formulaire |
| ligne groupée : icône vers libellé | 12 | conserver `GroupeReglages` existant |
| **objet, carte ou bloc vers le CTA qui agit directement dessus** | **16** | règle transversale obligatoire |
| checkbox/consentement vers CTA qu'elle conditionne | 16 | même décision |
| deux boutons du même action group | 8 | secondaire puis primaire en LTR |
| deux cartes autonomes d'une même section | 16 | même niveau hiérarchique |
| header/actions internes d'`AppCard` | 16 | conserver l'anatomie existante |
| groupe de champs vers groupe suivant | 20 | séparation fonctionnelle |
| section vers section suivante, mobile | 24 | séparation structurelle |
| section vers section suivante, tablette/desktop | 32 | respiration structurelle |
| padding de page mobile | 16 | `PageShell`/layout partagé |
| padding de page tablette | 24 | layout partagé |
| padding de page desktop | 32 | layout partagé |
| padding interne `AppCard` | 20 sous 600, 24 à partir de 600 | conserver le composant existant |
| padding de ligne groupée | 16 horizontal, 12 vertical | conserver `GroupeReglages` |

**Interdiction :** un CTA lié à un contenu ne peut pas être déplacé arbitrairement en bas du viewport si son objet est très au-dessus. Un écart de 40, 48 ou 64 entre l'objet et son CTA signifie visuellement une séparation de groupe et est donc interdit sauf structure explicitement documentée.

Les écrans utilisent des tokens sémantiques, par exemple `space.relatedAction`, `space.actionGroup`, `space.section`, et non des `SizedBox` choisis au jugé. Le coordinateur mappe ces rôles aux tokens réels du dépôt au lieu de créer des constantes concurrentes.

## 4 bis.2 Contrat B - CTA & Actions

`ActionPrincipale` reste le point d'entrée canonique des boutons. Son anatomie existante ne doit pas être redessinée localement : hauteur 52, padding interne 20 horizontal x 12 vertical, rayon 12, `labelLarge`, quatre niveaux d'emphase. La cible interactive reste au moins 48 dp.

Règles de hiérarchie :

1. un seul CTA **principal visuellement dominant** par écran ou contexte de décision ;
2. deux actions secondaires au plus dans le même action group ;
3. une action destructive utilise le niveau destructif existant, jamais un second bouton plein concurrent ;
4. une collection de cartes répétées ne porte pas un gros CTA plein identique sur chaque carte si la carte elle-même ou un lien tertiaire peut ouvrir l'action ;
5. les actions secondaires, contextuelles et rares utilisent secondaire, tertiaire, menu ou interaction de ligne selon leur nature ;
6. un CTA dit exactement l'action qu'il exécute.

Règles de placement :

- une action qui poursuit ou confirme un flux est placée au **trailing edge** de son action group ;
- retour, précédent et annulation sont au **leading edge** ou avant l'action principale dans le même groupe ;
- en français/anglais LTR, trailing = droite et leading = gauche ; en arabe RTL, l'interface inverse automatiquement via `start/end`, jamais via `left/right` codés en dur ;
- un CTA directement rattaché à une carte ou à un rectangle se trouve **16 dp sous cet objet** et aligne son bord trailing sur le bord trailing du conteneur ;
- sur desktop, un bouton n'est pas étiré pleine largeur sans justification ;
- un pied d'action sticky est réservé aux tâches longues où l'action concerne l'ensemble de l'écran et doit rester disponible pendant le scroll. Il réserve sa hauteur dans le contenu et ne doit jamais masquer le focus. Ce pattern n'est pas utilisé uniquement pour remplir un grand vide.

Pour les écrans de résultat montrés lors de la revue du 26/09/2026, la cible attendue est donc : rectangle de résultat, `16 dp`, CTA trailing. Pour une confirmation précédée d'une case « J'ai compris », la case devient l'ancre immédiate du bouton : `16 dp`, puis CTA trailing.

## 4 bis.3 Contrat C - Component Anatomy

Les agents assemblent le langage Rewayah, ils ne redessinent pas les briques dans chaque feature.

Composants structurants déjà identifiés à préserver :

- `ActionPrincipale` pour tous les boutons ;
- `PageShell`, `PageParcours`, `PageImmersive` pour les gabarits ;
- `AppCard` pour une carte autonome ;
- `GroupeReglages` + `LigneRubrique` pour une carte groupée ;
- `StatusPill`, `SectionHeader`, `LigneCleValeur` pour les informations structurées ;
- `EtatSysteme`, `EcranResultat`, `EmptyState` pour les états ;
- `BlocAsynchrone` + `Skeleton` pour les chargements ;
- `OfflineBanner` pour la coupure réseau ;
- `LocalFeedback` pour le retour local ;
- `ConfirmDestructive` pour une confirmation destructive ;
- `AppBottomSheet` pour feuille/dialogue adaptatif.

Avant de créer un nouveau composant, l'agent prouve qu'aucun composant partagé ne couvre la responsabilité. Aucun fork local de `ActionPrincipale`, `AppCard`, `Skeleton`, `GroupeReglages` ou `AppBottomSheet` n'est accepté pour obtenir « juste ce rendu ».

Anatomies existantes à conserver :

- `AppCard` : rayon 16, filet, padding 20 sous 600 ou 24 au-delà, en-tête et actions espacés de 16 ;
- `GroupeReglages` : un seul rectangle, ligne minimale 48, icône 24, gap icône/libellé 12, padding 16 horizontal x 12 vertical, filet interne absent sous la dernière ligne ;
- `ActionPrincipale` : valeurs du §4 bis.2 ;
- `Skeleton` : blocs `surfaceSunken` qui reproduisent la forme du contenu final, sans shimmer, scintillement ou pulsation.

## 4 bis.4 Contrat D - Responsive Desktop

Le web est une vraie interface bureau. Il n'étire jamais mécaniquement le mobile.

Seuils déjà décidés pour les shells :

- compact sous 600 ;
- rail à partir de 600 lorsque le rôle le prévoit ;
- sidebar persistante à partir de 1200 lorsque le rôle le prévoit ;
- `AdminShell` : tiroir, rail 80, sidebar 288 selon largeur disponible.

Pour cette verticale à 1440 :

- sidebar admin : 288 ;
- padding de page : 32 de chaque côté ;
- largeur utile principale : 1088 ;
- composition master-detail recommandée : file 336, gap 24, détail 728 ;
- aucun troisième panneau obligatoire ; le viewer reste une surface dédiée/modal si nécessaire ;
- le détail ne s'étire pas au-delà de ce que le contenu exige ;
- hover, focus visible, clavier, molette et browser navigation sont des états de premier rang, pas des adaptations après coup.

Un écran qui n'a besoin que d'une colonne conserve une largeur de lecture/formulaire bornée par le composant ou le gabarit existant. L'agent ne crée pas une largeur maximale ad hoc dans chaque page.

## 4 bis.5 Contrat E - Interaction & Motion

Les valeurs existantes du dépôt sont gelées :

| Jeton | Valeur |
|---|---:|
| `retourTactile` | 100 ms |
| `micro` | 120 ms |
| `apparition` | 180 ms |
| `navigation` | 220 ms |
| `feuilleOuverture` | 180 ms |
| `feuilleFermeture` | 120 ms |
| plafond d'animation | 400 ms |
| pulsation exceptionnelle | 1200 ms, uniquement l'élément déjà autorisé |
| skeleton avant apparition | 180 ms |
| chargement prolongé | 8 s |
| requête considérée perdue | 20 s |

Courbes existantes : entrée `easeOutCubic`, sortie `easeInCubic`, ressort sans rebond, `linear` seulement pour une progression indéterminée. En réduction de mouvement : durée 0 et translation 0.

Tout contrôle interactif définit au minimum les états pertinents `default`, `hover`, `focus`, `pressed`, `disabled`, `loading`, `error`, `success/unavailable` selon son contrat. Les agents ne créent pas leur propre timing local pour hover, navigation, sheets ou feedback.

## 4 bis.6 Skeletons - retour obligatoire dans les vagues futures

Le système de skeleton existe déjà et a commencé à être utilisé. Il n'est **pas à redessiner**.

Règles :

1. `Skeleton` et `BlocAsynchrone` redeviennent obligatoires pour tout chargement initial substantiel dont la structure finale est connue ;
2. rien n'est affiché avant le délai existant de 180 ms afin d'éviter le flash ;
3. le skeleton reproduit la géométrie du contenu attendu, sans faux nom, fausse date, faux solde ou fausse donnée métier ;
4. à 8 s, le chargement prolongé est expliqué ; à 20 s, l'état devient récupérable selon `BlocAsynchrone` ;
5. le spinner seul au centre d'une page métier n'est pas le pattern de chargement ; un indicateur local reste permis dans un bouton ou une action ponctuelle ;
6. aucun shimmer, scintillement ou pulsation ne doit être ajouté : le composant existant est volontairement calme ;
7. la présence de skeletons est vérifiée dans les nouvelles fiches écran et dans la future passe d'harmonisation.

## 4 bis.7 Obligation de l'agent orchestrateur - mémoire et Suivi Rewayah

Dès réception de ce document, l'orchestrateur ne lance pas une refonte. Il exécute d'abord une **publication documentaire durable** :

1. retrouver `projet/ressources/LISEZ-MOI.md`, qui est le point d'entrée déclaré de la mémoire, des specs, des décisions et du registre des agents ;
2. retrouver la mémoire canonique active réellement référencée par ce fichier et y ajouter `DESIGN-GOV-2026-09-26` ; ne pas créer une deuxième mémoire concurrente ;
3. mettre à jour le document canonique UX actif, notamment `docs/current/03_DESIGN_SYSTEM_ET_UX.md` ou son remplaçant prouvé, avec les cinq contrats A à E et le rappel Skeleton ;
4. mettre à jour les instructions frontend actives (`lib/CLAUDE.md` ou leur remplaçant prouvé) pour obliger tout agent frontend à consulter cette décision avant un nouveau lot visuel ;
5. déposer la décision dans **Suivi Rewayah** comme `consigne du directeur`, puis créer les étapes nécessaires : publication des règles, contrôle par une seconde session, puis future harmonisation UI globale ;
6. conserver dans Suivi Rewayah la distinction `fait` puis `vérifié` avec preuve, conformément au mécanisme partagé ;
7. noter explicitement : **« règle gelée jusqu'à nouvelle décision datée du directeur »** ;
8. si le chemin réel de mémoire ou le suivi vivant diffère de la copie documentaire, utiliser la source vivante prouvée et consigner le chemin exact. Ne jamais inventer un nouveau registre pour contourner le système partagé.

Ces opérations sont documentaires et de coordination. Elles ne donnent aucune autorisation implicite de merge `main`, migration distante, déploiement production ou réécriture d'un lot terminé.

## 4 bis.8 Règle de progression - aucune marche arrière automatique

La gouvernance design a deux moments distincts :

**Maintenant :**

- figer les règles dans la mémoire, la Bible UX active et Suivi Rewayah ;
- utiliser ces règles dans toute **nouvelle spécification ou nouvelle maquette** produite à partir de cette décision ;
- continuer les rôles dans l'ordre prévu ;
- ne pas rouvrir une étape `fait` ou `vérifié` uniquement parce qu'elle ne respecte pas encore ces règles.

**Après implémentation des visuels de tous les rôles :**

- lancer une passe unique d'**harmonisation UI transversale** ;
- appliquer les contrats A à E et les skeletons aux écrans déjà construits ;
- traiter les écarts visuels consignés sans réinventer le métier ;
- exécuter golden tests, captures multi-format et vérification des composants partagés.

**Exception :** le directeur peut demander explicitement la correction immédiate d'un écran, d'un composant ou d'un lot précis. Cette demande doit être nommée dans Suivi Rewayah et ne devient pas une autorisation générale de reprendre les autres étapes.

**Exemple obligatoire à conserver dans la mémoire :** le lot **Tuteur - compléments** est considéré comme visuellement insuffisant sur plusieurs points. Il est enregistré comme dette d'harmonisation, mais **on ne fait pas marche arrière maintenant**. Aucun reset, aucune réouverture générale de la vague Tuteur, aucune refonte de tous ses écrans avant de poursuivre les autres rôles. Le projet avance, puis la passe transversale corrige l'ensemble avec une même grammaire.

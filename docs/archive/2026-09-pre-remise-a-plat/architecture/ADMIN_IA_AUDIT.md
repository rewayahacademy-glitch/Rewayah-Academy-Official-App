# Audit et gel de l'architecture d'information — Administration

**Statut :** décision de cartographie. Aucune route, aucun écran, aucun droit
ni service métier n'est modifié par ce document.

**Instantané audité :** `main` au commit `7b3b89b9d55ed501c7457b0525dd140e4526e32d`,
le 19 septembre 2026. Les deux modifications locales Windows déjà présentes
(`windows/flutter/generated_plugin_registrant.cc` et
`windows/flutter/generated_plugins.cmake`) sont hors périmètre et n'ont pas
été touchées.

## Décision de navigation

La navigation principale de l'espace Administration contient uniquement ces
domaines, dans cet ordre :

1. Accueil
2. Opérations
3. Personnes
4. Pédagogie
5. Finance
6. Configuration
7. Sécurité et audit
8. Direction — seulement si la capacité serveur correspondante l'autorise

Un domaine ne peut jamais être remplacé dans la barre, le rail ou le drawer
par un écran métier, une liste, un outil ou une action. Les sous-fonctions
vivent dans le contenu du domaine. Une entrée de niveau 1 sans fonction
autorisée et réellement livrée n'est pas activée : aucun écran vide ni donnée
fictive ne doit être créé pour remplir le chrome. Direction est en outre
conditionnée par une capacité fournie par l'autorisation existante, jamais par
un test local de rôle ou un nouveau rôle inventé.

Le compte personnel reste hors de cette liste : `/compte`, `/compte/profil` et
`/compte/reglages` sont des surfaces transverses de la personne connectée. Il
reste accessible dans le pied de coque ou le menu de compte, sans être confondu
avec la Configuration de l'académie.

## Routes canoniques et compatibilité

| Domaine | Route de domaine cible | Fonctions actuelles à y raccorder | État actuel |
| :--- | :--- | :--- | :--- |
| Accueil | `/admin` | Centre de commande, indicateurs, file prioritaire | Existe sous `/admin/tableau-de-bord` |
| Opérations | `/admin/operations` | Groupes (fonction primaire), attribution, demandes | Groupes livré le 19/09/2026 (migration `0017`, pivot 1-à-1 → groupe) ; attribution et demandes restent secondaires |
| Personnes | `/admin/personnes` | Comptes, dossiers d'identité | Deux écrans distincts, dispersés entre barre, pied et accueil |
| Pédagogie | `/admin/pedagogie` | Aucune surface admin livrée | Domaine réservé, pas de route à activer maintenant |
| Finance | `/admin/finance` | Aucune surface admin livrée | Finance reportée ; `/comptable` ne constitue pas un écran Admin |
| Configuration | `/admin/configuration` | Aucune configuration organisationnelle livrée | Les réglages actuels sont personnels et restent dans Compte |
| Sécurité et audit | `/admin/securite-audit` | Journal, accès des agents IA | Deux écrans aujourd'hui séparés |
| Direction | `/admin/direction` | Aucune surface ni capacité observée | Domaine réservé ; invisible sans permission serveur |

Lors du lot de navigation, les anciennes URL restent des redirections explicites
vers leur route canonique. Elles ne portent pas une seconde page :

| URL actuelle | Route canonique cible |
| :--- | :--- |
| `/admin/tableau-de-bord` | `/admin` |
| `/admin/dossiers` | `/admin/personnes/dossiers` |
| `/admin/comptes` | `/admin/personnes/comptes` |
| `/admin/attribution` | `/admin/operations/attributions` |
| `/admin/demandes` | `/admin/operations/demandes` |
| `/admin/journal` | `/admin/securite-audit/journal` |
| `/admin/acces-agents` | `/admin/securite-audit/acces-agents` |

## Cartographie des fonctions observées

### Centre de commande (`ADM-01`)

- **Emplacement actuel :** `/admin/tableau-de-bord`, première destination de
  `NavShell`; `TableauDeBordPage` affiche six indicateurs, la file « à
  traiter » et le bloc « Outils ».
- **Doublons :** les actions Dossiers, Demandes et Attribution sont aussi dans
  la barre principale. Comptes et Accès des agents sont aussi dans le pied de
  coque. Le bloc « Outils » duplique donc ces deux entrées.
- **Emplacement cible :** Accueil, synthèse et orientation seulement.
- **Route canonique :** `/admin`.
- **Raccourcis autorisés :** chaque indicateur ou ligne de la file peut ouvrir
  la fonction canonique avec son filtre ou son contexte correspondant.
- **À supprimer :** le statut de destination principale des écrans métier et
  le regroupement autonome « Outils » comme deuxième menu.
- **À fusionner :** les tuiles « Outils » avec les raccourcis contextuels de
  l'Accueil ; elles ne doivent pas introduire de copie de `ADM-07` ou `ADM-08`.
- **À conserver :** les six valeurs réelles, leur état zéro, la file triée par
  ancienneté et les fournisseurs existants.

### Indicateur « Dossiers à traiter »

- **Emplacement actuel :** tuile de `ADM-01`, ligne de la file « à traiter »,
  et destination principale `/admin/dossiers`.
- **Doublons :** trois entrées de navigation pour la même validation KYC.
- **Emplacement cible :** Personnes > Dossiers d'identité.
- **Route canonique :** `/admin/personnes/dossiers`.
- **Raccourcis autorisés :** tuile et ligne de file depuis Accueil, avec la
  même liste en attente ; aucun écran de diagnostic propre au compteur.
- **À supprimer :** l'entrée « Dossiers » de niveau 1.
- **À fusionner :** les accès Accueil et le contenu de Personnes, pas les
  écrans `ADM-02` et `ADM-08`.
- **À conserver :** le geste d'approuver ou refuser et son contrôle métier.

### Indicateur « Demandes à traiter »

- **Emplacement actuel :** tuile et file de `ADM-01`, plus entrée secondaire
  `/admin/demandes` dans le pied de coque.
- **Doublons :** le compteur et le pied pointent déjà vers la même page, sans
  réimplémentation distincte.
- **Emplacement cible :** Opérations > Demandes et exceptions.
- **Route canonique :** `/admin/operations/demandes`.
- **Raccourcis autorisés :** tuile et file depuis Accueil, ouvertes sur la
  demande la plus ancienne ou le filtre « en attente ».
- **À supprimer :** l'entrée secondaire plate « Demandes » hors de son domaine.
- **À fusionner :** les chemins du compteur et du pied, autour de la même liste
  de demandes.
- **À conserver :** l'ordre par ancienneté, le verdict avec motif et les
  invalidations des fournisseurs après décision.

### Indicateur « Foyers sans enseignant »

- **Emplacement actuel :** tuile de `ADM-01` vers `/admin/attribution` et
  destination principale « Attribution ».
- **Doublons :** le compteur et la barre ouvrent le même flux.
- **Emplacement cible :** Opérations > Attribution.
- **Route canonique :** `/admin/operations/attributions`.
- **Raccourcis autorisés :** tuile depuis Accueil, filtrée sur les foyers sans
  enseignant ; elle ne crée pas une seconde liste d'affectation.
- **À supprimer :** l'entrée « Attribution » de niveau 1.
- **À fusionner :** le raccourci Accueil avec le flux unique `ADM-05`.
- **À conserver :** la sélection élève, enseignant, créneau et motif hors
  disponibilité, ainsi que les contraintes serveur déjà existantes.

### Indicateurs « Rapports manquants » et « Incidents 24 h »

- **Emplacement actuel :** deux tuiles non cliquables de `ADM-01`.
- **Doublons :** aucun ; aucune page d'action Admin n'est branchée.
- **Emplacement cible :** Pédagogie pour les rapports manquants ; Sécurité et
  audit pour les incidents.
- **Route canonique :** aucune à activer tant qu'une fonction réellement
  livrée, autorisée et spécifiée n'existe pas.
- **Raccourcis autorisés :** aucun aujourd'hui. Une future tuile ne pourra
  ouvrir que la liste canonique correspondante avec le filtre exact.
- **À supprimer :** rien dans le lot de cartographie ; ne pas rendre ces
  valeurs cliquables vers un journal générique ou un écran inventé.
- **À fusionner :** rien.
- **À conserver :** les compteurs non interactifs et leur source réelle.

### Indicateur « Comptes échus »

- **Emplacement actuel :** tuile non cliquable de `ADM-01` ; les comptes sont
  listés séparément par `ADM-08`.
- **Doublons :** pas de second écran, mais le tableau actuel ne porte pas
  encore le filtre fonctionnel « accès échu ».
- **Emplacement cible :** Personnes > Comptes.
- **Route canonique :** `/admin/personnes/comptes`.
- **Raccourcis autorisés :** aucun avant qu'un filtre canonique « accès échu »
  soit réellement implémenté. Après cela, la tuile ouvre cette même page avec
  ce filtre, sans liste dupliquée sur Accueil.
- **À supprimer :** rien aujourd'hui.
- **À fusionner :** le futur filtre avec `ADM-08`, pas avec une nouvelle page.
- **À conserver :** le compteur et l'affichage des états de compte.

### Comptes (`ADM-08`)

- **Emplacement actuel :** `/admin/comptes`, entrée secondaire du pied de
  coque et ligne « Outils » de `ADM-01`.
- **Doublons :** deux accès, une seule implémentation. Ce n'est pas un doublon
  métier ; l'Accueil peut rester un raccourci.
- **Emplacement cible :** Personnes > Comptes.
- **Route canonique :** `/admin/personnes/comptes`.
- **Raccourcis autorisés :** Accueil > raccourci contextualisé « comptes à
  traiter » et, plus tard, la tuile « comptes échus » avec filtre.
- **À supprimer :** l'entrée secondaire plate et la ligne « Outils » comme
  menu permanent.
- **À fusionner :** ses accès sous le domaine Personnes ; ne pas fusionner
  `ADM-08` avec la validation de pièces.
- **À conserver :** lecture seule, tri serveur, filtres état/rôle, identité
  masquée et visibilité des comptes sans pièce déposée.

### Dossiers d'identité (`ADM-02`)

- **Emplacement actuel :** `/admin/dossiers`, entrée principale de la barre.
- **Doublons :** même fonction atteinte depuis la tuile et la file de l'Accueil.
- **Emplacement cible :** Personnes > Dossiers d'identité.
- **Route canonique :** `/admin/personnes/dossiers`.
- **Raccourcis autorisés :** tuile et file de l'Accueil vers le dossier à
  traiter ; aucun écran de détail parallèle.
- **À supprimer :** l'entrée métier de niveau 1.
- **À fusionner :** le contexte de dossier dans le domaine Personnes, sans
  absorber `ADM-08` : consulter les comptes et rendre un verdict KYC restent
  deux responsabilités différentes.
- **À conserver :** la lecture de la file, la checklist, les motifs de refus,
  les états vide/erreur et les limites de visibilité existantes.

### Attribution manuelle (`ADM-05`)

- **Emplacement actuel :** `/admin/attribution`, entrée principale ; raccourci
  depuis le compteur « Foyers sans enseignant ».
- **Doublons :** deux accès, une seule implémentation.
- **Emplacement cible :** Opérations > Attribution.
- **Route canonique :** `/admin/operations/attributions`.
- **Raccourcis autorisés :** tuile Accueil préfiltrée sur les foyers sans
  enseignant ; aucun panneau d'affectation intégré au tableau de bord.
- **À supprimer :** l'entrée métier de niveau 1.
- **À fusionner :** le lien de compteur avec ce flux ; ne pas fusionner avec
  les demandes, car l'affectation est un geste différent.
- **À conserver :** les listes élève/enseignant, le repli mobile, le créneau
  familial, le motif requis et la confirmation serveur.

### Demandes et dérogations de règles (`ADM-06`)

- **Emplacement actuel :** `/admin/demandes`, entrée secondaire, tuile et file
  de l'Accueil. La même page contient le verdict de demande et la feuille des
  règles individuelles ; « Changer » et « Clore » ouvrent une bottom sheet.
- **Doublons :** les points d'entrée du flux sont multiples, mais la feuille de
  règle n'est pas une page autonome et ne doit pas le devenir par copie.
- **Emplacement cible :** Opérations > Demandes et exceptions. Les règles
  visibles restent un contexte de la demande individuelle, pas une seconde
  destination Pédagogie ou Configuration tant qu'aucun catalogue de règles
  distinct n'existe.
- **Route canonique :** `/admin/operations/demandes`.
- **Raccourcis autorisés :** compteur et file de l'Accueil ; une future page
  Pédagogie peut lier vers cette même route avec un contexte, jamais recopier
  la feuille ou les mutations.
- **À supprimer :** l'entrée secondaire plate hors domaine.
- **À fusionner :** compteur, file et pied autour de `ADM-06` ; conserver une
  seule bottom sheet partagée pour poser ou clore une dérogation.
- **À conserver :** verdict, motif obligatoire, historique des surcharges,
  comparaison règle plateforme/effective et les services existants.

### Journal d'audit (`ADM-04`)

- **Emplacement actuel :** `/admin/journal`, quatrième entrée principale.
- **Doublons :** aucun écran jumeau ; seul le journal affiche et vérifie sa
  chaîne d'intégrité.
- **Emplacement cible :** Sécurité et audit > Journal.
- **Route canonique :** `/admin/securite-audit/journal`.
- **Raccourcis autorisés :** depuis Accueil uniquement lorsqu'un indicateur
  correspond à un filtre réel et vérifié ; pas de compteur « incident » qui
  ouvre un journal non filtré.
- **À supprimer :** l'entrée « Journal » de niveau 1.
- **À fusionner :** le regroupement de navigation avec l'accès aux agents, pas
  leurs écrans ni leurs données.
- **À conserver :** lecture seule, filtres acteur/action/période, pagination,
  vérification séparée de chaîne et toutes les protections d'audit.

### Accès des agents IA (`ADM-07`)

- **Emplacement actuel :** `/admin/acces-agents`, entrée secondaire et ligne
  « Outils » de l'Accueil ; révocation par dialogue de confirmation.
- **Doublons :** deux accès, une seule implémentation et une seule émission de
  jeton. Le lien vers `/agent` est l'entrée de l'agent, pas une page Admin.
- **Emplacement cible :** Sécurité et audit > Accès des agents IA.
- **Route canonique :** `/admin/securite-audit/acces-agents`.
- **Raccourcis autorisés :** raccourci Accueil vers la route canonique, jamais
  formulaire d'émission embarqué dans le tableau de bord.
- **À supprimer :** l'entrée secondaire plate et le menu « Outils » dupliqué.
- **À fusionner :** ses deux liens sous Sécurité et audit ; ne pas fusionner
  l'émission/révocation avec le journal.
- **À conserver :** une seule émission, le secret affiché une fois, la liste,
  des jetons, leurs états, la révocation confirmée et les garanties ADR-025.

### Compte, profil, réglages et déconnexion

- **Emplacement actuel :** `/compte`, `/compte/profil` et `/compte/reglages`,
  accessibles dans les entrées secondaires de la coque Admin. Profil est en
  lecture seule ; les réglages sont des préférences personnelles locales ; la
  déconnexion vit dans Compte.
- **Doublons :** aucun équivalent administratif. Les intitulés peuvent prêter à
  confusion avec la future Configuration de l'académie, mais les responsabilités
  sont différentes.
- **Emplacement cible :** menu de compte transversal, hors navigation Admin de
  niveau 1.
- **Route canonique :** routes actuelles inchangées.
- **Raccourcis autorisés :** une entrée persistante Compte dans le pied ou le
  menu utilisateur, mais pas une copie dans Configuration.
- **À supprimer :** aucune fonction ; seulement toute future duplication dans
  « Configuration ».
- **À fusionner :** rien.
- **À conserver :** profil, préférences, déconnexion et leurs limites actuelles
  (notamment les réglages non encore disponibles).

### Correction de présence, galerie et fonctions non activées

- **Emplacement actuel :** `presence_correction` est un panneau réutilisable
  testé, sans route, sans entrée Admin et sans raccord observé. Les galeries
  `_galerie` et `_galerie/compte` sont des outils de développement. `ADM-03`
  (exports), une surface Finance, une surface Pédagogie Admin, une
  Configuration organisationnelle et une Direction ne sont pas implémentés.
- **Doublons :** aucun parcours Admin actif pour ces éléments.
- **Emplacement cible :** correction de présence : Pédagogie, seulement quand
  une capacité et un flux réel l'y raccordent. Galeries : développement hors
  production. Exports : Sécurité et audit seulement après la décision de
  périmètre déjà signalée par le handoff. Finance, Configuration et Direction :
  aucune activation avant contrat métier et autorisation.
- **Route canonique :** aucune à activer aujourd'hui ; aucune route fictive ne
  doit être ajoutée.
- **Raccourcis autorisés :** aucun.
- **À supprimer :** aucune fonction ou composant existant dans ce lot.
- **À fusionner :** aucun code ; raccorder un jour le panneau existant plutôt
  que de le réécrire.
- **À conserver :** l'isolation du composant de présence, l'exclusion des
  galeries de production et la séparation de l'espace Comptable (`/comptable`).

## Règles de mise en œuvre ultérieure

1. Créer d'abord les huit entrées de domaine et leurs permissions, puis
   raccorder les écrans existants un par un. Ne pas déplacer les services,
   providers, autorisations, migrations ou règles métier dans le lot de
   navigation.
2. Chaque raccourci transporte uniquement une route canonique et, si
   nécessaire, un filtre sérialisable. Il ne monte jamais une variante locale
   de l'écran, un provider distinct ou une liste calculée dans l'Accueil.
3. Les anciennes URL restent supportées par redirection. Un deep link ou un
   favori ne doit pas créer une seconde branche du routeur.
4. La barre, le rail et le drawer consomment la même liste de domaines. Les
   éléments plats actuellement fournis par `destinationsPour` et
   `secondairesPour` sont remplacés par les domaines et leurs sous-sections,
   sans dépasser les règles adaptatives déjà en place.
5. Aucun domaine absent ne reçoit un compteur actionnable ou une page
   placeholder. Le compteur reste informatif jusqu'à ce qu'une fonction réelle
   soit spécifiée, autorisée et testée.
6. Direction ne doit pas être ajoutée par `if (role == admin)`. Son affichage
   attend la capacité fournie par l'autorisation existante ; en son absence,
   ni la route ni le libellé ne sont exposés.

## Vérification de l'audit

- Les sept routes Admin actuelles ont été relevées dans `routes.dart` et
  `app_router.dart`.
- La barre principale, le pied de coque et leurs références de routes ont été
  comparés à `TableauDeBordPage`.
- Les pages `ADM-01`, `ADM-02`, `ADM-04`, `ADM-05`, `ADM-06`, `ADM-07` et
  `ADM-08`, leurs services et les fiches catalogue correspondantes ont été
  inspectés.
- Aucune tabulation d'administration n'a été trouvée. La seule bottom sheet
  Admin observée est la feuille de règle de `ADM-06`; le seul dialogue Admin
  observé confirme la révocation d'un jeton `ADM-07`.
- Ce document est une preuve de cartographie du code au commit indiqué, pas une
  preuve de parcours authentifié, de compilation, de déploiement ou de recette
  navigateur.

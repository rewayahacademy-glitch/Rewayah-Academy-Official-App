# REVUE_EA-R : revue croisée de la vague Élèves adultes (EA-1a à EA-12)

- **Date** : 02/10/2026.
- **Session relectrice** : A-2026-10-02-file. Elle n'a rien construit dans la vague.
- **Code revu** : worktree `D:\RA_TUTEUR\adultes`, branche `ui/eleves-adultes-v1` @ `510acbb`. Base de la vague : `1108a4a` (`ui/enseignant-v1`). Diff : 68 fichiers sous `lib/` et `test/`.
- **Mode** : lecture seule. Aucun fichier de code modifié. Aucun `flutter test` ni `flutter analyze` lancé (machine prise par une autre session). Les chiffres de tests cités viennent de `05_recette/EA/RAPPORT.md`, non rejoués ici.
- **Documents lus** : `16_eleves_adultes/00_REPRISE.md`, `02_DECOUPAGE.md`, `UX_REVIEW_07_ELEVES_ADULTES.md`, `EA-BR.md` ; `05_recette/EA/RAPPORT.md` ; `memoire/ELEVES-ADULTES-2026-09-27.md` (F1 à F24), `DESIGN-GOV-2026-09-26.md`, `STYLE-REFERENCE-CL4-2026-09-26.md` (K-42) ; spec foyer §7.1 à §7.3, §16, §17.
- **Limite importante** : le texte des décisions du directeur du 27/09 (E1 à E8, D4, D5) n'est écrit dans aucun fichier lu (pilotage, ressources, recette). Je juge ces décisions d'après leur résumé donné dans la consigne de cette revue. E8 reste non vérifiable.
- **Complément de la session (02/10)** : le texte de ces décisions existe, dans la feuille du directeur https://claude.ai/artifact/5hqpCULEK4Hwchu7D4BVtg (collection `reponses`). E3 = a y dit mot pour mot : « Dans le Foyer pour le titulaire, le Compte garde l'historique ; pas de rubrique Paiements pour le second adulte ». **M1 est donc décidé : à corriger en EA-RC, sans question au directeur** (question 1 retirée). E5 = a y dit « « Validation Admin refusée » (doc §18) et un bouton « Faire une nouvelle demande » (§10.3) » : le conflit avec K-53.6 reste une vraie question (question 2). Question 5 : sans objet, la source est cette feuille.

## Verdict

**Pas prêt pour la planche du directeur en l'état** : la vague est solide et honnête sur l'essentiel, mais « Se déconnecter » appelle le vrai service depuis la démonstration, la rubrique « Paiements du foyer » donnée au second adulte contredit E3 telle qu'elle m'a été transmise, et le texte E5 n'est pas celui décidé ; avec trois écarts de composants et d'états, ce sont six majeurs à corriger en EA-RC, dont deux à faire trancher d'abord.

## Majeurs

### M1. Le second adulte rattaché a une rubrique « Paiements du foyer » (contredit E3 = a)

- **Où** :
  - `lib/features/mon_espace_adulte/mon_espace_adulte_page.dart:328-338` : sous « Forfait famille », une ligne « Paiements du foyer » pour le second adulte.
  - `lib/features/mon_espace_adulte/mon_espace_adulte_page.dart:120-122` : `RubriqueMonEspace.paiementsFoyer`, « le second adulte rattache seulement (decision E3) ».
  - `lib/features/demo/demo_adulte_page.dart:956-961` : cette ligne ouvre `PaiementsComptePage`, qui lit `paiementsFoyerProvider`, c'est-à-dire l'historique des paiements du foyer, donc ceux du titulaire (`lib/features/compte/paiements_page.dart:36-37, 69-71`).
  - `16_eleves_adultes/EA-BR.md:22` (EA-BR-16) demande au serveur de rendre cet historique au second adulte.
- **Ce qui est faux** : E3 = a, tel que résumé dans la consigne, dit « pas de rubrique Paiements pour le second adulte ». Le code applique l'inverse, en citant E3. La spec ne donne pas ce droit : §7.1 dit que le second adulte « n'est pas le gestionnaire financier du foyer » ; §7.3 limite même la vue du titulaire sur le conjoint. F6 interdit au second adulte les moyens de paiement et les pièces du titulaire. Un historique de paiements du titulaire n'est prévu nulle part.
- **Circonstance** : en démonstration, `paiementsFoyerProvider` n'est pas surchargé, la page dit donc « indisponible ». Aucune donnée ne fuit aujourd'hui. Mais l'écran et la ligne BR existent et demanderont au serveur de livrer cette donnée.
- **Risque de confusion** : dans le même dépôt, « E3 » désigne aussi la règle enseignant « une fonction, un seul emplacement » (`V/00_MAQUETTES_ELEVES_ADULTES.md:214`, `demo_adulte_page.dart:1004`). Le code a peut-être lu le mauvais E3.
- **À faire** : si E3 = a est confirmé, retirer la ligne `mon_espace_adulte_page.dart:332-338` et l'écran `EcranDemoAdulte.paiementsFoyer` de la coquille du second adulte ; réécrire EA-BR-16 (le second adulte ne lit rien des paiements du foyer) ; ajouter un test qui échoue si le second adulte voit une ligne « Paiements » ou « Paiements du foyer » sur les 25 états. Écrire la décision E3 en clair dans `00_REPRISE.md`, avec son numéro distinct de la règle enseignant E3.
- **Décision du directeur** : oui, pour confirmer le sens de E3 (voir Questions).

### M2. Pendant le chargement ou en erreur, le second adulte voit encore la rubrique « Paiements » personnelle (F7)

- **Où** : `lib/features/mon_espace_adulte/mon_espace_adulte_page.dart:272-284`. La rubrique est retirée seulement si la ligne famille lue vaut `forfaitFamille`. Le commentaire le dit : « Tant que la ligne famille n'est pas lue, la rubrique reste. »
- **Ce qui est faux** : F7 interdit une permission tenue par un bouton masqué. Ici, c'est pire : la rubrique est affichée par défaut, puis masquée quand la donnée arrive. Un second adulte en erreur réseau garde une entrée vers des paiements personnels qu'il n'a pas tant qu'il est rattaché (F10).
- **À faire** : ne pas afficher la rubrique « Paiements » tant que la ligne famille n'est pas lue (squelette à sa place), ou faire rendre la liste des rubriques par la même lecture. Ajouter un test : second adulte, lecture en erreur, aucune rubrique « Paiements ».
- **Décision du directeur** : non.

### M3. Texte E5 non appliqué : « Validation refusée par la direction » au lieu de « Validation Admin refusée »

- **Où** : `assets/i18n/fr.i18n.json:3954` (« Validation refusée par la direction ») ; justification dans `lib/features/foyer/place_adulte.dart:195-196` (règle K-53.6 qui interdit le mot « admin »).
- **Ce qui est faux** : E5 = a fixe le libellé « Validation Admin refusée » avec « Faire une nouvelle demande » (ce second texte est bon, `fr.i18n.json:3955`). Le code a remplacé le premier sans décision écrite. Le vocabulaire est aussi incohérent : « direction » (`:3954`), « validation administrative » (`:3953`), « l'administration » (`:4026`, `:4068`).
- **À faire** : faire trancher par le directeur entre E5 mot pour mot et K-53.6, puis unifier un seul mot dans toutes les clés `adulte.*`.
- **Décision du directeur** : oui.

### M4. Contrat C : une surface de carte recopiée, et des écrans de résultat faits maison

- **Où** :
  - `lib/features/foyer/invitation_conjoint.dart:842-870` : `_Carte` compose sa propre `DecoratedBox(AppElevation.avecFilet(...))`. Or `lib/core/widgets/app_card.dart:16` dit que `AppCard` est le seul point d'entrée d'une surface. `_Carte` est réutilisée par `reprise_foyer.dart:428` (`_ListeGroupee`, `:405-445`).
  - `invitation_conjoint.dart:737-770` (`_Resultat`) et `acceptation_invitation.dart:497-590` (`_PageEtatInvitation`) refont un écran de résultat sans `EcranResultat`, alors que `sortie_forfait.dart:378` l'utilise.
  - `invitation_conjoint.dart:875-899` (`_Actions`) refait la rangée d'actions de `EtatSysteme(actionsContratB: true)`, comme son commentaire le dit.
- **Ce qui est faux** : UX_REVIEW_07, contrat C : « Aucun nouveau composant partagé ». La liste des composants à réutiliser cite `AppCard`, `EcranResultat`, `EtatSysteme`.
- **À faire** : remplacer `_Carte` par `AppCard` ; passer `_Resultat` et `_PageEtatInvitation` sur `EcranResultat` ou `EtatSysteme`. Si un composant ne convient pas, l'écrire dans le code et le noter pour HU-1, sans le recopier.
- **Décision du directeur** : non.

### M5. Accueil et Ma classe n'ont pas d'état hors ligne au niveau de la page

- **Où** : `lib/features/accueil_adulte/accueil_adulte_page.dart` et `lib/features/ma_classe_adulte/ma_classe_adulte_page.dart` : aucune occurrence de `horsLigne`. Un échec de lecture sans réseau tombe dans l'erreur générique de `BlocAsynchrone`. Seul l'emplacement de séance CL-4 gère le hors ligne (`accueil_adulte_page_test.dart:224`, `ma_classe_adulte_page_test.dart:280`).
- **Aggravant** : la vraie route force le hors ligne à faux (`demo_adulte_page.dart:746` et `:1238`). L'état hors ligne des écrans adultes n'est donc jamais atteint depuis la coquille ; EA-12 ne l'a comblé que pour la recharge (RAPPORT, trou n° 1).
- **Ce qui est faux** : DESIGN-GOV demande cinq états par écran ; ici quatre. Les autres écrans (Mon espace, Ma famille, invitation, recharge, reprise, sortie, soldes) l'ont.
- **À faire** : ajouter la branche « erreur et hors ligne » vers `EtatSysteme(nature: NatureEtat.horsLigne)`, comme `soldes_foyer.dart:67-70`. Ajouter un paramètre de démonstration `&reseau=coupe` pour l'atteindre depuis `/demo/adulte`, et un test par écran.
- **Décision du directeur** : non.

### M6. « Se déconnecter » appelle le vrai service d'authentification depuis `/demo/adulte` (K-28, F24, §17)

- **Où** :
  - `lib/features/mon_espace_adulte/mon_espace_adulte_page.dart:428` : Mon espace reprend `CarteDeconnexion`.
  - `lib/features/compte/compte_tuteur_page.dart:522-530` : si `fermerDemo()` rend `false`, la carte appelle `ref.read(serviceAuthProvider).deconnexion()`.
  - `lib/core/session/session_controleur.dart:94-97` : `fermerDemo()` rend `false` quand `_demoActive` est faux.
  - `lib/features/demo/demo_adulte_page.dart:452-461` : `_SessionAdulteDemo` ne surcharge que `build()`. `_demoActive` reste donc faux.
  - `demo_adulte_page.dart:723-847` : la coquille adulte ne surcharge pas `serviceAuthProvider`. C'est le vrai service Supabase.
- **Ce qui est faux** : dans la démonstration, confirmer « Se déconnecter » part vers le vrai serveur. C'est un appel réseau réel depuis un écran censé n'en faire aucun (K-28, F24). Si une vraie session existe sur l'appareil, elle est fermée.
- **Test** : aucun test ne tape ce bouton. `mon_espace_adulte_page_test.dart:157` et `:400` vérifient seulement sa présence.
- **À faire** : surcharger `serviceAuthProvider` par un faux dans la coquille adulte, ou faire que la session adulte de démonstration rende `true` à `fermerDemo()`. Ajouter un test qui tape « Se déconnecter » depuis `/demo/adulte`, confirme, et vérifie qu'aucun service réel n'est appelé.
- **Décision du directeur** : non.

## Mineurs

| N° | Constat | Fichier:ligne | À faire |
|---|---|---|---|
| m1 | « Faire une nouvelle demande » est au bord de début, avec 12 au-dessus au lieu de 16. Le contrat B veut l'action qui poursuit au bord de fin. | `lib/features/foyer/foyer_page.dart:225, 231-232` | `AlignmentDirectional.centerEnd` et `Ecart.vLg`. |
| m2 | 20 au lieu de 16 entre les profils et « Ajouter un profil élève » sur téléphone (contrat A). | `lib/features/foyer/foyer_page.dart:246` | `Ecart.vLg`, sauf si c'est voulu comme séparation de groupe : l'écrire. |
| m3 | Les soldes du foyer ne portent pas le mot « Démonstration » : « 120 unités », « 80 unités », « 215 unités au total ». E2 = c demande un libellé de démonstration ; la recharge, elle, l'a (« Solde de démonstration A »). Seul le repère global le dit. | `lib/features/demo/adulte_demo.dart:527-547` (recharge : `:567-573`) | Libeller les soldes comme la recharge (« Solde de démonstration … »), ou faire confirmer que le repère global suffit. |
| m4 | Les prix de recharge « 5,00 € » et « 10,00 € » viennent de la planche, sans marque « Démonstration » sur le libellé. F12 : « tout vient des données de démonstration, marqué Démonstration ». | `lib/features/demo/adulte_demo.dart:567, 572` | Marquer le prix (« 5,00 € (démonstration) ») ou le remplacer par un libellé neutre de démonstration. |
| m5 | La clé « Bientôt épuisé » est écrite dans Flutter. Le seuil n'est pas calculé (l'exception vient du port), mais F12 cite ce texte comme exemple interdit. | `assets/i18n/fr.i18n.json:3921` ; `lib/core/capacites/port_paiements_foyer.dart:46-52` ; `lib/features/compte/soldes_foyer.dart:126` | Faire rendre le libellé de l'exception par le serveur (EA-BR-23), ou noter une exception écrite à F12. |
| m6 | Le sélecteur de démonstration écrit « 60 jours », « 120 jours », « 30 jours » en dur (F12, F17). Déjà relevé par EA-12 (Défaut n° 1). | `assets/i18n/fr.i18n.json:4156-4157, 4161-4162, 4165` | Tourner les libellés sans chiffre (« Premier délai en cours », « Délai suivant »), ou écrire l'exception dans F17. |
| m7 | Le cas 25 « Émancipation » figure dans le sélecteur avec la phrase « Un élève devenu adulte garde toutes ses données. », mais aucun écran ne change pour cet état : il montre le foyer ordinaire. La démonstration affirme ce qu'elle ne montre pas (F19 non construite). | `lib/features/demo/adulte_demo.dart:100-101` ; `assets/i18n/fr.i18n.json:4172` ; aucune branche `EtatDemoAdulte.emancipation` ailleurs | Retirer le cas du sélecteur, ou le libeller « Non construit dans cette vague (F19) ». |
| m8 | Aucun test en sens droite-à-gauche sur les écrans de la vague. EA-12 point 3 demande le « test arabe simulé » ; UX_REVIEW_07 demande de contrôler le sens des deux boutons de l'acceptation. Le seul test RTL du dossier `foyer` est antérieur à la vague. | `test/features/foyer/accessibilite_foyer_test.dart` (hors diff) ; rien sous `test/features/adulte_recette/` | Ajouter un test `TextDirection.rtl` sur l'acceptation (Refuser et Accepter), la recharge et Ma famille. |
| m9 | Captures : EA-12 point 3 demande chaque écran et les 25 cas ; RAPPORT EA-12 assume une couverture partielle (point ouvert n° 5). | `05_recette/EA/RAPPORT.md:149` | Lister à la planche EA-RC les cas non capturés, au lieu de les laisser implicites. |
| m10 | E4 : l'invitation demande aussi le prénom (obligatoire) et le nom (facultatif), en plus de l'adresse. Si « e-mail seul » vise le canal d'envoi (Q8 d'UX_REVIEW_07), c'est conforme. Si E4 vise les champs, c'est un écart (minimisation, F23, Q7). | `lib/features/foyer/invitation_conjoint.dart:75-99, 426-451` ; `assets/i18n/fr.i18n.json:3969-3975` | Faire préciser E4 ; ne rien retirer avant. |
| m11 | Les ~20 libellés sans source relevés en EA-6 sont marqués provisoires (D4), pas sourcés. C'est conforme à D4, mais ils restent à valider. | `lib/features/foyer/invitation_conjoint.dart:14-15, 432, 446, 499, 517, 550, 672, 710, 748` ; `mon_espace_adulte_page.dart:268, 281, 290, 351` | Les lister dans un tableau unique pour le directeur à EA-RC (clé, texte, raison). |
| m12 | La réponse tardive après annulation (majeur EA-6) est corrigée par une fonction pure appliquée à un état fixe. Aucune réponse n'arrive pendant que l'écran est ouvert. | `lib/features/demo/adulte_demo.dart:291-312` ; test `test/features/foyer/inviter_conjoint_test.dart:447-479` | Suffisant pour la démonstration. Garder la ligne serveur EA-BR-15 (§17 : « réponse réseau tardive ne doit jamais rattacher un adulte »). |
| m13 | Messages hors ligne « Rien n'est envoyé » : juste seulement si aucun appel ne part hors ligne. Non vérifié dans cette revue. | `assets/i18n/fr.i18n.json:3984, 3996, 4029, 4063, 4096, 4124` | Ajouter un test par mutation : hors ligne, le port n'est jamais appelé. |
| m14 | « Ajouter ma famille » (adulte seul) mène à une page provisoire sans action : « L'ajout de votre famille arrivera dans une prochaine étape. » Le découpage ne prévoyait que la ligne. Mais RAPPORT EA-12 compte le critère §21-1 comme « OK », ce qui est faux : le parcours n'existe pas. | `lib/features/demo/demo_adulte_page.dart:951-955` ; `assets/i18n/fr.i18n.json:3885` ; `05_recette/EA/RAPPORT.md:35` ; `02_DECOUPAGE.md:43` | Passer le critère 1 à « non construit » dans le RAPPORT ; inscrire le besoin dans EA-BR ou au tableau ; question 6 au directeur. |
| m15 | « Refuser l'invitation » (second adulte) : les tests vérifient sa présence et sa position, mais aucun ne le tape. | `test/features/foyer/acceptation_invitation_test.dart:201, 211, 218` | Ajouter un test qui tape Refuser depuis `/demo/adulte` et vérifie l'état rendu. |
| m16 | Les tests montent leur propre `GoRouter(routes: routesDemoAdulte('dev'))` et jamais `routeurProvider`. Rien ne prouve que `app_router.dart:1076` inclut la route dans l'application réelle. Le chemin existe bien à la lecture (`app_router.dart:1076`, `redirection.dart:57-58`). | `test/features/foyer/inviter_conjoint_test.dart:45` (même motif ailleurs) | Ajouter un test qui ouvre `/demo/adulte` par `routeurProvider` hors production. |
| m17 | Les soldes du titulaire en démonstration sont en « unités », mais l'unité du solde n'est pas fixée (Q9, doc §20.3). La recharge, elle, évite l'unité. | `lib/features/demo/adulte_demo.dart:527-547, 557-563` | Aligner sur la recharge : un libellé de démonstration sans unité. À traiter avec m3. |

## Questions au directeur

1. ~~**Paiements et second adulte (M1).**~~ Retirée : décidé par E3 = a (voir le complément en tête). Quand la conjointe ou le conjoint fait partie du forfait, doit-il voir une page « Paiements du foyer » avec l'historique des paiements que vous faites ? Ou ne doit-il voir aucune rubrique de paiements tant qu'il est rattaché ? La consigne de cette revue dit « aucune » (E3 = a). Le code fait l'inverse.
2. **Le mot pour l'administration (M3).** Sur la ligne de la place, voulez-vous « Validation Admin refusée » (votre décision E5), ou « Validation refusée par l'administration » ? Une règle du projet (K-53.6) interdit le mot « admin » à l'écran. Un seul mot sera ensuite utilisé partout.
3. **L'invitation (m10).** « E-mail seul » veut-il dire : on envoie l'invitation seulement par e-mail ? Ou : on ne demande que l'adresse, sans le prénom ni le nom ?
4. **Les soldes de démonstration (m3, m4).** Le repère « Démonstration » en haut de l'écran suffit-il, ou chaque solde et chaque prix doit-il porter le mot ?
5. **Décisions du 27/09.** Le texte de E1 à E8, D4 et D5 n'est écrit dans aucun fichier du pilotage. Peut-on l'ajouter à `16_eleves_adultes/00_REPRISE.md`, avec vos mots, pour que les prochaines sessions ne les devinent pas ?
6. **Ajouter ma famille (m14).** Un adulte seul qui touche « Ajouter ma famille » arrive aujourd'hui sur une page « arrivera dans une prochaine étape ». Dans quelle vague voulez-vous ce parcours : celle du questionnaire d'accueil, ou une étape à ajouter ici ?

## Décisions du 27/09 (d'après le résumé de la consigne)

| Décision | Résultat | Preuve |
|---|---|---|
| E1 = a (4 destinations, famille depuis Mon espace) | Conforme | `demo_adulte_page.dart:428-445` ; ligne famille unique `mon_espace_adulte_page.dart:309-341` ; aucune entrée famille dans `accueil_adulte_page.dart`. Réserve : la coquille adulte n'existe que dans la démonstration. |
| E2 = c (solde sans taux, libellé de démonstration) | En partie | Aucun taux. Recharge marquée « Solde de démonstration A » (`adulte_demo.dart:567-573`). Soldes non marqués (m3, m17). |
| E3 = a (pas de rubrique Paiements pour le second adulte) | Écart | M1, M2. |
| E4 = a (e-mail seul ; « Continuer » puis « Envoyer l'invitation ») | Boutons conformes ; champs à préciser | `fr.i18n.json:3978, 3983` ; `invitation_conjoint.dart:214` ; m10. |
| E5 = a (« Validation Admin refusée » + « Faire une nouvelle demande ») | Écart de mot | M3 ; bouton conforme `fr.i18n.json:3955`, relance de l'invitation `demo_adulte_page.dart:1214-1215`. |
| E6 = a | Conforme selon la lecture du code | Carte du titulaire en tête puis place, profils, « Ajouter un profil élève » (`foyer_page.dart:185-246`). Texte de la décision non lu. |
| E7 = a (« Informations légales » au lieu de la version) | Conforme | `mon_espace_adulte_page.dart:20-23, 382-386` ; `fr.i18n.json:2116`. Aucune version affichée. |
| E8 = a | Non vérifiable | Aucune citation de cette décision dans le code ni dans le pilotage. |
| D5 = a (« L'envoi n'a pas été confirmé. Vérifiez avant de réessayer. ») | Conforme | `fr.i18n.json:3985-3986, 3999-4000, 4030-4032, 4060-4062, 4097-4098, 4123, 3911-3912`. Aucun « n'a pas été envoyé » dans les clés adulte. |
| D4 = a (libellés provisoires marqués dans le code) | Conforme | Voir m11. |

## Les 4 majeurs notés sur EA-6

Aucun fichier de revue EA-6 n'a été trouvé ; la trace est le message du commit `6c6633a` (EA-6c).

| Majeur EA-6 | Résultat | Preuve |
|---|---|---|
| Réponse tardive après annulation non simulée | Corrigé (démonstration) | `adulte_demo.dart:291-312` ; test `inviter_conjoint_test.dart:447-479`, qui échoue si quelqu'un est rattaché. Réserve m12. |
| Message d'erreur réseau de l'envoi qui affirmait ce que le client ignore | Corrigé | `fr.i18n.json:3985-3986` ; `invitation_conjoint.dart:119-142`. |
| Message d'erreur réseau de l'annulation, idem | Corrigé | `fr.i18n.json:3999-4000`. |
| ~20 libellés sans source | Marqués provisoires (D4), pas sourcés | m11. |

## Matrice des droits (§16) et sécurité (§17)

| Ligne | Résultat | Preuve |
|---|---|---|
| Second adulte : ni enfants, ni Foyer, ni soldes, ni recharge | Conforme, par absence de données (F7) | Le Foyer et ses surcharges ne sont montés que pour le titulaire (`demo_adulte_page.dart:673`, surcharges `:1223-1274`) ; la coquille du second adulte ne les surcharge pas (`:723-847`) ; `ecranPermisDemoAdulte` le renvoie ailleurs (`:246-315`). |
| Second adulte : paiements du titulaire | Écart | M1, M2. |
| Titulaire : rien de pédagogique sur le conjoint | Conforme | Accueil et Ma classe du second adulte gardent le fournisseur réel (`demo_adulte_page.dart:734-744`, `adulte_demo.dart:252-260`). Soldes du conjoint sans photo ni Classe (`adulte_demo.dart:508-534`). |
| Enseignant : rien du foyer | Conforme selon le test cité par EA-12 | `ma_classe_adulte_page_test.dart:142` (non rejoué). |
| Admin seul valide | Conforme côté client | Aucun bouton de validation ; reprise ouverte au seul second adulte (`demo_adulte_page.dart:263-269`). |
| Recharge initiée par le titulaire seul | Conforme | `recharge_foyer_adulte_test.dart:448` (cité par EA-12). |
| §17 : aucun prix ni remise codés, aucun délai calculé | Conforme pour les écrans ; exceptions de démonstration | Remise jamais rendue (`adulte_demo.dart:557-563`) ; date de délai donnée (`:139-141, 195-203`) ; m4 à m6. |
| §17 : aucun faux succès au paiement | Conforme | `payer` lève `CapaciteIndisponible('EA-BR-25')` (`demo_adulte_page.dart:1437`) ; textes `fr.i18n.json:3911-3914`. |
| §17 : aucune mutation ni appel réel depuis Flutter | Écart | M6 (déconnexion réelle). Les autres ports sont des doubles de démonstration (`demo_adulte_page.dart:1321-1463`). |
| Mention « Démonstration » et données synthétiques | Conforme | `RepereDemonstration` sur les trois coquilles (`demo_adulte_page.dart:665, 848, 1275`) ; index : `t.adulte.demo.mention` (`fr.i18n.json:4136`) ; e-mails `@example.com` (`adulte_demo.dart:495, 715`) ; dates 2026 ; foyer Diallo fictif. |
| Démonstration fermée en production | Conforme | `routesDemoAdulte` vide hors environnement autorisé (`demo_adulte_page.dart:331-332`) ; `mode_demonstration.dart:52-55`. Réserve héritée, hors vague : un environnement non déclaré vaut « developpement » (voir REVUE_AD-R m13). |

## Fait réel (K-07)

- **Accès** : `main.dart` → `app.dart:46` (`routeurProvider`) → `app_router.dart:1076` (`routesDemoAdulte`) → `demo_adulte_page.dart:331-357`. Redirection ouverte à `/demo/adulte` (`redirection.dart:57-58`). Limite : m16.
- **Boutons tapés depuis la vraie route par un test** : Recharger (`recharge_foyer_adulte_test.dart:143`, `paiements_foyer_adulte_test.dart:208`) ; Vérifier, Modifier (`recharge_foyer_adulte_test.dart:221, 272`) ; Payer (`:291, 405, 657`) ; Envoyer l'invitation (`inviter_conjoint_test.dart:351`) ; Annuler l'invitation (`:440`) ; Accepter (`acceptation_invitation_test.dart:224`) ; Quitter le forfait (`sortie_forfait_test.dart:256`) ; Retirer (`:407`) ; Compris (`:170, 267`) ; Déposer la demande (`reprise_foyer_test.dart:174`) ; Refuser la demande (`:318`) ; Faire une nouvelle demande (`ma_famille_adulte_test.dart:466`) ; Ajouter un profil élève (`:357`) ; Historique des paiements (`paiements_foyer_adulte_test.dart:325`) ; rubriques de Mon espace (`mon_espace_adulte_page_test.dart:450-478`).
- **Jamais tapés** : Se déconnecter (M6) ; Refuser l'invitation (m15).
- **Impasses** : « Ajouter ma famille » (m14). Coran provisoire (hors périmètre, `02_DECOUPAGE.md:28`, note seulement). « Mes accords » et « Cours et accès » indisponibles, assumés (EA-BR-08, EA-BR-09) et testés.
- **Boutons inertes** : aucun `() {}` ni `onPress: null` permanent dans les fichiers de la vague.

## K-42 et DESIGN-GOV

- **CTA au bord de fin, sans pleine largeur sur bureau** : conforme, sauf m1. Preuves : `soldes_foyer.dart:178-189`, `reprise_foyer.dart:375-396`, `recharge_foyer.dart:452-466`, `sortie_forfait.dart:439, 520`, `invitation_conjoint.dart:481, 562, 574, 726, 765`. Seule pleine largeur : « Ajouter un profil élève » sur téléphone (`foyer_page.dart:196`). Dérogation Q5 voulue sur l'acceptation (`acceptation_invitation.dart:440-468`).
- **Composants partagés** : M4.
- **Chargement** : conforme. `BlocAsynchrone` et `Skeleton` partout ; aucun `CircularProgressIndicator` ajouté par la vague.
- **Durées** : conforme. Aucune `Duration` littérale ni `Future.delayed` littéral dans les écrans ; la latence de démonstration vaut `Mouvement.maximum` (`demo_adulte_page.dart:1467`).
- **Cinq états** : conforme sauf M5.
- **K-41** : conforme. Aucun `Text('…')` littéral, aucune phrase par concaténation dans les écrans ; partout `AlignmentDirectional` et start/end. Données de démonstration en français dans les fichiers de démonstration seulement (`adulte_demo.dart:225-227`, `mode_demonstration.dart:169, 180`), acceptable. Pas de test RTL : m8.

## Conformité F1-F24

| Règle | Résultat | Preuve |
|---|---|---|
| F1 Foyer sans fusion de comptes | Conforme | Ports séparés, surcharges par vue (`demo_adulte_page.dart:673, 723-847, 1223-1274`). |
| F2 Titulaire unique, pas de « proche adulte » | Conforme | Aucun `procheAdulte` dans `lib/` hors code généré ; test `formulaire_profil_eleve_test.dart:200` (cité par EA-12). |
| F3 Libellés selon le genre | Conforme | `fr.i18n.json:3946-3949` ; `ma_famille_adulte_test.dart:277`. |
| F4 Invitation neutre | Conforme (tests cités, non rejoués) | `acceptation_invitation_test.dart:358` ; `inviter_conjoint_test.dart:265, 686`. |
| F5 Dix états de l'invitation | Conforme, réserve m12 | `inviter_conjoint_test.dart:539` ; `adulte_demo.dart:291-312`. |
| F6 Conjoint n'est pas tuteur | Écart | M1 (paiements du titulaire). Enfants et pédagogie : conformes. |
| F7 Pas de permission par masquage | Écart | M2. |
| F8 L'enseignant ne voit rien du foyer | Conforme (test cité) | `ma_classe_adulte_page_test.dart:142`. |
| F9 Un profil, un solde | Conforme | Récapitulatif rendu, jamais additionné (`port_paiements_foyer.dart:97-99`). |
| F10 Vue minimale du titulaire | Conforme côté titulaire | `port_paiements_foyer.dart:57-59` ; second adulte : M1. |
| F11 Recharge, récapitulatif séparé | Conforme (tests cités) | `recharge_foyer_adulte_test.dart:170, 225` ; libellés `fr.i18n.json:3903-3906`. |
| F12 Aucun chiffre économique en dur | Écart mineur | m4, m5, m6. |
| F13 Pas de succès local au paiement | Conforme | `demo_adulte_page.dart:1437` ; `fr.i18n.json:3911-3914`. |
| F14 Les deux adultes peuvent sortir | Conforme | `sortie_forfait.dart` (ConfirmDestructive) ; `sortie_forfait_test.dart:256, 407`. |
| F15 Une sortie ne supprime rien | Conforme | Textes du doc §19 contrôlés par `sortie_forfait_test.dart` (cité). |
| F16 Personne ne disparaît en silence | Conforme (tests cités) | `sortie_forfait_test.dart` (notifications des deux côtés). |
| F17 Délai rendu, jamais calculé | Conforme pour les écrans | `adulte_demo.dart:139-141, 195-203` ; exception du sélecteur m6. |
| F18 Reprise = succession | Conforme | `reprise_foyer.dart` ; `reprise_foyer_test.dart:174, 280, 318`. |
| F19 Émancipation | Non vérifiable | Parcours absent (déjà signalé, `00_REPRISE.md:35`) ; m7. |
| F20 Espaces séparés, 4 destinations, une seule entrée famille | Conforme | `demo_adulte_page.dart:428-445` ; `mon_espace_adulte_page.dart:309-341`. |
| F21 État de la place sur sa ligne | Conforme | `place_adulte.dart:200-226` ; `ma_famille_adulte_test.dart:209`. |
| F22 Textes du doc §19 mot pour mot | Non vérifiable en entier | Contrôles ponctuels seulement (RAPPORT, point ouvert 2). Pas refait ici. |
| F23 Droit anglais, minimisation | Non vérifiable côté client | Surtout serveur ; voir m10 sur les champs de l'invitation. |
| F24 Démonstration seulement | Écart | M6 ; le reste conforme (route gardée, ports de démonstration). |

## Ce qui est bien

- Les permissions tiennent par l'absence de données, pas par des boutons cachés : le second adulte ne reçoit ni enfants, ni soldes, ni recharge (F7), sauf le point M1 et M2.
- Les échecs réseau disent ce que le client sait : « n'a pas été confirmé. Vérifiez avant de réessayer. » partout (D5). Aucun faux succès au paiement (F13).
- Aucune date de délai calculée, aucune remise, aucun taux dans les écrans (F12, F17).
- K-41 tenu : aucun texte en dur dans les écrans, start et end partout.
- Chargement par `BlocAsynchrone` et `Skeleton`, aucune durée littérale (contrat E).
- Réutilisation réelle de l'existant (K-51) : `FoyerPage`, `PaiementsComptePage`, `NotificationsPage`, `FormulaireProfilEleve`, `CarteIdentiteCompte`.
- Presque chaque bouton important est tapé par un test depuis la vraie route `/demo/adulte`.
- Le rapport EA-12 est honnête sur ses limites (F19, F22, captures partielles) ; il ne surestime qu'un critère (m14).
- Chaque besoin serveur a sa ligne dans `EA-BR.md`.

## Bilan

**6 majeurs, 17 mineurs.** Deux majeurs (M1, M3) attendent une décision du directeur avant correction. Les quatre autres (M2, M4, M5, M6) se corrigent en EA-RC sans attendre. Les tests et l'analyse n'ont pas été rejoués dans cette revue.

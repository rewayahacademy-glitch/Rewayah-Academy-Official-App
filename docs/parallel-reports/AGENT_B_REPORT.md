# AGENT_B_REPORT

`ENS-03`, **la salle vue par l'enseignant** : le contenu présenté au groupe.

Agent B, 20 septembre 2026. Base : `BASELINE_SHA = 550e605`, plus le socle salle
(`SOCLE_SALLE_REPORT.md`, contenu présenté, états `instable` / `retabli`,
conversion `sourate:verset` → page).

> **Ce lot n'a lancé aucune commande Dart.** `flutter analyze`, `flutter test`,
> `dart run slang` et `build_runner` sont interdits aux agents métier : la
> vérification est centralisée chez l'Agent Z. Ce rapport ne dit donc nulle part
> « vert ». Il dit ce qui est écrit, ce qui est mesuré **par des tests écrits mais
> non exécutés**, et ce qui reste ouvert.

---

## 1. Les fichiers touchés, sans exception

| Fichier | Nature | Quoi |
| :--- | :--- | :--- |
| `lib/features/salle_enseignant/panneau_enseignant.dart` | créé | `PanneauEnseignantSalle`, le seul point d'entrée public, et ses sous-widgets privés |
| `lib/features/salle_enseignant/vue_presentation.dart` | créé | `VuePresentation` + `PhasePresentation` : la fonction pure de la surface |
| `lib/features/salle_enseignant/presentation_coran.dart` | créé | les deux providers de lecture du moteur et `PresentateurCoran` (les deux gestes de publication) |
| `test/features/salle_enseignant_test.dart` | créé | 4 tests purs + 16 tests de widget |
| `docs/parallel-reports/i18n_B.json` | créé | 20 clés sous `enseignant.salle.*` |
| `docs/parallel-reports/CONTRACT_REQUEST_B.md` | créé | une demande haute (`VueSalle.peutPresenter`), une différée |
| `docs/parallel-reports/AGENT_B_REPORT.md` | créé | ce fichier |

**Aucun fichier hors périmètre n'a été modifié.** Ni `lib/features/salle/**`, ni
`lib/core/**`, ni `assets/i18n/**`, ni `test/support/harnais.dart`, ni
`pubspec.yaml`, ni `supabase/**`. Vérifiable par `git status`.

---

## 2. L'API publique exposée

```dart
class PanneauEnseignantSalle extends ConsumerWidget {
  const PanneauEnseignantSalle({required this.seanceId, super.key});
  final String seanceId;
}
```

Nom, fichier et signature exactement ceux de `TEACHER_FILE_OWNERSHIP.md` §3.
**Rien d'autre n'est destiné à sortir du dossier** : `VuePresentation`,
`PhasePresentation`, `PresentateurCoran`, `SortPresentation`,
`etatLienSalleProvider` et `contenuPresenteProvider` sont publics dans leur
fichier mais internes à la feature, et tous les widgets sont privés.

---

## 3. Ce que le panneau fait, et ce qu'il ne fait surtout pas

La hiérarchie de la salle est tenue dans l'ordre : **contenu pédagogique**, puis
**contrôles pédagogiques**, puis **information secondaire**. Les niveaux « média
utile » et « contrôles média » ne sont pas les siens : ils appartiennent à
`salle_page.dart`, qui les rend déjà pour les quatre rôles.

| Fonction demandée | Où elle est | Pourquoi |
| :--- | :--- | :--- |
| micro fermé à l'entrée, activation volontaire | `salle_page.dart` (`_Commandes`) | déjà vrai pour les quatre rôles, et mesuré par `salle_test.dart`. Le panneau **n'appelle jamais** `reglerMicro` : un test le verrouille |
| caméra fermée à l'entrée | idem | idem |
| flux élève, vignette enseignant | `salle_page.dart` (`_Scene`, `_Galerie`) | le socle vient de la refaire pour six participants. La refaire ici aurait été un second écran de salle |
| quitter | `salle_page.dart` | un seul geste destructif par écran, confirmé une fois, et la sortie vers `ENS-04` appartient à l'Agent Z |
| **ouvrir le Coran / la bibliothèque** | **panneau** | feuille de sourates, clé `salle.ouvrirCoran` (qui n'avait aucun appelant depuis N3) |
| **pousser une page / un verset** | **panneau** | `PresentateurCoran`, sur le contrat du socle |
| **page présentée identifiable** | **panneau** | ligne « Présenté : page 42 sur 604 · 2:255 », toujours au-dessus du texte |
| **précédent / suivant de premier niveau** | **panneau** | deux verbes dans le flux, jamais un menu, jamais une flèche |
| **état réseau en mots** | **panneau**, sans doublon | voir §5 |
| **reconnexion sans perte** | **panneau** | voir §5 |

### Trois refus explicites

1. **aucun quatrième bandeau.** `PermanentNotice` reste posé par `salle_page` ;
   le panneau ne l'entoure pas, ne le double pas, ne le commente pas ;
2. **aucun second signal hors ligne.** `PageImmersive` refuse le bandeau de
   `PageShell` à dessein. L'état du lien vient du moteur, et de lui seul ;
3. **`reglerAudioSeul` n'est pas branché ici.** Il reste sans appelant, et c'est
   un choix : le mode « économie de données » de l'ADR-001 est un **contrôle
   média** (niveau 4 de la hiérarchie), pas un contrôle pédagogique. Le brancher
   dans le panneau du document aurait créé un deuxième endroit où l'on règle le
   média, à côté de `_Commandes` — exactement le défaut que ce lot refuse. Sa
   place est la rangée de commandes de `salle_page`, avec le micro et la caméra,
   et cette décision appartient au propriétaire de ce fichier.

---

## 4. Le point d'insertion, pour l'Agent Z

**Un seul point, dans `SallePage.build`, au slot `child:` de `PageImmersive`.**
Pas dans `commandes:` (le panneau porte du contenu, pas une rangée de boutons) et
pas dans `bandeau:`.

```dart
child: enImpasse
    ? _Impasse(cause: vue.cause, onReessayer: _entrer, onRentrer: _rentrer)
    // ENS-03 : la surface de presentation de l'enseignant, en un seul point.
    : vue.role == RoleSalle.enseignant && vue.peutPresenter
          ? _CorpsEnseignant(
              vue: vue,
              lignes: lignes,
              seanceId: widget.seanceId,
            )
          : _Corps(vue: vue, lignes: lignes),
```

avec, dans `salle_page.dart` (fichier de l'Agent Z), un composeur privé qui place
le document **avant** le média sur téléphone :

```dart
/// La salle de l'enseignant : le document d'abord, la scene ensuite.
///
/// `[RESPONSIVE]` Sur telephone, le contenu pedagogique est le premier niveau de
/// la hierarchie : il prend la plus grande part, et la scene garde la sienne
/// dessous -- jamais par-dessus, aucune barre d'outils ne couvre le Coran. Sur
/// grand gabarit, le document et le media se partagent la largeur.
class _CorpsEnseignant extends StatelessWidget {
  const _CorpsEnseignant({
    required this.vue,
    required this.lignes,
    required this.seanceId,
  });

  final VueSalle vue;
  final List<_Presence> lignes;
  final String seanceId;

  @override
  Widget build(BuildContext context) {
    final Widget panneau = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: PanneauEnseignantSalle(seanceId: seanceId),
    );

    if (AppGabarit.de(context).estLarge) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: panneau),
          Expanded(child: _Corps(vue: vue, lignes: lignes)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(flex: 3, child: panneau),
        Expanded(flex: 2, child: _Scene(vue: vue)),
      ],
    );
  }
}
```

### Les conditions, et elles comptent

1. **`vue.role == RoleSalle.enseignant`** : le rôle du **jeton**, jamais
   `sessionProvider.role` ;
2. **`vue.peutPresenter`** : ce getter n'existe pas encore, il est demandé par
   `CONTRACT_REQUEST_B` §1 (une ligne : `capacites?.peutPublierDonnees ?? false`).
   S'il est refusé, garder la seule condition de rôle : le panneau restera
   fonctionnel, mais un enseignant dont le jeton ne porte pas `can_publish_data`
   verrait des boutons que le moteur refuserait en silence ;
3. **pas en impasse** : la condition est déjà portée par `enImpasse` ci-dessus.
   Une impasse n'est pas une salle, il n'y a rien à présenter ;
4. **hauteur bornée.** Le panneau contient un `Expanded` et une liste qui défile :
   il se pose dans un `Expanded`, un `SizedBox` dimensionné ou le `child:` de
   `PageImmersive`. Dans une hauteur non bornée, il lèverait une erreur de mise en
   page. Il ne suppose rien d'autre de son parent qu'une largeur contrainte ;
5. **avant l'analyse : fusionner `i18n_B.json` et régénérer slang.** Les 20 clés
   `enseignant.salle.*` sont employées par le code et le test ; sans la fusion,
   le lot entier ne compile pas. C'est le protocole (déclarer d'abord, employer
   ensuite), pas une surprise.

Rien d'autre n'est attendu de l'Agent Z : aucune route, aucune destination,
aucun export, aucune modification de `vue_salle.dart` sauf le getter du §1 de la
demande de contrat.

---

## 5. Les états rendus, et où ils se voient

Les cinq états du protocole viennent de `EtatSalle` via `VuePresentation` ; les
états de contenu viennent de `VueLecteur`, la fonction pure du lecteur de l'élève,
réutilisée telle quelle.

| État | Rendu | Mot à l'écran |
| :--- | :--- | :--- |
| `connected` (`active`) | texte + trois commandes actives | aucun : « En direct » est déjà dans l'en-tête de la salle, le répéter prendrait la place du texte |
| `unstable` (`instable`) | texte + commandes **actives** | « Connexion faible - le tour de page peut arriver en retard chez votre groupe » |
| `reconnecting` (`reconnexion`) | texte **conservé**, commandes inertes | « Reconnexion - la page présentée est conservée, elle repartira au retour du lien » |
| `restored` (`retabli`) | texte + commandes actives | « Réseau rétabli » |
| `failed` (`echec`) | texte conservé, commandes inertes | « Connexion perdue - présentation suspendue » |
| hors salle (`absent`, `connexion`) | état vide **subi**, aucune action | « Vous n'êtes pas encore dans la salle » |
| `loading` du contenu | `Skeleton.texte(lignes: 6)`, après 200 ms | — |
| `content` | la page, découpée par sourate, en RTL, sur `surfaceQuran` | — |
| `empty` | `EmptyState` actionnable, « Ouvrir le Coran » | « Rien n'est présenté » |
| `error` de lecture | `EmptyState` + « Réessayer » (`invalidate` de la page) | « Cette page n'a pas pu être lue » — et **la référence reste affichée** : le groupe voit toujours cette page |
| corpus absent | `EmptyState` **subi**, sans « Réessayer » | « Le texte du Coran n'est pas installé » — distinct d'une panne, parce que le remède est une migration |
| référence introuvable | `LocalFeedback` | « Ce verset n'a pas pu être situé dans le mushaf. Rien n'a été envoyé à votre groupe. » |
| sans droit de présenter | aucune commande rendue, une phrase à la place | « Votre accès à cette séance ne permet pas de présenter un contenu. » |
| `offline` | **volontairement absent** | voir §3, refus n° 2 |

Aucun état n'est dit par la seule couleur (invariant **J7**), et aucun n'emprunte
la pastille de l'en-tête : ce que le panneau dit n'est pas l'état du lien pour
lui-même, c'est **ce que cet état change pour la page présentée**.

---

## 6. Les décisions qui ne se devinent pas

1. **Aucun état local « page que je présente ».** Le panneau lit
   `contenuPresenteProvider`, donc le flux du moteur, même pour ce qu'il vient de
   publier lui-même. Conséquence mesurée : avec un jeton sans `can_publish_data`,
   la demande est enregistrée, le moteur refuse en silence, et **l'écran continue
   d'afficher « Rien n'est présenté »** — il ne montre jamais une page que le
   groupe ne voit pas.
2. **Deux providers de lecture dans la feature, aucun second moteur.**
   `etatLienSalleProvider` et `contenuPresenteProvider` s'abonnent à
   `moteurSalleProvider`, le provider unique. Le premier émet `etatCourant` avant
   le flux, pour qu'un panneau monté au milieu d'une séance ouvre ses commandes
   sans attendre un changement d'état. Raison de ne pas passer l'état en
   paramètre : l'API publique du panneau est figée par le contrat de branchement.
3. **`[QURAN-STAGE]`, posé pour la première fois du dépôt.** Deux endroits : le
   modèle de présentation (`presentation_coran.dart`) et le rendu de la page
   (`panneau_enseignant.dart`), là où `position: null` est passé à `VueLecteur`.
   Aucun appel à `enregistrerPosition` n'existe dans la feature, et un test le
   verrouille (invariant **J2**).
4. **La conversion `sourate:verset` → page n'est jamais calculée ici.** Elle passe
   par `pageDuVersetProvider`. `null` vaut « je ne sais pas » : rien n'est publié,
   et l'échec se dit. Présenter la page 1 par défaut aurait ouvert la Fatiha
   devant une classe sur une requête ratée.
5. **Un seul geste à la fois.** `_enCours` refuse un second tour de page pendant
   qu'un premier est en vol : deux paquets qui se croisent feraient reculer la
   classe d'une page, et le moteur ne peut pas les remettre en ordre.
6. **Le texte du mushaf est rendu en registre de lecture**, `surfaceQuran`, dans
   la salle sombre. Ni un troisième registre inventé, ni du texte coranique sur un
   fond de scène vidéo. Taille : `AppTypography.document()`, la valeur par défaut
   du rendu de document, pas une taille posée pour cette surface.
7. **Les deux providers sont `isAutoDispose: true`, et c'est une exigence.** Un
   flux ne republie jamais « plus rien » : le dernier pointeur resterait la
   dernière valeur connue du provider, et `quitter()` efface le contenu du moteur
   sans pouvoir effacer ce cache. Sans cette fermeture, l'enseignant entrant dans
   son cours suivant verrait la page du cours précédent, et un « page suivante »
   partirait de ce pointeur périmé. Une coupure ne démonte pas le panneau, une
   sortie de salle si : la durée de vie est donc la bonne. C'est le premier usage
   d'`isAutoDispose` du dépôt (aucun `autoDispose` ailleurs dans `lib/`), écrit en
   paramètre nommé et non par le modificateur `.autoDispose`, pour que le type
   déclaré reste `StreamProvider<T>`.
8. **`[RESPONSIVE]` : les deux verbes côte à côte seulement sur grand gabarit.**
   À 390 points, et plus encore à 200 % d'échelle de texte, deux libellés complets
   dans une même rangée se tronquent — et le catalogue exige un verbe, pas une
   flèche. Ils s'empilent donc sur téléphone. Le gabarit vient de
   `AppGabarit.de(context)`, aucune largeur n'est comparée à un nombre.

---

## 7. Les tests écrits (non exécutés)

`test/features/salle_enseignant_test.dart`, 20 cas. Chacun mesure un invariant,
aucun ne vérifie qu'un widget se monte.

**Sans monter d'écran (4)** : les sept états du moteur donnent six phases
distinctes ; une coupure garde la page et ferme les commandes ; sans le droit de
présenter, aucune commande n'est active ; les bornes du mushaf ferment le geste au
bord.

**Sur l'écran (16)** : le panneau n'ouvre ni micro ni caméra et n'en porte pas la
commande ; sans contenu, il propose d'ouvrir le Coran ; hors de la salle, l'état
vide ne propose rien et le dit ; choisir une sourate publie un pointeur, page
comprise, **sans écrire aucune position de lecture** ; la page présentée est
toujours identifiable, texte compris (réception) ; précédent et suivant sont au
premier niveau et publient la page voisine ; une coupure ne vide pas la page et le
dit en mots, commande inerte ; le rétablissement se dit et rouvre les commandes ;
l'écran n'affiche que ce que le moteur a publié (refus silencieux) ; une référence
introuvable n'envoie rien et le dit ; le texte qui arrive se dit par un squelette ;
une page illisible se dit et se réessaye ; un corpus absent ne se confond pas avec
une panne ; **la page d'un cours ne suit pas dans le cours suivant** (fermeture des
deux providers à la sortie) ; 390×844 sans débordement, à l'échelle 1 **et** à
200 % ; sur grand gabarit, les deux verbes tiennent côte à côte.

Le harnais n'a pas été modifié. Les faux employés : `FauxMoteurSalle` (étendu par
le socle), `FausseSourceSession`, `hote`. Un faux **nouveau et local** au fichier
de test, `_FauxCoran` : il n'existe pas de `FauxServiceCoran` dans
`test/support/harnais.dart` (vérifié ; `test/coran/service_coran_test.dart` a son
propre faux privé, également local). Il porte un `delai`, pour la même raison que
`FauxServiceEnseignant.delai` : sans délai, l'état de chargement n'existe jamais.

Le piège du socle est respecté : **aucun `addTearDown(abonnement.cancel)` sur un
flux**. Les contenus se lisent par `dernierContenuPresente` et
`contenusPresentesDemandes`.

---

## 8. Ce qui reste ouvert, et ce dont il faut douter

1. **Rien n'a été compilé, analysé ni exécuté.** C'est la consigne, et c'est aussi
   le risque principal de ce lot. Deux endroits à vérifier en premier :
   - les 20 clés `enseignant.salle.*` doivent être fusionnées et slang régénéré
     **avant** `flutter analyze`, sinon tout le lot est rouge pour cette seule
     raison ;
   - `find.textContaining(..., findRichText: true)` sur le texte du mushaf : le
     flux continu est un `Text.rich`, et les assertions attendent `findsWidgets`
     et non `findsOneWidget` pour cette raison. Si un de ces cas échoue, c'est le
     finder qu'il faut lire, pas le rendu ;
   - le test `la page d'un cours ne suit pas dans le cours suivant` dépend du
     moment où Riverpod ferme un provider sans écouteur. Il démonte l'arbre, pompe
     jusqu'au repos, puis remonte. Si ce cas échoue seul, vérifier la fermeture
     avant de conclure quoi que ce soit sur le rendu.
2. **`peutPresenter` est câblé à `true` dans le panneau** en attendant
   `CONTRACT_REQUEST_B` §1. La condition vit donc au point d'insertion, pas dans
   la surface. C'est l'écart le plus visible de ce lot : il est nommé dans le code,
   dans la demande de contrat et ici.
3. **La composition du texte de page est dupliquée de `coran_page.dart`** (trois
   lignes : `Text.rich`, `RosaceVerset`, `Directionality.rtl`). Marquée
   `ponytail:` dans le code avec son plafond — la troisième surface qui rendra du
   Coran — et son chemin de reprise. Extraire un composant partagé maintenant
   aurait demandé un fichier dans `lib/core/widgets/`, ce que le protocole
   interdit et que `catalogue_galerie_test.dart` casse déjà.
4. **L'état vide et l'état d'erreur n'ont été mesurés qu'en pleine hauteur**
   (390×844, le panneau occupant la coquille). Dans une région courte — par
   exemple une colonne latérale basse sur tablette en paysage — `EmptyState` porte
   une icône de 64 points et deux paragraphes, et son comportement à 200 %
   d'échelle dans une hauteur réduite n'est pas mesuré. C'est un comportement du
   composant partagé, pas du panneau, mais c'est le premier endroit où un
   débordement apparaîtra.
5. **La page présentée n'est pas surlignée dans le texte.** La référence
   « 2:255 » est affichée, mais le verset visé n'est pas mis en évidence dans le
   flux. C'est un manque assumé de ce lot : surligner demanderait une décision de
   rendu sur un texte sacré, et la fiche ne la donne pas.
6. **Le contenu présenté ne survit pas à un redémarrage d'application**, seulement
   à une coupure réseau et à un remontage d'écran. Dette du socle (`§7.5`), pas de
   ce lot : elle exigerait une table d'état de séance, donc une migration.
7. **Aucune trace serveur d'un tour de page.** Voir `CONTRACT_REQUEST_B` §2.
8. **Migrations, vérifié et non touché.** Le contrat partagé annonçait `0025`
   « écrite mais non appliquée » : sur le projet `gggmtelinlpseweouyav`, `0025`
   (`role_enseignant`) **et** `0026` (`durcissement_execute_enseignant`) sont
   appliquées, et `mes_seances_enseignant_v` comme `mes_groupes_v` existent
   (lecture seule, vérifiée le 20 septembre 2026). En revanche `0020` à `0024`
   (programme, diagnostics, progression, évaluations, qualité) **ne figurent pas
   dans les migrations appliquées** : c'est un constat hors du périmètre de cet
   agent, signalé à l'orchestrateur, et aucune de ces migrations n'a été appliquée
   par B — `ENS-03` n'en dépend pas (il lit `verset` et `mushaf`, posés par `0007`
   et `0013`).

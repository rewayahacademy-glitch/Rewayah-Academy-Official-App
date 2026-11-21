// PERSONNES-UNE-PAGE, etape (f) point 2 (pilote, 21/11/2026 : « on ne perd
// aucune fonction et on ne garde pas de doublons deguises »).
//
// L'etat d'une selection de dossiers et ses gestes, sortis de la file des
// candidatures et de la liste des enseignants pour servir aussi a la page
// unique « Personnes ». Rien n'est reecrit : ce qui est retenu, « Selectionner
// la page », « Selectionner les N resultats », la barre du lot, ce qui reste
// retenu apres un lot et le geste d'une ligne sont le code de
// `candidatures_page.dart` et de `enseignants_page.dart`, deplace ici. Les
// trois pages l'appellent ; aucune ne decide un droit (le serveur refuse).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/modeles_lot_candidatures.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/barre_selection.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/menu_actions.dart';
import '../admin_candidature/geste_de_ligne.dart';
import 'libelles_candidatures.dart' show nomAffiche;
import 'lot_candidatures.dart';

/// Ce qu'une page retient pour un lot : des identifiants de candidature, dans
/// l'ordre ou ils ont ete retenus, gardes d'une page a l'autre. [L] : la ligne
/// gardee avec l'identifiant quand la page en a besoin (les gestes qu'un
/// enseignant permet en lot se lisent sur sa ligne).
class SelectionLot<L> {
  /// Les identifiants retenus. L'ordre d'insertion est garde : apres
  /// « Selectionner les N resultats », c'est l'ordre de la liste rendu par le
  /// serveur.
  final Set<String> ids = <String>{};

  /// Les lignes retenues dont la page a donne la ligne, par identifiant.
  final Map<String, L> lignes = <String, L>{};

  /// Le mode selection : la ligne coche sa case au lieu d'ouvrir.
  bool enSelection = false;

  /// La selection est celle de tous les resultats du filtre ([totalTous] est
  /// le nombre exact rendu par le serveur).
  bool tousRetenus = false;

  /// Le nombre exact de resultats du filtre, ou `null`.
  int? totalTous;

  /// La lecture de tous les resultats est en cours.
  bool lectureTous = false;

  /// La lecture de tous les resultats a echoue : la selection n'a pas change.
  bool echecTous = false;

  /// Le nombre de dossiers retenus.
  int get nombre => ids.length;

  /// Vrai sans rien de retenu.
  bool get estVide => ids.isEmpty;

  /// Vrai quand [id] est retenu.
  bool contient(String id) => ids.contains(id);

  /// Retient [id], ou le relache s'il l'etait.
  void basculer(String id, [L? ligne]) {
    if (ids.remove(id)) {
      lignes.remove(id);
    } else {
      retenir(id, ligne);
    }
    oublierTous();
  }

  /// Retient [id].
  void retenir(String id, [L? ligne]) {
    ids.add(id);
    if (ligne != null) lignes[id] = ligne;
  }

  /// Relache [id].
  void relacher(String id) {
    ids.remove(id);
    lignes.remove(id);
  }

  /// Relache tout, sans quitter le mode selection.
  void vider() {
    ids.clear();
    lignes.clear();
  }

  /// Relache tout et quitte le mode selection.
  void relacherTout() {
    vider();
    enSelection = false;
    oublierTous();
  }

  /// Entre dans le mode selection, ou en sort (la selection est alors relachee).
  void basculerMode() {
    enSelection = !enSelection;
    if (!enSelection) vider();
    oublierTous();
  }

  /// La selection n'est plus « tous les resultats ».
  void oublierTous() {
    tousRetenus = false;
    totalTous = null;
    echecTous = false;
  }

  /// « Selectionner la page » : les lignes de la page lue s'ajoutent.
  void retenirPage(Iterable<String> idsDeLaPage) {
    ids.addAll(idsDeLaPage);
    oublierTous();
  }

  /// Aucune candidature de ce lot ne peut recevoir le geste : elles restent
  /// retenues, en fin d'ordre ; le lot suivant porte sur les suivantes.
  void reporterEnFin(List<String> tentes) {
    final List<String> tentees = <String>[
      for (final String id in tentes)
        if (ids.remove(id)) id,
    ];
    ids.addAll(tentees);
  }

  /// Le serveur a rendu son rapport. Les lignes reussies sortent de la
  /// selection ; celles qui n'etaient pas dans ce lot restent retenues, puis
  /// les exclues et les refusees, en fin d'ordre. Sans reste, le mode
  /// selection se ferme. [toutRelacher] : la page relache tout apres un lot.
  /// Rend la phrase a dire (le compte, apres la reponse du serveur).
  String apresRapport(RapportLot rapport, {bool toutRelacher = false}) {
    if (toutRelacher) {
      relacherTout();
    } else {
      for (final LigneRapportLot l in rapport.lignes) {
        if (l.issue == IssueLigneLot.reussie) relacher(l.id);
      }
      reporterEnFin(<String>[
        for (final LigneRapportLot l in rapport.lignes)
          if (l.issue != IssueLigneLot.reussie) l.id,
      ]);
      if (ids.isEmpty) enSelection = false;
      oublierTous();
    }
    return rapport.rejoue
        ? t.admin.candidatures.lot.feuille.rapport.rejoue
        : t.admin.candidatures.lot.feuille.rapport.reussies(
            n: rapport.reussies,
          );
  }
}

/// « Selectionner les N resultats » : le serveur rend le nombre exact et les
/// identifiants du filtre en cours, dans l'ordre de la liste. Une lecture sans
/// effet : la selection ne change qu'a la reponse ; un echec le dit et laisse
/// la selection telle quelle. [encoreCourant] : faux quand le filtre ou le tri
/// a change pendant la lecture (la reponse ne vaut plus). [maj] : le
/// `setState` de la page ; [monte] : la page est encore a l'ecran.
Future<void> retenirTousLesResultats<L>({
  required SelectionLot<L> selection,
  required PortCandidaturesDirection port,
  required FiltreCandidatures filtre,
  required TriCandidatures tri,
  required bool Function() encoreCourant,
  required void Function(VoidCallback) maj,
  required bool Function() monte,
}) async {
  if (selection.lectureTous) return;
  maj(() {
    selection
      ..lectureTous = true
      ..echecTous = false;
  });
  try {
    final SelectionCandidatures sel = await port.selectionnerTout(
      filtre: filtre,
      tri: tri,
    );
    if (!monte()) return;
    if (!encoreCourant()) {
      maj(() => selection.lectureTous = false);
      return;
    }
    maj(() {
      selection
        ..lectureTous = false
        ..vider()
        ..ids.addAll(sel.ids)
        ..tousRetenus = true
        ..totalTous = sel.total;
    });
  } on Object {
    if (!monte()) return;
    maj(() {
      selection
        ..lectureTous = false
        ..echecTous = true;
    });
  }
}

/// Ouvre la feuille du lot sur ce que [selection] retient. Au-dela du plafond
/// du serveur, le lot porte sur les premieres retenues, dans l'ordre de la
/// liste ; la barre le dit avant.
Future<void> lancerLotDeLaSelection<L>(
  BuildContext context, {
  required SelectionLot<L> selection,
  required GesteLot geste,
  required CapacitesCandidatures capacites,
  required void Function(RapportLot rapport) onRapport,
  void Function(List<String> ids)? onAucunEligible,
}) => ouvrirFeuilleLot(
  context,
  geste: geste,
  ids: selection.ids.take(plafondLotCandidatures).toList(),
  capacites: capacites,
  onRapport: onRapport,
  onAucunEligible: selection.nombre > plafondLotCandidatures
      ? onAucunEligible
      : null,
);

/// La barre du lot : le compte (« dont N sur cette page » quand une partie de
/// la selection est sur d'autres pages), les gestes du lot que les capacites
/// ouvrent (deux boutons et un menu, ou un seul menu a l'etroit), jamais
/// grises. Hors ligne, aucun geste : la phrase dit pourquoi.
class BarreLot extends StatelessWidget {
  /// Cree la barre.
  const BarreLot({
    required this.nombre,
    required this.capacites,
    required this.horsLigne,
    required this.onRelacher,
    required this.onLancer,
    required this.cleOperation,
    this.surLaPage,
    this.gestes = GesteLot.values,
    this.parTranches = true,
    this.ecrire = true,
    this.cleBarre,
    super.key,
  });

  /// La cle de la barre elle-meme.
  final Key? cleBarre;

  /// Vrai : « Ecrire » est offert avec le droit d'agir en lot.
  final bool ecrire;

  /// Le nombre de dossiers retenus.
  final int nombre;

  /// Ceux de la page affichee, ou `null` : tous.
  final int? surLaPage;

  /// Les capacites lues au serveur.
  final CapacitesCandidatures capacites;

  /// Vrai hors connexion.
  final bool horsLigne;

  /// Les gestes proposes (ceux que toutes les lignes retenues permettent).
  final List<GesteLot> gestes;

  /// Vrai : au-dela du plafond du serveur, les gestes restent offerts et
  /// portent sur les premieres retenues ; faux : ils ne sont plus offerts.
  final bool parTranches;

  /// Relache la selection.
  final VoidCallback onRelacher;

  /// Lance un geste du lot.
  final void Function(GesteLot geste) onLancer;

  /// La cle de l'operation d'un geste.
  final Key Function(GesteLot geste) cleOperation;

  /// La cle du menu « Autres actions » (« Actions » au telephone).
  static const Key cleAutres = ValueKey<String>('barre-lot-autres');

  /// Les gestes les plus courants : des boutons a l'ordinateur.
  static const List<GesteLot> _courants = <GesteLot>[
    GesteLot.ecrire,
    GesteLot.mettreEnPause,
  ];

  @override
  Widget build(BuildContext context) {
    final l = t.admin.candidatures.lot;
    final int n = nombre;
    final int page = surLaPage ?? n;
    final bool tropNombreuses = n > plafondLotCandidatures;
    // Les gestes que les capacites ouvrent, jamais grises.
    final List<GesteLot> offerts = <GesteLot>[
      if (!horsLigne && (parTranches || !tropNombreuses))
        for (final GesteLot g in gestes)
          // « Ecrire » n'est pas un geste de la fiche : il suit le droit
          // d'agir en lot, que le serveur controle a nouveau.
          if (g.geste == null
              ? ecrire && capacites.peutAgirEnLot
              : capacites.geste(g.geste!.capacite))
            g,
    ];
    // Une seule rangee, de la hauteur d'un bouton (pilote, 21/11/2026 : la
    // barre ne mange plus la liste). A l'ordinateur, les deux gestes les plus
    // courants en boutons, le reste dans « Autres actions » ; au telephone,
    // tout dans « Actions ». Celui qui refuse en dernier, en couleur d'alerte.
    final bool etroit =
        MediaQuery.sizeOf(context).width < BarreSelection.largeurCoteACote;
    final List<GesteLot> boutons = etroit
        ? const <GesteLot>[]
        : <GesteLot>[
            for (final GesteLot g in _courants)
              if (offerts.contains(g)) g,
          ];
    final List<GesteLot> auMenu = <GesteLot>[
      for (final GesteLot g in offerts)
        if (!boutons.contains(g) && g != GesteLot.refuser) g,
      if (offerts.contains(GesteLot.refuser)) GesteLot.refuser,
    ];
    return BarreSelection.compacte(
      key: cleBarre,
      uneLigne: true,
      titre: page < n
          ? l.avecDont(
              selection: l.selectionnees(n: n),
              dont: l.dontPage(n: page),
            )
          : l.selectionnees(n: n),
      // Une phrase seulement quand elle dit pourquoi un geste manque ou sur
      // quoi il porte ; « les autres gestes se font un par un » ne prend plus
      // de place.
      phrase: horsLigne
          ? t.admin.candidatures.selection.horsLigne
          : tropNombreuses
          ? (parTranches
                ? l.parTranche(
                    n: plafondLotCandidatures,
                    reste: n - plafondLotCandidatures,
                  )
                : l.plafond(n: plafondLotCandidatures))
          : '',
      onRelacher: onRelacher,
      operations: <Widget>[
        for (final GesteLot g in boutons)
          ActionPrincipale(
            key: cleOperation(g),
            libelle: libelleGesteLot(g),
            niveau: NiveauAction.secondaire,
            compacte: true,
            pleineLargeur: false,
            onPress: () => onLancer(g),
          ),
        if (auMenu.isNotEmpty)
          MenuActions(
            key: cleAutres,
            etiquette: true,
            libelle: etroit ? t.commun.listes.actions : l.autresActions,
            actions: <EntreeAction>[
              for (final GesteLot g in auMenu)
                EntreeAction(
                  libelle: libelleGesteLot(g),
                  destructif: g == GesteLot.refuser,
                  onChoix: () => onLancer(g),
                ),
            ],
          ),
      ],
    );
  }
}

/// « Selectionner la page », puis, la page entiere retenue et d'autres
/// resultats au-dela, « Selectionner les N resultats », avec le nombre exact
/// du serveur (le geste de Gmail). Jamais en silence : la ligne dit ce qui est
/// retenu.
class LigneSelectionTous<L> extends StatelessWidget {
  /// Cree la ligne.
  const LigneSelectionTous({
    required this.selection,
    required this.idsDeLaPage,
    required this.total,
    required this.onRetenirPage,
    required this.onRetenirTous,
    super.key,
  });

  /// La selection.
  final SelectionLot<L> selection;

  /// Les identifiants de la page affichee.
  final List<String> idsDeLaPage;

  /// Le nombre de resultats du filtre.
  final int total;

  /// Retient la page affichee.
  final VoidCallback onRetenirPage;

  /// Retient tous les resultats, ou `null` : la page ne sait pas le faire.
  final VoidCallback? onRetenirTous;

  /// La cle de « Selectionner la page ».
  static const Key clePage = ValueKey<String>('candidatures-selection-page');

  @override
  Widget build(BuildContext context) {
    final s = t.admin.candidatures.selection;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final bool pageRetenue =
        idsDeLaPage.isNotEmpty && idsDeLaPage.every(selection.contient);
    final int? totalTous = selection.totalTous;
    final List<Widget> morceaux;
    if (selection.tousRetenus && totalTous != null) {
      morceaux = <Widget>[
        TexteSansCoupure(
          selection.nombre < totalTous
              ? s.tousPlafond(plafond: selection.nombre, n: totalTous)
              : s.tousRetenus(n: totalTous),
          key: const ValueKey<String>('candidatures-tous-retenus'),
          style: style,
        ),
      ];
    } else if (selection.lectureTous) {
      morceaux = <Widget>[
        const SizedBox.square(
          dimension: AppSpacing.lg,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        TexteSansCoupure(s.lectureTous, style: style),
      ];
    } else if (!pageRetenue) {
      morceaux = <Widget>[
        LienFleche(
          key: clePage,
          libelle: s.page,
          fleche: false,
          legende: true,
          alignerEnDebut: true,
          onPress: onRetenirPage,
        ),
      ];
    } else {
      morceaux = <Widget>[
        TexteSansCoupure(s.pageRetenue(n: idsDeLaPage.length), style: style),
        if (total > idsDeLaPage.length && onRetenirTous != null)
          LienFleche(
            key: const ValueKey<String>('candidatures-selection-tous'),
            libelle: s.tous(n: total),
            fleche: false,
            legende: true,
            alignerEnDebut: true,
            onPress: onRetenirTous!,
          ),
      ];
    }
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: morceaux,
          ),
          if (selection.echecTous)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: TexteSansCoupure(
                s.echecTous,
                key: const ValueKey<String>('candidatures-tous-echec'),
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Le geste d'une ligne et ce que la page en dit : le nom du dossier qui se
/// lit, l'echec en mots, le retour apres la reponse du serveur.
mixin GesteDeLigneEtat<W extends ConsumerStatefulWidget> on ConsumerState<W> {
  /// Le nom de la candidature dont le dossier se lit avant un geste du menu,
  /// ou `null`.
  String? ouvertureLigne;

  /// L'echec d'un geste du menu, dit en mots, ou `null` : rien n'a ete fait.
  String? echecLigne;

  /// Le retour du dernier geste ou du dernier lot : dit seulement apres la
  /// reponse du serveur.
  String? retourLigne;

  /// Le geste d'une ligne : lire le dossier (la ligne n'en porte ni la version
  /// ni les reponses), rappeler la table des gestes sur ce qu'on vient de lire,
  /// puis ouvrir **la meme feuille** que la fiche. Rien n'est fait si le geste
  /// n'est plus permis. [relire] : la liste se relit (filtres, tri et page
  /// gardes).
  Future<void> jouerGesteDeLigne(
    LigneCandidature ligne,
    GesteCandidature geste,
    CapacitesCandidatures capacites, {
    required VoidCallback relire,
  }) async {
    if (ouvertureLigne != null) return;
    setState(() {
      ouvertureLigne = nomAffiche(ligne);
      echecLigne = null;
      retourLigne = null;
    });
    final ResultatGesteDeLigne resultat = await lancerGesteDeLigne(
      context,
      ref,
      ligne: ligne,
      geste: geste,
      capacites: capacites,
      onLu: () {
        if (mounted) setState(() => ouvertureLigne = null);
      },
    );
    if (!mounted) return;
    if (resultat.aRelire) relire();
    setState(() {
      ouvertureLigne = null;
      if (resultat.echec) {
        echecLigne = resultat.message;
      } else if (resultat.issue != IssueGesteDeLigne.renonce) {
        retourLigne = resultat.message;
      }
    });
  }
}

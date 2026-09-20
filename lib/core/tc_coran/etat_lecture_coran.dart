import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coran/service_coran.dart';
import '../tc_bibliotheque/content_range.dart';
import 'page_mushaf_vm.dart';
import 'port_navigation_coran.dart';
import 'ports_externes/port_etat_partage.dart';

/// Ce que le lecteur regarde, ici, sur cet appareil.
///
/// **Le zoom vit ici et nulle part ailleurs.** C'est l'invariant 5 du contrat
/// `SharedContentState` et la decision D-21 : l'eleve suit automatiquement le
/// support que l'enseignant presente, mais son grossissement lui appartient.
/// Un eleve malvoyant qui a grossi son texte ne doit pas le voir retomber a
/// chaque page tournee par le professeur.
@immutable
class EtatLectureCoran {
  /// Cree un etat.
  const EtatLectureCoran({
    required this.page,
    required this.mode,
    required this.zoomLocal,
    required this.origine,
    this.plageFocus,
    this.revisionPartageeSuivie,
  });

  /// L'etat d'ouverture du lecteur.
  const EtatLectureCoran.ouverture({int page = 1, double zoom = 1})
    : this(
        page: page,
        mode: ModeRenduCoran.mushaf,
        zoomLocal: zoom,
        origine: OrigineNavigation.ouverture,
      );

  /// La page affichee.
  final int page;

  /// Le rendu courant.
  final ModeRenduCoran mode;

  /// Le grossissement choisi par ce lecteur-ci.
  final double zoomLocal;

  /// Qui a decide de la page affichee.
  final OrigineNavigation origine;

  /// La plage mise au centre en mode focus, quand il y en a une.
  final ContentRange? plageFocus;

  /// La derniere revision d'etat partage prise en compte.
  ///
  /// `null` tant qu'aucune presentation n'a ete suivie.
  final int? revisionPartageeSuivie;

  /// Le meme etat, ailleurs.
  EtatLectureCoran versPage(int page, {required OrigineNavigation origine}) =>
      EtatLectureCoran(
        page: page,
        mode: mode,
        zoomLocal: zoomLocal,
        origine: origine,
        plageFocus: plageFocus,
        revisionPartageeSuivie: revisionPartageeSuivie,
      );

  /// Le meme etat, dans un autre rendu.
  EtatLectureCoran versMode(ModeRenduCoran mode) => EtatLectureCoran(
    page: page,
    mode: mode,
    zoomLocal: zoomLocal,
    origine: origine,
    plageFocus: plageFocus,
    revisionPartageeSuivie: revisionPartageeSuivie,
  );

  /// Le meme etat, a un autre grossissement, borne comme la base le veut.
  EtatLectureCoran versZoom(double valeur) => EtatLectureCoran(
    page: page,
    mode: mode,
    zoomLocal: valeur.clamp(PositionLecture.zoomMin, PositionLecture.zoomMax),
    origine: origine,
    plageFocus: plageFocus,
    revisionPartageeSuivie: revisionPartageeSuivie,
  );

  /// L'etat resultant d'une revision d'etat partage.
  ///
  /// **Fonction pure, et c'est ce qui la rend verifiable.** Trois regles, et
  /// les trois sont des invariants de contrat :
  ///
  /// 1. Une revision inferieure ou egale a celle deja suivie est **ignoree**.
  ///    Cela couvre a la fois le paquet duplique et le paquet arrive en
  ///    desordre (contrat `SharedContentState`, invariant 1).
  /// 2. L'eleve suit **automatiquement** : aucun bouton « Revenir au
  ///    professeur » n'est requis (decision D-21).
  /// 3. [zoomLocal] **ne bouge pas**. Jamais.
  ///
  /// [pagePartagee] est la page deja resolue par la navigation : cette
  /// fonction ne lit rien, elle decide.
  EtatLectureCoran fusionnerPartage(
    SharedContentState? partage, {
    required int? pagePartagee,
  }) {
    if (partage == null) {
      return this;
    }
    final int? deja = revisionPartageeSuivie;
    if (deja != null && partage.revision <= deja) {
      return this;
    }
    return EtatLectureCoran(
      page: pagePartagee ?? page,
      mode: _modeDe(partage.displayMode),
      zoomLocal: zoomLocal,
      origine: OrigineNavigation.groupe,
      plageFocus: partage.contentRange,
      revisionPartageeSuivie: partage.revision,
    );
  }

  static ModeRenduCoran _modeDe(ModeAffichagePartage mode) => switch (mode) {
    ModeAffichagePartage.page => ModeRenduCoran.mushaf,
    ModeAffichagePartage.verse => ModeRenduCoran.versetAgrandi,
    ModeAffichagePartage.focus => ModeRenduCoran.focus,
  };
}

/// Le lecteur courant, sur cet appareil.
///
/// La persistance de la position personnelle n'est **pas** ici : elle passe par
/// [PortNavigationCoran.memoriserPositionPersonnelle], qui refuse d'ecrire une
/// page tournee par la classe. Le controleur ne fait que porter l'etat.
class ControleurLectureCoran extends Notifier<EtatLectureCoran> {
  @override
  EtatLectureCoran build() => const EtatLectureCoran.ouverture();

  /// Ouvre une page.
  void allerA(int page, {required OrigineNavigation origine}) {
    final int bornee = page.clamp(1, pagesMushafMedine);
    if (bornee == state.page && origine == state.origine) {
      return;
    }
    state = state.versPage(bornee, origine: origine);
  }

  /// Change de rendu.
  void changerMode(ModeRenduCoran mode) {
    if (mode == state.mode) {
      return;
    }
    state = state.versMode(mode);
  }

  /// Grossit ou reduit le texte, pour ce lecteur seulement.
  void zoomer(double delta) => state = state.versZoom(state.zoomLocal + delta);

  /// Pose le grossissement, par exemple celui que la position personnelle
  /// avait garde.
  void definirZoom(double valeur) => state = state.versZoom(valeur);

  /// Applique une revision d'etat partage.
  void appliquerPartage(SharedContentState? partage, {required int? page}) =>
      state = state.fusionnerPartage(partage, pagePartagee: page);
}

/// L'etat de lecture du mushaf.
final NotifierProvider<ControleurLectureCoran, EtatLectureCoran>
lectureCoranProvider =
    NotifierProvider<ControleurLectureCoran, EtatLectureCoran>(
      ControleurLectureCoran.new,
    );

/// Le double de demonstration du support actif (CAP29-G).
library;

import 'dart:async';

import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_bibliotheque/port_support_actif.dart';

/// Le support actif d'une seance, en memoire.
class SupportActifDemo implements PortSupportActif {
  /// Cree le double.
  SupportActifDemo({
    this.capacitesServeur = const CapacitesSupportActif(peutPresenter: true),
    SupportActif? depart,
  }) : _actuel = depart;

  /// Ce que la personne connectee peut faire.
  CapacitesSupportActif capacitesServeur;

  /// Vrai : la lecture et la presentation echouent, connexion perdue.
  bool panne = false;

  /// Le prochain refus du serveur, ou `null`.
  RefusActivation? refus;

  /// Les titres connus (id -> titre, type).
  final Map<String, (String, TypeRessource)> catalogue =
      <String, (String, TypeRessource)>{
        'demo-image': ('Tableau des lettres', TypeRessource.image),
        'demo-coran': ('Juz Amma', TypeRessource.quran),
        'demo-pdf': ('Les regles du Noon', TypeRessource.pdf),
      };

  SupportActif? _actuel;
  int _revision = 0;
  final StreamController<SupportActif?> _flux =
      StreamController<SupportActif?>.broadcast();
  final Set<String> _cles = <String>{};

  /// Le support actif courant.
  SupportActif? get actuel => _actuel;

  @override
  Future<CapacitesSupportActif> capacites(String seanceId) async {
    if (panne) throw const SupportActifHorsLigne();
    return capacitesServeur;
  }

  @override
  Future<ResultatActivation> activer({
    required String seanceId,
    required String resourceId,
    required int revisionAttendue,
    required String cle,
    ContentPosition? position,
  }) async {
    if (panne) throw const SupportActifHorsLigne();
    if (!capacitesServeur.peutPresenter) {
      return const ActivationRefusee(RefusActivation.nonAttribue);
    }
    // Idempotent : la meme cle ne presente pas deux fois.
    if (_cles.contains(cle)) return ActivationFaite(_actuel!);
    final RefusActivation? r = refus;
    if (r != null) return ActivationRefusee(r);
    if (revisionAttendue != _revision) return const ActivationEnConflit();
    final (String, TypeRessource)? info = catalogue[resourceId];
    if (info == null) {
      return const ActivationRefusee(RefusActivation.nonAttribue);
    }
    _cles.add(cle);
    _revision++;
    final SupportActif actif = SupportActif(
      resourceId: resourceId,
      titre: info.$1,
      type: info.$2,
      revision: _revision,
      numeroVersion: 1,
      position: position,
    );
    _publier(actif);
    return ActivationFaite(actif);
  }

  /// Le serveur retire le support presente, en cours de seance.
  void retirerEnSeance() {
    final SupportActif? a = _actuel;
    if (a == null) return;
    _revision++;
    _publier(
      SupportActif(
        resourceId: a.resourceId,
        titre: a.titre,
        type: a.type,
        revision: _revision,
        retire: true,
      ),
    );
  }

  void _publier(SupportActif? actif) {
    _actuel = actif;
    _flux.add(actif);
  }

  @override
  Stream<SupportActif?> suivre(String seanceId) async* {
    if (panne) throw const SupportActifHorsLigne();
    yield _actuel;
    yield* _flux.stream;
  }

  /// Ferme le flux.
  Future<void> fermer() => _flux.close();
}

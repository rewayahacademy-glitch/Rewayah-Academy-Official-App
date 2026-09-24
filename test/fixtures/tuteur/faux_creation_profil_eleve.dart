// Double du port de creation de profil eleve (contrat K3).
//
// PROPRIETE : coordinateur (`test/fixtures/tuteur/`). Pour les lots A et B :
// il rejoue les trois issues (cree, refuse, incertaine) sans reseau.

import 'dart:async';

import 'package:rewayah_academy/core/foyer/port_creation_profil_eleve.dart';
import 'package:rewayah_academy/core/foyer/profil_eleve_brouillon.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

/// Le port de creation, en memoire.
class FauxCreationProfilEleve implements PortCreationProfilEleve {
  /// Cree le faux, qui reussit par defaut.
  FauxCreationProfilEleve({this.resultat = const ProfilCree()});

  /// Ce que la prochaine creation rend.
  ResultatCreationProfil resultat;

  /// Les brouillons envoyes, dans l'ordre.
  final List<BrouillonProfilEleve> envois = <BrouillonProfilEleve>[];

  /// Quand il est pose, la creation attend qu'on le complete : c'est ce qui
  /// permet de regarder l'ecran PENDANT l'envoi (double soumission).
  Completer<void>? attente;

  @override
  bool peutCreer(PourQui pourQui, {required PorteAcces porte}) =>
      pourQui == PourQui.enfantOuMineur && porte == PorteAcces.actif;

  @override
  Future<ResultatCreationProfil> creer(BrouillonProfilEleve brouillon) async {
    envois.add(brouillon);
    final Completer<void>? enAttente = attente;
    if (enAttente != null) {
      await enAttente.future;
    }
    return resultat;
  }
}

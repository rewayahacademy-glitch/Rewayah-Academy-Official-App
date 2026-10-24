// Le double du port du message qui previent les candidats par e-mail, oracle
// des tests de widget de la feuille « Prevenir par e-mail » et de sa capture.
// Importe par aucune ligne de production.
//
// Il rend l'apercu et les resultats qu'on lui donne, et note chaque appel (la
// limite envoyee) pour qu'un test prouve ce qui part au serveur. Un test qui
// veut un refus le programme. **Aucune adresse ni personne reelle** : le port
// ne rend que des comptes.

import 'dart:async';

import 'package:rewayah_academy/core/candidature/port_prevenir_candidats.dart';

/// Le faux port.
class FauxPrevenirCandidats implements PortPrevenirCandidats {
  /// Cree le double. Par defaut : 5 a prevenir, 2 deja prevenus, 3 inscrits,
  /// inscription ouverte.
  FauxPrevenirCandidats({
    this.apercuRendu = const ApercuPrevenir(
      aPrevenir: 5,
      dejaPrevenus: 2,
      dejaInscrits: 3,
      inscriptionOuverte: true,
    ),
    List<ResultatPrevenir>? resultats,
  }) : resultats = resultats ?? <ResultatPrevenir>[];

  /// Ce que `apercu()` rend.
  ApercuPrevenir apercuRendu;

  /// Les resultats rendus par `prevenir()`, dans l'ordre. Epuises : le dernier
  /// apercu en deduit un resultat sans reste.
  final List<ResultatPrevenir> resultats;

  /// Si non nul, `apercu()` attend ce completer.
  Completer<ApercuPrevenir>? apercuRetenu;

  /// Si non nul, `apercu()` jette cette erreur.
  Exception? erreurApercu;

  /// Si non nul, `prevenir()` jette cette erreur (une seule fois), puis redevient
  /// normal.
  Exception? erreurPrevenir;

  /// Si non nul, `prevenir()` attend ce completer.
  Completer<ResultatPrevenir>? prevenirRetenu;

  /// Les limites envoyees a `prevenir()`, dans l'ordre.
  final List<int> limites = <int>[];

  /// Le nombre d'appels a `apercu()`.
  int appelsApercu = 0;

  @override
  Future<ApercuPrevenir> apercu() async {
    appelsApercu++;
    final Completer<ApercuPrevenir>? attente = apercuRetenu;
    if (attente != null) return attente.future;
    final Exception? e = erreurApercu;
    if (e != null) throw e;
    return apercuRendu;
  }

  @override
  Future<ResultatPrevenir> prevenir({
    int limite = limitePrevenirParDefaut,
  }) async {
    limites.add(limite);
    final Completer<ResultatPrevenir>? attente = prevenirRetenu;
    if (attente != null) return attente.future;
    final Exception? e = erreurPrevenir;
    if (e != null) {
      erreurPrevenir = null;
      throw e;
    }
    if (!apercuRendu.inscriptionOuverte) throw const InscriptionFermee();
    if (resultats.isNotEmpty) return resultats.removeAt(0);
    final int mis = apercuRendu.aPrevenir < limite
        ? apercuRendu.aPrevenir
        : limite;
    return ResultatPrevenir(
      misEnFile: mis,
      restants: apercuRendu.aPrevenir - mis,
    );
  }
}

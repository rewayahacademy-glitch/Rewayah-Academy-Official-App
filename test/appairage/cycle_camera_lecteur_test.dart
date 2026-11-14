import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/flux_camera_lecteur.dart';

/// Une fausse prise : chaque demarrage du moteur « ouvre » un flux pendant la
/// fenetre d'ecoute ; on compte ce qui est ferme.
class _FaussePrise implements PriseFluxCamera {
  bool fenetreOuverte = false;
  final List<String> capturesEnCours = <String>[];
  final List<String> fermes = <String>[];

  /// Ce que le moteur ouvre : un flux attache pendant la fenetre.
  void attacher(String flux) {
    if (fenetreOuverte) {
      capturesEnCours.add(flux);
    }
  }

  @override
  void ouvrirCapture() => fenetreOuverte = true;

  @override
  List<Object> fermerCapture() {
    fenetreOuverte = false;
    final List<Object> rendus = List<Object>.of(capturesEnCours);
    capturesEnCours.clear();
    return rendus;
  }

  @override
  void fermer(Iterable<Object> flux) => fermes.addAll(flux.cast<String>());
}

class _FauxMoteur {
  _FauxMoteur(this.prise);

  final _FaussePrise prise;
  int demarrages = 0;
  int arrets = 0;
  int liberations = 0;
  Completer<void>? attente;
  Error? erreur;
  bool fluxAvantErreur = false;

  Future<void> demarrer() async {
    demarrages++;
    final Completer<void>? c = attente;
    if (c != null) {
      await c.future;
    }
    if (erreur != null) {
      if (fluxAvantErreur) {
        prise.attacher('flux-$demarrages');
      }
      throw erreur!;
    }
    prise.attacher('flux-$demarrages');
  }

  Future<void> arreter() async => arrets++;

  Future<void> liberer() async => liberations++;
}

void main() {
  late _FaussePrise prise;
  late _FauxMoteur moteur;
  late CycleCameraLecteur cycle;

  setUp(() {
    prise = _FaussePrise();
    moteur = _FauxMoteur(prise);
    cycle = CycleCameraLecteur(
      demarrerMoteur: moteur.demarrer,
      arreterMoteur: moteur.arreter,
      libererMoteur: moteur.liberer,
      prise: prise,
    );
  });

  test('arreter ferme le flux ouvert par le demarrage', () async {
    expect(await cycle.demarrer(), isTrue);
    expect(cycle.fluxOuverts, 1);
    expect(prise.fenetreOuverte, isFalse);

    await cycle.arreter();

    expect(moteur.arrets, 1);
    expect(prise.fermes, <String>['flux-1']);
    expect(cycle.fluxOuverts, 0);
  });

  test('liberer ferme le flux ouvert par le demarrage', () async {
    await cycle.demarrer();

    await cycle.liberer();

    expect(moteur.liberations, 1);
    expect(prise.fermes, <String>['flux-1']);
    expect(cycle.libere, isTrue);
  });

  test('pause puis reprise : un flux neuf, ferme a son tour', () async {
    await cycle.demarrer();
    await cycle.arreter();
    expect(await cycle.demarrer(), isTrue);

    expect(moteur.demarrages, 2);
    expect(cycle.fluxOuverts, 1);
    await cycle.liberer();

    expect(prise.fermes, <String>['flux-1', 'flux-2']);
  });

  test(
    'start qui finit apres liberer : flux et moteur arretes aussitot',
    () async {
      moteur.attente = Completer<void>();
      final Future<bool> demarrage = cycle.demarrer();

      await cycle.liberer();
      expect(prise.fermes, isEmpty);

      moteur.attente!.complete();
      expect(await demarrage, isFalse);

      expect(prise.fermes, <String>['flux-1']);
      expect(moteur.arrets, 1);
      expect(cycle.fluxOuverts, 0);
      expect(prise.fenetreOuverte, isFalse);
    },
  );

  test('demarrer apres liberer ne touche plus au moteur', () async {
    await cycle.liberer();

    expect(await cycle.demarrer(), isFalse);
    expect(moteur.demarrages, 0);
  });

  test(
    'un echec du moteur ferme le flux ouvert avant lui et se relance',
    () async {
      moteur
        ..erreur = StateError('lecture impossible')
        ..fluxAvantErreur = true;

      await expectLater(cycle.demarrer(), throwsStateError);

      expect(prise.fermes, <String>['flux-1']);
      expect(prise.fenetreOuverte, isFalse);
      expect(cycle.fluxOuverts, 0);
    },
  );

  test('un echec sans flux ne ferme pas le flux deja en cours', () async {
    await cycle.demarrer();
    moteur.erreur = StateError('deja demarre');

    await expectLater(cycle.demarrer(), throwsStateError);

    expect(prise.fermes, isEmpty);
    expect(cycle.fluxOuverts, 1);
  });

  test('arreter et liberer sans demarrage ne ferment rien', () async {
    await cycle.arreter();
    await cycle.liberer();
    await cycle.liberer();

    expect(prise.fermes, isEmpty);
    expect(moteur.liberations, 1);
  });
}

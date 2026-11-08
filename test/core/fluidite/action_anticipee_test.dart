// FLUIDITE-1 : l'outil « afficher d'avance, revenir en arriere si echec »
// (DECISION-FLUIDITE-2026-11-07 §1 et §3).

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/fluidite/action_anticipee.dart';

void main() {
  group('ActionAnticipee', () {
    test('affichee d avance : en cours avant toute reponse', () {
      final ActionAnticipee a = ActionAnticipee(
        nature: NatureAction.instantanee,
        cle: 'k1',
        envoi: (String _) => Completer<void>().future,
      );
      expect(a.etat, EtatAnticipe.enCours);
      unawaited(a.tenter());
      expect(a.etat, EtatAnticipe.enCours);
    });

    test('reponse du serveur : confirme, avec la cle', () async {
      final List<String> cles = <String>[];
      final ActionAnticipee a = ActionAnticipee(
        nature: NatureAction.instantanee,
        cle: 'k1',
        envoi: (String c) async => cles.add(c),
      );
      expect(await a.tenter(), isTrue);
      expect(a.etat, EtatAnticipe.confirme);
      expect(cles, <String>['k1']);
    });

    test('echec puis Reessayer : la MEME cle repart, puis confirme', () async {
      final List<String> cles = <String>[];
      int essais = 0;
      final ActionAnticipee a = ActionAnticipee(
        nature: NatureAction.instantanee,
        cle: 'k-stable',
        envoi: (String c) async {
          cles.add(c);
          essais++;
          if (essais == 1) throw StateError('reseau');
        },
      );
      expect(await a.tenter(), isFalse);
      expect(a.etat, EtatAnticipe.echec);
      expect(await a.tenter(), isTrue);
      expect(a.etat, EtatAnticipe.confirme);
      expect(cles, <String>['k-stable', 'k-stable']);
    });

    test(
      'un ETAT revient en arriere a l echec (annuler), un contenu reste',
      () async {
        bool coche = true; // affiche d'avance
        final ActionAnticipee etat = ActionAnticipee(
          nature: NatureAction.instantanee,
          cle: 'k',
          envoi: (String _) async => throw StateError('refus'),
          annuler: () => coche = false,
        );
        await etat.tenter();
        expect(coche, isFalse);
        expect(etat.etat, EtatAnticipe.echec);

        // Un contenu (sans annuler) : rien n'est retire, l'echec se lit.
        final ActionAnticipee contenu = ActionAnticipee(
          nature: NatureAction.instantanee,
          cle: 'k',
          envoi: (String _) async => throw StateError('refus'),
        );
        await contenu.tenter();
        expect(contenu.etat, EtatAnticipe.echec);
      },
    );

    test('un double appui pendant l envoi ne fait qu un envoi', () async {
      final Completer<void> serveur = Completer<void>();
      int envois = 0;
      final ActionAnticipee a = ActionAnticipee(
        nature: NatureAction.instantanee,
        cle: 'k',
        envoi: (String _) {
          envois++;
          return serveur.future;
        },
      );
      final Future<bool> premier = a.tenter();
      expect(await a.tenter(), isFalse);
      serveur.complete();
      expect(await premier, isTrue);
      expect(envois, 1);
    });

    test('siConfirme et siEchec passent avant le changement d etat', () async {
      final List<String> ordre = <String>[];
      int essais = 0;
      final ActionAnticipee a = ActionAnticipee(
        nature: NatureAction.instantanee,
        cle: 'k',
        envoi: (String _) async {
          if (++essais == 1) throw StateError('x');
        },
      );
      a.addListener(() => ordre.add('etat:${a.etat.name}'));
      await a.tenter(siEchec: () => ordre.add('siEchec'));
      await a.tenter(siConfirme: () => ordre.add('siConfirme'));
      expect(ordre, <String>[
        'etat:enCours',
        'siEchec',
        'etat:echec',
        'etat:enCours',
        'siConfirme',
        'etat:confirme',
      ]);
    });

    test('ecran quitte pendant l envoi : siConfirme passe, aucune notification '
        'apres liberation', () async {
      final Completer<void> serveur = Completer<void>();
      bool effet = false;
      final ActionAnticipee a = ActionAnticipee(
        nature: NatureAction.instantanee,
        cle: 'k',
        envoi: (String _) => serveur.future,
      );
      final Future<bool> issue = a.tenter(siConfirme: () => effet = true);
      a.dispose();
      serveur.complete();
      expect(await issue, isTrue);
      expect(effet, isTrue);
    });

    test('une action SENSIBLE est refusee : elle attend le serveur', () {
      expect(
        () => ActionAnticipee(
          nature: NatureAction.sensible,
          cle: 'paiement',
          envoi: (String _) async {},
        ),
        throwsArgumentError,
      );
    });
  });
}

// COM-VOC-1 : VoiceMessageComposer (spec section 11, section 24 ; recette
// R-COM-03 et R-COM-04), rendu dans le vrai theme avec une horloge fixe et le
// faux enregistreur de la demonstration.
//
// Ce qui est verifie sur le rendu :
// - R-COM-03 : enregistrer, pause, reprendre, arreter, pre-ecouter,
//   supprimer, envoyer ; la duree ecrite ignore la pause ;
// - R-COM-04 : limite proche annoncee a 2:30, arret seul a 3:00, pre-ecoute ;
// - jamais d'envoi a l'arret : `onEnvoyer` n'est appele que par « Envoyer » ;
// - permission requise, refusee (phrase exacte, « Fermer »), port neutre ;
// - envoi non confirme puis reessai ; hors ligne : « Envoyer » non rendu ;
// - Semantics « Pause », « Reprendre », « Supprimer », « Envoyer » ;
// - branchement dans l'emplacement vocal du composer de COM-F ;
// - 390, 768, 1440 ; 320 en texte x2 ; sombre ; arabe (RTL).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_vocal/composer_vocal.dart';
import 'package:rewayah_academy/features/com_vocal/lecteur_vocal.dart';
import 'package:rewayah_academy/features/com_vocal/port_enregistreur_vocal.dart';
import 'package:rewayah_academy/features/demo/communications/com_vocal_demo.dart';

import '../../support/garde_interface.dart';
import '../../support/hote_theme.dart';
import 'support_vocal.dart';

class _Envois {
  final List<EnregistrementVocal> recus = <EnregistrementVocal>[];
  int echecsRestants = 0;

  Future<void> envoyer(EnregistrementVocal vocal) async {
    if (echecsRestants > 0) {
      echecsRestants--;
      throw StateError('non confirme');
    }
    recus.add(vocal);
  }
}

class _Banc {
  _Banc({
    PermissionMicro permission = PermissionMicro.accordee,
    PermissionMicro reponse = PermissionMicro.accordee,
  }) : horloge = HorlogeManuelle() {
    enregistreur = EnregistreurVocalDemonstration(
      horloge: horloge.horloge,
      permissionInitiale: permission,
      reponseALaDemande: reponse,
    );
  }

  final HorlogeManuelle horloge;
  late final EnregistreurVocalDemonstration enregistreur;
  final _Envois envois = _Envois();

  List<Override> surcharges({
    PortEnregistreurVocal? port,
    bool horsLigne = false,
  }) => <Override>[
    portEnregistreurVocalProvider.overrideWithValue(port ?? enregistreur),
    horlogeVocaleProvider.overrideWithValue(horloge.horloge),
    if (horsLigne)
      horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
  ];
}

/// Un enregistreur qui echoue a la demande, pour les etats d'erreur.
class _PortCapricieux extends EnregistreurVocalDemonstration {
  _PortCapricieux({required super.horloge});

  bool echouerPermission = false;
  bool echouerDemarrage = false;
  bool echouerPause = false;

  @override
  Future<PermissionMicro> permission() async {
    if (echouerPermission) throw StateError('micro illisible');
    return super.permission();
  }

  @override
  Future<void> demarrer() async {
    if (echouerDemarrage) throw StateError('micro occupe');
    return super.demarrer();
  }

  @override
  Future<void> mettreEnPause() async {
    if (echouerPause) throw StateError('micro perdu');
    return super.mettreEnPause();
  }
}

/// Un enregistreur dont le prochain arret ne repond qu'a l'ouverture de
/// [porte] (enregistreur reel lent a finaliser son fichier).
class _PortLent extends EnregistreurVocalDemonstration {
  _PortLent({required super.horloge});

  final Completer<void> porte = Completer<void>();
  bool retenir = true;

  @override
  Future<EnregistrementVocal> arreter({required Duration duree}) async {
    final EnregistrementVocal vocal = await super.arreter(duree: duree);
    if (retenir) {
      retenir = false;
      await porte.future;
    }
    return vocal;
  }
}

Future<void> _monter(
  WidgetTester tester,
  _Banc banc, {
  Size taille = vueMobile,
  double echelle = 1,
  Brightness luminosite = Brightness.light,
  PortEnregistreurVocal? port,
  bool horsLigne = false,
}) async {
  fixerVue(tester, taille);
  await tester.pumpWidget(
    hoteTheme(
      ComposerVocal(onEnvoyer: banc.envois.envoyer),
      echelleTexte: echelle,
      luminosite: luminosite,
      surcharges: banc.surcharges(port: port, horsLigne: horsLigne),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _toucher(WidgetTester tester, Key cle) async {
  await tester.ensureVisible(find.byKey(cle));
  await tester.tap(find.byKey(cle));
  await tester.pump();
  await tester.pump();
}

Finder _texte(String texte) => find.text(texte);

void main() {
  final c = t.com.vocal.composer;

  group('R-COM-03 : enregistrer, pause, reprendre, arreter, pre-ecouter, '
      'supprimer, envoyer', () {
    testWidgets('le parcours complet, la pause non comptee, un seul envoi', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc);
      expect(find.byKey(ComposerVocal.cleEnregistrer), findsOneWidget);
      expect(_texte(c.enregistrer), findsOneWidget);

      await _toucher(tester, ComposerVocal.cleEnregistrer);
      expect(_texte(c.enregistrement), findsOneWidget);
      expect(_texte(c.ecoule(ecoule: '0:00', max: '3:00')), findsOneWidget);
      expect(banc.enregistreur.actif, isTrue);

      await avancer(tester, banc.horloge, const Duration(seconds: 5));
      expect(_texte(c.ecoule(ecoule: '0:05', max: '3:00')), findsOneWidget);

      await _toucher(tester, ComposerVocal.clePause);
      expect(_texte(c.pause), findsOneWidget);
      expect(find.byKey(ComposerVocal.cleReprendre), findsOneWidget);
      expect(find.byKey(ComposerVocal.cleSupprimer), findsOneWidget);
      await avancer(tester, banc.horloge, const Duration(seconds: 40));
      expect(_texte(c.ecoule(ecoule: '0:05', max: '3:00')), findsOneWidget);

      await _toucher(tester, ComposerVocal.cleReprendre);
      expect(_texte(c.reprise), findsOneWidget);
      await avancer(tester, banc.horloge, const Duration(seconds: 7));
      expect(_texte(c.ecoule(ecoule: '0:12', max: '3:00')), findsOneWidget);

      await _toucher(tester, ComposerVocal.cleArreter);
      expect(_texte(c.preEcoute), findsOneWidget);
      expect(_texte(c.duree(duree: '0:12')), findsOneWidget);
      expect(find.byKey(ComposerVocal.cleEnvoyer), findsOneWidget);
      expect(find.byKey(ComposerVocal.cleSupprimer), findsOneWidget);
      // Jamais d'envoi a l'arret.
      expect(banc.envois.recus, isEmpty);

      // Pre-ecoute : le lecteur lit le vocal enregistre.
      expect(find.byType(LecteurVocal), findsOneWidget);
      await _toucher(tester, LecteurVocal.cleAction);
      expect(_texte(t.com.vocal.lecteur.lecture), findsOneWidget);
      await avancer(tester, banc.horloge, const Duration(seconds: 4));
      expect(
        _texte(t.com.vocal.lecteur.position(position: '0:04', duree: '0:12')),
        findsOneWidget,
      );
      expect(banc.envois.recus, isEmpty);

      // Supprimer demande confirmation ; Garder revient a la pre-ecoute.
      await _toucher(tester, ComposerVocal.cleSupprimer);
      expect(_texte(c.confirmerTitre), findsOneWidget);
      await _toucher(tester, ComposerVocal.cleGarder);
      expect(_texte(c.preEcoute), findsOneWidget);

      await _toucher(tester, ComposerVocal.cleEnvoyer);
      expect(banc.envois.recus, hasLength(1));
      expect(banc.envois.recus.single.duree, const Duration(seconds: 12));
      expect(_texte(c.envoye), findsOneWidget);
      expect(find.byKey(ComposerVocal.cleEnregistrer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('supprimer apres l arret efface le vocal, rien ne part', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      await avancer(tester, banc.horloge, const Duration(seconds: 3));
      await _toucher(tester, ComposerVocal.cleArreter);
      await _toucher(tester, ComposerVocal.cleSupprimer);
      await _toucher(tester, ComposerVocal.cleConfirmerSuppression);
      expect(find.byKey(ComposerVocal.cleEnregistrer), findsOneWidget);
      expect(banc.enregistreur.supprimes, <String>['vocal-demo-1']);
      expect(banc.envois.recus, isEmpty);
    });

    testWidgets('supprimer pendant la pause abandonne l enregistrement', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      await avancer(tester, banc.horloge, const Duration(seconds: 3));
      await _toucher(tester, ComposerVocal.clePause);
      await _toucher(tester, ComposerVocal.cleSupprimer);
      await _toucher(tester, ComposerVocal.cleConfirmerSuppression);
      expect(banc.enregistreur.abandons, 1);
      expect(banc.enregistreur.actif, isFalse);
      expect(banc.envois.recus, isEmpty);
    });

    testWidgets('quitter l ecran pendant l enregistrement l abandonne', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(banc.enregistreur.abandons, 1);
      expect(banc.envois.recus, isEmpty);
    });

    testWidgets('quitter l ecran en pre-ecoute efface le vocal, rien ne part', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      await avancer(tester, banc.horloge, const Duration(seconds: 2));
      await _toucher(tester, ComposerVocal.cleArreter);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(banc.enregistreur.supprimes, <String>['vocal-demo-1']);
      expect(banc.enregistreur.abandons, 0);
      expect(banc.envois.recus, isEmpty);
    });
  });

  group('Arret lent de l enregistreur', () {
    testWidgets('supprime avant la reponse : le vocal rendu est efface', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      final _PortLent port = _PortLent(horloge: banc.horloge.horloge);
      await _monter(tester, banc, port: port);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      await avancer(tester, banc.horloge, const Duration(seconds: 3));
      await _toucher(tester, ComposerVocal.cleArreter);
      await _toucher(tester, ComposerVocal.cleSupprimer);
      await _toucher(tester, ComposerVocal.cleConfirmerSuppression);
      expect(find.byKey(ComposerVocal.cleEnregistrer), findsOneWidget);

      port.porte.complete();
      await tester.pump();
      await tester.pump();
      expect(port.supprimes, <String>['vocal-demo-1']);
      expect(find.byKey(ComposerVocal.cleEnvoyer), findsNothing);
      expect(find.byKey(ComposerVocal.cleEnregistrer), findsOneWidget);
      expect(banc.envois.recus, isEmpty);
    });

    testWidgets(
      'nouvel enregistrement avant la reponse : l ancien ne part pas',
      (WidgetTester tester) async {
        final _Banc banc = _Banc();
        final _PortLent port = _PortLent(horloge: banc.horloge.horloge);
        await _monter(tester, banc, port: port);
        await _toucher(tester, ComposerVocal.cleEnregistrer);
        await avancer(tester, banc.horloge, const Duration(seconds: 3));
        await _toucher(tester, ComposerVocal.cleArreter);
        await _toucher(tester, ComposerVocal.cleSupprimer);
        await _toucher(tester, ComposerVocal.cleConfirmerSuppression);

        await _toucher(tester, ComposerVocal.cleEnregistrer);
        await avancer(tester, banc.horloge, const Duration(seconds: 5));
        await _toucher(tester, ComposerVocal.cleArreter);
        expect(_texte(c.duree(duree: '0:05')), findsOneWidget);

        // L'ancien arret repond enfin : il ne remplace pas le nouveau vocal.
        port.porte.complete();
        await tester.pump();
        await tester.pump();
        expect(port.supprimes, <String>['vocal-demo-1']);
        await _toucher(tester, ComposerVocal.cleEnvoyer);
        expect(banc.envois.recus.single.id, 'vocal-demo-2');
        expect(banc.envois.recus.single.duree, const Duration(seconds: 5));
      },
    );

    testWidgets('ecran ferme avant la reponse : le vocal rendu est efface', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      final _PortLent port = _PortLent(horloge: banc.horloge.horloge);
      await _monter(tester, banc, port: port);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      await avancer(tester, banc.horloge, const Duration(seconds: 2));
      await _toucher(tester, ComposerVocal.cleArreter);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      port.porte.complete();
      await tester.pump();
      await tester.pump();
      expect(port.supprimes, <String>['vocal-demo-1']);
      expect(banc.envois.recus, isEmpty);
    });

    testWidgets('Garder pendant l attente : le vocal rendu reste propose', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      final _PortLent port = _PortLent(horloge: banc.horloge.horloge);
      await _monter(tester, banc, port: port);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      await avancer(tester, banc.horloge, const Duration(seconds: 4));
      await _toucher(tester, ComposerVocal.cleArreter);
      await _toucher(tester, ComposerVocal.cleSupprimer);
      port.porte.complete();
      await tester.pump();
      await tester.pump();
      await _toucher(tester, ComposerVocal.cleGarder);
      expect(port.supprimes, isEmpty);
      await _toucher(tester, ComposerVocal.cleEnvoyer);
      expect(banc.envois.recus.single.id, 'vocal-demo-1');
    });
  });

  testWidgets('quitter l ecran pendant la confirmation en pause l abandonne', (
    WidgetTester tester,
  ) async {
    final _Banc banc = _Banc();
    await _monter(tester, banc);
    await _toucher(tester, ComposerVocal.cleEnregistrer);
    await avancer(tester, banc.horloge, const Duration(seconds: 3));
    await _toucher(tester, ComposerVocal.clePause);
    await _toucher(tester, ComposerVocal.cleSupprimer);
    expect(_texte(c.confirmerTitre), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(banc.enregistreur.abandons, 1);
    expect(banc.enregistreur.actif, isFalse);
    expect(banc.envois.recus, isEmpty);
  });

  group('R-COM-04 : limite de 3:00', () {
    testWidgets('limite proche a 2:30, arret seul a 3:00, pre-ecoute', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc);
      await _toucher(tester, ComposerVocal.cleEnregistrer);

      await avancer(
        tester,
        banc.horloge,
        const Duration(minutes: 2, seconds: 30),
      );
      expect(
        _texte(c.limiteProche(seuil: '0:30', max: '3:00')),
        findsOneWidget,
      );
      expect(find.byKey(ComposerVocal.clePause), findsOneWidget);

      // Annonce fixe : dix secondes plus tard, la region vivante dit la meme
      // chose (pas de relecture a chaque seconde) ; le decompte est dans la
      // duree ecrite.
      await avancer(tester, banc.horloge, const Duration(seconds: 10));
      expect(
        _texte(c.limiteProche(seuil: '0:30', max: '3:00')),
        findsOneWidget,
      );
      expect(_texte(c.ecoule(ecoule: '2:40', max: '3:00')), findsOneWidget);

      await avancer(tester, banc.horloge, const Duration(seconds: 20));
      expect(_texte(c.preEcoute), findsOneWidget);
      expect(_texte(c.limiteAtteinte(max: '3:00')), findsOneWidget);
      expect(_texte(c.duree(duree: '3:00')), findsOneWidget);
      expect(find.byKey(ComposerVocal.clePause), findsNothing);
      expect(find.byKey(ComposerVocal.cleEnvoyer), findsOneWidget);
      expect(banc.enregistreur.actif, isFalse);
      // Arrete seul : rien n'est envoye.
      expect(banc.envois.recus, isEmpty);

      await avancer(tester, banc.horloge, const Duration(seconds: 20));
      expect(_texte(c.duree(duree: '3:00')), findsOneWidget);
      expect(banc.envois.recus, isEmpty);

      await _toucher(tester, ComposerVocal.cleEnvoyer);
      expect(banc.envois.recus.single.duree, dureeMaxVocal);
    });

    testWidgets('l horloge saute au-dela de 3:00 : duree bornee', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      await avancer(tester, banc.horloge, const Duration(minutes: 4));
      expect(_texte(c.duree(duree: '3:00')), findsOneWidget);
      expect(banc.envois.recus, isEmpty);
    });
  });

  group('Permission du micro', () {
    testWidgets('a demander : explication, puis Autoriser demarre', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc(permission: PermissionMicro.aDemander);
      await _monter(tester, banc);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      expect(_texte(c.permissionPhrase), findsOneWidget);
      expect(banc.enregistreur.actif, isFalse);
      await _toucher(tester, ComposerVocal.cleAutoriser);
      expect(_texte(c.enregistrement), findsOneWidget);
      expect(banc.enregistreur.actif, isTrue);
    });

    testWidgets('a demander : Annuler revient au repos', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc(permission: PermissionMicro.aDemander);
      await _monter(tester, banc);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      await _toucher(tester, ComposerVocal.cleAnnuler);
      expect(find.byKey(ComposerVocal.cleEnregistrer), findsOneWidget);
      expect(banc.enregistreur.actif, isFalse);
    });

    testWidgets('refusee a la demande : phrase exacte, Fermer', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc(
        permission: PermissionMicro.aDemander,
        reponse: PermissionMicro.refusee,
      );
      await _monter(tester, banc);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      await _toucher(tester, ComposerVocal.cleAutoriser);
      expect(
        _texte("Le microphone n'est pas autorisé pour Rewayah."),
        findsOneWidget,
      );
      expect(find.byKey(ComposerVocal.cleFermer), findsOneWidget);
      await _toucher(tester, ComposerVocal.cleFermer);
      expect(find.byKey(ComposerVocal.cleEnregistrer), findsOneWidget);
    });

    testWidgets('deja refusee : aucun enregistrement, Fermer seul', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc(permission: PermissionMicro.refusee);
      await _monter(tester, banc);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      expect(_texte(c.refuse), findsOneWidget);
      expect(_texte(c.refuseAide), findsOneWidget);
      expect(find.byKey(ComposerVocal.cleAutoriser), findsNothing);
      expect(banc.enregistreur.actif, isFalse);
    });

    testWidgets('port neutre de production : indisponible, aucun bouton', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc, port: const EnregistreurVocalIndisponible());
      expect(find.byKey(ComposerVocal.cleIndisponible), findsOneWidget);
      expect(_texte(c.indisponible), findsOneWidget);
      expect(find.byKey(ComposerVocal.cleEnregistrer), findsNothing);
      expect(find.byType(LecteurVocal), findsNothing);
    });
  });

  group('Erreurs du micro : ce qui manque et quoi faire', () {
    testWidgets('etat du micro illisible : Reessayer, puis disponible', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      final _PortCapricieux port = _PortCapricieux(
        horloge: banc.horloge.horloge,
      )..echouerPermission = true;
      await _monter(tester, banc, port: port);
      expect(find.text(c.erreurVerificationTitre), findsOneWidget);
      expect(find.byKey(ComposerVocal.cleEnregistrer), findsNothing);
      port.echouerPermission = false;
      await _toucher(tester, const ValueKey<String>('vocal-verifier'));
      expect(find.byKey(ComposerVocal.cleEnregistrer), findsOneWidget);
    });

    testWidgets('demarrage impossible : la phrase, retour au repos', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      final _PortCapricieux port = _PortCapricieux(
        horloge: banc.horloge.horloge,
      )..echouerDemarrage = true;
      await _monter(tester, banc, port: port);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      expect(find.text(c.erreurDemarrage), findsOneWidget);
      expect(find.byKey(ComposerVocal.cleEnregistrer), findsOneWidget);
      port.echouerDemarrage = false;
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      expect(find.text(c.erreurDemarrage), findsNothing);
      expect(find.text(c.enregistrement), findsOneWidget);
    });

    testWidgets('micro perdu pendant la pause : interrompu, rien ne part', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      final _PortCapricieux port = _PortCapricieux(
        horloge: banc.horloge.horloge,
      )..echouerPause = true;
      await _monter(tester, banc, port: port);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      await avancer(tester, banc.horloge, const Duration(seconds: 3));
      await _toucher(tester, ComposerVocal.clePause);
      expect(find.text(c.erreurInterrompu), findsOneWidget);
      expect(find.byKey(ComposerVocal.cleEnregistrer), findsOneWidget);
      expect(banc.envois.recus, isEmpty);
    });
  });

  group('Envoi', () {
    testWidgets('non confirme : vocal garde, Reessayer envoie', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      banc.envois.echecsRestants = 1;
      await _monter(tester, banc);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      await avancer(tester, banc.horloge, const Duration(seconds: 8));
      await _toucher(tester, ComposerVocal.cleArreter);
      await _toucher(tester, ComposerVocal.cleEnvoyer);
      expect(_texte(c.nonConfirme), findsOneWidget);
      expect(_texte(c.nonConfirmeAide), findsOneWidget);
      expect(_texte(c.duree(duree: '0:08')), findsOneWidget);
      expect(banc.envois.recus, isEmpty);

      await _toucher(tester, ComposerVocal.cleReessayer);
      expect(banc.envois.recus.single.duree, const Duration(seconds: 8));
      expect(_texte(c.envoye), findsOneWidget);
    });

    testWidgets('envoi en cours : le bouton attend, aucun double envoi', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      int appels = 0;
      final HorlogeManuelle horloge = banc.horloge;
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          ComposerVocal(
            onEnvoyer: (EnregistrementVocal _) async {
              appels++;
              await Future<void>.delayed(const Duration(seconds: 2));
            },
          ),
          surcharges: banc.surcharges(),
        ),
      );
      await tester.pump();
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      await avancer(tester, horloge, const Duration(seconds: 2));
      await _toucher(tester, ComposerVocal.cleArreter);
      await _toucher(tester, ComposerVocal.cleEnvoyer);
      expect(_texte(c.envoi), findsOneWidget);
      await tester.tap(find.byKey(ComposerVocal.cleEnvoyer));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(appels, 1);
      expect(_texte(c.envoye), findsOneWidget);
    });

    testWidgets('hors ligne : Envoyer non rendu, la phrase le dit', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc, horsLigne: true);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      await avancer(tester, banc.horloge, const Duration(seconds: 3));
      await _toucher(tester, ComposerVocal.cleArreter);
      expect(find.byKey(ComposerVocal.cleEnvoyer), findsNothing);
      expect(_texte(c.horsLigne), findsOneWidget);
      expect(find.byKey(ComposerVocal.cleSupprimer), findsOneWidget);
    });
  });

  testWidgets('Semantics : Pause, Reprendre, Supprimer, Envoyer nommes', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    final _Banc banc = _Banc();
    await _monter(tester, banc);
    await _toucher(tester, ComposerVocal.cleEnregistrer);
    expect(find.bySemanticsLabel(c.actionPause), findsOneWidget);
    await _toucher(tester, ComposerVocal.clePause);
    expect(find.bySemanticsLabel(c.actionReprendre), findsOneWidget);
    expect(find.bySemanticsLabel(c.actionSupprimer), findsOneWidget);
    await _toucher(tester, ComposerVocal.cleArreter);
    expect(find.bySemanticsLabel(c.actionEnvoyer), findsOneWidget);
    expect(find.bySemanticsLabel(c.actionSupprimer), findsOneWidget);
    // L'etat est une region vivante, lue sans la barre de progression.
    final SemanticsNode statut = tester.getSemantics(
      find.byKey(ComposerVocal.cleStatut),
    );
    expect(statut.label, contains(c.preEcoute));
    semantique.dispose();
  });

  testWidgets('se branche dans l emplacement vocal du composer de COM-F', (
    WidgetTester tester,
  ) async {
    final _Banc banc = _Banc();
    fixerVue(tester, vueMobile);
    await tester.pumpWidget(
      hoteTheme(
        FilDiscussion(
          messages: const <MessageFil>[],
          textes: textesFilCommunication(),
          onEnvoyer: (String _) async {},
          emplacementVocal: ComposerVocal(onEnvoyer: banc.envois.envoyer),
        ),
        defilant: false,
        surcharges: banc.surcharges(),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      tester.getTopLeft(find.byKey(ComposerVocal.cleEnregistrer)).dy,
      greaterThan(tester.getBottomLeft(find.byKey(FilDiscussion.champKey)).dy),
    );
    await _toucher(tester, ComposerVocal.cleEnregistrer);
    await avancer(tester, banc.horloge, const Duration(seconds: 6));
    await _toucher(tester, ComposerVocal.cleArreter);
    expect(find.byKey(ComposerVocal.cleEnvoyer), findsOneWidget);
    // Un seul bouton plein : celui du texte (K-56), le vocal est secondaire.
    verifierUnSeulBoutonPlein(tester);
    expect(tester.takeException(), isNull);
  });

  group('Rendu', () {
    for (final Size taille in <Size>[
      vueMobile,
      const Size(768, 1024),
      vueBureau,
    ]) {
      for (final Brightness luminosite in Brightness.values) {
        testWidgets(
          '${taille.width.toInt()} ${luminosite.name} : pre-ecoute sans '
          'debordement, actions au bord de fin',
          (WidgetTester tester) async {
            final _Banc banc = _Banc();
            await _monter(tester, banc, taille: taille, luminosite: luminosite);
            await _toucher(tester, ComposerVocal.cleEnregistrer);
            await avancer(tester, banc.horloge, const Duration(seconds: 9));
            await _toucher(tester, ComposerVocal.cleArreter);
            expect(tester.takeException(), isNull);
            final Rect envoyer = tester.getRect(
              find.byKey(ComposerVocal.cleEnvoyer),
            );
            final Rect supprimer = tester.getRect(
              find.byKey(ComposerVocal.cleSupprimer),
            );
            // Contrat B : la sortie (Supprimer) avant la poursuite (Envoyer),
            // groupees au bord de fin.
            // Sur une ligne : Supprimer avant Envoyer ; empilees (place
            // etroite) : Supprimer au-dessus, meme largeur.
            expect(
              supprimer.left < envoyer.left || supprimer.top < envoyer.top,
              isTrue,
            );
            expect(envoyer.right, greaterThan(taille.width / 2));
            verifierUnSeulBoutonPlein(tester);
          },
        );
      }
    }

    testWidgets('320 en texte x2 : chaque etat sans debordement', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc(permission: PermissionMicro.aDemander);
      await _monter(tester, banc, taille: const Size(320, 900), echelle: 2);
      await _toucher(tester, ComposerVocal.cleEnregistrer);
      expect(tester.takeException(), isNull);
      await _toucher(tester, ComposerVocal.cleAutoriser);
      await avancer(
        tester,
        banc.horloge,
        const Duration(minutes: 2, seconds: 40),
      );
      expect(tester.takeException(), isNull);
      await _toucher(tester, ComposerVocal.clePause);
      expect(tester.takeException(), isNull);
      await _toucher(tester, ComposerVocal.cleArreter);
      expect(tester.takeException(), isNull);
      await _toucher(tester, ComposerVocal.cleSupprimer);
      expect(tester.takeException(), isNull);
      await _toucher(tester, ComposerVocal.cleGarder);
      for (final Key cle in <Key>[
        ComposerVocal.cleSupprimer,
        ComposerVocal.cleEnvoyer,
        LecteurVocal.cleAction,
      ]) {
        final Rect r = tester.getRect(find.byKey(cle));
        expect(r.left, greaterThanOrEqualTo(0), reason: '$cle');
        expect(r.right, lessThanOrEqualTo(320), reason: '$cle');
      }
    });

    testWidgets(
      'arabe (RTL) : libelles arabes, actions au bord de fin a gauche',
      (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        final _Banc banc = _Banc();
        fixerVue(tester, vueMobile);
        await tester.pumpWidget(
          hoteTheme(
            Directionality(
              textDirection: TextDirection.rtl,
              child: ComposerVocal(onEnvoyer: banc.envois.envoyer),
            ),
            surcharges: banc.surcharges(),
          ),
        );
        await tester.pump();
        await tester.pump();
        final ar = t.com.vocal.composer;
        expect(ar.enregistrer, isNot(c.enregistrer));
        expect(find.text(ar.enregistrer), findsOneWidget);
        await _toucher(tester, ComposerVocal.cleEnregistrer);
        await avancer(tester, banc.horloge, const Duration(seconds: 4));
        await _toucher(tester, ComposerVocal.cleArreter);
        expect(find.text(ar.actionEnvoyer), findsOneWidget);
        final Rect envoyer = tester.getRect(
          find.byKey(ComposerVocal.cleEnvoyer),
        );
        final Rect supprimer = tester.getRect(
          find.byKey(ComposerVocal.cleSupprimer),
        );
        // En arabe, le bord de fin est a gauche, et la sortie vient d'abord.
        expect(envoyer.left, lessThan(vueMobile.width / 2));
        expect(
          supprimer.left > envoyer.left || supprimer.top < envoyer.top,
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}

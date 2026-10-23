// COURRIELS-2 : l'ecran « Langue des e-mails et des messages » (fiche CPT-LANG).
//
// Ce que le test prouve : la liste du serveur s'affiche, chaque langue dans son
// nom, sans carte « Autre » ; la langue deja reglee est cochee (Francais quand
// le serveur n'en a pas retenu) ; le bouton n'existe que si le choix change ;
// « C'est enregistre » ne se dit qu'apres la reponse du serveur ; chaque refus a
// sa phrase ; un double appui n'envoie qu'une fois ; hors ligne rien ne part ;
// liste vide, erreur, chargement, port absent ; 320 px, texte x2, francais et
// arabe, LTR et RTL.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/langues_communication_demonstration.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_langues_communication.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';
import 'package:rewayah_academy/features/compte/langue_courriels_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../../support/monter_recrutement.dart';

Future<void> _monter(
  WidgetTester tester,
  PortLanguesCommunication? port, {
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
}) => monterRecrutement(
  tester,
  chemin: '/compte/langue-courriels',
  ecran: (_) => const LangueCourrielsPage(),
  surcharges: <Override>[
    if (port != null) portLanguesCommunicationProvider.overrideWithValue(port),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await laisser(tester);
}

Finder get _enregistrer => find.byKey(LangueCourrielsPage.enregistrerKey);

void main() {
  final l = t.compte.langueCourriels;

  setUpAll(chargerPolicesDuDepot);

  group('entree', () {
    testWidgets('les reglages du compte ouvrent la langue des e-mails', (
      tester,
    ) async {
      await monterRecrutement(
        tester,
        chemin: Routes.compteReglages,
        ecran: (_) => const ReglagesComptePage(),
        autres: <String>[Routes.compteLangueCourriels],
        surcharges: <Override>[
          sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        ],
      );
      final Finder ligne = find.byKey(
        const ValueKey<String>('reglage-langue-courriels'),
      );
      expect(ligne, findsOneWidget);
      expect(find.text(l.titre), findsOneWidget);
      await _taper(tester, ligne);
      expect(
        find.text('temoin:${Routes.compteLangueCourriels}'),
        findsOneWidget,
      );
    });
  });

  group('contenu', () {
    testWidgets(
      'la phrase de contexte, une carte par langue du serveur, pas de « Autre »',
      (tester) async {
        await _monter(tester, LanguesCommunicationDemonstration());
        expect(find.text(l.sousTitre), findsOneWidget);
        for (final LangueCommunication x
            in LanguesCommunicationDemonstration.languesDeDepart) {
          expect(
            find.byKey(LangueCourrielsPage.carteKey(x.code)),
            findsOneWidget,
          );
          expect(find.text(x.libelle), findsOneWidget);
        }
        expect(find.text(t.choix.autre), findsNothing);
        expect(find.byKey(LangueCourrielsPage.parDefautKey), findsOneWidget);
        verifierUnSeulBoutonPlein(tester);
      },
    );

    testWidgets('aucune langue reglee : Francais est la langue courante, '
        'et le bouton n\'existe pas', (tester) async {
      await _monter(tester, LanguesCommunicationDemonstration());
      expect(_enregistrer, findsNothing);
      // Toucher Francais ne change rien : toujours pas de bouton.
      await _taper(tester, find.byKey(LangueCourrielsPage.carteKey('fr')));
      expect(_enregistrer, findsNothing);
    });

    testWidgets('la langue reglee est cochee, choisir une autre montre le '
        'bouton', (tester) async {
      final LanguesCommunicationDemonstration p =
          LanguesCommunicationDemonstration(langue: 'en');
      await _monter(tester, p);
      expect(_enregistrer, findsNothing);
      await _taper(tester, find.byKey(LangueCourrielsPage.carteKey('es')));
      expect(_enregistrer, findsOneWidget);
      // Revenir a la langue enregistree retire le bouton.
      await _taper(tester, find.byKey(LangueCourrielsPage.carteKey('en')));
      expect(_enregistrer, findsNothing);
      expect(p.reglages, isEmpty);
    });
  });

  group('enregistrer', () {
    testWidgets('succes : le serveur recoit le code, la phrase le dit '
        'ensuite seulement', (tester) async {
      final LanguesCommunicationDemonstration p =
          LanguesCommunicationDemonstration();
      await _monter(tester, p);
      await _taper(tester, find.byKey(LangueCourrielsPage.carteKey('ar')));
      expect(find.byKey(LangueCourrielsPage.retourKey), findsNothing);
      await _taper(tester, _enregistrer);
      expect(p.reglages, <String>['ar']);
      expect(p.langue, 'ar');
      expect(
        find.text(l.retour.enregistre(langue: isolerSens('العربية'))),
        findsOneWidget,
      );
      // La langue enregistree devient la courante : plus de bouton.
      expect(_enregistrer, findsNothing);
    });

    testWidgets('le serveur refuse la langue : une phrase, rien de change', (
      tester,
    ) async {
      final LanguesCommunicationDemonstration p =
          LanguesCommunicationDemonstration()
            ..erreurReglage = const LangueRefusee();
      await _monter(tester, p);
      await _taper(tester, find.byKey(LangueCourrielsPage.carteKey('pt')));
      await _taper(tester, _enregistrer);
      expect(find.text(l.retour.refusee), findsOneWidget);
      expect(p.langue, isNull);
      // Le bouton reste : on peut choisir une autre langue ou rejouer.
      expect(_enregistrer, findsOneWidget);
    });

    testWidgets('droits refuses', (tester) async {
      final LanguesCommunicationDemonstration p =
          LanguesCommunicationDemonstration()
            ..erreurReglage = const PermissionInsuffisante('COURRIELS-2');
      await _monter(tester, p);
      await _taper(tester, find.byKey(LangueCourrielsPage.carteKey('en')));
      await _taper(tester, _enregistrer);
      expect(find.text(l.retour.refus), findsOneWidget);
    });

    testWidgets('echec non confirme : on ne dit jamais « enregistre »', (
      tester,
    ) async {
      final LanguesCommunicationDemonstration p =
          LanguesCommunicationDemonstration()..erreurReglage = Exception('x');
      await _monter(tester, p);
      await _taper(tester, find.byKey(LangueCourrielsPage.carteKey('en')));
      await _taper(tester, _enregistrer);
      expect(find.text(l.retour.echec), findsOneWidget);
      expect(find.textContaining('C\'est enregistré'), findsNothing);
      // Rejouer fonctionne.
      await _taper(tester, _enregistrer);
      expect(p.langue, 'en');
    });

    testWidgets('hors ligne : rien ne part', (tester) async {
      final LanguesCommunicationDemonstration p =
          LanguesCommunicationDemonstration();
      await _monter(tester, p, horsLigne: true);
      await _taper(tester, find.byKey(LangueCourrielsPage.carteKey('en')));
      await _taper(tester, _enregistrer);
      expect(find.text(l.retour.horsLigne), findsOneWidget);
      expect(p.reglages, isEmpty);
    });

    testWidgets('double appui : un seul envoi', (tester) async {
      final Completer<void> attente = Completer<void>();
      final _Retenu p = _Retenu(attente.future);
      await _monter(tester, p);
      await _taper(tester, find.byKey(LangueCourrielsPage.carteKey('en')));
      await tester.ensureVisible(_enregistrer);
      await tester.tap(_enregistrer);
      await tester.pump();
      await tester.tap(_enregistrer, warnIfMissed: false);
      await tester.pump();
      expect(p.reglages, <String>['en']);
      attente.complete();
      await laisser(tester);
      expect(p.reglages, <String>['en']);
    });
  });

  group('etats de la liste', () {
    testWidgets('chargement', (tester) async {
      final Completer<void> c = Completer<void>();
      await _monter(tester, _Retenu(c.future, retenirListe: true));
      expect(find.byType(Skeleton), findsWidgets);
    });

    testWidgets('liste vide : une phrase, le francais reste', (tester) async {
      await _monter(
        tester,
        LanguesCommunicationDemonstration(langues: <LangueCommunication>[]),
      );
      expect(find.text(l.vide), findsOneWidget);
      expect(find.byKey(LangueCourrielsPage.enregistrerKey), findsNothing);
    });

    testWidgets('erreur : Reessayer relit', (tester) async {
      final LanguesCommunicationDemonstration p =
          LanguesCommunicationDemonstration()..erreurListe = Exception('panne');
      await _monter(tester, p);
      expect(find.text(l.erreurLangues), findsOneWidget);
      await tester.tap(find.text(t.commun.reessayer));
      await laisser(tester);
      expect(find.byKey(LangueCourrielsPage.carteKey('fr')), findsOneWidget);
    });

    testWidgets('lecture de la langue en erreur : meme etat', (tester) async {
      final LanguesCommunicationDemonstration p =
          LanguesCommunicationDemonstration()
            ..erreurLecture = Exception('panne');
      await _monter(tester, p);
      expect(find.text(l.erreurLangues), findsOneWidget);
    });

    testWidgets('hors ligne : ce qui manque est dit', (tester) async {
      final LanguesCommunicationDemonstration p =
          LanguesCommunicationDemonstration()..erreurListe = Exception('x');
      await _monter(tester, p, horsLigne: true);
      expect(find.text(l.sansDonnees), findsOneWidget);
    });

    testWidgets('port absent : fonction indisponible', (tester) async {
      await _monter(tester, null);
      expect(find.text(l.indisponibleTitre), findsOneWidget);
      expect(find.byType(EtatSysteme), findsOneWidget);
    });
  });

  group('gabarits', () {
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final TextDirection d in TextDirection.values) {
        testWidgets('${langue.name}, 320 px, texte x2, ${d.name}', (
          tester,
        ) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          await _monter(
            tester,
            LanguesCommunicationDemonstration(langue: 'ar'),
            largeur: 320,
            echelle: 2,
            direction: d,
          );
          expect(tester.takeException(), isNull);
          verifierEcranSansMotCoupe(tester);
          await _taper(tester, find.byKey(LangueCourrielsPage.carteKey('en')));
          expect(tester.takeException(), isNull);
          verifierEcranSansMotCoupe(tester);
          verifierUnSeulBoutonPlein(tester);
          await _taper(tester, _enregistrer);
          expect(tester.takeException(), isNull);
          verifierEcranSansMotCoupe(tester);
        });
      }
    }
  });
}

/// Un port dont l'enregistrement (ou la liste) attend.
class _Retenu extends LanguesCommunicationDemonstration {
  _Retenu(this._attente, {this.retenirListe = false});

  final Future<void> _attente;
  final bool retenirListe;

  @override
  Future<List<LangueCommunication>> lister() async {
    if (retenirListe) await _attente;
    return super.lister();
  }

  @override
  Future<void> regler(String code) async {
    reglages.add(code);
    await _attente;
    langue = code;
  }
}

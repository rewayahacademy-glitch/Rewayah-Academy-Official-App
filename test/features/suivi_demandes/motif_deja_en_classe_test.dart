// MOTIF-DEJA-EN-CLASSE : « l'eleve a deja une place en classe » est un motif
// de cloture du port de suivi (R20), au meme titre que le retrait, l'offre
// retiree, la classe non constituee et le refus de la direction.
//
// Ce que le test prouve, et qui tombe si la valeur `MotifCloture.dejaEnClasse`
// est retiree :
// - la valeur existe dans le port et chaque motif a un libelle (pas de repli
//   silencieux sur « inconnu ») ;
// - le motif nomme l'eleve, n'est ni un retrait ni un refus suppose, et l'etat
//   court dit « Demande close » ;
// - la notification de cloture a son titre propre ;
// - l'ecran de suivi des demandes affiche le motif et la frise de la famille
//   affiche le meme motif (demo : Hana), a 320 px, texte a 200 %, LTR ;
// - le libelle arabe existe et isole le prenom.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/port_frise_demande.dart';
import 'package:rewayah_academy/core/offres/port_suivi_demandes.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/suivi_demandes_demo.dart';
import 'package:rewayah_academy/features/suivi_demandes/libelles_suivi_demandes.dart';
import 'package:rewayah_academy/features/suivi_demandes/suivi_demandes_page.dart';

const String _hana = 'demo-demande-hana';

// Isolats bidirectionnels (FSI, PDI) qui entourent le prenom en arabe.
final String _isoleDebut = String.fromCharCode(0x2068);
final String _isoleFin = String.fromCharCode(0x2069);

SuiviDemande _demande({MotifCloture? motif, String prenom = 'Hana'}) =>
    SuiviDemande(
      demandeId: 'd',
      eleveId: 'e',
      prenom: prenom,
      etape: EtapeDemande.close,
      creneau: CreneauDemande(
        occurrences: const <OccurrenceCreneau>[
          OccurrenceCreneau(jourIso: 2, heure: 18),
        ],
      ),
      fuseauIana: 'Europe/Paris',
      motif: motif,
    );

DemandeServeurDemo _hanaDemo() => SuiviDemandesDemo.frises().demandes
    .firstWhere((DemandeServeurDemo d) => d.demandeId == _hana);

Widget _app(Widget home, PortSuiviDemandes port, double echelle) =>
    ProviderScope(
      overrides: <Override>[
        portSuiviDemandesProvider.overrideWithValue(port),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext contexte, Widget? app) => MediaQuery(
            data: MediaQuery.of(contexte)
                .copyWith(textScaler: TextScaler.linear(echelle)),
            child: app!,
          ),
          home: home,
        ),
      ),
    );

void main() {
  group('Le port', () {
    test('porte la valeur dejaEnClasse', () {
      expect(MotifCloture.values, contains(MotifCloture.dejaEnClasse));
      expect(MotifCloture.dejaEnClasse, isNot(MotifCloture.inconnu));
    });

    test('chaque motif a son libelle : aucun repli sur « inconnu »', () {
      final String inconnu = motifDemande(MotifCloture.inconnu, 'Hana');
      for (final MotifCloture motif in MotifCloture.values) {
        final String texte = motifDemande(motif, 'Hana');
        expect(texte, isNotEmpty, reason: '$motif');
        if (motif != MotifCloture.inconnu) {
          expect(texte, isNot(inconnu), reason: '$motif');
        }
      }
    });
  });

  group('Le libelle', () {
    test('nomme l\'eleve et ne dit ni retrait ni refus', () {
      final String texte = motifDemande(MotifCloture.dejaEnClasse, 'Hana');
      expect(
        texte,
        'Hana a déjà une place en classe : cette demande n\'est plus '
        'nécessaire.',
      );
      expect(estRetiree(MotifCloture.dejaEnClasse), isFalse);
      expect(
        etatCourtDemande(_demande(motif: MotifCloture.dejaEnClasse)),
        t.suiviDemandes.close.close,
      );
    });

    test('la notification de cloture a son titre propre', () {
      final String titre = titreNotificationDemande(
        _demande(motif: MotifCloture.dejaEnClasse),
      );
      expect(
        titre,
        'Demande de créneau de Hana : élève déjà en classe, demande '
        'classée',
      );
      expect(
        titre,
        isNot(
          titreNotificationDemande(
            _demande(motif: MotifCloture.refusDirection),
          ),
        ),
      );
    });

    test('en arabe : le libelle existe et isole le prenom', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
      final String motif = motifDemande(MotifCloture.dejaEnClasse, 'Hana');
      expect(motif, contains('${_isoleDebut}Hana$_isoleFin'));
      expect(motif, isNot(motifDemande(MotifCloture.inconnu, 'Hana')));
      final String titre = titreNotificationDemande(
        _demande(motif: MotifCloture.dejaEnClasse),
      );
      expect(titre, contains(_isoleDebut));
      expect(
        titre,
        isNot(
          titreNotificationDemande(
            _demande(motif: MotifCloture.refusDirection),
          ),
        ),
      );
    });
  });

  group('La demonstration et la frise', () {
    test('Hana : le motif du port devient celui de la frise', () async {
      final DemandeServeurDemo hana = _hanaDemo();
      expect(hana.motif, MotifCloture.dejaEnClasse);
      final FriseDemande frise = hana.versFrise();
      expect(frise.cloture, MotifClotureFrise.dejaEnClasse);
    });
  });

  group('L\'ecran de suivi', () {
    for (final (double largeur, double echelle) in <(double, double)>[
      (390, 1),
      (320, 2),
    ]) {
      testWidgets('affiche le motif a ${largeur.toInt()} px, texte x$echelle', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = Size(largeur, 4000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final SuiviDemandesDemo port = SuiviDemandesDemo(<DemandeServeurDemo>[
          _hanaDemo(),
        ]);
        await tester.pumpWidget(_app(const SuiviDemandesPage(), port, echelle));
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          find.text(motifDemande(MotifCloture.dejaEnClasse, 'Hana')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}

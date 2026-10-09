// FI-3c (revue FI-3-R) : montant au bord de fin et en colonne (M1),
// compteur d'essai (M2), ton de l'essai mesure contre les accents de profil
// (M3), theme sombre et lecture sans la couleur, grand montant d'un seul
// tenant (m1), moyen de paiement indisponible annonce (m3).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/accent_profil.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/badge_periode_financee.dart';
import 'package:rewayah_academy/core/widgets/bandeau_attention.dart';
import 'package:rewayah_academy/core/widgets/identite_profil.dart';
import 'package:rewayah_academy/core/widgets/ligne_allocation.dart';
import 'package:rewayah_academy/core/widgets/ligne_finance.dart';
import 'package:rewayah_academy/core/widgets/ligne_moyen_paiement.dart';
import 'package:rewayah_academy/core/widgets/ligne_transaction.dart';
import 'package:rewayah_academy/core/widgets/montant_argent.dart';
import 'package:rewayah_academy/core/widgets/pastille_financiere.dart';
import 'package:rewayah_academy/core/widgets/resume_soldes.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';

Future<void> _monter(
  WidgetTester tester,
  Widget enfant, {
  double largeur = 390,
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
  Brightness luminosite = Brightness.light,
}) async {
  tester.view.physicalSize = Size(largeur, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
          themeMode: luminosite == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          builder: (BuildContext context, Widget? app) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(echelle)),
            child: Directionality(textDirection: sens, child: app!),
          ),
          home: Material(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: enfant,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const Montant _cinquante = Montant(5000, 'USD');
const Montant _remise = Montant(-500, 'USD');
const Montant _centimes = Montant(14320, 'USD');
const Montant _total = Montant(14500, 'USD');
const Montant _debit = Montant(-5000, 'USD');

/// Une colonne de montants : decomposition, mouvement avec sa pastille,
/// allocation avec son avatar.
const Widget _colonne = Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: <Widget>[
    LigneFinance(libelle: 'Tarif enfant', montant: _cinquante),
    LigneFinance(
      libelle: 'Remise familiale',
      detail: '3e membre',
      montant: _remise,
    ),
    LigneFinance(libelle: 'Taxe', montant: _centimes, signe: true),
    LigneFinance(libelle: 'Total a financer', montant: _total, total: true),
    LigneTransaction(
      libelle: 'Periode d octobre',
      date: '1er octobre',
      montant: _debit,
      statut: PastilleFinanciere(etat: EtatFinancier.enConfirmation),
    ),
    LigneAllocation(
      prenom: 'Mariam',
      detail: 'Octobre',
      montant: _cinquante,
      avatar: BandeauProfil(
        avatar: AvatarTile(prenom: 'Mariam', diametre: AppAvatar.moyen),
        diametre: AppAvatar.moyen,
        accent: AccentProfil.lavande,
      ),
    ),
  ],
);

/// Les textes des montants de [_colonne], dans l'ordre.
final List<(Type, String)> _montants = <(Type, String)>[
  (LigneFinance, formaterMontant(_cinquante)),
  (LigneFinance, formaterMontant(_remise)),
  (LigneFinance, formaterMontant(_centimes, signe: true)),
  (LigneFinance, formaterMontant(_total)),
  (LigneTransaction, formaterMontant(_debit, signe: true)),
  (LigneAllocation, formaterMontant(_cinquante)),
];

// --- Mesure de couleur (CIE L*a*b*, D65), pour M3 ---------------------------

double _lineaire(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _f(double t) =>
    t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;

/// (L*, a*, b*) d'une couleur opaque.
(double, double, double) _lab(Color c) {
  final double r = _lineaire(c.r);
  final double g = _lineaire(c.g);
  final double b = _lineaire(c.b);
  final double x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  final double y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  final double z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
  return (116 * _f(y) - 16, 500 * (_f(x) - _f(y)), 200 * (_f(y) - _f(z)));
}

double _chroma(Color c) {
  final (double _, double a, double b) = _lab(c);
  return math.sqrt(a * a + b * b);
}

double _teinte(Color c) {
  final (double _, double a, double b) = _lab(c);
  return (math.atan2(b, a) * 180 / math.pi) % 360;
}

double _ecartTeinte(Color x, Color y) {
  final double d = (_teinte(x) - _teinte(y)).abs();
  return math.min(d, 360 - d);
}

double _deltaE(Color x, Color y) {
  final (double l1, double a1, double b1) = _lab(x);
  final (double l2, double a2, double b2) = _lab(y);
  return math.sqrt(
    (l1 - l2) * (l1 - l2) + (a1 - a2) * (a1 - a2) + (b1 - b2) * (b1 - b2),
  );
}

/// Seuils de la mesure : une couleur est « chromatique » au-dessus de 30 de
/// chroma ; deux couleurs chromatiques a moins de 30 degres de teinte sont
/// de la meme famille (le violet et la lavande), donc confondues.
const double _chromaFamille = 30;
const double _teinteFamille = 30;

/// Vrai quand le point d'une pastille se confond avec un accent de profil.
bool _confondu(Color point, Color accent) =>
    _chroma(point) >= _chromaFamille &&
    _chroma(accent) >= _chromaFamille &&
    _ecartTeinte(point, accent) < _teinteFamille;

/// La couleur du disque rendu dans la pastille.
Color _point(WidgetTester tester) {
  final DecoratedBox disque = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(StatusPill),
      matching: find.byWidgetPredicate(
        (Widget w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle,
      ),
    ),
  );
  return (disque.decoration as BoxDecoration).color!;
}

void main() {
  group('M1 : le montant au bord de fin, une seule colonne', () {
    for (final double largeur in const <double>[390, 1440]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('${largeur.toInt()} px, ${sens.name}', (
          WidgetTester tester,
        ) async {
          await _monter(tester, _colonne, largeur: largeur, sens: sens);
          expect(tester.takeException(), isNull);
          final List<double> fins = <double>[];
          final Finder lignes = find.byWidgetPredicate(
            (Widget w) =>
                w is LigneFinance ||
                w is LigneTransaction ||
                w is LigneAllocation,
          );
          expect(lignes, findsNWidgets(_montants.length));
          for (int i = 0; i < _montants.length; i++) {
            final (Type type, String texte) = _montants[i];
            final Finder ligne = lignes.at(i);
            expect(tester.widget(ligne).runtimeType, type);
            final Rect r = tester.getRect(ligne);
            final Rect m = tester.getRect(
              find.descendant(of: ligne, matching: find.text(texte)),
            );
            final double finLigne = sens == TextDirection.ltr
                ? r.right
                : r.left;
            final double finMontant = sens == TextDirection.ltr
                ? m.right
                : m.left;
            expect(
              finMontant,
              moreOrLessEquals(finLigne, epsilon: 0.5),
              reason: '$texte : fin du montant = fin de la ligne',
            );
            fins.add(finMontant);
          }
          // Une colonne : toutes les fins sur un seul bord.
          for (final double f in fins) {
            expect(f, moreOrLessEquals(fins.first, epsilon: 0.5));
          }
          // La pastille du mouvement passe avant le montant, jamais apres :
          // sur la meme ligne, du cote du debut ; sinon au-dessus.
          final Rect pastille = tester.getRect(find.byType(StatusPill));
          final Rect debit = tester.getRect(
            find.text(formaterMontant(_debit, signe: true)),
          );
          final bool dessus = pastille.bottom <= debit.top + 0.5;
          final bool avant = sens == TextDirection.ltr
              ? pastille.right <= debit.left + 0.5
              : pastille.left >= debit.right - 0.5;
          expect(dessus || avant, isTrue);
        });
      }
    }

    testWidgets('texte x2 : empile, le montant garde le bord de fin', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _colonne, largeur: 320, echelle: 2);
      expect(tester.takeException(), isNull);
      final Rect ligne = tester.getRect(find.byType(LigneFinance).first);
      final Rect m = tester.getRect(
        find.text(formaterMontant(_cinquante)).first,
      );
      final Rect cle = tester.getRect(find.text('Tarif enfant'));
      expect(m.top, greaterThanOrEqualTo(cle.bottom));
      expect(m.right, moreOrLessEquals(ligne.right, epsilon: 0.5));
    });

    testWidgets('ResumeSoldes empile : ses valeurs au bord de fin', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const ResumeSoldes(
          synthese: SyntheseFoyer(
            totalSoldes: _total,
            aPayerCeMois: Montant(800, 'USD'),
            profilsFinances: 2,
            profils: 3,
            paiementsDuMois: 2,
          ),
        ),
      );
      final Rect resume = tester.getRect(find.byType(ResumeSoldes));
      final Rect aPayer = tester.getRect(
        find.text(formaterMontant(const Montant(800, 'USD'))),
      );
      expect(aPayer.right, moreOrLessEquals(resume.right, epsilon: 0.5));
    });
  });

  group('M2 : la pastille d essai dit « Essai : n/max »', () {
    testWidgets('les deux compteurs rendus : « Essai : 1/2 »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const PastilleFinanciere(
          etat: EtatFinancier.essai,
          essaisUtilises: 1,
          essaisMax: 2,
        ),
      );
      expect(find.text('Essai : 1/2'), findsOneWidget);
      expect(
        PastilleFinanciere.libelleEssai(utilises: 2, max: 2),
        'Essai : 2/2',
      );
    });

    testWidgets('sans maximum lu : le mot seul, jamais un maximum suppose', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const PastilleFinanciere(etat: EtatFinancier.essai, essaisUtilises: 1),
      );
      expect(find.text(t.argent.etat.essai), findsOneWidget);
    });

    testWidgets('hors essai, les compteurs ne changent pas le mot', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const PastilleFinanciere(
          etat: EtatFinancier.finance,
          essaisUtilises: 1,
          essaisMax: 2,
        ),
      );
      expect(find.text(t.argent.etat.finance), findsOneWidget);
    });
  });

  group('M3 : le ton de l essai se distingue des accents de profil', () {
    for (final Brightness luminosite in Brightness.values) {
      testWidgets('${luminosite.name} : mesure contre les six accents', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          const PastilleFinanciere(etat: EtatFinancier.essai),
          luminosite: luminosite,
        );
        final AppPalette palette = AppPalette.of(
          tester.element(find.byType(StatusPill)),
        );
        final Color essai = _point(tester);
        final List<Color> accents = <Color>[
          for (final AccentProfil a in AccentProfil.values)
            palette.accentsProfil[a.index].background,
        ];
        for (final Color accent in accents) {
          expect(_confondu(essai, accent), isFalse);
          // Ecart perceptible avec chacun (CIE76 >= 20 ; mesure : 26 au
          // plus pres, ciel en clair).
          expect(_deltaE(essai, accent), greaterThanOrEqualTo(20));
        }
        // Contre-epreuve : l'ancien ton (accent, point surfacePrimary) se
        // confond avec lavande (6 degres en clair, 4 en sombre). La mesure
        // distingue donc bien les deux cas.
        expect(
          _confondu(
            palette.surfacePrimary.background,
            palette.accentsProfil[AccentProfil.lavande.index].background,
          ),
          isTrue,
        );
      });
    }
  });

  group('Sans la couleur : chaque etat se lit par son mot', () {
    testWidgets('la pastille dit son mot au lecteur d ecran, et deux etats '
        'du meme ton gardent des mots distincts', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      final Map<TonEtat, Set<String>> parTon = <TonEtat, Set<String>>{};
      for (final EtatFinancier e in EtatFinancier.values) {
        await _monter(tester, PastilleFinanciere(etat: e));
        // Lu sans la couleur : le libelle semantique est le mot de l'etat.
        expect(
          tester.getSemantics(find.byType(StatusPill)),
          isSemantics(label: PastilleFinanciere.libelleDe(e)),
        );
        parTon
            .putIfAbsent(PastilleFinanciere.tonDe(e), () => <String>{})
            .add(PastilleFinanciere.libelleDe(e));
      }
      final int mots = parTon.values.fold<int>(
        0,
        (int n, Set<String> s) => n + s.length,
      );
      expect(mots, EtatFinancier.values.length);
      h.dispose();
    });
  });

  group('Theme sombre : les neuf composants d argent', () {
    for (final Brightness luminosite in Brightness.values) {
      testWidgets('${luminosite.name} : rendus, encres de la palette', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const MontantArgent(_total, taille: TailleMontant.grand),
              _colonne,
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: PastilleFinanciere(etat: EtatFinancier.aRegulariser),
              ),
              BadgePeriodeFinancee(
                periode: PeriodeFinancee(
                  debut: DateTime(2026, 10),
                  fin: DateTime(2026, 10, 31, 12),
                ),
              ),
              const BandeauAttention(
                titre: 'Paiement en cours de confirmation',
                message: 'Ne payez pas une seconde fois.',
              ),
              LigneMoyenPaiement(rail: RailPaiement.webStripe, onPress: () {}),
              const ResumeSoldes(
                synthese: SyntheseFoyer(
                  totalSoldes: Montant(800, 'USD'),
                  aPayerCeMois: Montant(0, 'USD'),
                  profilsFinances: 3,
                  profils: 3,
                  paiementsDuMois: 1,
                ),
              ),
            ],
          ),
          luminosite: luminosite,
        );
        expect(tester.takeException(), isNull);
        final BuildContext ctx = tester.element(
          find.byType(MontantArgent).first,
        );
        final AppPalette palette = AppPalette.of(ctx);
        expect(palette.estSombre, luminosite == Brightness.dark);
        // Le montant prend l'encre forte du theme courant, jamais une
        // couleur figee.
        final Text grand = tester.widget<Text>(
          find.descendant(
            of: find.byType(MontantArgent).first,
            matching: find.byType(Text),
          ),
        );
        expect(
          grand.style!.color,
          palette.inkStrong.applyTo(const TextStyle()).color,
        );
        final Text ligne = tester.widget<Text>(
          find.text(formaterMontant(_remise)),
        );
        expect(
          ligne.style!.color,
          palette.inkStrong.applyTo(const TextStyle()).color,
        );
      });
    }
  });

  group('m1 : un grand montant ne se coupe jamais dans le nombre', () {
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('320 px, texte x2, ${sens.name}', (
        WidgetTester tester,
      ) async {
        const Montant m = Montant(-123456, 'USD');
        await _monter(
          tester,
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: MontantArgent(m, taille: TailleMontant.grand),
          ),
          largeur: 320,
          echelle: 2,
          sens: sens,
        );
        expect(tester.takeException(), isNull);
        final String texte = formaterMontant(m);
        final RenderParagraph p = tester.renderObject<RenderParagraph>(
          find.text(texte),
        );
        final List<TextBox> boites = p.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: texte.length),
        );
        // Une seule ligne : toutes les boites sur le meme haut.
        for (final TextBox b in boites) {
          expect(b.top, moreOrLessEquals(boites.first.top, epsilon: 0.5));
        }
        // Et le chiffre reste dans la ligne de 288 px.
        expect(
          tester.getRect(find.byType(MontantArgent)).width,
          lessThanOrEqualTo(320 - 32 + 0.5),
        );
      });
    }
  });

  group('m3 : le moyen de paiement hors ligne est annonce indisponible', () {
    testWidgets('sans onPress : desactive ; avec : actif', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _monter(
        tester,
        const LigneMoyenPaiement(rail: RailPaiement.webStripe, retenu: true),
      );
      expect(
        tester.getSemantics(find.byType(LigneMoyenPaiement)),
        isSemantics(
          hasEnabledState: true,
          isEnabled: false,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      await _monter(
        tester,
        LigneMoyenPaiement(rail: RailPaiement.webStripe, onPress: () {}),
      );
      expect(
        tester.getSemantics(find.byType(LigneMoyenPaiement)),
        isSemantics(hasEnabledState: true, isEnabled: true),
      );
      h.dispose();
    });
  });
}

// COM-COMU-2 : les motifs de signalement de la politique anti-promotion
// (spec section 5.5), le port du garde (COM-BR-07, aucune detection cote
// client, jamais « Verifie ») et la demonstration du garde, dans la VRAIE
// coquille de l'enseignant.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/communications/moderation.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/com_communaute/composer_publication.dart';
import 'package:rewayah_academy/features/com_communaute/etat_lien.dart';
import 'package:rewayah_academy/features/com_communaute/feuille_signalement_communaute.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';
import 'package:rewayah_academy/features/com_communaute/garde_promotion.dart';
import 'package:rewayah_academy/features/com_communaute/port_communaute.dart';
import 'package:rewayah_academy/features/com_communaute/port_garde_promotion.dart';
import 'package:rewayah_academy/features/com_communaute/publication_detail.dart';
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import 'banc_communaute.dart';

Future<void> _monterDemo(
  WidgetTester tester,
  SituationDemoCommunaute situation, {
  Size taille = const Size(390, 844),
}) async {
  fixerTaille(tester, taille);
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoCommunaute(situation),
    routes: routesDemoCommunications('dev'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Ouvre la feuille de signalement de la publication « memorisation ».
Future<void> _ouvrirSignalement(WidgetTester tester) async {
  await taper(
    tester,
    find.byKey(FluxPublications.cleCarte('pub-memorisation')),
  );
  await taper(tester, find.byKey(PublicationDetail.cleMenu));
  await taper(tester, find.text(t.com.communaute.publication.signaler));
}

const BrouillonPublication _brouillonAffilie = BrouillonPublication(
  categorieId: 'pedagogie',
  titre: 'Mon lecteur audio préféré pour réviser',
  texte:
      "J'utilise ce lecteur pour faire réécouter les sourates. Il est en "
      'réduction cette semaine avec mon lien : '
      'https://lecteur-coran.example/produit?ref=prof42',
);

void main() {
  group('motifs de signalement (spec section 5.5)', () {
    testWidgets('les huit motifs, dans l ordre de la spec ; un motif de la '
        'politique dit la regle qu il vise', (WidgetTester tester) async {
      await monterCommunaute(tester, taille: const Size(1440, 900));
      await _ouvrirSignalement(tester);

      double? precedent;
      for (final MotifSignalement motif in MotifSignalement.values) {
        final Finder carte = find.byKey(
          FeuilleSignalementCommunaute.cleMotif(motif),
        );
        expect(carte, findsOneWidget, reason: motif.name);
        final double haut = tester.getTopLeft(carte).dy;
        if (precedent != null) {
          expect(haut, greaterThan(precedent), reason: motif.name);
        }
        precedent = haut;
      }
      expect(MotifSignalement.values, hasLength(8));
      expect(find.byKey(FeuilleSignalementCommunaute.cleRegle), findsNothing);

      final Map<MotifSignalement, String?>
      attendu = <MotifSignalement, String?>{
        MotifSignalement.publicite:
            "La publicité n'est pas autorisée dans la Communauté enseignants.",
        MotifSignalement.lienAffilie:
            'Les liens affiliés ne sont pas autorisés dans la Communauté '
            'enseignants.',
        MotifSignalement.venteNonAutorisee:
            "La vente de produits ou de services n'est pas autorisée dans "
            'cet espace.',
        MotifSignalement.sollicitationCommerciale:
            "La sollicitation commerciale n'est pas autorisée dans cet "
            'espace.',
        MotifSignalement.harcelement: null,
      };
      for (final MapEntry<MotifSignalement, String?> e in attendu.entries) {
        await taper(
          tester,
          find.byKey(FeuilleSignalementCommunaute.cleMotif(e.key)),
        );
        final String? regle = e.value;
        if (regle == null) {
          expect(
            find.byKey(FeuilleSignalementCommunaute.cleRegle),
            findsNothing,
            reason: e.key.name,
          );
        } else {
          expect(
            tester
                .widget<Text>(find.byKey(FeuilleSignalementCommunaute.cleRegle))
                .data,
            regle,
            reason: e.key.name,
          );
        }
      }
      await demonter(tester);
    });

    test('reglePolitique : les quatre motifs commerciaux seulement', () {
      final List<MotifSignalement> politiques = <MotifSignalement>[
        for (final MotifSignalement m in MotifSignalement.values)
          if (reglePolitique(m) != null) m,
      ];
      expect(politiques, <MotifSignalement>[
        MotifSignalement.publicite,
        MotifSignalement.lienAffilie,
        MotifSignalement.venteNonAutorisee,
        MotifSignalement.sollicitationCommerciale,
      ]);
    });

    testWidgets('le motif choisi part au port ; la confirmation exacte ne '
        'vient qu apres l accuse', (WidgetTester tester) async {
      final ModerationDemo moderation = ModerationDemo();
      await monterCommunaute(
        tester,
        taille: const Size(1440, 900),
        moderation: moderation,
      );
      await _ouvrirSignalement(tester);
      await taper(
        tester,
        find.byKey(
          FeuilleSignalementCommunaute.cleMotif(MotifSignalement.lienAffilie),
        ),
      );
      await taper(tester, find.byKey(FeuilleSignalementCommunaute.cleEnvoyer));
      expect(moderation.signalements, hasLength(1));
      expect(moderation.signalements.single.$2, MotifSignalement.lienAffilie);
      expect(moderation.signalements.single.$1.id, 'pub-memorisation');
      expect(
        find.text("Le contenu a été signalé à l'équipe de modération."),
        findsOneWidget,
      );
      await demonter(tester);
    });
  });

  group('port du garde (COM-BR-07)', () {
    test(
      'production : chaque appel echoue avec CapaciteIndisponible',
      () async {
        const GardePromotionIndisponible garde = GardePromotionIndisponible();
        await expectLater(
          garde.verifier(_brouillonAffilie),
          throwsA(
            isA<CapaciteIndisponible>().having(
              (CapaciteIndisponible e) => e.dependance,
              'dependance',
              'COM-BR-07',
            ),
          ),
        );
        await expectLater(
          garde.etatLien('https://quran.com/1'),
          throwsA(isA<CapaciteIndisponible>()),
        );
      },
    );

    test('fixtures : une table, pas une detection ; un mot change rend le '
        'brouillon normal', () async {
      final GardePromotionFixtures garde = DonneesCommunauteDemo.garde();
      final VerificationPromotion marque = await garde.verifier(
        _brouillonAffilie,
      );
      expect(marque.verdict, VerdictPromotion.lienAffilie);
      expect(marque.motif, MotifSignalement.lienAffilie);

      // Les blancs autour ne comptent pas.
      final VerificationPromotion espaces = await garde.verifier(
        BrouillonPublication(
          categorieId: 'gestion',
          titre: '  ${_brouillonAffilie.titre} ',
          texte: '${_brouillonAffilie.texte}\n',
        ),
      );
      expect(espaces.verdict, VerdictPromotion.lienAffilie);

      // Le meme lien dans un autre texte n'est pas « detecte » : seul le
      // serveur juge (COM-BR-07).
      final VerificationPromotion autre = await garde.verifier(
        const BrouillonPublication(
          categorieId: 'pedagogie',
          titre: 'Autre sujet',
          texte: 'https://lecteur-coran.example/produit?ref=prof42',
        ),
      );
      expect(autre.verdict, VerdictPromotion.normal);
      expect(autre.liens, isEmpty);
    });

    test(
      'etatLien : les quatre etats des fixtures ; inconnu = non verifie',
      () async {
        final GardePromotionFixtures garde = DonneesCommunauteDemo.garde();
        for (final MapEntry<String, EtatLien> e
            in DonneesCommunauteDemo.etatsLiens.entries) {
          expect(await garde.etatLien(e.key), e.value);
        }
        expect(
          await garde.etatLien('https://inconnu.example'),
          EtatLien.nonVerifie,
        );
      },
    );

    test('verdicts : seuls lien affilie et vente bloquent ; tout sauf normal '
        'retient', () {
      expect(
        <VerdictPromotion>[
          for (final VerdictPromotion v in VerdictPromotion.values)
            if (v.bloque) v,
        ],
        <VerdictPromotion>[
          VerdictPromotion.lienAffilie,
          VerdictPromotion.vente,
        ],
      );
      expect(VerdictPromotion.normal.retient, isFalse);
      expect(VerdictPromotion.avertissement.retient, isTrue);
      expect(GardePromotion.texteDe(VerdictPromotion.normal), isNull);
    });

    test('jamais « Verifie » : quatre etats de lien, aucun texte de la '
        'Communaute ne le dit', () {
      expect(EtatLien.values, hasLength(4));
      for (final EtatLien e in EtatLien.values) {
        expect(e.libelle.toLowerCase(), isNot(startsWith('vérifié')));
        expect(e.libelle.toLowerCase(), isNot(startsWith('lien vérifié')));
      }
      final Map<String, dynamic> fr = jsonDecode(
        File('assets/i18n/fr.i18n.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final Map<String, dynamic> communaute =
          (fr['com'] as Map<String, dynamic>)['communaute']
              as Map<String, dynamic>;
      final List<String> textes = <String>[];
      void aplatir(Object? v) {
        if (v is Map<String, dynamic>) {
          v.values.forEach(aplatir);
        } else if (v is String) {
          textes.add(v);
        }
      }

      aplatir(communaute);
      expect(
        // « Lien non verifie » est le seul emploi admis (spec section 5.4).
        textes.where(
          (String s) =>
              s.toLowerCase().replaceAll('non vérifié', '').contains('vérifié'),
        ),
        isEmpty,
      );
    });
  });

  group('demonstration du garde', () {
    for (final (SituationDemoCommunaute s, ValueKey<String> verdict)
        in <(SituationDemoCommunaute, ValueKey<String>)>[
          (SituationDemoCommunaute.lienAffilie, GardePromotion.cleBlocage),
          (SituationDemoCommunaute.vente, GardePromotion.cleBlocage),
          (
            SituationDemoCommunaute.avertissementPromotion,
            GardePromotion.cleAvertissement,
          ),
        ]) {
      testWidgets('${s.name} : brouillon restaure, une categorie, « Publier » '
          'retient la publication', (WidgetTester tester) async {
        await _monterDemo(tester, s);
        expect(find.byType(NavShell), findsOneWidget);
        expect(find.byType(ComposerPublication), findsOneWidget);
        await taper(
          tester,
          find.byKey(
            ComposerPublication.cleCategorie(
              DonneesCommunauteDemo.ressources.id,
            ),
          ),
        );
        await taper(tester, find.byKey(ComposerPublication.clePublier));
        expect(find.byKey(verdict), findsOneWidget);
        expect(find.byType(ComposerPublication), findsOneWidget);
        expect(find.text(t.com.communaute.composer.confirmee), findsNothing);
        expect(tester.takeException(), isNull);
        await demonter(tester);
      });
    }

    testWidgets('signalement non confirme : il le dit, sans confirmation', (
      WidgetTester tester,
    ) async {
      await _monterDemo(
        tester,
        SituationDemoCommunaute.signalementNonConfirme,
        taille: const Size(1440, 900),
      );
      await _ouvrirSignalement(tester);
      await taper(
        tester,
        find.byKey(
          FeuilleSignalementCommunaute.cleMotif(MotifSignalement.publicite),
        ),
      );
      await taper(tester, find.byKey(FeuilleSignalementCommunaute.cleEnvoyer));
      expect(
        find.byKey(FeuilleSignalementCommunaute.cleErreur),
        findsOneWidget,
      );
      expect(find.text(t.com.socle.signalement.erreur), findsOneWidget);
      expect(find.byKey(PublicationDetail.cleSignalee), findsNothing);
      await demonter(tester);
    });
  });
}

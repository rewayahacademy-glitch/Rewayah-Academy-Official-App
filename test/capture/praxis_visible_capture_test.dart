// Captures du lot PRAXIS-VISIBLE (R3) : la carte « L'avis de Praxis » du
// dossier et la page « Le travail de Praxis » (objectifs, filtres, dossiers),
// a 390 et 1440 px, en clair et en sombre, en francais et en arabe (de droite
// a gauche). Donnees fictives : aucune personne reelle. Saute sans CAPTURE_DIR
// (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/agent/travail_praxis.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/admin_candidature/avis_praxis_dossier.dart';
import 'package:rewayah_academy/features/admin_candidatures/travail_praxis_page.dart';

import 'outil_capture.dart';

final DateTime _le = DateTime.utc(2026, 11, 20, 9, 30);

List<RangementPraxis> _rangements(bool ar) => <RangementPraxis>[
  RangementPraxis(
    reference: 'CAND-00041',
    nom: ar ? 'أمينة الخيالية' : 'Amina Fictive',
    pile: PilePraxis.pretADecider,
    raison: ar
        ? 'كل الوثائق موجودة، والمقابلة الكتابية تمت.'
        : "Toutes les pièces sont là, l'entretien écrit est fait.",
    rangeLe: _le,
  ),
  RangementPraxis(
    reference: 'CAND-00042',
    nom: ar ? 'بلال الخيالي' : 'Bilal Fictif',
    pile: PilePraxis.incomplet,
    raison: ar ? 'تنقص صورة الهوية.' : "Il manque la pièce d'identité.",
    rangeLe: _le.subtract(const Duration(hours: 1)),
  ),
  RangementPraxis(
    reference: 'CAND-00043',
    nom: ar ? 'شادية الخيالية' : 'Chadia Fictive',
    pile: PilePraxis.sansNouvelles,
    raison: ar
        ? 'لا رد منذ ثلاثة أسابيع.'
        : 'Aucune réponse depuis trois semaines.',
    rangeLe: _le.subtract(const Duration(hours: 2)),
  ),
  RangementPraxis(
    reference: 'CAND-00044',
    nom: ar ? 'داود الخيالي' : 'Dawud Fictif',
    pile: PilePraxis.aRegarder,
    raison: ar
        ? 'إجابات متناقضة حول التفرّغ.'
        : 'Réponses contradictoires sur la disponibilité.',
    rangeLe: _le.subtract(const Duration(hours: 3)),
  ),
];

List<ImpressionPraxis> _impressions(bool ar) => <ImpressionPraxis>[
  ImpressionPraxis(
    reference: 'CAND-00041',
    nom: ar ? 'أمينة الخيالية' : 'Amina Fictive',
    etiquette: EtiquettePraxis.pepite,
    confiance: ConfiancePraxis.forte,
    texte: ar
        ? 'ملف واضح وإجابات دقيقة. تدرّس الأطفال منذ ست سنوات وتشرح بهدوء.'
        : 'Un dossier clair, des réponses précises. Enseigne aux enfants depuis six ans et explique avec calme.',
    noteeLe: _le,
    notes: const <CriterePraxis, int>{
      CriterePraxis.maitrise: 5,
      CriterePraxis.pedagogie: 4,
      CriterePraxis.disponibilite: 3,
    },
    contexte: <ElementContexte>[
      ElementContexte(
        theme: ar ? 'الخبرة' : 'Expérience',
        constat: ar
            ? 'تدرّس الأطفال منذ ست سنوات.'
            : 'Enseigne aux enfants depuis six ans.',
        source: ar ? 'الإجابة عن المسار' : 'Réponse sur le parcours',
        effet: EffetContexte.atout,
      ),
      ElementContexte(
        theme: ar ? 'المواعيد' : 'Horaires',
        constat: ar ? 'متاحة في المساء فقط.' : 'Disponible le soir seulement.',
        source: ar ? 'الأوقات المتاحة' : 'Disponibilités',
        effet: EffetContexte.aVerifier,
      ),
      ElementContexte(
        theme: ar ? 'الاتصال' : 'Connexion',
        constat: ar
            ? 'تذكر انقطاعات في الإنترنت.'
            : 'Signale des coupures de connexion.',
        source: ar ? 'رسالة في المحادثة' : 'Message dans la conversation',
        effet: EffetContexte.risque,
      ),
    ],
    synthese: SynthesePraxis(
      utilePour: ar ? 'أقسام الأطفال' : "les classes d'enfants",
      situation: ar ? 'في أيام الأسبوع، مساءً' : 'en semaine, le soir',
      reserves: ar
          ? 'الاتصال يحتاج إلى تأكيد'
          : 'la connexion reste à confirmer',
      video: true,
      videoPourquoi: ar
          ? 'التلاوة يجب أن تُسمع'
          : "la récitation doit s'entendre",
    ),
  ),
  ImpressionPraxis(
    reference: 'CAND-00042',
    nom: ar ? 'بلال الخيالي' : 'Bilal Fictif',
    etiquette: EtiquettePraxis.solide,
    confiance: ConfiancePraxis.moyenne,
    texte: 'x',
    noteeLe: _le,
  ),
  ImpressionPraxis(
    reference: 'CAND-00045',
    nom: ar ? 'إلياس الخيالي' : 'Elias Fictif',
    etiquette: EtiquettePraxis.aCreuser,
    confiance: ConfiancePraxis.faible,
    texte: 'x',
    noteeLe: _le.subtract(const Duration(hours: 5)),
  ),
];

List<ObjectifPraxis> _objectifs(bool ar) => <ObjectifPraxis>[
  ObjectifPraxis(
    id: 'o1',
    periode: PeriodeObjectif.jour,
    debut: DateTime(2026, 11, 20),
    libelle: ar
        ? 'تصنيف ثلاثين ملفًا وصلت هذا الأسبوع'
        : 'Ranger trente dossiers reçus cette semaine',
    etat: EtatObjectif.ouvert,
    creeLe: _le,
    cible: 30,
  ),
  ObjectifPraxis(
    id: 'o2',
    periode: PeriodeObjectif.semaine,
    debut: DateTime(2026, 11, 16),
    libelle: ar
        ? 'قراءة كل الملفات الجاهزة للقرار'
        : 'Lire tous les dossiers prêts à décider',
    etat: EtatObjectif.ouvert,
    creeLe: _le,
    echu: true,
  ),
  ObjectifPraxis(
    id: 'o3',
    periode: PeriodeObjectif.jour,
    debut: DateTime(2026, 11, 19),
    libelle: ar
        ? 'مراسلة الملفات التي بلا أخبار'
        : 'Relancer les dossiers sans nouvelles',
    etat: EtatObjectif.atteint,
    creeLe: _le,
    closLe: _le,
    noteCloture: ar ? 'تمت اثنتا عشرة مراسلة.' : 'Douze relances faites.',
  ),
];

class _Service implements ServiceTravailPraxis {
  const _Service(this.ar);

  final bool ar;

  @override
  Future<PageRangements> rangements({
    PilePraxis? pile,
    int limite = 200,
    int decalage = 0,
  }) async => PageRangements(
    lignes: _rangements(ar),
    total: 108,
    parPile: const <PilePraxis, int>{
      PilePraxis.pretADecider: 31,
      PilePraxis.incomplet: 44,
      PilePraxis.sansNouvelles: 21,
      PilePraxis.aRegarder: 12,
    },
  );

  @override
  Future<PageImpressions> impressions({
    EtiquettePraxis? etiquette,
    int limite = 200,
    int decalage = 0,
  }) async => PageImpressions(
    lignes: _impressions(ar),
    total: 3,
    parEtiquette: const <EtiquettePraxis, int>{
      EtiquettePraxis.pepite: 1,
      EtiquettePraxis.solide: 1,
      EtiquettePraxis.aCreuser: 1,
    },
  );

  @override
  Future<List<ObjectifPraxis>> objectifs({
    bool tous = true,
    int limite = 50,
    int decalage = 0,
  }) async => _objectifs(ar);
}

void main() {
  group('Capture : PRAXIS-VISIBLE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final double largeur in <double>[390, 1440]) {
          for (final String quoi in <String>['avis', 'piles']) {
            final String nom =
                'praxis_${quoi}_${langue.languageCode}_${theme.name}_'
                '${largeur.toInt()}';
            testWidgets(nom, (WidgetTester tester) async {
              await tester.runAsync(() => LocaleSettings.setLocale(langue));
              final bool ar = langue == AppLocale.ar;
              final double hauteur = switch ((quoi, largeur)) {
                ('avis', 390) => 1700,
                ('avis', _) => 1150,
                ('piles', 390) => 2300,
                _ => 1400,
              };
              fixerVueCapture(tester, Size(largeur, hauteur), 1);
              final List<Override> surcharges = <Override>[
                serviceTravailPraxisProvider.overrideWithValue(_Service(ar)),
                horsLigneProvider.overrideWith(
                  (Ref _) => Stream<bool>.value(false),
                ),
              ];
              final Widget ecran = quoi == 'avis'
                  ? Scaffold(
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Align(
                          alignment: AlignmentDirectional.topStart,
                          child: ConstrainedBox(
                            // La colonne de gauche du dossier au bureau.
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: const AvisPraxisDossier(
                              reference: 'CAND-00041',
                            ),
                          ),
                        ),
                      ),
                    )
                  : TravailPraxisPage(ouvrirDossier: (String _) {});
              await tester.pumpWidget(
                hoteCapture(ecran, surcharges: surcharges, themeMode: theme),
              );
              await stabiliser(tester);
              expect(tester.takeException(), isNull);
              debugPrint('PNG ${await capturer(tester, nom)}');
              await tester.pumpWidget(const SizedBox());
              await tester.runAsync(
                () => LocaleSettings.setLocale(AppLocale.fr),
              );
            });
          }
        }
      }
    }
  });
}

// PRAXIS-VISIBLE : le travail de Praxis vu par la direction.
//
//  - la lecture du serveur (forme exacte des trois lectures, pages de 200) ;
//  - la carte « L'avis de Praxis » du dossier : chaque etat (chargement,
//    contenu, pas encore lu, erreur, hors ligne, refus du serveur), seuls les
//    criteres notes, la synthese en phrases, le contexte, la pile et sa raison,
//    la phrase fixe ;
//  - la marque d'une ligne de la file et le lien vers la page ;
//  - la page « Le travail de Praxis » : chaque etat, chaque filtre dans
//    l'adresse (lu au chargement, ecrit au choix), toucher une ligne ouvre le
//    dossier, le retour ramene a la liste filtree ;
//  - les objectifs : ouverts du jour et de la semaine, cible, clos recents.
//
// Donnees fictives : aucune personne reelle.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/agent/travail_praxis.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_candidature/avis_praxis_dossier.dart';
import 'package:rewayah_academy/features/admin_candidatures/marque_travail_praxis.dart';
import 'package:rewayah_academy/features/admin_candidatures/objectifs_praxis.dart';
import 'package:rewayah_academy/features/admin_candidatures/travail_praxis_page.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

// ---------------------------------------------------------------------------
// Fixtures (fictives)
// ---------------------------------------------------------------------------

final DateTime _le = DateTime.utc(2026, 11, 20, 9, 30);

RangementPraxis _rang(
  String reference,
  PilePraxis pile, {
  String nom = 'Candidat Fictif',
  String raison = 'Toutes les pièces sont là.',
  int minutes = 0,
}) => RangementPraxis(
  reference: reference,
  nom: nom,
  pile: pile,
  raison: raison,
  rangeLe: _le.add(Duration(minutes: minutes)),
);

ImpressionPraxis _impr(
  String reference,
  EtiquettePraxis etiquette, {
  String nom = 'Candidat Fictif',
  Map<CriterePraxis, int> notes = const <CriterePraxis, int>{},
  List<ElementContexte> contexte = const <ElementContexte>[],
  SynthesePraxis? synthese,
  String texte = 'Un dossier clair, des réponses précises.',
}) => ImpressionPraxis(
  reference: reference,
  nom: nom,
  etiquette: etiquette,
  confiance: ConfiancePraxis.forte,
  texte: texte,
  noteeLe: _le,
  notes: notes,
  contexte: contexte,
  synthese: synthese,
);

final List<RangementPraxis> _rangements = <RangementPraxis>[
  _rang(
    'CAND-00001',
    PilePraxis.pretADecider,
    nom: 'Amina Fictive',
    minutes: 5,
  ),
  _rang('CAND-00002', PilePraxis.incomplet, nom: 'Bilal Fictif', minutes: 4),
  _rang(
    'CAND-00003',
    PilePraxis.sansNouvelles,
    nom: 'Chadia Fictive',
    minutes: 3,
  ),
  _rang('CAND-00004', PilePraxis.aRegarder, nom: 'Dawud Fictif', minutes: 2),
];

final List<ImpressionPraxis> _impressions = <ImpressionPraxis>[
  _impr('CAND-00001', EtiquettePraxis.pepite, nom: 'Amina Fictive'),
  _impr('CAND-00002', EtiquettePraxis.solide, nom: 'Bilal Fictif'),
  // Lu, jamais range.
  _impr('CAND-00005', EtiquettePraxis.aCreuser, nom: 'Elias Fictif'),
];

final List<ObjectifPraxis> _objectifs = <ObjectifPraxis>[
  ObjectifPraxis(
    id: 'o1',
    periode: PeriodeObjectif.jour,
    debut: DateTime(2026, 11, 20),
    libelle: 'Ranger trente dossiers reçus cette semaine',
    etat: EtatObjectif.ouvert,
    creeLe: _le,
    cible: 30,
  ),
  ObjectifPraxis(
    id: 'o2',
    periode: PeriodeObjectif.semaine,
    debut: DateTime(2026, 11, 16),
    libelle: 'Lire tous les dossiers prêts à décider',
    etat: EtatObjectif.ouvert,
    creeLe: _le,
    echu: true,
  ),
  ObjectifPraxis(
    id: 'o3',
    periode: PeriodeObjectif.jour,
    debut: DateTime(2026, 11, 19),
    libelle: 'Relancer les dossiers sans nouvelles',
    etat: EtatObjectif.atteint,
    creeLe: _le,
    closLe: _le,
    noteCloture: 'Douze relances faites.',
  ),
];

class _Faux implements ServiceTravailPraxis {
  _Faux({
    List<RangementPraxis>? rangements,
    List<ImpressionPraxis>? impressions,
    List<ObjectifPraxis>? objectifs,
  }) : rangementsRendus = rangements ?? _rangements,
       impressionsRendues = impressions ?? _impressions,
       objectifsRendus = objectifs ?? _objectifs;

  List<RangementPraxis> rangementsRendus;
  List<ImpressionPraxis> impressionsRendues;
  List<ObjectifPraxis> objectifsRendus;
  Exception? erreur;
  Exception? erreurObjectifs;
  Completer<void>? attente;
  final List<int> decalages = <int>[];
  int lectures = 0;

  @override
  Future<PageRangements> rangements({
    PilePraxis? pile,
    int limite = 200,
    int decalage = 0,
  }) async {
    lectures++;
    decalages.add(decalage);
    if (attente != null) await attente!.future;
    if (erreur != null) throw erreur!;
    final Map<PilePraxis, int> par = <PilePraxis, int>{};
    for (final RangementPraxis r in rangementsRendus) {
      par[r.pile] = (par[r.pile] ?? 0) + 1;
    }
    return PageRangements(
      lignes: rangementsRendus.skip(decalage).take(limite).toList(),
      total: rangementsRendus.length,
      parPile: par,
    );
  }

  @override
  Future<PageImpressions> impressions({
    EtiquettePraxis? etiquette,
    int limite = 200,
    int decalage = 0,
  }) async {
    if (attente != null) await attente!.future;
    if (erreur != null) throw erreur!;
    final Map<EtiquettePraxis, int> par = <EtiquettePraxis, int>{};
    for (final ImpressionPraxis i in impressionsRendues) {
      par[i.etiquette] = (par[i.etiquette] ?? 0) + 1;
    }
    return PageImpressions(
      lignes: impressionsRendues.skip(decalage).take(limite).toList(),
      total: impressionsRendues.length,
      parEtiquette: par,
    );
  }

  @override
  Future<List<ObjectifPraxis>> objectifs({
    bool tous = true,
    int limite = 50,
    int decalage = 0,
  }) async {
    if (erreurObjectifs != null) throw erreurObjectifs!;
    return objectifsRendus;
  }
}

List<Override> _surcharges(_Faux faux, {bool horsLigne = false}) => <Override>[
  serviceTravailPraxisProvider.overrideWithValue(faux),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
];

Future<void> _laisser(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _monterCarte(
  WidgetTester tester,
  _Faux faux, {
  String reference = 'CAND-00001',
  bool horsLigne = false,
  Size taille = const Size(1440, 2400),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AvisPraxisDossier(reference: reference),
        ),
      ),
      surcharges: _surcharges(faux, horsLigne: horsLigne),
    ),
  );
  await _laisser(tester);
}

const String _cheminDossier = '/admin/personnes/candidatures/:reference';

Future<void> _monterPage(
  WidgetTester tester,
  _Faux faux, {
  String depart = Routes.adminPersonnesTravailPraxis,
  double largeur = 1440,
  double hauteur = 2400,
  double echelle = 1,
  TextDirection? direction,
  bool horsLigne = false,
}) async {
  tester.view.physicalSize = Size(largeur, hauteur);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: depart,
      echelle: echelle,
      direction: direction,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.adminPersonnesTravailPraxis,
          builder: (BuildContext contexte, GoRouterState etat) =>
              TravailPraxisPage(
                requete: etat.uri.queryParameters,
                ouvrirDossier: (String reference) => GoRouter.of(
                  contexte,
                ).push<void>(Routes.adminPersonnesCandidaturePour(reference)),
              ),
        ),
        GoRoute(
          path: _cheminDossier,
          builder: (BuildContext _, GoRouterState etat) => Scaffold(
            body: Text('dossier:${etat.pathParameters['reference']}'),
          ),
        ),
      ],
      surcharges: _surcharges(faux, horsLigne: horsLigne),
    ),
  );
  await _laisser(tester);
}

GoRouter _routeur(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).last));

Uri _adresse(WidgetTester tester) =>
    _routeur(tester).routerDelegate.currentConfiguration.uri;

Future<void> _choisir(WidgetTester tester, Key menu, String entree) async {
  await tester.ensureVisible(find.byKey(menu));
  await tester.tap(find.byKey(menu));
  await _laisser(tester);
  await tester.tap(find.text(entree).last);
  await _laisser(tester);
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final a = t.admin.praxis.avis;
  final tr = t.admin.praxis.travail;
  final o = t.admin.praxis.objectifs;

  group('lecture du serveur', () {
    test('une impression se lit telle que le serveur la rend', () {
      final ImpressionPraxis? i = ImpressionPraxis.depuisJson(<String, dynamic>{
        'reference': 'CAND-00009',
        'nom': 'Candidat Fictif',
        'etiquette': 'a_creuser',
        'confiance': 'moyenne',
        'texte': 'Texte de Praxis.',
        'notes': <String, dynamic>{
          'maitrise': 4,
          'pedagogie': null,
          'vision': 5,
          'comportement': null,
          'disponibilite': null,
        },
        'contexte': <dynamic>[
          <String, dynamic>{
            'theme': 'Réseau',
            'constat': 'Enseigne déjà en ligne.',
            'source': 'Réponse 4',
            'effet': 'atout',
          },
          <String, dynamic>{'theme': 'illisible'},
        ],
        'synthese': <String, dynamic>{
          'utile_pour': 'Les adultes',
          'video': true,
        },
        'noteeLe': '2026-11-20T09:30:00+00:00',
      });
      expect(i, isNotNull);
      expect(i!.etiquette, EtiquettePraxis.aCreuser);
      expect(i.notes, <CriterePraxis, int>{
        CriterePraxis.maitrise: 4,
        CriterePraxis.vision: 5,
      });
      expect(i.contexte, hasLength(1));
      expect(i.contexte.single.effet, EffetContexte.atout);
      expect(i.synthese?.utilePour, 'Les adultes');
      expect(i.synthese?.video, isTrue);
    });

    test('une valeur inconnue n\'est pas inventee', () {
      expect(
        RangementPraxis.depuisJson(<String, dynamic>{
          'reference': 'CAND-1',
          'pile': 'pepite',
          'raison': 'x',
          'rangeLe': '2026-11-20T09:30:00Z',
        }),
        isNull,
      );
      expect(SynthesePraxis.depuisJson(<String, dynamic>{}), isNull);
    });

    test('toutes les pages sont lues, 200 par appel', () async {
      final _Faux faux = _Faux(
        rangements: <RangementPraxis>[
          for (int k = 0; k < 250; k++)
            _rang('CAND-${k.toString().padLeft(5, '0')}', PilePraxis.incomplet),
        ],
      );
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          serviceTravailPraxisProvider.overrideWithValue(faux),
        ],
      );
      addTearDown(c.dispose);
      final ProviderSubscription<AsyncValue<PageRangements>> s = c.listen(
        rangementsPraxisProvider,
        (_, _) {},
      );
      addTearDown(s.close);
      final PageRangements p = await c.read(rangementsPraxisProvider.future);
      expect(p.lignes, hasLength(250));
      expect(faux.decalages, <int>[0, 200]);
      expect(p.parPile[PilePraxis.incomplet], 250);
    });
  });

  group('carte « L\'avis de Praxis »', () {
    testWidgets('chargement : un squelette', (tester) async {
      final _Faux faux = _Faux()..attente = Completer<void>();
      await _monterCarte(tester, faux);
      expect(find.byKey(ClesAvisPraxis.chargement), findsOneWidget);
      expect(find.byKey(ClesAvisPraxis.carte), findsNothing);
      faux.attente!.complete();
      await _laisser(tester);
    });

    testWidgets('contenu : etiquette, confiance, criteres notes seuls, '
        'synthese, contexte, texte, pile et raison, phrase fixe', (
      tester,
    ) async {
      final _Faux faux = _Faux(
        impressions: <ImpressionPraxis>[
          _impr(
            'CAND-00001',
            EtiquettePraxis.pepite,
            notes: const <CriterePraxis, int>{
              CriterePraxis.maitrise: 5,
              CriterePraxis.pedagogie: 4,
            },
            contexte: const <ElementContexte>[
              ElementContexte(
                theme: 'Expérience',
                constat: 'Enseigne à des enfants depuis six ans.',
                source: 'Réponse sur le parcours',
                effet: EffetContexte.atout,
              ),
              ElementContexte(
                theme: 'Horaires',
                constat: 'Disponible le soir seulement.',
                source: 'Disponibilités',
                effet: EffetContexte.aVerifier,
              ),
            ],
            synthese: const SynthesePraxis(
              utilePour: 'les classes d\'enfants',
              situation: 'en semaine, le soir',
              reserves: 'aucune vue',
              video: true,
              videoPourquoi: 'la récitation doit s\'entendre',
            ),
          ),
        ],
      );
      await _monterCarte(tester, faux);
      expect(find.byKey(ClesAvisPraxis.carte), findsOneWidget);
      expect(find.text(a.titre), findsOneWidget);
      expect(find.byKey(ClesAvisPraxis.rappel), findsOneWidget);
      expect(find.text(a.rappel), findsOneWidget);
      expect(find.text(tr.etiquettes.pepite), findsOneWidget);
      expect(
        find.text(a.confiance(niveau: a.confiances.forte)),
        findsOneWidget,
      );
      expect(
        find.text(a.note(critere: a.critere.maitrise, note: '5')),
        findsOneWidget,
      );
      expect(
        find.text(a.note(critere: a.critere.pedagogie, note: '4')),
        findsOneWidget,
      );
      // Un critere non note n'apparait pas.
      expect(find.textContaining(a.critere.vision), findsNothing);
      expect(
        find.text(a.utilePour(texte: 'les classes d\'enfants')),
        findsOneWidget,
      );
      expect(
        find.text(a.situation(texte: 'en semaine, le soir')),
        findsOneWidget,
      );
      expect(find.text(a.reserves(texte: 'aucune vue')), findsOneWidget);
      expect(
        find.text(a.videoOuiParce(texte: 'la récitation doit s\'entendre')),
        findsOneWidget,
      );
      expect(find.text('Expérience'), findsOneWidget);
      expect(find.text(a.effets.atout), findsOneWidget);
      expect(find.text(a.effets.aVerifier), findsOneWidget);
      expect(
        find.text(a.source(source: 'Réponse sur le parcours')),
        findsOneWidget,
      );
      expect(
        find.text('Un dossier clair, des réponses précises.'),
        findsOneWidget,
      );
      expect(find.text(a.pile(pile: tr.piles.pretADecider)), findsOneWidget);
      expect(find.text('Toutes les pièces sont là.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });

    testWidgets('pas encore lu : une phrase calme, la pile reste dite', (
      tester,
    ) async {
      await _monterCarte(tester, _Faux(), reference: 'CAND-00003');
      expect(find.byKey(ClesAvisPraxis.pasLu), findsOneWidget);
      expect(find.text(a.pasLu), findsOneWidget);
      expect(find.text(a.pile(pile: tr.piles.sansNouvelles)), findsOneWidget);
      expect(find.byKey(ClesAvisPraxis.criteres), findsNothing);
    });

    testWidgets('ni lu ni range : deux phrases calmes', (tester) async {
      await _monterCarte(tester, _Faux(), reference: 'CAND-99999');
      expect(find.text(a.pasLu), findsOneWidget);
      expect(find.text(a.pasRange), findsOneWidget);
    });

    testWidgets('erreur : une phrase vraie et « Reessayer » qui relit', (
      tester,
    ) async {
      final _Faux faux = _Faux()..erreur = Exception('panne');
      await _monterCarte(tester, faux);
      expect(find.byKey(ClesAvisPraxis.erreur), findsOneWidget);
      expect(find.text(a.erreur), findsOneWidget);
      faux.erreur = null;
      await tester.tap(find.text(t.commun.reessayer));
      await _laisser(tester);
      expect(find.byKey(ClesAvisPraxis.carte), findsOneWidget);
    });

    testWidgets('hors ligne : l\'etat commun', (tester) async {
      final _Faux faux = _Faux()..erreur = Exception('reseau');
      await _monterCarte(tester, faux, horsLigne: true);
      expect(find.byKey(ClesAvisPraxis.erreur), findsOneWidget);
      expect(find.textContaining(a.horsLigne), findsOneWidget);
    });

    testWidgets('refus du serveur : rien n\'est rendu', (tester) async {
      final _Faux faux = _Faux()
        ..erreur = const PermissionInsuffisante('direction_praxis_impressions');
      await _monterCarte(tester, faux);
      expect(find.byKey(ClesAvisPraxis.carte), findsNothing);
      expect(find.byKey(ClesAvisPraxis.erreur), findsNothing);
    });

    testWidgets('320 px, texte x2, arabe : rien ne deborde', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      tester.view.physicalSize = const Size(320, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteRoutant(
          depart: '/',
          echelle: 2,
          direction: TextDirection.rtl,
          routes: <RouteBase>[
            GoRoute(
              path: '/',
              builder: (BuildContext _, GoRouterState _) => const Scaffold(
                body: SingleChildScrollView(
                  child: AvisPraxisDossier(reference: 'CAND-00001'),
                ),
              ),
            ),
          ],
          surcharges: _surcharges(_Faux()),
        ),
      );
      await _laisser(tester);
      expect(find.byKey(ClesAvisPraxis.carte), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('la file des candidatures', () {
    testWidgets('la marque dit la pile et l\'etiquette', (tester) async {
      await tester.pumpWidget(
        hote(
          const Scaffold(
            body: Column(
              children: <Widget>[
                MarqueTravailPraxis(reference: 'CAND-00001'),
                MarqueTravailPraxis(reference: 'CAND-00005'),
                MarqueTravailPraxis(reference: 'CAND-99999'),
              ],
            ),
          ),
          surcharges: _surcharges(_Faux()),
        ),
      );
      await _laisser(tester);
      expect(
        find.text(
          tr.marque(quoi: '${tr.piles.pretADecider} · ${tr.etiquettes.pepite}'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(tr.marque(quoi: tr.etiquettes.aCreuser)),
        findsOneWidget,
      );
      expect(find.byKey(MarqueTravailPraxis.cle('CAND-99999')), findsNothing);
    });

    testWidgets('le lien dit le nombre et ouvre la page', (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.adminPersonnesCandidatures,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.adminPersonnesCandidatures,
              builder: (BuildContext _, GoRouterState _) =>
                  const Scaffold(body: LienTravailPraxis()),
            ),
            GoRoute(
              path: Routes.adminPersonnesTravailPraxis,
              builder: (BuildContext _, GoRouterState _) =>
                  const Scaffold(body: Text('page-praxis')),
            ),
          ],
          surcharges: _surcharges(_Faux()),
        ),
      );
      await _laisser(tester);
      expect(find.text(tr.lienDetail(n: '4')), findsOneWidget);
      await tester.tap(find.byKey(LienTravailPraxis.cle));
      await _laisser(tester);
      expect(find.text('page-praxis'), findsOneWidget);
    });

    testWidgets('le lien se tait sur un refus du serveur', (tester) async {
      await tester.pumpWidget(
        hote(
          const Scaffold(body: LienTravailPraxis()),
          surcharges: _surcharges(
            _Faux()..erreur = const PermissionInsuffisante('x'),
          ),
        ),
      );
      await _laisser(tester);
      expect(find.byKey(LienTravailPraxis.cle), findsNothing);
    });
  });

  group('page « Le travail de Praxis »', () {
    testWidgets('chargement : un squelette', (tester) async {
      final _Faux faux = _Faux()..attente = Completer<void>();
      await _monterPage(tester, faux);
      expect(find.byKey(TravailPraxisPage.cleChargement), findsOneWidget);
      faux.attente!.complete();
      await _laisser(tester);
    });

    testWidgets('contenu : les dossiers ranges et lus, la phrase fixe', (
      tester,
    ) async {
      await _monterPage(tester, _Faux());
      expect(find.text(tr.titre), findsWidgets);
      expect(find.text(tr.rappel), findsOneWidget);
      for (final String nom in <String>[
        'Amina Fictive',
        'Bilal Fictif',
        'Chadia Fictive',
        'Dawud Fictif',
        'Elias Fictif',
      ]) {
        expect(find.text(nom), findsOneWidget);
      }
      expect(find.text(tr.nombre(n: '5')), findsOneWidget);
      expect(tester.takeException(), isNull);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });

    testWidgets('vide : une phrase', (tester) async {
      await _monterPage(
        tester,
        _Faux(
          rangements: const <RangementPraxis>[],
          impressions: const <ImpressionPraxis>[],
        ),
      );
      expect(find.byKey(TravailPraxisPage.cleVide), findsOneWidget);
    });

    testWidgets('erreur : une phrase vraie et « Reessayer »', (tester) async {
      final _Faux faux = _Faux()..erreur = Exception('panne');
      await _monterPage(tester, faux);
      expect(find.byKey(TravailPraxisPage.cleErreur), findsOneWidget);
      expect(find.text(tr.erreur), findsOneWidget);
      faux.erreur = null;
      await tester.tap(find.text(t.commun.reessayer).last);
      await _laisser(tester);
      expect(find.text('Amina Fictive'), findsOneWidget);
    });

    testWidgets('hors ligne : l\'etat commun', (tester) async {
      await _monterPage(
        tester,
        _Faux()..erreur = Exception('reseau'),
        horsLigne: true,
      );
      expect(find.byKey(TravailPraxisPage.cleErreur), findsOneWidget);
      expect(find.textContaining(tr.horsLigne), findsOneWidget);
    });

    testWidgets('refus du serveur : la page le dit, sans « Reessayer »', (
      tester,
    ) async {
      await _monterPage(
        tester,
        _Faux()..erreur = const PermissionInsuffisante('x'),
      );
      expect(find.text(tr.permission), findsOneWidget);
    });

    testWidgets('filtre par pile lu dans l\'adresse', (tester) async {
      await _monterPage(
        tester,
        _Faux(),
        depart: '${Routes.adminPersonnesTravailPraxis}?pile=incomplet',
      );
      expect(find.text('Bilal Fictif'), findsOneWidget);
      expect(find.text('Amina Fictive'), findsNothing);
      expect(find.text('Elias Fictif'), findsNothing);
      expect(find.text(tr.nombre(n: '1')), findsOneWidget);
    });

    testWidgets('filtre par etiquette lu dans l\'adresse', (tester) async {
      await _monterPage(
        tester,
        _Faux(),
        depart: '${Routes.adminPersonnesTravailPraxis}?etiquette=a_creuser',
      );
      expect(find.text('Elias Fictif'), findsOneWidget);
      expect(find.text('Amina Fictive'), findsNothing);
    });

    testWidgets('une valeur inconnue dans l\'adresse est ignoree', (
      tester,
    ) async {
      await _monterPage(
        tester,
        _Faux(),
        depart: '${Routes.adminPersonnesTravailPraxis}?pile=inconnue',
      );
      expect(find.text(tr.nombre(n: '5')), findsOneWidget);
    });

    testWidgets('choisir une pile l\'ecrit dans l\'adresse, '
        'avec le nombre par pile', (tester) async {
      await _monterPage(tester, _Faux());
      // Chaque pastille porte le nombre du serveur.
      final Finder pastille = find.byKey(
        TravailPraxisPage.clePile(PilePraxis.aRegarder),
      );
      expect(
        find.descendant(of: pastille, matching: find.text('1')),
        findsOneWidget,
      );
      await tester.ensureVisible(pastille);
      await _laisser(tester);
      await tester.tap(pastille);
      await _laisser(tester);
      expect(_adresse(tester).queryParameters['pile'], 'a_regarder');
      expect(find.text('Dawud Fictif'), findsOneWidget);
      expect(find.text('Amina Fictive'), findsNothing);
      // Un second toucher relache le filtre.
      await tester.tap(
        find.byKey(TravailPraxisPage.clePile(PilePraxis.aRegarder)),
      );
      await _laisser(tester);
      expect(_adresse(tester).queryParameters.containsKey('pile'), isFalse);
      expect(find.text('Amina Fictive'), findsOneWidget);
    });

    testWidgets('choisir une etiquette l\'ecrit dans l\'adresse', (
      tester,
    ) async {
      await _monterPage(tester, _Faux());
      await _choisir(
        tester,
        TravailPraxisPage.cleEtiquette,
        tr.etiquettes.solide,
      );
      expect(_adresse(tester).queryParameters['etiquette'], 'solide');
      expect(find.text('Bilal Fictif'), findsOneWidget);
      expect(find.text('Amina Fictive'), findsNothing);
    });

    testWidgets('aucun resultat : « Effacer les filtres » vide l\'adresse', (
      tester,
    ) async {
      await _monterPage(
        tester,
        _Faux(),
        depart:
            '${Routes.adminPersonnesTravailPraxis}?pile=sans_nouvelles&etiquette=pepite',
      );
      expect(find.byKey(TravailPraxisPage.cleAucunResultat), findsOneWidget);
      await tester.tap(find.text(tr.effacer));
      await _laisser(tester);
      expect(_adresse(tester).queryParameters, isEmpty);
      expect(find.text(tr.nombre(n: '5')), findsOneWidget);
    });

    testWidgets('toucher une ligne ouvre le dossier ; le retour ramene a la '
        'liste filtree', (tester) async {
      await _monterPage(
        tester,
        _Faux(),
        depart: '${Routes.adminPersonnesTravailPraxis}?etiquette=pepite',
      );
      await tester.tap(find.text('Amina Fictive'));
      await _laisser(tester);
      expect(find.text('dossier:CAND-00001'), findsOneWidget);
      _routeur(tester).pop();
      await _laisser(tester);
      expect(_adresse(tester).queryParameters['etiquette'], 'pepite');
      expect(find.text('Amina Fictive'), findsOneWidget);
      expect(find.text('Bilal Fictif'), findsNothing);
    });

    testWidgets('au-dela de 50 lignes, « Afficher les dossiers suivants »', (
      tester,
    ) async {
      await _monterPage(
        tester,
        _Faux(
          rangements: <RangementPraxis>[
            for (int k = 0; k < 60; k++)
              _rang(
                'CAND-${k.toString().padLeft(5, '0')}',
                PilePraxis.incomplet,
                nom: 'Fictif $k',
                minutes: -k,
              ),
          ],
          impressions: const <ImpressionPraxis>[],
        ),
        hauteur: 9000,
      );
      expect(find.text('Fictif 59'), findsNothing);
      await tester.tap(find.byKey(TravailPraxisPage.cleVoirPlus));
      await _laisser(tester);
      expect(find.text('Fictif 59'), findsOneWidget);
      expect(find.byKey(TravailPraxisPage.cleVoirPlus), findsNothing);
    });

    testWidgets('320 px, texte x2, arabe : rien ne deborde', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      await _monterPage(
        tester,
        _Faux(),
        largeur: 320,
        hauteur: 6000,
        echelle: 2,
        direction: TextDirection.rtl,
      );
      expect(find.text('Amina Fictive'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('objectifs de Praxis', () {
    testWidgets('ouverts du jour et de la semaine, cible, periode passee, '
        'clos recents avec la note', (tester) async {
      await _monterPage(tester, _Faux());
      expect(find.byKey(ClesObjectifsPraxis.bloc), findsOneWidget);
      expect(find.text(o.jour), findsOneWidget);
      expect(find.text(o.semaine), findsOneWidget);
      expect(find.text(o.clos), findsOneWidget);
      expect(
        find.text('Ranger trente dossiers reçus cette semaine'),
        findsOneWidget,
      );
      expect(find.textContaining(o.cible(n: '30')), findsOneWidget);
      expect(find.text(o.echu), findsOneWidget);
      expect(find.text(o.atteint), findsOneWidget);
      expect(find.text('Douze relances faites.'), findsOneWidget);
    });

    testWidgets('aucun objectif : une phrase', (tester) async {
      await _monterPage(tester, _Faux(objectifs: const <ObjectifPraxis>[]));
      expect(find.byKey(ClesObjectifsPraxis.vide), findsOneWidget);
    });

    testWidgets('erreur : « Reessayer », la liste des dossiers reste', (
      tester,
    ) async {
      await _monterPage(tester, _Faux()..erreurObjectifs = Exception('panne'));
      expect(find.byKey(ClesObjectifsPraxis.erreur), findsOneWidget);
      expect(find.text('Amina Fictive'), findsOneWidget);
    });
  });
}

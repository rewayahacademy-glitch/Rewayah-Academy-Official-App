// PX-2 (ecran) : les propositions de Praxis dans le dossier et dans la file.
//
//  - rien n'est rendu sans proposition, ni quand la lecture echoue ;
//  - le texte de Praxis et le motif dit au candidat sont montres MOT POUR MOT ;
//  - « Valider » envoie la version que Praxis a vue et une cle d'idempotence,
//    puis dit le geste fait ; « Ecarter » ne touche pas au dossier ;
//  - planifier un entretien : pas de « Valider » tant qu'aucun participant n'est
//    choisi, puis les participants choisis partent avec la validation ;
//  - un dossier qui a change : pas de « Valider », une phrase, « Ecarter » reste ;
//  - un refus du moteur se dit en mots (jamais par son code), la proposition reste
//    ouverte ; un refus faute de double verification aussi ;
//  - la pastille « Praxis propose » de la file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/agent/propositions_praxis.dart';
import 'package:rewayah_academy/core/candidature/modeles_entretien_direction.dart';
import 'package:rewayah_academy/core/candidature/port_entretiens_direction.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/propositions_praxis_dossier.dart';
import 'package:rewayah_academy/features/admin_candidatures/marque_propositions_praxis.dart';

import '../../support/harnais.dart';

PropositionPraxis _prop(
  String id,
  GestePrepare geste, {
  String reference = 'CAND-00042',
  int proposee = 3,
  int actuelle = 3,
  Map<String, dynamic> parametres = const <String, dynamic>{},
  String texte = 'Il manque les langues.',
}) => PropositionPraxis(
  id: id,
  geste: geste,
  reference: reference,
  nom: 'Candidat Fictif',
  versionProposee: proposee,
  versionActuelle: actuelle,
  parametres: parametres,
  texte: texte,
  expireLe: DateTime.utc(2026, 11, 20, 10),
);

class _Faux implements ServicePropositionsPraxis {
  _Faux(this.liste);

  List<PropositionPraxis> liste;
  final List<String> appels = <String>[];
  ResultatProposition Function()? reponse;
  bool refusDroit = false;
  Exception? erreurLecture;

  @override
  Future<List<PropositionPraxis>> ouvertes() async {
    if (erreurLecture != null) throw erreurLecture!;
    return liste;
  }

  @override
  Future<ResultatProposition> valider({
    required String id,
    required int version,
    required String cle,
    List<String>? participants,
  }) async {
    appels.add('valider:$id:$version:${participants?.join(',') ?? '-'}');
    if (refusDroit) throw const PermissionInsuffisante('valider');
    final ResultatProposition r =
        reponse?.call() ?? const ResultatProposition(fait: true);
    if (r.fait) {
      liste = <PropositionPraxis>[
        for (final PropositionPraxis p in liste)
          if (p.id != id) p,
      ];
    }
    return r;
  }

  @override
  Future<ResultatProposition> ecarter({
    required String id,
    required String cle,
    String? motif,
  }) async {
    appels.add('ecarter:$id');
    liste = <PropositionPraxis>[
      for (final PropositionPraxis p in liste)
        if (p.id != id) p,
    ];
    return const ResultatProposition(fait: true);
  }
}

Future<void> _monter(
  WidgetTester tester,
  _Faux faux, {
  List<PersonnelEntretien>? personnel,
  Widget? enfant,
  Size taille = const Size(1440, 2400),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: SingleChildScrollView(
          child:
              enfant ??
              const PropositionsPraxisDossier(
                reference: 'CAND-00042',
                candidatureId: 'cand-42',
              ),
        ),
      ),
      surcharges: <Override>[
        servicePropositionsPraxisProvider.overrideWithValue(faux),
        personnelEntretienProvider.overrideWith(
          (ref, String candidature) async =>
              personnel ??
              const <PersonnelEntretien>[
                PersonnelEntretien(
                  profilId: 'p1',
                  prenom: 'Amina',
                  nom: 'Fictive',
                  fondateur: true,
                ),
                PersonnelEntretien(
                  profilId: 'p2',
                  prenom: 'Bilal',
                  nom: 'Fictif',
                  fondateur: true,
                ),
              ],
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final p = t.admin.praxis.propositions;

  group('rendu', () {
    testWidgets('aucune proposition : rien n\'est rendu', (tester) async {
      await _monter(tester, _Faux(<PropositionPraxis>[]));
      expect(find.byKey(ClesPropositionsPraxis.bloc), findsNothing);
    });

    testWidgets('une proposition d\'un autre dossier : rien', (tester) async {
      await _monter(
        tester,
        _Faux(<PropositionPraxis>[
          _prop(
            'a',
            GestePrepare.admettreVerifications,
            reference: 'CAND-99999',
          ),
        ]),
      );
      expect(find.byKey(ClesPropositionsPraxis.bloc), findsNothing);
    });

    testWidgets('lecture en echec : rien (la file ne ment pas)', (
      tester,
    ) async {
      final _Faux faux = _Faux(<PropositionPraxis>[])
        ..erreurLecture = Exception('panne');
      await _monter(tester, faux);
      expect(find.byKey(ClesPropositionsPraxis.bloc), findsNothing);
    });

    testWidgets(
      'un complement : le texte et le motif de Praxis, mot pour mot',
      (tester) async {
        const String texte =
            'Le dossier est a completer : langues <b>manquantes</b>.';
        const String motif = 'Il manque les langues que vous enseignez.';
        await _monter(
          tester,
          _Faux(<PropositionPraxis>[
            _prop(
              'a',
              GestePrepare.demanderComplement,
              texte: texte,
              parametres: const <String, dynamic>{
                'elements': <String>['langues'],
                'motif': motif,
              },
            ),
          ]),
        );
        expect(find.text(p.titre), findsOneWidget);
        expect(find.text(p.geste.demanderComplement), findsOneWidget);
        expect(find.text(texte), findsOneWidget);
        expect(find.text(motif), findsOneWidget);
        expect(find.text(p.motif), findsOneWidget);
        expect(find.byKey(ClesPropositionsPraxis.valider('a')), findsOneWidget);
        expect(find.byKey(ClesPropositionsPraxis.ecarter('a')), findsOneWidget);
      },
    );
  });

  group('gestes', () {
    testWidgets(
      'valider : la version vue par Praxis part, le geste est dit fait',
      (tester) async {
        final _Faux faux = _Faux(<PropositionPraxis>[
          _prop(
            'a',
            GestePrepare.demanderComplement,
            proposee: 7,
            actuelle: 7,
            parametres: const <String, dynamic>{
              'elements': <String>['langues'],
              'motif': 'Il manque les langues.',
            },
          ),
        ]);
        int relu = 0;
        await _monter(
          tester,
          faux,
          enfant: PropositionsPraxisDossier(
            reference: 'CAND-00042',
            candidatureId: 'cand-42',
            onTraitee: () => relu++,
          ),
        );
        await _presser(tester, find.byKey(ClesPropositionsPraxis.valider('a')));
        expect(faux.appels, <String>['valider:a:7:-']);
        expect(relu, 1);
        // Le serveur a rendu la liste sans la proposition : le bloc disparait.
        expect(find.byKey(ClesPropositionsPraxis.bloc), findsNothing);
      },
    );

    testWidgets(
      'ecarter : rien n\'est fait sur le dossier, la proposition part',
      (tester) async {
        final _Faux faux = _Faux(<PropositionPraxis>[
          _prop('a', GestePrepare.admettreVerifications),
        ]);
        await _monter(tester, faux);
        await _presser(tester, find.byKey(ClesPropositionsPraxis.ecarter('a')));
        expect(faux.appels, <String>['ecarter:a']);
        expect(find.byKey(ClesPropositionsPraxis.bloc), findsNothing);
      },
    );

    testWidgets(
      'planifier : pas de Valider sans participant, puis ils partent',
      (tester) async {
        final _Faux faux = _Faux(<PropositionPraxis>[
          _prop(
            'e',
            GestePrepare.planifierEntretien,
            parametres: <String, dynamic>{
              'debut': '2026-11-19T09:00:00Z',
              'duree_minutes': 45,
            },
          ),
        ]);
        await _monter(tester, faux);
        expect(find.text(p.participantsAide), findsOneWidget);
        expect(find.byKey(ClesPropositionsPraxis.valider('e')), findsNothing);
        await _presser(
          tester,
          find.byKey(ClesPropositionsPraxis.participant('e', 'p2')),
        );
        await _presser(
          tester,
          find.byKey(ClesPropositionsPraxis.participant('e', 'p1')),
        );
        expect(find.byKey(ClesPropositionsPraxis.valider('e')), findsOneWidget);
        await _presser(tester, find.byKey(ClesPropositionsPraxis.valider('e')));
        expect(faux.appels, <String>['valider:e:3:p1,p2']);
      },
    );

    testWidgets(
      'aucun personnel a choisir : une phrase, jamais une liste vide muette',
      (tester) async {
        final _Faux faux = _Faux(<PropositionPraxis>[
          _prop(
            'e',
            GestePrepare.planifierEntretien,
            parametres: <String, dynamic>{
              'debut': '2026-11-19T09:00:00Z',
              'duree_minutes': 45,
            },
          ),
        ]);
        await _monter(tester, faux, personnel: const <PersonnelEntretien>[]);
        expect(find.text(p.participantsAucun), findsOneWidget);
      },
    );

    testWidgets('dossier change : pas de Valider, une phrase, Ecarter reste', (
      tester,
    ) async {
      await _monter(
        tester,
        _Faux(<PropositionPraxis>[
          _prop(
            'a',
            GestePrepare.admettreVerifications,
            proposee: 3,
            actuelle: 5,
          ),
        ]),
      );
      expect(find.text(p.perimee), findsOneWidget);
      expect(find.byKey(ClesPropositionsPraxis.valider('a')), findsNothing);
      expect(find.byKey(ClesPropositionsPraxis.ecarter('a')), findsOneWidget);
    });
  });

  group('refus', () {
    testWidgets('le moteur refuse : sa phrase, en mots, la proposition reste', (
      tester,
    ) async {
      final _Faux faux =
          _Faux(<PropositionPraxis>[
              _prop('a', GestePrepare.admettreVerifications),
            ])
            ..reponse = () => const ResultatProposition(
              fait: false,
              erreur: 'conflit_candidature',
              brut: <String, dynamic>{'erreur': 'conflit_candidature'},
            );
      await _monter(tester, faux);
      await _presser(tester, find.byKey(ClesPropositionsPraxis.valider('a')));
      expect(find.byKey(ClesPropositionsPraxis.carte('a')), findsOneWidget);
      expect(find.textContaining('conflit_candidature'), findsNothing);
      expect(find.text(p.generique), findsNothing);
    });

    testWidgets(
      'proposition deja traitee : la phrase « n\'est plus ouverte »',
      (tester) async {
        final _Faux faux =
            _Faux(<PropositionPraxis>[
                _prop('a', GestePrepare.admettreVerifications),
              ])
              ..reponse = () => const ResultatProposition(
                fait: false,
                erreur: 'proposition_expiree',
                brut: <String, dynamic>{'erreur': 'proposition_expiree'},
              );
        await _monter(tester, faux);
        await _presser(tester, find.byKey(ClesPropositionsPraxis.valider('a')));
        expect(find.text(p.close), findsOneWidget);
      },
    );

    testWidgets('sans double verification : la phrase vraie, rien n\'a bouge', (
      tester,
    ) async {
      final _Faux faux = _Faux(<PropositionPraxis>[
        _prop('a', GestePrepare.admettreVerifications),
      ])..refusDroit = true;
      await _monter(tester, faux);
      await _presser(tester, find.byKey(ClesPropositionsPraxis.valider('a')));
      expect(find.text(t.admin.praxis.doubleVerification), findsOneWidget);
      expect(find.byKey(ClesPropositionsPraxis.carte('a')), findsOneWidget);
    });
  });

  group('pastille de la file', () {
    testWidgets('« Praxis propose » seulement pour le dossier concerne', (
      tester,
    ) async {
      final _Faux faux = _Faux(<PropositionPraxis>[
        _prop('a', GestePrepare.admettreVerifications),
      ]);
      await _monter(
        tester,
        faux,
        enfant: const Column(
          children: <Widget>[
            MarquePropositionsPraxis(reference: 'CAND-00042'),
            MarquePropositionsPraxis(reference: 'CAND-00043'),
          ],
        ),
      );
      expect(
        find.byKey(MarquePropositionsPraxis.cle('CAND-00042')),
        findsOneWidget,
      );
      expect(
        find.byKey(MarquePropositionsPraxis.cle('CAND-00043')),
        findsNothing,
      );
      expect(find.text(p.pastille), findsOneWidget);
    });

    testWidgets('lecture en echec : pas de pastille', (tester) async {
      final _Faux faux = _Faux(<PropositionPraxis>[])
        ..erreurLecture = Exception('panne');
      await _monter(
        tester,
        faux,
        enfant: const MarquePropositionsPraxis(reference: 'CAND-00042'),
      );
      expect(find.text(p.pastille), findsNothing);
    });
  });
}

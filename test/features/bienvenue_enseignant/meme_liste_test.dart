// SALLE-3-ACCUEIL (garde-cap, 07/11/2026) : « Premiers pas » et la carte de la
// Journee lisent UNE seule liste. Pour chaque etat des lectures, les deux ecrans
// montrent exactement les memes lignes, dans le meme ordre.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_coordonnees_versement.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/bienvenue_enseignant/bienvenue_page.dart';
import 'package:rewayah_academy/features/bienvenue_enseignant/carte_bienvenue_equipe.dart';
import 'package:rewayah_academy/features/bienvenue_enseignant/reste_a_configurer.dart';
import 'package:rewayah_academy/features/paiements_recus/etat_coordonnees.dart';

import '../../support/harnais.dart';

const SessionState _session = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: 'prof-1',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

MesCoordonneesVersement _versement(bool complet) => MesCoordonneesVersement(
  deviseCible: 'USD',
  champs: const <ChampDemande>[],
  enregistre: complet,
  complet: complet,
);

/// Monte [ecran] avec les memes lectures, rend les lignes dans l'ordre affiche.
Future<List<ResteAConfigurer>> _lignes(
  WidgetTester tester,
  Widget ecran, {
  required bool? versementComplet,
  required PrerequisEnseignant? prerequis,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext _, GoRouterState _) =>
              ecran is BienvenueEnseignantPage
              ? ecran
              : Scaffold(body: SingleChildScrollView(child: ecran)),
        ),
      ],
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(FausseSourceSession(_session)),
        mesCoordonneesVersementProvider.overrideWith(
          (Ref _) async => versementComplet == null
              ? throw StateError('capacite indisponible')
              : _versement(versementComplet),
        ),
        prerequisEnseignantProvider.overrideWithValue(prerequis),
        profilEnseignantProvider.overrideWith(
          (Ref _) async =>
              const ProfilEnseignant(prenom: 'Salma', identifiant: 'RA-1'),
        ),
        baseLocaleEnMemoire(),
      ],
    ),
  );
  await tester.pumpAndSettle();
  final List<ResteAConfigurer> vues =
      <ResteAConfigurer>[
        for (final ResteAConfigurer r in ResteAConfigurer.values)
          if (find.text(libelleReste(r)).evaluate().isNotEmpty) r,
      ]..sort(
        (ResteAConfigurer a, ResteAConfigurer b) => tester
            .getTopLeft(find.text(libelleReste(a)).first)
            .dy
            .compareTo(tester.getTopLeft(find.text(libelleReste(b)).first).dy),
      );
  return vues;
}

void main() {
  const PrerequisEnseignant partiel = PrerequisEnseignant(
    photo: false,
    langues: true,
    fuseau: false,
    disponibilites: false,
  );
  final List<(String, bool?, PrerequisEnseignant?)> cas =
      <(String, bool?, PrerequisEnseignant?)>[
        ('tout a faire', false, partiel),
        ('versement fait', true, partiel),
        ('versement illisible', null, partiel),
        ('prerequis illisibles', false, null),
        (
          'tout fait',
          true,
          const PrerequisEnseignant(
            photo: true,
            langues: true,
            fuseau: true,
            disponibilites: true,
          ),
        ),
      ];
  for (final (String nom, bool? versement, PrerequisEnseignant? p) in cas) {
    testWidgets('meme liste sur les deux ecrans : $nom', (
      WidgetTester tester,
    ) async {
      final List<ResteAConfigurer> page = await _lignes(
        tester,
        const BienvenueEnseignantPage(),
        versementComplet: versement,
        prerequis: p,
      );
      final List<ResteAConfigurer> carte = await _lignes(
        tester,
        const CarteBienvenueEquipe(),
        versementComplet: versement,
        prerequis: p,
      );
      expect(page, carte);
      // Le versement, quand il est a faire, est toujours le premier.
      if (versement == false) {
        expect(carte.first, ResteAConfigurer.versement);
      }
      // L'attendu vient de la regle, pas des ecrans : une ligne par reste lu.
      expect(carte, <ResteAConfigurer>[
        if (versement == false) ResteAConfigurer.versement,
        if (p != null && !p.photo) ResteAConfigurer.photo,
        if (p != null && !p.langues) ResteAConfigurer.langues,
        if (p != null && !p.fuseau) ResteAConfigurer.fuseau,
        if (p != null && !p.disponibilites) ResteAConfigurer.disponibilites,
      ]);
    });
  }
}

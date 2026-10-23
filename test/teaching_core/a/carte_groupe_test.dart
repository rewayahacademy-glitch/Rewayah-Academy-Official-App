import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/carte_groupe.dart';

import '../../support/annonces.dart';
import 'support/hote_tc_a.dart';

const HorlogeAffichee _riyad = HorlogeAffichee(
  fuseauIana: 'Asia/Riyadh',
  libelleVille: 'Riyad',
  heureLocaleRendue: '18:00',
  dateLocaleRendue: 'Lundi 21 septembre',
);

const HorlogeAffichee _conakry = HorlogeAffichee(
  fuseauIana: 'Africa/Conakry',
  libelleVille: 'Conakry',
  heureLocaleRendue: '15:00',
  dateLocaleRendue: 'Lundi 21 septembre',
);

FenetreSeance _fenetre() => FenetreSeance(
  debutUtc: DateTime.utc(2026, 9, 21, 15),
  finPrevueUtc: DateTime.utc(2026, 9, 21, 16, 30),
  fenetreAcces: const Duration(minutes: 20),
  graceApresFin: const Duration(minutes: 15),
);

GroupSummaryVM _groupe({
  DateTime? maintenant,
  int membres = 4,
  int seuil = 5,
  String? photo = 'demo/photos/youssouf.jpg',
  bool? seanceOuverte,
}) {
  final GroupSummaryVM base = GroupSummaryVM(
    groupeId: 'g-1',
    libelle: 'Classe Al-Fatiha',
    couleurJeton: const JetonCouleurGroupe(index: 0, codeStable: 'g04'),
    enseignant: EnseignantVM(
      enseignantId: 'e-1',
      titre: TitreEnseignant.sayyid,
      nomAffichage: 'Youssouf',
      photoUrlOuCle: photo,
    ),
    nomCours: 'Lecture du Coran',
    niveauHumain: 'Niveau 2',
    nombreMembres: membres,
    seuilMax: seuil,
    typePublic: TypePublicGroupeVM.enfant,
    actif: true,
  );
  if (maintenant == null) {
    return base;
  }
  return base.avecHorloge(
    SessionClockVM.depuisFenetre(
      fenetre: _fenetre(),
      maintenantServeurUtc: maintenant,
      horlogeUtilisateur: _riyad,
      horlogeContrepartie: _conakry,
      seanceOuverte: seanceOuverte,
    ),
  );
}

Future<void> _poser(WidgetTester tester, Widget carte) async {
  await tester.pumpWidget(
    hoteTcA(Scaffold(body: SingleChildScrollView(child: carte))),
  );
  await tester.pump();
}

void main() {
  testWidgets('la carte nomme le groupe et donne sa capacite reelle', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      CarteGroupe(
        groupe: _groupe(maintenant: DateTime.utc(2026, 9, 21, 11, 32)),
      ),
    );

    expect(find.text('Classe Al-Fatiha'), findsOneWidget);
    expect(find.text('4 / 5'), findsOneWidget);
    expect(find.text('Sayyid Youssouf'), findsOneWidget);
    expect(find.text('Lecture du Coran · Niveau 2'), findsOneWidget);
    // Le repere de couleur existe, mais il n'est jamais seul : le nom est la.
    expect(find.byType(LisereGroupe), findsOneWidget);
  });

  testWidgets('une capacite de 3 sur 4 s affiche telle quelle', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      CarteGroupe(
        groupe: _groupe(
          maintenant: DateTime.utc(2026, 9, 21, 11, 32),
          membres: 3,
          seuil: 4,
        ),
      ),
    );
    expect(find.text('3 / 4'), findsOneWidget);
    // Aucun plafond ecrit dans l'ecran : cinq n'apparait nulle part.
    expect(find.text('3 / 5'), findsNothing);
  });

  testWidgets('avant la fenetre, aucun bouton Rejoindre', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      CarteGroupe(
        groupe: _groupe(maintenant: DateTime.utc(2026, 9, 21, 11, 32)),
      ),
    );
    expect(find.text(LibellesGroupe.rejoindre), findsNothing);
    expect(find.textContaining('Cours dans 3\u00A0h\u00A028'), findsOneWidget);
  });

  testWidgets('a T-20, le bouton Rejoindre apparait', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      CarteGroupe(
        groupe: _groupe(maintenant: DateTime.utc(2026, 9, 21, 14, 40)),
        onRejoindre: () {},
      ),
    );
    expect(find.text(LibellesGroupe.rejoindre), findsOneWidget);
  });

  testWidgets('en depassement, aucun compte a rebours negatif', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      CarteGroupe(
        groupe: _groupe(
          maintenant: DateTime.utc(2026, 9, 21, 16, 45),
          seanceOuverte: true,
        ),
      ),
    );
    expect(find.textContaining(LibellesGroupe.prolongee), findsOneWidget);
    expect(find.textContaining('-1'), findsNothing);
  });

  testWidgets('une seance terminee ferme la porte', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      CarteGroupe(
        groupe: _groupe(
          maintenant: DateTime.utc(2026, 9, 21, 17, 30),
          seanceOuverte: false,
        ),
      ),
    );
    expect(find.text(LibellesGroupe.rejoindre), findsNothing);
    expect(find.textContaining(LibellesGroupe.terminee), findsOneWidget);
  });

  testWidgets('sans occurrence, la carte le dit au lieu de mentir', (
    WidgetTester tester,
  ) async {
    await _poser(tester, CarteGroupe(groupe: _groupe()));
    expect(find.text(LibellesGroupe.aucuneSeance), findsOneWidget);
    expect(find.text(LibellesGroupe.rejoindre), findsNothing);
  });

  testWidgets('une photo manquante est dite, jamais remplacee en silence', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      CarteGroupe(
        groupe: _groupe(
          maintenant: DateTime.utc(2026, 9, 21, 11, 32),
          photo: null,
        ),
      ),
    );
    expect(find.text(LibellesGroupe.photoManquante), findsOneWidget);
    // Aucun avatar generique ne vient combler le trou.
    expect(find.byType(AvatarTile), findsNothing);
  });

  testWidgets('une photo presente reutilise AvatarTile', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      CarteGroupe(
        groupe: _groupe(maintenant: DateTime.utc(2026, 9, 21, 11, 32)),
      ),
    );
    expect(find.byType(AvatarTile), findsOneWidget);
    expect(find.text(LibellesGroupe.photoManquante), findsNothing);
  });

  testWidgets('toute la carte ouvre l Espace Groupe', (
    WidgetTester tester,
  ) async {
    int ouvertures = 0;
    await _poser(
      tester,
      CarteGroupe(
        groupe: _groupe(maintenant: DateTime.utc(2026, 9, 21, 11, 32)),
        onOuvrir: () => ouvertures++,
      ),
    );
    await tester.tap(find.text('Classe Al-Fatiha'));
    await tester.pump();
    expect(ouvertures, 1);
  });

  testWidgets('sans rappel branche, aucun Rejoindre : jamais grise '
      '(BOUTONS-GRISES-1)', (WidgetTester tester) async {
    await _poser(
      tester,
      CarteGroupe(
        groupe: _groupe(maintenant: DateTime.utc(2026, 9, 21, 14, 40)),
      ),
    );
    expect(
      find.widgetWithText(ActionPrincipale, LibellesGroupe.rejoindre),
      findsNothing,
    );
  });

  testWidgets('en attente : Rejoindre actif, l appui dit la phrase, '
      'l annonce et n entre pas (BOUTONS-GRISES-1)', (
    WidgetTester tester,
  ) async {
    final List<String> annonces = ecouterAnnonces(tester);
    int appels = 0;
    await _poser(
      tester,
      CarteGroupe(
        groupe: _groupe(maintenant: DateTime.utc(2026, 9, 21, 14, 40)),
        onRejoindre: () => appels++,
        attenteEntree: 'Attendez un instant.',
      ),
    );
    final Finder rejoindre = find.widgetWithText(
      ActionPrincipale,
      LibellesGroupe.rejoindre,
    );
    expect(tester.widget<ActionPrincipale>(rejoindre).onPress, isNotNull);
    await tester.tap(rejoindre);
    await tester.pump();
    expect(appels, 0);
    expect(find.text('Attendez un instant.'), findsOneWidget);
    expect(annonces, <String>['Attendez un instant.']);
    expect(
      tester.getSemantics(find.text('Attendez un instant.')),
      matchesSemantics(isLiveRegion: true, label: 'Attendez un instant.'),
    );
  });

  testWidgets('le groupe complet porte un libelle, pas seulement une couleur', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      CarteGroupe(
        groupe: _groupe(
          maintenant: DateTime.utc(2026, 9, 21, 11, 32),
          membres: 5,
          seuil: 5,
        ),
      ),
    );
    expect(find.text(LibellesGroupe.complet), findsOneWidget);
  });
}

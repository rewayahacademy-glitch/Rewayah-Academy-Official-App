import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/admin_groupes/creation_classe_page.dart';
import 'package:rewayah_academy/features/classes/carte_classe.dart';
import 'package:rewayah_academy/features/classes/domaine/classe_vm.dart';
import 'package:rewayah_academy/features/classes/domaine/providers.dart';
import 'package:rewayah_academy/features/disponibilites/grille_semaine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/harnais.dart';
import 'faux/faux_ports_classes.dart';
import 'support/largeurs.dart';

/// L'hote qui pousse la page et recueille ce qu'elle rend en se fermant.
///
/// La page se ferme par `Navigator.pop(nombre)` : montee comme `home`, elle
/// n'aurait rien sous elle. Ici elle vit **au-dessus** d'une liste temoin,
/// exactement comme Operations > Classes la pousse.
class _Lanceur extends StatefulWidget {
  const _Lanceur({required this.lot, required this.onResultat});

  final bool lot;
  final void Function(int? resultat) onResultat;

  @override
  State<_Lanceur> createState() => _LanceurEtat();
}

class _LanceurEtat extends State<_Lanceur> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context)
          .push<int>(
            MaterialPageRoute<int>(
              builder: (BuildContext _) => CreationClassePage(lot: widget.lot),
            ),
          )
          .then(widget.onResultat);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('liste')));
}

FauxPortClassesAdmin _port() => FauxPortClassesAdmin(
  programmesRendus: const <ProgrammeChoix>[
    ProgrammeChoix(
      niveauId: 'n1',
      nomHumain: 'Fondations de lecture',
      cycle: 'Cycle 1',
    ),
    ProgrammeChoix(niveauId: 'n2', nomHumain: 'Lecture fluide', cycle: 'Cycle 1'),
  ],
  eligiblesRendus: const <EnseignantEligible>[
    EnseignantEligible(id: 'ens-uuid-77', nomAffichage: 'Amina Diallo'),
  ],
);

Future<void> _monter(
  WidgetTester tester, {
  required FauxPortClassesAdmin port,
  bool lot = false,
  void Function(int? resultat)? onResultat,
}) async {
  await tester.pumpWidget(
    hote(
      _Lanceur(lot: lot, onResultat: onResultat ?? (int? _) {}),
      surcharges: <Override>[
        portClassesAdminProvider.overrideWithValue(port),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

/// La case libre d'un jour et d'une heure, par son libelle parle.
Finder _caseLibre(int jour, int heure) => find.byWidgetPredicate(
  (Widget w) =>
      w is Pressable &&
      w.libelleSemantique ==
          t.disponibilites.celluleLibre(
            jour: t.disponibilites.joursLongs[jour - 1],
            heure: '$heure',
          ),
);

Future<void> _choisirCase(WidgetTester tester, int jour, int heure) async {
  final Finder cible = _caseLibre(jour, heure);
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Future<void> _presser(WidgetTester tester, String libelle) async {
  final Finder cible = find.widgetWithText(ActionPrincipale, libelle);
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'mobile : trois pas, aucun identifiant, une grille au lieu des chiffres',
    (WidgetTester tester) async {
      await avecLargeur(tester, largeurMobile, () async {
        final FauxPortClassesAdmin port = _port();
        int? resultat;
        await _monter(tester, port: port, onResultat: (int? r) => resultat = r);

        // Pas 1 : le public et le programme, le nom prerempli.
        expect(find.text(t.classes.admin.creation.publicQuestion), findsOneWidget);
        expect(find.text('Fondations de lecture'), findsOneWidget);
        TextField nom = tester.widget<TextField>(
          find.byKey(CreationClassePage.cleNom),
        );
        expect(nom.controller!.text, t.classes.commun.publicEnfants);
        // Ce qui n'existe plus : un identifiant, un jour, une heure a taper.
        expect(find.text(t.admin.groupes.champEnseignantId), findsNothing);
        expect(find.text(t.admin.groupes.champJour), findsNothing);
        expect(find.text(t.admin.groupes.champHeure), findsNothing);

        await tester.tap(find.text('Fondations de lecture'));
        await tester.pumpAndSettle();
        nom = tester.widget<TextField>(find.byKey(CreationClassePage.cleNom));
        expect(nom.controller!.text, contains('Fondations de lecture'));

        await _presser(tester, t.classes.admin.creation.suivant);

        // Pas 2 : la grille de semaine, la meme que TUT-04 et ENS-06.
        expect(find.byType(GrilleSemaine), findsOneWidget);
        expect(find.text(t.classes.admin.creation.aucunCreneau), findsOneWidget);
        await _choisirCase(tester, 1, 17);
        expect(find.text(t.classes.admin.creation.creneauChoisi), findsOneWidget);
        // L'enseignant vient d'une liste filtree, et « a affecter » est le
        // choix par defaut.
        expect(find.text('Amina Diallo'), findsOneWidget);
        expect(
          find.text(t.classes.admin.creation.enseignantAucun),
          findsOneWidget,
        );
        // Les regles de l'academie sont preremplies, pas ressaisies.
        expect(find.text(t.classes.admin.creation.reglesTitre), findsOneWidget);
        expect(find.text('1 h'), findsOneWidget);

        await _presser(tester, t.classes.admin.creation.suivant);

        // Pas 3 : l'aperçu, carte par carte, puis la publication.
        expect(find.byType(CarteClasse), findsOneWidget);
        expect(
          find.text(t.classes.carte.creneau(jour: 'lundi', heure: '17:00')),
          findsOneWidget,
        );
        expect(find.text(t.classes.carte.enseignantAAffecter), findsOneWidget);
        await _presser(tester, t.classes.admin.creation.publier);

        expect(port.publications, hasLength(1));
        final BrouillonClasse publie = port.publications.single.single;
        expect(publie.creneau.jourIso, 1);
        expect(publie.creneau.heure, 17);
        expect(publie.enseignantId, isNull);
        expect(publie.niveauId, 'n1');
        expect(publie.libelle, contains('Fondations de lecture'));
        // La page s'est fermee en rendant ce qu'elle a publie.
        expect(resultat, 1);
        expect(find.text('liste'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    },
  );

  testWidgets('lot : une case, une classe, publiees ensemble', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurDesktop, () async {
      final FauxPortClassesAdmin port = _port();
      await _monter(tester, port: port, lot: true);

      expect(find.text(t.classes.admin.creation.titreLot), findsOneWidget);
      await _presser(tester, t.classes.admin.creation.suivant);
      await _choisirCase(tester, 1, 17);
      await _choisirCase(tester, 2, 17);
      await _choisirCase(tester, 3, 18);
      expect(
        find.text(t.classes.admin.creation.creneauxChoisis(nombre: 3)),
        findsOneWidget,
      );

      await _presser(tester, t.classes.admin.creation.suivant);
      expect(
        find.text(t.classes.admin.creation.apercuNombre(nombre: 3)),
        findsOneWidget,
      );
      expect(find.byType(CarteClasse), findsNWidgets(3));

      await _presser(tester, t.classes.admin.creation.publierLot(nombre: 3));
      expect(port.publications.single, hasLength(3));
      expect(
        port.publications.single.map((BrouillonClasse b) => b.creneau.cle),
        <String>['1-17-0', '2-17-0', '3-18-0'],
      );
    });
  });

  testWidgets('bureau : le pas courant et l aperçu cote a cote, boutons bornes', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurDesktop, () async {
      await _monter(tester, port: _port());
      await _presser(tester, t.classes.admin.creation.suivant);
      await _choisirCase(tester, 5, 16);

      // L'aperçu vivant se pose a droite de la grille : meme etat, deux
      // compositions, jamais deux ecrans.
      final Offset grille = tester.getTopLeft(find.byType(GrilleSemaine));
      final Offset apercu = tester.getTopLeft(find.byType(CarteClasse));
      expect(apercu.dx, greaterThan(grille.dx));
      expect(
        find.text(t.classes.carte.creneau(jour: 'vendredi', heure: '16:00')),
        findsOneWidget,
      );
      // Jamais un bouton primaire etire sur 1440 points.
      final Rect suivant = tester.getRect(
        find.widgetWithText(ActionPrincipale, t.classes.admin.creation.suivant),
      );
      expect(suivant.width, lessThan(700));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('l enseignant se choisit dans la liste, jamais par un champ', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      final FauxPortClassesAdmin port = _port();
      await _monter(tester, port: port);
      await _presser(tester, t.classes.admin.creation.suivant);
      await _choisirCase(tester, 2, 18);

      final Finder amina = find.text('Amina Diallo');
      await tester.ensureVisible(amina);
      await tester.pumpAndSettle();
      await tester.tap(amina);
      await tester.pumpAndSettle();

      await _presser(tester, t.classes.admin.creation.suivant);
      expect(find.text('Amina Diallo'), findsOneWidget);
      await _presser(tester, t.classes.admin.creation.publier);

      expect(port.publications.single.single.enseignantId, 'ens-uuid-77');
      // L'identifiant a transite par le port, jamais par l'ecran.
      expect(find.textContaining('ens-uuid-77'), findsNothing);
    });
  });

  testWidgets('un echec de publication se dit en langage humain', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      final FauxPortClassesAdmin port = _port()
        ..erreurPublication = const PostgrestException(
          message: 'ERROR: function public.creer_groupe(...) is not unique',
          code: 'PGRST203',
        );
      await _monter(tester, port: port);
      await _presser(tester, t.classes.admin.creation.suivant);
      await _choisirCase(tester, 1, 17);
      await _presser(tester, t.classes.admin.creation.suivant);
      await _presser(tester, t.classes.admin.creation.publier);

      expect(
        find.text(
          t.classes.admin.creation.echec(message: t.classes.erreur.inconnu),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('is not unique'), findsNothing);
      expect(find.textContaining('PGRST'), findsNothing);
      // La page reste ouverte : on corrige, on ne recommence pas tout.
      expect(find.text('liste'), findsNothing);
    });
  });

  testWidgets('annuler au premier pas ferme la page sans rien publier', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      final FauxPortClassesAdmin port = _port();
      int? resultat = -1;
      await _monter(tester, port: port, onResultat: (int? r) => resultat = r);
      await _presser(tester, t.classes.admin.creation.annuler);

      expect(find.text('liste'), findsOneWidget);
      expect(resultat, isNull);
      expect(port.publications, isEmpty);
    });
  });
}

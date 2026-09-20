// Q-07 : ouvrir la Bibliotheque en classe ne deconnecte pas la session.
//
// Spec section 15 : « la Bibliotheque peut s ouvrir en classe sans couper la
// room ». Decisions D-20 (une seule Bibliotheque) et D-24 (le shell ne possede
// pas la room).
//
// LE MONTAGE. Le moteur est tenu par un porteur applicatif, au-dessus du
// routeur. La Bibliotheque s ouvre comme un PANNEAU -- un `showModalBottomSheet`
// ici, ce que la spec appelle « panneau lateral ou sheet selon la largeur ».
// Ouvrir, choisir une ressource, fermer : le compteur de deconnexions doit
// rester a zero.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

import '../fixtures/contrats/contrats_b_ressources.dart';
import '../fixtures/fixtures_ressources.dart';
import 'faux/faux_moteur_salle.dart';
import 'support/hote_navigation.dart';

/// La cle de la surface Bibliotheque ouverte en classe.
const Key _cleePanneau = Key('panneau-bibliotheque');

/// Un ecran de Classe qui accueille le panneau Bibliotheque.
class _ClasseAvecPanneau extends StatefulWidget {
  const _ClasseAvecPanneau({required this.choisies});

  final List<LibraryResource> choisies;

  @override
  State<_ClasseAvecPanneau> createState() => _ClasseAvecPanneauEtat();
}

class _ClasseAvecPanneauEtat extends State<_ClasseAvecPanneau> {
  Future<void> _ouvrirBibliotheque() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext c) => ListView(
        key: _cleePanneau,
        children: <Widget>[
          for (final LibraryResource r in toutesLesRessources())
            ListTile(
              title: Text(r.shortTitle),
              onTap: () {
                widget.choisies.add(r);
                Navigator.of(c).pop();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        const Text('Classe Live'),
        const BarreCoursEnCours(),
        TextButton(
          onPressed: _ouvrirBibliotheque,
          child: const Text('Bibliotheque'),
        ),
      ],
    ),
  );
}

void main() {
  late FauxMoteurSalle moteur;
  late FauxAnnonceSortie annonce;
  late FauxSessionPersistante session;

  setUp(() {
    moteur = FauxMoteurSalle();
    annonce = FauxAnnonceSortie();
    session = FauxSessionPersistante(
      moteur: moteur,
      annonce: annonce,
      courante: const SessionEnCoursDouble(
        sessionId: 'seance-1',
        groupeId: 'grp-plein',
        libelleGroupe: 'Les Lanternes',
      ),
    );
  });

  tearDown(() async {
    await session.liberer();
    await moteur.liberer();
  });

  Future<void> monter(WidgetTester tester, List<LibraryResource> choisies) =>
      tester.pumpWidget(
        PorteurSession(
          session: session,
          child: MaterialApp(
            home: _ClasseAvecPanneau(choisies: choisies),
            debugShowCheckedModeBanner: false,
          ),
        ),
      );

  group('Q-07 : la Bibliotheque s ouvre sans couper la room', () {
    testWidgets('ouvrir puis fermer le panneau ne deconnecte pas', (
      WidgetTester tester,
    ) async {
      final List<LibraryResource> choisies = <LibraryResource>[];
      await monter(tester, choisies);

      expect(moteur.etatCourant, EtatSalle.connecte);

      await tester.tap(find.text('Bibliotheque'));
      await tester.pumpAndSettle();
      expect(find.byKey(_cleePanneau), findsOneWidget);

      // Choisir une ressource ferme le panneau et remplace le support actif.
      await tester.tap(find.text('Coran'));
      await tester.pumpAndSettle();

      expect(choisies.single.id, 'res-coran');
      expect(moteur.deconnexions, 0);
      expect(moteur.liberations, 0);
      expect(moteur.etatCourant, EtatSalle.connecte);
    });

    testWidgets('trois ouvertures de suite ne coutent aucune deconnexion', (
      WidgetTester tester,
    ) async {
      final List<LibraryResource> choisies = <LibraryResource>[];
      await monter(tester, choisies);

      for (final String titre in <String>['Coran', 'Ajurrumiyya', 'Makharij']) {
        await tester.tap(find.text('Bibliotheque'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(titre));
        await tester.pumpAndSettle();
      }

      expect(choisies, hasLength(3));
      expect(moteur.deconnexions, 0);
      expect(moteur.etatCourant, EtatSalle.connecte);
    });

    testWidgets('la barre « Cours en cours » reste visible pendant tout cela', (
      WidgetTester tester,
    ) async {
      await monter(tester, <LibraryResource>[]);
      expect(find.byKey(const Key('barre-cours-en-cours')), findsOneWidget);

      await tester.tap(find.text('Bibliotheque'));
      await tester.pumpAndSettle();
      // Le panneau couvre l ecran, la barre reste montee dessous.
      expect(find.byKey(const Key('barre-cours-en-cours')), findsOneWidget);
    });
  });

  group('Q-07 : une seule Bibliotheque, la meme dedans et dehors', () {
    test('le catalogue ouvert en classe est le catalogue tout court', () {
      // Decision D-20 : il n existe pas `LibraryOutsideClass` et
      // `LibraryInsideClass`. Le panneau de classe lit la meme liste que le
      // catalogue hors classe -- la meme fonction, pas une copie filtree.
      expect(toutesLesRessources(), hasLength(5));
      expect(
        toutesLesRessources().map((LibraryResource r) => r.id).toSet(),
        <String>{
          'res-coran',
          'res-pdf',
          'res-texte',
          'res-image',
          'res-lecon',
        },
      );
    });

    test('les capacites, et rien d autre, decident de ce qui est offert', () {
      // Invariant 4 de CONTRACTS section 4 : une interface ne devine jamais
      // qu un PDF est annotable, elle lit `capabilities`.
      expect(
        ressourcePdf.capabilities.contains(CapaciteRessource.annotatable),
        isTrue,
      );
      expect(
        ressourceImage.capabilities.contains(CapaciteRessource.annotatable),
        isFalse,
      );
      expect(
        ressourceLecon.capabilities.contains(CapaciteRessource.supportsOffline),
        isFalse,
      );
      // Toutes les ressources presentables en classe le declarent.
      for (final LibraryResource r in toutesLesRessources()) {
        expect(
          r.capabilities.contains(CapaciteRessource.presentableInClass),
          isTrue,
          reason: '${r.id} doit se presenter en classe',
        );
      }
    });

    test('une couverture est une cle, jamais une URL signee', () {
      for (final LibraryResource r in toutesLesRessources()) {
        final String? cle = r.coverAsset;
        if (cle == null) continue;
        expect(cle.startsWith('http'), isFalse, reason: r.id);
        expect(cle.contains('?'), isFalse, reason: r.id);
        expect(cle.contains('token'), isFalse, reason: r.id);
      }
    });
  });
}

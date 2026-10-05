// EA-HL-DOUBLE-1 (decision du 04/10 deleguee par le directeur, K-42) : hors
// ligne se dit une seule fois. Le bandeau de `PageShell` est le signal ; une
// lecture deja faite reste affichee ; un bloc ne vient que si rien ne peut
// l'etre, et il dit ce qui manque.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';

import '../../support/hors_ligne_une_fois.dart';

/// Les cles dont le texte peut encore dire « hors ligne » : des ecrans sans
/// `PageShell`, donc sans bandeau (la salle, `PageImmersive`), le bandeau
/// lui-meme, l'etat par defaut de la nature (galerie), et les etiquettes du
/// selecteur d'etats des demonstrations.
const Set<String> _permises = <String>{
  'reseau.horsLigne',
  'commun.etats.horsLigne.titre',
  'salle.secours.horsLigne',
  'salle.preparation.eleve.demo.horsLigne',
  'salle.seance.demo.etats.horsLigne',
  'classe.entree.demo.etats.horsLigne',
  'enseignant.demo.etatHorsLigne',
  'adulte.demo.reseauCoupe',
  'tc.bibliotheque.offline.indisponible',
  'tc.bibliotheque.action.telecharger',
  'tc.bibliotheque.message.telechargementImpossible',
};

void _aplatir(Object? noeud, String chemin, Map<String, String> sortie) {
  if (noeud is Map<String, Object?>) {
    noeud.forEach(
      (String cle, Object? v) =>
          _aplatir(v, chemin.isEmpty ? cle : '$chemin.$cle', sortie),
    );
  } else if (noeud is String) {
    sortie[chemin] = noeud;
  }
}

void main() {
  group('lectureHorsLigne', () {
    // Un echec qui garde sa derniere valeur, tel que Riverpod le rend apres
    // une relecture ratee.
    late AsyncValue<int> echecAvecValeur;
    setUp(() async {
      int lectures = 0;
      final FutureProvider<int> source = FutureProvider<int>(
        (Ref _) => ++lectures == 1
            ? Future<int>.value(7)
            : Future<int>.error(StateError('reseau')),
        retry: (int _, Object _) => null,
      );
      final ProviderContainer conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);
      final ProviderSubscription<AsyncValue<int>> abonnement = conteneur.listen(
        source,
        (AsyncValue<int>? _, AsyncValue<int> _) {},
      );
      await conteneur.read(source.future);
      conteneur.invalidate(source);
      await expectLater(conteneur.read(source.future), throwsStateError);
      echecAvecValeur = abonnement.read();
    });

    test('hors ligne, un echec qui garde sa valeur rend la valeur', () {
      expect(echecAvecValeur.hasError, isTrue);
      final AsyncValue<int> vue = lectureHorsLigne(
        echecAvecValeur,
        horsLigne: true,
      );
      expect(vue.hasError, isFalse);
      expect(vue.requireValue, 7);
    });

    test('en ligne, l echec reste un echec', () {
      expect(
        lectureHorsLigne(echecAvecValeur, horsLigne: false).hasError,
        isTrue,
      );
    });

    test('sans valeur, l echec reste un echec', () {
      final AsyncValue<int> nu = AsyncError<int>(
        StateError('reseau'),
        StackTrace.empty,
      );
      expect(lectureHorsLigne(nu, horsLigne: true).hasError, isTrue);
    });
  });

  group('sansDonneesHorsLigne', () {
    test('hors ligne, en echec, sans valeur : vrai', () {
      expect(
        sansDonneesHorsLigne(
          AsyncError<int>(StateError('reseau'), StackTrace.empty),
          horsLigne: true,
        ),
        isTrue,
      );
    });

    test('en ligne : faux ; capacite absente : faux ; valeur : faux', () {
      final AsyncValue<int> echec = AsyncError<int>(
        StateError('reseau'),
        StackTrace.empty,
      );
      expect(sansDonneesHorsLigne(echec, horsLigne: false), isFalse);
      expect(
        sansDonneesHorsLigne(
          const AsyncError<int>(CapaciteIndisponible('X'), StackTrace.empty),
          horsLigne: true,
        ),
        isFalse,
      );
      expect(
        sansDonneesHorsLigne(const AsyncData<int>(1), horsLigne: true),
        isFalse,
      );
    });
  });

  testWidgets('EtatSansDonnees : dit ce qui manque, jamais « hors ligne »', (
    WidgetTester tester,
  ) async {
    int relectures = 0;
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: EtatSansDonnees(
              quoi: t.adulte.maClasse.sansDonnees,
              onAction: () => relectures++,
            ),
          ),
        ),
      ),
    );
    final EtatSysteme etat = tester.widget<EtatSysteme>(
      find.byType(EtatSysteme),
    );
    expect(etat.nature, NatureEtat.horsLigne);
    expect(find.text(t.adulte.maClasse.sansDonnees), findsOneWidget);
    expect(signauxHorsLigne(), findsNothing);
    await tester.tap(find.text(t.commun.etats.actions.reessayer));
    expect(relectures, 1);
  });

  test('catalogue : aucun texte ne redit « hors ligne » hors des cles '
      'permises (le bandeau, la salle sans bandeau, les demonstrations)', () {
    final Map<String, String> textes = <String, String>{};
    _aplatir(
      jsonDecode(File('assets/i18n/fr.i18n.json').readAsStringSync()),
      '',
      textes,
    );
    final List<String> fautifs = <String>[
      for (final MapEntry<String, String> e in textes.entries)
        if (!_permises.contains(e.key) &&
            RegExp(
              r'hors ligne|pas de réseau|pas de connexion',
              caseSensitive: false,
            ).hasMatch(e.value))
          '${e.key} = ${e.value}',
    ];
    expect(fautifs, isEmpty);
  });
}

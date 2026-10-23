// CAND-06 : ce qui personnalise la carte a partager, sans ecran.
//
// La langue de la carte : le francais, l'anglais, le portugais et l'arabe, et
// seulement ces quatre (directeur, 22/10/2026 : « pas les langues
// vernaculaires, juste les internationales ; regarde la langue dans laquelle le
// candidat veut enseigner et utilise celle-la », puis « il va aussi avoir le
// portugais »). La variante : lue sur le profil, jamais devinee.

import 'dart:async';

// fake_async est la dependance de flutter_test qui porte son horloge simulee.
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';

import 'package:flutter/painting.dart' show TextDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/partage_offre/genre_partageur_supabase.dart';
import 'package:rewayah_academy/core/partage_offre/personnalisation_carte.dart';
import 'package:rewayah_academy/core/partage_offre/port_genre_partageur.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../fixtures/partage_offre/faux_partage_offre.dart';

/// Un conteneur avec les doubles voulus.
ProviderContainer _conteneur({
  FauxGenrePartageur? genre,
  PortMaCandidature? candidature,
}) {
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[
      portGenrePartageurProvider.overrideWithValue(
        genre ?? FauxGenrePartageur(),
      ),
      portMaCandidatureProvider.overrideWithValue(candidature),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('les langues de la carte', () {
    test('quatre langues, dans l\'ordre des puces, et pas une de plus', () {
      expect(LangueCarte.values.map((LangueCarte l) => l.code), <String>[
        'fr',
        'en',
        'pt',
        'ar',
      ]);
    });

    test('seul l\'arabe se lit de droite a gauche', () {
      for (final LangueCarte l in LangueCarte.values) {
        expect(
          l.sens,
          l == LangueCarte.arabe ? TextDirection.rtl : TextDirection.ltr,
          reason: l.code,
        );
        expect(l.droiteAGauche, l == LangueCarte.arabe);
      }
    });

    test('un code du questionnaire donne sa langue ; le reste n\'en donne '
        'pas', () {
      expect(
        LangueCarte.depuisCodeEnseignement('francais'),
        LangueCarte.francais,
      );
      expect(
        LangueCarte.depuisCodeEnseignement('english'),
        LangueCarte.anglais,
      );
      // Le portugais n'est pas encore au referentiel : le code ISO, ou un nom
      // du meme genre que `francais`.
      for (final String code in <String>[
        'pt',
        'portugais',
        'portugues',
        'portuguese',
      ]) {
        expect(
          LangueCarte.depuisCodeEnseignement(code),
          LangueCarte.portugais,
          reason: code,
        );
      }
      // Les langues vernaculaires ne donnent pas de carte.
      for (final String code in <String>[
        'poular',
        'wo',
        'bm',
        'man',
        'sus',
        'sw',
        'ha',
        'snk',
        'mnk',
        'autre',
        '',
      ]) {
        expect(
          LangueCarte.depuisCodeEnseignement(code),
          isNull,
          reason: 'le code « $code »',
        );
      }
    });

    test(
      'l\'arabe n\'est jamais une langue de cours : aucun code n\'y mene',
      () {
        expect(LangueCarte.arabe.codesEnseignement, isEmpty);
        expect(LangueCarte.depuisCodeEnseignement('ar'), isNull);
        expect(LangueCarte.depuisCodeEnseignement('arabe'), isNull);
      },
    );

    test('la langue de l\'application : francais ou arabe', () {
      expect(LangueCarte.depuisLocale(AppLocale.fr), LangueCarte.francais);
      expect(LangueCarte.depuisLocale(AppLocale.ar), LangueCarte.arabe);
    });
  });

  group('la langue par defaut : la premiere langue d\'enseignement', () {
    LangueCarte par(List<String> langues, LangueCarte app) =>
        langueCarteParDefaut(languesEnseignement: langues, langueApp: app);

    test('la premiere des trois langues internationales gagne', () {
      expect(
        par(<String>['english', 'francais'], LangueCarte.francais),
        LangueCarte.anglais,
      );
      expect(
        par(<String>['francais', 'english'], LangueCarte.arabe),
        LangueCarte.francais,
      );
      expect(
        par(<String>['pt', 'francais'], LangueCarte.francais),
        LangueCarte.portugais,
      );
      expect(
        par(<String>['portugais'], LangueCarte.arabe),
        LangueCarte.portugais,
      );
    });

    test('une langue vernaculaire est sautee, jamais choisie', () {
      expect(
        par(<String>['poular', 'wo', 'english'], LangueCarte.francais),
        LangueCarte.anglais,
      );
      expect(
        par(<String>['poular', 'francais'], LangueCarte.arabe),
        LangueCarte.francais,
      );
    });

    test('sans langue internationale, la langue de l\'application', () {
      expect(par(<String>[], LangueCarte.francais), LangueCarte.francais);
      expect(par(<String>[], LangueCarte.arabe), LangueCarte.arabe);
      expect(
        par(<String>['poular', 'bm'], LangueCarte.arabe),
        LangueCarte.arabe,
      );
      expect(
        par(<String>['autre'], LangueCarte.francais),
        LangueCarte.francais,
      );
    });

    test('l\'arabe de l\'application ne vient pas des langues de cours', () {
      expect(par(<String>['ar'], LangueCarte.francais), LangueCarte.francais);
    });
  });

  group('la variante : lue sur le profil, jamais devinee', () {
    test('une femme donne la variante des femmes', () {
      expect(VarianteCarte.depuisGenre(Genre.femme), VarianteCarte.femmes);
    });

    test('un homme, ou un genre inconnu, donne la variante des hommes, '
        'la neutre', () {
      expect(VarianteCarte.depuisGenre(Genre.homme), VarianteCarte.hommes);
      expect(VarianteCarte.depuisGenre(null), VarianteCarte.hommes);
    });

    test(
      'la ligne du profil : « female » et « male », le reste est inconnu',
      () {
        expect(
          genreDepuisLigne(<String, dynamic>{'gender': 'female'}),
          Genre.femme,
        );
        expect(
          genreDepuisLigne(<String, dynamic>{'gender': 'male'}),
          Genre.homme,
        );
        expect(genreDepuisLigne(<String, dynamic>{'gender': null}), isNull);
        expect(genreDepuisLigne(<String, dynamic>{'gender': 'autre'}), isNull);
        expect(genreDepuisLigne(<String, dynamic>{'gender': 1}), isNull);
        expect(genreDepuisLigne(<String, dynamic>{}), isNull);
        expect(genreDepuisLigne(null), isNull);
      },
    );

    test('sans adaptateur branche, le genre est inconnu', () async {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      expect(await c.read(genrePartageurProvider.future), isNull);
    });

    test('un profil illisible vaut « inconnu » : jamais un echec', () async {
      final FauxGenrePartageur faux = FauxGenrePartageur(genre: Genre.femme)
        ..erreur = StateError('hors ligne');
      final ProviderContainer c = _conteneur(genre: faux);
      expect(await c.read(genrePartageurProvider.future), isNull);
      expect(faux.lectures, 1);
    });
  });

  group('les invitations a partager', () {
    test('« une sœur » pour une femme, « une personne » sinon, en francais et '
        'en arabe', () async {
      await LocaleSettings.setLocale(AppLocale.fr);
      expect(
        invitationPartage(VarianteCarte.femmes),
        'Aidez une sœur à apprendre la parole d\'Allah.',
      );
      expect(
        invitationPartage(VarianteCarte.hommes),
        'Aidez une personne à apprendre la parole d\'Allah.',
      );
      await LocaleSettings.setLocale(AppLocale.ar);
      expect(
        invitationPartage(VarianteCarte.femmes),
        'ساعدي أختًا على تعلّم كلام الله',
      );
      expect(
        invitationPartage(VarianteCarte.hommes),
        'ساعد شخصًا على تعلّم كلام الله',
      );
    });
  });

  group('les langues d\'enseignement du candidat', () {
    test('lues dans la derniere reponse, dans l\'ordre du serveur', () async {
      final ProviderContainer c = _conteneur(
        candidature: FauxMaCandidature(
          questionnaireJson: questionnaireJsonDeTest(
            dernieresReponses: <String, Object?>{
              'languesExplication': <String>['poular', 'english', 'francais'],
            },
          ),
        ),
      );
      expect(await c.read(languesEnseignementCandidatProvider.future), <String>[
        'poular',
        'english',
        'francais',
      ]);
    });

    test('sans reponse, sans port ou en panne : une liste vide, jamais une '
        'erreur', () async {
      // Aucune reponse enregistree.
      expect(
        await _conteneur(candidature: FauxMaCandidature())
            .read(languesEnseignementCandidatProvider.future),
        isEmpty,
      );
      // Aucun port branche.
      expect(
        await _conteneur().read(languesEnseignementCandidatProvider.future),
        isEmpty,
      );
      // Une lecture qui echoue.
      final FauxMaCandidature panne = FauxMaCandidature()
        ..erreurQuestionnaire = StateError('hors ligne');
      expect(
        await _conteneur(candidature: panne)
            .read(languesEnseignementCandidatProvider.future),
        isEmpty,
      );
      // Une reponse qui n'est pas une liste de textes.
      final ProviderContainer c = _conteneur(
        candidature: FauxMaCandidature(
          questionnaireJson: questionnaireJsonDeTest(
            dernieresReponses: <String, Object?>{
              'languesExplication': <Object?>['francais', 3, null],
            },
          ),
        ),
      );
      expect(await c.read(languesEnseignementCandidatProvider.future), <String>[
        'francais',
      ]);
    });
  });

  group('les reglages de la carte', () {
    test('le genre et les langues, lus ensemble', () async {
      final ProviderContainer c = _conteneur(
        genre: FauxGenrePartageur(genre: Genre.femme),
        candidature: FauxMaCandidature(
          questionnaireJson: questionnaireJsonDeTest(
            dernieresReponses: <String, Object?>{
              'languesExplication': <String>['poular', 'pt'],
            },
          ),
        ),
      );
      final ReglagesCarte r = await c.read(reglagesCarteProvider.future);
      expect(r.variante, VarianteCarte.femmes);
      expect(r.languesEnseignement, <String>['poular', 'pt']);
      expect(r.langueParDefaut(LangueCarte.francais), LangueCarte.portugais);
    });

    test(
      'rien de lisible : les hommes, et la langue de l\'application',
      () async {
        final ProviderContainer c = _conteneur();
        final ReglagesCarte r = await c.read(reglagesCarteProvider.future);
        expect(r.variante, VarianteCarte.hommes);
        expect(r.languesEnseignement, isEmpty);
        expect(r.langueParDefaut(LangueCarte.arabe), LangueCarte.arabe);
      },
    );

    test(
      'une lecture trop lente vaut « inconnu » : la carte n\'attend pas',
      () {
        fakeAsync((FakeAsync temps) {
          final Completer<Genre?> jamais = Completer<Genre?>();
          final ProviderContainer c = ProviderContainer(
            overrides: <Override>[
              portGenrePartageurProvider.overrideWithValue(_GenreLent(jamais)),
              portMaCandidatureProvider.overrideWithValue(null),
            ],
          );
          ReglagesCarte? lu;
          c
              .read(reglagesCarteProvider.future)
              .then((ReglagesCarte r) => lu = r);
          temps.elapse(delaiReglagesCarte + const Duration(seconds: 1));
          temps.flushMicrotasks();
          expect(lu, isNotNull);
          expect(lu!.variante, VarianteCarte.hommes);
          c.dispose();
        });
      },
    );
  });
}

/// Un profil dont la lecture ne revient pas.
class _GenreLent implements PortGenrePartageur {
  _GenreLent(this._attente);

  final Completer<Genre?> _attente;

  @override
  Future<Genre?> genreDuTitulaire() => _attente.future;
}

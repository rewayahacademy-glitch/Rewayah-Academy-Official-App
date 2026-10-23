// CAND-04 : l'inscription sans code du candidat enseignant. Ce que le test
// prouve, par les gestes d'une personne :
//
// - les liens sans code ne sont rendus que si le serveur dit l'inscription
//   ouverte ; fermee, illisible ou sans lot serveur, le bloc reste celui
//   d'aujourd'hui (l'academie invite par courriel, le code est l'entree) ;
// - les etapes se calculent selon l'usage : le candidat a cinq etapes
//   (usage, identite, genre, telephone, recapitulatif), le tuteur en garde
//   quatre ;
// - le telephone : l'indicatif se choisit (cartes, puis recherche en francais,
//   en arabe ou par l'indicatif), le numero se saisit sans l'indicatif, et part
//   au format international ;
// - le recapitulatif ajoute la langue (deux cartes, la langue active deja
//   retenue) et la case de confidentialite, jamais precochee, exigee a l'ecran,
//   avec la version du texte que le lien ouvre ;
// - chaque issue du serveur se dit en mots, avec quoi faire ; le succes et le
//   depassement du plafond horaire ont la meme reponse, sans aucun signe
//   qu'une adresse ou un telephone est deja connu ;
// - hors ligne : pas de bouton, une phrase.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/candidature/port_inscription_candidat.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/inscription/brouillon_inscription.dart';
import 'package:rewayah_academy/features/inscription/etapes/genre_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/identite_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/recapitulatif_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/telephone_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/usage_etape.dart';
import 'package:rewayah_academy/features/inscription/inscription_page.dart';
import 'package:rewayah_academy/features/juridique/textes_juridiques.dart';

import '../../fixtures/candidature/faux_inscription_candidat.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../../support/sens_et_echelle.dart';

const Key _caseConfidentialite = Key('inscription-confidentialite');
const Key _lienPolitique = Key('inscription-confidentialite-lire');
const Key _carteArabe = ValueKey<String>('inscription-langue-ar');
const Key _carteFrancais = ValueKey<String>('inscription-langue-fr');

/// Ce que le test garde du parcours monte.
class _Hote {
  _Hote(this.candidat, this.session, this.dossier, this.routeur);

  final FauxInscriptionCandidat candidat;
  final FausseSourceSession session;
  final FauxServiceDossier dossier;
  final GoRouter routeur;

  String get chemin =>
      routeur.routerDelegate.currentConfiguration.uri.toString();
}

/// Une session dont la relecture echoue [echecs] fois, puis reussit.
class _SessionQuiEchoue extends FausseSourceSession {
  _SessionQuiEchoue(this.echecs);

  int echecs;

  @override
  Future<void> rafraichir() async {
    if (echecs > 0) {
      echecs--;
      throw StateError('reseau');
    }
    await super.rafraichir();
  }
}

/// Monte le parcours sur un routeur a toutes les etapes. [compteExiste] imite
/// la porte du vrai routeur : tant qu'il est faux, `/attente` renvoie a
/// l'inscription (la session n'a pas de profil).
Future<_Hote> _monter(
  WidgetTester tester, {
  String depart = Routes.inscriptionUsage,
  FauxInscriptionCandidat? candidat,
  bool? inscriptionAbsente,
  bool horsLigne = false,
  bool Function()? compteExiste,
  FausseSourceSession? sessionImposee,
  Size taille = const Size(390, 844),
  double echelle = 1,
  ThemeMode mode = ThemeMode.light,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxInscriptionCandidat port = candidat ?? FauxInscriptionCandidat();
  final FausseSourceSession session = sessionImposee ?? FausseSourceSession();
  final FauxServiceDossier dossier = FauxServiceDossier();
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    redirect: (BuildContext _, GoRouterState etat) {
      if (compteExiste != null &&
          etat.matchedLocation == Routes.attente &&
          !compteExiste()) {
        return Routes.inscription;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.inscription,
        builder: (BuildContext _, GoRouterState _) => const InscriptionPage(),
      ),
      GoRoute(
        path: Routes.inscriptionUsage,
        builder: (BuildContext _, GoRouterState _) => const UsageEtape(),
      ),
      GoRoute(
        path: Routes.inscriptionIdentite,
        builder: (BuildContext _, GoRouterState _) => const IdentiteEtape(),
      ),
      GoRoute(
        path: Routes.inscriptionGenre,
        builder: (BuildContext _, GoRouterState _) => const GenreEtape(),
      ),
      GoRoute(
        path: Routes.inscriptionTelephone,
        builder: (BuildContext _, GoRouterState _) => const TelephoneEtape(),
      ),
      GoRoute(
        path: Routes.inscriptionRecapitulatif,
        builder: (BuildContext _, GoRouterState _) =>
            const RecapitulatifEtape(),
      ),
      GoRoute(
        path: Routes.inscriptionInvitation,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('CODE-INVITATION')),
      ),
      GoRoute(
        path: Routes.attente,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('ATTENTE')),
      ),
      GoRoute(
        path: TexteJuridique.confidentialite.chemin,
        builder: (BuildContext context, GoRouterState _) => Scaffold(
          body: Column(
            children: <Widget>[
              const Text('POLITIQUE'),
              TextButton(
                key: const Key('politique-retour'),
                onPressed: () => context.pop(),
                child: const Text('RETOUR'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      // Un conteneur neuf a chaque montage : sans cle, Riverpod garde le
      // precedent quand un test monte le parcours plusieurs fois.
      key: UniqueKey(),
      overrides: <Override>[
        serviceDossierProvider.overrideWithValue(dossier),
        sourceSessionProvider.overrideWithValue(session),
        serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
        portInscriptionCandidatProvider.overrideWithValue(
          inscriptionAbsente ?? false ? null : port,
        ),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
      ],
      child: TranslationProvider(
        // Comme `RewayahApp` : la langue de l'application est celle du
        // fournisseur de traductions, et le sens de lecture la suit.
        child: Builder(
          builder: (BuildContext context) => MaterialApp.router(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
            themeMode: mode,
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: sensEtEchelle(echelle: echelle),
            routerConfig: routeur,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Hote(port, session, dossier, routeur);
}

/// L'arabe est une bibliotheque chargee a la demande : un test la charge hors
/// de l'horloge simulee (puis rend le francais), pour qu'un changement de
/// langue fait par un geste aboutisse.
Future<void> _precharger(
  WidgetTester tester, {
  bool garderArabe = false,
}) async {
  await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
  if (!garderArabe) {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
  }
}

ProviderContainer _conteneur(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

BrouillonInscription _brouillon(WidgetTester tester) =>
    _conteneur(tester).read(brouillonInscriptionProvider);

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Future<void> _continuer(WidgetTester tester) =>
    _taper(tester, find.text(t.commun.continuer));

/// Prepare le brouillon d'un candidat qui a tout renseigne, puis ouvre le
/// recapitulatif.
Future<void> _versLeRecap(
  WidgetTester tester,
  _Hote hote, {
  bool sansCode = true,
  String pays = 'FR',
  String numero = '06 12 34 56 78',
}) async {
  final BrouillonInscriptionControleur c = _conteneur(tester)
      .read(brouillonInscriptionProvider.notifier);
  if (sansCode) {
    c.deposerSansCode();
  } else {
    c.choisirUsage(UsageInscription.enseignant);
  }
  c
    ..saisirIdentite(prenom: 'Amina', nom: 'Exemple')
    ..choisirGenre(Genre.femme)
    ..saisirTelephone(pays: pays, numero: numero);
  hote.routeur.go(Routes.inscriptionRecapitulatif);
  await tester.pumpAndSettle();
}

Future<void> _cocherEtCreer(WidgetTester tester) async {
  await _taper(tester, find.byKey(_caseConfidentialite));
  await _taper(tester, find.text(t.inscription.candidat.envoyer));
}

void main() {
  tearDown(() async {
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  group('l\'entree sans code, lue au serveur', () {
    testWidgets(
      'fermee : le bloc reste celui d\'aujourd\'hui, 0 lien sans code',
      (WidgetTester tester) async {
        await _monter(
          tester,
          candidat: FauxInscriptionCandidat(cleOuverte: false),
        );
        expect(
          find.byKey(const Key('inscription-enseignant-invite')),
          findsOneWidget,
        );
        expect(find.text(t.inscription.usage.enseignantInvite), findsOneWidget);
        expect(find.text(t.inscription.usage.enseignantPostuler), findsNothing);
        expect(
          find.byKey(const Key('inscription-deposer-candidature')),
          findsNothing,
        );
        expect(find.text(t.inscription.usage.deposerCandidature), findsNothing);
        // L'entree par le code reste.
        expect(
          find.byKey(const Key('inscription-lien-enseignant')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ouverte : la phrase change, deux liens, 0 « invite par courriel »',
      (WidgetTester tester) async {
        await _monter(tester);
        expect(find.text(t.inscription.usage.enseignantInvite), findsNothing);
        expect(
          find.text(t.inscription.usage.enseignantPostuler),
          findsOneWidget,
        );
        expect(
          find.text(t.inscription.usage.deposerCandidature),
          findsOneWidget,
        );
        expect(find.text(t.inscription.usage.enseignant), findsOneWidget);
        // Un seul bouton plein : « Continuer ». Les liens sont discrets.
        verifierUnSeulBoutonPlein(tester);
      },
    );

    testWidgets('sans port, illisible, sans lot serveur : comme fermee', (
      WidgetTester tester,
    ) async {
      final List<FauxInscriptionCandidat> cas = <FauxInscriptionCandidat>[
        FauxInscriptionCandidat()..panneLecture = panneReseau,
        FauxInscriptionCandidat()..panneLecture = panneLotAbsent,
        FauxInscriptionCandidat()..panneLecture = StateError('autre'),
      ];
      for (final FauxInscriptionCandidat c in cas) {
        await _monter(tester, candidat: c);
        expect(c.lectures, 1);
        expect(find.text(t.inscription.usage.enseignantInvite), findsOneWidget);
        expect(find.text(t.inscription.usage.deposerCandidature), findsNothing);
      }
      await _monter(tester, inscriptionAbsente: true);
      expect(find.text(t.inscription.usage.enseignantInvite), findsOneWidget);
      expect(find.text(t.inscription.usage.deposerCandidature), findsNothing);
    });

    testWidgets('« Deposer ma candidature » ouvre l\'identite, a 2 sur 5', (
      WidgetTester tester,
    ) async {
      final _Hote hote = await _monter(tester);
      await _taper(
        tester,
        find.byKey(const Key('inscription-deposer-candidature')),
      );
      expect(hote.chemin, Routes.inscriptionIdentite);
      expect(find.byKey(const Key('inscription-prenom')), findsOneWidget);
      expect(find.text('2 sur 5'), findsOneWidget);
      final BrouillonInscription b = _brouillon(tester);
      expect(b.usage, UsageInscription.enseignant);
      expect(b.sansCode, isTrue);
    });

    testWidgets('« J\'ai un code d\'invitation » garde la porte du code', (
      WidgetTester tester,
    ) async {
      final _Hote hote = await _monter(tester);
      await _taper(
        tester,
        find.byKey(const Key('inscription-lien-enseignant')),
      );
      expect(hote.chemin, Routes.inscriptionInvitation);
      expect(_brouillon(tester).sansCode, isFalse);
    });

    testWidgets('choisir une carte annule « sans code »', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _taper(
        tester,
        find.byKey(const Key('inscription-deposer-candidature')),
      );
      expect(_brouillon(tester).sansCode, isTrue);
      _conteneur(tester)
          .read(brouillonInscriptionProvider.notifier)
          .choisirUsage(UsageInscription.moi);
      expect(_brouillon(tester).sansCode, isFalse);
    });
  });

  group('les etapes se calculent selon l\'usage', () {
    test('quatre etapes pour le tuteur, l\'eleve adulte et le comptable', () {
      for (final UsageInscription? u in <UsageInscription?>[
        null,
        UsageInscription.moi,
        UsageInscription.famille,
        UsageInscription.comptable,
      ]) {
        expect(etapesPour(u), etapesInscription);
        expect(etapesPour(u), hasLength(4));
        expect(rangEtape(Routes.inscriptionRecapitulatif, u), 4);
        expect(rangEtape(Routes.inscriptionTelephone, u), 0);
      }
    });

    test('cinq etapes pour le candidat enseignant', () {
      expect(etapesPour(UsageInscription.enseignant), etapesCandidat);
      expect(etapesCandidat, hasLength(5));
      expect(
        rangEtape(Routes.inscriptionTelephone, UsageInscription.enseignant),
        4,
      );
      expect(
        rangEtape(Routes.inscriptionRecapitulatif, UsageInscription.enseignant),
        5,
      );
    });

    test('la premiere etape manquante du candidat est le telephone', () {
      const BrouillonInscription b = BrouillonInscription(
        usage: UsageInscription.enseignant,
        prenom: 'Amina',
        nom: 'Exemple',
        genre: Genre.femme,
      );
      expect(b.premiereEtapeManquante, Routes.inscriptionTelephone);
      // Un tuteur ne passe jamais par le telephone.
      expect(
        b.copier(usage: UsageInscription.moi).premiereEtapeManquante,
        Routes.inscriptionRecapitulatif,
      );
      expect(
        b
            .copier(paysTelephone: 'FR', numeroTelephone: '0612345678')
            .premiereEtapeManquante,
        Routes.inscriptionRecapitulatif,
      );
    });

    testWidgets('le tuteur garde ses quatre etapes et son recapitulatif', (
      WidgetTester tester,
    ) async {
      final _Hote hote = await _monter(tester);
      await _taper(tester, find.text(t.inscription.usage.moiTitre));
      expect(find.text('1 sur 4'), findsOneWidget);
      await _continuer(tester);
      expect(find.text('2 sur 4'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('inscription-prenom')),
        'Sara',
      );
      await tester.enterText(find.byKey(const Key('inscription-nom')), 'Kane');
      await _continuer(tester);
      expect(find.text('3 sur 4'), findsOneWidget);
      await _taper(tester, find.text(t.inscription.genreFemme));
      await _continuer(tester);
      // Quatrieme etape : le recapitulatif, sans telephone, sans langue, sans
      // case de confidentialite.
      expect(hote.chemin, Routes.inscriptionRecapitulatif);
      expect(find.text('4 sur 4'), findsOneWidget);
      expect(
        find.byKey(const Key('inscription-modifier-telephone')),
        findsNothing,
      );
      expect(find.byKey(_carteArabe), findsNothing);
      expect(find.byKey(_caseConfidentialite), findsNothing);
      expect(find.text(t.inscription.creer), findsOneWidget);
    });

    testWidgets('le telephone d\'un tuteur renvoie a la premiere etape', (
      WidgetTester tester,
    ) async {
      final _Hote hote = await _monter(
        tester,
        depart: Routes.inscriptionTelephone,
      );
      expect(hote.chemin, Routes.inscriptionUsage);
      expect(find.byKey(TelephoneEtape.numeroKey), findsNothing);
    });

    testWidgets('le candidat compte cinq etapes jusqu\'a la creation', (
      WidgetTester tester,
    ) async {
      final _Hote hote = await _monter(tester);
      await _taper(
        tester,
        find.byKey(const Key('inscription-deposer-candidature')),
      );
      expect(find.text('2 sur 5'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('inscription-prenom')),
        'Amina',
      );
      await tester.enterText(
        find.byKey(const Key('inscription-nom')),
        'Exemple',
      );
      await _continuer(tester);
      expect(find.text('3 sur 5'), findsOneWidget);
      await _taper(tester, find.text(t.inscription.genreFemme));
      await _continuer(tester);
      expect(hote.chemin, Routes.inscriptionTelephone);
      expect(find.text('4 sur 5'), findsOneWidget);
      await _taper(tester, find.byKey(TelephoneEtape.paysKey('FR')));
      await tester.enterText(
        find.byKey(TelephoneEtape.numeroKey),
        '0612345678',
      );
      await _continuer(tester);
      expect(hote.chemin, Routes.inscriptionRecapitulatif);
      expect(find.text('5 sur 5'), findsOneWidget);
      await _cocherEtCreer(tester);
      expect(hote.candidat.creations, hasLength(1));
      final AppelInscriptionCandidat a = hote.candidat.appels.single;
      expect(a.code, isNull);
      expect(a.telephone, '+33612345678');
      expect(a.genre, 'female');
      expect(find.text('ATTENTE'), findsOneWidget);
    });
  });

  group('le telephone', () {
    Future<_Hote> monterTelephone(WidgetTester tester) async {
      final _Hote hote = await _monter(tester);
      final BrouillonInscriptionControleur c = _conteneur(tester)
          .read(brouillonInscriptionProvider.notifier);
      c
        ..deposerSansCode()
        ..saisirIdentite(prenom: 'Amina', nom: 'Exemple')
        ..choisirGenre(Genre.femme);
      hote.routeur.go(Routes.inscriptionTelephone);
      await tester.pumpAndSettle();
      return hote;
    }

    testWidgets(
      'la question, l\'explication de la fiche, et les cartes d\'abord',
      (WidgetTester tester) async {
        await monterTelephone(tester);
        expect(find.text('Votre numéro de téléphone'), findsOneWidget);
        expect(
          find.text(
            'Il sert à éviter les doublons et à relier vos échanges avec '
            'l\'académie à votre candidature. L\'académie vous écrit dans l\'application. '
            'Il n\'est jamais montré aux autres personnes qui postulent.',
          ),
          findsOneWidget,
        );
        expect(find.text(t.inscription.telephone.indicatif), findsOneWidget);
        // L'indicatif se choisit : des cartes, pas de clavier.
        expect(find.byKey(TelephoneEtape.paysKey('FR')), findsOneWidget);
        expect(find.byKey(TelephoneEtape.paysKey('MA')), findsOneWidget);
        expect(find.text('France'), findsOneWidget);
        expect(find.text('\u2066+33\u2069'), findsOneWidget);
        expect(find.byKey(TelephoneEtape.numeroKey), findsNothing);
        verifierUnSeulBoutonPlein(tester);
      },
    );

    testWidgets(
      'continuer sans indicatif : la phrase de la fiche, rien n\'avance',
      (WidgetTester tester) async {
        final _Hote hote = await monterTelephone(tester);
        expect(
          find.text(t.inscription.telephone.indicatifManquant),
          findsNothing,
        );
        await _continuer(tester);
        expect(
          find.text('Choisissez l\'indicatif de votre pays.'),
          findsOneWidget,
        );
        expect(hote.chemin, Routes.inscriptionTelephone);
      },
    );

    testWidgets('l\'indicatif choisi se replie, le numero prend la place', (
      WidgetTester tester,
    ) async {
      await monterTelephone(tester);
      await _taper(tester, find.byKey(TelephoneEtape.paysKey('FR')));
      expect(find.byKey(TelephoneEtape.paysChoisiKey), findsOneWidget);
      expect(find.byKey(TelephoneEtape.paysKey('MA')), findsNothing);
      expect(find.byKey(TelephoneEtape.numeroKey), findsOneWidget);
      expect(find.text('Numéro, sans l\'indicatif'), findsOneWidget);
      // L'indicatif est en tete du champ.
      expect(find.textContaining('+33'), findsWidgets);
    });

    testWidgets('numero absent, illisible ou trop court : le champ est nomme', (
      WidgetTester tester,
    ) async {
      final _Hote hote = await monterTelephone(tester);
      await _taper(tester, find.byKey(TelephoneEtape.paysKey('FR')));
      await _continuer(tester);
      expect(find.text('Saisissez votre numéro de téléphone.'), findsOneWidget);
      await tester.enterText(find.byKey(TelephoneEtape.numeroKey), '06 12 ab');
      await _continuer(tester);
      expect(find.text(t.inscription.telephone.numeroInvalide), findsOneWidget);
      await tester.enterText(
        find.byKey(TelephoneEtape.numeroKey),
        '+33 6 12 34 56 78',
      );
      await _continuer(tester);
      expect(find.text(t.inscription.telephone.numeroInvalide), findsOneWidget);
      await tester.enterText(find.byKey(TelephoneEtape.numeroKey), '12');
      await _continuer(tester);
      expect(find.text(t.inscription.telephone.numeroInvalide), findsOneWidget);
      expect(hote.chemin, Routes.inscriptionTelephone);
      expect(_brouillon(tester).telephoneRempli, isFalse);
    });

    testWidgets('un numero valable est garde, au format international', (
      WidgetTester tester,
    ) async {
      final _Hote hote = await monterTelephone(tester);
      await _taper(tester, find.byKey(TelephoneEtape.paysKey('MA')));
      await tester.enterText(
        find.byKey(TelephoneEtape.numeroKey),
        '0661 23 45 67',
      );
      await _continuer(tester);
      expect(hote.chemin, Routes.inscriptionRecapitulatif);
      final BrouillonInscription b = _brouillon(tester);
      expect(b.paysTelephone, 'MA');
      expect(b.telephone, '+212661234567');
    });

    testWidgets(
      '« Un autre pays » : recherche par nom, en francais et en arabe, ou par indicatif',
      (WidgetTester tester) async {
        await monterTelephone(tester);
        await _taper(
          tester,
          find.byKey(const ValueKey<String>('choix-recherche-autre')),
        );
        final Finder champ = find.byKey(
          const ValueKey<String>('choix-recherche-champ'),
        );
        // Le nom, en francais.
        await tester.enterText(champ, 'maur');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('choix-recherche-MR')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('choix-recherche-FR')),
          findsNothing,
        );
        // Le nom, en arabe, alors que l'application est en francais.
        await tester.enterText(champ, 'الجزائر');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('choix-recherche-DZ')),
          findsOneWidget,
        );
        // L'indicatif.
        await tester.enterText(champ, '+212');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('choix-recherche-MA')),
          findsOneWidget,
        );
        // Aucun resultat : une phrase.
        await tester.enterText(champ, 'zzzz');
        await tester.pumpAndSettle();
        expect(find.text(t.recrutement.parcours.pays.aucun), findsOneWidget);
        // Choisir un pays de la recherche.
        await tester.enterText(champ, 'japon');
        await tester.pumpAndSettle();
        await _taper(
          tester,
          find.byKey(const ValueKey<String>('choix-recherche-JP')),
        );
        expect(find.byKey(TelephoneEtape.paysChoisiKey), findsOneWidget);
        expect(find.text('Japon'), findsOneWidget);
        expect(find.textContaining('+81'), findsWidgets);
      },
    );

    testWidgets('changer d\'indicatif rouvre la liste, le numero est garde', (
      WidgetTester tester,
    ) async {
      await monterTelephone(tester);
      await _taper(tester, find.byKey(TelephoneEtape.paysKey('FR')));
      await tester.enterText(
        find.byKey(TelephoneEtape.numeroKey),
        '0612345678',
      );
      await _taper(tester, find.byKey(TelephoneEtape.paysChoisiKey));
      expect(find.byKey(TelephoneEtape.numeroKey), findsNothing);
      expect(find.byKey(TelephoneEtape.paysKey('BE')), findsOneWidget);
      await _taper(tester, find.byKey(TelephoneEtape.paysKey('BE')));
      final TextField champ = tester.widget<TextField>(
        find.byKey(TelephoneEtape.numeroKey),
      );
      expect(champ.controller!.text, '0612345678');
      await _continuer(tester);
      expect(_brouillon(tester).telephone, '+32612345678');
    });

    testWidgets('« Modifier » depuis le recapitulatif y revient', (
      WidgetTester tester,
    ) async {
      final _Hote hote = await _monter(tester);
      await _versLeRecap(tester, hote);
      await _taper(
        tester,
        find.byKey(const Key('inscription-modifier-telephone')),
      );
      expect(hote.chemin, startsWith(Routes.inscriptionTelephone));
      await tester.enterText(
        find.byKey(TelephoneEtape.numeroKey),
        '07 11 22 33 44',
      );
      await _continuer(tester);
      expect(hote.chemin, Routes.inscriptionRecapitulatif);
      expect(_brouillon(tester).telephone, '+33711223344');
    });

    testWidgets(
      'la phrase d\'indicatif est au-dessus de la liste, jamais sous le pli',
      (WidgetTester tester) async {
        await monterTelephone(tester);
        // La personne a fait defiler la longue liste des pays.
        await tester.ensureVisible(find.byKey(TelephoneEtape.paysKey('US')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.commun.continuer));
        await tester.pumpAndSettle();
        final Finder phrase = find.text(
          t.inscription.telephone.indicatifManquant,
        );
        expect(phrase, findsOneWidget);
        // Ramenee a l'ecran, et au-dessus des cartes.
        final Rect fenetre = tester.getRect(find.byType(Scaffold).first);
        expect(
          fenetre.contains(tester.getCenter(phrase)),
          isTrue,
          reason: 'la phrase doit etre visible',
        );
        expect(
          tester.getTopLeft(phrase).dy,
          lessThan(
            tester.getTopLeft(find.byKey(TelephoneEtape.paysKey('FR'))).dy,
          ),
        );
      },
    );

    testWidgets(
      'la recherche met d\'abord les noms qui commencent par ce qui est tape',
      (WidgetTester tester) async {
        await monterTelephone(tester);
        await _taper(
          tester,
          find.byKey(const ValueKey<String>('choix-recherche-autre')),
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('choix-recherche-champ')),
          'ma',
        );
        await tester.pumpAndSettle();
        // Maroc commence par « ma » ; Allemagne le contient seulement.
        final List<String> codes = <String>[
          for (final Element e
              in find
                  .byWidgetPredicate(
                    (Widget w) =>
                        w.key is ValueKey<String> &&
                        RegExp(r'^choix-recherche-[A-Z]{2}$')
                            .hasMatch((w.key! as ValueKey<String>).value),
                  )
                  .evaluate())
            (e.widget.key! as ValueKey<String>).value.substring(16),
        ];
        expect(codes, contains('MA'));
        expect(codes, contains('DE'));
        expect(codes.indexOf('MA'), lessThan(codes.indexOf('DE')));
      },
    );

    testWidgets(
      'en arabe, le numero se lit de gauche a droite, la phrase dans le sens de la page',
      (WidgetTester tester) async {
        await _precharger(tester, garderArabe: true);
        await monterTelephone(tester);
        await _taper(tester, find.byKey(TelephoneEtape.paysKey('FR')));
        await tester.enterText(
          find.byKey(TelephoneEtape.numeroKey),
          '06 12 ab',
        );
        await _continuer(tester);
        expect(
          Directionality.of(
            tester.element(find.byKey(TelephoneEtape.numeroKey)),
          ),
          TextDirection.ltr,
        );
        final Finder phrase = find.text(t.inscription.telephone.numeroInvalide);
        expect(phrase, findsOneWidget);
        expect(
          Directionality.of(tester.element(phrase)),
          TextDirection.rtl,
          reason: 'la phrase suit le sens de la page',
        );
      },
    );

    testWidgets('le disque retour ramene au genre', (
      WidgetTester tester,
    ) async {
      final _Hote hote = await monterTelephone(tester);
      await _taper(tester, find.bySemanticsLabel(t.commun.entete.retour));
      expect(hote.chemin, Routes.inscriptionGenre);
    });
  });

  group('le recapitulatif du candidat', () {
    testWidgets(
      'les reponses, la langue active retenue, la case jamais cochee',
      (WidgetTester tester) async {
        final _Hote hote = await _monter(tester);
        await _versLeRecap(tester, hote);
        expect(find.text('5 sur 5'), findsOneWidget);
        expect(find.text('Amina Exemple'), findsOneWidget);
        expect(find.text(t.inscription.recap.telephone), findsOneWidget);
        expect(find.text('\u2066+33 612345678\u2069'), findsOneWidget);
        expect(find.text(t.inscription.modifier), findsNWidgets(4));
        // La langue : deux cartes, la langue de l'ecran deja retenue.
        expect(find.text(t.inscription.langue.question), findsOneWidget);
        expect(find.byKey(_carteFrancais), findsOneWidget);
        expect(find.byKey(_carteArabe), findsOneWidget);
        // La case : jamais precochee, avec son lien.
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
        expect(
          find.text('J\'ai lu et j\'accepte la politique de confidentialité.'),
          findsOneWidget,
        );
        expect(
          find.text('Lire la politique de confidentialité'),
          findsOneWidget,
        );
        expect(find.text(t.inscription.candidat.envoyer), findsOneWidget);
        verifierUnSeulBoutonPlein(tester);
      },
    );

    testWidgets(
      'la version du texte accepte est dite, et c\'est celle qui part',
      (WidgetTester tester) async {
        final _Hote hote = await _monter(tester);
        await _versLeRecap(tester, hote);
        final Finder ligne = find.byKey(
          const Key('inscription-confidentialite-version'),
        );
        expect(ligne, findsOneWidget);
        expect(
          tester.widget<Text>(ligne).data,
          'Version 2026-10-v1, texte du 18 octobre 2026',
        );
        await _cocherEtCreer(tester);
        expect(
          hote.candidat.appels.single.versionConfidentialite,
          VersionsJuridiques.version,
        );
      },
    );

    testWidgets('sans la case : la phrase, rien n\'est envoye', (
      WidgetTester tester,
    ) async {
      final _Hote hote = await _monter(tester);
      await _versLeRecap(tester, hote);
      await _taper(tester, find.text(t.inscription.candidat.envoyer));
      expect(
        find.text('Cochez cette case pour envoyer votre candidature.'),
        findsOneWidget,
      );
      expect(hote.candidat.appels, isEmpty);
      // Cocher efface la phrase.
      await _taper(tester, find.byKey(_caseConfidentialite));
      expect(find.text(t.inscription.confidentialite.requise), findsNothing);
      expect(_brouillon(tester).confidentialiteAcceptee, isTrue);
    });

    testWidgets(
      'lire la politique ne perd pas la case, et part avec sa version',
      (WidgetTester tester) async {
        final _Hote hote = await _monter(tester);
        await _versLeRecap(tester, hote);
        await _taper(tester, find.byKey(_caseConfidentialite));
        await _taper(tester, find.byKey(_lienPolitique));
        expect(find.text('POLITIQUE'), findsOneWidget);
        await tester.tap(find.byKey(const Key('politique-retour')));
        await tester.pumpAndSettle();
        expect(hote.chemin, Routes.inscriptionRecapitulatif);
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
        await _taper(tester, find.text(t.inscription.candidat.envoyer));
        // La version envoyee est celle du texte que le lien ouvre.
        expect(
          hote.candidat.appels.single.versionConfidentialite,
          VersionsJuridiques.version,
        );
        expect(
          hote.candidat.appels.single.versionConfidentialite,
          '2026-10-v1',
        );
      },
    );

    testWidgets(
      'avec un code : le code part, le compte est celui de l\'invitation',
      (WidgetTester tester) async {
        final FauxInscriptionCandidat candidat = FauxInscriptionCandidat(
          cleOuverte: false,
          codesValides: <String>{'ABCD-EFGH-JKMN'},
        );
        final _Hote hote = await _monter(tester, candidat: candidat);
        _conteneur(tester)
            .read(codeInvitationRetenuProvider.notifier)
            .retenir('ABCD-EFGH-JKMN');
        await _versLeRecap(tester, hote, sansCode: false);
        await _cocherEtCreer(tester);
        expect(candidat.appels.single.code, 'ABCD-EFGH-JKMN');
        expect(candidat.creations, hasLength(1));
        expect(find.text('ATTENTE'), findsOneWidget);
        // Le code est oublie une fois servi.
        expect(_conteneur(tester).read(codeInvitationRetenuProvider), isNull);
      },
    );

    testWidgets(
      'sans code retenu et sans « Deposer ma candidature » : le champ du code',
      (WidgetTester tester) async {
        final _Hote hote = await _monter(tester);
        await _versLeRecap(tester, hote, sansCode: false);
        await _cocherEtCreer(tester);
        expect(hote.chemin, Routes.inscriptionInvitation);
        expect(hote.candidat.appels, isEmpty);
      },
    );

    testWidgets(
      'la langue : l\'arabe change l\'ecran, et c\'est cette langue qui part',
      (WidgetTester tester) async {
        await _precharger(tester);
        final _Hote hote = await _monter(tester);
        await _versLeRecap(tester, hote);
        await _taper(tester, find.byKey(_carteArabe));
        expect(LocaleSettings.currentLocale, AppLocale.ar);
        // L'ecran est maintenant en arabe, de droite a gauche.
        expect(find.text(t.inscription.candidat.envoyer), findsOneWidget);
        expect(t.inscription.candidat.envoyer, 'إرسال ترشحي');
        expect(
          Directionality.of(tester.element(find.byKey(_caseConfidentialite))),
          TextDirection.rtl,
        );
        await _cocherEtCreer(tester);
        expect(hote.candidat.appels.single.langue, 'ar');
        // Et retour au francais.
        await LocaleSettings.setLocale(AppLocale.fr);
      },
    );

    testWidgets('le francais par defaut part comme « fr »', (
      WidgetTester tester,
    ) async {
      final _Hote hote = await _monter(tester);
      await _versLeRecap(tester, hote);
      await _cocherEtCreer(tester);
      expect(hote.candidat.appels.single.langue, 'fr');
    });

    testWidgets('relire la session apres la creation, puis /attente', (
      WidgetTester tester,
    ) async {
      final _Hote hote = await _monter(tester);
      await _versLeRecap(tester, hote);
      await _cocherEtCreer(tester);
      expect(hote.session.rafraichissements, 1);
      expect(hote.dossier.profilsCrees, isEmpty);
      expect(hote.chemin, Routes.attente);
    });

    testWidgets('un double appui ne cree qu\'une fois', (
      WidgetTester tester,
    ) async {
      final Completer<void> porte = Completer<void>();
      final _PortLent lent = _PortLent(porte.future);
      final _Hote hote = await _monter(tester, candidat: lent);
      await _versLeRecap(tester, hote);
      await _taper(tester, find.byKey(_caseConfidentialite));
      final Finder creer = find.text(t.inscription.candidat.envoyer);
      await tester.ensureVisible(creer);
      await tester.tap(creer);
      await tester.pump();
      await tester.tap(creer, warnIfMissed: false);
      await tester.pump();
      expect(lent.entrees, 1);
      porte.complete();
      await tester.pumpAndSettle();
      expect(lent.entrees, 1);
      expect(lent.appels, hasLength(1));
    });
  });

  group('chaque issue du serveur se dit en mots', () {
    Future<_Hote> versLaCreation(
      WidgetTester tester,
      FauxInscriptionCandidat candidat, {
      bool horsLigne = false,
      bool sansCode = true,
    }) async {
      final _Hote hote = await _monter(
        tester,
        candidat: candidat,
        horsLigne: horsLigne,
      );
      await _versLeRecap(tester, hote, sansCode: sansCode);
      return hote;
    }

    testWidgets(
      'fermee : la phrase de la fiche, un lien vers le code, aucun bouton plein',
      (WidgetTester tester) async {
        final FauxInscriptionCandidat candidat = FauxInscriptionCandidat(
          cleOuverte: false,
        );
        // L'entree sans code etait ouverte quand la personne a commence.
        final _Hote hote = await versLaCreation(tester, candidat);
        await _cocherEtCreer(tester);
        expect(
          find.text(
            'Les candidatures sans code ne sont pas encore ouvertes. Si la '
            'direction vous a remis un code, saisissez-le.',
          ),
          findsOneWidget,
        );
        // Un bouton qui ne peut pas aboutir n'est pas rendu.
        expect(find.text(t.inscription.candidat.envoyer), findsNothing);
        expect(find.text(t.inscription.reessayer), findsNothing);
        verifierUnSeulBoutonPlein(tester, maximum: 0);
        await _taper(tester, find.byKey(const Key('inscription-recap-code')));
        expect(hote.chemin, Routes.inscriptionInvitation);
      },
    );

    testWidgets('courriel a confirmer : la phrase, et « Reessayer »', (
      WidgetTester tester,
    ) async {
      final FauxInscriptionCandidat candidat = FauxInscriptionCandidat()
        ..courrielConfirme = false;
      await versLaCreation(tester, candidat);
      await _cocherEtCreer(tester);
      expect(
        find.text(
          'Confirmez d\'abord votre adresse : ouvrez le lien reçu par courriel.',
        ),
        findsOneWidget,
      );
      expect(find.text(t.inscription.reessayer), findsOneWidget);
      expect(candidat.creations, isEmpty);
      // Une fois l'adresse confirmee, le meme geste aboutit.
      candidat.courrielConfirme = true;
      await _taper(tester, find.text(t.inscription.reessayer));
      expect(find.text('ATTENTE'), findsOneWidget);
    });

    testWidgets('invalide : les champs sont nommes, les « Modifier » restent', (
      WidgetTester tester,
    ) async {
      final FauxInscriptionCandidat candidat = FauxInscriptionCandidat()
        ..reponseImposee = const InscriptionInvalide(<String>[
          'telephone',
          'genre',
        ]);
      await versLaCreation(tester, candidat);
      await _cocherEtCreer(tester);
      expect(
        find.text(
          'Une réponse doit être corrigée : Téléphone, Genre. Appuyez '
          'sur « Modifier » à côté de la réponse.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inscription-modifier-telephone')),
        findsOneWidget,
      );
      expect(find.text(t.inscription.candidat.envoyer), findsOneWidget);
      // Les reponses, avec leurs « Modifier », sont ramenees a l'ecran.
      final Rect fenetre = tester.getRect(find.byType(Scaffold).first);
      expect(
        fenetre.contains(
          tester.getCenter(
            find.byKey(const Key('inscription-modifier-telephone')),
          ),
        ),
        isTrue,
      );
    });

    testWidgets(
      'code refuse : le code est oublie, le message de la direction',
      (WidgetTester tester) async {
        for (final ResultatInscriptionCandidat r
            in <ResultatInscriptionCandidat>[
              const InscriptionCodeInconnu(),
              const InscriptionCodeDejaUtilise(),
              const InscriptionCodeExpire(),
            ]) {
          final FauxInscriptionCandidat candidat = FauxInscriptionCandidat()
            ..reponseImposee = r;
          final _Hote hote = await versLaCreation(
            tester,
            candidat,
            sansCode: false,
          );
          _conteneur(tester)
              .read(codeInvitationRetenuProvider.notifier)
              .retenir('ABCD-EFGH-JKMN');
          await _cocherEtCreer(tester);
          expect(find.text(t.inscription.erreurInvitation), findsOneWidget);
          expect(_conteneur(tester).read(codeInvitationRetenuProvider), isNull);
          expect(hote.candidat.creations, isEmpty);
        }
      },
    );

    testWidgets(
      'confidentialite perimee ou indisponible : une phrase, aucune creation',
      (WidgetTester tester) async {
        final FauxInscriptionCandidat candidat = FauxInscriptionCandidat()
          ..versionAttendue = '2026-11-v2';
        await versLaCreation(tester, candidat);
        await _cocherEtCreer(tester);
        expect(
          find.text(t.inscription.candidat.confidentialitePerimee),
          findsOneWidget,
        );
        expect(candidat.creations, isEmpty);

        final FauxInscriptionCandidat sansVersion = FauxInscriptionCandidat()
          ..versionAttendue = null;
        await versLaCreation(tester, sansVersion);
        await _cocherEtCreer(tester);
        expect(find.text(t.inscription.candidat.indisponible), findsOneWidget);
      },
    );

    testWidgets(
      'panne : « Votre compte n\'a pas pu etre cree », puis « Reessayer »',
      (WidgetTester tester) async {
        final FauxInscriptionCandidat candidat = FauxInscriptionCandidat()
          ..panneInscription = StateError('panne');
        await versLaCreation(tester, candidat);
        await _cocherEtCreer(tester);
        expect(
          find.text(
            'Votre candidature n\'est peut-être pas partie. Réessayez dans un instant.',
          ),
          findsOneWidget,
        );
        expect(find.text(t.inscription.reessayer), findsOneWidget);
        // Reessayer rejoue l'appel, et il aboutit.
        candidat.panneInscription = null;
        await _taper(tester, find.text(t.inscription.reessayer));
        expect(candidat.appels, hasLength(2));
        expect(find.text('ATTENTE'), findsOneWidget);
      },
    );

    testWidgets(
      'reseau coupe pendant l\'envoi : non confirme, jamais « non envoye »',
      (WidgetTester tester) async {
        final FauxInscriptionCandidat candidat = FauxInscriptionCandidat()
          ..panneInscription = panneReseau;
        await versLaCreation(tester, candidat);
        await _cocherEtCreer(tester);
        expect(
          find.text(
            'Il est possible que votre demande ne soit pas parvenue jusqu\'à '
            'Rewayah. Réessayez dans un instant.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('non envoy'), findsNothing);
        expect(find.text(t.inscription.reessayer), findsOneWidget);
      },
    );

    testWidgets('lot serveur absent : une phrase honnete, pas de faux succes', (
      WidgetTester tester,
    ) async {
      final FauxInscriptionCandidat candidat = FauxInscriptionCandidat()
        ..panneInscription = panneLotAbsent;
      await versLaCreation(tester, candidat);
      await _cocherEtCreer(tester);
      expect(find.text(t.inscription.candidat.indisponible), findsOneWidget);
      expect(find.text('ATTENTE'), findsNothing);
    });

    testWidgets('port absent : la meme phrase, aucune creation', (
      WidgetTester tester,
    ) async {
      final _Hote hote = await _monter(tester, inscriptionAbsente: true);
      await _versLeRecap(tester, hote);
      await _cocherEtCreer(tester);
      expect(find.text(t.inscription.candidat.indisponible), findsOneWidget);
      expect(find.text('ATTENTE'), findsNothing);
    });

    testWidgets('hors ligne : pas de bouton, une phrase qui dit quand', (
      WidgetTester tester,
    ) async {
      final FauxInscriptionCandidat candidat = FauxInscriptionCandidat();
      await versLaCreation(tester, candidat, horsLigne: true);
      expect(
        find.text(
          'La candidature pourra être envoyée quand la connexion reviendra.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inscription-note-hors-ligne')),
        findsOneWidget,
      );
      expect(find.text(t.inscription.candidat.envoyer), findsNothing);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
      expect(candidat.appels, isEmpty);
    });

    testWidgets('une session qui a deja un profil : on relit et on entre', (
      WidgetTester tester,
    ) async {
      final FauxInscriptionCandidat candidat = FauxInscriptionCandidat()
        ..profilExiste = true;
      final _Hote hote = await versLaCreation(tester, candidat);
      await _cocherEtCreer(tester);
      expect(hote.session.rafraichissements, 1);
      expect(hote.chemin, Routes.attente);
    });
  });

  group('la reponse neutre : succes et plafond atteint, un seul visage', () {
    Future<List<String>> parcours(
      WidgetTester tester,
      FauxInscriptionCandidat candidat, {
      bool Function()? compteExiste,
    }) async {
      final _Hote hote = await _monter(
        tester,
        candidat: candidat,
        compteExiste: compteExiste,
      );
      await _versLeRecap(tester, hote);
      await _cocherEtCreer(tester);
      final List<String> vu = <String>[
        for (final Text w in tester.widgetList<Text>(find.byType(Text)))
          if ((w.data ?? '').isNotEmpty) w.data!,
      ];
      return <String>[hote.chemin, ...vu];
    }

    testWidgets('meme reponse du port, meme ecran, memes appels', (
      WidgetTester tester,
    ) async {
      final FauxInscriptionCandidat succes = FauxInscriptionCandidat();
      final List<String> a = await parcours(tester, succes);
      final FauxInscriptionCandidat plafond = FauxInscriptionCandidat(
        plafond: 0,
      );
      final List<String> b = await parcours(tester, plafond);
      // Le port rend le meme resultat, l'ecran fait le meme geste.
      expect(a, b);
      expect(a.first, Routes.attente);
      expect(succes.creations, hasLength(1));
      expect(plafond.creations, isEmpty, reason: 'le plafond ne cree rien');
      expect(plafond.appels, hasLength(1));
    });

    testWidgets('le plafond ne se lit nulle part : aucune phrase, aucun mot', (
      WidgetTester tester,
    ) async {
      final FauxInscriptionCandidat plafond = FauxInscriptionCandidat(
        plafond: 0,
      );
      final List<String> vu = await parcours(
        tester,
        plafond,
        compteExiste: () => plafond.creations.isNotEmpty,
      );
      final String tout = vu.join(' ').toLowerCase();
      for (final String interdit in <String>[
        'plafond',
        'limite',
        'trop de',
        'déjà',
        'deja',
        'connu',
        'existe',
      ]) {
        expect(tout.contains(interdit), isFalse, reason: interdit);
      }
    });

    testWidgets(
      'si la session n\'a pas de profil, l\'ecran le dit comme une panne',
      (WidgetTester tester) async {
        final FauxInscriptionCandidat plafond = FauxInscriptionCandidat(
          plafond: 0,
        );
        final _Hote hote = await _monter(
          tester,
          candidat: plafond,
          compteExiste: () => plafond.creations.isNotEmpty,
        );
        await _versLeRecap(tester, hote);
        await _cocherEtCreer(tester);
        // Le routeur a renvoye au recapitulatif : la personne lit une phrase
        // vraie dans les deux mondes et peut recommencer.
        expect(hote.chemin, Routes.inscriptionRecapitulatif);
        expect(
          find.text(
            'Votre candidature n\'est peut-être pas partie. Réessayez dans un instant.',
          ),
          findsOneWidget,
        );
        expect(find.text(t.inscription.reessayer), findsOneWidget);
        // « Reessayer » rejoue l'appel (jamais un faux « compte cree »).
        await _taper(tester, find.text(t.inscription.reessayer));
        expect(plafond.appels, hasLength(2));
      },
    );

    testWidgets(
      'la version du texte a change : rien n\'est envoye, la phrase le dit',
      (WidgetTester tester) async {
        final FauxInscriptionCandidat candidat = FauxInscriptionCandidat(
          versionAttendue: '2099-01-v9',
        );
        final _Hote hote = await _monter(tester, candidat: candidat);
        await _versLeRecap(tester, hote);
        await _cocherEtCreer(tester);
        expect(candidat.appels, isEmpty);
        expect(
          find.text(t.inscription.candidat.confidentialitePerimee),
          findsOneWidget,
        );
        expect(hote.chemin, Routes.inscriptionRecapitulatif);
      },
    );

    testWidgets(
      'invite, session non relue : « Reessayer » rejoue avec le code, '
      'jamais le champ du code',
      (WidgetTester tester) async {
        final FauxInscriptionCandidat candidat = FauxInscriptionCandidat(
          cleOuverte: false,
          codesValides: <String>{'ABCD-EFGH-JKMN'},
        );
        final _Hote hote = await _monter(
          tester,
          candidat: candidat,
          sessionImposee: _SessionQuiEchoue(1),
        );
        _conteneur(tester)
            .read(codeInvitationRetenuProvider.notifier)
            .retenir('ABCD-EFGH-JKMN');
        await _versLeRecap(tester, hote, sansCode: false);
        await _cocherEtCreer(tester);
        expect(hote.chemin, Routes.inscriptionRecapitulatif);
        expect(find.text(t.inscription.candidat.nonConfirmee), findsOneWidget);
        expect(
          _conteneur(tester).read(codeInvitationRetenuProvider),
          'ABCD-EFGH-JKMN',
        );
        await _taper(tester, find.text(t.inscription.reessayer));
        expect(hote.chemin, Routes.attente);
        expect(candidat.appels, hasLength(2));
        expect(candidat.appels.last.code, 'ABCD-EFGH-JKMN');
        expect(_conteneur(tester).read(codeInvitationRetenuProvider), isNull);
      },
    );

    testWidgets(
      'lot serveur absent : l\'invite garde l\'ancien chemin, avec son code',
      (WidgetTester tester) async {
        final FauxInscriptionCandidat candidat =
            FauxInscriptionCandidat(cleOuverte: false)
              ..panneInscription = const CapaciteIndisponible(
                dependanceInscriptionCandidat,
              );
        final _Hote hote = await _monter(tester, candidat: candidat);
        _conteneur(tester)
            .read(codeInvitationRetenuProvider.notifier)
            .retenir('ABCD-EFGH-JKMN');
        await _versLeRecap(tester, hote, sansCode: false);
        await _cocherEtCreer(tester);
        expect(hote.dossier.profilsCrees, hasLength(1));
        expect(hote.dossier.profilsCrees.single.role, AppRole.teacher);
        expect(hote.dossier.codesInvitation.single, 'ABCD-EFGH-JKMN');
        expect(hote.chemin, Routes.attente);
      },
    );

    testWidgets(
      'lot serveur absent et sans code : la phrase, aucun ancien chemin',
      (WidgetTester tester) async {
        final FauxInscriptionCandidat candidat = FauxInscriptionCandidat()
          ..panneInscription = const CapaciteIndisponible(
            dependanceInscriptionCandidat,
          );
        final _Hote hote = await _monter(tester, candidat: candidat);
        await _versLeRecap(tester, hote);
        await _cocherEtCreer(tester);
        expect(hote.dossier.profilsCrees, isEmpty);
        expect(find.text(t.inscription.candidat.indisponible), findsOneWidget);
      },
    );

    testWidgets('un depassement qui se leve : le meme geste cree le compte', (
      WidgetTester tester,
    ) async {
      final FauxInscriptionCandidat plafond = FauxInscriptionCandidat(
        plafond: 0,
      );
      final _Hote hote = await _monter(
        tester,
        candidat: plafond,
        compteExiste: () => plafond.creations.isNotEmpty,
      );
      await _versLeRecap(tester, hote);
      await _cocherEtCreer(tester);
      expect(hote.chemin, Routes.inscriptionRecapitulatif);
      plafond.plafond = 60;
      await _taper(tester, find.text(t.inscription.reessayer));
      expect(plafond.creations, hasLength(1));
      expect(hote.chemin, Routes.attente);
    });

    test('aucun texte du parcours ne dit qu\'une adresse ou un telephone est connu', () {
      final List<String> textes = <String>[
        t.inscription.candidat.creationEchec,
        t.inscription.candidat.horsLigne,
        t.inscription.candidat.courrielAConfirmer,
        t.inscription.candidat.nonOuverte,
        t.inscription.candidat.nonConfirmee,
        t.inscription.candidat.aCorriger(champs: 'Téléphone'),
        t.inscription.candidat.confidentialitePerimee,
        t.inscription.candidat.indisponible,
        t.inscription.telephone.explication,
        t.inscription.telephone.numeroInvalide,
        t.inscription.telephone.numeroManquant,
        t.inscription.telephone.indicatifManquant,
      ];
      for (final String texte in textes) {
        expect(
          texte.toLowerCase(),
          isNot(
            anyOf(
              contains('déjà'),
              contains('deja'),
              contains('existe'),
              contains('connu'),
              contains('doublon :'),
            ),
          ),
          reason: texte,
        );
      }
    });
  });

  group('lisibilite', () {
    testWidgets('le telephone a 320 px, texte x2, sans debordement', (
      WidgetTester tester,
    ) async {
      final _Hote hote = await _monter(
        tester,
        taille: const Size(320, 740),
        echelle: 2,
      );
      final BrouillonInscriptionControleur c = _conteneur(tester)
          .read(brouillonInscriptionProvider.notifier);
      c
        ..deposerSansCode()
        ..saisirIdentite(prenom: 'Amina', nom: 'Exemple')
        ..choisirGenre(Genre.femme);
      hote.routeur.go(Routes.inscriptionTelephone);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _taper(tester, find.byKey(TelephoneEtape.paysKey('FR')));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'le recapitulatif a 320 px, texte x2, en arabe, sans debordement',
      (WidgetTester tester) async {
        await _precharger(tester, garderArabe: true);
        final _Hote hote = await _monter(
          tester,
          taille: const Size(320, 740),
          echelle: 2,
        );
        await _versLeRecap(tester, hote);
        expect(tester.takeException(), isNull);
        expect(find.byKey(_carteArabe), findsOneWidget);
      },
    );

    testWidgets(
      'bureau 1440 : le recapitulatif tient dans une colonne bornee',
      (WidgetTester tester) async {
        final _Hote hote = await _monter(tester, taille: const Size(1440, 900));
        await _versLeRecap(tester, hote);
        expect(tester.takeException(), isNull);
        final Rect colonne = tester.getRect(
          find.byKey(const ValueKey<String>('page-etape-colonne')),
        );
        expect(colonne.width, lessThanOrEqualTo(560));
      },
    );
  });
}

/// Un port dont l'inscription attend qu'on la libere, pour surprendre un second
/// appui pendant que le premier est encore en vol.
class _PortLent extends FauxInscriptionCandidat {
  _PortLent(this._porte);

  final Future<void> _porte;

  /// Le nombre d'appels entres, avant meme que le serveur reponde.
  int entrees = 0;

  @override
  Future<ResultatInscriptionCandidat> inscrire({
    required String prenom,
    required String nom,
    required String genre,
    required String telephone,
    required String langue,
    required String versionConfidentialite,
    String? code,
  }) async {
    entrees++;
    await _porte;
    return super.inscrire(
      prenom: prenom,
      nom: nom,
      genre: genre,
      telephone: telephone,
      langue: langue,
      versionConfidentialite: versionConfidentialite,
      code: code,
    );
  }
}

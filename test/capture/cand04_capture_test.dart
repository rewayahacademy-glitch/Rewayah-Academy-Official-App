// Captures de CAND-04 (« Inscription sans code ») : chaque pas du parcours du
// candidat enseignant et chaque etat.
//
// Les pas : l'usage (entree sans code ouverte, puis fermee), le code
// d'invitation (avec l'entree sans code, puis apres un code non reconnu),
// l'identite, le genre, le telephone (les pays, l'erreur d'indicatif, la
// recherche, le numero, l'erreur de numero, le numero rempli), le
// recapitulatif (la langue, la case de confidentialite).
//
// Les etats du recapitulatif : case manquante, envoi en cours, echec, issue non
// confirmee, hors ligne, inscription sans code fermee (refus), courriel a
// confirmer, champ a corriger, indisponible, et la reponse neutre du plafond
// horaire (la session n'a pas de profil : la personne revient ici).
//
// 390x844 et 1440x900, clair et sombre, francais et arabe de droite a gauche.
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/candidature/port_inscription_candidat.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/recrutement_demo.dart';
import 'package:rewayah_academy/features/inscription/brouillon_inscription.dart';
import 'package:rewayah_academy/features/inscription/etapes/genre_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/identite_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/recapitulatif_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/telephone_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/usage_etape.dart';
import 'package:rewayah_academy/features/inscription/inscription_page.dart';
import 'package:rewayah_academy/features/juridique/textes_juridiques.dart';
import 'package:rewayah_academy/features/recrutement/invitation_candidat_page.dart';

import '../fixtures/candidature/faux_inscription_candidat.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

/// Ce que le scenario garde du parcours monte.
class _Hote {
  _Hote(this.candidat, this.routeur);

  final FauxInscriptionCandidat candidat;
  final GoRouter routeur;
}

/// Un port dont l'inscription ne repond jamais : l'envoi reste « en cours ».
class _PortSansReponse extends FauxInscriptionCandidat {
  @override
  Future<ResultatInscriptionCandidat> inscrire({
    required String prenom,
    required String nom,
    required String genre,
    required String telephone,
    required String langue,
    required String versionConfidentialite,
    String? code,
  }) => Completer<ResultatInscriptionCandidat>().future;
}

/// Monte le parcours dans le cadre de capture, sous le vrai theme.
Future<_Hote> _monter(
  WidgetTester tester, {
  required FauxInscriptionCandidat candidat,
  Size taille = _telephone,
  ThemeMode mode = ThemeMode.light,
  String depart = Routes.inscriptionUsage,
  bool horsLigne = false,
  bool Function()? compteExiste,
}) async {
  fixerVueCapture(tester, taille, 1);
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
        builder: (BuildContext _, GoRouterState etat) => InvitationCandidatPage(
          codeInitial: etat.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: Routes.attente,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Center(child: Text('ATTENTE'))),
      ),
      GoRoute(
        path: TexteJuridique.confidentialite.chemin,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Center(child: Text('POLITIQUE'))),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
        sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
        portInscriptionCandidatProvider.overrideWithValue(candidat),
        portVerificationInvitationProvider.overrideWithValue(InvitationsDemo()),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: mode,
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Hote(candidat, routeur);
}

ProviderContainer _conteneur(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Future<void> _continuer(WidgetTester tester) =>
    _taper(tester, find.text(t.commun.continuer));

/// Remplit le brouillon d'un candidat qui a tout renseigne sauf ce que le
/// scenario veut montrer.
void _brouillon(
  WidgetTester tester, {
  bool identite = true,
  bool genre = true,
  bool telephone = true,
  bool sansCode = true,
}) {
  final BrouillonInscriptionControleur c = _conteneur(tester)
      .read(brouillonInscriptionProvider.notifier);
  if (sansCode) {
    c.deposerSansCode();
  } else {
    c.choisirUsage(UsageInscription.enseignant);
  }
  if (identite) {
    c.saisirIdentite(prenom: 'Amina', nom: 'Exemple');
  }
  if (genre) {
    c.choisirGenre(Genre.femme);
  }
  if (telephone) {
    c.saisirTelephone(pays: 'FR', numero: '06 12 34 56 78');
  }
}

Future<void> _aller(WidgetTester tester, _Hote hote, String route) async {
  hote.routeur.go(route);
  await tester.pumpAndSettle();
}

Future<void> _cocherEtCreer(WidgetTester tester) async {
  await _taper(tester, find.byKey(const Key('inscription-confidentialite')));
  await _taper(tester, find.text(t.inscription.candidat.envoyer));
}

/// Remonte toutes les listes verticales en haut.
Future<void> _enHaut(WidgetTester tester) async {
  for (final Element e in find.byType(Scrollable).evaluate()) {
    final ScrollableState etat =
        (e as StatefulElement).state as ScrollableState;
    if (etat.position.axis == Axis.vertical) {
      etat.position.jumpTo(etat.position.minScrollExtent);
    }
  }
  await tester.pump();
}

/// Descend toutes les listes verticales jusqu'au bout.
Future<void> _enBas(WidgetTester tester) async {
  for (final Element e in find.byType(Scrollable).evaluate()) {
    final ScrollableState etat =
        (e as StatefulElement).state as ScrollableState;
    if (etat.position.axis == Axis.vertical) {
      etat.position.jumpTo(etat.position.maxScrollExtent);
    }
  }
  await tester.pump();
}

/// Un scenario : comment monter, comment arriver a l'etat, ce qu'on photographie.
class _Scenario {
  const _Scenario(
    this.nom,
    this.piloter, {
    this.candidat,
    this.horsLigne = false,
    this.plafond = false,
    this.bas = false,
    this.deux = false,
  });

  final String nom;
  final Future<void> Function(WidgetTester tester, _Hote hote) piloter;
  final FauxInscriptionCandidat Function()? candidat;
  final bool horsLigne;

  /// Vrai : la session n'a pas de profil apres la reponse (plafond atteint).
  final bool plafond;

  /// Vrai : photographier le bas de la page (les messages et le bouton).
  final bool bas;

  /// Vrai : photographier le haut ET le bas.
  final bool deux;
}

Future<void> _rien(WidgetTester tester, _Hote hote) async {}

Future<void> _vers(
  WidgetTester tester,
  _Hote hote,
  String route, {
  bool identite = true,
  bool genre = true,
  bool telephone = true,
}) async {
  _brouillon(tester, identite: identite, genre: genre, telephone: telephone);
  await _aller(tester, hote, route);
}

FauxInscriptionCandidat _ouvert() => FauxInscriptionCandidat();

final List<_Scenario> _pas = <_Scenario>[
  const _Scenario('01_usage_ouvert', _rien),
  _Scenario(
    '02_usage_ferme',
    _rien,
    candidat: () => FauxInscriptionCandidat(cleOuverte: false),
  ),
  _Scenario(
    '03_code_saisie',
    (WidgetTester tester, _Hote hote) =>
        _aller(tester, hote, Routes.inscriptionInvitation),
  ),
  _Scenario('04_code_non_reconnu', (WidgetTester tester, _Hote hote) async {
    await _aller(tester, hote, Routes.inscriptionInvitation);
    await tester.enterText(
      find.byKey(const ValueKey<String>('candidat-code')),
      'NIMPORTE',
    );
    await _taper(
      tester,
      find.byKey(const ValueKey<String>('candidat-verifier')),
    );
  }),
  _Scenario('05_identite', (WidgetTester tester, _Hote hote) async {
    _brouillon(tester, identite: false, genre: false, telephone: false);
    await _aller(tester, hote, Routes.inscriptionIdentite);
  }),
  _Scenario('06_genre', (WidgetTester tester, _Hote hote) async {
    _brouillon(tester, genre: false, telephone: false);
    await _aller(tester, hote, Routes.inscriptionGenre);
  }),
  _Scenario('07_telephone_pays', (WidgetTester tester, _Hote hote) async {
    _brouillon(tester, telephone: false);
    await _aller(tester, hote, Routes.inscriptionTelephone);
  }),
  _Scenario('09_telephone_recherche', (WidgetTester tester, _Hote hote) async {
    _brouillon(tester, telephone: false);
    await _aller(tester, hote, Routes.inscriptionTelephone);
    await _taper(
      tester,
      find.byKey(const ValueKey<String>('choix-recherche-autre')),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('choix-recherche-champ')),
      'ma',
    );
    await tester.pumpAndSettle();
  }),
  _Scenario('10_telephone_numero', (WidgetTester tester, _Hote hote) async {
    _brouillon(tester, telephone: false);
    await _aller(tester, hote, Routes.inscriptionTelephone);
    await _taper(tester, find.byKey(TelephoneEtape.paysKey('FR')));
  }),
  _Scenario('12_telephone_rempli', (WidgetTester tester, _Hote hote) async {
    _brouillon(tester, telephone: false);
    await _aller(tester, hote, Routes.inscriptionTelephone);
    await _taper(tester, find.byKey(TelephoneEtape.paysKey('FR')));
    await tester.enterText(
      find.byKey(TelephoneEtape.numeroKey),
      '06 12 34 56 78',
    );
    await tester.pumpAndSettle();
  }),
  _Scenario(
    '13_recapitulatif',
    (WidgetTester tester, _Hote hote) =>
        _vers(tester, hote, Routes.inscriptionRecapitulatif),
    deux: true,
  ),
];

final List<_Scenario> _etats = <_Scenario>[
  _Scenario('08_telephone_erreur_indicatif', (
    WidgetTester tester,
    _Hote hote,
  ) async {
    _brouillon(tester, telephone: false);
    await _aller(tester, hote, Routes.inscriptionTelephone);
    await _continuer(tester);
  }),
  _Scenario('11_telephone_erreur_numero', (
    WidgetTester tester,
    _Hote hote,
  ) async {
    _brouillon(tester, telephone: false);
    await _aller(tester, hote, Routes.inscriptionTelephone);
    await _taper(tester, find.byKey(TelephoneEtape.paysKey('FR')));
    await tester.enterText(find.byKey(TelephoneEtape.numeroKey), '06 12 ab');
    await _continuer(tester);
  }),
  _Scenario('14_recap_case_manquante', (WidgetTester tester, _Hote hote) async {
    await _vers(tester, hote, Routes.inscriptionRecapitulatif);
    await _taper(tester, find.text(t.inscription.candidat.envoyer));
  }, bas: true),
  _Scenario(
    '15_recap_envoi_en_cours',
    (WidgetTester tester, _Hote hote) async {
      await _vers(tester, hote, Routes.inscriptionRecapitulatif);
      await _taper(
        tester,
        find.byKey(const Key('inscription-confidentialite')),
      );
      await tester.tap(find.text(t.inscription.candidat.envoyer));
      await tester.pump(const Duration(milliseconds: 300));
    },
    candidat: _PortSansReponse.new,
    bas: true,
  ),
  _Scenario(
    '16_recap_echec',
    (WidgetTester tester, _Hote hote) async {
      await _vers(tester, hote, Routes.inscriptionRecapitulatif);
      await _cocherEtCreer(tester);
    },
    candidat: () =>
        FauxInscriptionCandidat()..panneInscription = StateError('x'),
    bas: true,
  ),
  _Scenario(
    '17_recap_non_confirme',
    (WidgetTester tester, _Hote hote) async {
      await _vers(tester, hote, Routes.inscriptionRecapitulatif);
      await _cocherEtCreer(tester);
    },
    candidat: () => FauxInscriptionCandidat()..panneInscription = panneReseau,
    bas: true,
  ),
  _Scenario(
    '18_recap_hors_ligne',
    (WidgetTester tester, _Hote hote) =>
        _vers(tester, hote, Routes.inscriptionRecapitulatif),
    horsLigne: true,
    bas: true,
  ),
  _Scenario(
    '19_recap_refus_ferme',
    (WidgetTester tester, _Hote hote) async {
      await _vers(tester, hote, Routes.inscriptionRecapitulatif);
      await _cocherEtCreer(tester);
    },
    candidat: () => FauxInscriptionCandidat(cleOuverte: false),
    bas: true,
  ),
  _Scenario(
    '20_recap_courriel_a_confirmer',
    (WidgetTester tester, _Hote hote) async {
      await _vers(tester, hote, Routes.inscriptionRecapitulatif);
      await _cocherEtCreer(tester);
    },
    candidat: () => FauxInscriptionCandidat()..courrielConfirme = false,
    bas: true,
  ),
  _Scenario(
    '21_recap_champs_a_corriger',
    (WidgetTester tester, _Hote hote) async {
      await _vers(tester, hote, Routes.inscriptionRecapitulatif);
      await _cocherEtCreer(tester);
    },
    candidat: () =>
        FauxInscriptionCandidat()
          ..reponseImposee = const InscriptionInvalide(<String>['telephone']),
    bas: true,
  ),
  _Scenario(
    '22_recap_plafond_neutre',
    (WidgetTester tester, _Hote hote) async {
      await _vers(tester, hote, Routes.inscriptionRecapitulatif);
      await _cocherEtCreer(tester);
    },
    candidat: () => FauxInscriptionCandidat(plafond: 0),
    plafond: true,
    bas: true,
  ),
  _Scenario(
    '23_recap_indisponible',
    (WidgetTester tester, _Hote hote) async {
      await _vers(tester, hote, Routes.inscriptionRecapitulatif);
      await _cocherEtCreer(tester);
    },
    candidat: () =>
        FauxInscriptionCandidat()..panneInscription = panneLotAbsent,
    bas: true,
  ),
];

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  Future<void> photographier(
    WidgetTester tester,
    _Scenario s, {
    required Size taille,
    required ThemeMode mode,
    required bool arabe,
  }) async {
    if (arabe) {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    }
    final FauxInscriptionCandidat candidat = s.candidat?.call() ?? _ouvert();
    final _Hote hote = await _monter(
      tester,
      candidat: candidat,
      taille: taille,
      mode: mode,
      horsLigne: s.horsLigne,
      compteExiste: s.plafond ? () => candidat.creations.isNotEmpty : null,
    );
    await s.piloter(tester, hote);
    final String suffixe =
        '${taille.width.toInt()}_${mode == ThemeMode.dark ? 'sombre' : 'clair'}'
        '_${arabe ? 'ar' : 'fr'}';
    if (!s.bas || s.deux) {
      await _enHaut(tester);
      await capturer(tester, '${s.nom}${s.deux ? '_haut' : ''}_$suffixe');
    }
    if (s.bas || s.deux) {
      await _enBas(tester);
      await capturer(tester, '${s.nom}${s.deux ? '_bas' : ''}_$suffixe');
    }
  }

  group('CAND-04 : captures des pas', skip: sautSansCapture, () {
    for (final _Scenario s in _pas) {
      for (final (Size taille, ThemeMode mode, bool arabe)
          in <(Size, ThemeMode, bool)>[
            (_telephone, ThemeMode.light, false),
            (_telephone, ThemeMode.dark, false),
            (_bureau, ThemeMode.light, false),
            (_bureau, ThemeMode.dark, false),
            (_telephone, ThemeMode.light, true),
            (_telephone, ThemeMode.dark, true),
            (_bureau, ThemeMode.light, true),
          ]) {
        testWidgets(
          '${s.nom} ${taille.width.toInt()} ${mode.name} ${arabe ? 'ar' : 'fr'}',
          (WidgetTester tester) => photographier(
            tester,
            s,
            taille: taille,
            mode: mode,
            arabe: arabe,
          ),
        );
      }
    }
  });

  group('CAND-04 : captures des etats', skip: sautSansCapture, () {
    for (final _Scenario s in _etats) {
      for (final (Size taille, ThemeMode mode, bool arabe)
          in <(Size, ThemeMode, bool)>[
            (_telephone, ThemeMode.light, false),
            (_telephone, ThemeMode.dark, false),
            (_bureau, ThemeMode.light, false),
            (_telephone, ThemeMode.light, true),
          ]) {
        testWidgets(
          '${s.nom} ${taille.width.toInt()} ${mode.name} ${arabe ? 'ar' : 'fr'}',
          (WidgetTester tester) => photographier(
            tester,
            s,
            taille: taille,
            mode: mode,
            arabe: arabe,
          ),
        );
      }
    }
  });
}

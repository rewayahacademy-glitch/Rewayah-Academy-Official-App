// RTL-ISOL-1 : valeurs et phrases francaises dans l'interface arabe (RTL),
// relevees par les relectures du lot 4.
//
// 1. Espace Classe de demonstration : la duree avant le cours (« الدرس بعد
//    3 h 28 », jamais « h 28 3 ») et la ligne des eleves (« Niveau 1 ·
//    الاستئناف: Page 24 », chaque segment isole) ; le conseil d'appareil de
//    l'accueil famille (« ... pris en charge. », jamais « .téléphone »).
// 2. `EmptyState` partage : le constat et l'invitation (« ... ouverts à
//    l'enseignant. » sur la fiche de seance, jamais « .l'enseignant »).
// 3. « A propos de cette classe » (« ... règles de tajwid. ») et
//    l'introduction de Comptes (« ... qui le montre. »).
// 4. Observation du Controleur (reserve 3 de COUPE-MOTS-3b) : valeurs
//    Nature et Domaine, explication, message d'echec.
//
// Mesure par la position des glyphes rendus (`getBoxesForSelection`), en
// francais (LTR) comme en arabe (RTL), a 320 px et texte x2. Quand l'ordre
// visuel d'une valeur seule ne change pas (« À suivre »), le texte rendu
// doit porter l'isolat en arabe et rester nu en francais.
//
// Contre-epreuve : sur l'ancien code (5a52ff30), les cas arabes 1 a 3
// echouent ; ceux du point 4 echouent des qu'on retire l'isolat de la valeur
// visee dans `observation_controle_page.dart`.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/features/accueil_famille/bloc_seance.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/tc_classe_live/fiche_seance.dart';

import '../capture/outil_capture.dart';
import '../support/harnais.dart';
import '../teaching_core/e/faux/faux_classe.dart';
import '../teaching_core/e/support/hote_classe.dart';

const String _fsi = '\u2068';
const String _pdi = '\u2069';

class _Comptes implements ServiceComptes {
  @override
  Future<List<CompteAdmin>> comptes() async => <CompteAdmin>[
    CompteAdmin(
      profilId: 'GUARDIAN-FB-000003',
      identifiant: 'GUARDIAN-FB-000003',
      prenom: 'Fatoumata',
      nom: 'Diallo',
      role: AppRole.guardian,
      etat: AccountStatus.active,
      inscritLe: DateTime(2026, 9, 1),
      accesJusquAu: null,
      foyerId: null,
      piece: EtatPiece.validee,
      contrats: 1,
      aEnseignant: true,
      enfantsDuFoyer: 2,
    ),
  ];
}

/// Monte [routes] a [adresse], a 320 px et texte x2, dans la locale
/// [langue] (l'arabe donne le sens RTL).
Future<void> _monterRoutes(
  WidgetTester tester,
  AppLocale langue,
  String adresse,
  List<RouteBase> routes, {
  double hauteur = 6400,
}) async {
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  fixerVueCapture(tester, Size(320, hauteur), 1);
  final GoRouter routeur = GoRouter(initialLocation: adresse, routes: routes);
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: Builder(
          builder: (BuildContext context) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (BuildContext c, Widget? app) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: app!,
            ),
            routerConfig: routeur,
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

/// Monte [ecran] seul, sous un routeur, a 320 px et texte x2.
Future<void> _monter(
  WidgetTester tester,
  AppLocale langue,
  Widget Function() ecran, {
  double hauteur = 2400,
}) => _monterRoutes(tester, langue, '/', <RouteBase>[
  GoRoute(path: '/', builder: (BuildContext _, GoRouterState _) => ecran()),
], hauteur: hauteur);

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Les paragraphes rendus dont le texte contient [marque].
List<RenderParagraph> _paragraphes(WidgetTester tester, String marque) =>
    <RenderParagraph>{
      for (final RenderParagraph p
          in tester.allRenderObjects.whereType<RenderParagraph>())
        if (p.attached && p.text.toPlainText().contains(marque)) p,
    }.toList();

/// Le paragraphe rendu dont le texte contient [marque] (un seul).
RenderParagraph _paragraphe(WidgetTester tester, String marque) {
  final List<RenderParagraph> trouves = _paragraphes(tester, marque);
  expect(trouves, hasLength(1), reason: 'Paragraphe « $marque »');
  return trouves.single;
}

/// La boite rendue du dernier [extrait] de [p].
TextBox _boite(RenderParagraph p, String extrait) {
  final String texte = p.text.toPlainText();
  final int debut = texte.lastIndexOf(extrait);
  expect(debut, isNonNegative, reason: '« $extrait » dans « $texte »');
  final List<TextBox> boites = p.getBoxesForSelection(
    TextSelection(baseOffset: debut, extentOffset: debut + extrait.length),
  );
  expect(boites, isNotEmpty);
  return boites.first;
}

/// Echoue si [suivant] ne s'affiche pas apres [precedent] dans le sens de
/// lecture [sens] (a droite en LTR, a gauche en RTL, ou sur une ligne plus
/// bas) dans le paragraphe [p].
void _suit(
  RenderParagraph p, {
  required String precedent,
  required String suivant,
  TextDirection sens = TextDirection.ltr,
}) {
  final TextBox avant = _boite(p, precedent);
  final TextBox apres = _boite(p, suivant);
  // Les glyphes arabes ont des boites plus hautes que les latins : deux
  // boites sont sur la meme ligne quand le milieu de l'une tombe dans
  // l'autre ; sinon, la suivante est sur une ligne plus basse.
  final double milieuAvant = (avant.top + avant.bottom) / 2;
  final double milieuApres = (apres.top + apres.bottom) / 2;
  final bool memeLigne =
      (milieuAvant >= apres.top && milieuAvant <= apres.bottom) ||
      (milieuApres >= avant.top && milieuApres <= avant.bottom);
  final bool dansLOrdre = !memeLigne
      ? milieuApres > milieuAvant
      : sens == TextDirection.ltr
      ? apres.left >= avant.right - 1
      : apres.right <= avant.left + 1;
  expect(
    dansLOrdre,
    isTrue,
    reason:
        '« $suivant » doit suivre « $precedent » (${sens.name}) dans '
        '« ${p.text.toPlainText()} » : $avant / $apres',
  );
}

/// Une phrase francaise se lit de gauche a droite, quelle que soit
/// l'interface : [suivant] apres [precedent] dans le paragraphe [marque].
void _aDroiteDe(
  WidgetTester tester, {
  required String marque,
  required String precedent,
  required String suivant,
}) =>
    _suit(_paragraphe(tester, marque), precedent: precedent, suivant: suivant);

/// L'observation du Controleur, a l'etape 1 (nature).
Future<void> _monterObservation(WidgetTester tester, AppLocale langue) async {
  final CompteRenduEnSuspens visite = CompteRenduEnSuspens(
    seanceId: 'seance-A',
    classe: 'Classe Al-Fajr',
    debut: DateTime(2026, 9, 28, 16),
  );
  await _monter(
    tester,
    langue,
    () => ProviderScope(
      overrides: <Override>[
        visitesObserveesProvider.overrideWith(
          () => VisitesObservees(<String, CompteRenduEnSuspens>{
            visite.seanceId: visite,
          }),
        ),
        rosterControleProvider.overrideWith(
          (Ref _) async => const <EleveRoster>[
            EleveRoster(id: 'e1', prenom: 'Mariam', initialeNom: 'S'),
          ],
        ),
      ],
      child: ObservationControlePage(seanceId: visite.seanceId),
    ),
    hauteur: 1400,
  );
  await tester.pumpAndSettle();
}

/// De l'etape 1 au recapitulatif (etape 5), « Classe entiere ».
Future<void> _jusquAuRecapitulatif(WidgetTester tester) async {
  await _toucher(
    tester,
    find.byKey(ObservationControlePage.cleNature(NatureObservation.aSuivre)),
  );
  await _toucher(tester, find.text(t.commun.continuer).last);
  await _toucher(
    tester,
    find.byKey(
      ObservationControlePage.cleDomaine(DomaineObservation.pedagogie),
    ),
  );
  await _toucher(tester, find.text(t.commun.continuer).last);
  await _toucher(
    tester,
    find.byKey(
      ObservationControlePage.clePersonne(PersonneConcernee.classeEntiere),
    ),
  );
  await _toucher(tester, find.text(t.commun.continuer).last);
  await _toucher(tester, find.text(t.commun.continuer).last);
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  test('phraseAvecValeur : seule une valeur de l autre sens est isolee', () {
    String ar(String d) => 'الدرس بعد $d';
    String fr(String d) => 'Cours dans $d';
    expect(phraseAvecValeur(ar, '3 h 28'), 'الدرس بعد ${_fsi}3 h 28$_pdi');
    expect(phraseAvecValeur(fr, '3 h 28'), 'Cours dans 3 h 28');
    expect(phraseAvecValeur(ar, '45'), 'الدرس بعد 45');
    expect(phraseAvecValeur((String v) => '$v · 2', 'Page'), 'Page · 2');
  });

  for (final AppLocale langue in AppLocale.values) {
    final String cas = '320 px x2, ${langue.languageCode}';
    final bool arabe = langue == AppLocale.ar;

    // Reprise de la relecture : les variantes « salle ouverte » et
    // « attente » (vouvoiement et tutoiement) passent aussi par
    // phraseAvecValeur.
    EmplacementEntree entree(
      Duration avantT0, {
      bool connecte = false,
      bool tutoiement = false,
    }) {
      LocaleSettings.setLocaleSync(langue);
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      return EmplacementEntree.pour(
        role: RoleEntree.eleve,
        horloge: SessionClockVM.depuisFenetre(
          fenetre: DonneesClasseDemo.fenetre,
          maintenantServeurUtc: DonneesClasseDemo.debutUtc.subtract(avantT0),
          horlogeUtilisateur: DonneesClasseDemo.horlogeUtilisateur,
          connecte: connecte,
        ),
        nomClasse: DonneesClasseDemo.classe,
        tutoiement: tutoiement,
      );
    }

    /// La duree « 8 min » de [detail] : isolee dans une phrase arabe, nue
    /// dans une phrase francaise.
    void dureeIsoleeSiArabe(String detail, {required bool phraseArabe}) {
      final RegExp isolee = RegExp('$_fsi\\d+\\s*min$_pdi');
      if (phraseArabe) {
        expect(detail, matches(isolee), reason: detail);
      } else {
        expect(detail, isNot(contains(_fsi)), reason: detail);
        expect(detail, matches(RegExp(r'\d+\s*min')), reason: detail);
      }
    }

    test('Salle ouverte : la duree est isolee dans la phrase arabe ($cas)', () {
      final EmplacementEntree e = entree(const Duration(minutes: 8));
      expect(e.etat, EtatEntree.fenetreOuverte);
      dureeIsoleeSiArabe(e.detail!, phraseArabe: arabe);
    });

    test('Attente (vouvoiement puis tutoiement) : la duree est isolee dans '
        'une phrase arabe, nue dans une phrase francaise ($cas)', () {
      final EmplacementEntree vous = entree(
        const Duration(minutes: 8),
        connecte: true,
      );
      expect(vous.etat, EtatEntree.attente);
      dureeIsoleeSiArabe(vous.detail!, phraseArabe: arabe);
      // Le tutoiement n'a pas encore de traduction arabe : sa phrase reste
      // francaise, la duree francaise s'y lit sans isolat, dans les deux
      // interfaces.
      final EmplacementEntree tu = entree(
        const Duration(minutes: 8),
        connecte: true,
        tutoiement: true,
      );
      expect(tu.etat, EtatEntree.attente);
      final bool tuArabe = sensDuTexte(tu.detail!) == TextDirection.rtl;
      dureeIsoleeSiArabe(tu.detail!, phraseArabe: tuArabe);
    });

    testWidgets('EmptyState : le constat et l invitation gardent leur point, '
        'leur texte reste nu ($cas)', (WidgetTester tester) async {
      const String constat = 'Aucun support pour cette séance.';
      const String invitation = "Les supports s'ouvrent à l'enseignant.";
      await _monter(
        tester,
        langue,
        () => const Scaffold(
          body: EmptyState(
            message: constat,
            invitation: invitation,
            registre: RegistreVide.subi,
          ),
        ),
      );
      // Le texte n'est pas modifie : il se retrouve tel quel.
      expect(find.text(constat), findsOneWidget);
      expect(find.text(invitation), findsOneWidget);
      _aDroiteDe(tester, marque: 'Aucun', precedent: 'séance', suivant: '.');
      _aDroiteDe(
        tester,
        marque: 'ouvrent',
        precedent: 'enseignant',
        suivant: '.',
      );
    });

    testWidgets('Ma classe : la ligne de progression est isolee en arabe '
        '($cas)', (WidgetTester tester) async {
      await _monterRoutes(
        tester,
        langue,
        adresseDemoAdulte(EcranDemoAdulte.maClasse),
        routesDemoAdulte('dev'),
      );
      final String ligne = DonneesAdulteDemo.ligneProgressionClasse;
      expect(ligne, 'Chapitre 1 · Page 24');
      final RenderParagraph p = _paragraphe(tester, ligne);
      // L'ordre visuel d'une ligne toute latine ne change pas : le texte
      // rendu porte l'isolat en arabe, et reste nu en francais.
      expect(p.text.toPlainText(), arabe ? isolerSens(ligne) : ligne);
      _suit(p, precedent: 'Chapitre', suivant: '1');
      _suit(p, precedent: '1', suivant: '·');
      _suit(p, precedent: '·', suivant: 'Page');
      _suit(p, precedent: 'Page', suivant: '24');
    });

    testWidgets('Espace Classe eleve : la duree avant le cours se lit dans '
        'l ordre ($cas)', (WidgetTester tester) async {
      await _monterRoutes(
        tester,
        langue,
        adresseDemoClasse(RoleEntree.eleve, EtatDemoClasse.aVenir),
        routesDemoClasse('dev'),
      );
      final String debut = t.classe.entree.coursDans(duree: '').trim();
      final RenderParagraph p = _paragraphe(tester, debut);
      final RegExpMatch? duree = RegExp(r'(\d+)\s*h\s*(\d+)')
          .firstMatch(p.text.toPlainText());
      expect(duree, isNotNull, reason: p.text.toPlainText());
      // « 3 h 28 » se lit de gauche a droite, meme dans la phrase arabe.
      _suit(p, precedent: duree!.group(1)!, suivant: 'h');
      _suit(p, precedent: 'h', suivant: duree.group(2)!);
      // Et la duree suit le debut de la phrase dans le sens de l'interface.
      _suit(
        p,
        precedent: debut.split(' ').last,
        suivant: duree.group(1)!,
        sens: arabe ? TextDirection.rtl : TextDirection.ltr,
      );
    });

    testWidgets('Espace Classe enseignant : la ligne des eleves isole chaque '
        'segment ($cas)', (WidgetTester tester) async {
      await _monterRoutes(
        tester,
        langue,
        adresseDemoClasse(RoleEntree.enseignant, EtatDemoClasse.aVenir),
        routesDemoClasse('dev'),
      );
      final List<RenderParagraph> lignes = <RenderParagraph>[
        for (final RenderParagraph p in _paragraphes(tester, 'Page 24'))
          if (p.text.toPlainText().contains('Niveau')) p,
      ];
      expect(lignes, isNotEmpty);
      final RenderParagraph p = lignes.first;
      final String texte = p.text.toPlainText();
      final String reprise = t.enseignant.ficheGroupe.repriseEleve(
        page: arabe ? '${_fsi}Page 24$_pdi' : 'Page 24',
      );
      // Le niveau et la page, donnees francaises, sont isoles en arabe ; en
      // francais, la ligne reste nue.
      expect(
        texte,
        arabe ? '${_fsi}Niveau 1$_pdi · $reprise' : 'Niveau 1 · $reprise',
      );
      _suit(p, precedent: 'Page', suivant: '24');
      _suit(p, precedent: 'Niveau', suivant: '1');
      // Le separateur suit le sens de l'interface : le niveau d'abord.
      _suit(
        p,
        precedent: '1',
        suivant: '·',
        sens: arabe ? TextDirection.rtl : TextDirection.ltr,
      );
    });

    testWidgets('Accueil famille : le conseil d appareil garde son point '
        '($cas)', (WidgetTester tester) async {
      await _monter(
        tester,
        langue,
        () => const Scaffold(body: ConseilAppareil()),
      );
      _aDroiteDe(tester, marque: 'Tablette', precedent: 'charge', suivant: '.');
    });

    testWidgets('EmptyState de la fiche de seance : le point reste en fin de '
        'phrase ($cas)', (WidgetTester tester) async {
      const TeacherStudentProjection fiche = TeacherStudentProjection(
        firstName: 'Ilyas',
        academyId: 'RA-CD0044',
        liveStatus: EtatPresenceProjete.present,
        interfaceGuidee: false,
      );
      await _monter(
        tester,
        langue,
        () => ProviderScope(
          overrides: surchargesClasse(
            moteur: FauxMoteurClasse(),
            video: FauxServiceVideoClasse(),
            preVol: FauxPreVolClasse(),
            rappel: FauxRappelDiscret(),
          ),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: FicheSeance(eleve: fiche, sessionId: 's1'),
            ),
          ),
        ),
      );
      expect(t.tc.classe.fiche.sansPedagogieDetail, endsWith("l'enseignant."));
      _aDroiteDe(
        tester,
        marque: 'ouverts',
        precedent: 'enseignant',
        suivant: '.',
      );
    });

    testWidgets('Ma classe : « A propos » garde son point ($cas)', (
      WidgetTester tester,
    ) async {
      await _monterRoutes(
        tester,
        langue,
        adresseDemoAdulte(EcranDemoAdulte.maClasse),
        routesDemoAdulte('dev'),
      );
      _aDroiteDe(tester, marque: 'tajwid', precedent: 'tajwid', suivant: '.');
    });

    testWidgets('Comptes : l introduction garde son point ($cas)', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        langue,
        () => ProviderScope(
          overrides: <Override>[
            serviceComptesProvider.overrideWithValue(_Comptes()),
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
          child: const ComptesPage(),
        ),
      );
      final String intro = t.admin.comptes.intro;
      expect(intro, endsWith('.'));
      final String dernier = intro
          .substring(0, intro.length - 1)
          .split(' ')
          .last;
      _aDroiteDe(
        tester,
        marque: intro.split(' ').take(3).join(' '),
        precedent: dernier,
        suivant: '.',
      );
    });

    testWidgets('Observation : l explication garde son point ($cas)', (
      WidgetTester tester,
    ) async {
      await _monterObservation(tester, langue);
      final String contexte = t.controleur.observation.contexteNature;
      expect(contexte, endsWith("l'administration."));
      _aDroiteDe(
        tester,
        marque: 'transmis',
        precedent: 'administration',
        suivant: '.',
      );
    });

    testWidgets('Observation : les valeurs Nature et Domaine sont isolees en '
        'arabe ($cas)', (WidgetTester tester) async {
      await _monterObservation(tester, langue);
      await _jusquAuRecapitulatif(tester);
      for (final String valeur in <String>[
        ObservationControlePage.libelleNature(NatureObservation.aSuivre),
        ObservationControlePage.libelleDomaine(DomaineObservation.pedagogie),
      ]) {
        final RenderParagraph p = _paragraphe(tester, valeur);
        expect(
          p.text.toPlainText(),
          arabe ? isolerSens(valeur) : valeur,
          reason: 'Valeur « $valeur »',
        );
      }
    });

    testWidgets('Observation : le message d echec garde son point ($cas)', (
      WidgetTester tester,
    ) async {
      await _monterObservation(tester, langue);
      await _jusquAuRecapitulatif(tester);
      // Le port par defaut n'a aucun serveur : l'envoi echoue.
      await _toucher(tester, find.text(t.controleur.compteRendu.envoyer).last);
      final String echec = t.controleur.observation.echec;
      expect(echec, endsWith("l'administration."));
      final RenderParagraph p = _paragraphe(tester, 'parvenu');
      expect(p.text.toPlainText(), arabe ? isolerSens(echec) : echec);
      _suit(p, precedent: 'administration', suivant: '.');
    });
  }
}

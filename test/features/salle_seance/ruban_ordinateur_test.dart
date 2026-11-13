// RUBAN-ORDINATEUR (directeur, 11/11/2026 ; regle :
// docs/current/salle/MODES-AFFICHAGE.md §4 et §5) : le ruban de l'enseignant
// sur ordinateur, les passages d'un mode a l'autre, la tete des panneaux et
// l'ile dans la colonne.
//
// - mode Classe : les cartes du panneau n'ont pas d'image vivante (les
//   visages sont dans la grille) ; mode Document : elles l'ont, le recitant
//   en premier et plus grand ; une personne n'est jamais deux fois a l'ecran ;
// - passage : depart, arrivee, interrompu a mi-course, mouvement reduit ;
// - la tete des Eleves et celle de la Bibliotheque : meme hauteur, titre au
//   debut, croix a la fin ;
// - l'ile repliee tient dans la colonne avec tous ses signes.
//
// Captures (CAPTURE_DIR) : docs/current/captures/E2E/ruban-ordinateur/.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope, Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/mouvement/passage_scene.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_classe/roster_classe_vm.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/cadre_visage.dart';
import 'package:rewayah_academy/core/widgets/tete_panneau.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/dynamique_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/salle_ordinateur.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart'
    show TelephonePleinEcran, margeFlechePage;
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_mushaf/page_madina_15.dart'
    show ratioHauteurPageMadina15;

import '../../capture/outil_capture.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../../support/mushaf_15l.dart'
    show chargerPoliceMadina15, surchargesMadina15;
import '../../teaching_core/e/faux/faux_classe.dart';

AccesSalle _acces() => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: 'teacher',
  capacites: const CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: true,
    peutPublierDonnees: true,
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

ParticipantSalle _personne(String id, String role, {bool local = false}) =>
    ParticipantSalle(
      identite: id,
      nom: '',
      role: role,
      estLocal: local,
      micro: false,
      camera: true,
      parle: false,
      qualite: QualiteLien.bonne,
    );

PresenceParticipant _ligne(String id, String prenom, String role) =>
    PresenceParticipant(
      seanceId: 's1',
      profilId: id,
      role: role,
      prenom: prenom,
      identifiantImmuable: 'RA-26-$id',
      etat: EtatPresence.presente,
      consolide: false,
      entreLe: DateTime.now(),
    );

List<Override> _surcharges(FauxMoteurSalle moteur) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      const SessionState(
        resolue: true,
        role: AppRole.teacher,
        profileId: 't1',
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
  serviceVideoProvider.overrideWithValue(FauxServiceVideo(acces0: _acces())),
  moteurSalleProvider.overrideWithValue(moteur),
  servicePresenceProvider.overrideWithValue(
    FauxServicePresence(
      lignes: <PresenceParticipant>[
        _ligne('t1', 'Amina', 'teacher'),
        _ligne('e1', 'Yasmine', 'student'),
        _ligne('e2', 'Ilyes', 'student'),
      ],
    ),
  ),
  portAnnonceObservationEnfantProvider.overrideWithValue(
    FauxAnnonceObservationEnfant(observe: false),
  ),
  portAnnonceObservationProvider.overrideWithValue(
    FauxAnnonceObservation(lignes: const <AnnonceObservation>[]),
  ),
  ...surchargesMadina15(page: 42),
  pageCoranProvider.overrideWith(
    (Ref _, int n) async => PageCoran(
      numero: n,
      versets: <VersetCoran>[
        VersetCoran(
          sourateNumero: 2,
          numero: 255,
          texte: 'verset',
          pageNumero: n,
        ),
      ],
    ),
  ),
];

/// Monte la salle de l'enseignant a 1440 x 900, trois cameras allumees, sans
/// rien presenter (mode Classe).
Future<FauxMoteurSalle> _monter(
  WidgetTester tester, {
  ThemeMode theme = ThemeMode.light,
  Size taille = const Size(1440, 900),
}) async {
  fixerVueCapture(tester, taille, 1);
  final FauxMoteurSalle moteur = FauxMoteurSalle()
    ..avecImage.addAll(<String>{'t1', 'e1', 'e2'});
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: _surcharges(moteur),
      themeMode: theme,
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(<ParticipantSalle>[
    _personne('t1', 'teacher', local: true),
    _personne('e1', 'student'),
    _personne('e2', 'student'),
  ]);
  await tester.pumpAndSettle();
  return moteur;
}

Future<void> _presenter(WidgetTester tester, FauxMoteurSalle moteur) async {
  await moteur.presenterContenu(
    ContenuPresente(
      page: 42,
      sourate: 2,
      verset: 255,
      presentePar: 't1',
      emisLe: DateTime.now(),
    ),
  );
  await tester.pumpAndSettle();
}

final Finder _images = find.byKey(const Key('image-video'));
final Finder _panneau = find.byKey(
  const ValueKey<String>('salle-ordinateur-eleves'),
);

void _rien() {}
void _eleve(EleveSeance _) {}

const ActionsSeance _actions = ActionsSeance(
  onRappeler: _eleve,
  onChoisirPourReciter: _eleve,
  onNoter: _eleve,
  onSignaler: _eleve,
  onEleves: _rien,
);

const List<EleveSeance> _eleves = <EleveSeance>[
  EleveSeance(
    prenom: 'Yasmine',
    statut: StatutEleveSeance.connecte,
    id: 'RA-1',
    profilId: 'e1',
    microOuvert: true,
  ),
  EleveSeance(
    prenom: 'Ilyes',
    statut: StatutEleveSeance.connecte,
    id: 'RA-2',
    profilId: 'e2',
    fiche: FicheEleveSeance(
      niveau: 'Niveau 2',
      objectifActuel: '',
      derniereSeance: '',
      aReprendre: '',
      presenceRecente: '',
      travailActuel: '',
    ),
  ),
  EleveSeance(
    prenom: 'Sami',
    statut: StatutEleveSeance.pasEncoreConnecte,
    id: 'RA-3',
    profilId: 'e3',
  ),
];

Future<void> _panneauSeul(
  WidgetTester tester, {
  VisagesPanneau? visages,
  FileRecitation? recitation,
}) async {
  fixerVueCapture(tester, const Size(1440, 900), 1);
  await tester.pumpWidget(
    hoteCapture(
      Center(
        child: SizedBox(
          width: largeurPanneauGauche - 24,
          height: 860,
          child: PanneauEleves(
            eleves: _eleves,
            actions: _actions,
            large: true,
            recitation: recitation,
            visages: visages,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget? _image(String id) =>
    id == 'e3' ? null : SizedBox.expand(key: ValueKey<String>('img-$id'));

void main() {
  setUpAll(() async {
    if (dossierCapture == null) return;
    await chargerPolicesDuDepot();
    await chargerPoliceMadina15();
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('le panneau seul', () {
    testWidgets('sans visages (mode Classe) : l initiale, aucune image, '
        'l ordre ne change pas', (WidgetTester tester) async {
      await _panneauSeul(
        tester,
        recitation: const FileRecitation(actif: 'RA-2'),
      );
      expect(find.byType(CadreVisage), findsNothing);
      expect(find.byKey(const ValueKey<String>('img-e1')), findsNothing);
      // L'ordre de la vue : Yasmine, puis Ilyes (qui recite).
      expect(
        tester.getTopLeft(find.byKey(const ValueKey<String>('eleve-RA-1'))).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey<String>('eleve-RA-2')))
              .dy,
        ),
      );
    });

    testWidgets('avec visages (mode Document) : un cadre vivant par eleve dans '
        'la salle ; le recitant en premier, son cadre en grand ; les gestes '
        'restent', (WidgetTester tester) async {
      await _panneauSeul(
        tester,
        visages: const VisagesPanneau(image: _image),
        recitation: const FileRecitation(actif: 'RA-2'),
      );
      expect(tester.takeException(), isNull);
      // Deux eleves dans la salle : deux cadres ; l'absent garde son
      // initiale (aucune image a montrer).
      expect(find.byType(CadreVisage), findsNWidgets(2));
      expect(find.byKey(const ValueKey<String>('img-e1')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('img-e2')), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('cadre-ruban-RA-3')),
        findsNothing,
      );
      // Le recitant en premier.
      expect(
        tester.getTopLeft(find.byKey(const ValueKey<String>('eleve-RA-2'))).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey<String>('eleve-RA-1')))
              .dy,
        ),
      );
      // Son cadre est le plus grand, a la largeur de la carte, en 4/3.
      final Size grand = tester.getSize(
        find.byKey(const ValueKey<String>('cadre-ruban-RA-2')),
      );
      final Size petit = tester.getSize(
        find.byKey(const ValueKey<String>('cadre-ruban-RA-1')),
      );
      expect(grand.width, greaterThan(2 * petit.width));
      expect(grand.width / grand.height, closeTo(4 / 3, 0.01));
      expect(petit.width / petit.height, closeTo(4 / 3, 0.01));
      expect(petit.width, largeurCadreRuban);
      // Le micro ferme d'Ilyes se lit sur son cadre ; Yasmine l'a ouvert.
      final CadreVisage ilyes = tester.widget<CadreVisage>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('cadre-ruban-RA-2')),
          matching: find.byType(CadreVisage),
        ),
      );
      expect(ilyes.microCoupe, isTrue);
      expect(ilyes.recite, isTrue);
      // Les gestes de la carte depliee sont toujours la (Terminer la
      // recitation, Appeler), et le nom se lit une seule fois.
      expect(find.text(t.salle.gestes.terminerRecitation), findsOneWidget);
      expect(find.text(t.salle.seance.rappeler), findsWidgets);
      expect(find.text('Ilyes'), findsWidgets);
      verifierAucuneCarteCollee(
        tester,
        estCarte: (Widget w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('eleve-'),
      );
    });

    testWidgets('la parole allume l anneau du seul cadre qui parle', (
      WidgetTester tester,
    ) async {
      final Map<String, ValueNotifier<bool>> paroles =
          <String, ValueNotifier<bool>>{};
      Stream<bool> parle(String id) {
        final ValueNotifier<bool> n = paroles.putIfAbsent(
          id,
          () => ValueNotifier<bool>(false),
        );
        // ignore: close_sinks, ferme par son seul abonne.
        late final StreamController<bool> c;
        void relayer() => c.add(n.value);
        c = StreamController<bool>(
          onListen: () => n.addListener(relayer),
          onCancel: () => n.removeListener(relayer),
        );
        return c.stream;
      }

      await _panneauSeul(
        tester,
        visages: VisagesPanneau(image: _image, parle: parle),
      );
      paroles['e1']!.value = true;
      await tester.pumpAndSettle();
      final List<CadreVisage> cadres = tester
          .widgetList<CadreVisage>(find.byType(CadreVisage))
          .toList();
      expect(cadres.where((CadreVisage c) => c.parle), hasLength(1));
      expect(cadres.firstWhere((CadreVisage c) => c.parle).personneId, 'e1');
    });
  });

  group('la salle de l enseignant, 1440 x 900', () {
    testWidgets('une personne, un cadre : en Classe, les visages dans la '
        'grille et des initiales dans le panneau ; en Document, les visages '
        'dans le panneau, a cote de la page entiere', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = await _monter(tester);
      expect(tester.takeException(), isNull);
      // Classe : trois personnes, trois images ; dans le panneau, la seule
      // image est celle de l'enseignant (son seul cadre).
      expect(_images, findsNWidgets(3));
      expect(find.descendant(of: _panneau, matching: _images), findsOneWidget);
      expect(
        find.descendant(
          of: _panneau,
          matching: find.byKey(const ValueKey<String>('cadre-ruban-RA-26-e1')),
        ),
        findsNothing,
      );
      if (dossierCapture != null) {
        await capturerVue(tester, 'enseignant_1440_classe');
      }

      await _presenter(tester, moteur);
      expect(tester.takeException(), isNull);
      // Document : la page, et les memes trois images, toutes dans le panneau.
      expect(find.byKey(TelephonePleinEcran.clePage), findsOneWidget);
      expect(_images, findsNWidgets(3));
      expect(
        find.descendant(of: _panneau, matching: _images),
        findsNWidgets(3),
      );
      expect(
        find.byKey(const ValueKey<String>('cadre-ruban-RA-26-e1')),
        findsOneWidget,
      );
      // La page garde sa pleine hauteur (CORAN-GRAND) : le ruban ne la
      // reduit pas.
      final Rect page = tester.getRect(find.byKey(TelephonePleinEcran.clePage));
      final Rect centre = tester.getRect(find.byKey(SalleOrdinateur.cleCentre));
      expect(
        page.height,
        closeTo(
          math.min(
            centre.height,
            (centre.width - 2 * margeFlechePage) * ratioHauteurPageMadina15,
          ),
          1,
        ),
      );
      verifierSansChevauchement(tester, <Finder>[
        find.byKey(TelephonePleinEcran.clePage),
        find.byKey(SalleOrdinateur.cleGauche),
        find.byKey(SalleOrdinateur.cleCommandes),
      ]);
      verifierUnSeulBoutonPlein(tester);
      if (dossierCapture != null) {
        await capturerVue(tester, 'enseignant_1440_document');
      }

      // « Voir la classe » (toucher son propre cadre) : retour a la grille,
      // la page attend ; « Revenir a la page » est sous la grille, jamais sur
      // un visage.
      await tester.tap(find.byKey(const ValueKey<String>('vignette-en-grand')));
      await tester.pumpAndSettle();
      expect(_images, findsNWidgets(3));
      expect(find.descendant(of: _panneau, matching: _images), findsOneWidget);
      final Finder revenir = find.text(t.salle.revenirALaPage);
      expect(revenir, findsOneWidget);
      final Rect bouton = tester.getRect(revenir);
      for (final Element e in find.byType(CadreVisage).evaluate()) {
        final Rect cadre = tester.getRect(find.byWidget(e.widget));
        expect(cadre.overlaps(bouton), isFalse);
      }
      await tester.tap(revenir);
      await tester.pumpAndSettle();
      expect(find.byKey(TelephonePleinEcran.clePage), findsOneWidget);
      expect(
        find.descendant(of: _panneau, matching: _images),
        findsNWidgets(3),
      );
    });

    testWidgets('le passage Classe vers Document : la grille part vers le '
        'panneau pendant que la page arrive, rien ne change de taille, puis il '
        'ne reste que la page', (WidgetTester tester) async {
      final FauxMoteurSalle moteur = await _monter(tester);
      final Rect centre = tester.getRect(find.byKey(SalleOrdinateur.cleCentre));
      await moteur.presenterContenu(
        ContenuPresente(
          page: 42,
          sourate: 2,
          verset: 255,
          presentePar: 't1',
          emisLe: DateTime.now(),
        ),
      );
      await tester.pump();
      await tester.pump(AppMouvement.deplacementEntreeOrdinateur ~/ 2);
      // A mi-course : la grille (qui part) et la page (qui arrive) ensemble,
      // dans la meme place.
      expect(find.byType(PassageScene), findsOneWidget);
      expect(tester.getRect(find.byKey(SalleOrdinateur.cleCentre)), centre);
      await tester.pumpAndSettle();
      expect(find.byKey(TelephonePleinEcran.clePage), findsOneWidget);
      expect(tester.getRect(find.byKey(SalleOrdinateur.cleCentre)), centre);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'la tete des Eleves et celle de la Bibliotheque : meme hauteur, '
      'le titre au debut, la croix a la fin',
      (WidgetTester tester) async {
        await _monter(tester);
        final Finder tetes = find.byType(TetePanneau);
        expect(tetes, findsNWidgets(2));
        final Rect eleves = tester.getRect(
          find.byKey(SalleOrdinateur.cleTeteEleves),
        );
        final Rect livres = tester.getRect(
          find.ancestor(
            of: find.byKey(const ValueKey<String>('bibliotheque-languette')),
            matching: find.byType(TetePanneau),
          ),
        );
        expect(eleves.height, closeTo(livres.height, 0.5));
        final Rect croixEleves = tester.getRect(
          find.byKey(SalleOrdinateur.cleFermerEleves),
        );
        final Rect croixLivres = tester.getRect(
          find.byKey(const ValueKey<String>('bibliotheque-fermer')),
        );
        expect(croixEleves.right, closeTo(eleves.right, 0.5));
        expect(croixLivres.right, closeTo(livres.right, 0.5));
        expect(croixEleves.size, croixLivres.size);
        // Le titre « Eleves 3/3 » au debut, en tete du panneau, au-dessus du
        // cadre de l'enseignant.
        expect(
          find.descendant(
            of: find.byKey(SalleOrdinateur.cleTeteEleves),
            matching: find.textContaining(t.salle.seance.eleves),
          ),
          findsOneWidget,
        );
        expect(
          eleves.bottom,
          lessThan(tester.getRect(find.byKey(SalleOrdinateur.cleVideo)).top),
        );
        // La croix ferme le panneau.
        await tester.tap(find.byKey(SalleOrdinateur.cleFermerEleves));
        await tester.pumpAndSettle();
        expect(find.byKey(SalleOrdinateur.cleGauche), findsNothing);
      },
    );

    testWidgets('le cadre de l enseignant : toute la largeur du panneau '
        '(directeur, 11/11 soir), au plus le sixieme de l ecran', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      final Rect v = tester.getRect(find.byKey(SalleOrdinateur.cleVideo));
      final Rect tete = tester.getRect(
        find.byKey(SalleOrdinateur.cleTeteEleves),
      );
      expect(v.left, closeTo(tete.left, 1));
      expect(v.right, closeTo(tete.right, 1));
      expect(v.width / v.height, greaterThanOrEqualTo(4 / 3 - 0.02));
      expect(v.height, lessThanOrEqualTo(900 / 6 + 0.5));
    });
  });

  group('captures', () {
    for (final (String nom, ThemeMode theme, AppLocale langue)
        in <(String, ThemeMode, AppLocale)>[
          ('clair', ThemeMode.light, AppLocale.fr),
          ('sombre', ThemeMode.dark, AppLocale.fr),
          ('arabe', ThemeMode.light, AppLocale.ar),
        ]) {
      group(nom, () {
        // La langue se pose hors de la zone de temps simulee du test.
        setUp(() => LocaleSettings.setLocale(langue));
        testWidgets('capture document $nom', (WidgetTester tester) async {
          if (dossierCapture == null) return;
          final FauxMoteurSalle moteur = await _monter(tester, theme: theme);
          await capturerVue(tester, 'enseignant_1440_classe_$nom');
          await _presenter(tester, moteur);
          await capturerVue(tester, 'enseignant_1440_document_$nom');
        });
      });
    }
  });

  // DYNAMIQUE-CHRONO-1 (directeur, 12/11/2026 : « le panneau cache le
  // chrono ») : remplace « l ile dans la colonne » (RUBAN-ORDINATEUR), dont
  // la largeur comptait le point d'etat, le signe du reseau et le point de la
  // mention, qui ont quitte la barre (ligne d'etat, jamais repliee).
  group('la Dynamique chrono dans la colonne', () {
    for (final double echelle in <double>[1, 1.3, 2]) {
      testWidgets('repliee avec sa marque de pause, elle tient sur une ligne '
          'dans la colonne, texte x$echelle', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        final DateTime t0 = DateTime.now().toUtc();
        final VueSeance vue = VueSeance(
          role: RoleSeance.enseignant,
          nomClasse: 'Classe',
          nomEnseignant: 'Sayyida Amina',
          initialesEnseignant: 'SA',
          chrono: BornesChrono(
            debutUtc: t0,
            finPrevueUtc: t0.add(const Duration(minutes: 55)),
          ),
          pause: PauseSeance(
            statut: StatutPause.programmee,
            dureePrevueMinutes: 10,
            debutPrevuUtc: t0.add(const Duration(minutes: 21)),
            peutPiloter: true,
          ),
        );
        double colonne = 0;
        await tester.pumpWidget(
          ProviderScope(
            child: TranslationProvider(
              child: MediaQuery(
                data: MediaQueryData(
                  size: const Size(1440, 900),
                  textScaler: TextScaler.linear(echelle),
                ),
                child: MaterialApp(
                  theme: AppTheme.pour(
                    InterfaceMode.standard,
                    Brightness.light,
                  ),
                  home: Material(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Builder(
                        builder: (BuildContext context) {
                          colonne = largeurBarreColonne(context);
                          return SizedBox(
                            width: colonne,
                            child: DynamiqueChrono(
                              vue: vue,
                              avecChrono: true,
                              enPlace: true,
                              largeurMax: colonne,
                              onPause: () {},
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        final Rect barre = tester.getRect(
          find.byKey(const ValueKey<String>('pilule-etat-salle')),
        );
        expect(barre.width, lessThanOrEqualTo(colonne + 0.5));
        // Une ligne : la cible de 48 (texte x1), une ligne de texte agrandi
        // au-dela, jamais deux.
        expect(barre.height, lessThan(80));
        // La ligne du chrono entiere, sans reduction a texte x1.
        final Rect ligne = tester.getRect(find.byKey(ChronoSalle.cleLigne));
        expect(ligne.right, lessThanOrEqualTo(barre.right + 0.5));
        // Depliee a sa place : tout tient dans la largeur de la colonne.
        await tester.tap(find.byKey(DynamiqueChrono.cleDeplier));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byKey(DynamiqueChrono.cleDepliee)).right,
          lessThanOrEqualTo(colonne + 0.5),
        );
        expect(find.byKey(ChronoSalle.cleCommandePause), findsOneWidget);
      });
    }
  });
}

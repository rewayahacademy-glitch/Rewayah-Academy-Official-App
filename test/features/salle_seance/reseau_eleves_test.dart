// Lot RESEAU-ELEVES (directeur, 11/11/2026 ; cahier de la salle §5 et §6) :
// l'enseignant voit le reseau de chaque eleve dans sa carte ; celui qu'on
// entend peut-etre mal le lit dans l'ile ; une situation de reseau n'est dite
// qu'une fois (defaut C6-4 : l'ile ET le bandeau la disaient).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/seuils_reseau.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/depuis_salle.dart';
import 'package:rewayah_academy/features/salle_seance/dynamique_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/vignette_video.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

const EtatReseau _faibleQuiDure = EtatReseau(
  qualite: QualiteLien.mediocre,
  alerte: true,
);

EleveSeance _eleve(
  String prenom, {
  EtatReseau? reseau,
  bool micro = true,
  StatutEleveSeance statut = StatutEleveSeance.connecte,
}) => EleveSeance(
  prenom: prenom,
  statut: statut,
  id: 'RA-$prenom',
  profilId: 'p-$prenom',
  reseau: reseau,
  microOuvert: micro,
);

Future<void> _panneau(
  WidgetTester tester,
  List<EleveSeance> eleves, {
  Size taille = const Size(390, 844),
  double echelle = 1,
  AppLocale langue = AppLocale.fr,
}) async {
  await tester.runAsync(() => LocaleSettings.setLocale(langue));
  addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(echelle),
          ),
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            home: Directionality(
              textDirection: langue == AppLocale.ar
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Material(
                child: SizedBox(
                  width: taille.width < 600 ? taille.width : 300,
                  height: taille.height,
                  child: PanneauEleves(
                    eleves: eleves,
                    large: taille.width >= 600,
                    actions: const ActionsSeance(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

VueSeance _vueEleve({
  ConnexionSeance connexion = ConnexionSeance.enLigne,
  bool videoSuspendue = false,
  bool onVousEntendMal = false,
  bool reseauDansIle = true,
  RoleSeance role = RoleSeance.eleve,
  bool? tutoiement,
}) => VueSeance(
  role: role,
  nomClasse: 'Classe',
  nomEnseignant: 'Sayyida Amina',
  initialesEnseignant: 'SA',
  connexion: connexion,
  videoSuspendue: videoSuspendue,
  onVousEntendMal: onVousEntendMal,
  reseauDansIle: reseauDansIle,
  tutoiement: tutoiement,
  enregistrementConfirme: false,
);

Future<void> _ile(
  WidgetTester tester,
  VueSeance vue, {
  Size taille = const Size(390, 844),
  double echelle = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(echelle),
          ),
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            home: Material(
              child: Align(
                alignment: Alignment.topLeft,
                // DYNAMIQUE-CHRONO-1 : la phrase de reseau est dite par la
                // ligne d'etat de la zone de la Dynamique chrono, qui ne se
                // replie jamais.
                child: ZoneChrono(vue: vue, largeur: taille.width - 32),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

AccesSalle _acces(String role) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: role == 'teacher',
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

ParticipantSalle _participant(
  String id, {
  String role = 'student',
  bool local = false,
  bool micro = true,
}) => ParticipantSalle(
  identite: id,
  nom: id,
  role: role,
  estLocal: local,
  micro: micro,
  camera: false,
  parle: false,
  qualite: QualiteLien.mediocre,
);

void main() {
  group('la carte de l eleve chez l enseignant', () {
    testWidgets('trois barres, une barre, ou aucun signe sans mesure', (
      WidgetTester tester,
    ) async {
      await _panneau(tester, <EleveSeance>[
        _eleve(
          'Yasmine',
          reseau: const EtatReseau(qualite: QualiteLien.excellente),
        ),
        _eleve(
          'Amine',
          reseau: const EtatReseau(qualite: QualiteLien.mediocre),
        ),
        _eleve('Sara'),
      ]);
      final SignalVideo y = tester.widget(
        find.byKey(const ValueKey<String>('reseau-RA-Yasmine')),
      );
      final SignalVideo a = tester.widget(
        find.byKey(const ValueKey<String>('reseau-RA-Amine')),
      );
      expect(y.barres, 3);
      expect(a.barres, 1);
      expect(
        find.byKey(const ValueKey<String>('reseau-RA-Sara')),
        findsNothing,
        reason: 'jamais des barres inventees',
      );
      // Le libelle lu : « Reseau faible » avec la carte.
      expect(
        find.bySemanticsLabel(RegExp('Amine.*${t.salle.reseau.faible}')),
        findsOneWidget,
      );
      // Aucun reseau mauvais qui dure : aucune phrase.
      expect(find.textContaining('peut-être mal'), findsNothing);
    });

    testWidgets('un reseau mauvais qui dure remonte une phrase courte, '
        'differente selon le micro', (WidgetTester tester) async {
      await _panneau(tester, <EleveSeance>[
        _eleve('Yasmine', reseau: _faibleQuiDure),
        _eleve('Amine', reseau: _faibleQuiDure, micro: false),
      ]);
      expect(
        find.text(t.salle.reseau.onEntendMal(prenom: 'Yasmine')),
        findsOneWidget,
      );
      expect(
        find.text(t.salle.reseau.entendMal(prenom: 'Amine')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('un eleve deconnecte ne porte ni barres ni phrase', (
      WidgetTester tester,
    ) async {
      await _panneau(tester, <EleveSeance>[
        _eleve(
          'Yasmine',
          reseau: _faibleQuiDure,
          statut: StatutEleveSeance.connexionInterrompue,
        ),
      ]);
      expect(find.byType(SignalVideo), findsNothing);
      expect(find.textContaining('peut-être mal'), findsNothing);
    });

    for (final Size taille in <Size>[
      const Size(320, 640),
      const Size(1440, 900),
    ]) {
      for (final double echelle in <double>[1, 2]) {
        testWidgets('${taille.width.toInt()} px, texte x$echelle : rien ne '
            'deborde', (WidgetTester tester) async {
          await _panneau(
            tester,
            <EleveSeance>[
              _eleve('Yasmine-Maryam', reseau: _faibleQuiDure),
              _eleve(
                'Amine',
                reseau: const EtatReseau(qualite: QualiteLien.bonne),
              ),
            ],
            taille: taille,
            echelle: echelle,
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(SignalVideo), findsNWidgets(2));
        });
      }
    }

    testWidgets('en arabe : la phrase et le libelle lu sont en arabe', (
      WidgetTester tester,
    ) async {
      await _panneau(
        tester,
        <EleveSeance>[_eleve('ياسمين', reseau: _faibleQuiDure)],
        langue: AppLocale.ar,
        taille: const Size(320, 640),
        echelle: 2,
      );
      expect(tester.takeException(), isNull);
      final String phrase = t.salle.reseau.onEntendMal(prenom: 'ياسمين');
      expect(phrase.contains('peut'), isFalse);
      expect(find.text(phrase), findsOneWidget);
      expect(find.byType(SignalVideo), findsOneWidget);
    });
  });

  group('celui qu on entend mal le sait, dans l ile', () {
    // DYNAMIQUE-CHRONO-1 (directeur, 12/11/2026) : la phrase ne se replie
    // plus sur un signe court ; elle reste ecrite dans la ligne d'etat, a sa
    // place reservee, tant que ca dure (avant ce lot : l'ile la depliait 6 s,
    // puis gardait l'onde du reseau).
    testWidgets('la phrase reste dite tant que ca dure, une seule', (
      WidgetTester tester,
    ) async {
      await _ile(tester, _vueEleve(connexion: ConnexionSeance.reseauFaible));
      await tester.pump(const Duration(milliseconds: 500));
      await _ile(
        tester,
        _vueEleve(
          connexion: ConnexionSeance.reseauFaible,
          videoSuspendue: true,
          onVousEntendMal: true,
        ),
      );
      // Le fondu de l'ancienne phrase se termine.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(t.salle.reseau.onVousEntendMal), findsOneWidget);
      // Un seul message : ni l'image coupee ni le reseau faible en plus.
      expect(find.text(t.salle.videoSuspendue), findsNothing);
      expect(find.text(t.salle.secours.reseauFaible), findsNothing);
      await tester.pump(AppMouvement.ilePassage);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(t.salle.reseau.onVousEntendMal), findsOneWidget);
      expect(
        find.bySemanticsLabel(t.salle.reseau.onVousEntendMal),
        findsOneWidget,
        reason: 'le lecteur d ecran lit toujours la phrase entiere',
      );
    });

    test('tutoiement pour l enfant, forme courte en Interface guidee', () {
      expect(
        _vueEleve(onVousEntendMal: true, tutoiement: true).texteConnexion,
        t.salle.reseau.onTEntendMal,
      );
      expect(
        _vueEleve(
          onVousEntendMal: true,
          role: RoleSeance.guidee,
        ).texteConnexion,
        t.salle.reseau.onTEntendMalGuidee,
      );
      expect(
        t.salle.reseau.onTEntendMalGuidee.length,
        lessThan(t.salle.reseau.onTEntendMal.length),
      );
      expect(
        _vueEleve(onVousEntendMal: true, tutoiement: false).texteConnexion,
        t.salle.reseau.onVousEntendMal,
      );
    });

    for (final double echelle in <double>[1, 2]) {
      testWidgets('320 px, texte x$echelle : la phrase tient', (
        WidgetTester tester,
      ) async {
        await _ile(
          tester,
          _vueEleve(
            connexion: ConnexionSeance.reseauFaible,
            onVousEntendMal: true,
          ),
          taille: const Size(320, 640),
          echelle: echelle,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(t.salle.reseau.onVousEntendMal), findsOneWidget);
      });
    }
  });

  group('une situation de reseau n est dite qu une fois (C6-4)', () {
    test('dans /salle, l ile la dit et le bandeau se tait', () {
      for (final ConnexionSeance c in <ConnexionSeance>[
        ConnexionSeance.reseauFaible,
        ConnexionSeance.reconnexion,
      ]) {
        final VueSeance vue = _vueEleve(connexion: c);
        expect(vue.texteBandeau, isNull, reason: c.name);
        expect(vue.sousTexteBandeau, isNull, reason: c.name);
      }
      expect(
        _vueEleve(connexion: ConnexionSeance.reseauFaible).texteConnexion,
        t.salle.secours.reseauFaible,
      );
      expect(
        _vueEleve(connexion: ConnexionSeance.reconnexion).texteConnexion,
        t.salle.secours.reconnexion,
      );
      expect(
        _vueEleve(
          connexion: ConnexionSeance.reseauFaible,
          videoSuspendue: true,
        ).texteConnexion,
        t.salle.videoSuspendue,
      );
    });

    test('hors de /salle (galerie, anciennes compositions sans ile), le '
        'bandeau garde la phrase', () {
      final VueSeance vue = _vueEleve(
        connexion: ConnexionSeance.reseauFaible,
        reseauDansIle: false,
      );
      expect(vue.texteBandeau, t.salle.secours.reseauFaible);
      expect(vue.texteConnexion, t.salle.seance.enLigne);
    });

    test('au telephone de l enseignant (ile dans le profil seulement), le '
        'bandeau dit « on vous entend peut-etre mal », une seule fois', () {
      final VueSeance vue = _vueEleve(
        role: RoleSeance.enseignant,
        connexion: ConnexionSeance.reseauFaible,
        onVousEntendMal: true,
        reseauDansIle: false,
      );
      expect(vue.texteBandeau, t.salle.reseau.onVousEntendMal);
      expect(vue.texteConnexion, isNot(t.salle.reseau.onVousEntendMal));
    });

    test('DepuisSalle : l ile porte le reseau, la phrase suit le micro '
        'ouvert, chaque eleve recoit le sien', () {
      VueSalle salle({required bool micro, required String role}) =>
          VueSalle.depuis(
            materielPret: true,
            acces: _acces(role),
            etatMoteur: EtatSalle.connecte,
            participants: <ParticipantSalle>[
              _participant('moi', role: role, local: true, micro: micro),
              _participant('yasmine'),
              _participant('amine', micro: false),
            ],
            qualite: QualiteLien.mediocre,
          );
      final Map<String, EtatReseau> reseaux = <String, EtatReseau>{
        'moi': _faibleQuiDure,
        'yasmine': _faibleQuiDure,
        'amine': const EtatReseau(qualite: QualiteLien.bonne),
      };
      final VueSeance ouvert = DepuisSalle.vue(
        salle: salle(micro: true, role: 'teacher'),
        mode: InterfaceMode.standard,
        reseaux: reseaux,
      )!;
      expect(ouvert.reseauDansIle, isTrue);
      expect(ouvert.onVousEntendMal, isTrue);
      expect(ouvert.signalEnseignant, 1);
      final EleveSeance y = ouvert.eleves.firstWhere(
        (EleveSeance e) => e.profilId == 'yasmine',
      );
      expect(y.reseau, _faibleQuiDure);
      expect(y.phraseReseau, t.salle.reseau.onEntendMal(prenom: 'yasmine'));
      final EleveSeance a = ouvert.eleves.firstWhere(
        (EleveSeance e) => e.profilId == 'amine',
      );
      expect(a.reseau?.barres, 2);
      expect(a.phraseReseau, isNull);

      final VueSeance ferme = DepuisSalle.vue(
        salle: salle(micro: false, role: 'teacher'),
        mode: InterfaceMode.standard,
        reseaux: reseaux,
      )!;
      expect(ferme.onVousEntendMal, isFalse, reason: 'micro ferme');

      // Sans suivi (la galerie, les tests), les barres restent la mesure
      // brute, comme avant.
      final VueSeance brut = DepuisSalle.vue(
        salle: salle(micro: true, role: 'teacher'),
        mode: InterfaceMode.standard,
      )!;
      expect(brut.signalEnseignant, 1);
      expect(brut.onVousEntendMal, isFalse);
    });
  });
}

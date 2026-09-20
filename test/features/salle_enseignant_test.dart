import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/page_immersive.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/salle_enseignant/panneau_enseignant.dart';
import 'package:rewayah_academy/features/salle_enseignant/vue_presentation.dart';

import '../support/harnais.dart';

const String _seance = 's1';

/// Le corpus reduit a ce qu'une seance exerce : deux pages, une sourate.
class _FauxCoran implements ServiceCoran {
  _FauxCoran({
    this.pages = const <int, List<VersetCoran>>{},
    this.catalogue,
    this.pagesDeReference = const <String, int>{},
    this.delai = Duration.zero,
  });

  /// Le temps que met une page a arriver.
  ///
  /// Sans delai, le futur se resout dans la micro-tache que le premier `pump`
  /// vide, et **l'etat de chargement n'existe jamais** : c'est la meme raison
  /// qui fait exister `FauxServiceEnseignant.delai` dans le harnais.
  final Duration delai;

  /// Les versets par page. Une page absente rend `null` : lecture impossible.
  /// Une page presente et vide dit que le corpus n'est pas importe.
  final Map<int, List<VersetCoran>> pages;

  /// Les 114 sourates, ou `null` quand la lecture echoue.
  final List<Sourate>? catalogue;

  /// La page d'une reference « sourate:verset ».
  final Map<String, int> pagesDeReference;

  /// **Ce qui doit rester vide** : l'invariant J2 interdit a la surface
  /// enseignante d'ecrire une position de lecture, la sienne comprise.
  final List<PositionLecture> positionsEcrites = <PositionLecture>[];

  @override
  Future<String?> editionCourante() async => 'edition-de-test';

  @override
  Future<List<Sourate>?> sourates() async => catalogue;

  @override
  Future<PageCoran?> page(int numero) async {
    if (delai > Duration.zero) {
      await Future<void>.delayed(delai);
    }
    final List<VersetCoran>? versets = pages[numero];
    return versets == null
        ? null
        : PageCoran(numero: numero, versets: versets);
  }

  @override
  Future<int?> pageDe(int sourate, int verset) =>
      Future<int?>.value(pagesDeReference['$sourate:$verset']);

  @override
  Future<PositionLecture?> position(String profilId) async => null;

  @override
  Future<bool> enregistrerPosition(
    String profilId,
    PositionLecture position,
  ) async {
    positionsEcrites.add(position);
    return true;
  }

  @override
  Future<({int sourate, int verset})?> debutDeJuz(int juz) async => null;

  @override
  Future<List<VersetCoran>?> rechercher(
    String requete, {
    int limite = 50,
  }) async => const <VersetCoran>[];
}

VersetCoran _verset({
  required int sourate,
  required int numero,
  required int page,
}) => VersetCoran(
  sourateNumero: sourate,
  numero: numero,
  texte: 'texte du verset $sourate:$numero',
  pageNumero: page,
);

const Sourate _baqara = Sourate(
  numero: 2,
  nomArabe: 'البقرة',
  nomTranslittere: 'Al-Baqara',
  lieuRevelation: 'medine',
  nombreVersets: 286,
);

/// Le corpus employe par la plupart des cas : la page 42 et la page 43 lisibles.
_FauxCoran _corpus() => _FauxCoran(
  pages: <int, List<VersetCoran>>{
    42: <VersetCoran>[_verset(sourate: 2, numero: 255, page: 42)],
    43: <VersetCoran>[_verset(sourate: 2, numero: 257, page: 43)],
  },
  catalogue: const <Sourate>[_baqara],
  pagesDeReference: const <String, int>{'2:1': 2, '2:255': 42},
);

/// L'acces tel que `create-room-token` le rend a un enseignant.
AccesSalle _acces({bool peutPublierDonnees = true}) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: 'teacher',
  capacites: CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: true,
    peutPublierDonnees: peutPublierDonnees,
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

/// Le pointeur d'un tour de page : l'ayat al-Kursi, page 42 de ce corpus.
ContenuPresente _contenu({int page = 42, int sourate = 2, int verset = 255}) =>
    ContenuPresente(
      page: page,
      sourate: sourate,
      verset: verset,
      presentePar: 'ens-1',
      emisLe: DateTime.now(),
    );

List<Override> _surcharges({
  required FauxMoteurSalle moteur,
  required _FauxCoran coran,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      const SessionState(
        resolue: true,
        role: AppRole.teacher,
        profileId: 'ens-1',
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  moteurSalleProvider.overrideWithValue(moteur),
  serviceCoranProvider.overrideWithValue(coran),
];

/// Monte le panneau dans la coquille reelle de la salle.
///
/// **La coquille et non un `Scaffold` de test** : c'est elle qui donne le
/// registre inverse, la hauteur bornee et l'encre par defaut, c'est-a-dire
/// exactement ce que le panneau trouvera a son point d'insertion.
Future<void> _monter(
  WidgetTester tester, {
  required List<Override> surcharges,
  Size taille = const Size(390, 844),
  TextScaler echelle = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    hote(
      Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: echelle),
          child: const PageImmersive(
            registre: RegistreImmersif.salle,
            child: PanneauEnseignantSalle(seanceId: _seance),
          ),
        ),
      ),
      surcharges: surcharges,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('La vue de presentation, sans monter d ecran', () {
    test('les sept etats du moteur donnent six phases distinctes', () {
      // Les cinq etats du protocole -- connecte, instable, reconnexion,
      // retabli, echec -- plus l'attente d'entree. Chacun doit se distinguer :
      // deux etats qui retomberaient sur la meme phase se diraient par le meme
      // mot, et l'enseignant ne saurait pas si sa page est partie.
      final Map<EtatSalle, PhasePresentation> attendu =
          <EtatSalle, PhasePresentation>{
            EtatSalle.absent: PhasePresentation.horsSalle,
            EtatSalle.connexion: PhasePresentation.horsSalle,
            EtatSalle.connecte: PhasePresentation.active,
            EtatSalle.instable: PhasePresentation.instable,
            EtatSalle.reconnexion: PhasePresentation.reconnexion,
            EtatSalle.retabli: PhasePresentation.retabli,
            EtatSalle.echec: PhasePresentation.echec,
          };

      for (final MapEntry<EtatSalle, PhasePresentation> cas
          in attendu.entries) {
        expect(
          VuePresentation.depuis(
            etatMoteur: cas.key,
            contenu: null,
            peutPresenter: true,
          ).phase,
          cas.value,
          reason: cas.key.name,
        );
      }
      expect(attendu.values.toSet().length, 6);
      expect(attendu.length, EtatSalle.values.length);
    });

    test('une coupure garde la page et ferme les commandes', () {
      final VuePresentation vue = VuePresentation.depuis(
        etatMoteur: EtatSalle.reconnexion,
        contenu: _contenu(),
        peutPresenter: true,
      );

      expect(vue.presente, isTrue);
      expect(vue.contenuConserve, isTrue);
      // Un paquet publie pendant une reconnexion n'atteindrait personne.
      expect(vue.commandesActives, isFalse);

      // Un lien faible, lui, laisse tourner la page : la seance continue.
      expect(
        VuePresentation.depuis(
          etatMoteur: EtatSalle.instable,
          contenu: _contenu(),
          peutPresenter: true,
        ).commandesActives,
        isTrue,
      );
    });

    test('sans le droit de presenter, aucune commande n est active', () {
      // `can_publish_data` est refuse : un bouton qui echouerait ne doit meme
      // pas etre calcule comme actif.
      final VuePresentation vue = VuePresentation.depuis(
        etatMoteur: EtatSalle.connecte,
        contenu: _contenu(),
        peutPresenter: false,
      );

      expect(vue.lienPorte, isTrue);
      expect(vue.commandesActives, isFalse);
    });

    test('les bornes du mushaf ferment le geste au bord', () {
      final VuePresentation premiere = VuePresentation.depuis(
        etatMoteur: EtatSalle.connecte,
        contenu: _contenu(page: 1, verset: 1),
        peutPresenter: true,
      );
      final VuePresentation derniere = VuePresentation.depuis(
        etatMoteur: EtatSalle.connecte,
        contenu: _contenu(page: pagesMushafMedine, sourate: 114, verset: 1),
        peutPresenter: true,
      );

      expect(premiere.pagePrecedente, isNull);
      expect(premiere.pageSuivante, 2);
      expect(derniere.pagePrecedente, pagesMushafMedine - 1);
      expect(derniere.pageSuivante, isNull);

      // Sans contenu, il n'y a pas de page voisine : on ne tourne pas une page
      // qu'on n'a pas ouverte.
      final VuePresentation vide = VuePresentation.depuis(
        etatMoteur: EtatSalle.connecte,
        contenu: null,
        peutPresenter: true,
      );
      expect(vide.pagePrecedente, isNull);
      expect(vide.pageSuivante, isNull);
    });
  });

  group('Le panneau de l enseignant, dans la salle', () {
    testWidgets('il n ouvre ni micro ni camera, et n en porte pas la commande', (
      WidgetTester tester,
    ) async {
      // **L'invariant du catalogue** -- micro et camera fermes a l'entree, pour
      // tous les roles -- et la frontiere de cette surface : les controles media
      // vivent dans `salle_page`, et un second micro sur le meme ecran finirait
      // par ne plus dire la meme chose que le premier.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());

      await _monter(
        tester,
        surcharges: _surcharges(moteur: moteur, coran: _corpus()),
      );

      expect(moteur.microDemande, isEmpty);
      expect(moteur.cameraDemandee, isEmpty);
      expect(moteur.departs, 0);
      expect(find.bySemanticsLabel(RegExp(t.salle.ouvrirMicro)), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp(t.salle.quitterLeCours)),
        findsNothing,
      );
    });

    testWidgets('sans contenu presente, il propose d ouvrir le Coran', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());

      await _monter(
        tester,
        surcharges: _surcharges(moteur: moteur, coran: _corpus()),
      );

      expect(find.text(t.enseignant.salle.rien), findsOneWidget);
      expect(find.text(t.enseignant.salle.rienInvitation), findsOneWidget);
      // La cle existante, jamais une jumelle.
      expect(find.text(t.salle.ouvrirCoran), findsOneWidget);
      // Aucune commande de page tant qu'aucune page n'est ouverte.
      expect(find.text(t.enseignant.salle.suivante), findsNothing);
    });

    testWidgets('hors de la salle, l etat vide ne propose rien et le dit', (
      WidgetTester tester,
    ) async {
      // Le moteur n'a pas rejoint : `etatCourant` vaut `absent`. Ouvrir le Coran
      // n'atteindrait personne, donc l'action n'est pas rendue.
      await _monter(
        tester,
        surcharges: _surcharges(moteur: FauxMoteurSalle(), coran: _corpus()),
      );

      expect(find.text(t.enseignant.salle.attenteSalle), findsOneWidget);
      expect(find.text(t.enseignant.salle.attenteSalleDetail), findsOneWidget);
      expect(find.text(t.salle.ouvrirCoran), findsNothing);
    });

    testWidgets('choisir une sourate publie un pointeur, page comprise', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());
      final _FauxCoran coran = _corpus();

      await _monter(
        tester,
        surcharges: _surcharges(moteur: moteur, coran: coran),
      );

      await tester.tap(find.text(t.salle.ouvrirCoran));
      await tester.pumpAndSettle();
      expect(find.text(_baqara.nomTranslittere), findsOneWidget);

      await tester.tap(find.text(_baqara.nomTranslittere));
      await tester.pumpAndSettle();

      // Un pointeur, jamais du texte : page, sourate, verset.
      expect(moteur.contenusPresentesDemandes.length, 1);
      final ContenuPresente envoye = moteur.contenusPresentesDemandes.single;
      expect(envoye.sourate, 2);
      expect(envoye.verset, 1);
      // La page vient de la conversion du socle, pas d'un calcul local.
      expect(envoye.page, 2);
      expect(moteur.dernierContenuPresente?.reference, '2:1');
      // [QURAN-STAGE] J2 : presenter n'ecrit la position de personne.
      expect(coran.positionsEcrites, isEmpty);
    });

    testWidgets('la page presentee est toujours identifiable', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());

      await _monter(
        tester,
        surcharges: _surcharges(moteur: moteur, coran: _corpus()),
      );

      // Une RECEPTION, comme si le paquet venait du canal de donnees : c'est
      // aussi ce qui arrive au presentateur lui-meme, qui lit son propre
      // contenu par ce flux et n'en garde aucune copie locale.
      moteur.publierContenu(_contenu());
      await tester.pumpAndSettle();

      expect(
        find.text(
          t.enseignant.salle.reference(
            page: '42',
            total: '$pagesMushafMedine',
            reference: '2:255',
          ),
        ),
        findsOneWidget,
      );
      // `findRichText` : le texte du mushaf est un flux continu, donc un
      // `Text.rich`, que le finder ignore sans ce drapeau.
      expect(
        find.textContaining('texte du verset 2:255', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets('precedent et suivant sont au premier niveau, et publient', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());

      await _monter(
        tester,
        surcharges: _surcharges(moteur: moteur, coran: _corpus()),
      );
      moteur.publierContenu(_contenu());
      await tester.pumpAndSettle();

      // Visibles dans le flux, pas derriere un menu.
      expect(find.text(t.enseignant.salle.precedente), findsOneWidget);
      expect(find.text(t.enseignant.salle.suivante), findsOneWidget);

      await tester.tap(find.text(t.enseignant.salle.suivante));
      await tester.pumpAndSettle();

      expect(moteur.contenusPresentesDemandes.length, 1);
      expect(moteur.contenusPresentesDemandes.single.page, 43);
      expect(moteur.contenusPresentesDemandes.single.verset, 257);
      expect(moteur.dernierContenuPresente?.page, 43);
    });

    testWidgets('une coupure ne vide pas la page, et le dit en mots', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());

      await _monter(
        tester,
        surcharges: _surcharges(moteur: moteur, coran: _corpus()),
      );
      moteur.publierContenu(_contenu());
      await tester.pumpAndSettle();

      moteur.poser(EtatSalle.reconnexion);
      await tester.pumpAndSettle();

      // L'etat pedagogique survit : la reference et le texte restent la.
      expect(
        find.textContaining('texte du verset 2:255', findRichText: true),
        findsWidgets,
      );
      // Le mot, jamais la seule couleur (invariant J7).
      expect(
        find.textContaining(t.enseignant.salle.presentationConservee),
        findsOneWidget,
      );

      // Et la commande ne part pas dans le vide : elle est inerte, pas grisee
      // par-dessus un geste qui aurait quand meme publie.
      expect(
        tester
            .widget<ActionPrincipale>(
              find.widgetWithText(
                ActionPrincipale,
                t.enseignant.salle.suivante,
              ),
            )
            .onPress,
        isNull,
      );
      expect(moteur.contenusPresentesDemandes, isEmpty);
    });

    testWidgets('le retablissement se dit, et rouvre les commandes', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());

      await _monter(
        tester,
        surcharges: _surcharges(moteur: moteur, coran: _corpus()),
      );
      moteur.publierContenu(_contenu());
      moteur.poser(EtatSalle.reconnexion);
      await tester.pumpAndSettle();

      // Le socle republie le contenu au retour ; l'ecran, lui, doit d'abord
      // dire que la coupure est refermee.
      moteur.poser(EtatSalle.retabli);
      await tester.pumpAndSettle();

      expect(find.text(t.reseau.retabli), findsOneWidget);
      await tester.tap(find.text(t.enseignant.salle.suivante));
      await tester.pumpAndSettle();
      expect(moteur.contenusPresentesDemandes.length, 1);
    });

    testWidgets('l ecran n affiche que ce que le moteur a publie', (
      WidgetTester tester,
    ) async {
      // Un jeton sans `can_publish_data` : le moteur enregistre la demande et
      // refuse en silence. Une surface qui garderait un etat local de « page que
      // je presente » afficherait une page que le groupe ne voit pas.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces(peutPublierDonnees: false));

      await _monter(
        tester,
        surcharges: _surcharges(moteur: moteur, coran: _corpus()),
      );

      await tester.tap(find.text(t.salle.ouvrirCoran));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_baqara.nomTranslittere));
      await tester.pumpAndSettle();

      expect(moteur.contenusPresentesDemandes.length, 1);
      expect(moteur.dernierContenuPresente, isNull);
      expect(find.text(t.enseignant.salle.rien), findsOneWidget);
    });

    testWidgets('une reference introuvable n envoie rien, et le dit', (
      WidgetTester tester,
    ) async {
      // `null` veut dire « je ne sais pas », jamais « page 1 » : ouvrir la
      // Fatiha devant une classe parce qu'une requete a echoue serait pire que
      // ne rien presenter.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());
      final _FauxCoran coran = _FauxCoran(
        catalogue: const <Sourate>[_baqara],
      );

      await _monter(
        tester,
        surcharges: _surcharges(moteur: moteur, coran: coran),
      );

      await tester.tap(find.text(t.salle.ouvrirCoran));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_baqara.nomTranslittere));
      await tester.pumpAndSettle();

      expect(moteur.contenusPresentesDemandes, isEmpty);
      expect(find.text(t.enseignant.salle.echecPresentation), findsOneWidget);
    });

    testWidgets('le texte qui arrive se dit par un squelette', (
      WidgetTester tester,
    ) async {
      // Le chargement a la forme de ce qui arrive : un paragraphe, pas un
      // tourniquet nu. La reference, elle, est deja identifiable.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());

      await _monter(
        tester,
        surcharges: _surcharges(
          moteur: moteur,
          coran: _FauxCoran(
            pages: <int, List<VersetCoran>>{
              42: <VersetCoran>[_verset(sourate: 2, numero: 255, page: 42)],
            },
            catalogue: const <Sourate>[_baqara],
            delai: const Duration(seconds: 1),
          ),
        ),
      );

      moteur.publierContenu(_contenu());
      await tester.pump();
      // Le squelette ne s'affiche qu'au bout de 200 ms : un squelette qui
      // clignote coute plus cher qu'il ne rassure.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Skeleton), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(Skeleton), findsNothing);
      expect(
        find.textContaining('texte du verset 2:255', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets('une page illisible se dit, et se reessaye', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());

      await _monter(
        tester,
        surcharges: _surcharges(
          moteur: moteur,
          // Aucune page : la lecture rend `null`, donc un echec de lecture.
          coran: _FauxCoran(catalogue: const <Sourate>[_baqara]),
        ),
      );
      moteur.publierContenu(_contenu());
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.salle.pageIndisponible), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
      // La reference reste : le groupe voit toujours cette page, meme si le
      // texte n'est pas arrive jusqu'ici.
      expect(
        find.text(
          t.enseignant.salle.reference(
            page: '42',
            total: '$pagesMushafMedine',
            reference: '2:255',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('un corpus absent ne se confond pas avec une panne', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());

      await _monter(
        tester,
        surcharges: _surcharges(
          moteur: moteur,
          // La page existe et n'a aucun verset : le corpus n'est pas importe.
          coran: _FauxCoran(
            pages: const <int, List<VersetCoran>>{42: <VersetCoran>[]},
            catalogue: const <Sourate>[_baqara],
          ),
        ),
      );
      moteur.publierContenu(_contenu());
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.salle.corpusAbsent), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsNothing);
    });

    testWidgets('la page d un cours ne suit pas dans le cours suivant', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());
      final List<Override> surcharges = _surcharges(
        moteur: moteur,
        coran: _corpus(),
      );

      await _monter(tester, surcharges: surcharges);
      moteur.publierContenu(_contenu());
      await tester.pumpAndSettle();
      expect(
        find.textContaining('texte du verset 2:255', findRichText: true),
        findsWidgets,
      );

      // La sortie de salle demonte le panneau. Un flux ne republie jamais
      // « plus rien » : si le provider survivait, la page de ce cours serait
      // encore la au cours suivant, et un « page suivante » partirait d'un
      // pointeur perime.
      await tester.pumpWidget(
        hote(const SizedBox.shrink(), surcharges: surcharges),
      );
      await tester.pumpAndSettle();
      await moteur.quitter();
      await moteur.rejoindre(_acces());

      await _monter(tester, surcharges: surcharges);
      expect(find.text(t.enseignant.salle.rien), findsOneWidget);
    });

    testWidgets('sur 390x844, rien ne deborde, meme a 200 pour cent', (
      WidgetTester tester,
    ) async {
      for (final TextScaler echelle in <TextScaler>[
        TextScaler.noScaling,
        const TextScaler.linear(2),
      ]) {
        final FauxMoteurSalle moteur = FauxMoteurSalle();
        await moteur.rejoindre(_acces());

        await _monter(
          tester,
          surcharges: _surcharges(moteur: moteur, coran: _corpus()),
          echelle: echelle,
        );
        moteur.publierContenu(_contenu());
        await tester.pumpAndSettle();

        // Un debordement de mise en page est leve comme exception de rendu :
        // c'est ainsi que le defaut de la vignette du controleur avait ete
        // mesure, et c'est la meme mesure ici.
        expect(tester.takeException(), isNull, reason: '$echelle');
        expect(find.text(t.enseignant.salle.suivante), findsOneWidget);
      }
    });

    testWidgets('sur grand gabarit, les deux verbes tiennent cote a cote', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());

      await _monter(
        tester,
        surcharges: _surcharges(moteur: moteur, coran: _corpus()),
        taille: const Size(1280, 800),
      );
      moteur.publierContenu(_contenu());
      await tester.pumpAndSettle();

      // `[RESPONSIVE]` Les deux verbes entiers, sur une seule rangee : ce que
      // 390 points ne permettent pas.
      final Offset precedente = tester.getCenter(
        find.text(t.enseignant.salle.precedente),
      );
      final Offset suivante = tester.getCenter(
        find.text(t.enseignant.salle.suivante),
      );
      expect(precedente.dy, suivante.dy);
      expect(precedente.dx, lessThan(suivante.dx));
      expect(tester.takeException(), isNull);
    });
  });
}

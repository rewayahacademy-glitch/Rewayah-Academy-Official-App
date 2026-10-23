// AVIS-PUBLICS : le formulaire d'avis, sans compte.
//
// Ce que le test prouve : les etats (chargement, formulaire, envoi, envoye,
// lien ferme, erreur, hors ligne, port absent) ; les textes exacts de la
// decision (aide du nom, case d'accord, phrase de moderation et de retrait,
// regles de moderation) ; un formulaire incomplet n'envoie rien et nomme ce
// qui manque ; la case d'accord est obligatoire ; un envoi valide part avec
// les bonnes valeurs ; chaque erreur du serveur (champ 22023, lien P0002)
// a sa phrase ; 320 px, texte x2, francais et arabe, LTR et RTL.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/avis_demonstration.dart';
import 'package:rewayah_academy/core/capacites/port_avis.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/note_etoiles.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/avis_public/avis_public_page.dart';
import 'package:rewayah_academy/features/salle_seance/information_controle.dart'
    show coupuresAdresse;

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';

final DateTime _maintenant = DateTime(2026, 10, 19, 10);

AvisDemonstration _port({Set<String> ouverts = const <String>{'ouvert'}}) =>
    AvisDemonstration(ouverts: ouverts, maintenant: () => _maintenant);

Future<void> _monter(
  WidgetTester tester,
  PortAvis? port, {
  String jeton = 'ouvert',
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
}) => monterRecrutement(
  tester,
  chemin: '/avis/:jeton',
  depart: '/avis/$jeton',
  ecran: (state) => AvisPublicPage(jeton: state.pathParameters['jeton']!),
  surcharges: <Override>[
    if (port != null) portAvisProvider.overrideWithValue(port),
    horlogeAvisProvider.overrideWithValue(() => _maintenant),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

final Finder _envoyer = find.byKey(AvisPublicPage.envoyerKey);

Finder _champ(Key cle) =>
    find.descendant(of: find.byKey(cle), matching: find.byType(TextField));

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await laisser(tester);
}

Future<void> _ecrire(WidgetTester tester, Key cle, String texte) async {
  await tester.ensureVisible(_champ(cle));
  await tester.enterText(_champ(cle), texte);
  await laisser(tester, fois: 2);
}

const String _texteValide =
    'Les cours sont réguliers et les enseignants sont patients avec les enfants.';

/// Remplit tout le formulaire sauf ce qui est demande en [sauf].
Future<void> _remplir(
  WidgetTester tester, {
  Set<ChampAvis> sauf = const <ChampAvis>{},
  String texte = _texteValide,
}) async {
  if (!sauf.contains(ChampAvis.nom)) {
    await _ecrire(tester, AvisPublicPage.nomKey, '  Awa B.  ');
  }
  if (!sauf.contains(ChampAvis.qualite)) {
    await _taper(
      tester,
      find.byKey(AvisPublicPage.qualiteKey(QualiteAvis.parent)),
    );
  }
  if (!sauf.contains(ChampAvis.pays)) {
    await _taper(tester, find.byKey(AvisPublicPage.paysKey));
    await tester.enterText(find.byKey(AvisPublicPage.rechercheKey), 'guin');
    await laisser(tester, fois: 2);
    await tester.tap(find.byKey(AvisPublicPage.paysListeKey('GN')));
    await laisser(tester);
  }
  if (!sauf.contains(ChampAvis.depuis)) {
    await _taper(tester, find.byKey(AvisPublicPage.moisKey));
    await tester.tap(find.text('mars').last);
    await laisser(tester);
    await _taper(tester, find.byKey(AvisPublicPage.anneeKey));
    await tester.tap(find.text('2024').last);
    await laisser(tester);
  }
  if (!sauf.contains(ChampAvis.note)) {
    await _taper(tester, find.byKey(NoteEtoiles.etoileKey(4)));
  }
  if (!sauf.contains(ChampAvis.texte)) {
    await _ecrire(tester, AvisPublicPage.texteKey, texte);
  }
  if (!sauf.contains(ChampAvis.accord)) {
    await _taper(tester, find.byKey(AvisPublicPage.accordKey));
  }
}

void main() {
  final f = t.avis.form;

  group('textes de la decision', () {
    testWidgets('champs, aide, accord, moderation et regles', (tester) async {
      await _monter(tester, _port());
      expect(find.text(f.titre), findsWidgets);
      expect(find.text(f.nom.libelle), findsWidgets);
      expect(
        find.text("Votre prénom et l'initiale de votre nom suffisent."),
        findsOneWidget,
      );
      expect(find.text(f.qualite.parent), findsOneWidget);
      expect(find.text(f.qualite.eleveAdulte), findsOneWidget);
      expect(find.text(f.pays.libelle), findsWidgets);
      expect(find.text(f.depuis.libelle), findsWidgets);
      expect(find.text(f.note.libelle), findsWidgets);
      expect(find.text(f.titreAvis.libelle), findsWidgets);
      expect(find.text(f.texte.libelle), findsWidgets);
      expect(
        find.text(
          "J'accepte que cet avis, mon nom affiché, mon pays et la date "
          'soient publiés sur le site de Rewayah Academy.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          coupuresAdresse(
            "Votre avis sera lu par la direction avant d'être publié. Pour le "
            'faire retirer plus tard, écrivez à support@rewayahacademy.com.',
          ),
        ),
        findsOneWidget,
      );
      // Les regles de moderation, en bref.
      expect(find.text(f.regles.titre), findsOneWidget);
      expect(find.text(f.regles.insulte), findsOneWidget);
      expect(find.text(f.regles.tiers), findsOneWidget);
      expect(find.text(f.regles.publicite), findsOneWidget);
      expect(find.text(f.regles.horsSujet), findsOneWidget);
      expect(find.text(f.regles.doublon), findsOneWidget);
      // Jamais le nom d'un enfant, un courriel ou un telephone.
      expect(find.text(f.regles.donnees), findsOneWidget);
      expect(find.textContaining('vérifié'), findsNothing);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('la case d accord n est jamais precochee', (tester) async {
      await _monter(tester, _port());
      final Checkbox case_ = tester.widget<Checkbox>(
        find.descendant(
          of: find.byKey(AvisPublicPage.accordKey),
          matching: find.byType(Checkbox),
        ),
      );
      expect(case_.value, isFalse);
    });

    testWidgets('le compteur suit la saisie', (tester) async {
      await _monter(tester, _port());
      expect(find.text(f.texte.compteur(n: 0, max: 1500)), findsOneWidget);
      await _ecrire(tester, AvisPublicPage.texteKey, 'abcde');
      expect(find.text(f.texte.compteur(n: 5, max: 1500)), findsOneWidget);
    });

    testWidgets('les etoiles se lisent une a une pour le lecteur d ecran', (
      tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _monter(tester, _port());
      for (int n = 1; n <= 5; n++) {
        expect(find.bySemanticsLabel(f.note.etoile(n: n)), findsOneWidget);
      }
      await _taper(tester, find.byKey(NoteEtoiles.etoileKey(3)));
      expect(
        tester.getSemantics(find.byKey(NoteEtoiles.etoileKey(3))),
        isSemantics(label: f.note.etoile(n: 3), isSelected: true),
      );
      h.dispose();
    });
  });

  group('pays et date', () {
    testWidgets('la liste des pays se cherche par nom, sans accent', (
      tester,
    ) async {
      await _monter(tester, _port());
      await _taper(tester, find.byKey(AvisPublicPage.paysKey));
      await tester.enterText(find.byKey(AvisPublicPage.rechercheKey), 'cote');
      await laisser(tester, fois: 2);
      expect(find.byKey(AvisPublicPage.paysListeKey('CI')), findsOneWidget);
      await tester.enterText(find.byKey(AvisPublicPage.rechercheKey), 'zzzz');
      await laisser(tester, fois: 2);
      expect(find.text(f.pays.aucun), findsOneWidget);
    });

    testWidgets('le pays choisi s affiche par son nom', (tester) async {
      await _monter(tester, _port());
      await _taper(tester, find.byKey(AvisPublicPage.paysKey));
      await tester.enterText(find.byKey(AvisPublicPage.rechercheKey), 'france');
      await laisser(tester, fois: 2);
      await tester.tap(find.byKey(AvisPublicPage.paysListeKey('FR')));
      await laisser(tester);
      expect(find.text('France'), findsOneWidget);
    });

    testWidgets('les annees vont de 2015 a l annee courante', (tester) async {
      await _monter(tester, _port());
      await _taper(tester, find.byKey(AvisPublicPage.anneeKey));
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2015'), findsOneWidget);
      expect(find.text('2014'), findsNothing);
      expect(find.text('2027'), findsNothing);
    });

    testWidgets('un mois futur est refuse, sans rien envoyer', (tester) async {
      final AvisDemonstration p = _port();
      await _monter(tester, p);
      await _remplir(tester, sauf: <ChampAvis>{ChampAvis.depuis});
      await _taper(tester, find.byKey(AvisPublicPage.moisKey));
      await tester.tap(find.text('décembre').last);
      await laisser(tester);
      await _taper(tester, find.byKey(AvisPublicPage.anneeKey));
      await tester.tap(find.text('2026').last);
      await laisser(tester);
      await _taper(tester, _envoyer);
      expect(
        find.byKey(AvisPublicPage.erreurKey(ChampAvis.depuis)),
        findsOneWidget,
      );
      expect(p.depots, isEmpty);
    });
  });

  group('validation', () {
    testWidgets('formulaire vide : rien ne part, chaque champ est nomme', (
      tester,
    ) async {
      final AvisDemonstration p = _port();
      await _monter(tester, p);
      // Pas d'erreur avant la premiere tentative.
      expect(find.byKey(AvisPublicPage.erreurKey(ChampAvis.nom)), findsNothing);
      await _taper(tester, _envoyer);
      expect(p.depots, isEmpty);
      expect(find.text(f.aCorriger), findsOneWidget);
      for (final ChampAvis c in <ChampAvis>[
        ChampAvis.nom,
        ChampAvis.qualite,
        ChampAvis.pays,
        ChampAvis.depuis,
        ChampAvis.note,
        ChampAvis.texte,
        ChampAvis.accord,
      ]) {
        expect(
          find.byKey(AvisPublicPage.erreurKey(c)),
          findsOneWidget,
          reason: c.name,
        );
      }
      // Le titre est facultatif.
      expect(
        find.byKey(AvisPublicPage.erreurKey(ChampAvis.titre)),
        findsNothing,
      );
    });

    testWidgets('la case d accord est obligatoire', (tester) async {
      final AvisDemonstration p = _port();
      await _monter(tester, p);
      await _remplir(tester, sauf: <ChampAvis>{ChampAvis.accord});
      await _taper(tester, _envoyer);
      expect(p.depots, isEmpty);
      expect(find.text(f.accord.erreur), findsOneWidget);
      // Cocher la case efface l'erreur et ouvre l'envoi.
      await _taper(tester, find.byKey(AvisPublicPage.accordKey));
      expect(find.text(f.accord.erreur), findsNothing);
      await _taper(tester, _envoyer);
      expect(p.depots, hasLength(1));
    });

    testWidgets('nom trop court, avis trop court, titre trop long', (
      tester,
    ) async {
      final AvisDemonstration p = _port();
      await _monter(tester, p);
      await _remplir(tester, texte: 'trop court');
      await _ecrire(tester, AvisPublicPage.nomKey, 'A');
      await _ecrire(tester, AvisPublicPage.titreKey, 'T' * 81);
      await _taper(tester, _envoyer);
      expect(find.text(f.nom.erreur), findsOneWidget);
      expect(find.text(f.texte.erreur), findsOneWidget);
      expect(find.text(f.titreAvis.erreur), findsOneWidget);
      expect(p.depots, isEmpty);
    });

    testWidgets('1501 caracteres : refuse', (tester) async {
      final AvisDemonstration p = _port();
      await _monter(tester, p);
      await _remplir(tester, texte: 'a' * 1501);
      await _taper(tester, _envoyer);
      expect(find.text(f.texte.erreur), findsOneWidget);
      expect(p.depots, isEmpty);
    });
  });

  group('envoi', () {
    testWidgets('un formulaire valide part, puis le merci', (tester) async {
      final AvisDemonstration p = _port();
      await _monter(tester, p);
      await _remplir(tester);
      await _ecrire(tester, AvisPublicPage.titreKey, ' Très bien ');
      await _taper(tester, _envoyer);
      expect(p.depots, hasLength(1));
      final (String jeton, DepotAvis d) = p.depots.single;
      expect(jeton, 'ouvert');
      expect(d.nom, 'Awa B.');
      expect(d.qualite, QualiteAvis.parent);
      expect(d.pays, 'GN');
      expect(d.depuis, DateTime(2024, 3));
      expect(d.note, 4);
      expect(d.titre, 'Très bien');
      expect(d.texte, _texteValide);
      expect(d.accord, isTrue);
      // Le merci dit que la direction le lit avant la publication.
      expect(find.byKey(const ValueKey<String>('avis-envoye')), findsOneWidget);
      expect(find.text(f.envoye.titre), findsOneWidget);
      expect(
        find.text(
          coupuresAdresse(
            f.envoye.phrase(courriel: 'support@rewayahacademy.com'),
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('direction'), findsWidgets);
      expect(_envoyer, findsNothing);
    });

    testWidgets('titre vide : part sans titre', (tester) async {
      final AvisDemonstration p = _port();
      await _monter(tester, p);
      await _remplir(tester);
      await _taper(tester, _envoyer);
      expect(p.depots.single.$2.titre, isNull);
    });

    testWidgets('pendant l envoi, un second appui n envoie rien de plus', (
      tester,
    ) async {
      final AvisDemonstration p = _port();
      final Completer<void> libere = Completer<void>();
      p.retenueDepot = libere.future;
      await _monter(tester, p);
      await _remplir(tester);
      await _taper(tester, _envoyer);
      await _taper(tester, _envoyer);
      libere.complete();
      await laisser(tester);
      expect(p.depots, hasLength(1));
    });

    testWidgets('hors ligne : rien ne part, la saisie reste', (tester) async {
      final AvisDemonstration p = _port();
      await _monter(tester, p, horsLigne: true);
      await _remplir(tester);
      await _taper(tester, _envoyer);
      expect(p.depots, isEmpty);
      expect(find.text(f.horsLigne), findsOneWidget);
      expect(find.text(_texteValide), findsOneWidget);
    });

    testWidgets('coupure : non confirme, la saisie reste, on peut renvoyer', (
      tester,
    ) async {
      final AvisDemonstration p = _port()..erreurDepot = Exception('coupure');
      await _monter(tester, p);
      await _remplir(tester);
      await _taper(tester, _envoyer);
      expect(find.text(f.echec), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('avis-envoye')), findsNothing);
      expect(find.text(_texteValide), findsOneWidget);
      await _taper(tester, _envoyer);
      expect(p.depots, hasLength(1));
      expect(find.byKey(const ValueKey<String>('avis-envoye')), findsOneWidget);
    });

    testWidgets('22023 : le champ nomme est montre', (tester) async {
      final AvisDemonstration p = _port()
        ..erreurDepot = const ChampAvisInvalide(ChampAvis.pays);
      await _monter(tester, p);
      await _remplir(tester);
      await _taper(tester, _envoyer);
      expect(find.text(f.pays.erreur), findsOneWidget);
      // Choisir un autre pays efface l'erreur du serveur.
      await _taper(tester, find.byKey(AvisPublicPage.paysKey));
      await tester.enterText(find.byKey(AvisPublicPage.rechercheKey), 'france');
      await laisser(tester, fois: 2);
      await tester.tap(find.byKey(AvisPublicPage.paysListeKey('FR')));
      await laisser(tester);
      expect(find.text(f.pays.erreur), findsNothing);
    });

    testWidgets('22023 sans champ connu : une phrase generale', (tester) async {
      final AvisDemonstration p = _port()
        ..erreurDepot = const ChampAvisInvalide(null);
      await _monter(tester, p);
      await _remplir(tester);
      await _taper(tester, _envoyer);
      expect(find.text(f.erreurChamp), findsOneWidget);
    });

    testWidgets('P0002 a l envoi : le lien vient de se fermer', (tester) async {
      final AvisDemonstration p = _port()..erreurDepot = const LienAvisFerme();
      await _monter(tester, p);
      await _remplir(tester);
      await _taper(tester, _envoyer);
      expect(find.byKey(const ValueKey<String>('avis-ferme')), findsOneWidget);
      expect(find.text(f.ferme.titre), findsOneWidget);
      expect(_envoyer, findsNothing);
    });
  });

  group('etats', () {
    testWidgets('chargement', (tester) async {
      final Completer<bool> c = Completer<bool>();
      await _monter(tester, _AttentePort(c.future));
      expect(find.byType(Skeleton), findsWidgets);
      expect(_envoyer, findsNothing);
    });

    testWidgets('lien ferme : un message clair, aucun formulaire', (
      tester,
    ) async {
      await _monter(tester, _port(), jeton: 'inconnu');
      expect(find.byKey(const ValueKey<String>('avis-ferme')), findsOneWidget);
      expect(find.text(f.ferme.titre), findsOneWidget);
      expect(
        find.text(
          coupuresAdresse(
            f.ferme.phrase(courriel: 'support@rewayahacademy.com'),
          ),
        ),
        findsOneWidget,
      );
      expect(_envoyer, findsNothing);
      expect(find.byKey(AvisPublicPage.nomKey), findsNothing);
    });

    testWidgets('port absent : disponible au branchement serveur', (
      tester,
    ) async {
      await _monter(tester, null);
      expect(
        find.byKey(const ValueKey<String>('avis-indisponible')),
        findsOneWidget,
      );
      expect(find.text(f.indisponiblePhrase), findsOneWidget);
    });

    testWidgets('erreur : un Reessayer relit', (tester) async {
      final AvisDemonstration p = _port()..erreurLienOuvert = Exception('x');
      await _monter(tester, p);
      expect(find.byType(EtatSysteme), findsOneWidget);
      expect(find.text(f.erreurChargement), findsOneWidget);
      await tester.tap(find.text(t.commun.reessayer));
      await laisser(tester);
      expect(find.byKey(AvisPublicPage.nomKey), findsOneWidget);
    });

    testWidgets('hors ligne au chargement : ce qui manque est dit', (
      tester,
    ) async {
      final AvisDemonstration p = _port()..erreurLienOuvert = Exception('x');
      await _monter(tester, p, horsLigne: true);
      expect(
        find.byKey(const ValueKey<String>('avis-sans-donnees')),
        findsOneWidget,
      );
      expect(find.text(f.sansDonnees), findsOneWidget);
    });
  });

  group('gabarits', () {
    setUpAll(chargerPolicesDuDepot);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final TextDirection d in TextDirection.values) {
        testWidgets('${langue.name}, 320 px, texte x2, ${d.name}', (
          tester,
        ) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          expect(
            t.avis.form.titre,
            langue == AppLocale.ar ? 'شاركنا رأيك' : 'Donnez votre avis',
          );
          await _monter(
            tester,
            _port(),
            largeur: 320,
            echelle: 2,
            direction: d,
          );
          await _taper(tester, _envoyer);
          expect(tester.takeException(), isNull);
          verifierEcranSansMotCoupe(tester);
        });
      }
    }
  });
}

/// Un port dont la lecture de l'etat du lien attend.
class _AttentePort extends AvisIndisponibles {
  _AttentePort(this._etat);

  final Future<bool> _etat;

  @override
  Future<bool> lienOuvert(String jeton) => _etat;
}

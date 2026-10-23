// COURRIELS-1 : l'ecran « E-mails » de la direction.
//
// Ce que le test prouve : les cinq etats de chaque section et le port absent ;
// la validation avant tout envoi ; une mise en file dit « Envoi dans la
// minute », jamais « envoye » ; un double appui ne met qu'un e-mail en file ;
// un nouvel essai apres une reponse perdue rejoue la meme cle, une correction
// en tire une autre ; chaque refus du serveur a sa phrase ; la file se filtre,
// se relance seulement pour un e-mail non envoye ou annule ; les adresses
// d'envoi se lisent ; 320 px, texte x2, francais et arabe, LTR et RTL.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/courriels_demonstration.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_courriels.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_courriels/courriels_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';
import '../../support/selecteur_section.dart';

final DateTime _maintenant = DateTime(2026, 10, 23, 10);

CourrielSortant _courriel({
  String id = 'c1',
  StatutCourriel statut = StatutCourriel.envoye,
  String? sujet = 'Bonjour',
  String adresse = 'awa@exemple.com',
  OrigineCourriel origine = OrigineCourriel.manuel,
  String? erreur,
  int tentatives = 1,
}) => CourrielSortant(
  id: id,
  categorie: 'direction',
  modele: sujet == null ? 'invitation_foyer' : 'message_libre',
  destinataire: adresse,
  origine: origine,
  statut: statut,
  tentatives: tentatives,
  derniereErreur: erreur,
  creeLe: DateTime(2026, 10, 23, 9, 30),
  envoyeLe: statut == StatutCourriel.envoye
      ? DateTime(2026, 10, 23, 9, 31)
      : null,
  sujet: sujet,
);

CourrielsDemonstration _port({
  List<CourrielSortant> courriels = const <CourrielSortant>[],
}) =>
    CourrielsDemonstration(courriels: courriels, maintenant: () => _maintenant);

int _compteur = 0;

Future<void> _monter(
  WidgetTester tester,
  PortCourriels? port, {
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
}) {
  _compteur = 0;
  return monterRecrutement(
    tester,
    chemin: '/admin/operations/courriels',
    ecran: (_) => CourrielsAdminPage(genererCle: () => 'cle-${++_compteur}'),
    surcharges: <Override>[
      if (port != null) portCourrielsProvider.overrideWithValue(port),
    ],
    horsLigne: horsLigne,
    largeur: largeur,
    echelle: echelle,
    direction: direction,
  );
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await laisser(tester);
}

Future<void> _section(WidgetTester tester, String libelle) async {
  await choisirSection(tester, libelle);
  await laisser(tester);
}

Future<void> _ecrire(WidgetTester tester, Key cle, String texte) async {
  final Finder champ = find.descendant(
    of: find.byKey(cle),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(champ);
  await tester.enterText(champ, texte);
  await laisser(tester, fois: 2);
}

Future<void> _remplir(WidgetTester tester) async {
  await _ecrire(tester, CourrielsAdminPage.adresseKey, 'awa@exemple.com');
  await _taper(
    tester,
    find.byKey(CourrielsAdminPage.categorieCarteKey('direction')),
  );
  await _ecrire(tester, CourrielsAdminPage.sujetKey, 'Bonjour');
  await _ecrire(tester, CourrielsAdminPage.corpsKey, 'Un message.');
}

Future<void> _envoyer(WidgetTester tester) =>
    _taper(tester, find.byKey(CourrielsAdminPage.envoyerKey));

void main() {
  final a = t.courriels.admin;

  // Les vraies polices : sous la police de test, les mots sont trop larges et
  // le selecteur de sections passe en menu.
  setUpAll(chargerPolicesDuDepot);

  group('ecrire : contenu et validation', () {
    testWidgets(
      'les champs, les categories avec leur alias, un seul bouton plein',
      (tester) async {
        await _monter(tester, _port());
        expect(find.byKey(CourrielsAdminPage.adresseKey), findsOneWidget);
        expect(find.byKey(CourrielsAdminPage.sujetKey), findsOneWidget);
        expect(find.byKey(CourrielsAdminPage.corpsKey), findsOneWidget);
        expect(find.text('Message de la direction'), findsOneWidget);
        expect(
          find.text(a.ecrire.partDe(adresse: 'invoice@rewayahacademy.com')),
          findsOneWidget,
        );
        // Une categorie facultative dit qu'elle porte un lien de desinscription.
        expect(find.text(a.ecrire.desinscription), findsOneWidget);
        // Choix fermes : aucune carte « Autre ».
        expect(find.text(t.choix.autre), findsNothing);
        verifierUnSeulBoutonPlein(tester);
      },
    );

    testWidgets(
      'formulaire vide : chaque champ dit ce qui manque, rien ne part',
      (tester) async {
        final CourrielsDemonstration p = _port();
        await _monter(tester, p);
        await _envoyer(tester);
        expect(find.text(a.ecrire.champ.adresse), findsOneWidget);
        expect(find.text(a.ecrire.champ.categorie), findsOneWidget);
        expect(find.text(a.ecrire.champ.sujet), findsOneWidget);
        expect(find.text(a.ecrire.champ.corps), findsOneWidget);
        expect(p.appelsEnvoi, 0);
      },
    );

    testWidgets('adresse sans arobase, sujet trop long : refus local', (
      tester,
    ) async {
      final CourrielsDemonstration p = _port();
      await _monter(tester, p);
      await _remplir(tester);
      await _ecrire(tester, CourrielsAdminPage.adresseKey, 'pas-une-adresse');
      await _ecrire(tester, CourrielsAdminPage.sujetKey, 'x' * 121);
      await _envoyer(tester);
      expect(find.text(a.ecrire.champ.adresse), findsOneWidget);
      expect(find.text(a.ecrire.champ.sujet), findsOneWidget);
      expect(find.text(a.ecrire.champ.corps), findsNothing);
      expect(p.appelsEnvoi, 0);
    });
  });

  group('ecrire : envoi', () {
    testWidgets('mise en file : « Envoi dans la minute », jamais « envoye »', (
      tester,
    ) async {
      final CourrielsDemonstration p = _port();
      await _monter(tester, p);
      await _remplir(tester);
      await _envoyer(tester);
      expect(p.envois, hasLength(1));
      expect(p.envois.single.$2, 'direction');
      expect(p.envois.single.$3, 'awa@exemple.com');
      expect(p.envois.single.$4, 'Bonjour');
      expect(p.envois.single.$5, 'Un message.');
      expect(find.text(a.ecrire.retour.misEnFile), findsOneWidget);
      expect(find.text(a.file.statut.envoye), findsNothing);
      // Le formulaire est vide : on peut ecrire le suivant.
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(CourrielsAdminPage.sujetKey),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        isEmpty,
      );
      // La ligne est en file, pas envoyee.
      await _taper(tester, find.byKey(CourrielsAdminPage.voirKey));
      expect(find.text(a.file.statut.enAttente), findsWidgets);
      expect(find.text(a.file.statut.envoye), findsNothing);
      expect(find.text(isolerSens('Bonjour')), findsOneWidget);
    });

    testWidgets('double appui : un seul e-mail en file', (tester) async {
      final CourrielsDemonstration p = _port();
      final Completer<void> retenue = Completer<void>();
      p.retenueEnvoi = retenue.future;
      await _monter(tester, p);
      await _remplir(tester);
      final Finder bouton = find.byKey(CourrielsAdminPage.envoyerKey);
      await tester.ensureVisible(bouton);
      await tester.tap(bouton);
      await tester.pump();
      await tester.tap(bouton, warnIfMissed: false);
      await tester.pump();
      retenue.complete();
      await laisser(tester);
      expect(p.appelsEnvoi, 1);
      expect(p.envois, hasLength(1));
    });

    testWidgets(
      'reponse perdue : le nouvel essai rejoue la meme cle, une correction en tire une autre',
      (tester) async {
        final CourrielsDemonstration p = _port()
          ..erreurEnvoi = Exception('reponse perdue');
        await _monter(tester, p);
        await _remplir(tester);
        await _envoyer(tester);
        expect(find.text(a.ecrire.retour.echec), findsOneWidget);
        expect(p.envois, isEmpty);
        await _envoyer(tester);
        expect(p.envois, hasLength(1));
        expect(p.clesVues, hasLength(2));
        expect(p.clesVues[0], p.clesVues[1]);

        // Un autre e-mail, avec une correction apres un echec : autre cle.
        p.erreurEnvoi = Exception('reponse perdue');
        await _remplir(tester);
        await _envoyer(tester);
        final String avant = p.clesVues.last;
        await _ecrire(
          tester,
          CourrielsAdminPage.corpsKey,
          'Un message corrige.',
        );
        await _envoyer(tester);
        expect(p.clesVues.last, isNot(avant));
        expect(p.envois, hasLength(2));
      },
    );

    for (final (ChampCourriel c, String Function() phrase)
        in <(ChampCourriel, String Function())>[
          (ChampCourriel.adresse, () => a.ecrire.champ.adresse),
          (ChampCourriel.categorie, () => a.ecrire.champ.categorie),
          (ChampCourriel.sujet, () => a.ecrire.champ.sujet),
          (ChampCourriel.corps, () => a.ecrire.champ.corps),
          (
            ChampCourriel.destinataireExclu,
            () => a.ecrire.champ.destinataireExclu,
          ),
        ]) {
      testWidgets('refus du serveur : ${c.name} a sa phrase', (tester) async {
        final CourrielsDemonstration p = _port()
          ..erreurEnvoi = CourrielInvalide(c);
        await _monter(tester, p);
        await _remplir(tester);
        await _envoyer(tester);
        expect(
          tester.widget<Text>(find.byKey(CourrielsAdminPage.retourKey)).data,
          phrase(),
        );
        expect(p.envois, isEmpty);
      });
    }

    testWidgets('droits refuses', (tester) async {
      final CourrielsDemonstration p = _port()
        ..erreurEnvoi = const PermissionInsuffisante('x');
      await _monter(tester, p);
      await _remplir(tester);
      await _envoyer(tester);
      expect(find.text(a.ecrire.retour.refus), findsOneWidget);
    });

    testWidgets('hors ligne : rien ne part', (tester) async {
      final CourrielsDemonstration p = _port();
      await _monter(tester, p, horsLigne: true);
      await _remplir(tester);
      await _envoyer(tester);
      expect(find.text(a.ecrire.retour.horsLigne), findsOneWidget);
      expect(p.appelsEnvoi, 0);
    });
  });

  group('ecrire : etats des categories', () {
    testWidgets('chargement', (tester) async {
      final Completer<void> c = Completer<void>();
      await _monter(tester, _AttenteCategories(c.future));
      expect(find.byType(Skeleton), findsWidgets);
    });

    testWidgets('erreur : Reessayer relit', (tester) async {
      final CourrielsDemonstration p = _port()
        ..erreurCategories = Exception('panne');
      await _monter(tester, p);
      expect(find.text(a.ecrire.erreurCategories), findsOneWidget);
      await tester.tap(find.text(t.commun.reessayer));
      await laisser(tester);
      expect(find.text('Message de la direction'), findsOneWidget);
    });

    testWidgets('hors ligne : ce qui manque est dit', (tester) async {
      final CourrielsDemonstration p = _port()
        ..erreurCategories = Exception('reseau');
      await _monter(tester, p, horsLigne: true);
      expect(find.text(a.ecrire.sansDonneesCategories), findsOneWidget);
    });

    testWidgets('aucune categorie active : une phrase', (tester) async {
      final CourrielsDemonstration p = CourrielsDemonstration(
        categories: <CategorieCourriel>[
          for (final CategorieCourriel c
              in CourrielsDemonstration.categoriesDeDepart)
            CategorieCourriel(
              code: c.code,
              libelle: c.libelle,
              expediteurAdresse: c.expediteurAdresse,
              expediteurNom: c.expediteurNom,
              repondreA: c.repondreA,
              essentielle: c.essentielle,
              active: false,
            ),
        ],
      );
      await _monter(tester, p);
      expect(find.text(a.ecrire.pasDeCategorie), findsOneWidget);
    });

    testWidgets('port absent', (tester) async {
      await _monter(tester, null);
      expect(
        find.byKey(const ValueKey<String>('courriel-categories-indisponible')),
        findsOneWidget,
      );
      await _section(tester, a.sections.file);
      expect(
        find.byKey(const ValueKey<String>('courriels-file-indisponible')),
        findsOneWidget,
      );
      expect(find.text(a.indisponiblePhrase), findsOneWidget);
    });
  });

  group('envois', () {
    final List<CourrielSortant> file = <CourrielSortant>[
      _courriel(),
      _courriel(
        id: 'c2',
        statut: StatutCourriel.echec,
        sujet: 'Rappel',
        erreur: 'boite pleine',
        tentatives: 5,
      ),
      _courriel(id: 'c3', statut: StatutCourriel.enAttente, tentatives: 0),
      _courriel(
        id: 'c4',
        statut: StatutCourriel.annule,
        sujet: null,
        origine: OrigineCourriel.auto,
        tentatives: 0,
      ),
    ];

    testWidgets('contenu : champs, statuts, relance seulement si non envoye', (
      tester,
    ) async {
      await _monter(tester, _port(courriels: file));
      await _section(tester, a.sections.file);
      expect(find.text(isolerSens('Bonjour')), findsWidgets);
      expect(find.text(isolerSens('awa@exemple.com')), findsWidgets);
      expect(find.text(isolerSens('Message de la direction')), findsWidgets);
      expect(find.text(a.file.statut.envoye), findsOneWidget);
      expect(find.text(a.file.statut.echec), findsOneWidget);
      expect(find.text(a.file.statut.enAttente), findsWidgets);
      expect(find.text(a.file.statut.annule), findsOneWidget);
      expect(find.text(a.file.messageAuto), findsOneWidget);
      expect(find.text(isolerSens('boite pleine')), findsOneWidget);
      expect(find.byKey(CourrielsAdminPage.reessayerKey('c1')), findsNothing);
      expect(find.byKey(CourrielsAdminPage.reessayerKey('c3')), findsNothing);
      expect(find.byKey(CourrielsAdminPage.reessayerKey('c2')), findsOneWidget);
      expect(find.byKey(CourrielsAdminPage.reessayerKey('c4')), findsOneWidget);
    });

    testWidgets('filtres par statut', (tester) async {
      await _monter(tester, _port(courriels: file));
      await _section(tester, a.sections.file);
      await _taper(
        tester,
        find.byKey(CourrielsAdminPage.filtreKey(StatutCourriel.echec)),
      );
      expect(find.byKey(CourrielsAdminPage.carteKey('c2')), findsOneWidget);
      expect(find.byKey(CourrielsAdminPage.carteKey('c1')), findsNothing);
      await _taper(
        tester,
        find.byKey(CourrielsAdminPage.filtreKey(StatutCourriel.envoye)),
      );
      expect(find.byKey(CourrielsAdminPage.carteKey('c1')), findsOneWidget);
      expect(find.byKey(CourrielsAdminPage.carteKey('c2')), findsNothing);
    });

    testWidgets(
      'remettre en file : la ligne repart en file, la file est relue',
      (tester) async {
        final CourrielsDemonstration p = _port(courriels: file);
        await _monter(tester, p);
        await _section(tester, a.sections.file);
        final int avant = p.lecturesFile;
        await _taper(tester, find.byKey(CourrielsAdminPage.reessayerKey('c2')));
        expect(p.relances, 1);
        expect(find.text(a.file.retour.relance), findsOneWidget);
        expect(p.lecturesFile, greaterThan(avant));
        expect(find.byKey(CourrielsAdminPage.reessayerKey('c2')), findsNothing);
      },
    );

    testWidgets('relance refusee : l e-mail n est plus a relancer', (
      tester,
    ) async {
      final CourrielsDemonstration p = _port(courriels: file)
        ..erreurRelance = const CourrielIntrouvable();
      await _monter(tester, p);
      await _section(tester, a.sections.file);
      await _taper(tester, find.byKey(CourrielsAdminPage.reessayerKey('c2')));
      expect(find.text(a.file.retour.introuvable), findsOneWidget);
    });

    testWidgets('relance non confirmee', (tester) async {
      final CourrielsDemonstration p = _port(courriels: file)
        ..erreurRelance = Exception('panne');
      await _monter(tester, p);
      await _section(tester, a.sections.file);
      await _taper(tester, find.byKey(CourrielsAdminPage.reessayerKey('c2')));
      expect(find.text(a.file.retour.echec), findsOneWidget);
    });

    testWidgets('relance hors ligne : rien ne part', (tester) async {
      await _monter(tester, _port(courriels: file), horsLigne: true);
      await _section(tester, a.sections.file);
      await _taper(tester, find.byKey(CourrielsAdminPage.reessayerKey('c2')));
      expect(find.text(a.file.retour.horsLigne), findsOneWidget);
    });

    testWidgets('Actualiser relit la file', (tester) async {
      final CourrielsDemonstration p = _port();
      await _monter(tester, p);
      await _section(tester, a.sections.file);
      expect(find.text(a.file.vide), findsOneWidget);
      p.file.add(_courriel());
      await _taper(tester, find.byKey(CourrielsAdminPage.actualiserKey));
      expect(find.byKey(CourrielsAdminPage.carteKey('c1')), findsOneWidget);
    });

    testWidgets('chargement', (tester) async {
      final Completer<void> c = Completer<void>();
      await _monter(tester, _AttenteFile(c.future));
      await _section(tester, a.sections.file);
      expect(find.byType(Skeleton), findsWidgets);
    });

    testWidgets('vide', (tester) async {
      await _monter(tester, _port());
      await _section(tester, a.sections.file);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(a.file.vide), findsOneWidget);
    });

    testWidgets('erreur : Reessayer relit', (tester) async {
      final CourrielsDemonstration p = _port(courriels: file)
        ..erreurListe = Exception('panne');
      await _monter(tester, p);
      await _section(tester, a.sections.file);
      expect(find.byType(EtatSysteme), findsOneWidget);
      expect(find.text(a.file.erreur), findsOneWidget);
      await tester.tap(find.text(t.commun.reessayer));
      await laisser(tester);
      expect(find.byKey(CourrielsAdminPage.carteKey('c1')), findsOneWidget);
    });

    testWidgets('hors ligne : ce qui manque est dit', (tester) async {
      final CourrielsDemonstration p = _port()
        ..erreurListe = Exception('reseau');
      await _monter(tester, p, horsLigne: true);
      await _section(tester, a.sections.file);
      expect(
        find.byKey(const ValueKey<String>('courriels-file-sans-donnees')),
        findsOneWidget,
      );
      expect(find.text(a.file.sansDonnees), findsOneWidget);
    });

    testWidgets('lecture refusee : une phrase, aucune action', (tester) async {
      final CourrielsDemonstration p = _port(courriels: file)
        ..erreurListe = const PermissionInsuffisante('x');
      await _monter(tester, p);
      await _section(tester, a.sections.file);
      expect(find.text(a.refuse), findsOneWidget);
      expect(find.byKey(CourrielsAdminPage.reessayerKey('c2')), findsNothing);
    });
  });

  group('adresses d envoi', () {
    testWidgets('chaque categorie dit son alias, en lecture seule', (
      tester,
    ) async {
      await _monter(tester, _port());
      await _section(tester, a.sections.adresses);
      expect(
        find.byKey(CourrielsAdminPage.categorieCarteKey('direction')),
        findsOneWidget,
      );
      expect(find.text(isolerSens('invoice@rewayahacademy.com')), findsWidgets);
      expect(
        find.text(isolerSens('Rewayah Academy · Facturation')),
        findsOneWidget,
      );
      expect(find.text(a.adresses.essentielle), findsWidgets);
      expect(find.text(a.adresses.facultative), findsOneWidget);
      expect(find.text(a.adresses.active), findsWidgets);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('chargement', (tester) async {
      final Completer<void> c = Completer<void>();
      await _monter(tester, _AttenteCategories(c.future));
      await _section(tester, a.sections.adresses);
      expect(find.byType(Skeleton), findsWidgets);
    });

    testWidgets('vide', (tester) async {
      await _monter(
        tester,
        CourrielsDemonstration(categories: <CategorieCourriel>[]),
      );
      await _section(tester, a.sections.adresses);
      expect(find.text(a.adresses.vide), findsOneWidget);
    });

    testWidgets('erreur', (tester) async {
      final CourrielsDemonstration p = _port()
        ..erreurCategories = Exception('panne');
      await _monter(tester, p);
      await _section(tester, a.sections.adresses);
      expect(find.text(a.adresses.erreur), findsOneWidget);
    });

    testWidgets('hors ligne : ce qui manque est dit', (tester) async {
      final CourrielsDemonstration p = _port()
        ..erreurCategories = Exception('reseau');
      await _monter(tester, p, horsLigne: true);
      await _section(tester, a.sections.adresses);
      expect(find.text(a.adresses.sansDonnees), findsOneWidget);
    });
  });

  group('gabarits', () {
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final TextDirection d in TextDirection.values) {
        testWidgets('${langue.name}, 320 px, texte x2, ${d.name}', (
          tester,
        ) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          await _monter(
            tester,
            _port(
              courriels: <CourrielSortant>[
                _courriel(),
                _courriel(
                  id: 'c2',
                  statut: StatutCourriel.echec,
                  erreur: 'boite pleine',
                ),
              ],
            ),
            largeur: 320,
            echelle: 2,
            direction: d,
          );
          expect(tester.takeException(), isNull);
          verifierEcranSansMotCoupe(tester);
          await _envoyer(tester);
          expect(tester.takeException(), isNull);
          verifierEcranSansMotCoupe(tester);
          await _section(tester, t.courriels.admin.sections.file);
          expect(tester.takeException(), isNull);
          verifierEcranSansMotCoupe(
            tester,
            exceptions: <String>{'awa@exemple.com'},
          );
          await _section(tester, t.courriels.admin.sections.adresses);
          expect(tester.takeException(), isNull);
          verifierEcranSansMotCoupe(
            tester,
            exceptions: <String>{
              'contact@rewayahacademy.com',
              'invoice@rewayahacademy.com',
            },
          );
        });
      }
    }
  });
}

/// Un port dont la lecture des categories attend.
class _AttenteCategories extends CourrielsIndisponibles {
  _AttenteCategories(this._attente);

  final Future<void> _attente;

  @override
  Future<List<CategorieCourriel>> categories() async {
    await _attente;
    return <CategorieCourriel>[];
  }

  @override
  Future<List<CourrielSortant>> lister({
    StatutCourriel? statut,
    int limite = 100,
  }) async {
    await _attente;
    return <CourrielSortant>[];
  }
}

/// Un port dont la lecture de la file attend.
class _AttenteFile extends CourrielsDemonstration {
  _AttenteFile(this._attente);

  final Future<void> _attente;

  @override
  Future<List<CourrielSortant>> lister({
    StatutCourriel? statut,
    int limite = 100,
  }) async {
    await _attente;
    return <CourrielSortant>[];
  }
}

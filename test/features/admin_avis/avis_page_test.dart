// AVIS-PUBLICS : l'ecran de la direction (liens de collecte et moderation).
//
// Ce que le test prouve : les cinq etats de chaque section et le port absent ;
// tous les champs d'un avis ; le texte n'est jamais modifiable ; publier
// passe par une confirmation, refuser et retirer demandent un motif puis
// redisent la consequence ; renoncer n'envoie rien ; chaque refus du serveur a
// sa phrase et la liste est relue ; la creation d'un lien montre l'adresse
// complete une seule fois, avec un bouton pour la copier ; fermer un lien
// demande une confirmation ; 320 px, texte x2, francais et arabe, LTR et RTL.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/avis_demonstration.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_avis.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_avis/avis_page.dart';
import 'package:rewayah_academy/features/admin_avis/lien_avis.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';

final DateTime _maintenant = DateTime(2026, 10, 19, 10);

AvisAdmin _avis({
  String id = 'a1',
  String nom = 'Awa B.',
  StatutAvis statut = StatutAvis.enAttente,
  String? titre = 'Très bien',
  String? motif,
  int note = 4,
}) => AvisAdmin(
  id: id,
  lienLibelle: 'Familles octobre 2026',
  nomAffiche: nom,
  qualite: QualiteAvis.parent,
  pays: 'GN',
  depuis: DateTime(2024, 3),
  note: note,
  titre: titre,
  texte: 'Les cours sont réguliers et les enseignants sont patients.',
  accordPublicLe: DateTime(2026, 10, 18, 9),
  statut: statut,
  motif: motif,
  deposeLe: DateTime(2026, 10, 18, 9),
  modereLe: statut == StatutAvis.enAttente ? null : DateTime(2026, 10, 19, 8),
  publieLe: statut == StatutAvis.publie ? DateTime(2026, 10, 19, 8) : null,
);

LienAvis _lien({
  String id = 'l1',
  String libelle = 'Familles octobre 2026',
  bool ferme = false,
  bool actif = true,
  DateTime? expire,
  int recus = 12,
  int max = 200,
}) => LienAvis(
  id: id,
  libelle: libelle,
  creeLe: DateTime(2026, 10, 1),
  expireLe: expire ?? DateTime(2026, 12, 30),
  avisMax: max,
  avisRecus: recus,
  ferme: ferme,
  actif: actif,
);

AvisDemonstration _port({
  List<AvisAdmin> avis = const <AvisAdmin>[],
  List<LienAvis> liens = const <LienAvis>[],
}) =>
    AvisDemonstration(avis: avis, liens: liens, maintenant: () => _maintenant);

Future<void> _monter(
  WidgetTester tester,
  PortAvis? port, {
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
}) => monterRecrutement(
  tester,
  chemin: '/admin/operations/avis',
  ecran: (_) => AvisAdminPage(horloge: () => _maintenant),
  surcharges: <Override>[
    if (port != null) portAvisProvider.overrideWithValue(port),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await laisser(tester);
}

Future<void> _versLiens(WidgetTester tester) => _taper(
  tester,
  find.descendant(
    of: find.byKey(AvisAdminPage.sectionsKey),
    matching: find.text(t.avis.admin.sections.liens),
  ),
);

Future<void> _filtre(WidgetTester tester, StatutAvis? s) =>
    _taper(tester, find.byKey(AvisAdminPage.filtreKey(s)));

Future<void> _ecrire(WidgetTester tester, Key cle, String texte) async {
  final Finder champ = find.descendant(
    of: find.byKey(cle),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(champ);
  await tester.enterText(champ, texte);
  await laisser(tester, fois: 2);
}

void main() {
  final a = t.avis.admin;

  group('avis : contenu', () {
    testWidgets('tous les champs d un avis, et le geste de decision', (
      tester,
    ) async {
      await _monter(tester, _port(avis: <AvisAdmin>[_avis()]));
      expect(find.text(isolerSens('Awa B.')), findsOneWidget);
      expect(find.text(isolerSens('Très bien')), findsOneWidget);
      expect(
        find.text(
          isolerSens(
            'Les cours sont réguliers et les enseignants sont patients.',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(t.avis.form.qualite.parent), findsOneWidget);
      expect(find.text('Guinée'), findsOneWidget);
      expect(find.text('mars 2024'), findsOneWidget);
      expect(find.text(isolerSens('Familles octobre 2026')), findsOneWidget);
      expect(find.text(a.statut.enAttente), findsWidgets);
      expect(find.text(a.attente(n: 1)), findsOneWidget);
      expect(find.byKey(AvisAdminPage.publierKey('a1')), findsOneWidget);
      expect(find.byKey(AvisAdminPage.refuserKey('a1')), findsOneWidget);
      expect(find.byKey(AvisAdminPage.retirerKey('a1')), findsNothing);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('la direction ne peut jamais modifier le texte', (
      tester,
    ) async {
      await _monter(tester, _port(avis: <AvisAdmin>[_avis()]));
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('filtres : publies, refuses, retires, tous', (tester) async {
      await _monter(
        tester,
        _port(
          avis: <AvisAdmin>[
            _avis(),
            _avis(id: 'a2', nom: 'Bilal K.', statut: StatutAvis.publie),
            _avis(
              id: 'a3',
              nom: 'Cheikh D.',
              statut: StatutAvis.refuse,
              motif: 'Doublon',
            ),
            _avis(
              id: 'a4',
              nom: 'Dina M.',
              statut: StatutAvis.retire,
              motif: 'Demande de la personne',
            ),
          ],
        ),
      );
      expect(find.text(isolerSens('Awa B.')), findsOneWidget);
      expect(find.text(isolerSens('Bilal K.')), findsNothing);
      await _filtre(tester, StatutAvis.publie);
      expect(find.text(isolerSens('Bilal K.')), findsOneWidget);
      expect(find.byKey(AvisAdminPage.retirerKey('a2')), findsOneWidget);
      expect(find.byKey(AvisAdminPage.publierKey('a2')), findsNothing);
      await _filtre(tester, StatutAvis.refuse);
      expect(find.text(isolerSens('Cheikh D.')), findsOneWidget);
      expect(find.text(isolerSens('Doublon')), findsOneWidget);
      expect(find.byKey(AvisAdminPage.publierKey('a3')), findsNothing);
      await _filtre(tester, StatutAvis.retire);
      expect(find.text(isolerSens('Dina M.')), findsOneWidget);
      expect(find.text(isolerSens('Demande de la personne')), findsOneWidget);
      await _filtre(tester, null);
      expect(find.text(isolerSens('Awa B.')), findsOneWidget);
      expect(find.text(isolerSens('Dina M.')), findsOneWidget);
    });
  });

  group('avis : etats', () {
    testWidgets('chargement', (tester) async {
      final AvisDemonstration p = _port();
      final Completer<void> c = Completer<void>();
      await _monter(tester, _AttenteAvis(c.future, p));
      expect(find.byType(Skeleton), findsWidgets);
    });

    testWidgets('vide', (tester) async {
      await _monter(tester, _port());
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(a.vide), findsOneWidget);
    });

    testWidgets('port absent', (tester) async {
      await _monter(tester, null);
      expect(
        find.byKey(const ValueKey<String>('avis-admin-indisponible')),
        findsOneWidget,
      );
      expect(find.text(a.indisponiblePhrase), findsOneWidget);
    });

    testWidgets('erreur : Reessayer relit', (tester) async {
      final AvisDemonstration p = _port(avis: <AvisAdmin>[_avis()])
        ..erreurAvis = Exception('panne');
      await _monter(tester, p);
      expect(find.byType(EtatSysteme), findsOneWidget);
      expect(find.text(a.erreur), findsOneWidget);
      await tester.tap(find.text(t.commun.reessayer));
      await laisser(tester);
      expect(find.text(isolerSens('Awa B.')), findsOneWidget);
    });

    testWidgets('hors ligne : ce qui manque est dit', (tester) async {
      final AvisDemonstration p = _port()..erreurAvis = Exception('reseau');
      await _monter(tester, p, horsLigne: true);
      expect(
        find.byKey(const ValueKey<String>('avis-admin-sans-donnees')),
        findsOneWidget,
      );
      expect(find.text(a.sansDonnees), findsOneWidget);
    });

    testWidgets('lecture refusee : une phrase, aucune action', (tester) async {
      final AvisDemonstration p = _port()
        ..erreurAvis = const PermissionInsuffisante('x');
      await _monter(tester, p);
      expect(find.text(a.refuse), findsOneWidget);
      expect(find.byKey(AvisAdminPage.publierKey('a1')), findsNothing);
    });
  });

  group('moderation', () {
    testWidgets('publier : confirmation, puis la liste est relue', (
      tester,
    ) async {
      final AvisDemonstration p = _port(avis: <AvisAdmin>[_avis()]);
      await _monter(tester, p);
      await _taper(tester, find.byKey(AvisAdminPage.publierKey('a1')));
      // La confirmation dit ce qui va se passer ; rien n'est parti.
      expect(
        find.text(a.publier.question(deNom: deDevant('Awa B.'))),
        findsWidgets,
      );
      expect(find.text(a.publier.consequence), findsOneWidget);
      expect(p.avis.single.statut, StatutAvis.enAttente);
      final int avant = p.lecturesAvis;
      await tester.tap(find.text(a.publier.action).last);
      await laisser(tester);
      expect(p.avis.single.statut, StatutAvis.publie);
      expect(p.lecturesAvis, greaterThan(avant));
      expect(find.text(a.retour.publie), findsOneWidget);
      // L'avis quitte la liste « en attente ».
      expect(find.text(isolerSens('Awa B.')), findsNothing);
    });

    testWidgets('publier, renoncer : rien ne part', (tester) async {
      final AvisDemonstration p = _port(avis: <AvisAdmin>[_avis()]);
      await _monter(tester, p);
      await _taper(tester, find.byKey(AvisAdminPage.publierKey('a1')));
      await tester.tap(find.text(a.publier.rester).last);
      await laisser(tester);
      expect(p.avis.single.statut, StatutAvis.enAttente);
      expect(find.byKey(AvisAdminPage.retourKey), findsNothing);
    });

    testWidgets('refuser : le motif est obligatoire, puis motif garde', (
      tester,
    ) async {
      final AvisDemonstration p = _port(avis: <AvisAdmin>[_avis()]);
      await _monter(tester, p);
      await _taper(tester, find.byKey(AvisAdminPage.refuserKey('a1')));
      expect(find.text(a.refuser.intro), findsOneWidget);
      expect(find.text(a.refuser.consequence), findsOneWidget);
      // Les motifs de la decision sont proposes.
      for (final String m in <String>[
        a.motifs.insulte,
        a.motifs.tiers,
        a.motifs.publicite,
        a.motifs.horsSujet,
        a.motifs.doublon,
      ]) {
        expect(find.text(m), findsOneWidget, reason: m);
      }
      // Sans motif, rien ne part et le manque est dit.
      await tester.tap(find.byKey(AvisAdminPage.confirmerMotifKey));
      await laisser(tester);
      expect(find.text(t.formulaire.motif.manque), findsOneWidget);
      expect(p.avis.single.statut, StatutAvis.enAttente);
      await tester.tap(find.text(a.motifs.doublon));
      await laisser(tester);
      await tester.tap(find.byKey(AvisAdminPage.confirmerMotifKey));
      await laisser(tester);
      expect(p.avis.single.statut, StatutAvis.refuse);
      expect(p.avis.single.motif, a.motifs.doublon);
      expect(find.text(a.retour.refuse), findsOneWidget);
      // Le texte n'a pas bouge.
      expect(
        p.avis.single.texte,
        'Les cours sont réguliers et les enseignants sont patients.',
      );
    });

    testWidgets('refuser, renoncer : rien ne part', (tester) async {
      final AvisDemonstration p = _port(avis: <AvisAdmin>[_avis()]);
      await _monter(tester, p);
      await _taper(tester, find.byKey(AvisAdminPage.refuserKey('a1')));
      await tester.tap(find.text(a.refuser.rester));
      await laisser(tester);
      expect(p.avis.single.statut, StatutAvis.enAttente);
      expect(find.byKey(AvisAdminPage.retourKey), findsNothing);
    });

    testWidgets('retirer un avis publie : motif obligatoire', (tester) async {
      final AvisDemonstration p = _port(
        avis: <AvisAdmin>[_avis(statut: StatutAvis.publie)],
      );
      await _monter(tester, p);
      await _filtre(tester, StatutAvis.publie);
      await _taper(tester, find.byKey(AvisAdminPage.retirerKey('a1')));
      expect(find.text(a.retirer.consequence), findsOneWidget);
      // Le motif « demande de la personne » n'existe que pour un retrait.
      expect(find.text(a.motifs.demande), findsOneWidget);
      await tester.tap(find.byKey(AvisAdminPage.confirmerMotifKey));
      await laisser(tester);
      expect(p.avis.single.statut, StatutAvis.publie);
      await tester.tap(find.text(a.motifs.demande));
      await laisser(tester);
      await tester.tap(find.byKey(AvisAdminPage.confirmerMotifKey));
      await laisser(tester);
      expect(p.avis.single.statut, StatutAvis.retire);
      expect(p.avis.single.motif, a.motifs.demande);
      expect(find.text(a.retour.retire), findsOneWidget);
    });

    testWidgets('hors ligne : rien ne part', (tester) async {
      final AvisDemonstration p = _port(avis: <AvisAdmin>[_avis()]);
      await _monter(tester, p, horsLigne: true);
      await _taper(tester, find.byKey(AvisAdminPage.publierKey('a1')));
      await tester.tap(find.text(a.publier.action).last);
      await laisser(tester);
      expect(p.avis.single.statut, StatutAvis.enAttente);
      expect(find.text(a.retour.horsLigne), findsOneWidget);
    });

    final Map<RefusModeration, String> refus = <RefusModeration, String>{
      RefusModeration.etatChange: a.retour.etatChange,
      RefusModeration.introuvable: a.retour.introuvable,
      RefusModeration.motifManquant: a.retour.motifManque,
    };
    refus.forEach((RefusModeration r, String phrase) {
      testWidgets('refus du serveur ${r.name} : sa phrase, liste relue', (
        tester,
      ) async {
        final AvisDemonstration p = _port(avis: <AvisAdmin>[_avis()])
          ..erreurModeration = ModerationAvisRefusee(r);
        await _monter(tester, p);
        await _taper(tester, find.byKey(AvisAdminPage.publierKey('a1')));
        final int avant = p.lecturesAvis;
        await tester.tap(find.text(a.publier.action).last);
        await laisser(tester);
        expect(find.text(phrase), findsOneWidget);
        expect(p.lecturesAvis, greaterThan(avant));
      });
    });

    testWidgets('pas la direction : refus dit', (tester) async {
      final AvisDemonstration p = _port(avis: <AvisAdmin>[_avis()])
        ..erreurModeration = const PermissionInsuffisante('x');
      await _monter(tester, p);
      await _taper(tester, find.byKey(AvisAdminPage.publierKey('a1')));
      await tester.tap(find.text(a.publier.action).last);
      await laisser(tester);
      expect(find.text(a.retour.refus), findsOneWidget);
    });

    testWidgets('coupure : non confirme, la liste est relue', (tester) async {
      final AvisDemonstration p = _port(avis: <AvisAdmin>[_avis()])
        ..erreurModeration = Exception('coupure');
      await _monter(tester, p);
      await _taper(tester, find.byKey(AvisAdminPage.publierKey('a1')));
      final int avant = p.lecturesAvis;
      await tester.tap(find.text(a.publier.action).last);
      await laisser(tester);
      expect(find.text(a.retour.echec), findsOneWidget);
      expect(find.text(a.retour.publie), findsNothing);
      expect(p.lecturesAvis, greaterThan(avant));
    });
  });

  group('liens', () {
    testWidgets('liste : etat, recus sur max, fin, gestes', (tester) async {
      await _monter(
        tester,
        _port(
          liens: <LienAvis>[
            _lien(),
            _lien(id: 'l2', libelle: 'Ferme', ferme: true, actif: false),
            _lien(
              id: 'l3',
              libelle: 'Expire',
              actif: false,
              expire: DateTime(2026, 9, 1),
            ),
            _lien(
              id: 'l4',
              libelle: 'Complet',
              actif: false,
              recus: 200,
              max: 200,
            ),
          ],
        ),
      );
      await _versLiens(tester);
      expect(find.text(a.liens.etat.ouvert), findsOneWidget);
      expect(find.text(a.liens.etat.ferme), findsOneWidget);
      expect(find.text(a.liens.etat.expire), findsOneWidget);
      expect(find.text(a.liens.etat.plein), findsOneWidget);
      expect(find.text(a.liens.recus(recus: 12, max: 200)), findsNWidgets(3));
      // Seul un lien ouvert se ferme.
      expect(find.byKey(AvisAdminPage.fermerKey('l1')), findsOneWidget);
      expect(find.byKey(AvisAdminPage.fermerKey('l2')), findsNothing);
      expect(find.byKey(AvisAdminPage.fermerKey('l3')), findsNothing);
      expect(find.byKey(AvisAdminPage.fermerKey('l4')), findsNothing);
    });

    testWidgets('etat vide', (tester) async {
      await _monter(tester, _port());
      await _versLiens(tester);
      expect(find.text(a.liens.vide), findsOneWidget);
    });

    testWidgets('etat erreur', (tester) async {
      await _monter(tester, _port()..erreurLiens = Exception('x'));
      await _versLiens(tester);
      expect(find.text(a.liens.erreur), findsOneWidget);
    });

    testWidgets('etat hors ligne', (tester) async {
      await _monter(
        tester,
        _port()..erreurLiens = Exception('x'),
        horsLigne: true,
      );
      await _versLiens(tester);
      expect(find.text(a.liens.sansDonnees), findsOneWidget);
    });

    testWidgets('etat chargement', (tester) async {
      final Completer<void> c = Completer<void>();
      await _monter(tester, _AttenteLiens(c.future));
      await _versLiens(tester);
      expect(find.byType(Skeleton), findsWidgets);
    });

    testWidgets('port absent', (tester) async {
      await _monter(tester, null);
      await _versLiens(tester);
      expect(
        find.byKey(const ValueKey<String>('liens-indisponible')),
        findsOneWidget,
      );
    });

    testWidgets('valeurs par defaut : 90 jours, 200 avis', (tester) async {
      await _monter(tester, _port());
      await _versLiens(tester);
      expect(find.text('90'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('creer sans nom ou avec une duree hors borne : rien ne part', (
      tester,
    ) async {
      final AvisDemonstration p = _port();
      await _monter(tester, p);
      await _versLiens(tester);
      await _taper(tester, find.byKey(AvisAdminPage.creerKey));
      expect(find.text(a.liens.libelleErreur), findsOneWidget);
      expect(p.jetonsCrees, isEmpty);
      await _ecrire(tester, AvisAdminPage.libelleKey, 'Familles');
      await _ecrire(tester, AvisAdminPage.joursKey, '366');
      await _ecrire(tester, AvisAdminPage.maxKey, '2001');
      await _taper(tester, find.byKey(AvisAdminPage.creerKey));
      expect(find.text(a.liens.joursErreur), findsOneWidget);
      expect(find.text(a.liens.maxErreur), findsOneWidget);
      expect(p.jetonsCrees, isEmpty);
    });

    testWidgets('creer : l adresse complete est montree une seule fois', (
      tester,
    ) async {
      final AvisDemonstration p = _port();
      await _monter(tester, p);
      await _versLiens(tester);
      await _ecrire(tester, AvisAdminPage.libelleKey, '  Familles octobre  ');
      await _taper(tester, find.byKey(AvisAdminPage.creerKey));
      expect(p.jetonsCrees, <String>['jeton-l1']);
      expect(p.liens.single.libelle, 'Familles octobre');
      expect(p.liens.single.avisMax, 200);
      // L'adresse complete, une fois, avec l'avertissement.
      final String adresse = lienAvisPour('jeton-l1');
      expect(adresse, endsWith('/#/avis/jeton-l1'));
      expect(find.byKey(AvisAdminPage.creeKey), findsOneWidget);
      expect(find.text(adresse), findsOneWidget);
      expect(find.text(a.liens.creePhrase), findsOneWidget);
      // Le formulaire est vide pour le lien suivant.
      expect(
        find.text(isolerSens('Familles octobre')),
        findsOneWidget,
      ); // dans la liste
      // « Copier le lien » met l'adresse dans le presse-papiers.
      String? copie;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall appel) async {
          if (appel.method == 'Clipboard.setData') {
            copie =
                (appel.arguments as Map<Object?, Object?>)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _taper(tester, find.byKey(AvisAdminPage.copierKey));
      expect(copie, adresse);
      expect(find.text(a.liens.copie), findsOneWidget);
      // Une fois fermee, l'adresse ne revient plus.
      await _taper(tester, find.byKey(AvisAdminPage.creeFermerKey));
      expect(find.byKey(AvisAdminPage.creeKey), findsNothing);
      expect(find.text(adresse), findsNothing);
      expect(find.textContaining('jeton-l1'), findsNothing);
      // Meme en changeant de section et en revenant.
      await _taper(
        tester,
        find.descendant(
          of: find.byKey(AvisAdminPage.sectionsKey),
          matching: find.text(a.sections.avis),
        ),
      );
      await _versLiens(tester);
      expect(find.byKey(AvisAdminPage.creeKey), findsNothing);
    });

    testWidgets('creer, coupure : non confirme, la liste est relue', (
      tester,
    ) async {
      final AvisDemonstration p = _port()..erreurCreation = Exception('x');
      await _monter(tester, p);
      await _versLiens(tester);
      await _ecrire(tester, AvisAdminPage.libelleKey, 'Familles');
      final int avant = p.lecturesLiens;
      await _taper(tester, find.byKey(AvisAdminPage.creerKey));
      expect(find.text(a.liens.echecCreation), findsOneWidget);
      expect(find.byKey(AvisAdminPage.creeKey), findsNothing);
      expect(p.lecturesLiens, greaterThan(avant));
    });

    testWidgets('creer hors ligne : rien ne part', (tester) async {
      final AvisDemonstration p = _port();
      await _monter(tester, p, horsLigne: true);
      await _versLiens(tester);
      await _ecrire(tester, AvisAdminPage.libelleKey, 'Familles');
      await _taper(tester, find.byKey(AvisAdminPage.creerKey));
      expect(p.jetonsCrees, isEmpty);
      expect(find.text(a.retour.horsLigne), findsOneWidget);
    });

    testWidgets('fermer : confirmation, puis le lien est ferme', (
      tester,
    ) async {
      final AvisDemonstration p = _port(liens: <LienAvis>[_lien()]);
      await _monter(tester, p);
      await _versLiens(tester);
      await _taper(tester, find.byKey(AvisAdminPage.fermerKey('l1')));
      expect(find.text(a.liens.fermerConsequence), findsOneWidget);
      expect(p.liens.single.ferme, isFalse);
      await tester.tap(find.text(a.liens.fermerAction).last);
      await laisser(tester);
      expect(p.liens.single.ferme, isTrue);
      expect(find.text(a.liens.fermeOk), findsOneWidget);
      expect(find.text(a.liens.etat.ferme), findsOneWidget);
      expect(find.byKey(AvisAdminPage.fermerKey('l1')), findsNothing);
    });

    testWidgets('fermer, renoncer : rien ne part', (tester) async {
      final AvisDemonstration p = _port(liens: <LienAvis>[_lien()]);
      await _monter(tester, p);
      await _versLiens(tester);
      await _taper(tester, find.byKey(AvisAdminPage.fermerKey('l1')));
      await tester.tap(find.text(a.liens.fermerRester).last);
      await laisser(tester);
      expect(p.liens.single.ferme, isFalse);
    });

    testWidgets('fermer, coupure : non confirme', (tester) async {
      final AvisDemonstration p = _port(liens: <LienAvis>[_lien()])
        ..erreurFermeture = Exception('x');
      await _monter(tester, p);
      await _versLiens(tester);
      await _taper(tester, find.byKey(AvisAdminPage.fermerKey('l1')));
      await tester.tap(find.text(a.liens.fermerAction).last);
      await laisser(tester);
      expect(find.text(a.liens.fermeEchec), findsOneWidget);
    });
  });

  group('adresse du lien', () {
    test('web par hash, web par chemin, hors web', () {
      expect(
        lienAvisPour('abc', base: Uri.parse('https://app.exemple/#/admin/x')),
        'https://app.exemple/#/avis/abc',
      );
      expect(
        lienAvisPour('abc', base: Uri.parse('https://app.exemple/admin/x')),
        'https://app.exemple/avis/abc',
      );
      expect(
        lienAvisPour('a/b', base: Uri.parse('file:///tmp/index.html')),
        '$origineParDefaut/#/avis/a%2Fb',
      );
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
          final AvisDemonstration p = _port(
            avis: <AvisAdmin>[_avis()],
            liens: <LienAvis>[_lien()],
          );
          await _monter(tester, p, largeur: 320, echelle: 2, direction: d);
          expect(tester.takeException(), isNull);
          verifierEcranSansMotCoupe(tester);
          await _versLiens(tester);
          await _ecrire(tester, AvisAdminPage.libelleKey, 'Familles');
          await _taper(tester, find.byKey(AvisAdminPage.creerKey));
          expect(tester.takeException(), isNull);
          verifierEcranSansMotCoupe(
            tester,
            // L'adresse complete est un seul mot sans espace : elle se
            // selectionne et se copie, elle ne se lit pas par mots.
            exceptions: <String>{lienAvisPour('jeton-l1')},
          );
        });
      }
    }
  });
}

/// Un port dont la lecture des avis attend.
class _AttenteAvis extends AvisIndisponibles {
  _AttenteAvis(this._attente, this._reel);

  final Future<void> _attente;
  final AvisDemonstration _reel;

  @override
  Future<List<AvisAdmin>> listerAvis({StatutAvis? statut}) async {
    await _attente;
    return _reel.listerAvis(statut: statut);
  }
}

/// Un port dont la lecture des liens attend.
class _AttenteLiens extends AvisIndisponibles {
  _AttenteLiens(this._attente);

  final Future<void> _attente;

  @override
  Future<List<LienAvis>> listerLiens() async {
    await _attente;
    return <LienAvis>[];
  }
}

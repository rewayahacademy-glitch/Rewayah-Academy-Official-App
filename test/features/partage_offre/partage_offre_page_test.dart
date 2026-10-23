// CAND-06 : la page « Aidez une personne a apprendre la parole d'Allah. »
// (`/attente/partage`), qui parle de la personne qui apprendra et non de
// l'academie (consigne du directeur du 22/10/2026), avec tres peu de mots :
// l'invitation en titre (« une soeur » pour une femme), la langue de la carte,
// l'apercu, la mention « Facultatif » et les gestes (Je partage, Enregistrer
// l'image, Copier le lien) avec leur retour. Chaque etat : lecture du dossier et
// des reglages de la carte, pas de candidature en cours, pas de lien, image en
// preparation, image non preparee, hors ligne, arabe de droite a gauche, texte
// agrandi. La variante et la langue de la carte : lues, jamais devinees.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/partage_offre/personnalisation_carte.dart';
import 'package:rewayah_academy/core/partage_offre/port_partage_offre.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/partage_offre/carte_partage.dart';
import 'package:rewayah_academy/features/partage_offre/rendu_carte.dart';
import 'package:rewayah_academy/features/partage_offre/textes_carte.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/partage_offre/faux_partage_offre.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../candidature/hote_candidature.dart';
import 'hote_partage.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

ActionPrincipale _bouton(WidgetTester tester, String cle) =>
    tester.widget<ActionPrincipale>(_cle(cle));

/// Touche un bouton de la page, apres l'avoir amene a l'ecran.
Future<void> _toucher(WidgetTester tester, String cle) async {
  final Finder f = _cle(cle);
  expect(f, findsOneWidget, reason: 'bouton absent : $cle');
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await tester.pump();
}

/// Choisit la puce de langue [nom], apres l'avoir amenee a l'ecran.
Future<void> _puce(WidgetTester tester, String nom) async {
  final Finder f = find.text(nom);
  expect(f, findsOneWidget, reason: 'puce absente : $nom');
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await tester.pump();
}

/// Remonte la page depuis zero : un nouvel arbre, un nouvel etat.
Future<MontagePartage> _remonter(
  WidgetTester tester, {
  List<String> langues = const <String>[],
  TextDirection? direction,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  return monterPartage(tester, langues: langues, direction: direction);
}

/// Un service de dossier dont la lecture dure tant que le test ne la termine pas.
class _DossierLent extends FauxServiceDossier {
  /// La lecture en cours.
  final Completer<EtatDossier> attente = Completer<EtatDossier>();

  @override
  Future<EtatDossier> etat() => attente.future;
}

/// Un profil dont la lecture dure tant que le test ne la termine pas.
class _GenreLent extends FauxGenrePartageur {
  _GenreLent(this.attente);

  /// La lecture en cours.
  final Completer<Genre?> attente;

  @override
  Future<Genre?> genreDuTitulaire() => attente.future;
}

VarianteCarte varianteDeLaCarteSansExpect(WidgetTester tester) =>
    tester.widget<CartePartage>(find.byType(CartePartage)).variante;

const CandidatureDossier _enExamen = CandidatureDossier(
  existe: true,
  etape: EtapeCandidature.prequalification,
  etat: EtatCandidature.enExamen,
  version: 4,
);

void main() {
  // Les vraies polices : la carte a une taille fixe, ses lignes se mesurent
  // avec les glyphes reels et non avec ceux, carres, de la police de test.
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('le contenu', () {
    testWidgets(
      'le titre, la langue de la carte, la carte, « Facultatif », et un seul '
      'bouton plein',
      (WidgetTester tester) async {
        await monterPartage(tester);
        final c = t.recrutement.partage;
        expect(find.text(c.titre), findsWidgets);
        expect(find.text(c.langueCarte), findsOneWidget);
        expect(find.text(c.facultatif), findsOneWidget);
        expect(_cle('partage-apercu'), findsOneWidget);
        expect(find.byType(CartePartage), findsOneWidget);
        expect(find.text(c.partager), findsOneWidget);
        expect(find.text(c.enregistrer), findsOneWidget);
        expect(find.text(c.copier), findsOneWidget);
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester);
        expect(
          _bouton(tester, 'partage-partager').niveau,
          NiveauAction.principale,
        );
        expect(
          _bouton(tester, 'partage-enregistrer').niveau,
          NiveauAction.secondaire,
        );
        expect(
          _bouton(tester, 'partage-copier').niveau,
          NiveauAction.secondaire,
        );
      },
    );

    testWidgets(
      'peu de mots : le titre, la mention « Facultatif » et les boutons ; ni '
      'introduction, ni explication, ni hadith dans la page',
      (WidgetTester tester) async {
        await monterPartage(tester);
        final String tout = textesAffiches(tester).join('\n');
        expect(tout, isNot(contains('Envoyez-lui')));
        expect(tout, isNot(contains('Pour vous aussi')));
        expect(tout, isNot(contains('hadith')));
        expect(tout, isNot(contains('en quelques lignes')));
        expect(_cle('partage-introduction'), findsNothing);
        expect(_cle('partage-motif'), findsNothing);
      },
    );

    testWidgets(
      'le bouton plein est a la premiere personne : « Je partage », et un '
      'lecteur d\'ecran entend ce qu\'il partage',
      (WidgetTester tester) async {
        await monterPartage(tester);
        expect(t.recrutement.partage.partager, 'Je partage');
        expect(
          _bouton(tester, 'partage-partager').libelleSemantique,
          t.recrutement.partage.partagerLaCarte,
        );
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        expect(t.recrutement.partage.partager, 'أشارك');
      },
    );

    testWidgets(
      'la page dit « Facultatif » et « ne change rien a votre candidature », '
      'apres la carte et avant les boutons',
      (WidgetTester tester) async {
        await monterPartage(tester);
        final c = t.recrutement.partage;
        expect(c.facultatif, contains('Facultatif'));
        expect(c.facultatif, contains('ne change rien à votre candidature'));
        final double facultatif = tester
            .getTopLeft(_cle('partage-facultatif'))
            .dy;
        final double langues = tester.getTopLeft(_cle('partage-langues')).dy;
        final double apercu = tester.getBottomLeft(_cle('partage-apercu')).dy;
        expect(langues, lessThan(facultatif));
        expect(apercu, lessThan(facultatif));
        for (final String bouton in <String>[
          'partage-partager',
          'partage-enregistrer',
          'partage-copier',
        ]) {
          final double haut = tester.getTopLeft(_cle(bouton)).dy;
          expect(facultatif, lessThan(haut), reason: 'avant $bouton');
        }
      },
    );

    testWidgets(
      'la page parle de la personne qui apprendra (consigne du directeur, '
      '22/10) ; jamais « pour l\'academie »',
      (WidgetTester tester) async {
        await monterPartage(tester);
        final c = t.recrutement.partage;
        expect(c.titre, 'Aidez une personne à apprendre la parole d\'Allah.');
        final String tout = textesAffiches(tester).join('\n');
        for (final String mot in motsQuiNommentLAcademie) {
          // La ligne du lien porte le nom du site ; elle n'est pas un motif.
          expect(
            tout.replaceAll(RegExp(r'Lien de l.offre.*'), ''),
            isNot(contains(mot)),
            reason: mot,
          );
        }
      },
    );

    testWidgets('la ligne du lien porte l\'adresse de la carte', (
      WidgetTester tester,
    ) async {
      await monterPartage(tester);
      final SelectableText ligne = tester.widget<SelectableText>(
        _cle('partage-lien'),
      );
      expect(ligne.data, contains('rewayah.test/fr/'));
      expect(ligne.data, isNot(contains('https://')));
    });

    testWidgets('aucun prix, aucune promesse, aucun mot interdit', (
      WidgetTester tester,
    ) async {
      await monterPartage(tester);
      final String tout = textesAffiches(tester).join('\n');
      expect(
        RegExp(
          r'\d+\s*(\$|€|usd|dollars?|euros?)',
          caseSensitive: false,
        ).hasMatch(tout),
        isFalse,
        reason: tout,
      );
      for (final String mot in <String>[
        'prix',
        'tarif',
        'gratuit',
        'garanti',
        'rembours',
        'remise',
        'admin',
        'groupe',
      ]) {
        expect(tout.toLowerCase(), isNot(contains(mot)), reason: mot);
      }
    });
  });

  group('Partager', () {
    testWidgets(
      'le menu recoit l\'image rendue, le titre et la ligne de la carte, et le '
      'lien ; le succes ne se dit qu\'apres la reponse',
      (WidgetTester tester) async {
        final MontagePartage m = await monterPartage(tester);
        final Completer<IssuePartage> ouvert = Completer<IssuePartage>();
        m.partage.ouvert = ouvert;
        await _toucher(tester, 'partage-partager');
        expect(m.partage.appels, hasLength(1));
        final AppelPartage appel = m.partage.appels.single;
        expect(appel.png, m.rendu.octets);
        expect(appel.nomFichier, nomFichierCarte);
        // Le message lu par la personne qui recoit, dans la langue de la carte :
        // ce qu'elle y gagne.
        expect(appel.titre, textesCarte[LangueCarte.francais]!.titre);
        expect(appel.texte, textesCarte[LangueCarte.francais]!.sousTitre);
        expect(appel.lien, lienDeTest);
        // Le menu est ouvert : rien n'est encore dit, le bouton est en cours.
        expect(find.text(t.recrutement.partage.fait.partage), findsNothing);
        expect(_bouton(tester, 'partage-partager').enCours, isTrue);
        ouvert.complete(IssuePartage.partage);
        await tester.pump();
        expect(find.text(t.recrutement.partage.fait.partage), findsOneWidget);
        expect(_bouton(tester, 'partage-partager').enCours, isFalse);
        // Le retour d'un geste se lit sous les boutons : ils ne bougent pas.
        expect(
          tester.getTopLeft(_cle('partage-retour')).dy,
          greaterThan(tester.getBottomLeft(_cle('partage-copier')).dy),
        );
        verifierUnSeulBoutonPlein(tester);
      },
    );

    testWidgets('le menu ferme par la personne : aucun message', (
      WidgetTester tester,
    ) async {
      final MontagePartage m = await monterPartage(tester);
      m.partage.issue = IssuePartage.annule;
      await _toucher(tester, 'partage-partager');
      expect(m.partage.appels, hasLength(1));
      expect(_cle('partage-retour'), findsNothing);
      expect(_bouton(tester, 'partage-partager').enCours, isFalse);
    });

    testWidgets(
      'le menu refuse par l\'appareil : le message dit quoi faire a la place',
      (WidgetTester tester) async {
        final MontagePartage m = await monterPartage(tester);
        m.partage.erreur = const PartageImpossible();
        await _toucher(tester, 'partage-partager');
        final Finder message = _cle('partage-retour');
        expect(message, findsOneWidget);
        expect(
          tester.widget<Text>(message).data,
          t.recrutement.partage.echec.partage,
        );
        expect(t.recrutement.partage.echec.partage, contains('enregistrer'));
        expect(t.recrutement.partage.echec.partage, contains('copier'));
        // Les autres gestes restent possibles.
        expect(_bouton(tester, 'partage-enregistrer').onPress, isNotNull);
        expect(_bouton(tester, 'partage-copier').onPress, isNotNull);
      },
    );

    testWidgets('une panne imprevue du menu se dit pareil', (
      WidgetTester tester,
    ) async {
      final MontagePartage m = await monterPartage(tester);
      m.partage.erreur = StateError('boum');
      await _toucher(tester, 'partage-partager');
      expect(
        tester.widget<Text>(_cle('partage-retour')).data,
        t.recrutement.partage.echec.partage,
      );
    });

    testWidgets(
      'sans menu de partage : pas de « Partager », « Enregistrer l\'image » '
      'devient le geste plein, la phrase dit pourquoi',
      (WidgetTester tester) async {
        await monterPartage(tester, niveau: NiveauPartage.aucun);
        expect(_cle('partage-partager'), findsNothing);
        expect(find.text(t.recrutement.partage.partager), findsNothing);
        expect(
          _bouton(tester, 'partage-enregistrer').niveau,
          NiveauAction.principale,
        );
        expect(
          _bouton(tester, 'partage-copier').niveau,
          NiveauAction.secondaire,
        );
        expect(
          tester.widget<Text>(_cle('partage-note')).data,
          t.recrutement.partage.sansMenu,
        );
        verifierUnSeulBoutonPlein(tester);
      },
    );

    testWidgets('menu qui ne partage que le lien : « Partager » et sa note', (
      WidgetTester tester,
    ) async {
      await monterPartage(tester, niveau: NiveauPartage.lien);
      expect(_cle('partage-partager'), findsOneWidget);
      expect(
        tester.widget<Text>(_cle('partage-note')).data,
        t.recrutement.partage.lienSeul,
      );
      verifierUnSeulBoutonPlein(tester);
    });
  });

  group('Enregistrer l\'image', () {
    testWidgets('l\'image rendue part au selecteur de fichier, en PNG', (
      WidgetTester tester,
    ) async {
      final MontagePartage m = await monterPartage(tester);
      await _toucher(tester, 'partage-enregistrer');
      expect(m.enregistrement.appels, hasLength(1));
      final appel = m.enregistrement.appels.single;
      expect(appel.nom, nomFichierCarte);
      expect(appel.mime, 'image/png');
      expect(appel.octets, m.rendu.octets);
      expect(
        tester.widget<Text>(_cle('partage-retour')).data,
        t.recrutement.partage.fait.enregistre,
      );
    });

    testWidgets('la boite fermee par la personne : aucun message', (
      WidgetTester tester,
    ) async {
      final MontagePartage m = await monterPartage(tester);
      m.enregistrement.destinationRendue = null;
      await _toucher(tester, 'partage-enregistrer');
      expect(m.enregistrement.appels, hasLength(1));
      expect(_cle('partage-retour'), findsNothing);
    });

    testWidgets('un enregistrement qui echoue : non confirme, quoi faire', (
      WidgetTester tester,
    ) async {
      final MontagePartage m = await monterPartage(tester);
      m.enregistrement.erreur = StateError('disque plein');
      await _toucher(tester, 'partage-enregistrer');
      final String message = tester.widget<Text>(_cle('partage-retour')).data!;
      expect(message, t.recrutement.partage.echec.enregistrement);
      expect(message, contains('n\'est pas confirmé'));
      expect(message, contains('copiez le lien'));
    });
  });

  group('Copier le lien', () {
    testWidgets('le lien de l\'offre part au presse-papiers, sans parametre', (
      WidgetTester tester,
    ) async {
      await monterPartage(tester);
      final PressePapiersDeTest presse = PressePapiersDeTest(tester);
      await _toucher(tester, 'partage-copier');
      expect(presse.copies, <String>[lienDeTest.toString()]);
      expect(lienDeTest.hasQuery, isFalse);
      expect(
        tester.widget<Text>(_cle('partage-retour')).data,
        t.recrutement.partage.fait.copie,
      );
    });

    testWidgets('une copie qui echoue : le lien se selectionne a la main', (
      WidgetTester tester,
    ) async {
      await monterPartage(tester);
      PressePapiersDeTest(tester, echec: true);
      await _toucher(tester, 'partage-copier');
      expect(
        tester.widget<Text>(_cle('partage-retour')).data,
        t.recrutement.partage.echec.copie,
      );
      expect(_cle('partage-lien'), findsOneWidget);
    });
  });

  group('l\'image de la carte', () {
    testWidgets(
      'en preparation : « Partager » et « Enregistrer » sont en cours, '
      '« Copier le lien » reste possible ; prete, ils s\'ouvrent',
      (WidgetTester tester) async {
        final FauxRenduCarte rendu = FauxRenduCarte()
          ..enCours = Completer<Uint8List>();
        final MontagePartage m = await monterPartage(
          tester,
          rendu: rendu,
          attendre: false,
        );
        await tester.pump();
        expect(rendu.appels, 1);
        expect(_bouton(tester, 'partage-partager').enCours, isTrue);
        expect(_bouton(tester, 'partage-enregistrer').enCours, isTrue);
        expect(_bouton(tester, 'partage-copier').enCours, isFalse);
        verifierUnSeulBoutonPlein(tester);
        // Toucher un geste en cours ne fait rien : pas d'image, pas de partage.
        await _toucher(tester, 'partage-partager');
        await _toucher(tester, 'partage-enregistrer');
        expect(m.partage.appels, isEmpty);
        expect(m.enregistrement.appels, isEmpty);
        rendu.enCours!.complete(rendu.octets);
        await tester.pumpAndSettle();
        expect(_bouton(tester, 'partage-partager').enCours, isFalse);
        expect(_bouton(tester, 'partage-enregistrer').enCours, isFalse);
        await _toucher(tester, 'partage-partager');
        expect(m.partage.appels, hasLength(1));
      },
    );

    testWidgets('image non preparee : le message, « Reessayer » (seul geste plein), et '
        'le lien se copie encore', (WidgetTester tester) async {
      final FauxRenduCarte rendu = FauxRenduCarte()
        ..erreur = StateError('pas peinte');
      await monterPartage(tester, rendu: rendu);
      expect(
        tester.widget<Text>(_cle('partage-retour')).data,
        t.recrutement.partage.echec.carte,
      );
      // La raison se lit avant « Reessayer », pas sous lui.
      expect(
        tester.getTopLeft(_cle('partage-retour')).dy,
        lessThan(tester.getTopLeft(_cle('partage-reessayer')).dy),
      );
      expect(_cle('partage-partager'), findsNothing);
      expect(_cle('partage-enregistrer'), findsNothing);
      expect(
        _bouton(tester, 'partage-reessayer').niveau,
        NiveauAction.principale,
      );
      expect(find.text(t.commun.reessayer), findsOneWidget);
      expect(_bouton(tester, 'partage-copier').onPress, isNotNull);
      verifierUnSeulBoutonPlein(tester);
      // « Reessayer » refait le rendu ; une fois rendu, les gestes reviennent.
      rendu.erreur = null;
      await _toucher(tester, 'partage-reessayer');
      await tester.pumpAndSettle();
      expect(rendu.appels, 2);
      expect(_cle('partage-reessayer'), findsNothing);
      expect(_cle('partage-retour'), findsNothing);
      expect(_bouton(tester, 'partage-partager').enCours, isFalse);
      expect(_bouton(tester, 'partage-enregistrer').enCours, isFalse);
    });

    testWidgets('le rendu est demande une seule fois a l\'ouverture', (
      WidgetTester tester,
    ) async {
      final MontagePartage m = await monterPartage(tester);
      expect(m.rendu.appels, 1);
    });
  });

  group('la lecture du dossier et les gardes', () {
    testWidgets(
      'sans candidature : retour au portail, aucune phrase de carte',
      (WidgetTester tester) async {
        await monterPartage(tester, candidature: const CandidatureDossier());
        expect(find.byType(CartePartage), findsNothing);
        expect(find.text(t.recrutement.partage.facultatif), findsNothing);
        // Le portail s'affiche a la place.
        expect(find.text(t.attente.seDeconnecter), findsOneWidget);
      },
    );

    testWidgets('candidature refusee ou retiree : retour au portail', (
      WidgetTester tester,
    ) async {
      for (final IssueCandidature issue in <IssueCandidature>[
        IssueCandidature.refusee,
        IssueCandidature.retiree,
      ]) {
        await monterPartage(
          tester,
          candidature: CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            etat: EtatCandidature.enExamen,
            issue: issue,
            version: 5,
          ),
        );
        expect(find.byType(CartePartage), findsNothing, reason: '$issue');
        expect(find.text(t.attente.seDeconnecter), findsOneWidget);
      }
    });

    testWidgets('en examen, en pause : la carte reste proposee', (
      WidgetTester tester,
    ) async {
      await monterPartage(tester, candidature: _enExamen);
      expect(find.byType(CartePartage), findsOneWidget);
      await monterPartage(
        tester,
        candidature: candidatureAFaire(enPause: true),
      );
      expect(find.byType(CartePartage), findsOneWidget);
    });

    testWidgets(
      'pas de lien d\'offre : la phrase de capacite indisponible, ni carte ni '
      'bouton, jamais le nom de la configuration',
      (WidgetTester tester) async {
        await monterPartage(tester, sansLien: true);
        expect(_cle('partage-non-ouvert'), findsOneWidget);
        expect(find.text(t.recrutement.partage.nonOuvert), findsOneWidget);
        expect(find.byType(CartePartage), findsNothing);
        expect(find.byType(ActionPrincipale), findsNothing);
        expect(find.textContaining('SITE_URL'), findsNothing);
        expect(find.textContaining('CAND-BR'), findsNothing);
      },
    );

    testWidgets('lecture du dossier en echec : l\'erreur et « Reessayer »', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..erreurAJeter = Exception('serveur');
      await monterPartage(tester, dossier: dossier, attendre: false);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text(t.recrutement.portail.nonCharge), findsWidgets);
      expect(find.text(t.commun.reessayer), findsOneWidget);
      expect(find.byType(CartePartage), findsNothing);
    });

    testWidgets('chargement du dossier : un squelette, pas de carte', (
      WidgetTester tester,
    ) async {
      final _DossierLent dossier = _DossierLent();
      await monterPartage(tester, dossier: dossier, attendre: false);
      // Rien avant 180 ms ; puis le squelette, jamais la carte.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(CartePartage), findsNothing);
      expect(find.byType(ActionPrincipale), findsNothing);
      dossier.attente.complete(etatCandidat(candidature: candidatureAFaire()));
      await tester.pumpAndSettle();
      expect(find.byType(Skeleton), findsNothing);
      expect(find.byType(CartePartage), findsOneWidget);
    });
  });

  group('hors ligne', () {
    testWidgets(
      'la page marche sans reseau (rien ne part au serveur) ; le bandeau le '
      'dit une fois',
      (WidgetTester tester) async {
        final MontagePartage m = await monterPartage(tester, horsLigne: true);
        expect(find.text(t.reseau.horsLigne), findsOneWidget);
        expect(find.byType(CartePartage), findsOneWidget);
        await _toucher(tester, 'partage-partager');
        expect(m.partage.appels, hasLength(1));
        expect(find.text(t.recrutement.partage.fait.partage), findsOneWidget);
      },
    );

    testWidgets(
      'dossier illisible hors ligne : ce qui manque, sans redire « hors ligne »',
      (WidgetTester tester) async {
        final FauxServiceDossier dossier = FauxServiceDossier()
          ..erreurAJeter = Exception('reseau');
        await monterPartage(
          tester,
          dossier: dossier,
          horsLigne: true,
          attendre: false,
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(find.text(t.reseau.horsLigne), findsOneWidget);
        expect(find.text(t.recrutement.portail.nonCharge), findsWidgets);
        expect(find.byType(CartePartage), findsNothing);
      },
    );
  });

  group('l\'arabe, de droite a gauche', () {
    testWidgets(
      'les textes arabes, la carte arabe sans traduction francaise, un seul '
      'bouton plein',
      (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        await monterPartage(tester, direction: TextDirection.rtl);
        final c = t.recrutement.partage;
        expect(find.text(c.titre), findsWidgets);
        expect(find.text(c.facultatif), findsOneWidget);
        expect(find.text(c.partager), findsOneWidget);
        expect(find.text(c.enregistrer), findsOneWidget);
        expect(find.text(c.copier), findsOneWidget);
        // La carte : le meme hadith, sa reference en arabe, aucune traduction.
        expect(_cle('carte-hadith'), findsOneWidget);
        expect(tester.widget<Text>(_cle('carte-hadith')).data, hadithArabe);
        expect(_cle('carte-traduction'), findsNothing);
        expect(
          find.text(textesCarte[LangueCarte.arabe]!.reference),
          findsOneWidget,
        );
        // Aucune phrase francaise ne reste dans la page.
        expect(find.textContaining('Facultatif'), findsNothing);
        expect(find.textContaining('Aidez'), findsNothing);
        expect(find.textContaining('Celui qui'), findsNothing);
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester);
      },
    );

    testWidgets(
      'sur bureau, le geste plein est au bord de fin (a gauche) et la carte '
      'est a la fin de la ligne, a gauche du texte',
      (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        await monterPartage(
          tester,
          direction: TextDirection.rtl,
          taille: const Size(1440, 900),
        );
        final Rect plein = tester.getRect(_cle('partage-partager'));
        final Rect enregistrer = tester.getRect(_cle('partage-enregistrer'));
        final Rect carte = tester.getRect(_cle('partage-apercu'));
        // En arabe la ligne va de droite a gauche : le plein est le dernier,
        // donc le plus a gauche de sa colonne ; la carte est a la fin de la
        // ligne, donc encore plus a gauche.
        expect(plein.center.dx, lessThan(enregistrer.center.dx));
        expect(carte.center.dx, lessThan(plein.center.dx));
        expect(
          tester.getTopRight(_cle('partage-langues')).dx,
          greaterThan(carte.right),
        );
      },
    );

    testWidgets('en francais, sur bureau : le geste plein au bord de fin', (
      WidgetTester tester,
    ) async {
      await monterPartage(tester, taille: const Size(1440, 900));
      final Rect plein = tester.getRect(_cle('partage-partager'));
      final Rect enregistrer = tester.getRect(_cle('partage-enregistrer'));
      final Rect carte = tester.getRect(_cle('partage-apercu'));
      expect(plein.center.dx, greaterThan(enregistrer.center.dx));
      // La carte est a la fin de la ligne, a cote du texte et non dessous.
      expect(carte.left, greaterThan(plein.left));
      expect(
        tester.getTopLeft(_cle('partage-langues')).dy,
        lessThan(carte.bottom),
      );
    });
  });

  group('la langue de la carte : quatre puces, la langue d\'enseignement par '
      'defaut', () {
    /// Les puces, dans l'ordre, avec ce qu'elles disent et si elles sont
    /// retenues.
    List<(String, bool)> puces(WidgetTester tester) => <(String, bool)>[
      for (final FilterPill p in tester.widgetList<FilterPill>(
        find.descendant(
          of: _cle('partage-langues'),
          matching: find.byType(FilterPill),
        ),
      ))
        (p.libelle, p.retenue),
    ];

    LangueCarte langueDeLaCarte(WidgetTester tester) =>
        LangueCarte.values.singleWhere(
          (LangueCarte l) =>
              textesCarte[l]!.titre ==
              tester.widget<Text>(_cle('carte-titre')).data,
        );

    testWidgets(
      'les quatre langues, chacune ecrite dans sa langue : Francais, English, '
      'Portugues, l\'arabe',
      (WidgetTester tester) async {
        await monterPartage(tester);
        expect(_cle('partage-langues'), findsOneWidget);
        expect(puces(tester), <(String, bool)>[
          ('Français', true),
          ('English', false),
          ('Português', false),
          ('العربية', false),
        ]);
        for (final String nom in <String>[
          'Français',
          'English',
          'Português',
          'العربية',
        ]) {
          expect(find.text(nom), findsOneWidget, reason: nom);
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'sans langue d\'enseignement : la langue de l\'application, le francais',
      (WidgetTester tester) async {
        await monterPartage(tester);
        expect(langueDeLaCarte(tester), LangueCarte.francais);
        expect(
          <String>[
            for (final (String, bool) p in puces(tester))
              if (p.$2) p.$1,
          ],
          <String>['Français'],
        );
      },
    );

    testWidgets(
      'la premiere langue d\'enseignement qui est internationale : l\'anglais, '
      'le portugais, le francais',
      (WidgetTester tester) async {
        for (final (List<String>, LangueCarte) cas
            in <(List<String>, LangueCarte)>[
              (<String>['poular', 'english', 'francais'], LangueCarte.anglais),
              (<String>['portugais', 'poular'], LangueCarte.portugais),
              (<String>['pt'], LangueCarte.portugais),
              (<String>['wo', 'francais', 'english'], LangueCarte.francais),
            ]) {
          await _remonter(tester, langues: cas.$1);
          expect(langueDeLaCarte(tester), cas.$2, reason: '${cas.$1}');
          expect(
            <String>[
              for (final (String, bool) p in puces(tester))
                if (p.$2) p.$1,
            ],
            <String>[textesCarte[cas.$2]!.nomPropre],
          );
        }
      },
    );

    testWidgets(
      'une langue vernaculaire ne donne pas de carte : la langue de '
      'l\'application, le francais ; et l\'arabe, jamais une langue de cours',
      (WidgetTester tester) async {
        await monterPartage(tester, langues: <String>['poular', 'bm', 'ar']);
        expect(langueDeLaCarte(tester), LangueCarte.francais);
      },
    );

    testWidgets(
      'application en arabe, sans langue d\'enseignement : la carte en arabe ; '
      'avec l\'anglais : la carte en anglais, la page reste en arabe',
      (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        await monterPartage(tester, direction: TextDirection.rtl);
        expect(langueDeLaCarte(tester), LangueCarte.arabe);
        await _remonter(
          tester,
          direction: TextDirection.rtl,
          langues: <String>['english'],
        );
        expect(langueDeLaCarte(tester), LangueCarte.anglais);
        expect(find.text(t.recrutement.partage.langueCarte), findsOneWidget);
        expect(find.text(t.recrutement.partage.partager), findsOneWidget);
      },
    );

    testWidgets(
      'choisir une puce change la langue de la carte et refait l\'image ; le '
      'message de partage suit',
      (WidgetTester tester) async {
        final MontagePartage m = await monterPartage(tester);
        expect(m.rendu.appels, 1);
        await _puce(tester, 'Português');
        await tester.pumpAndSettle();
        expect(langueDeLaCarte(tester), LangueCarte.portugais);
        // L'image se refait des que la carte est repeinte, avant tout toucher.
        await tester.pumpAndSettle();
        expect(m.rendu.appels, 2);
        await _toucher(tester, 'partage-partager');
        final AppelPartage appel = m.partage.appels.single;
        expect(appel.titre, textesCarte[LangueCarte.portugais]!.titre);
        expect(appel.texte, textesCarte[LangueCarte.portugais]!.sousTitre);
        // Puis l'arabe, de droite a gauche, sur une page qui reste en francais.
        await _puce(tester, 'العربية');
        await tester.pumpAndSettle();
        expect(langueDeLaCarte(tester), LangueCarte.arabe);
        expect(m.rendu.appels, 3);
        expect(find.text(t.recrutement.partage.partager), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'pendant que l\'image se refait, « Je partage » et « Enregistrer » sont '
      'en cours ; la puce deja choisie ne refait rien',
      (WidgetTester tester) async {
        final FauxRenduCarte rendu = FauxRenduCarte();
        final MontagePartage m = await monterPartage(tester, rendu: rendu);
        // La puce deja choisie : aucun nouveau rendu.
        await _puce(tester, 'Français');
        await tester.pumpAndSettle();
        expect(m.rendu.appels, 1);
        // Une autre : le rendu est en cours tant que le test ne le finit pas.
        rendu.enCours = Completer<Uint8List>();
        await _puce(tester, 'English');
        await tester.pumpAndSettle();
        await tester.pump();
        expect(rendu.appels, 2);
        expect(_bouton(tester, 'partage-partager').enCours, isTrue);
        expect(_bouton(tester, 'partage-enregistrer').enCours, isTrue);
        await _toucher(tester, 'partage-partager');
        expect(m.partage.appels, isEmpty);
        rendu.enCours!.complete(rendu.octets);
        await tester.pumpAndSettle();
        expect(_bouton(tester, 'partage-partager').enCours, isFalse);
        await _toucher(tester, 'partage-partager');
        expect(m.partage.appels, hasLength(1));
      },
    );

    testWidgets(
      'changer de langue efface le dernier retour, et une image non preparee '
      'se retente dans la nouvelle langue',
      (WidgetTester tester) async {
        final MontagePartage m = await monterPartage(tester);
        PressePapiersDeTest(tester);
        await _toucher(tester, 'partage-copier');
        expect(_cle('partage-retour'), findsOneWidget);
        await _puce(tester, 'English');
        await tester.pumpAndSettle();
        expect(_cle('partage-retour'), findsNothing);
        // Un rendu qui echoue : « Reessayer », puis une autre langue refait.
        m.rendu.erreur = StateError('pas peinte');
        await _puce(tester, 'Português');
        await tester.pumpAndSettle();
        expect(_cle('partage-reessayer'), findsOneWidget);
        m.rendu.erreur = null;
        await _puce(tester, 'Français');
        await tester.pumpAndSettle();
        expect(_cle('partage-reessayer'), findsNothing);
        expect(_cle('partage-partager'), findsOneWidget);
      },
    );
  });

  group('la variante : lue sur le profil, jamais devinee', () {
    VarianteCarte varianteDeLaCarte(WidgetTester tester) =>
        tester.widget<CartePartage>(find.byType(CartePartage)).variante;

    testWidgets('une femme : le titre « une soeur » et la carte des femmes', (
      WidgetTester tester,
    ) async {
      await monterPartage(tester, genre: Genre.femme);
      expect(varianteDeLaCarte(tester), VarianteCarte.femmes);
      expect(find.text(t.recrutement.partage.titreFemme), findsWidgets);
      expect(find.text(t.recrutement.partage.titre), findsNothing);
    });

    testWidgets(
      'un homme, ou un genre inconnu : le titre « une personne » et la carte '
      'des hommes, la neutre',
      (WidgetTester tester) async {
        for (final Genre? genre in <Genre?>[Genre.homme, null]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await monterPartage(tester, genre: genre);
          expect(
            varianteDeLaCarte(tester),
            VarianteCarte.hommes,
            reason: '$genre',
          );
          expect(find.text(t.recrutement.partage.titre), findsWidgets);
          expect(find.text(t.recrutement.partage.titreFemme), findsNothing);
        }
      },
    );

    testWidgets(
      'un profil illisible : la page reste, avec la variante neutre',
      (WidgetTester tester) async {
        await monterPartage(
          tester,
          lectureGenre: FauxGenrePartageur(genre: Genre.femme)
            ..erreur = StateError('hors ligne'),
        );
        expect(varianteDeLaCarte(tester), VarianteCarte.hommes);
        expect(find.byType(CartePartage), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('en arabe, au feminin pour une femme, au masculin sinon', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await monterPartage(
        tester,
        genre: Genre.femme,
        direction: TextDirection.rtl,
      );
      expect(find.text('ساعدي أختًا على تعلّم كلام الله'), findsWidgets);
      await monterPartage(tester, direction: TextDirection.rtl);
      expect(find.text('ساعد شخصًا على تعلّم كلام الله'), findsWidgets);
    });

    testWidgets(
      'la lecture du genre est unique : l\'image n\'est rendue qu\'une fois '
      'pour la bonne variante',
      (WidgetTester tester) async {
        final FauxGenrePartageur genre = FauxGenrePartageur(genre: Genre.femme);
        final MontagePartage m = await monterPartage(
          tester,
          lectureGenre: genre,
        );
        expect(genre.lectures, 1);
        expect(m.rendu.appels, 1);
      },
    );

    testWidgets(
      'la lecture des reglages est en cours : un squelette, pas de carte, '
      'aucun rendu ; puis la carte de la bonne variante',
      (WidgetTester tester) async {
        final Completer<Genre?> attente = Completer<Genre?>();
        final FauxRenduCarte rendu = FauxRenduCarte();
        await monterPartage(
          tester,
          rendu: rendu,
          lectureGenre: _GenreLent(attente),
          attendre: false,
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Skeleton), findsWidgets);
        expect(find.byType(CartePartage), findsNothing);
        expect(rendu.appels, 0);
        attente.complete(Genre.femme);
        await tester.pumpAndSettle();
        expect(find.byType(Skeleton), findsNothing);
        expect(
          tester.widget<CartePartage>(find.byType(CartePartage)).variante,
          VarianteCarte.femmes,
        );
        expect(rendu.appels, 1);
      },
    );

    testWidgets(
      'une lecture qui ne revient pas : au bout de cinq secondes la carte '
      'des hommes, jamais une page bloquee',
      (WidgetTester tester) async {
        final Completer<Genre?> jamais = Completer<Genre?>();
        await monterPartage(
          tester,
          lectureGenre: _GenreLent(jamais),
          attendre: false,
        );
        await tester.pump(delaiReglagesCarte + const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(find.byType(CartePartage), findsOneWidget);
        expect(varianteDeLaCarteSansExpect(tester), VarianteCarte.hommes);
      },
    );
  });

  group('tailles et themes', () {
    for (final Size taille in const <Size>[
      Size(320, 640),
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      for (final double echelle in const <double>[1, 2]) {
        testWidgets(
          '${taille.width.toInt()} de large, texte x${echelle.toInt()} : '
          'rien ne deborde, un seul bouton plein, la carte garde sa taille',
          (WidgetTester tester) async {
            await monterPartage(tester, taille: taille, echelle: echelle);
            expect(tester.takeException(), isNull);
            verifierUnSeulBoutonPlein(tester);
            // L'image a toujours le rapport 9:16, quelle que soit la place.
            final Rect carte = tester.getRect(_cle('partage-apercu'));
            expect(carte.width / carte.height, closeTo(9 / 16, 0.005));
            // Les trois gestes sont atteignables et ne se recouvrent pas.
            for (final String cle in <String>[
              'partage-partager',
              'partage-enregistrer',
              'partage-copier',
            ]) {
              await tester.ensureVisible(_cle(cle));
              await tester.pump();
              expect(
                tester.getSize(_cle(cle)).height,
                greaterThanOrEqualTo(48),
              );
            }
            verifierSansChevauchement(tester, <Finder>[
              _cle('partage-partager'),
              _cle('partage-enregistrer'),
              _cle('partage-copier'),
            ]);
          },
        );
      }
    }

    testWidgets('sombre : la page suit le theme, la carte ne change pas', (
      WidgetTester tester,
    ) async {
      await monterPartage(tester, themeMode: ThemeMode.dark);
      expect(tester.takeException(), isNull);
      expect(find.byType(CartePartage), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });
  });

  group('la carte dans la page', () {
    testWidgets('la carte porte un QR (son contenu est lu dans le rendu)', (
      WidgetTester tester,
    ) async {
      await monterPartage(tester);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('l\'apercu porte la carte a sa taille d\'export, reduite', (
      WidgetTester tester,
    ) async {
      await monterPartage(tester);
      final Size carte = tester.getSize(find.byType(CartePartage));
      expect(carte, const Size(CartePartage.largeur, CartePartage.hauteur));
      expect(CartePartage.largeur * CartePartage.echelleExport, 1080);
      expect(CartePartage.hauteur * CartePartage.echelleExport, 1920);
      expect(
        CartePartage.largeur / CartePartage.hauteur,
        closeTo(9 / 16, 1e-9),
      );
    });
  });
}

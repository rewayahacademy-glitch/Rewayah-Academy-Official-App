// CAND-PREVENIR : le lien « Prevenir par e-mail » de la file des candidatures et
// la feuille qui envoie le lien d'inscription aux personnes des formulaires
// importes.
//
// Ce que le test prouve :
// - le lien n'existe que si le serveur ouvre le geste (`consignerPrevenu`) ET
//   que le port est servi, jamais grise ;
// - les cinq etats (chargement, contenu, vide, erreur, hors ligne), plus
//   l'inscription fermee, l'acces refuse et la capacite indisponible ;
// - jamais plus d'un bouton plein ; inscription fermee et plus personne a
//   prevenir : aucun bouton d'envoi ;
// - apres l'envoi : « {n} messages partent... », et s'il reste du monde le
//   bouton devient « Envoyer aux {n} suivantes » ; un envoi trop gros part par
//   groupes de 200 ;
// - une coupure du reseau pendant l'envoi est « non confirme », « Reessayer »
//   rejoue sans rien promettre de recu ;
// - 320 px a texte x2 et 1440 px, en francais et en arabe (droite a gauche).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_prevenir_candidats.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_candidatures/prevenir_candidats.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../fixtures/candidature/faux_prevenir_candidats.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';
import 'hote_candidatures.dart';

/// Une direction qui lit et a qui le serveur ouvre le geste.
const CapacitesCandidatures _capsPrevenir = CapacitesCandidatures(
  peutLire: true,
  genreLecteurConnu: true,
  gestes: <String, bool>{'consignerPrevenu': true},
);

Finder _cle(Key cle) => find.byKey(cle);

const Key _lien = ValueKey<String>('candidatures-prevenir');

/// Monte la file avec le port [faux] (nul : port non servi) et les capacites
/// [caps].
Future<void> _monter(
  WidgetTester tester,
  FauxPrevenirCandidats? faux, {
  CapacitesCandidatures caps = _capsPrevenir,
  bool horsLigne = false,
  double largeur = 390,
  double hauteur = 3000,
  double echelle = 1,
  TextDirection? direction,
}) => monterCandidatures(
  tester,
  port: FauxCandidaturesDirection(
    lignes: <LigneCandidature>[ligneTest(id: 'a1')],
    capacitesRendues: caps,
  ),
  surcharges: <Override>[portPrevenirCandidatsProvider.overrideWithValue(faux)],
  horsLigne: horsLigne,
  largeur: largeur,
  hauteur: hauteur,
  echelle: echelle,
  direction: direction,
);

/// Ouvre la feuille par le lien.
Future<void> _ouvrir(WidgetTester tester) async {
  await tester.ensureVisible(_cle(_lien));
  await tester.pump();
  await tester.tap(_cle(_lien));
  await laisser(tester);
}

Future<void> _envoyer(WidgetTester tester) async {
  await tester.ensureVisible(_cle(FeuillePrevenir.cleEnvoyer));
  await tester.pump();
  await tester.tap(_cle(FeuillePrevenir.cleEnvoyer));
  await laisser(tester);
}

String _libelleEnvoyer(WidgetTester tester) =>
    tester.widget<ActionPrincipale>(_cle(FeuillePrevenir.cleEnvoyer)).libelle;

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('le lien', () {
    testWidgets('present quand le geste est ouvert et le port servi', (
      tester,
    ) async {
      await _monter(tester, FauxPrevenirCandidats());
      expect(_cle(_lien), findsOneWidget);
      expect(find.text('Prévenir par e-mail'), findsWidgets);
    });

    testWidgets('absent sans la capacite du serveur', (tester) async {
      await _monter(tester, FauxPrevenirCandidats(), caps: capacitesQuiLit);
      expect(_cle(_lien), findsNothing);
    });

    testWidgets('absent quand le port n\'est pas servi', (tester) async {
      await _monter(tester, null);
      expect(_cle(_lien), findsNothing);
    });

    testWidgets('absent quand le geste est refuse explicitement', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxPrevenirCandidats(),
        caps: const CapacitesCandidatures(
          peutLire: true,
          genreLecteurConnu: true,
          gestes: <String, bool>{'consignerPrevenu': false},
        ),
      );
      expect(_cle(_lien), findsNothing);
    });

    testWidgets('present au bureau, a 1440 px', (tester) async {
      await _monter(
        tester,
        FauxPrevenirCandidats(),
        largeur: 1440,
        hauteur: 1000,
      );
      expect(_cle(_lien), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('la feuille', () {
    testWidgets('chargement : un squelette, aucun bouton', (tester) async {
      final FauxPrevenirCandidats faux = FauxPrevenirCandidats()
        ..apercuRetenu = Completer<ApercuPrevenir>();
      await _monter(tester, faux);
      await _ouvrir(tester);
      expect(_cle(FeuillePrevenir.cle), findsOneWidget);
      expect(
        find.descendant(
          of: _cle(FeuillePrevenir.cle),
          matching: find.byType(Skeleton),
        ),
        findsWidgets,
      );
      expect(_cle(FeuillePrevenir.cleEnvoyer), findsNothing);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('contenu : les trois comptes, le message, un seul bouton', (
      tester,
    ) async {
      await _monter(tester, FauxPrevenirCandidats());
      await _ouvrir(tester);
      expect(find.text('5 personnes à prévenir'), findsOneWidget);
      expect(find.text('2 personnes déjà prévenues'), findsOneWidget);
      expect(find.text('3 personnes déjà inscrites'), findsOneWidget);
      expect(find.textContaining('rien n\'est à payer'), findsOneWidget);
      expect(find.textContaining('même adresse'), findsWidgets);
      expect(_libelleEnvoyer(tester), 'Envoyer le lien à 5 personnes');
      verifierUnSeulBoutonPlein(tester);
      // Ni adresse ni code brut.
      expect(find.textContaining('@'), findsNothing);
      expect(find.textContaining('CAND-BR'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('une seule personne : le singulier', (tester) async {
      await _monter(
        tester,
        FauxPrevenirCandidats(
          apercuRendu: const ApercuPrevenir(
            aPrevenir: 1,
            dejaPrevenus: 1,
            dejaInscrits: 1,
            inscriptionOuverte: true,
          ),
        ),
      );
      await _ouvrir(tester);
      expect(find.text('1 personne à prévenir'), findsOneWidget);
      expect(_libelleEnvoyer(tester), 'Envoyer le lien à 1 personne');
    });

    testWidgets('inscription fermee : une phrase, aucun bouton d\'envoi', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxPrevenirCandidats(
          apercuRendu: const ApercuPrevenir(
            aPrevenir: 4,
            dejaPrevenus: 0,
            dejaInscrits: 0,
            inscriptionOuverte: false,
          ),
        ),
      );
      await _ouvrir(tester);
      expect(_cle(FeuillePrevenir.cleFermee), findsOneWidget);
      expect(find.textContaining('doit d\'abord être ouverte'), findsOneWidget);
      expect(_cle(FeuillePrevenir.cleEnvoyer), findsNothing);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });

    testWidgets('plus personne a prevenir : etat vide, aucun bouton', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxPrevenirCandidats(
          apercuRendu: const ApercuPrevenir(
            aPrevenir: 0,
            dejaPrevenus: 4,
            dejaInscrits: 2,
            inscriptionOuverte: true,
          ),
        ),
      );
      await _ouvrir(tester);
      expect(_cle(FeuillePrevenir.cleVide), findsOneWidget);
      expect(find.text('Tout le monde est déjà prévenu'), findsOneWidget);
      expect(_cle(FeuillePrevenir.cleEnvoyer), findsNothing);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });

    testWidgets('erreur de lecture : « Reessayer » relit', (tester) async {
      final FauxPrevenirCandidats faux = FauxPrevenirCandidats()
        ..erreurApercu = Exception('muet');
      await _monter(tester, faux);
      await _ouvrir(tester);
      expect(
        find.text('Le nombre de personnes à prévenir n\'a pas pu être chargé.'),
        findsOneWidget,
      );
      expect(find.text('Réessayer'), findsOneWidget);
      expect(_cle(FeuillePrevenir.cleEnvoyer), findsNothing);
      faux.erreurApercu = null;
      final int avant = faux.appelsApercu;
      await tester.tap(find.text('Réessayer'));
      await laisser(tester);
      expect(faux.appelsApercu, greaterThan(avant));
      expect(_cle(FeuillePrevenir.cleEnvoyer), findsOneWidget);
    });

    testWidgets('sans reseau : ce qui manque, sans dire hors ligne', (
      tester,
    ) async {
      final FauxPrevenirCandidats faux = FauxPrevenirCandidats()
        ..erreurApercu = const PrevenirHorsLigne();
      await _monter(tester, faux, horsLigne: true);
      await _ouvrir(tester);
      expect(_cle(FeuillePrevenir.cleSansDonnees), findsOneWidget);
      expect(_cle(FeuillePrevenir.cleEnvoyer), findsNothing);
      expect(find.textContaining('hors ligne'), findsNothing);
      expect(find.textContaining('Vérifiez votre connexion'), findsNothing);
    });

    testWidgets('sans reseau, apercu lu : l\'envoi n\'est pas offert', (
      tester,
    ) async {
      await _monter(tester, FauxPrevenirCandidats(), horsLigne: true);
      await _ouvrir(tester);
      expect(find.text('5 personnes à prévenir'), findsOneWidget);
      expect(_cle(FeuillePrevenir.cleEnvoyer), findsNothing);
      expect(
        find.text('L\'envoi sera possible dès le retour du réseau.'),
        findsOneWidget,
      );
    });

    testWidgets('acces refuse : une phrase, aucun bouton', (tester) async {
      final FauxPrevenirCandidats faux = FauxPrevenirCandidats()
        ..erreurApercu = const PermissionInsuffisante('apercu');
      await _monter(tester, faux);
      await _ouvrir(tester);
      expect(_cle(FeuillePrevenir.cleRefus), findsOneWidget);
      expect(_cle(FeuillePrevenir.cleEnvoyer), findsNothing);
    });

    testWidgets('apres l\'envoi : le resultat, rien de plus a envoyer', (
      tester,
    ) async {
      final FauxPrevenirCandidats faux = FauxPrevenirCandidats();
      await _monter(tester, faux);
      await _ouvrir(tester);
      await _envoyer(tester);
      expect(faux.limites, <int>[200]);
      expect(_cle(FeuillePrevenir.cleResultat), findsOneWidget);
      expect(
        find.text('5 messages partent dans les prochaines minutes'),
        findsOneWidget,
      );
      expect(_cle(FeuillePrevenir.cleEnvoyer), findsNothing);
      expect(find.textContaining('tout le monde est prévenu'), findsOneWidget);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });

    testWidgets('il reste du monde : « Envoyer aux {n} suivantes »', (
      tester,
    ) async {
      final FauxPrevenirCandidats faux = FauxPrevenirCandidats(
        apercuRendu: const ApercuPrevenir(
          aPrevenir: 450,
          dejaPrevenus: 0,
          dejaInscrits: 0,
          inscriptionOuverte: true,
        ),
        resultats: <ResultatPrevenir>[
          const ResultatPrevenir(misEnFile: 200, restants: 250),
          const ResultatPrevenir(misEnFile: 200, restants: 50),
        ],
      );
      await _monter(tester, faux);
      await _ouvrir(tester);
      // Un envoi trop gros part par tranches : le bouton dit ce qui part.
      expect(_libelleEnvoyer(tester), 'Envoyer le lien à 200 personnes');
      expect(find.textContaining('par tranches de 200'), findsOneWidget);
      await _envoyer(tester);
      expect(
        find.text('200 messages partent dans les prochaines minutes'),
        findsOneWidget,
      );
      expect(find.text('Il reste 250 personnes à prévenir.'), findsOneWidget);
      expect(_libelleEnvoyer(tester), 'Envoyer aux 250 suivantes');
      verifierUnSeulBoutonPlein(tester);
      await _envoyer(tester);
      expect(faux.limites, <int>[200, 200]);
      expect(_libelleEnvoyer(tester), 'Envoyer aux 50 suivantes');
    });

    testWidgets(
      'inscription fermee refusee a l\'envoi : la phrase prend la place',
      (tester) async {
        final FauxPrevenirCandidats faux = FauxPrevenirCandidats()
          ..erreurPrevenir = const InscriptionFermee();
        await _monter(tester, faux);
        await _ouvrir(tester);
        await _envoyer(tester);
        expect(_cle(FeuillePrevenir.cleFermee), findsOneWidget);
        expect(_cle(FeuillePrevenir.cleEnvoyer), findsNothing);
        expect(_cle(FeuillePrevenir.cleResultat), findsNothing);
      },
    );

    testWidgets('coupure pendant l\'envoi : non confirme, Reessayer rejoue', (
      tester,
    ) async {
      final FauxPrevenirCandidats faux = FauxPrevenirCandidats()
        ..erreurPrevenir = const PrevenirHorsLigne();
      await _monter(tester, faux);
      await _ouvrir(tester);
      await _envoyer(tester);
      expect(_cle(FeuillePrevenir.cleNonConfirme), findsOneWidget);
      expect(find.text('Envoi non confirmé'), findsOneWidget);
      expect(find.textContaining('en double'), findsOneWidget);
      expect(find.textContaining('partent dans les prochaines'), findsNothing);
      expect(_libelleEnvoyer(tester), 'Réessayer');
      verifierUnSeulBoutonPlein(tester);
      await _envoyer(tester);
      expect(faux.limites, <int>[200, 200]);
      expect(_cle(FeuillePrevenir.cleNonConfirme), findsNothing);
      expect(_cle(FeuillePrevenir.cleResultat), findsOneWidget);
    });

    testWidgets('panne inconnue pendant l\'envoi : aussi non confirme', (
      tester,
    ) async {
      final FauxPrevenirCandidats faux = FauxPrevenirCandidats()
        ..erreurPrevenir = Exception('muet');
      await _monter(tester, faux);
      await _ouvrir(tester);
      await _envoyer(tester);
      expect(_cle(FeuillePrevenir.cleNonConfirme), findsOneWidget);
      expect(_libelleEnvoyer(tester), 'Réessayer');
    });

    testWidgets('« Fermer » ferme la feuille', (tester) async {
      await _monter(tester, FauxPrevenirCandidats());
      await _ouvrir(tester);
      await tester.ensureVisible(_cle(FeuillePrevenir.cleFermer));
      await tester.pump();
      await tester.tap(_cle(FeuillePrevenir.cleFermer));
      await laisser(tester);
      expect(_cle(FeuillePrevenir.cle), findsNothing);
    });
  });

  group('largeurs et langues', () {
    for (final TextDirection direction in <TextDirection>[
      TextDirection.ltr,
      TextDirection.rtl,
    ]) {
      for (final (double largeur, double echelle) mesure in <(double, double)>[
        (320, 2),
        (1440, 1),
      ]) {
        testWidgets(
          '${mesure.$1.toInt()} px, texte x${mesure.$2.toInt()}, $direction : '
          'aucun debordement, un seul bouton plein',
          (tester) async {
            if (direction == TextDirection.rtl) {
              await tester.runAsync(
                () => LocaleSettings.setLocale(AppLocale.ar),
              );
            }
            final FauxPrevenirCandidats faux = FauxPrevenirCandidats(
              resultats: <ResultatPrevenir>[
                const ResultatPrevenir(misEnFile: 3, restants: 2),
              ],
            );
            await _monter(
              tester,
              faux,
              largeur: mesure.$1,
              hauteur: 6000,
              echelle: mesure.$2,
              direction: direction,
            );
            await _ouvrir(tester);
            expect(tester.takeException(), isNull);
            expect(_cle(FeuillePrevenir.cleComptes), findsOneWidget);
            verifierUnSeulBoutonPlein(tester);
            await _envoyer(tester);
            expect(tester.takeException(), isNull);
            expect(_cle(FeuillePrevenir.cleResultat), findsOneWidget);
            verifierUnSeulBoutonPlein(tester);
          },
        );
      }
    }

    testWidgets('en arabe : les mots de la feuille, pas le francais', (
      tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(
        tester,
        FauxPrevenirCandidats(),
        direction: TextDirection.rtl,
      );
      expect(find.text('Prévenir par e-mail'), findsNothing);
      await _ouvrir(tester);
      expect(find.textContaining('Envoyer'), findsNothing);
      expect(find.textContaining('prévenir'), findsNothing);
      expect(_cle(FeuillePrevenir.cleEnvoyer), findsOneWidget);
    });
  });
}

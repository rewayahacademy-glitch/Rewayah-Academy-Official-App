// SUIVI-ATTENTE : l'ecran du suivi, monte dans un vrai GoRouter (le routeur
// de l'ecran porte son parametre `demandeId` ; aucune page montee seule).
//
// Ce que le test prouve :
// - les cinq etapes, toujours les memes, et leur mot (S1) ;
// - chaque etape franchie par le serveur seulement : aucune barre, aucun
//   pourcentage, un marqueur qui change quand le serveur le dit ;
// - ce que dit chaque etape, la date, le delai honnete, le delai depasse, le
//   delai absent (S2) ;
// - les cas hors du chemin droit : refusee, retiree, classe en attente
//   d'enseignant, liste d'attente, changement de creneau (S3) ;
// - la carte de l'enseignant : tout, ou seulement nom et langue ; jamais avant
//   l'etape 4 (S4) ;
// - la version simple de l'enfant : tutoiement, aucun delai chiffre (S6) ;
// - les cinq etats : chargement, contenu, vide (avec son geste), erreur, hors
//   ligne (S9) ;
// - 320 px, texte x2, arabe (RTL), un seul bouton plein, aucun mot coupe.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/attente_classe/modele_attente.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/attente_classe/frise_attente.dart';
import 'package:rewayah_academy/features/attente_classe/libelles_attente.dart';
import 'package:rewayah_academy/features/attente_classe/suivi_attente_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/attente_donnees.dart';
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';

List<Override> _avec(PortSuiviAttente port) => <Override>[
  portSuiviAttenteProvider.overrideWithValue(port),
];

Future<void> _ecran(
  WidgetTester tester, {
  required List<Override> surcharges,
  String id = 'd1',
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
  CheminsAttente chemins = CheminsAttente.tuteur,
}) => monterRecrutement(
  tester,
  chemin: '/tuteur/attente/:demandeId',
  depart: '/tuteur/attente/$id',
  ecran: (s) => SuiviAttentePage(
    demandeId: s.pathParameters['demandeId']!,
    chemins: chemins,
  ),
  autres: <String>['/tuteur', '/tuteur/parcours/:eleveId'],
  surcharges: surcharges,
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

Future<void> _avecSuivi(
  WidgetTester tester,
  SuiviAttente suivi, {
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
  CheminsAttente chemins = CheminsAttente.tuteur,
}) => _ecran(
  tester,
  surcharges: _avec(PortSuiviAttenteFaux(<SuiviAttente>[suivi])),
  largeur: largeur,
  echelle: echelle,
  direction: direction,
  chemins: chemins,
);

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

void main() {
  // Les vraies polices : avec la police de test (Ahem, un carre par lettre),
  // « formation » ne tient pas a 320 px, texte x2, et la mesure des mots
  // coupes accuse un defaut qui n'existe pas.
  setUpAll(() async {
    await chargerPolicesDuDepot();
  });

  group('les cinq etapes (S1)', () {
    testWidgets('toujours cinq, dans l\'ordre, avec leurs mots', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(tester, suiviDeTest(delai: delaiDeTest()));
      final f = t.suiviAttente.etapes;
      for (final String mot in <String>[
        f.recue,
        f.formation,
        f.confirmee,
        f.enseignant,
        f.pret,
      ]) {
        expect(find.text(mot), findsOneWidget);
      }
      double y(int n) =>
          tester.getTopLeft(find.byKey(FriseAttente.cleEtape(n))).dy;
      expect(y(1), lessThan(y(2)));
      expect(y(2), lessThan(y(3)));
      expect(y(3), lessThan(y(4)));
      expect(y(4), lessThan(y(5)));
    });

    testWidgets('aucune barre, aucun pourcentage : rien qui avance seul', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(tester, suiviDeTest(delai: delaiDeTest()));
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('l\'etape 1 : demande recue ; la formation est en cours', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(tester, suiviDeTest(delai: delaiDeTest()));
      expect(
        find.text(t.suiviAttente.dit.recueFait),
        findsOneWidget,
        reason: 'la demande est arrivee',
      );
      expect(
        find.text(t.suiviAttente.dit.formationEnCours),
        findsOneWidget,
        reason: 'qui agit : l\'academie reunit les eleves',
      );
      expect(_cle('attente-en-cours-2'), findsOneWidget);
      expect(_cle('attente-en-cours-3'), findsNothing);
      // L'etape 1 porte sa date ; l'etape 2 n'en a pas, le serveur n'en connait pas.
      expect(_cle('attente-date-1'), findsOneWidget);
      expect(_cle('attente-date-2'), findsNothing);
      expect(_cle('attente-depuis-2'), findsOneWidget);
      expect(find.byKey(FriseAttente.cleEtape(5)), findsOneWidget);
      expect(find.text(t.suiviAttente.dit.pretAVenir), findsOneWidget);
    });

    testWidgets(
      'l\'etape 3 : classe confirmee, nommee, et l\'enseignant attendu',
      (WidgetTester tester) async {
        await _avecSuivi(
          tester,
          suiviDeTest(
            etapes: etapesJusqua(2),
            classe: 'Classe Al-Fatiha',
            enseignant: enseignantVisible,
          ),
        );
        expect(
          find.text(
            t.suiviAttente.dit.confirmeeFaitNom(classe: 'Classe Al-Fatiha'),
          ),
          findsOneWidget,
        );
        expect(_cle('attente-en-cours-4'), findsOneWidget);
        expect(find.text(t.suiviAttente.dit.enseignantEnCours), findsOneWidget);
        // Avant l'etape 4, aucun nom d'enseignant nulle part.
        expect(_cle('attente-carte-enseignant'), findsNothing);
        expect(find.textContaining('Camara'), findsNothing);
        expect(find.textContaining('Ibrahim'), findsNothing);
      },
    );

    testWidgets('l\'etape 5 : tout est pret, le premier cours dit', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(tester, suiviToutEstPret());
      expect(find.text(t.suiviAttente.dit.pretFait), findsOneWidget);
      expect(
        find.text(
          t.suiviAttente.premierCours(
            // Le jour glisse dans la phrase : en minuscule.
            quand: enMinuscule(
              t.suiviDemandes.debutValeur(
                date: t.commun.dates.jourDate(
                  jour: t.commun.dates.jours[0],
                  numero: 16,
                  mois: t.commun.dates.mois[10],
                ),
                heure: '18:00',
                deVille: 'de Paris',
              ),
            ),
          ),
        ),
        findsOneWidget,
      );
      expect(_cle('attente-en-cours-5'), findsNothing);
      expect(
        _cle('attente-pret-5'),
        findsOneWidget,
        reason: 'tout est franchi : « Tout est pret » est mis en avant',
      );
      expect(_cle('attente-resume'), findsOneWidget);
    });

    testWidgets('l\'etape 5 en cours sans date : l\'ecran n\'en invente pas', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(
        tester,
        suiviDeTest(
          etapes: etapesJusqua(3),
          classe: 'Classe Al-Fatiha',
          enseignant: enseignantVisible,
        ),
      );
      expect(find.text(t.suiviAttente.dit.pretEnCours), findsOneWidget);
      expect(_cle('attente-premier-cours'), findsNothing);
    });
  });

  group('le delai : une phrase vraie, rien d\'autre (13/11)', () {
    testWidgets('aucune duree, aucune date limite, aucun point d\'etape', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(tester, suiviDeTest(delai: delaiDeTest()));
      expect(find.textContaining('jours au plus'), findsNothing);
      expect(find.textContaining('Date limite'), findsNothing);
      expect(find.textContaining('Point d'), findsNothing);
      expect(find.textContaining('23 novembre'), findsNothing);
      expect(find.textContaining('16 novembre'), findsNothing);
      expect(find.text(t.suiviAttente.delai.depasse), findsNothing);
    });

    testWidgets(
      'le delai depasse dit la phrase vraie, sans regle ni promesse',
      (WidgetTester tester) async {
        await _avecSuivi(
          tester,
          suiviDeTest(delai: delaiDeTest(depasse: true, pointPasse: true)),
        );
        expect(find.text(t.suiviAttente.delai.depasse), findsOneWidget);
        expect(find.textContaining('jours au plus'), findsNothing);
        expect(find.textContaining('Date limite'), findsNothing);
        expect(find.textContaining('prolonge'), findsNothing);
        expect(find.textContaining('accord'), findsNothing);
      },
    );

    testWidgets('sans valeur dans les reglages, l\'ecran ne promet rien', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(tester, suiviDeTest());
      expect(_cle('attente-delai-0'), findsNothing);
      expect(find.textContaining('jours au plus'), findsNothing);
      expect(find.textContaining('Date limite'), findsNothing);
    });

    testWidgets('le delai disparait avec la classe confirmee', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(
        tester,
        suiviDeTest(etapes: etapesJusqua(2), classe: 'Classe Al-Fatiha'),
      );
      expect(_cle('attente-delai-0'), findsNothing);
    });
  });

  group('les cas hors du chemin droit (S3)', () {
    testWidgets('la classe attend son enseignant : etat vrai', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(
        tester,
        suiviDeTest(
          cas: CasAttente.enAttenteEnseignant,
          etapes: etapesJusqua(2),
          classe: 'Classe Al-Fatiha',
        ),
      );
      expect(find.text(t.suiviAttente.dit.enseignantEnAttente), findsOneWidget);
    });

    testWidgets('la liste d\'attente : les classes sont pleines', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(tester, suiviDeTest(cas: CasAttente.listeAttente));
      expect(
        find.text(t.suiviAttente.dit.formationListeAttente),
        findsOneWidget,
      );
    });

    testWidgets('un changement de creneau recent est dit', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(
        tester,
        suiviDeTest(
          etapes: etapesJusqua(2),
          classe: 'Classe Al-Fatiha',
          creneauChangeLe: DateTime(2026, 11, 12, 8, 0),
        ),
      );
      expect(_cle('attente-changement'), findsOneWidget);
      expect(find.textContaining('12 novembre'), findsWidgets);
    });

    testWidgets('demande refusee : motif, suite et le geste', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(
        tester,
        suiviDeTest(
          cas: CasAttente.refusee,
          motif: MotifCloture.refusDirection,
          peutChoisirAutreCreneau: true,
        ),
      );
      expect(find.text(t.suiviAttente.cloture.titreRefusee), findsOneWidget);
      expect(
        find.text(t.suiviAttente.cloture.motif.refusDirection),
        findsOneWidget,
      );
      expect(find.text(t.suiviAttente.cloture.suite), findsOneWidget);
      expect(
        _cle('attente-en-cours-2'),
        findsNothing,
        reason: 'close : rien en cours',
      );
      await tester.ensureVisible(_cle('attente-autre-creneau'));
      verifierUnSeulBoutonPlein(tester);
      await tester.tap(_cle('attente-autre-creneau'));
      await laisser(tester);
      expect(find.text('temoin:/tuteur/parcours/:eleveId'), findsOneWidget);
    });

    testWidgets('demande retiree par la famille : pas de geste sans capacite', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(
        tester,
        suiviDeTest(
          cas: CasAttente.retiree,
          motif: MotifCloture.retraitFamille,
        ),
      );
      expect(find.text(t.suiviAttente.cloture.titreRetiree), findsOneWidget);
      expect(
        find.text(t.suiviAttente.cloture.motif.retraitFamille),
        findsOneWidget,
      );
      expect(_cle('attente-autre-creneau'), findsNothing);
      expect(find.text(t.suiviAttente.cloture.suite), findsNothing);
    });

    testWidgets(
      'classe non constituee et motif inconnu : jamais un refus suppose',
      (WidgetTester tester) async {
        await _avecSuivi(
          tester,
          suiviDeTest(
            cas: CasAttente.close,
            motif: MotifCloture.classeNonConstituee,
          ),
        );
        expect(find.text(t.suiviAttente.cloture.titreClose), findsOneWidget);
        expect(
          find.text(t.suiviAttente.cloture.motif.classeNonConstituee),
          findsOneWidget,
        );
        expect(find.text(t.suiviAttente.cloture.titreRefusee), findsNothing);
      },
    );
  });

  group('la carte de l\'enseignant (S4)', () {
    testWidgets('a l\'etape 4 : nom, langue, deux pays, mot ; rien d\'autre', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(tester, suiviToutEstPret());
      expect(_cle('attente-carte-enseignant'), findsOneWidget);
      // Civilite et prenom ; jamais le nom de famille (revue du 13/11).
      expect(find.text('Sayyid Ibrahim'), findsOneWidget);
      expect(find.textContaining('Camara'), findsNothing);
      expect(_cle('attente-enseignant-langue'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(_cle('attente-enseignant-origine'), findsOneWidget);
      expect(find.textContaining('Guinée'), findsOneWidget);
      expect(_cle('attente-enseignant-residence'), findsOneWidget);
      expect(find.textContaining('France'), findsOneWidget);
      expect(_cle('attente-enseignant-mot'), findsOneWidget);
      expect(find.text('Je suis heureux de vous retrouver.'), findsOneWidget);
      expect(_cle('attente-enseignant-photo'), findsOneWidget);
      expect(_cle('attente-enseignant-presenter'), findsOneWidget);
      // Ni ville, ni telephone, ni courriel, ni naissance, ni piece : le
      // modele ne les porte pas, donc l'ecran ne peut pas les montrer.
      for (final String mot in <String>[
        '@',
        'Ville',
        'Téléphone',
        'naissance',
      ]) {
        expect(find.textContaining(mot), findsNothing);
      }
    });

    testWidgets(
      'l\'enseignant qui ne montre ni pays ni mot : civilite, prenom, langue, photo',
      (WidgetTester tester) async {
        await _avecSuivi(
          tester,
          suiviToutEstPret(enseignant: enseignantDiscret),
        );
        expect(find.text('Sayyida Khadija'), findsOneWidget);
        expect(find.textContaining('Diallo'), findsNothing);
        expect(_cle('attente-enseignant-langue'), findsOneWidget);
        // Le reglage ne masque pas la photo : la source unique des photos decide.
        expect(_cle('attente-enseignant-photo'), findsOneWidget);
        expect(_cle('attente-enseignant-origine'), findsNothing);
        expect(_cle('attente-enseignant-residence'), findsNothing);
        expect(_cle('attente-enseignant-mot'), findsNothing);
      },
    );

    testWidgets('un pays non declare n\'est pas rendu, jamais « inconnu »', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(
        tester,
        suiviToutEstPret(
          enseignant: const CarteEnseignantAttente(
            prenom: 'Ibrahim',
            titre: 'sayyid',
            montre: true,
            enseignantId: 'ens-1',
            paysOrigine: 'GN',
          ),
        ),
      );
      expect(_cle('attente-enseignant-origine'), findsOneWidget);
      expect(_cle('attente-enseignant-residence'), findsNothing);
      expect(find.textContaining('nconnu'), findsNothing);
    });
  });

  group('la version simple de l\'enfant (S6)', () {
    testWidgets('tutoiement, aucun delai chiffre, rien sur l\'argent', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(
        tester,
        suiviDeTest(versionSimple: true, delai: delaiDeTest()),
        chemins: CheminsAttente.enfant,
      );
      expect(find.text(t.suiviAttente.titreSimple), findsOneWidget);
      expect(find.text(t.suiviAttente.contexteSimple), findsOneWidget);
      expect(find.text(t.suiviAttente.dit.recueFaitSimple), findsOneWidget);
      expect(_cle('attente-delai-0'), findsNothing);
      expect(find.textContaining('jours'), findsNothing);
      for (final String mot in <String>[
        '€',
        '\$',
        'prix',
        'tarif',
        'paiement',
      ]) {
        expect(find.textContaining(mot), findsNothing);
      }
    });

    testWidgets('l\'enfant dont la demande est refusee : pas de geste', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(
        tester,
        suiviDeTest(
          versionSimple: true,
          cas: CasAttente.refusee,
          motif: MotifCloture.refusDirection,
          peutChoisirAutreCreneau: true,
        ),
        chemins: CheminsAttente.enfant,
      );
      expect(find.text(t.suiviAttente.cloture.simple.refusee), findsOneWidget);
      expect(_cle('attente-autre-creneau'), findsNothing);
    });

    testWidgets('l\'enfant qui n\'a rien demande : pas de geste pour choisir', (
      WidgetTester tester,
    ) async {
      await _ecran(
        tester,
        surcharges: _avec(PortSuiviAttenteFaux()),
        chemins: CheminsAttente.enfant,
      );
      expect(find.text(t.suiviAttente.vide.messageSimple), findsOneWidget);
      expect(find.text(t.suiviAttente.vide.action), findsNothing);
    });
  });

  group('les mots selon qui lit (arbitrage du 13/11)', () {
    // Tous les textes affiches, d'un seul tenant.
    String tout(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((Text w) => w.data ?? w.textSpan?.toPlainText() ?? '')
        .join(' | ')
        // Le mot de l'enseignant est le sien, affiche tel qu'il l'a ecrit.
        .replaceAll(enseignantVisible.mot ?? '', '');

    testWidgets(
      'le tuteur d\'un enfant de 6 a 9 ans lit les mots des adultes',
      (WidgetTester tester) async {
        await _avecSuivi(
          tester,
          suiviToutEstPret(versionSimple: true),
          chemins: CheminsAttente.tuteur,
        );
        expect(find.text(t.suiviAttente.titre), findsOneWidget);
        expect(find.text(t.suiviAttente.dit.recueFait), findsOneWidget);
        expect(find.text(t.suiviAttente.titreSimple), findsNothing);
        // Dates, creneau et fuseau : le tuteur les lit.
        expect(_cle('attente-creneau'), findsOneWidget);
        expect(_cle('attente-fuseau'), findsOneWidget);
        expect(_cle('attente-date-1'), findsOneWidget);
      },
    );

    testWidgets('l\'enfant de 6 a 9 ans ne lit ni date ni duree', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(
        tester,
        suiviToutEstPret(versionSimple: true),
        chemins: CheminsAttente.enfant,
      );
      expect(_cle('attente-creneau'), findsNothing);
      expect(_cle('attente-fuseau'), findsNothing);
      for (int n = 1; n <= 5; n++) {
        expect(_cle('attente-date-$n'), findsNothing, reason: 'etape $n');
      }
      expect(find.text(t.suiviAttente.tu.premierCoursPetit), findsOneWidget);
      final String texte = tout(tester);
      expect(texte, isNot(contains('novembre')));
      expect(texte, isNot(contains('18')));
      expect(texte, isNot(matches(RegExp(r'\b(jours?|heures?|semaines?)\b'))));
      // Et jamais les mots des adultes.
      expect(texte, isNot(matches(RegExp(r'\b[Vv]ot(re|res)\b|\b[Vv]ous\b'))));
    });

    testWidgets(
      'l\'enfant de 6 a 9 ans dont la classe attend : rien de chiffre',
      (WidgetTester tester) async {
        await _avecSuivi(
          tester,
          suiviDeTest(
            versionSimple: true,
            delai: delaiDeTest(depasse: true),
            creneauChangeLe: DateTime(2026, 11, 10, 9, 0),
            etapes: etapesJusqua(1),
            classe: 'Classe Al-Fatiha',
          ),
          chemins: CheminsAttente.enfant,
        );
        final String texte = tout(tester);
        expect(texte, isNot(contains('novembre')));
        expect(texte, isNot(matches(RegExp(r'\b\d+\s*(jours?|h)\b'))));
        expect(
          texte,
          isNot(matches(RegExp(r'\b[Vv]ot(re|res)\b|\b[Vv]ous\b'))),
        );
      },
    );

    testWidgets('un mineur de 10 a 17 ans : tutoiement, avec ses dates', (
      WidgetTester tester,
    ) async {
      final SuiviAttente s = suiviToutEstPret();
      expect(s.versionSimple, isFalse);
      expect(s.typePublic, 'enfant');
      await _avecSuivi(tester, s, chemins: CheminsAttente.enfant);
      expect(find.text(t.suiviAttente.titreSimple), findsOneWidget);
      expect(_cle('attente-date-1'), findsOneWidget);
      expect(_cle('attente-creneau'), findsOneWidget);
      final String texte = tout(tester);
      expect(texte, contains('Ton premier cours'));
      expect(texte, isNot(matches(RegExp(r'\b[Vv]ot(re|res)\b|\b[Vv]ous\b'))));
      // Pas le geste du tuteur ni celui de l'enseignant.
      expect(
        find.text(t.suiviAttente.enseignant.peutSePresenter),
        findsNothing,
      );
    });

    testWidgets('un mineur de 10 a 17 ans, delai depasse : tutoiement', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(
        tester,
        suiviDeTest(delai: delaiDeTest(depasse: true, pointPasse: true)),
        chemins: CheminsAttente.enfant,
      );
      expect(find.text(t.suiviAttente.tu.depasse), findsOneWidget);
      expect(find.text(t.suiviAttente.delai.depasse), findsNothing);
    });

    testWidgets('delai depasse : une phrase vraie, aucune action promise', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(
        tester,
        suiviDeTest(delai: delaiDeTest(depasse: true, pointPasse: true)),
      );
      expect(
        find.text(
          'La formation de votre classe prend plus de temps que prévu. '
          'L\'académie vous écrit.',
        ),
        findsOneWidget,
      );
      final String texte = tout(tester);
      for (final String promesse in <String>[
        'prolonge',
        'accord',
        'autre classe',
        'relance',
        'automatique',
      ]) {
        expect(texte, isNot(contains(promesse)));
      }
    });
  });

  group('les cinq etats (S9)', () {
    testWidgets('chargement : un squelette', (WidgetTester tester) async {
      await _ecran(tester, surcharges: _avec(const PortSuiviAttenteSansFin()));
      expect(find.byType(Skeleton), findsWidgets);
    });

    testWidgets(
      'vide : « Vous n\'avez pas encore choisi de classe » et le geste',
      (WidgetTester tester) async {
        await _ecran(tester, surcharges: _avec(PortSuiviAttenteFaux()));
        expect(find.byType(EmptyState), findsOneWidget);
        expect(find.text(t.suiviAttente.vide.message), findsOneWidget);
        expect(find.text(t.suiviAttente.vide.action), findsOneWidget);
        await tester.tap(find.text(t.suiviAttente.vide.action));
        await laisser(tester);
        expect(find.text('temoin:/tuteur'), findsOneWidget);
      },
    );

    testWidgets('demande introuvable : on le dit et on revient', (
      WidgetTester tester,
    ) async {
      await _ecran(
        tester,
        surcharges: _avec(PortSuiviAttenteFaux(<SuiviAttente>[suiviDeTest()])),
        id: 'autre',
      );
      expect(find.text(t.suiviAttente.introuvable), findsOneWidget);
      await tester.tap(find.text(t.suiviAttente.retour));
      await laisser(tester);
      expect(find.text('temoin:/tuteur'), findsOneWidget);
    });

    testWidgets('erreur : la phrase et « Reessayer »', (
      WidgetTester tester,
    ) async {
      await _ecran(tester, surcharges: _avec(const PortSuiviAttenteEnEchec()));
      expect(find.byType(EtatSysteme), findsOneWidget);
      expect(find.text(t.suiviAttente.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets('hors ligne sans rien lire : le bloc dit ce qui manque', (
      WidgetTester tester,
    ) async {
      await _ecran(
        tester,
        surcharges: _avec(const PortSuiviAttenteEnEchec()),
        horsLigne: true,
      );
      expect(find.text(t.suiviAttente.sansDonnees), findsOneWidget);
    });
  });

  group('le franchissement d\'une etape', () {
    testWidgets('le marqueur change quand le serveur change l\'etat', (
      WidgetTester tester,
    ) async {
      final PortSuiviAttenteFaux port = PortSuiviAttenteFaux(<SuiviAttente>[
        suiviDeTest(delai: delaiDeTest()),
      ]);
      await _ecran(tester, surcharges: _avec(port));
      expect(_cle('attente-marqueur-3-aVenir'), findsOneWidget);
      expect(_cle('attente-marqueur-3-fait'), findsNothing);
      port.pousser(<SuiviAttente>[
        suiviDeTest(etapes: etapesJusqua(2), classe: 'Classe Al-Fatiha'),
      ]);
      await laisser(tester);
      expect(_cle('attente-marqueur-3-fait'), findsOneWidget);
      expect(_cle('attente-marqueur-2-fait'), findsOneWidget);
      expect(_cle('attente-en-cours-4'), findsOneWidget);
    });

    testWidgets('sans passage du serveur, rien ne bouge', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(tester, suiviDeTest(delai: delaiDeTest()));
      await tester.pump(const Duration(seconds: 30));
      expect(_cle('attente-marqueur-2-enCours'), findsOneWidget);
      expect(_cle('attente-marqueur-3-aVenir'), findsOneWidget);
    });
  });

  group('geometrie', () {
    for (final (String nom, double largeur, double echelle)
        in <(String, double, double)>[
          ('320 px, texte x2', 320, 2),
          ('390 px', 390, 1),
          ('1440 px', 1440, 1),
        ]) {
      testWidgets('tout est pret, $nom : aucun debordement, aucun mot coupe', (
        WidgetTester tester,
      ) async {
        await _avecSuivi(
          tester,
          suiviToutEstPret(),
          largeur: largeur,
          echelle: echelle,
        );
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester);
        // Le nom d'une classe (« Al-Fatiha ») peut passer a la ligne apres son
        // trait d'union ; chaque partie reste entiere.
        expect(
          motsCoupes(tester, find.byType(Scaffold), traitDUnionPermis: true),
          isEmpty,
        );
      });

      testWidgets('delai depasse, $nom : aucun debordement', (
        WidgetTester tester,
      ) async {
        await _avecSuivi(
          tester,
          suiviDeTest(delai: delaiDeTest(depasse: true, pointPasse: true)),
          largeur: largeur,
          echelle: echelle,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
      });

      testWidgets('demande refusee, $nom : un seul bouton plein', (
        WidgetTester tester,
      ) async {
        await _avecSuivi(
          tester,
          suiviDeTest(
            cas: CasAttente.refusee,
            motif: MotifCloture.refusDirection,
            peutChoisirAutreCreneau: true,
          ),
          largeur: largeur,
          echelle: echelle,
        );
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester);
      });
    }

    testWidgets('droite a gauche : l\'ecran se monte sans debordement', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(
        tester,
        suiviToutEstPret(),
        direction: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      expect(_cle('attente-carte-enseignant'), findsOneWidget);
    });

    testWidgets('lecteur d\'ecran : chaque etape est une phrase entiere', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await _avecSuivi(tester, suiviDeTest(delai: delaiDeTest()));
      // La ligne de l'etape est un seul nœud : rang, mot, etat, phrase.
      final Finder etape = find.descendant(
        of: find.byKey(FriseAttente.cleEtape(2)),
        matching: find.bySemanticsLabel(
          RegExp(
            '^${RegExp.escape(t.suiviAttente.etapeSurTotal(n: 2, total: 5, etape: t.suiviAttente.etapes.formation))}, ${RegExp.escape(t.suiviAttente.etats.enCours)}',
          ),
        ),
      );
      expect(etape, findsOneWidget);
      poignee.dispose();
    });
  });

  group('en arabe (droite a gauche)', () {
    setUp(() async {
      await LocaleSettings.setLocale(AppLocale.ar);
    });
    tearDown(() async {
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    for (final (String nom, double largeur, double echelle)
        in <(String, double, double)>[
          ('320 px, texte x2', 320, 2),
          ('390 px', 390, 1),
          ('1440 px', 1440, 1),
        ]) {
      testWidgets('les cinq etapes et la carte de l\'enseignant, $nom', (
        WidgetTester tester,
      ) async {
        await _avecSuivi(
          tester,
          suiviToutEstPret(),
          largeur: largeur,
          echelle: echelle,
          direction: TextDirection.rtl,
        );
        final f = t.suiviAttente.etapes;
        expect(
          f.recue,
          'تم استلام الطلب',
          reason: 'la langue active est l\'arabe',
        );
        for (final String mot in <String>[
          f.recue,
          f.formation,
          f.confirmee,
          f.enseignant,
          f.pret,
        ]) {
          expect(find.text(mot), findsOneWidget);
        }
        expect(_cle('attente-carte-enseignant'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(
          motsCoupes(tester, find.byType(Scaffold), traitDUnionPermis: true),
          isEmpty,
        );
      });
    }

    testWidgets('demande refusee : le motif et le geste en arabe', (
      WidgetTester tester,
    ) async {
      await _avecSuivi(
        tester,
        suiviDeTest(
          cas: CasAttente.refusee,
          motif: MotifCloture.refusDirection,
          peutChoisirAutreCreneau: true,
        ),
        direction: TextDirection.rtl,
      );
      expect(find.text(t.suiviAttente.cloture.titreRefusee), findsOneWidget);
      expect(find.text(t.suiviAttente.cloture.autreCreneau), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('les libelles', () {
    test('la ligne de la carte d\'accueil', () {
      expect(
        ligneCarte(suiviDeTest()),
        t.suiviAttente.carte.ligne(
          prenom: 'Yusuf',
          n: 2,
          total: 5,
          etape: t.suiviAttente.etapes.formation,
        ),
      );
      expect(
        ligneCarte(
          suiviDeTest(
            cas: CasAttente.refusee,
            motif: MotifCloture.refusDirection,
          ),
        ),
        'Yusuf : ${t.suiviAttente.cloture.titreRefusee}',
      );
      expect(ligneCarte(suiviToutEstPret()), contains('Yusuf'));
      expect(ligneCarte(suiviToutEstPret()), contains('18:00'));
    });

    test('la ligne de la carte : le tuteur lit la date, l\'enfant de 6 a 9 ans non', () {
      final SuiviAttente brut = suiviToutEstPret(versionSimple: true);
      expect(
        ligneCarte(brut.pourEspace(espaceEnfant: false)),
        contains('18:00'),
      );
      expect(
        ligneCarte(brut.pourEspace(espaceEnfant: true)),
        t.suiviAttente.carte.pretSansDate(prenom: 'Yusuf'),
      );
    });
  });
}

// ADM-21 : la candidature ouverte par la direction.
//
// Ce que le test prouve :
// - les cinq etats (chargement, contenu, historique vide, erreur, hors ligne) et
//   les etats propres de la fiche : capacite indisponible, hors portee et
//   absente (deux textes), acces refuse, genre du lecteur inconnu, exception du
//   super-admin, blocs non servis (chacun le dit seul) ;
// - l'ordre des sections de la fiche ; aucun contact avant « Voir le contact »
//   (et la lecture du contact est comptee une fois par ouverture) ; aucun genre,
//   aucun code d'etat, de dependance ni nom de personne dans l'historique ;
// - la prochaine action est le seul bouton plein, et seulement quand le
//   serveur ouvre le geste ; hors ligne, aucun geste n'est rendu ;
// - chaque geste passe par une feuille de confirmation : ce qu'il exige est
//   demande et nomme (motif, modele, elements, moyen, canal, jour), rien ne part
//   tant qu'il manque quelque chose, le geste part avec la version attendue et
//   une cle d'idempotence, le succes ne se dit qu'apres la reponse du serveur et
//   la candidature est relue ;
// - chaque refus nomme du serveur se dit en mots, dans la feuille, sans rien
//   ecrire ; un essai non confirme rejoue la MEME cle, un champ change prend une
//   cle neuve.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_candidature/blocs_candidature.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_geste.dart';
import 'package:rewayah_academy/features/admin_candidature/libelles_candidature.dart';
import 'package:rewayah_academy/features/admin_candidature/plan_dossier.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';
import 'hote_candidature.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

/// Le texte de la cle de traduction courante.
String get _branchement => t.commun.etats.branchementServeur;

/// Les codes que la direction ne lit jamais a l'ecran.
const List<String> _codesBruts = <String>[
  'a_completer',
  'en_examen',
  'paiement_non_disponible',
  'entretien_a_planifier',
  'entretien_planifie',
  'decision_en_attente',
  'prequalification',
  'verifications',
  'confirmee',
  'en_cours',
  'a_verifier',
  'compatible',
  'incompatible',
  'lien_public',
  'refus_general',
  'pause_attente_besoin',
  'complement_clos',
  'cadre_religieux',
  'CAND-BR',
];

/// Tout le texte visible de l'ecran (et des feuilles ouvertes).
String _toutLeTexte(WidgetTester tester) => <String>[
  for (final Element e in find.byType(Text).evaluate())
    if ((e.widget as Text).data case final String d) d,
  for (final Element e in find.byType(RichText).evaluate())
    (e.widget as RichText).text.toPlainText(),
].join('\n');

FauxCandidaturesDirection _port({
  DetailCandidature? detail,
  CapacitesCandidatures capacites = capacitesGestes,
  Object? Function(int)? erreurLire,
  Object? Function(DemandeGeste, int)? erreurGeste,
  DetailCandidature Function(DemandeGeste, DetailCandidature)? effet,
  Map<String, MoyensConfirmes>? moyens,
  List<EvenementCandidature>? historique,
  List<ResponsablePossible> responsables = const <ResponsablePossible>[],
  bool responsablesIndisponibles = false,
}) {
  final DetailCandidature d = detail ?? detailTest();
  return FauxCandidaturesDirection(
    capacitesRendues: capacites,
    details: <DetailCandidature>[d],
    erreurLire: erreurLire,
    erreurGeste: erreurGeste,
    effetGeste: effet,
    contacts: const <String, ContactCandidat>{
      'c1': ContactCandidat(
        courriel: 'amina.diallo@exemple.org',
        telephoneBrut: '0771234567',
      ),
    },
    moyens:
        moyens ??
        const <String, MoyensConfirmes>{
          'SN': MoyensConfirmes(
            virementBancaire: true,
            operateurs: <OperateurPaiement>[
              OperateurPaiement(code: 'orange_money', nom: 'Orange Money'),
            ],
          ),
        },
    historiques: <String, List<EvenementCandidature>>{
      d.ligne.id:
          historique ??
          <EvenementCandidature>[
            evenementTest(
              id: 4,
              auteur: AuteurEvenement.candidat,
              etatAvant: EtatCandidature.aCompleter,
              etatApres: EtatCandidature.enExamen,
              etapeAvant: EtapeCandidature.prequalification,
              etapeApres: EtapeCandidature.prequalification,
            ),
            evenementTest(
              id: 3,
              auteur: AuteurEvenement.direction,
              etatAvant: EtatCandidature.enExamen,
              etatApres: EtatCandidature.aCompleter,
              etapeAvant: EtapeCandidature.prequalification,
              etapeApres: EtapeCandidature.prequalification,
              motif: 'Disponibilites a preciser.',
            ),
            evenementTest(
              id: 2,
              type: 'controle',
              auteur: AuteurEvenement.systeme,
            ),
            evenementTest(
              id: 1,
              type: 'creee',
              auteur: AuteurEvenement.systeme,
            ),
          ],
    },
    responsables: responsables,
    responsablesIndisponibles: responsablesIndisponibles,
  );
}

/// Le dossier d'une candidature en examen dont le versement est confirme : la
/// prochaine action est d'admettre.
DetailCandidature _compatible() =>
    detailTest(paiement: EtatVersement.compatible);

/// Le dossier apres un geste : meme candidature, version suivante, etat change.
DetailCandidature _apres(
  DetailCandidature d, {
  IssueCandidature? issue,
  bool? enPause,
  EtatVersement? paiement,
  EtatCandidature? etat,
  EtapeCandidature? etape,
}) => detailTest(
  id: d.ligne.id,
  etape: etape ?? d.ligne.etape,
  etat: etat ?? d.ligne.etat,
  issue: issue ?? d.ligne.issue,
  enPause: enPause ?? d.ligne.enPause,
  paiement: paiement ?? d.ligne.paiement,
  version: d.version + 1,
);

Future<void> _monter(
  WidgetTester tester,
  PortCandidaturesDirection? port, {
  bool horsLigne = false,
  double largeur = 390,
  String? identifiant = 'c1',
}) => monterCandidature(
  tester,
  port: port,
  horsLigne: horsLigne,
  largeur: largeur,
  identifiant: identifiant,
  ouvrirRubriques: false,
);

Future<void> _tapper(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await laisser(tester, fois: 2);
  await tester.tap(f, warnIfMissed: false);
  await laisser(tester);
}

/// La prochaine action du serveur, ou qu'elle soit dans le dossier en trois
/// etages (BE-DOSSIER) : la decision de la barre, ou le lien de la rubrique.
const List<String> _clesPrincipal = <String>[
  'candidature-decision-leverPause',
  'candidature-decision-validerPiece',
  'rubrique-geste-confirmerMoyenPaiement',
  'candidature-decision-admettreVerifications',
];

/// La prochaine action : la premiere de la table du serveur qui est vraiment
/// proposee (un bouton grise de la barre n'en est pas une).
Finder _principal() {
  Finder? dernier;
  for (final String cle in _clesPrincipal) {
    dernier = find.byWidgetPredicate(
      (Widget w) =>
          w.key == ValueKey<String>(cle) &&
          (w is! ActionPrincipale || w.onPress != null),
    );
    if (dernier.evaluate().isNotEmpty) return dernier;
  }
  return dernier!;
}

Future<void> _agirPrincipal(WidgetTester tester) =>
    _tapper(tester, _principal().first);

/// Un geste, ou qu'il soit : la decision de la barre, le lien de sa rubrique,
/// sinon le menu « ⋯ ».
Future<void> _geste(WidgetTester tester, GesteCandidature g) async {
  for (final Key k in <Key>[
    ValueKey<String>('candidature-decision-${g.name}'),
    ValueKey<String>('rubrique-geste-${g.name}'),
  ]) {
    if (find.byKey(k).evaluate().isNotEmpty) {
      await _tapper(tester, find.byKey(k));
      return;
    }
  }
  await _tapper(tester, find.byKey(BarreDecisionDossier.cleMenu));
  await tester.tap(find.text(libelleGeste(g)));
  await laisser(tester);
}

/// Ouvre une rubrique du dossier.
Future<void> _ouvrir(WidgetTester tester, RubriqueDossierCode c) async {
  // Une rubrique deja ouverte (c'est elle qui bloque) reste ouverte.
  if (find.byKey(RubriqueDossier.cleContenu(c)).evaluate().isNotEmpty) return;
  final Finder entete = find.byKey(RubriqueDossier.cleEntete(c));
  await tester.ensureVisible(entete);
  await laisser(tester, fois: 2);
  await tester.tap(entete, warnIfMissed: false);
  await laisser(tester);
}

/// Ouvre toutes les rubriques (le test lit leur contenu).
Future<void> _toutOuvrir(WidgetTester tester) async {
  for (final RubriqueDossierCode c in RubriqueDossierCode.values) {
    final Finder entete = find.byKey(RubriqueDossier.cleEntete(c));
    if (entete.evaluate().isNotEmpty) {
      await _ouvrir(tester, c);
    }
  }
}

Future<void> _saisirMotif(WidgetTester tester, String texte) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(FeuilleGeste.cleMotif),
      matching: find.byType(EditableText),
    ),
    texte,
  );
  await laisser(tester, fois: 2);
}

/// Le nombre de boutons pleins visibles : au plus un par surface (la page, ou
/// la feuille ouverte), jamais deux.
int _pleins([Finder? dans]) {
  final Finder pleins = find.byWidgetPredicate(
    (Widget w) => w is ActionPrincipale && w.niveau == NiveauAction.principale,
  );
  return dans == null
      ? pleins.evaluate().length
      : find.descendant(of: dans, matching: pleins).evaluate().length;
}

Future<void> _valider(WidgetTester tester) =>
    _tapper(tester, find.byKey(FeuilleGeste.cleValider));

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.en);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('contenu', () {
    testWidgets('la situation : nom, reference, salle, etat, versement, pays', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port());
      await _toutOuvrir(tester);
      expect(find.text('Amina Diallo'), findsWidgets);
      // La reference s'affiche aux traits d'union insecables (U+2011).
      expect(find.text('CAND‑0000C1'), findsOneWidget);
      final String texte = _toutLeTexte(tester);
      expect(texte, contains(t.recrutement.salles.examen));
      expect(texte, contains(t.admin.candidatures.etats.enExamen));
      expect(texte, contains(t.admin.candidatures.etats.versement.aVerifier));
      expect(texte, contains('Sénégal'));
      expect(texte, contains(t.admin.candidatures.etats.provenance.lienPublic));
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('l\'ordre : etage 1, resume, puis les rubriques', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port());
      final List<Key> ordre = <Key>[
        // BE-DOSSIER (16/11/2026) : trois etages, rubriques repliees.
        EtageUnDossier.cle,
        ResumeDossier.cle,
        RubriqueDossier.cleDe(RubriqueDossierCode.piece),
        RubriqueDossier.cleDe(RubriqueDossierCode.versement),
        RubriqueDossier.cleDe(RubriqueDossierCode.langues),
        RubriqueDossier.cleDe(RubriqueDossierCode.entretien),
        RubriqueDossier.cleDe(RubriqueDossierCode.responsable),
        RubriqueDossier.cleDe(RubriqueDossierCode.contact),
        RubriqueDossier.cleDe(RubriqueDossierCode.historique),
      ];
      double precedent = -1;
      for (final Key k in ordre) {
        final Finder f = find.byKey(k);
        expect(f, findsOneWidget, reason: '$k');
        final double y = tester.getTopLeft(f).dy;
        expect(y, greaterThan(precedent), reason: '$k apres le bloc precedent');
        precedent = y;
      }
    });

    testWidgets(
      'sur grand ecran : etages 1 et 2 a gauche, rubriques a droite',
      (WidgetTester tester) async {
        await _monter(tester, _port(), largeur: 1440);
        final Offset etage1 = tester.getTopLeft(find.byKey(EtageUnDossier.cle));
        final Offset resume = tester.getTopLeft(find.byKey(ResumeDossier.cle));
        final Offset rubriques = tester.getTopLeft(
          find.byKey(CorpsDossier.cle),
        );
        expect((resume.dx - etage1.dx).abs(), lessThan(1));
        expect(rubriques.dx, greaterThan(etage1.dx + 300));
        expect((rubriques.dy - etage1.dy).abs(), lessThan(40));
        verifierUnSeulBoutonPlein(tester);
      },
    );

    testWidgets('rien de vide : un bloc non servi n\'est pas rendu', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port());
      await _ouvrir(tester, RubriqueDossierCode.entretien);
      // SALLE2-FICHE (directeur, 14/11/2026, « rien de vide affiché ») :
      // blocages, controles, piece, affectation et courriels non servis ne
      // sont plus rendus. Reste l'entretien, dont le port manque a ce test.
      expect(find.text(_branchement), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('candidature-affectation')),
        findsNothing,
      );
      // L'historique et les reponses, eux, sont servis.
      expect(
        find.text(t.admin.candidatures.detail.historiqueVide),
        findsNothing,
      );
    });

    testWidgets('des controles servis : le faux est nomme avec sa cause', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(
          detail: detailTest(
            controles: const <ControleCandidature>[
              ControleCandidature(nom: 'paiement_compatible', valeur: true),
              ControleCandidature(
                nom: 'cadre_religieux',
                valeur: false,
                cause: 'non_accepte',
              ),
              ControleCandidature(
                nom: 'questionnaire_complet',
                valeur: false,
                cause: 'perime',
              ),
            ],
          ),
        ),
      );
      await _ouvrir(tester, RubriqueDossierCode.entretien);
      final String texte = _toutLeTexte(tester);
      // « Ce qui bloque » (etage 1) nomme chaque controle faux avec sa cause :
      // aucune cause ne se perd avec le bloc « Controles ».
      expect(
        texte,
        contains(t.admin.candidatures.controles.noms.cadreReligieux),
      );
      expect(texte, contains(t.admin.candidatures.controles.causes.nonAccepte));
      expect(texte, contains(t.admin.candidatures.controles.causes.perime));
      // Les accords bloquent : leur rubrique s'ouvre, le controle y est dit.
      expect(
        find.text(t.admin.candidatures.detail.controlesFaux),
        findsWidgets,
      );
      // Plus de bloc « Controles » ; reste l'entretien, dont le port manque a
      // ce test (SALLE2-FICHE).
      expect(find.byKey(BlocControles.cle), findsNothing);
      expect(find.text(_branchement), findsOneWidget);
      for (final String code in _codesBruts) {
        expect(texte, isNot(contains(code)));
      }
    });

    testWidgets('SALLE2-GENRE : le genre en mots en tete de la fiche', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port(detail: detailTest(genre: 'female')));
      final String texte = _toutLeTexte(tester);
      // En tete de la fiche (etage 1), en mots.
      expect(find.byKey(EtageUnDossier.cleReperes), findsOneWidget);
      expect(texte, contains(t.admin.candidatures.genres.female));
      expect(texte, isNot(contains('female')));
    });

    testWidgets(
      'aucun code brut, aucun contact a l\'ecran ; sans genre lu, rien',
      (WidgetTester tester) async {
        await _monter(
          tester,
          _port(detail: detailTest(courrielAObtenir: true)),
        );
        await _toutOuvrir(tester);
        final String texte = _toutLeTexte(tester);
        for (final String code in _codesBruts) {
          expect(texte, isNot(contains(code)), reason: code);
        }
        expect(texte, isNot(contains('amina.diallo@exemple.org')));
        expect(texte, isNot(contains('0771234567')));
        expect(texte, isNot(contains('@')));
        expect(texte, isNot(contains('+221')));
        expect(texte.toLowerCase(), isNot(contains('genre')));
        expect(texte, contains(t.admin.candidatures.ligne.courrielAObtenir));
      },
    );

    testWidgets('pause et restriction se disent avec leur cause', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(
          detail: detailTest(
            enPause: true,
            repriseLe: DateTime.utc(2026, 11, 10),
            pauseModele: 'pause_attente_besoin',
          ),
        ),
      );
      await _toutOuvrir(tester);
      final String texte = _toutLeTexte(tester);
      expect(texte, contains(t.admin.candidatures.etats.enPause));
      expect(texte, contains(t.admin.candidatures.modeles.pauseAttenteBesoin));
      expect(texte, contains('10'));
    });

    testWidgets('une confirmee restreinte pour le versement : cause nommee', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(
          detail: detailTest(
            etape: EtapeCandidature.confirmee,
            etat: null,
            restreinte: true,
            restrictionCause: 'paiement',
            paiement: EtatVersement.aVerifier,
          ),
        ),
      );
      expect(
        find.text(t.admin.candidatures.etats.restreinteVersement),
        findsOneWidget,
      );
      expect(find.text(t.admin.candidatures.etats.restreinte), findsNothing);
    });

    testWidgets(
      'l\'exception du super-admin : la phrase seulement si l\'autre cote',
      (WidgetTester tester) async {
        final CapacitesCandidatures exception = CapacitesCandidatures(
          peutLire: true,
          peutLireHorsGenre: true,
          genreLecteurConnu: true,
          peutDecider: capacitesGestes.peutDecider,
          gestes: capacitesGestes.gestes,
          listes: capacitesGestes.listes,
        );
        // Le serveur ne dit pas le cote : aucune phrase, jamais devinee.
        await _monter(tester, _port(capacites: exception));
        expect(_cle('candidature-exception'), findsNothing);
      },
    );
  });

  group('reponses', () {
    testWidgets('par theme, mises en mots, avec la version du questionnaire', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port());
      await _toutOuvrir(tester);
      final String texte = _toutLeTexte(tester);
      for (final String titre in <String>[
        t.admin.candidatures.detail.cartes.langues,
        t.admin.candidatures.detail.cartes.recitation,
        t.admin.candidatures.detail.cartes.disponibilites,
        t.admin.candidatures.detail.cartes.publics,
        // Le groupe « versement » est la rubrique « Versement ».
        t.recrutement.dossier3.rubrique.versement,
      ]) {
        expect(texte, contains(titre));
      }
      expect(texte, contains('Hafs, Warsh'));
      // BE-DOSSIER : plus de texte technique (« Version du questionnaire »).
      expect(texte, isNot(contains('salle-examen-1')));
      expect(texte, contains(t.recrutement.parcours.oui));
      // Les operateurs sont nommes quand le referentiel les sert.
      expect(texte, contains('Orange Money'));
      // Les disponibilites : un groupe de jours par ligne.
      expect(texte, contains('18'));
      expect(find.text(t.admin.candidatures.detail.preRempli), findsNothing);
    });

    testWidgets('sans nom d\'operateur, le nombre, jamais le code', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port(moyens: const <String, MoyensConfirmes>{}));
      await _toutOuvrir(tester);
      final String texte = _toutLeTexte(tester);
      expect(texte, contains(t.admin.candidatures.detail.moyensIndiques(n: 1)));
      expect(texte, isNot(contains('orange_money')));
      expect(texte, isNot(contains('wave')));
    });

    testWidgets('les reponses venues de l\'ancien formulaire sont marquees', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(
          detail: detailTest(
            provenance: ProvenanceCandidature.importee,
            documents: <DocumentReponses>[
              const DocumentReponses(
                questionnaireVersion: 'formulaire-2025',
                reponses: <String, Object?>{
                  'langueMaternelle': 'poular',
                  'paysResidence': 'SN',
                },
                importe: true,
              ),
            ],
          ),
        ),
      );
      await _toutOuvrir(tester);
      expect(find.text(t.admin.candidatures.detail.preRempli), findsOneWidget);
      expect(
        _toutLeTexte(tester),
        contains(t.admin.candidatures.etats.provenance.formulairesImportes),
      );
    });

    testWidgets('aucune reponse envoyee : la phrase, pas un bloc vide', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(detail: detailTest(documents: const <DocumentReponses>[])),
      );
      expect(
        find.text(t.admin.candidatures.detail.aucuneReponse),
        findsOneWidget,
      );
    });
  });

  group('historique', () {
    testWidgets('une ligne par evenement, l\'auteur par sa qualite', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port());
      await _ouvrir(tester, RubriqueDossierCode.historique);
      await _tapper(tester, find.byKey(BlocHistorique.clePlus));
      final String texte = _toutLeTexte(tester);
      expect(texte, contains(t.admin.candidatures.historique.auteur.personne));
      expect(texte, contains(t.admin.candidatures.historique.auteur.direction));
      expect(
        texte,
        contains(t.admin.candidatures.historique.auteur.automatique),
      );
      // Jamais « Vous » ni un nom : le serveur ne rend pas l'auteur.
      expect(texte, isNot(contains('Vous')));
      expect(texte, contains('Disponibilites a preciser.'));
      // Les changements se disent par les libelles de la salle.
      expect(
        texte,
        contains(
          t.admin.candidatures.historique.deA(
            avant: t.admin.candidatures.etats.aCompleter,
            apres: t.admin.candidatures.etats.enExamen,
          ),
        ),
      );
      expect(texte, contains(t.admin.candidatures.historique.types.creee));
    });

    testWidgets(
      'par pages : le plus ancien se charge, puis le lien disparait',
      (WidgetTester tester) async {
        final FauxCandidaturesDirection port = _port();
        await _monter(tester, port);
        await _ouvrir(tester, RubriqueDossierCode.historique);
        expect(port.appelsHistorique, <int?>[null]);
        expect(
          find.text(t.admin.candidatures.historique.types.creee),
          findsNothing,
        );
        await _tapper(tester, find.byKey(BlocHistorique.clePlus));
        expect(port.appelsHistorique, <int?>[null, 3]);
        expect(
          find.text(t.admin.candidatures.historique.types.creee),
          findsOneWidget,
        );
        expect(find.byKey(BlocHistorique.clePlus), findsNothing);
      },
    );

    testWidgets(
      'apres un geste, la premiere page est relue et les pages ouvertes se referment',
      (WidgetTester tester) async {
        final FauxCandidaturesDirection port = _port(
          detail: _compatible(),
          effet: (DemandeGeste d, DetailCandidature a) => _apres(
            a,
            etape: EtapeCandidature.verifications,
            etat: EtatCandidature.entretienAPlanifier,
          ),
        );
        await _monter(tester, port);
        await _ouvrir(tester, RubriqueDossierCode.historique);
        await _tapper(tester, find.byKey(BlocHistorique.clePlus));
        expect(
          find.text(t.admin.candidatures.historique.types.creee),
          findsOneWidget,
        );
        await _agirPrincipal(tester);
        await _valider(tester);
        // L'ancien curseur ne vaut plus : la page plus ancienne se referme, et
        // le lien repart de la nouvelle premiere page.
        expect(port.appelsHistorique, <int?>[null, 3, null]);
        expect(
          find.text(t.admin.candidatures.historique.types.creee),
          findsNothing,
        );
        expect(find.byKey(BlocHistorique.clePlus), findsOneWidget);
      },
    );

    testWidgets('vide : « Aucun evenement pour le moment »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port(historique: const <EvenementCandidature>[]));
      await _ouvrir(tester, RubriqueDossierCode.historique);
      expect(
        find.text(t.admin.candidatures.detail.historiqueVide),
        findsOneWidget,
      );
    });

    testWidgets('en erreur : le bloc seul le dit, le reste s\'affiche', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port()
        ..erreurHistorique = StateError('panne');
      await _monter(tester, port);
      await _ouvrir(tester, RubriqueDossierCode.historique);
      expect(
        find.text(t.admin.candidatures.detail.historiqueEchec),
        findsOneWidget,
      );
      expect(find.text('Amina Diallo'), findsWidgets);
    });
  });

  group('contact', () {
    testWidgets('masque : rien ne se lit avant « Voir le contact »', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port();
      await _monter(tester, port);
      await _ouvrir(tester, RubriqueDossierCode.contact);
      expect(
        find.text(t.admin.candidatures.detail.contact.masque),
        findsOneWidget,
      );
      expect(
        find.text(t.admin.candidatures.detail.contact.journal),
        findsOneWidget,
      );
      expect(port.appelsContact, isEmpty);
      expect(find.text('amina.diallo@exemple.org'), findsNothing);
    });

    testWidgets('« Voir le contact » lit une fois, dans la feuille', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port();
      await _monter(tester, port);
      await _tapper(tester, find.byKey(BlocContact.cleVoir));
      expect(port.appelsContact, <String>['c1']);
      expect(find.text('amina.diallo@exemple.org'), findsOneWidget);
      // Un telephone sans indicatif connu est marque, jamais complete.
      expect(find.text('0771234567'), findsOneWidget);
      expect(
        find.text(t.admin.candidatures.detail.contact.aConfirmer),
        findsOneWidget,
      );
      await tester.tap(find.text(t.commun.fermer));
      await laisser(tester);
      expect(find.text('amina.diallo@exemple.org'), findsNothing);
      expect(port.appelsContact, hasLength(1));
    });

    testWidgets('sans la capacite : ni lien, ni phrase du journal', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(
          capacites: CapacitesCandidatures(
            peutLire: true,
            genreLecteurConnu: true,
            peutDecider: true,
            gestes: capacitesGestes.gestes,
            listes: capacitesGestes.listes,
          ),
        ),
      );
      await _ouvrir(tester, RubriqueDossierCode.contact);
      expect(find.byKey(BlocContact.cleVoir), findsNothing);
      expect(
        find.text(t.admin.candidatures.detail.contact.journal),
        findsNothing,
      );
      expect(
        find.text(t.admin.candidatures.detail.contact.masque),
        findsOneWidget,
      );
    });

    testWidgets('refuse : la feuille le dit, sans « Reessayer »', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port()
        ..erreurContact = const PermissionInsuffisante('contact');
      await _monter(tester, port);
      await _tapper(tester, find.byKey(BlocContact.cleVoir));
      expect(find.text(t.admin.candidatures.accesRefuse), findsOneWidget);
    });
  });

  group('etats', () {
    testWidgets('chargement : un squelette, pas de fausse donnee', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port()
        ..attenteLire = Completer<void>();
      await monterCandidature(tester, port: port);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Skeleton), findsOneWidget);
      expect(find.text('Amina Diallo'), findsNothing);
      expect(find.byKey(BlocProchaineAction.cle), findsNothing);
      port.attenteLire!.complete();
      await laisser(tester);
      expect(find.text('Amina Diallo'), findsWidgets);
    });

    testWidgets('erreur : la phrase et « Reessayer », qui relit', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port(
        erreurLire: (int appel) => appel == 1 ? StateError('panne') : null,
      );
      await _monter(tester, port);
      expect(
        find.text(t.admin.candidatures.detail.titreLecture),
        findsOneWidget,
      );
      await tester.tap(find.text(t.commun.reessayer));
      await laisser(tester);
      expect(find.text('Amina Diallo'), findsWidgets);
      expect(port.appelsLire, hasLength(2));
    });

    testWidgets('hors ligne, rien de lu : le bloc dit ce qui manque', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(erreurLire: (int _) => StateError('panne')),
        horsLigne: true,
      );
      expect(find.byType(EtatSansDonnees), findsOneWidget);
      expect(
        find.text(t.admin.candidatures.detail.sansDonnees),
        findsOneWidget,
      );
      expect(_toutLeTexte(tester).toLowerCase(), isNot(contains('hors ligne')));
    });

    testWidgets('hors ligne : la lecture reste, aucun geste, une note', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port(), horsLigne: true);
      expect(find.text('Amina Diallo'), findsWidgets);
      expect(_principal(), findsNothing);
      expect(find.byKey(BarreDecisionDossier.cleMenu), findsNothing);
      expect(find.byKey(BlocContact.cleVoir), findsNothing);
      expect(find.text(t.admin.candidatures.erreurs.horsLigne), findsOneWidget);
      expect(_pleins(), 0);
    });

    testWidgets(
      'capacite indisponible : « Disponible au branchement serveur »',
      (WidgetTester tester) async {
        await _monter(tester, const CandidaturesDirectionIndisponible());
        expect(_cle('candidature-indisponible'), findsOneWidget);
        expect(find.text(_branchement), findsOneWidget);
        expect(_toutLeTexte(tester), isNot(contains('CAND-BR')));
      },
    );

    testWidgets('sans port : la meme capacite indisponible', (
      WidgetTester tester,
    ) async {
      await _monter(tester, null);
      expect(_cle('candidature-indisponible'), findsOneWidget);
    });

    testWidgets(
      'hors portee et absente : deux textes, jamais l\'un pour l\'autre',
      (WidgetTester tester) async {
        await _monter(
          tester,
          _port(erreurLire: (int _) => const CandidatureHorsPortee()),
        );
        expect(
          find.text(t.admin.candidatures.detail.titreHorsPortee),
          findsOneWidget,
        );
        expect(
          find.text(t.admin.candidatures.detail.titreAbsente),
          findsNothing,
        );
        // La page dit quoi faire : revenir a la file.
        expect(
          find.text(t.admin.candidatures.detail.revenirALaFile),
          findsOneWidget,
        );
        expect(find.text('Amina Diallo'), findsNothing);

        await _monter(
          tester,
          _port(erreurLire: (int _) => const CandidatureIntrouvable()),
        );
        expect(
          find.text(t.admin.candidatures.detail.titreAbsente),
          findsOneWidget,
        );
        expect(
          find.text(t.admin.candidatures.detail.titreHorsPortee),
          findsNothing,
        );
      },
    );

    testWidgets('acces refuse et genre du lecteur inconnu', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(erreurLire: (int _) => const PermissionInsuffisante('lire')),
      );
      expect(find.text(t.admin.candidatures.accesRefuse), findsOneWidget);
      await _monter(
        tester,
        _port(erreurLire: (int _) => const GenreLecteurInconnu()),
      );
      expect(find.text(t.admin.candidatures.genreInconnu), findsOneWidget);
    });

    testWidgets('adresse tapee, sans identifiant : la reference est resolue', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port();
      await _monter(tester, port, identifiant: null);
      expect(find.text('Amina Diallo'), findsWidgets);
      // La file a retrouve l'identifiant par la reference exacte.
      expect(port.appels.single.filtre.recherche, referenceTest);
      expect(port.appelsLire, <String>['c1']);
    });

    testWidgets('reference inconnue : absente, sans lecture du dossier', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port();
      await monterCandidature(
        tester,
        ouvrirRubriques: false,
        port: port,
        reference: 'CAND-99999',
        identifiant: null,
      );
      expect(
        find.text(t.admin.candidatures.detail.titreAbsente),
        findsOneWidget,
      );
      expect(port.appelsLire, isEmpty);
    });
  });

  group('la prochaine action et le menu', () {
    /// Les entrees du menu ouvert, dans l'ordre ou elles s'affichent.
    Future<List<String>> menu(WidgetTester tester) async {
      await _tapper(tester, find.byKey(BarreDecisionDossier.cleMenu));
      return <String>[
        for (final Element e
            in find
                .descendant(
                  of: find.byType(PopupMenuItem<int>),
                  matching: find.byType(Text),
                )
                .evaluate())
          (e.widget as Text).data!,
      ];
    }

    testWidgets('en examen, versement a verifier : confirmer le moyen', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port());
      // BE-DOSSIER : « Confirmer le moyen » est a cote du versement, replie ;
      // « Ecarter » aussi ; la barre garde les trois decisions.
      final Finder bouton = _principal();
      expect(bouton, findsOneWidget);
      expect(
        find.descendant(
          of: bouton,
          matching: find.text(t.admin.candidatures.gestes.confirmerMoyen),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('rubrique-geste-infirmerMoyenPaiement'),
        ),
        findsOneWidget,
      );
      verifierUnSeulBoutonPlein(tester);
      final List<String> autres = await menu(tester);
      expect(autres, <String>[
        t.admin.candidatures.gestes.mettreEnPause,
        t.admin.candidatures.gestes.retrait,
      ]);
    });

    testWidgets('versement confirme : admettre en Salle de verification', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port(detail: _compatible()));
      expect(
        find.descendant(
          of: _principal(),
          // SALLE2-FICHE : « Accepter », avec « Demander une precision » et
          // « Refuser » visibles a cote, hors du menu.
          matching: find.text(t.admin.candidatures.decision.accepter),
        ),
        findsOneWidget,
      );
      // Demander une precision : dans la barre et a cote de chaque groupe.
      expect(
        find.byKey(
          BarreDecisionDossier.cleBouton(GesteCandidature.demanderComplement),
        ),
        findsOneWidget,
      );
      expect(find.text(t.admin.candidatures.decision.refuser), findsOneWidget);
      final List<String> autres = await menu(tester);
      expect(
        autres,
        isNot(contains(t.admin.candidatures.gestes.confirmerMoyen)),
      );
      expect(autres, isNot(contains(t.admin.candidatures.gestes.refuser)));
      // Ecarter le moyen est a cote du versement, plus dans le menu.
      expect(autres, isNot(contains(t.admin.candidatures.gestes.ecarterMoyen)));
      expect(
        find.byKey(
          const ValueKey<String>('rubrique-geste-infirmerMoyenPaiement'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('en pause : lever la pause, et aucune autre mise en pause', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port(detail: detailTest(enPause: true)));
      expect(
        find.descendant(
          of: _principal(),
          matching: find.text(t.admin.candidatures.gestes.leverPause),
        ),
        findsOneWidget,
      );
      final List<String> autres = await menu(tester);
      expect(
        autres,
        isNot(contains(t.admin.candidatures.gestes.mettreEnPause)),
      );
      // Refuser reste dans la barre, a cote de lever la pause.
      expect(
        find.byKey(BarreDecisionDossier.cleBouton(GesteCandidature.refuser)),
        findsOneWidget,
      );
    });

    testWidgets('a completer : en attente de la personne, aucun bouton plein', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(detail: detailTest(etat: EtatCandidature.aCompleter)),
      );
      expect(_principal(), findsNothing);
      expect(
        find.text(t.admin.candidatures.detail.enAttentePersonne),
        findsOneWidget,
      );
      // Accepter est grise, avec sa raison ; aucun bouton plein.
      expect(_pleins(), 0);
      expect(
        find.byKey(
          BarreDecisionDossier.cleRaison(
            GesteCandidature.admettreVerifications,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('refusee : fermee, rouvrir est dans le menu', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(
          detail: detailTest(
            issue: IssueCandidature.refusee,
            refusModele: 'refus_niveau',
          ),
        ),
      );
      expect(find.text(t.admin.candidatures.detail.fermee), findsOneWidget);
      expect(_principal(), findsNothing);
      await _ouvrir(tester, RubriqueDossierCode.historique);
      expect(
        _toutLeTexte(tester),
        contains(t.admin.candidatures.modeles.refusNiveau),
      );
      final List<String> autres = await menu(tester);
      expect(autres, <String>[t.admin.candidatures.gestes.rouvrir]);
    });

    testWidgets('en Salle de verification : complement, clore, retrait...', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(
          detail: detailTest(
            etape: EtapeCandidature.verifications,
            etat: EtatCandidature.entretienAPlanifier,
            paiement: EtatVersement.compatible,
          ),
        ),
      );
      // Aucune prochaine action ouverte par le serveur (l'entretien est L4).
      expect(_principal(), findsNothing);
      final List<String> autres = await menu(tester);
      expect(autres, <String>[
        t.admin.candidatures.gestes.cloreComplement,
        t.admin.candidatures.gestes.mettreEnPause,
        t.admin.candidatures.gestes.retrait,
      ]);
    });

    testWidgets('sans le droit de decider : aucun geste n\'est propose', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port(capacites: capacitesQuiLit));
      expect(_principal(), findsNothing);
      expect(find.byKey(BarreDecisionDossier.cleMenu), findsNothing);
      expect(_pleins(), 0);
    });

    testWidgets('un geste que le serveur n\'ouvre pas n\'est pas propose', (
      WidgetTester tester,
    ) async {
      final Map<String, bool> gestes = <String, bool>{
        ...capacitesGestes.gestes,
        'refuser': false,
        'confirmerMoyenPaiement': false,
      };
      await _monter(
        tester,
        _port(
          capacites: CapacitesCandidatures(
            peutLire: true,
            genreLecteurConnu: true,
            peutDecider: true,
            gestes: gestes,
            listes: capacitesGestes.listes,
          ),
        ),
      );
      // Refuser n'est pas propose : le bouton n'est pas rendu (K-56).
      expect(
        find.byKey(BarreDecisionDossier.cleBouton(GesteCandidature.refuser)),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('rubrique-geste-confirmerMoyenPaiement'),
        ),
        findsNothing,
      );
      final List<String> autres = await menu(tester);
      expect(autres, contains(t.admin.candidatures.gestes.mettreEnPause));
    });
  });

  group('feuilles : ce que chaque geste exige', () {
    testWidgets(
      'confirmer un moyen : le moyen se choisit, puis le geste part',
      (WidgetTester tester) async {
        final FauxCandidaturesDirection port = _port(
          effet: (DemandeGeste d, DetailCandidature a) =>
              _apres(a, paiement: EtatVersement.compatible),
        );
        await _monter(tester, port);
        await _agirPrincipal(tester);
        expect(find.byKey(FeuilleGeste.cle), findsOneWidget);
        // La consequence se lit avant le choix.
        expect(
          find.text(t.admin.candidatures.consequences.confirmerMoyen),
          findsWidgets,
        );
        // Les moyens declares, nommes.
        expect(find.text(t.admin.candidatures.moyens.virement), findsOneWidget);
        expect(
          find.text(t.admin.candidatures.moyens.mobile(nom: 'Orange Money')),
          findsOneWidget,
        );
        // Un bouton plein pour la feuille.
        expect(_pleins(find.byKey(FeuilleGeste.cle)), 1);

        // Sans choix : rien ne part, le champ le dit.
        await _valider(tester);
        expect(port.appelsGeste, isEmpty);
        expect(find.text(t.admin.candidatures.moyens.manquant), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('moyen-mobile:orange_money')),
        );
        await laisser(tester);
        await _valider(tester);
        final DemandeGeste d = port.appelsGeste.single.demande;
        expect(d.geste, GesteCandidature.confirmerMoyenPaiement);
        expect(d.moyen, const MoyenVersement.mobile('orange_money'));
        expect(d.candidatureId, 'c1');
        // La version lue avec le dossier, et une cle d'idempotence.
        expect(d.versionAttendue, 3);
        expect(d.cleIdempotence, isNotEmpty);
        // La feuille est fermee, la candidature relue, le retour dit apres.
        expect(find.byKey(FeuilleGeste.cle), findsNothing);
        expect(port.appelsLire, hasLength(2));
        expect(
          find.text(t.admin.candidatures.retours.confirmerMoyen),
          findsOneWidget,
        );
        // Le versement relu est confirme : la prochaine action change.
        expect(
          find.descendant(
            of: _principal(),
            matching: find.text(t.admin.candidatures.decision.accepter),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('aucun moyen declare : la feuille le dit, sans bouton', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(
          detail: detailTest(
            documents: <DocumentReponses>[
              const DocumentReponses(
                questionnaireVersion: 'salle-examen-1',
                reponses: <String, Object?>{
                  'paysVersement': 'SN',
                  'compteBancaire': false,
                  'operateurs': <String>[],
                },
                importe: false,
              ),
            ],
          ),
        ),
      );
      await _agirPrincipal(tester);
      expect(
        find.text(t.admin.candidatures.moyens.aucunDeclare),
        findsOneWidget,
      );
      expect(find.byKey(FeuilleGeste.cleValider), findsNothing);
      expect(_pleins(find.byKey(FeuilleGeste.cle)), 0);
    });

    testWidgets('ecarter un moyen : le moyen et un motif', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port();
      await _monter(tester, port);
      await _geste(tester, GesteCandidature.infirmerMoyenPaiement);
      await _valider(tester);
      expect(port.appelsGeste, isEmpty);
      expect(find.text(t.admin.candidatures.moyens.manquant), findsOneWidget);
      expect(
        find.text(t.admin.candidatures.feuille.motifManquant),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey<String>('moyen-virement')));
      await laisser(tester);
      await _saisirMotif(tester, '  Compte clos.  ');
      await _valider(tester);
      final DemandeGeste d = port.appelsGeste.single.demande;
      expect(d.geste, GesteCandidature.infirmerMoyenPaiement);
      expect(d.moyen, const MoyenVersement.virement());
      expect(d.motif, 'Compte clos.');
    });

    testWidgets('refuser : motif et message, nommes quand ils manquent', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port(
        effet: (DemandeGeste d, DetailCandidature a) =>
            _apres(a, issue: IssueCandidature.refusee),
      );
      await _monter(tester, port);
      await _geste(tester, GesteCandidature.refuser);
      // Les quatre messages du serveur, nommes ; le motif interne n'est pas
      // ce que la personne lit.
      for (final String nom in <String>[
        t.admin.candidatures.modeles.refusGeneral,
        t.admin.candidatures.modeles.refusNiveau,
        t.admin.candidatures.modeles.refusBesoins,
        t.admin.candidatures.modeles.refusSansReponse,
      ]) {
        expect(find.text(nom), findsOneWidget);
      }
      expect(find.text(t.admin.candidatures.feuille.modeleLu), findsOneWidget);
      expect(find.text(t.admin.candidatures.feuille.motifAide), findsOneWidget);

      await _valider(tester);
      expect(port.appelsGeste, isEmpty);
      expect(
        find.text(t.admin.candidatures.feuille.motifManquant),
        findsOneWidget,
      );
      expect(
        find.text(t.admin.candidatures.feuille.modeleManquant),
        findsOneWidget,
      );

      await _saisirMotif(tester, '  Niveau insuffisant.  ');
      await tester.tap(
        find.byKey(const ValueKey<String>('modele-refus_niveau')),
      );
      await laisser(tester);
      await _valider(tester);
      final DemandeGeste d = port.appelsGeste.single.demande;
      expect(d.geste, GesteCandidature.refuser);
      expect(d.motif, 'Niveau insuffisant.');
      expect(d.modele, 'refus_niveau');
      expect(d.versionAttendue, 3);
      // Le motif interne n'est jamais dans ce que la personne lira.
      expect(find.byKey(FeuilleGeste.cle), findsNothing);
      expect(find.text(t.admin.candidatures.retours.refuser), findsOneWidget);
      // Relue : fermee, rouvrir seulement.
      expect(find.text(t.admin.candidatures.detail.fermee), findsOneWidget);
    });

    testWidgets('demander un complement : les elements se choisissent', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port();
      await _monter(tester, port);
      await _geste(tester, GesteCandidature.demanderComplement);
      // La liste fermee de la Salle d'examen, par ses libelles.
      expect(
        find.text(t.recrutement.questionnaire.disponibilites),
        findsOneWidget,
      );
      expect(find.text(t.recrutement.portail.elementCadre), findsOneWidget);
      // COMPLEMENT-ET-FORMATS : en salle 1, tout ce que le candidat fournit,
      // en deux groupes dans l'ordre de son parcours, sur une seule colonne.
      expect(find.byKey(FeuilleGeste.cleGroupeReponses), findsOneWidget);
      expect(find.byKey(FeuilleGeste.cleGroupeDocuments), findsOneWidget);
      final List<String> documents = <String>[
        'cadre_religieux',
        'contrat',
        'avis',
        'code_conduite',
        'piece_identite',
        'photo',
        'accord_publication',
      ];
      for (final String code in documents) {
        expect(find.byKey(ValueKey<String>('element-$code')), findsOneWidget);
      }
      expect(find.text(t.admin.candidatures.complement.piece), findsOneWidget);
      expect(
        find.text(t.admin.candidatures.complement.accordPublication),
        findsOneWidget,
      );
      // Les reponses d'abord, puis les documents, dans l'ordre du parcours.
      double haut(String code) =>
          tester.getTopLeft(find.byKey(ValueKey<String>('element-$code'))).dy;
      expect(
        tester.getTopLeft(find.byKey(FeuilleGeste.cleGroupeReponses)).dy,
        lessThan(haut('langues')),
      );
      expect(
        haut('versement'),
        lessThan(
          tester.getTopLeft(find.byKey(FeuilleGeste.cleGroupeDocuments)).dy,
        ),
      );
      for (int i = 1; i < documents.length; i++) {
        expect(haut(documents[i - 1]), lessThan(haut(documents[i])));
      }
      expect(find.text(t.admin.candidatures.complement.aide), findsOneWidget);

      // Aucun texte libre : la liste nommee des elements EST le motif.
      expect(find.byKey(FeuilleGeste.cleMotif), findsNothing);
      await _valider(tester);
      expect(port.appelsGeste, isEmpty);
      expect(
        find.text(t.admin.candidatures.complement.manquant),
        findsOneWidget,
      );
      expect(
        find.text(t.admin.candidatures.feuille.motifManquant),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey<String>('element-versement')));
      await laisser(tester);
      await tester.tap(find.byKey(const ValueKey<String>('element-langues')));
      await laisser(tester);
      await _valider(tester);
      final DemandeGeste d = port.appelsGeste.single.demande;
      expect(d.geste, GesteCandidature.demanderComplement);
      // Les elements choisis, dans l'ordre de la liste du serveur, rien d'autre.
      expect(d.elements, <String>['langues', 'versement']);
      // Le serveur exige un motif non vide : il part, deduit de la liste.
      expect(
        d.motif,
        '${t.recrutement.questionnaire.langues}, '
        '${t.recrutement.questionnaire.versement}',
      );
    });

    testWidgets('en Salle de verification, la liste est celle de cette salle', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(
          detail: detailTest(
            etape: EtapeCandidature.verifications,
            etat: EtatCandidature.entretienAPlanifier,
          ),
        ),
      );
      await _geste(tester, GesteCandidature.demanderComplement);
      expect(find.text(t.admin.candidatures.complement.piece), findsOneWidget);
      expect(find.text(t.recrutement.portail.elementContrat), findsOneWidget);
      // COMPLEMENT-ET-FORMATS : la salle 2 ne change pas.
      expect(find.byKey(FeuilleGeste.cleGroupeReponses), findsNothing);
      expect(find.byKey(const ValueKey<String>('element-photo')), findsNothing);
      expect(find.text(t.recrutement.questionnaire.langues), findsNothing);
    });

    testWidgets('clore le complement : un motif, le seul code de cloture', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port(
        detail: detailTest(
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.entretienAPlanifier,
        ),
      );
      await _monter(tester, port);
      await _geste(tester, GesteCandidature.cloreComplement);
      await _valider(tester);
      expect(port.appelsGeste, isEmpty);
      expect(
        find.text(t.admin.candidatures.feuille.motifManquant),
        findsOneWidget,
      );
      await _saisirMotif(tester, 'Piece recue par la conversation.');
      await _valider(tester);
      final DemandeGeste d = port.appelsGeste.single.demande;
      expect(d.geste, GesteCandidature.cloreComplement);
      expect(d.elements, <String>['complement_clos']);
      expect(d.motif, 'Piece recue par la conversation.');
      expect(
        find.text(t.admin.candidatures.retours.cloreComplement),
        findsOneWidget,
      );
    });

    testWidgets(
      'mettre en pause : un message, un motif, une reprise facultative',
      (WidgetTester tester) async {
        final FauxCandidaturesDirection port = _port(
          effet: (DemandeGeste d, DetailCandidature a) =>
              _apres(a, enPause: true),
        );
        await _monter(tester, port);
        await _geste(tester, GesteCandidature.mettreEnPause);
        expect(find.text(t.admin.candidatures.pause.reprise), findsOneWidget);
        await _valider(tester);
        expect(port.appelsGeste, isEmpty);
        await tester.tap(
          find.byKey(const ValueKey<String>('modele-pause_attente_besoin')),
        );
        await laisser(tester);
        await _saisirMotif(tester, 'Pas de classe a pourvoir.');
        await _valider(tester);
        final DemandeGeste d = port.appelsGeste.single.demande;
        expect(d.geste, GesteCandidature.mettreEnPause);
        expect(d.modele, 'pause_attente_besoin');
        expect(d.repriseLe, isNull);
        expect(
          find.text(t.admin.candidatures.retours.mettreEnPause),
          findsOneWidget,
        );
        // Relue : en pause, la prochaine action est de la lever.
        expect(
          find.descendant(
            of: _principal(),
            matching: find.text(t.admin.candidatures.gestes.leverPause),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'la reprise d\'une pause se choisit dans un calendrier, a venir',
      (WidgetTester tester) async {
        final FauxCandidaturesDirection port = _port();
        await _monter(tester, port);
        await _geste(tester, GesteCandidature.mettreEnPause);
        await tester.tap(find.byKey(const ValueKey<String>('champ-date')));
        await laisser(tester);
        // Le premier jour permis est demain : aujourd'hui (22) est grise.
        await tester.tap(find.text('25'));
        await laisser(tester, fois: 2);
        await tester.tap(find.text('OK'));
        await laisser(tester);
        expect(
          find.text(t.admin.candidatures.pause.effacerReprise),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('modele-pause_general')),
        );
        await laisser(tester);
        await _saisirMotif(tester, 'A la demande de la personne.');
        await _valider(tester);
        final DemandeGeste d = port.appelsGeste.single.demande;
        expect(d.repriseLe, DateTime(2026, 10, 25));
      },
    );

    testWidgets('lever la pause : une confirmation, sans motif', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port(
        detail: detailTest(enPause: true),
        effet: (DemandeGeste d, DetailCandidature a) =>
            _apres(a, enPause: false),
      );
      await _monter(tester, port);
      await _agirPrincipal(tester);
      expect(find.byKey(FeuilleGeste.cleMotif), findsNothing);
      await _valider(tester);
      final DemandeGeste d = port.appelsGeste.single.demande;
      expect(d.geste, GesteCandidature.leverPause);
      expect(d.motif, isNull);
      expect(
        find.text(t.admin.candidatures.retours.leverPause),
        findsOneWidget,
      );
    });

    testWidgets('admettre : une confirmation, qui dit ce qui arrive', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port(
        detail: _compatible(),
        effet: (DemandeGeste d, DetailCandidature a) => _apres(
          a,
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.entretienAPlanifier,
        ),
      );
      await _monter(tester, port);
      await _agirPrincipal(tester);
      expect(
        find.text(t.admin.candidatures.consequences.admettre),
        findsWidgets,
      );
      await _valider(tester);
      expect(
        port.appelsGeste.single.demande.geste,
        GesteCandidature.admettreVerifications,
      );
      expect(find.text(t.admin.candidatures.retours.admettre), findsOneWidget);
      // Relue : en Salle de verification et d'entretien.
      expect(_toutLeTexte(tester), contains(t.recrutement.salles.verification));
    });

    testWidgets('retrait : canal, jour de la demande et motif', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port();
      await _monter(tester, port);
      await _geste(tester, GesteCandidature.consignerRetrait);
      expect(
        find.text(t.admin.candidatures.retrait.canaux.conversation),
        findsOneWidget,
      );
      expect(
        find.text(t.admin.candidatures.retrait.canaux.courriel),
        findsOneWidget,
      );
      await _valider(tester);
      expect(port.appelsGeste, isEmpty);
      expect(
        find.text(t.admin.candidatures.retrait.canalManquant),
        findsOneWidget,
      );
      expect(
        find.text(t.admin.candidatures.retrait.dateManquante),
        findsOneWidget,
      );
      expect(
        find.text(t.admin.candidatures.feuille.motifManquant),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('canal-courriel')));
      await laisser(tester);
      await tester.tap(find.byKey(const ValueKey<String>('champ-date')));
      await laisser(tester);
      // Entre la reception (1er octobre) et aujourd'hui (22).
      await tester.tap(find.text('20'));
      await laisser(tester, fois: 2);
      await tester.tap(find.text('OK'));
      await laisser(tester);
      await _saisirMotif(tester, 'Demande recue par courriel.');
      await _valider(tester);
      final DemandeGeste d = port.appelsGeste.single.demande;
      expect(d.geste, GesteCandidature.consignerRetrait);
      expect(d.canal, CanalRetrait.courriel);
      expect(d.demandeRecueLe, DateTime(2026, 10, 20));
    });

    Future<void> monterTard(WidgetTester tester, GesteCandidature geste) async {
      // 22/10 a 23 h 30 UTC : le jour du serveur est le 22, quelle que soit la
      // zone de l'appareil (jour local et jour UTC different quelques heures
      // par jour). Recue le 1er a 23 h 30 UTC : le jour de reception est le 1er.
      await monterCandidature(
        tester,
        ouvrirRubriques: false,
        port: _port(
          detail: detailTest(recueLe: DateTime.utc(2026, 10, 1, 23, 30)),
        ),
        maintenant: DateTime.utc(2026, 10, 22, 23, 30),
      );
      await _geste(tester, geste);
    }

    testWidgets('la reprise d\'une pause se compte en jour UTC, comme le '
        'serveur', (WidgetTester tester) async {
      await monterTard(tester, GesteCandidature.mettreEnPause);
      // La premiere reprise permise : demain, en jour UTC (le 23).
      expect(
        tester.widget<ChampDate>(find.byType(ChampDate)).aujourdhui,
        DateTime(2026, 10, 23),
      );
    });

    testWidgets('le jour d\'une demande de retrait se compte en jour UTC', (
      WidgetTester tester,
    ) async {
      await monterTard(tester, GesteCandidature.consignerRetrait);
      final ChampDate jour = tester.widget<ChampDate>(find.byType(ChampDate));
      // Du jour de la reception au jour du serveur, jamais au-dela.
      expect(jour.aujourdhui, DateTime(2026, 10, 1));
      expect(jour.dernier, DateTime(2026, 10, 22));
    });

    testWidgets('rouvrir : un motif', (WidgetTester tester) async {
      final FauxCandidaturesDirection port = _port(
        detail: detailTest(issue: IssueCandidature.retiree),
        effet: (DemandeGeste d, DetailCandidature a) =>
            _apres(a, issue: IssueCandidature.enCours),
      );
      await _monter(tester, port);
      await _geste(tester, GesteCandidature.rouvrir);
      await _valider(tester);
      expect(port.appelsGeste, isEmpty);
      await _saisirMotif(tester, 'Erreur de saisie.');
      await _valider(tester);
      expect(port.appelsGeste.single.demande.geste, GesteCandidature.rouvrir);
      expect(find.text(t.admin.candidatures.retours.rouvrir), findsOneWidget);
      expect(find.text(t.admin.candidatures.detail.fermee), findsNothing);
    });

    testWidgets('responsable : choisi dans la liste du serveur, ou personne', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port(
        responsables: const <ResponsablePossible>[
          ResponsablePossible(id: 'r1', nom: 'Salma Idrissi'),
          ResponsablePossible(id: 'r2', nom: 'Leila Benkacem'),
        ],
      );
      await _monter(tester, port);
      await _geste(tester, GesteCandidature.definirResponsable);
      expect(find.text('Salma Idrissi'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(FeuilleGeste.cle),
          matching: find.text(t.admin.candidatures.responsables.aucun),
        ),
        findsOneWidget,
      );
      await _valider(tester);
      expect(port.appelsGeste, isEmpty);
      await tester.tap(find.byKey(const ValueKey<String>('responsable-r2')));
      await laisser(tester);
      await _valider(tester);
      final DemandeGeste d = port.appelsGeste.single.demande;
      expect(d.geste, GesteCandidature.definirResponsable);
      expect(d.responsableId, 'r2');
    });

    testWidgets('responsable : liste non servie, la feuille le dit seule', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port(responsablesIndisponibles: true));
      await _geste(tester, GesteCandidature.definirResponsable);
      expect(find.text(_branchement), findsWidgets);
      expect(find.byKey(FeuilleGeste.cleValider), findsNothing);
      expect(find.byKey(FeuilleGeste.cleAnnuler), findsOneWidget);
    });

    testWidgets(
      'une liste fermee non servie : la feuille le dit, sans bouton',
      (WidgetTester tester) async {
        await _monter(
          tester,
          _port(
            capacites: CapacitesCandidatures(
              peutLire: true,
              genreLecteurConnu: true,
              peutDecider: true,
              gestes: capacitesGestes.gestes,
            ),
          ),
        );
        await _geste(tester, GesteCandidature.refuser);
        expect(find.text(_branchement), findsWidgets);
        expect(find.byKey(FeuilleGeste.cleValider), findsNothing);
      },
    );

    testWidgets('annuler ferme la feuille sans rien envoyer', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port();
      await _monter(tester, port);
      await _geste(tester, GesteCandidature.refuser);
      await _saisirMotif(tester, 'Un motif.');
      await _tapper(tester, find.byKey(FeuilleGeste.cleAnnuler));
      expect(find.byKey(FeuilleGeste.cle), findsNothing);
      expect(port.appelsGeste, isEmpty);
      expect(port.appelsLire, hasLength(1));
    });

    testWidgets('la feuille n\'a qu\'un bouton plein (ou une action douce)', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port());
      await _geste(tester, GesteCandidature.demanderComplement);
      // Le geste motive : un bouton principal, « Annuler » secondaire.
      final Finder valider = find.byKey(FeuilleGeste.cleValider);
      expect(valider, findsOneWidget);
      expect(
        tester.widget<ActionPrincipale>(valider).niveau,
        NiveauAction.principale,
      );
      expect(
        tester
            .widget<ActionPrincipale>(find.byKey(FeuilleGeste.cleAnnuler))
            .niveau,
        NiveauAction.secondaire,
      );
    });

    testWidgets('un geste destructif n\'est jamais un bouton plein', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port());
      await _geste(tester, GesteCandidature.refuser);
      expect(
        tester
            .widget<ActionPrincipale>(find.byKey(FeuilleGeste.cleValider))
            .niveau,
        NiveauAction.destructive,
      );
    });
  });

  group('refus nommes du serveur', () {
    Future<void> faireRefuser(
      WidgetTester tester,
      Object refus, {
      DetailCandidature? detail,
    }) async {
      final FauxCandidaturesDirection port = _port(
        detail: detail ?? _compatible(),
        erreurGeste: (DemandeGeste _, int _) => refus,
      );
      await _monter(tester, port);
      await _agirPrincipal(tester);
      await _valider(tester);
    }

    testWidgets(
      'controles non satisfaits : chaque controle nomme, avec sa cause',
      (WidgetTester tester) async {
        await faireRefuser(
          tester,
          const ControlesNonSatisfaits(<({String nom, String? cause})>[
            (nom: 'cadre_religieux', cause: 'non_accepte'),
            (nom: 'questionnaire_complet', cause: 'perime'),
          ]),
        );
        final Finder bandeau = find.byKey(FeuilleGeste.cleRefus);
        expect(bandeau, findsOneWidget);
        final String texte = _toutLeTexte(tester);
        expect(texte, contains(t.admin.candidatures.erreurs.titre));
        expect(
          texte,
          contains(
            t.admin.candidatures.erreurs.controles(
              controles: <String>[
                t.admin.candidatures.detail.controleLigne(
                  nom: t.admin.candidatures.controles.noms.cadreReligieux,
                  cause: t.admin.candidatures.controles.causes.nonAccepte,
                ),
                t.admin.candidatures.detail.controleLigne(
                  nom: t.admin.candidatures.controles.noms.questionnaireComplet,
                  cause: t.admin.candidatures.controles.causes.perime,
                ),
              ].join(t.admin.candidatures.detail.separateurControles),
            ),
          ),
        );
        // Aucun code, la feuille reste ouverte, le geste peut etre refait.
        expect(texte, isNot(contains('cadre_religieux')));
        expect(texte, isNot(contains('non_accepte')));
        expect(find.byKey(FeuilleGeste.cle), findsOneWidget);
        expect(find.byKey(FeuilleGeste.cleValider), findsOneWidget);
      },
    );

    testWidgets('transition interdite : l\'etat courant par son libelle', (
      WidgetTester tester,
    ) async {
      await faireRefuser(
        tester,
        const GesteInterdit(
          etape: EtapeCandidature.prequalification,
          etat: EtatCandidature.aCompleter,
        ),
      );
      expect(
        _toutLeTexte(tester),
        contains(
          t.admin.candidatures.erreurs.transition(
            etat: t.admin.candidatures.etats.aCompleter,
          ),
        ),
      );
      expect(_toutLeTexte(tester), isNot(contains('a_completer')));
      // Plus de bouton qui puisse aboutir : seulement relire.
      expect(find.byKey(FeuilleGeste.cleValider), findsNothing);
      expect(find.byKey(FeuilleGeste.cleRelire), findsOneWidget);
      expect(_pleins(find.byKey(FeuilleGeste.cle)), 1);
    });

    testWidgets('transition interdite par une pause : « En pause »', (
      WidgetTester tester,
    ) async {
      await faireRefuser(
        tester,
        const GesteInterdit(
          etape: EtapeCandidature.prequalification,
          etat: EtatCandidature.enExamen,
          enPause: true,
          parLaPause: true,
        ),
      );
      expect(
        _toutLeTexte(tester),
        contains(
          t.admin.candidatures.erreurs.transition(
            etat: t.admin.candidatures.etats.enPause,
          ),
        ),
      );
    });

    testWidgets('conflit : relire, qui relit vraiment la candidature', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port(
        detail: _compatible(),
        erreurGeste: (DemandeGeste _, int _) => const ConflitGeste(7),
      );
      await _monter(tester, port);
      await _agirPrincipal(tester);
      await _valider(tester);
      expect(find.text(t.admin.candidatures.erreurs.conflit), findsOneWidget);
      expect(find.byKey(FeuilleGeste.cleValider), findsNothing);
      expect(port.appelsLire, hasLength(1));
      await _tapper(tester, find.byKey(FeuilleGeste.cleRelire));
      expect(find.byKey(FeuilleGeste.cle), findsNothing);
      expect(port.appelsLire, hasLength(2));
      // Rien n'a ete fait : aucun retour de succes.
      expect(find.text(t.admin.candidatures.retours.admettre), findsNothing);
    });

    testWidgets('aucun complement a clore : la feuille propose d\'actualiser', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port(
        detail: _compatible(),
        erreurGeste: (DemandeGeste _, int _) => const AucunComplement(),
      );
      await _monter(tester, port);
      await _agirPrincipal(tester);
      await _valider(tester);
      expect(
        find.text(t.admin.candidatures.erreurs.aucunComplement),
        findsOneWidget,
      );
      expect(find.byKey(FeuilleGeste.cleValider), findsNothing);
      expect(
        find.text(t.admin.candidatures.feuille.actualiser),
        findsOneWidget,
      );
      await _tapper(tester, find.byKey(FeuilleGeste.cleRelire));
      expect(find.byKey(FeuilleGeste.cle), findsNothing);
      expect(port.appelsLire, hasLength(2));
    });

    testWidgets(
      'une version perimee est refusee par le serveur, sans ecriture',
      (WidgetTester tester) async {
        // Entre l'ouverture et l'envoi, un autre onglet a change la candidature :
        // la version du double augmente, la page garde l'ancienne.
        final FauxCandidaturesDirection port = _port(detail: _compatible());
        await _monter(tester, port);
        port.details['c1'] = detailTest(
          paiement: EtatVersement.compatible,
          version: 9,
        );
        await _agirPrincipal(tester);
        await _valider(tester);
        expect(find.text(t.admin.candidatures.erreurs.conflit), findsOneWidget);
        expect(port.details['c1']!.version, 9);
      },
    );

    testWidgets(
      'un refus sans lien avec la feuille : sa phrase, rien d\'autre',
      (WidgetTester tester) async {
        for (final (RefusGeste refus, String phrase) in <(RefusGeste, String)>[
          (const MotifRequis(), t.admin.candidatures.erreurs.motifRequis),
          (const ModeleRequis(), t.admin.candidatures.erreurs.modeleRequis),
          (const ModeleInconnu(), t.admin.candidatures.erreurs.modeleInconnu),
          (
            const AucunComplement(),
            t.admin.candidatures.erreurs.aucunComplement,
          ),
          (
            const MoyenNonConfirmable(etatLigne: 'en_verification'),
            t.admin.candidatures.erreurs.moyenNonConfirmable,
          ),
          (
            const MoyenNonConfirmable(nonDeclare: true),
            t.admin.candidatures.erreurs.moyenNonDeclare,
          ),
          (
            const ResponsableInvalide(),
            t.admin.candidatures.erreurs.responsableInvalide,
          ),
          (const CleReutilisee(), t.admin.candidatures.erreurs.cleReutilisee),
          (
            const RepriseInvalide(),
            t.admin.candidatures.erreurs.repriseInvalide,
          ),
          (
            const DateDemandeInvalide(),
            t.admin.candidatures.erreurs.dateDemande,
          ),
        ]) {
          await faireRefuser(tester, refus);
          expect(find.text(phrase), findsOneWidget, reason: '$refus');
          final String texte = _toutLeTexte(tester);
          expect(texte, isNot(contains('en_verification')));
          expect(find.byKey(FeuilleGeste.cle), findsOneWidget);
        }
      },
    );
  });

  group('essai non confirme et cle d\'idempotence', () {
    testWidgets('reessayer rejoue la MEME cle, puis le geste est fait', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port(
        detail: _compatible(),
        erreurGeste: (DemandeGeste _, int essai) =>
            essai == 1 ? const GesteNonConfirme() : null,
        effet: (DemandeGeste d, DetailCandidature a) => _apres(
          a,
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.entretienAPlanifier,
        ),
      );
      await _monter(tester, port);
      await _agirPrincipal(tester);
      await _valider(tester);
      // Non confirme : on le dit comme tel, jamais « non envoye ».
      expect(
        find.text(t.admin.candidatures.erreurs.nonConfirmeTitre),
        findsOneWidget,
      );
      expect(
        find.text(t.admin.candidatures.erreurs.nonConfirme),
        findsOneWidget,
      );
      expect(find.text(t.commun.reessayer), findsOneWidget);
      expect(find.text(t.admin.candidatures.retours.admettre), findsNothing);
      await _valider(tester);
      expect(port.appelsGeste, hasLength(2));
      expect(
        port.appelsGeste[0].demande.cleIdempotence,
        port.appelsGeste[1].demande.cleIdempotence,
      );
      expect(find.byKey(FeuilleGeste.cle), findsNothing);
      expect(find.text(t.admin.candidatures.retours.admettre), findsOneWidget);
    });

    testWidgets('un champ change : c\'est une autre demande, une cle neuve', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port(
        detail: detailTest(issue: IssueCandidature.retiree),
        erreurGeste: (DemandeGeste _, int essai) =>
            essai == 1 ? const GesteNonConfirme() : null,
      );
      await _monter(tester, port);
      await _geste(tester, GesteCandidature.rouvrir);
      await _saisirMotif(tester, 'Premier motif.');
      await _valider(tester);
      expect(
        find.text(t.admin.candidatures.erreurs.nonConfirme),
        findsOneWidget,
      );
      await _saisirMotif(tester, 'Second motif.');
      // La demande a change : le non confirme ne la concerne plus.
      expect(find.text(t.admin.candidatures.erreurs.nonConfirme), findsNothing);
      await _valider(tester);
      expect(port.appelsGeste, hasLength(2));
      expect(
        port.appelsGeste[0].demande.cleIdempotence,
        isNot(port.appelsGeste[1].demande.cleIdempotence),
      );
      expect(port.appelsGeste[1].demande.motif, 'Second motif.');
    });

    testWidgets(
      'un refus nomme n\'a rien ecrit : l\'essai suivant a une cle neuve',
      (WidgetTester tester) async {
        final List<String> cles = <String>[];
        final FauxCandidaturesDirection port = _port(
          detail: _compatible(),
          erreurGeste: (DemandeGeste d, int _) {
            cles.add(d.cleIdempotence);
            return cles.length == 1 ? const ConflitGeste(3) : null;
          },
        );
        await _monter(tester, port);
        await _agirPrincipal(tester);
        await _valider(tester);
        await _tapper(tester, find.byKey(FeuilleGeste.cleRelire));
        await _agirPrincipal(tester);
        await _valider(tester);
        expect(cles, hasLength(2));
        expect(cles[0], isNot(cles[1]));
      },
    );

    testWidgets(
      'reponse perdue apres l\'ecriture : le rejeu le dit, rien n\'est ecrit deux fois',
      (WidgetTester tester) async {
        final FauxCandidaturesDirection port = _port(
          detail: _compatible(),
          erreurGeste: (DemandeGeste _, int essai) =>
              essai == 1 ? const GesteNonConfirme() : null,
          effet: (DemandeGeste d, DetailCandidature a) => _apres(
            a,
            etape: EtapeCandidature.verifications,
            etat: EtatCandidature.entretienAPlanifier,
          ),
        )..perteApresEcriture = true;
        await _monter(tester, port);
        await _agirPrincipal(tester);
        await _valider(tester);
        expect(
          find.text(t.admin.candidatures.erreurs.nonConfirme),
          findsOneWidget,
        );
        // La candidature est deja en Salle de verification (version 4) ; le
        // rejeu de la meme cle rend le premier resultat, sans conflit.
        await _valider(tester);
        expect(port.details['c1']!.version, 4);
        expect(find.text(t.admin.candidatures.retours.rejoue), findsOneWidget);
        expect(find.text(t.admin.candidatures.retours.admettre), findsNothing);
      },
    );

    testWidgets('une panne imprevue : phrase neutre, rien de confirme', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port(
        detail: _compatible(),
        erreurGeste: (DemandeGeste _, int _) => StateError('panne'),
      );
      await _monter(tester, port);
      await _agirPrincipal(tester);
      await _valider(tester);
      expect(find.text(t.admin.candidatures.erreurs.generique), findsOneWidget);
      expect(find.text(t.admin.candidatures.retours.admettre), findsNothing);
      expect(find.byKey(FeuilleGeste.cleValider), findsOneWidget);
    });

    testWidgets('une panne imprevue : l\'essai suivant rejoue la meme cle', (
      WidgetTester tester,
    ) async {
      // Le geste a pu partir (reponse 5xx, delai) : le rejeu, pas un second geste.
      final FauxCandidaturesDirection port = _port(
        detail: _compatible(),
        erreurGeste: (DemandeGeste _, int essai) =>
            essai == 1 ? StateError('panne') : null,
      );
      await _monter(tester, port);
      await _agirPrincipal(tester);
      await _valider(tester);
      await _valider(tester);
      expect(port.appelsGeste, hasLength(2));
      expect(
        port.appelsGeste[0].demande.cleIdempotence,
        port.appelsGeste[1].demande.cleIdempotence,
      );
    });

    testWidgets(
      'un geste interdit par la permission : dit sans « Reessayer »',
      (WidgetTester tester) async {
        final FauxCandidaturesDirection port = _port(
          detail: _compatible(),
          erreurGeste: (DemandeGeste _, int _) =>
              const PermissionInsuffisante('geste'),
        );
        await _monter(tester, port);
        await _agirPrincipal(tester);
        await _valider(tester);
        expect(
          find.text(t.admin.candidatures.erreurs.permission),
          findsOneWidget,
        );
      },
    );
  });
}

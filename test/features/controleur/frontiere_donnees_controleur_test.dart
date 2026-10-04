// CT-11 : revue frontiere des donnees visibles du controle (doc §17.14).
//
// Chaque ecran de la demonstration controleur est monte par la VRAIE route
// (`routesDemoControleur`), a 390 et a 1440 ; TOUT le texte rendu (Text,
// RichText, EditableText, Tooltip, et l'arbre semantique) est rassemble, puis
// confronte a la regle C8 (minimisation) et aux libelles interdits de C16 :
// - aucune adresse e-mail, aucun numero de telephone, aucune URL brute ;
// - aucun mot du paiement, du solde, des appareils, de la remuneration, des
//   exports et telechargements, du KYC, de l'adresse postale, de la note
//   administrative ou de la sanction ;
// - aucun libelle de surveillance (Inspection, Surveillance, Espion, Score,
//   Conforme) ;
// - aucun nom de famille d'eleve : les eleves de la demonstration n'ont
//   qu'un prenom, et aucun prenom n'est suivi d'un nom.
//
// Recette 32 (aucune donnee de demonstration en production) : les routes
// sont testees dans test/features/demo/demo_controleur_page_test.dart
// (`routesDemoControleur('production')` vide, porte fermee) ; ce fichier y
// ajoute les sous-adresses et les fournisseurs reels, neutres par defaut.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/features/compte/espaces_compte.dart';
import 'package:rewayah_academy/features/controleur/complement_rapport_page.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/echanges_controleur.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur_page.dart';
import 'package:rewayah_academy/features/controleur/mission_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';
import 'package:rewayah_academy/features/demo/espaces_controleur_demo.dart';
import 'package:rewayah_academy/features/demo/salle_controleur_demo.dart';

/// Les exceptions nommees : les ecrans ou elles valent (`*` pour tous), le
/// texte exact retire avant la verification, et la raison. Une ligne par
/// exception ; aucune n'est accordee en silence, et hors de ses ecrans le
/// meme texte reste une fuite.
final List<(List<String> ecrans, String texte, String raison)> _exceptions =
    <(List<String>, String, String)>[
      // « Se deconnecter : Mettre fin a la session sur cet appareil » (Compte,
      // tous les espaces) : « cet appareil » designe celui qu'on tient en
      // main ; aucun appareil n'est liste ni decrit.
      (<String>['*'], t.compte.deconnexionDetail, 'deconnexion locale'),
      // « Foyer : Les appareils et profils rattaches a votre foyer » : ligne
      // inerte du Compte de l'espace PRINCIPAL (Enseignant, Admin), hors
      // Controle ; elle parle du compte lui-meme, jamais d'un autre foyer.
      // En Controle, `afficheAppareils` la retire (C8, CT-9) : les ecrans
      // Controle de ce fichier le verifient, l'exception ne les couvre pas.
      (
        <String>[
          'lien-espaces-enseignant-principal',
          'lien-espaces-admin-principal',
        ],
        t.compte.appareilsDetail,
        'espace principal, hors Controle',
      ),
    ];

/// Les mots interdits (C8, C16), en mot entier, sans tenir compte de la
/// casse. « Note » seul est ambigu : seule « note administrative » est
/// interdite.
final List<(String, RegExp)> _motsInterdits = <(String, RegExp)>[
  for (final String motif in <String>[
    'paiements?',
    'soldes?',
    'recharges?',
    'appareils?',
    'rémunérations?',
    'salaires?',
    'payes?',
    'exports?',
    'exporter',
    'télécharger',
    'téléchargements?',
    'kyc',
    "pièces? d['’]identité",
    'passeports?',
    'adresses? postales?',
    'notes? administratives?',
    'sanctions?',
    'inspections?',
    'surveillances?',
    'espions?',
    'scores?',
    'conformes?',
  ])
    (
      motif,
      RegExp(
        '(?<![\\p{L}\\p{N}])(?:$motif)(?![\\p{L}\\p{N}])',
        caseSensitive: false,
        unicode: true,
      ),
    ),
];

final RegExp _email = RegExp(r'\S+@\S+\.\S+');

/// Au moins huit chiffres consecutifs (espaces, points, tirets toleres), ou
/// un prefixe international.
final RegExp _telephone = RegExp(r'\+\s?\d|\d(?:[ .\-]?\d){7,}');

final RegExp _url = RegExp(
  r'https?:|wss?:|supabase|storage|\.co/',
  caseSensitive: false,
);

/// Les prenoms des eleves de la demonstration.
List<String> get _prenoms => DonneesControleurDemo.roster;

/// Un prenom d'eleve suivi d'un mot a majuscule : un nom de famille.
final List<RegExp> _prenomSuiviDUnNom = <RegExp>[
  for (final String p in _prenoms)
    RegExp(
      '(?<![\\p{L}])${RegExp.escape(p)}[ \\u00A0]+\\p{Lu}[\\p{L}\\-]+',
      unicode: true,
    ),
];

/// Tout le texte rendu : widgets de texte, champs, infobulles et arbre
/// semantique.
Set<String> _textesRendus(WidgetTester tester) {
  final Set<String> textes = <String>{};
  void ajouter(String? s) {
    if (s != null && s.trim().isNotEmpty) textes.add(s);
  }

  for (final Widget w in tester.allWidgets) {
    switch (w) {
      case Text():
        ajouter(w.data);
        ajouter(w.textSpan?.toPlainText());
        ajouter(w.semanticsLabel);
      case RichText():
        ajouter(w.text.toPlainText());
      case EditableText():
        ajouter(w.controller.text);
      case Tooltip():
        ajouter(w.message);
      case Semantics():
        ajouter(w.properties.label);
        ajouter(w.properties.value);
        ajouter(w.properties.hint);
        ajouter(w.properties.tooltip);
      case Image():
        ajouter(w.semanticLabel);
      default:
    }
  }
  void visiter(SemanticsNode n) {
    ajouter(n.label);
    ajouter(n.value);
    ajouter(n.hint);
    ajouter(n.tooltip);
    n.visitChildren((SemanticsNode e) {
      visiter(e);
      return true;
    });
  }

  for (final RenderView v in tester.binding.renderViews) {
    final SemanticsNode? racine = v.owner?.semanticsOwner?.rootSemanticsNode;
    if (racine != null) visiter(racine);
  }
  return textes;
}

/// Les fuites de [textes] sur [ecran], exceptions nommees deduites.
List<String> _fuites(Set<String> textes, String ecran) {
  final List<String> fuites = <String>[];
  for (final String brut in textes) {
    String texte = brut;
    for (final (List<String> ecrans, String excuse, String _) in _exceptions) {
      if (ecrans.contains('*') || ecrans.contains(ecran)) {
        texte = texte.replaceAll(excuse, '');
      }
    }
    void verifier(String motif, RegExp re) {
      if (re.hasMatch(texte)) fuites.add('$motif : « $brut »');
    }

    verifier('e-mail', _email);
    verifier('telephone', _telephone);
    verifier('url', _url);
    for (final (String motif, RegExp re) in _motsInterdits) {
      verifier(motif, re);
    }
    for (final RegExp re in _prenomSuiviDUnNom) {
      verifier('nom de famille', re);
    }
  }
  return fuites;
}

Future<void> _monter(
  WidgetTester tester,
  String adresse,
  Size taille, {
  Object? extra,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    initialExtra: extra,
    routes: routesDemoControleur('dev'),
  );
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await _attendre(tester);
}

/// Les ports de demonstration repondent en 400 ms.
Future<void> _attendre(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await _attendre(tester);
}

Future<void> _continuer(WidgetTester tester) =>
    _toucher(tester, find.text(t.commun.continuer).last);

typedef _Geste = Future<void> Function(WidgetTester tester);

/// Un ecran de demonstration : son nom, son adresse, l'extra de route et les
/// gestes qui y menent depuis l'adresse.
typedef _Ecran = (String nom, String adresse, Object? extra, _Geste? avant);

const SituationEspacesDemo _enseignant = SituationEspacesDemo(
  profil: ProfilDemoControleur.enseignant,
);
const SituationEspacesDemo _admin = SituationEspacesDemo(
  profil: ProfilDemoControleur.admin,
);

/// Les liens de la section « Espaces et acces » de la liste, par cle.
final Map<String, String> _adressesEspaces = <String, String>{
  'enseignant-controle': adresseDemoControleur(
    EcranDemoControleur.controle,
    espaces: _enseignant,
  ),
  'enseignant-principal': adresseDemoControleur(
    EcranDemoControleur.compte,
    espaces: _enseignant.vers(principal: true),
  ),
  'admin-controle': adresseDemoControleur(
    EcranDemoControleur.controle,
    espaces: _admin,
  ),
  'admin-principal': adresseDemoControleur(
    EcranDemoControleur.compte,
    espaces: _admin.vers(principal: true),
  ),
  'mission-en-cours': adresseDemoControleur(
    EcranDemoControleur.compte,
    espaces: _enseignant.enMission(),
  ),
  'acces-revoque': adresseDemoControleur(
    EcranDemoControleur.historique,
    espaces: const SituationEspacesDemo(
      profil: ProfilDemoControleur.enseignant,
      acces: AccesDemoControleur.revoque,
    ),
  ),
  'sans-capacite': adresseDemoControleur(
    EcranDemoControleur.controle,
    espaces: const SituationEspacesDemo(
      profil: ProfilDemoControleur.enseignant,
      acces: AccesDemoControleur.sansCapacite,
    ),
  ),
  'compte-rendu-indisponible': Uri(
    path: cheminDemoCompteRenduControleur,
    queryParameters: <String, String>{
      'etat': EtatDemoControleur.indisponible.name,
    },
  ).toString(),
};

Future<void> _choisir(WidgetTester tester, ChoixCompteRendu choix) =>
    _toucher(tester, find.byKey(CompteRenduControlePage.cleChoix(choix)));

Future<void> _nature(WidgetTester tester) => _toucher(
  tester,
  find.byKey(
    ObservationControlePage.cleNature(NatureObservation.interventionAdmin),
  ),
);

Future<void> _domaine(WidgetTester tester) async {
  await _nature(tester);
  await _continuer(tester);
  await _toucher(
    tester,
    find.byKey(
      ObservationControlePage.cleDomaine(DomaineObservation.pedagogie),
    ),
  );
}

Future<void> _roster(WidgetTester tester) async {
  await _domaine(tester);
  await _continuer(tester);
  await _toucher(
    tester,
    find.byKey(
      ObservationControlePage.clePersonne(PersonneConcernee.elevePrecis),
    ),
  );
  await _toucher(
    tester,
    find.byKey(ObservationControlePage.cleEleve('demo-eleve-0')),
  );
}

Future<void> _texte(WidgetTester tester) async {
  await _roster(tester);
  await _continuer(tester);
  await tester.enterText(
    find.byKey(ObservationControlePage.texteKey),
    "L'élève n'a pas eu la parole pendant la récitation.",
  );
  await _attendre(tester);
}

Future<void> _recapitulatif(WidgetTester tester) async {
  await _texte(tester);
  await _continuer(tester);
}

Future<void> _observationEnvoyee(WidgetTester tester) async {
  await _recapitulatif(tester);
  await _toucher(tester, find.text(t.controleur.compteRendu.envoyer).last);
}

Future<void> _complementMotif(WidgetTester tester) async {
  await _toucher(
    tester,
    find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0921')),
  );
  await _toucher(tester, find.byKey(HistoriqueControleurPage.complementKey));
}

Future<void> _complementRecapitulatif(WidgetTester tester) async {
  await _complementMotif(tester);
  await _continuer(tester);
  await tester.enterText(
    find.byKey(ComplementRapportPage.texteKey),
    'La connexion de la Classe a été coupée deux minutes.',
  );
  await tester.pump();
  await _continuer(tester);
}

Future<void> _complementAjoute(WidgetTester tester) async {
  await _complementRecapitulatif(tester);
  await _toucher(tester, find.text(t.controleur.complement.envoyer).last);
  await _toucher(tester, find.text(t.controleur.complement.revenir).last);
}

/// Tous les ecrans atteignables de la demonstration controleur.
List<_Ecran> _ecrans() => <_Ecran>[
  ('liste', Routes.demoControleur, null, null),
  // Les quatre destinations dans chaque situation de mission.
  for (final EcranDemoControleur e in EcranDemoControleur.values)
    for (final EtatDemoControleur etat in EtatDemoControleur.values)
      (
        'lien-${e.name}-${etat.name}',
        adresseDemoControleur(e, etat: etat),
        null,
        null,
      ),
  // La section « Espaces et acces » (CT-9).
  for (final MapEntry<String, String> l in _adressesEspaces.entries)
    ('lien-espaces-${l.key}', l.value, null, null),
  (
    'feuille-espaces',
    _adressesEspaces['enseignant-controle']!,
    null,
    (WidgetTester tester) => _toucher(tester, find.byKey(RaccourciEspaces.cle)),
  ),
  // La salle (CTR-02).
  ('salle', cheminDemoSalleControleur, null, null),
  // Le compte rendu (CTR-03) et ses etapes.
  ('compte-rendu', cheminDemoCompteRenduControleur, null, null),
  (
    'compte-rendu-faits',
    cheminDemoCompteRenduControleur,
    null,
    (WidgetTester tester) =>
        _toucher(tester, find.text(t.controleur.compteRendu.faits)),
  ),
  for (final ChoixCompteRendu c in ChoixCompteRendu.values)
    (
      'compte-rendu-${c.name}',
      cheminDemoCompteRenduControleur,
      null,
      (WidgetTester tester) => _choisir(tester, c),
    ),
  (
    'compte-rendu-envoye',
    cheminDemoCompteRenduControleur,
    null,
    (WidgetTester tester) async {
      await _choisir(tester, ChoixCompteRendu.rienASignaler);
      await _toucher(tester, find.byKey(CompteRenduControlePage.actionKey));
    },
  ),
  // L'observation structuree (CTR-03A) et son recapitulatif.
  for (final (String nom, _Geste? geste) in <(String, _Geste?)>[
    ('nature', null),
    ('domaine', _domaine),
    ('roster', _roster),
    ('texte', _texte),
    ('recapitulatif', _recapitulatif),
    ('envoyee', _observationEnvoyee),
  ])
    (
      'observation-$nom',
      cheminDemoObservationControleur,
      ChoixCompteRendu.ajouterObservation,
      geste,
    ),
  (
    'observation-point-important',
    cheminDemoObservationControleur,
    ChoixCompteRendu.pointImportant,
    null,
  ),
  // L'Historique (CTR-05) et le Detail d'un controle (CTR-06) : un rapport
  // avec observation et complement, un rapport « Rien a signaler ».
  for (final String id in <String>['demo-rapport-0924', 'demo-rapport-0921'])
    (
      'historique-detail-$id',
      adresseDemoControleur(EcranDemoControleur.historique),
      null,
      (WidgetTester tester) =>
          _toucher(tester, find.byKey(HistoriqueControleurPage.ligneKey(id))),
    ),
  // Le complement (CTR-03B) : motif, recapitulatif, puis le detail enrichi.
  for (final (String nom, _Geste geste) in <(String, _Geste)>[
    ('motif', _complementMotif),
    ('recapitulatif', _complementRecapitulatif),
    ('ajoute', _complementAjoute),
  ])
    (
      'complement-$nom',
      adresseDemoControleur(EcranDemoControleur.historique),
      null,
      geste,
    ),
  // Le fil d'echanges (CTR-04).
  (
    'fil-al-badr',
    adresseDemoControleur(
      EcranDemoControleur.echanges,
      fil: 'demo-mission-al-badr-0924',
    ),
    null,
    null,
  ),
  (
    'fil-mission-envoye',
    adresseFilMissionDemoControleur(),
    null,
    (WidgetTester tester) async {
      await tester.enterText(
        find.byKey(FilDiscussion.champKey),
        'Une question sur cette visite.',
      );
      await tester.pump();
      await _toucher(tester, find.byKey(FilDiscussion.envoyerKey));
    },
  ),
];

void main() {
  group('C8 : aucune donnee interdite sur les ecrans de demonstration', () {
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final (String nom, String adresse, Object? extra, _Geste? avant)
          in _ecrans()) {
        testWidgets('$nom a $l', (WidgetTester tester) async {
          final SemanticsHandle semantique = tester.ensureSemantics();
          await _monter(tester, adresse, taille, extra: extra);
          if (avant != null) await avant(tester);
          final Set<String> textes = _textesRendus(tester);
          // Un ecran sans texte ne prouverait rien.
          expect(textes, isNotEmpty, reason: nom);
          // Temoins : ce que C8 autorise est bien rassemble (le filtre
          // voit ce que l'ecran montre).
          final String tout = textes.join('\n');
          if (nom == 'lien-controle-enDirect') {
            expect(tout, contains(DonneesClasseDemo.classe));
          }
          if (nom == 'salle' || nom == 'observation-recapitulatif') {
            expect(tout, contains(_prenoms.first), reason: nom);
          }
          if (nom == 'complement-ajoute') {
            expect(tout, contains('coupée deux minutes'));
            expect(tout, contains(t.controleur.historique.complementAjoute));
          }
          if (nom == 'fil-mission-envoye') {
            expect(tout, contains('Une question sur cette visite.'));
          }
          expect(_fuites(textes, nom), isEmpty, reason: '$nom a $l');
          expect(tester.takeException(), isNull, reason: nom);
          semantique.dispose();
        });
      }
    }
  });

  testWidgets('chaque lien de la liste de demonstration est parcouru', (
    WidgetTester tester,
  ) async {
    await _monter(tester, Routes.demoControleur, const Size(390, 844));
    final Set<String> liens = <String>{
      for (final Element e in find.byType(LienFleche).evaluate())
        if (e.widget.key case ValueKey<String>(:final String value)) value,
    };
    final Set<String> parcourus = <String>{
      for (final _Ecran e in _ecrans()) e.$1,
    };
    // 20 liens ecran x situation (cinq situations depuis CTRL-SALLE-1),
    // 8 liens d'espaces.
    expect(liens, hasLength(28));
    expect(parcourus.containsAll(liens), isTrue, reason: '$liens');
  });

  test('le filtre detecte ce qu il doit refuser', () {
    const String ecran = 'temoin';
    for (final String fuite in <String>[
      'parent@exemple.fr',
      '06 12 34 56 78',
      '+33 6 12 34 56 78',
      'https://x.supabase.co/storage/v1/objet',
      'Solde du compte',
      'Paiements',
      'Vos appareils',
      'Télécharger le rapport',
      "Pièce d'identité",
      'Note administrative',
      'Score de la séance',
      'Inspection',
      'Classe conforme',
      '${_prenoms.first} Durand',
    ]) {
      expect(_fuites(<String>{fuite}, ecran), isNotEmpty, reason: fuite);
    }
    for (final String permis in <String>[
      'Note',
      "Merci, c'est noté.",
      'Lundi 28 septembre 2026, 18 h 12',
      'Page 24',
      'Classe An-Nour',
      _prenoms.first,
    ]) {
      expect(_fuites(<String>{permis}, ecran), isEmpty, reason: permis);
    }
    // Une exception ne vaut que sur ses ecrans, et pour son texte exact.
    expect(
      _fuites(<String>{t.compte.appareilsDetail}, 'lien-compte-enDirect'),
      isNotEmpty,
    );
    expect(
      _fuites(<String>{
        t.compte.appareilsDetail,
      }, 'lien-espaces-admin-principal'),
      isEmpty,
    );
    expect(
      _fuites(<String>{'${t.compte.deconnexionDetail} Paiements'}, ecran),
      isNotEmpty,
    );
  });

  test('aucun eleve de la demonstration controleur n a de nom de famille', () {
    bool unMot(String nom) => RegExp(r'^\S+$').hasMatch(nom.trim());
    for (final String p in DonneesControleurDemo.roster) {
      expect(unMot(p), isTrue, reason: p);
    }
    for (final EleveProjectionDemo e in DonneesClasseDemo.eleves) {
      expect(unMot(e.prenom), isTrue, reason: e.prenom);
    }
    for (final EleveRoster e in rosterDemoControleur()) {
      expect(unMot(e.prenom), isTrue, reason: e.prenom);
    }
    // Dans la salle, chaque eleve porte son prenom seul.
    for (final ParticipantSalle p in participantsControleurDemo()) {
      if (p.identite.startsWith('demo-eleve-')) {
        expect(unMot(p.nom), isTrue, reason: p.nom);
        expect(_prenoms, contains(p.nom));
      }
    }
    // Les controleurs de la demonstration aussi.
    for (final ControleurDemo c in DonneesControleurDemo.profils) {
      expect(unMot(c.prenom), isTrue, reason: c.prenom);
    }
  });

  group('Recette 32 : aucune donnee de demonstration en production', () {
    // Les routes : test/features/demo/demo_controleur_page_test.dart
    // (`routesDemoControleur('production')` vide). Ici, chaque sous-adresse
    // de la demonstration reste fermee par la porte en production.
    test('la porte ferme chaque adresse de demonstration en production', () {
      for (final String chemin in <String>[
        Routes.demoControleur,
        cheminDemoSalleControleur,
        cheminDemoCompteRenduControleur,
        cheminDemoObservationControleur,
      ]) {
        String? decider(String environnement) => deciderRedirection(
          session: const SessionState.deconnecte(),
          cheminDemande: chemin,
          maintenant: DateTime.utc(2026, 9, 27),
          environnement: environnement,
        );
        expect(decider('production'), isNotNull, reason: chemin);
        expect(decider('dev'), isNull, reason: chemin);
      }
      for (final String env in <String>['production', 'PROD', 'prod-eu', '']) {
        expect(routesDemoControleur(env), isEmpty, reason: env);
      }
    });

    test('les fournisseurs reels sont neutres par defaut', () async {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      // Aucune mission, aucun fait, aucun eleve : rien de la demonstration.
      expect(await c.read(missionControleProvider.future), isNull);
      expect(await c.read(faitsVisiteProvider('seance-A').future), isNull);
      expect(await c.read(rosterControleProvider('seance-A').future), isEmpty);
      // Les ports d'envoi et d'echanges ne sont pas ceux de la
      // demonstration, et ne repondent pas sans serveur.
      expect(
        c.read(envoiCompteRenduProvider),
        isNot(isA<EnvoiCompteRenduDemo>()),
      );
      expect(c.read(portEchangesProvider), isNot(isA<EchangesDemo>()));
      await expectLater(c.read(portEchangesProvider).fils(), throwsStateError);
      // Les espaces menent aux vraies racines, jamais a /demo.
      final AdressesEspaces a = c.read(adressesEspacesProvider);
      expect(a, same(AdressesEspaces.reelles));
      for (final EspaceTravail e in EspaceTravail.values) {
        expect(a.de(e).startsWith('/demo'), isFalse, reason: e.name);
      }
      expect(
        c.read(espacesCompteProvider.notifier),
        isNot(isA<EspacesCompteDemo>()),
      );
    });
  });
}

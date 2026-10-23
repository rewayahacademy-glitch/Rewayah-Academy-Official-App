// ADM-21 : les textes. Chaque cle neuve de `admin.candidatures` existe en
// francais ET en arabe (slang retombe en silence sur le francais quand une cle
// arabe manque : seul ce test le dit), l'arabe n'est jamais le francais recopie,
// chaque parametre du francais se retrouve en arabe, et le francais respecte la
// typographie (espace insecable avant « : ? ! ; » et dans les guillemets).
// Aucun mot interdit (« admin », « groupe », « Reussi »...), aucun tiret long.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/libelles_candidature.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';

Map<String, dynamic> _arbre(String langue) =>
    ((jsonDecode(File('assets/i18n/$langue.i18n.json').readAsStringSync())
                as Map<String, dynamic>)['admin']
            as Map<String, dynamic>)['candidatures']
        as Map<String, dynamic>;

Map<String, String> _feuilles(Map<String, dynamic> a, [String chemin = '']) {
  final Map<String, String> sortie = <String, String>{};
  a.forEach((String k, dynamic v) {
    final String ici = chemin.isEmpty ? k : '$chemin.$k';
    if (v is Map<String, dynamic>) {
      sortie.addAll(_feuilles(v, ici));
    } else if (v is String) {
      sortie[ici] = v;
    }
  });
  return sortie;
}

Set<String> _parametres(String s) =>
    RegExp(r'\{(\w+)\}')
        .allMatches(s)
        .map((RegExpMatch m) => m.group(1)!)
        .toSet();

/// Les sous-arbres que ce lot ajoute.
const List<String> _neufs = <String>[
  'detail.',
  'controles.',
  'historique.',
  'gestes.',
  'consequences.',
  'feuille.',
  'complement.',
  'retrait.',
  'pause.',
  'moyens.',
  'responsables.',
  'modeles.',
  'erreurs.',
  'retours.',
  'exception.candidature',
  'etats.restreintePiece',
  'etats.restreinteVersement',
  'etats.restreinteDirection',
  'etats.provenance.',
];

bool _neuf(String cle) => _neufs.any(cle.startsWith);

void main() {
  final Map<String, String> fr = _feuilles(_arbre('fr'));
  final Map<String, String> ar = _feuilles(_arbre('ar'));

  test('chaque cle neuve a son texte arabe', () {
    final List<String> neuves = fr.keys.where(_neuf).toList();
    expect(neuves, isNotEmpty);
    final List<String> manquantes = <String>[
      for (final String k in neuves)
        if (!ar.containsKey(k)) k,
    ];
    // Chiffre mesure : 0 cle neuve sans traduction arabe.
    expect(manquantes, isEmpty);
    // ignore: avoid_print
    print(
      'ADM-21 : ${neuves.length} cles neuves, ${manquantes.length} sans arabe',
    );
  });

  test('l\'arabe n\'est jamais le francais recopie', () {
    final List<String> copies = <String>[
      for (final String k in fr.keys.where(_neuf))
        if (ar[k] == fr[k] && RegExp('[A-Za-z]{3}').hasMatch(fr[k]!)) k,
    ];
    expect(copies, isEmpty);
  });

  test('chaque parametre du francais se retrouve en arabe', () {
    for (final String k in fr.keys.where(_neuf)) {
      expect(_parametres(ar[k] ?? ''), _parametres(fr[k]!), reason: k);
    }
  });

  test(
    'le francais : espace insecable avant : ? ! ; et dans les guillemets',
    () {
      for (final String k in fr.keys.where(_neuf)) {
        final String s = fr[k]!;
        expect(RegExp(r'[^  ] [:?!;]').hasMatch(s), isFalse, reason: '$k : $s');
        expect(s.contains('« '), isFalse, reason: '$k : $s');
        expect(s.contains(' »'), isFalse, reason: '$k : $s');
      }
    },
  );

  test('aucun mot interdit, aucun tiret long, aucun code interne', () {
    for (final Map<String, String> langue in <Map<String, String>>[fr, ar]) {
      for (final MapEntry<String, String> e in langue.entries.where(
        (MapEntry<String, String> e) => _neuf(e.key),
      )) {
        final String s = e.value;
        expect(s.contains('—'), isFalse, reason: e.key);
        expect(s.contains('–'), isFalse, reason: e.key);
        expect(
          RegExp(r'CAND-BR|L2A|\bL[1-6]\b').hasMatch(s),
          isFalse,
          reason: e.key,
        );
      }
    }
    for (final MapEntry<String, String> e in fr.entries.where(
      (MapEntry<String, String> e) => _neuf(e.key),
    )) {
      final String s = e.value.toLowerCase();
      expect(RegExp(r'\badmin\b').hasMatch(s), isFalse, reason: e.key);
      expect(RegExp(r'\bgroupes?\b').hasMatch(s), isFalse, reason: e.key);
      expect(RegExp(r'r[ée]ussi|[ée]chec').hasMatch(s), isFalse, reason: e.key);
    }
  });

  group('les libelles par code, dans les deux langues', () {
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      test('en ${langue.languageCode}', () async {
        await LocaleSettings.setLocale(langue);
        addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        // Chaque modele du serveur a un nom, jamais le code.
        for (final String code in <String>[
          ...capacitesGestes.listes.modelesRefus,
          ...capacitesGestes.listes.modelesPause,
        ]) {
          expect(libelleModele(code), isNot(code));
          expect(
            libelleModele(code),
            isNot(t.admin.candidatures.modeles.autre),
          );
        }
        expect(
          libelleModele('code_inconnu'),
          t.admin.candidatures.modeles.autre,
        );
        // Chaque element de complement du serveur a un nom.
        for (final String code in <String>[
          ...capacitesGestes.listes.complementSalleExamen,
          ...capacitesGestes.listes.complementSalleVerification,
        ]) {
          expect(libelleElementComplement(code), isNotNull, reason: code);
          expect(libelleElementComplement(code), isNot(code));
        }
        expect(libelleElementComplement('code_inconnu'), isNull);
        // Chaque geste, consequence et retour a son texte.
        for (final GesteCandidature g in GesteCandidature.values) {
          expect(libelleGeste(g).trim(), isNotEmpty);
          expect(libelleConsequence(g).trim(), isNotEmpty);
          expect(libelleRetour(g).trim(), isNotEmpty);
        }
        // Chaque controle et chaque cause du serveur a son nom.
        for (final String nom in <String>[
          'compte_conforme',
          'paiement_compatible',
          'cadre_religieux',
          'questionnaire_complet',
        ]) {
          expect(libelleControle(nom), isNot(nom));
          expect(
            libelleControle(nom),
            isNot(t.admin.candidatures.controles.noms.inconnu),
          );
        }
        for (final String cause in <String>[
          'supprime',
          'role',
          'statut',
          'expire',
          'engagement',
          'non_publie',
          'non_accepte',
          'questionnaire_absent',
          'absent',
          'perime',
          'incomplet',
        ]) {
          expect(
            libelleCauseControle('cadre_religieux', cause),
            isNot(t.admin.candidatures.controles.causes.inconnue),
            reason: cause,
          );
        }
        for (final String cause in <String>[
          'inconnu',
          'a_verifier',
          'incompatible',
        ]) {
          expect(
            libelleCauseControle('paiement_compatible', cause),
            isNot(t.admin.candidatures.controles.causes.inconnue),
            reason: cause,
          );
        }
        // Chaque type d'evenement du serveur a son nom.
        for (final String type in <String>[
          'creee',
          'transition',
          'pause',
          'reprise',
          'restriction',
          'levee_restriction',
          'responsable',
          'controle',
          'import',
          'correction_import',
          'lecture_contact',
          'lecture_hors_portee',
          'entretien',
          'engagement',
          'prevenu',
        ]) {
          expect(
            libelleTypeEvenement(type),
            isNot(t.admin.candidatures.historique.types.inconnu),
            reason: type,
          );
        }
        // Chaque etat nomme par un refus se dit par son libelle de la salle.
        for (final EtatCandidature e in EtatCandidature.values) {
          expect(
            libelleEtatCourant(
              issue: IssueCandidature.enCours,
              enPause: false,
              etape: EtapeCandidature.prequalification,
              etat: e,
            ),
            isNot(e.valeurSql),
          );
        }
        // Chaque refus se dit en mots.
        for (final RefusGeste r in <RefusGeste>[
          const ConflitGeste(2),
          const GesteInterdit(),
          const ControlesNonSatisfaits(<({String nom, String? cause})>[
            (nom: 'cadre_religieux', cause: 'non_accepte'),
          ]),
          const MotifRequis(),
          const ModeleRequis(),
          const ModeleInconnu(),
          const ElementsRequis(),
          const ElementsInvalides(),
          const AucunComplement(),
          const RepriseInvalide(),
          const DateDemandeInvalide(),
          const MoyenNonConfirmable(),
          const MoyenNonDeclare(),
          const ResponsableInvalide(),
          const CleReutilisee(),
          const GesteNonConfirme(),
        ]) {
          expect(messageRefus(r).trim(), isNotEmpty);
          expect(messageRefus(r), isNot(contains('_')));
        }
      });
    }
  });
}

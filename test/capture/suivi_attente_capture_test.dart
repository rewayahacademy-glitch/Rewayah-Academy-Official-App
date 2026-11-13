// SUIVI-ATTENTE : les captures de recette, sur des donnees de test (il n'y a
// aucune demande reelle en production, S9). Les cinq etapes et chaque cas
// particulier, en 390 et 1440 de large, clair et sombre, francais et arabe
// (droite a gauche).
//
//   CAPTURE_DIR=docs/current/captures/E2E/suivi-attente \
//     flutter test test/capture/suivi_attente_capture_test.dart
//
// Saute sans CAPTURE_DIR. Nom des PNG : `<ecran>_<largeur>_<clair|sombre>_<fr|ar>`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/attente_classe/modele_attente.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/attente_classe/carte_suivi_attente.dart';
import 'package:rewayah_academy/features/attente_classe/me_presenter_page.dart';
import 'package:rewayah_academy/features/attente_classe/presentation_familles_page.dart';
import 'package:rewayah_academy/features/attente_classe/suivi_attente_page.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../features/com_messages/support_messages.dart';
import '../support/attente_donnees.dart';
import 'outil_capture.dart';

typedef _Variante = ({
  String nom,
  double largeur,
  double hauteur,
  Brightness clarte,
  AppLocale langue,
});

final List<_Variante> _variantes = <_Variante>[
  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar])
    for (final Brightness clarte in <Brightness>[
      Brightness.light,
      Brightness.dark,
    ]) ...<_Variante>[
      (
        nom:
            '390_${clarte == Brightness.light ? 'clair' : 'sombre'}_${langue.languageCode}',
        largeur: 390,
        hauteur: 1500,
        clarte: clarte,
        langue: langue,
      ),
      (
        nom:
            '1440_${clarte == Brightness.light ? 'clair' : 'sombre'}_${langue.languageCode}',
        largeur: 1440,
        hauteur: 1000,
        clarte: clarte,
        langue: langue,
      ),
    ],
];

typedef _Ecran = ({
  String nom,
  Widget Function() ecran,
  List<Override> Function() surcharges,
});

List<Override> _avec(List<SuiviAttente> suivis) => <Override>[
  portSuiviAttenteProvider.overrideWithValue(PortSuiviAttenteFaux(suivis)),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
];

_Ecran _suivi(String nom, SuiviAttente s, {CheminsAttente? chemins}) => (
  nom: nom,
  ecran: () => SuiviAttentePage(
    demandeId: s.demandeId,
    chemins: chemins ?? CheminsAttente.tuteur,
  ),
  surcharges: () => _avec(<SuiviAttente>[s]),
);

GroupeEnseignant _classe() => GroupeEnseignant(
  id: 'g1',
  libelle: 'Classe Al-Fatiha',
  type: TypePublicGroupe.enfant,
  seuilMax: 5,
  creneau: const Creneau(jour: 1, heure: 18, fuseau: 'Europe/Paris'),
  nbMembres: 3,
  creeLe: DateTime.now(),
);

final List<_Ecran> _ecrans = <_Ecran>[
  _suivi(
    '01_demande_recue_classe_en_formation',
    suiviDeTest(delai: delaiDeTest()),
  ),
  _suivi(
    '02_classe_confirmee',
    suiviDeTest(
      etapes: etapesJusqua(2),
      classe: 'Classe Al-Fatiha',
      enseignant: enseignantVisible,
    ),
  ),
  _suivi(
    '03_enseignant_affecte',
    suiviDeTest(
      etapes: etapesJusqua(3),
      classe: 'Classe Al-Fatiha',
      enseignant: enseignantVisible,
    ),
  ),
  _suivi('04_tout_est_pret', suiviToutEstPret()),
  _suivi(
    '05_classe_en_attente_enseignant',
    suiviDeTest(
      cas: CasAttente.enAttenteEnseignant,
      etapes: etapesJusqua(2),
      classe: 'Classe Al-Fatiha',
    ),
  ),
  _suivi('06_liste_attente', suiviDeTest(cas: CasAttente.listeAttente)),
  _suivi(
    '07_delai_depasse',
    suiviDeTest(delai: delaiDeTest(depasse: true, pointPasse: true)),
  ),
  _suivi(
    '08_demande_refusee',
    suiviDeTest(
      cas: CasAttente.refusee,
      motif: MotifCloture.refusDirection,
      peutChoisirAutreCreneau: true,
    ),
  ),
  _suivi(
    '09_demande_retiree',
    suiviDeTest(cas: CasAttente.retiree, motif: MotifCloture.retraitFamille),
  ),
  _suivi(
    '10_enseignant_discret',
    suiviToutEstPret(enseignant: enseignantDiscret),
  ),
  _suivi(
    '11_changement_de_creneau',
    suiviDeTest(
      etapes: etapesJusqua(2),
      classe: 'Classe Al-Fatiha',
      creneauChangeLe: DateTime(2026, 11, 12, 8, 0),
    ),
  ),
  _suivi(
    '12_version_simple_enfant',
    suiviToutEstPret(versionSimple: true),
    chemins: CheminsAttente.enfant,
  ),
  _suivi(
    '17_mineur_10_17_tout_est_pret',
    suiviToutEstPret(),
    chemins: CheminsAttente.enfant,
  ),
  _suivi(
    '18_mineur_10_17_delai_depasse',
    suiviDeTest(delai: delaiDeTest(depasse: true, pointPasse: true)),
    chemins: CheminsAttente.enfant,
  ),
  _suivi(
    '19_tuteur_enfant_6_9_tout_est_pret',
    suiviToutEstPret(versionSimple: true),
  ),
  (
    nom: '13_vide',
    ecran: () =>
        const SuiviAttentePage(demandeId: 'd1', chemins: CheminsAttente.tuteur),
    surcharges: () => _avec(const <SuiviAttente>[]),
  ),
  (
    nom: '14_carte_accueil',
    ecran: () => const Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: CarteSuiviAttente(chemins: CheminsAttente.tuteur),
      ),
    ),
    surcharges: () => _avec(<SuiviAttente>[
      suiviDeTest(delai: delaiDeTest()),
      suiviToutEstPret(id: 'd2').copyAvecPrenom('Ines'),
    ]),
  ),
  (
    nom: '15_enseignant_me_presenter',
    ecran: () => const MePresenterPage(groupeId: 'g1'),
    surcharges: () {
      final ConversationPossible a = ConversationPossible(
        interlocuteur: const Participant(id: 'a', nomAffiche: 'Famille A'),
        nature: NatureInterlocuteur.famille,
        objet: ObjetLie(
          type: TypeObjetLie.classe,
          id: 'g1',
          libelle: 'Classe Al-Fatiha',
        ),
      );
      return <Override>[
        portMessagesMetierProvider.overrideWithValue(
          FauxMessagesMetier(
            fils: <FilMetier>[filSimple(id: 'fil-a')],
            conversations: <String, List<ConversationPossible>>{
              cleObjet(TypeObjetLie.classe, 'g1'): <ConversationPossible>[a],
            },
            filsParConversation: <String, String>{a.cle: 'fil-a'},
          ),
        ),
        groupesEnseignantProvider.overrideWith(
          (Ref _) async => <GroupeEnseignant>[_classe()],
        ),
        profilEnseignantProvider.overrideWith(
          (Ref _) async => const ProfilEnseignant(
            prenom: 'Ibrahim',
            identifiant: 'RA-ENS-1',
            titre: 'sayyid',
          ),
        ),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
      ];
    },
  ),
  (
    nom: '16_enseignant_ce_que_les_familles_voient',
    ecran: () => const PresentationFamillesPage(),
    surcharges: () => <Override>[
      portPresentationEnseignantProvider.overrideWithValue(
        _PortPresentationCapture(),
      ),
      horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
    ],
  ),
];

class _PortPresentationCapture implements PortPresentationEnseignant {
  @override
  Future<PresentationAuxFamilles> lire() async => const PresentationAuxFamilles(
    montre: true,
    confirme: false,
    paysOrigine: 'GN',
    paysResidence: 'FR',
    mot: 'Je suis heureux de vous retrouver.',
  );

  @override
  Future<void> regler({
    required bool montre,
    String? paysOrigine,
    String? paysResidence,
    String? mot,
  }) async {}
}

extension on SuiviAttente {
  SuiviAttente copyAvecPrenom(String autre) => SuiviAttente(
    demandeId: demandeId,
    eleveId: eleveId,
    prenom: autre,
    fuseauIana: fuseauIana,
    cas: cas,
    etapes: etapes,
    typePublic: typePublic,
    versionSimple: versionSimple,
    motif: motif,
    creneau: creneau,
    delai: delai,
    classe: classe,
    premierCours: premierCours,
    premierCoursPasse: premierCoursPasse,
    creneauChangeLe: creneauChangeLe,
    enseignant: enseignant,
    peutChoisirAutreCreneau: peutChoisirAutreCreneau,
    visibleAccueil: visibleAccueil,
  );
}

void main() {
  group('Capture : SUIVI-ATTENTE', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    for (final _Variante v in _variantes) {
      for (final _Ecran e in _ecrans) {
        testWidgets('${e.nom}_${v.nom}', (WidgetTester tester) async {
          LocaleSettings.setLocaleSync(v.langue);
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          fixerVueCapture(tester, Size(v.largeur, v.hauteur), 1);
          await tester.pumpWidget(
            hoteCapture(
              e.ecran(),
              surcharges: e.surcharges(),
              themeMode: v.clarte == Brightness.light
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
          );
          await stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, '${e.nom}_${v.nom}')}');
        });
      }
    }
  });
}

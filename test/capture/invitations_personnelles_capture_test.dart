// Captures du lot 7 INVITATIONS-PERSONNELLES (07/11/2026) :
// - la feuille « Envoyer les codes personnels » de la direction, 390 et 1440 ;
// - la page « Continuer » des familles deja inscrites, 390 x 844, avant et
//   apres l'option (c) (PHASE=avant ou apres nomme les fichiers).
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Donnees inventees ; aucune adresse, aucune personne reelle.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/port_invitations_personnelles.dart';
import 'package:rewayah_academy/core/import_inscriptions/port_reclamation_preinscription.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/accueil_inscrits/accueil_inscrits_page.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_lien_personnel.dart';
import 'package:rewayah_academy/features/admin_candidatures/invitations_personnelles.dart';

import '../support/harnais.dart' show FauxServiceReseau;
import 'outil_capture.dart';

final String _phase = Platform.environment['PHASE'] ?? 'apres';

class _Faux implements PortInvitationsPersonnelles {
  _Faux({this.importees = 1599});

  final int importees;

  @override
  Future<ApercuInvitationsPersonnelles> apercu() async =>
      ApercuInvitationsPersonnelles(
        aInviter: 612,
        aRenvoyer: 3,
        dejaInvites: 0,
        dejaInscrits: 21,
        revoquees: 0,
        desinscrits: 4,
        sansAdresse: 37,
        plafondJour: 300,
        resteAujourdhui: 300,
        reponsesImportees: importees,
        varianteA: 600,
      );

  @override
  Future<ResultatInvitationsPersonnelles> envoyer({
    required int attendu,
    int limite = limiteInvitationsParEnvoi,
  }) => throw UnimplementedError();

  @override
  Future<ResultatLien> lienPour({
    required String candidatureId,
    required String courriel,
  }) async =>
      LienPret(code: 'ABCD-EFGH-JKMN', expireLe: DateTime.utc(2026, 11, 21));
}

class _Ouvreur extends StatefulWidget {
  const _Ouvreur({this.lien = false});

  final bool lien;

  @override
  State<_Ouvreur> createState() => _OuvreurEtat();
}

class _OuvreurEtat extends State<_Ouvreur> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (Duration _) => widget.lien
          ? ouvrirFeuilleLienPersonnel(context, candidatureId: 'c1')
          : ouvrirFeuilleInvitationsPersonnelles(context),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.expand());
}

const ReclamationPreinscription _famille = ReclamationPreinscription(
  connue: true,
  motAccueil:
      'Mariam, vous nous aviez demandé, il y a longtemps déjà, de vous '
      'inscrire, vous et Yasmine, Adam, Sara, Ilyes et Nour. Nous vous avions '
      "demandé d'attendre, et vous avez attendu, avec une patience et une "
      'confiance qui nous ont profondément touchés. Vous faites partie des '
      'toutes premières familles de la nouvelle Rewayah Academy. Bienvenue '
      'chez vous. La direction',
  personnes: <PersonneImportee>[
    PersonneImportee(
      id: 'p-tuteur',
      prenom: 'Mariam',
      nature: NaturePersonneImportee.tuteur,
    ),
    PersonneImportee(
      id: 'p-1',
      prenom: 'Yasmine',
      nature: NaturePersonneImportee.eleve,
    ),
    PersonneImportee(
      id: 'p-2',
      prenom: 'Adam',
      nature: NaturePersonneImportee.eleve,
    ),
    PersonneImportee(
      id: 'p-3',
      prenom: 'Sara',
      nature: NaturePersonneImportee.eleve,
    ),
    PersonneImportee(
      id: 'p-4',
      prenom: 'Ilyes',
      nature: NaturePersonneImportee.eleve,
    ),
    PersonneImportee(
      id: 'p-5',
      prenom: 'Nour',
      nature: NaturePersonneImportee.eleve,
    ),
  ],
);

void main() {
  group('Capture : lot 7', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (Size taille, double densite) in <(Size, double)>[
      (const Size(390, 844), 3),
      (const Size(1440, 900), 1),
    ]) {
      testWidgets('feuille ${taille.width.toInt()}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, densite);
        await tester.pumpWidget(
          hoteCapture(
            const _Ouvreur(),
            surcharges: <Override>[
              portInvitationsPersonnellesProvider.overrideWithValue(_Faux()),
              serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
            ],
          ),
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'codes_personnels_feuille_${taille.width.toInt()}')}',
        );
      });
    }

    testWidgets('aucune reponse importee 390', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3);
      await tester.pumpWidget(
        hoteCapture(
          const _Ouvreur(),
          surcharges: <Override>[
            portInvitationsPersonnellesProvider.overrideWithValue(
              _Faux(importees: 0),
            ),
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
        ),
      );
      await stabiliser(tester);
      debugPrint(
        'PNG ${await capturer(tester, 'codes_personnels_aucune_importee_390')}',
      );
    });

    testWidgets('copier le lien 390', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3);
      await tester.pumpWidget(
        hoteCapture(
          const _Ouvreur(lien: true),
          surcharges: <Override>[
            portInvitationsPersonnellesProvider.overrideWithValue(_Faux()),
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
        ),
      );
      await stabiliser(tester);
      debugPrint('PNG ${await capturer(tester, 'lien_personnel_saisie_390')}');
      await tester.enterText(
        find.descendant(
          of: find.byKey(FeuilleLienPersonnel.cleChamp),
          matching: find.byType(EditableText),
        ),
        'personne@test.invalid',
      );
      await tester.tap(find.byKey(FeuilleLienPersonnel.clePreparer));
      await stabiliser(tester);
      debugPrint('PNG ${await capturer(tester, 'lien_personnel_pret_390')}');
    });

    testWidgets('continuer 390', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3);
      await tester.pumpWidget(
        hoteCapture(
          VueAccueilInscrits(
            reclamation: _famille,
            onAjouter: (PersonneImportee _) {},
            onContinuer: () {},
          ),
        ),
      );
      await stabiliser(tester);
      debugPrint(
        'PNG ${await capturer(tester, 'continuer_${_phase}_390x844')}',
      );
    });
  });
}

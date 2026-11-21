// PERSONNES-UNE-PAGE, etape (e) : les outils du recrutement (inviter,
// prevenir par e-mail, creneaux d'entretien, codes personnels, import des
// formulaires), sortis de la file des candidatures pour servir aussi au menu
// « Outils » de la page « Personnes ». Le code est celui de
// `candidatures_page.dart`, deplace tel quel : chaque lien n'est rendu que si
// le serveur ouvre le geste a ce lecteur et que le port est servi, jamais
// grise.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/creneaux_direction.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/candidature/port_import_candidatures.dart';
import '../../core/candidature/port_invitations_personnelles.dart';
import '../../core/candidature/port_prevenir_candidats.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/recrutement/port_invitations_comptable.dart';
import '../../core/recrutement/port_invitations_enseignant.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/menu_actions.dart';
import '../admin_import_formulaires/routes_candidats_flux.dart';
import 'invitations_personnelles.dart';
import 'prevenir_candidats.dart';

/// Les outils du recrutement que [caps] et les ports ouvrent a ce lecteur.
List<EntreeAction> outilsDuRecrutement(
  BuildContext context,
  WidgetRef ref,
  CapacitesCandidatures caps,
) {
  final bool invitations =
      ref.watch(portInvitationsEnseignantProvider) != null ||
      ref.watch(portInvitationsComptableProvider) != null;

  // CANDIDATS-FLUX (06/11/2026, porte de la PR 50) : « Prevenir par e-mail »
  // les personnes des formulaires importes, et l'import des formulaires.
  // Chaque lien n'est rendu que si le serveur ouvre le geste a ce lecteur et
  // que le port est servi, jamais grise.
  final bool prevenir =
      caps.geste('consignerPrevenu') &&
      ref.watch(portPrevenirCandidatsProvider) != null;
  // L'import : pour le super administrateur, que sa session soit deja en
  // double verification (`peutImporter`) ou qu'elle doive y monter au geste
  // (`doubleVerificationRequise`, la page d'import demande alors le code).
  final CapacitesImportCandidatures? capsImport = ref
      .watch(capacitesImportCandidaturesProvider)
      .value;
  final bool importer =
      ref.watch(portImportCandidaturesProvider) != null &&
      capsImport != null &&
      (capsImport.peutImporter || capsImport.doubleVerificationRequise);
  // SALLE-2-ENTRETIEN (07/11/2026) : les creneaux d'entretien, pour qui
  // decide d'une candidature, quand le port est servi.
  final bool creneaux =
      caps.peutDecider && ref.watch(portCreneauxDirectionProvider) != null;

  return <EntreeAction>[
    if (invitations)
      EntreeAction(
        libelle: t.recrutement.invitations.onglet,
        onChoix: () =>
            unawaited(context.push<void>(Routes.adminPersonnesInvitations)),
      ),
    if (prevenir)
      EntreeAction(
        libelle: t.candidatsFlux.prevenir.lien,
        onChoix: () => ouvrirFeuillePrevenir(context),
      ),
    if (creneaux)
      EntreeAction(
        libelle: t.admin.candidatures.creneaux.lien,
        onChoix: () => unawaited(
          context.push<void>(Routes.adminPersonnesCreneauxEntretien),
        ),
      ),
    // INVITATIONS-PERSONNELLES (lot 7, 07/11/2026) : les codes personnels
    // des candidats importes, pour le meme lecteur que l'import.
    if (importer && ref.watch(portInvitationsPersonnellesProvider) != null)
      EntreeAction(
        libelle: t.candidatsFlux.invitationsPersonnelles.lien,
        onChoix: () => ouvrirFeuilleInvitationsPersonnelles(context),
      ),
    if (importer)
      EntreeAction(
        libelle: t.candidatsFlux.importFormulaires.lienEntree,
        onChoix: () => unawaited(
          context.push<void>(RoutesCandidatsFlux.importFormulaires),
        ),
      ),
  ];
}

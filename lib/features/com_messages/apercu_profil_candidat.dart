// L'apercu du profil d'un candidat dans un fil de messages, cote direction
// (demande du directeur, 14/11/2026, relayee par le pilote) : photo, nom,
// type, genre, pays, situation de la candidature, piece d'identite,
// entretien, dernieres decisions ; en bas, « Voir tout le dossier » ouvre la
// fiche existante (`ADM-21`).
//
// **Tout vient du serveur, par les lectures existantes de la direction** :
// `lire_candidature` (portee de genre comprise, CAND-Q07), les entretiens
// (V1-a) et l'historique. Aucune RPC nouvelle, aucun calcul ici. Un compte
// qui n'est pas de la direction n'obtient rien : le serveur refuse, et
// l'apercu ne rend rien (ni erreur, ni donnee). Il ne se pose d'ailleurs que
// quand la personne qui lit est l'equipe du fil (`Participant.equipe` de
// soi, rendu par le serveur), jamais d'apres un role.
//
// Donnee non servie aujourd'hui : la langue du candidat (`lire_candidature`
// ne la rend pas) ; elle n'est pas inventee.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/modeles_entretien_direction.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/candidature/port_entretiens_direction.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/modeles_communication.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import '../admin_candidature/bloc_entretien.dart' show libelleIssueEntretien;
import '../admin_candidature/libelles_candidature.dart';
import '../admin_candidatures/libelles_candidatures.dart';
import 'avatar_participant.dart';

/// Ce que l'apercu montre, lu en une fois.
@immutable
class ApercuCandidature {
  /// Cree l'apercu.
  const ApercuCandidature({
    required this.detail,
    required this.entretiens,
    required this.decisions,
  });

  /// La candidature telle que `lire_candidature` la rend.
  final DetailCandidature detail;

  /// Les entretiens, ou `null` quand ils ne sont pas lisibles.
  final List<EntretienCandidature>? entretiens;

  /// Les dernieres decisions (au plus trois), les plus recentes d'abord.
  final List<EvenementCandidature> decisions;
}

/// Au plus tant de decisions dans l'apercu.
const int decisionsApercu = 3;

/// L'apercu d'une candidature, ou une erreur. [CapaciteIndisponible] quand
/// la direction n'a pas de port (personne d'autre ne lit rien).
final FutureProviderFamily<ApercuCandidature, String>
apercuCandidatureProvider = FutureProvider.autoDispose
    .family<ApercuCandidature, String>((Ref ref, String candidatureId) async {
      final PortCandidaturesDirection? port = ref.watch(
        portCandidaturesDirectionProvider,
      );
      if (port == null) {
        throw const CapaciteIndisponible('APERCU-CANDIDAT');
      }
      final DetailCandidature detail = await port.lire(candidatureId);
      List<EntretienCandidature>? entretiens;
      try {
        entretiens = await ref.watch(
          entretiensCandidatureProvider(candidatureId).future,
        );
      } on Object {
        entretiens = null;
      }
      List<EvenementCandidature> decisions = const <EvenementCandidature>[];
      try {
        final PageHistorique page = await port.historique(candidatureId);
        decisions = page.evenements.take(decisionsApercu).toList();
      } on Object {
        decisions = const <EvenementCandidature>[];
      }
      return ApercuCandidature(
        detail: detail,
        entretiens: entretiens,
        decisions: decisions,
      );
    }, retry: (int _, Object _) => null);

/// L'apercu du profil du candidat [candidat], pour la candidature
/// [candidatureId].
class ApercuProfilCandidat extends ConsumerWidget {
  /// Cree l'apercu.
  const ApercuProfilCandidat({
    required this.candidatureId,
    required this.candidat,
    super.key,
    this.onOuvrir,
  });

  /// La candidature du fil.
  final String candidatureId;

  /// Le candidat (sa photo par le fournisseur unique).
  final Participant candidat;

  /// Ouvre un chemin ; par defaut, le routeur.
  final ValueChanged<String>? onOuvrir;

  /// La cle du bloc, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('apercu-profil');

  /// La cle du lien vers le dossier, pour les tests.
  static const ValueKey<String> cleDossier = ValueKey<String>(
    'apercu-profil-dossier',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ApercuCandidature> lu = ref.watch(
      apercuCandidatureProvider(candidatureId),
    );
    if (lu.hasValue && !lu.isLoading) {
      return _contenu(context, lu.requireValue);
    }
    if (lu.hasError) {
      // Refus du serveur, port absent ou lecture impossible : rien du
      // candidat n'est montre. Le reste du panneau reste lisible.
      return const SizedBox.shrink();
    }
    return const Skeleton.texte(key: cle);
  }

  Widget _contenu(BuildContext context, ApercuCandidature a) {
    final m = t.com.messages.apercu;
    final LigneCandidature l = a.detail.ligne;
    final EntretienCandidature? dernier = _dernierEntretien(a.entretiens);
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GroupeReglages(
          titre: m.titre,
          lignes: <LigneRubrique>[
            LigneRubrique(
              meneur: AvatarParticipant(
                participant: candidat,
                repli: l.nomComplet,
                diametre: AppAvatar.moyen,
              ),
              libelle: l.nomComplet,
              legende: l.type == 'enseignant' ? m.typeEnseignant : null,
            ),
            if (libelleGenre(l.genre) case final String genre)
              LigneRubrique(libelle: m.genre, valeur: genre),
            if (libellePays(l.paysResidence) case final String pays)
              LigneRubrique(libelle: m.pays, valeur: pays),
            LigneRubrique(
              libelle: m.situation,
              valeur: libelleEtatCourant(
                issue: l.issue,
                enPause: l.enPause,
                etape: l.etape,
                etat: l.etat,
              ),
            ),
            LigneRubrique(
              libelle: m.piece,
              valeur: _piece(a.detail.piece) ?? m.nonServi,
            ),
            LigneRubrique(
              libelle: m.entretien,
              valeur: a.entretiens == null
                  ? m.nonServi
                  : dernier == null
                  ? m.aucunEntretien
                  : dernier.issue == null
                  ? m.entretienPrevu(
                      quand: dateCourteCandidature(dernier.debut),
                    )
                  : '${libelleIssueEntretien(dernier.issue!)} · '
                        '${dateCourteCandidature(dernier.debut)}',
            ),
          ],
        ),
        Ecart.vLg,
        GroupeReglages(
          titre: m.decisions,
          lignes: <LigneRubrique>[
            if (a.decisions.isEmpty)
              LigneRubrique(libelle: m.aucuneDecision)
            else
              for (final EvenementCandidature e in a.decisions)
                LigneRubrique(
                  libelle: libelleTypeEvenement(e.type),
                  legende: e.quand == null ? null : instantHistorique(e.quand!),
                ),
          ],
        ),
        Ecart.vMd,
        LienFleche(
          key: cleDossier,
          libelle: m.voirDossier,
          alignerEnDebut: true,
          onPress: () {
            final String chemin = Routes.adminPersonnesCandidaturePour(
              l.reference,
            );
            final ValueChanged<String>? ouvrir = onOuvrir;
            if (ouvrir != null) {
              ouvrir(chemin);
            } else {
              GoRouter.of(context).go(chemin, extra: l.id);
            }
          },
        ),
      ],
    );
  }

  static EntretienCandidature? _dernierEntretien(
    List<EntretienCandidature>? entretiens,
  ) {
    if (entretiens == null || entretiens.isEmpty) return null;
    return entretiens.reduce(
      (EntretienCandidature a, EntretienCandidature b) =>
          a.debut.isAfter(b.debut) ? a : b,
    );
  }

  static String? _piece(EtatPiece? p) {
    final e = t.admin.candidatures.detail.etatsPiece;
    return switch (p) {
      EtatPiece.aDeposer => e.aDeposer,
      EtatPiece.deposee => e.deposee,
      EtatPiece.aCorriger => e.aCorriger,
      EtatPiece.validee => e.validee,
      null => null,
    };
  }
}

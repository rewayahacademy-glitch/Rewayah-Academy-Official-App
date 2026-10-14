import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/apparition_douce.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/skeleton.dart';
import '../accueil_famille/bloc_seance.dart' show heureDeLAppareil;
import 'compte_rendu_controle.dart';
import 'compte_rendu_controle_page.dart' show LigneTransmissionVisite;
import 'mission_controle.dart';

/// `CTR-01` Controle (CT-2) : **une seule** carte de mission, jamais un
/// planning (decision du directeur du 27/09/2026, C1, C3, C14).
///
/// Quatre situations : aucune mission (le texte vide du doc 08), seance pas
/// encore en direct (ligne calme, aucun bouton, R4), seance en direct (un seul
/// bouton dominant « Commencer le controle », au bord de fin de la carte,
/// K-42), mission indisponible (P-CTR-08). La carte « Mon compte » de l'ancien
/// planning est retiree : Compte est une destination de la barre (C13).
///
/// Une seule colonne bornee tant qu'il n'y a pas de bloc « Compte rendu a
/// terminer » : on ne remplit pas le vide (UX_REVIEW_08 CTR-01 d).
class ControleControleurPage extends ConsumerWidget {
  /// Cree l'ecran.
  const ControleControleurPage({
    super.key,
    this.onCommencer,
    this.onReprendreCompteRendu,
  });

  /// L'entree en salle ; par defaut `/salle` avec le billet (ADR-005). La
  /// demonstration la redirige vers sa salle fictive (CT-3).
  final void Function(MissionControle mission)? onCommencer;

  /// Le retour au compte rendu a terminer de la seance donnee ; par defaut,
  /// sa route avec `?seance=` (CT-4, revue CT-R B1).
  final ValueChanged<String>? onReprendreCompteRendu;

  /// La cle de « Reprendre » pour la visite [seanceId] ; la plus recente
  /// garde [reprendreKey].
  static Key cleReprendre(String seanceId) =>
      ValueKey<String>('ctr01-reprendre-$seanceId');

  /// La cle du bouton d'entree.
  static const Key commencerKey = ValueKey<String>('ctr01-commencer');

  /// La cle du message « Un controle est deja en cours » (CTRL-SALLE-1).
  static const Key dejaControleeKey = ValueKey<String>('ctr01-deja-controlee');

  /// La cle de « Reprendre le compte rendu ».
  static const Key reprendreKey = ValueKey<String>('ctr01-reprendre');

  /// La largeur utile de la colonne.
  static const double largeurMax = 640;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MissionControle?> mission = ref.watch(
      missionControleProvider,
    );
    final Widget corps = switch (mission) {
      AsyncData<MissionControle?>(:final MissionControle? value) => _Mission(
        mission: value,
        onCommencer: onCommencer,
      ),
      AsyncError<MissionControle?>() => EtatSysteme(
        nature: NatureEtat.echecServeur,
        phrase: t.controleur.controle.erreur,
        onAction: () => ref.invalidate(missionControleProvider),
      ),
      _ => Semantics(
        label: t.controleur.controle.chargement,
        child: const Skeleton(hauteur: 180),
      ),
    };
    // Le compte rendu commence et non envoye (CT-4, doc 08 CTR-01).
    // Chaque visite a terminer garde son bloc, la plus recente d'abord :
    // aucune n'en remplace une autre (revue CT-R B1).
    final List<CompteRenduEnSuspens> aTerminer = ref
        .watch(compteRenduATerminerProvider)
        .values
        .toList()
        .reversed
        .toList();
    return PageShell(
      titre: t.controleur.controle.titre,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: largeurMax),
          child: ApparitionDouce(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                corps,
                for (final (int i, CompteRenduEnSuspens v)
                    in aTerminer.indexed) ...<Widget>[
                  if (i == 0) Ecart.vXxl else Ecart.vLg,
                  _BlocATerminer(
                    visite: v,
                    cle: i == 0 ? reprendreKey : cleReprendre(v.seanceId),
                    onReprendre: () {
                      final ValueChanged<String>? f = onReprendreCompteRendu;
                      if (f != null) {
                        f(v.seanceId);
                      } else {
                        GoRouter.of(context).go(
                          adresseCompteRendu(
                            Routes.controleurCompteRendu,
                            v.seanceId,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// « Compte rendu a terminer » : la visite dont la reponse n'est pas partie.
class _BlocATerminer extends StatelessWidget {
  const _BlocATerminer({
    required this.visite,
    required this.cle,
    required this.onReprendre,
  });

  final CompteRenduEnSuspens visite;
  final Key cle;
  final VoidCallback onReprendre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      surface: palette.surfaceRaised,
      marge: AppSpacing.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              t.controleur.compteRendu.aTerminer,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vXs,
          Text(
            t.controleur.compteRendu.sousTitre(
              classe: visite.classe,
              heure: heureDeLAppareil(visite.debut),
            ),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          // La visite part sans attendre la reponse (C2) : son etat reste
          // visible ici apres « Plus tard ».
          Ecart.vMd,
          LigneTransmissionVisite(seanceId: visite.seanceId),
          Ecart.vLg,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ActionPrincipale(
              key: cle,
              libelle: t.controleur.compteRendu.reprendre,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              onPress: onReprendre,
            ),
          ),
        ],
      ),
    );
  }
}

class _Mission extends StatelessWidget {
  const _Mission({required this.mission, this.onCommencer});

  final MissionControle? mission;
  final void Function(MissionControle mission)? onCommencer;

  @override
  Widget build(BuildContext context) {
    final MissionControle? m = mission;
    if (m == null) {
      return EmptyState(
        message: t.controleur.controle.vide,
        invitation: t.controleur.controle.videAide,
        registre: RegistreVide.subi,
      );
    }
    if (m.etat == EtatMissionControle.indisponible) {
      // Aucun contenu de la mission ne reste visible (P-CTR-01 point 6,
      // P-CTR-08) : le message generique seul.
      return EmptyState(
        message: t.controleur.controle.indisponible,
        registre: RegistreVide.subi,
      );
    }
    return _CarteMission(mission: m, onCommencer: onCommencer);
  }
}

class _CarteMission extends StatelessWidget {
  const _CarteMission({required this.mission, this.onCommencer});

  final MissionControle mission;
  final void Function(MissionControle mission)? onCommencer;

  bool get _enDirect => mission.etat == EtatMissionControle.enDirect;

  /// CTRL-SALLE-1 : la seance est en direct, mais deja controlee.
  bool get _dejaControlee => mission.etat == EtatMissionControle.dejaControlee;

  void _commencer(BuildContext context) => GoRouter.of(context).go(
    Routes.salle,
    // Le billet passe par `extra`, jamais par l'URL (ADR-005) ; le serveur
    // reste seul juge de l'entree (BR-1).
    extra: BilletSalle(sessionId: mission.seanceId, emisA: DateTime.now()),
  );

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool compact = AppGabarit.de(context) == Gabarit.mobile;
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final TextStyle fort = palette.inkStrong.applyTo(
      textes.titleLarge ?? const TextStyle(),
    );
    final String details = <String>[
      t.controleur.controle.horaire(
        debut: heureDeLAppareil(mission.debut),
        fin: heureDeLAppareil(mission.finPrevue),
      ),
      // DUREE-INSECABLE-1 : la duree prevue n'est jamais scindee.
      LibellesGroupe.insecable(
        t.controleur.controle.duree(minutes: mission.dureePrevue.inMinutes),
      ),
      t.controleur.controle.eleves(n: mission.nombreEleves),
    ].join(' · ');

    return AppCard(
      surface: compact ? palette.surfaceRaised : palette.surfaceMiseEnAvant,
      marge: compact ? AppSpacing.lg : AppSpacing.xxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // COUPE-MOTS-CTRL-1 (revue BENTO-3b-R C7) : le libelle et la
          // pastille partagent la ligne quand elle suffit (pastille au bord
          // de fin) ; sinon la pastille passe dessous. Dans une `Row`, a
          // 320 px et texte x2, la pastille ne laissait au libelle qu'une
          // colonne etroite : « Classe / a obser / ver mai / ntenan / t ».
          // Le libelle passe a la ligne entre les mots, jamais dans un mot.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              Semantics(
                header: true,
                // Decision du directeur C1 = a (27/09), textes revus le
                // 02/10 : un titre pendant le direct, un autre avant.
                child: TexteSansCoupure(
                  _enDirect
                      ? t.controleur.controle.missionEnDirect
                      : t.controleur.controle.mission,
                  style: doux,
                ),
              ),
              // La seance en direct se reconnait au premier coup d'oeil
              // (ON-AIR-1) : le meme composant que partout ailleurs.
              if (_enDirect || _dejaControlee)
                const PastilleEtatSeance(etat: EtatPastilleSeance.enDirect),
            ],
          ),
          Ecart.vSm,
          Text(mission.classeDistincte, style: fort),
          Ecart.vLg,
          // AVATAR-1 : l'enseignant est un couple avatar + nom du composant
          // partage, avec au plus une ligne de role (horaire, duree, effectif).
          AvatarNom.enLigne(
            prenom: mission.enseignant,
            pays: mission.paysEnseignant,
            role: details,
            styleNom: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
            styleRole: doux,
          ),
          Ecart.vLg,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IconTheme(
                data: palette.inkMuted.asIconTheme(size: 18),
                child: Icon(AppIcons.info.resoudre()),
              ),
              Ecart.hSm,
              Expanded(
                child: Text(t.controleur.controle.incognito, style: doux),
              ),
            ],
          ),
          Ecart.vLg,
          // L'emplacement unique (C14) : sa hauteur est reservee dans les deux
          // etats, et seul le changement d'etat s'annonce (UX_REVIEW_08 a).
          Semantics(
            liveRegion: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: _enDirect
                  ? Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: ActionPrincipale(
                        key: ControleControleurPage.commencerKey,
                        libelle: t.controleur.controle.commencer,
                        pleineLargeur: compact,
                        onPress: () {
                          // La visite est copiee a l'entree : apres la
                          // seance, le compte rendu la retrouve par sa
                          // seance, meme si la mission courante a change
                          // (revue CT-R B1).
                          ProviderScope.containerOf(context, listen: false)
                              .read(visitesObserveesProvider.notifier)
                              .noter(CompteRenduEnSuspens.deMission(mission));
                          final void Function(MissionControle)? f = onCommencer;
                          f == null ? _commencer(context) : f(mission);
                        },
                      ),
                    )
                  // CTRL-SALLE-1 : un seul controle a la fois par Classe. Jamais
                  // de bouton grise (K-56) : ce qui se passe, et quoi faire
                  // (K-59). Le serveur refuse de toute facon le second
                  // controle (BR-1).
                  : _dejaControlee
                  ? Column(
                      key: ControleControleurPage.dejaControleeKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          t.controleur.controle.dejaEnCours,
                          style: palette.inkStrong.applyTo(
                            textes.bodyMedium ?? const TextStyle(),
                          ),
                        ),
                        Ecart.vXs,
                        Text(
                          t.controleur.controle.dejaEnCoursAide,
                          style: doux,
                        ),
                      ],
                    )
                  : Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(t.controleur.controle.attente, style: doux),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/icons/app_icons.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_pill.dart';

/// La Session Card : le bloc dominant de l'Espace Groupe.
///
/// Elle porte tout ce qui concerne le prochain rendez-vous, et **rien d'autre**
/// : la date, les deux horloges quand elles different, la duree, l'etat du
/// temps, le bouton d'entree quand la fenetre est ouverte, l'avertissement de
/// changement d'heure quand il y en a un, et le conseil d'appareil.
///
/// Deux regles y sont visibles a l'oeil nu :
///
/// - **aucun compte a rebours negatif** : en prolongation, la carte dit
///   « Cours toujours en cours » et ne montre aucun nombre ;
/// - **aucune conversion de fuseau ici** : les heures arrivent deja rendues,
///   et le libelle de ville est lisible, jamais « UTC+3 ».
class CarteSession extends StatelessWidget {
  /// Cree la Session Card.
  const CarteSession({required this.espace, super.key, this.onRejoindre});

  /// L'Espace Groupe auquel elle appartient.
  final GroupHomeVM espace;

  /// Ce que fait « Rejoindre ». Nul tant qu'Agent Z ne l'a pas branche.
  final VoidCallback? onRejoindre;

  @override
  Widget build(BuildContext context) {
    final SessionClockVM? horloge = espace.horloge;
    final OccurrenceSeance? occurrence = espace.identite.prochaineSeance;

    if (horloge == null || occurrence == null) {
      return AppCard(
        dominante: true,
        child: EmptyState(
          message: LibellesGroupe.aucuneSeance,
          invitation: LibellesGroupe.aucuneSeanceDetail,
          icone: AppIcons.cours,
          registre: RegistreVide.subi,
        ),
      );
    }

    return AppCard(
      dominante: true,
      entete: _EnteteSession(horloge: horloge),
      actions: horloge.rejoindreOuvert
          ? ActionPrincipale(
              libelle: LibellesGroupe.rejoindre,
              onPress: onRejoindre,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _LigneHorloge(
            libelle: LibellesGroupe.votreHeure,
            horloge: horloge.horlogeUtilisateur,
          ),
          if (horloge.horlogeContrepartie != null) ...<Widget>[
            Ecart.vSm,
            _LigneHorloge(
              libelle: _libelleContrepartie(espace),
              horloge: horloge.horlogeContrepartie!,
            ),
          ],
          Ecart.vSm,
          _LigneValeur(
            libelle: LibellesGroupe.dureeLibelle,
            valeur: LibellesGroupe.dureeLisible(occurrence.duree),
          ),
          Ecart.vLg,
          _EtatDuTemps(horloge: horloge),
          if (horloge.noticeDst != null) ...<Widget>[
            Ecart.vLg,
            NoticeChangementHeure(notice: horloge.noticeDst!),
          ],
          if (espace.afficheConseilAppareil) ...<Widget>[
            Ecart.vLg,
            const _ConseilAppareil(),
          ],
        ],
      ),
    );
  }
}

/// Le libelle de la seconde horloge, selon qui regarde.
///
/// L'eleve et le tuteur lisent « Chez Sayyid Youssouf » ; l'enseignant lit
/// « Heure du groupe ». **Le voyage d'un enseignant ne deplace jamais l'horaire
/// institutionnel du groupe** : c'est pour cela que sa contrepartie est le
/// groupe, et non un collegue.
String _libelleContrepartie(GroupHomeVM espace) => espace.estCoteFamille
    ? LibellesGroupe.chezEnseignant(
        LibellesGroupe.enseignantNomme(espace.identite.enseignant),
      )
    : LibellesGroupe.heureGroupe;

/// La date du rendez-vous et l'etat court de la seance.
class _EnteteSession extends StatelessWidget {
  const _EnteteSession({required this.horloge});

  final SessionClockVM horloge;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            horloge.horlogeUtilisateur.dateLocaleRendue,
            style: textes.titleMedium ?? const TextStyle(),
          ),
        ),
        Ecart.hMd,
        StatusPill(
          libelle: LibellesGroupe.phase(horloge.phase),
          ton: switch (horloge.phase) {
            PhaseSeance.enCours ||
            PhaseSeance.prolongee ||
            PhaseSeance.attenteAvantT0 => TonEtat.accent,
            PhaseSeance.salleOuverte => TonEtat.succes,
            PhaseSeance.avantFenetre || PhaseSeance.terminee => TonEtat.neutre,
          },
        ),
      ],
    );
  }
}

/// Une heure deja rendue, avec sa ville.
class _LigneHorloge extends StatelessWidget {
  const _LigneHorloge({required this.libelle, required this.horloge});

  final String libelle;
  final HorlogeAffichee horloge;

  @override
  Widget build(BuildContext context) {
    return _LigneValeur(
      libelle: libelle,
      valeur: LibellesGroupe.heureEtVille(
        heure: horloge.heureLocaleRendue,
        ville: horloge.libelleVille,
      ),
    );
  }
}

/// Un libelle a gauche, une valeur a droite, lus d'un bloc.
class _LigneValeur extends StatelessWidget {
  const _LigneValeur({required this.libelle, required this.valeur});

  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              libelle,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.hMd,
          Flexible(
            child: Text(
              valeur,
              textAlign: TextAlign.end,
              style: textes.titleSmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// La phrase de temps, et l'invariant de presence quand il s'applique.
class _EtatDuTemps extends StatelessWidget {
  const _EtatDuTemps({required this.horloge});

  final SessionClockVM horloge;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            LibellesGroupe.ligneEtat(horloge),
            style: textes.titleMedium ?? const TextStyle(),
          ),
          // Entrer vingt minutes en avance prouve qu'on etait pret ; cela ne
          // credite aucune minute de presence academique. On le dit a la
          // personne plutot que de le laisser deviner.
          if (horloge.phase == PhaseSeance.attenteAvantT0) ...<Widget>[
            Ecart.vXs,
            Text(
              LibellesGroupe.attenteAvantDebutDetail,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// L'avertissement de changement d'heure.
///
/// **Le widget ne calcule rien.** Il recoit deux heures deja rendues et une
/// echeance ; il n'ouvre aucune base de fuseaux, ne compare aucun offset et ne
/// connait pas la date de transition. C'est `SessionClockVM` qui l'apporte, et
/// le serveur qui la determine.
class NoticeChangementHeure extends StatelessWidget {
  /// Cree la notice.
  const NoticeChangementHeure({required this.notice, super.key});

  /// Ce que le port a rendu.
  final NoticeDst notice;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    // Une notice dont les deux heures coincident n'annonce rien : la transition
    // existe, mais elle ne deplace pas ce cours-la.
    if (!notice.deplaceLHeure) {
      return const SizedBox.shrink();
    }

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          StatusPill(
            libelle: LibellesGroupe.dstEcheance(notice.echeance),
            ton: TonEtat.avertissement,
          ),
          Ecart.vXs,
          Text(
            LibellesGroupe.dstDetail(
              avant: notice.heureAvantRendue,
              apres: notice.heureApresRendue,
            ),
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le conseil d'appareil, discret.
///
/// **Pas de fenetre modale, pas de blocage, aucun jugement.** Une ligne, au bas
/// de la Session Card, que l'on peut ignorer sans consequence.
class _ConseilAppareil extends StatelessWidget {
  const _ConseilAppareil();

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconTheme(
            data: IconThemeData(
              color: palette.inkMuted.applyTo(const TextStyle()).color,
              size: AppSpacing.xl,
            ),
            // TC-ICONE: un pictogramme « tablette ou ordinateur » manque au
            // catalogue. `appareil` est le plus proche et sert de placeholder.
            child: Icon(AppIcons.appareil.repos),
          ),
          Ecart.hSm,
          Expanded(
            child: Text(
              LibellesGroupe.conseilAppareil,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

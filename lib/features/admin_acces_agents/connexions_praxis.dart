import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agent/service_autorisation_praxis.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../mfa_controleur/double_verification.dart';
import 'section_praxis.dart' show FeuilleRevocationPraxis;

/// Les cles des widgets de la liste, pour les tests.
abstract final class ClesConnexionsPraxis {
  /// Le bloc d'une page hors ligne qui ne peut rien afficher.
  static const Key sansDonnees = ValueKey<String>(
    'connexions-praxis-sans-donnees',
  );

  /// Le message d'erreur d'une revocation.
  static const Key erreur = ValueKey<String>('connexions-praxis-erreur');
}

/// PX-OAUTH 2e : les connexions des applications (claude.ai) a Praxis, **une
/// ligne par connexion** (jamais une par cle d'une heure), chacune revocable.
/// Couper une connexion arrete aussi toutes ses cles et son renouvellement :
/// l'application ne se reconnecte pas seule. Le geste est sensible : il attend
/// le serveur, avec la double verification, et la liste est relue ensuite.
class ConnexionsPraxis extends ConsumerStatefulWidget {
  /// Cree la liste.
  const ConnexionsPraxis({super.key});

  @override
  ConsumerState<ConnexionsPraxis> createState() => _ConnexionsPraxisEtat();
}

class _ConnexionsPraxisEtat extends ConsumerState<ConnexionsPraxis> {
  String? _message;
  String? _erreur;

  void _relire() => ref.invalidate(connexionsPraxisProvider);

  Future<void> _revoquer(ConnexionPraxis connexion) async {
    final String? motif = await AppBottomSheet.ouvrir<String>(
      context,
      titre: t.admin.praxis.connexions.revoquerTitre,
      constructeur: (BuildContext contexte) => FeuilleRevocationPraxis(
        detail: t.admin.praxis.connexions.revoquerDetail,
        confirmer: t.admin.praxis.connexions.revoquerConfirmer,
        onConfirmer: (String m) => Navigator.of(contexte).pop(m),
      ),
    );
    if (motif == null || !mounted) return;
    String? message;
    String? erreur;
    try {
      await avecDoubleVerification<bool>(
        context,
        ref,
        () => ref
            .read(serviceAutorisationPraxisProvider)
            .revoquerConnexion(id: connexion.id, motif: motif),
      );
      message = t.admin.praxis.connexions.revoquee;
    } on Object catch (e) {
      erreur = estRefusDeDroit(e)
          ? t.admin.praxis.doubleVerification
          : t.admin.praxis.connexions.erreurRevocation;
    }
    // Dans tous les cas la liste est relue : une reponse perdue ne laisse pas
    // l'ecran dire autre chose que la base.
    _relire();
    if (!mounted) return;
    setState(() {
      _message = message;
      _erreur = erreur;
    });
  }

  // HEURES-PROFIL H2 : a l'heure du profil.
  String _quand(DateTime instant) {
    final DateTime date = chezMoi(instant);
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')} '
        '${heureChezMoi(instant)}';
  }

  String _nomEtat(EtatConnexionPraxis etat) => switch (etat) {
    EtatConnexionPraxis.active => t.admin.praxis.etatActive,
    EtatConnexionPraxis.revoquee => t.admin.praxis.etatRevoquee,
    EtatConnexionPraxis.expiree => t.admin.praxis.etatExpiree,
  };

  TonEtat _ton(EtatConnexionPraxis etat) => switch (etat) {
    EtatConnexionPraxis.active => TonEtat.succes,
    EtatConnexionPraxis.revoquee => TonEtat.alerte,
    EtatConnexionPraxis.expiree => TonEtat.neutre,
  };

  @override
  Widget build(BuildContext context) {
    ref.watch(monHorlogeProvider);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<List<ConnexionPraxis>> lecture = lectureHorsLigne(
      ref.watch(connexionsPraxisProvider),
      horsLigne: horsLigne,
    );
    final Widget corps = sansDonneesHorsLigne(lecture, horsLigne: horsLigne)
        ? EtatSansDonnees(
            key: ClesConnexionsPraxis.sansDonnees,
            quoi: t.admin.praxis.connexions.sansDonnees,
            onAction: _relire,
          )
        : BlocAsynchrone<List<ConnexionPraxis>>(
            valeur: lecture,
            squelette: const Skeleton.liste(),
            onReessayer: _relire,
            titreEchec: t.admin.praxis.connexions.erreurLecture,
            estVide: (List<ConnexionPraxis> l) => l.isEmpty,
            vide: EmptyState(
              message: t.admin.praxis.connexions.vide,
              invitation: t.admin.praxis.connexions.videDetail,
              icone: AppIcons.rienAAfficher,
              registre: RegistreVide.bonneNouvelle,
            ),
            construire: _liste,
          );
    final int compte = lecture.value?.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.admin.praxis.connexions.titre, compteur: compte),
        Ecart.vSm,
        Text(t.admin.praxis.connexions.intro, style: textes.bodyMedium),
        Ecart.vLg,
        LocalFeedback(message: _message),
        if (_erreur != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              _erreur!,
              key: ClesConnexionsPraxis.erreur,
              style: textes.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          Ecart.vLg,
        ],
        corps,
      ],
    );
  }

  Widget _liste(List<ConnexionPraxis> connexions) {
    return DataCollection<ConnexionPraxis>(
      // Une section d'une page qui defile deja : la liste est la page.
      defileSeule: false,
      defileAvecLaPage: true,
      lignes: connexions,
      colonnes: <ColonneDonnees<ConnexionPraxis>>[
        ColonneDonnees<ConnexionPraxis>(
          titre: t.admin.praxis.connexions.colonneClient,
          role: RoleColonne.identifiante,
          flex: 2,
          texte: (ConnexionPraxis c) => isolerSens(c.client),
        ),
        ColonneDonnees<ConnexionPraxis>(
          titre: t.admin.praxis.connexions.colonneAutorisee,
          tabulaire: true,
          texte: (ConnexionPraxis c) => _quand(c.creeLe),
        ),
        ColonneDonnees<ConnexionPraxis>(
          titre: t.admin.praxis.colonneUtilisee,
          tabulaire: true,
          texte: (ConnexionPraxis c) => c.derniereUtilisationLe == null
              ? t.admin.praxis.jamaisUtilisee
              : _quand(c.derniereUtilisationLe!),
        ),
        ColonneDonnees<ConnexionPraxis>(
          titre: t.admin.praxis.connexions.colonneFin,
          tabulaire: true,
          texte: (ConnexionPraxis c) => _quand(c.expireLe),
        ),
        ColonneDonnees<ConnexionPraxis>(
          titre: t.admin.praxis.colonneEtat,
          flex: 2,
          texte: (ConnexionPraxis c) => _nomEtat(c.etat),
          rendu: (BuildContext _, ConnexionPraxis c) =>
              StatusPill(libelle: _nomEtat(c.etat), ton: _ton(c.etat)),
        ),
        // L'action d'une ligne vit dans sa propre colonne (LISTES-1), rendue
        // seulement quand elle peut aboutir (une connexion active).
        ColonneDonnees<ConnexionPraxis>(
          titre: t.commun.listes.actions,
          flex: 2,
          action: true,
          texte: (ConnexionPraxis c) => c.etat == EtatConnexionPraxis.active
              ? t.admin.praxis.revoquer
              : '',
          rendu: (BuildContext _, ConnexionPraxis c) =>
              c.etat != EtatConnexionPraxis.active
              ? const SizedBox.shrink()
              : ActionPrincipale(
                  libelle: t.admin.praxis.revoquer,
                  niveau: NiveauAction.destructive,
                  compacte: true,
                  pleineLargeur: false,
                  onPress: () => unawaited(_revoquer(c)),
                ),
        ),
      ],
    );
  }
}

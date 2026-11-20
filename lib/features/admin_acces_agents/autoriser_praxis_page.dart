import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/agent/aller_adresse.dart';
import '../../core/agent/service_autorisation_praxis.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../mfa_controleur/double_verification.dart';

/// Les cles des widgets de la page, pour les tests.
abstract final class ClesAutoriserPraxis {
  /// La carte de la demande.
  static const Key carte = ValueKey<String>('autoriser-praxis-carte');

  /// « Autoriser » : le seul bouton plein.
  static const Key autoriser = ValueKey<String>('autoriser-praxis-autoriser');

  /// « Refuser » : un lien, jamais un gros bouton.
  static const Key refuser = ValueKey<String>('autoriser-praxis-refuser');

  /// Le lien vers « Accès des agents ».
  static const Key versAcces = ValueKey<String>('autoriser-praxis-acces');

  /// Le bloc d'une page hors ligne qui ne peut rien afficher.
  static const Key sansDonnees = ValueKey<String>(
    'autoriser-praxis-sans-donnees',
  );
}

/// Les retours que la page accepte d'ouvrir : l'adresse de rappel de claude.ai
/// seulement. La base ne rend que celles de sa liste blanche ; cette barriere
/// est la seconde, au cas ou une reponse serait alteree en route.
final RegExp _retourAccepte = RegExp(
  r'^https://claude\.ai/api/mcp/auth_callback\?(code=[0-9a-f]{64}|error=access_denied)(&state=[A-Za-z0-9._~%-]*)?$',
);

/// PX-OAUTH 2d : la page de consentement. Claude (claude.ai) demande a se
/// connecter a Praxis ; la direction autorise ou refuse. **Une seule tache,
/// un seul bouton plein** : « Autoriser ». Le client et ce qu'il pourra faire
/// sont ecrits en clair avant la decision. La decision est un geste sensible
/// (elle donne un acces) : elle attend le serveur, avec la double
/// verification, et ne s'affiche jamais comme faite avant qu'il l'ait dit.
class AutoriserPraxisPage extends ConsumerStatefulWidget {
  /// Cree la page de la demande [demande] (l'identifiant lu dans l'adresse).
  const AutoriserPraxisPage({required this.demande, super.key});

  /// L'identifiant de la demande ; vide ou mal forme : « inconnue ».
  final String demande;

  @override
  ConsumerState<AutoriserPraxisPage> createState() =>
      _AutoriserPraxisPageEtat();
}

enum _Issue { autorisee, refusee }

class _AutoriserPraxisPageEtat extends ConsumerState<AutoriserPraxisPage> {
  static final RegExp _forme = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );

  /// `autoriser`, `refuser` ou nul : le geste en attente de la reponse.
  String? _enCours;
  String? _erreur;
  _Issue? _issue;

  bool get _valide => _forme.hasMatch(widget.demande);

  void _relire() =>
      ref.invalidate(demandeAutorisationPraxisProvider(widget.demande));

  Future<void> _decider({required bool accepter}) async {
    if (_enCours != null) return;
    setState(() {
      _enCours = accepter ? 'autoriser' : 'refuser';
      _erreur = null;
    });
    String? erreur;
    DecisionAutorisationPraxis? decision;
    try {
      decision = await avecDoubleVerification<DecisionAutorisationPraxis>(
        context,
        ref,
        () => ref
            .read(serviceAutorisationPraxisProvider)
            .decider(widget.demande, accepter: accepter),
      );
    } on Object catch (e) {
      erreur = estRefusDeDroit(e)
          ? t.admin.praxis.doubleVerification
          : t.admin.praxis.autoriser.erreurDecision;
    }
    if (!mounted) return;
    final String? cause = decision?.erreur;
    final String? retour = decision?.redirection;
    if (erreur == null && cause != null) {
      erreur = switch (cause) {
        'sans_cote' => t.admin.praxis.autoriser.sansCote,
        'deja_decidee' => t.admin.praxis.autoriser.dejaDecidee,
        'expiree' => t.admin.praxis.autoriser.expiree,
        'inconnue' => t.admin.praxis.autoriser.inconnue,
        _ => t.admin.praxis.autoriser.erreurDecision,
      };
    } else if (erreur == null &&
        (retour == null || !_retourAccepte.hasMatch(retour))) {
      // Une reponse sans retour sur, jamais une decision annoncee comme faite.
      erreur = t.admin.praxis.autoriser.erreurDecision;
    }
    setState(() {
      _enCours = null;
      _erreur = erreur;
      _issue = erreur == null
          ? (accepter ? _Issue.autorisee : _Issue.refusee)
          : null;
    });
    if (erreur == null && retour != null) {
      ref.read(allerAdresseProvider)(retour);
    } else {
      // Une decision perdue ne laisse pas l'ecran dire autre chose que la base.
      _relire();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<DemandeAutorisationPraxis> lecture = _valide
        ? lectureHorsLigne(
            ref.watch(demandeAutorisationPraxisProvider(widget.demande)),
            horsLigne: horsLigne,
          )
        : const AsyncData<DemandeAutorisationPraxis>(
            DemandeAutorisationPraxis(etat: EtatDemandePraxis.inconnue),
          );
    final Widget corps = sansDonneesHorsLigne(lecture, horsLigne: horsLigne)
        ? EtatSansDonnees(
            key: ClesAutoriserPraxis.sansDonnees,
            quoi: t.admin.praxis.autoriser.sansDonnees,
            onAction: _relire,
          )
        : BlocAsynchrone<DemandeAutorisationPraxis>(
            valeur: lecture,
            squelette: const Skeleton.texte(lignes: 5),
            onReessayer: _relire,
            titreEchec: t.admin.praxis.autoriser.erreurLecture,
            construire: _contenu,
          );
    return PageShell(
      titre: t.admin.praxis.autoriser.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LocalFeedback(message: _erreur),
          corps,
        ],
      ),
    );
  }

  Widget _contenu(DemandeAutorisationPraxis demande) {
    if (_issue != null) return _Termine(issue: _issue!, hote: demande.hote);
    return switch (demande.etat) {
      EtatDemandePraxis.inconnue => _Clos(
        message: t.admin.praxis.autoriser.inconnue,
        detail: t.admin.praxis.autoriser.inconnueDetail,
      ),
      EtatDemandePraxis.decidee => _Clos(
        message: t.admin.praxis.autoriser.dejaDecidee,
        detail: t.admin.praxis.autoriser.dejaDecideeDetail,
      ),
      EtatDemandePraxis.expiree => _Clos(
        message: t.admin.praxis.autoriser.expiree,
        detail: t.admin.praxis.autoriser.expireeDetail,
      ),
      EtatDemandePraxis.enAttente => _Demande(
        demande: demande,
        enCours: _enCours,
        onAutoriser: () => unawaited(_decider(accepter: true)),
        onRefuser: () => unawaited(_decider(accepter: false)),
      ),
    };
  }
}

/// La demande en attente : qui demande, ce qu'il pourra, la duree, la decision.
class _Demande extends StatelessWidget {
  const _Demande({
    required this.demande,
    required this.enCours,
    required this.onAutoriser,
    required this.onRefuser,
  });

  final DemandeAutorisationPraxis demande;
  final String? enCours;
  final VoidCallback onAutoriser;
  final VoidCallback onRefuser;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final String client = isolerSens(
      (demande.client ?? '').isEmpty
          ? t.admin.praxis.autoriser.clientInconnu
          : demande.client!,
    );
    final String hote = isolerSens(demande.hote ?? '');
    final bool occupe = enCours != null;
    return AppCard(
      key: ClesAutoriserPraxis.carte,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            hote.isEmpty
                ? t.admin.praxis.autoriser.demandeSansHote(client: client)
                : t.admin.praxis.autoriser.demande(client: client, hote: hote),
            style: textes.titleMedium,
          ),
          Ecart.vLg,
          Text(t.admin.praxis.pourra, style: textes.titleSmall),
          Ecart.vXs,
          Text(t.admin.praxis.pourraDetail, style: textes.bodyMedium),
          Ecart.vLg,
          Text(t.admin.praxis.nePourraPas, style: textes.titleSmall),
          Ecart.vXs,
          Text(t.admin.praxis.nePourraPasDetail, style: textes.bodyMedium),
          Ecart.vLg,
          Text(t.admin.praxis.autoriser.duree, style: textes.bodyMedium),
          if (!demande.peutAutoriser) ...<Widget>[
            Ecart.vLg,
            Text(t.admin.praxis.autoriser.sansCote, style: textes.bodyMedium),
          ],
          Ecart.vXl,
          if (demande.peutAutoriser)
            // Au telephone le bouton prend la largeur de la carte ; au bureau,
            // sa largeur propre, au bord de fin (DESIGN-GOV §4 bis).
            LayoutBuilder(
              builder: (BuildContext contexte, BoxConstraints contraintes) {
                final bool etroit =
                    contraintes.maxWidth <
                    480 * MediaQuery.textScalerOf(contexte).scale(1);
                final Widget bouton = ActionPrincipale(
                  key: ClesAutoriserPraxis.autoriser,
                  libelle: t.admin.praxis.autoriser.autoriser,
                  pleineLargeur: etroit,
                  enCours: enCours == 'autoriser',
                  onPress: occupe ? () {} : onAutoriser,
                );
                return etroit
                    ? bouton
                    : Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: bouton,
                      );
              },
            ),
          if (demande.peutAutoriser) Ecart.vLg,
          LayoutBuilder(
            builder: (BuildContext contexte, BoxConstraints contraintes) {
              final bool etroit =
                  contraintes.maxWidth <
                  480 * MediaQuery.textScalerOf(contexte).scale(1);
              final Widget lien = LienFleche(
                key: ClesAutoriserPraxis.refuser,
                libelle: t.admin.praxis.autoriser.refuser,
                onPress: occupe ? () {} : onRefuser,
              );
              return etroit
                  ? lien
                  : Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: lien,
                    );
            },
          ),
        ],
      ),
    );
  }
}

/// Une demande qui ne s'ouvre plus (deja traitee, expiree) : la phrase vraie,
/// et le chemin vers « Accès des agents ».
class _Clos extends StatelessWidget {
  const _Clos({required this.message, required this.detail});

  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      EmptyState(
        message: message,
        invitation: detail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      ),
      Ecart.vLg,
      const _LienAcces(),
    ],
  );
}

/// Apres la decision : la phrase vraie. Le navigateur est deja renvoye vers le
/// client ; ce bloc reste si le renvoi tarde ou n'a pas lieu.
class _Termine extends StatelessWidget {
  const _Termine({required this.issue, required this.hote});

  final _Issue issue;
  final String? hote;

  @override
  Widget build(BuildContext context) {
    final bool autorisee = issue == _Issue.autorisee;
    final String lieu = isolerSens((hote ?? '').isEmpty ? '' : hote!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EmptyState(
          message: autorisee
              ? t.admin.praxis.autoriser.termineAutorisee
              : t.admin.praxis.autoriser.termineRefusee,
          invitation: autorisee
              ? (lieu.isEmpty
                    ? t.admin.praxis.autoriser.termineAutoriseeDetailSansHote
                    : t.admin.praxis.autoriser.termineAutoriseeDetail(
                        hote: lieu,
                      ))
              : t.admin.praxis.autoriser.termineRefuseeDetail,
          icone: autorisee ? AppIcons.succes : AppIcons.rienAAfficher,
          registre: RegistreVide.subi,
        ),
        Ecart.vLg,
        const _LienAcces(),
      ],
    );
  }
}

class _LienAcces extends StatelessWidget {
  const _LienAcces();

  @override
  Widget build(BuildContext context) => LienFleche(
    key: ClesAutoriserPraxis.versAcces,
    libelle: t.admin.praxis.autoriser.versAcces,
    onPress: () => context.go(Routes.adminSecuriteAuditAccesAgents),
  );
}

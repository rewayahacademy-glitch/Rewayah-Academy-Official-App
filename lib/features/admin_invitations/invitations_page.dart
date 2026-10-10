/// RECRUT-ECRANS (1/5) : « Inviter un enseignant », cote administration.
///
/// L'administration saisit une adresse e-mail, le serveur cree un code a usage
/// unique avec une echeance ; la liste dit l'etat de chaque invitation et
/// permet de revoquer une invitation active (contrat C-13). Un enseignant ne
/// s'inscrit qu'avec un code valide : seule la direction emet une invitation.
///
/// L'ecran lit une capacite, jamais un role : le formulaire n'existe que si le
/// port d'invitation est present, et chaque revocation n'est offerte que sur
/// une invitation que le serveur dit active. Aucun code n'est calcule ici.
///
/// Etats : chargement (`Skeleton` dans `BlocAsynchrone`), contenu, vide
/// (`EmptyState`), erreur (`EtatSysteme`, « Reessayer »), hors ligne (bandeau
/// de `PageShell`, `EtatSansDonnees` quand rien n'a pu etre lu), port absent.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/recrutement/port_invitations_enseignant.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/zone_saisie.dart';
import '../salle_seance/information_controle.dart' show coupuresAdresse;

/// Le ton de la pastille d'un etat (jamais la couleur seule : le mot reste).
TonEtat tonInvitation(EtatInvitation etat) => switch (etat) {
  EtatInvitation.active => TonEtat.accent,
  EtatInvitation.utilisee => TonEtat.succes,
  EtatInvitation.expiree => TonEtat.avertissement,
  EtatInvitation.revoquee => TonEtat.neutre,
};

/// Le mot d'un etat.
String libelleEtatInvitation(EtatInvitation etat) => switch (etat) {
  EtatInvitation.active => t.recrutement.invitations.etat.active,
  EtatInvitation.utilisee => t.recrutement.invitations.etat.utilisee,
  EtatInvitation.expiree => t.recrutement.invitations.etat.expiree,
  EtatInvitation.revoquee => t.recrutement.invitations.etat.revoquee,
};

/// L'ecran « Inviter un enseignant ».
class InvitationsPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const InvitationsPage({super.key});

  @override
  ConsumerState<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends ConsumerState<InvitationsPage> {
  final TextEditingController _email = TextEditingController();
  bool _envoi = false;
  String? _erreur;
  String? _succes;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _inviter(PortInvitationsEnseignant port) async {
    final r = t.recrutement.invitations;
    setState(() {
      _envoi = true;
      _erreur = null;
      _succes = null;
    });
    String? erreur;
    String? succes;
    try {
      final Invitation inv = await port.inviter(_email.text.trim());
      succes = r.creee(code: inv.code);
      _email.clear();
    } on ErreurInvitation catch (e) {
      erreur = switch (e) {
        EmailInvalide() => r.emailInvalide,
        DejaInvite() => r.dejaInvite,
        CompteExistant() => r.compteExistant,
        NonAutorise() => r.nonAutorise,
        HorsLigne() => r.horsLigne,
      };
    } on Object {
      erreur = r.erreur;
    }
    // Dans tous les cas la liste est relue : une creation dont la reponse
    // s'est perdue doit y apparaitre (D5 : « non confirme », pas « non envoye »).
    ref.invalidate(invitationsEnseignantProvider);
    if (!mounted) return;
    setState(() {
      _envoi = false;
      _erreur = erreur;
      _succes = succes;
    });
  }

  Future<void> _revoquer(PortInvitationsEnseignant port, Invitation i) async {
    final r = t.recrutement.invitations;
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: r.revoquerQuestion(email: i.email),
      consequence: r.revoquerConsequence,
      libelleConfirmer: r.revoquer,
    );
    if (!oui || !mounted) return;
    try {
      await port.revoquer(i.code);
      setState(() => _erreur = null);
    } on Object {
      if (mounted) setState(() => _erreur = r.revoquerEchec);
    }
    ref.invalidate(invitationsEnseignantProvider);
  }

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.invitations;
    final PortInvitationsEnseignant? port = ref.watch(
      portInvitationsEnseignantProvider,
    );
    final AsyncValue<List<Invitation>> valeur = ref.watch(
      invitationsEnseignantProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return PageShell(
      titre: r.titre,
      sousTitre: r.sousTitre,
      entete: SousNavigationDomaine(onglets: ongletsPersonnes(), indexActif: 2),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: port == null
              ? EtatSysteme(
                  key: const ValueKey<String>('invitations-indisponible'),
                  nature: NatureEtat.indisponible,
                  titre: r.indisponibleTitre,
                  phrase: r.indisponiblePhrase,
                  dependance: dependanceInvitations,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ZoneSaisie(
                      controleur: _email,
                      cleChamp: const ValueKey<String>('invitations-email'),
                      libelle: r.champEmail,
                      aide: r.aideEmail,
                      majuscules: TextCapitalization.none,
                      actionClavier: TextInputAction.done,
                      onSubmitted: (_) => unawaited(_inviter(port)),
                    ),
                    Ecart.vMd,
                    if (_erreur != null || _succes != null)
                      Semantics(
                        liveRegion: true,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            _erreur ?? _succes!,
                            key: ValueKey<String>(
                              _erreur != null
                                  ? 'invitations-erreur'
                                  : 'invitations-succes',
                            ),
                            style:
                                (_erreur != null
                                        ? palette.inkAlert
                                        : palette.inkMuted)
                                    .applyTo(
                                      textes.bodyMedium ?? const TextStyle(),
                                    ),
                          ),
                        ),
                      ),
                    ActionPrincipale(
                      key: const ValueKey<String>('invitations-inviter'),
                      libelle: r.inviter,
                      enCours: _envoi,
                      onPress: _envoi ? null : () => unawaited(_inviter(port)),
                    ),
                    Ecart.vSection,
                    BlocAsynchrone<List<Invitation>>(
                      key: const ValueKey<String>('invitations-bloc'),
                      valeur: valeur,
                      squelette: const Skeleton.liste(lignes: 3),
                      onReessayer: () =>
                          ref.invalidate(invitationsEnseignantProvider),
                      vide: EmptyState(
                        key: const ValueKey<String>('invitations-vide'),
                        message: r.vide,
                        invitation: r.videDetail,
                        icone: AppIcons.invitationEnvoyee,
                      ),
                      erreurVersEtat: (Object e, VoidCallback? reessayer) {
                        if (e is CapaciteIndisponible) {
                          return EtatSysteme(
                            key: const ValueKey<String>(
                              'invitations-indisponible',
                            ),
                            nature: NatureEtat.indisponible,
                            titre: r.indisponibleTitre,
                            phrase: r.indisponiblePhrase,
                            dependance: e.dependance,
                          );
                        }
                        return horsLigne
                            ? EtatSansDonnees(
                                key: const ValueKey<String>(
                                  'invitations-sans-donnees',
                                ),
                                quoi: r.sansDonnees,
                                onAction: reessayer,
                              )
                            : EtatSysteme(
                                key: const ValueKey<String>(
                                  'invitations-erreur-liste',
                                ),
                                nature: NatureEtat.echecServeur,
                                phrase: r.erreurListe,
                                onAction: reessayer,
                              );
                      },
                      construire: (List<Invitation> lues) => GroupeReglages(
                        titre: r.liste,
                        lignes: <LigneRubrique>[
                          for (final Invitation i in lues)
                            _ligne(i, port, horsLigne),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  LigneRubrique _ligne(
    Invitation i,
    PortInvitationsEnseignant port,
    bool horsLigne,
  ) {
    final r = t.recrutement.invitations;
    final String quand = switch (i.etat) {
      EtatInvitation.utilisee when i.utiliseeLe != null => r.utiliseeLe(
        date: dateDeLAppareil(i.utiliseeLe!.toLocal()),
      ),
      _ => r.expireLe(date: dateDeLAppareil(i.expireLe.toLocal())),
    };
    return LigneRubrique(
      icone: AppIcons.invitationEnvoyee,
      libelle: coupuresAdresse(i.email),
      legende: '${i.code} · $quand',
      pastille: StatusPill(
        libelle: libelleEtatInvitation(i.etat),
        ton: tonInvitation(i.etat),
      ),
      // Revoquer n'existe que sur une invitation active et en ligne : un
      // bouton qui ne peut pas aboutir n'est pas rendu.
      controle: i.etat == EtatInvitation.active && !horsLigne
          ? ActionPrincipale(
              key: ValueKey<String>('invitation-revoquer-${i.code}'),
              libelle: r.revoquer,
              libelleSemantique: r.revoquerPour(email: i.email),
              niveau: NiveauAction.destructive,
              pleineLargeur: false,
              onPress: () => unawaited(_revoquer(port, i)),
            )
          : null,
    );
  }
}

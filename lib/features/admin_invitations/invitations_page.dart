/// RECRUT-ECRANS (1/5) : « Inviter un enseignant », cote administration.
/// Lot F2 : la meme page invite aussi un comptable (BF1-03).
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
/// Quand les deux ports sont servis, deux cartes disent qui l'on invite
/// (enseignant ou comptable), chacune avec son explication ; la liste et la
/// revocation suivent la carte retenue. Le serveur exige la direction en
/// double verification pour un comptable : son refus se dit tel quel.
///
/// Etats : chargement (`Skeleton` dans `BlocAsynchrone`), contenu, vide
/// (`EmptyState`), erreur (`EtatSysteme`, « Reessayer »), hors ligne (bandeau
/// de `PageShell`, `EtatSansDonnees` quand rien n'a pu etre lu), port absent.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/recrutement/port_invitations_comptable.dart';
import '../../core/recrutement/port_invitations_enseignant.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
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

/// La personne que l'on invite.
enum RoleInvite {
  /// Un enseignant (RECRUT-ECRANS).
  enseignant,

  /// Un comptable (BF1-03).
  comptable,
}

/// L'ecran « Inviter un enseignant » (ou un comptable).
class InvitationsPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const InvitationsPage({super.key});

  @override
  ConsumerState<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends ConsumerState<InvitationsPage> {
  final TextEditingController _email = TextEditingController();
  RoleInvite? _role;
  bool _envoi = false;
  String? _erreur;
  String? _succes;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  FutureProvider<List<Invitation>> _liste(RoleInvite role) => switch (role) {
    RoleInvite.enseignant => invitationsEnseignantProvider,
    RoleInvite.comptable => invitationsComptableProvider,
  };

  void _choisir(RoleInvite role) {
    if (role == _role) return;
    _email.clear();
    setState(() {
      _role = role;
      _erreur = null;
      _succes = null;
    });
  }

  Future<void> _inviter(PortInvitationsEnseignant port, RoleInvite role) async {
    final r = t.recrutement.invitations;
    final bool comptable = role == RoleInvite.comptable;
    setState(() {
      _envoi = true;
      _erreur = null;
      _succes = null;
    });
    String? erreur;
    String? succes;
    try {
      final Invitation inv = await port.inviter(_email.text.trim());
      succes = comptable
          ? r.comptable.creee(code: inv.code)
          : r.creee(code: inv.code);
      _email.clear();
    } on ErreurInvitation catch (e) {
      erreur = switch (e) {
        EmailInvalide() => r.emailInvalide,
        DejaInvite() => r.dejaInvite,
        CompteExistant() => r.compteExistant,
        // Le serveur exige la direction en double verification (aal2) pour
        // un comptable : le refus le dit, avec quoi faire.
        NonAutorise() =>
          comptable ? r.comptable.doubleVerification : r.nonAutorise,
        HorsLigne() => r.horsLigne,
      };
    } on Object {
      erreur = r.erreur;
    }
    // Dans tous les cas la liste est relue : une creation dont la reponse
    // s'est perdue doit y apparaitre (D5 : « non confirme », pas « non envoye »).
    ref.invalidate(_liste(role));
    if (!mounted) return;
    setState(() {
      _envoi = false;
      _erreur = erreur;
      _succes = succes;
    });
  }

  Future<void> _revoquer(
    PortInvitationsEnseignant port,
    RoleInvite role,
    Invitation i,
  ) async {
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
      if (mounted) setState(() => _erreur = null);
    } on NonAutorise {
      if (mounted) {
        setState(
          () => _erreur = role == RoleInvite.comptable
              ? r.comptable.doubleVerification
              : r.nonAutorise,
        );
      }
    } on Object {
      if (mounted) setState(() => _erreur = r.revoquerEchec);
    }
    ref.invalidate(_liste(role));
  }

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.invitations;
    // Chaque carte n'existe que si son port est servi : on lit la capacite,
    // jamais un role.
    final PortInvitationsEnseignant? portEnseignant = ref.watch(
      portInvitationsEnseignantProvider,
    );
    final PortInvitationsEnseignant? portComptable = ref.watch(
      portInvitationsComptableProvider,
    );
    final List<RoleInvite> roles = <RoleInvite>[
      if (portEnseignant != null) RoleInvite.enseignant,
      if (portComptable != null) RoleInvite.comptable,
    ];
    final RoleInvite? role = roles.isEmpty
        ? null
        : roles.contains(_role)
        ? _role
        : roles.first;
    final PortInvitationsEnseignant? port = switch (role) {
      RoleInvite.enseignant => portEnseignant,
      RoleInvite.comptable => portComptable,
      null => null,
    };
    final bool avecComptable = roles.contains(RoleInvite.comptable);

    return PageShell(
      titre: avecComptable ? r.comptable.titrePage : r.titre,
      sousTitre: avecComptable ? r.comptable.sousTitrePage : r.sousTitre,
      // ADM-20 : l'onglet Invitations a cede son rang aux Candidatures. Cette
      // page reste atteignable par un lien de la file (CAND-F01) ; elle n'a
      // plus d'onglet. Le retour de la coquille d'administration (vers
      // l'Accueil) reste celui de toutes les pages de Personnes.
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: port == null || role == null
              ? EtatSysteme(
                  key: const ValueKey<String>('invitations-indisponible'),
                  nature: NatureEtat.indisponible,
                  titre: r.indisponibleTitre,
                  phrase: r.indisponiblePhrase,
                  dependance: dependanceInvitations,
                )
              : _corps(port, role, roles),
        ),
      ),
    );
  }

  Widget _corps(
    PortInvitationsEnseignant port,
    RoleInvite role,
    List<RoleInvite> roles,
  ) {
    final r = t.recrutement.invitations;
    final bool comptable = role == RoleInvite.comptable;
    final AsyncValue<List<Invitation>> valeur = ref.watch(_liste(role));
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (roles.length > 1) ...<Widget>[
          Text(r.comptable.choixQuestion, style: textes.titleMedium),
          Ecart.vMd,
          // Toute la carte se touche ; deux cartes differentes (icone,
          // illustration, explication), jamais de saisie libre.
          ChoiceCardGroup(
            key: const ValueKey<String>('invitations-role'),
            autoriserSaisieLibre: false,
            valeurInitiale: ReponseChoix(valeurs: <String>{role.name}),
            options: <OptionChoix>[
              OptionChoix(
                cle: const ValueKey<String>('invitations-role-enseignant'),
                valeur: RoleInvite.enseignant.name,
                libelle: r.comptable.enseignantTitre,
                explication: r.comptable.enseignantExplication,
                icone: AppIcons.cours,
                illustration: const IllustrationChoix(
                  AppIcons.cours,
                  autour: <AppIcon>[AppIcons.classes, AppIcons.livreOuvert],
                ),
              ),
              OptionChoix(
                cle: const ValueKey<String>('invitations-role-comptable'),
                valeur: RoleInvite.comptable.name,
                libelle: r.comptable.comptableTitre,
                explication: r.comptable.comptableExplication,
                icone: AppIcons.paiements,
                illustration: const IllustrationChoix(
                  AppIcons.paiements,
                  autour: <AppIcon>[
                    AppIcons.encaissement,
                    AppIcons.rapprochement,
                  ],
                ),
              ),
            ],
            onChange: (ReponseChoix reponse) {
              for (final RoleInvite x in RoleInvite.values) {
                if (reponse.valeurs.contains(x.name)) _choisir(x);
              }
            },
          ),
          Ecart.vSection,
        ],
        ZoneSaisie(
          controleur: _email,
          cleChamp: const ValueKey<String>('invitations-email'),
          libelle: comptable ? r.comptable.champEmail : r.champEmail,
          aide: r.aideEmail,
          majuscules: TextCapitalization.none,
          actionClavier: TextInputAction.done,
          onSubmitted: (_) => unawaited(_inviter(port, role)),
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
                  _erreur != null ? 'invitations-erreur' : 'invitations-succes',
                ),
                style: (_erreur != null ? palette.inkAlert : palette.inkMuted)
                    .applyTo(textes.bodyMedium ?? const TextStyle()),
              ),
            ),
          ),
        ActionPrincipale(
          key: const ValueKey<String>('invitations-inviter'),
          libelle: r.inviter,
          enCours: _envoi,
          onPress: _envoi ? null : () => unawaited(_inviter(port, role)),
        ),
        Ecart.vSection,
        BlocAsynchrone<List<Invitation>>(
          key: ValueKey<String>('invitations-bloc-${role.name}'),
          valeur: valeur,
          squelette: const Skeleton.liste(lignes: 3),
          onReessayer: () => ref.invalidate(_liste(role)),
          vide: EmptyState(
            key: const ValueKey<String>('invitations-vide'),
            message: comptable ? r.comptable.vide : r.vide,
            invitation: comptable ? r.comptable.videDetail : r.videDetail,
            icone: AppIcons.invitationEnvoyee,
          ),
          erreurVersEtat: (Object e, VoidCallback? reessayer) {
            if (e is CapaciteIndisponible) {
              return EtatSysteme(
                key: const ValueKey<String>('invitations-indisponible'),
                nature: NatureEtat.indisponible,
                titre: comptable ? r.comptable.liste : r.indisponibleTitre,
                phrase: r.indisponiblePhrase,
                dependance: e.dependance,
              );
            }
            return horsLigne
                ? EtatSansDonnees(
                    key: const ValueKey<String>('invitations-sans-donnees'),
                    quoi: r.sansDonnees,
                    onAction: reessayer,
                  )
                : EtatSysteme(
                    key: const ValueKey<String>('invitations-erreur-liste'),
                    nature: NatureEtat.echecServeur,
                    phrase: r.erreurListe,
                    onAction: reessayer,
                  );
          },
          construire: (List<Invitation> lues) => GroupeReglages(
            titre: comptable
                ? r.comptable.liste
                : roles.length > 1
                ? r.indisponibleTitre
                : r.liste,
            lignes: <LigneRubrique>[
              for (final Invitation i in lues) _ligne(i, port, role, horsLigne),
            ],
          ),
        ),
      ],
    );
  }

  LigneRubrique _ligne(
    Invitation i,
    PortInvitationsEnseignant port,
    RoleInvite role,
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
              onPress: () => unawaited(_revoquer(port, role, i)),
            )
          : null,
    );
  }
}

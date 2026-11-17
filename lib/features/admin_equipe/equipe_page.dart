// BE-2b (pilote, 17/11/2026) : l'ecran « Equipe », sous Personnes. Cahier :
// docs/current/BUREAU-EQUIPE/CAHIER-BE-2B-EQUIPE.md.
//
// Une seule page qui defile : en tete « Inviter une personne » et « Nouvelle
// mission » ; les personnes qui portent une mission (une ligne par mission
// accordee, avec son menu « Voir le detail », « Retirer la mission ») ; les
// missions, repliees par defaut ; les invitations en attente. Trois feuilles
// pour agir (nouvelle mission, accorder, retirer), plus archiver, inviter,
// revoquer. Accorder et retirer sont des actions sensibles : on les attend, le
// bouton dit l'attente ; le serveur decide, l'ecran ne calcule aucun droit.
//
// L'ecran lit une capacite, jamais un role : sans port, la page dit que l'equipe
// n'est pas disponible. Etats de chaque liste : chargement (`Skeleton`), contenu,
// vide (une phrase qui dit quoi faire), erreur (`EtatSysteme`, « Reessayer »),
// hors ligne (bandeau de `PageShell`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/equipe/modeles_equipe.dart';
import '../../core/equipe/port_equipe.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import 'feuilles_equipe.dart';
import 'libelles_equipe.dart';

/// Le ton de la pastille d'une invitation (le mot porte l'etat, jamais la
/// couleur seule).
TonEtat tonInvitationAssocie(EtatInvitationAssocie e) => switch (e) {
  EtatInvitationAssocie.active => TonEtat.accent,
  EtatInvitationAssocie.utilisee => TonEtat.succes,
  EtatInvitationAssocie.expiree => TonEtat.avertissement,
  EtatInvitationAssocie.revoquee => TonEtat.neutre,
};

/// Le mot de l'etat d'une invitation.
String libelleEtatInvitationAssocie(EtatInvitationAssocie e) {
  final r = t.admin.equipe.invitation.etat;
  return switch (e) {
    EtatInvitationAssocie.active => r.active,
    EtatInvitationAssocie.utilisee => r.utilisee,
    EtatInvitationAssocie.expiree => r.expiree,
    EtatInvitationAssocie.revoquee => r.revoquee,
  };
}

/// L'ecran « Equipe ».
class EquipePage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const EquipePage({super.key});

  /// La cle de la page.
  static const Key clePage = ValueKey<String>('equipe-page');

  /// La cle de « Inviter une personne ».
  static const Key cleInviter = ValueKey<String>('equipe-inviter');

  /// La cle de « Nouvelle mission ».
  static const Key cleNouvelleMission = ValueKey<String>(
    'equipe-nouvelle-mission',
  );

  /// La cle de « Accorder une mission ».
  static const Key cleAccorder = ValueKey<String>('equipe-accorder');

  /// La cle de la section des missions.
  static const Key cleMissions = ValueKey<String>('equipe-section-missions');

  @override
  ConsumerState<EquipePage> createState() => _EtatEquipe();
}

class _EtatEquipe extends ConsumerState<EquipePage> {
  bool _missionsOuvertes = false;
  String? _message;

  Future<void> _ouvrir(
    String titre,
    Widget Function(VoidCallback fermer, ValueChanged<String> fini) corps,
  ) async {
    final String? m = await AppBottomSheet.ouvrir<String>(
      context,
      titre: titre,
      constructeur: (BuildContext contexte) => corps(
        () => Navigator.of(contexte).pop(),
        (String m) => Navigator.of(contexte).pop(m),
      ),
    );
    if (m == null || !mounted) return;
    // Dans tous les cas la lecture est relue : un geste dont la reponse s'est
    // perdue doit s'y voir (D5 : « non confirme », pas « non envoye »).
    ref
      ..invalidate(attributionsProvider)
      ..invalidate(missionsProvider)
      ..invalidate(invitationsAssocieProvider)
      ..invalidate(personnesMissionProvider);
    setState(() => _message = m);
  }

  void _nouvelleMission() => _ouvrir(
    t.admin.equipe.feuille.mission.titre,
    (VoidCallback fermer, ValueChanged<String> fini) =>
        FeuilleNouvelleMission(onFini: fini, onAnnuler: fermer),
  );

  void _accorder() => _ouvrir(
    t.admin.equipe.feuille.accorder.titre,
    (VoidCallback fermer, ValueChanged<String> fini) =>
        FeuilleAccorderMission(onFini: fini, onAnnuler: fermer),
  );

  void _inviter() => _ouvrir(
    t.admin.equipe.feuille.inviter.titre,
    (VoidCallback fermer, ValueChanged<String> fini) =>
        FeuilleInviter(onFini: fini, onAnnuler: fermer),
  );

  void _retirer(Attribution a) => _ouvrir(
    t.admin.equipe.feuille.retirer.titre,
    (VoidCallback fermer, ValueChanged<String> fini) => FeuilleAMotif(
      geste: GesteAMotif.retirer,
      cible: a.id,
      nom: a.nom.isEmpty ? t.admin.equipe.detail.sansNom : a.nom,
      onFini: fini,
      onAnnuler: fermer,
    ),
  );

  void _archiver(Mission m) => _ouvrir(
    t.admin.equipe.feuille.archiver.titre,
    (VoidCallback fermer, ValueChanged<String> fini) => FeuilleAMotif(
      geste: GesteAMotif.archiver,
      cible: m.id,
      nom: m.nom,
      onFini: fini,
      onAnnuler: fermer,
    ),
  );

  void _revoquer(InvitationAssocie i) => _ouvrir(
    t.admin.equipe.feuille.revoquer.titre,
    (VoidCallback fermer, ValueChanged<String> fini) => FeuilleAMotif(
      geste: GesteAMotif.revoquer,
      cible: i.id,
      nom: i.courriel,
      onFini: fini,
      onAnnuler: fermer,
    ),
  );

  Future<void> _detail(Attribution a) async {
    await AppBottomSheet.ouvrir<void>(
      context,
      titre: t.admin.equipe.detail.titre,
      constructeur: (BuildContext _) =>
          FeuilleDetailAttribution(attribution: a),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = t.admin.equipe;
    final PortEquipe? port = ref.watch(portEquipeProvider);
    final int index = ongletsPersonnes().indexWhere(
      (({String libelle, String chemin}) o) =>
          o.chemin == Routes.adminPersonnesEquipe,
    );
    return PageShell(
      key: EquipePage.clePage,
      titre: e.titre,
      sousTitre: e.sousTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsPersonnes(),
        indexActif: index,
      ),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: port == null
              ? EtatSysteme(
                  key: const ValueKey<String>('equipe-indisponible'),
                  nature: NatureEtat.indisponible,
                  titre: e.indisponibleTitre,
                  phrase: e.indisponiblePhrase,
                  dependance: dependanceEquipe,
                )
              : _corps(),
        ),
      ),
    );
  }

  Widget _corps() {
    final e = t.admin.equipe;
    final AsyncValue<List<Attribution>> attributions = ref.watch(
      attributionsProvider,
    );
    final AsyncValue<List<Mission>> missions = ref.watch(missionsProvider);
    final AsyncValue<List<InvitationAssocie>> invitations = ref.watch(
      invitationsAssocieProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // En tete : seulement deux commandes, rien de plus en permanence.
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            ActionPrincipale(
              key: EquipePage.cleInviter,
              libelle: e.inviter,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              onPress: horsLigne ? null : _inviter,
            ),
            ActionPrincipale(
              key: EquipePage.cleNouvelleMission,
              libelle: e.nouvelleMission,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              onPress: horsLigne ? null : _nouvelleMission,
            ),
          ],
        ),
        if (_message != null) ...<Widget>[
          Ecart.vLg,
          BandeauAttention(
            key: const ValueKey<String>('equipe-message'),
            titre: _message!,
            message: '',
            ton: TonEtat.succes,
          ),
        ],
        Ecart.vXl,
        SectionHeader(
          titre: e.porteurs,
          libelleAction: e.accorder,
          onAction: horsLigne ? null : _accorder,
        ),
        Ecart.vMd,
        BlocAsynchrone<List<Attribution>>(
          valeur: attributions,
          squelette: const Skeleton.texte(lignes: 3),
          onReessayer: () => ref.invalidate(attributionsProvider),
          estVide: (List<Attribution> l) =>
              l.where((Attribution a) => a.active).isEmpty,
          vide: EmptyState(
            message: e.videTitre,
            invitation: e.videPhrase,
            icone: AppIcons.profil,
          ),
          construire: (List<Attribution> l) => _porteurs(
            l.where((Attribution a) => a.active).toList(),
            horsLigne,
          ),
        ),
        Ecart.vXl,
        SectionHeader(
          key: EquipePage.cleMissions,
          titre: e.missions,
          compteur: missions.value?.where((Mission m) => !m.archivee).length,
          libelleAction: _missionsOuvertes
              ? e.replierMissions
              : e.deplierMissions,
          onAction: () =>
              setState(() => _missionsOuvertes = !_missionsOuvertes),
        ),
        if (_missionsOuvertes) ...<Widget>[
          Ecart.vMd,
          BlocAsynchrone<List<Mission>>(
            valeur: missions,
            squelette: const Skeleton.texte(lignes: 3),
            onReessayer: () => ref.invalidate(missionsProvider),
            estVide: (List<Mission> l) => l.isEmpty,
            vide: EmptyState(
              message: e.aucuneMission,
              icone: AppIcons.dossiers,
            ),
            construire: (List<Mission> l) => _listeMissions(l, horsLigne),
          ),
        ],
        Ecart.vXl,
        SectionHeader(titre: e.invitations),
        Ecart.vMd,
        BlocAsynchrone<List<InvitationAssocie>>(
          valeur: invitations,
          squelette: const Skeleton.texte(lignes: 2),
          onReessayer: () => ref.invalidate(invitationsAssocieProvider),
          estVide: (List<InvitationAssocie> l) => l
              .where(
                (InvitationAssocie i) => i.etat == EtatInvitationAssocie.active,
              )
              .isEmpty,
          vide: EmptyState(message: e.aucuneInvitation, icone: AppIcons.profil),
          construire: (List<InvitationAssocie> l) => _listeInvitations(
            l
                .where(
                  (InvitationAssocie i) =>
                      i.etat == EtatInvitationAssocie.active,
                )
                .toList(),
            horsLigne,
          ),
        ),
      ],
    );
  }

  Widget _porteurs(List<Attribution> l, bool horsLigne) => CarteLignes(
    lignes: <Widget>[
      for (final Attribution a in l)
        SettingRow(
          key: ValueKey<String>('equipe-attribution-${a.id}'),
          title: a.nom.isEmpty ? t.admin.equipe.detail.sansNom : a.nom,
          description: <String>[
            libelleRoleEquipe(a.role),
            a.mission,
            phrasePerimetre(a.perimetre),
            phraseDuree(a.fin),
          ].where((String s) => s.isNotEmpty).join(' · '),
          controle: MenuActions(
            points: true,
            libelle: t.admin.equipe.menu.plus(
              nom: a.nom.isEmpty ? t.admin.equipe.detail.sansNom : a.nom,
            ),
            actions: <EntreeAction>[
              EntreeAction(
                libelle: t.admin.equipe.menu.detail,
                onChoix: () => _detail(a),
              ),
              if (!horsLigne)
                EntreeAction(
                  libelle: t.admin.equipe.menu.retirer,
                  destructif: true,
                  separateurAvant: true,
                  onChoix: () => _retirer(a),
                ),
            ],
          ),
        ),
    ],
  );

  Widget _listeMissions(List<Mission> l, bool horsLigne) => CarteLignes(
    lignes: <Widget>[
      for (final Mission m in l)
        SettingRow(
          key: ValueKey<String>('equipe-mission-${m.id}'),
          title: m.nom,
          description: <String>[
            phraseGestes(m.gestes),
            t.admin.equipe.mission.porteurs(n: m.porteurs),
            if (m.archivee) t.admin.equipe.mission.archivee,
          ].join(' · '),
          controle: m.archivee || horsLigne
              ? null
              : MenuActions(
                  points: true,
                  libelle: t.admin.equipe.menu.plus(nom: m.nom),
                  actions: <EntreeAction>[
                    EntreeAction(
                      libelle: t.admin.equipe.menu.archiver,
                      destructif: true,
                      onChoix: () => _archiver(m),
                    ),
                  ],
                ),
        ),
    ],
  );

  Widget _listeInvitations(List<InvitationAssocie> l, bool horsLigne) =>
      CarteLignes(
        lignes: <Widget>[
          for (final InvitationAssocie i in l)
            SettingRow(
              key: ValueKey<String>('equipe-invitation-${i.id}'),
              title: i.nom == null || i.nom!.isEmpty
                  ? i.courriel
                  : '${i.nom} · ${i.courriel}',
              description: <String>[
                libelleEtatInvitationAssocie(i.etat),
                t.admin.equipe.invitation.code(code: i.code),
                t.admin.equipe.invitation.expire(date: _date(i.expireLe)),
              ].join(' · '),
              controle: horsLigne
                  ? null
                  : MenuActions(
                      points: true,
                      libelle: t.admin.equipe.menu.plus(nom: i.courriel),
                      actions: <EntreeAction>[
                        EntreeAction(
                          libelle: t.admin.equipe.menu.revoquer,
                          destructif: true,
                          onChoix: () => _revoquer(i),
                        ),
                      ],
                    ),
            ),
        ],
      );

  String _date(DateTime d) {
    final DateTime l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
  }
}

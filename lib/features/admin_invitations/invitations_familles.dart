/// I1 (02/11/2026) : le bloc « Familles a inviter » de la direction.
///
/// Pose sous la carte « Invitations a envoyer » de l'import des inscriptions
/// et dans la page des invitations (carte « Une famille deja inscrite »).
/// Une ligne par famille importee et confirmee : son adresse, le nombre de
/// personnes, l'etat de son invitation (lu sur la file du serveur), et, quand
/// l'envoi est possible, « Envoyer l'invitation ». « Envoyer a toutes les
/// familles » demande une confirmation qui dit le nombre ; le serveur refuse
/// si ce nombre a change entre-temps (rien ne part). Rien ne part tout seul.
///
/// L'ecran lit une capacite, jamais un role : sans port, une phrase dit que
/// la fonction n'est pas branchee. Etats : chargement (`Skeleton`), contenu,
/// vide (`EmptyState`), erreur (`EtatSysteme`, « Reessayer »), hors ligne
/// (`EtatSansDonnees`, et aucun bouton d'envoi : il ne peut pas aboutir).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/recrutement/port_invitations_enseignant.dart'
    show HorsLigne, NonAutorise;
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
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../salle_seance/information_controle.dart' show coupuresAdresse;
import 'familles_importees.dart';

/// Le ton de la pastille d'un etat (jamais la couleur seule : le mot reste).
TonEtat tonInvitationFamille(EtatInvitationFamille etat) => switch (etat) {
  EtatInvitationFamille.aEnvoyer => TonEtat.neutre,
  EtatInvitationFamille.enFile => TonEtat.accent,
  EtatInvitationFamille.envoyee => TonEtat.accent,
  EtatInvitationFamille.echec => TonEtat.avertissement,
  EtatInvitationFamille.compteCree => TonEtat.succes,
};

/// Le mot d'un etat.
String libelleInvitationFamille(EtatInvitationFamille etat) => switch (etat) {
  EtatInvitationFamille.aEnvoyer => t.i1.familles.etat.aEnvoyer,
  EtatInvitationFamille.enFile => t.i1.familles.etat.enFile,
  EtatInvitationFamille.envoyee => t.i1.familles.etat.envoyee,
  EtatInvitationFamille.echec => t.i1.familles.etat.echec,
  EtatInvitationFamille.compteCree => t.i1.familles.etat.compteCree,
};

/// Le bloc des familles a inviter.
class InvitationsFamilles extends ConsumerStatefulWidget {
  /// Cree le bloc. [avecTitre] pose le titre de la liste (faux quand la
  /// carte qui l'accueille porte deja le sien).
  const InvitationsFamilles({super.key, this.avecTitre = true});

  /// Vrai pour poser le titre « Familles a inviter » au-dessus de la liste.
  final bool avecTitre;

  @override
  ConsumerState<InvitationsFamilles> createState() =>
      _InvitationsFamillesState();
}

class _InvitationsFamillesState extends ConsumerState<InvitationsFamilles> {
  String? _message;
  bool _messageErreur = false;
  final Set<String> _enCours = <String>{};
  bool _envoi = false;

  void _dire(String message, {bool erreur = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageErreur = erreur;
    });
  }

  String _motErreur(Object e) => switch (e) {
    HorsLigne() => t.i1.familles.horsLigne,
    NonAutorise() => t.i1.familles.nonAutorise,
    _ => t.i1.familles.erreurEnvoi,
  };

  Future<void> _envoyer(PortFamillesImportees port, FoyerImporte f) async {
    final r = t.i1.familles;
    setState(() {
      _enCours.add(f.id);
      _message = null;
    });
    try {
      final ResultatEnvoiFoyer res = await port.envoyer(f.id);
      _dire(switch (res) {
        ResultatEnvoiFoyer.enFile => r.enFile(email: f.email),
        ResultatEnvoiFoyer.dejaEnFile => r.dejaEnFile(email: f.email),
        ResultatEnvoiFoyer.compteCree => r.compteCree,
        ResultatEnvoiFoyer.introuvable => r.introuvable,
      }, erreur: res == ResultatEnvoiFoyer.introuvable);
    } on Object catch (e) {
      _dire(_motErreur(e), erreur: true);
    }
    // Dans tous les cas la liste est relue : un envoi dont la reponse s'est
    // perdue doit y apparaitre (D5 : « non confirme », pas « non envoye »).
    ref.invalidate(famillesImporteesProvider);
    if (mounted) setState(() => _enCours.remove(f.id));
  }

  Future<void> _envoyerATous(PortFamillesImportees port, int n) async {
    final r = t.i1.familles;
    // Un envoi a tous est irreversible : la confirmation dit le nombre.
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: r.toutesQuestion(n: n),
      consequence: r.toutesConsequence,
      libelleConfirmer: r.toutesConfirmer(n: n),
      irreversible: true,
    );
    if (!oui || !mounted) return;
    setState(() {
      _envoi = true;
      _message = null;
    });
    try {
      final ResultatEnvoiTous res = await port.envoyerATous(n);
      switch (res) {
        case EnvoiTousEnFile(:final int envoyees):
          _dire(r.toutesEnFile(n: envoyees));
        case EnvoiTousNombreChange():
          _dire(r.nombreChange, erreur: true);
      }
    } on Object catch (e) {
      _dire(_motErreur(e), erreur: true);
    }
    ref.invalidate(famillesImporteesProvider);
    if (mounted) setState(() => _envoi = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = t.i1.familles;
    final PortFamillesImportees? port = ref.watch(
      portFamillesImporteesProvider,
    );
    if (port == null) {
      return EtatSysteme(
        key: const ValueKey<String>('familles-indisponible'),
        nature: NatureEtat.indisponible,
        titre: r.titre,
        phrase: r.indisponible,
        dependance: dependanceFamillesImportees,
      );
    }
    final AsyncValue<FamillesImportees> valeur = ref.watch(
      famillesImporteesProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return BlocAsynchrone<FamillesImportees>(
      key: const ValueKey<String>('familles-bloc'),
      valeur: valeur,
      squelette: const Skeleton.liste(lignes: 3),
      onReessayer: () => ref.invalidate(famillesImporteesProvider),
      estVide: (FamillesImportees l) => l.foyers.isEmpty,
      vide: EmptyState(
        key: const ValueKey<String>('familles-vide'),
        message: r.vide,
        invitation: r.videDetail,
        icone: AppIcons.invitationEnvoyee,
      ),
      erreurVersEtat: (Object e, VoidCallback? reessayer) {
        if (e is CapaciteIndisponible) {
          return EtatSysteme(
            key: const ValueKey<String>('familles-indisponible'),
            nature: NatureEtat.indisponible,
            titre: r.titre,
            phrase: r.indisponible,
            dependance: e.dependance,
          );
        }
        return horsLigne
            ? EtatSansDonnees(
                key: const ValueKey<String>('familles-sans-donnees'),
                quoi: r.sansDonnees,
                onAction: reessayer,
              )
            : EtatSysteme(
                key: const ValueKey<String>('familles-erreur-liste'),
                nature: NatureEtat.echecServeur,
                phrase: r.erreurListe,
                onAction: reessayer,
              );
      },
      construire: (FamillesImportees l) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(r.aide, style: textes.bodyMedium),
          Ecart.vMd,
          if (_message != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                _message!,
                key: ValueKey<String>(
                  _messageErreur ? 'familles-erreur' : 'familles-succes',
                ),
                style: (_messageErreur ? palette.inkAlert : palette.inkMuted)
                    .applyTo(textes.bodyMedium ?? const TextStyle()),
              ),
            ),
            Ecart.vMd,
          ],
          // Envoyer a toutes : seulement s'il reste des familles a inviter et
          // qu'on est en ligne (un bouton qui ne peut pas aboutir n'est pas
          // rendu). Sinon une phrase dit que tout est parti.
          if (l.aEnvoyer > 0 && !horsLigne)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ActionPrincipale(
                key: const ValueKey<String>('familles-envoyer-toutes'),
                libelle: r.envoyerToutes(n: l.aEnvoyer),
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
                enCours: _envoi,
                onPress: _envoi
                    ? null
                    : () => unawaited(_envoyerATous(port, l.aEnvoyer)),
              ),
            )
          else if (l.aEnvoyer == 0)
            Text(
              r.toutesEnvoyees,
              key: const ValueKey<String>('familles-toutes-envoyees'),
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          Ecart.vMd,
          GroupeReglages(
            titre: widget.avecTitre ? r.titre : null,
            lignes: <LigneRubrique>[
              for (final FoyerImporte f in l.foyers) _ligne(port, f, horsLigne),
            ],
          ),
        ],
      ),
    );
  }

  LigneRubrique _ligne(
    PortFamillesImportees port,
    FoyerImporte f,
    bool horsLigne,
  ) {
    final r = t.i1.familles;
    final String personnes = r.personnes(n: f.personnes);
    final DateTime? le = f.envoyeeLe;
    return LigneRubrique(
      icone: AppIcons.invitationEnvoyee,
      libelle: coupuresAdresse(f.email),
      legende: le == null
          ? personnes
          : '$personnes · ${r.envoyeeLe(date: dateDeLAppareil(le.toLocal()))}',
      pastille: StatusPill(
        libelle: libelleInvitationFamille(f.etat),
        ton: tonInvitationFamille(f.etat),
      ),
      controle: f.envoyable && !horsLigne
          ? ActionPrincipale(
              key: ValueKey<String>('famille-envoyer-${f.id}'),
              libelle: f.etat == EtatInvitationFamille.echec
                  ? r.renvoyer
                  : r.envoyer,
              libelleSemantique: f.etat == EtatInvitationFamille.echec
                  ? r.renvoyerPour(email: f.email)
                  : r.envoyerPour(email: f.email),
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              enCours: _enCours.contains(f.id),
              onPress: _enCours.contains(f.id) || _envoi
                  ? null
                  : () => unawaited(_envoyer(port, f)),
            )
          : null,
    );
  }
}

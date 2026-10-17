import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/enums.dart';
import '../../../core/dossier/service_dossier.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/recrutement/port_invitations_enseignant.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controleur.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/groupe_reglages.dart';
import '../brouillon_inscription.dart';
import '../inscription_page.dart';

/// `/inscription/recapitulatif` : les reponses, un « Modifier » par ligne, et
/// la creation du compte.
///
/// Double soumission bloquee (drapeau pose avant tout `await`). Impasse apres
/// `refreshSession` corrigee : une fois le profil cree, une nouvelle tentative
/// ne rappelle que le rafraichissement (la creation refuserait un doublon), et
/// la page part d'elle-meme vers `/attente`, le routeur redirigeant selon la
/// porte ; si la porte reste `inscription`, on revient ici avec un message et
/// deux issues (reessayer, se deconnecter).
class RecapitulatifEtape extends ConsumerStatefulWidget {
  /// Cree l'etape.
  const RecapitulatifEtape({super.key});

  @override
  ConsumerState<RecapitulatifEtape> createState() => _RecapitulatifEtapeState();
}

class _RecapitulatifEtapeState extends ConsumerState<RecapitulatifEtape> {
  static const String _route = Routes.inscriptionRecapitulatif;

  bool _envoi = false;
  String? _erreur;

  Future<void> _creer() async {
    if (_envoi) {
      return;
    }
    final BrouillonInscription brouillon = ref.read(
      brouillonInscriptionProvider,
    );
    final UsageInscription? usage = brouillon.usage;
    if (usage == null) {
      return;
    }
    // L1-11 : le serveur refuse un profil enseignant sans code ; on renvoie au
    // champ du code plutot que d'envoyer un appel voue au refus.
    if (usage.role == AppRole.teacher &&
        ref.read(codeInvitationRetenuProvider) == null) {
      context.go(Routes.inscriptionInvitation);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    // RACCORDEMENT-1016 (D) : le code verifie par le candidat enseignant est
    // consomme par le serveur avec la creation du profil, dans la meme
    // transaction. Il ne sert qu'a l'enseignant.
    final String? codeInvitation = usage.role == AppRole.teacher
        ? ref.read(codeInvitationRetenuProvider)
        : null;
    try {
      if (!brouillon.profilCree) {
        await ref
            .read(serviceDossierProvider)
            .creerProfil(
              role: usage.role,
              prenom: brouillon.prenom,
              nom: brouillon.nom,
              genre: brouillon.genre,
              codeInvitation: codeInvitation,
            );
        ref.read(brouillonInscriptionProvider.notifier).noterProfilCree();
        ref.read(codeInvitationRetenuProvider.notifier).oublier();
      }
    } on InvitationNonConsommee {
      // Aucun profil n'a ete cree : le code est oublie, le candidat en
      // demande un nouveau (K-59 : ce qui manque, pourquoi, quoi faire).
      ref.read(codeInvitationRetenuProvider.notifier).oublier();
      if (mounted) {
        setState(() {
          _envoi = false;
          _erreur = t.inscription.erreurInvitation;
        });
      }
      return;
    } on Object {
      if (mounted) {
        setState(() {
          _envoi = false;
          _erreur = t.inscription.erreur;
        });
      }
      return;
    }
    try {
      // Le role et le foyer sont injectes dans le jeton par le hook de la base :
      // le jeton emis avant la creation ne les porte pas encore.
      await ref.read(sourceSessionProvider).rafraichir();
    } on Object {
      if (mounted) {
        setState(() {
          _envoi = false;
          _erreur = t.inscription.erreurActualisation;
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _envoi = false);
      context.go(Routes.attente);
    }
  }

  void _modifier(String route) => context.go(
    Uri(
      path: route,
      queryParameters: <String, String>{parametreModifier: '1'},
    ).toString(),
  );

  @override
  Widget build(BuildContext context) {
    final BrouillonInscription brouillon = ref.watch(
      brouillonInscriptionProvider,
    );
    exigerEtapesPrecedentes(context, brouillon, _route);
    final String? erreur =
        _erreur ??
        (brouillon.profilCree && !_envoi
            ? t.inscription.erreurActualisation
            : null);

    // Le profil deja cree ne se modifie plus d'ici : « Modifier » n'est pas
    // rendu (jamais grise, BOUTONS-GRISES-1) ; l'erreur d'actualisation et
    // « Reessayer » disent la suite. Pendant l'envoi, il ne repart pas.
    Widget? modifier(String route, String cle) => brouillon.profilCree
        ? null
        : ActionPrincipale(
            key: Key(cle),
            libelle: t.inscription.modifier,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: _envoi ? null : () => _modifier(route),
          );

    return CoquilleEtape(
      route: _route,
      question: t.inscription.recapitulatif,
      libelleAction: brouillon.profilCree
          ? t.inscription.reessayer
          : t.inscription.creer,
      onAction: brouillon.usage == null ? null : _creer,
      onRetour: _envoi || brouillon.profilCree
          ? null
          : () => context.go(Routes.inscriptionGenre),
      enCours: _envoi,
      souscription: erreur == null ? null : ErreurEtape(message: erreur),
      enfant: GroupeReglages(
        lignes: <LigneRubrique>[
          LigneRubrique(
            icone: brouillon.usage == UsageInscription.famille
                ? AppIcons.foyer
                : AppIcons.profil,
            libelle: t.inscription.recap.usage,
            legende: switch (brouillon.usage) {
              UsageInscription.moi => t.inscription.usage.moiTitre,
              UsageInscription.famille => t.inscription.usage.familleTitre,
              UsageInscription.enseignant => t.inscription.recap.enseignant,
              null => '',
            },
            controle: modifier(
              Routes.inscriptionUsage,
              'inscription-modifier-usage',
            ),
          ),
          LigneRubrique(
            icone: AppIcons.profil,
            libelle: t.inscription.recap.identite,
            legende: '${brouillon.prenom} ${brouillon.nom}',
            controle: modifier(
              Routes.inscriptionIdentite,
              'inscription-modifier-identite',
            ),
          ),
          LigneRubrique(
            icone: AppIcons.profil,
            libelle: t.inscription.recap.genre,
            legende: switch (brouillon.genre) {
              Genre.femme => t.inscription.genreFemme,
              Genre.homme => t.inscription.genreHomme,
              null => '',
            },
            controle: modifier(
              Routes.inscriptionGenre,
              'inscription-modifier-genre',
            ),
          ),
        ],
      ),
    );
  }
}

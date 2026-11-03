import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/port_profil_eleve_titulaire.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart' show TonEtat;
import '../compte/carte_rubriques.dart' show ColonneSousPage;
import '../compte/donnees_compte.dart' show profilEleveTitulaireExisteProvider;

/// « Creer mon profil eleve » (`/tuteur/foyer/ajouter?pour=moi`, FA5, lot
/// N2), ouvert depuis le Foyer et depuis le Compte : la meme page, le meme
/// flux (dossier maitre, une fonction en un seul endroit).
///
/// Le serveur sait creer le profil eleve du titulaire
/// (`creer_profil_eleve_titulaire`, migration 0052, idempotente) et dire s'il
/// existe (`profil_eleve_titulaire_existe`, 0056), par
/// `ProfilEleveTitulaireSupabase`, surcharge dans `lib/main.dart`. Avant le
/// lot N2, la route affichait « indisponible » en dur.
///
/// Ce que la page dit est ce que fait le serveur, rien de plus : un profil
/// eleve adulte pour le titulaire, son compte de tuteur inchange. Elle ne
/// promet aucune Classe : l'inscription dans une Classe reste un autre
/// parcours.
///
/// Etats : chargement (squelette), contenu (explication et action), profil
/// deja present, erreur de lecture (« Reessayer »), hors ligne sans lecture,
/// envoi en cours, creation faite, creation non confirmee (K-59, D5).
class CreerMonProfilPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const CreerMonProfilPage({super.key, this.onRetour});

  /// Le retour ; par defaut, le Foyer par son adresse (un `pop` garderait
  /// `?pour=moi` dans l'adresse). La demonstration y ramene a sa coquille.
  final VoidCallback? onRetour;

  /// L'action « Creer mon profil eleve ».
  static const Key creerKey = Key('foyer.monProfil.creer');

  /// L'etat « profil cree ».
  static const Key creeKey = Key('foyer.monProfil.cree');

  /// L'etat « profil deja present ».
  static const Key dejaKey = Key('foyer.monProfil.deja');

  /// Le message « creation non confirmee ».
  static const Key nonConfirmeKey = Key('foyer.monProfil.nonConfirme');

  @override
  ConsumerState<CreerMonProfilPage> createState() => _CreerMonProfilPageState();
}

enum _Envoi { aucun, enCours, cree, nonConfirme }

class _CreerMonProfilPageState extends ConsumerState<CreerMonProfilPage> {
  _Envoi _envoi = _Envoi.aucun;

  void _retour() {
    final VoidCallback? propre = widget.onRetour;
    if (propre != null) {
      propre();
    } else {
      GoRouter.of(context).go(Routes.tuteurFoyer);
    }
  }

  Future<void> _creer() async {
    if (_envoi == _Envoi.enCours) return;
    setState(() => _envoi = _Envoi.enCours);
    _Envoi resultat;
    try {
      await ref.read(portProfilEleveTitulaireProvider).creer();
      resultat = _Envoi.cree;
    } on Object {
      // Reponse perdue ou refus : la creation n'est pas confirmee (D5). Le
      // serveur est idempotent : reessayer ne cree rien en double.
      resultat = _Envoi.nonConfirme;
    }
    if (!mounted) return;
    setState(() => _envoi = resultat);
    if (resultat == _Envoi.cree) {
      // Le Compte relit l'existence (sa ligne disparait) ; la session relit
      // la capacite « eleve autonome », que le serveur rend desormais.
      ref.invalidate(profilEleveTitulaireExisteProvider);
      ref.read(sessionProvider.notifier).relireCapaciteEleve();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pol = t.foyer.monProfil;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<bool> existe = ref.watch(
      profilEleveTitulaireExisteProvider,
    );
    final Widget corps;
    if (_envoi == _Envoi.cree) {
      corps = EcranResultat(
        key: CreerMonProfilPage.creeKey,
        icone: AppIcons.succes,
        ton: TonEtat.succes,
        titre: pol.creeTitre,
        phrase: pol.creePhrase,
        libelleAction: pol.retour,
        onAction: _retour,
      );
    } else if (horsLigne && !existe.hasValue) {
      corps = EtatSysteme.sansDonnees(quoi: pol.sansDonnees);
    } else {
      corps = BlocAsynchrone<bool>(
        valeur: existe,
        squelette: const Skeleton.texte(),
        onReessayer: () => ref.invalidate(profilEleveTitulaireExisteProvider),
        construire: (bool deja) => deja
            ? EcranResultat(
                key: CreerMonProfilPage.dejaKey,
                icone: AppIcons.profil,
                ton: TonEtat.neutre,
                titre: pol.dejaTitre,
                phrase: pol.dejaPhrase,
                libelleAction: pol.retour,
                onAction: _retour,
              )
            : _Proposition(
                envoi: _envoi,
                horsLigne: horsLigne,
                onCreer: _creer,
              ),
      );
    }
    return PageShell(
      titre: pol.titre,
      onRetour: _retour,
      child: ColonneSousPage(child: corps),
    );
  }
}

/// L'explication, la consequence (K-58), puis l'action ; sous elle, le
/// message d'une creation non confirmee (K-59).
class _Proposition extends StatelessWidget {
  const _Proposition({
    required this.envoi,
    required this.horsLigne,
    required this.onCreer,
  });

  final _Envoi envoi;
  final bool horsLigne;
  final VoidCallback onCreer;

  @override
  Widget build(BuildContext context) {
    final pol = t.foyer.monProfil;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(pol.intro, style: textes.bodyLarge),
        Ecart.vMd,
        Text(
          pol.consequence,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        if (envoi == _Envoi.nonConfirme) ...<Widget>[
          Ecart.vLg,
          Text(
            pol.nonConfirme,
            key: CreerMonProfilPage.nonConfirmeKey,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        if (horsLigne) ...<Widget>[
          Ecart.vLg,
          Text(
            pol.horsLigne,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ] else ...<Widget>[
          Ecart.vXl,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ActionPrincipale(
              key: CreerMonProfilPage.creerKey,
              libelle: envoi == _Envoi.nonConfirme ? pol.reessayer : pol.creer,
              enCours: envoi == _Envoi.enCours,
              pleineLargeur: false,
              onPress: onCreer,
            ),
          ),
        ],
      ],
    );
  }
}

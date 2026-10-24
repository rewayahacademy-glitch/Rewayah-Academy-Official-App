// D6 et R8 (24/10/2026, decisions du pilote) : l'enfant rejoint la salle depuis
// l'appareil de son tuteur, depuis la carte de la Classe et depuis l'Accueil,
// avec la meme condition et le meme billet. La porte est celle du serveur
// (`join_opens_at`), jamais une constante plus courte.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/tc_groupe/concierge_seance.dart';
import '../../core/tc_groupe/rejoindre_classe.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/pre_vol.dart' show seuilOuvertureSalle;
import '../../core/widgets/action_principale.dart';

/// Vrai quand la salle est ouverte ou la seance en direct : l'enfant peut la
/// rejoindre depuis l'appareil de son tuteur. Le serveur seul decide (foyer,
/// inscription a la seance, role eleve).
bool salleRejoignable(EtatSeanceFamille etat) => switch (etat) {
  EtatSeanceFamille.salleOuverte ||
  EtatSeanceFamille.enDirect ||
  EtatSeanceFamille.prolongee => true,
  _ => false,
};

/// L'heure d'ouverture de la salle, telle que le serveur la rend
/// (`join_opens_at`) ; a defaut, le debut moins la fenetre par defaut du
/// serveur.
DateTime ouvertureSalle(SeanceFamille seance) => seance.debutUtc.subtract(
  seance.fenetre?.fenetreAcces ?? seuilOuvertureSalle,
);

/// « Rejoindre la salle avec {prenom} », qui demande le jeton de l'eleve.
class BoutonRejoindreAvecEleve extends StatelessWidget {
  /// Cree le bouton.
  const BoutonRejoindreAvecEleve({
    required this.seance,
    required this.eleve,
    super.key,
  });

  /// La seance a rejoindre.
  final SeanceFamille seance;

  /// L'eleve qui la rejoint.
  final ProfilEleveFoyer eleve;

  /// La cle du bouton (tests).
  static const Key cle = ValueKey<String>('rejoindre-avec-eleve');

  @override
  Widget build(BuildContext context) => _boutonRejoindre(
    cle: cle,
    eleve: eleve,
    onPress: () => _entrer(context, seance.seanceId, seance.groupeId, eleve),
  );
}

/// Le seul bouton « Rejoindre la salle avec {prenom} » (un bouton plein).
Widget _boutonRejoindre({
  required Key cle,
  required ProfilEleveFoyer eleve,
  required VoidCallback onPress,
}) => ActionPrincipale(
  key: cle,
  libelle: t.classe.seance.rejoindreAvec(prenom: eleve.prenom),
  onPress: onPress,
);

/// Ouvre la salle [sessionId] avec le billet de l'eleve.
void _entrer(
  BuildContext context,
  String sessionId,
  String? groupeId,
  ProfilEleveFoyer eleve,
) => unawaited(
  GoRouter.of(context).push(
    Routes.salle,
    extra: BilletSalle(
      sessionId: sessionId,
      emisA: DateTime.now(),
      groupeId: groupeId,
      eleveId: eleve.eleveId,
      interfaceGuidee: eleve.mode == InterfaceMode.enfant,
    ),
  ),
);

/// Concierge (a), tuteur (decision du pilote, 24/10/2026) : la Classe est
/// ouverte par son horloge (`horloge_classe`, tiree des creneaux meme sans
/// seance) alors qu'aucune seance rejoignable n'est connue de la famille.
bool classeRejoignableSansSeance(SessionClockVM? horloge) =>
    horloge?.rejoindreOuvert ?? false;

/// « Rejoindre la salle avec {prenom} » depuis l'horloge de la Classe : la
/// seance connue de l'horloge, sinon celle que le concierge rend (creee si
/// elle manquait, tuteur du foyer accepte par le serveur) ; refus ou rien :
/// K-59, « … Revenez 20 minutes avant l'heure du cours. ».
class BoutonRejoindreClasseAvecEleve extends ConsumerWidget {
  /// Cree le bouton.
  const BoutonRejoindreClasseAvecEleve({
    required this.groupeId,
    required this.sessionId,
    required this.eleve,
    super.key,
  });

  /// La Classe a rejoindre.
  final String groupeId;

  /// La seance que l'horloge connait deja, ou `null`.
  final String? sessionId;

  /// L'eleve qui la rejoint.
  final ProfilEleveFoyer eleve;

  /// La cle du bouton (tests).
  static const Key cle = ValueKey<String>('rejoindre-classe-avec-eleve');

  /// La cle de la phrase de refus (tests).
  static const Key cleRefus = ValueKey<String>('rejoindre-classe-refus');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? refus = ref.watch(refusEntreeProvider)[groupeId];
    final Widget bouton = _boutonRejoindre(
      cle: cle,
      eleve: eleve,
      onPress: () => rejoindreClasse(
        context,
        groupeId: groupeId,
        sessionId: sessionId,
        entrer: (String id) => _entrer(context, id, groupeId, eleve),
      ),
    );
    if (refus == null) return bouton;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        bouton,
        Ecart.vSm,
        Semantics(
          liveRegion: true,
          child: Text(
            refus,
            key: cleRefus,
            style: AppPalette.of(context).inkAlert.applyTo(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}

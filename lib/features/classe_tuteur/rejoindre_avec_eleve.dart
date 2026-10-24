// D6 et R8 (24/10/2026, decisions du pilote) : l'enfant rejoint la salle depuis
// l'appareil de son tuteur, depuis la carte de la Classe et depuis l'Accueil,
// avec la meme condition et le meme billet. La porte est celle du serveur
// (`join_opens_at`), jamais une constante plus courte.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/seance_famille/seance_famille.dart';
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
  Widget build(BuildContext context) => ActionPrincipale(
    key: cle,
    libelle: t.classe.seance.rejoindreAvec(prenom: eleve.prenom),
    onPress: () => GoRouter.of(context).push(
      Routes.salle,
      extra: BilletSalle(
        sessionId: seance.seanceId,
        emisA: DateTime.now(),
        groupeId: seance.groupeId,
        eleveId: eleve.eleveId,
        interfaceGuidee: eleve.mode == InterfaceMode.enfant,
      ),
    ),
  );
}

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';

/// « Creer mon profil eleve » (`/tuteur/foyer/ajouter?pour=moi`), ouvert
/// depuis le Foyer et, plus tard, depuis le Compte (meme route, meme ecran).
///
/// **Indisponible, et dit comme tel** (contrat K5) : le serveur ne sait pas
/// encore creer le profil eleve du titulaire (DB-FOY-01, port
/// `PortProfilEleveTitulaire`, sans adaptateur). Jamais un profil fictif,
/// jamais le conseil de s'ajouter comme un autre eleve du foyer (cela
/// creerait un second compte mineur).
///
/// Tache focalisee : sans barre basse sur telephone, donc un disque retour et
/// une action qui ramenent au Foyer. Aucune impasse.
///
/// **Titulaire adulte** ([titulaireAdulte], EA-5c, EA-BR-19) : la meme page,
/// mais ses textes ne parlent ni de « compte de tuteur » ni de cours a
/// commencer (il suit deja les siens), et le retour dit « Revenir a Ma
/// famille ».
class CreerMonProfilIndisponible extends StatelessWidget {
  /// Cree la page.
  const CreerMonProfilIndisponible({
    super.key,
    this.onRetour,
    this.titulaireAdulte = false,
  });

  /// Le retour ; par defaut, le Foyer par son adresse. La demonstration de
  /// l'eleve adulte y ramene a Ma famille dans sa coquille (EA-5c).
  final VoidCallback? onRetour;

  /// Vrai quand la page est ouverte depuis Ma famille d'un titulaire adulte,
  /// deja eleve : textes et retour propres a l'adulte.
  final bool titulaireAdulte;

  /// Toujours vers le Foyer, par son adresse : un `pop` garderait la requete
  /// `?pour=moi` dans l'adresse du Foyer (mesure en test).
  void _retour(BuildContext context) {
    final VoidCallback? propre = onRetour;
    if (propre != null) {
      propre();
    } else {
      GoRouter.of(context).go(Routes.tuteurFoyer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.foyer.monProfil.titre,
      onRetour: () => _retour(context),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxl),
        child: EtatSysteme(
          nature: NatureEtat.indisponible,
          portee: PorteeEtat.page,
          // Textes de l'adulte : libelle provisoire, lexique D4.
          titre: titulaireAdulte
              ? t.adulte.famille.monProfilIndisponibleTitre
              : t.foyer.monProfil.indisponibleTitre,
          phrase: titulaireAdulte
              ? t.adulte.famille.monProfilIndisponiblePhrase
              : t.foyer.monProfil.indisponiblePhrase,
          libelleAction: titulaireAdulte
              ? t.adulte.invitation.revenirMaFamille
              : t.foyer.monProfil.retour,
          onAction: () => _retour(context),
          dependance: 'DB-FOY-01',
        ),
      ),
    );
  }
}

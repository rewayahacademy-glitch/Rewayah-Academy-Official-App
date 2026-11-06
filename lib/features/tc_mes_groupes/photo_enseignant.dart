import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/app_icons.dart';
import '../../core/photos/photo_personne.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/status_pill.dart';

/// La photo de l'enseignant, ou l'aveu qu'elle manque.
///
/// **La photo est obligatoire** (decision `D-01`) : son absence declenche un
/// etat explicite, jamais un avatar generique silencieux. Ce composant fait
/// donc une distinction que `AvatarTile` seul ne sait pas faire :
///
/// - `photoUrlOuCle == null` : **la photo n'existe pas**. On le dit. C'est un
///   manque de donnee, et le masquer derriere des initiales le rendrait
///   invisible a tout le monde, y compris a l'administration.
/// - `photoUrlOuCle != null` mais [urlSignee] absente : **la photo existe, elle
///   n'est simplement pas encore resolue**. On persiste la cle de stockage,
///   jamais une URL signee qui expire ; la resolution demande une capacite
///   serveur qui n'existe pas encore (section 5 de `TC_CONTRACT_REQUEST_A.md`).
///   Les initiales sont alors un etat de chargement, pas un cache-misere.
///
/// PHOTOS-2b (04/11/2026) : sans [urlSignee] fournie par l'hote, la photo se
/// lit par le fournisseur unique (`photoPersonneProvider`, par
/// [EnseignantVM.enseignantId]) : la meme photo sur toutes les cartes, et le
/// serveur dit seul si l'appelant a le droit de la voir. Hors d'un
/// `ProviderScope` (galerie, tests de composant), les initiales restent.
///
/// `AvatarTile` est **reutilise tel quel** pour le second cas : son repli, son
/// contour et son cadrage sont deja calibres, et le redessiner ferait diverger
/// deux avatars du meme produit.
class PhotoEnseignant extends StatelessWidget {
  /// Cree la photo d'un enseignant.
  const PhotoEnseignant({
    required this.enseignant,
    super.key,
    this.urlSignee,
    this.diametre,
    this.repliInitiales = false,
  });

  /// Vrai sur un ecran de l'eleve (Accueil du Mode Accessibilite, MA-3) :
  /// une photo manquante y montre les initiales, comme `PhotoEleve` cote
  /// famille. Le manque est une donnee pour l'enseignant et l'administration,
  /// jamais un avertissement pour un enfant. Faux partout ailleurs : l'etat
  /// « photo manquante » reste explicite (D-01).
  final bool repliInitiales;

  /// L'enseignant concerne.
  final EnseignantVM enseignant;

  /// L'URL signee de courte duree, quand l'hote sait la resoudre.
  final String? urlSignee;

  /// Le diametre du cadre.
  final double? diametre;

  @override
  Widget build(BuildContext context) {
    // PHOTOS-A (04/11/2026) : avec un vrai id, dans une ProviderScope, tout
    // vient de la source unique : l'image, et « Photo a fournir » quand elle
    // a repondu « aucune photo ». Ni urlSignee ni la cle lue au chargement
    // (teacher_photo_cle) ne decident plus rien ; pendant la lecture, les
    // initiales.
    final bool sourcePartagee =
        enseignant.enseignantId.isNotEmpty &&
        context.findAncestorWidgetOfExactType<UncontrolledProviderScope>() !=
            null;
    if (sourcePartagee) {
      return Consumer(
        builder: (BuildContext context, WidgetRef ref, _) {
          final AsyncValue<String?> lue = ref.watch(
            photoPersonneProvider(enseignant.enseignantId),
          );
          final String? url = lue.value;
          if (url == null && lue.hasValue && !repliInitiales) {
            return _manquante(context);
          }
          return AvatarTile(
            prenom: enseignant.nomAffichage,
            urlSignee: url,
            diametre: diametre,
          );
        },
      );
    }
    if (!enseignant.photoManquante || repliInitiales) {
      return AvatarTile(
        prenom: enseignant.nomAffichage,
        urlSignee: enseignant.photoManquante ? null : urlSignee,
        diametre: diametre,
      );
    }
    return _manquante(context);
  }

  /// L'etat « photo a fournir » : un cercle d'avertissement et son libelle.
  Widget _manquante(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = palette.washWarning;
    final double taille = diametre ?? AppAvatar.moyen;

    // Un etat, donc un libelle : une pastille de couleur seule serait un defaut
    // d'accessibilite (invariant J7). Le libelle complet est porte par la
    // semantique, et la pastille visible est posee par la carte appelante.
    return Semantics(
      label: LibellesGroupe.photoManquante,
      child: SizedBox(
        width: taille,
        height: taille,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: paire.background,
            border: Border.fromBorderSide(palette.borderStrong.asBorderSide()),
          ),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: palette.inkWarning.applyTo(const TextStyle()).color,
                size: AppSpacing.xxl,
              ),
              child: Icon(AppIcons.avertissement.repos),
            ),
          ),
        ),
      ),
    );
  }
}

/// La pastille « Photo a fournir » d'un enseignant, decidee comme le cercle
/// de [PhotoEnseignant] (PHOTOS-A, 04/11/2026) : sur la source unique quand
/// l'id est connu (rien tant qu'elle n'a pas repondu), sinon sur la cle lue
/// au chargement. [avant] (un ecart) ne se pose qu'avec la pastille.
Widget pastillePhotoAFournir(EnseignantVM enseignant, {Widget? avant}) {
  Widget pastille() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      ?avant,
      StatusPill(
        libelle: LibellesGroupe.photoManquante,
        ton: TonEtat.avertissement,
      ),
    ],
  );
  return Builder(
    builder: (BuildContext context) {
      final bool sourcePartagee =
          enseignant.enseignantId.isNotEmpty &&
          context.findAncestorWidgetOfExactType<UncontrolledProviderScope>() !=
              null;
      if (!sourcePartagee) {
        return enseignant.photoManquante ? pastille() : const SizedBox.shrink();
      }
      return Consumer(
        builder: (BuildContext context, WidgetRef ref, _) {
          final AsyncValue<String?> lue = ref.watch(
            photoPersonneProvider(enseignant.enseignantId),
          );
          return lue.hasValue && lue.value == null
              ? pastille()
              : const SizedBox.shrink();
        },
      );
    },
  );
}

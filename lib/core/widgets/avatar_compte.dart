import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/port_identite_titulaire.dart';
import '../photos/photo_personne.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
import 'avatar_tile.dart';

/// PHOTOS-2b : le prenom de la personne connectee, lu par le port de
/// l'identite (`profiles` par soi). Une lecture refusee ou impossible rend
/// `null`, sans nouvelle tentative automatique : ni l'en-tete du Compte ni le
/// cercle Compte de la barre n'ont d'etat d'erreur a montrer.
///
/// NAV-REFONTE (09/11/2026) : deplace ici depuis la page Compte pour servir
/// aussi au cercle Compte de [NavShell] ; une seule lecture pour les deux.
final FutureProvider<String?> prenomDuCompteProvider =
    FutureProvider.autoDispose<String?>((Ref ref) async {
      ref.watch(
        sessionProvider.select((SessionState session) => session.profileId),
      );
      try {
        return (await ref.watch(portIdentiteTitulaireProvider).lire()).prenom;
      } on Object {
        return null;
      }
    }, retry: (int _, Object _) => null);

/// Le cercle de la personne connectee, dans le cercle Compte de la barre
/// flottante (NAV-REFONTE, decision du directeur du 09/11/2026 : « la photo
/// de la personne »).
///
/// Sa photo, lue a la source unique ([photoPersonneProvider]) ; sinon son
/// initiale ; sinon, tant que le prenom n'est pas lu, l'initiale de [repli]
/// (le nom de la destination, « Compte »). Hors de toute ProviderScope
/// (galerie, test de composant), l'initiale de [repli].
///
/// Purement visuel : le nom accessible est porte par le bouton qui l'entoure.
class AvatarCompte extends StatelessWidget {
  /// Cree le cercle.
  const AvatarCompte({required this.repli, required this.diametre, super.key});

  /// Le texte dont l'initiale s'affiche tant que le prenom n'est pas connu.
  final String repli;

  /// Le diametre du cercle.
  final double diametre;

  @override
  Widget build(BuildContext context) {
    if (context.findAncestorWidgetOfExactType<UncontrolledProviderScope>() ==
        null) {
      return ExcludeSemantics(
        child: AvatarTile(prenom: repli, diametre: diametre),
      );
    }
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? _) {
        final String? id = ref.watch(
          sessionProvider.select((SessionState s) => s.profileId),
        );
        final String? prenom = ref.watch(prenomDuCompteProvider).value?.trim();
        final String? photo = id == null || id.isEmpty
            ? null
            : ref.watch(photoPersonneProvider(id)).value;
        return ExcludeSemantics(
          child: AvatarTile(
            prenom: prenom == null || prenom.isEmpty ? repli : prenom,
            urlSignee: photo,
            diametre: diametre,
          ),
        );
      },
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../appairage/service_appairage.dart';
import '../domain/enums.dart';

/// Ce qu'est un profil eleve selectionnable du point de vue du foyer.
///
/// [titulaire] est **reserve** : il ne sera produit que le jour ou le serveur
/// saura creer le profil eleve du titulaire lui-meme (dependance DB-FOY-01),
/// jamais par une fixture ni par un repli de production. Un ecran ne dit
/// jamais « enfant » d'un profil [titulaire].
enum NatureProfilEleve {
  /// Un eleve du foyer, cree par le titulaire (`student_type = 'minor'`).
  membreDuFoyer,

  /// Le titulaire, quand il est aussi eleve. Reserve (DB-FOY-01).
  titulaire,
}

/// Un profil eleve du foyer, tel que les blocs dependants d'un eleve le lisent.
///
/// **Enveloppe d'`EleveDuFoyer`, pas un second modele** : la source reste
/// `profils_du_foyer_v`, lue par `elevesDuFoyerProvider`. Ce type n'ajoute que
/// la [nature], que la vue ne porte pas encore.
@immutable
class ProfilEleveFoyer {
  /// Cree un profil.
  const ProfilEleveFoyer({
    required this.eleveId,
    required this.prenom,
    required this.nature,
    required this.mode,
    required this.camera,
    this.cleAvatar,
    this.finAcces,
  });

  /// Le profil d'un eleve du foyer, tel que la vue le rend.
  factory ProfilEleveFoyer.depuis(EleveDuFoyer eleve) => ProfilEleveFoyer(
    eleveId: eleve.id,
    prenom: eleve.prenom,
    nature: NatureProfilEleve.membreDuFoyer,
    mode: eleve.mode,
    camera: eleve.camera,
    cleAvatar: eleve.cleAvatar,
    finAcces: eleve.finAcces,
  );

  /// Identifiant du profil eleve.
  final String eleveId;

  /// Prenom. Jamais le nom de famille a l'ecran (ADR-008).
  final String prenom;

  /// Membre du foyer ou titulaire.
  final NatureProfilEleve nature;

  /// Interface guidee ou standard.
  final InterfaceMode mode;

  /// Politique camera.
  final CameraPolicy camera;

  /// Cle de la photo dans le stockage, jamais une URL signee.
  final String? cleAvatar;

  /// Fin d'acces, quand le compte en porte une. `null` est le cas ordinaire.
  final DateTime? finAcces;

  @override
  bool operator ==(Object other) =>
      other is ProfilEleveFoyer &&
      other.eleveId == eleveId &&
      other.prenom == prenom &&
      other.nature == nature &&
      other.mode == mode &&
      other.camera == camera &&
      other.cleAvatar == cleAvatar &&
      other.finAcces == finAcces;

  @override
  int get hashCode =>
      Object.hash(eleveId, prenom, nature, mode, camera, cleAvatar, finAcces);
}

/// Les profils eleves du foyer, dans un ordre stable.
///
/// **Trie par prenom puis par identifiant.** La vue `profils_du_foyer_v` ne
/// porte aucun `order by` et la lecture n'en pose pas : l'ordre rendu par la
/// base peut changer d'une lecture a l'autre, et avec lui le profil retenu par
/// defaut. Un tri explicite garde le meme premier profil tant que le foyer ne
/// change pas.
final FutureProvider<List<ProfilEleveFoyer>> profilsElevesFoyerProvider =
    FutureProvider<List<ProfilEleveFoyer>>((Ref ref) async {
      final List<EleveDuFoyer> eleves = await ref.watch(
        elevesDuFoyerProvider.future,
      );
      return <ProfilEleveFoyer>[
        for (final EleveDuFoyer eleve in eleves) ProfilEleveFoyer.depuis(eleve),
      ]..sort(_parPrenomPuisIdentifiant);
    });

int _parPrenomPuisIdentifiant(ProfilEleveFoyer a, ProfilEleveFoyer b) {
  final int parPrenom = a.prenom.toLowerCase().compareTo(
    b.prenom.toLowerCase(),
  );
  return parPrenom != 0 ? parPrenom : a.eleveId.compareTo(b.eleveId);
}

/// L'identifiant d'eleve demande par l'utilisateur ou par l'URL (`?eleve=`).
///
/// **Une demande, jamais une autorisation.** Un identifiant inconnu du foyer
/// est ignore par [eleveSelectionneProvider] ; ce qu'on peut lire d'un eleve,
/// c'est la RLS qui le decide.
///
/// Memoire de session seulement : la demande survit aux changements d'onglet
/// de la coquille (le provider n'est pas libere), pas au redemarrage. Aucun
/// stockage persistant, par choix : un identifiant d'eleve n'a rien a faire
/// sur le disque d'un appareil partage.
class SelectionEleveControleur extends Notifier<String?> {
  @override
  String? build() => null;

  /// Demande un eleve.
  void choisir(String eleveId) => state = eleveId;

  /// Revient au profil par defaut.
  void effacer() => state = null;
}

/// La demande de selection d'eleve.
final NotifierProvider<SelectionEleveControleur, String?>
selectionEleveProvider = NotifierProvider<SelectionEleveControleur, String?>(
  SelectionEleveControleur.new,
);

/// Le profil a retenir parmi [profils] pour la [demande] donnee.
///
/// Le profil demande s'il figure dans la liste, sinon le premier, sinon `null`
/// (foyer vide). Pure : la meme regle sert au provider et aux tests.
ProfilEleveFoyer? profilRetenu(
  List<ProfilEleveFoyer> profils,
  String? demande,
) {
  if (profils.isEmpty) {
    return null;
  }
  for (final ProfilEleveFoyer profil in profils) {
    if (profil.eleveId == demande) {
      return profil;
    }
  }
  return profils.first;
}

/// Le profil effectivement selectionne.
///
/// Tout bloc qui depend d'un eleve lit ce provider, puis un provider
/// `.family` indexe par `eleveId` : un changement de profil reconstruit chaque
/// bloc sur une autre cle, et aucune valeur de l'eleve precedent ne subsiste.
///
/// Rend un `AsyncValue` pour que l'ecran distingue le chargement du foyer, son
/// echec et le foyer vide (`AsyncData(null)`). Ne jamais le filtrer par son
/// type : lire `hasValue`, `hasError`, `isLoading` (`lib/CLAUDE.md`).
final Provider<AsyncValue<ProfilEleveFoyer?>> eleveSelectionneProvider =
    Provider<AsyncValue<ProfilEleveFoyer?>>((Ref ref) {
      final String? demande = ref.watch(selectionEleveProvider);
      return ref
          .watch(profilsElevesFoyerProvider)
          .whenData(
            (List<ProfilEleveFoyer> profils) => profilRetenu(profils, demande),
          );
    });

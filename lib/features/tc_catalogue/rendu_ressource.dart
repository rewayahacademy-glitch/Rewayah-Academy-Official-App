/// CAP29-F : le rendu d'un support selon son type (spec CAP-29 §6.1, §6.2).
///
/// - **Image** : rendue pour de bon, depuis l'artefact image de la version
///   publiee courante (octets lus par `LecteurArtefact`, jamais une URL
///   signee gardee cote client). Etats : chargement, contenu, absent, echec
///   avec relance.
/// - **Coran** : jamais rendu ici. Le lecteur dedie est le seul a l'afficher ;
///   l'ecran le dit et ne le contourne pas.
/// - **PDF, texte structure, lecon** : aucun lecteur n'est present dans
///   l'application. L'ecran le dit au lieu de faire semblant, et la copie
///   reste proposee par la fiche.
/// - Les droits sont recontroles a la resolution : la fiche n'existe que si le
///   serveur rend la ressource, et l'artefact n'est demande qu'a travers la
///   version publiee courante.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/donnees_catalogue.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_telechargement/download_asset.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/skeleton.dart';

/// Le rendu du support de [detail].
class RenduRessource extends ConsumerWidget {
  /// Cree le rendu.
  const RenduRessource({required this.detail, super.key});

  /// La fiche resolue (droits deja controles par le serveur).
  final DetailRessource detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryResource r = detail.ressource;
    final TextTheme textes = Theme.of(context).textTheme;
    if (!r.publiee || detail.version == null) {
      return Text(
        t.tc.bibliotheque.detail.sansVersion,
        style: textes.bodyMedium,
      );
    }
    return switch (r.resourceType) {
      TypeRessource.quran => Text(
        t.tc.bibliotheque.detail.renduCoran,
        style: textes.bodyMedium,
      ),
      TypeRessource.image => _RenduImage(
        key: ValueKey<String>('rendu-image-${detail.version!.id}'),
        versionId: detail.version!.id,
        titre: r.title,
      ),
      TypeRessource.pdf ||
      TypeRessource.texteStructure ||
      TypeRessource.lecon => Text(
        t.tc.bibliotheque.detail.apercuIndisponible,
        key: const ValueKey<String>('rendu-sans-lecteur'),
        style: textes.bodyMedium,
      ),
    };
  }
}

/// L'octet d'une image, ou son absence : trois issues, jamais une exception.
sealed class _Image {
  const _Image();
}

final class _ImagePrete extends _Image {
  const _ImagePrete(this.octets);
  final Uint8List octets;
}

final class _ImageAbsente extends _Image {
  const _ImageAbsente();
}

final class _ImageIntrouvable extends _Image {
  const _ImageIntrouvable();
}

final FutureProviderFamily<_Image, String> _imageProvider =
    FutureProvider.family<_Image, String>((Ref ref, String versionId) async {
      final DownloadAsset? a = await ref
          .watch(portTelechargementProvider)
          .artefactDe(versionId, FormatArtefact.image);
      if (a == null) return const _ImageAbsente();
      final List<int>? octets = await ref
          .watch(lecteurArtefactProvider)
          .octets(a);
      if (octets == null) return const _ImageIntrouvable();
      return _ImagePrete(Uint8List.fromList(octets));
    });

class _RenduImage extends ConsumerWidget {
  const _RenduImage({required this.versionId, required this.titre, super.key});

  final String versionId;
  final String titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<_Image> image = ref.watch(_imageProvider(versionId));
    final TextTheme textes = Theme.of(context).textTheme;
    return switch (image) {
      AsyncValue<_Image>(hasValue: true) => switch (image.requireValue) {
        _ImagePrete(:final Uint8List octets) => ClipRRect(
          borderRadius: AppRadius.arrondiMd,
          child: Image.memory(
            octets,
            key: const ValueKey<String>('rendu-image'),
            semanticLabel: titre,
            fit: BoxFit.contain,
            errorBuilder: (BuildContext _, Object _, StackTrace? _) => _Echec(
              phrase: t.tc.bibliotheque.rendu.imageIllisible,
              onReessayer: () => ref.invalidate(_imageProvider(versionId)),
            ),
          ),
        ),
        _ImageAbsente() => Text(
          t.tc.bibliotheque.detail.apercuIndisponible,
          key: const ValueKey<String>('rendu-sans-lecteur'),
          style: textes.bodyMedium,
        ),
        _ImageIntrouvable() => _Echec(
          phrase: t.tc.bibliotheque.rendu.imageInaccessible,
          onReessayer: () => ref.invalidate(_imageProvider(versionId)),
        ),
      },
      AsyncValue<_Image>(hasError: true) => _Echec(
        phrase: t.tc.bibliotheque.rendu.imageInaccessible,
        onReessayer: () => ref.invalidate(_imageProvider(versionId)),
      ),
      _ => const Skeleton.texte(lignes: 4),
    };
  }
}

class _Echec extends StatelessWidget {
  const _Echec({required this.phrase, required this.onReessayer});

  final String phrase;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('rendu-echec'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExcludeSemantics(child: Icon(AppIcons.avertissement.repos)),
            Ecart.hSm,
            Expanded(child: TexteSansCoupure(phrase)),
          ],
        ),
        Ecart.vSm,
        ActionPrincipale(
          key: const ValueKey<String>('rendu-reessayer'),
          libelle: t.tc.bibliotheque.rendu.reessayer,
          niveau: NiveauAction.tertiaire,
          pleineLargeur: false,
          onPress: onReessayer,
        ),
      ],
    );
  }
}

/// CAP29-F : le rendu d'un support selon son type (spec CAP-29 §6.1, §6.2).
///
/// - **Image** : rendue pour de bon, depuis l'artefact image de la version
///   publiee courante (octets lus par `LecteurArtefact`, jamais une URL
///   signee gardee cote client). Etats : chargement, contenu, absent, echec
///   avec relance.
/// - **Coran** : jamais rendu ici. Le lecteur dedie est le seul a l'afficher ;
///   l'ecran le dit et, quand la capacite de lecture du Coran est la (eleve,
///   adulte eleve autonome), propose « Ouvrir le mushaf » vers ce lecteur.
///   Sans la capacite, la phrase seule : jamais un bouton grise.
/// - **PDF, texte structure, lecon** : aucun lecteur n'est present dans
///   l'application. Quand la source rend un lien de lecture court
///   (`PortTelechargement.lienLectureServi`, C-35) et qu'on est dans un
///   navigateur, « Ouvrir » demande ce lien, l'ouvre dans un nouvel onglet,
///   puis l'oublie : jamais garde ni journalise. Sinon l'ecran le dit au lieu
///   de faire semblant, et la copie reste proposee par la fiche.
/// - Les droits sont recontroles a la resolution : la fiche n'existe que si le
///   serveur rend la ressource, et l'artefact n'est demande qu'a travers la
///   version publiee courante.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/tc_bibliotheque/capacite_lecture_coran.dart';
import '../../core/tc_bibliotheque/donnees_catalogue.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_bibliotheque/ouvreur_onglet.dart';
import '../../core/tc_telechargement/download_asset.dart';
import '../../core/tc_telechargement/port_telechargement.dart';
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
      TypeRessource.quran => const _RenduCoran(),
      TypeRessource.image => _RenduImage(
        key: ValueKey<String>('rendu-image-${detail.version!.id}'),
        versionId: detail.version!.id,
        titre: r.title,
      ),
      TypeRessource.pdf ||
      TypeRessource.texteStructure ||
      TypeRessource.lecon => _RenduLecture(versionId: detail.version!.id),
    };
  }
}

/// Le Coran : la phrase, et « Ouvrir le mushaf » seulement avec la capacite
/// de lecture du Coran. Aucun rendu du Coran ici.
class _RenduCoran extends ConsumerWidget {
  const _RenduCoran();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool capacite = ref.watch(capaciteLectureCoranProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.tc.bibliotheque.detail.renduCoran,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (capacite) ...<Widget>[
          Ecart.vMd,
          ActionPrincipale(
            key: const ValueKey<String>('rendu-ouvrir-mushaf'),
            libelle: t.tc.bibliotheque.rendu.ouvrirMushaf,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            onPress: () => GoRouter.of(context).go(Routes.eleveCoran),
          ),
        ],
      ],
    );
  }
}

/// Ou en est l'ouverture d'un support de lecture.
enum _EtatLecture { repos, chargement, horsLigne, bloque, echec, indisponible }

/// PDF, texte structure, lecon : « Ouvrir » dans un nouvel onglet, avec un
/// lien de lecture court demande au port a chaque ouverture (jamais garde).
class _RenduLecture extends ConsumerStatefulWidget {
  const _RenduLecture({required this.versionId});

  final String versionId;

  @override
  ConsumerState<_RenduLecture> createState() => _EtatRenduLecture();
}

class _EtatRenduLecture extends ConsumerState<_RenduLecture> {
  _EtatLecture _etat = _EtatLecture.repos;

  Future<void> _ouvrir() async {
    if (_etat == _EtatLecture.chargement) return;
    final OuvreurOnglet? ouvreur = ref.read(ouvreurOngletProvider);
    if (ouvreur == null) return;
    // Hors ligne : aucune demande ne part ; la phrase le dit.
    if (ref.read(horsLigneProvider).value ?? false) {
      setState(() => _etat = _EtatLecture.horsLigne);
      return;
    }
    setState(() => _etat = _EtatLecture.chargement);
    try {
      final Uri lien = await ref
          .read(portTelechargementProvider)
          .lienLecture(widget.versionId);
      if (!mounted) return;
      // Le lien n'existe que le temps de cet appel : ouvert, puis oublie.
      final bool ouvert = ouvreur(lien);
      setState(() => _etat = ouvert ? _EtatLecture.repos : _EtatLecture.bloque);
    } on EchecArtefact {
      if (mounted) setState(() => _etat = _EtatLecture.indisponible);
    } on Object {
      if (mounted) setState(() => _etat = _EtatLecture.echec);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final bool servi = ref.watch(portTelechargementProvider).lienLectureServi;
    final bool navigateur = ref.watch(ouvreurOngletProvider) != null;
    if (!servi || !navigateur) {
      return Text(
        t.tc.bibliotheque.detail.apercuIndisponible,
        key: const ValueKey<String>('rendu-sans-lecteur'),
        style: textes.bodyMedium,
      );
    }
    final String? phrase = switch (_etat) {
      _EtatLecture.repos || _EtatLecture.chargement => null,
      _EtatLecture.horsLigne => t.tc.bibliotheque.rendu.lienHorsLigne,
      _EtatLecture.bloque => t.tc.bibliotheque.rendu.lienBloque,
      _EtatLecture.echec => t.tc.bibliotheque.rendu.lienEchec,
      _EtatLecture.indisponible => t.tc.bibliotheque.rendu.lienIndisponible,
    };
    final bool relance =
        _etat == _EtatLecture.horsLigne ||
        _etat == _EtatLecture.bloque ||
        _etat == _EtatLecture.echec;
    return Column(
      key: const ValueKey<String>('rendu-lecture'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (phrase != null) ...<Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(child: Icon(AppIcons.avertissement.repos)),
              Ecart.hSm,
              Expanded(child: TexteSansCoupure(phrase)),
            ],
          ),
          Ecart.vSm,
        ],
        // Une phrase sans suite (non disponible pour ce support) ne porte
        // aucun bouton : il n'aboutirait jamais.
        if (_etat != _EtatLecture.indisponible)
          ActionPrincipale(
            key: const ValueKey<String>('rendu-ouvrir'),
            libelle: relance
                ? t.tc.bibliotheque.rendu.reessayer
                : t.tc.bibliotheque.rendu.ouvrir,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            enCours: _etat == _EtatLecture.chargement,
            onPress: _ouvrir,
          ),
      ],
    );
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

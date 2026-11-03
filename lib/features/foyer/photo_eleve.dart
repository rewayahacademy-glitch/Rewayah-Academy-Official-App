import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/appairage/service_avatar.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/photos/photos_personnes.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/raccourci_tactile.dart';

/// La photo d'un profil eleve, par URL signee, avec repli sur les initiales.
///
/// Le seul point d'affichage du portrait d'un eleve dans le Foyer et sa fiche.
/// Lue par `value`, jamais par le type de l'`AsyncValue` : tant que l'URL
/// manque ou echoue, la tuile montre les initiales, ce qui est le repli prevu
/// par `AvatarTile` (ADR-012).
class PhotoEleve extends ConsumerWidget {
  /// Cree la photo.
  const PhotoEleve({
    required this.prenom,
    required this.cleAvatar,
    super.key,
    this.diametre,
    this.personneId,
  });

  /// PHOTOS-2a (mode a la demande) : l'identifiant de profil de l'eleve. Donne,
  /// la photo est lue au serveur (`photoPersonneProvider`), selon ses regles
  /// (K-44), et [cleAvatar] ne sert plus.
  final String? personneId;

  /// Le prenom, source des initiales de repli.
  final String prenom;

  /// La cle de la photo dans le stockage, `null` sans photo.
  final String? cleAvatar;

  /// Le diametre de la tuile.
  final double? diametre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (personneId case final String id) {
      return AvatarTile(prenom: prenom, personneId: id, diametre: diametre);
    }
    final String? cle = cleAvatar;
    final String? url = cle == null
        ? null
        : ref.watch(avatarUrlProvider(cle)).value;
    return AvatarTile(prenom: prenom, urlSignee: url, diametre: diametre);
  }
}

/// PHOTOS-2a : ouvre « Ma photo » en feuille (dialogue sur bureau), pour la
/// personne connectee.
///
/// La feuille vit dans l'overlay du `Navigator`, hors du `ProviderScope` de
/// l'appelant : elle recoit donc son conteneur (comme `ouvrirPhotoPublique`).
Future<void> ouvrirMaPhoto(
  BuildContext context, {
  required String personneId,
  required String prenom,
}) {
  final ProviderContainer conteneur = ProviderScope.containerOf(context);
  return AppBottomSheet.ouvrir<void>(
    context,
    titre: t.compte.tuteur.identite.maPhotoTitre,
    constructeur: (BuildContext _) => UncontrolledProviderScope(
      container: conteneur,
      child: EditeurPhotoEleve.moi(personneId: personneId, prenom: prenom),
    ),
  );
}

/// Ou en est l'envoi d'une photo.
enum _Phase {
  /// Rien en cours : la photo actuelle et l'action de choix.
  repos,

  /// Une photo choisie, montree avant l'envoi.
  apercu,

  /// Le fichier monte vers le stockage (etape 1 sur 2).
  envoi,

  /// La cle est ecrite sur le profil (etape 2 sur 2).
  enregistrement,

  /// L'envoi n'a pas abouti : rien n'a change sur le profil.
  echecEnvoi,

  /// Le fichier est monte, la cle n'a pas ete ecrite : la reprise ne
  /// renvoie pas le fichier, elle ne refait que l'ecriture.
  echecEnregistrement,
}

/// Le changement de photo d'un profil eleve : selection, apercu, envoi en
/// deux etapes dites, reprise sans perte.
///
/// **Aucun etat optimiste** : la photo affichee apres coup est celle que la
/// relecture du foyer rend. **Jamais melangee a la piece d'identite** : un
/// `PhotoEnfant`, le seau `avatars`, jamais `PieceAEnvoyer` ni le seau `kyc`
/// (`service_avatar.dart`).
class EditeurPhotoEleve extends ConsumerStatefulWidget {
  /// Cree l'editeur.
  const EditeurPhotoEleve({required ProfilEleveFoyer this.profil, super.key})
    : personneId = null,
      prenom = null;

  /// PHOTOS-2a (mode a la demande) : la photo de la personne connectee, pour
  /// tout adulte (tuteur, eleve adulte, direction). Elle se pose par
  /// `poser_ma_photo`, dans le seau que le serveur rend pour cette personne.
  const EditeurPhotoEleve.moi({
    required String this.personneId,
    required String this.prenom,
    super.key,
  }) : profil = null;

  /// Le profil dont on change la photo ; `null` en mode « ma photo ».
  final ProfilEleveFoyer? profil;

  /// L'identifiant de la personne connectee, en mode « ma photo ».
  final String? personneId;

  /// Son prenom, source des initiales, en mode « ma photo ».
  final String? prenom;

  /// L'action « Choisir une photo » ou « Changer la photo ».
  static const Key choisirKey = Key('photoEleve.choisir');

  /// L'action « Envoyer cette photo ».
  static const Key envoyerKey = Key('photoEleve.envoyer');

  /// L'action « Reessayer » apres un echec.
  static const Key reprendreKey = Key('photoEleve.reprendre');

  /// L'apercu de la photo choisie.
  static const Key apercuKey = Key('photoEleve.apercu');

  @override
  ConsumerState<EditeurPhotoEleve> createState() => _EditeurPhotoEleveState();
}

class _EditeurPhotoEleveState extends ConsumerState<EditeurPhotoEleve> {
  _Phase _phase = _Phase.repos;
  PhotoEnfant? _photo;
  String? _cleEnvoyee;
  String? _refus;
  bool _succes = false;

  bool get _moi => widget.profil == null;

  String get _id => widget.profil?.eleveId ?? widget.personneId!;

  String get _prenom => widget.profil?.prenom ?? widget.prenom!;

  /// En mode « ma photo », la photo vient du serveur ; sinon de la vue du
  /// foyer.
  bool _aUnePhoto() => _moi
      ? ref.watch(photoPersonneProvider(_id)).value != null
      : widget.profil?.cleAvatar != null;

  /// Le fichier de la personne connectee, dans son seau (`avatars`, ou
  /// `photos_enseignants` pour un enseignant) : celui que le serveur rend.
  Future<String> _televerserMoi(PhotoEnfant photo) async {
    final SourcePhoto? source = await ref.read(lotPhotosProvider).source(_id);
    if (source == null) {
      throw StateError('source de photo inconnue');
    }
    return ref
        .read(portPhotosProvider)
        .televerser(personneId: _id, seau: source.seau, photo: photo);
  }

  Future<void> _choisir() async {
    setState(() {
      _refus = null;
      _succes = false;
    });
    final PhotoEnfant? photo;
    try {
      photo = await ref.read(selecteurPhotoProvider).choisirPhoto();
    } on Object {
      // Permission refusee, fichier illisible, erreur de la plateforme : le
      // selecteur n'a rien rendu, et l'ecran le dit au lieu de se taire.
      if (mounted) {
        setState(() => _refus = t.ficheEleve.informations.selectionEchec);
      }
      return;
    }
    if (!mounted || photo == null) {
      return;
    }
    if (photo.octets.lengthInBytes > ServiceAvatar.tailleMaximaleOctets) {
      // Refus AVANT l'envoi : rien ne monte sur une connexion de telephone
      // pour etre refuse ensuite.
      setState(() {
        _refus = t.ficheEleve.informations.tropLourde(
          taille: '${ServiceAvatar.tailleMaximaleOctets ~/ (1024 * 1024)}',
        );
        _phase = _Phase.repos;
        _photo = null;
      });
      return;
    }
    setState(() {
      _photo = photo;
      _cleEnvoyee = null;
      _phase = _Phase.apercu;
    });
  }

  void _annuler() => setState(() {
    _photo = null;
    _cleEnvoyee = null;
    _phase = _Phase.repos;
  });

  Future<void> _envoyer() async {
    final PhotoEnfant? photo = _photo;
    if (photo == null) {
      return;
    }
    String? cle = _cleEnvoyee;
    if (cle == null) {
      setState(() => _phase = _Phase.envoi);
      try {
        cle = _moi
            ? await _televerserMoi(photo)
            : await ref
                  .read(serviceAvatarProvider)
                  .televerser(eleveId: _id, photo: photo);
      } on Object {
        if (mounted) {
          setState(() => _phase = _Phase.echecEnvoi);
        }
        return;
      }
      _cleEnvoyee = cle;
    }
    if (!mounted) {
      return;
    }
    setState(() => _phase = _Phase.enregistrement);
    // PHOTOS-2a : la cle se pose par la porte nommee du serveur, qui verifie
    // le foyer, l'age et le dossier ; plus jamais par une ecriture directe
    // (droit ferme, migration 20261107400000).
    final PortPhotos port = ref.read(portPhotosProvider);
    try {
      if (_moi) {
        await port.poserMaPhoto(cle);
      } else {
        await port.poserPhotoEleve(_id, cle);
      }
    } on Object {
      if (mounted) {
        setState(() => _phase = _Phase.echecEnregistrement);
      }
      return;
    }
    // La photo remplacee ne doit plus etre servie par l'URL precedente ; le
    // foyer relu porte la nouvelle cle.
    relirePhoto(ref, _id);
    ref.invalidate(elevesDuFoyerProvider);
    if (mounted) {
      setState(() {
        _photo = null;
        _cleEnvoyee = null;
        _phase = _Phase.repos;
        _succes = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final PhotoEnfant? photo = _photo;
    final bool avecApercu = photo != null && _phase != _Phase.repos;
    final bool enCours =
        _phase == _Phase.envoi || _phase == _Phase.enregistrement;

    final Widget portrait = avecApercu
        ? _Apercu(photo: photo)
        // Toucher la photo ouvre aussi le choix (PHOTO-LIEN-1) : le lien en
        // dessous reste le controle du clavier et du lecteur d'ecran.
        : RaccourciTactile(
            onPress: enCours ? null : _choisir,
            child: _moi
                ? AvatarTile(
                    prenom: _prenom,
                    personneId: _id,
                    diametre: AppAvatar.grand,
                  )
                : PhotoEleve(
                    prenom: _prenom,
                    cleAvatar: widget.profil?.cleAvatar,
                    diametre: AppAvatar.grand,
                  ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            portrait,
            Ecart.hLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    avecApercu
                        ? t.ficheEleve.informations.apercuTitre
                        : !_aUnePhoto()
                        ? t.ficheEleve.informations.photoAucune
                        : t.ficheEleve.informations.photoPresente,
                    style: palette.inkStrong.applyTo(
                      textes.titleMedium ?? const TextStyle(),
                    ),
                  ),
                  Ecart.vXs,
                  Text(
                    avecApercu
                        ? t.ficheEleve.informations.apercuPhrase
                        : _moi
                        ? t.ficheEleve.informations.photoLegendeMoi
                        : t.ficheEleve.informations.photoLegende(
                            dePrenom: deDevant(_prenom),
                          ),
                    style: attenue,
                  ),
                ],
              ),
            ),
          ],
        ),
        Ecart.vLg,
        if (enCours) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              _phase == _Phase.envoi
                  ? t.ficheEleve.informations.etapeEnvoi
                  : t.ficheEleve.informations.etapeEnregistrement,
              style: attenue,
            ),
          ),
          Ecart.vSm,
          const LinearProgressIndicator(),
        ] else if (avecApercu) ...<Widget>[
          if (_refus != null) ...<Widget>[
            Text(
              _refus!,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vMd,
          ],
          if (_phase == _Phase.echecEnvoi ||
              _phase == _Phase.echecEnregistrement) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                _phase == _Phase.echecEnvoi
                    ? t.ficheEleve.informations.echecEnvoi
                    : t.ficheEleve.informations.echecEnregistrement,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
          ],
          if (horsLigne) ...<Widget>[
            Text(t.ficheEleve.informations.horsLigne, style: attenue),
            Ecart.vMd,
          ],
          // L'envoi est l'unique bouton plein de cet etat (K-56) : les
          // autres actions sont des liens. Hors ligne, l'envoi ne peut pas
          // aboutir : il n'est pas rendu, la phrase au-dessus dit pourquoi
          // (lib/CLAUDE.md, BOUTONS-GRISES-1).
          if (!horsLigne) ...<Widget>[
            ActionPrincipale(
              key: _phase == _Phase.apercu
                  ? EditeurPhotoEleve.envoyerKey
                  : EditeurPhotoEleve.reprendreKey,
              libelle: _phase == _Phase.apercu
                  ? t.ficheEleve.informations.envoyer
                  : t.ficheEleve.informations.reprendre,
              onPress: _envoyer,
            ),
            Ecart.vSm,
          ],
          if (_phase != _Phase.echecEnregistrement)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LienFleche(
                libelle: t.ficheEleve.informations.autre,
                onPress: _choisir,
              ),
            ),
          ActionPrincipale(
            libelle: t.ficheEleve.informations.annuler,
            niveau: NiveauAction.tertiaire,
            onPress: _annuler,
          ),
        ] else ...<Widget>[
          if (_refus != null) ...<Widget>[
            Text(
              _refus!,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vMd,
          ],
          if (_succes) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                t.ficheEleve.informations.succes,
                style: palette.inkSuccess.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
          ],
          // Une action secondaire n'est jamais un bouton plein (K-56,
          // PHOTO-LIEN-1) : une ligne de lien, texte et fleche, au bord de
          // debut, sous la photo.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: EditeurPhotoEleve.choisirKey,
              libelle: !_aUnePhoto()
                  ? t.ficheEleve.informations.choisir
                  : t.ficheEleve.informations.changer,
              onPress: _choisir,
            ),
          ),
        ],
      ],
    );
  }
}

/// L'apercu local de la photo choisie, avant tout envoi.
///
/// Un format que l'appareil ne sait pas decoder (HEIC sur plusieurs
/// plateformes) ne bloque pas l'envoi : une phrase le dit a la place de
/// l'image, jamais une icone d'erreur.
class _Apercu extends StatelessWidget {
  const _Apercu({required this.photo});

  final PhotoEnfant photo;

  static const double _diametre = AppAvatar.grand;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return SizedBox.square(
      key: EditeurPhotoEleve.apercuKey,
      dimension: _diametre,
      child: ClipOval(
        child: Image.memory(
          photo.octets,
          fit: BoxFit.cover,
          semanticLabel: t.ficheEleve.informations.apercuTitre,
          errorBuilder: (BuildContext contexte, Object _, StackTrace? _) =>
              ColoredBox(
                color: palette.surfaceSunken.background,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Center(
                    child: Text(
                      t.ficheEleve.informations.apercuIllisible,
                      textAlign: TextAlign.center,
                      style: palette.inkMuted.applyTo(
                        Theme.of(contexte).textTheme.labelSmall ??
                            const TextStyle(),
                      ),
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

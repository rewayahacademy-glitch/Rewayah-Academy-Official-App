import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/selecteur_fichier.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/session/deconnexion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';

/// Le depot de la piece d'identite.
///
/// Le genre transmis avec la piece n'est pas une donnee d'etat civil : c'est ce
/// qui decide **quel membre du personnel pourra la regarder** (audit 1.3). Il
/// vient du profil renseigne a l'inscription, pas d'une saisie de plus.
///
/// Lot E7 (DECISION-ENTREE-2026-10-17, qui remplace ici BOUTONS-GRISES-1) :
/// un retour vers le portail d'attente et « Se deconnecter » ; chaque type de
/// piece est explique et se choisit dans une selection simple, jamais saisi ;
/// « Choisir la photo » parait une fois le type choisi et « Envoyer ma
/// piece », toujours visible, n'agit qu'une fois la photo choisie. Une phrase dit d'avance ce qui reste
/// a faire : aucun reproche apres coup.
class DepotPiecePage extends ConsumerStatefulWidget {
  /// Cree l'ecran de depot.
  const DepotPiecePage({super.key});

  @override
  ConsumerState<DepotPiecePage> createState() => _DepotPiecePageState();
}

class _DepotPiecePageState extends ConsumerState<DepotPiecePage> {
  TypePiece? _type;
  PieceAEnvoyer? _piece;
  bool _envoi = false;
  String? _erreur;

  Future<void> _choisir(TypePiece type) async {
    setState(() => _erreur = null);
    final PieceAEnvoyer? choisie = await ref
        .read(selecteurFichierProvider)
        .choisirPiece(type);
    if (!mounted || choisie == null) {
      return;
    }

    // La borne est verifiee ici plutot qu'apres l'envoi : refuser une photo de
    // vingt mega-octets au bout de trois minutes de televersement sur un
    // reseau guineen serait une facon de perdre la famille.
    if (choisie.octets.lengthInBytes > ServiceDossier.tailleMaximaleOctets) {
      setState(
        () => _erreur = t.kyc.tropVolumineux(
          taille: (ServiceDossier.tailleMaximaleOctets / (1024 * 1024))
              .round()
              .toString(),
        ),
      );
      return;
    }
    setState(() => _piece = choisie);
  }

  Future<void> _envoyer(PieceAEnvoyer piece) async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref.read(serviceDossierProvider).deposerPiece(piece);
      ref.invalidate(etatDossierProvider);
      if (mounted) {
        GoRouter.of(context).go(Routes.attente);
      }
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.kyc.erreur);
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TypePiece? type = _type;
    final PieceAEnvoyer? piece = _piece;

    // Ce qui reste a faire, dit d'avance et sans encre d'alerte : le bouton
    // qui attend ne reproche rien quand on l'atteint.
    final String? aFaire = type == null
        ? t.kyc.manqueType
        : piece == null
        ? t.kyc.manquePhoto
        : null;

    return PageShell(
      titre: t.kyc.titre,
      // Le depot s'ouvre depuis le portail d'attente : on y revient sans
      // rien perdre du dossier.
      onRetour: _envoi ? null : () => GoRouter.of(context).go(Routes.attente),
      // Les gestes du depot vivent dans la zone collee, dans l'ordre ou on
      // les fait : a 390 x 844, « Choisir la photo » tombait autrefois sous la
      // ligne de flottaison (dossier_test.dart, 20/09/2026).
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_erreur != null || aFaire != null) ...<Widget>[
            Semantics(
              liveRegion: _erreur != null,
              child: Text(
                _erreur ?? aFaire!,
                textAlign: TextAlign.center,
                style: (_erreur != null ? palette.inkAlert : palette.inkMuted)
                    .applyTo(textes.bodyMedium ?? const TextStyle()),
              ),
            ),
            Ecart.vMd,
          ],
          // Choisir un fichier est une action secondaire : une ligne de lien,
          // jamais un bouton plein (K-56, PHOTO-LIEN-1). Sans type, le
          // selecteur ne saurait pas quelle piece il recoit : le lien n'est
          // pas rendu (un `LienFleche` sans action garde l'encre d'un lien
          // actif) et la phrase au-dessus dit de choisir la piece d'abord.
          if (type != null) ...<Widget>[
            LienFleche(
              libelle: piece == null
                  ? t.kyc.choisirFichier
                  : t.kyc.fichierChoisi,
              onPress: () => unawaited(_choisir(type)),
            ),
            Ecart.vMd,
          ],
          // DECISION-ENTREE-2026-10-17 : inactif tant qu'aucune photo n'est
          // choisie, comme dans les autres apps.
          ActionPrincipale(
            libelle: t.kyc.envoyer,
            enCours: _envoi,
            onPress: piece == null ? null : () => unawaited(_envoyer(piece)),
          ),
          Ecart.vXs,
          Center(
            child: ActionPrincipale(
              key: const Key('piece-deconnexion'),
              libelle: t.attente.seDeconnecter,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: () => unawaited(seDeconnecter(context, ref)),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TexteSansCoupure(t.kyc.intro, style: textes.bodyMedium),
          // KYC-PHOTO-1 : jamais publique, la direction seule.
          Ecart.vSm,
          TexteSansCoupure(t.kyc.confidentialite, style: textes.bodyMedium),
          Ecart.vXxl,
          TexteSansCoupure(t.kyc.typeQuestion, style: textes.titleMedium),
          Ecart.vMd,
          // Les cartes de choix posees a meme la page, jamais dans une autre
          // carte (audit d'entree E14).
          ChoiceCardGroup(
            options: <OptionChoix>[
              OptionChoix(
                valeur: TypePiece.carteIdentite.valeurSql,
                libelle: t.kyc.carteIdentite,
                explication: t.kyc.explicationCarteIdentite,
              ),
              OptionChoix(
                valeur: TypePiece.passeport.valeurSql,
                libelle: t.kyc.passeport,
                explication: t.kyc.explicationPasseport,
              ),
              OptionChoix(
                valeur: TypePiece.titreSejour.valeurSql,
                libelle: t.kyc.titreSejour,
                explication: t.kyc.explicationTitreSejour,
              ),
              // `other` existe en base : « Autre » est un type choisi comme
              // les trois autres, jamais un champ libre (FORM-L11).
              OptionChoix(
                valeur: TypePiece.autre.valeurSql,
                libelle: t.kyc.autrePiece,
                explication: t.kyc.explicationAutre,
                exemple: t.kyc.exempleAutre,
              ),
            ],
            autoriserSaisieLibre: false,
            onChange: (ReponseChoix reponse) => setState(() {
              final String? valeur = reponse.valeurs.isEmpty
                  ? null
                  : reponse.valeurs.first;
              _type = TypePiece.depuisSql(valeur);
              _piece = null;
              _erreur = null;
            }),
          ),
        ],
      ),
    );
  }
}

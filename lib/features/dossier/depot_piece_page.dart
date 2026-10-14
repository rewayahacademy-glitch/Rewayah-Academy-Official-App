import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/signaler_manque.dart';
import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/selecteur_fichier.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/marque_page.dart';
import '../../core/widgets/page_shell.dart';

/// Le depot de la piece d'identite.
///
/// Le genre transmis avec la piece n'est pas une donnee d'etat civil : c'est ce
/// qui decide **quel membre du personnel pourra la regarder** (audit 1.3). Il
/// vient du profil renseigne a l'inscription, pas d'une saisie de plus.
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

  /// Le choix du type, ou le focus revient quand il manque.
  final FocusNode _focusType = FocusNode(debugLabel: 'type-piece');

  /// Le lien « Choisir la photo », ou le focus revient quand elle manque.
  final FocusNode _focusFichier = FocusNode(debugLabel: 'fichier-piece');

  final GlobalKey _cleType = GlobalKey();

  @override
  void dispose() {
    _focusType.dispose();
    _focusFichier.dispose();
    super.dispose();
  }

  /// Bouton jamais grise (BOUTONS-GRISES-1) : presse trop tot, il dit ce qui
  /// manque, l'annonce au lecteur d'ecran et ramene le focus au bon geste.
  void _direManque() {
    final bool sansType = _type == null;
    final String message = sansType ? t.kyc.manqueType : t.kyc.manquePhoto;
    setState(() => _erreur = message);
    if (sansType) {
      final BuildContext? choix = _cleType.currentContext;
      if (choix != null) {
        unawaited(Scrollable.ensureVisible(choix));
      }
    }
    signalerManque(
      context,
      message,
      champ: sansType ? _focusType : _focusFichier,
    );
  }

  Future<void> _choisir() async {
    final TypePiece? type = _type;
    if (type == null) {
      _direManque();
      return;
    }
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

  Future<void> _envoyer() async {
    final PieceAEnvoyer? piece = _piece;
    if (piece == null) {
      _direManque();
      return;
    }
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

    return PageShell(
      // Les DEUX gestes du depot vivent ici, dans l'ordre ou on les fait.
      //
      // Defaut mesure le 20 septembre 2026, et c'en etait un vrai : « Choisir la
      // photo » etait pose en bas de la carte, donc **sous la ligne de
      // flottaison d'un telephone**. A 390 x 844, son centre tombait a 971, hors
      // du viewport. Un enseignant comme un tuteur voyait donc un « Envoyer ma
      // piece » inerte, colle en bas, et devait deviner qu'il fallait faire
      // defiler pour trouver le geste qui vient avant. Les trois tests rouges de
      // `dossier_test.dart` mesuraient exactement cela, et accusaient le test.
      //
      // Le remede n'est pas de faire defiler le test : c'est de mettre le
      // premier geste la ou il est toujours atteignable. Le corps defilant garde
      // ce qui se lit -- le texte et le choix du type -- et la zone collee garde
      // ce qui s'actionne. Rien n'est renomme, aucune etape n'est ajoutee : le
      // parcours du tuteur est inchange.
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_erreur != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                _erreur!,
                textAlign: TextAlign.center,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
          ],
          // Choisir un fichier est une action secondaire : une ligne de lien,
          // jamais un bouton plein (K-56, PHOTO-LIEN-1). "Envoyer" reste l'unique
          // bouton plein.
          // Jamais grises (BOUTONS-GRISES-1) : sans type ou sans photo,
          // l'appui dit ce qui manque au-dessus des actions.
          LienFleche(
            libelle: _piece == null
                ? t.kyc.choisirFichier
                : t.kyc.fichierChoisi,
            focusNode: _focusFichier,
            onPress: () => unawaited(_choisir()),
          ),
          Ecart.vMd,
          ActionPrincipale(
            libelle: t.kyc.envoyer,
            enCours: _envoi,
            onPress: () => unawaited(_envoyer()),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const MarquePage(),
          Ecart.vXxxl,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TexteSansCoupure(t.kyc.titre, style: textes.headlineSmall),
                Ecart.vMd,
                TexteSansCoupure(t.kyc.intro, style: textes.bodyMedium),
                // KYC-PHOTO-1 : jamais publique, la direction seule.
                Ecart.vSm,
                TexteSansCoupure(
                  t.kyc.confidentialite,
                  style: textes.bodyMedium,
                ),
                Ecart.vXxl,
                TexteSansCoupure(t.kyc.typeQuestion, style: textes.titleMedium),
                Ecart.vMd,
                Focus(
                  key: _cleType,
                  focusNode: _focusType,
                  child: ChoiceCardGroup(
                    options: <OptionChoix>[
                      OptionChoix(
                        valeur: TypePiece.carteIdentite.valeurSql,
                        libelle: t.kyc.carteIdentite,
                      ),
                      OptionChoix(
                        valeur: TypePiece.passeport.valeurSql,
                        libelle: t.kyc.passeport,
                      ),
                      OptionChoix(
                        valeur: TypePiece.titreSejour.valeurSql,
                        libelle: t.kyc.titreSejour,
                      ),
                      // `other` existe en base : « Autre » est un type choisi
                      // comme les trois autres. La carte « Autre » generique
                      // ouvrait un champ libre dont le contenu n'etait jamais lu
                      // (FORM-L11) : elle est retiree, la saisie ne servait a rien.
                      OptionChoix(
                        valeur: TypePiece.autre.valeurSql,
                        libelle: t.kyc.autrePiece,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

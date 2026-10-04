import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/vue_etat_communication.dart';
import 'carte_annonce_classe.dart';
import 'port_annonces.dart';

/// L'emplacement des annonces d'une Classe dans sa page (Espace Classe du
/// tuteur et de l'enseignant, Ma classe de l'eleve adulte) : **pose une fois
/// par le socle (COM-F), rempli par la voie COM-ANN** dans ce fichier, sans
/// rouvrir la page hote (`02_DECOUPAGE`, regle des fichiers 3).
///
/// Lecture pour la famille et l'eleve adulte ; pour l'enseignant, l'entree
/// « Publier une annonce » (`Routes.publierAnnoncePour`), seulement avec la
/// capacite rendue par le port (`AnnoncesDeLaClasse.peut`), jamais par un
/// test de role.
///
/// **Ce que l'emplacement rend, etat par etat** (COM-ANN-1) :
///
/// - chargement : rien. La page hote a deja son squelette ; un second
///   squelette qui disparaitrait aussitot ferait sauter la page ;
/// - capacite indisponible (port neutre de production, COM-BR-10) : rien.
///   Aucune source d'annonces n'existe avant BR-1 : l'Espace Classe ne
///   promet pas d'annonces et ne montre pas de faux vide ;
/// - echec de lecture : la section et son erreur, avec « Reessayer » ;
/// - aucune annonce : rien pour qui ne peut que lire ; pour qui peut publier,
///   la section, la phrase du vide et « Publier une annonce » ;
/// - des annonces : la section et une carte par annonce
///   (`CarteAnnonceClasse`, sans « Ouvrir la Classe » : on y est deja).
///
/// **Contrat d'ecart, fixe par le socle** : l'emplacement n'est pas pose au
/// meme endroit dans toutes les pages (en tete chez le tuteur, en fin de
/// section chez l'enseignant et l'eleve adulte). C'est donc la page hote qui
/// dit de quel cote l'ecart se pose et lequel ([ecartAvant], [ecartApres],
/// un `Ecart.*` de la page) ; l'emplacement les rend autour de son contenu,
/// et seulement quand il rend quelque chose.
class AnnoncesDeClasse extends ConsumerStatefulWidget {
  /// Cree l'emplacement pour la Classe [classeId].
  const AnnoncesDeClasse({
    required this.classeId,
    super.key,
    this.ecartAvant,
    this.ecartApres,
  });

  /// La Classe affichee par la page hote. Un identifiant, jamais une
  /// autorisation.
  final String classeId;

  /// L'ecart a poser avant le contenu (emplacement en fin de section), ou
  /// `null`. Jamais rendu tant que l'emplacement est vide.
  final Widget? ecartAvant;

  /// L'ecart a poser apres le contenu (emplacement en tete), ou `null`.
  /// Jamais rendu tant que l'emplacement est vide.
  final Widget? ecartApres;

  /// La cle de la section, pour les tests.
  static const ValueKey<String> cleSection = ValueKey<String>(
    'annonces-de-classe',
  );

  /// La cle du lien « Publier une annonce ».
  static const ValueKey<String> clePublier = ValueKey<String>(
    'annonces-publier',
  );

  @override
  ConsumerState<AnnoncesDeClasse> createState() => _AnnoncesDeClasseState();
}

class _AnnoncesDeClasseState extends ConsumerState<AnnoncesDeClasse> {
  /// Le retour local d'une lecture non confirmee ; `null` : rien a dire.
  String? _retour;

  /// Enregistre la lecture de [annonce], puis relit la Classe. Un echec
  /// garde l'annonce non lue et le dit : rien n'est suppose.
  Future<void> _marquerLue(AnnonceClasse annonce) async {
    if (annonce.lue) return;
    try {
      await ref.read(portAnnoncesProvider).marquerLue(annonce.id);
      if (!mounted) return;
      setState(() => _retour = null);
      ref
        ..invalidate(annoncesDeClasseProvider(widget.classeId))
        ..invalidate(annonceProvider(annonce.id));
    } on CapaciteIndisponible {
      // Aucune source : rien n'est enregistre, rien n'est affirme.
    } on Object {
      if (!mounted) return;
      setState(() => _retour = t.notifications.lectureNonConfirmee);
    }
  }

  /// Le detail, en surface contextuelle (spec section 18) : le texte entier
  /// de l'annonce deja lue par la Classe, sans nouvelle lecture.
  Future<void> _lire(AnnonceClasse annonce) async {
    unawaited(_marquerLue(annonce));
    await AppBottomSheet.ouvrir<void>(
      context,
      titre: t.com.annonces.annonce,
      constructeur: (BuildContext _) =>
          CarteAnnonceClasse(annonce: annonce, complete: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AnnoncesDeLaClasse> valeur = ref.watch(
      annoncesDeClasseProvider(widget.classeId),
    );
    final Widget? contenu = _contenu(context, valeur);
    if (contenu == null) return const SizedBox.shrink();
    return Column(
      key: AnnoncesDeClasse.cleSection,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[?widget.ecartAvant, contenu, ?widget.ecartApres],
    );
  }

  /// Le contenu de la section, ou `null` quand l'emplacement ne rend rien.
  Widget? _contenu(BuildContext context, AsyncValue<AnnoncesDeLaClasse> v) {
    final a = t.com.annonces;
    // Une valeur deja la reste affichee pendant un rafraichissement.
    if (v.hasValue && !v.hasError) {
      return _annonces(context, v.requireValue);
    }
    if (v.hasError) {
      final Object erreur = v.error!;
      if (erreur is CapaciteIndisponible) return null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SectionHeader(titre: a.section),
          Ecart.vMd,
          VueEtatCommunication(
            etat: EtatCommunication.erreur,
            onReessayer: () =>
                ref.invalidate(annoncesDeClasseProvider(widget.classeId)),
          ),
        ],
      );
    }
    return null;
  }

  Widget? _annonces(BuildContext context, AnnoncesDeLaClasse vue) {
    final a = t.com.annonces;
    final bool publier = vue.peut(CapaciteAnnonces.publier);
    if (vue.annonces.isEmpty && !publier) return null;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? retour = _retour;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(
          titre: a.section,
          compteur: vue.annonces.isEmpty ? null : vue.annonces.length,
        ),
        Ecart.vMd,
        if (vue.annonces.isEmpty)
          Text(
            a.videPublier,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        // Des annonces independantes : des cartes detachees, separees de 16
        // (K-55), jamais collees.
        if (vue.annonces.isNotEmpty)
          PileCartes(
            children: <Widget>[
              for (final AnnonceClasse annonce in vue.annonces)
                CarteAnnonceClasse(
                  key: ValueKey<String>('annonce-${annonce.id}'),
                  annonce: annonce,
                  onLire: () => unawaited(_lire(annonce)),
                  onMarquerLue: () => unawaited(_marquerLue(annonce)),
                ),
            ],
          ),
        if (retour != null) ...<Widget>[
          Ecart.vSm,
          LocalFeedback(message: retour),
        ],
        if (publier) ...<Widget>[
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: LienFleche(
              key: AnnoncesDeClasse.clePublier,
              libelle: a.publier,
              alignerEnFin: true,
              onPress: () =>
                  GoRouter.of(context)
                      .go(Routes.publierAnnoncePour(widget.classeId)),
            ),
          ),
        ],
      ],
    );
  }
}

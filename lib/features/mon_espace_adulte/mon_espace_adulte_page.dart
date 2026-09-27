// Mon espace de l'eleve adulte (EA-4, planche 1.3, 00_MAQUETTES 1.3,
// UX_REVIEW_07 ligne 5).
//
// Aucun composant neuf (K-51) : la carte d'identite et la carte « Se
// deconnecter » sont celles du Compte du tuteur (`CarteIdentiteCompte`,
// `CarteDeconnexion`), les rubriques sont des `GroupeReglages`, la photo est
// `PhotoEleve` (K-44), l'apparition `ElementEchelonne` (lib/core/mouvement).
//
// Composition : l'identite ; « Mon compte » (Mes informations, Cours et
// acces, Paiements, Mes accords, Connexion et securite, Preferences) ; la
// ligne famille UNIQUE, dont le libelle suit la situation rendue (« Ajouter
// ma famille », « Ma famille » ou, pour le second adulte, « Forfait
// famille ») ; « Aide et support » ; la deconnexion a part, en bas. Deux
// colonnes a partir du seuil etendu, comme le Compte du tuteur.
//
// Rectifications (00_MAQUETTES 1.3, C) : ni pastille « Nouveau », ni
// engrenage (les Preferences n'ont qu'une place, la ligne), ni
// « Abonnements » (il n'y a pas d'abonnement, F9) ; aucune pastille « Compte
// valide » pour l'etat normal (E12) : la carte n'en porte une que pour une
// exception (`pastilleEtatNormal: false`). « A propos » de la planche devient
// « Informations legales », la page existante du Compte (textes acceptes, leur
// version et leur date) : aucune page « A propos » n'existe, et une rubrique
// ne se cree pas sans contenu rendu (rien d'invente).
//
// L'identite est lue par le port existant, `identiteTitulaireProvider`
// (« l'identite de la personne connectee », lot E) : branche en production le
// jour ou ce port l'est. Le seul provider propre a l'ecran,
// [monEspaceAdulteProvider], ne porte que ce que ce port n'a pas (la ligne
// famille et la cle de la photo) et n'a aucune source serveur (EA-BR-07) : il
// rend `CapaciteIndisponible`, la demonstration le surcharge (K-28). Les deux
// lectures sont independantes : une panne de l'une ne masque pas l'autre, et
// les rubriques restent en place dans tous les cas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_identite_titulaire.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/apparition_douce.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../compte/carte_rubriques.dart' show ColonneSousPage;
import '../compte/compte_tuteur_page.dart'
    show CarteDeconnexion, CarteIdentiteCompte;
import '../compte/donnees_compte.dart' show identiteTitulaireProvider;
import '../foyer/photo_eleve.dart';

/// La ligne famille de Mon espace (UX_REVIEW_07 ligne 5 a) : jamais deux a
/// la fois.
enum LigneFamilleAdulte {
  /// Adulte seul : « Ajouter ma famille ».
  ajouterMaFamille,

  /// Titulaire d'un foyer : « Ma famille ».
  maFamille,

  /// Second adulte : « Forfait famille ».
  forfaitFamille,
}

/// Les rubriques de Mon espace, dans leur ordre.
enum RubriqueMonEspace {
  /// Mes informations.
  informations,

  /// Cours et acces.
  coursAcces,

  /// Paiements personnels.
  paiements,

  /// Mes accords (charte 09 section 3).
  accords,

  /// Connexion et securite.
  securite,

  /// Preferences.
  preferences,

  /// Aide et contact.
  aide,

  /// Informations legales.
  informationsLegales,
}

/// Ce que Mon espace lit en plus de l'identite (`identiteTitulaireProvider`).
@immutable
class MonEspaceAdulteVM {
  /// Cree la vue.
  const MonEspaceAdulteVM({this.cleAvatar, this.ligneFamille});

  /// La cle de la photo de la personne connectee, `null` sans photo
  /// (initiales en repli).
  final String? cleAvatar;

  /// La ligne famille rendue ; `null` : aucune ligne.
  final LigneFamilleAdulte? ligneFamille;
}

/// La ligne famille et la photo de Mon espace. **Aucune source serveur a ce
/// jour** (EA-BR-07) : `CapaciteIndisponible`, et alors aucune ligne famille,
/// les initiales en repli.
final FutureProvider<MonEspaceAdulteVM> monEspaceAdulteProvider =
    FutureProvider<MonEspaceAdulteVM>(
      (Ref _) => Future<MonEspaceAdulteVM>.error(
        const CapaciteIndisponible('mon_espace_eleve_adulte'),
      ),
    );

/// Mon espace : identite, rubriques groupees, ligne famille, deconnexion.
class MonEspaceAdultePage extends ConsumerWidget {
  /// Cree la page.
  const MonEspaceAdultePage({super.key, this.onOuvrir, this.onFamille});

  /// Ouvre une rubrique ; `null` : les rubriques ne menent nulle part.
  final void Function(RubriqueMonEspace rubrique)? onOuvrir;

  /// Ouvre la ligne famille.
  final void Function(LigneFamilleAdulte ligne)? onFamille;

  /// La cle de la ligne famille.
  static const Key ligneFamilleKey = Key('adulte.monEspace.famille');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MonEspaceAdulteVM> lecture = ref.watch(
      monEspaceAdulteProvider,
    );
    final MonEspaceAdulteVM? vue = lecture.hasValue && !lecture.hasError
        ? lecture.requireValue
        : null;
    final bool large = AppGabarit.de(context).estLarge;
    final double ecart = large ? AppSpacing.lg : AppSpacing.md;
    final LigneFamilleAdulte? famille = vue?.ligneFamille;

    LigneRubrique rubrique(
      RubriqueMonEspace r,
      AppIcon icone,
      String libelle, {
      String? legende,
      String? valeur,
    }) => LigneRubrique(
      icone: icone,
      libelle: libelle,
      legende: legende,
      valeur: valeur,
      onPress: onOuvrir == null ? null : () => onOuvrir!(r),
    );

    final Widget identite = BlocAsynchrone<IdentiteTitulaire>(
      valeur: ref.watch(identiteTitulaireProvider),
      squelette: const Skeleton(hauteur: AppSpacing.respiration * 2),
      onReessayer: () => ref.invalidate(identiteTitulaireProvider),
      construire: (IdentiteTitulaire lue) => CarteIdentiteCompte(
        identite: lue,
        large: large,
        role: t.adulte.monEspace.role,
        pastilleEtatNormal: false,
        photo: (double diametre) => PhotoEleve(
          prenom: lue.prenom,
          cleAvatar: vue?.cleAvatar,
          diametre: diametre,
        ),
      ),
    );

    final Widget compte = GroupeReglages(
      titre: t.adulte.monEspace.monCompte,
      lignes: <LigneRubrique>[
        rubrique(
          RubriqueMonEspace.informations,
          AppIcons.profil,
          t.adulte.monEspace.informations,
          legende: t.compte.tuteur.informations.resume,
        ),
        rubrique(
          RubriqueMonEspace.coursAcces,
          AppIcons.classes,
          t.adulte.monEspace.coursAcces,
          legende: t.adulte.monEspace.coursAccesLegende,
        ),
        rubrique(
          RubriqueMonEspace.paiements,
          AppIcons.finance,
          t.adulte.monEspace.paiements,
          legende: t.adulte.monEspace.paiementsLegende,
        ),
        rubrique(
          RubriqueMonEspace.accords,
          AppIcons.controleQualite,
          t.adulte.monEspace.accords,
          legende: t.adulte.monEspace.accordsLegende,
        ),
        rubrique(
          RubriqueMonEspace.securite,
          AppIcons.verrou,
          t.compte.tuteur.securite.titre,
          legende: t.adulte.monEspace.securiteLegende,
        ),
        rubrique(
          RubriqueMonEspace.preferences,
          AppIcons.reglages,
          t.compte.tuteur.preferences,
          legende: t.compte.reglagesDetail,
        ),
      ],
    );

    final Widget? ligneFamille = famille == null
        ? null
        : KeyedSubtree(
            key: ligneFamilleKey,
            child: GroupeReglages(
              lignes: <LigneRubrique>[
                LigneRubrique(
                  icone: AppIcons.foyer,
                  libelle: switch (famille) {
                    LigneFamilleAdulte.ajouterMaFamille =>
                      t.adulte.famille.ajouter,
                    LigneFamilleAdulte.maFamille => t.adulte.famille.maFamille,
                    LigneFamilleAdulte.forfaitFamille =>
                      t.adulte.famille.forfaitFamille,
                  },
                  // Une seule ligne secondaire, sous « Ajouter ma famille »
                  // seulement : la 1re phrase du doc section 19 (ligne 5 b).
                  legende: famille == LigneFamilleAdulte.ajouterMaFamille
                      ? t.adulte.famille.ajouterLegende
                      : null,
                  onPress: onFamille == null ? null : () => onFamille!(famille),
                ),
              ],
            ),
          );

    final Widget aide = GroupeReglages(
      titre: t.compte.tuteur.aide.titre,
      lignes: <LigneRubrique>[
        rubrique(
          RubriqueMonEspace.aide,
          AppIcons.lecon,
          t.compte.tuteur.aide.ligne,
          valeur: t.compte.nonDisponible,
        ),
        rubrique(
          RubriqueMonEspace.informationsLegales,
          AppIcons.journal,
          t.compte.tuteur.aide.legal,
        ),
      ],
    );

    Widget pile(List<Widget> blocs) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < blocs.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: ecart * 2),
          ElementEchelonne(index: i, child: blocs[i]),
        ],
      ],
    );

    return PageShell(
      titre: t.adulte.nav.monEspace,
      child: LayoutBuilder(
        builder: (BuildContext _, BoxConstraints contraintes) {
          final bool deuxColonnes =
              contraintes.maxWidth >= AppGabarit.seuilEtendu;
          final List<Widget> droite = <Widget>[?ligneFamille, aide];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              identite,
              SizedBox(height: ecart * 2),
              if (deuxColonnes)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 11, child: pile(<Widget>[compte])),
                    SizedBox(width: ecart),
                    Expanded(flex: 10, child: pile(droite)),
                  ],
                )
              else
                pile(<Widget>[compte, ...droite]),
              SizedBox(height: ecart * 2),
              const CarteDeconnexion(),
            ],
          );
        },
      ),
    );
  }
}

/// La page d'une rubrique de Mon espace qui n'a encore aucune source :
/// « Mes accords » (EA-BR-08) et « Cours et acces » (EA-BR-09). Aucun ecran
/// neuf : l'en-tete de sous-page du Compte (`PageShell`, `ColonneSousPage`)
/// et l'etat systeme « indisponible », comme la page des paiements sans
/// service. Rien n'est promis ni invente.
class RubriqueIndisponibleAdultePage extends StatelessWidget {
  /// Cree la page.
  const RubriqueIndisponibleAdultePage({
    required this.rubrique,
    this.onRetour,
    super.key,
  }) : assert(
         rubrique == RubriqueMonEspace.accords ||
             rubrique == RubriqueMonEspace.coursAcces,
         'Seules Mes accords et Cours et acces sont sans page.',
       );

  /// La rubrique : `accords` ou `coursAcces`.
  final RubriqueMonEspace rubrique;

  /// Le retour vers Mon espace.
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context) {
    final bool accords = rubrique == RubriqueMonEspace.accords;
    return PageShell(
      titre: accords
          ? t.adulte.monEspace.accords
          : t.adulte.monEspace.coursAcces,
      onRetour: onRetour,
      child: ColonneSousPage(
        child: EtatSysteme(
          nature: NatureEtat.indisponible,
          titre: accords
              ? t.adulte.monEspace.pageAccords.indisponibleTitre
              : t.adulte.monEspace.pageCoursAcces.indisponibleTitre,
          phrase: accords
              ? t.adulte.monEspace.pageAccords.indisponiblePhrase
              : t.adulte.monEspace.pageCoursAcces.indisponiblePhrase,
          dependance: accords ? 'EA-BR-08' : 'EA-BR-09',
        ),
      ),
    );
  }
}

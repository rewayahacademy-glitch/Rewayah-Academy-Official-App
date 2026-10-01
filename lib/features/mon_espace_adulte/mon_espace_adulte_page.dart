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
//
// Corrections EA-4c (revue du 27/09) :
// - la ligne famille passe par `BlocAsynchrone` : squelette pendant la
//   lecture, erreur avec « Reessayer », indisponible dit comme tel ; elle ne
//   disparait plus en silence ; sans reseau, un echec se dit « hors ligne »
//   (meme regle que le Foyer) ;
// - le second adulte rattache voit, sous « Forfait famille », les
//   « Paiements du foyer » (decision E3, spec section 7.1) : la meme page que
//   le titulaire, jamais le Foyer ni les enfants (F6, F7) ;
// - « Non disponible » n'est plus pose en dur : il suit la source de la page
//   d'arrivee (paiements, aide), ou l'absence de toute source (Mes accords,
//   Cours et acces, EA-BR-08 et 09) ; les legendes ne promettent plus une
//   action que la page dit impossible, et ne melangent plus « mes » et
//   « vos » ;
// - (revue d'EA-4c) une seule entree vers les paiements : le second adulte
//   rattache n'a que « Paiements du foyer », la page d'arrivee porte ce
//   titre ; hors ligne se dit une seule fois (bandeau et un seul etat, un
//   seul « Reessayer » qui relit les deux lectures, K-42) ;
// - sur bureau, la ligne famille suit « Mon compte » dans la colonne de debut
//   (l'ordre du telephone) et la colonne de fin commence par le titre « Aide
//   et support », a la hauteur du titre « Mon compte ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_identite_titulaire.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/apparition_douce.dart';
import '../../core/reseau/service_reseau.dart';
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
import '../compte/donnees_compte.dart'
    show
        canalSupportProvider,
        identiteTitulaireProvider,
        paiementsFoyerProvider;
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

  /// Paiements du foyer, sous « Forfait famille » : le second adulte
  /// rattache seulement (decision E3).
  paiementsFoyer,
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

  /// La cle de la ligne famille (le groupe rendu, jamais son etat).
  static const Key ligneFamilleKey = Key('adulte.monEspace.famille');

  /// La cle du bloc de la ligne famille : squelette, erreur, indisponible
  /// ou la ligne elle-meme.
  static const Key blocFamilleKey = Key('adulte.monEspace.famille.bloc');

  /// La cle de l'unique etat « hors ligne » de la page.
  static const Key horsLigneKey = Key('adulte.monEspace.horsLigne');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MonEspaceAdulteVM> lecture = ref.watch(
      monEspaceAdulteProvider,
    );
    final MonEspaceAdulteVM? vue = lecture.hasValue && !lecture.hasError
        ? lecture.requireValue
        : null;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final bool large = AppGabarit.de(context).estLarge;
    final double ecart = large ? AppSpacing.lg : AppSpacing.md;

    // « Non disponible » suit la source de la page d'arrivee : les paiements
    // (DB-CPT-03) et l'aide (DB-CPT-07) le disent tant que leur port est
    // indisponible ou sans canal, jamais en dur.
    final String? paiementsValeur = _indisponible(
      ref.watch(paiementsFoyerProvider),
    );
    final AsyncValue<Object?> canal = ref.watch(canalSupportProvider);
    final String? aideValeur =
        _indisponible(canal) ??
        (canal.hasValue && !canal.hasError && canal.requireValue == null
            ? t.compte.nonDisponible
            : null);

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

    // Sans reseau, un echec se dit « hors ligne », pas « le serveur n'a pas
    // repondu » (meme regle que le Foyer) ; une capacite absente reste dite
    // indisponible, hors ligne ou non.
    bool echecHorsLigne(AsyncValue<Object?> v) =>
        horsLigne && v.hasError && v.error is! CapaciteIndisponible;

    final AsyncValue<IdentiteTitulaire> identiteLue = ref.watch(
      identiteTitulaireProvider,
    );
    // Hors ligne se dit UNE fois (K-42, comme le Foyer) : le bandeau de
    // `PageShell` et un seul etat, a la place du premier bloc en echec, dont
    // l'unique « Reessayer » relit les deux lectures. L'autre bloc en echec
    // garde son squelette, sans bouton.
    final bool identiteHorsLigne = echecHorsLigne(identiteLue);
    final bool familleHorsLigne = echecHorsLigne(lecture);
    void relireTout() {
      ref
        ..invalidate(identiteTitulaireProvider)
        ..invalidate(monEspaceAdulteProvider);
    }

    Widget horsLigneUnique() => EtatSysteme(
      key: horsLigneKey,
      nature: NatureEtat.horsLigne,
      onAction: relireTout,
    );
    final Widget identite = identiteHorsLigne
        ? horsLigneUnique()
        : BlocAsynchrone<IdentiteTitulaire>(
            valeur: identiteLue,
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
        // Aucune source (EA-BR-09) : la page d'arrivee le dit toujours.
        rubrique(
          RubriqueMonEspace.coursAcces,
          AppIcons.classes,
          t.adulte.monEspace.coursAcces,
          // `coursAccesLegende` : libelle provisoire, lexique D4.
          legende: t.adulte.monEspace.coursAccesLegende,
          valeur: t.compte.nonDisponible,
        ),
        // Une seule entree vers les paiements (revue EA-4c) : le second
        // adulte rattache n'a pas de paiement propre lisible, il a ceux du
        // foyer (E3), sous « Forfait famille ». Tant que la ligne famille
        // n'est pas lue, la rubrique reste.
        if (vue?.ligneFamille != LigneFamilleAdulte.forfaitFamille)
          rubrique(
            RubriqueMonEspace.paiements,
            AppIcons.finance,
            t.adulte.monEspace.paiements,
            // `paiementsLegende` : libelle provisoire, lexique D4.
            legende: t.adulte.monEspace.paiementsLegende,
            valeur: paiementsValeur,
          ),
        // Aucune source (EA-BR-08) : la page d'arrivee le dit toujours.
        rubrique(
          RubriqueMonEspace.accords,
          AppIcons.controleQualite,
          t.adulte.monEspace.accords,
          // `accordsLegende` : libelle provisoire, lexique D4.
          legende: t.adulte.monEspace.accordsLegende,
          valeur: t.compte.nonDisponible,
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

    Widget groupeFamille(LigneFamilleAdulte famille) => KeyedSubtree(
      key: ligneFamilleKey,
      child: GroupeReglages(
        lignes: <LigneRubrique>[
          LigneRubrique(
            icone: AppIcons.foyer,
            libelle: switch (famille) {
              LigneFamilleAdulte.ajouterMaFamille => t.adulte.famille.ajouter,
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
          // Le second adulte rattache voit les paiements du foyer (E3, spec
          // section 7.1), sans en etre le gestionnaire : la page des
          // paiements, jamais le Foyer ni les enfants (F6, F7). Source
          // serveur : EA-BR-16.
          if (famille == LigneFamilleAdulte.forfaitFamille)
            rubrique(
              RubriqueMonEspace.paiementsFoyer,
              AppIcons.finance,
              t.adulte.famille.paiementsFoyer,
              valeur: paiementsValeur,
            ),
        ],
      ),
    );

    // La ligne famille : absente seulement quand la lecture a abouti sans
    // ligne (la situation n'en rend aucune) ; sinon son etat se dit.
    final bool sansLigne = vue != null && vue.ligneFamille == null;
    final Object? erreurFamille = lecture.hasError ? lecture.error : null;
    final Widget? famille = sansLigne
        ? null
        : KeyedSubtree(
            key: blocFamilleKey,
            // Titre et phrase : libelle provisoire, lexique D4.
            child: erreurFamille is CapaciteIndisponible
                ? EtatSysteme(
                    nature: NatureEtat.indisponible,
                    titre: t.adulte.famille.indisponibleTitre,
                    phrase: t.adulte.famille.indisponiblePhrase,
                    dependance: erreurFamille.dependance,
                  )
                : familleHorsLigne
                ? (identiteHorsLigne
                      ? const Skeleton.liste(lignes: 1)
                      : horsLigneUnique())
                : BlocAsynchrone<MonEspaceAdulteVM>(
                    valeur: lecture,
                    squelette: const Skeleton.liste(lignes: 1),
                    onReessayer: () => ref.invalidate(monEspaceAdulteProvider),
                    construire: (MonEspaceAdulteVM v) => v.ligneFamille == null
                        ? const SizedBox.shrink()
                        : groupeFamille(v.ligneFamille!),
                  ),
          );

    final Widget aide = GroupeReglages(
      titre: t.compte.tuteur.aide.titre,
      lignes: <LigneRubrique>[
        rubrique(
          RubriqueMonEspace.aide,
          AppIcons.lecon,
          t.compte.tuteur.aide.ligne,
          valeur: aideValeur,
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
          // L'ordre du telephone, lu colonne par colonne : Mon compte puis la
          // ligne famille au debut, l'aide a la fin. Chaque colonne commence
          // par un titre de groupe : leurs surfaces partent a la meme hauteur.
          final List<Widget> debut = <Widget>[compte, ?famille];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              identite,
              SizedBox(height: ecart * 2),
              if (deuxColonnes)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 11, child: pile(debut)),
                    SizedBox(width: ecart),
                    Expanded(flex: 10, child: pile(<Widget>[aide])),
                  ],
                )
              else
                pile(<Widget>[...debut, aide]),
              SizedBox(height: ecart * 2),
              const CarteDeconnexion(),
            ],
          );
        },
      ),
    );
  }

  /// « Non disponible » quand la source dit qu'elle n'existe pas encore.
  static String? _indisponible(AsyncValue<Object?> v) =>
      v.hasError && v.error is CapaciteIndisponible
      ? t.compte.nonDisponible
      : null;
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

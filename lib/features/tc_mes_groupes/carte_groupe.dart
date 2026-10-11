import 'package:flutter/material.dart';

import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_groupe/palette_groupe.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/status_pill.dart';
import 'photo_enseignant.dart';

/// Le repere de couleur du groupe.
///
/// **Jamais le seul identifiant.** Il est pose a cote du nom, pas a sa place,
/// et il n'est pas expose aux technologies d'assistance : une couleur ne se lit
/// pas a voix haute, et la doubler d'un libelle de couleur n'apprendrait rien.
/// C'est l'invariant `J7` du depot.
class LisereGroupe extends StatelessWidget {
  /// Cree un repere de couleur.
  const LisereGroupe({required this.jeton, super.key});

  /// Le jeton de la palette administree.
  final JetonCouleurGroupe jeton;

  @override
  Widget build(BuildContext context) {
    final AppColorPair teinte = PaletteGroupe.paire(context, jeton);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AppRadius.arrondiFull,
        child: SizedBox(
          width: AppSpacing.xs,
          height: AppSpacing.xxl,
          child: ColoredBox(color: teinte.background),
        ),
      ),
    );
  }
}

/// La carte du Groupe dans « Mes groupes ».
///
/// **Toute la carte ouvre l'Espace Groupe** ; le bouton « Rejoindre »
/// n'apparait que lorsque la fenetre d'acces est ouverte, et cette decision
/// vient de l'horloge, jamais de l'ecran.
///
/// Ce que la carte montre, et pourquoi :
///
/// - un repere de couleur **et** le nom du groupe, jamais la couleur seule ;
/// - la photo de l'enseignant, obligatoire, dont l'absence est **dite** ;
/// - le titre Sayyid ou Sayyida, jamais Ustaz (decision `D-02`) ;
/// - le cours et le niveau en langage humain, jamais un code interne ;
/// - la capacite reelle, `4 / 5` ou `3 / 4`, **lue de la donnee serveur** ;
/// - la prochaine seance, sa duree et un compte a rebours.
///
/// Elle reste une carte, pas un tableau de bord : tout le detail vit dans
/// l'Espace Groupe, a un tap.
class CarteGroupe extends StatelessWidget {
  /// Cree une carte de groupe.
  const CarteGroupe({
    required this.groupe,
    super.key,
    this.onOuvrir,
    this.onRejoindre,
    this.urlPhotoEnseignant,
    this.rejoindreRetire = false,
  });

  /// Le groupe montre.
  final GroupSummaryVM groupe;

  /// Ce que fait un tap sur la carte.
  final VoidCallback? onOuvrir;

  /// Ce que fait le bouton « Rejoindre ».
  final VoidCallback? onRejoindre;

  /// L'URL signee de la photo, quand l'hote sait la resoudre.
  final String? urlPhotoEnseignant;

  /// Vrai quand les seances de l'eleve sont fermees (FI-9a, guide §1.7) :
  /// une limite de droit, pas une panne. Le bouton est alors absent, jamais
  /// grise ; l'hote dit l'etat avec la copie neutre, sans cause. La carte
  /// garde son geste d'ouverture : l'Espace Groupe reste lisible.
  final bool rejoindreRetire;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final SessionClockVM? horloge = groupe.horloge;

    return AppCard(
      onPress: onOuvrir,
      libelleSemantique: LibellesGroupe.ouvrirGroupe(groupe.libelle),
      entete: _Entete(groupe: groupe),
      actions: groupe.rejoindreOuvert && !rejoindreRetire
          ? ActionPrincipale(
              libelle: LibellesGroupe.rejoindre,
              onPress: onRejoindre,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Enseignant(groupe: groupe, urlPhotoEnseignant: urlPhotoEnseignant),
          Ecart.vLg,
          if (horloge == null || groupe.prochaineSeance == null)
            // L'etat reel de la base aujourd'hui, dit sans detour : un groupe
            // existe sans qu'aucune occurrence ait ete materialisee.
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    LibellesGroupe.aucuneSeance,
                    style: textes.titleSmall ?? const TextStyle(),
                  ),
                  Ecart.vXs,
                  Text(
                    LibellesGroupe.aucuneSeanceDetail,
                    style: palette.inkMuted.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
                ],
              ),
            )
          else
            _ProchaineSeance(groupe: groupe, horloge: horloge),
        ],
      ),
    );
  }
}

/// Le nom du groupe, son repere de couleur et sa capacite reelle.
class _Entete extends StatelessWidget {
  const _Entete({required this.groupe});

  final GroupSummaryVM groupe;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle styleNom = textes.titleMedium ?? const TextStyle();
    final TextStyle styleCapacite = textes.labelLarge ?? const TextStyle();
    final String capacite = LibellesGroupe.capacite(
      membres: groupe.nombreMembres,
      seuil: groupe.seuilMax,
    );

    final Widget nom = Text(groupe.libelle, style: styleNom);
    // `4 / 5` ou `3 / 4` : jamais un plafond ecrit dans cet ecran. La
    // phrase complete est reservee aux technologies d'assistance, qui
    // liraient « quatre barre oblique cinq » sans elle.
    final Widget valeur = Semantics(
      label: LibellesGroupe.capacitePhrase(
        membres: groupe.nombreMembres,
        seuil: groupe.seuilMax,
      ),
      child: ExcludeSemantics(child: Text(capacite, style: styleCapacite)),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        // AR-TC-1 : la capacite reste a cote du nom tant que le mot le plus
        // long du nom y tient entier ; sinon (320 px, texte x2, « 4 من 5 »)
        // elle passe sous le nom, et aucun mot n'est coupe.
        final TextScaler echelle = MediaQuery.textScalerOf(context);
        final TextDirection sens = Directionality.of(context);
        double largeur(String texte, TextStyle style) {
          final TextPainter mesure = TextPainter(
            text: TextSpan(text: texte, style: style),
            textDirection: sens,
            textScaler: echelle,
            maxLines: 1,
          )..layout();
          final double l = mesure.width;
          mesure.dispose();
          return l;
        }
        final double motLePlusLong = groupe.libelle
            .split(RegExp(r'\s+'))
            .map((String mot) => largeur(mot, styleNom))
            .fold(0, (double a, double b) => a > b ? a : b);
        final bool aCote =
            AppSpacing.xs +
                2 * AppSpacing.md +
                motLePlusLong +
                largeur(capacite, styleCapacite) <=
            contraintes.maxWidth;

        final Widget ligneNom = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            LisereGroupe(jeton: groupe.couleurJeton),
            Ecart.hMd,
            Expanded(child: nom),
            if (aCote) ...<Widget>[Ecart.hMd, valeur],
          ],
        );
        if (aCote) return ligneNom;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ligneNom,
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.xs + AppSpacing.md,
              ),
              child: valeur,
            ),
          ],
        );
      },
    );
  }
}

/// La photo, le titre, le nom, le cours et le niveau.
class _Enseignant extends StatelessWidget {
  const _Enseignant({required this.groupe, this.urlPhotoEnseignant});

  final GroupSummaryVM groupe;
  final String? urlPhotoEnseignant;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final EnseignantVM enseignant = groupe.enseignant;
    final String coursEtNiveau = LibellesGroupe.coursEtNiveau(
      cours: groupe.nomCours,
      niveau: groupe.niveauHumain,
    );

    // AVATAR-1 : couple avatar + nom du composant partage, nom et une ligne
    // de role (cours et niveau) ; les etats se lisent dessous.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AvatarNom.enLigne(
          prenom: enseignant.nomAffichage,
          nom: LibellesGroupe.enseignantNomme(enseignant),
          pays: enseignant.pays,
          role: coursEtNiveau.isEmpty ? null : coursEtNiveau,
          ecart: AppSpacing.lg,
          styleNom: textes.titleSmall,
          styleRole: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
          avatar: PhotoEnseignant(
            enseignant: enseignant,
            urlSignee: urlPhotoEnseignant,
          ),
        ),
        if (enseignant.photoManquante) ...<Widget>[
          Ecart.vSm,
          // Un etat, pas une couleur : `StatusPill` refuse par construction
          // une pastille sans libelle.
          StatusPill(
            libelle: LibellesGroupe.photoManquante,
            ton: TonEtat.avertissement,
          ),
        ],
        if (groupe.complet) ...<Widget>[
          Ecart.vSm,
          StatusPill(libelle: LibellesGroupe.complet, ton: TonEtat.neutre),
        ],
      ],
    );
  }
}

/// Le jour, la date, l'heure, la duree et le compte a rebours.
class _ProchaineSeance extends StatelessWidget {
  const _ProchaineSeance({required this.groupe, required this.horloge});

  final GroupSummaryVM groupe;
  final SessionClockVM horloge;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final OccurrenceSeance occurrence = groupe.prochaineSeance!;
    final HorlogeAffichee mienne = horloge.horlogeUtilisateur;

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Une seance en cours se reconnait au premier coup d'oeil
          // (ON-AIR-1) ; la ligne d'etat garde le temps restant.
          if (horloge.enDirect) ...<Widget>[
            const PastilleEtatSeance(etat: EtatPastilleSeance.enDirect),
            Ecart.vSm,
          ],
          Text(
            LibellesGroupe.prochainCours,
            style: palette.inkMuted.applyTo(
              textes.labelSmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          // La date et l'heure arrivent **deja rendues** : aucun widget du
          // Teaching Core ne convertit un fuseau.
          Text(
            LibellesGroupe.joindre(
              mienne.dateLocaleRendue,
              mienne.heureLocaleRendue,
            ),
            style: textes.titleSmall ?? const TextStyle(),
          ),
          Ecart.vXs,
          Text(
            LibellesGroupe.joindre(
              LibellesGroupe.dureeCarte(occurrence.duree),
              LibellesGroupe.ligneEtat(horloge),
            ),
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

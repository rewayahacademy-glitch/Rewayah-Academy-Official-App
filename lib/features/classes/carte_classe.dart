import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_pill.dart';
import 'domaine/classe_vm.dart';
import 'libelles_classes.dart';

/// L'unique action contextuelle d'une carte de Classe.
///
/// **Une carte, un bouton.** Candidater pour l'enseignant, Inscrire pour le
/// tuteur, Rejoindre pour l'eleve, Publier pour l'administration : ce qui
/// change d'un role a l'autre est ce bouton, jamais la carte.
@immutable
class ActionCarte {
  /// Cree une action.
  const ActionCarte({
    required this.libelle,
    this.onPress,
    this.niveau = NiveauAction.principale,
    this.enCours = false,
  });

  /// Le libelle, un verbe et son objet.
  final String libelle;

  /// L'action. `null` rend le bouton inerte, et le dit.
  final VoidCallback? onPress;

  /// Le niveau hierarchique.
  final NiveauAction niveau;

  /// Vrai pendant l'envoi.
  final bool enCours;
}

/// La carte compacte d'une Classe.
///
/// **Une carte, pas un tableau de bord.** Ce qui se lit d'un coup d'oeil :
/// le nom, le programme et le niveau en langage humain, le creneau local, la
/// duree, la capacite reelle, l'enseignant s'il est affecte, et un seul bouton.
/// Le reste (fuseau, seuil minimal, prochaine seance, etat) attend derriere
/// « Voir le detail » : c'est de la divulgation progressive, pas une
/// omission.
///
/// Aucun identifiant technique n'y est rendu, aucun jour ni aucune heure en
/// chiffre brut : `LibellesClasses` compose les mots. La capacite vient
/// **toujours** de la donnee serveur (`ClasseVM.capacite`), jamais d'un nombre
/// ecrit ici.
class CarteClasse extends StatefulWidget {
  /// Cree une carte.
  const CarteClasse({
    required this.classe,
    super.key,
    this.action,
    this.onOuvrir,
    this.pied,
    this.fuseauUtilisateur,
    this.detailOuvert = false,
  });

  /// La Classe montree.
  final ClasseVM classe;

  /// Le bouton contextuel, quand il y en a un.
  final ActionCarte? action;

  /// Ce que fait un tap sur la carte entiere. `null` : la carte se lit.
  final VoidCallback? onOuvrir;

  /// Ce qui se pose sous le contenu, avant le bouton : une porte d'entree, un
  /// retour local.
  final Widget? pied;

  /// Le fuseau de la personne qui regarde, pour dire la ville quand le
  /// creneau vit ailleurs.
  final String? fuseauUtilisateur;

  /// Vrai pour ouvrir le detail des le premier rendu.
  final bool detailOuvert;

  /// La cle du bloc de detail, pour les tests.
  static const Key cleDetail = Key('carte-classe-detail');

  @override
  State<CarteClasse> createState() => _CarteClasseEtat();
}

class _CarteClasseEtat extends State<CarteClasse> {
  late bool _ouvert = widget.detailOuvert;

  @override
  Widget build(BuildContext context) {
    final ClasseVM classe = widget.classe;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final ActionCarte? action = widget.action;
    final EnseignantClasse? enseignant = classe.enseignant;

    return AppCard(
      onPress: widget.onOuvrir,
      libelleSemantique: t.classes.carte.ouvrir(libelle: classe.libelle),
      entete: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              classe.libelle,
              style: textes.titleMedium ?? const TextStyle(),
            ),
          ),
          Ecart.hMd,
          // `4 / 5` : la phrase complete est reservee aux technologies
          // d'assistance, qui liraient « quatre barre oblique cinq » sans elle.
          if (classe.capaciteConnue)
            Semantics(
              label: LibellesClasses.capacitePhrase(
                inscrits: classe.inscrits,
                seuil: classe.capacite,
              ),
              child: ExcludeSemantics(
                child: Text(
                  LibellesClasses.capacite(
                    inscrits: classe.inscrits,
                    seuil: classe.capacite,
                  ),
                  style: textes.labelLarge ?? const TextStyle(),
                ),
              ),
            )
          else
            // Un brouillon dont la capacite viendra du serveur : on le dit,
            // on n'ecrit pas un nombre a sa place.
            Text(
              t.classes.commun.defautAcademie,
              style: palette.inkMuted.applyTo(
                textes.labelMedium ?? const TextStyle(),
              ),
            ),
        ],
      ),
      actions: widget.pied == null && action == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.pied != null) widget.pied!,
                if (widget.pied != null && action != null) Ecart.vMd,
                if (action != null)
                  ActionPrincipale(
                    libelle: action.libelle,
                    onPress: action.onPress,
                    niveau: action.niveau,
                    enCours: action.enCours,
                  ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            LibellesClasses.ligneProgramme(classe),
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          Text(
            LibellesClasses.creneau(
              classe.creneau,
              fuseauUtilisateur: widget.fuseauUtilisateur,
            ),
            style: textes.titleSmall ?? const TextStyle(),
          ),
          if (classe.duree case final Duration duree) ...<Widget>[
            Ecart.vXs,
            Text(
              t.classes.carte.duree(valeur: LibellesClasses.duree(duree)),
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
          Ecart.vSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (enseignant != null && enseignant.nomAffichage.isNotEmpty)
                Text(
                  LibellesClasses.enseignantNomme(enseignant),
                  style: textes.titleSmall ?? const TextStyle(),
                )
              else if (enseignant == null)
                // Un etat, pas une case vide : la Classe existe sans
                // enseignant, et le dit.
                StatusPill(
                  libelle: t.classes.carte.enseignantAAffecter,
                  ton: TonEtat.avertissement,
                ),
              if (classe.complete)
                StatusPill(
                  libelle: t.classes.carte.complet,
                  ton: TonEtat.neutre,
                ),
              if (classe.etat != EtatPublication.publiee)
                StatusPill(
                  libelle: LibellesClasses.etat(classe.etat),
                  ton: LibellesClasses.tonEtat(classe.etat),
                ),
              if (classe.inscrit)
                StatusPill(
                  libelle: t.classes.carte.inscrit,
                  ton: TonEtat.succes,
                ),
              if (classe.candidature == EtatCandidature.envoyee)
                StatusPill(
                  libelle: t.classes.enseignant.candidatureEnvoyee,
                  ton: TonEtat.accent,
                ),
            ],
          ),
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              libelle: _ouvert
                  ? t.classes.carte.masquerDetail
                  : t.classes.carte.voirDetail,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: () => setState(() => _ouvert = !_ouvert),
            ),
          ),
          if (_ouvert) ...<Widget>[
            Ecart.vSm,
            _Detail(key: CarteClasse.cleDetail, classe: classe),
          ],
        ],
      ),
    );
  }
}

/// Le detail d'une Classe, derriere « Voir le detail ».
class _Detail extends StatelessWidget {
  const _Detail({required this.classe, super.key});

  final ClasseVM classe;

  @override
  Widget build(BuildContext context) {
    final SeanceAVenir? seance = classe.prochaineSeance;
    final String prochaine = seance == null
        ? t.classes.carte.aucuneSeance
        : classe.horloge != null
        ? LibellesGroupe.joindre(
            LibellesGroupe.joindre(seance.dateRendue, seance.heureRendue),
            LibellesGroupe.ligneEtat(classe.horloge!),
          )
        : LibellesGroupe.joindre(seance.dateRendue, seance.heureRendue);

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (classe.programme case final String p when p.isNotEmpty)
            _Ligne(libelle: t.classes.carte.programme, valeur: p),
          if (classe.niveauHumain case final String n when n.isNotEmpty)
            _Ligne(libelle: t.classes.carte.niveau, valeur: n),
          _Ligne(
            libelle: t.classes.carte.public,
            valeur: LibellesClasses.publicClasse(classe.publicClasse),
          ),
          _Ligne(
            libelle: t.classes.carte.fuseau,
            valeur:
                classe.creneau.libelleVille ??
                LibellesClasses.ville(classe.creneau.fuseauIana),
          ),
          if (classe.seuilMinimal case final int seuil)
            _Ligne(
              libelle: t.classes.admin.creation.seuilMinimal,
              valeur: t.classes.carte.seuilMinimal(seuil: seuil),
            ),
          _Ligne(
            libelle: t.classes.carte.prochaineSeance,
            valeur: prochaine.isEmpty ? t.classes.carte.aucuneSeance : prochaine,
          ),
          _Ligne(
            libelle: t.classes.carte.etat,
            valeur: LibellesClasses.etat(classe.etat),
          ),
        ],
      ),
    );
  }
}

/// Une ligne libelle / valeur du detail.
class _Ligne extends StatelessWidget {
  const _Ligne({required this.libelle, required this.valeur});

  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              libelle,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.hMd,
          Expanded(
            flex: 2,
            child: Text(valeur, style: textes.bodySmall ?? const TextStyle()),
          ),
        ],
      ),
    );
  }
}

// Ce que les ecrans de la voie CPT-ENC partagent (W05, detail, rapprochement)
// : la lecture d'une valeur du port avec les cinq etats, la ligne « libelle
// · montant masquable », la carte de section. Aucun fichier partage n'est
// modifie (`20_comptable/02_DECOUPAGE.md`, liste C) : ces habits vivent ici.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/montant_argent.dart';
import '../../../core/widgets/montant_sensible.dart';
import '../../../core/widgets/skeleton.dart';

/// Vrai quand le texte est assez agrandi pour que deux colonnes coupent des
/// mots (meme seuil que `LigneCleValeur`) : les ecrans passent en pile.
bool texteAgrandi(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(AppSpacing.lg) / AppSpacing.lg >=
    AppGabarit.seuilTexteColonne;

/// Vrai quand l'ecran a la place d'un tableau et d'un panneau cote a cote :
/// bureau (1200 et plus) et texte non agrandi. Sinon, liste puis page.
bool composeEnPanneau(BuildContext context) =>
    AppGabarit.de(context) == Gabarit.desktop && !texteAgrandi(context);

/// L'etat d'un port sans source serveur (`CapaciteIndisponible`, K-09) :
/// l'ecran est « en preparation », honnete, sans chiffre (meme phrase que
/// les pages posees par CPT-F).
class EnPreparationComptable extends StatelessWidget {
  /// Cree l'etat.
  const EnPreparationComptable({super.key});

  @override
  Widget build(BuildContext context) => EmptyState(
    message: t.comptable.commun.enPreparationTitre,
    invitation: t.comptable.commun.enPreparationPhrase,
  );
}

/// Un bloc de la voie qui lit [valeur] : squelette, contenu, [vide], erreur
/// avec « Reessayer », « hors ligne » quand l'echec arrive sans reseau, et
/// [EnPreparationComptable] quand le port n'a pas de source.
class BlocEncaissements<T> extends ConsumerWidget {
  /// Cree le bloc.
  const BlocEncaissements({
    required this.valeur,
    required this.construire,
    required this.onReessayer,
    super.key,
    this.vide,
    this.estVide,
    this.squelette,
  });

  /// La valeur lue.
  final AsyncValue<T> valeur;

  /// Le contenu.
  final Widget Function(T valeur) construire;

  /// Relit la valeur.
  final VoidCallback onReessayer;

  /// L'etat vide.
  final Widget? vide;

  /// Dit si une valeur est vide.
  final bool Function(T valeur)? estVide;

  /// Le squelette ; une liste par defaut.
  final Widget? squelette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return BlocAsynchrone<T>(
      valeur: valeur,
      squelette: squelette ?? const Skeleton.liste(),
      onReessayer: onReessayer,
      vide: vide,
      estVide: estVide,
      construire: construire,
      erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
        if (erreur is CapaciteIndisponible) {
          return const EnPreparationComptable();
        }
        if (horsLigne) {
          return EtatSysteme(nature: NatureEtat.horsLigne, onAction: reessayer);
        }
        return null;
      },
    );
  }
}

/// Une ligne « libelle · montant » d'un encaissement ou d'un remboursement :
/// le montant est un [MontantSensible] (masque par defaut, lu « Montant
/// masque »), pose au bord de fin ; empilee quand le texte est agrandi.
class LigneMontant extends StatelessWidget {
  /// Cree la ligne.
  const LigneMontant({
    required this.libelle,
    required this.montant,
    super.key,
    this.detail,
    this.fort = false,
  });

  /// Ce que le montant designe.
  final String libelle;

  /// Le montant, rendu par la source.
  final Montant montant;

  /// Une precision sous le libelle.
  final String? detail;

  /// Vrai pour le montant qui conclut le bloc (le net).
  final bool fort;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? precision = detail;
    final Widget cle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          libelle,
          style: (fort ? palette.inkStrong : palette.inkMuted).applyTo(
            (fort ? textes.titleSmall : textes.bodyMedium) ?? const TextStyle(),
          ),
        ),
        if (precision != null)
          Text(
            precision,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
      ],
    );
    final Widget valeur = MontantSensible(
      montant,
      taille: fort ? TailleMontant.titre : TailleMontant.corps,
    );
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: texteAgrandi(context)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  cle,
                  Ecart.vXs,
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: valeur,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: cle),
                  Ecart.hLg,
                  valeur,
                ],
              ),
      ),
    );
  }
}

/// Le titre d'une zone du panneau ou de la page (« Affectation par profil »,
/// « Journal ») : un en-tete pour le lecteur d'ecran.
class TitreZone extends StatelessWidget {
  /// Cree le titre.
  const TitreZone(this.texte, {super.key});

  /// Le titre.
  final String texte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      header: true,
      child: Text(
        texte,
        style: palette.inkStrong.applyTo(
          Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
        ),
      ),
    );
  }
}

/// Une phrase d'information attenuee (note §24.3, politique §26).
class NoteAttenuee extends StatelessWidget {
  /// Cree la note.
  const NoteAttenuee(this.texte, {super.key});

  /// La phrase.
  final String texte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Text(
      texte,
      style: palette.inkMuted.applyTo(
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
      ),
    );
  }
}

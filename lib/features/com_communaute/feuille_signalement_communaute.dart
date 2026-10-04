// Le signalement d'un contenu de la Communaute (spec section 5.5 ; COM-BR-06).
//
// Les huit motifs viennent du socle (`MotifSignalement`), dans l'ordre de la
// spec ; le signalement part par `PortModeration`, sans le modifier. La
// confirmation ne s'affiche qu'apres l'accuse du serveur : un echec dit « pas
// encore confirme », une capacite absente dit « pas encore disponible »,
// jamais un faux signalement accepte (section 25, « moderation
// indisponible »).
//
// La politique anti-promotion (COM-COMU-2, spec section 5.1) : les quatre
// premiers motifs sont ceux de la politique (publicite, lien affilie, vente,
// sollicitation commerciale). Le motif choisi dit la regle qu'il vise, pour
// rendre visible la difference entre un contenu autorise et un contenu
// commercial ; les autres motifs n'ajoutent rien. Le motif part tel quel au
// port (en demonstration, `ModerationDemo` le garde).
//
// Le texte d'echec n'est pas celui de la spec section 5.2 (« Le signalement
// n'a pas pu etre envoye. Reessayez. ») : apres une coupure, l'app ne sait
// pas si le signalement est arrive, elle dit donc « pas encore confirme »
// (K-59, D5, regle `affirmation-reseau`). Ecart OUVERT, a trancher par le
// directeur (amender la spec section 5.2 ou admettre une exception a
// `verifier_revue`), puis a reporter dans COM-BR.md et QUESTIONS.md a COM-FUS.

import 'package:flutter/material.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/modeles_communication.dart';
import '../../core/communications/moderation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/choice_card_group.dart';

/// L'etat d'un signalement en preparation, partage entre le corps de la
/// feuille et son action.
class _Signalement extends ChangeNotifier {
  MotifSignalement? motif;
  String precision = '';
  bool enCours = false;
  String? erreur;

  void choisir(MotifSignalement? m) {
    motif = m;
    erreur = null;
    notifyListeners();
  }

  void etat({required bool enCours, String? erreur}) {
    this.enCours = enCours;
    this.erreur = erreur;
    notifyListeners();
  }
}

/// La regle de la politique anti-promotion que vise [motif] ; nulle pour un
/// motif hors de la politique (spec section 4.1, section 5.2, section 22).
String? reglePolitique(MotifSignalement motif) {
  final p = t.com.communaute.signalement.politique;
  return switch (motif) {
    MotifSignalement.publicite => p.publicite,
    MotifSignalement.lienAffilie => t.com.communaute.garde.bloqueAffilie,
    MotifSignalement.venteNonAutorisee => t.com.communaute.garde.bloqueVente,
    MotifSignalement.sollicitationCommerciale => p.sollicitation,
    MotifSignalement.horsSujet ||
    MotifSignalement.harcelement ||
    MotifSignalement.donneesPersonnelles ||
    MotifSignalement.autre => null,
  };
}

/// La feuille de signalement de la Communaute.
abstract final class FeuilleSignalementCommunaute {
  /// La cle de l'action « Envoyer le signalement », pour les tests.
  static const ValueKey<String> cleEnvoyer = ValueKey<String>(
    'communaute-signalement-envoyer',
  );

  /// La cle du message d'erreur, pour les tests.
  static const ValueKey<String> cleErreur = ValueKey<String>(
    'communaute-signalement-erreur',
  );

  /// La cle de la carte d'un motif, pour les tests.
  static ValueKey<String> cleMotif(MotifSignalement motif) =>
      ValueKey<String>('communaute-motif-${motif.name}');

  /// La cle de la regle visee par le motif choisi, pour les tests.
  static const ValueKey<String> cleRegle = ValueKey<String>(
    'communaute-signalement-regle',
  );

  /// Ouvre la feuille pour [objet]. Rend vrai seulement si le serveur a
  /// accuse le signalement ; faux si la personne renonce.
  static Future<bool> ouvrir(
    BuildContext context, {
    required PortModeration moderation,
    required ObjetLie objet,
  }) async {
    final _Signalement etat = _Signalement();
    final s = t.com.socle.signalement;

    Future<void> envoyer(BuildContext contexte) async {
      final MotifSignalement? motif = etat.motif;
      if (motif == null) {
        etat.etat(
          enCours: false,
          erreur: t.com.communaute.signalement.motifManquant,
        );
        return;
      }
      etat.etat(enCours: true);
      try {
        final String precision = etat.precision.trim();
        await moderation.signaler(
          objet: objet,
          motif: motif,
          precision: precision.isEmpty ? null : precision,
        );
        if (contexte.mounted) Navigator.of(contexte).pop(true);
      } on CapaciteIndisponible {
        etat.etat(enCours: false, erreur: s.indisponible);
      } on Object {
        etat.etat(enCours: false, erreur: s.erreur);
      }
    }

    // La feuille anime sa sortie apres le retour du futur : l'etat reste
    // vivant jusqu'a ce qu'elle soit retiree, il n'est donc pas libere ici.
    final bool? envoye = await AppBottomSheet.ouvrir<bool>(
      context,
      titre: s.titre,
      constructeur: (BuildContext _) => _Corps(etat: etat),
      actions: (BuildContext contexte) => ListenableBuilder(
        listenable: etat,
        builder: (BuildContext _, Widget? _) => ActionPrincipale(
          key: cleEnvoyer,
          libelle: s.envoyer,
          enCours: etat.enCours,
          onPress: () => envoyer(contexte),
        ),
      ),
    );
    return envoye ?? false;
  }
}

class _Corps extends StatelessWidget {
  const _Corps({required this.etat});

  final _Signalement etat;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final s = t.com.socle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          s.motifs.titre,
          style: palette.inkStrong.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vLg,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            for (final MotifSignalement motif in MotifSignalement.values)
              OptionChoix(
                cle: FeuilleSignalementCommunaute.cleMotif(motif),
                valeur: motif.name,
                libelle: motif.libelle,
              ),
          ],
          onChange: (ReponseChoix reponse) {
            final String? nom = reponse.valeurs.firstOrNull;
            etat.choisir(
              nom == null ? null : MotifSignalement.values.byName(nom),
            );
          },
        ),
        // La regle visee par le motif choisi, sous les motifs.
        ListenableBuilder(
          listenable: etat,
          builder: (BuildContext _, Widget? _) {
            final MotifSignalement? motif = etat.motif;
            final String? regle = motif == null ? null : reglePolitique(motif);
            if (regle == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  regle,
                  key: FeuilleSignalementCommunaute.cleRegle,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
            );
          },
        ),
        TextField(
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (String texte) => etat.precision = texte,
          decoration: InputDecoration(
            labelText: s.signalement.precision,
            alignLabelWithHint: true,
          ),
        ),
        ListenableBuilder(
          listenable: etat,
          builder: (BuildContext _, Widget? _) {
            final String? erreur = etat.erreur;
            if (erreur == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  erreur,
                  key: FeuilleSignalementCommunaute.cleErreur,
                  style: palette.inkAlert.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

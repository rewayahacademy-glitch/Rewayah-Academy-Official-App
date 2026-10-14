// DELEG-FIN-1 : les sorties retenues par le delai de securite (au-dessus du
// plafond par transaction), que la Direction peut annuler avant leur
// liberation. La liste, le delai et la date de liberation sont rendus par la
// source (CPT-BR-13) ; l'ecran n'additionne rien et ne calcule aucun delai.
//
// Cinq etats : chargement (`Skeleton`), contenu, vide (phrase), erreur
// (`EtatSysteme`, « Reessayer »), hors ligne ; plus « pas encore disponible »
// (capacite absente). L'annulation passe par `ConfirmDestructive` (une sortie
// annulee ne repart pas) et une cle d'idempotence ; aucun succes n'est dit
// avant la reponse.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/port_delegation_finance.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/carte_groupee.dart';
import '../../../core/widgets/comptable/ligne_activite.dart' show dateComptable;
import '../../../core/widgets/confirm_destructive.dart';
import '../../../core/widgets/montant_sensible.dart';
import 'composants_politique.dart';
import 'politiques_direction.dart';

/// Les sorties en attente de la delegation.
class SortiesEnAttente extends ConsumerStatefulWidget {
  /// Cree la section.
  const SortiesEnAttente({super.key});

  /// La cle de la section.
  static const Key cle = ValueKey<String>('deleg-sorties');

  /// La cle du bouton « Annuler » d'une sortie.
  static Key cleAnnuler(String sortieId) =>
      ValueKey<String>('deleg-sortie-annuler-$sortieId');

  /// La cle de la phrase « Aucune sortie en attente ».
  static const Key cleVide = ValueKey<String>('deleg-sorties-vide');

  /// La cle du message de retour.
  static const Key cleRetour = ValueKey<String>('deleg-sorties-retour');

  @override
  ConsumerState<SortiesEnAttente> createState() => _SortiesEnAttenteEtat();
}

class _SortiesEnAttenteEtat extends ConsumerState<SortiesEnAttente> {
  String? _enCours;
  String? _retour;
  bool _retourEchec = false;

  /// Une cle par sortie : un appui repete, ou apres une reponse perdue,
  /// reprend la meme annulation cote serveur.
  final Map<String, String> _cles = <String, String>{};

  Future<void> _annuler(SortieEnAttente sortie) async {
    if (_enCours != null) return;
    final d = t.comptable.direction.delegationPanneau;
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: d.sortieAnnulerTitre,
      consequence: d.sortieAnnulerPhrase(beneficiaire: sortie.beneficiaire),
      libelleConfirmer: d.sortieAnnulerConfirmer,
      libelleAnnuler: d.sortieGarder,
    );
    if (!oui || !mounted) return;
    final String cle = _cles[sortie.id] ??= nouvelleCleIdempotence('sortie');
    setState(() {
      _enCours = sortie.id;
      _retour = null;
    });
    try {
      await ref
          .read(portControleDelegationProvider)
          .annulerSortie(sortieId: sortie.id, cleIdempotence: cle);
      if (!mounted) return;
      _cles.remove(sortie.id);
      ref
        ..invalidate(sortiesEnAttenteProvider)
        ..invalidate(journalDelegationProvider);
      setState(() {
        _enCours = null;
        _retour = d.sortieAnnulee;
        _retourEchec = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _enCours = null;
        _retour = d.sortieAnnulationEchec;
        _retourEchec = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = t.comptable.direction.delegationPanneau;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? retour = _retour;
    return Column(
      key: SortiesEnAttente.cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(d.sortiesTitre, style: textes.titleMedium),
        ),
        Ecart.vXs,
        Text(
          d.sortiesDetail,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        BlocPolitique<List<SortieEnAttente>>(
          fournisseur: sortiesEnAttenteProvider,
          construire: (List<SortieEnAttente> sorties) {
            if (sorties.isEmpty) {
              return Text(
                d.sortiesVide,
                key: SortiesEnAttente.cleVide,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              );
            }
            return CarteGroupee(
              sections: <Widget>[
                for (final SortieEnAttente s in sorties)
                  _LigneSortie(
                    sortie: s,
                    enCours: _enCours == s.id,
                    occupe: _enCours != null,
                    onAnnuler: () => _annuler(s),
                  ),
              ],
            );
          },
        ),
        if (retour != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              retour,
              key: SortiesEnAttente.cleRetour,
              style: (_retourEchec ? palette.inkAlert : palette.inkStrong)
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
          ),
        ],
      ],
    );
  }
}

class _LigneSortie extends StatelessWidget {
  const _LigneSortie({
    required this.sortie,
    required this.enCours,
    required this.occupe,
    required this.onAnnuler,
  });

  final SortieEnAttente sortie;
  final bool enCours;
  final bool occupe;
  final VoidCallback onAnnuler;

  @override
  Widget build(BuildContext context) {
    final d = t.comptable.direction.delegationPanneau;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(sortie.beneficiaire, style: textes.titleSmall),
          Ecart.vXs,
          Text(
            d.sortiePart(
              objet: sortie.objet,
              date: dateComptable(sortie.liberableLe),
            ),
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          MontantSensible(sortie.montant),
          Ecart.vSm,
          // Une action secondaire : un seul bouton plein par ecran (K-56).
          if (!occupe || enCours)
            ActionPrincipale(
              key: SortiesEnAttente.cleAnnuler(sortie.id),
              libelle: d.sortieAnnuler,
              libelleSemantique: d.sortieAnnulerNom(
                beneficiaire: sortie.beneficiaire,
              ),
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              compacte: true,
              enCours: enCours,
              onPress: onAnnuler,
            ),
          Ecart.vXs,
        ],
      ),
    );
  }
}

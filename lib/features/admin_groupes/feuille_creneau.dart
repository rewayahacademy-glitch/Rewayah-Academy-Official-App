// B2.2 bis (c), plan de nuit du pilote (24/10/2026) : « ajouter un creneau ».
//
// Une Classe peut se tenir plusieurs fois par semaine. La direction choisit un
// jour et une heure (dans le fuseau de la Classe) ; le serveur repasse le
// predicat d'affectation (memes refus, memes phrases que le deplacement) et
// cree aussitot les seances des quatre prochaines semaines.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/creneaux_classe.dart';
import '../../core/admin/port_classes_admin.dart';
import '../../core/admin/service_groupes.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/offres/affectation_refusee.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/menu_filtre.dart';
import '../creneaux/plages.dart' show jourCapitalise;
import 'bas_de_feuille.dart';
import 'refus_deplacement_libelles.dart';

/// La plage d'heures proposee, celle de la creation d'une Classe (6 h - 21 h).
const int _heureDebut = 6;
const int _heureFin = 21;

/// Ouvre la feuille « Ajouter un creneau » pour [groupe].
void ouvrirAjoutCreneau(
  BuildContext context,
  WidgetRef ref,
  GroupeAdmin groupe, {
  String? nom,
}) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.creneau.titre(
      deLibelle: deDevant(nom ?? groupe.libelle),
    ),
    constructeur: (BuildContext contexte) => FeuilleCreneau(
      groupe: groupe,
      onAjoute: () => ref
        ..invalidate(groupesProvider)
        ..invalidate(pageClassesAdminProvider),
    ),
  );
}

/// Le choix du jour et de l'heure du creneau ajoute.
class FeuilleCreneau extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleCreneau({
    required this.groupe,
    required this.onAjoute,
    super.key,
  });

  /// La Classe qui recoit le creneau.
  final GroupeAdmin groupe;

  /// Appele quand le serveur a ajoute le creneau.
  final VoidCallback onAjoute;

  @override
  ConsumerState<FeuilleCreneau> createState() => _FeuilleCreneauEtat();
}

class _FeuilleCreneauEtat extends ConsumerState<FeuilleCreneau> {
  int? _jour;
  int? _heure;
  bool _envoi = false;
  String? _erreur;

  void _maj(VoidCallback changement) => setState(() {
    changement();
    _erreur = null;
  });

  Future<void> _ajouter() async {
    final int? jour = _jour;
    final int? heure = _heure;
    final c = t.admin.groupes.creneau;
    if (jour == null || heure == null) {
      setState(() => _erreur = t.admin.groupes.formulaire.manqueCreneau);
      return;
    }
    if (jour == widget.groupe.creneau.jour &&
        heure == widget.groupe.creneau.heure) {
      setState(() => _erreur = c.dejaLa);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final int n = await ref
          .read(serviceCreneauxClasseProvider)
          .ajouter(groupeId: widget.groupe.id, jour: jour, heure: heure);
      if (n == 0) {
        // Le serveur avait deja ce creneau (ou la Classe n'a pas encore son
        // enseignant) : rien n'a change, la phrase le dit.
        if (mounted) setState(() => _erreur = c.dejaLa);
        return;
      }
      widget.onAjoute();
      if (mounted) Navigator.of(context).pop();
    } on AffectationRefusee catch (refus) {
      if (mounted) {
        setState(
          () => _erreur = phraseRefusDeplacement(
            refus.motif,
            actives: refus.actives,
            maximum: refus.maximum,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _erreur = c.erreur);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final f = t.admin.groupes.formulaire;
    final c = t.admin.groupes.creneau;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TexteSansCoupure(c.contexte, style: textes.bodyMedium),
        Ecart.vLg,
        TexteSansCoupure(f.jour, style: textes.labelLarge),
        Ecart.vSm,
        // Choix de formulaire, pas un filtre : le jour du creneau ajoute.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (int j = 1; j <= 7; j++)
              FilterPill(
                key: ValueKey<String>('creneau-jour-$j'),
                libelle: jourCapitalise(j),
                retenue: _jour == j,
                onPress: () => _maj(() => _jour = j),
              ),
          ],
        ),
        Ecart.vLg,
        TexteSansCoupure(f.heure, style: textes.labelLarge),
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MenuFiltre<int>(
            key: const ValueKey<String>('creneau-heure'),
            libelle: f.heure,
            valeur: _heure,
            entrees: <EntreeFiltre<int>>[
              for (int h = _heureDebut; h <= _heureFin; h++)
                EntreeFiltre<int>(
                  valeur: h,
                  libelle: LibellesGroupe.insecable(f.heureValeur(heure: '$h')),
                ),
            ],
            onChoix: (int? h) {
              if (h != null) _maj(() => _heure = h);
            },
          ),
        ),
        Ecart.vSm,
        TexteSansCoupure(c.fuseau, style: textes.bodySmall),
        if (_erreur case final String erreur) ...<Widget>[
          Ecart.vMd,
          MessageAlerte(erreur),
        ],
        Ecart.vXxl,
        BasDeFeuille(
          libelle: c.envoyer,
          enCours: _envoi,
          horsLigne: c.horsLigne,
          onPress: _ajouter,
        ),
        Ecart.vMd,
        TexteSansCoupure(c.journalisation, style: textes.bodySmall),
      ],
    );
  }
}

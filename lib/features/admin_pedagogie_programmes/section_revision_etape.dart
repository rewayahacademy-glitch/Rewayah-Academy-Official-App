// MA-PROGRESSION-ECRAN (12/11/2026) : ce que la direction regle pour une
// etape : les heures de revision par semaine et les repetitions estimees.
// C'est la seule reponse a « combien de temps » qu'aucun calcul ne donne, et
// c'est ce que la famille lit dans « Ou j'en suis ». Vide par defaut : tant
// que la direction n'a rien rempli, la famille ne voit aucune ligne.
//
// Choisi au pas a pas, jamais au clavier (K-57) : la demi-heure et la
// repetition. « Non regle » (zero) vide la valeur. Hors de la version : le
// reglage tient a l'etape (son code technique), il se regle meme sur une
// version publiee ; son enregistrement est a part de celui du contenu.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/choix_nombre.dart';
import 'feuille_contenu_niveau.dart' show messageMetier;

/// La saisie du reglage d'une etape.
class SectionRevisionEtape extends StatefulWidget {
  /// Cree la section.
  const SectionRevisionEtape({
    required this.heuresInitiales,
    required this.repetitionsInitiales,
    required this.onRegler,
    super.key,
  });

  /// Les heures de revision deja reglees, ou `null`.
  final double? heuresInitiales;

  /// Les repetitions deja reglees, ou `null`.
  final int? repetitionsInitiales;

  /// L'ecriture au serveur ; une valeur nulle vide le reglage.
  final Future<void> Function({double? heures, int? repetitions}) onRegler;

  /// La cle des heures.
  static const Key heuresKey = ValueKey<String>('revision-heures');

  /// La cle des repetitions.
  static const Key repetitionsKey = ValueKey<String>('revision-repetitions');

  /// La cle du bouton d'enregistrement.
  static const Key enregistrerKey = ValueKey<String>('revision-enregistrer');

  @override
  State<SectionRevisionEtape> createState() => _SectionRevisionEtapeEtat();
}

class _SectionRevisionEtapeEtat extends State<SectionRevisionEtape> {
  // Les heures se comptent en demi-heures : 0 = non regle, 5 = 2,5 h.
  late int _demiHeures = ((widget.heuresInitiales ?? 0) * 2).round();
  late int _repetitions = widget.repetitionsInitiales ?? 0;
  bool _envoi = false;
  bool _fait = false;
  String? _erreur;

  String _heures(int demi) {
    if (demi == 0) return t.admin.programmes.contenu.revisionNonRegle;
    final double h = demi / 2;
    final String brut = h == h.roundToDouble()
        ? '${h.toInt()}'
        : h.toStringAsFixed(1);
    return t.admin.programmes.contenu.revisionHeuresValeur(
      heures: LocaleSettings.currentLocale == AppLocale.ar
          ? brut.replaceAll('.', '٫')
          : brut.replaceAll('.', ','),
    );
  }

  Future<void> _enregistrer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
      _fait = false;
    });
    try {
      await widget.onRegler(
        heures: _demiHeures == 0 ? null : _demiHeures / 2,
        repetitions: _repetitions == 0 ? null : _repetitions,
      );
      if (mounted) setState(() => _fait = true);
    } catch (erreur) {
      if (!mounted) return;
      setState(
        () => _erreur = t.admin.programmes.contenu.revisionErreur(
          message: messageMetier(erreur),
        ),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final c = t.admin.programmes.contenu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Ecart.vXl,
        Text(c.revisionTitre, style: textes.titleSmall),
        Ecart.vSm,
        Text(
          c.revisionAide,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        ChoixNombre(
          key: SectionRevisionEtape.heuresKey,
          libelle: c.revisionHeures,
          valeur: _demiHeures,
          max: 80,
          affichage: _heures,
          libelleMoins: c.revisionHeuresMoins,
          libellePlus: c.revisionHeuresPlus,
          onChange: (int v) => setState(() {
            _demiHeures = v;
            _fait = false;
          }),
        ),
        Ecart.vMd,
        ChoixNombre(
          key: SectionRevisionEtape.repetitionsKey,
          libelle: c.revisionRepetitions,
          valeur: _repetitions,
          max: 500,
          affichage: (int v) => v == 0 ? c.revisionNonRegle : '$v',
          libelleMoins: c.revisionRepetitionsMoins,
          libellePlus: c.revisionRepetitionsPlus,
          onChange: (int v) => setState(() {
            _repetitions = v;
            _fait = false;
          }),
        ),
        Ecart.vMd,
        if (_erreur != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              _erreur!,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vMd,
        ],
        if (_fait) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(c.revisionEnregistree, style: textes.bodyMedium),
          ),
          Ecart.vMd,
        ],
        ActionPrincipale(
          key: SectionRevisionEtape.enregistrerKey,
          libelle: c.revisionEnregistrer,
          enCours: _envoi,
          onPress: _enregistrer,
        ),
      ],
    );
  }
}

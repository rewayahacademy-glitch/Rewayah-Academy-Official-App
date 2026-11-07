/// SALLE-2-ENTRETIEN (07/11/2026) : la feuille « Ecrire mon compte rendu »
/// d'une personne qui mene l'entretien (`ecrire_compte_rendu_entretien`).
///
/// Le texte et l'avis sont exiges ; le constat (memorisation, tajwid, ijaza,
/// codes de la salle d'examen) est facultatif. Le serveur decide : apres le
/// debut, avant la consignation, participant du cote de la candidature. Le
/// compte rendu et l'avis ne sont lus que par la direction, jamais par le
/// candidat.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/compte_rendu_entretien.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/zone_saisie.dart';
import '../candidature/libelles_parcours.dart';

/// Les champs du constat et leurs codes (ceux de la salle d'examen).
const Map<String, List<String>> _constat = <String, List<String>>{
  'niveauMemorisationDeclare': <String>[
    'aucune',
    'moins_10_juz',
    'de_10_a_29_juz',
    'coran_entier',
  ],
  'niveauLectureTajwid': <String>[
    'lecture_sans_regles_tajwid',
    'tajwid_applique',
    'tajwid_enseigne',
  ],
  'ijazaPresentable': <String>['oui', 'pret_test', 'non'],
};

/// Les riwayat qu'un compte rendu peut constater (CHECK de
/// `entretien_comptes_rendus.riwayat_observees`), dans l'ordre du
/// questionnaire.
const List<String> _riwayat = <String>[
  'hafs',
  'shuba',
  'warsh',
  'qalun',
  'al_bazzi',
  'qunbul',
  'ad_duri_abi_amr',
  'as_susi',
  'hisham',
  'ibn_dhakwan',
  'khalaf_an_hamza',
  'khallad',
  'abu_al_harith',
  'ad_duri_al_kisai',
  'ibn_wardan',
  'ibn_jammaz',
  'ruways',
  'rawh',
  'ishaq',
  'idris',
];

/// La feuille du compte rendu.
class FeuilleCompteRendu extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleCompteRendu({
    required this.sessionId,
    required this.onFini,
    required this.onAnnuler,
    super.key,
  });

  /// La seance de l'entretien.
  final String sessionId;

  /// Le compte rendu est enregistre : le message du retour local.
  final ValueChanged<String> onFini;

  /// La personne renonce.
  final VoidCallback onAnnuler;

  /// Le bouton d'enregistrement.
  static const Key enregistrerKey = ValueKey<String>(
    'compte-rendu-enregistrer',
  );

  /// Le champ du texte.
  static const Key texteKey = ValueKey<String>('compte-rendu-texte');

  @override
  ConsumerState<FeuilleCompteRendu> createState() => _EtatFeuille();
}

class _EtatFeuille extends ConsumerState<FeuilleCompteRendu> {
  final TextEditingController _texte = TextEditingController();
  AvisEntretien? _avis;
  final Map<String, String?> _choix = <String, String?>{};
  Set<String> _riwayatChoisies = <String>{};
  bool _tente = false;
  bool _envoi = false;
  String? _refus;

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final c = t.admin.candidatures.entretien.compteRendu;
    if (_texte.text.trim().isEmpty || _avis == null) {
      setState(() => _tente = true);
      return;
    }
    final PortCompteRenduEntretien? port = ref.read(
      portCompteRenduEntretienProvider,
    );
    if (port == null) {
      setState(() => _refus = c.echec);
      return;
    }
    final bool horsLigne = ref.read(horsLigneProvider).value ?? false;
    setState(() {
      _envoi = true;
      _refus = null;
    });
    try {
      final RefusCompteRendu? refus = await port.ecrire(
        widget.sessionId,
        CompteRenduAEcrire(
          texte: _texte.text.trim(),
          avis: _avis!,
          memorisation: _choix['niveauMemorisationDeclare'],
          tajwid: _choix['niveauLectureTajwid'],
          ijaza: _choix['ijazaPresentable'],
          riwayat: <String>[
            for (final String r in _riwayat)
              if (_riwayatChoisies.contains(r)) r,
          ],
        ),
      );
      if (!mounted) return;
      if (refus == null) {
        widget.onFini(c.enregistre);
        return;
      }
      setState(
        () => _refus = switch (refus) {
          RefusCompteRendu.pasCommence => c.pasCommence,
          RefusCompteRendu.consigne => c.consigne,
          RefusCompteRendu.texteInvalide => c.texteInvalide,
          RefusCompteRendu.constatInvalide => c.constatInvalide,
          RefusCompteRendu.autre => c.echec,
        },
      );
    } on Object {
      if (mounted) {
        setState(() => _refus = horsLigne ? t.contrat.horsLigne : c.echec);
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Widget _titre(String texte) => Semantics(
    header: true,
    child: TexteSansCoupure(
      texte,
      style: Theme.of(context).textTheme.titleMedium,
    ),
  );

  Widget _erreur(String texte) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: Semantics(
      liveRegion: true,
      child: TexteSansCoupure(
        texte,
        style: AppPalette.of(context).inkAlert.applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = t.admin.candidatures.entretien.compteRendu;
    final a = t.admin.candidatures.entretien.avis;
    return Column(
      key: const ValueKey<String>('feuille-compte-rendu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          c.consequence,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Ecart.vLg,
        ZoneSaisie(
          cleChamp: FeuilleCompteRendu.texteKey,
          controleur: _texte,
          libelle: c.texte,
          erreur: _tente && _texte.text.trim().isEmpty ? c.texteManquant : null,
          minLignes: 4,
          maxLignes: 12,
          onChanged: (String _) => setState(() {}),
        ),
        Ecart.vLg,
        _titre(c.avis),
        Ecart.vSm,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            for (final AvisEntretien v in AvisEntretien.values)
              OptionChoix(
                cle: ValueKey<String>('avis-${v.valeurSql}'),
                valeur: v.valeurSql,
                libelle: switch (v) {
                  AvisEntretien.favorable => a.favorable,
                  AvisEntretien.reserve => a.reserve,
                  AvisEntretien.defavorable => a.defavorable,
                },
              ),
          ],
          valeurInitiale: _avis == null
              ? null
              : ReponseChoix(valeurs: <String>{_avis!.valeurSql}),
          onChange: (ReponseChoix r) => setState(() {
            _avis = r.valeurs.isEmpty
                ? null
                : AvisEntretien.values.firstWhere(
                    (AvisEntretien v) => v.valeurSql == r.valeurs.first,
                  );
          }),
        ),
        if (_tente && _avis == null) _erreur(c.avisManquant),
        Ecart.vLg,
        _titre(c.constat),
        Ecart.vXs,
        TexteSansCoupure(
          c.constatAide,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
        for (final MapEntry<String, List<String>> champ
            in _constat.entries) ...<Widget>[
          Ecart.vMd,
          TexteSansCoupure(
            nomCourtQuestion(champ.key) ?? titreQuestion(champ.key) ?? '',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Ecart.vSm,
          ChoiceCardGroup(
            autoriserSaisieLibre: false,
            options: <OptionChoix>[
              for (final String code in champ.value)
                OptionChoix(
                  cle: ValueKey<String>('constat-${champ.key}-$code'),
                  valeur: code,
                  libelle: textesOption(champ.key, code)?.libelle ?? code,
                ),
            ],
            valeurInitiale: _choix[champ.key] == null
                ? null
                : ReponseChoix(valeurs: <String>{_choix[champ.key]!}),
            onChange: (ReponseChoix r) => setState(
              () => _choix[champ.key] = r.valeurs.isEmpty
                  ? null
                  : r.valeurs.first,
            ),
          ),
        ],
        Ecart.vMd,
        TexteSansCoupure(
          nomCourtQuestion('riwayat') ?? titreQuestion('riwayat') ?? '',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Ecart.vSm,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          selectionMultiple: true,
          options: <OptionChoix>[
            for (final String code in _riwayat)
              OptionChoix(
                cle: ValueKey<String>('constat-riwayat-$code'),
                valeur: code,
                libelle: textesOption('riwayat', code)?.libelle ?? code,
              ),
          ],
          valeurInitiale: ReponseChoix(valeurs: _riwayatChoisies),
          onChange: (ReponseChoix r) =>
              setState(() => _riwayatChoisies = <String>{...r.valeurs}),
        ),
        if (_refus != null) _erreur(_refus!),
        Ecart.vXxl,
        ActionPrincipale(
          key: FeuilleCompteRendu.enregistrerKey,
          libelle: c.enregistrer,
          enCours: _envoi,
          onPress: _envoi ? null : () => unawaited(_enregistrer()),
        ),
        Ecart.vMd,
        ActionPrincipale(
          libelle: t.commun.annuler,
          niveau: NiveauAction.secondaire,
          onPress: widget.onAnnuler,
        ),
      ],
    );
  }
}

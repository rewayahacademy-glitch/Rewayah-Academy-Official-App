/// SUIVI-ATTENTE (S4) : « Ce que les familles voient de vous », dans le Compte
/// de l'enseignant.
///
/// Les familles d'une classe voient toujours le nom de l'enseignant et la
/// langue du cours. L'enseignant choisit de montrer aussi sa photo (celle de
/// son profil), son pays d'origine, son pays de residence et un mot de
/// presentation. Le choix est vrai par defaut pour un nouvel enseignant, faux
/// pour ceux d'avant le lot tant qu'ils ne l'ont pas confirme : l'ecran le dit
/// (`nonConfirme`).
///
/// Pays : choisis dans la liste des pays (`ChampRecherche` et `SettingRow`,
/// comme les coordonnees de versement), jamais saisis. Etats : chargement,
/// contenu, erreur (« Reessayer »), enregistrement en cours, enregistre,
/// echec (K-59).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/attente_classe/modele_attente.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/zone_saisie.dart';
import '../consentements/texte_observation.dart' show CaseAccordTexte;

/// La page du reglage de l'enseignant.
class PresentationFamillesPage extends ConsumerWidget {
  /// Cree la page.
  const PresentationFamillesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => PageShell(
    titre: t.suiviAttente.presentation.titre,
    sousTitre: t.suiviAttente.presentation.phrase,
    onRetour: () {
      final GoRouter? routeur = GoRouter.maybeOf(context);
      if (routeur == null) return;
      if (routeur.canPop()) {
        routeur.pop();
      } else {
        routeur.go(Routes.enseignantProfil);
      }
    },
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPage.largeurFormulaire),
        child: BlocAsynchrone<PresentationAuxFamilles>(
          key: const ValueKey<String>('presentation-bloc'),
          valeur: ref.watch(presentationEnseignantProvider),
          squelette: const Skeleton.liste(lignes: 3),
          onReessayer: () => ref.invalidate(presentationEnseignantProvider),
          titreEchec: t.suiviAttente.presentation.erreur,
          construire: (PresentationAuxFamilles lu) => _Formulaire(initial: lu),
        ),
      ),
    ),
  );
}

class _Formulaire extends ConsumerStatefulWidget {
  const _Formulaire({required this.initial});

  final PresentationAuxFamilles initial;

  @override
  ConsumerState<_Formulaire> createState() => _FormulaireEtat();
}

class _FormulaireEtat extends ConsumerState<_Formulaire> {
  late bool _montre = widget.initial.montre;
  late String? _origine = widget.initial.paysOrigine;
  late String? _residence = widget.initial.paysResidence;
  late final TextEditingController _mot = TextEditingController(
    text: widget.initial.mot ?? '',
  );
  bool _enCours = false;
  bool? _reussi;

  @override
  void dispose() {
    _mot.dispose();
    super.dispose();
  }

  Future<void> _choisirPays({required bool origine}) async {
    final String? code = await AppBottomSheet.ouvrir<String>(
      context,
      titre: t.suiviAttente.presentation.choisirPays,
      constructeur: (BuildContext contexte) =>
          _ListePays(onChoix: (String c) => Navigator.of(contexte).pop(c)),
    );
    if (code == null || !mounted) return;
    setState(() {
      // Le code vide (« Ne pas renseigner ») efface le pays.
      final String? valeur = code.isEmpty ? null : code;
      if (origine) {
        _origine = valeur;
      } else {
        _residence = valeur;
      }
      _reussi = null;
    });
  }

  Future<void> _enregistrer() async {
    final PortPresentationEnseignant? port = ref.read(
      portPresentationEnseignantProvider,
    );
    if (port == null || _enCours) return;
    setState(() {
      _enCours = true;
      _reussi = null;
    });
    final String mot = _mot.text.trim();
    try {
      await port.regler(
        montre: _montre,
        paysOrigine: _origine,
        paysResidence: _residence,
        mot: mot.isEmpty ? null : mot,
      );
      ref.invalidate(presentationEnseignantProvider);
      if (mounted) setState(() => _reussi = true);
    } on Object {
      if (mounted) setState(() => _reussi = false);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final f = t.suiviAttente.presentation;
    String pays(String? code) =>
        code == null ? f.nonRenseigne : nomDuPays(code);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!widget.initial.confirme) ...<Widget>[
          TexteSansCoupure(
            f.nonConfirme,
            key: const ValueKey<String>('presentation-non-confirme'),
            style: palette.inkWarning.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vLg,
        ],
        CaseAccordTexte(
          key: const ValueKey<String>('presentation-montrer'),
          libelle: f.montrer,
          cochee: _montre,
          onChanged: _enCours
              ? null
              : (bool v) => setState(() {
                  _montre = v;
                  _reussi = null;
                }),
        ),
        if (_montre) ...<Widget>[
          Ecart.vLg,
          CarteLignes(
            lignes: <Widget>[
              SettingRow(
                key: const ValueKey<String>('presentation-origine'),
                title: f.paysOrigine,
                value: pays(_origine),
                onPress: () => unawaited(_choisirPays(origine: true)),
              ),
              SettingRow(
                key: const ValueKey<String>('presentation-residence'),
                title: f.paysResidence,
                value: pays(_residence),
                onPress: () => unawaited(_choisirPays(origine: false)),
              ),
            ],
          ),
          Ecart.vLg,
          ZoneSaisie(
            cleChamp: const ValueKey<String>('presentation-mot'),
            controleur: _mot,
            libelle: f.mot,
            aide: f.motAide,
            minLignes: 4,
            maxLignes: 8,
            onChanged: (String _) => setState(() => _reussi = null),
          ),
        ],
        if (_reussi != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              _reussi! ? f.enregistre : f.erreur,
              key: const ValueKey<String>('presentation-retour'),
              style: (_reussi! ? palette.inkSuccess : palette.inkAlert).applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          key: const ValueKey<String>('presentation-enregistrer'),
          libelle: f.enregistrer,
          pleineLargeur: false,
          enCours: _enCours,
          onPress: () => unawaited(_enregistrer()),
        ),
      ],
    );
  }
}

/// La liste des pays et sa recherche : meme forme que les coordonnees de
/// versement et le formulaire d'avis. Le premier choix efface le pays.
class _ListePays extends StatefulWidget {
  const _ListePays({required this.onChoix});

  final ValueChanged<String> onChoix;

  @override
  State<_ListePays> createState() => _ListePaysEtat();
}

class _ListePaysEtat extends State<_ListePays> {
  final TextEditingController _recherche = TextEditingController();

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = t.avis.form.pays;
    final List<PaysIso> pays = chercherPays(_recherche.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ChampRecherche(
          controleur: _recherche,
          libelle: f.rechercheLibelle,
          aide: f.rechercheAide,
          onChange: (String _) => setState(() {}),
        ),
        Ecart.vLg,
        CarteLignes(
          lignes: <Widget>[
            if (_recherche.text.trim().isEmpty)
              SettingRow(
                key: const ValueKey<String>('presentation-pays-aucun'),
                title: t.suiviAttente.presentation.effacerPays,
                onPress: () => widget.onChoix(''),
              ),
            for (final PaysIso p in pays)
              SettingRow(
                key: ValueKey<String>('presentation-pays-${p.code}'),
                title: p.nom,
                onPress: () => widget.onChoix(p.code),
              ),
          ],
        ),
        if (pays.isEmpty) ...<Widget>[
          Ecart.vMd,
          Text(f.aucun, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

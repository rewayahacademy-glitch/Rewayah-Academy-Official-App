// Le code de conduite de l'enseignant (PE, 18/10/2026).
//
// Le texte reprend le sens des clauses que l'enseignant a deja signees
// (contrat `2026-10-jur` : enregistrement et visites de controle, coordonnees
// des familles) et des principes de protection des enfants de l'academie,
// avec les decisions du directeur. Version definitive, validee par le
// directeur le 19/10/2026 (`VersionsContrat.codeConduite`, `2026-10-19`) :
// il n'est plus provisoire.
//
// L'acceptation passe par le mecanisme des consentements existant
// (`PortConsentements.accepter`, ligne immuable de `contract_acceptances`,
// version et date tracees par la base), jamais par un second chemin.
//
// Surface : la lecture partagee (`AppBottomSheet.ouvrirLecture`), ouverte
// depuis le profil de l'enseignant ; aucune route propre.
//
// Les cinq etats : chargement (squelette), contenu (le texte et sa case),
// vide (aucune acceptation lue : le texte et la case, cas normal),
// erreur (lecture impossible, avec « Reessayer »), hors ligne (le message du
// contrat : l'accord sera enregistre au retour du reseau, en appuyant de
// nouveau).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/capacites/consentements_supabase.dart';
import '../../core/capacites/port_consentements.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/versions_contrat.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/profil/service_acceptations.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import '../consentements/texte_observation.dart';

/// L'acceptation du code de conduite dans [lues], ou `null` si la version
/// courante n'est pas signee. **Aucune acceptation n'est presumee.**
Acceptation? acceptationCodeConduite(List<Acceptation> lues) {
  final String version = VersionsContrat.pour(
    SorteContrat.codeConduiteEnseignant,
  );
  for (final Acceptation a in lues) {
    if (a.sorte == SorteContrat.codeConduiteEnseignant &&
        a.version == version) {
      return a;
    }
  }
  return null;
}

/// Ouvre le code de conduite en lecture, avec sa case d'acceptation.
Future<void> ouvrirCodeConduite(BuildContext context) =>
    AppBottomSheet.ouvrirLecture<void>(
      context,
      titre: t.codeConduite.titre,
      libelleFermer: t.commun.fermer,
      constructeur: (BuildContext _) =>
          const SingleChildScrollView(child: ContenuCodeConduite()),
    );

/// Le texte du code de conduite, sa case et son bouton.
class ContenuCodeConduite extends ConsumerStatefulWidget {
  /// Cree le contenu.
  const ContenuCodeConduite({super.key});

  /// La cle de la case d'acceptation.
  static const Key caseKey = ValueKey<String>('code-conduite-case');

  /// La cle du bouton d'acceptation.
  static const Key accepterKey = ValueKey<String>('code-conduite-accepter');

  /// La cle de la ligne « Accepte le ... ».
  static const Key accepteKey = ValueKey<String>('code-conduite-accepte');

  /// La cle de l'etat d'erreur de lecture.
  static const Key erreurLectureKey = ValueKey<String>(
    'code-conduite-erreur-lecture',
  );

  @override
  ConsumerState<ContenuCodeConduite> createState() =>
      _ContenuCodeConduiteEtat();
}

class _ContenuCodeConduiteEtat extends ConsumerState<ContenuCodeConduite> {
  bool _cochee = false;
  bool _horsLigne = false;
  bool _envoi = false;
  String? _erreur;

  Future<void> _accepter() async {
    if (!_cochee) {
      setState(() => _erreur = t.contrat.caseRequise);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(portConsentementsProvider)
          .accepter(
            sorte: SorteContrat.codeConduiteEnseignant,
            version: VersionsContrat.pour(SorteContrat.codeConduiteEnseignant),
          );
      ref.invalidate(accordsTitulaireProvider);
      ref.invalidate(acceptationsProvider);
      if (mounted) setState(() => _envoi = false);
    } on Object {
      if (!mounted) return;
      final bool horsLigne = _horsLigne;
      setState(() {
        _envoi = false;
        _erreur = horsLigne ? t.contrat.horsLigne : t.codeConduite.erreur;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Acceptation>> lecture = ref.watch(
      accordsTitulaireProvider,
    );
    // L'etat du reseau est suivi des l'ouverture : il dit la bonne phrase si
    // l'envoi tombe en panne.
    _horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    if (!lecture.hasValue) {
      if (lecture.hasError) {
        return Column(
          key: ContenuCodeConduite.erreurLectureKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TexteSansCoupure(
              t.codeConduite.erreurLecture,
              style: textes.bodyLarge,
            ),
            Ecart.vLg,
            LienFleche(
              libelle: t.commun.reessayer,
              onPress: () => ref.invalidate(accordsTitulaireProvider),
            ),
          ],
        );
      }
      return const Skeleton.texte(lignes: 6);
    }

    final Acceptation? acceptee = acceptationCodeConduite(lecture.requireValue);
    final List<String> regles = t.codeConduite.regles;
    final TextStyle corps = textes.bodyLarge ?? const TextStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(t.codeConduite.intro, style: corps),
        Ecart.vLg,
        for (int n = 0; n < regles.length; n++) ...<Widget>[
          if (n > 0) Ecart.vMd,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${n + 1}.', style: corps),
              Ecart.hSm,
              Expanded(child: Text(regles[n], style: corps)),
            ],
          ),
        ],
        Ecart.vXl,
        if (acceptee != null)
          Semantics(
            key: ContenuCodeConduite.accepteKey,
            liveRegion: true,
            child: Text(
              t.codeConduite.accepteLe(
                date: _date(acceptee.accepteeLe),
                version: acceptee.version,
              ),
              style: palette.inkStrong.applyTo(corps),
            ),
          )
        else ...<Widget>[
          CaseAccordTexte(
            key: ContenuCodeConduite.caseKey,
            libelle: t.codeConduite.caseAccord,
            cochee: _cochee,
            onChanged: _envoi
                ? null
                : (bool v) => setState(() {
                    _cochee = v;
                    _erreur = null;
                  }),
          ),
          if (_erreur != null) ...<Widget>[
            Ecart.vSm,
            Semantics(
              liveRegion: true,
              child: Text(_erreur!, style: palette.inkAlert.applyTo(corps)),
            ),
          ],
          Ecart.vLg,
          ActionPrincipale(
            key: ContenuCodeConduite.accepterKey,
            libelle: t.codeConduite.accepter,
            enCours: _envoi,
            onPress: _envoi ? null : () => unawaited(_accepter()),
          ),
        ],
      ],
    );
  }

  static String _date(DateTime quand) =>
      '${quand.day.toString().padLeft(2, '0')}/'
      '${quand.month.toString().padLeft(2, '0')}/${quand.year}';
}

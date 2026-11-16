// PAYS-VERSEMENT (directeur, 15/11/2026) : apres l'envoi, le candidat change
// lui-meme le pays de son compte de versement depuis son portail.
//
// Le compte peut etre celui d'un proche de confiance dans un pays pris en
// charge. Le serveur (`modifier_mon_pays_versement`) borne le geste a la
// candidature du titulaire, vide les operateurs, remet les coordonnees a
// valider et recalcule le paiement : la candidature n'est jamais refusee pour
// ce motif. Les pays proposes sont ceux que le serveur accepte (la liste
// ISO) : l'ecran n'en invente aucun.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/port_ma_candidature.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/lien_fleche.dart';
import 'choix_avec_recherche.dart';
import 'question_etape.dart' show motsClesDuPays, paysCourants;

/// Vrai quand le candidat peut changer son pays de versement : candidature en
/// cours, hors refus et retrait, avec des reponses deja envoyees.
bool peutChangerPaysVersement(CandidatureDossier c) =>
    c.existe &&
    c.issue == IssueCandidature.enCours &&
    c.questionnaire.envoyeLe != null &&
    (c.etape == EtapeCandidature.prequalification ||
        c.etape == EtapeCandidature.verifications ||
        c.etape == EtapeCandidature.confirmee);

/// Le lien « Changer le pays de versement » et son panneau.
class LienPaysVersement extends ConsumerStatefulWidget {
  /// Cree le lien.
  const LienPaysVersement({required this.candidature, super.key});

  /// La candidature.
  final CandidatureDossier candidature;

  /// La cle du lien.
  static const Key lienKey = ValueKey<String>('pays-versement-lien');

  /// La cle du message de resultat.
  static const Key messageKey = ValueKey<String>('pays-versement-message');

  /// La cle du bouton d'enregistrement du panneau.
  static const Key enregistrerKey = ValueKey<String>(
    'pays-versement-enregistrer',
  );

  @override
  ConsumerState<LienPaysVersement> createState() => _LienPaysVersementState();
}

class _LienPaysVersementState extends ConsumerState<LienPaysVersement> {
  String? _message;
  bool _reussi = false;

  Future<void> _ouvrir() async {
    final _SaisiePays saisie = _SaisiePays(ref);
    final String? fait = await AppBottomSheet.ouvrir<String>(
      context,
      titre: t.recrutement.portail.paysVersementTitre,
      panneauLateral: true,
      constructeur: (BuildContext contexte) => _ContenuPays(saisie: saisie),
      // Le bouton reste dans le pied du panneau : jamais sous la liste.
      actions: (BuildContext contexte) => _PiedPays(saisie: saisie),
    );
    if (!mounted || fait == null) {
      return;
    }
    setState(() {
      _reussi = fait == 'ok';
      _message = fait == 'ok' ? t.recrutement.portail.paysVersementFait : fait;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(portMaCandidatureProvider) == null ||
        !peutChangerPaysVersement(widget.candidature)) {
      return const SizedBox.shrink();
    }
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (_message != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              _message!,
              key: LienPaysVersement.messageKey,
              textAlign: TextAlign.center,
              style: (_reussi ? palette.inkMuted : palette.inkAlert).applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vSm,
        ],
        LienFleche(
          key: LienPaysVersement.lienKey,
          libelle: t.recrutement.portail.paysVersementLien,
          onPress: () => unawaited(_ouvrir()),
        ),
      ],
    );
  }
}

/// Ce que le candidat a choisi, et l'etat de l'enregistrement : partage entre
/// le contenu du panneau et son pied.
class _SaisiePays extends ChangeNotifier {
  _SaisiePays(this._ref);

  final WidgetRef _ref;
  String? choix;
  bool enCours = false;
  String? echec;

  void choisir(String pays) {
    choix = pays;
    notifyListeners();
  }

  Future<void> enregistrer(BuildContext context) async {
    final PortMaCandidature? port = _ref.read(portMaCandidatureProvider);
    final String? pays = choix;
    if (port == null || pays == null) {
      return;
    }
    final r = t.recrutement.portail;
    enCours = true;
    echec = null;
    notifyListeners();
    try {
      await port.modifierPaysVersement(pays);
      // Le portail relit l'etat du serveur : rien n'est deduit ici.
      _ref.invalidate(etatDossierProvider);
      if (context.mounted) {
        Navigator.of(context).pop('ok');
      }
    } on HorsLigneCandidature {
      _erreur(r.paysVersementHorsLigne);
    } on TransitionInterdite {
      _erreur(r.paysVersementInterdit);
    } on PermissionInsuffisante {
      _erreur(r.paysVersementInterdit);
    } on Object {
      _erreur(r.paysVersementEchec);
    }
  }

  void _erreur(String message) {
    enCours = false;
    echec = message;
    notifyListeners();
  }
}

/// Le contenu du panneau : la phrase, le choix du pays, l'echec eventuel.
class _ContenuPays extends StatelessWidget {
  const _ContenuPays({required this.saisie});

  final _SaisiePays saisie;

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.portail;
    final p = t.recrutement.parcours.pays;
    final TextTheme textes = Theme.of(context).textTheme;
    final List<ElementChoix> tous =
        <ElementChoix>[
          for (final PaysIso x in paysIso)
            ElementChoix(
              code: x.code,
              libelle: x.nom,
              motsCles: motsClesDuPays(x),
              cle: ValueKey<String>('pays-versement-${x.code}'),
            ),
        ]..sort(
          (ElementChoix a, ElementChoix b) =>
              formeDeRecherche(a.libelle)
                  .compareTo(formeDeRecherche(b.libelle)),
        );
    final Map<String, ElementChoix> parCode = <String, ElementChoix>{
      for (final ElementChoix e in tous) e.code: e,
    };
    return ListenableBuilder(
      listenable: saisie,
      builder: (BuildContext contexte, Widget? _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(r.paysVersementExplication, style: textes.bodyLarge),
          Ecart.vLg,
          ChoixAvecRecherche(
            cle: 'pays-versement-portail',
            courants: <ElementChoix>[
              for (final String c in paysCourants)
                if (parCode[c] case final ElementChoix e) e,
            ],
            tous: tous,
            selection: <String>{?saisie.choix},
            textes: TextesRecherche(
              recherche: p.recherche,
              aide: p.rechercheAide,
              aucun: p.aucun,
              retour: p.retour,
            ),
            onChange: (Set<String> s) {
              if (s.isNotEmpty) {
                saisie.choisir(s.first);
              }
            },
          ),
          if (saisie.echec != null) ...<Widget>[
            Ecart.vMd,
            Semantics(
              liveRegion: true,
              child: Text(
                saisie.echec!,
                style: AppPalette.of(contexte).inkAlert
                    .applyTo(textes.bodyMedium ?? const TextStyle()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le pied du panneau : le bouton, rendu seulement quand un pays est choisi.
class _PiedPays extends StatelessWidget {
  const _PiedPays({required this.saisie});

  final _SaisiePays saisie;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: saisie,
    builder: (BuildContext contexte, Widget? _) => saisie.choix == null
        ? const SizedBox.shrink()
        : ActionPrincipale(
            key: LienPaysVersement.enregistrerKey,
            libelle: t.recrutement.portail.paysVersementEnregistrer,
            enCours: saisie.enCours,
            pleineLargeur: false,
            onPress: () {
              // Un seul envoi a la fois : le bouton montre l'attente, il ne
              // se grise pas.
              if (!saisie.enCours) {
                unawaited(saisie.enregistrer(contexte));
              }
            },
          ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_politique_revue_kyc.dart';
import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/dossier/service_validation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../admin_dossiers/etat_file_dossiers.dart';

/// Configuration > Politique de genre pour la revue KYC (AD-9, spec 15).
///
/// **Garde dans la page** : la route n'a pas de redirect (la capacite arrive
/// de facon asynchrone). Le reglage, son titre et son interrupteur ne sont
/// rendus que si le port dit `peutModifier` ; sinon accesRefuse, et en
/// production (`CapaciteIndisponible`) « Pas encore disponible ». La
/// capacite n'est jamais deduite d'`app_role` (Q40).
///
/// La bascule agit tout de suite, sans fenetre ni confirmation (Q32), et
/// **sans optimisme** : l'interrupteur montre toujours la valeur relue.
class PolitiqueRevueKycPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const PolitiqueRevueKycPage({super.key});

  @override
  ConsumerState<PolitiqueRevueKycPage> createState() =>
      _PolitiqueRevueKycPageState();
}

class _PolitiqueRevueKycPageState extends ConsumerState<PolitiqueRevueKycPage> {
  bool _envoi = false;
  bool _refuse = false;
  String? _retour;
  int _essai = 0;

  Future<void> _basculer(PolitiqueRevueKyc politique, bool valeur) async {
    if (_envoi) {
      return;
    }
    setState(() {
      _envoi = true;
      _retour = null;
    });
    try {
      await ref
          .read(portPolitiqueRevueKycProvider)
          .modifier(
            genreRelecteurApplique: valeur,
            versionAttendue: politique.version,
          );
      if (!mounted) {
        return;
      }
      // La file ouverte se relit (P-ADM-07.9, 15.4).
      ref
        ..invalidate(dossiersEnAttenteProvider)
        ..invalidate(dossierPourRevueProvider)
        ..invalidate(fileDossiersProvider);
    } on ErreurRevueDossier catch (e) {
      if (!mounted) {
        return;
      }
      if (e.code == CodeErreurRevue.interdit ||
          e.code == CodeErreurRevue.nonAutorise) {
        setState(() => _refuse = true);
      } else {
        setState(() {
          _retour = t.admin.politiqueRevueKyc.echecEnregistrement;
          _essai++;
        });
      }
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _retour = t.admin.politiqueRevueKyc.echecEnregistrement;
        _essai++;
      });
    } finally {
      if (mounted) {
        // Toujours relire : la valeur affichee est celle du serveur.
        ref.invalidate(politiqueRevueKycProvider);
        setState(() => _envoi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_refuse) {
      return const PageShell(
        child: EtatSysteme(nature: NatureEtat.accesRefuse),
      );
    }
    final AsyncValue<PolitiqueRevueKyc> lue = ref.watch(
      politiqueRevueKycProvider,
    );
    if (lue.hasValue) {
      final PolitiqueRevueKyc p = lue.requireValue;
      if (!p.peutModifier) {
        return const PageShell(
          child: EtatSysteme(nature: NatureEtat.accesRefuse),
        );
      }
      return PageShell(
        titre: t.admin.politiqueRevueKyc.titre,
        entete: SousNavigationDomaine(
          onglets: ongletsConfiguration(politiqueRevueKyc: true),
          indexActif: 3,
        ),
        // Une seule colonne bornee, calee au debut : jamais un mobile etire
        // sur bureau (STYLE-REFERENCE regle 6).
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppPage.largeurReglages,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GroupeReglages(
                  lignes: <LigneRubrique>[
                    LigneRubrique(
                      libelle: t.admin.politiqueRevueKyc.libelle,
                      legende: t.admin.politiqueRevueKyc.aide,
                      controle: Switch.adaptive(
                        value: p.genreRelecteurApplique,
                        onChanged: _envoi ? null : (bool v) => _basculer(p, v),
                      ),
                    ),
                  ],
                ),
                Ecart.vLg,
                LocalFeedback(key: ValueKey<int>(_essai), message: _retour),
              ],
            ),
          ),
        ),
      );
    }
    // AD-9-ONGLET-PROD : tant que la capacite n'est pas connue ET vraie
    // (chargement, indisponible, echec), ni le titre ni l'onglet reserve ne
    // sont montres : un administrateur sans la capacite qui tape l'adresse ne
    // les voit jamais, meme avant le refus d'acces (fiche AD-9).
    if (lue.hasError) {
      final Object erreur = lue.error!;
      return PageShell(
        child: switch (erreur) {
          CapaciteIndisponible(:final String dependance) => EtatSysteme(
            nature: NatureEtat.indisponible,
            dependance: dependance,
          ),
          ErreurRevueDossier(
            code: CodeErreurRevue.interdit || CodeErreurRevue.nonAutorise,
          ) =>
            const EtatSysteme(nature: NatureEtat.accesRefuse),
          // AD9-M1 : sans reseau, l'etat hors ligne, pas l'echec serveur
          // (meme lecture que la file des dossiers, `etatErreurDossiers`).
          _ when ref.read(horsLigneProvider).value ?? false => EtatSysteme(
            nature: NatureEtat.horsLigne,
            onAction: () => ref.invalidate(politiqueRevueKycProvider),
          ),
          _ => EtatSysteme(
            nature: NatureEtat.echecServeur,
            onAction: () => ref.invalidate(politiqueRevueKycProvider),
          ),
        },
      );
    }
    return const PageShell(child: Skeleton.liste(lignes: 1));
  }
}

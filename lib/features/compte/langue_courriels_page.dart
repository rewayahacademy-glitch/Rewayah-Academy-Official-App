/// COURRIELS-2 : la langue des e-mails et des messages de la direction,
/// reglee par chaque personne connectee (fiche `CPT-LANG`,
/// `docs/current/CATALOGUE_ECRANS_COMPTE.md`).
///
/// La direction ecrit une seule fois ; le serveur traduit a l'envoi. Cet ecran
/// ne decide de rien : les langues viennent du serveur, le choix part au
/// serveur, et « C'est enregistre » ne se dit qu'apres sa reponse. Sans choix,
/// c'est le francais.
///
/// **Pas de carte « Autre »** (`autoriserSaisieLibre: false`) : la liste est
/// fermee par le serveur, une langue saisie a la main ne saurait pas etre
/// traduite. C'est le cas deja admis des listes fermees du serveur (categories
/// d'e-mail, cahier, classes).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_langues_communication.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'carte_rubriques.dart';

/// Ce que dit la ligne sous les cartes apres un enregistrement.
enum RetourLangue {
  /// La langue est enregistree.
  enregistre,

  /// Le serveur ne propose plus cette langue.
  refusee,

  /// Le serveur refuse cette personne.
  refus,

  /// L'enregistrement n'est pas confirme.
  echec,

  /// Pas de reseau : rien n'est enregistre.
  horsLigne,
}

/// L'ecran « Langue des e-mails et des messages ».
class LangueCourrielsPage extends ConsumerStatefulWidget {
  /// Cree l'ecran. [onRetour] : le retour de l'en-tete ; par defaut, les
  /// reglages du compte.
  const LangueCourrielsPage({super.key, this.onRetour});

  /// Le retour de l'en-tete.
  final VoidCallback? onRetour;

  /// La carte de la langue [code].
  static Key carteKey(String code) => ValueKey<String>('langue-$code');

  /// Le geste « Enregistrer la langue ».
  static const Key enregistrerKey = ValueKey<String>('langue-enregistrer');

  /// La ligne qui dit ce qu'est devenu le dernier enregistrement.
  static const Key retourKey = ValueKey<String>('langue-retour');

  /// La phrase « sans choix, tout arrive en francais ».
  static const Key parDefautKey = ValueKey<String>('langue-par-defaut');

  @override
  ConsumerState<LangueCourrielsPage> createState() =>
      _LangueCourrielsPageState();
}

class _LangueCourrielsPageState extends ConsumerState<LangueCourrielsPage> {
  // La carte touchee, pas encore enregistree.
  String? _choix;
  // La langue enregistree pendant cette ouverture ; prime sur la lecture.
  String? _enregistree;
  bool _enCours = false;
  RetourLangue? _retour;
  String? _libelleEnregistre;

  bool get _horsLigne => ref.read(horsLigneProvider).value ?? false;

  Future<void> _enregistrer(LangueCommunication langue) async {
    if (_enCours) return;
    if (_horsLigne) {
      setState(() => _retour = RetourLangue.horsLigne);
      return;
    }
    // Pose avant tout `await` : un second appui n'envoie rien.
    setState(() {
      _enCours = true;
      _retour = null;
    });
    RetourLangue retour;
    try {
      await ref.read(portLanguesCommunicationProvider).regler(langue.code);
      retour = RetourLangue.enregistre;
    } on LangueRefusee {
      retour = RetourLangue.refusee;
    } on PermissionInsuffisante {
      retour = RetourLangue.refus;
    } on Object {
      retour = _horsLigne ? RetourLangue.horsLigne : RetourLangue.echec;
    }
    if (!mounted) return;
    setState(() {
      _enCours = false;
      _retour = retour;
      if (retour == RetourLangue.enregistre) {
        _enregistree = langue.code;
        _libelleEnregistre = langue.libelle;
        _choix = null;
      }
    });
  }

  String _message(RetourLangue r) {
    final retour = t.compte.langueCourriels.retour;
    return switch (r) {
      RetourLangue.enregistre => retour.enregistre(
        langue: isolerSens(_libelleEnregistre ?? ''),
      ),
      RetourLangue.refusee => retour.refusee,
      RetourLangue.refus => retour.refus,
      RetourLangue.echec => retour.echec,
      RetourLangue.horsLigne => retour.horsLigne,
    };
  }

  Widget? _etatErreur(Object e, VoidCallback? reessayer) {
    final l = t.compte.langueCourriels;
    if (e is CapaciteIndisponible) {
      return EtatSysteme(
        key: const ValueKey<String>('langue-indisponible'),
        nature: NatureEtat.indisponible,
        titre: l.indisponibleTitre,
        phrase: l.indisponiblePhrase,
        dependance: e.dependance,
      );
    }
    if (e is PermissionInsuffisante) {
      return EtatSysteme(
        key: const ValueKey<String>('langue-refuse'),
        nature: NatureEtat.echecServeur,
        phrase: l.retour.refus,
      );
    }
    return _horsLigne
        ? EtatSansDonnees(
            key: const ValueKey<String>('langue-sans-donnees'),
            quoi: l.sansDonnees,
            onAction: reessayer,
          )
        : EtatSysteme(
            key: const ValueKey<String>('langue-erreur'),
            nature: NatureEtat.echecServeur,
            phrase: l.erreurLangues,
            onAction: reessayer,
          );
  }

  @override
  Widget build(BuildContext context) {
    final l = t.compte.langueCourriels;
    // Suit le reseau pour que l'etat « sans donnees » se redessine.
    ref.watch(horsLigneProvider);
    final AsyncValue<EtatLanguesCommunication> valeur = ref.watch(
      languesCommunicationProvider,
    );
    return PageShell(
      titre: l.titre,
      sousTitre: l.sousTitre,
      onRetour:
          widget.onRetour ??
          () {
            final GoRouter routeur = GoRouter.of(context);
            if (routeur.canPop()) {
              routeur.pop();
            } else {
              routeur.go(Routes.compteReglages);
            }
          },
      child: ColonneSousPage(
        child: BlocAsynchrone<EtatLanguesCommunication>(
          key: const ValueKey<String>('langue-bloc'),
          valeur: valeur,
          squelette: const Skeleton.liste(lignes: 3),
          onReessayer: () => ref.invalidate(languesCommunicationProvider),
          vide: Text(
            l.vide,
            key: const ValueKey<String>('langue-vide'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          estVide: (EtatLanguesCommunication e) => e.langues.isEmpty,
          erreurVersEtat: _etatErreur,
          construire: _contenu,
        ),
      ),
    );
  }

  Widget _contenu(EtatLanguesCommunication lu) {
    final l = t.compte.langueCourriels;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String courante = _enregistree ?? lu.code;
    final String? choix = _choix;
    LangueCommunication? aEnregistrer;
    if (choix != null && choix != courante) {
      for (final LangueCommunication x in lu.langues) {
        if (x.code == choix) aEnregistrer = x;
      }
    }
    final RetourLangue? retour = _retour;
    return Column(
      key: const ValueKey<String>('langue-contenu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(l.choix, style: textes.titleMedium),
        ),
        Ecart.vSm,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(valeurs: <String>{courante}),
          options: <OptionChoix>[
            for (final LangueCommunication x in lu.langues)
              OptionChoix(
                cle: LangueCourrielsPage.carteKey(x.code),
                valeur: x.code,
                libelle: x.libelle,
                description: l.optionDetail(langue: isolerSens(x.libelle)),
              ),
          ],
          onChange: (ReponseChoix r) => setState(() {
            _choix = r.valeurs.isEmpty ? null : r.valeurs.first;
            _retour = null;
          }),
        ),
        Ecart.vMd,
        Text(
          l.parDefaut,
          key: LangueCourrielsPage.parDefautKey,
          style: textes.bodyMedium,
        ),
        Ecart.vLg,
        if (retour != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                _message(retour),
                key: LangueCourrielsPage.retourKey,
                style:
                    (retour == RetourLangue.enregistre
                            ? palette.inkStrong
                            : palette.inkAlert)
                        .applyTo(textes.bodyMedium ?? const TextStyle()),
              ),
            ),
          ),
        if (aEnregistrer case final LangueCommunication cible)
          ActionPrincipale(
            key: LangueCourrielsPage.enregistrerKey,
            libelle: l.enregistrer,
            enCours: _enCours,
            onPress: () => unawaited(_enregistrer(cible)),
          ),
      ],
    );
  }
}

// PAYS-VERSEMENT (directeur, 15/11/2026) puis VERSEMENT-QUESTIONS (directeur,
// 16/11/2026) : apres l'envoi, le candidat modifie lui-meme TOUT le bloc de
// versement depuis son portail (compte bancaire oui ou non, pays, services de
// paiement sur telephone), tant que l'academie n'a pas valide son dossier ;
// apres, une phrase dit que c'est ferme et renvoie vers la messagerie.
//
// Le compte peut etre celui d'un proche de confiance dans un pays pris en
// charge. Le serveur (`modifier_mon_versement`) borne le geste a la
// candidature du titulaire et a l'etape de prequalification, remet les
// coordonnees a valider si le pays change et recalcule le paiement : la
// candidature n'est jamais refusee pour ce motif. Les pays proposes sont ceux
// que le serveur accepte (la liste ISO) : l'ecran n'en invente aucun.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/port_ma_candidature.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import 'choix_avec_recherche.dart';
import 'libelles_parcours.dart';
import 'question_etape.dart' show motsClesDuPays, paysCourants;

/// Vrai quand le candidat peut modifier son versement : candidature en cours,
/// hors refus et retrait, avec des reponses deja envoyees, et dossier pas
/// encore valide (la prequalification : directeur, 16/11/2026).
bool peutChangerPaysVersement(CandidatureDossier c) =>
    c.existe &&
    c.issue == IssueCandidature.enCours &&
    c.questionnaire.envoyeLe != null &&
    c.etape == EtapeCandidature.prequalification;

/// Vrai quand le versement est ferme : le dossier est valide (l'academie l'a
/// fait passer au-dela de la prequalification), le candidat ne le modifie plus.
bool versementFerme(CandidatureDossier c) =>
    c.existe &&
    c.issue == IssueCandidature.enCours &&
    c.questionnaire.envoyeLe != null &&
    (c.etape == EtapeCandidature.verifications ||
        c.etape == EtapeCandidature.confirmee);

/// Vrai quand le bloc du versement s'affiche : le lien pour modifier, ou la
/// phrase qui dit que c'est ferme.
bool afficheBlocVersement(CandidatureDossier c) =>
    peutChangerPaysVersement(c) || versementFerme(c);

/// Le lien « Modifier mon versement » et son panneau ; une fois le dossier
/// valide, la phrase qui dit que c'est ferme et le renvoi vers la messagerie.
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

  /// La cle de la phrase « le versement est ferme » (dossier valide).
  static const Key fermeKey = ValueKey<String>('versement-ferme');

  /// La cle du lien vers la messagerie, une fois le dossier valide.
  static const Key fermeLienKey = ValueKey<String>('versement-ferme-lien');

  @override
  ConsumerState<LienPaysVersement> createState() => _LienPaysVersementState();
}

class _LienPaysVersementState extends ConsumerState<LienPaysVersement> {
  String? _message;
  bool _reussi = false;

  Future<void> _ouvrir() async {
    // Ce que le candidat a deja repondu prerempli le panneau (deduit > saisi) ;
    // sans lecture, il part vide.
    Map<String, Object?> reponses = const <String, Object?>{};
    try {
      final Questionnaire q = await ref.read(
        questionnaireCandidatProvider.future,
      );
      reponses = q.dernieresReponses?.reponses ?? reponses;
    } on Object {
      // Panneau vide : le candidat choisit lui-meme.
    }
    if (!mounted) {
      return;
    }
    final _SaisieVersement saisie = _SaisieVersement(ref, reponses);
    final String? fait = await AppBottomSheet.ouvrir<String>(
      context,
      titre: t.recrutement.portail.paysVersementTitre,
      panneauLateral: true,
      constructeur: (BuildContext contexte) =>
          _ContenuVersement(saisie: saisie),
      // Le bouton reste dans le pied du panneau : jamais sous la liste.
      actions: (BuildContext contexte) => _PiedVersement(saisie: saisie),
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
        !afficheBlocVersement(widget.candidature)) {
      return const SizedBox.shrink();
    }
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    if (versementFerme(widget.candidature)) {
      // Directeur, 16/11/2026 : les modifications s'arretent apres la
      // validation du dossier ; une phrase et le renvoi vers la messagerie.
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            t.recrutement.portail.versementFerme,
            key: LienPaysVersement.fermeKey,
            textAlign: TextAlign.center,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          LienFleche(
            key: LienPaysVersement.fermeLienKey,
            libelle: t.recrutement.portail.versementFermeLien,
            onPress: () =>
                GoRouter.maybeOf(context)?.go(Routes.attenteMessages),
          ),
        ],
      );
    }
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
class _SaisieVersement extends ChangeNotifier {
  _SaisieVersement(this._ref, Map<String, Object?> reponses) {
    final Object? compte = reponses['compteBancaire'];
    if (compte is bool) {
      this.compte = compte;
    }
    final Object? pays = reponses['paysVersement'];
    if (pays is String && paysDuCode(pays) != null) {
      choix = pays;
    }
    final Object? ops = reponses['operateurs'];
    if (ops is List) {
      operateurs.addAll(<String>[
        for (final Object? o in ops)
          if (o is String) o,
      ]);
    }
  }

  final WidgetRef _ref;
  bool? compte;
  String? choix;
  final Set<String> operateurs = <String>{};
  bool enCours = false;
  String? echec;

  void choisirCompte(bool valeur) {
    compte = valeur;
    if (valeur) {
      operateurs.clear();
    }
    notifyListeners();
  }

  void choisir(String pays) {
    if (pays != choix) {
      // Les services dependent du pays : ceux d'un autre pays ne valent plus.
      operateurs.clear();
    }
    choix = pays;
    notifyListeners();
  }

  void basculer(String code, Set<String> valeurs) {
    operateurs
      ..clear()
      ..addAll(valeurs);
    notifyListeners();
  }

  /// Vrai quand le bloc est assez rempli pour etre enregistre.
  bool get pret => compte != null && choix != null;

  Future<void> enregistrer(BuildContext context) async {
    final PortMaCandidature? port = _ref.read(portMaCandidatureProvider);
    final bool? avecCompte = compte;
    final String? pays = choix;
    if (port == null || avecCompte == null || pays == null) {
      return;
    }
    final r = t.recrutement.portail;
    enCours = true;
    echec = null;
    notifyListeners();
    try {
      await port.modifierVersement(
        compteBancaire: avecCompte,
        pays: pays,
        operateurs: avecCompte
            ? const <String>[]
            : (operateurs.toList()..sort()),
      );
      // Le portail relit l'etat du serveur : rien n'est deduit ici.
      _ref.invalidate(etatDossierProvider);
      _ref.invalidate(questionnaireCandidatProvider);
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

/// Le contenu du panneau : la phrase, le compte bancaire, le pays, les
/// services du pays (sans compte), l'echec eventuel.
class _ContenuVersement extends ConsumerWidget {
  const _ContenuVersement({required this.saisie});

  final _SaisieVersement saisie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Text(
            titreQuestion('compteBancaire') ?? '',
            style: textes.titleMedium,
          ),
          Ecart.vSm,
          _CompteOuiNon(saisie: saisie),
          Ecart.vLg,
          Text(
            titreQuestion('paysVersement', compteBancaire: saisie.compte) ?? '',
            style: textes.titleMedium,
          ),
          Ecart.vSm,
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
          if (saisie.compte == false && saisie.choix != null) ...<Widget>[
            Ecart.vLg,
            Text(titreQuestion('operateurs') ?? '', style: textes.titleMedium),
            Ecart.vSm,
            _ServicesDuPays(saisie: saisie, pays: saisie.choix!),
          ],
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

/// Oui ou non : un compte bancaire, a son nom ou a celui d'un proche.
class _CompteOuiNon extends StatelessWidget {
  const _CompteOuiNon({required this.saisie});

  final _SaisieVersement saisie;

  @override
  Widget build(BuildContext context) {
    OptionChoix option(String code, AppIcon icone) {
      final TextesOption x = textesOption('compteBancaire', code)!;
      return OptionChoix(
        cle: ValueKey<String>('versement-compte-$code'),
        valeur: code,
        libelle: x.libelle,
        description: x.description,
        explication: x.explication,
        exemple: x.exemple,
        icone: icone,
        illustration: IllustrationChoix(icone),
      );
    }

    return ChoiceCardGroup(
      key: const ValueKey<String>('versement-compte'),
      autoriserSaisieLibre: false,
      coteACote: true,
      valeurInitiale: saisie.compte == null
          ? null
          : ReponseChoix(valeurs: <String>{saisie.compte! ? 'oui' : 'non'}),
      options: <OptionChoix>[
        option('oui', AppIcons.paiements),
        option('non', AppIcons.appareil),
      ],
      onChange: (ReponseChoix r) {
        if (r.valeurs.contains('oui')) {
          saisie.choisirCompte(true);
        } else if (r.valeurs.contains('non')) {
          saisie.choisirCompte(false);
        }
      },
    );
  }
}

/// Les services de paiement sur telephone que l'academie a confirmes dans le
/// pays : au choix. Un pays sans service dit quoi faire.
class _ServicesDuPays extends ConsumerWidget {
  const _ServicesDuPays({required this.saisie, required this.pays});

  final _SaisieVersement saisie;
  final String pays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.recrutement.parcours.versement;
    final AsyncValue<MoyensConfirmes> valeur = ref.watch(
      moyensConfirmesProvider(pays),
    );
    return BlocAsynchrone<MoyensConfirmes>(
      key: ValueKey<String>('versement-services-$pays'),
      valeur: valeur,
      squelette: const Skeleton.liste(lignes: 2),
      titreEchec: r.nonCharge,
      onReessayer: () => ref.invalidate(moyensConfirmesProvider(pays)),
      erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
          erreur is HorsLigneCandidature
          ? EtatSansDonnees(quoi: r.nonCharge, onAction: reessayer)
          : null,
      construire: (MoyensConfirmes moyens) {
        if (moyens.operateurs.isEmpty) {
          return Text(
            moyens.virementBancaire ? r.virementSeul : r.aucunMoyen,
            key: const ValueKey<String>('versement-services-aucun'),
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return ChoiceCardGroup(
          key: ValueKey<String>('versement-services-$pays-groupe'),
          autoriserSaisieLibre: false,
          selectionMultiple: true,
          valeurInitiale: saisie.operateurs.isEmpty
              ? null
              : ReponseChoix(valeurs: saisie.operateurs.toSet()),
          options: <OptionChoix>[
            for (final OperateurPaiement o in moyens.operateurs)
              OptionChoix(
                cle: ValueKey<String>('versement-service-${o.code}'),
                valeur: o.code,
                libelle: o.nom,
                description: r.operateurDescription,
                explication: r.operateurExplication,
                icone: AppIcons.appareil,
              ),
          ],
          onChange: (ReponseChoix reponse) => saisie.basculer('', <String>{
            for (final OperateurPaiement o in moyens.operateurs)
              if (reponse.valeurs.contains(o.code)) o.code,
          }),
        );
      },
    );
  }
}

/// Le pied du panneau : le bouton, rendu seulement quand le compte et le pays
/// sont choisis.
class _PiedVersement extends StatelessWidget {
  const _PiedVersement({required this.saisie});

  final _SaisieVersement saisie;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: saisie,
    builder: (BuildContext contexte, Widget? _) => !saisie.pret
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

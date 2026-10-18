import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_mes_donnees.dart';
import '../../core/finance/format_montant.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/tc_telechargement/port_enregistrement_fichier.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'carte_rubriques.dart';

/// La demande de suppression en cours et ce qui reste du, lus au serveur
/// (`ma_situation_suppression`). Relu a chaque ouverture de l'ecran.
final FutureProvider<SituationSuppression> situationSuppressionProvider =
    FutureProvider.autoDispose<SituationSuppression>(
      (Ref ref) => ref.watch(portMesDonneesProvider).situation(),
    );

/// Vrai quand « Mes donnees » existe pour cette personne : la source repond,
/// ou echoue pour une autre raison qu'une capacite absente ou un refus. C'est
/// la capacite rendue par le port qui decide, jamais le role.
final Provider<bool> mesDonneesDisponiblesProvider = Provider.autoDispose<bool>(
  (Ref ref) {
    final AsyncValue<SituationSuppression> lecture = ref.watch(
      situationSuppressionProvider,
    );
    if (lecture.hasValue) return true;
    final Object? erreur = lecture.hasError ? lecture.error : null;
    return lecture.hasError &&
        erreur is! CapaciteIndisponible &&
        erreur is! PermissionInsuffisante;
  },
);

/// La longueur maximale du motif (le serveur refuse au-dela).
const int motifLongueurMax = 500;

/// Ce que dit la ligne sous « Telecharger une copie ».
enum RetourCopie {
  /// Le fichier est enregistre.
  reussi,

  /// La copie n'a pas pu etre preparee.
  echec,

  /// Pas de reseau.
  horsLigne,

  /// Le serveur refuse ce compte.
  refuse,
}

/// Ce que dit la ligne sous la demande de suppression.
enum RetourDemande {
  /// La demande est enregistree.
  envoyee,

  /// La demande est annulee.
  annulee,

  /// L'action n'a pas abouti.
  echec,

  /// Pas de reseau.
  horsLigne,

  /// Le serveur refuse ce compte.
  refuse,
}

/// La rubrique « Mes donnees » du Compte (CPT-SUPPR-EXPORT).
///
/// Elle n'apparait que si le port repond : c'est la capacite rendue par la
/// source qui decide, jamais le role (un widget ne lit pas un role). Un
/// serveur sans la fonction, ou qui refuse ce compte, ne montre rien : aucun
/// lien mort.
class RubriqueMesDonnees extends ConsumerWidget {
  /// Cree la rubrique. [onOuvrir] ouvre l'ecran.
  const RubriqueMesDonnees({required this.onOuvrir, super.key});

  /// La cle de la ligne.
  static const Key ligneKey = ValueKey<String>('rubrique-mes-donnees');

  /// Ouvre « Mes donnees ».
  final VoidCallback onOuvrir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(mesDonneesDisponiblesProvider)) {
      return const SizedBox.shrink();
    }
    final d = t.compte.donnees;
    return Column(
      key: ligneKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Ecart.vSection,
        GroupeReglages(
          titre: d.titre,
          lignes: <LigneRubrique>[
            LigneRubrique(
              icone: AppIcons.dossiers,
              libelle: d.ligne,
              legende: d.ligneDetail,
              onPress: onOuvrir,
            ),
          ],
        ),
      ],
    );
  }
}

/// « Mes donnees » : telecharger une copie de ses donnees, demander la
/// suppression de son compte. Ouvert depuis le Compte (tuteur, eleve adulte,
/// enseignant) ; le serveur borne la copie a la personne et, pour un tuteur,
/// a son foyer.
class MesDonneesPage extends ConsumerStatefulWidget {
  /// Cree la page. [onRetour] : le retour de l'en-tete ; par defaut, la page
  /// precedente, sinon le Compte.
  const MesDonneesPage({super.key, this.onRetour});

  /// Le bouton plein : telecharger la copie.
  static const Key actionKey = ValueKey<String>('mes-donnees-telecharger');

  /// Le lien qui demande la suppression.
  static const Key demanderKey = ValueKey<String>('mes-donnees-demander');

  /// Le lien qui annule la demande.
  static const Key annulerKey = ValueKey<String>('mes-donnees-annuler');

  /// Le champ du motif.
  static const Key motifKey = ValueKey<String>('mes-donnees-motif');

  /// La ligne qui dit ce qu'est devenue la copie.
  static const Key retourCopieKey = ValueKey<String>(
    'mes-donnees-retour-copie',
  );

  /// La ligne qui dit ce qu'est devenue la demande.
  static const Key retourDemandeKey = ValueKey<String>(
    'mes-donnees-retour-demande',
  );

  /// La ligne « aucune demande en cours ».
  static const Key aucuneDemandeKey = ValueKey<String>(
    'mes-donnees-aucune-demande',
  );

  /// Le retour de l'en-tete.
  final VoidCallback? onRetour;

  @override
  ConsumerState<MesDonneesPage> createState() => _MesDonneesPageState();
}

class _MesDonneesPageState extends ConsumerState<MesDonneesPage> {
  final TextEditingController _motif = TextEditingController();
  bool _copieEnCours = false;
  bool _demandeEnCours = false;
  RetourCopie? _retourCopie;
  RetourDemande? _retourDemande;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  bool get _horsLigne => ref.read(horsLigneProvider).value ?? false;

  Future<void> _telecharger() async {
    if (_copieEnCours) return;
    setState(() {
      _copieEnCours = true;
      _retourCopie = null;
    });
    RetourCopie? retour;
    try {
      final CopieDonnees copie = await ref
          .read(portMesDonneesProvider)
          .exporter();
      final String? destination = await ref
          .read(portEnregistrementFichierProvider)
          .enregistrerCopie(
            octets: copie.octets,
            nomFichierPropose: copie.nomFichier,
            typeMime: 'application/json',
          );
      // Une annulation n'est pas une erreur : aucun message.
      retour = destination == null ? null : RetourCopie.reussi;
    } on PermissionInsuffisante {
      retour = RetourCopie.refuse;
    } on Object {
      retour = _horsLigne ? RetourCopie.horsLigne : RetourCopie.echec;
    }
    if (!mounted) return;
    setState(() {
      _copieEnCours = false;
      _retourCopie = retour;
    });
  }

  Future<void> _demander(SituationSuppression situation) async {
    if (_demandeEnCours) return;
    final d = t.compte.donnees.suppression;
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: d.confirmerQuestion,
      consequence: d.confirmerConsequence(n: situation.delaiJours),
      libelleConfirmer: d.confirmerAction,
      libelleAnnuler: d.confirmerRester,
    );
    if (!confirme || !mounted) return;
    final String brut = _motif.text.trim();
    final String? motif = brut.isEmpty
        ? null
        : (brut.length > motifLongueurMax
              ? brut.substring(0, motifLongueurMax)
              : brut);
    await _agir(
      (PortMesDonnees port) => port.demander(motif: motif),
      RetourDemande.envoyee,
      apres: _motif.clear,
    );
  }

  Future<void> _annuler() =>
      _agir((PortMesDonnees port) => port.annuler(), RetourDemande.annulee);

  Future<void> _agir(
    Future<void> Function(PortMesDonnees port) action,
    RetourDemande reussi, {
    VoidCallback? apres,
  }) async {
    if (_demandeEnCours) return;
    setState(() {
      _demandeEnCours = true;
      _retourDemande = null;
    });
    RetourDemande retour = reussi;
    try {
      await action(ref.read(portMesDonneesProvider));
      apres?.call();
      ref.invalidate(situationSuppressionProvider);
    } on PermissionInsuffisante {
      retour = RetourDemande.refuse;
    } on Object {
      retour = _horsLigne ? RetourDemande.horsLigne : RetourDemande.echec;
    }
    if (!mounted) return;
    setState(() {
      _demandeEnCours = false;
      _retourDemande = retour;
    });
  }

  void _retour() {
    final VoidCallback? surMesure = widget.onRetour;
    if (surMesure != null) {
      surMesure();
      return;
    }
    final GoRouter routeur = GoRouter.of(context);
    if (routeur.canPop()) {
      routeur.pop();
    } else {
      routeur.go(Routes.compte);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = t.compte.donnees;
    final AsyncValue<SituationSuppression> lecture = ref.watch(
      situationSuppressionProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    return PageShell(
      titre: d.titre,
      sousTitre: d.sousTitre,
      onRetour: _retour,
      actions: ActionPrincipale(
        key: MesDonneesPage.actionKey,
        libelle: d.copie.action,
        enCours: _copieEnCours,
        onPress: () => unawaited(_telecharger()),
      ),
      child: ColonneSousPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _CarteCopie(retour: _retourCopie),
            Ecart.vLg,
            AppCard(
              child: BlocAsynchrone<SituationSuppression>(
                valeur: lecture,
                squelette: const Skeleton.liste(lignes: 3),
                onReessayer: () => ref.invalidate(situationSuppressionProvider),
                erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
                  if (erreur is PermissionInsuffisante) {
                    return _Message(texte: d.suppression.refuse, echec: true);
                  }
                  return horsLigne && erreur is! CapaciteIndisponible
                      ? EtatSysteme.sansDonnees(
                          quoi: t.sansDonnees.mesDonnees,
                          onAction: reessayer,
                        )
                      : null;
                },
                construire: (SituationSuppression s) => _CarteSuppression(
                  situation: s,
                  motif: _motif,
                  enCours: _demandeEnCours,
                  retour: _retourDemande,
                  onDemander: () => unawaited(_demander(s)),
                  onAnnuler: () => unawaited(_annuler()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le titre d'une carte de la page.
class _Titre extends StatelessWidget {
  const _Titre(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(texte, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// Une ligne de retour, lue par le lecteur d'ecran des qu'elle apparait.
class _Message extends StatelessWidget {
  const _Message({required this.texte, required this.echec, this.cle});

  final String texte;
  final bool echec;
  final Key? cle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        texte,
        key: cle,
        style: (echec ? palette.inkAlert : palette.inkStrong).applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      ),
    );
  }
}

class _CarteCopie extends StatelessWidget {
  const _CarteCopie({required this.retour});

  final RetourCopie? retour;

  @override
  Widget build(BuildContext context) {
    final c = t.compte.donnees.copie;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle attenue = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    final RetourCopie? r = retour;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Titre(c.titre),
          Ecart.vSm,
          Text(c.intro),
          Ecart.vSm,
          Text(c.exclus, style: attenue),
          if (r != null) ...<Widget>[
            Ecart.vLg,
            _Message(
              cle: MesDonneesPage.retourCopieKey,
              echec: r != RetourCopie.reussi,
              texte: switch (r) {
                RetourCopie.reussi => c.reussi,
                RetourCopie.echec => c.echec,
                RetourCopie.horsLigne => c.horsLigne,
                RetourCopie.refuse => c.refuse,
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _CarteSuppression extends StatelessWidget {
  const _CarteSuppression({
    required this.situation,
    required this.motif,
    required this.enCours,
    required this.retour,
    required this.onDemander,
    required this.onAnnuler,
  });

  final SituationSuppression situation;
  final TextEditingController motif;
  final bool enCours;
  final RetourDemande? retour;
  final VoidCallback onDemander;
  final VoidCallback onAnnuler;

  @override
  Widget build(BuildContext context) {
    final s = t.compte.donnees.suppression;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final DemandeSuppression? demande = situation.demande;
    final RetourDemande? r = retour;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Titre(s.titre),
        Ecart.vSm,
        Text(s.intro(n: situation.delaiJours)),
        Ecart.vSm,
        Text(s.effacement, style: attenue),
        Ecart.vSm,
        Text(s.conservation, style: attenue),
        // Ce qui reste n'empeche pas la demande : l'ecran le dit avant.
        if (situation.soldeDu) ...<Widget>[
          Ecart.vLg,
          BandeauAttention(
            titre: s.soldeTitre,
            message: s.soldeDetail(
              montant: enchainer(
                situation.montantsDus.map<String>(formaterMontant),
                ' · ',
              ),
            ),
          ),
        ],
        if (situation.seancesAVenir > 0) ...<Widget>[
          Ecart.vLg,
          BandeauAttention(
            titre: s.seancesTitre,
            message: s.seancesDetail(n: situation.seancesAVenir),
          ),
        ],
        Ecart.vLg,
        if (demande != null) ...<Widget>[
          Text(s.enCoursTitre, style: textes.titleSmall),
          Ecart.vSm,
          Text(
            s.enCoursDetail(
              demandee: dateDeLAppareil(demande.demandeeLe),
              echeance: dateDeLAppareil(demande.echeanceLe),
            ),
          ),
          Ecart.vLg,
          LienFleche(
            key: MesDonneesPage.annulerKey,
            libelle: s.annuler,
            onPress: onAnnuler,
          ),
        ] else ...<Widget>[
          Text(s.aucuneDemande, key: MesDonneesPage.aucuneDemandeKey),
          Ecart.vLg,
          ChampEtiquete(
            key: MesDonneesPage.motifKey,
            libelle: s.motifLibelle,
            aide: s.motifAide,
            controller: motif,
            maxLines: 3,
          ),
          Ecart.vLg,
          LienFleche(
            key: MesDonneesPage.demanderKey,
            libelle: s.demander,
            onPress: onDemander,
          ),
        ],
        if (r != null) ...<Widget>[
          Ecart.vLg,
          _Message(
            cle: MesDonneesPage.retourDemandeKey,
            echec:
                r == RetourDemande.echec ||
                r == RetourDemande.horsLigne ||
                r == RetourDemande.refuse,
            texte: switch (r) {
              RetourDemande.envoyee => s.demandeEnvoyee,
              RetourDemande.annulee => s.demandeAnnulee,
              RetourDemande.echec => s.echec,
              RetourDemande.horsLigne => s.horsLigne,
              RetourDemande.refuse => s.refuse,
            },
          ),
        ],
      ],
    );
  }
}

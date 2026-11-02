// FN-115c (pilote, 02/11/2026) : « Rembourser », dans le menu « ... » de la
// ligne d'un eleve de Finance > Paiements. Decision du directeur du
// 01/11/2026 (point 7) : le serveur propose le montant juste, la direction
// confirme, l'application rembourse par le prestataire.
//
// La feuille lit les paiements de l'eleve et ce que le serveur propose de
// rendre, avec le detail de la regle (rien n'est calcule ici) ; « Rembourser
// {montant} » confirme ce montant (plafonne par le serveur), puis l'envoie au
// prestataire. Une cle par feuille : un double toucher, ou « Reessayer »
// apres une coupure, ne rembourse jamais deux fois (le serveur rend la meme
// demande, et Stripe le meme remboursement).
//
// Etats : chargement, contenu, vide (« Aucun paiement a rembourser »),
// erreur, hors ligne (la phrase des paiements, sans bouton).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/capacites/port_remboursements_direction.dart';
import '../../../core/finance/format_montant.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/dates_appareil.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/confirm_destructive.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/ligne_cle_valeur.dart';
import '../../../core/widgets/status_pill.dart';

/// Les eleves qui ont un paiement remboursable : la capacite du serveur qui
/// montre « Rembourser » sur leur ligne. Une erreur n'en montre aucun.
final FutureProvider<Set<String>> elevesRemboursablesProvider =
    FutureProvider<Set<String>>(
      (Ref ref) =>
          ref.watch(portRemboursementsDirectionProvider).elevesRemboursables(),
    );

/// Les paiements d'un eleve, avec le montant propose.
final paiementsRemboursablesProvider = FutureProvider.autoDispose
    .family<List<PaiementRemboursable>, String>(
      (Ref ref, String profilId) =>
          ref.watch(portRemboursementsDirectionProvider).paiements(profilId),
    );

/// La date d'un paiement au fil de la phrase (« Paiement du lundi 2
/// novembre ») : la date de l'appareil, sans majuscule initiale.
String _datePaiement(DateTime quand) {
  final String d = dateDeLAppareil(quand.toLocal());
  return d.isEmpty ? d : d[0].toLowerCase() + d.substring(1);
}

/// Ouvre la feuille ; vrai si un remboursement est parti.
Future<bool> ouvrirRemboursement(
  BuildContext context, {
  required String profilId,
  required String prenom,
}) async {
  final ProviderContainer portee = ProviderScope.containerOf(
    context,
    listen: false,
  );
  final bool? change = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: t.admin.finance.pai.rembTitre(prenom: prenom),
    constructeur: (BuildContext _) => UncontrolledProviderScope(
      container: portee,
      child: FeuilleRemboursement(profilId: profilId, prenom: prenom),
    ),
  );
  return change ?? false;
}

enum _Phase { choix, envoi, envoye, refuse, inconnue }

/// Le contenu de la feuille « Rembourser ».
class FeuilleRemboursement extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleRemboursement({
    required this.profilId,
    required this.prenom,
    super.key,
  });

  /// L'eleve vise.
  final String profilId;

  /// Son prenom, dit dans la seconde confirmation.
  final String prenom;

  /// La cle du bouton qui rembourse.
  static const Key cleConfirmer = ValueKey<String>('remboursement-confirmer');

  /// La cle du montant propose.
  static const Key clePropose = ValueKey<String>('remboursement-propose');

  /// La cle du bandeau « Remboursement envoye ».
  static const Key cleEnvoye = ValueKey<String>('remboursement-envoye');

  /// La cle de l'etat vide.
  static const Key cleVide = ValueKey<String>('remboursement-vide');

  /// La cle d'un paiement a choisir.
  static Key clePaiement(String commandeId) =>
      ValueKey<String>('remboursement-paiement-$commandeId');

  @override
  ConsumerState<FeuilleRemboursement> createState() =>
      _FeuilleRemboursementState();
}

class _FeuilleRemboursementState extends ConsumerState<FeuilleRemboursement> {
  /// Tiree une fois par feuille, rejouee telle quelle a chaque nouvel essai.
  final String _cle = const Uuid().v4();
  String? _choisi;
  String? _demande;
  _Phase _phase = _Phase.choix;
  bool _change = false;

  /// Vrai pendant que la seconde confirmation est ouverte : un double appui
  /// n'en ouvre pas une deuxieme.
  bool _question = false;

  Future<void> _rembourser(PaiementRemboursable paiement) async {
    if (_phase == _Phase.envoi || _question) return;
    // Seconde confirmation : garde-fou demande par le directeur le
    // 02/11/2026 contre un remboursement par accident ; la seconde fenetre
    // est un choix du pilote. Rien ne part sans « Oui, rembourser ». « Annuler » a le focus ; Echap ou un clic a cote
    // renoncent. Une demande deja confirmee (reprise apres une coupure) ne
    // se redemande pas : elle repart telle quelle.
    if (_demande == null) {
      final p = t.admin.finance.pai;
      _question = true;
      final bool oui = await ConfirmDestructive.demander(
        context,
        question: p.rembQuestion(
          montant: formaterMontant(paiement.propose),
          prenom: widget.prenom,
        ),
        consequence: p.rembSansRetour,
        libelleConfirmer: p.rembOui,
        annulerParDefaut: true,
      );
      _question = false;
      if (!oui || !mounted) return;
    }
    setState(() => _phase = _Phase.envoi);
    final PortRemboursementsDirection port = ref.read(
      portRemboursementsDirectionProvider,
    );
    try {
      // La meme cle a chaque essai : le serveur rend la meme demande.
      final String demande =
          _demande ??
          await port.confirmer(
            commandeId: paiement.commandeId,
            profilId: widget.profilId,
            montant: paiement.propose,
            cle: _cle,
          );
      _demande = demande;
      final IssueRemboursement issue = await port.envoyer(demande);
      if (!mounted) return;
      setState(() {
        _change = true;
        _phase = issue == IssueRemboursement.refuse
            ? _Phase.refuse
            : _Phase.envoye;
      });
      if (issue == IssueRemboursement.refuse) _demande = null;
    } on Object {
      if (!mounted) return;
      setState(() => _phase = _Phase.inconnue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = t.admin.finance.pai;
    final AsyncValue<List<PaiementRemboursable>> lus = ref.watch(
      paiementsRemboursablesProvider(widget.profilId),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return lus.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Text(p.rembChargement),
      ),
      error: (Object _, StackTrace _) => horsLigne
          ? Text(p.horsLigne)
          : BandeauAttention(
              titre: p.rembRefuseTitre,
              message: p.rembErreur,
              ton: TonEtat.alerte,
            ),
      data: (List<PaiementRemboursable> tous) {
        final List<PaiementRemboursable> paiements = <PaiementRemboursable>[
          for (final PaiementRemboursable x in tous)
            if (x.remboursable) x,
        ];
        if (paiements.isEmpty) {
          return EmptyState(
            key: FeuilleRemboursement.cleVide,
            message: p.rembAucun,
            registre: RegistreVide.subi,
          );
        }
        final PaiementRemboursable choisi = paiements.firstWhere(
          (PaiementRemboursable x) => x.commandeId == _choisi,
          orElse: () => paiements.first,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (paiements.length > 1 && _phase == _Phase.choix) ...<Widget>[
              ChoiceCardGroup(
                options: <OptionChoix>[
                  for (final PaiementRemboursable x in paiements)
                    OptionChoix(
                      valeur: x.commandeId,
                      libelle: p.rembPaiement(date: _datePaiement(x.payeLe)),
                      description: formaterMontant(x.propose),
                      cle: FeuilleRemboursement.clePaiement(x.commandeId),
                    ),
                ],
                valeurInitiale: ReponseChoix(
                  valeurs: <String>{choisi.commandeId},
                ),
                autoriserSaisieLibre: false,
                onChange: (ReponseChoix r) =>
                    setState(() => _choisi = r.valeurs.firstOrNull),
              ),
              Ecart.vLg,
            ],
            ..._detail(choisi),
            Ecart.vLg,
            ..._issue(),
            Ecart.vXl,
            _actions(context, choisi, horsLigne: horsLigne),
          ],
        );
      },
    );
  }

  List<Widget> _detail(PaiementRemboursable x) {
    final p = t.admin.finance.pai;
    final Montant? deja = x.dejaRendu;
    return <Widget>[
      LigneCleValeur(
        cle: p.rembPaiement(date: _datePaiement(x.payeLe)),
        valeur: x.reference,
      ),
      LigneCleValeur(
        cle: p.rembPaye,
        valeur: formaterMontant(x.paye),
        chiffres: true,
      ),
      if (x.regle == RegleRemboursement.delai && x.prixSeance != null)
        LigneCleValeur(
          cle: p.rembSeances,
          valeur: p.rembFois(
            n: x.seancesSuivies,
            prix: formaterMontant(x.prixSeance!),
          ),
          chiffres: true,
        ),
      if (x.regle == RegleRemboursement.prepaiement && x.prixMensuel != null)
        LigneCleValeur(
          cle: p.rembMois,
          valeur: p.rembFois(
            n: x.moisCommences,
            prix: formaterMontant(x.prixMensuel!),
          ),
          chiffres: true,
        ),
      if (deja != null)
        LigneCleValeur(
          cle: p.rembDejaRendu,
          valeur: formaterMontant(deja),
          chiffres: true,
        ),
      LigneCleValeur(
        key: FeuilleRemboursement.clePropose,
        cle: p.rembPropose,
        valeur: formaterMontant(x.propose),
        chiffres: true,
        valeurForte: true,
      ),
      Ecart.vSm,
      Text(
        switch (x.regle) {
          RegleRemboursement.delai => LibellesGroupe.insecable(
            p.rembRegleDelai(jours: x.delaiJours ?? 0),
          ),
          RegleRemboursement.prepaiement => p.rembReglePrepaiement,
          _ => p.rembRien,
        },
        style: AppPalette.of(context).inkMuted.applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      ),
    ];
  }

  List<Widget> _issue() {
    final p = t.admin.finance.pai;
    return switch (_phase) {
      _Phase.envoye => <Widget>[
        BandeauAttention(
          key: FeuilleRemboursement.cleEnvoye,
          titre: p.rembEnvoyeTitre,
          message: p.rembEnvoyePhrase,
          ton: TonEtat.succes,
        ),
      ],
      _Phase.refuse => <Widget>[
        BandeauAttention(
          titre: p.rembRefuseTitre,
          message: p.rembRefusePhrase,
          ton: TonEtat.alerte,
        ),
      ],
      _Phase.inconnue => <Widget>[
        BandeauAttention(
          titre: p.rembRefuseTitre,
          message: p.rembErreur,
          ton: TonEtat.avertissement,
        ),
      ],
      _ => const <Widget>[],
    };
  }

  Widget _actions(
    BuildContext context,
    PaiementRemboursable choisi, {
    required bool horsLigne,
  }) {
    final p = t.admin.finance.pai;
    final bool envoi = _phase == _Phase.envoi;
    final bool fini = _phase == _Phase.envoye;
    final List<Widget> boutons = <Widget>[
      ActionPrincipale(
        libelle: fini ? p.fermer : p.annuler,
        niveau: NiveauAction.tertiaire,
        onPress: envoi ? null : () => Navigator.of(context).pop(_change),
      ),
      if (!fini && !horsLigne)
        ActionPrincipale(
          key: FeuilleRemboursement.cleConfirmer,
          libelle: _phase == _Phase.inconnue || _phase == _Phase.refuse
              ? p.reessayer
              : p.rembConfirmer(montant: formaterMontant(choisi.propose)),
          enCours: envoi,
          onPress: () => _rembourser(choisi),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (horsLigne && !fini) ...<Widget>[Text(p.horsLigne), Ecart.vMd],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.end,
          children: boutons,
        ),
      ],
    );
  }
}

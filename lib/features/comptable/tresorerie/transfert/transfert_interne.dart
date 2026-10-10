// Mouvement entre coffres (`TreasuryInternalTransfer`, spec §9.5, §10 ;
// CPT-BR-05 ; DR-15 ; CPT-TRES-2).
//
// Trois temps, jamais moins : **choisir** un couple permis par la politique
// et un montant (propose par la politique, modifiable, K-57) ; **verifier**
// le montant exact (confirmation explicite) ; **envoyer une fois** (cle
// d'idempotence gardee pour la nouvelle tentative). Le resultat est celui du
// port, jamais un succes local (§5.3) : « execute par la source »,
// « Validation demandee » (sortie d'un coffre protege, retrait de la Reserve
// strategique : jamais d'execution directe demandee par l'ecran), ou refus
// avec sa raison. Les couples interdits (§10.4) ne sont jamais proposes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/capacites/capacite_indisponible.dart';
import '../../../../core/capacites/port_tresorerie.dart';
import '../../../../core/comptable/statuts_comptable.dart';
import '../../../../core/comptable/visibilite_montants.dart';
import '../../../../core/finance/format_montant.dart';
import '../../../../core/finance/montant.dart';
import '../../../../core/i18n/strings.g.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/action_principale.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/choice_card_group.dart';
import '../../../../core/widgets/montant_argent.dart';
import '../../../../core/widgets/montant_sensible.dart';
import '../../../../core/widgets/pastilles_comptable.dart';
import '../tresorerie_donnees.dart';

/// Ouvre le mouvement entre coffres dans une feuille (mobile) ou une boite
/// de dialogue (bureau), dans le **meme** conteneur de providers que la
/// page (la demonstration a le sien, sous la route modale).
Future<void> ouvrirTransfertInterne(
  BuildContext context, {
  required String titre,
  required List<MouvementPermis> offerts,
  required String devise,
  List<MouvementBloque> bloques = const <MouvementBloque>[],
  Montant? manqueReserve,
  VoidCallback? onMouvement,
}) {
  final ProviderContainer conteneur = ProviderScope.containerOf(context);
  return AppBottomSheet.ouvrir<void>(
    context,
    titre: titre,
    constructeur: (BuildContext _) => UncontrolledProviderScope(
      container: conteneur,
      child: TransfertInterne(
        offerts: offerts,
        bloques: bloques,
        devise: devise,
        manqueReserve: manqueReserve,
        onMouvement: onMouvement,
      ),
    ),
  );
}

enum _Etape { saisie, verification, envoi, resultat }

/// Le contenu du mouvement entre coffres.
class TransfertInterne extends ConsumerStatefulWidget {
  /// Cree le contenu.
  const TransfertInterne({
    required this.offerts,
    required this.devise,
    super.key,
    this.bloques = const <MouvementBloque>[],
    this.manqueReserve,
    this.onMouvement,
  });

  /// Les couples proposes (deja filtres par `MouvementsCoffres`).
  final List<MouvementPermis> offerts;

  /// Les couples refuses, montres avec leur raison et jamais pressables.
  final List<MouvementBloque> bloques;

  /// La devise de la saisie.
  final String devise;

  /// Le manque a completer de la Reserve, propose pour l'alimenter quand la
  /// politique ne propose pas de montant.
  final Montant? manqueReserve;

  /// Appele apres une reponse de la source qui change quelque chose
  /// (execute ou validation demandee) : la page relit ses chiffres.
  final VoidCallback? onMouvement;

  /// Cle du champ montant.
  static const Key cleMontant = ValueKey<String>('transfert-montant');

  /// Cle du bouton « Verifier le mouvement ».
  static const Key cleVerifier = ValueKey<String>('transfert-verifier');

  /// Cle du bouton d'envoi (« Confirmer » ou « Demander la validation »).
  static const Key cleEnvoyer = ValueKey<String>('transfert-envoyer');

  /// Cle de l'option d'un couple.
  static Key cleCouple(Coffre origine, Coffre destination) =>
      ValueKey<String>('couple-${origine.name}-${destination.name}');

  @override
  ConsumerState<TransfertInterne> createState() => _TransfertInterneState();
}

class _TransfertInterneState extends ConsumerState<TransfertInterne> {
  final TextEditingController _montant = TextEditingController();
  _Etape _etape = _Etape.saisie;
  int? _choisi;
  bool _montantInvalide = false;
  Montant? _aEnvoyer;
  String? _cle;
  ResultatMouvement? _resultat;
  Object? _echec;

  MouvementPermis? get _mouvement {
    final int? i = _choisi;
    return i == null ? null : widget.offerts[i];
  }

  @override
  void initState() {
    super.initState();
    if (widget.offerts.length == 1) _choisir(0);
  }

  @override
  void dispose() {
    _montant.dispose();
    super.dispose();
  }

  Montant? _proposePour(MouvementPermis m) {
    final Montant? manque = widget.manqueReserve;
    return m.montantPropose ??
        (m.destination == Coffre.reserveStrategique &&
                manque != null &&
                manque.mineur > 0
            ? manque
            : null);
  }

  void _choisir(int i) {
    _choisi = i;
    _montantInvalide = false;
    _montant.clear();
    // Montants masques : le champ reste vide, la proposition se lit masquee
    // et se reprend d'un geste. Affiches : il est prerempli (K-57).
    final Montant? propose = _proposePour(widget.offerts[i]);
    if (propose != null && ref.read(visibiliteMontantsProvider)) {
      _reprendre(propose);
    }
  }

  void _reprendre(Montant propose) {
    final int? unites = unitesEntieresDe(propose);
    if (unites != null) _montant.text = '$unites';
  }

  Montant? _lireMontant() {
    final String texte = _montant.text.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{1,12}$').hasMatch(texte)) return null;
    final int unites = int.parse(texte);
    if (unites <= 0) return null;
    return montantDepuisUnites(unites, widget.devise);
  }

  void _verifier() {
    final Montant? montant = _lireMontant();
    setState(() {
      if (montant == null) {
        _montantInvalide = true;
        return;
      }
      // Une autre saisie est un autre mouvement : nouvelle cle.
      if (montant != _aEnvoyer) _cle = const Uuid().v4();
      _aEnvoyer = montant;
      _etape = _Etape.verification;
    });
  }

  Future<void> _envoyer() async {
    final MouvementPermis? m = _mouvement;
    final Montant? montant = _aEnvoyer;
    final String? cle = _cle;
    if (m == null || montant == null || cle == null) return;
    setState(() {
      _etape = _Etape.envoi;
      _echec = null;
    });
    try {
      final ResultatMouvement r = await ref
          .read(portTresorerieProvider)
          .transferer(
            origine: m.origine,
            destination: m.destination,
            montant: montant,
            cleIdempotence: cle,
          );
      if (!mounted) return;
      setState(() {
        _resultat = r;
        _etape = _Etape.resultat;
      });
      if (r.execute || r.validation != null) widget.onMouvement?.call();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _echec = e;
        _etape = _Etape.resultat;
      });
    }
  }

  @override
  Widget build(BuildContext context) => switch (_etape) {
    _Etape.saisie => _saisie(context),
    _Etape.verification || _Etape.envoi => _verification(context),
    _Etape.resultat => _resultatVue(context),
  };

  /// L'unique action pleine de la feuille, selon le temps : « Verifier »,
  /// puis « Confirmer » ou « Demander la validation », ou « Reessayer ».
  /// Un temps n'en montre jamais deux.
  Widget _actionPleine({
    required String libelle,
    required VoidCallback onPress,
    Key? key,
    bool enCours = false,
  }) => ActionPrincipale(
    key: key,
    libelle: libelle,
    enCours: enCours,
    onPress: onPress,
  );

  Widget _fermer() => ActionPrincipale(
    libelle: t.comptable.tresorerie.transfert.fermer,
    niveau: NiveauAction.tertiaire,
    onPress: () => Navigator.of(context).maybePop(),
  );

  Widget _saisie(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final tr = t.comptable.tresorerie.transfert;
    if (widget.offerts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(tr.aucunCouple, style: textes.bodyLarge),
          for (final MouvementBloque b in widget.bloques) ...<Widget>[
            Ecart.vSm,
            Text(
              '${tr.couple(origine: libelleCoffre(b.origine), destination: libelleCoffre(b.destination))} : ${libelleRaisonBlocage(b.raison)}',
              style: attenue,
            ),
          ],
          Ecart.vXxl,
          _fermer(),
        ],
      );
    }
    final MouvementPermis? m = _mouvement;
    final Montant? propose = m == null ? null : _proposePour(m);
    final int? choisi = _choisi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(tr.choix, style: textes.titleSmall),
        Ecart.vSm,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: choisi == null
              ? null
              : ReponseChoix(valeurs: <String>{'$choisi'}),
          options: <OptionChoix>[
            for (int i = 0; i < widget.offerts.length; i++)
              OptionChoix(
                cle: TransfertInterne.cleCouple(
                  widget.offerts[i].origine,
                  widget.offerts[i].destination,
                ),
                valeur: '$i',
                libelle: tr.couple(
                  origine: libelleCoffre(widget.offerts[i].origine),
                  destination: libelleCoffre(widget.offerts[i].destination),
                ),
                description: estSensible(widget.offerts[i])
                    ? tr.sensible
                    : tr.delegable,
              ),
            for (final MouvementBloque b in widget.bloques)
              OptionChoix(
                cle: TransfertInterne.cleCouple(b.origine, b.destination),
                valeur: 'bloque-${b.origine.name}-${b.destination.name}',
                libelle: tr.couple(
                  origine: libelleCoffre(b.origine),
                  destination: libelleCoffre(b.destination),
                ),
                disponible: false,
                raisonIndisponible: libelleRaisonBlocage(b.raison),
              ),
          ],
          onChange: (ReponseChoix r) {
            final int? i = int.tryParse(r.valeurs.firstOrNull ?? '');
            if (i == null) return;
            setState(() => _choisir(i));
          },
        ),
        if (m != null) ...<Widget>[
          Ecart.vXl,
          Text(tr.montant, style: textes.titleSmall),
          Ecart.vXs,
          Text(tr.montantAide(devise: widget.devise), style: attenue),
          Ecart.vSm,
          Semantics(
            label: tr.montant,
            child: TextField(
              key: TransfertInterne.cleMontant,
              controller: _montant,
              keyboardType: TextInputType.number,
              style: AppTypography.tabulaire(
                textes.bodyLarge ?? const TextStyle(),
              ),
              onChanged: (String _) {
                if (_montantInvalide) setState(() => _montantInvalide = false);
              },
              decoration: InputDecoration(
                suffixText: symboleDe(widget.devise),
                errorText: _montantInvalide ? tr.erreurMontant : null,
                errorMaxLines: 4,
              ),
            ),
          ),
          if (propose != null) ...<Widget>[
            Ecart.vMd,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(tr.montantPropose, style: attenue),
                MontantSensible(propose, attenue: true),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActionPrincipale(
                libelle: tr.utiliserPropose,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
                onPress: () => setState(() {
                  _montantInvalide = false;
                  _reprendre(propose);
                }),
              ),
            ),
          ],
        ],
        Ecart.vLg,
        Text(t.comptable.tresorerie.interdits, style: attenue),
        Ecart.vXxl,
        if (m != null)
          _actionPleine(
            key: TransfertInterne.cleVerifier,
            libelle: tr.verifier,
            onPress: _verifier,
          ),
        _fermer(),
      ],
    );
  }

  Widget _verification(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle cle = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final TextStyle valeur = palette.inkStrong.applyTo(
      textes.bodyLarge ?? const TextStyle(),
    );
    final tr = t.comptable.tresorerie.transfert;
    final MouvementPermis m = _mouvement!;
    final bool sensible = estSensible(m);
    final bool envoi = _etape == _Etape.envoi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(tr.recapPhrase, style: textes.bodyLarge),
        Ecart.vLg,
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(tr.de, style: cle),
              Text(libelleCoffre(m.origine), style: valeur),
            ],
          ),
        ),
        Ecart.vMd,
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(tr.vers, style: cle),
              Text(libelleCoffre(m.destination), style: valeur),
            ],
          ),
        ),
        Ecart.vMd,
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(tr.montant, style: cle),
              // Le montant exact avant d'envoyer, meme montants masques :
              // on ne confirme pas un mouvement d'argent a l'aveugle (meme
              // regle que la confirmation de payout, §7.5, R-FIN-04).
              MontantArgent(_aEnvoyer!, taille: TailleMontant.titre),
            ],
          ),
        ),
        Ecart.vLg,
        Text(
          sensible ? tr.sensible : tr.delegable,
          style: palette.inkStrong.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXxl,
        _actionPleine(
          key: TransfertInterne.cleEnvoyer,
          libelle: sensible ? tr.demanderValidation : tr.confirmer,
          enCours: envoi,
          onPress: _envoyer,
        ),
        if (!envoi) ...<Widget>[
          Ecart.vSm,
          ActionPrincipale(
            libelle: tr.modifier,
            niveau: NiveauAction.secondaire,
            onPress: () => setState(() => _etape = _Etape.saisie),
          ),
        ],
      ],
    );
  }

  Widget _resultatVue(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle titre = palette.inkStrong.applyTo(
      textes.titleMedium ?? const TextStyle(),
    );
    final TextStyle corps = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final tr = t.comptable.tresorerie.transfert;
    final Object? echec = _echec;
    final ResultatMouvement? r = _resultat;
    final List<Widget> contenu;
    Widget? reessayer;
    if (echec is CapaciteIndisponible) {
      contenu = <Widget>[Text(tr.indisponible, style: textes.bodyLarge)];
    } else if (echec != null || r == null) {
      contenu = <Widget>[
        Semantics(
          liveRegion: true,
          child: Text(tr.erreurEnvoiTitre, style: titre),
        ),
        Ecart.vXs,
        Text(tr.erreurEnvoi, style: corps),
      ];
      // Meme cle : si la premiere tentative est arrivee, la source ne la
      // compte pas deux fois.
      reessayer = _actionPleine(libelle: t.commun.reessayer, onPress: _envoyer);
    } else if (r.validation case final EtatDemandeValidation v) {
      contenu = <Widget>[
        Semantics(
          liveRegion: true,
          child: Text(tr.validationTitre, style: titre),
        ),
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PastilleDemandeValidation(v),
        ),
        Ecart.vSm,
        Text(tr.validationPhrase, style: corps),
      ];
    } else if (r.execute) {
      final String reference = r.journal?.reference ?? r.mouvementId;
      contenu = <Widget>[
        Semantics(liveRegion: true, child: Text(tr.executeTitre, style: titre)),
        Ecart.vXs,
        Text(tr.executePhrase, style: corps),
        Ecart.vXs,
        Text(tr.reference(reference: reference), style: corps),
      ];
    } else {
      contenu = <Widget>[
        Semantics(liveRegion: true, child: Text(tr.refusTitre, style: titre)),
        Ecart.vXs,
        Text(
          tr.refusPhrase(
            raison: libelleRaisonBlocage(
              r.refus ?? RaisonBlocage.capaciteAbsente,
            ),
          ),
          style: corps,
        ),
      ];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[...contenu, Ecart.vXxl, ?reessayer, _fermer()],
    );
  }
}

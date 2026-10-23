import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/indicatifs_telephoniques.dart';
import '../../../core/i18n/pays_iso.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/carte_lignes.dart';
import '../../../core/widgets/champ_etiquete.dart' show TitreChamp;
import '../../../core/widgets/setting_row.dart';
import '../../candidature/choix_avec_recherche.dart';
import '../../candidature/question_etape.dart' show paysCourants;
import '../brouillon_inscription.dart';
import '../inscription_page.dart';

/// `/inscription/telephone` (CAND-04) : le telephone du candidat enseignant.
///
/// Deux reponses, la plus facile d'abord. **L'indicatif se choisit** dans la
/// liste des pays (cartes des pays courants, puis une recherche par nom en
/// francais ou en arabe, ou par l'indicatif lui-meme) ; **le numero se saisit**
/// sans l'indicatif, parce qu'un numero ne se choisit pas. Une fois le pays
/// retenu, la liste se replie en une ligne qui se touche pour le changer, et
/// le numero prend la place.
///
/// Le numero partira avec l'indicatif, au format que le serveur lit (`+`, puis
/// l'indicatif et le numero) : le « 0 » national est retire (`telephoneInternational`),
/// jamais deviné d'ailleurs. Aucune erreur ne s'affiche avant la premiere
/// tentative de continuer ; aucun signe n'indique qu'un numero est deja connu.
class TelephoneEtape extends ConsumerStatefulWidget {
  /// Cree l'etape.
  const TelephoneEtape({super.key});

  /// La cle du champ du numero (tests).
  static const Key numeroKey = ValueKey<String>('inscription-telephone-numero');

  /// La cle de la ligne qui rappelle le pays choisi (tests).
  static const Key paysChoisiKey = ValueKey<String>(
    'inscription-telephone-pays',
  );

  /// La cle de la carte (ou de la ligne de recherche) d'un pays.
  static Key paysKey(String code) =>
      ValueKey<String>('inscription-telephone-pays-$code');

  @override
  ConsumerState<TelephoneEtape> createState() => _TelephoneEtapeState();
}

class _TelephoneEtapeState extends ConsumerState<TelephoneEtape> {
  static const String _route = Routes.inscriptionTelephone;

  late final TextEditingController _numero;
  final FocusNode _focusNumero = FocusNode();

  /// Le pays retenu (code ISO), ou `null`.
  String? _pays;

  /// Vrai quand la personne revient changer de pays.
  bool _enChangement = false;

  /// Les erreurs ne s'affichent qu'apres une premiere tentative.
  bool _tente = false;

  /// La phrase « Choisissez l'indicatif », que la page ramene a l'ecran : la
  /// liste des pays est longue, la phrase ne doit pas rester sous le pli.
  final GlobalKey _cleErreurPays = GlobalKey();

  @override
  void initState() {
    super.initState();
    final BrouillonInscription brouillon = ref.read(
      brouillonInscriptionProvider,
    );
    _pays = brouillon.paysTelephone;
    _numero = TextEditingController(text: brouillon.numeroTelephone);
  }

  @override
  void dispose() {
    _numero.dispose();
    _focusNumero.dispose();
    super.dispose();
  }

  String? get _indicatif => indicatifDuPays(_pays);

  /// Le numero international, ou `null` quand il ne se lit pas.
  String? get _international {
    final String? code = _indicatif;
    return code == null
        ? null
        : telephoneInternational(indicatif: code, saisie: _numero.text);
  }

  void _choisirPays(Set<String> codes) {
    if (codes.isEmpty) {
      return;
    }
    setState(() {
      _pays = codes.first;
      _enChangement = false;
    });
    // Le pays choisi, la suite naturelle est le numero.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        _focusNumero.requestFocus();
      }
    });
  }

  void _continuer() {
    final String? pays = _pays;
    if (pays == null || _international == null) {
      setState(() => _tente = true);
      if (pays == null) {
        WidgetsBinding.instance.addPostFrameCallback((Duration _) {
          final BuildContext? cible = _cleErreurPays.currentContext;
          if (mounted && cible != null && cible.mounted) {
            Scrollable.ensureVisible(cible);
          }
        });
      }
      return;
    }
    ref
        .read(brouillonInscriptionProvider.notifier)
        .saisirTelephone(pays: pays, numero: _numero.text);
    avancerDepuis(
      context,
      _route,
      usage: ref.read(brouillonInscriptionProvider).usage,
    );
  }

  String? get _erreurNumero {
    if (!_tente || _pays == null) {
      return null;
    }
    if (_numero.text.trim().isEmpty) {
      return t.inscription.telephone.numeroManquant;
    }
    return _international == null
        ? t.inscription.telephone.numeroInvalide
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final BrouillonInscription brouillon = ref.watch(
      brouillonInscriptionProvider,
    );
    exigerEtapesPrecedentes(context, brouillon, _route);
    final r = t.inscription.telephone;
    final bool paysRetenu = _pays != null && !_enChangement;

    return CoquilleEtape(
      route: _route,
      question: r.question,
      explication: r.explication,
      libelleAction: t.commun.continuer,
      onAction: _continuer,
      onRetour: () => reculerDepuis(context, _route, usage: brouillon.usage),
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TitreChamp(
            r.indicatif,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_tente && _pays == null) ...<Widget>[
            Ecart.vSm,
            KeyedSubtree(
              key: _cleErreurPays,
              child: _ErreurChamp(message: r.indicatifManquant),
            ),
          ],
          Ecart.vMd,
          if (paysRetenu)
            _PaysChoisi(
              code: _pays!,
              onChanger: () => setState(() => _enChangement = true),
            )
          else
            _ListeDesPays(choisi: _pays, onChange: _choisirPays),
          if (paysRetenu) ...<Widget>[
            Ecart.vXl,
            _ChampNumero(
              controleur: _numero,
              focus: _focusNumero,
              indicatif: _indicatif!,
              erreur: _erreurNumero,
              onChanged: () => setState(() {}),
              onValider: _continuer,
            ),
          ],
        ],
      ),
    );
  }
}

/// Les pays courants en cartes, puis la recherche. Les noms se cherchent en
/// francais comme en arabe, et par l'indicatif.
class _ListeDesPays extends StatelessWidget {
  const _ListeDesPays({required this.choisi, required this.onChange});

  final String? choisi;
  final ValueChanged<Set<String>> onChange;

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.parcours.pays;
    final List<ElementChoix> tous =
        <ElementChoix>[
          for (final PaysIso p in paysAvecIndicatif)
            ElementChoix(
              code: p.code,
              libelle: p.nom,
              description: indicatifAffiche(indicatifDuPays(p.code)!),
              cle: TelephoneEtape.paysKey(p.code),
              motsCles:
                  '${p.fr} ${p.ar} +${indicatifDuPays(p.code)} '
                  '${indicatifDuPays(p.code)}',
            ),
        ]..sort(
          (ElementChoix a, ElementChoix b) =>
              formeDeRecherche(a.libelle)
                  .compareTo(formeDeRecherche(b.libelle)),
        );
    final Map<String, ElementChoix> parCode = <String, ElementChoix>{
      for (final ElementChoix e in tous) e.code: e,
    };
    return ChoixAvecRecherche(
      cle: 'telephone-indicatif',
      courants: <ElementChoix>[
        for (final String c in paysCourants)
          if (parCode[c] case final ElementChoix e) e,
      ],
      tous: tous,
      selection: <String>{?choisi},
      textes: TextesRecherche(
        autre: r.autre,
        recherche: r.recherche,
        aide: r.rechercheAide,
        aucun: r.aucun,
        retour: r.retour,
      ),
      onChange: onChange,
    );
  }
}

/// Le pays retenu, en une ligne qui se touche pour le changer.
class _PaysChoisi extends StatelessWidget {
  const _PaysChoisi({required this.code, required this.onChanger});

  final String code;
  final VoidCallback onChanger;

  @override
  Widget build(BuildContext context) => CarteLignes(
    lignes: <Widget>[
      SettingRow(
        key: TelephoneEtape.paysChoisiKey,
        title: nomDuPays(code),
        description: t.inscription.telephone.changerIndicatif,
        value: indicatifAffiche(indicatifDuPays(code) ?? ''),
        onPress: onChanger,
      ),
    ],
  );
}

/// Le numero, sans l'indicatif, avec l'indicatif en tete du champ.
class _ChampNumero extends StatelessWidget {
  const _ChampNumero({
    required this.controleur,
    required this.focus,
    required this.indicatif,
    required this.erreur,
    required this.onChanged,
    required this.onValider,
  });

  final TextEditingController controleur;
  final FocusNode focus;
  final String indicatif;
  final String? erreur;
  final VoidCallback onChanged;
  final VoidCallback onValider;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExcludeSemantics(
          child: TitreChamp(
            t.inscription.telephone.numero,
            style: textes.titleMedium,
          ),
        ),
        Ecart.vSm,
        // Un numero s'ecrit de gauche a droite, meme dans une page en arabe :
        // le champ entier (indicatif en tete, chiffres, curseur) est pose de
        // gauche a droite, et le titre et la phrase d'erreur gardent le sens de
        // la page. Les groupes de chiffres separes par des espaces ne se
        // lisent jamais a l'envers.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            label: t.inscription.telephone.numero,
            textField: true,
            child: TextField(
              key: TelephoneEtape.numeroKey,
              controller: controleur,
              focusNode: focus,
              onChanged: (String _) => onChanged(),
              onSubmitted: (String _) => onValider(),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[
                AutofillHints.telephoneNumberNational,
              ],
              decoration: InputDecoration(
                prefixText: '${indicatifAffiche(indicatif)}  ',
                // Le champ prend le style d'erreur ; la phrase est posee
                // dessous, dans le sens de la page.
                error: erreur == null ? null : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        if (erreur != null) ...<Widget>[
          Ecart.vSm,
          _ErreurChamp(message: erreur!),
        ],
      ],
    );
  }
}

/// Une erreur sous un champ : une phrase, annoncee, qui dit quoi faire.
class _ErreurChamp extends StatelessWidget {
  const _ErreurChamp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: AppPalette.of(context).inkAlert
          .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
    ),
  );
}

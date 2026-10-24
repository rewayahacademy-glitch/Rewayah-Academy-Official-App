import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/indicatifs_telephoniques.dart';
import '../../../core/i18n/pays_iso.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/pays_enseignant.dart'
    show cheminDrapeau, rapportDrapeau;
import '../../../core/widgets/pressable.dart';
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

  /// La cle du champ de recherche des pays (tests).
  static const Key rechercheKey = ValueKey<String>(
    'inscription-telephone-recherche',
  );

  /// La cle de la ligne d'un pays dans la liste.
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
          // Un seul champ, demande du directeur (23/10) : le drapeau du pays
          // a gauche ouvre la liste des pays (avec une recherche), le numero
          // se saisit a droite. Un numero s'ecrit de gauche a droite, meme en
          // arabe.
          Directionality(
            textDirection: TextDirection.ltr,
            child: _ChampNumero(
              controleur: _numero,
              focus: _focusNumero,
              pays: _pays,
              indicatif: _indicatif,
              erreur: _erreurNumero,
              onChanged: () => setState(() {}),
              onValider: _continuer,
              onChoisirPays: () async {
                final String? code = await choisirPays(context, _pays);
                if (code != null) {
                  _choisirPays(<String>{code});
                }
              },
            ),
          ),
          if (_tente && _pays == null) ...<Widget>[
            Ecart.vSm,
            KeyedSubtree(
              key: _cleErreurPays,
              child: _ErreurChamp(message: r.indicatifManquant),
            ),
          ],
          if (_erreurNumero case final String erreur) ...<Widget>[
            Ecart.vSm,
            _ErreurChamp(message: erreur),
          ],
        ],
      ),
    );
  }
}

/// Ouvre la liste des pays, avec une recherche en tete ; rend le code choisi.
Future<String?> choisirPays(BuildContext context, String? choisi) =>
    AppBottomSheet.ouvrir<String>(
      context,
      titre: t.inscription.telephone.choisirPays,
      constructeur: (BuildContext contexte) => _ListePays(choisi: choisi),
    );

/// La recherche (nom en francais ou en arabe, ou indicatif) puis les pays :
/// drapeau, nom, indicatif, et une coche sur le pays choisi.
class _ListePays extends StatefulWidget {
  const _ListePays({required this.choisi});

  final String? choisi;

  @override
  State<_ListePays> createState() => _ListePaysState();
}

class _ListePaysState extends State<_ListePays> {
  String _saisie = '';

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String cle = formeDeRecherche(_saisie.replaceAll('+', ''));
    final List<PaysIso> pays =
        <PaysIso>[
          for (final PaysIso p in paysAvecIndicatif)
            if (cle.isEmpty ||
                formeDeRecherche(p.fr).startsWith(cle) ||
                formeDeRecherche(p.ar).startsWith(cle) ||
                formeDeRecherche(p.nom).contains(' $cle') ||
                (indicatifDuPays(p.code) ?? '').startsWith(cle))
              p,
        ]..sort((PaysIso a, PaysIso b) {
          // Ce qui commence par la saisie d'abord (« ma » : Mali, Maroc).
          final int debutA = formeDeRecherche(a.nom).startsWith(cle) ? 0 : 1;
          final int debutB = formeDeRecherche(b.nom).startsWith(cle) ? 0 : 1;
          return debutA != debutB
              ? debutA - debutB
              : formeDeRecherche(a.nom).compareTo(formeDeRecherche(b.nom));
        });
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          key: TelephoneEtape.rechercheKey,
          autofocus: true,
          onChanged: (String v) => setState(() => _saisie = v),
          decoration: InputDecoration(
            prefixIcon: Icon(AppIcons.recherche.repos),
            hintText: t.inscription.telephone.rechercherPays,
          ),
        ),
        Ecart.vSm,
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              for (final PaysIso p in pays)
                Pressable(
                  key: TelephoneEtape.paysKey(p.code),
                  selectionne: p.code == widget.choisi,
                  libelleSemantique: '${p.nom}, +${indicatifDuPays(p.code)}',
                  onPress: () => Navigator.of(context).pop(p.code),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: <Widget>[
                        Drapeau(code: p.code),
                        Ecart.hMd,
                        Expanded(
                          child: Text(
                            '${p.nom} (${indicatifAffiche(indicatifDuPays(p.code)!)})',
                            style: p.code == widget.choisi
                                ? textes.titleSmall
                                : textes.bodyLarge,
                          ),
                        ),
                        if (p.code == widget.choisi)
                          IconTheme(
                            data: palette.inkAccent.asIconTheme(),
                            child: Icon(AppIcons.succes.repos),
                          ),
                      ],
                    ),
                  ),
                ),
              if (pays.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    t.recrutement.parcours.pays.aucun,
                    style: palette.inkMuted.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Un seul champ : le drapeau du pays et sa fleche a gauche (toucher ouvre la
/// liste des pays), puis le numero, l'indicatif en tete.
class _ChampNumero extends StatelessWidget {
  const _ChampNumero({
    required this.controleur,
    required this.focus,
    required this.pays,
    required this.indicatif,
    required this.erreur,
    required this.onChanged,
    required this.onValider,
    required this.onChoisirPays,
  });

  final TextEditingController controleur;
  final FocusNode focus;
  final String? pays;
  final String? indicatif;
  final String? erreur;
  final VoidCallback onChanged;
  final VoidCallback onValider;
  final VoidCallback onChoisirPays;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String? code = pays;
    return TextField(
      key: TelephoneEtape.numeroKey,
      controller: controleur,
      focusNode: focus,
      onChanged: (String _) => onChanged(),
      onSubmitted: (String _) => onValider(),
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      autofillHints: const <String>[AutofillHints.telephoneNumberNational],
      decoration: InputDecoration(
        hintText: t.inscription.telephone.numeroCourt,
        prefixText: indicatif == null
            ? null
            : '${indicatifAffiche(indicatif!)} ',
        error: erreur == null ? null : const SizedBox.shrink(),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
          // Le filet qui separe le pays du numero est pose autour du
          // Pressable, jamais peint par lui (bouton-recompose), du cote de
          // fin pour suivre l'arabe.
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: BorderDirectional(
                end: palette.borderResting.asBorderSide(),
              ),
            ),
            child: Pressable(
              key: TelephoneEtape.paysChoisiKey,
              libelleSemantique: code == null
                  ? t.inscription.telephone.choisirPays
                  : '${t.inscription.telephone.pays} : ${nomDuPays(code)}',
              onPress: onChoisirPays,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (code != null)
                      Drapeau(code: code)
                    else
                      Text(
                        t.inscription.telephone.pays,
                        style: palette.surfaceSunken.applyTo(
                          Theme.of(context).textTheme.bodyLarge ??
                              const TextStyle(),
                        ),
                      ),
                    Ecart.hXs,
                    IconTheme(
                      data: palette.inkMuted.asIconTheme(),
                      child: Icon(AppIcons.menuDeroulant.repos),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le drapeau d'un pays, image embarquee 4:3 (flag-icons, MIT), decoratif.
class Drapeau extends StatelessWidget {
  /// Cree le drapeau du pays [code] (ISO, deux lettres).
  const Drapeau({required this.code, super.key});

  /// Le code ISO du pays.
  final String code;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.xs / 2),
    child: Image.asset(
      cheminDrapeau(code),
      width: AppSpacing.lg * rapportDrapeau,
      height: AppSpacing.lg,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) =>
          const SizedBox(width: AppSpacing.lg * rapportDrapeau),
    ),
  );
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

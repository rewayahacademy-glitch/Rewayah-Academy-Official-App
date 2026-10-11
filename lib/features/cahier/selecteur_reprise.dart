import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/signaler_manque.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/recherche_catalogue.dart';
import '../../core/tc_coran/moteur_mushaf.dart' show souratesCoranProvider;
import '../../core/tc_coran/port_corpus_coran.dart' show SourateVM;
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/zone_saisie.dart';

/// Une position de reprise choisie : une sourate et un verset.
@immutable
class PositionReprise {
  /// Cree une position.
  const PositionReprise({required this.sourate, required this.verset});

  /// Le rang de la sourate, de 1 a 114.
  final int sourate;

  /// Le numero du verset.
  final int verset;

  /// Ce que le cahier enregistre : **la meme phrase qu'avant** (« Sourate 18,
  /// verset 10 »), celle que la proposition du brouillon ecrivait deja. Le
  /// contrat `positionReprise` (texte) ne change pas.
  String get texte => t.enseignant.cahier.repriseProposee(
    sourate: '$sourate',
    verset: '$verset',
  );

  @override
  bool operator ==(Object other) =>
      other is PositionReprise &&
      other.sourate == sourate &&
      other.verset == verset;

  @override
  int get hashCode => Object.hash(sourate, verset);
}

/// Le champ « Ou la Classe s'est arretee » : une sourate et un verset
/// **choisis**, jamais tapes (K-57, FORM-L9).
///
/// Meme forme que `ChampDate` : un champ qui ouvre un choix. La liste des
/// sourates vient du corpus deja lu par le lecteur du Coran
/// (`souratesCoranProvider`, au-dessus de `portCorpusCoranProvider`, la source
/// de la feuille « Aller a » de `navigation_coran_feuille.dart`) ; ni le rendu
/// ni les fichiers du Coran ne sont touches.
class ChampReprise extends StatelessWidget {
  /// Cree le champ.
  const ChampReprise({
    required this.valeur,
    required this.onChoix,
    super.key,
    this.erreur,
  });

  /// La position retenue, ou `null` tant que rien n'est choisi.
  final PositionReprise? valeur;

  /// Appele avec la position choisie dans la feuille.
  final ValueChanged<PositionReprise> onChoix;

  /// Le message calme quand la reprise manque.
  final String? erreur;

  /// Cle du champ.
  static const Key champKey = ValueKey<String>('cahier-reprise');

  Future<void> _ouvrir(BuildContext context) async {
    // La feuille vit dans la route du navigateur : elle recoit le conteneur
    // de l'ecran, pour lire le meme corpus (et ses surcharges).
    final ProviderContainer conteneur = ProviderScope.containerOf(context);
    final PositionReprise? choisie =
        await AppBottomSheet.ouvrir<PositionReprise>(
          context,
          titre: t.enseignant.cahier.reprise,
          constructeur: (BuildContext _) => UncontrolledProviderScope(
            container: conteneur,
            child: FeuilleReprise(initiale: valeur),
          ),
        );
    if (choisie != null) {
      onChoix(choisie);
    }
  }

  @override
  Widget build(BuildContext context) {
    final PositionReprise? position = valeur;
    // `Pressable` et non un `InkWell` nu : focus, survol, cible tactile et
    // semantique de bouton viennent du composant commun.
    return Pressable(
      key: champKey,
      libelleSemantique: t.enseignant.cahier.reprise,
      onPress: () => _ouvrir(context),
      child: InputDecorator(
        decoration: InputDecoration(
          helperText: t.enseignant.cahier.repriseDetail,
          helperMaxLines: ZoneSaisie.lignesAideMax,
          errorText: erreur,
          errorMaxLines: 3,
          suffixIcon: Icon(AppIcons.chevron.repos),
        ),
        child: Text(
          position == null
              ? t.enseignant.cahier.repriseChoisir
              : position.texte,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

/// La feuille : la sourate dans une liste cherchable, puis le verset en
/// puces.
class FeuilleReprise extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleReprise({required this.initiale, super.key, this.maximum = 6});

  /// La position deja retenue (ou proposee par le brouillon).
  final PositionReprise? initiale;

  /// Le nombre de sourates affichees au plus, la retenue comprise.
  final int maximum;

  /// Cle de l'action « Retenir cette position ».
  static const Key retenirKey = ValueKey<String>('reprise-retenir');

  /// Cle de la carte d'une sourate.
  static Key sourateKey(int numero) => ValueKey<String>('reprise-s$numero');

  /// Cle de la puce d'un verset.
  static Key versetKey(int numero) => ValueKey<String>('reprise-v$numero');

  /// Cle du champ de recherche d'une sourate.
  static const Key rechercheKey = ValueKey<String>('reprise-recherche');

  /// Cle de la saisie du numero de verset.
  static const Key versetSaisieKey = ValueKey<String>('reprise-verset-saisie');

  @override
  ConsumerState<FeuilleReprise> createState() => _FeuilleRepriseEtat();
}

class _FeuilleRepriseEtat extends ConsumerState<FeuilleReprise> {
  final TextEditingController _recherche = TextEditingController();
  late int? _sourate = widget.initiale?.sourate;
  late int? _verset = widget.initiale?.verset;
  // Le champ « Verset » montre toujours le verset retenu, y compris celui de
  // la reprise initiale.
  late final TextEditingController _numero = TextEditingController(
    text: widget.initiale == null ? '' : '${widget.initiale!.verset}',
  );
  bool _incomplete = false;

  /// Vrai quand la saisie du verset est vide ou hors bornes : aucun verset
  /// n'est retenu, la feuille ne peut pas se refermer sur une autre valeur.
  bool _saisieInvalide = false;

  /// Les champs ou le focus revient quand le verset manque
  /// (BOUTONS-GRISES-1) : la recherche de sourate, puis le verset.
  final FocusNode _focusRecherche = FocusNode(debugLabel: 'reprise-sourate');
  final FocusNode _focusVerset = FocusNode(debugLabel: 'reprise-verset');

  @override
  void dispose() {
    _recherche.dispose();
    _numero.dispose();
    _focusRecherche.dispose();
    _focusVerset.dispose();
    super.dispose();
  }

  /// Les sourates qui repondent a la recherche, par nom ou par numero.
  List<SourateVM> _correspondantes(List<SourateVM> toutes) {
    final String cle = RechercheCatalogue.normaliser(_recherche.text.trim());
    if (cle.isEmpty) return toutes;
    final int? numero = int.tryParse(cle);
    return toutes
        .where(
          (SourateVM s) =>
              s.numero == numero ||
              RechercheCatalogue.normaliser(s.nomTranslittere).contains(cle),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final s = t.enseignant.cahier;
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(s.repriseConsigne, style: textes.bodyMedium),
        Ecart.vLg,
        BlocAsynchrone<List<SourateVM>>(
          valeur: ref.watch(souratesCoranProvider),
          squelette: const Skeleton.liste(lignes: 4),
          onReessayer: () => ref.invalidate(souratesCoranProvider),
          erreurVersEtat: (Object _, VoidCallback? reessayer) => EtatSysteme(
            nature: NatureEtat.echecServeur,
            titre: s.repriseSansListe,
            phrase: s.repriseSansListeFeuille,
            onAction: reessayer,
          ),
          vide: EtatSysteme(
            nature: NatureEtat.aucunResultat,
            titre: s.repriseSansListe,
            phrase: s.repriseSansListeFeuille,
          ),
          construire: _contenu,
        ),
      ],
    );
  }

  Widget _contenu(List<SourateVM> toutes) {
    final s = t.enseignant.cahier;
    final TextTheme textes = Theme.of(context).textTheme;
    final List<SourateVM> trouvees = _correspondantes(toutes);
    final SourateVM? retenue = toutes
        .where((SourateVM v) => v.numero == _sourate)
        .firstOrNull;
    final List<SourateVM> affichees = <SourateVM>[
      ?retenue,
      ...trouvees
          .where((SourateVM v) => v.numero != retenue?.numero)
          .take(widget.maximum - (retenue == null ? 0 : 1)),
    ];
    final int restantes =
        trouvees.length - affichees.where(trouvees.contains).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextField(
          key: FeuilleReprise.rechercheKey,
          controller: _recherche,
          focusNode: _focusRecherche,
          onChanged: (String _) => setState(() {}),
          decoration: InputDecoration(
            // L'indice n'existe que tant que le champ est vide : un indice
            // pose dans l'arbre (meme invisible) impose sa hauteur de quatre
            // lignes au champ, texte saisi compris. Il peut grandir (rien
            // n'est coupe en « ... »), mais une saisie le ramene a une ligne.
            hintText: _recherche.text.isEmpty ? s.repriseRecherche : null,
            hintMaxLines: 4,
            prefixIcon: Icon(AppIcons.recherche.repos),
          ),
        ),
        Ecart.vMd,
        if (trouvees.isEmpty) ...<Widget>[
          EtatSysteme(
            nature: NatureEtat.aucunResultat,
            titre: s.repriseAucune,
            phrase: s.repriseAucuneDetail,
            libelleAction: t.commun.selecteurPersonne.effacerRecherche,
            onAction: () => setState(_recherche.clear),
          ),
          Ecart.vLg,
        ],
        // La cle suit la liste affichee : la selection vit ici, pas dans le
        // groupe, et une recherche nouvelle reconstruit des cartes justes.
        ChoiceCardGroup(
          key: ValueKey<String>(
            affichees.map((SourateVM v) => v.numero).join(','),
          ),
          autoriserSaisieLibre: false,
          valeurInitiale: _sourate == null
              ? null
              : ReponseChoix(valeurs: <String>{'$_sourate'}),
          options: <OptionChoix>[
            for (final SourateVM v in affichees)
              OptionChoix(
                cle: FeuilleReprise.sourateKey(v.numero),
                valeur: '${v.numero}',
                libelle: s.repriseSourate(
                  numero: '${v.numero}',
                  nom: v.nomTranslittere,
                ),
                description: s.repriseVersets(n: v.nombreVersets),
              ),
          ],
          onChange: (ReponseChoix r) => setState(() {
            final int? choisie = int.tryParse(r.valeurs.firstOrNull ?? '');
            if (choisie != _sourate) {
              _sourate = choisie;
              _verset = null;
              _saisieInvalide = false;
              _numero.clear();
            }
          }),
        ),
        if (restantes > 0) ...<Widget>[
          Text(s.repriseRestantes(n: restantes), style: textes.bodySmall),
          Ecart.vLg,
        ],
        if (retenue != null) ...<Widget>[
          // Le numero se tape aussi : 286 puces pour Al-Baqara, c'est long a
          // parcourir, surtout en texte agrandi. Meme mot « Verset », aucune
          // phrase nouvelle.
          TextField(
            key: FeuilleReprise.versetSaisieKey,
            controller: _numero,
            focusNode: _focusVerset,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (String v) {
              final int? n = int.tryParse(v);
              setState(() {
                final bool valide =
                    n != null && n >= 1 && n <= retenue.nombreVersets;
                _verset = valide ? n : null;
                _saisieInvalide = !valide;
                if (valide) _incomplete = false;
              });
            },
            decoration: InputDecoration(
              labelText: s.repriseVerset,
              errorText: _saisieInvalide
                  ? s.repriseVersetBornes(n: retenue.nombreVersets)
                  : null,
            ),
          ),
          Ecart.vMd,
          // Choix de formulaire, pas un filtre : le verset de reprise.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (int n = 1; n <= retenue.nombreVersets; n++)
                FilterPill(
                  key: FeuilleReprise.versetKey(n),
                  libelle: '$n',
                  retenue: n == _verset,
                  onPress: () => setState(() {
                    _verset = n;
                    _numero.text = '$n';
                    _saisieInvalide = false;
                    _incomplete = false;
                  }),
                ),
            ],
          ),
          Ecart.vXl,
        ],
        if (_incomplete) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              s.repriseIncomplete,
              style: AppPalette.of(context).inkAlert
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
          ),
          Ecart.vMd,
        ],
        // Jamais grise (regle du cahier) : sans verset, une phrase calme.
        ActionPrincipale(
          key: FeuilleReprise.retenirKey,
          libelle: s.repriseRetenir,
          // Jamais inerte (BOUTONS-GRISES-1) : une saisie hors bornes ou un
          // verset manquant se disent, s'annoncent et rendent le focus au
          // champ fautif.
          onPress: () {
            final int? verset = _verset;
            if (retenue != null && _saisieInvalide) {
              signalerManque(
                context,
                s.repriseVersetBornes(n: retenue.nombreVersets),
                champ: _focusVerset,
              );
              return;
            }
            if (retenue == null || verset == null) {
              setState(() => _incomplete = true);
              signalerManque(
                context,
                s.repriseIncomplete,
                champ: retenue == null ? _focusRecherche : _focusVerset,
              );
              return;
            }
            Navigator.of(context)
                .pop(PositionReprise(sourate: retenue.numero, verset: verset));
          },
        ),
      ],
    );
  }
}

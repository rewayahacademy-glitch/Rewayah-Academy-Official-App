import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/offres/service_offres.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/skeleton.dart';

/// Un pays propose a l'enseignant, et les fuseaux ou il se trouve.
///
/// **Liste reprise, pas inventee (K-57, FORM-L8).** Ce sont exactement les pays
/// que le produit nomme deja dans `fuseauxProposes`
/// (`parcours_offres/libelles_parcours.dart`) : la question « ou etes-vous »
/// des familles et celle-ci se repondent donc avec les memes lieux. Un test
/// verifie que chaque nom figure dans le libelle de son fuseau.
///
/// [nom] est ce qui s'enregistre : `teacher_profiles.country` est du texte
/// libre, et le profil y portait deja un nom en clair (« France »). Le contrat
/// `maj_profil_enseignant(p_country)` ne change donc pas. Passer a des codes
/// ISO serait une decision serveur (BR-1), pas un choix d'ecran.
@immutable
class PaysPropose {
  /// Cree un pays propose.
  const PaysPropose(this.nom, this.fuseaux);

  /// Le nom affiche et enregistre.
  final String nom;

  /// Les identifiants IANA de `fuseauxProposes` qui le couvrent.
  final Set<String> fuseaux;
}

/// Les pays proposes, dans l'ordre stable de `fuseauxProposes`.
const List<PaysPropose> paysProposes = <PaysPropose>[
  PaysPropose('France', <String>{'Europe/Paris'}),
  PaysPropose('Belgique', <String>{'Europe/Paris'}),
  PaysPropose('Espagne', <String>{'Europe/Paris'}),
  PaysPropose('Royaume-Uni', <String>{'Europe/London'}),
  PaysPropose('Irlande', <String>{'Europe/London'}),
  PaysPropose('Guinée', <String>{'Africa/Conakry'}),
  PaysPropose('Sénégal', <String>{'Africa/Conakry'}),
  PaysPropose('Mali', <String>{'Africa/Conakry'}),
  PaysPropose('Mauritanie', <String>{'Africa/Conakry'}),
  PaysPropose('Maroc', <String>{'Africa/Casablanca'}),
  PaysPropose("Côte d'Ivoire", <String>{'Africa/Abidjan'}),
  PaysPropose('Burkina Faso', <String>{'Africa/Abidjan'}),
  PaysPropose('Togo', <String>{'Africa/Abidjan'}),
  PaysPropose('Nigéria', <String>{'Africa/Lagos'}),
  PaysPropose('Niger', <String>{'Africa/Lagos'}),
  PaysPropose('Tchad', <String>{'Africa/Lagos'}),
  PaysPropose('Cameroun', <String>{'Africa/Lagos'}),
  PaysPropose('Canada', <String>{'America/Toronto', 'America/Los_Angeles'}),
  PaysPropose('États-Unis', <String>{'America/Toronto', 'America/Los_Angeles'}),
];

/// Les pays du [fuseau] d'abord, les autres ensuite, chacun dans l'ordre
/// stable de [paysProposes].
///
/// Le fuseau de l'enseignant ne bouge pas d'une ouverture a l'autre : l'ordre
/// qu'il voit reste donc le meme, et la memoire du geste tient.
List<PaysPropose> paysOrdonnes(String? fuseau) => <PaysPropose>[
  ...paysProposes.where((PaysPropose p) => p.fuseaux.contains(fuseau)),
  ...paysProposes.where((PaysPropose p) => !p.fuseaux.contains(fuseau)),
];

/// La reponse a pre-cocher pour le pays.
///
/// Le pays deja declare gagne toujours : le contredire serait pire que ne rien
/// proposer. S'il n'est pas dans la liste, il revient dans « Autre », tel
/// qu'il a ete ecrit. Sans pays declare, le premier pays du fuseau est
/// propose ; l'enseignant confirme toujours par « Enregistrer ».
ReponseChoix? paysPreselectionne({String? paysDeclare, String? fuseau}) {
  final String? declare = paysDeclare?.trim();
  if (declare != null && declare.isNotEmpty) {
    final bool connu = paysProposes.any((PaysPropose p) => p.nom == declare);
    return connu
        ? ReponseChoix(valeurs: <String>{declare})
        : ReponseChoix(
            valeurs: const <String>{ChoiceCardGroup.valeurAutre},
            saisieLibre: declare,
          );
  }
  final PaysPropose? duFuseau = paysProposes
      .where((PaysPropose p) => p.fuseaux.contains(fuseau))
      .firstOrNull;
  return duFuseau == null
      ? null
      : ReponseChoix(valeurs: <String>{duFuseau.nom});
}

/// Ce qu'une reponse de pays enregistre, ou `null` si rien d'exploitable.
String? paysDeLaReponse(ReponseChoix reponse) {
  if (reponse.valeurs.contains(ChoiceCardGroup.valeurAutre)) {
    final String libre = reponse.saisieLibre?.trim() ?? '';
    return libre.isEmpty ? null : libre;
  }
  return reponse.valeurs.firstOrNull;
}

/// La feuille du pays : une liste au doigt, le clavier en dernier recours.
class FeuillePays extends StatefulWidget {
  /// Cree la feuille.
  const FeuillePays({
    required this.paysDeclare,
    required this.fuseau,
    super.key,
  });

  /// Le pays deja declare, s'il existe.
  final String? paysDeclare;

  /// Le fuseau IANA de l'enseignant, s'il est connu.
  final String? fuseau;

  /// Cle de l'action « Enregistrer ».
  static const Key enregistrerKey = ValueKey<String>('pays-enregistrer');

  /// Cle de la carte d'un pays.
  static Key carteKey(String nom) => ValueKey<String>('pays-$nom');

  @override
  State<FeuillePays> createState() => _FeuillePaysEtat();
}

class _FeuillePaysEtat extends State<FeuillePays> {
  late final ReponseChoix? _initiale = paysPreselectionne(
    paysDeclare: widget.paysDeclare,
    fuseau: widget.fuseau,
  );
  late ReponseChoix? _reponse = _initiale;
  bool _manquant = false;

  void _enregistrer() {
    final ReponseChoix? reponse = _reponse;
    final String? pays = reponse == null ? null : paysDeLaReponse(reponse);
    if (pays == null) {
      setState(() => _manquant = true);
      return;
    }
    Navigator.of(context).pop(pays);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final s = t.enseignant.profil;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(s.paysConsigne, style: textes.bodyMedium),
        Ecart.vLg,
        ChoiceCardGroup(
          valeurInitiale: _initiale,
          options: <OptionChoix>[
            for (final PaysPropose p in paysOrdonnes(widget.fuseau))
              OptionChoix(
                cle: FeuillePays.carteKey(p.nom),
                valeur: p.nom,
                libelle: p.nom,
                description: p.fuseaux.contains(widget.fuseau)
                    ? s.paysDuFuseau
                    : null,
              ),
          ],
          onChange: (ReponseChoix r) => setState(() {
            _reponse = r;
            _manquant = false;
          }),
        ),
        if (_manquant) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              s.paysRequis,
              style: AppPalette.of(context).inkAlert
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
          ),
        ],
        Ecart.vXl,
        ActionPrincipale(
          key: FeuillePays.enregistrerKey,
          libelle: s.enregistrer,
          onPress: _enregistrer,
        ),
      ],
    );
  }
}

/// Les langues a cocher : celles que l'academie publie, puis celles que
/// l'enseignant avait deja declarees hors de cette liste.
///
/// **On enregistre le nom, pas le code.** `teacher_profiles.languages` est un
/// `text[]` libre et contient deja des noms (« Arabe », « Français ») ; y
/// melanger des codes (`francais`) rendrait la colonne illisible pour
/// l'academie. Le contrat `maj_profil_enseignant(p_languages)` reste donc
/// celui d'aujourd'hui. Une langue declaree avant que la liste existe n'est
/// jamais effacee en silence : elle reste une carte, cochee.
List<OptionChoix> optionsLangues(
  List<LangueCours> publiees,
  List<String> declarees,
) {
  final Set<String> noms = <String>{
    for (final LangueCours l in publiees)
      if (l.nom.trim().isNotEmpty) l.nom.trim(),
  };
  return <OptionChoix>[
    for (final String nom in noms)
      OptionChoix(cle: FeuilleLangues.carteKey(nom), valeur: nom, libelle: nom),
    for (final String nom in declarees)
      if (nom.trim().isNotEmpty && !noms.contains(nom.trim()))
        OptionChoix(
          cle: FeuilleLangues.carteKey(nom.trim()),
          valeur: nom.trim(),
          libelle: nom.trim(),
          description: t.enseignant.profil.langueDejaDeclaree,
        ),
  ];
}

/// Ce qu'une reponse de langues enregistre : les cartes, puis « Autre ».
List<String> languesDeLaReponse(ReponseChoix reponse) => <String>[
  for (final String v in reponse.valeurs)
    if (v != ChoiceCardGroup.valeurAutre) v,
  if (reponse.valeurs.contains(ChoiceCardGroup.valeurAutre) &&
      (reponse.saisieLibre?.trim().isNotEmpty ?? false))
    reponse.saisieLibre!.trim(),
];

/// La feuille des langues : choix multiple sur `languesCoursProvider`.
class FeuilleLangues extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleLangues({required this.declarees, super.key});

  /// Les langues deja declarees.
  final List<String> declarees;

  /// Cle de l'action « Enregistrer ».
  static const Key enregistrerKey = ValueKey<String>('langues-enregistrer');

  /// Cle de la carte d'une langue.
  static Key carteKey(String nom) => ValueKey<String>('langue-$nom');

  @override
  ConsumerState<FeuilleLangues> createState() => _FeuilleLanguesEtat();
}

class _FeuilleLanguesEtat extends ConsumerState<FeuilleLangues> {
  late final ReponseChoix _initiale = ReponseChoix(
    valeurs: <String>{
      for (final String l in widget.declarees)
        if (l.trim().isNotEmpty) l.trim(),
    },
  );
  late ReponseChoix _reponse = _initiale;
  bool _manquant = false;

  void _enregistrer() {
    final List<String> langues = languesDeLaReponse(_reponse);
    if (langues.isEmpty) {
      setState(() => _manquant = true);
      return;
    }
    Navigator.of(context).pop(langues);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final s = t.enseignant.profil;
    final AsyncValue<List<LangueCours>> publiees = ref.watch(
      languesCoursProvider,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(s.languesConsigne, style: textes.bodyMedium),
        Ecart.vLg,
        BlocAsynchrone<List<LangueCours>>(
          valeur: publiees,
          squelette: const Skeleton.liste(lignes: 3),
          onReessayer: () => ref.invalidate(languesCoursProvider),
          // Une liste vide n'est pas un mur : les langues deja declarees et
          // « Autre » restent proposees.
          estVide: (List<LangueCours> _) => false,
          erreurVersEtat: (Object _, VoidCallback? reessayer) => EtatSysteme(
            nature: NatureEtat.echecServeur,
            titre: s.languesErreur,
            phrase: s.languesErreurDetail,
            onAction: reessayer,
          ),
          construire: (List<LangueCours> lues) => ChoiceCardGroup(
            selectionMultiple: true,
            valeurInitiale: _initiale,
            options: optionsLangues(lues, widget.declarees),
            onChange: (ReponseChoix r) => setState(() {
              _reponse = r;
              _manquant = false;
            }),
          ),
        ),
        if (_manquant) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              s.languesRequises,
              style: AppPalette.of(context).inkAlert
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
          ),
        ],
        Ecart.vXl,
        if (publiees.hasValue)
          ActionPrincipale(
            key: FeuilleLangues.enregistrerKey,
            libelle: s.enregistrer,
            onPress: _enregistrer,
          ),
      ],
    );
  }
}

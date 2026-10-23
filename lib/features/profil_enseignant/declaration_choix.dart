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
        _BoutonEnregistrer(
          cle: FeuillePays.enregistrerKey,
          libelle: s.enregistrer,
          onPress: _enregistrer,
        ),
      ],
    );
  }
}

/// Le code d'une langue declaree, tel que le serveur l'enregistre.
///
/// Meme regle que le declencheur `teacher_profiles_langues_par_code`
/// (`20261021210000_ens_l8_langues_par_code.sql`) : un code du [referentiel]
/// (casse et espaces ignores) se donne lui-meme, un nom du referentiel donne
/// son code, et un code exact passe avant un nom homonyme. Toute autre saisie
/// revient telle quelle, sans ses espaces de bord (« Autre »). A nom egal, la
/// premiere langue du referentiel gagne : il est lu dans l'ordre publie,
/// comme cote serveur.
String codeLangueCours(String valeur, List<LangueCours> referentiel) {
  final String brut = valeur.trim();
  if (brut.isEmpty) {
    return brut;
  }
  final String reduit = brut.toLowerCase();
  for (final LangueCours l in referentiel) {
    if (l.code == reduit) {
      return l.code;
    }
  }
  for (final LangueCours l in referentiel) {
    if (l.nom.trim().toLowerCase() == reduit) {
      return l.code;
    }
  }
  return brut;
}

/// Le nom a afficher d'une langue enregistree dans le profil enseignant.
///
/// Le profil porte des codes (`francais`) : on affiche le nom du [referentiel]
/// (« Français »), langues retirees comprises. Un nom stocke avant la
/// correction se retrouve aussi. Une saisie libre (« Wolof », tant que la
/// langue n'est pas au referentiel) s'affiche telle qu'elle a ete ecrite.
///
/// **Le referentiel doit etre lu.** Sans lui, un code ne se distingue pas
/// d'une saisie libre : l'ecran montre alors son etat de chargement ou
/// d'echec, jamais un code (`lib/CLAUDE.md`).
String nomLangueCours(String valeur, List<LangueCours> referentiel) {
  final String code = codeLangueCours(valeur, referentiel);
  for (final LangueCours l in referentiel) {
    if (l.code == code && l.nom.trim().isNotEmpty) {
      return l.nom.trim();
    }
  }
  return valeur.trim();
}

/// Les langues a cocher : celles que l'academie propose (les actives du
/// [referentiel]), puis celles que l'enseignant avait deja declarees hors de
/// cette liste.
///
/// **On enregistre le code, on affiche le nom** (CAND-Q15, lot langue).
/// `teacher_profiles.languages` porte des codes de `langues_cours`, comme
/// `groupes.langue_code` (0043:450) auquel l'eligibilite d'une classe le
/// compare (0082:64, 0083:111). FORM-L8 y ecrivait le nom : aucun enseignant
/// ne pouvait alors etre propose a une classe. Le serveur ramene de toute
/// facon un nom a son code, pour les clients encore en cache.
///
/// Une langue declaree n'est jamais effacee en silence. Un nom ou un code du
/// referentiel retrouve la carte de sa langue, sans seconde carte a la meme
/// cle (`choice_card_group.dart`, « Duplicate keys ») ; une langue retiree ou
/// une saisie libre reste une carte cochee, nommee. La cle d'une carte suit le
/// nom affiche.
List<OptionChoix> optionsLangues(
  List<LangueCours> referentiel,
  List<String> declarees,
) {
  final List<OptionChoix> options = <OptionChoix>[];
  final Set<String> valeurs = <String>{};
  final Set<String> cles = <String>{};
  void ajouter(String valeur, String libelle, {String? description}) {
    if (valeur.trim().isEmpty || libelle.isEmpty || !valeurs.add(valeur)) {
      return;
    }
    // Deux langues de meme nom (`nom_humain` n'est pas unique) : la seconde
    // ne reprend pas la cle de la premiere.
    final String cle = cles.add(libelle) ? libelle : '$libelle|$valeur';
    options.add(
      OptionChoix(
        cle: FeuilleLangues.carteKey(cle),
        valeur: valeur,
        libelle: libelle,
        description: description,
      ),
    );
  }

  for (final LangueCours l in referentiel) {
    if (l.actif) {
      ajouter(l.code, l.nom.trim());
    }
  }
  for (final String declaree in declarees) {
    final String code = codeLangueCours(declaree, referentiel);
    ajouter(
      code,
      nomLangueCours(code, referentiel),
      description: t.enseignant.profil.langueDejaDeclaree,
    );
  }
  return options;
}

/// La reponse a pre-cocher : les langues [declarees], ramenees a leur code
/// comme le fait le serveur, sans doublon et dans l'ordre declare. Un nom
/// enregistre par un ancien client (« Français ») coche donc la carte
/// `francais`, au lieu d'en creer une seconde.
ReponseChoix languesPreselectionnees(
  List<String> declarees,
  List<LangueCours> referentiel,
) => ReponseChoix(
  valeurs: <String>{
    for (final String l in declarees)
      if (l.trim().isNotEmpty) codeLangueCours(l, referentiel),
  },
);

/// Ce qu'une reponse de langues enregistre : les cartes, puis « Autre ».
List<String> languesDeLaReponse(ReponseChoix reponse) => <String>[
  for (final String v in reponse.valeurs)
    if (v != ChoiceCardGroup.valeurAutre) v,
  if (reponse.valeurs.contains(ChoiceCardGroup.valeurAutre) &&
      (reponse.saisieLibre?.trim().isNotEmpty ?? false))
    reponse.saisieLibre!.trim(),
];

/// La feuille des langues : choix multiple sur `referentielLanguesProvider`,
/// les langues actives en cartes.
class FeuilleLangues extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleLangues({required this.declarees, super.key});

  /// Les langues deja declarees, telles que le profil les porte.
  final List<String> declarees;

  /// Cle de l'action « Enregistrer ».
  static const Key enregistrerKey = ValueKey<String>('langues-enregistrer');

  /// Cle de la carte d'une langue, d'apres son nom affiche.
  static Key carteKey(String nom) => ValueKey<String>('langue-$nom');

  @override
  ConsumerState<FeuilleLangues> createState() => _FeuilleLanguesEtat();
}

class _FeuilleLanguesEtat extends ConsumerState<FeuilleLangues> {
  /// La reponse pre-cochee, calculee une seule fois sur le referentiel lu :
  /// les langues declarees y sont deja des codes. Nulle tant qu'il n'est pas
  /// lu ; le bouton n'existe pas avant.
  ReponseChoix? _initiale;

  /// La reponse en cours, nulle tant que rien n'a ete touche.
  ReponseChoix? _reponse;
  bool _manquant = false;

  ReponseChoix _initialePour(List<LangueCours> referentiel) =>
      _initiale ??= languesPreselectionnees(widget.declarees, referentiel);

  void _enregistrer() {
    final List<LangueCours> referentiel =
        ref.read(referentielLanguesProvider).value ?? const <LangueCours>[];
    final ReponseChoix? reponse = _reponse ?? _initiale;
    // « Autre » peut nommer une langue du referentiel : elle part en code,
    // une seule fois.
    final List<String> langues = <String>{
      if (reponse != null)
        for (final String v in languesDeLaReponse(reponse))
          codeLangueCours(v, referentiel),
    }.toList(growable: false);
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
    final AsyncValue<List<LangueCours>> referentiel = ref.watch(
      referentielLanguesProvider,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(s.languesConsigne, style: textes.bodyMedium),
        Ecart.vLg,
        BlocAsynchrone<List<LangueCours>>(
          valeur: referentiel,
          squelette: const Skeleton.liste(lignes: 3),
          onReessayer: () => ref.invalidate(referentielLanguesProvider),
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
            valeurInitiale: _initialePour(lues),
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
        if (referentiel.hasValue)
          _BoutonEnregistrer(
            cle: FeuilleLangues.enregistrerKey,
            libelle: s.enregistrer,
            onPress: _enregistrer,
          ),
      ],
    );
  }
}

/// Le bouton plein d'une feuille : une feuille n'en porte qu'un (K-42). Les deux
/// feuilles du fichier le posent par ce seul constructeur.
class _BoutonEnregistrer extends StatelessWidget {
  const _BoutonEnregistrer({
    required this.cle,
    required this.libelle,
    required this.onPress,
  });

  final Key cle;
  final String libelle;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) =>
      ActionPrincipale(key: cle, libelle: libelle, onPress: onPress);
}

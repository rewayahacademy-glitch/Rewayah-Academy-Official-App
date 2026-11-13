// HORLOGE-ET-LIEU, partie B (H5) : le choix de la ville, un seul composant.
//
// Utilise par la page `/ville` (tuteur, enseignant), par l'etape de ville de
// l'inscription et par la candidature. Un champ de recherche (les premieres
// lettres, avec ou sans accent), sous lui la liste, et avant toute frappe les
// plus grandes villes dont le fuseau a aujourd'hui le decalage de l'appareil :
// l'appareil ne donne jamais la position, seulement un decalage.
//
// Cinq etats : lecture (squelette), contenu, vide (ce qu'il faut essayer),
// erreur (ce qui manque et quoi faire), hors ligne (le bandeau de la page le
// dit, le bloc dit ce qui manque). Le credit GeoNames (CC BY 4.0) reste sous
// le champ, dans les deux langues.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/pays_iso.dart';
import '../i18n/strings.g.dart';
import '../reseau/etat_sans_donnees.dart';
import '../reseau/service_reseau.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_spacing.dart';
import '../widgets/champ_recherche.dart';
import '../widgets/choice_card_group.dart';
import '../widgets/etat_systeme.dart';
import '../widgets/skeleton.dart';
import 'lieu.dart';

/// Le nom d'une ville dans la langue de l'interface : le nom arabe quand la
/// liste en donne un et que l'interface est en arabe.
String nomDeLaVille(Ville v) =>
    LocaleSettings.currentLocale == AppLocale.ar && v.nomAr != null
    ? v.nomAr!
    : v.nom;

/// « Region, Pays » : ce qui distingue deux villes du meme nom.
String detailDeLaVille(Ville v) {
  final String pays = nomDuPays(v.paysCode);
  final String? region = v.region;
  return region == null || region == v.nom ? pays : '$region, $pays';
}

/// Le choix d'une ville.
class ChoixVille extends ConsumerStatefulWidget {
  /// Cree le choix.
  const ChoixVille({required this.onChoisie, this.initiale, super.key});

  /// Appelee quand la personne choisit une ville.
  final ValueChanged<Ville> onChoisie;

  /// La ville deja choisie, retenue d'emblee.
  final Ville? initiale;

  /// Cle du champ de recherche.
  static const Key cleChamp = ValueKey<String>('choix-ville-champ');

  /// Cle du texte de credit.
  static const Key cleCredit = ValueKey<String>('choix-ville-credit');

  @override
  ConsumerState<ChoixVille> createState() => _EtatChoixVille();
}

class _EtatChoixVille extends ConsumerState<ChoixVille> {
  final TextEditingController _controleur = TextEditingController();
  Timer? _delai;
  int _requete = 0;
  bool _chargement = true;
  bool _erreur = false;
  List<Ville> _liste = const <Ville>[];
  bool _recherche = false;
  Ville? _choisie;

  @override
  void initState() {
    super.initState();
    _choisie = widget.initiale;
    unawaited(_charger());
  }

  @override
  void dispose() {
    _delai?.cancel();
    _controleur.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final int cette = ++_requete;
    final String texte = _controleur.text.trim();
    final bool cherche = texte.length >= 2;
    setState(() {
      _chargement = true;
      _erreur = false;
      _recherche = cherche;
    });
    try {
      final PortLieu port = ref.read(portLieuProvider);
      final List<Ville> liste = cherche
          ? await port.rechercher(texte)
          : await port.proposees(DateTime.now().timeZoneOffset.inMinutes);
      if (!mounted || cette != _requete) return;
      setState(() {
        _liste = liste;
        _chargement = false;
      });
    } on Object {
      if (!mounted || cette != _requete) return;
      setState(() {
        _erreur = true;
        _chargement = false;
      });
    }
  }

  void _frappe(String _) {
    _delai?.cancel();
    _delai = Timer(AppMouvement.delaiFrappe, () => unawaited(_charger()));
  }

  void _choisir(ReponseChoix r) {
    if (r.valeurs.isEmpty) return;
    final int? id = int.tryParse(r.valeurs.first);
    final Ville? v = _liste.where((Ville x) => x.id == id).firstOrNull;
    if (v == null) return;
    setState(() => _choisie = v);
    widget.onChoisie(v);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final h = t.lieu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChampRecherche(
          cleChamp: ChoixVille.cleChamp,
          controleur: _controleur,
          libelle: h.champ,
          aide: h.aide,
          onChange: _frappe,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
          child: Text(
            key: ChoixVille.cleCredit,
            h.credit,
            style: textes.bodySmall,
          ),
        ),
        Ecart.vLg,
        _contenu(context, textes),
      ],
    );
  }

  Widget _contenu(BuildContext context, TextTheme textes) {
    final h = t.lieu;
    if (_chargement) return const Skeleton.liste(lignes: 4);
    if (_erreur) {
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      if (horsLigne) {
        return EtatSansDonnees(
          quoi: h.chargeEchec,
          onAction: () => unawaited(_charger()),
        );
      }
      return EtatSysteme(
        nature: NatureEtat.echecServeur,
        titre: h.chargeEchec,
        phrase: h.chargeEchecPhrase,
        libelleAction: t.commun.reessayer,
        onAction: () => unawaited(_charger()),
      );
    }
    if (_liste.isEmpty) {
      return Text(
        _recherche ? h.aucune(texte: _controleur.text.trim()) : h.aide,
        style: textes.bodyMedium,
      );
    }
    final Ville? retenue = _choisie;
    final bool retenueDansLaListe =
        retenue != null && _liste.any((Ville v) => v.id == retenue.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          _recherche ? h.resultats : h.propositions,
          style: textes.titleSmall,
        ),
        Ecart.vMd,
        ChoiceCardGroup(
          // Une autre liste, un autre groupe : la carte retenue se relit.
          key: ValueKey<String>(
            '${_recherche ? 'r' : 'p'}${_liste.map((Ville v) => v.id).join(',')}',
          ),
          autoriserSaisieLibre: false,
          valeurInitiale: retenueDansLaListe
              ? ReponseChoix(valeurs: <String>{'${retenue.id}'})
              : null,
          options: <OptionChoix>[
            for (final Ville v in _liste)
              OptionChoix(
                valeur: '${v.id}',
                libelle: nomDeLaVille(v),
                description: detailDeLaVille(v),
              ),
          ],
          onChange: _choisir,
        ),
      ],
    );
  }
}

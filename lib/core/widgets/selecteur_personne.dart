import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../tc_bibliotheque/recherche_catalogue.dart';
import '../theme/app_spacing.dart';
import 'bloc_asynchrone.dart';
import 'choice_card_group.dart';
import 'etat_systeme.dart';
import 'skeleton.dart';

/// Une personne qu'un formulaire peut proposer : son identifiant technique
/// (jamais affiche), son nom, et son identifiant immuable, qui departage deux
/// homonymes.
@immutable
class PersonneProposee {
  /// Cree une personne proposee.
  const PersonneProposee({
    required this.id,
    required this.nom,
    required this.identifiant,
  });

  /// L'identifiant technique du profil, celui que la RPC attend.
  final String id;

  /// Le nom affiche. Se replie sur l'identifiant immuable quand l'identite
  /// est masquee (voir `CompteAdmin.libelle`).
  final String nom;

  /// L'identifiant immuable, `[ROLE]-[INITIALES]-[SEQ]`.
  final String identifiant;
}

/// Ce que le selecteur cherche : les textes en dependent.
enum SortePersonne {
  /// Un eleve.
  eleve,

  /// Un enseignant.
  enseignant,

  /// N'importe quelle personne qu'un agent peut observer (eleve, parent,
  /// enseignant...) : la liste vient de `personnes_observables()`.
  observable,
}

/// Le choix d'une personne dans une liste cherchable (FORM-L2, K-57 :
/// proposer avant de faire saisir).
///
/// Remplace les identifiants tapes a la main des formulaires
/// d'administration. Trois regles :
///
///   * **la liste vient d'une lecture existante**, jamais d'une requete de
///     plus : l'appelant passe la valeur asynchrone, ce composant la lit par
///     [BlocAsynchrone] (squelette, echec avec « Reessayer », vide) ;
///   * **la recherche porte sur le nom et l'identifiant**, sans accent ni
///     casse ([RechercheCatalogue.normaliser]) ;
///   * **au plus [maximumAffiche] cartes** : au-dela, une phrase dit combien
///     de personnes restent et invite a preciser la recherche. La personne
///     choisie reste toujours affichee, meme quand la recherche l'exclut.
class SelecteurPersonne extends StatefulWidget {
  /// Cree un selecteur.
  const SelecteurPersonne({
    required this.sorte,
    required this.personnes,
    required this.choisie,
    required this.onChoix,
    required this.onReessayer,
    super.key,
    this.maximumAffiche = 6,
  });

  /// Eleve ou enseignant.
  final SortePersonne sorte;

  /// Les personnes proposables, telles que le provider les rend.
  final AsyncValue<List<PersonneProposee>> personnes;

  /// L'identifiant de la personne choisie, nul tant que rien n'est choisi.
  final String? choisie;

  /// Appele avec la personne touchee.
  final void Function(PersonneProposee personne) onChoix;

  /// Relance la lecture (en general `ref.invalidate`).
  final VoidCallback onReessayer;

  /// Le nombre de cartes au-dela duquel la recherche doit etre precisee.
  final int maximumAffiche;

  @override
  State<SelecteurPersonne> createState() => _SelecteurPersonneEtat();
}

class _SelecteurPersonneEtat extends State<SelecteurPersonne> {
  final TextEditingController _recherche = TextEditingController();

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  /// Les phrases de la sorte choisie.
  _Textes get _textes {
    final s = t.commun.selecteurPersonne;
    return switch (widget.sorte) {
      SortePersonne.eleve => _Textes(
        titre: s.titreEleve,
        contexte: s.contexteEleve,
        recherche: s.rechercheEleve,
        videTitre: s.videEleve,
        videDetail: s.videEleveDetail,
        erreurTitre: s.erreurEleveTitre,
      ),
      SortePersonne.enseignant => _Textes(
        titre: s.titreEnseignant,
        contexte: s.contexteEnseignant,
        recherche: s.rechercheEnseignant,
        videTitre: s.videEnseignant,
        videDetail: s.videEnseignantDetail,
        erreurTitre: s.erreurEnseignantTitre,
      ),
      SortePersonne.observable => _Textes(
        titre: s.titreObservable,
        contexte: s.contexteObservable,
        recherche: s.rechercheObservable,
        videTitre: s.videObservable,
        videDetail: s.videObservableDetail,
        erreurTitre: s.erreurObservableTitre,
      ),
    };
  }

  List<PersonneProposee> _correspondantes(List<PersonneProposee> toutes) {
    final String cle = RechercheCatalogue.normaliser(_recherche.text.trim());
    if (cle.isEmpty) return toutes;
    return toutes
        .where(
          (PersonneProposee p) =>
              RechercheCatalogue.normaliser(p.nom).contains(cle) ||
              RechercheCatalogue.normaliser(p.identifiant).contains(cle),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final s = t.commun.selecteurPersonne;
    final _Textes mots = _textes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(mots.titre, style: textes.titleMedium),
        Ecart.vXs,
        Text(mots.contexte, style: textes.bodySmall),
        Ecart.vMd,
        BlocAsynchrone<List<PersonneProposee>>(
          valeur: widget.personnes,
          squelette: const Skeleton.liste(lignes: 3),
          onReessayer: widget.onReessayer,
          erreurVersEtat: (Object _, VoidCallback? reessayer) => EtatSysteme(
            nature: NatureEtat.echecServeur,
            titre: mots.erreurTitre,
            phrase: s.erreurDetail,
            onAction: reessayer,
          ),
          vide: EtatSysteme(
            nature: NatureEtat.aucunResultat,
            titre: mots.videTitre,
            phrase: mots.videDetail,
          ),
          construire: _liste,
        ),
      ],
    );
  }

  Widget _liste(List<PersonneProposee> toutes) {
    final s = t.commun.selecteurPersonne;
    final List<PersonneProposee> trouvees = _correspondantes(toutes);
    final PersonneProposee? choisie = toutes
        .where((PersonneProposee p) => p.id == widget.choisie)
        .firstOrNull;
    final List<PersonneProposee> affichees = <PersonneProposee>[
      ?choisie,
      ...trouvees
          .where((PersonneProposee p) => p.id != choisie?.id)
          .take(widget.maximumAffiche - (choisie == null ? 0 : 1)),
    ];
    final int restantes =
        trouvees.length - affichees.where(trouvees.contains).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextField(
          controller: _recherche,
          onChanged: (String _) => setState(() {}),
          // Une indication sur plusieurs lignes, pas une etiquette : une
          // etiquette flottante tient sur une ligne et se coupait a 320 px en
          // texte x2 (« Chercher un ... », capture FORM-L2).
          decoration: InputDecoration(
            hintText: _textes.recherche,
            hintMaxLines: 6,
            prefixIcon: Icon(AppIcons.recherche.repos),
          ),
        ),
        Ecart.vMd,
        if (trouvees.isEmpty) ...<Widget>[
          EtatSysteme(
            nature: NatureEtat.aucunResultat,
            titre: s.aucunResultat(recherche: _recherche.text.trim()),
            phrase: s.aucunResultatDetail,
            libelleAction: s.effacerRecherche,
            onAction: () => setState(_recherche.clear),
          ),
          if (affichees.isNotEmpty) Ecart.vLg,
        ],
        if (affichees.isNotEmpty)
          ChoiceCardGroup(
            // Une cle par choix : le groupe repart de la personne choisie,
            // qui reste ainsi la seule source de verite (le parent).
            key: ValueKey<String?>(choisie?.id),
            autoriserSaisieLibre: false,
            valeurInitiale: choisie == null
                ? null
                : ReponseChoix(valeurs: <String>{choisie.id}),
            options: <OptionChoix>[
              for (final PersonneProposee p in affichees)
                OptionChoix(
                  cle: ValueKey<String>('personne-${p.id}'),
                  valeur: p.id,
                  libelle: p.nom,
                  description: p.identifiant == p.nom ? null : p.identifiant,
                ),
            ],
            onChange: (ReponseChoix reponse) {
              final String? id = reponse.valeurs.firstOrNull;
              final PersonneProposee? personne = toutes
                  .where((PersonneProposee p) => p.id == id)
                  .firstOrNull;
              if (personne != null) widget.onChoix(personne);
            },
          ),
        if (restantes > 0)
          Text(
            restantes == 1 ? s.autreUne : s.autresPlusieurs(n: restantes),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

/// Les phrases d'une sorte de personne.
@immutable
class _Textes {
  const _Textes({
    required this.titre,
    required this.contexte,
    required this.recherche,
    required this.videTitre,
    required this.videDetail,
    required this.erreurTitre,
  });

  final String titre;
  final String contexte;
  final String recherche;
  final String videTitre;
  final String videDetail;
  final String erreurTitre;
}

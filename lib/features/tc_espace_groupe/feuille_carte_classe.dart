// CARTES-PERSO-1 : la feuille ou l'enseignant compose une carte de sa
// Classe (fiche CLS-CARTES, `docs/current/DASH_STRATEGIE.md` annexe A).
//
// K-57, deduit > choisi > saisi : le modele (choisi) preremplit le titre
// propose et, pour un devoir ou un rappel, l'echeance (deduite : la date de
// la prochaine seance) ; seuls le titre, le texte et le lien se saisissent,
// parce que ce sont des mots de l'enseignant. K-58 : la feuille commence par
// une phrase de contexte et chaque modele dit quand le choisir. Le bouton
// d'enregistrement n'est jamais grise : il dit ce qui manque (K-59).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_groupe/cartes_classe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/zone_saisie.dart';
import 'bloc_cartes_classe.dart'
    show echeanceRendue, iconeTypeCarte, libelleTypeCarte;

/// Le titre propose d'un modele.
String titreModele(TypeCarteClasse type) => switch (type) {
  TypeCarteClasse.annonce => t.classe.cartes.modeles.annonce,
  TypeCarteClasse.devoir => t.classe.cartes.modeles.devoir,
  TypeCarteClasse.lien => t.classe.cartes.modeles.lien,
  TypeCarteClasse.rappel => t.classe.cartes.modeles.rappel,
};

String _quandChoisir(TypeCarteClasse type) => switch (type) {
  TypeCarteClasse.annonce => t.classe.cartes.typesDetail.annonce,
  TypeCarteClasse.devoir => t.classe.cartes.typesDetail.devoir,
  TypeCarteClasse.lien => t.classe.cartes.typesDetail.lien,
  TypeCarteClasse.rappel => t.classe.cartes.typesDetail.rappel,
};

/// Le sens de lecture d'une saisie de l'enseignant : celui de sa premiere
/// lettre (arabe, hebreu : droite a gauche ; une autre lettre : gauche a
/// droite), ou `null` sans lettre, et le champ suit alors l'interface. En
/// arabe, « Lire la sourate. » saisi en francais s'affichait « .Lire la
/// sourate » (revue CARTES-PERSO-1, deuxieme passe).
TextDirection? sensDeLaSaisie(String texte) {
  final RegExpMatch? lettre = _lettre.firstMatch(texte);
  if (lettre == null) return null;
  return _lettreDroiteAGauche.hasMatch(lettre[0]!)
      ? TextDirection.rtl
      : TextDirection.ltr;
}

final RegExp _lettre = RegExp(r'\p{L}', unicode: true);
final RegExp _lettreDroiteAGauche = RegExp(
  '[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]',
);

/// Le message d'un defaut, qui dit ce qui manque et quoi faire (K-59).
String messageDefaut(DefautCarte defaut) {
  final d = t.classe.cartes.feuille.defauts;
  return switch (defaut) {
    DefautCarte.titreVide => d.titreVide,
    DefautCarte.titreLong => d.titreLong(max: BornesCarteClasse.titreMax),
    DefautCarte.texteLong => d.texteLong(max: BornesCarteClasse.texteMax),
    DefautCarte.lienInvalide => d.lienInvalide,
    DefautCarte.echeanceManquante => d.echeanceManquante,
  };
}

/// La feuille de composition d'une carte. Rend, en se fermant, le message de
/// retour a afficher (carte enregistree ou retiree), ou rien si elle est
/// fermee sans envoi.
class FeuilleCarteClasse extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleCarteClasse({
    required this.groupeId,
    super.key,
    this.carte,
    this.prochaineSeance,
    this.aujourdhui,
  });

  /// La Classe.
  final String groupeId;

  /// La carte a modifier ; nulle pour une nouvelle carte.
  final CarteClasse? carte;

  /// La prochaine seance, qui devient l'echeance proposee.
  final DateTime? prochaineSeance;

  /// Le jour de reference du choix de date ; par defaut, l'appareil.
  final DateTime? aujourdhui;

  /// La cle du bouton d'enregistrement.
  static const Key enregistrerKey = Key('classe.cartes.enregistrer');

  /// La cle du lien de retrait.
  static const Key retirerKey = Key('classe.cartes.retirer');

  /// La cle du champ de titre.
  static const Key titreKey = Key('classe.cartes.champTitre');

  /// La cle du champ de texte.
  static const Key texteKey = Key('classe.cartes.champTexte');

  /// La cle du champ de lien.
  static const Key lienKey = Key('classe.cartes.champLien');

  @override
  ConsumerState<FeuilleCarteClasse> createState() => _FeuilleCarteClasseEtat();
}

class _FeuilleCarteClasseEtat extends ConsumerState<FeuilleCarteClasse> {
  late BrouillonCarte _brouillon =
      widget.carte?.versBrouillon() ??
      BrouillonCarte.modele(
        TypeCarteClasse.annonce,
        titre: titreModele(TypeCarteClasse.annonce),
        prochaineSeance: widget.prochaineSeance,
      );
  late final TextEditingController _titre = TextEditingController(
    text: _brouillon.titre,
  );
  late final TextEditingController _texte = TextEditingController(
    text: _brouillon.texte,
  );
  late final TextEditingController _lien = TextEditingController(
    text: _brouillon.lien,
  );

  /// Les defauts montres, seulement apres une premiere tentative : on ne
  /// gronde pas avant que la personne ait fini.
  Set<DefautCarte> _defauts = const <DefautCarte>{};
  bool _tente = false;
  bool _envoi = false;
  bool _retrait = false;
  String? _echec;

  @override
  void dispose() {
    _titre.dispose();
    _texte.dispose();
    _lien.dispose();
    super.dispose();
  }

  BrouillonCarte get _saisi => _brouillon.copie(
    titre: _titre.text,
    texte: _texte.text,
    lien: _lien.text,
  );

  /// Apres chaque frappe : le sens de lecture des champs suit leur texte,
  /// et les defauts se relisent apres une premiere tentative.
  void _revalider() {
    setState(() {
      if (_tente) _defauts = defautsCarte(_saisi);
    });
  }

  void _changerType(TypeCarteClasse type) {
    final TypeCarteClasse avant = _brouillon.type;
    // Le titre propose suit le modele tant que l'enseignant ne l'a pas
    // reecrit ; une echeance deja choisie est gardee.
    final String titre = _titre.text.trim();
    if (titre.isEmpty || titre == titreModele(avant)) {
      _titre.text = titreModele(type);
    }
    final BrouillonCarte modele = BrouillonCarte.modele(
      type,
      titre: _titre.text,
      prochaineSeance: widget.prochaineSeance,
    );
    setState(() {
      _brouillon = _brouillon.copie(
        type: type,
        echeance: _brouillon.echeance ?? modele.echeance,
      );
    });
    _revalider();
  }

  Future<void> _choisirDate() async {
    final DateTime jour = dateSeule(widget.aujourdhui ?? DateTime.now());
    final DateTime? actuelle = _brouillon.echeance;
    final DateTime? choisie = await showDatePicker(
      context: context,
      initialDate: actuelle != null && !actuelle.isBefore(jour)
          ? actuelle
          : jour,
      firstDate: jour,
      lastDate: DateTime(jour.year + 1, jour.month, jour.day),
      helpText: t.classe.cartes.feuille.choisirEcheance,
    );
    if (!mounted || choisie == null) return;
    setState(() => _brouillon = _brouillon.copie(echeance: dateSeule(choisie)));
    _revalider();
  }

  void _retirerEcheance() {
    setState(() => _brouillon = _brouillon.copie(sansEcheance: true));
    _revalider();
  }

  Future<void> _enregistrer() async {
    // Un envoi deja parti : le second appui ne repart pas (double envoi).
    if (_envoi || _retrait) return;
    final BrouillonCarte brouillon = _saisi;
    final Set<DefautCarte> defauts = defautsCarte(brouillon);
    setState(() {
      _tente = true;
      _defauts = defauts;
      _echec = null;
    });
    if (defauts.isNotEmpty) return;
    setState(() => _envoi = true);
    try {
      await ref
          .read(portCartesClasseProvider)
          .enregistrer(widget.groupeId, brouillon, carteId: widget.carte?.id);
      if (!mounted) return;
      Navigator.of(context).pop(t.classe.cartes.enregistree);
    } on Object {
      // Une reponse perdue ne dit pas que rien n'a ete fait (D5).
      if (mounted) {
        setState(() => _echec = t.classe.cartes.feuille.envoiNonConfirme);
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _retirer() async {
    final CarteClasse? carte = widget.carte;
    if (carte == null || _envoi || _retrait) return;
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: isolerSens(
        t.classe.cartes.feuille.retirerQuestion(titre: isolerSens(carte.titre)),
      ),
      consequence: isolerSens(t.classe.cartes.feuille.retirerConsequence),
      libelleConfirmer: t.classe.cartes.feuille.retirerConfirmer,
    );
    if (!confirme || !mounted) return;
    setState(() {
      _retrait = true;
      _echec = null;
    });
    try {
      await ref
          .read(portCartesClasseProvider)
          .retirer(widget.groupeId, carte.id);
      if (!mounted) return;
      Navigator.of(context).pop(t.classe.cartes.retiree);
    } on Object {
      if (mounted) {
        setState(() => _echec = t.classe.cartes.feuille.retraitNonConfirme);
      }
    } finally {
      if (mounted) setState(() => _retrait = false);
    }
  }

  /// Le message du premier defaut concerne, isole dans son sens de lecture
  /// (en RTL, « par .//:https » se lisait a rebours, revue CARTES-PERSO-1).
  String? _erreur(Iterable<DefautCarte> concernes) {
    for (final DefautCarte d in concernes) {
      if (_defauts.contains(d)) return isolerSens(messageDefaut(d));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final DateTime? echeance = _brouillon.echeance;
    final String? erreurEcheance = _erreur(const <DefautCarte>[
      DefautCarte.echeanceManquante,
    ]);
    final String? echec = _echec;
    final TextStyle alerte = palette.inkAlert.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    // Les aides des champs, isolees : en RTL, « 60 caracteres au plus » se
    // lisait « caracteres au plus 60 » (revue CARTES-PERSO-1).
    final String aideLongueurTitre = isolerSens(
      t.classe.cartes.feuille.aideLongueur(max: BornesCarteClasse.titreMax),
    );
    final String aideLongueurTexte = isolerSens(
      t.classe.cartes.feuille.aideLongueur(max: BornesCarteClasse.texteMax),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          isolerSens(t.classe.cartes.feuille.contexte),
          style: textes.bodyMedium,
        ),
        Ecart.vLg,
        Text(t.classe.cartes.feuille.modele, style: textes.titleSmall),
        Ecart.vSm,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(valeurs: <String>{_brouillon.type.name}),
          options: <OptionChoix>[
            for (final TypeCarteClasse type in TypeCarteClasse.values)
              OptionChoix(
                valeur: type.name,
                libelle: libelleTypeCarte(type),
                icone: iconeTypeCarte(type),
                // Une phrase de l'interface : isolee, son point reste a la
                // fin en RTL (« .classe » a 320 px x2, revue CARTES-PERSO-1).
                description: isolerSens(_quandChoisir(type)),
                cle: ValueKey<String>('classe.cartes.modele.${type.name}'),
              ),
          ],
          onChange: (ReponseChoix reponse) {
            final String? valeur = reponse.valeurs.firstOrNull;
            if (valeur == null) return;
            _changerType(TypeCarteClasse.values.byName(valeur));
          },
        ),
        _Libelle(t.classe.cartes.feuille.champTitre),
        Ecart.vXs,
        ZoneSaisie(
          cleChamp: FeuilleCarteClasse.titreKey,
          controleur: _titre,
          sens: sensDeLaSaisie(_titre.text),
          onChanged: (String _) => _revalider(),
          actionClavier: TextInputAction.next,
          // Le titre se relit en entier, meme a 320 px et texte x2.
          maxLignes: 3,
          explication: aideLongueurTitre,
          erreur: _erreur(const <DefautCarte>[
            DefautCarte.titreVide,
            DefautCarte.titreLong,
          ]),
        ),
        Ecart.vLg,
        _Libelle(t.classe.cartes.feuille.champTexte),
        Ecart.vXs,
        ZoneSaisie(
          cleChamp: FeuilleCarteClasse.texteKey,
          controleur: _texte,
          sens: sensDeLaSaisie(_texte.text),
          onChanged: (String _) => _revalider(),
          minLignes: 3,
          explication: aideLongueurTexte,
          erreur: _erreur(const <DefautCarte>[DefautCarte.texteLong]),
        ),
        Ecart.vLg,
        _Libelle(t.classe.cartes.feuille.champLien),
        Ecart.vXs,
        TextField(
          key: FeuilleCarteClasse.lienKey,
          controller: _lien,
          // Une adresse se lit toujours de gauche a droite.
          textDirection: TextDirection.ltr,
          onChanged: (String _) => _revalider(),
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            helperText: isolerSens(t.classe.cartes.feuille.aideLien),
            helperMaxLines: 6,
            errorMaxLines: 8,
            errorText: _erreur(const <DefautCarte>[DefautCarte.lienInvalide]),
          ),
        ),
        Ecart.vLg,
        // CARTES-PERSO-1c : la ligne d'echeance isolee dans son sens de
        // lecture, comme les aides et les erreurs (revue CARTES-PERSO-1b,
        // reserve 1) : un libelle termine par un point le garderait a la fin
        // en RTL.
        Text(
          isolerSens(
            echeance == null
                ? t.classe.cartes.feuille.echeanceAucune
                : t.classe.cartes.echeance(date: echeanceRendue(echeance)),
          ),
          style: textes.bodyLarge,
        ),
        if (erreurEcheance != null) ...<Widget>[
          Ecart.vXs,
          Text(erreurEcheance, style: alerte),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LienFleche(
            libelle: t.classe.cartes.feuille.choisirEcheance,
            onPress: () => unawaited(_choisirDate()),
          ),
        ),
        if (echeance != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              libelle: t.classe.cartes.feuille.retirerEcheance,
              onPress: _retirerEcheance,
            ),
          ),
        if (echec != null) ...<Widget>[
          Ecart.vLg,
          Text(isolerSens(echec), style: alerte),
        ],
        Ecart.vXl,
        ActionPrincipale(
          key: FeuilleCarteClasse.enregistrerKey,
          libelle: t.classe.cartes.feuille.enregistrer,
          enCours: _envoi,
          onPress: () => unawaited(_enregistrer()),
        ),
        if (widget.carte != null) ...<Widget>[
          Ecart.vMd,
          ActionPrincipale(
            key: FeuilleCarteClasse.retirerKey,
            libelle: t.classe.cartes.feuille.retirer,
            niveau: NiveauAction.tertiaire,
            enCours: _retrait,
            onPress: () => unawaited(_retirer()),
          ),
        ],
      ],
    );
  }
}

/// Le libelle d'un champ, pose au-dessus de lui, en entier, et lu juste
/// avant lui : celui de la decoration se tronque a 320 px et texte x2
/// (« Lien de la carte (facu... »).
class _Libelle extends StatelessWidget {
  const _Libelle(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) =>
      TexteSansCoupure(texte, style: Theme.of(context).textTheme.titleSmall);
}

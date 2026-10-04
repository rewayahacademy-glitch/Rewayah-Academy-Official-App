// Complement d'un rapport envoye (CTR-03B, CT-8, doc 08 P-CTR-07, C10).
//
// Meme langage que l'observation (CT-5) : `PageParcours`, une question par
// page, cartes de choix, recapitulatif, puis un seul bouton plein en bas.
// Les etapes sont celles que C10 enumere pour un complement : motif
// facultatif, contenu, puis recapitulatif. L'auteur, la date, l'heure et le
// rapport parent sont deduits (K-57), jamais saisis. Choix provisoire tant
// que la question 13 de UX_REVIEW_08 n'est pas tranchee par le directeur.
//
// Le bandeau « Ce complement sera ajoute au rapport existant. » reste en tete
// de chaque etape. `PermanentNotice` porte un texte fixe (enregistrement) et
// `EtatSysteme` n'a pas de nature « information » : le bandeau est donc une
// ligne icone + texte, dans le registre de la notice de CT-5.
//
// Le rapport parent n'est jamais modifie : seuls le contenu et le motif
// partent par le port ; l'ecran rend au detail une NOUVELLE vue
// (`RapportControle.avecComplement`). Echec honnete (D5, K-59) : « non
// confirme », la saisie reste, « Reessayer ». Aucun serveur (K-28).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/apparition_douce.dart';
import '../../core/theme/app_delais.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_parcours.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/status_pill.dart' show TonEtat;
import '../accueil_famille/bloc_seance.dart' show dateDeLAppareil;
import 'historique_controleur.dart';

/// Le motif d'un complement (libelles provisoires, D4 : absents du doc 08).
enum MotifComplement {
  /// Un detail manque.
  precision,

  /// Un fait du rapport est inexact.
  correction,

  /// Un fait appris apres la visite.
  faitNouveau,
}

enum _Etape { motif, texte, recapitulatif, envoye }

/// Le parcours « Ajouter un complement » d'un rapport envoye.
class ComplementRapportPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const ComplementRapportPage({
    required this.rapport,
    required this.onRetour,
    required this.onTermine,
    super.key,
  });

  /// Le rapport parent, en lecture seule.
  final RapportControle rapport;

  /// Le retour au detail depuis la premiere etape : rien n'est envoye.
  final VoidCallback onRetour;

  /// Le retour au detail apres l'envoi confirme, avec la nouvelle vue.
  final ValueChanged<RapportControle> onTermine;

  /// Le bandeau permanent.
  static const Key bandeauKey = ValueKey<String>('ctr03b-bandeau');

  /// Le champ de texte.
  static const Key texteKey = ValueKey<String>('ctr03b-texte');

  /// La carte d'un motif.
  static Key cleMotif(MotifComplement m) =>
      ValueKey<String>('ctr03b-motif-${m.name}');

  /// Le libelle d'un motif.
  static String libelleMotif(MotifComplement m) => switch (m) {
    MotifComplement.precision => t.controleur.complement.precision,
    MotifComplement.correction => t.controleur.complement.correction,
    MotifComplement.faitNouveau => t.controleur.complement.faitNouveau,
  };

  @override
  ConsumerState<ComplementRapportPage> createState() =>
      _ComplementRapportPageState();
}

class _ComplementRapportPageState extends ConsumerState<ComplementRapportPage> {
  _Etape _etape = _Etape.motif;
  MotifComplement? _motif;
  final TextEditingController _texte = TextEditingController();
  bool _texteManquant = false;
  bool _enCours = false;
  bool _echec = false;
  RapportControle? _resultat;

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  void _aller(_Etape e) => setState(() {
    _etape = e;
    _echec = false;
  });

  void _precedent() => switch (_etape) {
    _Etape.motif => widget.onRetour(),
    _Etape.texte => _aller(_Etape.motif),
    _Etape.recapitulatif => _aller(_Etape.texte),
    _Etape.envoye => null,
  };

  void _validerTexte() {
    if (_texte.text.trim().isEmpty) {
      setState(() => _texteManquant = true);
      return;
    }
    _aller(_Etape.recapitulatif);
  }

  Future<void> _envoyer() async {
    final String texte = _texte.text.trim();
    if (_enCours) return;
    if (texte.isEmpty) {
      setState(() {
        _etape = _Etape.texte;
        _texteManquant = true;
      });
      return;
    }
    final MotifComplement? m = _motif;
    setState(() {
      _enCours = true;
      _echec = false;
    });
    try {
      final ComplementRapport c = await ref
          .read(portHistoriqueProvider)
          .ajouterComplement(
            widget.rapport.id,
            texte: texte,
            motif: m == null ? null : ComplementRapportPage.libelleMotif(m),
          )
          // Serveur muet : « non confirme » et Reessayer (CTRL-DELAI-1).
          .timeout(AppDelais.requeteMax);
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _resultat = widget.rapport.avecComplement(c);
        _etape = _Etape.envoye;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _echec = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = t.controleur.complement;
    final RapportControle? fait = _resultat;
    if (_etape == _Etape.envoye && fait != null) {
      return PageShell(
        titre: t.controleur.historique.ajouterComplement,
        child: ApparitionDouce(
          child: EcranResultat(
            icone: AppIcons.succes,
            ton: TonEtat.succes,
            titre: c.envoyeTitre,
            phrase: c.envoyePhrase,
            libelleAction: c.revenir,
            onAction: () => widget.onTermine(fait),
          ),
        ),
      );
    }

    final String question;
    String? explication;
    final Widget corps;
    VoidCallback? action;
    String libelle = t.commun.continuer;
    switch (_etape) {
      case _Etape.motif:
        question = c.questionMotif;
        explication = c.contexteMotif;
        corps = _motifs();
        action = () => _aller(_Etape.texte);
      case _Etape.texte:
        question = c.questionTexte;
        explication = c.texteObligatoire;
        corps = _champTexte();
        action = _validerTexte;
      case _Etape.recapitulatif:
      case _Etape.envoye:
        question = c.questionRecap;
        corps = _recapitulatif();
        action = _envoyer;
        libelle = _echec ? t.commun.reessayer : c.envoyer;
    }

    return PageParcours(
      numero: _etape.index + 1,
      total: 3,
      question: question,
      explication: explication,
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _Bandeau(key: ComplementRapportPage.bandeauKey),
          Ecart.vLg,
          ApparitionDouce(key: ValueKey<_Etape>(_etape), child: corps),
        ],
      ),
      libelleAction: libelle,
      onAction: _enCours ? null : action,
      onRetour: _enCours ? null : _precedent,
      enCours: _enCours,
      souscription: _etape == _Etape.recapitulatif && _echec
          ? Semantics(
              liveRegion: true,
              child: Text(
                c.echec,
                style: AppPalette.of(context).inkStrong.applyTo(
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                ),
              ),
            )
          : null,
    );
  }

  Widget _motifs() {
    final c = t.controleur.complement;
    final MotifComplement? m = _motif;
    return ChoiceCardGroup(
      key: const ValueKey<String>('ctr03b-motifs'),
      autoriserSaisieLibre: false,
      valeurInitiale: m == null
          ? null
          : ReponseChoix(valeurs: <String>{m.name}),
      options: <OptionChoix>[
        for (final MotifComplement v in MotifComplement.values)
          OptionChoix(
            cle: ComplementRapportPage.cleMotif(v),
            valeur: v.name,
            libelle: ComplementRapportPage.libelleMotif(v),
            description: switch (v) {
              MotifComplement.precision => c.precisionAide,
              MotifComplement.correction => c.correctionAide,
              MotifComplement.faitNouveau => c.faitNouveauAide,
            },
          ),
      ],
      onChange: (ReponseChoix r) => setState(
        () => _motif = r.valeurs.isEmpty
            ? null
            : MotifComplement.values.firstWhere(
                (MotifComplement v) => v.name == r.valeurs.first,
              ),
      ),
    );
  }

  Widget _champTexte() => TextField(
    key: ComplementRapportPage.texteKey,
    controller: _texte,
    minLines: 4,
    maxLines: 8,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: t.controleur.complement.libelleTexte,
      hintText: t.controleur.complement.aideTexte,
      alignLabelWithHint: true,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      errorText: _texteManquant ? t.controleur.complement.texteRequis : null,
    ),
    onChanged: (String _) {
      if (_texteManquant) setState(() => _texteManquant = false);
    },
  );

  Widget _recapitulatif() {
    final c = t.controleur.complement;
    final RapportControle r = widget.rapport;
    final MotifComplement? m = _motif;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Le parent est rappele, deduit et non modifiable (K-57, C10).
        LigneCleValeur(
          cle: c.cleRapport,
          valeur: c.rapportInchange(
            classe: r.classe,
            date: dateDeLAppareil(r.debut),
          ),
        ),
        LigneCleValeur(
          cle: c.cleMotif,
          valeur: m == null
              ? c.sansMotif
              : ComplementRapportPage.libelleMotif(m),
        ),
        LigneCleValeur(cle: c.cleTexte, valeur: _texte.text.trim()),
      ],
    );
  }
}

/// Le bandeau permanent du complement : icone et texte, registre discret.
class _Bandeau extends StatelessWidget {
  const _Bandeau({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconTheme(
            data: palette.inkMuted.asIconTheme(size: 18),
            child: Icon(AppIcons.info.resoudre()),
          ),
          Ecart.hSm,
          Expanded(
            child: Text(
              t.controleur.complement.bandeau,
              style: palette.inkMuted.applyTo(
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/choice_card_group.dart';
import 'page_parcours.dart';

/// `TUT-00c` : creer son profil, en pages courtes.
///
/// Atteignable seulement par [PorteAcces.inscription], donc avec une session
/// valide et aucune ligne `profiles`.
///
/// Quatre pages, une question par page, cartes cliquables partout ou un choix
/// se presente (ADR-013). Le role declare ici n'accorde rien : la base ne
/// connait que deux roles publics et ecrit `pending_kyc` en dur, quoi que le
/// client envoie.
class InscriptionPage extends ConsumerStatefulWidget {
  /// Cree le parcours d'inscription.
  const InscriptionPage({super.key});

  @override
  ConsumerState<InscriptionPage> createState() => _InscriptionPageState();
}

/// Ce que la premiere page peut repondre.
///
/// L'eleve adulte n'est pas un role de plus : il est **son propre tuteur**, un
/// foyer d'une personne (ADR-009). Un seul chemin en base, deux libelles a
/// l'ecran, parce qu'un adulte qui apprend ne se reconnait pas dans « parent ».
enum _ChoixRole {
  tuteur(AppRole.guardian),
  eleveAdulte(AppRole.guardian),
  enseignant(AppRole.teacher);

  const _ChoixRole(this.role);

  final AppRole role;
}

class _InscriptionPageState extends ConsumerState<InscriptionPage> {
  static const int _pages = 4;

  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _nom = TextEditingController();

  int _page = 0;
  _ChoixRole? _choixRole;
  Genre? _genre;
  bool _horsParcours = false;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    super.dispose();
  }

  bool get _identiteRemplie =>
      _prenom.text.trim().isNotEmpty && _nom.text.trim().isNotEmpty;

  void _avancer() => setState(() {
    _page++;
    _erreur = null;
  });

  void _reculer() => setState(() {
    _page--;
    _erreur = null;
    _horsParcours = false;
  });

  Future<void> _creer() async {
    final _ChoixRole? choix = _choixRole;
    if (choix == null) {
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceDossierProvider)
          .creerProfil(
            role: choix.role,
            prenom: _prenom.text.trim(),
            nom: _nom.text.trim(),
            genre: _genre,
          );

      // Le role et le foyer sont injectes dans le jeton par le hook de la base :
      // le jeton emis avant la creation ne les porte pas encore. Sans ce
      // rafraichissement, le compte resterait sans role jusqu'a sa prochaine
      // connexion, et le routeur le laisserait devant une porte fermee.
      await ref.read(sourceSessionProvider).rafraichir();
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.inscription.erreur);
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_page) {
      0 => _pageRole(),
      1 => _pageIdentite(),
      2 => _pageGenre(),
      _ => _pageRecapitulatif(),
    };
  }

  Widget _pageRole() {
    return PageParcours(
      numero: 1,
      total: _pages,
      minutesRestantes: 3,
      question: t.inscription.roleQuestion,
      libelleAction: t.commun.continuer,
      onAction: _choixRole == null || _horsParcours ? null : _avancer,
      souscription: _horsParcours ? _Refus(message: t.inscription.autreAide) : null,
      enfant: ChoiceCardGroup(
        options: <OptionChoix>[
          OptionChoix(
            valeur: _ChoixRole.tuteur.name,
            libelle: t.inscription.roleTuteur,
            icone: AppIcons.foyer,
          ),
          OptionChoix(
            valeur: _ChoixRole.eleveAdulte.name,
            libelle: t.inscription.roleEleveAdulte,
            icone: AppIcons.accueil,
          ),
          OptionChoix(
            valeur: _ChoixRole.enseignant.name,
            libelle: t.inscription.roleEnseignant,
            icone: AppIcons.profil,
          ),
        ],
        onChange: (ReponseChoix reponse) {
          setState(() {
            final String? valeur = reponse.valeurs.isEmpty
                ? null
                : reponse.valeurs.first;
            // La carte « Autre » n'invente pas un role : elle dit que ce
            // parcours ne convient pas et renvoie vers l'academie.
            _horsParcours = valeur == ChoiceCardGroup.valeurAutre;
            _choixRole = _horsParcours
                ? null
                : _ChoixRole.values
                      .where((_ChoixRole r) => r.name == valeur)
                      .firstOrNull;
          });
        },
      ),
    );
  }

  Widget _pageIdentite() {
    return PageParcours(
      numero: 2,
      total: _pages,
      minutesRestantes: 2,
      question: t.inscription.identiteQuestion,
      explication: t.inscription.identiteRaison,
      libelleAction: t.commun.continuer,
      onAction: _identiteRemplie ? _avancer : null,
      onRetour: _reculer,
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _prenom,
            onChanged: (String _) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            autofillHints: const <String>[AutofillHints.givenName],
            decoration: InputDecoration(labelText: t.inscription.prenom),
          ),
          Ecart.vLg,
          TextField(
            controller: _nom,
            onChanged: (String _) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            autofillHints: const <String>[AutofillHints.familyName],
            decoration: InputDecoration(labelText: t.inscription.nom),
          ),
        ],
      ),
    );
  }

  Widget _pageGenre() {
    return PageParcours(
      numero: 3,
      total: _pages,
      minutesRestantes: 1,
      question: t.inscription.genreQuestion,
      explication: t.inscription.genreRaison,
      libelleAction: t.commun.continuer,
      onAction: _genre == null || _horsParcours ? null : _avancer,
      onRetour: _reculer,
      souscription: _horsParcours ? _Refus(message: t.inscription.autreAide) : null,
      enfant: ChoiceCardGroup(
        options: <OptionChoix>[
          OptionChoix(
            valeur: Genre.homme.valeurSql,
            libelle: t.inscription.genreHomme,
          ),
          OptionChoix(
            valeur: Genre.femme.valeurSql,
            libelle: t.inscription.genreFemme,
          ),
        ],
        onChange: (ReponseChoix reponse) {
          setState(() {
            final String? valeur = reponse.valeurs.isEmpty
                ? null
                : reponse.valeurs.first;
            _horsParcours = valeur == ChoiceCardGroup.valeurAutre;
            _genre = Genre.depuisSql(valeur);
          });
        },
      ),
    );
  }

  Widget _pageRecapitulatif() {
    final _ChoixRole? choix = _choixRole;
    return PageParcours(
      numero: 4,
      total: _pages,
      question: t.inscription.recapitulatif,
      libelleAction: t.inscription.creer,
      onAction: choix == null ? null : () => unawaited(_creer()),
      onRetour: _reculer,
      enCours: _envoi,
      souscription: _erreur == null ? null : _Refus(message: _erreur!),
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Ligne(
            libelle: t.inscription.roleQuestion,
            valeur: switch (choix) {
              _ChoixRole.tuteur => t.inscription.roleTuteur,
              _ChoixRole.eleveAdulte => t.inscription.roleEleveAdulte,
              _ChoixRole.enseignant => t.inscription.roleEnseignant,
              null => '',
            },
          ),
          const Divider(),
          _Ligne(
            libelle: t.inscription.identiteQuestion,
            valeur: '${_prenom.text.trim()} ${_nom.text.trim()}',
          ),
          const Divider(),
          _Ligne(
            libelle: t.inscription.genreQuestion,
            valeur: _genre == Genre.femme
                ? t.inscription.genreFemme
                : t.inscription.genreHomme,
          ),
        ],
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({required this.libelle, required this.valeur});

  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(libelle, style: textes.bodySmall),
          Ecart.vXs,
          Text(valeur, style: textes.titleMedium),
        ],
      ),
    );
  }
}

/// Un refus, ou une impasse, dit en une phrase sous le bouton.
class _Refus extends StatelessWidget {
  const _Refus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: palette.textOnLightAlert.applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      ),
    );
  }
}

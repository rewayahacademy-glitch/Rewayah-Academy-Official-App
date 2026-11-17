// L'inscription d'un associe invite (suite de BE-2a-2, ordre du pilote du
// 17/11/2026) : `/inscription/associe`. La personne a recu un code de la
// direction et s'est connectee avec l'adresse invitee. Elle verifie le code,
// puis dit son prenom, son nom et son genre (requis : une mission se porte du
// cote de la personne). Le serveur decide de tout (code lie a l'adresse, usage
// unique, compte sans aucun droit) ; l'ecran ne calcule rien.
//
// Cinq etats : chargement (verification, creation : le bouton le dit), contenu
// (le formulaire), vide (code inconnu, expire ou deja utilise : une phrase qui
// dit quoi faire), erreur (une phrase vraie par cause, D5 « non confirme »),
// hors ligne (rien n'est tente, la phrase le dit) ; sans port, indisponible.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/equipe/port_inscription_associe.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/zone_saisie.dart';

/// Ce que l'ecran montre.
enum _Phase { saisie, verification, resultat, envoi }

/// Le message d'une tentative qui n'a pas abouti.
enum _Echec {
  horsLigne,
  erreur,
  sessionRefusee,
  champsRefuses,
  nonConfirme,
  champsManquants,
}

/// `/inscription/associe`.
class AssociePage extends ConsumerStatefulWidget {
  /// Cree l'ecran ; [codeInitial] vient d'un lien et est verifie des l'ouverture.
  const AssociePage({this.codeInitial, super.key});

  /// Le code du lien, ou `null`.
  final String? codeInitial;

  /// La cle du champ du code.
  static const Key cleCode = ValueKey<String>('associe-code');

  /// La cle du bouton de verification.
  static const Key cleVerifier = ValueKey<String>('associe-verifier');

  /// La cle du bouton de creation du compte.
  static const Key cleCreer = ValueKey<String>('associe-creer');

  /// La cle du message d'echec.
  static const Key cleMessage = ValueKey<String>('associe-message');

  @override
  ConsumerState<AssociePage> createState() => _EtatAssocie();
}

class _EtatAssocie extends ConsumerState<AssociePage> {
  late final TextEditingController _code;
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _nom = TextEditingController();
  Genre? _genre;
  _Phase _phase = _Phase.saisie;
  ResultatCodeAssocie? _resultat;
  _Echec? _echec;
  bool _vide = false;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.codeInitial ?? '');
    if ((widget.codeInitial ?? '').trim().isNotEmpty) {
      unawaited(Future<void>.microtask(_verifier));
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _prenom.dispose();
    _nom.dispose();
    super.dispose();
  }

  Future<void> _verifier() async {
    final PortInscriptionAssocie? port = ref.read(
      portInscriptionAssocieProvider,
    );
    final String saisi = _code.text.trim();
    if (saisi.isEmpty) {
      setState(() => _vide = true);
      return;
    }
    if (port == null) return;
    setState(() {
      _vide = false;
      _echec = null;
      _phase = _Phase.verification;
    });
    ResultatCodeAssocie? resultat;
    _Echec? echec;
    try {
      resultat = await port.verifier(saisi);
    } on HorsLigneInscriptionAssocie {
      echec = _Echec.horsLigne;
    } on RefusInscriptionAssocie {
      echec = _Echec.sessionRefusee;
    } on Object {
      echec = _Echec.erreur;
    }
    if (!mounted) return;
    setState(() {
      _phase = resultat == null ? _Phase.saisie : _Phase.resultat;
      _resultat = resultat;
      _echec = echec;
    });
  }

  void _ressaisir() {
    _code.clear();
    setState(() {
      _phase = _Phase.saisie;
      _resultat = null;
      _echec = null;
      _vide = false;
    });
  }

  Future<void> _creer() async {
    final PortInscriptionAssocie? port = ref.read(
      portInscriptionAssocieProvider,
    );
    if (port == null || _phase == _Phase.envoi) return;
    final Genre? genre = _genre;
    if (_prenom.text.trim().isEmpty ||
        _nom.text.trim().isEmpty ||
        genre == null) {
      setState(() => _echec = _Echec.champsManquants);
      return;
    }
    setState(() {
      _phase = _Phase.envoi;
      _echec = null;
    });
    ResultatInscriptionAssocie? resultat;
    _Echec? echec;
    try {
      resultat = await port.inscrire(
        code: _code.text.trim(),
        prenom: _prenom.text.trim(),
        nom: _nom.text.trim(),
        genre: genre.valeurSql,
      );
    } on HorsLigneInscriptionAssocie {
      echec = _Echec.horsLigne;
    } on RefusInscriptionAssocie catch (e) {
      echec = switch (e.cause) {
        CauseRefusInscriptionAssocie.sessionRefusee => _Echec.sessionRefusee,
        CauseRefusInscriptionAssocie.champsRefuses => _Echec.champsRefuses,
      };
    } on Object {
      echec = _Echec.nonConfirme;
    }
    if (!mounted) return;
    if (resultat == ResultatInscriptionAssocie.consommee) {
      // Le role est pose dans le jeton par le crochet de la base : le jeton
      // emis avant la creation ne le porte pas encore.
      try {
        await ref.read(sourceSessionProvider).rafraichir();
      } on Object {
        if (!mounted) return;
        setState(() {
          _phase = _Phase.resultat;
          _echec = _Echec.nonConfirme;
        });
        return;
      }
      if (mounted) context.go(Routes.racinePour(AppRole.associe));
      return;
    }
    setState(() {
      if (resultat == null) {
        _phase = _Phase.resultat;
        _echec = echec;
        return;
      }
      _phase = _Phase.resultat;
      _resultat = switch (resultat) {
        ResultatInscriptionAssocie.inconnue => const CodeAssocieInconnu(),
        ResultatInscriptionAssocie.dejaUtilisee =>
          const CodeAssocieDejaUtilise(),
        ResultatInscriptionAssocie.expiree => const CodeAssocieExpire(),
        ResultatInscriptionAssocie.consommee => _resultat,
      };
    });
  }

  String? _phrase(_Echec? e) {
    final r = t.inscription.associe;
    return switch (e) {
      _Echec.horsLigne => r.horsLigne,
      _Echec.erreur => r.erreur,
      _Echec.sessionRefusee => r.sessionRefusee,
      _Echec.champsRefuses => r.champsRefuses,
      _Echec.nonConfirme => r.nonConfirme,
      _Echec.champsManquants => r.champsManquants,
      null => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final r = t.inscription.associe;
    final bool capable = ref.watch(portInscriptionAssocieProvider) != null;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return PageShell(
      titre: r.titre,
      onRetour: () => GoRouter.of(context).go(Routes.inscriptionUsage),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: !capable
              ? EtatSysteme(
                  key: const ValueKey<String>('associe-indisponible'),
                  nature: NatureEtat.indisponible,
                  titre: r.titre,
                  phrase: r.indisponible,
                  dependance: dependanceInscriptionAssocie,
                )
              : _corps(horsLigne),
        ),
      ),
    );
  }

  Widget _message(String? phrase) {
    if (phrase == null) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Semantics(
        liveRegion: true,
        child: Text(
          phrase,
          key: AssociePage.cleMessage,
          style: palette.inkAlert.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
      ),
    );
  }

  Widget _corps(bool horsLigne) {
    final r = t.inscription.associe;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle doux = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    final ResultatCodeAssocie? res = _resultat;

    if (_phase == _Phase.resultat || _phase == _Phase.envoi) {
      switch (res) {
        case CodeAssocieValide(:final DateTime? expireLe):
          return _formulaire(horsLigne, doux, expireLe);
        case CodeAssocieExpire():
          return _videCode(
            const ValueKey<String>('associe-expiree'),
            r.expiree,
            r.expireeDetail,
            AppIcons.invitationExpiree,
          );
        case CodeAssocieDejaUtilise():
          return EmptyState(
            key: const ValueKey<String>('associe-deja-utilisee'),
            message: r.dejaUtilisee,
            invitation: r.dejaUtiliseeDetail,
            icone: AppIcons.invitationRefusee,
            libelleAction: r.seConnecter,
            onAction: () => GoRouter.of(context).go(Routes.connexion),
          );
        case CodeAssocieInconnu():
          return _videCode(
            const ValueKey<String>('associe-inconnue'),
            r.inconnue,
            r.inconnueDetail,
            AppIcons.invitationRefusee,
          );
        case null:
          break;
      }
    }

    final bool enCours = _phase == _Phase.verification;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(r.intro, style: doux),
        Ecart.vLg,
        ZoneSaisie(
          controleur: _code,
          cleChamp: AssociePage.cleCode,
          libelle: r.champ,
          majuscules: TextCapitalization.characters,
          champDeCode: true,
          actionClavier: TextInputAction.done,
          erreur: _vide ? r.champVide : null,
          lectureSeule: enCours,
          onChanged: (_) {
            if (_vide) setState(() => _vide = false);
          },
          onSubmitted: (_) => unawaited(_verifier()),
        ),
        _message(horsLigne ? r.horsLigne : _phrase(_echec)),
        Ecart.vMd,
        // Hors ligne, la verification ne peut pas aboutir : le bouton n'est
        // pas rendu, la phrase le dit.
        if (!horsLigne)
          _bouton(
            cle: AssociePage.cleVerifier,
            libelle: r.verifier,
            enCours: enCours,
            surAppui: () => unawaited(_verifier()),
          ),
      ],
    );
  }

  /// Le seul bouton plein de l'ecran (K-56) : « Verifier le code », puis « Creer
  /// mon compte ». Un bouton qui ne peut pas aboutir n'est pas rendu (hors
  /// ligne) ; pendant l'attente, il le dit et ne repart pas.
  Widget _bouton({
    required Key cle,
    required String libelle,
    required bool enCours,
    required VoidCallback surAppui,
  }) => ActionPrincipale(
    key: cle,
    libelle: libelle,
    enCours: enCours,
    onPress: enCours ? null : surAppui,
  );

  Widget _videCode(Key cle, String message, String detail, AppIcon icone) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          EmptyState(
            key: cle,
            message: message,
            invitation: detail,
            icone: icone,
          ),
          Ecart.vMd,
          LienFleche(
            key: const ValueKey<String>('associe-ressaisir'),
            libelle: t.inscription.associe.ressaisir,
            onPress: _ressaisir,
          ),
        ],
      );

  Widget _formulaire(bool horsLigne, TextStyle doux, DateTime? expireLe) {
    final r = t.inscription.associe;
    final bool envoi = _phase == _Phase.envoi;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (expireLe != null)
            Text(
              r.valide(date: dateDeLAppareil(expireLe.toLocal())),
              key: const ValueKey<String>('associe-valide'),
              style: doux,
            ),
          Ecart.vSm,
          Text(r.formIntro, style: doux),
          Ecart.vLg,
          ChampEtiquete(
            libelle: t.inscription.prenom,
            obligatoire: true,
            cleChamp: const ValueKey<String>('associe-prenom'),
            controller: _prenom,
            textCapitalization: TextCapitalization.words,
            actionClavier: TextInputAction.next,
            remplissage: const <String>[AutofillHints.givenName],
            lectureSeule: envoi,
          ),
          Ecart.vLg,
          ChampEtiquete(
            libelle: t.inscription.nom,
            obligatoire: true,
            cleChamp: const ValueKey<String>('associe-nom'),
            controller: _nom,
            textCapitalization: TextCapitalization.words,
            actionClavier: TextInputAction.done,
            remplissage: const <String>[AutofillHints.familyName],
            lectureSeule: envoi,
          ),
          Ecart.vXl,
          Text(r.genreQuestion, style: Theme.of(context).textTheme.titleMedium),
          Ecart.vSm,
          Text(r.genreRaison, style: doux),
          Ecart.vMd,
          ChoiceCardGroup(
            key: const ValueKey<String>('associe-genre'),
            autoriserSaisieLibre: false,
            coteACote: true,
            valeurInitiale: _genre == null
                ? null
                : ReponseChoix(valeurs: <String>{_genre!.name}),
            onChange: (ReponseChoix reponse) {
              final String? v = reponse.valeurs.isEmpty
                  ? null
                  : reponse.valeurs.first;
              setState(() {
                _genre = v == Genre.homme.name
                    ? Genre.homme
                    : v == Genre.femme.name
                    ? Genre.femme
                    : null;
                if (_echec == _Echec.champsManquants) _echec = null;
              });
            },
            options: <OptionChoix>[
              OptionChoix(
                valeur: Genre.homme.name,
                libelle: t.inscription.genreHomme,
                explication: r.genreHommeExplication,
                icone: AppIcons.homme,
              ),
              OptionChoix(
                valeur: Genre.femme.name,
                libelle: t.inscription.genreFemme,
                explication: r.genreFemmeExplication,
                icone: AppIcons.femme,
              ),
            ],
          ),
          _message(horsLigne ? r.horsLigne : _phrase(_echec)),
          Ecart.vLg,
          if (!horsLigne)
            _bouton(
              cle: AssociePage.cleCreer,
              libelle: r.creer,
              enCours: envoi,
              surAppui: () => unawaited(_creer()),
            ),
          Ecart.vSm,
          Center(
            child: LienFleche(
              key: const ValueKey<String>('associe-ressaisir'),
              libelle: r.ressaisir,
              onPress: envoi ? null : _ressaisir,
            ),
          ),
        ],
      ),
    );
  }
}

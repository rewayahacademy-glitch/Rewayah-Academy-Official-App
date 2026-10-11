import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_partage_pedagogique.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart' show horsLigneProvider;
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../suivi_foyer/filtres_historique.dart' show dateCourte, heureMinute;
import 'apercu_familial.dart';
import 'partage_commun.dart';

/// Le reglage de partage d'une classe (page 1 de ses eleves).
///
/// **`autoDispose` et lie a la session** : la valeur affichee est celle que le
/// serveur vient de rendre, jamais une copie gardee d'un autre compte.
final partageClasseProvider = FutureProvider.autoDispose
    .family<PartageClasse, String>((Ref ref, String classeId) {
      ref.watch(sessionProvider.select((s) => (s.profileId, s.role)));
      return ref
          .watch(portPartagePedagogiqueProvider)
          .partageClasse(classeId: classeId);
    });

/// ADM-PED-APR-02 : le groupe « Partage des comptes rendus pedagogiques » de
/// la fiche d'une classe (inspecteur de bureau et feuille de detail mobile : le
/// meme widget).
///
/// **Aucune fausse bascule.** L'interrupteur montre la valeur que le serveur a
/// rendue ; il ne change qu'apres confirmation et relecture. Pendant l'envoi il
/// est inerte (un seul envoi a la fois). Un conflit relit la valeur a jour et
/// le dit. Sans source, le groupe dit « Le reglage de partage n'est pas encore
/// disponible. » et ne pose aucun interrupteur.
class GroupePartageClasse extends ConsumerStatefulWidget {
  /// Cree le groupe.
  const GroupePartageClasse({
    required this.classeId,
    required this.nomClasse,
    super.key,
  });

  /// La classe.
  final String classeId;

  /// Son nom, pour les titres des feuilles.
  final String nomClasse;

  @override
  ConsumerState<GroupePartageClasse> createState() =>
      _GroupePartageClasseEtat();
}

class _GroupePartageClasseEtat extends ConsumerState<GroupePartageClasse> {
  bool _envoi = false;
  String? _retour;
  bool _retourDefinitif = false;
  int _essai = 0;

  void _dire(String message, {required bool definitif}) {
    setState(() {
      _retour = message;
      _retourDefinitif = definitif;
      _essai++;
    });
  }

  Future<void> _basculer(PartageClasse lu, bool actif) async {
    if (_envoi) {
      return;
    }
    final l = t.admin.groupes.partage;
    if (ref.read(horsLigneProvider).value ?? false) {
      _dire(l.horsLigne, definitif: true);
      return;
    }
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: actif ? l.confirmerActiver : l.confirmerDesactiver,
      consequence: actif ? l.consequenceActiver : l.consequenceDesactiver,
      libelleConfirmer: l.enregistrer,
    );
    if (!confirme || !mounted || _envoi) {
      return;
    }
    setState(() {
      _envoi = true;
      _retour = null;
    });
    ResultatPartage resultat = ResultatPartage.ok;
    try {
      await ref
          .read(portPartagePedagogiqueProvider)
          .definirPartageClasse(
            classeId: widget.classeId,
            actif: actif,
            versionAttendue: lu.version,
            cleIdempotence: nouvelleCleGeste(),
          );
    } on Object catch (erreur) {
      resultat = resultatDe(erreur);
    }
    if (!mounted) {
      return;
    }
    // Dans tous les cas, on relit : la valeur affichee est celle du serveur.
    ref.invalidate(partageClasseProvider(widget.classeId));
    setState(() => _envoi = false);
    final String? phrase = phraseDe(resultat);
    if (phrase == null) {
      _dire(l.confirme, definitif: false);
    } else {
      _dire(phrase, definitif: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = t.admin.groupes.partage;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final AsyncValue<PartageClasse> lecture = ref.watch(
      partageClasseProvider(widget.classeId),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    Widget titre() => Semantics(
      header: true,
      child: Text(l.titre, style: textes.titleMedium),
    );
    Widget phrase(String texte) =>
        Text(texte, style: palette.inkMuted.applyTo(textes.bodyMedium!));

    final Widget corps;
    if (lecture.hasValue && !lecture.hasError) {
      final PartageClasse p = lecture.requireValue;
      final String? modif = _modification(p);
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GroupeReglages(
            lignes: <LigneRubrique>[
              LigneRubrique(
                libelle: l.interrupteur,
                legende: l.aide,
                pastille: StatusPill(
                  libelle: p.actif ? l.etatActif : l.etatInactif,
                  ton: p.actif ? TonEtat.succes : TonEtat.neutre,
                ),
                controle: Switch.adaptive(
                  value: p.actif,
                  onChanged: _envoi || horsLigne
                      ? null
                      : (bool actif) => _basculer(p, actif),
                ),
              ),
            ],
          ),
          Ecart.vMd,
          phrase(l.priorite),
          if (modif != null) ...<Widget>[Ecart.vXs, phrase(modif)],
          if (_envoi) ...<Widget>[Ecart.vSm, phrase(l.enregistrement)],
          if (horsLigne) ...<Widget>[Ecart.vSm, phrase(l.horsLigne)],
          Ecart.vSm,
          if (p.total == 0)
            phrase(l.classeVide)
          else
            LienFleche(
              libelle: l.gererExceptions,
              alignerEnDebut: true,
              onPress: () => _ouvrirExceptions(context),
            ),
          Ecart.vSm,
          LocalFeedback(
            key: ValueKey<int>(_essai),
            message: _retour,
            persistant: _retourDefinitif,
          ),
        ],
      );
    } else if (lecture.hasError) {
      final Object erreur = lecture.error!;
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          phrase(switch (erreur) {
            CapaciteIndisponible() => l.indisponible,
            PermissionInsuffisante() => l.refuse,
            _ => horsLigne ? l.horsLigne : l.illisible,
          }),
          if (erreur is! CapaciteIndisponible &&
              erreur is! PermissionInsuffisante) ...<Widget>[
            Ecart.vSm,
            LienFleche(
              libelle: t.commun.reessayer,
              alignerEnDebut: true,
              onPress: () =>
                  ref.invalidate(partageClasseProvider(widget.classeId)),
            ),
          ],
        ],
      );
    } else {
      corps = const Skeleton.liste(lignes: 2);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[titre(), Ecart.vMd, corps],
    );
  }

  String? _modification(PartageClasse p) {
    final DateTime? quand = p.modifieLe;
    if (quand == null) {
      return null;
    }
    final l = t.admin.groupes.partage;
    final String date = '${dateCourte(quand)} ${heureMinute(quand)}';
    final String? qui = p.modifiePar;
    return qui == null
        ? l.modifieLe(date: date)
        : l.modifiePar(date: date, auteur: qui);
  }

  void _ouvrirExceptions(BuildContext context) {
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.admin.groupes.partage.exceptionsTitre,
      constructeur: (BuildContext contexte) => FeuilleExceptionsPartage(
        classeId: widget.classeId,
        nomClasse: widget.nomClasse,
        onModifie: () => ref.invalidate(partageClasseProvider(widget.classeId)),
      ),
    );
  }
}

/// La liste des eleves d'une classe avec leur regle de partage (exceptions
/// individuelles), en feuille dans le contexte de la classe : **jamais un
/// niveau 1 de navigation**.
///
/// **Aucune copie de la classe** : le serveur pagine (page de N eleves, recherche
/// cote serveur), la feuille accumule par identifiant. Une page relue remplace
/// les lignes de meme identifiant, jamais ne les double.
class FeuilleExceptionsPartage extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleExceptionsPartage({
    required this.classeId,
    required this.nomClasse,
    required this.onModifie,
    super.key,
  });

  /// La classe.
  final String classeId;

  /// Son nom.
  final String nomClasse;

  /// Appele quand une regle d'eleve a change (le groupe de la fiche relit).
  final VoidCallback onModifie;

  @override
  ConsumerState<FeuilleExceptionsPartage> createState() =>
      _FeuilleExceptionsPartageEtat();
}

class _FeuilleExceptionsPartageEtat
    extends ConsumerState<FeuilleExceptionsPartage> {
  final TextEditingController _recherche = TextEditingController();
  final Map<String, PartageEleve> _eleves = <String, PartageEleve>{};
  Timer? _attente;
  Object? _erreur;
  bool _chargement = true;
  bool _plus = false;
  int _page = 1;
  int _total = 0;
  String _version = '';
  String? _retour;
  int _essai = 0;

  /// Le delai entre la derniere frappe et la requete : pas un mouvement.
  static const Duration _delaiSaisie = Duration(
    microseconds: 300 * Duration.microsecondsPerMillisecond,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_lire());
  }

  @override
  void dispose() {
    _attente?.cancel();
    _recherche.dispose();
    super.dispose();
  }

  void _chercher(String _) {
    _attente?.cancel();
    _attente = Timer(_delaiSaisie, () {
      if (mounted) {
        unawaited(_lire());
      }
    });
  }

  /// Lit la page 1 (nouvelle recherche, ou relecture apres une ecriture).
  Future<void> _lire() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final PartageClasse p = await ref
          .read(portPartagePedagogiqueProvider)
          .partageClasse(
            classeId: widget.classeId,
            recherche: _recherche.text.trim().isEmpty ? null : _recherche.text,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _eleves
          ..clear()
          ..addEntries(
            p.eleves.map((PartageEleve e) => MapEntry(e.eleveId, e)),
          );
        _total = p.total;
        _version = p.version;
        _page = 1;
        _chargement = false;
      });
    } on Object catch (erreur) {
      if (mounted) {
        setState(() {
          _erreur = erreur;
          _chargement = false;
        });
      }
    }
  }

  Future<void> _lirePlus() async {
    if (_plus) {
      return;
    }
    setState(() => _plus = true);
    try {
      final PartageClasse p = await ref
          .read(portPartagePedagogiqueProvider)
          .partageClasse(
            classeId: widget.classeId,
            page: _page + 1,
            recherche: _recherche.text.trim().isEmpty ? null : _recherche.text,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        for (final PartageEleve e in p.eleves) {
          _eleves[e.eleveId] = e;
        }
        _page++;
        _version = p.version;
        _plus = false;
      });
    } on Object {
      if (mounted) {
        setState(() {
          _plus = false;
          _retour = t.admin.groupes.partage.echec;
          _essai++;
        });
      }
    }
  }

  /// L'ecriture d'une regle d'eleve : un seul envoi, la valeur a jour relue
  /// ensuite quoi qu'il arrive.
  Future<ResultatPartage> _definir(
    PartageEleve eleve,
    ReglePartageEleve regle,
  ) async {
    if (ref.read(horsLigneProvider).value ?? false) {
      return ResultatPartage.horsLigne;
    }
    ResultatPartage resultat = ResultatPartage.ok;
    try {
      await ref
          .read(portPartagePedagogiqueProvider)
          .definirRegleEleve(
            classeId: widget.classeId,
            eleveId: eleve.eleveId,
            regle: regle,
            versionAttendue: _version,
            cleIdempotence: nouvelleCleGeste(),
          );
    } on Object catch (erreur) {
      resultat = resultatDe(erreur);
    }
    if (mounted &&
        (resultat == ResultatPartage.ok ||
            resultat == ResultatPartage.conflit)) {
      widget.onModifie();
      await _lire();
      if (mounted) {
        setState(() {
          _retour = resultat == ResultatPartage.ok
              ? t.admin.groupes.partage.confirme
              : t.admin.groupes.partage.conflit;
          _essai++;
        });
      }
    }
    return resultat;
  }

  void _ouvrirEleve(PartageEleve eleve) {
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.admin.groupes.partage.modifierEleve(prenom: eleve.libelle),
      constructeur: (BuildContext contexte) => FeuilleRegleEleve(
        classeId: widget.classeId,
        eleve: eleve,
        onValider: (ReglePartageEleve regle) => _definir(eleve, regle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = t.admin.groupes.partage;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    Widget phrase(String texte) =>
        Text(texte, style: palette.inkMuted.applyTo(textes.bodyMedium!));

    final List<Widget> corps;
    if (_chargement && _eleves.isEmpty) {
      corps = const <Widget>[Skeleton.liste(lignes: 4)];
    } else if (_erreur != null) {
      final Object erreur = _erreur!;
      corps = <Widget>[
        phrase(switch (erreur) {
          CapaciteIndisponible() => l.indisponible,
          PermissionInsuffisante() => l.refuse,
          _ => horsLigne ? l.horsLigne : l.illisible,
        }),
        if (erreur is! CapaciteIndisponible &&
            erreur is! PermissionInsuffisante) ...<Widget>[
          Ecart.vSm,
          LienFleche(
            libelle: t.commun.reessayer,
            alignerEnDebut: true,
            onPress: () => unawaited(_lire()),
          ),
        ],
      ];
    } else if (_eleves.isEmpty) {
      corps = <Widget>[phrase(l.classeVide)];
    } else {
      corps = <Widget>[
        GroupeReglages(
          lignes: <LigneRubrique>[
            for (final PartageEleve e in _eleves.values) _ligne(e),
          ],
        ),
        if (_eleves.length < _total) ...<Widget>[
          Ecart.vMd,
          LienFleche(
            libelle: l.plusEleves,
            alignerEnDebut: true,
            onPress: _plus ? () {} : () => unawaited(_lirePlus()),
          ),
        ],
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        phrase(l.exceptionsAide),
        Ecart.vMd,
        phrase(l.priorite),
        Ecart.vLg,
        ChampRecherche(
          cleChamp: const ValueKey<String>('partage-recherche-eleve'),
          controleur: _recherche,
          libelle: l.rechercheEleve,
          aide: l.rechercheEleve,
          onChange: _chercher,
        ),
        Ecart.vLg,
        ...corps,
        Ecart.vMd,
        LocalFeedback(
          key: ValueKey<int>(_essai),
          message: _retour,
          persistant: _retour == l.conflit,
        ),
      ],
    );
  }

  LigneRubrique _ligne(PartageEleve e) {
    final l = t.admin.groupes.partage;
    final bool retire = e.situation == SituationEleveClasse.retire;
    final String source = switch (e.source) {
      SourceRegle.exceptionEleve => l.sourceException,
      SourceRegle.classe => l.sourceClasse,
      SourceRegle.defaut => l.sourceDefaut,
    };
    final DateTime? quand = e.modifieLe;
    final String? modif = quand == null
        ? null
        : (e.modifiePar == null
              ? l.modifieLe(date: '${dateCourte(quand)} ${heureMinute(quand)}')
              : l.modifiePar(
                  date: '${dateCourte(quand)} ${heureMinute(quand)}',
                  auteur: e.modifiePar!,
                ));
    final String legende = <String>[
      if (retire) l.eleveRetire else source,
      ?modif,
    ].join(' · ');
    final Widget pastille = StatusPill(
      libelle: e.visible ? l.visible : l.nonVisible,
      ton: e.visible ? TonEtat.succes : TonEtat.neutre,
    );
    // Un eleve retire ou transfere : sa ligne se lit, aucune modification
    // n'est proposee (pas de geste qui ne peut pas aboutir).
    if (retire) {
      return LigneRubrique(
        libelle: e.libelle,
        legende: legende,
        pastille: pastille,
      );
    }
    return LigneRubrique(
      libelle: e.libelle,
      legende: legende,
      pastille: pastille,
      libelleSemantique: l.modifierEleve(prenom: e.libelle),
      onPress: () => _ouvrirEleve(e),
    );
  }
}

/// La regle d'**un** eleve, en feuille : un choix unique parmi trois, la portee
/// et la consequence dites avant d'enregistrer (K-58), et l'acces aux comptes
/// rendus de cet eleve (point d'entree provisoire d'ADM-PED-APR-03).
class FeuilleRegleEleve extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleRegleEleve({
    required this.classeId,
    required this.eleve,
    required this.onValider,
    super.key,
  });

  /// La classe.
  final String classeId;

  /// L'eleve.
  final PartageEleve eleve;

  /// Enregistre la regle choisie, et rend ce que le serveur a repondu.
  final Future<ResultatPartage> Function(ReglePartageEleve regle) onValider;

  @override
  ConsumerState<FeuilleRegleEleve> createState() => _FeuilleRegleEleveEtat();
}

class _FeuilleRegleEleveEtat extends ConsumerState<FeuilleRegleEleve> {
  late ReglePartageEleve _regle = widget.eleve.regle;
  bool _envoi = false;
  String? _retour;
  int _essai = 0;

  Future<void> _enregistrer() async {
    if (_envoi) {
      return;
    }
    if (_regle == widget.eleve.regle) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _envoi = true;
      _retour = null;
    });
    final ResultatPartage resultat = await widget.onValider(_regle);
    if (!mounted) {
      return;
    }
    setState(() => _envoi = false);
    if (resultat == ResultatPartage.ok || resultat == ResultatPartage.conflit) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _retour = phraseDe(resultat);
      _essai++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = t.admin.groupes.partage;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String consequence = _regle == ReglePartageEleve.jamais
        ? '${l.consequenceEleve} ${l.consequenceEleveJamais}'
        : l.consequenceEleve;
    final String valeurInitiale = switch (widget.eleve.regle) {
      ReglePartageEleve.regleClasse => 'classe',
      ReglePartageEleve.toujours => 'toujours',
      ReglePartageEleve.jamais => 'jamais',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(valeurs: <String>{valeurInitiale}),
          options: <OptionChoix>[
            OptionChoix(
              valeur: 'classe',
              libelle: l.regleClasse,
              description: l.regleClasseAide,
            ),
            OptionChoix(
              valeur: 'toujours',
              libelle: l.regleToujours,
              description: l.regleToujoursAide,
            ),
            OptionChoix(
              valeur: 'jamais',
              libelle: l.regleJamais,
              description: l.regleJamaisAide,
            ),
          ],
          onChange: (ReponseChoix r) {
            final String? v = r.valeurs.firstOrNull;
            setState(() {
              _regle = switch (v) {
                'toujours' => ReglePartageEleve.toujours,
                'jamais' => ReglePartageEleve.jamais,
                _ => ReglePartageEleve.regleClasse,
              };
            });
          },
        ),
        Ecart.vLg,
        Text(consequence, style: palette.inkMuted.applyTo(textes.bodyMedium!)),
        Ecart.vLg,
        ActionPrincipale(
          libelle: l.enregistrer,
          enCours: _envoi,
          onPress: _enregistrer,
        ),
        Ecart.vMd,
        LienFleche(
          libelle: l.comptesRendus,
          alignerEnDebut: true,
          onPress: () => ouvrirComptesRendusEleve(
            context,
            classeId: widget.classeId,
            eleveId: widget.eleve.eleveId,
            prenom: widget.eleve.libelle,
          ),
        ),
        Ecart.vSm,
        LocalFeedback(
          key: ValueKey<int>(_essai),
          message: _retour,
          persistant: true,
        ),
      ],
    );
  }
}

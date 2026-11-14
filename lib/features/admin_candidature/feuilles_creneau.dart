/// SALLE-2-ENTRETIEN (07/11/2026) : les feuilles de la page des creneaux,
/// « Ouvrir un creneau » et « Retirer ce creneau ». Les refus du serveur sont
/// dits avec les mots de l'entretien quand il les connait deja.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/creneaux_direction.dart';
import '../../core/candidature/modeles_entretien_direction.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/champ_date.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart' show TonEtat;
import '../candidature/entretien_creneaux.dart' show horaireEntretien;
import '../candidature/libelles_parcours.dart' show nomDeLangue;
import 'bloc_entretien.dart'
    show dureesEntretien, heuresEntretien, messageRefusEntretien;

/// Le message d'un refus d'ouverture ou de retrait.
String messageRefusCreneau(Object refus) {
  final c = t.admin.candidatures.creneaux;
  if (refus is RefusCreneau) {
    return switch (refus.code) {
      'creneau_reserve' => c.refusReserve,
      'absente' => c.refusAbsent,
      'langues_invalides' => c.refusLangues,
      'hors_portee' => c.refusHorsPortee,
      'plage_trop_courte' => c.refusPlageCourte,
      'plage_trop_longue' => c.refusPlageLongue,
      _ => t.admin.candidatures.erreurs.generique,
    };
  }
  return messageRefusEntretien(refus);
}

/// L'envoi commun des deux feuilles : un seul a la fois, le refus garde.
mixin _EnvoiCreneau<W extends ConsumerStatefulWidget> on ConsumerState<W> {
  bool enCours = false;
  bool tente = false;
  Object? refus;

  Future<void> envoyer(
    Future<String> Function(PortCreneauxDirection port) geste,
    ValueChanged<String> fini,
  ) async {
    if (enCours) return;
    final PortCreneauxDirection? port = ref.read(portCreneauxDirectionProvider);
    setState(() {
      enCours = true;
      refus = null;
    });
    try {
      if (port == null) throw const CapaciteIndisponible(dependanceCreneaux);
      final String m = await geste(port);
      if (mounted) fini(m);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          enCours = false;
          refus = e;
        });
      }
    }
  }

  List<Widget> bandeauRefus() {
    final Object? r = refus;
    if (r == null) return const <Widget>[];
    return <Widget>[
      Ecart.vLg,
      BandeauAttention(
        key: const ValueKey<String>('creneau-refus'),
        titre: t.admin.candidatures.erreurs.titre,
        message: messageRefusCreneau(r),
        ton: TonEtat.alerte,
      ),
    ];
  }

  List<Widget> boutons({
    required Key cle,
    required String libelle,
    required VoidCallback onEnvoyer,
    required VoidCallback onAnnuler,
    bool destructif = false,
  }) => <Widget>[
    Ecart.vXxl,
    ActionPrincipale(
      key: cle,
      libelle: libelle,
      onPress: onEnvoyer,
      enCours: enCours,
      niveau: destructif ? NiveauAction.destructive : NiveauAction.principale,
    ),
    Ecart.vMd,
    ActionPrincipale(
      libelle: t.commun.annuler,
      onPress: onAnnuler,
      niveau: NiveauAction.secondaire,
    ),
  ];

  Widget muet(String texte) => TexteSansCoupure(
    texte,
    style: AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
  );

  Widget erreurChamp(String texte) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: Semantics(
      liveRegion: true,
      child: TexteSansCoupure(
        texte,
        style: AppPalette.of(context).inkAlert.applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      ),
    ),
  );

  Widget titreChamp(String texte) => Semantics(
    header: true,
    child: TexteSansCoupure(
      texte,
      style: Theme.of(context).textTheme.titleMedium,
    ),
  );
}

/// La feuille « Ouvrir un creneau ».
class FeuilleOuvrirCreneau extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleOuvrirCreneau({
    required this.onFini,
    required this.onAnnuler,
    super.key,
  });

  /// Le creneau est ouvert : le message du retour local.
  final ValueChanged<String> onFini;

  /// La personne renonce.
  final VoidCallback onAnnuler;

  /// Le bouton d'envoi.
  static const Key envoyerKey = ValueKey<String>('creneau-envoyer');

  @override
  ConsumerState<FeuilleOuvrirCreneau> createState() => _EtatOuvrir();
}

class _EtatOuvrir extends ConsumerState<FeuilleOuvrirCreneau>
    with _EnvoiCreneau<FeuilleOuvrirCreneau> {
  String? _cote;
  DateTime? _jour;
  int? _heure;
  int _duree = 45;

  /// SALLE2-ENTRETIEN : la fin de la plage, en minutes depuis minuit, ou
  /// [_unSeul] pour un seul entretien.
  int _fin = _unSeul;
  static const int _unSeul = -1;
  final Set<String> _langues = <String>{};
  List<String> _ordre = const <String>[];
  final Set<String> _choisis = <String>{};

  bool get _complet =>
      _cote != null &&
      _jour != null &&
      _heure != null &&
      _langues.isNotEmpty &&
      _choisis.isNotEmpty;

  void _modifie(VoidCallback changement) => setState(() {
    changement();
    refus = null;
  });

  Future<void> _valider() async {
    if (!_complet) {
      setState(() => tente = true);
      return;
    }
    final DateTime j = _jour!;
    // HEURES-PROFIL H3 (12/11/2026) : le jour et l'heure choisis sont ceux du
    // fuseau du PROFIL ; l'instant envoye en est l'inverse exact.
    final DateTime debut = instantChezMoi(
      j.year,
      j.month,
      j.day,
      _heure! ~/ 60,
      _heure! % 60,
    );
    final DateTime? finPlage = _fin == _unSeul || _fin <= _heure!
        ? null
        : instantChezMoi(j.year, j.month, j.day, _fin ~/ 60, _fin % 60);
    await envoyer((PortCreneauxDirection port) async {
      await port.ouvrir(
        cote: _cote!,
        debut: debut,
        dureeMinutes: _duree,
        langues: <String>[
          for (final String l in _ordre)
            if (_langues.contains(l)) l,
        ],
        participants: <String>[..._choisis],
        finPlage: finPlage,
      );
      return finPlage == null
          ? t.admin.candidatures.creneaux.ouvert
          : t.admin.candidatures.creneaux.plagePubliee;
    }, widget.onFini);
  }

  @override
  Widget build(BuildContext context) {
    final c = t.admin.candidatures.creneaux;
    final e = t.admin.candidatures.entretien;
    final f = e.feuille;
    // Aujourd'hui au fuseau du profil (HEURES-PROFIL H3).
    final DateTime maintenant = chezMoi(ref.read(horlogeFormulairesProvider)());
    final DateTime aujourdhui = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );
    final AsyncValue<List<PersonnelEntretien>> personnel = ref.watch(
      personnelCreneauProvider,
    );
    final List<PersonnelEntretien> liste =
        personnel.value ?? const <PersonnelEntretien>[];
    final AsyncValue<List<String>> langues = ref.watch(languesCreneauProvider);
    _ordre = langues.value ?? const <String>[];
    return Column(
      key: const ValueKey<String>('feuille-ouvrir-creneau'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          c.ouvrirConsequence,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Ecart.vLg,
        titreChamp(c.cote),
        Ecart.vSm,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            OptionChoix(
              cle: const ValueKey<String>('creneau-cote-male'),
              valeur: 'male',
              libelle: c.coteHommes,
            ),
            OptionChoix(
              cle: const ValueKey<String>('creneau-cote-female'),
              valeur: 'female',
              libelle: c.coteFemmes,
            ),
          ],
          valeurInitiale: _cote == null
              ? null
              : ReponseChoix(valeurs: <String>{_cote!}),
          onChange: (ReponseChoix r) => _modifie(
            () => _cote = r.valeurs.isEmpty ? null : r.valeurs.first,
          ),
        ),
        if (tente && _cote == null) erreurChamp(c.coteManquant),
        Ecart.vLg,
        ChampDate(
          libelle: t.admin.groupes.formulaire.jour,
          valeur: _jour,
          aujourdhui: aujourdhui,
          dernier: DateTime(
            aujourdhui.year,
            aujourdhui.month,
            aujourdhui.day + 89,
          ),
          aide: f.jourAide,
          onChoix: (DateTime j) => _modifie(() => _jour = j),
        ),
        if (tente && _jour == null) erreurChamp(f.jourManquant),
        Ecart.vLg,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MenuFiltre<int>(
            key: const ValueKey<String>('creneau-heure'),
            libelle: t.admin.groupes.formulaire.heure,
            valeur: _heure,
            entrees: <EntreeFiltre<int>>[
              for (final int m in heuresEntretien)
                EntreeFiltre<int>(
                  valeur: m,
                  libelle: heureDeLAppareil(
                    DateTime(2000, 1, 1, m ~/ 60, m % 60),
                  ),
                ),
            ],
            onChoix: (int? m) {
              if (m != null) {
                _modifie(() {
                  _heure = m;
                  _fin = _unSeul;
                });
              }
            },
          ),
        ),
        if (tente && _heure == null) erreurChamp(f.heureManquante),
        Ecart.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MenuFiltre<int>(
            key: const ValueKey<String>('creneau-duree'),
            libelle: t.admin.groupes.formulaire.duree,
            valeur: _duree,
            entrees: <EntreeFiltre<int>>[
              for (final int d in dureesEntretien)
                EntreeFiltre<int>(
                  valeur: d,
                  libelle: LibellesGroupe.insecable(
                    t.admin.regles.uniteMinutes(n: '$d'),
                  ),
                ),
            ],
            onChoix: (int? d) {
              if (d != null) {
                _modifie(() {
                  _duree = d;
                  _fin = _unSeul;
                });
              }
            },
          ),
        ),
        // SALLE2-ENTRETIEN (directeur, 14/11/2026) : la direction publie une
        // plage, le candidat choisit lui-meme un moment dedans.
        Ecart.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MenuFiltre<int>(
            key: const ValueKey<String>('creneau-fin-plage'),
            libelle: c.finPlage,
            valeur: _fin,
            entrees: <EntreeFiltre<int>>[
              EntreeFiltre<int>(valeur: _unSeul, libelle: c.unSeulMoment),
              for (final int m in heuresEntretien)
                if (_heure != null && m >= _heure! + _duree * 2)
                  EntreeFiltre<int>(
                    valeur: m,
                    libelle: heureDeLAppareil(
                      DateTime(2000, 1, 1, m ~/ 60, m % 60),
                    ),
                  ),
            ],
            onChoix: (int? m) {
              if (m != null) _modifie(() => _fin = m);
            },
          ),
        ),
        Ecart.vXs,
        muet(c.finPlageAide),
        Ecart.vLg,
        titreChamp(c.langues),
        Ecart.vXs,
        muet(c.languesAide),
        Ecart.vSm,
        if (!langues.hasValue)
          langues.hasError
              ? EtatSysteme(
                  key: const ValueKey<String>('creneau-langues-echec'),
                  nature: NatureEtat.echecServeur,
                  phrase: c.languesEchec,
                  onAction: () => ref.invalidate(languesCreneauProvider),
                )
              : const Skeleton.liste(lignes: 2)
        else
          ChoiceCardGroup(
            autoriserSaisieLibre: false,
            selectionMultiple: true,
            options: <OptionChoix>[
              for (final String l in _ordre)
                OptionChoix(
                  cle: ValueKey<String>('creneau-langue-$l'),
                  valeur: l,
                  libelle: nomDeLangue(l) ?? l,
                ),
            ],
            valeurInitiale: ReponseChoix(valeurs: Set<String>.of(_langues)),
            onChange: (ReponseChoix r) => _modifie(() {
              _langues
                ..clear()
                ..addAll(r.valeurs);
            }),
          ),
        if (tente && _langues.isEmpty) erreurChamp(c.languesManquantes),
        Ecart.vLg,
        titreChamp(t.com.messages.panneau.participants),
        Ecart.vXs,
        muet(f.participantsAide),
        Ecart.vSm,
        if (!personnel.hasValue)
          personnel.hasError
              ? EtatSysteme(
                  key: const ValueKey<String>('creneau-personnel-echec'),
                  nature: NatureEtat.echecServeur,
                  phrase: f.personnelEchec,
                  onAction: () => ref.invalidate(personnelCreneauProvider),
                )
              : const Skeleton.liste(lignes: 2)
        else if (liste.isEmpty)
          muet(f.personnelVide)
        else ...<Widget>[
          ChoiceCardGroup(
            selectionMultiple: true,
            autoriserSaisieLibre: false,
            options: <OptionChoix>[
              for (final PersonnelEntretien p in liste)
                OptionChoix(
                  cle: ValueKey<String>('creneau-personnel-${p.profilId}'),
                  valeur: p.profilId,
                  libelle: p.nomComplet,
                  description: p.fondateur ? e.fondateur : null,
                ),
            ],
            valeurInitiale: ReponseChoix(valeurs: Set<String>.of(_choisis)),
            onChange: (ReponseChoix r) => _modifie(() {
              _choisis
                ..clear()
                ..addAll(r.valeurs);
            }),
          ),
          if (tente && _choisis.isEmpty) erreurChamp(f.participantsManquants),
        ],
        ...bandeauRefus(),
        ...boutons(
          cle: FeuilleOuvrirCreneau.envoyerKey,
          libelle: c.envoyer,
          onEnvoyer: () => unawaited(_valider()),
          onAnnuler: widget.onAnnuler,
        ),
      ],
    );
  }
}

/// La feuille « Retirer ce creneau ».
class FeuilleRetirerCreneau extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleRetirerCreneau({
    required this.creneau,
    required this.onFini,
    required this.onAnnuler,
    super.key,
  });

  /// Le creneau a retirer.
  final CreneauDirection creneau;

  /// Le creneau est retire : le message du retour local.
  final ValueChanged<String> onFini;

  /// La personne renonce.
  final VoidCallback onAnnuler;

  /// Le bouton d'envoi.
  static const Key envoyerKey = ValueKey<String>('creneau-retirer-envoyer');

  @override
  ConsumerState<FeuilleRetirerCreneau> createState() => _EtatRetirer();
}

class _EtatRetirer extends ConsumerState<FeuilleRetirerCreneau>
    with _EnvoiCreneau<FeuilleRetirerCreneau> {
  @override
  Widget build(BuildContext context) {
    final c = t.admin.candidatures.creneaux;
    return Column(
      key: const ValueKey<String>('feuille-retirer-creneau'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          horaireEntretien(widget.creneau.debut, widget.creneau.fin),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Ecart.vSm,
        TexteSansCoupure(
          c.retirerConsequence,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        ...bandeauRefus(),
        ...boutons(
          cle: FeuilleRetirerCreneau.envoyerKey,
          libelle: c.retirerEnvoyer,
          destructif: true,
          onEnvoyer: () => unawaited(
            envoyer((PortCreneauxDirection port) async {
              await port.annuler(widget.creneau.id);
              return c.retireFait;
            }, widget.onFini),
          ),
          onAnnuler: widget.onAnnuler,
        ),
      ],
    );
  }
}

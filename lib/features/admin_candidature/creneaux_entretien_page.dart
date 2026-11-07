/// SALLE-2-ENTRETIEN (07/11/2026) : les creneaux d'entretien de la direction,
/// `/admin/personnes/candidatures/creneaux`, sur V1-b (en production, jamais
/// appele jusqu'ici) : la liste des 30 prochains jours, « Ouvrir un
/// creneau », « Retirer ce creneau » (un creneau libre).
///
/// Le serveur decide de tout : la portee de genre, la regle des fondateurs,
/// les bornes du debut et de la duree, les langues. Ses refus sont dits avec
/// les mots de l'entretien quand il les connait deja.
///
/// La page defile seule (DECISION-DEFILEMENT) : aucune liste dans un cadre de
/// hauteur fixe.
///
/// Etats : chargement (squelette), contenu, vide (« Ouvrir un creneau »),
/// erreur (« Reessayer »), hors ligne (la derniere lecture reste ; rien lu :
/// le bloc de ce qui manque ; aucun geste), capacite indisponible, acces
/// refuse.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/creneaux_direction.dart';
import '../../core/candidature/modeles_entretien_direction.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/champ_date.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
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
      _ => t.admin.candidatures.erreurs.generique,
    };
  }
  return messageRefusEntretien(refus);
}

/// La page des creneaux.
class CreneauxEntretienPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const CreneauxEntretienPage({super.key});

  /// La cle de la page.
  static const Key clePage = ValueKey<String>('creneaux-page');

  /// « Ouvrir un creneau ».
  static const Key ouvrirKey = ValueKey<String>('creneaux-ouvrir');

  @override
  ConsumerState<CreneauxEntretienPage> createState() => _EtatPage();
}

class _EtatPage extends ConsumerState<CreneauxEntretienPage> {
  String? _retour;

  void _fait(String? m) {
    if (m == null || !mounted) return;
    ref.invalidate(creneauxDirectionProvider);
    setState(() => _retour = m);
  }

  Future<void> _ouvrir() async => _fait(
    await AppBottomSheet.ouvrir<String>(
      context,
      titre: t.admin.candidatures.creneaux.ouvrir,
      constructeur: (BuildContext contexte) => FeuilleOuvrirCreneau(
        onFini: (String m) => Navigator.of(contexte).pop(m),
        onAnnuler: () => Navigator.of(contexte).pop(),
      ),
    ),
  );

  Future<void> _retirer(CreneauDirection c) async => _fait(
    await AppBottomSheet.ouvrir<String>(
      context,
      titre: t.admin.candidatures.creneaux.retirer,
      constructeur: (BuildContext contexte) => FeuilleRetirerCreneau(
        creneau: c,
        onFini: (String m) => Navigator.of(contexte).pop(m),
        onAnnuler: () => Navigator.of(contexte).pop(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = t.admin.candidatures.creneaux;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<List<CreneauDirection>> lecture = ref.watch(
      creneauxDirectionProvider,
    );
    final bool gestes = !horsLigne && lecture.hasValue;
    return PageShell(
      key: CreneauxEntretienPage.clePage,
      titre: c.titre,
      onRetour: () =>
          GoRouter.of(context).go(Routes.adminPersonnesCandidatures),
      // Une colonne de lecture (garde bureau B4) : les cartes et les
      // phrases ne s'etirent pas sur toute la largeur d'un ordinateur.
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // L'explication defile avec la liste (garde bureau B6 : la tete
              // fixe reste courte).
              TexteSansCoupure(
                c.intro,
                style: AppPalette.of(context).inkMuted.applyTo(
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                ),
              ),
              Ecart.vLg,
              if (_retour != null) ...<Widget>[
                LocalFeedback(
                  key: const ValueKey<String>('creneaux-retour'),
                  message: _retour!,
                ),
                Ecart.vLg,
              ],
              if (gestes && (lecture.value?.isNotEmpty ?? false)) ...<Widget>[
                ActionPrincipale(
                  key: CreneauxEntretienPage.ouvrirKey,
                  libelle: c.ouvrir,
                  onPress: () => unawaited(_ouvrir()),
                ),
                Ecart.vLg,
              ],
              BlocAsynchrone<List<CreneauDirection>>(
                key: const ValueKey<String>('creneaux-bloc'),
                valeur: lecture,
                squelette: const Skeleton.liste(lignes: 4),
                onReessayer: () => ref.invalidate(creneauxDirectionProvider),
                estVide: (List<CreneauDirection> l) => l.isEmpty,
                vide: EmptyState(
                  key: const ValueKey<String>('creneaux-vide'),
                  message: c.aucun,
                  invitation: c.aucunInvitation,
                  libelleAction: gestes ? c.ouvrir : null,
                  onAction: gestes ? () => unawaited(_ouvrir()) : null,
                ),
                erreurVersEtat: (Object e, VoidCallback? reessayer) {
                  if (e is CapaciteIndisponible) {
                    return EtatSysteme(
                      key: const ValueKey<String>('creneaux-indisponible'),
                      nature: NatureEtat.indisponible,
                      titre: t.commun.etats.branchementServeur,
                      phrase: '',
                      dependance: e.dependance,
                    );
                  }
                  if (e is PermissionInsuffisante) {
                    return EtatSysteme(
                      key: const ValueKey<String>('creneaux-refus'),
                      nature: NatureEtat.echecServeur,
                      phrase: t.admin.candidatures.erreurs.permission,
                    );
                  }
                  return horsLigne
                      ? EtatSansDonnees(
                          key: const ValueKey<String>('creneaux-sans-donnees'),
                          quoi: c.sansDonnees,
                          onAction: reessayer,
                        )
                      : EtatSysteme(
                          key: const ValueKey<String>('creneaux-erreur'),
                          nature: NatureEtat.echecServeur,
                          phrase: c.lectureEchec,
                          onAction: reessayer,
                        );
                },
                construire: (List<CreneauDirection> liste) => Column(
                  key: const ValueKey<String>('creneaux-liste'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final CreneauDirection cr in liste) ...<Widget>[
                      CarteCreneau(
                        creneau: cr,
                        onRetirer: gestes && cr.etat == EtatCreneau.libre
                            ? () => unawaited(_retirer(cr))
                            : null,
                      ),
                      Ecart.vLg,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un creneau : le moment, l'etat, le cote, les langues, les personnes.
class CarteCreneau extends StatelessWidget {
  /// Cree la carte.
  const CarteCreneau({required this.creneau, this.onRetirer, super.key});

  /// Le creneau.
  final CreneauDirection creneau;

  /// « Retirer ce creneau » ; nul : pas de geste.
  final VoidCallback? onRetirer;

  @override
  Widget build(BuildContext context) {
    final c = t.admin.candidatures.creneaux;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String etat = switch (creneau.etat) {
      EtatCreneau.libre => c.libre,
      EtatCreneau.reserve => c.reserve,
      EtatCreneau.annule => c.retire,
    };
    final String cote = creneau.cote == 'female' ? c.coteFemmes : c.coteHommes;
    final String langues = <String>[
      for (final String l in creneau.langues) nomDeLangue(l) ?? l,
    ].join(', ');
    TextStyle? muet(TextStyle? s) =>
        s == null ? null : palette.inkMuted.applyTo(s);
    return AppCard(
      key: ValueKey<String>('creneau-${creneau.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TexteSansCoupure(
            horaireEntretien(creneau.debut, creneau.fin),
            style: textes.titleMedium,
          ),
          Ecart.vXs,
          TexteSansCoupure('$etat · $cote', style: textes.bodyMedium),
          Ecart.vXs,
          TexteSansCoupure(langues, style: muet(textes.bodyMedium)),
          Ecart.vXs,
          TexteSansCoupure(
            LibellesGroupe.insecable(
              c.participants(n: '${creneau.participants}'),
            ),
            style: muet(textes.bodyMedium),
          ),
          if (creneau.fondateurs > 0)
            TexteSansCoupure(
              LibellesGroupe.insecable(
                c.fondateurs(n: '${creneau.fondateurs}'),
              ),
              style: muet(textes.bodyMedium),
            ),
          if (onRetirer != null) ...<Widget>[
            Ecart.vSm,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LienFleche(
                key: ValueKey<String>('creneau-retirer-${creneau.id}'),
                libelle: c.retirer,
                fleche: false,
                onPress: onRetirer,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
    final DateTime debut = DateTime(
      j.year,
      j.month,
      j.day,
      _heure! ~/ 60,
      _heure! % 60,
    );
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
      );
      return t.admin.candidatures.creneaux.ouvert;
    }, widget.onFini);
  }

  @override
  Widget build(BuildContext context) {
    final c = t.admin.candidatures.creneaux;
    final e = t.admin.candidatures.entretien;
    final f = e.feuille;
    final DateTime maintenant = ref.read(horlogeFormulairesProvider)();
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
              if (m != null) _modifie(() => _heure = m);
            },
          ),
        ),
        if (tente && _heure == null) erreurChamp(f.heureManquante),
        Ecart.vSm,
        muet(f.heureAide),
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
              if (d != null) _modifie(() => _duree = d);
            },
          ),
        ),
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

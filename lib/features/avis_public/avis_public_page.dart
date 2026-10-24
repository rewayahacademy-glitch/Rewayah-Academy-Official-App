/// AVIS-PUBLICS : le formulaire d'avis des familles et des eleves, `/avis/<jeton>`.
///
/// Ouvert sans compte ni connexion (`Routes.avis`, `deciderRedirection`). La
/// personne arrive avec le lien que la direction lui a remis ; le serveur dit
/// seulement si ce lien accepte encore des avis (`avis_lien_etat`).
///
/// Ce que la page tient (DECISION-AVIS-2026-10-19, choix 2) : nom affiche, qui
/// parle, pays, « avec nous depuis », note, avis, la case d'accord de
/// publication, la phrase de moderation et de retrait, et les regles de
/// moderation en deux phrases. Jamais le nom d'un enfant, un courriel ou un
/// telephone.
///
/// AVIS-UI (24/10/2026, captures du directeur a 1366 et 390 px) : un panneau
/// centre de 560 au plus, en-tete compris ; « Vous etes » en deux cartes cote a
/// cote a toutes les largeurs ; mois et annee cote a cote, bornes a avril 2024
/// et au mois courant ; la note lue a cote des etoiles ; plus de titre
/// d'avis (la colonne reste en base, nulle) ; le logo a sa taille sur l'ecran
/// de remerciement.
///
/// Un bouton qui ne peut pas aboutir n'est pas grise (lib/CLAUDE.md) : il
/// reste actif, et un appui sur un formulaire incomplet dit, champ par champ,
/// ce qui manque, sans rien envoyer. Etats : chargement, formulaire, envoi,
/// envoye, lien ferme, erreur, hors ligne, fonction indisponible.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_avis.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/entete_page.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/marque_page.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/note_etoiles.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../consentements/texte_observation.dart';
import '../salle_seance/information_controle.dart';
import 'validation_avis.dart';

/// L'adresse a laquelle ecrire pour faire retirer un avis ou obtenir un lien.
const String courrielSupportAvis = InformationControle.contactConfidentialite;

/// L'instant courant, injectable (tests : le mois futur se refuse).
final Provider<DateTime Function()> horlogeAvisProvider =
    Provider<DateTime Function()>((Ref _) => DateTime.now);

/// Vrai quand le lien de [jeton] accepte encore des avis. Relu a chaque
/// ouverture de la page.
final avisLienOuvertProvider = FutureProvider.autoDispose.family<bool, String>(
  (Ref ref, String jeton) => ref.watch(portAvisProvider).lienOuvert(jeton),
  retry: (int _, Object _) => null,
);

/// Ce que dit la ligne au-dessus du bouton d'envoi.
enum RetourAvis {
  /// Des champs sont a corriger : rien n'est parti.
  aCorriger,

  /// Le serveur refuse un champ qu'il ne nomme pas.
  champServeur,

  /// L'envoi n'est pas confirme.
  echec,

  /// Pas de reseau : rien n'est parti.
  horsLigne,
}

/// Le formulaire d'avis.
class AvisPublicPage extends ConsumerStatefulWidget {
  /// Cree la page pour le lien de [jeton].
  const AvisPublicPage({required this.jeton, super.key});

  /// Le jeton du lien, tel qu'il figure dans l'adresse.
  final String jeton;

  /// Le bouton d'envoi.
  static const Key envoyerKey = ValueKey<String>('avis-envoyer');

  /// La ligne qui dit pourquoi rien n'est parti.
  static const Key retourKey = ValueKey<String>('avis-retour');

  /// La case d'accord de publication.
  static const Key accordKey = ValueKey<String>('avis-accord');

  /// Le champ du nom affiche.
  static const Key nomKey = ValueKey<String>('avis-nom');

  /// Le champ de l'avis.
  static const Key texteKey = ValueKey<String>('avis-texte');

  /// Le panneau centre de la page (AVIS-UI).
  static const Key panneauKey = ValueKey<String>('avis-panneau');

  /// La note lue a cote des etoiles (« 4 sur 5 »).
  static const Key noteLueKey = ValueKey<String>('avis-note-lue');

  /// Le compteur de caracteres de l'avis.
  static const Key compteurKey = ValueKey<String>('avis-compteur');

  /// La ligne du pays choisi.
  static const Key paysKey = ValueKey<String>('avis-pays');

  /// Le choix du mois.
  static const Key moisKey = ValueKey<String>('avis-mois');

  /// Le choix de l'annee.
  static const Key anneeKey = ValueKey<String>('avis-annee');

  /// Le message d'erreur du champ [champ].
  static Key erreurKey(ChampAvis champ) =>
      ValueKey<String>('avis-erreur-${champ.name}');

  /// La carte de la qualite [q].
  static Key qualiteKey(QualiteAvis q) =>
      ValueKey<String>('avis-qualite-${q.name}');

  /// La ligne du pays [code] dans la liste.
  static Key paysListeKey(String code) => ValueKey<String>('avis-pays-$code');

  /// Le champ de recherche de la liste des pays.
  static const Key rechercheKey = ValueKey<String>('avis-pays-recherche');

  @override
  ConsumerState<AvisPublicPage> createState() => _AvisPublicPageState();
}

class _AvisPublicPageState extends ConsumerState<AvisPublicPage> {
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _texte = TextEditingController();
  final FocusNode _focusAccord = FocusNode();
  final Map<ChampAvis, GlobalKey> _ancres = <ChampAvis, GlobalKey>{
    for (final ChampAvis c in ChampAvis.values) c: GlobalKey(),
  };

  QualiteAvis? _qualite;
  String? _pays;
  int? _mois;
  int? _annee;
  int _note = 0;
  bool _accord = false;

  bool _tente = false;
  bool _envoi = false;
  bool _envoye = false;
  bool _lienFerme = false;
  RetourAvis? _retour;
  Set<ChampAvis> _refuses = <ChampAvis>{};

  @override
  void dispose() {
    _nom.dispose();
    _texte.dispose();
    _focusAccord.dispose();
    super.dispose();
  }

  bool get _horsLigne => ref.read(horsLigneProvider).value ?? false;

  SaisieAvis get _saisie => SaisieAvis(
    nom: _nom.text,
    qualite: _qualite,
    pays: _pays,
    mois: _mois,
    annee: _annee,
    note: _note,
    texte: _texte.text,
    accord: _accord,
  );

  /// Un champ change : l'erreur du serveur sur ce champ ne vaut plus.
  void _modifie(VoidCallback changement, [ChampAvis? champ]) => setState(() {
    changement();
    _retour = null;
    if (champ != null) _refuses = <ChampAvis>{..._refuses}..remove(champ);
  });

  Future<void> _envoyer() async {
    if (_envoi) return;
    final Set<ChampAvis> erreurs = champsACorriger(
      _saisie,
      ref.read(horlogeAvisProvider)(),
    ).toSet();
    if (erreurs.isNotEmpty) {
      setState(() {
        _tente = true;
        _retour = RetourAvis.aCorriger;
      });
      final ChampAvis premier = ChampAvis.values.firstWhere(erreurs.contains);
      unawaited(_montrer(premier));
      return;
    }
    // Hors ligne, rien ne part ; la saisie reste sur l'ecran.
    if (_horsLigne) {
      setState(() => _retour = RetourAvis.horsLigne);
      return;
    }
    setState(() {
      _envoi = true;
      _retour = null;
      _refuses = <ChampAvis>{};
    });
    final S saisie = _saisie;
    RetourAvis? retour;
    bool envoye = false;
    bool ferme = false;
    Set<ChampAvis> refuses = <ChampAvis>{};
    try {
      await ref
          .read(portAvisProvider)
          .deposer(
            widget.jeton,
            DepotAvis(
              nom: saisie.nom.trim(),
              qualite: saisie.qualite!,
              pays: saisie.pays!,
              depuis: moisDepuis(saisie)!,
              note: saisie.note,
              titre: null,
              texte: saisie.texte.trim(),
              accord: saisie.accord,
            ),
          );
      envoye = true;
    } on ChampAvisInvalide catch (e) {
      final ChampAvis? champ = e.champ;
      if (champ == null) {
        retour = RetourAvis.champServeur;
      } else {
        refuses = <ChampAvis>{champ};
        retour = RetourAvis.aCorriger;
      }
    } on LienAvisFerme {
      ferme = true;
    } on Object {
      retour = _horsLigne ? RetourAvis.horsLigne : RetourAvis.echec;
    }
    if (!mounted) return;
    setState(() {
      _envoi = false;
      _envoye = envoye;
      _lienFerme = ferme;
      _retour = retour;
      _refuses = refuses;
      _tente = _tente || refuses.isNotEmpty;
    });
    if (refuses.isNotEmpty) unawaited(_montrer(refuses.first));
  }

  Future<void> _montrer(ChampAvis champ) async {
    // Laisse le message d'erreur se poser avant de defiler jusqu'au champ.
    await WidgetsBinding.instance.endOfFrame;
    final BuildContext? ctx = _ancres[champ]?.currentContext;
    if (ctx == null || !ctx.mounted) return;
    unawaited(
      Scrollable.ensureVisible(ctx, alignment: 0.1, duration: Duration.zero),
    );
    if (champ == ChampAvis.accord) _focusAccord.requestFocus();
  }

  Future<void> _choisirPays() async {
    final String? code = await AppBottomSheet.ouvrir<String>(
      context,
      titre: t.avis.form.pays.libelle,
      constructeur: (BuildContext contexte) =>
          _ListePays(onChoix: (String c) => Navigator.of(contexte).pop(c)),
    );
    if (code == null || !mounted) return;
    _modifie(() => _pays = code, ChampAvis.pays);
  }

  @override
  Widget build(BuildContext context) {
    final f = t.avis.form;
    final AsyncValue<bool> lien = ref.watch(
      avisLienOuvertProvider(widget.jeton),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final bool enTete = !_envoye && !_lienFerme;
    return PageShell(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          key: AvisPublicPage.panneauKey,
          constraints: const BoxConstraints(maxWidth: AppPage.largeurDialogue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (enTete) ...<Widget>[
                EntetePage(titre: f.titre, sousTitre: f.sousTitre),
                Ecart.vXl,
              ],
              _contenu(lien, horsLigne),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenu(AsyncValue<bool> lien, bool horsLigne) {
    final f = t.avis.form;
    return _envoye
        ? Column(
            key: const ValueKey<String>('avis-envoye'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Center(child: MarquePage(logo: true)),
              Ecart.vXl,
              EcranResultat(
                icone: AppIcons.succes,
                ton: TonEtat.succes,
                titre: f.envoye.titre,
                phrase: coupuresAdresse(
                  f.envoye.phrase(courriel: courrielSupportAvis),
                ),
              ),
            ],
          )
        : _lienFerme
        ? _ecranFerme()
        : BlocAsynchrone<bool>(
            key: const ValueKey<String>('avis-bloc'),
            valeur: lien,
            squelette: const Skeleton.liste(lignes: 4),
            onReessayer: () =>
                ref.invalidate(avisLienOuvertProvider(widget.jeton)),
            erreurVersEtat: (Object e, VoidCallback? reessayer) {
              if (e is CapaciteIndisponible) {
                return EtatSysteme(
                  key: const ValueKey<String>('avis-indisponible'),
                  nature: NatureEtat.indisponible,
                  titre: f.indisponibleTitre,
                  phrase: f.indisponiblePhrase,
                  dependance: e.dependance,
                );
              }
              return horsLigne
                  ? EtatSansDonnees(
                      key: const ValueKey<String>('avis-sans-donnees'),
                      quoi: f.sansDonnees,
                      onAction: reessayer,
                    )
                  : EtatSysteme(
                      key: const ValueKey<String>('avis-erreur'),
                      nature: NatureEtat.echecServeur,
                      phrase: f.erreurChargement,
                      onAction: reessayer,
                    );
            },
            construire: (bool ouvert) => ouvert ? _formulaire() : _ecranFerme(),
          );
  }

  Widget _ecranFerme() => EcranResultat(
    key: const ValueKey<String>('avis-ferme'),
    icone: AppIcons.verrou,
    ton: TonEtat.neutre,
    titre: t.avis.form.ferme.titre,
    phrase: coupuresAdresse(
      t.avis.form.ferme.phrase(courriel: courrielSupportAvis),
    ),
  );

  bool _montreErreur(ChampAvis champ) =>
      _refuses.contains(champ) ||
      (_tente &&
          champsACorriger(
            _saisie,
            ref.read(horlogeAvisProvider)(),
          ).contains(champ));

  Widget _erreur(ChampAvis champ, String message) {
    if (!_montreErreur(champ)) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          key: AvisPublicPage.erreurKey(champ),
          style: palette.inkAlert.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
      ),
    );
  }

  Widget _formulaire() {
    final f = t.avis.form;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final DateTime maintenant = ref.read(horlogeAvisProvider)();
    final int longueur = _texte.text.trim().length;
    final RetourAvis? retour = _retour;
    return Column(
      key: const ValueKey<String>('avis-formulaire'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Nom affiche (saisi : personne ne le connait d'avance).
        KeyedSubtree(
          key: _ancres[ChampAvis.nom],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ChampEtiquete(
                key: AvisPublicPage.nomKey,
                libelle: f.nom.libelle,
                aide: f.nom.aide,
                controller: _nom,
                obligatoire: true,
                textCapitalization: TextCapitalization.words,
                onChanged: (String _) => _modifie(() {}, ChampAvis.nom),
              ),
              _erreur(ChampAvis.nom, f.nom.erreur),
            ],
          ),
        ),
        Ecart.vXl,
        // Qui parle (choisi).
        KeyedSubtree(
          key: _ancres[ChampAvis.qualite],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TitreChamp(
                f.qualite.libelle,
                style: textes.titleMedium,
                obligatoire: true,
              ),
              Ecart.vSm,
              ChoiceCardGroup(
                autoriserSaisieLibre: false,
                enLigne: true,
                options: <OptionChoix>[
                  OptionChoix(
                    cle: AvisPublicPage.qualiteKey(QualiteAvis.parent),
                    valeur: QualiteAvis.parent.name,
                    libelle: f.qualite.parent,
                  ),
                  OptionChoix(
                    cle: AvisPublicPage.qualiteKey(QualiteAvis.eleveAdulte),
                    valeur: QualiteAvis.eleveAdulte.name,
                    libelle: f.qualite.eleveAdulte,
                  ),
                ],
                onChange: (ReponseChoix r) => _modifie(() {
                  _qualite = r.valeurs.contains(QualiteAvis.parent.name)
                      ? QualiteAvis.parent
                      : r.valeurs.contains(QualiteAvis.eleveAdulte.name)
                      ? QualiteAvis.eleveAdulte
                      : null;
                }, ChampAvis.qualite),
              ),
              _erreur(ChampAvis.qualite, f.qualite.erreur),
            ],
          ),
        ),
        Ecart.vXl,
        // Pays (choisi dans une liste qui se cherche).
        KeyedSubtree(
          key: _ancres[ChampAvis.pays],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TitreChamp(
                f.pays.libelle,
                style: textes.titleMedium,
                obligatoire: true,
              ),
              Ecart.vSm,
              CarteLignes(
                lignes: <Widget>[
                  SettingRow(
                    key: AvisPublicPage.paysKey,
                    title: _pays == null ? f.pays.choisir : nomDuPays(_pays!),
                    onPress: () => unawaited(_choisirPays()),
                  ),
                ],
              ),
              _erreur(ChampAvis.pays, f.pays.erreur),
            ],
          ),
        ),
        Ecart.vXl,
        // Depuis quand (choisi : mois et annee).
        KeyedSubtree(
          key: _ancres[ChampAvis.depuis],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TitreChamp(
                f.depuis.libelle,
                style: textes.titleMedium,
                obligatoire: true,
              ),
              Ecart.vXs,
              Text(f.depuis.aide, style: textes.bodySmall),
              Ecart.vSm,
              // Deux menus de meme largeur, cote a cote : le mois, borne par
              // l'annee choisie, puis l'annee.
              Row(
                children: <Widget>[
                  Expanded(
                    child: MenuFiltre<int>(
                      key: AvisPublicPage.moisKey,
                      libelle: f.depuis.mois,
                      valeur: _mois,
                      entrees: <EntreeFiltre<int>>[
                        for (final int m in moisProposes(_annee, maintenant))
                          EntreeFiltre<int>(
                            valeur: m,
                            libelle: t.commun.dates.mois[m - 1],
                          ),
                      ],
                      onChoix: (int? m) =>
                          _modifie(() => _mois = m, ChampAvis.depuis),
                    ),
                  ),
                  Ecart.hLg,
                  Expanded(
                    child: MenuFiltre<int>(
                      key: AvisPublicPage.anneeKey,
                      libelle: f.depuis.annee,
                      valeur: _annee,
                      entrees: <EntreeFiltre<int>>[
                        for (final int a in anneesProposees(maintenant))
                          EntreeFiltre<int>(valeur: a, libelle: '$a'),
                      ],
                      onChoix: (int? a) => _modifie(() {
                        _annee = a;
                        // Un mois hors des bornes de la nouvelle annee tombe.
                        if (!moisProposes(a, maintenant).contains(_mois)) {
                          _mois = null;
                        }
                      }, ChampAvis.depuis),
                    ),
                  ),
                ],
              ),
              _erreur(ChampAvis.depuis, f.depuis.erreur),
            ],
          ),
        ),
        Ecart.vXl,
        // Note (choisie).
        KeyedSubtree(
          key: _ancres[ChampAvis.note],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TitreChamp(
                f.note.libelle,
                style: textes.titleMedium,
                obligatoire: true,
              ),
              Ecart.vXs,
              Text(f.note.aide, style: textes.bodySmall),
              Ecart.vSm,
              // La note lue suit les etoiles, et passe dessous a 320 px
              // (cinq cibles de 48 n'y laissent pas sa place).
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  NoteEtoiles(
                    valeur: _note,
                    onChange: (int n) =>
                        _modifie(() => _note = n, ChampAvis.note),
                  ),
                  if (_note > 0)
                    Text(
                      f.note.surCinq(n: _note),
                      key: AvisPublicPage.noteLueKey,
                      style: textes.bodyLarge,
                    ),
                ],
              ),
              _erreur(ChampAvis.note, f.note.erreur),
            ],
          ),
        ),
        Ecart.vXl,
        // Avis.
        KeyedSubtree(
          key: _ancres[ChampAvis.texte],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ChampEtiquete(
                key: AvisPublicPage.texteKey,
                libelle: f.texte.libelle,
                aide: f.texte.aide,
                controller: _texte,
                maxLines: 5,
                obligatoire: true,
                onChanged: (String _) => _modifie(() {}, ChampAvis.texte),
              ),
              Ecart.vXs,
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  f.texte.compteur(n: longueur, max: BornesAvis.texteMax),
                  key: AvisPublicPage.compteurKey,
                  style: longueur > BornesAvis.texteMax
                      ? palette.inkAlert.applyTo(
                          textes.bodySmall ?? const TextStyle(),
                        )
                      : palette.inkMuted.applyTo(
                          textes.bodySmall ?? const TextStyle(),
                        ),
                ),
              ),
              _erreur(ChampAvis.texte, f.texte.erreur),
            ],
          ),
        ),
        Ecart.vXl,
        // Les regles de moderation, avant l'accord : la personne les lit avant
        // de decider.
        _Regles(),
        Ecart.vXl,
        // Accord de publication, jamais precoche.
        KeyedSubtree(
          key: _ancres[ChampAvis.accord],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CaseAccordTexte(
                key: AvisPublicPage.accordKey,
                libelle: f.accord.libelle,
                cochee: _accord,
                focusNode: _focusAccord,
                onChanged: _envoi
                    ? null
                    : (bool v) => _modifie(() => _accord = v, ChampAvis.accord),
              ),
              _erreur(ChampAvis.accord, f.accord.erreur),
            ],
          ),
        ),
        Ecart.vLg,
        Text(
          coupuresAdresse(f.lecture(courriel: courrielSupportAvis)),
          key: const ValueKey<String>('avis-lecture'),
          style: textes.bodyMedium,
        ),
        Ecart.vLg,
        if (retour != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              switch (retour) {
                RetourAvis.aCorriger => f.aCorriger,
                RetourAvis.champServeur => f.erreurChamp,
                RetourAvis.echec => f.echec,
                RetourAvis.horsLigne => f.horsLigne,
              },
              key: AvisPublicPage.retourKey,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vLg,
        ],
        // Pleine largeur aussi sur ordinateur (AVIS-UI) : le panneau borne le
        // bouton a 560, la largeur du formulaire qu'il envoie.
        ActionPrincipale(
          key: AvisPublicPage.envoyerKey,
          pleineLargeur: true,
          libelle: f.envoyer,
          enCours: _envoi,
          onPress: () => unawaited(_envoyer()),
        ),
      ],
    );
  }
}

/// Une saisie figee pour l'envoi (evite de relire les champs apres un await).
typedef S = SaisieAvis;

/// Les regles de moderation, en bref.
class _Regles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = t.avis.form.regles;
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey<String>('avis-regles'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(r.titre, style: textes.titleMedium),
        ),
        Ecart.vSm,
        Text(r.publie, style: textes.bodyMedium),
        Ecart.vSm,
        Text(r.donnees, style: textes.bodyMedium),
      ],
    );
  }
}

/// La liste des pays, avec sa recherche.
class _ListePays extends StatefulWidget {
  const _ListePays({required this.onChoix});

  final ValueChanged<String> onChoix;

  @override
  State<_ListePays> createState() => _ListePaysState();
}

class _ListePaysState extends State<_ListePays> {
  final TextEditingController _recherche = TextEditingController();

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = t.avis.form.pays;
    final List<PaysIso> pays = chercherPays(_recherche.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ChampRecherche(
          cleChamp: AvisPublicPage.rechercheKey,
          controleur: _recherche,
          libelle: f.rechercheLibelle,
          aide: f.rechercheAide,
          onChange: (String _) => setState(() {}),
        ),
        Ecart.vLg,
        if (pays.isEmpty)
          Text(
            f.aucun,
            key: const ValueKey<String>('avis-pays-aucun'),
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          CarteLignes(
            lignes: <Widget>[
              for (final PaysIso p in pays)
                SettingRow(
                  key: AvisPublicPage.paysListeKey(p.code),
                  title: p.nom,
                  onPress: () => widget.onChoix(p.code),
                ),
            ],
          ),
      ],
    );
  }
}

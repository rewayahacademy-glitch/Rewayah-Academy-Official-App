/// AVIS-PUBLICS : les avis des familles et des eleves, cote direction.
///
/// Deux sections (`SelecteurSection`) :
///
///   * **Avis** : la liste, filtree par statut, avec tous les champs. Pour un
///     avis en attente, « Publier » et « Refuser » ; pour un avis publie,
///     « Retirer ». Refuser et retirer demandent un motif (propose, puis
///     « Autre ») dans une feuille qui redit la consequence ; publier passe
///     par une confirmation. **La direction ne modifie jamais le texte** : il
///     n'existe aucun champ de modification.
///   * **Liens** : creer un lien de collecte (nom, duree en jours, nombre
///     maximal d'avis), voir son adresse complete **une seule fois**, lister
///     les liens et en fermer un.
///
/// Le serveur decide de tout (transitions, motifs, validite) ; l'ecran envoie
/// et affiche. Etats de chaque section : chargement, contenu, vide, erreur,
/// hors ligne (et fonction indisponible tant que le serveur n'est pas branche).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_avis.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/note_etoiles.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/selecteur_mois.dart';
import '../../core/widgets/selecteur_motif.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'lien_avis.dart';

/// Les liens de collecte, lus au serveur. Relus a chaque ouverture.
final avisLiensProvider = FutureProvider.autoDispose<List<LienAvis>>(
  (Ref ref) => ref.watch(portAvisProvider).listerLiens(),
  retry: (int _, Object _) => null,
);

/// Les avis, lus au serveur, filtres par [StatutAvis] (nul : tous).
final avisAdminProvider = FutureProvider.autoDispose
    .family<List<AvisAdmin>, StatutAvis?>(
      (Ref ref, StatutAvis? statut) =>
          ref.watch(portAvisProvider).listerAvis(statut: statut),
      retry: (int _, Object _) => null,
    );

/// Les sections de l'ecran.
enum SectionAvis {
  /// Les avis.
  avis,

  /// Les liens de collecte.
  liens,
}

/// Ce que dit la ligne en haut des avis apres un geste.
enum RetourAvisAdmin {
  /// L'avis est publie.
  publie,

  /// L'avis est refuse.
  refuse,

  /// L'avis est retire.
  retire,

  /// L'avis n'est plus dans l'etat attendu.
  etatChange,

  /// L'avis n'existe plus.
  introuvable,

  /// Le motif manque.
  motifManque,

  /// Le serveur refuse cette personne.
  refus,

  /// La decision n'est pas confirmee.
  echec,

  /// Pas de reseau : rien n'est parti.
  horsLigne,
}

/// Ce que dit la ligne en haut des liens apres un geste.
enum RetourLien {
  /// Le lien est ferme.
  ferme,

  /// La creation n'est pas confirmee.
  echecCreation,

  /// La fermeture n'est pas confirmee.
  echecFermeture,

  /// Le serveur refuse cette personne.
  refus,

  /// Pas de reseau : rien n'est parti.
  horsLigne,
}

/// L'ecran « Avis ».
class AvisAdminPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const AvisAdminPage({super.key, this.horloge});

  /// L'instant courant (tests) ; par defaut l'horloge de l'appareil.
  final DateTime Function()? horloge;

  /// Le choix de la section.
  static const Key sectionsKey = ValueKey<String>('avis-admin-sections');

  /// La ligne qui dit ce qu'est devenu le dernier geste sur un avis.
  static const Key retourKey = ValueKey<String>('avis-admin-retour');

  /// La ligne qui dit ce qu'est devenu le dernier geste sur un lien.
  static const Key retourLienKey = ValueKey<String>('avis-admin-retour-lien');

  /// Le filtre « statut » de la liste.
  static Key filtreKey(StatutAvis? s) =>
      ValueKey<String>('avis-admin-filtre-${s?.name ?? 'tous'}');

  /// La carte de l'avis [id].
  static Key carteKey(String id) => ValueKey<String>('avis-admin-$id');

  /// « Publier » l'avis [id].
  static Key publierKey(String id) => ValueKey<String>('avis-publier-$id');

  /// « Refuser » l'avis [id].
  static Key refuserKey(String id) => ValueKey<String>('avis-refuser-$id');

  /// « Retirer » l'avis [id].
  static Key retirerKey(String id) => ValueKey<String>('avis-retirer-$id');

  /// Le bouton qui confirme dans la feuille du motif.
  static const Key confirmerMotifKey = ValueKey<String>('avis-motif-confirmer');

  /// Le champ du nom du nouveau lien.
  static const Key libelleKey = ValueKey<String>('lien-libelle');

  /// Le champ de la duree du nouveau lien.
  static const Key joursKey = ValueKey<String>('lien-jours');

  /// Le champ du nombre maximal d'avis du nouveau lien.
  static const Key maxKey = ValueKey<String>('lien-max');

  /// Le geste « Creer le lien ».
  static const Key creerKey = ValueKey<String>('lien-creer');

  /// L'encadre du lien qui vient d'etre cree.
  static const Key creeKey = ValueKey<String>('lien-cree');

  /// L'adresse complete du lien qui vient d'etre cree.
  static const Key adresseKey = ValueKey<String>('lien-adresse');

  /// « Copier le lien ».
  static const Key copierKey = ValueKey<String>('lien-copier');

  /// « J'ai copie le lien » : l'adresse disparait.
  static const Key creeFermerKey = ValueKey<String>('lien-cree-fermer');

  /// La carte du lien [id].
  static Key lienKey(String id) => ValueKey<String>('lien-$id');

  /// « Fermer le lien » [id].
  static Key fermerKey(String id) => ValueKey<String>('lien-fermer-$id');

  @override
  ConsumerState<AvisAdminPage> createState() => _AvisAdminPageState();
}

class _AvisAdminPageState extends ConsumerState<AvisAdminPage> {
  SectionAvis _section = SectionAvis.avis;
  StatutAvis? _filtre = StatutAvis.enAttente;

  String? _enCours;
  RetourAvisAdmin? _retour;
  RetourLien? _retourLien;

  final TextEditingController _libelle = TextEditingController();
  final TextEditingController _jours = TextEditingController(text: '90');
  final TextEditingController _max = TextEditingController(text: '200');
  bool _creationTentee = false;
  bool _creationEnCours = false;
  LienAvisCree? _cree;
  bool _copie = false;

  DateTime _maintenant() => (widget.horloge ?? DateTime.now)();

  bool get _horsLigne => ref.read(horsLigneProvider).value ?? false;

  @override
  void dispose() {
    _libelle.dispose();
    _jours.dispose();
    _max.dispose();
    super.dispose();
  }

  // --- Avis ---------------------------------------------------------------

  Future<void> _publier(AvisAdmin a) async {
    if (_enCours != null) return;
    final p = t.avis.admin.publier;
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: p.question(
        deNom: deDevant(a.nomAffiche, cle: 'avis.admin.publier.question'),
      ),
      consequence: p.consequence,
      libelleConfirmer: p.action,
      libelleAnnuler: p.rester,
    );
    if (!oui || !mounted) return;
    await _moderer(a, StatutAvis.publie, null);
  }

  Future<void> _decider(AvisAdmin a, StatutAvis statut) async {
    if (_enCours != null) return;
    final bool refus = statut == StatutAvis.refuse;
    final i = t.avis.admin;
    final String? motif = await AppBottomSheet.ouvrir<String>(
      context,
      titre: refus
          ? i.refuser.titre(
              deNom: deDevant(a.nomAffiche, cle: 'avis.admin.refuser.titre'),
            )
          : i.retirer.titre(
              deNom: deDevant(a.nomAffiche, cle: 'avis.admin.retirer.titre'),
            ),
      constructeur: (BuildContext contexte) => _FeuilleMotif(
        intro: refus ? i.refuser.intro : i.retirer.intro,
        consequence: refus ? i.refuser.consequence : i.retirer.consequence,
        libelleAction: refus ? i.refuser.action : i.retirer.action,
        libelleRester: refus ? i.refuser.rester : i.retirer.rester,
        motifs: <String>[
          if (!refus) i.motifs.demande,
          i.motifs.insulte,
          i.motifs.tiers,
          i.motifs.publicite,
          i.motifs.horsSujet,
          i.motifs.doublon,
        ],
        onConfirmer: (String m) => Navigator.of(contexte).pop(m),
        onRester: () => Navigator.of(contexte).pop(),
      ),
    );
    if (motif == null || !mounted) return;
    await _moderer(a, statut, motif);
  }

  Future<void> _moderer(AvisAdmin a, StatutAvis statut, String? motif) async {
    // Hors ligne, rien ne part.
    if (_horsLigne) {
      setState(() => _retour = RetourAvisAdmin.horsLigne);
      return;
    }
    setState(() {
      _enCours = a.id;
      _retour = null;
    });
    RetourAvisAdmin retour;
    try {
      await ref.read(portAvisProvider).moderer(a.id, statut, motif: motif);
      retour = switch (statut) {
        StatutAvis.publie => RetourAvisAdmin.publie,
        StatutAvis.refuse => RetourAvisAdmin.refuse,
        StatutAvis.retire => RetourAvisAdmin.retire,
        StatutAvis.enAttente => RetourAvisAdmin.echec,
      };
    } on ModerationAvisRefusee catch (e) {
      retour = switch (e.raison) {
        RefusModeration.introuvable => RetourAvisAdmin.introuvable,
        RefusModeration.etatChange => RetourAvisAdmin.etatChange,
        RefusModeration.motifManquant => RetourAvisAdmin.motifManque,
      };
    } on PermissionInsuffisante {
      retour = RetourAvisAdmin.refus;
    } on Object {
      // La reponse a pu se perdre apres la decision : la liste est relue.
      retour = _horsLigne ? RetourAvisAdmin.horsLigne : RetourAvisAdmin.echec;
    }
    // Dans tous les cas la liste est relue : une decision dont la reponse s'est
    // perdue doit y apparaitre, jamais « non envoyee ».
    ref.invalidate(avisAdminProvider);
    if (!mounted) return;
    setState(() {
      _enCours = null;
      _retour = retour;
    });
  }

  // --- Liens --------------------------------------------------------------

  int? _entier(TextEditingController c, int min, int max) {
    final int? n = int.tryParse(c.text.trim());
    return n == null || n < min || n > max ? null : n;
  }

  Future<void> _creer() async {
    if (_creationEnCours) return;
    final String libelle = _libelle.text.trim();
    final int? jours = _entier(_jours, 1, 365);
    final int? max = _entier(_max, 1, 2000);
    setState(() {
      _creationTentee = true;
      _retourLien = null;
    });
    if (libelle.isEmpty || jours == null || max == null) return;
    if (_horsLigne) {
      setState(() => _retourLien = RetourLien.horsLigne);
      return;
    }
    setState(() => _creationEnCours = true);
    LienAvisCree? cree;
    RetourLien? retour;
    try {
      cree = await ref
          .read(portAvisProvider)
          .creerLien(libelle: libelle, jours: jours, avisMax: max);
    } on PermissionInsuffisante {
      retour = RetourLien.refus;
    } on Object {
      retour = _horsLigne ? RetourLien.horsLigne : RetourLien.echecCreation;
    }
    // La liste est relue aussi apres un echec : un lien a pu etre cree.
    ref.invalidate(avisLiensProvider);
    if (!mounted) return;
    setState(() {
      _creationEnCours = false;
      _retourLien = retour;
      if (cree != null) {
        _cree = cree;
        _copie = false;
        _creationTentee = false;
        _libelle.clear();
        _jours.text = '90';
        _max.text = '200';
      }
    });
  }

  Future<void> _copier(String adresse) async {
    await Clipboard.setData(ClipboardData(text: adresse));
    if (!mounted) return;
    setState(() => _copie = true);
  }

  Future<void> _fermer(LienAvis l) async {
    final f = t.avis.admin.liens;
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: f.fermerQuestion(nom: l.libelle),
      consequence: f.fermerConsequence,
      libelleConfirmer: f.fermerAction,
      libelleAnnuler: f.fermerRester,
      irreversible: true,
    );
    if (!oui || !mounted) return;
    if (_horsLigne) {
      setState(() => _retourLien = RetourLien.horsLigne);
      return;
    }
    setState(() {
      _enCours = l.id;
      _retourLien = null;
    });
    RetourLien retour;
    try {
      await ref.read(portAvisProvider).fermerLien(l.id);
      retour = RetourLien.ferme;
    } on PermissionInsuffisante {
      retour = RetourLien.refus;
    } on Object {
      retour = _horsLigne ? RetourLien.horsLigne : RetourLien.echecFermeture;
    }
    ref.invalidate(avisLiensProvider);
    if (!mounted) return;
    setState(() {
      _enCours = null;
      _retourLien = retour;
    });
  }

  // --- Rendu --------------------------------------------------------------

  Widget _ligneRetour(Key cle, String message, {required bool bon}) {
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(
          message,
          key: cle,
          style: (bon ? palette.inkStrong : palette.inkAlert).applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
      ),
    );
  }

  Widget? _etatErreur(
    Object e,
    VoidCallback? reessayer, {
    required String cle,
    required String erreur,
    required String sansDonnees,
  }) {
    final a = t.avis.admin;
    if (e is CapaciteIndisponible) {
      return EtatSysteme(
        key: ValueKey<String>('$cle-indisponible'),
        nature: NatureEtat.indisponible,
        titre: a.indisponibleTitre,
        phrase: a.indisponiblePhrase,
        dependance: e.dependance,
      );
    }
    if (e is PermissionInsuffisante) {
      return EtatSysteme(
        key: ValueKey<String>('$cle-refuse'),
        nature: NatureEtat.echecServeur,
        phrase: a.refuse,
      );
    }
    return _horsLigne
        ? EtatSansDonnees(
            key: ValueKey<String>('$cle-sans-donnees'),
            quoi: sansDonnees,
            onAction: reessayer,
          )
        : EtatSysteme(
            key: ValueKey<String>('$cle-erreur'),
            nature: NatureEtat.echecServeur,
            phrase: erreur,
            onAction: reessayer,
          );
  }

  @override
  Widget build(BuildContext context) {
    final a = t.avis.admin;
    // Suit le reseau pour que l'etat « sans donnees » se redessine.
    ref.watch(horsLigneProvider);
    return PageShell(
      titre: a.titre,
      sousTitre: a.sousTitre,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SelecteurSection<SectionAvis>(
                key: AvisAdminPage.sectionsKey,
                libelle: a.sections.libelle,
                valeur: _section,
                sections: <Segment<SectionAvis>>[
                  Segment<SectionAvis>(
                    valeur: SectionAvis.avis,
                    libelle: a.sections.avis,
                  ),
                  Segment<SectionAvis>(
                    valeur: SectionAvis.liens,
                    libelle: a.sections.liens,
                  ),
                ],
                onChange: (SectionAvis s) => setState(() => _section = s),
              ),
              Ecart.vXl,
              if (_section == SectionAvis.avis)
                _sectionAvis()
              else
                _sectionLiens(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Section Avis -------------------------------------------------------

  String _messageAvis(RetourAvisAdmin r) {
    final a = t.avis.admin.retour;
    return switch (r) {
      RetourAvisAdmin.publie => a.publie,
      RetourAvisAdmin.refuse => a.refuse,
      RetourAvisAdmin.retire => a.retire,
      RetourAvisAdmin.etatChange => a.etatChange,
      RetourAvisAdmin.introuvable => a.introuvable,
      RetourAvisAdmin.motifManque => a.motifManque,
      RetourAvisAdmin.refus => a.refus,
      RetourAvisAdmin.echec => a.echec,
      RetourAvisAdmin.horsLigne => a.horsLigne,
    };
  }

  bool _retourBon(RetourAvisAdmin r) =>
      r == RetourAvisAdmin.publie ||
      r == RetourAvisAdmin.refuse ||
      r == RetourAvisAdmin.retire;

  Widget _sectionAvis() {
    final a = t.avis.admin;
    final AsyncValue<List<AvisAdmin>> valeur = ref.watch(
      avisAdminProvider(_filtre),
    );
    final RetourAvisAdmin? retour = _retour;
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RangeeFiltres(
          replier: false,
          filtres: <Widget>[
            for (final (StatutAvis? s, String libelle)
                in <(StatutAvis?, String)>[
                  (StatutAvis.enAttente, a.filtre.enAttente),
                  (StatutAvis.publie, a.filtre.publie),
                  (StatutAvis.refuse, a.filtre.refuse),
                  (StatutAvis.retire, a.filtre.retire),
                  (null, a.filtre.tous),
                ])
              FilterPill(
                key: AvisAdminPage.filtreKey(s),
                libelle: libelle,
                retenue: _filtre == s,
                onPress: () => setState(() => _filtre = s),
              ),
          ],
        ),
        Ecart.vLg,
        if (retour != null)
          _ligneRetour(
            AvisAdminPage.retourKey,
            _messageAvis(retour),
            bon: _retourBon(retour),
          ),
        BlocAsynchrone<List<AvisAdmin>>(
          key: const ValueKey<String>('avis-admin-bloc'),
          valeur: valeur,
          squelette: const Skeleton.liste(lignes: 3),
          onReessayer: () => ref.invalidate(avisAdminProvider),
          vide: EmptyState(
            key: const ValueKey<String>('avis-admin-vide'),
            message: a.vide,
            icone: AppIcons.rienAAfficher,
            registre: RegistreVide.subi,
          ),
          erreurVersEtat: (Object e, VoidCallback? reessayer) => _etatErreur(
            e,
            reessayer,
            cle: 'avis-admin',
            erreur: a.erreur,
            sansDonnees: a.sansDonnees,
          ),
          construire: (List<AvisAdmin> lus) {
            final int attendent = lus
                .where((AvisAdmin x) => x.statut == StatutAvis.enAttente)
                .length;
            return Column(
              key: const ValueKey<String>('avis-admin-contenu'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (attendent > 0) ...<Widget>[
                  Text(a.attente(n: attendent), style: textes.titleMedium),
                  Ecart.vLg,
                ],
                PileCartes(
                  children: <Widget>[
                    for (final AvisAdmin x in lus)
                      _CarteAvis(
                        avis: x,
                        enCours: _enCours == x.id,
                        occupe: _enCours != null,
                        onPublier: () => unawaited(_publier(x)),
                        onRefuser: () =>
                            unawaited(_decider(x, StatutAvis.refuse)),
                        onRetirer: () =>
                            unawaited(_decider(x, StatutAvis.retire)),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // --- Section Liens ------------------------------------------------------

  String _messageLien(RetourLien r) {
    final f = t.avis.admin.liens;
    return switch (r) {
      RetourLien.ferme => f.fermeOk,
      RetourLien.echecCreation => f.echecCreation,
      RetourLien.echecFermeture => f.fermeEchec,
      RetourLien.refus => t.avis.admin.retour.refus,
      RetourLien.horsLigne => t.avis.admin.retour.horsLigne,
    };
  }

  Widget _sectionLiens() {
    final f = t.avis.admin.liens;
    final AsyncValue<List<LienAvis>> valeur = ref.watch(avisLiensProvider);
    final RetourLien? retour = _retourLien;
    final LienAvisCree? cree = _cree;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (cree != null) ...<Widget>[_encadreCree(cree), Ecart.vXl],
        _formulaireCreation(),
        Ecart.vXl,
        if (retour != null)
          _ligneRetour(
            AvisAdminPage.retourLienKey,
            _messageLien(retour),
            bon: retour == RetourLien.ferme,
          ),
        BlocAsynchrone<List<LienAvis>>(
          key: const ValueKey<String>('liens-bloc'),
          valeur: valeur,
          squelette: const Skeleton.liste(lignes: 3),
          onReessayer: () => ref.invalidate(avisLiensProvider),
          vide: EmptyState(
            key: const ValueKey<String>('liens-vide'),
            message: f.vide,
            icone: AppIcons.rienAAfficher,
            registre: RegistreVide.subi,
          ),
          erreurVersEtat: (Object e, VoidCallback? reessayer) => _etatErreur(
            e,
            reessayer,
            cle: 'liens',
            erreur: f.erreur,
            sansDonnees: f.sansDonnees,
          ),
          construire: (List<LienAvis> lus) => PileCartes(
            key: const ValueKey<String>('liens-contenu'),
            children: <Widget>[
              for (final LienAvis l in lus)
                _CarteLien(
                  lien: l,
                  maintenant: _maintenant(),
                  enCours: _enCours == l.id,
                  occupe: _enCours != null,
                  onFermer: () => unawaited(_fermer(l)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _encadreCree(LienAvisCree cree) {
    final f = t.avis.admin.liens;
    final TextTheme textes = Theme.of(context).textTheme;
    final String adresse = lienAvisPour(cree.jeton);
    return AppCard(
      key: AvisAdminPage.creeKey,
      entete: Semantics(
        header: true,
        child: Text(f.creeTitre, style: textes.titleMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BandeauAttention(titre: f.creeTitre, message: f.creePhrase),
          Ecart.vLg,
          Text(f.creeAdresse, style: textes.labelLarge),
          Ecart.vXs,
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SelectableText(
                adresse,
                key: AvisAdminPage.adresseKey,
                style: textes.bodyMedium,
              ),
            ),
          ),
          Ecart.vSm,
          Text(
            f.creeValable(date: dateDeLAppareil(cree.expireLe)),
            style: textes.bodySmall,
          ),
          Ecart.vLg,
          if (_copie) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(f.copie, style: textes.bodyMedium),
            ),
            Ecart.vSm,
          ],
          ActionPrincipale(
            key: AvisAdminPage.copierKey,
            libelle: f.copier,
            niveau: NiveauAction.secondaire,
            onPress: () => unawaited(_copier(adresse)),
          ),
          Ecart.vSm,
          ActionPrincipale(
            key: AvisAdminPage.creeFermerKey,
            libelle: f.creeFermer,
            niveau: NiveauAction.tertiaire,
            onPress: () => setState(() => _cree = null),
          ),
        ],
      ),
    );
  }

  Widget _erreurChamp(String message) {
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: palette.inkAlert.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
      ),
    );
  }

  Widget _formulaireCreation() {
    final f = t.avis.admin.liens;
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      entete: Semantics(
        header: true,
        child: Text(f.creerTitre, style: textes.titleMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(f.creerIntro, style: textes.bodyMedium),
          Ecart.vLg,
          ChampEtiquete(
            key: AvisAdminPage.libelleKey,
            libelle: f.libelle,
            aide: f.libelleAide,
            controller: _libelle,
            obligatoire: true,
            onChanged: (String _) => setState(() {}),
          ),
          if (_creationTentee && _libelle.text.trim().isEmpty)
            _erreurChamp(f.libelleErreur),
          Ecart.vLg,
          ChampEtiquete(
            key: AvisAdminPage.joursKey,
            libelle: f.jours,
            aide: f.joursAide,
            controller: _jours,
            keyboardType: TextInputType.number,
            obligatoire: true,
            onChanged: (String _) => setState(() {}),
          ),
          if (_creationTentee && _entier(_jours, 1, 365) == null)
            _erreurChamp(f.joursErreur),
          Ecart.vLg,
          ChampEtiquete(
            key: AvisAdminPage.maxKey,
            libelle: f.max,
            aide: f.maxAide,
            controller: _max,
            keyboardType: TextInputType.number,
            obligatoire: true,
            onChanged: (String _) => setState(() {}),
          ),
          if (_creationTentee && _entier(_max, 1, 2000) == null)
            _erreurChamp(f.maxErreur),
          Ecart.vLg,
          ActionPrincipale(
            key: AvisAdminPage.creerKey,
            libelle: f.creer,
            enCours: _creationEnCours,
            onPress: () => unawaited(_creer()),
          ),
        ],
      ),
    );
  }
}

String _qualite(QualiteAvis q) => switch (q) {
  QualiteAvis.parent => t.avis.form.qualite.parent,
  QualiteAvis.eleveAdulte => t.avis.form.qualite.eleveAdulte,
};

class _CarteAvis extends StatelessWidget {
  const _CarteAvis({
    required this.avis,
    required this.enCours,
    required this.occupe,
    required this.onPublier,
    required this.onRefuser,
    required this.onRetirer,
  });

  final AvisAdmin avis;
  final bool enCours;
  final bool occupe;
  final VoidCallback onPublier;
  final VoidCallback onRefuser;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) {
    final a = t.avis.admin;
    final AvisAdmin x = avis;
    final TextTheme textes = Theme.of(context).textTheme;
    final String? titre = x.titre;
    final String? motif = x.motif;
    final String? lien = x.lienLibelle;
    final DateTime? accord = x.accordPublicLe;
    final DateTime? modere = x.modereLe;
    final DateTime? publie = x.publieLe;
    final bool peutPublier = x.statut == StatutAvis.enAttente;
    final bool peutRetirer = x.statut == StatutAvis.publie;
    return AppCard(
      key: AvisAdminPage.carteKey(x.id),
      entete: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.start,
        spacing: AppSpacing.sm,
        overflowSpacing: AppSpacing.sm,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(isolerSens(x.nomAffiche), style: textes.titleMedium),
          ),
          switch (x.statut) {
            StatutAvis.enAttente => StatusPill(
              libelle: a.statut.enAttente,
              ton: TonEtat.avertissement,
            ),
            StatutAvis.publie => StatusPill(
              libelle: a.statut.publie,
              ton: TonEtat.succes,
            ),
            StatutAvis.refuse => StatusPill(
              libelle: a.statut.refuse,
              ton: TonEtat.neutre,
            ),
            StatutAvis.retire => StatusPill(
              libelle: a.statut.retire,
              ton: TonEtat.neutre,
            ),
          },
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: NoteEtoiles(valeur: x.note),
          ),
          Ecart.vSm,
          if (titre != null && titre.trim().isNotEmpty) ...<Widget>[
            Text(isolerSens(titre.trim()), style: textes.titleSmall),
            Ecart.vXs,
          ],
          // Le texte, tel que la personne l'a ecrit : jamais modifiable ici.
          Text(isolerSens(x.texte), style: textes.bodyMedium),
          Ecart.vLg,
          LigneCleValeur(cle: a.champs.qualite, valeur: _qualite(x.qualite)),
          Ecart.vSm,
          LigneCleValeur(cle: a.champs.pays, valeur: nomDuPays(x.pays)),
          Ecart.vSm,
          LigneCleValeur(
            cle: a.champs.depuis,
            valeur: SelecteurMois.enMots(x.depuis),
          ),
          if (lien != null && lien.isNotEmpty) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(cle: a.champs.lien, valeur: isolerSens(lien)),
          ],
          Ecart.vSm,
          LigneCleValeur(
            cle: a.champs.depose,
            valeur: dateDeLAppareil(x.deposeLe),
          ),
          if (accord != null) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(
              cle: a.champs.accord,
              valeur: dateDeLAppareil(accord),
            ),
          ],
          if (modere != null) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(
              cle: a.champs.modere,
              valeur: dateDeLAppareil(modere),
            ),
          ],
          if (publie != null) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(
              cle: a.champs.publie,
              valeur: dateDeLAppareil(publie),
            ),
          ],
          if (motif != null && motif.trim().isNotEmpty) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(
              cle: a.champs.motif,
              valeur: isolerSens(motif.trim()),
            ),
          ],
          // Pendant une decision, les autres gestes ne sont pas rendus.
          if ((peutPublier || peutRetirer) && (enCours || !occupe)) ...<Widget>[
            Ecart.vLg,
            OverflowBar(
              alignment: MainAxisAlignment.start,
              overflowAlignment: OverflowBarAlignment.start,
              spacing: AppSpacing.sm,
              overflowSpacing: AppSpacing.sm,
              children: <Widget>[
                if (peutPublier) ...<Widget>[
                  ActionPrincipale(
                    key: AvisAdminPage.publierKey(x.id),
                    libelle: a.actions.publier,
                    niveau: NiveauAction.secondaire,
                    pleineLargeur: false,
                    enCours: enCours,
                    onPress: enCours ? null : onPublier,
                  ),
                  ActionPrincipale(
                    key: AvisAdminPage.refuserKey(x.id),
                    libelle: a.actions.refuser,
                    niveau: NiveauAction.destructive,
                    pleineLargeur: false,
                    onPress: enCours ? null : onRefuser,
                  ),
                ],
                if (peutRetirer)
                  ActionPrincipale(
                    key: AvisAdminPage.retirerKey(x.id),
                    libelle: a.actions.retirer,
                    niveau: NiveauAction.destructive,
                    pleineLargeur: false,
                    enCours: enCours,
                    onPress: enCours ? null : onRetirer,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CarteLien extends StatelessWidget {
  const _CarteLien({
    required this.lien,
    required this.maintenant,
    required this.enCours,
    required this.occupe,
    required this.onFermer,
  });

  final LienAvis lien;
  final DateTime maintenant;
  final bool enCours;
  final bool occupe;
  final VoidCallback onFermer;

  @override
  Widget build(BuildContext context) {
    final f = t.avis.admin.liens;
    final LienAvis l = lien;
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      key: AvisAdminPage.lienKey(l.id),
      entete: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.start,
        spacing: AppSpacing.sm,
        overflowSpacing: AppSpacing.sm,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(isolerSens(l.libelle), style: textes.titleMedium),
          ),
          // L'etat vient du serveur (`actif`, `ferme`) ; l'expiration et le
          // plein ne servent qu'a le nommer.
          if (l.actif)
            StatusPill(libelle: f.etat.ouvert, ton: TonEtat.succes)
          else if (l.ferme)
            StatusPill(libelle: f.etat.ferme, ton: TonEtat.neutre)
          else if (l.expireLe.isBefore(maintenant))
            StatusPill(libelle: f.etat.expire, ton: TonEtat.neutre)
          else
            StatusPill(libelle: f.etat.plein, ton: TonEtat.avertissement),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            f.recus(recus: l.avisRecus, max: l.avisMax),
            style: textes.bodyMedium,
          ),
          Ecart.vXs,
          Text(
            f.fin(date: dateDeLAppareil(l.expireLe)),
            style: textes.bodySmall,
          ),
          Text(
            f.cree(date: dateDeLAppareil(l.creeLe)),
            style: textes.bodySmall,
          ),
          if (l.actif && (enCours || !occupe)) ...<Widget>[
            Ecart.vLg,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActionPrincipale(
                key: AvisAdminPage.fermerKey(l.id),
                libelle: f.fermer,
                niveau: NiveauAction.destructive,
                pleineLargeur: false,
                enCours: enCours,
                onPress: enCours ? null : onFermer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// La feuille qui demande le motif d'un refus ou d'un retrait, redit la
/// consequence et attend une confirmation.
class _FeuilleMotif extends StatefulWidget {
  const _FeuilleMotif({
    required this.intro,
    required this.consequence,
    required this.libelleAction,
    required this.libelleRester,
    required this.motifs,
    required this.onConfirmer,
    required this.onRester,
  });

  final String intro;
  final String consequence;
  final String libelleAction;
  final String libelleRester;
  final List<String> motifs;
  final ValueChanged<String> onConfirmer;
  final VoidCallback onRester;

  @override
  State<_FeuilleMotif> createState() => _FeuilleMotifState();
}

class _FeuilleMotifState extends State<_FeuilleMotif> {
  final TextEditingController _motif = TextEditingController();
  bool _tente = false;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final bool manque = _tente && _motif.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(widget.intro, style: textes.bodyMedium),
        Ecart.vLg,
        SelecteurMotif(
          motifs: widget.motifs,
          controleur: _motif,
          erreur: manque ? t.formulaire.motif.manque : null,
          onChange: (String _) => setState(() {}),
        ),
        Ecart.vLg,
        Text(widget.consequence, style: textes.bodyMedium),
        Ecart.vLg,
        ActionPrincipale(
          key: AvisAdminPage.confirmerMotifKey,
          libelle: widget.libelleAction,
          niveau: NiveauAction.destructive,
          onPress: () {
            final String m = _motif.text.trim();
            if (m.isEmpty) {
              setState(() => _tente = true);
              return;
            }
            widget.onConfirmer(m);
          },
        ),
        Ecart.vSm,
        ActionPrincipale(
          libelle: widget.libelleRester,
          niveau: NiveauAction.tertiaire,
          onPress: widget.onRester,
        ),
      ],
    );
  }
}

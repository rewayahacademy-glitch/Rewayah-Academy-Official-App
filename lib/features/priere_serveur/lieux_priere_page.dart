import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/port_politique_revue_kyc.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/priere/libelle_priere.dart';
import '../../core/priere/lieu_priere.dart';
import '../../core/priere/service_priere.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';

/// La liste a lire de la direction : zone, cinq heures du jour, methode appliquee
/// et son origine, par enseignant. Aucune coordonnee.
final FutureProvider<List<VueEnseignantPriere>> vueEnseignantsPriereProvider =
    FutureProvider<List<VueEnseignantPriere>>(
      (Ref ref) => ref.watch(servicePriereProvider).vueEnseignants(),
    );

/// Les comptes dont le fuseau, le pays et le lieu de priere different.
final FutureProvider<List<IncoherencePriere>> incoherencesPriereProvider =
    FutureProvider<List<IncoherencePriere>>(
      (Ref ref) => ref.watch(servicePriereProvider).incoherences(),
    );

/// Le lieu et les reglages d'un enseignant, lus par la direction.
final FutureProviderFamily<LieuPriere?, String> lieuEnseignantProvider =
    FutureProvider.family<LieuPriere?, String>(
      (Ref ref, String id) =>
          ref.watch(servicePriereProvider).lieu(enseignantId: id),
    );

/// « Lieux de priere » : une liste a LIRE (PRIERE-2, « zero saisie »).
///
/// Par enseignant : sa zone, ses cinq heures du jour, la methode appliquee et
/// d'ou elle vient ; sans lieu, « en attente » (il le partage lui-meme d'un
/// toucher). Aucun champ visible : la direction ne corrige qu'une exception,
/// par « Corriger », qui ouvre une feuille courte. Ouverte depuis la section
/// « La priere » des Regles. Les signalements « a verifier » (fuseau, pays,
/// longitude) sont des avertissements : rien n'est corrige automatiquement.
///
/// Cinq etats : chargement, contenu, vide (aucun enseignant actif), erreur,
/// hors ligne (bandeau de la page).
class LieuxPrierePage extends ConsumerWidget {
  /// Cree la page.
  const LieuxPrierePage({super.key});

  /// La cle de la ligne d'un enseignant.
  static Key cleLigne(String enseignantId) =>
      ValueKey<String>('priere-enseignant-$enseignantId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<VueEnseignantPriere>> liste = ref.watch(
      vueEnseignantsPriereProvider,
    );
    final List<IncoherencePriere> incoherences =
        ref.watch(incoherencesPriereProvider).value ??
        const <IncoherencePriere>[];
    final TextTheme textes = Theme.of(context).textTheme;

    void relire() => ref
      ..invalidate(vueEnseignantsPriereProvider)
      ..invalidate(incoherencesPriereProvider);

    final Widget corps;
    if (liste.hasError) {
      corps = EmptyState(
        message: t.priere.direction.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: relire,
      );
    } else if (!liste.hasValue) {
      corps = const Skeleton.liste(lignes: 5);
    } else if (liste.requireValue.isEmpty) {
      corps = EmptyState(
        message: t.priere.direction.vide,
        icone: AppIcons.priere,
      );
    } else {
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (incoherences.isNotEmpty) ...<Widget>[
            Text(
              t.priere.direction.incoherenceTitre,
              style: textes.titleMedium,
            ),
            Ecart.vSm,
            Text(t.priere.direction.incoherenceAide, style: textes.bodyMedium),
            Ecart.vMd,
            CarteLignes(
              lignes: <Widget>[
                for (final IncoherencePriere i in incoherences)
                  SettingRow(title: _phrase(i), icon: AppIcons.avertissement),
              ],
            ),
            Ecart.vXl,
          ],
          CarteLignes(
            lignes: <Widget>[
              for (final VueEnseignantPriere e in liste.requireValue)
                SettingRow(
                  key: cleLigne(e.enseignantId),
                  title: e.prenom,
                  description: _description(e),
                  value: t.priere.direction.corriger,
                  icon: AppIcons.priere,
                  lien: true,
                  libelleSemantique: t.priere.direction.corrigerDe(
                    dePrenom: deDevant(e.prenom),
                  ),
                  onPress: () => _ouvrir(context, e),
                ),
            ],
          ),
        ],
      );
    }

    return PageShell(
      titre: t.priere.direction.titre,
      entete: SousNavigationDomaine(
        onglets: ongletsConfiguration(
          politiqueRevueKyc: ref.watch(peutReglerPolitiqueKycProvider),
        ),
        // Ouverte depuis la section « La priere » de Regles.
        indexActif: 0,
      ),
      // Un texte suivi ne s'etire pas sur tout un ecran d'ordinateur (B4, 800 px).
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(t.priere.direction.intro, style: textes.bodyMedium),
              Ecart.vXl,
              corps,
            ],
          ),
        ),
      ),
    );
  }

  void _ouvrir(BuildContext context, VueEnseignantPriere e) {
    unawaited(
      AppBottomSheet.ouvrir<void>(
        context,
        titre: t.priere.direction.feuille.titre(dePrenom: deDevant(e.prenom)),
        constructeur: (BuildContext _) => FeuilleLieuPriere(enseignant: e),
      ),
    );
  }
}

/// Les lignes de lecture d'un enseignant : la zone et d'ou elle vient, les cinq
/// heures du jour, la methode appliquee et son origine.
String _description(VueEnseignantPriere e) {
  if (!e.aUnLieu) {
    return t.priere.direction.attente;
  }
  final String source = switch (e.source) {
    'enseignant' => t.priere.direction.sourceEnseignant,
    'auto' => t.priere.direction.sourceAuto,
    _ => t.priere.direction.sourceDirection,
  };
  final String origine = switch (e.origineMethode) {
    'enseignant' => t.priere.direction.origineEnseignant,
    'pays' => t.priere.direction.originePays,
    _ => t.priere.direction.origineAcademie,
  };
  return <String>[
    t.priere.direction.zoneLigne(lieu: e.lieu ?? '', source: source),
    if (e.horaires.isNotEmpty)
      e.horaires
          .map(
            (HeurePriere h) =>
                '${libellePriere(h.priere)} ${heureChezMoi(h.instant)}',
          )
          .join(' \u00b7 '),
    if (e.methode != null)
      t.priere.direction.methodeLigne(
        methode: libelleMethode(e.methode!),
        origine: origine,
      ),
    if (e.assisteVendredi) t.priere.direction.vendredi,
  ].join('\n');
}

String _phrase(IncoherencePriere i) => switch (i.motif) {
  'fuseau_compte_different' => t.priere.direction.incoherenceFuseauCompte(
    prenom: i.prenom,
    detail: i.detail,
  ),
  'fuseau_lieu_incoherent' => t.priere.direction.incoherenceFuseauLieu(
    prenom: i.prenom,
    detail: i.detail,
  ),
  'pays_fuseau_incoherent' => t.priere.direction.incoherencePaysFuseau(
    prenom: i.prenom,
    detail: i.detail,
  ),
  _ => t.priere.direction.incoherencePays(prenom: i.prenom, detail: i.detail),
};

/// La feuille « Corriger » d'un enseignant : une exception, jamais un formulaire.
///
/// Visible : ce que le serveur a deduit (zone et origine), l'interrupteur du
/// vendredi (les heures seulement s'il est active) et un seul bouton plein.
/// Replie sous « Reglage avance » : la methode de calcul et l'ecole d'Asr
/// (automatiques par defaut) et la pose du lieu a la main, pour l'enseignant qui
/// n'a pas pu partager sa position.
class FeuilleLieuPriere extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleLieuPriere({required this.enseignant, super.key});

  /// L'enseignant que l'on corrige.
  final VueEnseignantPriere enseignant;

  @override
  ConsumerState<FeuilleLieuPriere> createState() => _FeuilleLieuEtat();
}

class _FeuilleLieuEtat extends ConsumerState<FeuilleLieuPriere> {
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _latitude = TextEditingController();
  final TextEditingController _longitude = TextEditingController();
  final TextEditingController _fuseau = TextEditingController();
  final TextEditingController _debut = TextEditingController(text: '12:30');
  final TextEditingController _fin = TextEditingController(text: '14:30');
  MethodeCalcul? _methode;
  Madhab? _ecole;
  bool _vendredi = false;
  bool _initialise = false;
  bool _avance = false;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _nom,
      _latitude,
      _longitude,
      _fuseau,
      _debut,
      _fin,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Reprend les reglages deja poses, une seule fois. Les champs de la main ne
  /// sont remplis que pour un lieu pose par la direction : la position d'un
  /// enseignant n'est pas recopiee.
  void _reprendre(LieuPriere? lieu) {
    if (_initialise) return;
    _initialise = true;
    if (lieu == null) return;
    if (lieu.source == 'direction') {
      _nom.text = lieu.lieu;
      _latitude.text = '${lieu.latitude}';
      _longitude.text = '${lieu.longitude}';
      _fuseau.text = lieu.fuseau;
    }
    _methode = lieu.methodeSurchargee ? lieu.methode : null;
    _ecole = lieu.ecoleSurchargee ? lieu.ecoleAsr : null;
    _vendredi = lieu.assisteVendredi;
    _debut.text = lieu.vendrediDebut;
    _fin.text = lieu.vendrediFin;
  }

  static final RegExp _heure = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  double? _nombre(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  /// La plage du vendredi, valide ou nulle.
  (String, String)? _plage() {
    final String debut = _debut.text.trim();
    final String fin = _fin.text.trim();
    if (!_heure.hasMatch(debut) ||
        !_heure.hasMatch(fin) ||
        debut.compareTo(fin) >= 0) {
      return null;
    }
    return (debut, fin);
  }

  DefinitionLieu? _definition() {
    final double? lat = _nombre(_latitude);
    final double? lon = _nombre(_longitude);
    final (String, String)? plage = _plage();
    if (_nom.text.trim().isEmpty ||
        _nom.text.trim().length > 80 ||
        lat == null ||
        lat < -90 ||
        lat > 90 ||
        lon == null ||
        lon < -180 ||
        lon > 180 ||
        _fuseau.text.trim().isEmpty ||
        plage == null) {
      return null;
    }
    return DefinitionLieu(
      enseignantId: widget.enseignant.enseignantId,
      lieu: _nom.text.trim(),
      latitude: lat,
      longitude: lon,
      fuseau: _fuseau.text.trim(),
      methode: _methode,
      ecoleAsr: _ecole,
      assisteVendredi: _vendredi,
      vendrediDebut: plage.$1,
      vendrediFin: plage.$2,
    );
  }

  void _rafraichir() {
    final String id = widget.enseignant.enseignantId;
    ref
      ..invalidate(vueEnseignantsPriereProvider)
      ..invalidate(incoherencesPriereProvider)
      ..invalidate(lieuEnseignantProvider(id))
      ..invalidate(pausePrevueProvider);
  }

  /// Lance une ecriture : l'erreur se dit en mots, la feuille se referme au succes.
  Future<void> _ecrire(Future<void> Function() action) async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await action();
      _rafraichir();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => _erreur = t.priere.direction.feuille.erreurEnregistrement,
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _corriger() async {
    final (String, String)? plage = _plage();
    if (plage == null) {
      setState(() => _erreur = t.priere.direction.feuille.invalide);
      return;
    }
    await _ecrire(
      () => ref
          .read(servicePriereProvider)
          .corriger(
            enseignantId: widget.enseignant.enseignantId,
            methode: _methode,
            ecoleAsr: _ecole,
            assisteVendredi: _vendredi,
            vendrediDebut: plage.$1,
            vendrediFin: plage.$2,
          ),
    );
  }

  Future<void> _poser() async {
    final DefinitionLieu? d = _definition();
    if (d == null) {
      setState(() => _erreur = t.priere.direction.feuille.invalide);
      return;
    }
    await _ecrire(() => ref.read(servicePriereProvider).definirLieu(d));
  }

  Future<void> _retirer() => _ecrire(
    () => ref
        .read(servicePriereProvider)
        .retirerLieu(widget.enseignant.enseignantId),
  );

  @override
  Widget build(BuildContext context) {
    final String id = widget.enseignant.enseignantId;
    final AsyncValue<LieuPriere?> lecture = ref.watch(
      lieuEnseignantProvider(id),
    );
    final TextTheme textes = Theme.of(context).textTheme;
    final f = t.priere.direction.feuille;

    if (lecture.hasError) {
      return EmptyState(
        message: t.priere.direction.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => ref.invalidate(lieuEnseignantProvider(id)),
      );
    }
    if (!lecture.hasValue) {
      return const Skeleton.liste(lignes: 4);
    }
    _reprendre(lecture.requireValue);
    final bool aUnLieu = lecture.requireValue != null;

    final Widget poseALaMain = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(f.poserMain, style: textes.titleSmall),
        Ecart.vSm,
        Text(f.coordonneesAide, style: textes.bodyMedium),
        Ecart.vMd,
        ChampEtiquete(
          libelle: f.nomLieu,
          controller: _nom,
          lectureSeule: _envoi,
        ),
        Ecart.vMd,
        ChampEtiquete(
          libelle: f.latitude,
          controller: _latitude,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          lectureSeule: _envoi,
        ),
        Ecart.vMd,
        ChampEtiquete(
          libelle: f.longitude,
          controller: _longitude,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          lectureSeule: _envoi,
        ),
        Ecart.vMd,
        ChampEtiquete(
          libelle: f.fuseau(exemple: 'Africa/Conakry'),
          controller: _fuseau,
          autocorrection: false,
          lectureSeule: _envoi,
        ),
        Ecart.vMd,
        LienFleche(
          libelle: f.poserLieu,
          onPress: _envoi ? null : () => unawaited(_poser()),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          aUnLieu ? _description(widget.enseignant) : f.sansLieuAide,
          style: textes.bodyMedium,
        ),
        if (aUnLieu) ...<Widget>[
          Ecart.vLg,
          CarteLignes(
            lignes: <Widget>[
              SettingRow(
                key: const ValueKey<String>('priere-vendredi'),
                title: f.vendredi,
                description: f.vendrediAide,
                controle: Switch.adaptive(
                  value: _vendredi,
                  onChanged: _envoi
                      ? null
                      : (bool v) => setState(() => _vendredi = v),
                ),
              ),
            ],
          ),
          if (_vendredi) ...<Widget>[
            Ecart.vMd,
            Text(f.plageAide, style: textes.bodyMedium),
            Ecart.vMd,
            ChampEtiquete(
              libelle: f.vendrediDebut,
              controller: _debut,
              lectureSeule: _envoi,
              autocorrection: false,
            ),
            Ecart.vMd,
            ChampEtiquete(
              libelle: f.vendrediFin,
              controller: _fin,
              lectureSeule: _envoi,
              autocorrection: false,
            ),
          ],
        ],
        Ecart.vLg,
        CarteLignes(
          lignes: <Widget>[
            SettingRow(
              key: const ValueKey<String>('priere-avance'),
              title: f.avance,
              description: f.avanceAide,
              lien: true,
              onPress: () => setState(() => _avance = !_avance),
            ),
          ],
        ),
        if (_avance) ...<Widget>[
          Ecart.vMd,
          if (aUnLieu) ...<Widget>[
            Text(f.methode, style: textes.titleSmall),
            Ecart.vSm,
            MenuFiltre<MethodeCalcul>(
              libelle: f.methodeAuto,
              valeur: _methode,
              entrees: <EntreeFiltre<MethodeCalcul>>[
                EntreeFiltre<MethodeCalcul>(
                  valeur: null,
                  libelle: f.methodeAuto,
                ),
                for (final MethodeCalcul m in MethodeCalcul.values)
                  EntreeFiltre<MethodeCalcul>(
                    valeur: m,
                    libelle: libelleMethode(m),
                  ),
              ],
              onChoix: (MethodeCalcul? m) => setState(() => _methode = m),
            ),
            Ecart.vLg,
            Text(f.ecole, style: textes.titleSmall),
            Ecart.vSm,
            ControleSegmente<Madhab?>(
              valeur: _ecole,
              segments: <Segment<Madhab?>>[
                Segment<Madhab?>(valeur: null, libelle: f.ecoleAuto),
                for (final Madhab m in Madhab.values)
                  Segment<Madhab?>(valeur: m, libelle: libelleEcoleAsr(m)),
              ],
              onChange: (Madhab? m) => setState(() => _ecole = m),
            ),
            Ecart.vLg,
          ],
          poseALaMain,
        ],
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            _erreur!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (aUnLieu) ...<Widget>[
          Ecart.vLg,
          ActionPrincipale(
            libelle: f.enregistrer,
            enCours: _envoi,
            onPress: _corriger,
          ),
          Ecart.vMd,
          LienFleche(
            libelle: f.retirer,
            onPress: _envoi ? null : () => unawaited(_retirer()),
          ),
        ],
      ],
    );
  }
}

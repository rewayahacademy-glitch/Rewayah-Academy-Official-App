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
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';

/// Les enseignants et l'etat de leur lieu de priere, lus par la direction.
final FutureProvider<List<EnseignantPriere>> enseignantsPriereProvider =
    FutureProvider<List<EnseignantPriere>>(
      (Ref ref) => ref.watch(servicePriereProvider).enseignants(),
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

/// Les cinq heures du jour d'un enseignant, lues par la direction.
final FutureProviderFamily<List<HeurePriere>, String>
horairesEnseignantProvider = FutureProvider.family<List<HeurePriere>, String>(
  (Ref ref, String id) =>
      ref.watch(servicePriereProvider).horairesDuJour(enseignantId: id),
);

/// « Lieux de priere » : la direction pose le lieu de chaque enseignant, avec
/// l'apercu de ses cinq heures du jour (PRIERE-1, P3).
///
/// Un onglet de la Configuration. La position est une donnee personnelle : elle
/// ne se lit qu'ici, par la direction, et chez l'enseignant. Les signalements
/// « a verifier » (fuseau, pays, longitude) sont des avertissements : rien n'est
/// corrige automatiquement.
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
    final AsyncValue<List<EnseignantPriere>> liste = ref.watch(
      enseignantsPriereProvider,
    );
    final List<IncoherencePriere> incoherences =
        ref.watch(incoherencesPriereProvider).value ??
        const <IncoherencePriere>[];
    final TextTheme textes = Theme.of(context).textTheme;

    void relire() => ref
      ..invalidate(enseignantsPriereProvider)
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
              for (final EnseignantPriere e in liste.requireValue)
                SettingRow(
                  key: cleLigne(e.enseignantId),
                  title: e.prenom,
                  description: e.aUnLieu
                      ? <String>[
                          '${e.lieu}',
                          if (e.assisteVendredi) t.priere.direction.vendredi,
                        ].join('\n')
                      : t.priere.direction.sansLieu,
                  icon: AppIcons.priere,
                  onPress: () => _ouvrir(context, ref, e),
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
        // Ouverte depuis la section « La prière » de Règles.
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

  void _ouvrir(BuildContext context, WidgetRef ref, EnseignantPriere e) {
    unawaited(
      AppBottomSheet.ouvrir<void>(
        context,
        titre: t.priere.direction.feuille.titre(dePrenom: deDevant(e.prenom)),
        constructeur: (BuildContext _) => FeuilleLieuPriere(enseignant: e),
      ),
    );
  }
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

/// La feuille « Lieu et heures de priere » d'un enseignant.
class FeuilleLieuPriere extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleLieuPriere({required this.enseignant, super.key});

  /// L'enseignant dont on pose le lieu.
  final EnseignantPriere enseignant;

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

  /// Reprend le lieu deja pose, une seule fois.
  void _reprendre(LieuPriere? lieu) {
    if (_initialise) return;
    _initialise = true;
    if (lieu == null) return;
    _nom.text = lieu.lieu;
    _latitude.text = '${lieu.latitude}';
    _longitude.text = '${lieu.longitude}';
    _fuseau.text = lieu.fuseau;
    _methode = lieu.methodeSurchargee ? lieu.methode : null;
    _ecole = lieu.ecoleSurchargee ? lieu.ecoleAsr : null;
    _vendredi = lieu.assisteVendredi;
    _debut.text = lieu.vendrediDebut;
    _fin.text = lieu.vendrediFin;
  }

  static final RegExp _heure = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  double? _nombre(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  DefinitionLieu? _definition() {
    final double? lat = _nombre(_latitude);
    final double? lon = _nombre(_longitude);
    final String debut = _debut.text.trim();
    final String fin = _fin.text.trim();
    if (_nom.text.trim().isEmpty ||
        _nom.text.trim().length > 80 ||
        lat == null ||
        lat < -90 ||
        lat > 90 ||
        lon == null ||
        lon < -180 ||
        lon > 180 ||
        _fuseau.text.trim().isEmpty ||
        !_heure.hasMatch(debut) ||
        !_heure.hasMatch(fin) ||
        debut.compareTo(fin) >= 0) {
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
      vendrediDebut: debut,
      vendrediFin: fin,
    );
  }

  void _rafraichir() {
    final String id = widget.enseignant.enseignantId;
    ref
      ..invalidate(enseignantsPriereProvider)
      ..invalidate(incoherencesPriereProvider)
      ..invalidate(lieuEnseignantProvider(id))
      ..invalidate(horairesEnseignantProvider(id))
      ..invalidate(pausePrevueProvider);
  }

  Future<void> _enregistrer() async {
    final DefinitionLieu? d = _definition();
    if (d == null) {
      setState(() => _erreur = t.priere.direction.feuille.invalide);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref.read(servicePriereProvider).definirLieu(d);
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

  Future<void> _retirer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(servicePriereProvider)
          .retirerLieu(widget.enseignant.enseignantId);
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

  Future<void> _choisirMethode() async {
    final MethodeCalcul? ecole = await _choisir<MethodeCalcul>(
      titre: t.priere.direction.feuille.methode,
      defaut: t.priere.direction.feuille.methodeEcole,
      valeurs: MethodeCalcul.values,
      libelle: libelleMethode,
      cle: (MethodeCalcul m) => m.valeurSql,
      courante: _methode,
    );
    if (!mounted) return;
    setState(() => _methode = ecole);
  }

  Future<void> _choisirEcole() async {
    final Madhab? ecole = await _choisir<Madhab>(
      titre: t.priere.direction.feuille.ecole,
      defaut: t.priere.direction.feuille.ecoleEcole,
      valeurs: Madhab.values,
      libelle: libelleEcoleAsr,
      cle: (Madhab m) => m.valeurSql,
      courante: _ecole,
    );
    if (!mounted) return;
    setState(() => _ecole = ecole);
  }

  /// Une feuille de choix : « celle de l'academie », ou une valeur propre a
  /// l'enseignant. Rend `null` pour « celle de l'academie ».
  Future<T?> _choisir<T extends Object>({
    required String titre,
    required String defaut,
    required List<T> valeurs,
    required String Function(T) libelle,
    required String Function(T) cle,
    required T? courante,
  }) async {
    T? retenue = courante;
    await AppBottomSheet.ouvrir<void>(
      context,
      titre: titre,
      constructeur: (BuildContext contexte) => ChoiceCardGroup(
        autoriserSaisieLibre: false,
        valeurInitiale: ReponseChoix(
          valeurs: <String>{courante == null ? '' : cle(courante)},
        ),
        options: <OptionChoix>[
          OptionChoix(valeur: '', libelle: defaut),
          for (final T v in valeurs)
            OptionChoix(valeur: cle(v), libelle: libelle(v)),
        ],
        onChange: (ReponseChoix r) {
          final String choix = r.valeurs.isEmpty ? '' : r.valeurs.first;
          retenue = choix.isEmpty
              ? null
              : valeurs.firstWhere((T v) => cle(v) == choix);
          Navigator.of(contexte).pop();
        },
      ),
    );
    return retenue;
  }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChampEtiquete(
          libelle: f.nomLieu,
          controller: _nom,
          obligatoire: true,
          lectureSeule: _envoi,
        ),
        Ecart.vMd,
        ChampEtiquete(
          libelle: f.latitude,
          controller: _latitude,
          obligatoire: true,
          aide: f.coordonneesAide,
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
          obligatoire: true,
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
          obligatoire: true,
          autocorrection: false,
          lectureSeule: _envoi,
        ),
        Ecart.vLg,
        CarteLignes(
          lignes: <Widget>[
            SettingRow(
              title: f.methode,
              description: t.priere.aValider,
              value: _methode == null
                  ? f.methodeEcole
                  : libelleMethode(_methode!),
              onPress: _envoi ? null : () => unawaited(_choisirMethode()),
            ),
            SettingRow(
              title: f.ecole,
              description: t.priere.aValider,
              value: _ecole == null ? f.ecoleEcole : libelleEcoleAsr(_ecole!),
              onPress: _envoi ? null : () => unawaited(_choisirEcole()),
            ),
          ],
        ),
        Ecart.vLg,
        Text(f.vendredi, style: textes.titleSmall),
        Ecart.vSm,
        ControleSegmente<bool>(
          valeur: _vendredi,
          segments: <Segment<bool>>[
            Segment<bool>(valeur: true, libelle: f.vendrediOui),
            Segment<bool>(valeur: false, libelle: f.vendrediNon),
          ],
          onChange: (bool v) => setState(() => _vendredi = v),
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
        Ecart.vLg,
        Text(f.apercu, style: textes.titleSmall),
        Ecart.vSm,
        if (aUnLieu)
          _Apercu(enseignantId: id)
        else
          Text(f.apercuVide, style: textes.bodyMedium),
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            _erreur!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          libelle: f.enregistrer,
          enCours: _envoi,
          onPress: _enregistrer,
        ),
        if (aUnLieu) ...<Widget>[
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

/// L'apercu des cinq heures du jour de l'enseignant.
class _Apercu extends ConsumerWidget {
  const _Apercu({required this.enseignantId});

  final String enseignantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<HeurePriere>> heures = ref.watch(
      horairesEnseignantProvider(enseignantId),
    );
    if (heures.hasError) {
      return Text(t.priere.direction.erreur);
    }
    if (!heures.hasValue) {
      return const Skeleton.liste(lignes: 5);
    }
    return CarteLignes(
      lignes: <Widget>[
        for (final HeurePriere h in heures.requireValue)
          SettingRow(
            title: libellePriere(h.priere),
            value: heureChezMoi(h.instant),
            description: h.approximee ? t.priere.approchee : null,
          ),
      ],
    );
  }
}

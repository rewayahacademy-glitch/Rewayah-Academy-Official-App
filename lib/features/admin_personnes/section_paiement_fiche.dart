// PAIEMENT-UNIFIE P5 (directeur, 23/11/2026) : la section « Paiement » de la
// fiche d'un eleve, lue par la direction.
//
// Rien n'est recree : l'etat vient de `fiche_eleve_direction` (bloc
// `paiement`, deduit par le serveur des factures, des credits, des
// suspensions et des remises), et chaque geste ouvre la feuille qui existait
// deja dans la Finance (`tarifs_particuliers.dart`) ou fait l'unique appel
// nouveau, « Demander maintenant ». Quatre gestes : Prix special, Exonerer,
// Reporter (le meme acces offert, pose en un choix) et Demander maintenant ;
// « Retirer la remise » apparait quand une remise est en cours.
//
// Une seule carte de lecture, une seule carte de gestes, separees (K-55).
// Chaque geste dit ce qu'il fait avant qu'on le choisisse (K-58). Un echec
// dit « non confirme », jamais « non envoye » (K-59).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/fiche_eleve_direction.dart';
import '../../core/capacites/port_tarifs_particuliers.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/montant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/selecteur_mois.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_finance/paiements/tarifs_particuliers.dart';

/// La section « Paiement » de la fiche de l'eleve [eleveId].
class SectionPaiementFiche extends ConsumerStatefulWidget {
  /// Cree la section.
  const SectionPaiementFiche({
    required this.eleveId,
    required this.prenom,
    required this.paiement,
    required this.nom,
    super.key,
  });

  /// L'eleve.
  final String eleveId;

  /// Son prenom (vide sous masquage d'identite).
  final String prenom;

  /// Son nom d'affichage ; repli : son matricule.
  final String nom;

  /// Ce que le serveur a rendu.
  final PaiementFiche paiement;

  /// La cle de la section.
  static const Key cle = ValueKey<String>('fiche-eleve-paiement');

  /// La cle d'un geste : `prix`, `exonerer`, `reporter`, `demander`,
  /// `retirer`.
  static Key cleGeste(String nom) => ValueKey<String>('fiche-paiement-$nom');

  /// La cle de l'etat.
  static const Key cleEtat = ValueKey<String>('fiche-paiement-etat');

  @override
  ConsumerState<SectionPaiementFiche> createState() =>
      _SectionPaiementFicheState();
}

enum _Issue { aucune, demandee, rien, echec }

class _SectionPaiementFicheState extends ConsumerState<SectionPaiementFiche> {
  _Issue _issue = _Issue.aucune;
  bool _enCours = false;

  PaiementFiche get _p => widget.paiement;

  void _relire() => ref.invalidate(ficheEleveDirectionProvider(widget.eleveId));

  /// Le prenom pour les phrases : sous masquage d'identite, le nom d'affichage.
  String get _prenom => widget.prenom.isEmpty ? widget.nom : widget.prenom;

  String? get _devise => _p.facture?.devise ?? _p.remise?.devise;

  /// Hors ligne ou un envoi en cours : le geste ne part pas (la phrase du bas
  /// dit pourquoi), il n'est pas grise.
  bool get _peutAgir =>
      !(ref.read(horsLigneProvider).value ?? false) && !_enCours;

  Future<void> _ouvrirTarif({
    required NatureTarif nature,
    bool report = false,
  }) async {
    if (!_peutAgir) return;
    final bool change = await ouvrirTarifParticulier(
      context,
      profilId: widget.eleveId,
      prenom: _prenom,
      devise: _devise,
      report: report,
      nature: nature,
    );
    if (change && mounted) _relire();
  }

  Future<void> _retirer() async {
    final RemiseFiche? r = _p.remise;
    if (r == null || !_peutAgir) return;
    final bool change = await ouvrirRetraitTarif(
      context,
      TarifParticulier(
        profilId: widget.eleveId,
        prenom: _prenom,
        nature: switch (r.nature) {
          'acces_offert' => NatureTarif.accesOffert,
          'prix_special' => NatureTarif.prixSpecial,
          _ => NatureTarif.bourse,
        },
        moisFin: r.moisFin,
        motif: '',
        pourMille: r.pourMille,
        montantMensuel: r.montantMineur == null || r.devise == null
            ? null
            : Montant(r.montantMineur!, r.devise!),
      ),
    );
    if (change && mounted) _relire();
  }

  Future<void> _demander() async {
    if (!_peutAgir) return;
    final PortFicheEleveDirection? port = ref.read(
      portFicheEleveDirectionProvider,
    );
    if (port == null) return;
    setState(() {
      _enCours = true;
      _issue = _Issue.aucune;
    });
    try {
      final ResultatDemandePaiement r = await port.demanderPaiement(
        widget.eleveId,
      );
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _issue = r == ResultatDemandePaiement.demandee
            ? _Issue.demandee
            : _Issue.rien;
      });
      _relire();
    } on Object {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _issue = _Issue.echec;
      });
    }
  }

  (String, TonEtat) _etat(EtatPaiementEleve e) {
    final p = t.admin.ficheEleve.paiement;
    return switch (e) {
      EtatPaiementEleve.aPayer => (p.aPayer, TonEtat.avertissement),
      EtatPaiementEleve.paye => (p.paye, TonEtat.succes),
      EtatPaiementEleve.enRetard => (p.enRetard, TonEtat.alerte),
      EtatPaiementEleve.exonere => (p.exonere, TonEtat.accent),
    };
  }

  String? _valeurFacture() {
    final FactureFiche? f = _p.facture;
    if (f == null) return null;
    final p = t.admin.ficheEleve.paiement;
    final String montant = formaterMontant(Montant(f.totalMineur, f.devise));
    final String mois = SelecteurMois.enMots(f.mois);
    return f.statut == 'financee'
        ? p.facPayee(montant: montant, mois: mois)
        : p.facAPayer(montant: montant, mois: mois);
  }

  String? _valeurRemise() {
    final RemiseFiche? r = _p.remise;
    if (r == null) return null;
    return valeurTarif(
      TarifParticulier(
        profilId: widget.eleveId,
        prenom: _prenom,
        nature: switch (r.nature) {
          'acces_offert' => NatureTarif.accesOffert,
          'prix_special' => NatureTarif.prixSpecial,
          _ => NatureTarif.bourse,
        },
        moisFin: r.moisFin,
        motif: '',
        pourMille: r.pourMille,
        montantMensuel: r.montantMineur == null || r.devise == null
            ? null
            : Montant(r.montantMineur!, r.devise!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = t.admin.ficheEleve.paiement;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final (String, TonEtat) etat = _etat(_p.etat);
    final String? facture = _valeurFacture();
    final String? remise = _valeurRemise();
    Widget ligne(String cle, String valeur) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: LigneCleValeur(cle: cle, valeur: valeur),
    );
    return KeyedSubtree(
      key: SectionPaiementFiche.cle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SectionHeader(titre: p.titre),
          Ecart.vSm,
          CarteLignes(
            lignes: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(p.etat)),
                    StatusPill(
                      key: SectionPaiementFiche.cleEtat,
                      libelle: etat.$1,
                      ton: etat.$2,
                    ),
                  ],
                ),
              ),
              ligne(
                p.premier,
                _p.dejaPaye ? p.premierRecu : p.premierPasEncore,
              ),
              ?(facture == null ? null : ligne(p.facture, facture)),
              ?(remise == null ? null : ligne(p.remise, remise)),
            ],
          ),
          if (_issue != _Issue.aucune) ...<Widget>[
            Ecart.vLg,
            switch (_issue) {
              _Issue.demandee => BandeauAttention(
                titre: p.demandeTitre,
                message: p.demandePhrase,
                ton: TonEtat.succes,
              ),
              _Issue.rien => BandeauAttention(
                titre: p.rienTitre,
                message: p.rienPhrase,
                ton: TonEtat.accent,
              ),
              _ => BandeauAttention(
                titre: p.echecTitre,
                message: p.echecPhrase,
                ton: TonEtat.alerte,
              ),
            },
          ],
          Ecart.vLg,
          CarteLignes(
            lignes: <Widget>[
              SettingRow(
                key: SectionPaiementFiche.cleGeste('prix'),
                title: p.prixSpecial,
                description: p.prixSpecialAide,
                lien: true,
                onPress: () => _ouvrirTarif(nature: NatureTarif.prixSpecial),
              ),
              SettingRow(
                key: SectionPaiementFiche.cleGeste('exonerer'),
                title: p.exonerer,
                description: p.exonererAide,
                lien: true,
                onPress: () => _ouvrirTarif(nature: NatureTarif.accesOffert),
              ),
              SettingRow(
                key: SectionPaiementFiche.cleGeste('reporter'),
                title: p.reporter,
                description: p.reporterAide,
                lien: true,
                onPress: () =>
                    _ouvrirTarif(nature: NatureTarif.accesOffert, report: true),
              ),
              SettingRow(
                key: SectionPaiementFiche.cleGeste('demander'),
                title: p.demander,
                description: p.demanderAide,
                lien: true,
                onPress: _demander,
              ),
              ?(_p.remise == null
                  ? null
                  : SettingRow(
                      key: SectionPaiementFiche.cleGeste('retirer'),
                      title: p.retirer,
                      description: p.retirerAide,
                      lien: true,
                      onPress: _retirer,
                    )),
            ],
          ),
          if (horsLigne) ...<Widget>[
            Ecart.vMd,
            Text(
              t.admin.finance.pai.horsLigne,
              style: AppPalette.of(context).inkMuted.applyTo(
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

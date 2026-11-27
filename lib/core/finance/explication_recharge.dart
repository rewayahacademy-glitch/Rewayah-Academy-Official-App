// L'explication d'un paiement, mise en mots (PAIEMENT-FAMILLE-PRIX, directeur,
// 23/11/2026 : « il faut dire quoi, quand et pourquoi »).
//
// **Aucun chiffre n'est calcule ici** (FI6) : chaque montant, chaque mois,
// chaque taux, chaque nombre de seances arrive du serveur
// (`recharge_beneficiaires`) et se met en mots. Ce fichier ne fait que
// choisir la phrase qui dit un code (`premier_inscrit`, `plafond_atteint`...)
// et assembler une liste de mois (« decembre et janvier »).
//
// Un code que ce fichier ne connait pas est ignore : une ligne en trop
// vaut mieux qu'un paiement qu'on ne peut plus ouvrir ; le test de ce fichier
// liste tous les codes que le serveur rend aujourd'hui.

import 'package:flutter/foundation.dart';

import '../capacites/port_recharge_foyer.dart';
import '../i18n/isolat_bidi.dart';
import '../i18n/strings.g.dart';
import 'format_montant.dart';
import 'montant.dart';

/// Une ligne de l'explication : ce qu'elle dit, sa valeur (un montant mis en
/// mots) et son registre.
@immutable
class LigneExplication {
  /// Cree la ligne.
  const LigneExplication({
    required this.cle,
    this.valeur,
    this.detail,
    this.note = false,
    this.fort = false,
  });

  /// Ce que la ligne designe (« Prix de 2 mois »).
  final String cle;

  /// Le montant, deja formate, ou `null` pour une phrase seule.
  final String? valeur;

  /// Une precision sous la cle, ou `null`.
  final String? detail;

  /// Vrai pour une phrase attenuee (une remise non accordee).
  final bool note;

  /// Vrai pour la ligne qui conclut (le total).
  final bool fort;
}

/// Le nom d'un mois, en toutes lettres, dans la langue de l'ecran.
String nomDuMois(DateTime d, {bool avecAnnee = false}) {
  final String nom = t.commun.dates.mois[d.month - 1];
  return avecAnnee ? '$nom ${d.year}' : nom;
}

/// Une liste de mois : « novembre », « novembre et decembre »,
/// « novembre, decembre et janvier ».
String listeDeMois(List<DateTime> mois) {
  final List<String> noms = <String>[
    for (final DateTime m in mois) nomDuMois(m),
  ];
  return switch (noms.length) {
    0 => '',
    1 => noms.first,
    _ => t.adulte.recharge.explication.mois.et(
      liste: noms
          .sublist(0, noms.length - 1)
          .join(t.adulte.recharge.explication.mois.separateur),
      dernier: noms.last,
    ),
  };
}

/// Les mois qu'une offre couvre : un mois, deux mois, ou « de decembre a
/// mars » (l'annee s'ajoute quand la periode en change).
String moisCouvertsEnLettres(MoisCouverts m) {
  if (m.nbMois <= 1) return nomDuMois(m.debut);
  if (m.nbMois == 2) return listeDeMois(<DateTime>[m.debut, m.fin]);
  final bool annee = m.debut.year != m.fin.year;
  return t.adulte.recharge.explication.mois.plage(
    debut: nomDuMois(m.debut, avecAnnee: annee),
    fin: nomDuMois(m.fin, avecAnnee: annee),
  );
}

/// Un taux en pour mille mis en mots : 80 donne « 8 % », 125 « 12,5 % ».
String pourcentage(int pourMille) {
  final int entier = pourMille ~/ 10;
  final int dixieme = pourMille % 10;
  return dixieme == 0 ? '$entier %' : '$entier,$dixieme %';
}

String _m(Montant m) => sansAncre(formaterMontant(m));

String _moisDus(BeneficiaireRecharge b) => listeDeMois(<DateTime>[
  for (final MoisDu m in b.dette?.mois ?? const <MoisDu>[]) m.mois,
]);

/// La phrase qui dit ce que la famille paie pour ce profil avec cette offre :
/// « Vous payez d'abord 25,30 $ (novembre), puis 2 mois d'avance (decembre et
/// janvier) : 135,30 $ en tout. »
String phraseSynthese(BeneficiaireRecharge b, OptionPaiement o) {
  final e = t.adulte.recharge.explication.synthese;
  final MoisCouverts? couverts = o.moisCouverts;
  if (o.nbMois == 0) {
    return e.detteSeule(montant: _m(o.montant), mois: _moisDus(b));
  }
  if (couverts == null) {
    // Avant le premier mois reel : le mois couvert n'est pas encore connu.
    final String mois = e.moisSansDate(montant: _m(o.avance));
    return o.dette.estNul
        ? mois
        : '${e.detteSeule(montant: _m(o.dette), mois: _moisDus(b))} $mois';
  }
  if (o.dette.estNul) {
    return e.avanceSeule(
      n: o.nbMois,
      moisCouverts: moisCouvertsEnLettres(couverts),
      montant: _m(o.montant),
    );
  }
  return e.detteEtAvance(
    n: o.nbMois,
    dette: _m(o.dette),
    moisDus: _moisDus(b),
    moisCouverts: moisCouvertsEnLettres(couverts),
    montant: _m(o.montant),
  );
}

/// La phrase d'un profil auquel rien n'est proposable, ou `null`.
String? phraseEtat(BeneficiaireRecharge b) {
  if (b.options.isNotEmpty) return null;
  return switch (b.etat) {
    EtatRecharge.aucunCreneau =>
      t.adulte.recharge.explication.synthese.aucunCreneau,
    _ => null,
  };
}

/// La phrase « un seul mois avant le debut des cours », ou `null`.
String? phraseAvantPremierMois(BeneficiaireRecharge b) =>
    b.etat == EtatRecharge.avantPremierMois && b.options.isNotEmpty
    ? t.adulte.recharge.explication.synthese.avantPremierMois
    : null;

/// Le detail, ligne par ligne : ce qui est du d'abord, puis les mois d'avance
/// avec leurs remises, puis ce qui n'a pas ete accorde et pourquoi.
List<LigneExplication> detailOption(BeneficiaireRecharge b, OptionPaiement o) {
  final e = t.adulte.recharge.explication;
  final List<LigneExplication> lignes = <LigneExplication>[];

  final DetteRecharge? dette = b.dette;
  if (dette != null && dette.mois.isNotEmpty) {
    lignes.add(LigneExplication(cle: e.dette.titre));
    for (final MoisDu m in dette.mois) {
      lignes.add(
        LigneExplication(
          cle: m.apercu
              ? e.dette.moisApercu(mois: nomDuMois(m.mois))
              : nomDuMois(m.mois),
          valeur: _m(m.montant),
        ),
      );
      // Le calcul du mois : prix, remise de famille, prorata (D3).
      for (final LigneDue l in m.lignes) {
        final String? cle = cleLigneDue(l);
        if (cle == null) continue;
        lignes.add(
          LigneExplication(
            cle: cle,
            valeur: _m(l.montant),
            detail: l.nature == 'prorata' ? _detailFacture(m) : null,
            note: true,
          ),
        );
      }
    }
    if (!dette.solde.estNul) {
      lignes.add(
        LigneExplication(
          cle: e.dette.solde,
          valeur: sansAncre(formaterMontant(dette.solde, signe: true)),
          note: true,
        ),
      );
    }
  }

  if (o.nbMois > 0) {
    for (final LigneOption l in o.lignes) {
      final String? cle = _cleLigne(l, o);
      if (cle == null) continue;
      lignes.add(
        LigneExplication(
          cle: cle,
          valeur: l.montant == null ? null : _m(l.montant!),
        ),
      );
    }
  }

  lignes.add(
    LigneExplication(cle: e.ligne.total, valeur: _m(o.montant), fort: true),
  );

  for (final RemiseNonAppliquee n in o.nonAppliquees) {
    final String? phrase = _phraseNonAppliquee(n);
    if (phrase != null) lignes.add(LigneExplication(cle: phrase, note: true));
  }
  return lignes;
}

/// Le prorata d'un mois du (« Debut le 14 novembre : 6 seances sur 12 »).
String? _detailFacture(MoisDu m) {
  final ProrataExplique? p = m.prorata;
  if (p == null) return null;
  return t.adulte.recharge.explication.dette.prorata(
    restantes: p.seancesRestantes,
    total: p.seancesDuMois,
    date: '${p.entreeLe.day} ${nomDuMois(p.entreeLe)}',
  );
}

String? _cleLigne(LigneOption l, OptionPaiement o) {
  final ligne = t.adulte.recharge.explication.ligne;
  return switch (l.code) {
    'prix' => ligne.prix(n: l.nbMois ?? o.nbMois),
    'remise_famille' => ligne.remiseFamille(
      rang: l.rang ?? 0,
      taux: pourcentage(l.pourMille ?? 0),
    ),
    'remise_prepaiement' => ligne.remisePrepaiement(
      taux: pourcentage(l.pourMille ?? 0),
    ),
    'plafond' => ligne.plafond(taux: pourcentage(l.pourMille ?? 0)),
    'arrondi' => ligne.arrondi,
    'bourse' => ligne.bourse,
    'prix_special' => ligne.prixSpecial,
    'acces_offert' => ligne.accesOffert,
    _ => null,
  };
}

String? _phraseNonAppliquee(RemiseNonAppliquee n) {
  final non = t.adulte.recharge.explication.nonAppliquee;
  return switch ((n.type, n.code)) {
    ('remise_famille', 'premier_inscrit') => non.premierInscrit,
    ('remise_famille', 'prix_special_non_cumulable') => non.familleSpecial,
    ('remise_famille', 'acces_offert_non_cumulable') => non.familleOffert,
    ('remise_famille', 'bourse_non_cumulable') => non.familleBourse,
    ('remise_prepaiement', 'moins_de_trois_mois') =>
      non.prepaiementMoinsDeTrois,
    ('remise_prepaiement', 'prix_special_non_cumulable') =>
      non.prepaiementSpecial,
    ('remise_prepaiement', 'acces_offert_non_cumulable') =>
      non.prepaiementOffert,
    ('remise_prepaiement', 'bourse_non_cumulable') => non.prepaiementBourse,
    ('remise', 'plafond_atteint') => non.plafondAtteint(
      taux: pourcentage(n.pourMille ?? 0),
      montant: n.montant == null ? '' : _m(n.montant!),
    ),
    _ => null,
  };
}

/// Les lignes d'une facture due, mises en mots (le detail d'un mois).
String? cleLigneDue(LigneDue l) {
  final d = t.adulte.recharge.explication.dette;
  return switch (l.nature) {
    'tarif' => d.factureTarif,
    'remise_rang' => d.factureRemiseRang(rang: l.rang ?? 0),
    'prorata' => d.factureProrata,
    'remise_prepaiement' => d.facturePrepaiement,
    'bourse' => t.adulte.recharge.explication.ligne.bourse,
    _ => null,
  };
}

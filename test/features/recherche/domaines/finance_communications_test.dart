// RECH-D4 : finance (encaissements FI/CPT), fils de Messages et canaux du
// Studio, sur les doubles de demonstration des modules (spec RECH-03 §3,
// §12 ; SEC-R01, R09, R13). Les fils se cherchent sans messages globaux ;
// le texte reste interne au module ; aucun droit FI/CPT supplementaire ;
// aucun montant n'est cherche ni rendu.

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Provider, ProviderContainer;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_encaissements.dart';
import 'package:rewayah_academy/core/recherche/modeles_recherche.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';
import 'package:rewayah_academy/features/demo/comptable/encaissements_demo.dart';
import 'package:rewayah_academy/features/recherche/domaines/finance_communications/moteur_fils.dart';
import 'package:rewayah_academy/features/recherche/domaines/finance_communications/moteur_finances.dart';
import 'package:rewayah_academy/features/recherche/domaines/finance_communications/moteurs_finance_communications.dart';
import 'package:rewayah_academy/features/recherche/resolveur_cible.dart';

const ContexteRecherche _comptable = ContexteRecherche(
  espace: EspaceRecherche.comptable,
);
const ContexteRecherche _famille = ContexteRecherche(
  espace: EspaceRecherche.famille,
);
const ContexteRecherche _admin = ContexteRecherche(
  espace: EspaceRecherche.administration,
);

final DateTime _maintenant = DateTime(2026, 10, 11, 18);

ResumeFil _fil(
  String id,
  String objet, {
  String interlocuteur = 'Mme Nour',
  String? apercu,
  TypeObjetLie type = TypeObjetLie.classe,
}) => ResumeFil(
  id: id,
  objet: ObjetLie(type: type, id: 'o-$id', libelle: objet),
  interlocuteurs: <Participant>[
    Participant(
      id: 'p-$id',
      nomAffiche: interlocuteur,
      fonction: 'Enseignante',
    ),
  ],
  apercu: apercu,
);

class _FilsFixes extends MessagesMetierIndisponibles {
  const _FilsFixes(this.fils_);
  final List<ResumeFil> fils_;

  @override
  Future<List<ResumeFil>> fils() async => fils_;
}

class _EncaissementsEnRefus extends EncaissementsIndisponibles {
  const _EncaissementsEnRefus();
}

class _StudioEnPanne extends StudioIndisponible {
  const _StudioEnPanne();
}

void main() {
  group('finance : encaissements', () {
    final MoteurEncaissements moteur = MoteurEncaissements(EncaissementsDemo());

    test('trouve par reference ou par nom de famille', () async {
      final ReponseOk parRef = await moteur.rechercher(
        requete: 'demo-7a21',
        contexte: _comptable,
      ) as ReponseOk;
      expect(parRef.elements.single.titre, 'DEMO-7A21');
      expect(parRef.elements.single.cible.kind, KindCible.operation);
      final ReponseOk parFamille = await moteur.rechercher(
        requete: 'famille bah',
        contexte: _comptable,
      ) as ReponseOk;
      expect(parFamille.elements, isNotEmpty);
      expect(
        parFamille.elements.map((ResultatRecherche e) => e.contexte).join(),
        contains('Famille Bah'),
      );
    });

    test(
      'ni montant ni moyen ni prestataire : ni cherches ni rendus',
      () async {
        final List<Encaissement> tous = await EncaissementsDemo().liste(
          FiltreEncaissements.tout,
        );
        final Encaissement e = tous.first;
        for (final String secret in <String>[
          '${e.brut.mineur}',
          e.moyen,
          e.prestataire,
        ]) {
          final ReponseOk r = await moteur.rechercher(
            requete: secret,
            contexte: _comptable,
          ) as ReponseOk;
          for (final ResultatRecherche x in r.elements) {
            // Une reference ou une famille qui contiendrait le mot par hasard
            // reste un resultat legitime : le champ cherche est la seule cause.
            expect(
              '${x.titre} ${x.contexte}'.toLowerCase(),
              contains(secret.toLowerCase()),
            );
          }
        }
        final ReponseOk r = await moteur.rechercher(
          requete: 'famille',
          contexte: _comptable,
        ) as ReponseOk;
        for (final ResultatRecherche x in r.elements) {
          expect(x.extrait, isNull);
          expect(
            '${x.titre} ${x.contexte}',
            isNot(contains(RegExp(r'\d+\s?(€|\$|USD|EUR)'))),
          );
        }
      },
    );

    test('aucun droit supplementaire : seul le comptable est servi', () async {
      for (final EspaceRecherche e in EspaceRecherche.values) {
        final ContexteRecherche c = ContexteRecherche(espace: e);
        expect(
          await moteur.disponiblePour(c),
          e == EspaceRecherche.comptable,
          reason: e.name,
        );
        if (e != EspaceRecherche.comptable) {
          expect(
            await moteur.rechercher(requete: 'bah', contexte: c),
            isA<ReponseEchec>(),
            reason: e.name,
          );
        }
      }
    });

    test('un refus du module est un echec, jamais un vide', () async {
      const PortRecherche port = PortRechercheParMoteurs(
        <MoteurRechercheDomaine>[MoteurEncaissements(_EncaissementsEnRefus())],
      );
      final ReponseDomaine r = await port.rechercher(
        domaine: DomaineRecherche.finances,
        requete: 'bah',
        contexte: _comptable,
      );
      expect(r, isA<ReponseEchec>());
    });

    test('la cible ouvre le detail de l\'encaissement, au comptable seul', () {
      const CibleRecherche c = CibleRecherche(
        kind: KindCible.operation,
        reference: 'enc-1',
      );
      expect(
        cheminPourCible(c, EspaceRecherche.comptable),
        Routes.comptableEncaissementPour('enc-1'),
      );
      expect(cheminPourCible(c, EspaceRecherche.administration), isNull);
      expect(cheminPourCible(c, EspaceRecherche.famille), isNull);
    });
  });

  group('fils de discussion', () {
    test('trouve par interlocuteur, fonction ou objet', () async {
      final MoteurFils m = MoteurFils(
        messages: _FilsFixes(<ResumeFil>[
          _fil('f1', 'Classe Al-Fatiha'),
          _fil('f2', 'Mission du mardi', interlocuteur: 'Omar Sy'),
        ]),
      );
      Future<List<String>> chercher(String q) async =>
          ((await m.rechercher(requete: q, contexte: _famille)) as ReponseOk)
              .elements
              .map((ResultatRecherche e) => e.reference)
              .toList();
      expect(await chercher('fatiha'), <String>['f1']);
      expect(await chercher('omar'), <String>['f2']);
      expect(await chercher('enseignante'), <String>['f1', 'f2']);
    });

    test('jamais le corps ni l\'apercu d\'un message', () async {
      final MoteurFils m = MoteurFils(
        messages: _FilsFixes(<ResumeFil>[
          _fil('f1', 'Classe Al-Fatiha', apercu: 'le code secret est zebulon'),
        ]),
      );
      final ReponseOk r = await m.rechercher(
        requete: 'zebulon',
        contexte: _famille,
      ) as ReponseOk;
      expect(r.elements, isEmpty);
      final ReponseOk vu = await m.rechercher(
        requete: 'fatiha',
        contexte: _famille,
      ) as ReponseOk;
      expect(vu.elements.single.extrait, isNull);
      expect(
        '${vu.elements.single.titre}${vu.elements.single.contexte}',
        isNot(contains('zebulon')),
      );
    });

    test('un fil qui n\'est pas un fil metier est ecarte', () async {
      final MoteurFils m = MoteurFils(
        messages: _FilsFixes(<ResumeFil>[
          _fil('f1', 'Annonce de rentree', type: TypeObjetLie.publication),
        ]),
      );
      final ReponseOk r = await m.rechercher(
        requete: 'annonce',
        contexte: _famille,
      ) as ReponseOk;
      expect(r.elements, isEmpty);
    });

    test(
      'l\'Interface guidee n\'a pas de messagerie : domaine absent',
      () async {
        const MoteurFils m = MoteurFils(messages: _FilsFixes(<ResumeFil>[]));
        expect(
          await m.disponiblePour(
            const ContexteRecherche(espace: EspaceRecherche.eleveGuide),
          ),
          isFalse,
        );
        expect(await m.disponiblePour(_famille), isTrue);
      },
    );

    test('sur le double de demonstration des Messages (tuteur)', () async {
      final MessagesMetierDemo demo = MessagesMetierDemo(
        role: RoleDemoCommunications.tuteur,
        maintenant: _maintenant,
      );
      final List<ResumeFil> fils = await demo.fils();
      expect(fils, isNotEmpty);
      final MoteurFils m = MoteurFils(messages: demo);
      final String mot = fils.first.objet.libelle.split(' ').first;
      final ReponseOk r =
          await m.rechercher(requete: mot, contexte: _famille) as ReponseOk;
      expect(r.elements, isNotEmpty);
      for (final ResultatRecherche e in r.elements) {
        expect(e.cible.kind, KindCible.fil);
      }
    });

    test(
      'la cible d\'un fil est celle de l\'espace, jamais celle d\'un autre',
      () {
        const CibleRecherche c = CibleRecherche(
          kind: KindCible.fil,
          reference: 'f1',
        );
        expect(
          cheminPourCible(c, EspaceRecherche.famille),
          Routes.tuteurFilPour('f1'),
        );
        expect(
          cheminPourCible(c, EspaceRecherche.enseignant),
          Routes.enseignantFilPour('f1'),
        );
        expect(
          cheminPourCible(c, EspaceRecherche.administration),
          Routes.adminFilPour('f1'),
        );
        expect(cheminPourCible(c, EspaceRecherche.comptable), isNull);
      },
    );
  });

  group('canaux du Studio', () {
    test(
      'l\'administration trouve un canal par son nom, pas par un message',
      () async {
        final StudioDemo studio = StudioDemo(maintenant: _maintenant);
        final List<ResumeCanal> canaux = await studio.canaux();
        expect(canaux, isNotEmpty);
        final MoteurFils m = MoteurFils(
          messages: const _FilsFixes(<ResumeFil>[]),
          studio: studio,
        );
        final ResumeCanal c = canaux.first;
        final ReponseOk r =
            await m.rechercher(requete: c.nom, contexte: _admin) as ReponseOk;
        expect(
          r.elements.map((ResultatRecherche e) => e.reference),
          contains(c.id),
        );
        expect(
          r.elements.every(
            (ResultatRecherche e) => e.cible.kind == KindCible.canal,
          ),
          isTrue,
        );
        expect(
          cheminPourCible(
            CibleRecherche(kind: KindCible.canal, reference: c.id),
            EspaceRecherche.administration,
          ),
          Routes.canalStudioPour(c.id),
        );
      },
    );

    test('un autre espace n\'interroge pas le Studio', () async {
      final StudioDemo studio = StudioDemo(maintenant: _maintenant);
      final MoteurFils m = MoteurFils(
        messages: const _FilsFixes(<ResumeFil>[]),
        studio: studio,
      );
      final String nom = (await studio.canaux()).first.nom;
      final ReponseOk r =
          await m.rechercher(requete: nom, contexte: _famille) as ReponseOk;
      expect(r.elements, isEmpty);
    });

    test(
      'un Studio en panne fait echouer le domaine, jamais un vide',
      () async {
        const PortRecherche port = PortRechercheParMoteurs(
          <MoteurRechercheDomaine>[
            MoteurFils(
              messages: _FilsFixes(<ResumeFil>[]),
              studio: _StudioEnPanne(),
            ),
          ],
        );
        final ReponseDomaine r = await port.rechercher(
          domaine: DomaineRecherche.fils,
          requete: 'equipe',
          contexte: _admin,
        );
        expect(r, isA<ReponseEchec>());
      },
    );
  });

  test('le fournisseur branche la finance et les fils, sans autre domaine', () {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    final List<MoteurRechercheDomaine> moteurs = c.read(_fournisseur);
    expect(
      moteurs.map((MoteurRechercheDomaine m) => m.domaine).toSet(),
      <DomaineRecherche>{DomaineRecherche.finances, DomaineRecherche.fils},
    );
    // Sans module serveur, les ports de production disent « indisponible » :
    // la finance ne se fait pas passer pour un vide.
    expect(
      c.read(portEncaissementsProvider).liste(FiltreEncaissements.tout),
      throwsA(isA<CapaciteIndisponible>()),
    );
  });
}

final _fournisseur = Provider<List<MoteurRechercheDomaine>>(
  moteursFinanceCommunications,
);

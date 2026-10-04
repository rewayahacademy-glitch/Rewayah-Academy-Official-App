import 'package:flutter/widgets.dart';

import 'demo_communications_page.dart';

/// La demonstration de la voie COM-COMU (Communaute enseignants) :
/// `/demo/communications?voie=communaute&role=...`.
///
/// **Fichier de la voie COM-COMU**, pose vide par le socle (COM-F) : la voie
/// le remplit ici, avec ses doubles de demonstration (jamais un port reel,
/// K-28), sans toucher a l'index `demo_communications_page.dart`. Tant
/// qu'elle ne l'a pas fait, l'ecran dit « Bientot disponible ».
class ComCommunauteDemo extends StatelessWidget {
  /// Cree la demonstration de la voie.
  const ComCommunauteDemo({super.key, this.role});

  /// Le role mis en scene (`?role=`), nul si l'adresse n'en donne pas.
  final RoleDemoCommunications? role;

  @override
  Widget build(BuildContext context) =>
      const VoieDemoProvisoire(voie: VoieDemoCommunications.communaute);
}

import 'package:supabase_flutter/supabase_flutter.dart';

import 'role_foyer.dart';

/// Le role de la personne connectee dans son foyer, lu par la RPC
/// `mon_role_foyer()` (migration 20261106700000 ; lot N2). Un echec de lecture
/// remonte : les lignes qui en dependent ne sont pas posees.
Future<RoleFoyerLu> lireRoleFoyer(SupabaseClient client) async =>
    roleFoyerDepuis(await client.rpc<Object?>('mon_role_foyer'));

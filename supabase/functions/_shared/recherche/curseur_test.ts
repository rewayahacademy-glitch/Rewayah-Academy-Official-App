import { assertEquals } from "jsr:@std/assert@1";
import { lireCurseur, signerCurseur } from "./curseur.ts";

const secret = "test-only-search-secret-with-at-least-32-bytes";
const maintenant = 1_800_000_000;
const sujet = "8de44d8d-7642-4a58-90c0-90386c871883";
const apres = "8de44d8d-7642-4a58-90c0-90386c871884";

Deno.test("le curseur enseignant est signé et lié au sujet, espace, domaine et requête", async () => {
  const contexte = {
    version: 1 as const,
    domaine: "enseignants" as const,
    sujet,
    espace: "famille",
    ordre: "groupe_id_asc" as const,
    requete: "nour classe",
  };
  const token = await signerCurseur({
    ...contexte,
    apres,
    expireLe: maintenant + 600,
  }, secret);
  const charge = await lireCurseur(token, secret, contexte, maintenant);
  assertEquals(charge?.apres, apres);
  assertEquals(
    await lireCurseur(token, secret, { ...contexte, sujet: apres }, maintenant),
    null,
  );
  assertEquals(
    await lireCurseur(
      token,
      secret,
      { ...contexte, espace: "eleve" },
      maintenant,
    ),
    null,
  );
  assertEquals(
    await lireCurseur(
      token,
      secret,
      { ...contexte, requete: "autre" },
      maintenant,
    ),
    null,
  );
  assertEquals(
    await lireCurseur(
      token,
      secret,
      { ...contexte, domaine: "classes" },
      maintenant,
    ),
    null,
  );
});

Deno.test("le curseur expiré ou altéré est refusé", async () => {
  const contexte = {
    version: 1 as const,
    domaine: "classes" as const,
    sujet,
    espace: "enseignant",
    ordre: "groupe_id_asc" as const,
    requete: "classe arabe",
  };
  const token = await signerCurseur({
    ...contexte,
    apres,
    expireLe: maintenant,
  }, secret);
  assertEquals(await lireCurseur(token, secret, contexte, maintenant), null);
  assertEquals(
    await lireCurseur(`${token}x`, secret, contexte, maintenant),
    null,
  );
});

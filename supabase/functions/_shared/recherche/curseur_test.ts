import { assertEquals } from "jsr:@std/assert@1";
import {
  type ChargeCurseurRecherche,
  type ContexteCurseurRecherche,
  lireCurseur,
  signerCurseur,
} from "./curseur.ts";

const secret = "test-secret-which-is-at-least-32-bytes";
const maintenant = 1_800_000_000;
const charge: ChargeCurseurRecherche = {
  version: 1,
  domaine: "classes",
  sujet: "8de44d8d-7642-4a58-90c0-90386c871883",
  espace: "famille",
  requete: "classe arabe",
  apres: "8de44d8d-7642-4a58-90c0-90386c871884",
  expireLe: maintenant + 600,
};
const contexte: ContexteCurseurRecherche = {
  version: charge.version,
  domaine: charge.domaine,
  sujet: charge.sujet,
  espace: charge.espace,
  requete: charge.requete,
};

Deno.test("le curseur signé se relit pour le même appelant et contexte", async () => {
  const token = await signerCurseur(charge, secret);
  const curseur = await lireCurseur(token, secret, contexte, maintenant);
  assertEquals(curseur?.apres, charge.apres);
  assertEquals(curseur?.sujet, charge.sujet);
});

Deno.test("le contenu du curseur ne sérialise jamais la requête en clair", async () => {
  const token = await signerCurseur(charge, secret);
  const [contenu] = token.split(".");
  const json = atob(
    contenu.replaceAll("-", "+").replaceAll("_", "/") + "=".repeat(
      (4 - contenu.length % 4) % 4,
    ),
  );
  assertEquals(json.includes(charge.requete), false);
  assertEquals(json.includes("requeteTag"), true);
});

Deno.test("le curseur refusé si son contenu ou sa signature est altéré", async () => {
  const token = await signerCurseur(charge, secret);
  const [contenu, signature] = token.split(".");
  assertEquals(
    await lireCurseur(
      `${contenu.slice(0, -1)}A.${signature}`,
      secret,
      contexte,
      maintenant,
    ),
    null,
  );
});

Deno.test("le curseur refusé pour un autre appelant ou une autre requête", async () => {
  const token = await signerCurseur(charge, secret);
  assertEquals(
    await lireCurseur(
      token,
      secret,
      { ...contexte, sujet: "autre-appelant" },
      maintenant,
    ),
    null,
  );
  assertEquals(
    await lireCurseur(
      token,
      secret,
      { ...contexte, requete: "autre requête" },
      maintenant,
    ),
    null,
  );
});

Deno.test("le curseur expiré ou mal formé est refusé", async () => {
  const token = await signerCurseur(
    { ...charge, expireLe: maintenant },
    secret,
  );
  assertEquals(await lireCurseur(token, secret, contexte, maintenant), null);
  assertEquals(
    await lireCurseur("pas-un-curseur", secret, contexte, maintenant),
    null,
  );
});

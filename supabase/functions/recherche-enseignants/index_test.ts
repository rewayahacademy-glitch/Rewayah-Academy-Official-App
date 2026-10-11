import { assertEquals } from "jsr:@std/assert@1";
import type { AppelantRecherche } from "../_shared/recherche/appelant.ts";
import { normaliser, requeteValide, traiter } from "./index.ts";

Deno.test("normalise les diacritiques latins et arabes pour la comparaison", () => {
  assertEquals(normaliser("Al-Fātiḥa"), "al fatiha");
  assertEquals(normaliser("الْفَاتِحَة"), "الفاتحة");
});

Deno.test("valide les bornes C-31 et le seul cas arabe de deux caractères", () => {
  assertEquals(requeteValide("abc"), "abc");
  assertEquals(requeteValide("لا"), "لا");
  assertEquals(requeteValide("ab"), null);
  assertEquals(requeteValide("abc de"), "abc de");
  assertEquals(requeteValide("mot ".repeat(9)), null);
  assertEquals(requeteValide("x".repeat(161)), null);
  assertEquals(requeteValide(null), null);
});

function appelantFactice(
  groupes: Array<{
    groupe_id: string;
    teacher_id: string;
    teacher_prenom: string;
    teacher_titre: string;
    libelle: string;
  }>,
): AppelantRecherche {
  const sql = {
    rpc: async (nom: string) => ({
      data: nom === "app_account_valid"
        ? true
        : nom === "app_role"
        ? "guardian"
        : null,
      error: null,
    }),
    from: () => ({
      select: () => ({
        order: () => ({
          limit: async () => ({ data: groupes, error: null }),
        }),
      }),
    }),
  } as unknown as AppelantRecherche["sql"];
  return { id: "c3500000-0000-4000-8000-000000000001", sql };
}

function requeteRecherche(limite = 5): Request {
  return new Request("https://local.test/recherche-enseignants", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      action: "rechercher",
      espace: "famille",
      requete: "Mariam",
      limite,
    }),
  });
}

Deno.test("le handler dédoublonne l'enseignant avant pagination et garde sa classe minimale", async () => {
  const appelant = appelantFactice([
    {
      groupe_id: "00000000-0000-4000-8000-000000000003",
      teacher_id: "c3500000-0000-4000-8000-000000000004",
      teacher_prenom: "Mariam",
      teacher_titre: "Sayyida",
      libelle: "Classe C",
    },
    {
      groupe_id: "00000000-0000-4000-8000-000000000002",
      teacher_id: "c3500000-0000-4000-8000-000000000003",
      teacher_prenom: "Mariam",
      teacher_titre: "Sayyida",
      libelle: "Classe B",
    },
    {
      groupe_id: "00000000-0000-4000-8000-000000000001",
      teacher_id: "c3500000-0000-4000-8000-000000000003",
      teacher_prenom: "Mariam",
      teacher_titre: "Sayyida",
      libelle: "Classe A",
    },
    {
      groupe_id: "00000000-0000-4000-8000-000000000004",
      teacher_id: "c3500000-0000-4000-8000-000000000005",
      teacher_prenom: "Mariam",
      teacher_titre: "Ustadha",
      libelle: "Classe D",
    },
  ]);
  const response = await traiter(requeteRecherche(1), {
    appelant: async () => appelant,
    secretCurseur: "test-secret-with-at-least-32-bytes-long",
    maintenantMs: () => 1_800_000_000_000,
  });
  const body = await response.json();
  assertEquals(response.status, 200);
  assertEquals(body.elements.length, 1);
  assertEquals(
    body.elements[0].reference,
    "c3500000-0000-4000-8000-000000000003",
  );
  assertEquals(body.elements[0].contexte, "Enseignant de la classe Classe A");
  assertEquals(body.aPlus, true);
  assertEquals(typeof body.curseurSuivant, "string");
});

Deno.test("une famille autorisée sans classe reçoit une page vide", async () => {
  const response = await traiter(requeteRecherche(), {
    appelant: async () => appelantFactice([]),
    secretCurseur: "test-secret-with-at-least-32-bytes-long",
  });
  const body = await response.json();
  assertEquals(response.status, 200);
  assertEquals(body.statut, "ok");
  assertEquals(body.elements, []);
  assertEquals(body.curseurSuivant, null);
  assertEquals(body.aPlus, false);
});

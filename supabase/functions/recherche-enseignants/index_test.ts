import { assertEquals } from "jsr:@std/assert@1";
import { normaliser, requeteValide } from "./index.ts";

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

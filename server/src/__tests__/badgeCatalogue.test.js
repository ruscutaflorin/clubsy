import { BADGE_CATALOGUE } from "../services/badgeCatalogue.js";

// Kinds gamificationService evaluates explicitly; anything else silently falls through to the streak branch.
const KNOWN_KINDS = ["checkIns", "clubs", "cities", "regular", "nightOwl", "weekend", "streak"];

describe("BADGE_CATALOGUE", () => {
  it("has unique ids", () => {
    const ids = BADGE_CATALOGUE.map((b) => b.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it("only uses kinds the evaluator understands", () => {
    for (const badge of BADGE_CATALOGUE) {
      expect(KNOWN_KINDS).toContain(badge.kind);
    }
  });

  it("gives every badge a title, description and positive integer target", () => {
    for (const badge of BADGE_CATALOGUE) {
      expect(badge.title).toBeTruthy();
      expect(badge.description).toBeTruthy();
      expect(Number.isInteger(badge.target)).toBe(true);
      expect(badge.target).toBeGreaterThan(0);
    }
  });
});

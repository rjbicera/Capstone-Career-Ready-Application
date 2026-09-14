const { z } = require("zod");

// Matches docs/api/api-contract.md POST /auth/register request shape exactly.
// Kept separate from the controller so the schema is easy to find/update
// if the contract changes.
//
// course/yearLevel are optional here (SDD v1.6) — registration now only
// creates the account; BSIT/BSBA + year level are collected in a
// dedicated demographic-profiling step right after signup (see
// demographicsSchema below), matching docs/architecture's recommendation
// to treat program as a first-class demographic variable rather than
// cramming it onto the signup form. Still accepted if sent, so nothing
// breaks for a caller that provides them at registration time.
const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, "Password must be at least 8 characters"),
  fullName: z.string().trim().min(1, "Full name is required"),
  course: z.string().trim().min(1).optional(),
  yearLevel: z.string().trim().min(1).optional(),
});

// Gender is intentionally free-text on the backend (not an enum) so the
// mobile dropdown can offer an inclusive list of options — including
// LGBTQ+ identities and a "prefer to self-describe" custom entry — without
// the server needing to know every label the client shows. Nothing here
// branches on the value; see gender note in firestore-schema-design.md.
const genderField = z.string().trim().min(1).optional();

// PATCH /auth/me — the demographic-profiling step. `course` is
// specifically constrained to BSIT/BSBA (not free text like the old
// signup field was) because it's the variable the whole app branches
// career categories, question banks, and AI prompts on — a typo here
// would silently misroute a student's entire experience.
const demographicsSchema = z.object({
  course: z.enum(["BSIT", "BSBA"], {
    error: "Course must be BSIT or BSBA",
  }),
  yearLevel: z.enum(["1st Year", "2nd Year", "3rd Year", "4th Year"], {
    error: "Select a valid year level",
  }),
  gender: genderField,
  // Optional. Shown around the app (home greeting, profile header)
  // instead of the full legal name whenever it's set.
  nickname: z.string().trim().min(1).optional(),
});

// PATCH /auth/me/profile — general "Edit profile" updates, made any time
// after onboarding. Every field is optional since this is a partial
// update; at least one must be present (enforced in the controller so we
// can return a clear error message rather than a generic schema issue).
const profileUpdateSchema = z.object({
  fullName: z.string().trim().min(1).optional(),
  nickname: z.string().trim().min(1).optional(),
  careerGoal: z.string().trim().min(1).optional(),
  course: z.enum(["BSIT", "BSBA"]).optional(),
  yearLevel: z
    .enum(["1st Year", "2nd Year", "3rd Year", "4th Year"])
    .optional(),
  gender: genderField,
});

module.exports = { registerSchema, demographicsSchema, profileUpdateSchema };

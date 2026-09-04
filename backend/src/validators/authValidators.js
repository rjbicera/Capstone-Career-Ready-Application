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
  // Optional and free-text on purpose — see gender note in
  // firestore-schema-design.md. Not used for any branching logic.
  gender: z.string().trim().min(1).optional(),
});

module.exports = { registerSchema, demographicsSchema };

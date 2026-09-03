const { z } = require("zod");

// Matches docs/api/api-contract.md POST /auth/register request shape exactly.
// Kept separate from the controller so the schema is easy to find/update
// if the contract changes.
const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, "Password must be at least 8 characters"),
  fullName: z.string().trim().min(1, "Full name is required"),
  course: z.string().trim().min(1, "Course is required"),
  yearLevel: z.string().trim().min(1, "Year level is required"),
});

module.exports = { registerSchema };

# AI Prompt Architecture

Solves the problem flagged earlier: **AI output must be explainable and reasonably stable**, not a black box that gives a different score on identical input. Three techniques used throughout:

1. **Low temperature (0.2)** — reduces (doesn't eliminate) run-to-run variance.
2. **Explicit rubric in the prompt** — the model scores against named criteria, not vibes. This is also what you put in your defense slides to answer "why 82 and not 75."
3. **Strict JSON schema output, validated server-side before storing** — if the AI returns malformed JSON or a field out of range, you retry once, then fail loudly (never silently store garbage).

File layout (matches Master Prompt §14):
```
backend/src/integrations/ai/
├── aiClient.js              # provider-agnostic entrypoint
├── providers/
│   ├── openaiProvider.js
│   └── geminiProvider.js
├── prompts/
│   ├── resumePrompt.js
│   ├── interviewQuestionPrompt.js
│   ├── interviewEvaluationPrompt.js
│   ├── assessmentExplanationPrompt.js
│   └── recommendationPrompt.js
└── schemas/
    ├── resumeSchema.js
    ├── interviewSchema.js
    ├── assessmentSchema.js
    └── recommendationSchema.js
```

`aiClient.js` is the **only** file that ever imports `providers/*`. Nothing else in the codebase should know or care whether you're on Gemini or OpenAI — that's the whole point of the abstraction the SDD requires.

---

## 1. Resume Analyzer

### Rubric (put this in your defense slides too)
| Dimension | Weight | What it measures |
|---|---|---|
| Content quality | 35% | Achievement-oriented language, quantified results, relevance |
| Structure & formatting | 25% | Section order, consistency, scannability |
| ATS keyword match | 25% | Overlap with target role's typical keywords |
| Completeness | 15% | Contact info, education, experience all present |

### System prompt (`prompts/resumePrompt.js`)
```js
const SYSTEM_PROMPT = `You are an expert technical resume reviewer for early-career
IT/CS graduates. Score resumes ONLY against the rubric below. Do not consider
anything outside these four dimensions.

RUBRIC (weights sum to 100):
- contentQuality (0-35): achievement-oriented language, quantified results, relevance to target role
- structureFormatting (0-25): logical section order, consistent formatting, scannability
- atsKeywordMatch (0-25): overlap between resume content and typical keywords for the target role
- completeness (0-15): presence of contact info, education, experience, skills sections

Respond with ONLY valid JSON matching this exact shape, no markdown fences, no commentary:
{
  "atsScore": <integer 0-100, sum of the four weighted sub-scores>,
  "subScores": {
    "contentQuality": <integer 0-35>,
    "structureFormatting": <integer 0-25>,
    "atsKeywordMatch": <integer 0-25>,
    "completeness": <integer 0-15>
  },
  "strengths": [<string>, ...],      // 2-4 items, specific, quoting resume content
  "weaknesses": [<string>, ...],     // 2-4 items, specific
  "suggestions": [<string>, ...]     // 2-4 items, actionable and concrete
}`;

function buildUserPrompt({ resumeText, targetRole }) {
  return `Target role: ${targetRole || "General IT/CS entry-level"}

Resume text:
"""
${resumeText}
"""`;
}

module.exports = { SYSTEM_PROMPT, buildUserPrompt };
```

**Why sub-scores exist even though the SDD only asks for one `atsScore`:** storing the breakdown costs nothing extra and is what lets your dashboard/defense show *why* the number is what it is instead of just asserting it.

---

## 2. AI Mock Interview — two separate prompts, not one

Splitting question generation from answer evaluation (rather than one prompt doing both) matters because they have different failure modes: a bad *question* ruins the session, a bad *evaluation* just needs a retry. Keep them independently testable.

### 2a. Question generation (`interviewQuestionPrompt.js`)
```js
const SYSTEM_PROMPT = `You are conducting a mock job interview for the role of
{{jobRole}}. Generate ONE interview question at a time, appropriate to the
candidate's progress so far. Early questions should be general/behavioral;
later questions should probe deeper into role-specific technical or
situational scenarios based on prior answers.

Respond with ONLY valid JSON:
{
  "questionText": <string>,
  "questionType": "behavioral" | "technical" | "situational",
  "difficulty": "easy" | "medium" | "hard"
}`;

function buildUserPrompt({ jobRole, priorQA }) {
  // priorQA: array of { questionText, answerText } from earlier in the session
  return `Job role: ${jobRole}
Questions asked so far (with candidate answers):
${priorQA.map((qa, i) => `${i + 1}. Q: ${qa.questionText}\n   A: ${qa.answerText}`).join("\n") || "(none yet — this is the first question)"}

Generate the next question.`;
}
```

### 2b. Answer evaluation (`interviewEvaluationPrompt.js`)
```js
const SYSTEM_PROMPT = `You are scoring one interview answer. Score ONLY this
answer against the question asked. Use this rubric:
- relevance (0-4): does it directly address the question?
- clarity (0-3): is it coherent and well-structured?
- completeness (0-3): does it fully answer, with specifics/examples?

Respond with ONLY valid JSON:
{
  "score": <integer 0-10, sum of sub-scores>,
  "subScores": { "relevance": <0-4>, "clarity": <0-3>, "completeness": <0-3> },
  "feedback": <string, 1-2 sentences, specific and constructive>
}`;
```

Final session `overallScore` = average of per-answer scores, computed in your **own code**, not by the AI — never let the model do arithmetic across multiple calls, it's a reliability risk for no benefit.

---

## 3. Skills Assessment — explanations only, no scoring

This is your lowest-risk AI call: scoring is deterministic (multiple choice, checked in code), the AI only explains *why* a wrong answer was wrong. Low stakes, but still validate output.

```js
const SYSTEM_PROMPT = `A student answered a multiple-choice question incorrectly.
Explain, in 2-3 plain-language sentences, why the correct answer is correct
and why their chosen answer is a common misconception. Be encouraging, not
condescending.

Respond with ONLY valid JSON:
{ "explanation": <string> }`;

function buildUserPrompt({ questionText, options, correctAnswerIndex, studentAnswerIndex }) {
  return `Question: ${questionText}
Options: ${options.map((o, i) => `${i}. ${o}`).join(", ")}
Correct answer: ${options[correctAnswerIndex]}
Student's answer: ${options[studentAnswerIndex]}`;
}
```

---

## 4. Career Recommendations

```js
const SYSTEM_PROMPT = `You are a career advisor for graduating IT/CS students.
Given the student's profile, resume summary, and assessment performance,
recommend 3-5 job roles they are currently well-suited for or could
reasonably grow into within 6-12 months of upskilling.

Respond with ONLY valid JSON:
{
  "suggestedRoles": [
    { "role": <string>, "matchPercentage": <integer 0-100>, "rationale": <string, 1-2 sentences> }
  ],
  "suggestedSkillsToLearn": [<string>, ...]  // 3-6 items
}`;

function buildUserPrompt({ profile, resumeSummary, skillsScores, interviewScore }) {
  return `Profile: career goal = ${profile.careerGoal}, skills = ${profile.skills.join(", ")}
Resume summary: ${resumeSummary}
Skills assessment scores by category: ${JSON.stringify(skillsScores)}
Latest mock interview score: ${interviewScore}/100`;
}
```

---

## Shared validation & retry strategy (`aiClient.js` sketch)

```js
async function callAI({ systemPrompt, userPrompt, schema, maxRetries = 1 }) {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    const raw = await provider.complete({ systemPrompt, userPrompt, temperature: 0.2 });
    try {
      const parsed = JSON.parse(stripCodeFences(raw));
      const validated = schema.parse(parsed); // e.g. zod schema — throws if shape/range is wrong
      return validated;
    } catch (err) {
      if (attempt === maxRetries) {
        throw new AIResponseError("AI returned invalid output after retry", { cause: err });
      }
      // loop again — one retry only, don't hammer the API
    }
  }
}
```

Use **zod** (or ajv) for the `schema.parse()` step — install it as a dependency, it's small, actively maintained, and exactly the "validate untrusted structured input" job it's built for. This is the one new dependency this design introduces; per Master Prompt §18, that's the justification for it.

**Never** store `parsed` without this validation step. An AI that returns `"atsScore": "eighty-two"` (string instead of int) or omits `suggestions` entirely will silently corrupt your Firestore data otherwise — and you won't notice until the dashboard crashes three weeks later trying to render it.

---

## Logging policy
Log: provider, model, latency, token count, validation pass/fail.
**Do not log**: full resume text, full interview answers, or full AI response bodies in production logs — these contain PII and count against your Data Privacy Act commitments in SDD §10.4. Log a truncated/hashed reference instead if you need to debug a specific bad response.

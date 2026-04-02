# AGENTS.md instructions for /Users/bytedance/Documents/Code/archerypro

<INSTRUCTIONS>
## Skills
A skill is a set of local instructions stored in a `SKILL.md` file.

### Available skills
- flutter-poster-share: Reusable Flutter workflow for generating poster images from widgets, saving to local gallery, and invoking system share sheet with image/text fallback. Use for result sharing, achievement posters, invite cards, or similar share features. (file: /Users/bytedance/Documents/Code/archerypro/.codex/skills/flutter-poster-share/SKILL.md)

### How to use skills
- Discovery: The list above is the skills available in this project.
- Trigger rules: If the user names a skill (with `$SkillName` or plain text) OR the task clearly matches a skill description, you must use that skill for that turn.
- Missing/blocked: If a named skill cannot be read, say so briefly and continue with the best fallback.
- Progressive disclosure:
  1) Open the skill `SKILL.md` and read only what is needed.
  2) Resolve relative paths from the skill directory first.
  3) Load extra references only when needed.
</INSTRUCTIONS>

## Product Outcome Rule

- Treat every request as a desired product outcome, not merely a literal local condition.
- Before changing existing behavior, identify the product qualities it preserves (UX, gameplay, visual hierarchy, compatibility, performance, maintainability, release scope, and similar constraints) and preserve them unless the user explicitly asks to trade them off.
- Passing the narrow acceptance criterion is not success if the overall product becomes worse. A locally correct change that creates a larger regression is incorrect and must not be implemented.
- If the literal request conflicts with preserved product qualities and no scoped solution satisfies both, stop and ask instead of silently sacrificing one of them.

## Code Quality Rules

- Keep changes scoped. No opportunistic redesigns, validations, upgrades or style tweaks.
- Prefer explicit module boundaries over clever abstractions.
- Write short comments for important or unobvious logic. Also for all methods and classes. 
- Decompose code into small methods and separate files.
- Follow the **Single Responsibility Principle** strictly.
- **Never overcomplicate**. Think about how to write the simplest code possible. Fight complexity.

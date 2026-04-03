# Skill: Task State Manager
Use this to track progress through a multi-step PLAN.md.

## Tools
- **status_update:** Updates `.opencode/state.json` with the current Task ID.
- **get_context:** Reads the current Task ID and pulls the specific "Logic" and "Verification" steps from PLAN.md.

## Protocol
When a Worker model starts, it MUST run `get_context` to avoid reading the entire plan and getting confused. 
When a Worker finishes a step, it MUST run `status_update --complete` before the Reviewer is called.

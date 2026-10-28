# ComfyKills

**Version 0.4 – Development / not released**
**Target: World of Warcraft: Forever 1.60.1 / Interface 16001**

Persistent mob kill database with session, character and account-wide statistics for WoW Forever.

The important kill history is stored through **ComfyData**, not in the ComfyKills settings profile.

## 0.1 Beta

- Tracks modern PARTY_KILL(attackerGUID,targetGUID) frame events directly,
rather than the forbidden COMBAT_LOG_EVENT_UNFILTERED. Only player/pet attacker
GUIDs are credited (when pet tracking is enabled). A bounded GUID-based
30-second dedupe avoids duplicate reporting for the same mob.
- Stores NPC ID, name, creature type, classification, level range, first/last kill and last location when known.
- Separates account, character and current-session counts.
- Learns average XP from kills when an XP update follows a recorded kill.
- Reads player death statistics from ComfyData, the sole writer of death data (avoids double-counting).
- Adds kill history to unit tooltips.
- Searchable kill browser with All Kills and Session views.
- Optional milestone messages.

This is an original Comfy Suite implementation inspired by the useful database/statistics ideas found in long-lived kill-counter addons; no third-party code or data is copied.

## Launch validation checklist (still required)

- On the actual Forever client verify PARTY_KILL registration, actor/target GUID access, and kill count increments with a real NPC.
- Verify pet kills and duplicate prevention.
- Verify ComfyData and ComfyKills count exactly one death for one PLAYER_DEAD.
- Verify ComfyDataVault SavedVariables persist through /reload and login.
- If modern API marks GUIDs secret during combat, do not bypass restrictions or claim complete kill coverage.

Offline tests: lua5.1 tests/test_kill_events.lua . ; lua5.4 tests/test_kill_events.lua .

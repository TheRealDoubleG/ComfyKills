# ComfyKills Changelog

## 0.4 (development, not released)
- Use modern standalone PARTY_KILL API, not restricted combat log.
- Count attacker player/pet GUID kills only, with bounded mob GUID deduplication.
- Remove duplicate death recording; ComfyData remains single writer.
- Lua 5.1/5.4 tests for kills, pet kills, duplicates and death interoperability.
- Requires client-side tests at WoW Forever launch.

## 0.2 Beta – 28.09.2026
- Registered ComfyKills in Blizzard's native AddOns settings list with a button to open the full Comfy settings window.


## 0.1 Beta – 28.09.2026
- Initial ComfyData-backed mob kill tracker.
- Added account/character/session kill counts.
- Added NPC metadata and location storage.
- Added player/pet attribution, XP samples, deaths and milestones.
- Added unit tooltip statistics.
- Added searchable kill database browser.
- Added Comfy Suite profile/settings/info framework.

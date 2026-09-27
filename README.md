# ComfyKills

**Version 0.2 – Beta**  
**Target: World of Warcraft: Forever 1.60.1 / Interface 16001**

Persistent mob kill database with session, character and account-wide statistics for WoW Forever.

The important kill history is stored through **ComfyData**, not in the ComfyKills settings profile.

## 0.1 Beta

- Tracks PARTY_KILL events credited to the player and optionally the player's pet.
- Stores NPC ID, name, creature type, classification, level range, first/last kill and last location when known.
- Separates account, character and current-session counts.
- Learns average XP from kills when an XP update follows a recorded kill.
- Tracks player deaths.
- Adds kill history to unit tooltips.
- Searchable kill browser with All Kills and Session views.
- Optional milestone messages.

This is an original Comfy Suite implementation inspired by the useful database/statistics ideas found in long-lived kill-counter addons; no third-party code or data is copied.

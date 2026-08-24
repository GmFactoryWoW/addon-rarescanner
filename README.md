# RareScanner 3.3.5a Backport

A lightweight **World of Warcraft 3.3.5a** backport of [RareScanner](https://www.curseforge.com/wow/addons/rarescanner).

Based on **RareScanner WotLK 3.4.0.3** by **maqjav**:  
https://www.curseforge.com/wow/addons/rarescanner/files/4026370

## Changes

- Backported to **WoW 3.3.5a (Interface 30300)**.
- Replaced unsupported modern WoW APIs with 3.3.5a-compatible rare detection.
- Rare detection through creature cache, target and mouseover.
- Displays the **rare NPC portrait/model** in alerts.
- Simplified alert/chat messages and removed unnecessary login messages.
- Added rare spawn coordinates and **skull icons on the World Map**.
- Region maps display all known spawns; continent/world maps display one pin per NPC.
- Region pins include NPC tooltips, hover highlight and spawn-group focus.
- Added **Interface > AddOns > RareScanner** settings:
  - Enable/disable RareScanner.
  - Enable/disable alert sound.
  - Show/hide rares on the World Map.
  - Reset alert history.
- Added `/rs reset` and `/rs reset <NPC ID>`.
- Separated RareScanner alert history from the WoW creature-cache baseline.
- Removed unused code and media files.

## Credits

RareScanner was originally created by **maqjav**.

This is an unofficial compatibility backport for **WoW 3.3.5a**.

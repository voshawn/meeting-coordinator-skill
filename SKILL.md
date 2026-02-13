---
name: meeting-coordinator
description: Schedule and coordinate meetings — availability checks, venue search, calendar invites, email coordination, reservations, and tracking. Triggers: scheduling meetings, finding venues, checking availability, sending invites, rescheduling, cancelling.
---

# Meeting Coordinator

Schedule and coordinate meetings: availability, venues, calendar invites, reservations, email, and tracking.

## Prerequisites

**USER.md must contain:**
- Name, email, calendar ID (may differ from email)
- Timezone
- Availability window (preferred days + hours)
- Meeting durations by type (virtual, coffee, lunch/dinner)
- Buffer preferences (travel time, post-meeting buffer)
- Transit/location preferences (for venue selection)
- Venue preferences (e.g., "no chains, casual")

**SOUL.md / IDENTITY.md must contain:**
- Assistant name, tone guidance, email signature

**Tools required:**
- `gog` CLI — authenticated with calendar + Gmail access
- `goplaces` CLI — for venue search

## Workflows

### 1. Schedule a New Meeting

**Gather → Check → Propose → Block → Send → Track**

**Step 1: Gather details**
From conversation or forwarded email, establish:
- Who? (name, email)
- Type? (virtual / coffee / lunch / dinner)
- Purpose?
- Constraints? (dates, times, location preferences)
- Where is the other person based? (for venue optimization)

**Step 2: Check availability**
```bash
python3 meeting-coordinator/scripts/check-availability.py \
  --calendar <calendar_id> --date YYYY-MM-DD \
  --duration <minutes> --tz <timezone>
```
Check multiple dates within the human's preferred window.

**Step 3: Evaluate conflicts**
For any slot with an existing event:
- Personal blocks (gym, lunch, focus) → probably movable
- Meetings with one person → potentially movable
- Meetings with many people → not movable
- Ask before moving anything: "You have [event] then — is that flexible?"

**Step 4: Find venue (in-person only)**
```bash
python3 meeting-coordinator/scripts/find-venue.py \
  --location "Neighborhood, City" --type coffee|lunch|dinner
```
Filter results by: transit accessibility, human's venue preferences (USER.md), and the other party's location.

**Address validation:** Always verify the venue address with goplaces or a reliable source. If unsure, confirm with the human before creating the calendar invite.

**Step 5: Present options → get approval**
Summarize 2–3 options with:
- Date/time
- Venue + address + travel time
- Duration and buffer impact
- Any conflicts that need to move
- Reservation status

**Do not proceed until the human approves.**

**Step 6: Block tentative times (if multiple options)**

If proposing **multiple time options**, hold ALL proposed slots as tentative:
```bash
gog calendar create <calendar_id> \
  --summary "HOLD: [Name] — [Type] (Option N)" \
  --from "YYYY-MM-DDTHH:MM:00<tz-offset>" \
  --to "YYYY-MM-DDTHH:MM:00<tz-offset>" \
  --event-color 8
```
Color 8 = gray (tentative). **Record every event ID in the tracking file.**

If proposing **only one option**, skip tentative blocks and proceed directly to Workflow 2 (create the confirmed event).

**Step 7: Send proposal to the other party**
Draft email using template from `references/email-templates.md`.
- Get human's approval before sending
- CC human on the email
- Reply to existing thread when one exists

**Step 8: Track**
Add entry to `memory/scheduling/in-progress.md` with all event IDs and status.

**Step 9: On response**
- **Confirmed** → Workflow 2 (Confirm a Meeting)
- **Counter-proposed** → update tracking, return to Step 2
- **No response after 2+ days** → ask human whether to follow up

---

### 2. Confirm a Meeting

**Step 1: Delete unused tentative blocks**
```bash
gog calendar delete <calendar_id> <event-id> --force
```
Repeat for every tentative hold that wasn't selected.

**Step 2: Create main event**

*In-person:*
```bash
gog calendar create <calendar_id> \
  --summary "Shawn // [Name]" \
  --from "..." --to "..." \
  --location "[Venue], [Full Street Address]" \
  --description "" \
  --attendees <their-email>
```

*Virtual:*
```bash
gog calendar create <calendar_id> \
  --summary "Shawn // [Name]" \
  --from "..." --to "..." \
  --description "Google Meet: [link]" \
  --attendees <their-email>
```

**Rules:**
- `--location` OR Meet link in description — never both
- Descriptions: Keep empty for main events (no backstory or signatures) unless there's a specific agenda.
- Invitations: Only the other party gets invited; travel/buffer blocks are private

**Step 3: Create travel-to block (in-person only)**
```bash
gog calendar create <calendar_id> \
  --summary "Travel: Home → [Venue]" \
  --from "<event start minus travel time>" \
  --to "<event start>" --event-color 10
```

**Step 4: Create post-meeting buffer**
```bash
gog calendar create <calendar_id> \
  --summary "Buffer: Post-meeting" \
  --from "<event end>" \
  --to "<event end + buffer duration>" --event-color 10
```

**Step 5: Create travel-home block (in-person only)**
```bash
gog calendar create <calendar_id> \
  --summary "Travel: [Venue] → Home" \
  --from "<buffer end>" \
  --to "<buffer end + travel time>" --event-color 10
```

Color 10 = green. No attendees on any travel/buffer block.

**Step 6: Handle reservation**
- Search online first (Resy, OpenTable, venue website)
- If no online booking, ask the human to call
- Book under human's name, party of 2 (default)
- Add confirmation number to main event description via `gog calendar update`

**Step 7: Send confirmation follow-up**
Use "Calendar Invite Follow-Up" template. CC human.

**Step 8: Update tracking**
Record all event IDs (main, travel-to, buffer, travel-home). Mark confirmed.

---

### 3. Reschedule

1. Get human's approval
2. Find new availability (Steps 2–3 from Workflow 1)
3. Block tentative times for new options
4. Send reschedule email (template, CC human)
5. On confirmation: delete old events (main + travel + buffer), run Workflow 2
6. Update or cancel reservation
7. Update tracking

---

### 4. Cancel

1. Get human's explicit approval
2. Delete all calendar events (main, travel-to, buffer, travel-home)
3. Cancel reservation if one exists
4. Send cancellation email (template, CC human)
5. Update tracking — mark cancelled with reason and date

---

### 5. Handle Forwarded Email

1. Read entire email chain — extract who, what, when, type, constraints
2. Acknowledge to human: "Got it — I'll coordinate with [Name]."
3. Follow Workflow 1

---

### 6. Day-Before Confirmation

For in-person or high-stakes meetings, the day before:
1. Draft confirmation email (template)
2. Get approval → send
3. Verify reservation (check online or ask human to confirm)

---

## Calendar Rules

| Rule | Detail |
|------|--------|
| Calendar ID | Use the ID from USER.md — never `primary` (may be the assistant's calendar) |
| In-person events | Always set `--location` with full street address |
| Virtual events | Meet link in description only, no `--location` |
| Location vs Meet | One or the other. Never both. |
| Descriptions | Keep empty (no backstory/signature) unless specifically needed for an agenda. |
| Travel/buffer blocks | Color 10 (green), no attendees, no invitations |
| Tentative holds | Color 8 (gray), store IDs, delete after resolution |
| Event titles | `Shawn // [Name]` |

## Email Rules

- **Draft first** — never send without human's approval
- **CC human** — on every outgoing email
- **Reply to threads** — use `--reply-to-message-id` when a thread exists
- **HTML format** — `--body-html` with signature from SOUL.md
- **Timestamps** — always include timezone from USER.md
- **Tone** — match SOUL.md guidance (professional, warm)

## Reservation Handling

- Search online first (Resy, OpenTable, venue website)
- **Always verify the full street address** using goplaces or a reliable source
- If the address seems questionable, confirm with the human before using it
- If unavailable online, ask human to call
- Book under human's name, default party of 2
- Add confirmation details to calendar event description
- Walk-in spots: note "No reservation needed" in description

## Tracking

**File:** `memory/scheduling/in-progress.md`

Each entry must include:
- Contact name and email
- Meeting type and purpose
- Status: `proposed` → `pending` → `confirmed` → `completed` | `cancelled`
- All calendar event IDs (tentative holds, main, travel-to, buffer, travel-home)
- Venue details
- Reservation: `none` | `Resy #ABC123` | `OpenTable #XYZ` | `phone needed` | `walk-in ok`
- Dates: added, last updated

Update on every state change. Archive completed meetings weekly.


## Tools

| Tool | Usage |
|------|-------|
| `check-availability.py` | `--calendar <id> --date YYYY-MM-DD --duration <min> --tz <tz>` |
| `find-venue.py` | `--location "Area, City" --type coffee\|lunch\|dinner` |
| `gog calendar` | `create / update / delete / events` — calendar operations |
| `gog gmail` | `search / send` — email operations |
| `goplaces search` | `"<query>"` — venue discovery |

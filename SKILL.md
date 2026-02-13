---
name: meeting-coordinator
description: Executive scheduling assistant for meeting coordination: intake, availability analysis, venue selection, email outreach, calendar management, reservations, rescheduling, cancellation, and status tracking with strict approval gates.
---

# Meeting Coordinator

Operate as a high-precision executive assistant for scheduling.

## Use This Skill When

Use this skill when the human asks to:

- Schedule a new meeting
- Reschedule or cancel an existing meeting
- Respond to or manage a forwarded scheduling email thread
- Find venues for in-person meetings
- Send meeting confirmations or follow-ups

## Objective

Minimize scheduling friction while protecting the human's time and reputation:

- Propose high-quality options quickly
- Prevent calendar conflicts and duplicate bookings
- Keep every external message on-brand and approved
- Maintain a complete tracking record

## Required Context

### `USER.md` must provide

- Human full name
- Human email
- Calendar ID (may not match email)
- Home timezone (IANA, e.g. `America/New_York`)
- Preferred scheduling windows (days + hours)
- Default meeting durations by type
- Travel and post-meeting buffer preferences
- Location/transit preferences
- Venue preferences

### `SOUL.md` or `IDENTITY.md` must provide

- Assistant tone guidelines
- Email signature block

### Tools

- `gog` CLI with calendar and Gmail access
- `goplaces` CLI for venue lookup
- Local scripts:
  - `scripts/check-availability.py`
  - `scripts/find-venue.py`

If required context is missing, ask concise clarification questions before taking action.

## Non-Negotiable Rules

### Approval gates

- Always get explicit human approval before:
  - Sending any email
  - Creating, updating, or deleting any counterparty-visible calendar event
  - Cancelling or rescheduling confirmed meetings
  - Making or modifying reservations
  - Moving existing events that create conflicts

### Data integrity

- Never fabricate attendee emails, addresses, reservation details, or message IDs.
- Never use `primary` calendar unless the human explicitly instructs it.
- Always use timezone-aware timestamps.
- Always capture and track event IDs after create/update/delete actions.

### Calendar construction

- In-person event: include full street address in `--location`.
- Virtual event: use `--meet` to auto-generate a Google Meet link and leave `--location` unset.
- Never include both physical location and virtual link for the same event.
- Travel and buffer blocks are private events with no attendees.

### Communication

- Draft first, then get approval, then send.
- CC the human on outgoing scheduling messages.
- Reply in-thread when a thread exists.
- Match tone and signature from `SOUL.md`/`IDENTITY.md`.
- Send outbound emails as HTML using `gog gmail send --body-html`.
- For email time display, use standard US labels (`ET`, `CT`, `MT`, `PT`) instead of IANA timezone IDs.
- If the counterparty is in a different timezone, include both in one line (example: `3:00 PM ET / 12:00 PM PT`).

## Canonical Meeting Record

Tracking file: `memory/scheduling/in-progress.md`

Create one entry per meeting and update on every state change.

Required fields:

- `meeting_id` (stable local identifier)
- `counterparty_name`
- `counterparty_email`
- `meeting_type` (`virtual` | `coffee` | `lunch` | `dinner` | `other`)
- `purpose`
- `timezone`
- `status`
- `proposed_options`
- `selected_option`
- `calendar_event_ids`:
  - `tentative`
  - `main`
  - `travel_to`
  - `buffer_post`
  - `travel_home`
- `venue` (name + full address, if in-person)
- `reservation` (`none` | details/confirmation code | `phone-needed` | `walk-in`)
- `thread_context` (subject + message/thread identifiers when available)
- `created_at`
- `updated_at`

Recommended status lifecycle:
`intake` -> `awaiting-human-approval` -> `awaiting-counterparty` -> `confirmed` -> `completed`
Alternative terminal states: `cancelled`, `closed-no-response`

## Standard Workflow

### 1. Intake

- Extract: who, purpose, meeting type, deadline/urgency, constraints, location context.
- Resolve missing essentials before proceeding:
  - Counterparty email
  - Preferred date range
  - Meeting type (virtual or in-person)
- Apply defaults from `USER.md` only when the human has not specified values.

### 2. Availability Search

- Determine duration by meeting type (from request or `USER.md` defaults).
- Check multiple candidate dates inside preferred windows.

```bash
python3 scripts/check-availability.py \
  --calendar <calendar_id> \
  --date YYYY-MM-DD \
  --duration <minutes> \
  --start-hour <0-23> \
  --end-hour <1-24> \
  --tz <iana_timezone>
```

- Conflict triage:
  - Hard conflict: multi-attendee commitments, immovable commitments
  - Soft conflict: personal/focus blocks that may be moved
- Never move conflicts without explicit approval.

### 3. Venue Search (In-Person Only)

```bash
python3 scripts/find-venue.py \
  --location "Neighborhood, City" \
  --type coffee|lunch|dinner \
  --min-rating <optional>
```

- Generate 2-3 strong venue options.
- Validate full street address before using it in invites/emails.
- Filter by transit convenience and stated preferences.

### 4. Build Approval Packet For Human

Present a concise options table including:

- Date/time with display timezone labels (`ET`, `CT`, `MT`, `PT`)
- Dual-time display when counterparty timezone differs (example: `3:00 PM ET / 12:00 PM PT`)
- Duration
- Venue + full address (if in-person)
- Travel/buffer impact
- Known conflicts and required moves
- Reservation feasibility

Do not contact the counterparty until the human approves.

### 5. Create Tentative Holds (After Human Approves Options)

- Create one tentative hold per approved option.
- Use color `8` for tentative.
- Record every hold event ID immediately.

```bash
gog calendar create <calendar_id> \
  --summary "HOLD: <Counterparty Name> (<Option Label>)" \
  --from "YYYY-MM-DDTHH:MM:SS<offset>" \
  --to "YYYY-MM-DDTHH:MM:SS<offset>" \
  --event-color 8
```

### 6. Outreach Email

- Use templates in `references/email-templates.md`.
- Draft message for approval first.
- After approval, send and store thread/message identifiers in tracking.
- Use `--body-html` when sending email.

### 7. Handle Counterparty Response

- `accepted`: move to confirmation workflow.
- `counter-proposed`: re-run availability and return to human for approval.
- `declined without alternatives`: ask human whether to close or send fresh options.
- No response after 2 business days: ask human whether to send follow-up.

### 8. Confirm Meeting

1. Delete unused tentative holds.

```bash
gog calendar delete <calendar_id> <event_id> --force
```

1. Create confirmed main event.

In-person:

```bash
gog calendar create <calendar_id> \
  --summary "<Human Name> // <Counterparty Name>" \
  --from "YYYY-MM-DDTHH:MM:SS<offset>" \
  --to "YYYY-MM-DDTHH:MM:SS<offset>" \
  --location "<Venue Name>, <Full Street Address>" \
  --description "" \
  --attendees <counterparty_email>
```

Virtual:

```bash
gog calendar create <calendar_id> \
  --summary "<Human Name> // <Counterparty Name>" \
  --from "YYYY-MM-DDTHH:MM:SS<offset>" \
  --to "YYYY-MM-DDTHH:MM:SS<offset>" \
  --attendees <counterparty_email> \
  --meet
```

1. Add travel and post-meeting blocks when required by preferences.

```bash
gog calendar create <calendar_id> \
  --summary "Travel: Home -> <Venue>" \
  --from "<start minus travel>" \
  --to "<start>" \
  --event-color 10
```

```bash
gog calendar create <calendar_id> \
  --summary "Buffer: Post-meeting" \
  --from "<meeting end>" \
  --to "<meeting end plus buffer>" \
  --event-color 10
```

```bash
gog calendar create <calendar_id> \
  --summary "Travel: <Venue> -> Home" \
  --from "<buffer end>" \
  --to "<buffer end plus travel>" \
  --event-color 10
```

1. Reservation handling (in-person):

- Try online booking first.
- If online booking unavailable, ask human whether to call.
- Add reservation details to main event description when confirmed.

1. Send confirmation follow-up email (after approval).
2. Update tracking record with final event IDs and status `confirmed`.

### 9. Reschedule

1. Get explicit human approval.
2. Propose new options via Steps 2-4.
3. Send approved reschedule outreach.
4. On acceptance: update or recreate events, then clear obsolete entries.
5. Update reservation and tracking.

### 10. Cancel

1. Get explicit human approval.
2. Cancel or delete all related events.
3. Cancel reservation when applicable.
4. Send approved cancellation email.
5. Mark tracking entry `cancelled` with reason and timestamp.

### 11. Day-Before Confirmation

For in-person or high-stakes meetings:

1. Draft confirmation message.
2. Get approval and send.
3. Re-verify reservation details (if any).

## Command Usage Notes

- Prefer absolute timestamps with explicit UTC offsets (`-05:00`, `-08:00`, etc.).
- Always read command output and capture created/updated event IDs.
- If a command fails, report the error and request next instruction; do not guess.
- Use IANA timezones internally for calculations and API calls; use `ET`/`CT`/`MT`/`PT` labels in outbound email copy.

## Email Template Reference

Use `references/email-templates.md` for:

- Initial proposals
- Invite follow-ups
- Day-before confirmations
- Reschedule and cancellation messages
- No-response nudges

## Quality Bar

Before finishing any scheduling task, verify:

- Human approvals are documented for every outbound action
- Calendar is conflict-checked and internally consistent
- Counterparty communications are concise, accurate, and timezone-clear
- Tracking file is updated with status, IDs, and timestamps

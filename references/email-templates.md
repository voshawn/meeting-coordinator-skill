# Email Templates

All templates use placeholders: `[Human]`, `[Name]`, `[Type]`, `[Date]`, `[Time]`, etc.
Replace with actual values. Adapt tone to match SOUL.md guidance.

## Sending Rules

- **Always CC** the human's email on every outgoing message
- **Always use** `--body-html` format with signature from SOUL.md
- **Reply to threads** with `--reply-to-message-id` when a thread exists
- **Get approval** before sending anything

---

## Meeting Proposal (Multiple Options)

Use when proposing times to the other party.

**Subject:** [Type] with [Human] — Finding a Time

```
Hi [Name],

I'm coordinating a [type] for [Human] and would love to find a time that works for you.

Here are a few options:
- [Day, Month Date] at [Time] ET
- [Day, Month Date] at [Time] ET
- [Day, Month Date] at [Time] ET

[If in-person: "Happy to suggest a location that works for both of you, or open to ideas!"]
[If virtual: "I'll send a Google Meet link once we confirm."]

Let me know what works best!

[Signature]
```

---

## Calendar Invite Follow-Up

Use after sending the calendar invite to confirm details.

**Subject:** Re: [Thread Subject]

```
Hi [Name],

I just sent over a calendar invite for [type] with [Human] [relative timing]:

**[Day, Month Date] at [Time] [TZ]**
[Venue Name] ([neighborhood/context])
[Full Address]

[Brief venue note if relevant]

Let me know if you need to reschedule or if there's anything else I can help with!

[Signature]
```

---

## Day-Before Confirmation

**Subject:** Confirming tomorrow — [Type] at [Time]

```
Hi [Name],

Quick confirmation for tomorrow:

**[Day, Month Date] at [Time] [TZ]**
[If in-person: "[Venue Name], [Address]"]
[If virtual: "Google Meet: [link]"]
[If reservation: "Reservation under [Human]'s name."]

Looking forward to it!

[Signature]
```

---

## Rescheduling

**Subject:** Rescheduling [Type] — [Original Date]

```
Hi [Name],

[Human] needs to move [the/our] [type] originally scheduled for [Day, Month Date] at [Time].

Here are some alternatives:
- [Option 1]
- [Option 2]
- [Option 3]

Apologies for the shuffle — let me know what works!

[Signature]
```

---

## Cancellation

**Subject:** Cancelling [Type] — [Original Date]

```
Hi [Name],

Unfortunately [Human] needs to cancel [the/our] [type] scheduled for [Day, Month Date] at [Time].

[If rescheduling later: "We'd love to find another time — I'll follow up soon with options."]
[If not: "Thank you for your understanding."]

[Signature]
```

---

## Post-Meeting Follow-Up

**Subject:** Great [meeting/lunch/coffee] — [optional topic]

```
Hi [Name],

Thanks for meeting with [Human] [today/yesterday]. [Brief reference to conversation]

[If next steps: "As discussed, here's what's next: ..."]
[If follow-up meeting: "I'll send a calendar invite for the follow-up."]

[Signature]
```

---

## Notes

- **Relative timing:** Use "this week" / "next week" / "on [date]" correctly based on the current date
- **Timezone:** Always include the timezone from USER.md
- **Signature:** Use the signature defined in SOUL.md — do not hardcode it in templates
- **Personalize:** These are starting points. Adapt formality and warmth based on the relationship context in the email thread.

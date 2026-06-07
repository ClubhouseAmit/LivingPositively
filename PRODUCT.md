# Product

## Register

product

## Users

Mazilon serves people using a mental-health support app in vulnerable or
distressed moments. The primary user may need fast access to emergency contacts,
low-friction self-support tools, or a personal plan while attention, patience,
and emotional bandwidth are limited.

Secondary users include people maintaining wellness habits over time and family
or caregiver contexts where trust, privacy, and clear recovery paths matter.

## Product Purpose

Mazilon provides personal planning, gratitude journaling, positive-trait
reflection, emergency contact access, Feel Good imagery, and wellness resources
in a Flutter mobile app.

Success means a user can find help, recover from mistakes, understand what the
app is asking, and continue their support workflow without confusion, dead ends,
or inaccessible controls.

## Brand Personality

Calm, supportive, practical.

The interface should feel safe and steady rather than clinical, decorative, or
attention-seeking. It should reduce pressure in crisis moments and preserve
agency in reflective flows.

## Anti-references

- Text-heavy screens that trap users before they can act.
- Crisis flows where emergency access is hidden, delayed, or visually secondary.
- Decorative wellness UI that makes standard controls feel unfamiliar.
- Generic app polish that improves appearance while leaving recovery, empty
  states, accessibility, or localization gaps unresolved.
- Speculative design abstractions or broad redesigns that cross existing product
  boundaries without explicit human direction.

## Design Principles

1. Crisis access stays reachable in every app state.
2. Distressed users get one clear next action, not a wall of choices or text.
3. Every destructive or dismissive action has confirmation, undo, or a visible
   recovery path.
4. Component behavior stays predictable across Hebrew, English, Arabic, large
   text, screen readers, and small screens.
5. Improvements stay local to existing Flutter boundaries unless a human
   approves architectural change.

## Accessibility & Inclusion

Use WCAG AA as the baseline and add crisis-safety constraints for mental-health
contexts. All interactive controls need accessible labels, sufficient touch
targets, visible focus and pressed states, screen-reader state announcements,
localized strings, RTL-aware layout, and support for user text scaling.

Audio or video wellness content must have accessible alternatives such as
captions and transcripts. Error, empty, loading, and recovery states must be
clear without relying on color alone.

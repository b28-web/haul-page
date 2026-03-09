---
id: S-009
title: address-autocomplete
status: open
epics: [E-009, E-003, E-006]
---

## Address Autocomplete (Google Places)

Add address autocomplete to the booking form so customers can quickly enter a valid address on mobile. Uses Google Places API (New) via a thin server-side wrapper with `req`.

## Scope

- Server-side proxy endpoint for Places Autocomplete — keeps API key off the client
- LiveView hook: debounced input sends keystrokes to proxy, renders suggestion dropdown
- On selection, populate structured address fields (street, city, state, zip)
- Geocode result stored on Job for future routing/dispatch features
- API key in Fly secrets, request-scoped billing via Google Cloud project
- Graceful degradation: if API is down or key missing, form still accepts manual address entry

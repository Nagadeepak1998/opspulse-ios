# Live API Contract

The app runs fully in demo mode without this API. Live mode uses `HTTPOpsAPI`, `URLSession`, typed errors, and a token supplied by `APITokenProvider`.

## Authentication

Use an optional bearer token:

```http
Authorization: Bearer <token>
```

Tokens are stored by the app in Keychain. The token must never be logged.

## Dates

All dates use ISO 8601 UTC strings.

## Endpoints

### GET /health

Returns:

```json
{
  "status": "ok",
  "version": "2026.06.25",
  "generatedAt": "2026-06-25T12:00:00Z"
}
```

### GET /api/v1/services

Returns an array of service objects matching `OpsService`.

### GET /api/v1/services/{id}

Returns one service object.

### GET /api/v1/incidents

Returns an array of incident objects matching `Incident`.

### GET /api/v1/incidents/{id}

Returns one incident object.

### POST /api/v1/incidents/{id}/acknowledge

Acknowledges an incident. Returns the updated incident.

### POST /api/v1/incidents/{id}/timeline

Request:

```json
{
  "note": "Investigating elevated gateway queue time."
}
```

Returns the updated incident.

### POST /api/v1/incidents/{id}/transition

Request:

```json
{
  "status": "mitigating"
}
```

Returns the updated incident.

## Error Handling

`HTTPOpsAPI` maps failures into:

- `invalidBaseURL`
- `invalidResponse`
- `timeout`
- `unauthorized`
- `server(statusCode:body:)`
- `decoding`
- `connectivity`

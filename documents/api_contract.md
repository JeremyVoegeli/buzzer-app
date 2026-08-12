# Buzzer App — WebSocket API Contract
 
Base connection: `wss://<api-id>.execute-api.<region>.amazonaws.com/prod`
> Real value lives in `.env.local` as `NEXT_PUBLIC_WS_URL`
 
All messages sent **to** the server must include an `"action"` field matching one of the route keys below. All messages sent **from** the server (via `post_to_connection`) follow the shape `{ "message": string, "status": "success" | "Error", ...extra fields }`.
 
---

## 1. `create_user`
 
Handles both room creation and room joining — distinguished by whether `room_id` is present in the request.
 
### Request — Create a room (host)
```json
{
  "action": "create_user",
  "username": "Jeremy"
}
```
 
### Request — Join a room
```json
{
  "action": "create_user",
  "username": "Jeremy",
  "room_id": "ABCDEF"
}
```
 
### Response — Success (sent to the joiner/creator themselves)
```json
{
  "message": "Created new user.",
  "status": "success",
  "user_id": "a1a4dc35-c81b-4d35-8aca-0600a9f95e02",
  "room_id": "ABCDEF",
  "is_host": true,
  "roster": [
    { "username": "Jeremy", "is_host": true },
    { "username": "John Doe", "is_host": false }
  ]
}
```
 
### Broadcast — sent to everyone else already in the room when a new user joins
```json
{
  "message": "Created new user.",
  "status": "success",
  "roster": [
    { "username": "Jeremy", "is_host": true },
    { "username": "John Doe", "is_host": false }
  ]
}
```
> No identity fields (`room_id`/`user_id`/`is_host`) — this message is distinguished from the one above purely by their absence. Frontend replaces its whole `participants` list with `roster` on every message of either shape.
 
### Response — Error (missing body)
```json
{ "message": "Missing request body", "status": "Error" }
```
 
### Response — Error (invalid JSON)
```json
{ "message": "Invalid JSON format", "status": "Error" }
```
 
### Response — Error (room_id generation failed)
```json
{ "message": "Couldn't generate room id. Please try again later.", "status": "Error" }
```
 
### Response — Error (DB write failed)
```json
{ "message": "Couldn't add new user to the database", "status": "Error" }
```
 
---

## 2. `remove_user` (custom action, shares Lambda with `$disconnect`)

### Request
```json
{
  "action": "remove_user"
}
```
No body fields needed — the Lambda derives `room_id` from the caller's `connectionId` via the `index_by_connection_id` GSI on `connections`.

### Also triggered by: `$disconnect`
Fires automatically when a socket closes (tab closed, network drop, etc.) — same underlying cleanup logic, no client message involved.

### Response — Success
```json
{
  "message": "removed user: <user_id>",
  "status": "success"
}
```

### Response — Error (missing body)
```json
{ "message": "Missing request body", "status": "Error" }
```

### Response — Error (invalid JSON)
```json
{ "message": "Invalid JSON format", "status": "Error" }
```

### Response - Error (user not found)
```json
{"message": "User isn't currently in database", "status": "Error"}
```

---

## 3. `buzz`
 
### Request
```json
{
  "action": "buzz",
  "user_id": "a1a4dc35-c81b-4d35-8aca-0600a9f95e02",
  "room_id": "ABCDEF"
}
```
 
### Response — Broadcast when someone wins (sent to every open connection in the room, including the winner)
```json
{ "message": "Jeremy buzzed first", "status": "success" }
```
> Includes the winner's `username` embedded in the message string (not a separate field) — frontend parses it by stripping the trailing `" buzzed first"`. Every client (winner included) receives the identical message; the frontend determines "did I win?" by comparing the parsed name against its own locally-stored `username`.
 
### Non-winning buzz
No message is sent to the client. The Lambda still records the buzz in `buzz_in` and returns `{"statusCode": 200}` to API Gateway, but nothing is delivered over the socket — a losing buzz is silent from the client's perspective.
 
### Known behavior
- Stale/disconnected connections encountered during broadcast (`GoneException`) are now handled without crashing the whole invocation — confirm whether stale rows also get cleaned up from `connections`, or just skipped.
---

## 4. `clear_buzzes`

### Request
```json
{
  "action": "clear_buzzes",
  "room_id": "ABCDEF"
}
```

### Request - Success
```json
{
    "message": "Successfully cleared all buzzes for room <room_id>.",
    "status": "success"
}
```

### Response — Error (missing body)
```json
{ "message": "Missing request body", "status": "Error" }
```

### Response — Error (invalid JSON)
```json
{ "message": "Invalid JSON format", "status": "Error" }
```

### Response - Error (no buzzes were found)
```json
{
    "message": "No buzzes were found.",
    "status": "Error"
}
```

---

## 5. `$disconnect`
See **`leave_room`** above — shares the same cleanup Lambda. No client-sent body; `connectionId` from `requestContext` is the only input.

---
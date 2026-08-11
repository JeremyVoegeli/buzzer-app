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

### Response — Success
```json
{
  "message": "Created new user.",
  "status": "success",
  "room_id": "ABCDEF",
  "user_id": "a1a4dc35-c81b-4d35-8aca-0600a9f95e02",
  "is_host": true
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

### Request - Success
```json
{
  "action": "buzz",
  "user_id": "a1a4dc35-c81b-4d35-8aca-0600a9f95e02",
  "room_id": "ABCDEF"
}
```

### Response — To the winner (first buzz)
```json
{ "message": "You buzzed first!", "status": "success" }
```

### Response — Broadcast to other room members (when someone wins)
```json
{ "message": "John buzzed first", "status": "success" }
```

### Response — To a non-winning buzzer
```json
{ "message": "You didn't buzz first in the room.", "status": "success" }
```

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
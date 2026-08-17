# Buzzer App

A real-time multiplayer buzzer app (think game-show buzzer) built to get hands-on experience with Terraform and AWS serverless WebSocket infrastructure.

## What It Does

- A host creates a room and shares a 6-character room code
- Other players join the room using that code
- Anyone can hit "Buzz" — the app resolves who buzzed first and broadcasts the winner to everyone in the room in real time
- The host can clear buzzes to reset for another round
- Rejoining after a page refresh restores your session (name, room, host status) instead of dropping you back to the home screen

## Why This Project

This project's primary goal was learning **Terraform** and infrastructure-as-code — a named skill gap for the AWS/cloud roles I was targeting. A secondary goal was to get hands-on experience with **API Gateway WebSocket APIs**, a new pattern for me compared to the REST + Step Functions architecture I'd used on an earlier project.

The scope was intentionally kept small — a bare buzzer rather than a full quiz/scoring game — to keep the focus on the infrastructure and real-time architecture rather than feature breadth.

## Architecture

- **Frontend:** Next.js (JavaScript), deployed as a static/client app. Since the frontend wasn't the focus of this project, I leaned on AI assistance for a good portion of it to keep momentum on the infrastructure work.
- **Real-time transport:** API Gateway WebSocket API
- **Compute:** AWS Lambda (Python) — one function per action (create user, remove user, buzz, clear buzzes, rejoin room), plus `$disconnect` handling
- **Data:** DynamoDB
  - `buzzes` table — records each buzz-in attempt per room, ordered by timestamp
  - `connections` table — tracks active WebSocket connections per room, with a TTL attribute for automatic cleanup of abandoned connections
- **Infrastructure:** fully provisioned via Terraform — IAM roles/policies (least-privilege per Lambda), API Gateway routes and integrations, DynamoDB tables, and Lambda deployments

### Key Design Decisions

- **First-writer-wins via DynamoDB, not client timestamps.** Simultaneous buzzes are resolved by writing each buzz to DynamoDB and querying for the earliest record per room, rather than trusting client-reported timestamps (which are vulnerable to clock skew and network jitter between players).
- **TTL as a safety net, not the primary cleanup mechanism.** Live rooms self-heal stale connections by checking connection liveness against API Gateway at broadcast time; DynamoDB TTL (fixed session length) exists as a background sweep for rooms that get abandoned entirely and never receive another action.
- **Explicit rejoin flow.** Because refreshing the page creates a new WebSocket connection (and browser refreshes don't reliably trigger `$disconnect`), reconnecting a user required a dedicated `rejoin_room` action rather than reusing the user-creation flow — session identity (room, user ID, username) is persisted client-side and used to re-associate the new connection with the existing participant record.

## What I Learned

- Writing and structuring Terraform from scratch: resources, data sources, IAM policy documents, and wiring dependent resources (Lambda ↔ IAM role ↔ API Gateway integration) together
- The tradeoffs of WebSocket-based real-time apps vs. request/response REST APIs — connection lifecycle management, broadcasting to multiple clients, and the fact that clean disconnect handling is best-effort, not guaranteed
- DynamoDB access patterns (partition/sort key design, GSIs, TTL) for a connection-tracking use case
- Debugging IAM permission errors by reading `AccessDeniedException` messages closely to identify the missing action/resource
- React Strict Mode's double-invoke behavior in development and how it surfaces real cleanup bugs (e.g., WebSocket lifecycle handling) that could otherwise go unnoticed

## Status

Functionally complete and tested end-to-end (create → join → buzz → broadcast → rejoin-after-refresh). Built as a learning project focused on infrastructure and real-time architecture, not a production deployment.
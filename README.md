# Campus Letter

Campus Letter is a Flutter application for creating formal campus letters in
two formats:

- **Language Nest Letter**: includes the Language Nest header and a subtle
  watermark.
- **Normal Letter**: uses a clean formal page without the Language Nest logo.

The project also includes a Node.js and Express backend. The backend validates,
stores, and manages letters through a REST API. MongoDB is used when configured;
local JSON storage is available only as a development fallback.

## Project structure

```text
campus_letter/
├── lib/main.dart              Flutter application
├── images/                    Letter template assets
├── test/                      Flutter widget tests
└── backend/
    ├── src/
    │   ├── app.js             Express app and security middleware
    │   ├── server.js          Startup and graceful shutdown
    │   ├── auth.js            JWT verification
    │   ├── config.js          Environment configuration
    │   ├── errors.js          Structured error responses
    │   ├── letter-service.js  Letter validation and business logic
    │   ├── mongo.js           MongoDB model and repository
    │   ├── repository.js       Development JSON repository
    │   └── routes.js           REST endpoints
    ├── test/api.test.js        Backend API tests
    ├── .env.example            Safe configuration template
    └── Dockerfile               Production container image
```

## Prerequisites

- Flutter SDK
- Node.js 20 or newer
- npm
- MongoDB Atlas account or a local MongoDB server for production-like use

## Run the Flutter app

From the project root:

```powershell
flutter pub get
flutter run
```

The app supports home, create, preview, save, copy, download, and saved-letter
flows. The current Flutter UI keeps its form state locally.

The deployed API URL is configured at build time. The default is
`https://campus-letter.onrender.com/api`; for another deployment, use:

```powershell
flutter build web `
  --dart-define=API_BASE_URL=https://your-api.example/api `
  --dart-define=API_AUTH_TOKEN=<jwt-for-the-configured-user>
```

`API_AUTH_TOKEN` is only needed when the backend has `REQUIRE_AUTH=true`.
Prefer a real sign-in flow for multi-user production deployments rather than
embedding a long-lived token in a public Flutter web build.

## Run the backend locally

```powershell
cd backend
npm install
Copy-Item .env.example .env
npm run dev
```

The API starts at `http://127.0.0.1:3000`.

If `MONGO_URI` is empty, the backend starts with a local JSON fallback. This is
useful for learning and API development, but it is not suitable for production.
When `MONGO_URI` is set, the backend connects to MongoDB before listening.

## Environment configuration

Never commit `.env`. Use [backend/.env.example](backend/.env.example) as a
template and replace every placeholder locally or through your deployment
platform's secret manager.

Important values:

```env
NODE_ENV=development
MONGO_URI=mongodb+srv://<username>:<password>@<cluster>.mongodb.net/campus_letter
JWT_SECRET=<at-least-32-random-characters>
REQUIRE_AUTH=false
```

For production:

```env
NODE_ENV=production
HOST=0.0.0.0
MONGO_URI=<private MongoDB connection string>
JWT_SECRET=<strong-private-secret>
REQUIRE_AUTH=true
CLIENT_ORIGIN=https://your-frontend.example
```

Production startup refuses to run without MongoDB and JWT authentication.

## API endpoints

```text
GET    /                       API information
GET    /api/health             Health and active database status
GET    /api/auth/verify        Verify a Bearer JWT
GET    /api/letters            List the current user's letters
POST   /api/letters            Create a letter
GET    /api/letters/:id        Read one of the current user's letters
PATCH  /api/letters/:id        Update one of the current user's letters
DELETE /api/letters/:id        Delete one of the current user's letters
```

When authentication is enabled, send:

```http
Authorization: Bearer <jwt>
```

The JWT must contain a `sub` claim. Letter records store that subject as
`ownerId`, and all reads and writes are scoped to it.

## Example API request

```powershell
$body = @{
  type = "normal"
  recipient = "Dean - Academics"
  institution = "SRKR Engineering College"
  subject = "Attendance request"
  salutation = "Respected Sir/Madam,"
  message = "Please consider my request."
  senderName = "Student"
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri http://127.0.0.1:3000/api/letters `
  -ContentType "application/json" `
  -Body $body
```

## Security and deployment checklist

1. Copy `.env.example` to `.env` only on your machine.
2. Replace all MongoDB and JWT placeholders with private values.
3. Rotate any credentials that were previously placed in source files.
4. Set `NODE_ENV=production`.
5. Set `REQUIRE_AUTH=true`.
6. Use a JWT secret with at least 32 random characters.
7. Restrict `CLIENT_ORIGIN` to the real frontend origin.
8. Restrict the MongoDB Atlas network access list and database user privileges.
9. Run the container as the non-root `node` user.
10. Store production secrets in the hosting provider's secret manager.
11. Use HTTPS at the deployment proxy or platform.
12. Monitor `/api/health`, logs, and MongoDB connection events.

Helmet security headers, CORS restrictions, JSON body limits, and rate
limiting are enabled by the backend. No secret values belong in Flutter assets,
README files, source code, or `.env.example`.

## Test and validate

From the project root:

```powershell
flutter test
flutter analyze
```

For the backend:

```powershell
cd backend
npm test
node --check src/server.js
```

The backend tests use an in-memory repository, so they do not require a live
MongoDB instance. A real startup with `MONGO_URI` verifies MongoDB connectivity
before the HTTP server begins listening.

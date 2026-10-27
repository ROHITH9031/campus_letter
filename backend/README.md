# Campus Letter API

The backend is a Node.js and Express REST API for managing Language Nest and
normal campus letters.

## Run locally

```powershell
cd backend
npm install
Copy-Item .env.example .env
npm run dev
```

The API listens on `http://127.0.0.1:3000` locally. In deployment, it binds to
`0.0.0.0` and uses the platform-provided `PORT`.

Set `MONGO_URI` in `.env` to your MongoDB connection string. When it is
configured, the server uses MongoDB. If it is empty, the server starts with a
local JSON development fallback at `backend/data/letters.json`.

For deployment, set `NODE_ENV=production`, `MONGO_URI`, a strong
`JWT_SECRET`, and `REQUIRE_AUTH=true`. Production startup fails if these
requirements are not met. Set `CLIENT_ORIGIN` to the frontend origin; multiple
origins may be comma-separated. Every authenticated letter is scoped to the JWT
`sub` claim, so users cannot access another user's letters.

JWT verification is available through `GET /api/auth/verify`. Set
`REQUIRE_AUTH=true` to protect letter endpoints with
`Authorization: Bearer <token>`. Replace `JWT_SECRET` and
`JWT_EXAMPLE_TOKEN` with your own values. The values in `.env.example` are
placeholders and are not valid credentials.

## Endpoints

- `GET /`
- `GET /api/health`
- `GET /api/auth/verify`
- `GET /api/letters?type=languageNest|normal`
- `POST /api/letters`
- `GET /api/letters/:id`
- `PATCH /api/letters/:id`
- `DELETE /api/letters/:id`

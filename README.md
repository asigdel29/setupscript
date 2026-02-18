#setupscript

A single shell script that scaffolds a production-ready **Go + React + Supabase** monorepo — with linters, test frameworks, CI, and Vercel deployment baked in.

## What It Does

Run one command and get a fully wired monorepo:

```
my-app/
├── server/            # Go API (Gin + supabase-go)
│   ├── db/            # Supabase client init
│   ├── handlers/      # Route handlers + tests
│   ├── middleware/     # CORS config
│   ├── models/        # Data structs
│   ├── routers/       # Route definitions
│   ├── main.go
│   └── .golangci.yml  # Go linter config
├── client/            # React (Vite + TypeScript)
│   ├── src/
│   │   ├── lib/       # Supabase client
│   │   ├── components/
│   │   ├── pages/
│   │   └── __tests__/
│   ├── vitest.config.ts
│   ├── eslint.config.js
│   └── .prettierrc
├── api/               # Vercel serverless Go functions
├── supabase/          # Migrations & local config
├── .github/workflows/ # CI pipeline
├── vercel.json        # Deployment config
├── Makefile           # Dev commands
├── .env.example
└── README.md
```

## Prerequisites

- [Go 1.22+](https://go.dev/dl/)
- [Node.js 20+](https://nodejs.org/)
- [Git](https://git-scm.com/)
- [golangci-lint](https://golangci-lint.run/welcome/install-local/) *(for linting)*
- [Supabase CLI](https://supabase.com/docs/guides/cli) *(optional, for local DB)*

## Quick Start

```bash
chmod +x setup-fullstack.sh
./setup-fullstack.sh
```

The script will prompt you for:

| Prompt | Default | Description |
|--------|---------|-------------|
| Project name | `my-fullstack-app` | Root directory name |
| Supabase URL | *(set later)* | Your project's API URL |
| Supabase Anon Key | *(set later)* | Public client key |
| Supabase Service Role Key | *(set later)* | Server-side key |
| Supabase DB URL | *(set later)* | PostgreSQL connection string |
| Go module path | `github.com/yourusername/<name>` | Go module identifier |

## After Setup

```bash
cd my-fullstack-app
cp .env.example .env   # fill in your Supabase credentials
```

### Development

```bash
make dev               # starts Go server + React dev server concurrently
```

- Go API runs on `http://localhost:8080`
- React app runs on `http://localhost:5173` (proxies `/api` → Go server)

### Testing

```bash
make test              # run all tests
make test-server       # Go tests only (testify)
make test-client       # React tests only (vitest)
```

### Linting & Formatting

```bash
make lint              # golangci-lint + ESLint
make fmt               # gofmt + Prettier
```

### Database

```bash
make db-push           # push migrations to Supabase
make db-migrate name=add_users  # create a new migration
make db-reset          # reset local database
```

### Deploying to Vercel

```bash
vercel --prod
```

The `vercel.json` is pre-configured to:
- Build the React app from `client/dist`
- Route `/api/*` to Go serverless functions in `api/`
- Fall back to `index.html` for client-side routing

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Go, Gin, supabase-go |
| Frontend | React, TypeScript, Vite |
| Database | Supabase (PostgreSQL) |
| Go Linting | golangci-lint (errcheck, gosec, revive, staticcheck, govet) |
| JS Linting | ESLint, Prettier |
| Go Testing | `testing` + Testify |
| JS Testing | Vitest + React Testing Library |
| CI | GitHub Actions |
| Deployment | Vercel |

## CI Pipeline

The included GitHub Actions workflow (`.github/workflows/ci.yml`) runs on every push and PR to `main`:

- **Go**: lint → test with race detection + coverage
- **React**: typecheck → lint → test with coverage

## Customization

- **Add routes**: Create new handler files in `server/handlers/` and register them in `server/routers/`
- **Add pages**: Create components in `client/src/pages/` and add routes via `react-router-dom`
- **Add migrations**: Run `make db-migrate name=your_migration` and edit the generated SQL
- **Add serverless endpoints**: Create new `.go` files in `api/`

## License

MIT

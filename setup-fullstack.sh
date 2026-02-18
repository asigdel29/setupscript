#!/bin/bash
set -e

#############################################
############     BANNER       ###############
#############################################
echo "============================================="
echo "  Pre-Development Setup Harness"
echo "  Go + React + Supabase + Vercel"
echo "============================================="
echo

#############################################
############     PROMPTS      ###############
#############################################

read -p "Project name (default: my-fullstack-app): " project_name
project_name=${project_name:-my-fullstack-app}

read -p "Supabase Project URL (or press Enter to set later): " supabase_url
supabase_url=${supabase_url:-YOUR_SUPABASE_URL}

read -p "Supabase Anon Key (or press Enter to set later): " supabase_anon_key
supabase_anon_key=${supabase_anon_key:-YOUR_SUPABASE_ANON_KEY}

read -p "Supabase Service Role Key (or press Enter to set later): " supabase_service_key
supabase_service_key=${supabase_service_key:-YOUR_SUPABASE_SERVICE_ROLE_KEY}

read -p "Supabase DB Connection String (or press Enter to set later): " supabase_db_url
supabase_db_url=${supabase_db_url:-YOUR_SUPABASE_DB_URL}

go_module=""
read -p "Go module path (default: github.com/yourusername/$project_name): " go_module
go_module=${go_module:-github.com/yourusername/$project_name}

#############################################
#########  DEPENDENCY CHECKS     ############
#############################################
echo
echo "Checking dependencies..."

check_cmd() {
    if ! command -v "$1" &> /dev/null; then
        echo "ERROR: $1 is not installed. Please install it first."
        exit 1
    else
        echo "  ✓ $1 found ($(command -v $1))"
    fi
}

check_cmd go
check_cmd node
check_cmd npm
check_cmd git

echo "All dependencies found."

#############################################
####  PROJECT ROOT & MONOREPO STRUCTURE  ####
#############################################
echo
echo "Creating monorepo structure: $project_name/"
mkdir -p "$project_name"
cd "$project_name"

git init
echo "  ✓ Git initialized"

#############################################
####        ROOT-LEVEL FILES             ####
#############################################

# ---------- Root .gitignore ----------
cat << 'GITIGNORE' > .gitignore
# Dependencies
node_modules/

# Build outputs
dist/
build/
.vercel/

# Environment
.env
.env.local
.env.*.local

# Go binaries
*.exe
*.exe~
*.dll
*.so
*.dylib
*.test
*.out

# OS
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.swp
*.swo

# Coverage
coverage/
*.coverprofile
GITIGNORE
echo "  ✓ .gitignore"

# ---------- Root .env ----------
cat << EOF > .env
# Supabase
SUPABASE_URL=$supabase_url
SUPABASE_ANON_KEY=$supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=$supabase_service_key
SUPABASE_DB_URL=$supabase_db_url

# Go Server
GO_PORT=8080
GIN_MODE=debug

# Frontend
VITE_SUPABASE_URL=$supabase_url
VITE_SUPABASE_ANON_KEY=$supabase_anon_key
EOF
echo "  ✓ .env"

# ---------- .env.example ----------
cat << 'EOF' > .env.example
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_DB_URL=postgresql://postgres:[YOUR-PASSWORD]@db.your-project.supabase.co:5432/postgres

# Go Server
GO_PORT=8080
GIN_MODE=debug

# Frontend
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
EOF
echo "  ✓ .env.example"

# ---------- Root vercel.json ----------
cat << 'EOF' > vercel.json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "buildCommand": "cd client && npm run build",
  "outputDirectory": "client/dist",
  "installCommand": "cd client && npm install",
  "rewrites": [
    { "source": "/api/(.*)", "destination": "/api/$1" },
    { "source": "/(.*)", "destination": "/index.html" }
  ],
  "functions": {
    "api/**/*.go": {
      "runtime": "vercel-golang@latest",
      "maxDuration": 30
    }
  }
}
EOF
echo "  ✓ vercel.json"

# ---------- Root Makefile ----------
cat << 'MAKEFILE' > Makefile
include .env
export

############### GLOBAL VARS ###############
GO_SERVER_DIR=server
CLIENT_DIR=client
###########################################

# ─── Development ────────────────────────
.PHONY: dev
dev:
	@echo "Starting full-stack dev environment..."
	@make -j2 dev-server dev-client

.PHONY: dev-server
dev-server:
	@cd $(GO_SERVER_DIR) && go run .

.PHONY: dev-client
dev-client:
	@cd $(CLIENT_DIR) && npm run dev

# ─── Build ──────────────────────────────
.PHONY: build
build: build-server build-client

.PHONY: build-server
build-server:
	@cd $(GO_SERVER_DIR) && go build -o ../bin/server .

.PHONY: build-client
build-client:
	@cd $(CLIENT_DIR) && npm run build

# ─── Testing ────────────────────────────
.PHONY: test
test: test-server test-client

.PHONY: test-server
test-server:
	@cd $(GO_SERVER_DIR) && go test -v -cover ./...

.PHONY: test-client
test-client:
	@cd $(CLIENT_DIR) && npm run test

# ─── Linting ────────────────────────────
.PHONY: lint
lint: lint-server lint-client

.PHONY: lint-server
lint-server:
	@cd $(GO_SERVER_DIR) && golangci-lint run ./...

.PHONY: lint-client
lint-client:
	@cd $(CLIENT_DIR) && npm run lint

# ─── Formatting ─────────────────────────
.PHONY: fmt
fmt:
	@cd $(GO_SERVER_DIR) && gofmt -w .
	@cd $(CLIENT_DIR) && npm run format

# ─── Clean ──────────────────────────────
.PHONY: clean
clean:
	@rm -rf bin/
	@rm -rf $(CLIENT_DIR)/dist
	@echo "Cleaned build artifacts."

# ─── DB Migrations (via Supabase CLI) ───
.PHONY: db-reset
db-reset:
	@supabase db reset

.PHONY: db-migrate
db-migrate:
	@supabase migration new $(name)

.PHONY: db-push
db-push:
	@supabase db push
MAKEFILE
echo "  ✓ Makefile"

# ---------- README.md ----------
cat << EOF > README.md
# $project_name

Full-stack monorepo: **Go (Gin)** + **React (Vite/TypeScript)** + **Supabase** — deployable to **Vercel**.

## Project Structure

\`\`\`
$project_name/
├── server/          # Go backend (Gin + Supabase)
│   ├── db/          # Database client & helpers
│   ├── handlers/    # Route handler functions
│   ├── middleware/   # Auth & CORS middleware
│   ├── models/      # Data models / structs
│   ├── routers/     # Route definitions
│   └── main.go
├── client/          # React frontend (Vite + TypeScript)
│   ├── src/
│   │   ├── components/
│   │   ├── lib/     # Supabase client
│   │   ├── pages/
│   │   └── App.tsx
│   └── package.json
├── api/             # Vercel serverless Go functions
├── vercel.json
├── Makefile
└── .env.example
\`\`\`

## Getting Started

### Prerequisites
- [Go 1.22+](https://go.dev/)
- [Node.js 20+](https://nodejs.org/)
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- [golangci-lint](https://golangci-lint.run/welcome/install-local/)

### Setup
1. Clone the repo and copy env vars:
   \`\`\`bash
   cp .env.example .env
   # Fill in your Supabase credentials
   \`\`\`
2. Start full-stack dev:
   \`\`\`bash
   make dev
   \`\`\`

### Commands
| Command            | Description                         |
|--------------------|-------------------------------------|
| \`make dev\`         | Start Go server + React dev server  |
| \`make test\`        | Run all tests (Go + React)          |
| \`make lint\`        | Lint all code (golangci-lint + ESLint) |
| \`make build\`       | Production build                    |
| \`make fmt\`         | Format all code                     |
| \`make db-push\`     | Push Supabase migrations            |

### Deploying to Vercel
\`\`\`bash
vercel --prod
\`\`\`

## Tech Stack
- **Backend**: Go, Gin, supabase-go
- **Frontend**: React, TypeScript, Vite
- **Database**: Supabase (PostgreSQL)
- **Linting**: golangci-lint, ESLint, Prettier
- **Testing**: Go testing + Testify, Vitest + React Testing Library
- **Deployment**: Vercel
EOF
echo "  ✓ README.md"

#############################################
####          GO SERVER SETUP            ####
#############################################
echo
echo "Setting up Go server..."
mkdir -p server
cd server

# Go module
go mod init "$go_module/server"
echo "  ✓ go mod init"

# Install Go dependencies
echo "  Installing Go packages..."
go get -u github.com/gin-gonic/gin
go get -u github.com/gin-contrib/cors
go get github.com/joho/godotenv
go get github.com/supabase-community/supabase-go
go get github.com/stretchr/testify
echo "  ✓ Go packages installed"

# ─── db/db.go ───
mkdir -p db
cat << 'EOF' > db/db.go
package db

import (
	"log"
	"os"

	supa "github.com/supabase-community/supabase-go"
)

var Client *supa.Client

// InitSupabase initializes the Supabase client using env vars.
func InitSupabase() {
	url := os.Getenv("SUPABASE_URL")
	key := os.Getenv("SUPABASE_SERVICE_ROLE_KEY")

	if url == "" || key == "" {
		log.Fatal("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set")
	}

	client, err := supa.NewClient(url, key, nil)
	if err != nil {
		log.Fatalf("Failed to create Supabase client: %v", err)
	}

	Client = client
	log.Println("Supabase client initialized")
}
EOF
echo "  ✓ db/db.go"

# ─── models/models.go ───
mkdir -p models
cat << 'EOF' > models/models.go
package models

import "time"

// Example model — customize for your schema.
type Item struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

// HealthResponse is the response for the health check endpoint.
type HealthResponse struct {
	Status  string `json:"status"`
	Service string `json:"service"`
}
EOF
echo "  ✓ models/models.go"

# ─── handlers/handlers.go ───
mkdir -p handlers
cat << 'EOF' > handlers/handlers.go
package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// HealthCheck returns service health status.
func HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "ok",
		"service": "go-server",
	})
}

// Ping is a simple liveness probe.
func Ping(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "pong"})
}
EOF
echo "  ✓ handlers/handlers.go"

# ─── handlers/handlers_test.go ───
cat << 'EOF' > handlers/handlers_test.go
package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func setupRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.Default()
	r.GET("/ping", Ping)
	r.GET("/health", HealthCheck)
	return r
}

func TestPing(t *testing.T) {
	router := setupRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/ping", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]string
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.Nil(t, err)
	assert.Equal(t, "pong", response["message"])
}

func TestHealthCheck(t *testing.T) {
	router := setupRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/health", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]string
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.Nil(t, err)
	assert.Equal(t, "ok", response["status"])
	assert.Equal(t, "go-server", response["service"])
}
EOF
echo "  ✓ handlers/handlers_test.go"

# ─── middleware/middleware.go ───
mkdir -p middleware
cat << 'EOF' > middleware/middleware.go
package middleware

import (
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

// CORSConfig returns a CORS middleware configured for local + Vercel origins.
func CORSConfig() gin.HandlerFunc {
	return cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:5173", "https://*.vercel.app"},
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	})
}
EOF
echo "  ✓ middleware/middleware.go"

# ─── routers/routers.go ───
mkdir -p routers
cat << 'EOF' > routers/routers.go
package routers

import (
	"github.com/gin-gonic/gin"
)

// RegisterRoutes sets up all API route groups.
func RegisterRoutes(rg *gin.RouterGroup, handlers ...func(*gin.RouterGroup)) {
	for _, h := range handlers {
		h(rg)
	}
}
EOF
echo "  ✓ routers/routers.go"

# ─── main.go ───
cat << GOEOF > main.go
package main

import (
	"log"
	"os"

	"$go_module/server/db"
	"$go_module/server/handlers"
	"$go_module/server/middleware"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env in non-production
	if os.Getenv("GIN_MODE") != "release" {
		if err := godotenv.Load("../.env"); err != nil {
			log.Println("Warning: .env file not found, using system env vars")
		}
	}

	// Initialize Supabase client
	db.InitSupabase()

	// Gin engine
	r := gin.Default()
	r.SetTrustedProxies(nil)
	r.Use(middleware.CORSConfig())

	// Health & liveness
	api := r.Group("/api/v1")
	api.GET("/health", handlers.HealthCheck)
	api.GET("/ping", handlers.Ping)

	// Start server
	port := os.Getenv("GO_PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("Server starting on :%s", port)
	r.Run(":" + port)
}
GOEOF
echo "  ✓ main.go"

# ─── golangci-lint config ───
cat << 'EOF' > .golangci.yml
run:
  timeout: 5m
  modules-download-mode: readonly

linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
    - gofmt
    - goimports
    - revive
    - gosec
    - misspell
    - unconvert
    - bodyclose
    - noctx

linters-settings:
  revive:
    rules:
      - name: exported
        severity: warning
  gosec:
    excludes:
      - G104 # unhandled errors (covered by errcheck)

issues:
  exclude-use-default: false
  max-issues-per-linter: 50
  max-same-issues: 3
EOF
echo "  ✓ .golangci.yml"

go mod tidy
echo "  ✓ go mod tidy"

cd ..

#############################################
####       VERCEL API FUNCTIONS          ####
#############################################
echo
echo "Setting up Vercel serverless Go functions..."
mkdir -p api
cat << 'GOEOF' > api/index.go
package handler

import (
	"encoding/json"
	"net/http"
)

// Handler is the Vercel serverless entry point.
func Handler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "ok",
		"message": "API is running on Vercel",
	})
}
GOEOF

# api go.mod
cat << 'EOF' > api/go.mod
module vercel-api

go 1.22
EOF
echo "  ✓ api/ serverless functions"

#############################################
####        REACT CLIENT SETUP           ####
#############################################
echo
echo "Setting up React client (Vite + TypeScript)..."

npm create vite@latest client -- --template react-ts
cd client

# Install core dependencies
npm install @supabase/supabase-js react-router-dom

# Install dev dependencies: linting, formatting, testing
npm install -D \
  prettier \
  eslint-config-prettier \
  eslint-plugin-prettier \
  vitest \
  @testing-library/react \
  @testing-library/jest-dom \
  @testing-library/user-event \
  jsdom \
  @vitest/coverage-v8

echo "  ✓ npm packages installed"

# ─── Supabase client lib ───
mkdir -p src/lib
cat << 'EOF' > src/lib/supabase.ts
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error("Missing Supabase environment variables");
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
EOF
echo "  ✓ src/lib/supabase.ts"

# ─── Sample test ───
mkdir -p src/__tests__
cat << 'EOF' > src/__tests__/App.test.tsx
import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import App from "../App";

describe("App", () => {
  it("renders without crashing", () => {
    render(<App />);
    expect(document.body).toBeTruthy();
  });
});
EOF
echo "  ✓ src/__tests__/App.test.tsx"

# ─── Vitest config ───
cat << 'EOF' > vitest.config.ts
/// <reference types="vitest" />
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: "jsdom",
    setupFiles: "./src/setupTests.ts",
    css: true,
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html"],
    },
  },
});
EOF
echo "  ✓ vitest.config.ts"

# ─── Test setup file ───
cat << 'EOF' > src/setupTests.ts
import "@testing-library/jest-dom";
EOF
echo "  ✓ src/setupTests.ts"

# ─── Prettier config ───
cat << 'EOF' > .prettierrc
{
  "semi": true,
  "singleQuote": false,
  "tabWidth": 2,
  "trailingComma": "all",
  "printWidth": 100,
  "arrowParens": "always",
  "endOfLine": "auto"
}
EOF
echo "  ✓ .prettierrc"

# ─── Update ESLint config (append prettier) ───
cat << 'EOF' > eslint.config.js
import js from "@eslint/js";
import globals from "globals";
import reactHooks from "eslint-plugin-react-hooks";
import reactRefresh from "eslint-plugin-react-refresh";
import tseslint from "typescript-eslint";
import prettier from "eslint-plugin-prettier";
import prettierConfig from "eslint-config-prettier";

export default tseslint.config(
  { ignores: ["dist"] },
  {
    extends: [js.configs.recommended, ...tseslint.configs.recommended, prettierConfig],
    files: ["**/*.{ts,tsx}"],
    languageOptions: {
      ecmaVersion: 2024,
      globals: globals.browser,
    },
    plugins: {
      "react-hooks": reactHooks,
      "react-refresh": reactRefresh,
      prettier: prettier,
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      "react-refresh/only-export-components": ["warn", { allowConstantExport: true }],
      "prettier/prettier": "error",
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
      "no-console": ["warn", { allow: ["warn", "error"] }],
    },
  },
);
EOF
echo "  ✓ eslint.config.js"

# ─── Update package.json scripts ───
# Use node to patch package.json
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts = {
  ...pkg.scripts,
  'dev': 'vite',
  'build': 'tsc -b && vite build',
  'preview': 'vite preview',
  'lint': 'eslint . --ext .ts,.tsx --report-unused-disable-directives --max-warnings 0',
  'lint:fix': 'eslint . --ext .ts,.tsx --fix',
  'format': 'prettier --write \"src/**/*.{ts,tsx,css,json}\"',
  'format:check': 'prettier --check \"src/**/*.{ts,tsx,css,json}\"',
  'test': 'vitest run',
  'test:watch': 'vitest',
  'test:coverage': 'vitest run --coverage',
  'typecheck': 'tsc --noEmit'
};
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
"
echo "  ✓ package.json scripts updated"

# ─── Vite proxy for local dev ───
cat << 'EOF' > vite.config.ts
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      "/api": {
        target: "http://localhost:8080",
        changeOrigin: true,
      },
    },
  },
});
EOF
echo "  ✓ vite.config.ts (with API proxy)"

cd ..

#############################################
####        SUPABASE INIT                ####
#############################################
echo
echo "Initializing Supabase project structure..."
mkdir -p supabase/migrations

cat << 'EOF' > supabase/config.toml
# Supabase local development config
# Run `supabase start` to spin up a local instance
[api]
port = 54321

[db]
port = 54322

[studio]
port = 54323
EOF

cat << 'EOF' > supabase/migrations/00000000000000_init.sql
-- Initial migration
-- Add your table definitions here

CREATE TABLE IF NOT EXISTS items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE items ENABLE ROW LEVEL SECURITY;

-- Example RLS policy (allow all reads for anon)
CREATE POLICY "Allow public read" ON items
    FOR SELECT
    USING (true);
EOF
echo "  ✓ supabase/ initialized with sample migration"

#############################################
####       GITHUB ACTIONS CI             ####
#############################################
echo
echo "Setting up CI pipeline..."
mkdir -p .github/workflows

cat << 'EOF' > .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint-and-test-server:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: server
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: "1.22"
      - name: Install golangci-lint
        run: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
      - name: Lint
        run: golangci-lint run ./...
      - name: Test
        run: go test -v -cover -race ./...

  lint-and-test-client:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: client
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"
          cache-dependency-path: client/package-lock.json
      - run: npm ci
      - name: Typecheck
        run: npm run typecheck
      - name: Lint
        run: npm run lint
      - name: Test
        run: npm run test:coverage
EOF
echo "  ✓ .github/workflows/ci.yml"

#############################################
####         INITIAL COMMIT              ####
#############################################
echo
echo "Committing initial setup..."
git add .
git commit -m "init: scaffold fullstack Go + React + Supabase monorepo"

echo
echo "============================================="
echo "  ✅ Success! Created $project_name at $(pwd)"
echo "============================================="
echo
echo "Project structure:"
echo "  $project_name/"
echo "  ├── server/        Go API (Gin + Supabase)"
echo "  ├── client/        React (Vite + TypeScript)"
echo "  ├── api/           Vercel serverless functions"
echo "  ├── supabase/      Migrations & config"
echo "  ├── .github/       CI workflows"
echo "  ├── vercel.json    Deployment config"
echo "  └── Makefile       Dev commands"
echo
echo "Next steps:"
echo "  1. cd $project_name"
echo "  2. Fill in .env with your Supabase credentials"
echo "  3. make dev          — start full-stack dev"
echo "  4. make test         — run all tests"
echo "  5. make lint         — lint everything"
echo "  6. vercel --prod     — deploy to Vercel"
echo
echo "Happy building! 🚀"

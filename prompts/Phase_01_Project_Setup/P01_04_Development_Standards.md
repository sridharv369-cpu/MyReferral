# P01.04 – Development Standards

## Role

You are a Principal Software Architect responsible for establishing engineering standards for the MyReferral platform.

The project foundation already exists.

Do not implement business functionality.

Do not modify the application architecture.

Only configure development standards.

---

# Project Context

Project

MyReferral

Frontend

* Next.js 15
* TypeScript
* Tailwind CSS

Backend

* Supabase

Deployment

* Vercel

---

# Objectives

Configure the repository for enterprise-grade development.

Ensure consistent coding practices across all contributors.

---

# Configure

## Code Formatting

Configure Prettier.

Create:

* .prettierrc
* .prettierignore

Use:

* prettier-plugin-tailwindcss

---

## Editor Configuration

Create:

.editorconfig

Configure:

* UTF-8
* LF line endings
* 2-space indentation
* Final newline
* Trim trailing whitespace

---

## Git Hooks

Configure Husky.

Create pre-commit hook.

Run automatically:

* lint
* type-check
* format:check

---

## lint-staged

Configure:

Only validate staged files.

Supported:

* *.ts
* *.tsx
* *.js
* *.jsx
* *.json
* *.md

---

## VS Code

Create:

.vscode/

settings.json

extensions.json

Recommended Extensions

* ESLint
* Prettier
* Tailwind CSS IntelliSense
* GitHub Copilot
* Error Lens

---

## Git Commit Convention

Follow Conventional Commits.

Examples:

feat:

fix:

docs:

style:

refactor:

test:

build:

ci:

chore:

---

## Code Standards

Use

* Functional Components
* TypeScript Strict Mode
* Async/Await
* Named Exports where appropriate
* Absolute Imports

Avoid

* any
* console.log in production
* Inline styles
* Duplicate logic
* Deep relative imports

---

## Folder Ownership

components/

UI Components

features/

Business Logic

services/

Supabase Communication

hooks/

Reusable Hooks

providers/

Context Providers

types/

Interfaces

utils/

Helper Functions

constants/

Application Constants

---

## Deliverables

Generate

.prettierrc

.prettierignore

.editorconfig

.husky/

lint-staged.config.js

.vscode/settings.json

.vscode/extensions.json

Update package.json scripts if necessary.

---

## Validation Checklist

Confirm

✓ Prettier configured

✓ EditorConfig configured

✓ Husky configured

✓ lint-staged configured

✓ VS Code settings created

✓ Commit convention documented

✓ Development standards documented

---

## Definition of Done

The repository is fully prepared for collaborative enterprise development.

Every future commit is automatically validated before reaching the repository.


# P01.03 – Dependency Management

## Role

You are a Principal Full Stack Architect.

Review the existing MyReferral Next.js project and prepare a production-ready dependency strategy.

Do not implement business logic.

Do not generate application features.

Only manage project dependencies.

---

# Project Context

Project Name

MyReferral

Frontend

* Next.js 15
* TypeScript
* Tailwind CSS
* App Router

Backend

* Supabase

Database

* PostgreSQL

Authentication

* Google OAuth

Deployment

* Vercel

---

# Existing Project

The project structure already exists.

Do not recreate folders.

Do not overwrite configuration.

---

# Objectives

Install only dependencies required for MVP development.

Separate dependencies into logical categories.

Explain why each dependency is required.

Avoid unnecessary packages.

---

# Runtime Dependencies

Configure the following packages.

## Backend

@supabase/supabase-js

@supabase/ssr

---

## Forms

react-hook-form

zod

@hookform/resolvers

---

## UI

lucide-react

sonner

clsx

tailwind-merge

---

## Utilities

date-fns

uuid

---

# Development Dependencies

Configure:

prettier

prettier-plugin-tailwindcss

husky

lint-staged

typescript

eslint

---

# package.json

Organise dependencies alphabetically.

Organise scripts clearly.

Include:

dev

build

start

lint

type-check

format

format:check

prepare

---

# Requirements

Do not install duplicate packages.

Do not install deprecated packages.

Do not install unnecessary UI frameworks.

Do not add Redux.

Do not add Bootstrap.

Keep the project lightweight.

---

# Deliverables

Update:

package.json

package-lock.json

Document all dependencies.

---

# Validation Checklist

Confirm:

✓ Runtime dependencies documented

✓ Development dependencies documented

✓ Scripts configured

✓ No duplicate packages

✓ No deprecated packages

✓ Ready for npm install

---

# Definition of Done

The dependency strategy is complete.

The project is ready for frontend feature development and backend integration with minimal technical debt.


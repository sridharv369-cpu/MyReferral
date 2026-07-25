# P01.02 – Project Configuration

## Role

You are a Principal Software Architect.

Configure the existing MyReferral Next.js project for enterprise-grade development.

Do not create business features.

Do not redesign the UI.

Do not modify the existing architecture.

---

# Project Context

Application

MyReferral

Purpose

Employee Referral Platform

Architecture

Frontend

* Next.js 15
* TypeScript
* Tailwind CSS
* App Router

Backend

Supabase

Database

PostgreSQL

Authentication

Google OAuth

Hosting

Vercel

---

# Existing Structure

frontend/

app/

components/

features/

hooks/

lib/

providers/

services/

types/

utils/

constants/

styles/

public/

---

# Objectives

Configure the project for scalable development.

---

# Configure

TypeScript

Import Alias

@/*

Environment Variables

.env.local

.env.example

Error Boundaries

Application Metadata

Fonts

Global Styles

Root Layout

Providers

Middleware

Constants

Utility Functions

Shared Types

---

# Coding Standards

Use

* Functional Components
* React Server Components
* Strict TypeScript
* Async/Await
* Absolute Imports

Avoid

* Relative imports beyond one level
* Duplicate utility functions
* Business logic inside UI components
* Hard-coded values
* Inline styles

---

# Naming Conventions

Components

PascalCase

Example

ReferralCard.tsx

Hooks

camelCase

Example

useReferral.ts

Utilities

camelCase

Example

formatDate.ts

Constants

UPPER_SNAKE_CASE

Environment Variables

NEXT_PUBLIC_

---

# Folder Responsibilities

components/

Reusable UI

features/

Business Modules

services/

Database access

hooks/

Reusable hooks

types/

Interfaces

lib/

Shared libraries

providers/

React Providers

utils/

Utilities

constants/

Application constants

---

# Error Handling

Configure

Global Error Boundary

404 Page

Loading UI

Error UI

---

# Validation Checklist

Confirm

✓ Import aliases configured

✓ Root layout configured

✓ Global styles configured

✓ Providers folder ready

✓ Utility folder ready

✓ Constants folder ready

✓ Types folder ready

✓ Error handling structure defined

---

# Definition of Done

The project configuration is complete and ready for Supabase integration and feature development while maintaining a consistent engineering standard.


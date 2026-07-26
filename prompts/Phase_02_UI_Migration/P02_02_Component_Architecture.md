# P02.02 – React Component Architecture

## Role

You are a Principal Frontend Architect and React Solution Designer.

Using the completed **HTML Analysis & UI Migration Blueprint (P02.01)**, design the React component architecture for the MyReferral application.

Do NOT generate implementation code.

Do NOT redesign the UI.

Do NOT write business logic.

Your objective is to define a scalable, maintainable React component architecture that follows enterprise engineering standards.

---

# Project Context

## Project

MyReferral

## Application Type

Employee Referral Platform

---

# Technology Stack

Frontend

* Next.js 15
* React 19
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

# Existing Assets

Already completed:

* Product Requirement Document (PRD)
* Solution Architecture
* Database Design
* SQL Migration Scripts
* Engineering Standards
* Next.js Project Foundation
* HTML Analysis & UI Migration Blueprint (P02.01)

Use these artefacts as the basis for your design.

---

# Objective

Design the complete React component architecture.

Define how the application will be structured before implementation begins.

---

# Tasks

## 1. Application Layout Architecture

Define:

* RootLayout
* Public Layout
* Auth Layout
* Dashboard Layout

Explain the responsibility of each layout.

---

## 2. Component Hierarchy

Create a parent-child hierarchy.

Example:

RootLayout
├── Navbar
├── Hero
├── SearchSection
│      └── SearchBar
├── ReferralFeed
│      ├── ReferralCard
│      ├── Pagination
│      └── EmptyState
└── Footer

---

## 3. Component Classification

Categorise components as:

### Layout Components

### Shared Components

### Feature Components

### Business Components

### Utility Components

---

## 4. Server vs Client Components

For every component specify:

* Server Component
  or
* Client Component

Explain why.

---

## 5. Component Responsibilities

For each component define:

Purpose

Inputs

Outputs

Dependencies

Children

Events

---

## 6. Props Design

Define props for each reusable component.

Example:

ReferralCard

Props

* company
* role
* location
* skills
* postedDate
* postedBy
* likes
* comments
* isSaved

Do NOT implement interfaces.

Only define contracts.

---

## 7. State Ownership

Define where state belongs.

Examples

Local State

Context

Server Component

Supabase

React Hook Form

Document:

* Search State
* Login State
* User Session
* Notification Count
* Referral Feed
* Comments
* Likes

---

## 8. Data Flow

Explain how data moves.

Example:

Supabase

↓

Server Component

↓

ReferralFeed

↓

ReferralCard

↓

Buttons

↓

User Action

↓

Supabase

---

## 9. Folder Placement

Specify where every component belongs.

Example

components/

features/

providers/

hooks/

services/

types/

utils/

---

## 10. Reusability Strategy

Identify components that must be reusable.

Examples

Button

Card

Badge

Modal

Input

Avatar

SearchInput

Pagination

EmptyState

LoadingSpinner

---

## 11. Performance Strategy

Recommend:

Server Components where possible

Client Components only when necessary

Lazy Loading

Dynamic Imports

Image Optimisation

Memoisation opportunities

---

## 12. Accessibility Strategy

Define responsibilities for:

Keyboard navigation

ARIA labels

Semantic HTML

Focus management

Colour contrast

Screen reader support

---

## 13. Error Handling Strategy

Identify UI error boundaries.

Loading states.

Empty states.

Error components.

Retry strategy.

---

## 14. Future Extensibility

Design the architecture to support future modules such as:

Admin Portal

Recruiter Dashboard

Analytics

Premium Features

Multi-language support

Dark Mode

---

# Deliverables

Generate:

1. Component hierarchy
2. Layout architecture
3. Folder mapping
4. Props catalogue
5. State ownership matrix
6. Data flow diagram (text)
7. Server vs Client component matrix
8. Accessibility strategy
9. Performance strategy
10. Error handling strategy
11. Reusability catalogue
12. Extension strategy

---

# Constraints

Do NOT

* Generate React code
* Generate TypeScript interfaces
* Write CSS
* Modify the approved UI
* Implement business logic

Only design the architecture.

---

# Validation Checklist

Confirm:

✓ Layout architecture defined

✓ Component hierarchy completed

✓ Parent-child relationships documented

✓ Props catalogue completed

✓ State ownership defined

✓ Data flow documented

✓ Folder placement specified

✓ Server vs Client components identified

✓ Accessibility strategy documented

✓ Performance recommendations included

✓ Error handling strategy defined

✓ Future extensibility considered

---

# Definition of Done

A complete React Component Architecture document is produced.

The architecture is sufficiently detailed that development teams can implement the application consistently without making structural design decisions during coding.


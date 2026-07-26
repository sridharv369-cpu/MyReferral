# P02.03 – Layout Migration

## Role

You are a Principal Frontend Engineer responsible for implementing the application layout for the MyReferral platform.

This is the first implementation task.

The React Component Architecture (P02.02) has already been approved.

Your responsibility is to implement the application shell only.

Do NOT implement business functionality.

Do NOT connect to Supabase.

Do NOT implement authentication.

Do NOT redesign the approved UI.

---

# Project Context

Project

MyReferral

Application

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

Authentication

* Google OAuth (Future Phase)

Deployment

* Vercel

---

# Existing Assets

Completed

✓ Product Requirement Document

✓ Solution Architecture

✓ Database Design

✓ HTML Analysis

✓ React Component Architecture

✓ Project Setup

Use these artefacts as the source of truth.

---

# Objective

Implement the application layout that all future pages will inherit.

Create only the application shell.

No business features.

---

# Tasks

## 1. Root Layout

Create:

app/layout.tsx

Responsibilities:

* Configure HTML structure
* Configure metadata
* Import global styles
* Configure fonts
* Wrap application with providers
* Render page children

Follow Next.js App Router best practices.

---

## 2. Home Page

Create:

app/page.tsx

Requirements

Do NOT recreate the full homepage.

Render only a placeholder layout using the approved architecture.

Include placeholders for:

* Navbar
* Hero
* Search Section
* Referral Feed
* Footer

Do not use hardcoded business data.

---

## 3. Providers

Create:

providers/

Create a root provider that will later host:

* Supabase Session Provider
* Theme Provider
* Toast Provider

At this stage implement only the provider structure.

---

## 4. Global Styles

Review:

styles/

Configure:

* CSS variables
* Global typography
* Base spacing
* Utility classes

Do not redesign the visual appearance.

---

## 5. Metadata

Configure:

* Title

MyReferral

* Description

Employee Referral Platform

* Icons

* Open Graph placeholders

* SEO-ready metadata

---

## 6. Fonts

Configure one production-ready Google Font.

Recommended:

Inter

Use next/font/google.

---

## 7. Error Pages

Create:

app/not-found.tsx

app/error.tsx

app/loading.tsx

Provide professional placeholder implementations.

---

## 8. Route Groups

Prepare the routing structure.

Create folders only:

app/

(public)/

(auth)/

dashboard/

profile/

referrals/

Do not implement pages inside them yet.

---

## 9. Layout Standards

Ensure:

* No duplicated layout code
* Shared layout
* Semantic HTML
* Responsive container
* Accessibility-friendly structure

---

# Deliverables

Generate production-ready implementations for:

app/layout.tsx

app/page.tsx

app/loading.tsx

app/error.tsx

app/not-found.tsx

providers/

Global layout structure

Metadata configuration

Font configuration

---

# Constraints

Do NOT

* Connect Supabase
* Create APIs
* Implement authentication
* Implement business logic
* Add sample data
* Add mock referrals
* Modify approved UI

Only implement the application shell.

---

# Acceptance Criteria

The application starts successfully.

Shared layout renders correctly.

Providers are configured.

Global styles load correctly.

Metadata is configured.

Error pages exist.

Loading page exists.

Fonts load correctly.

Route groups are created.

Ready for Navbar implementation.

---

# Validation Checklist

Confirm:

✓ app/layout.tsx created

✓ app/page.tsx created

✓ Providers configured

✓ Global styles loaded

✓ Metadata configured

✓ Font configured

✓ Error page created

✓ Loading page created

✓ Not-found page created

✓ Route groups created

✓ No business logic added

✓ Ready for Navigation implementation

---

# Definition of Done

The MyReferral application shell is complete.

Every future page inherits the same layout.

The project is ready to implement the Navigation component in the next phase.


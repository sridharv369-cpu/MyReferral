# P02.06 – Shared UI Components (Design System)

## Role

You are a Principal Frontend Architect responsible for designing and implementing the shared UI component library for the MyReferral platform.

The landing page and navigation have already been migrated.

Your responsibility is to create reusable, production-ready UI components that will be shared across the entire application.

Do NOT implement business logic.

Do NOT connect to Supabase.

Do NOT redesign the approved UI.

---

# Project Context

Project

MyReferral

Application

Employee Referral Platform

Technology

* Next.js 15
* React 19
* TypeScript
* Tailwind CSS
* App Router

Backend

* Supabase

Deployment

* Vercel

---

# Existing Assets

Completed

✓ Project Foundation

✓ Component Architecture

✓ Layout Migration

✓ Navigation

✓ Landing Page

✓ Approved HTML

---

# Objective

Create a reusable UI component library that follows enterprise design system principles.

All future pages must use these shared components.

---

# Folder Structure

Create:

components/ui/

Button/

Input/

Textarea/

Select/

SearchInput/

Card/

Badge/

Avatar/

Modal/

Dialog/

Drawer/

Dropdown/

Tooltip/

Toast/

Spinner/

Skeleton/

EmptyState/

ErrorState/

Pagination/

Breadcrumb/

Divider/

Chip/

Tag/

IconButton/

LoadingOverlay/

ConfirmDialog/

SectionHeading/

Container/

---

# Component Requirements

Every component must:

* Be reusable
* Be strongly typed with TypeScript
* Accept configurable props
* Support accessibility
* Use Tailwind CSS
* Avoid inline styles
* Support responsive layouts
* Be documented with comments where necessary

---

# Button

Support:

Primary

Secondary

Outline

Ghost

Link

Danger

Disabled

Loading

Icon Only

Different sizes:

Small

Medium

Large

---

# Input

Support:

Text

Email

Password

Search

Number

Disabled

ReadOnly

Validation State

Error Message

Helper Text

Prefix/Suffix Icons

---

# Card

Support:

Header

Content

Footer

Image

Actions

Hover state

Loading state

---

# Modal / Dialog

Support:

Header

Body

Footer

Close button

Escape key

Overlay click

Focus trap

---

# Dropdown

Support:

Keyboard navigation

ARIA

Nested items

Icons

Disabled items

---

# Avatar

Support:

Image

Initials

Status badge

Sizes

Fallback image

---

# Badge / Chip / Tag

Support:

Status

Success

Warning

Error

Info

Neutral

---

# Pagination

Support:

Previous

Next

Page numbers

Disabled state

Responsive layout

---

# Empty State

Support:

Title

Description

Illustration placeholder

Action button

---

# Error State

Support:

Icon

Message

Retry button

---

# Loading Components

Implement:

Spinner

Skeleton

LoadingOverlay

---

# Container

Reusable responsive container.

Configurable max-width.

---

# Section Heading

Support:

Title

Subtitle

Description

Action Button

---

# Accessibility

Every component must support:

ARIA labels

Keyboard navigation

Visible focus states

Screen readers

Semantic HTML

---

# Performance

Use Server Components where possible.

Only interactive components should be Client Components.

Avoid unnecessary re-renders.

---

# Deliverables

Generate:

components/ui/

All shared UI components

Shared TypeScript types

Reusable styling utilities

Index export file

---

# Constraints

Do NOT

Implement authentication

Implement APIs

Implement Supabase

Add business logic

Redesign the UI

Install additional UI frameworks

---

# Acceptance Criteria

All components compile successfully.

All components are reusable.

TypeScript strict mode passes.

Tailwind styling consistent.

Accessibility implemented.

Ready for feature development.

---

# Validation Checklist

Confirm

✓ Button created

✓ Input created

✓ Card created

✓ Modal created

✓ Dialog created

✓ Dropdown created

✓ Avatar created

✓ Badge created

✓ Pagination created

✓ EmptyState created

✓ ErrorState created

✓ Loading components created

✓ Container created

✓ SectionHeading created

✓ Accessibility implemented

✓ TypeScript strict mode maintained

✓ No business logic added

✓ Ready for Responsive Validation

---

# Git Commit

feat(ui): implement shared design system components

---

# Definition of Done

The MyReferral Design System is complete.

All future features and pages use the shared UI component library instead of creating duplicate UI elements.


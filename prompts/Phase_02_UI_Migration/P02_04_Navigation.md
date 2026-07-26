# P02.04 – Navigation System Implementation

## Role

You are a Principal Frontend Engineer responsible for implementing the navigation system for the MyReferral platform.

The application architecture has already been approved.

Your task is to implement a production-ready, reusable navigation system.

Do NOT implement authentication logic.

Do NOT connect to Supabase.

Do NOT redesign the approved UI.

Implement only the navigation components.

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

Supabase (Future Integration)

Authentication

Google OAuth (Future Phase)

Deployment

Vercel

---

# Existing Assets

Completed

✓ Project Foundation

✓ Component Architecture

✓ Layout Migration

✓ Approved HTML Design

---

# Objective

Create a reusable navigation system that supports both the current MVP and future product growth.

---

# Components to Create

Create the following components.

components/navigation/

Navbar.tsx

NavLogo.tsx

NavLinks.tsx

NavActions.tsx

MobileMenu.tsx

MobileMenuButton.tsx

UserMenu.tsx

NavigationContainer.tsx

---

# Navigation Layout

Implement a responsive navigation bar.

Include placeholders for:

Logo

Primary Navigation Links

Search Icon (placeholder)

Notifications Icon (placeholder)

Login Button (placeholder)

Profile Avatar (placeholder)

Mobile Menu Button

Do NOT implement authentication behaviour.

---

# Desktop Navigation

Support:

Home

Browse Referrals

Companies

About

Contact

Login (placeholder)

Post Referral (placeholder)

---

# Mobile Navigation

Implement:

Hamburger Menu

Slide-down or slide-out menu

Keyboard accessible

Responsive behaviour

Touch friendly

---

# User Menu

Create the component only.

Placeholder items:

My Profile

My Referrals

Notifications

Settings

Logout

No authentication logic.

---

# Navigation State

Use local component state only for:

Mobile menu open/close

Dropdown visibility

Avoid global state.

---

# Routing

Use Next.js <Link> components.

Create placeholder routes only.

Do not implement pages.

---

# Styling

Follow the approved HTML design.

Do not redesign colours or spacing.

Use Tailwind CSS.

---

# Accessibility

Support:

Semantic <nav>

ARIA labels

Keyboard navigation

Visible focus states

Screen reader friendly buttons

Escape key closes mobile menu

---

# Performance

Use Server Components where possible.

Convert only interactive elements into Client Components.

Avoid unnecessary re-renders.

---

# Future Readiness

Design the navigation to support:

Authenticated users

Anonymous users

Admin role

Recruiter role

Dark mode

Internationalisation

Notification badges

User avatars

---

# Deliverables

Generate:

components/navigation/

Navbar.tsx

NavLogo.tsx

NavLinks.tsx

NavActions.tsx

MobileMenu.tsx

MobileMenuButton.tsx

UserMenu.tsx

NavigationContainer.tsx

Update app/layout.tsx to include the Navbar.

---

# Constraints

Do NOT

Connect Supabase

Implement Login

Implement Logout

Implement Search

Implement Notifications

Implement User Profile

Add business logic

Redesign the UI

---

# Acceptance Criteria

Responsive navigation works.

Desktop navigation renders correctly.

Mobile menu opens and closes.

Navigation uses reusable components.

Navigation is keyboard accessible.

Navigation integrates into app/layout.tsx.

Ready for authentication integration.

---

# Validation Checklist

Confirm

✓ Navbar created

✓ NavigationContainer created

✓ Desktop navigation implemented

✓ Mobile navigation implemented

✓ User menu placeholder created

✓ Responsive behaviour implemented

✓ Accessibility implemented

✓ App Router links used

✓ Navbar integrated into layout

✓ No business logic added

✓ Ready for Landing Page implementation

---

# Git Commit

feat(navigation): implement responsive navigation system

---

# Definition of Done

The MyReferral application has a production-ready navigation system that is reusable, responsive, accessible, and prepared for future authentication and role-based navigation.


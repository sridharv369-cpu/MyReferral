# P02.05 – Landing Page Migration

## Role

You are a Principal Frontend Engineer responsible for migrating the approved MyReferral landing page from static HTML into a production-ready Next.js application.

The navigation and application shell are already implemented.

Do NOT redesign the UI.

Do NOT connect to Supabase.

Do NOT implement authentication.

Do NOT implement business logic.

Your responsibility is to migrate the approved HTML into reusable React components while preserving the exact visual appearance.

---

# Project Context

Project

MyReferral

Application

Employee Referral Platform

Frontend

* Next.js 15
* React 19
* TypeScript
* Tailwind CSS
* App Router

Backend

* Supabase (Future Phase)

Authentication

* Google OAuth (Future Phase)

Deployment

* Vercel

---

# Existing Assets

Completed

✓ PRD

✓ Architecture

✓ Database Design

✓ HTML Analysis

✓ Component Architecture

✓ Layout Migration

✓ Navigation System

✓ Approved index.html

---

# Objective

Convert the landing page into reusable React components without changing the approved UI.

The landing page should become fully component-based while remaining static.

No backend integration.

---

# Components to Create

Create the following structure.

components/home/

Hero/

Hero.tsx

HeroContent.tsx

HeroActions.tsx

Search/

SearchSection.tsx

SearchBar.tsx

SearchFilters.tsx

Featured/

FeaturedReferrals.tsx

ReferralPreviewCard.tsx

Statistics/

Statistics.tsx

StatisticCard.tsx

Testimonials/

Testimonials.tsx

TestimonialCard.tsx

CTA/

CallToAction.tsx

Footer/

Footer.tsx

FooterLinks.tsx

FooterSocial.tsx

---

# Hero Section

Migrate the Hero exactly as designed.

Support:

Headline

Sub-heading

Primary CTA

Secondary CTA

Hero Illustration/Image

Responsive layout

---

# Search Section

Convert the search section.

Keep the UI static.

Create placeholders for:

Search Input

Location

Skills

Search Button

No search functionality.

---

# Featured Referrals

Convert referral cards into reusable preview components.

Use placeholder data.

Do NOT connect to Supabase.

---

# Statistics

Convert all statistic blocks into reusable cards.

Example:

Jobs Posted

Companies

Employees

Successful Referrals

---

# Testimonials

Convert testimonial section into reusable cards.

Use placeholder content.

---

# CTA Section

Convert the final call-to-action section.

Preserve typography and spacing.

---

# Footer

Convert footer into reusable components.

Include:

Navigation Links

Legal Links

Social Icons

Copyright

---

# Images

Use next/image.

Move static assets into public/.

Do not hardcode image URLs.

---

# Styling

Preserve:

Spacing

Typography

Colours

Animations

Shadows

Border Radius

Responsive behaviour

Do not redesign.

---

# Accessibility

Support:

Semantic HTML

ARIA labels

Keyboard navigation

Accessible buttons

Alt text

Focus indicators

---

# Performance

Use:

Server Components where possible

Client Components only when required

Image optimisation

Lazy loading

Avoid unnecessary client-side rendering

---

# Deliverables

Generate:

components/home/

Hero

Search

Featured

Statistics

Testimonials

CTA

Footer

Update:

app/page.tsx

Compose the landing page using the reusable components.

---

# Constraints

Do NOT

Connect Supabase

Implement authentication

Implement search logic

Implement referral APIs

Implement analytics

Redesign the UI

---

# Acceptance Criteria

Landing page visually matches the approved HTML.

All sections are reusable components.

Responsive behaviour preserved.

Images optimised.

No business logic.

Ready for backend integration.

---

# Validation Checklist

Confirm

✓ Hero migrated

✓ Search section migrated

✓ Featured referrals migrated

✓ Statistics migrated

✓ Testimonials migrated

✓ CTA migrated

✓ Footer migrated

✓ app/page.tsx updated

✓ Responsive layout preserved

✓ No business logic added

✓ Ready for Shared UI Components

---

# Git Commit

feat(home): migrate landing page into reusable React components

---

# Definition of Done

The MyReferral landing page is fully migrated into reusable Next.js components while preserving the original design and remaining ready for future Supabase integration.


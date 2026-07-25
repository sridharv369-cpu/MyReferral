# P02.01 – HTML Analysis & UI Migration Blueprint

## Role

You are a Principal Frontend Architect specializing in enterprise React and Next.js applications.

Your task is to analyze an existing client-approved **index.html** and produce a complete migration blueprint for converting it into a scalable Next.js application.

Do **NOT** generate React components.

Do **NOT** modify the UI design.

Do **NOT** write business logic.

Your responsibility is to understand the HTML and produce an implementation plan.

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

Hosting

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
* Development Standards

An approved **index.html** already exists.

This HTML is the source of truth for the UI.

---

# Objective

Analyze the HTML structure and prepare a migration blueprint.

Do not convert the HTML into React yet.

---

# Tasks

Analyze the HTML and identify:

## 1. Overall Page Structure

Document every major section.

Example:

* Header
* Hero
* Search
* Job Feed
* Statistics
* Testimonials
* Footer

---

## 2. Navigation Structure

Identify:

* Logo
* Navigation Items
* Mobile Menu
* User Menu
* CTA Buttons

---

## 3. Forms

Identify every form.

Document:

* Input fields
* Selects
* Search bars
* Buttons
* Validation requirements

---

## 4. Cards

Identify every card type.

Examples:

* Referral Card
* Company Card
* Profile Card
* Statistics Card

Document:

* Fields displayed
* Actions available
* Dynamic content placeholders

---

## 5. Buttons

List every button.

Examples:

* Login
* Post Referral
* Apply
* View Details
* Like
* Comment

Classify each button as:

* Primary
* Secondary
* Icon
* Link

---

## 6. Images

Identify:

* Logos
* Hero images
* Icons
* User avatars
* Background images

Specify whether each should be:

* Static asset
* Next.js Image
* Supabase Storage

---

## 7. Icons

List all icons.

Recommend using:

Lucide React

---

## 8. Responsive Behaviour

Analyze:

Desktop

Tablet

Mobile

Document:

* Navigation changes
* Grid changes
* Hidden sections
* Responsive breakpoints

---

## 9. CSS Analysis

Identify:

Reusable styles

Repeated utility classes

Color palette

Typography

Spacing system

Border radius

Shadow usage

Animations

---

## 10. JavaScript Analysis

Identify existing JavaScript.

Document:

* Interactive elements
* Dropdowns
* Navigation
* Search
* Forms
* Animations

Recommend how each interaction should be implemented in React.

---

## 11. Component Identification

Create a complete component inventory.

Example:

Layout

* RootLayout
* PublicLayout

Navigation

* Navbar
* MobileMenu

Shared

* Button
* Card
* Input
* Badge
* Avatar
* Modal

Business Components

* ReferralCard
* ReferralFeed
* SearchBar
* NotificationBadge
* UserProfile

---

## 12. Future Dynamic Components

Identify sections that will later connect to Supabase.

Examples:

* Referral Feed
* Comments
* Likes
* Notifications
* User Profile
* Search Results

---

# Deliverables

Generate a structured migration blueprint containing:

1. Page hierarchy
2. Component hierarchy
3. Responsive strategy
4. UI inventory
5. Asset inventory
6. Form inventory
7. Card inventory
8. Button inventory
9. CSS observations
10. JavaScript observations
11. Recommended React component tree

---

# Constraints

Do NOT

* Redesign the UI
* Optimize the UI
* Rewrite HTML
* Generate React code
* Create TypeScript files
* Modify CSS

Only analyze.

---

# Expected Output

Produce a professional UI Migration Blueprint that will guide the implementation of the Next.js frontend in the following phases.

---

# Validation Checklist

Confirm:

✓ Every page section identified

✓ Navigation analyzed

✓ Forms documented

✓ Cards documented

✓ Buttons classified

✓ Images inventoried

✓ Icons inventoried

✓ CSS analyzed

✓ JavaScript analyzed

✓ Component tree proposed

✓ Responsive behaviour documented

✓ Dynamic components identified

---

# Definition of Done

The HTML has been fully analyzed and a complete migration blueprint is available.

The blueprint is detailed enough that another developer can implement the React application without referring back to the original HTML except for styling details.


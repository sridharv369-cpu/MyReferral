# MyReferral

> **Connecting Job Seekers with Employee Referrals**

![Version](https://img.shields.io/badge/version-v1.0-blue)
![Status](https://img.shields.io/badge/status-Development-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Web-success)

---

# Project Overview

**MyReferral** is a referral-first job platform that enables employees to share internal job openings from their organizations while allowing job seekers to discover opportunities through skill-based search.

Unlike traditional job portals that primarily aggregate job postings, MyReferral focuses on one of the most effective hiring channels—**employee referrals**.

The platform creates a centralized marketplace where employees can publish referral opportunities and qualified candidates can connect directly with the referring employee.

---

# Business Problem

Thousands of internal job openings are available every day across companies worldwide.

Employees are often willing to refer qualified candidates, but these opportunities are typically shared across fragmented channels such as:

* LinkedIn posts
* WhatsApp groups
* Telegram channels
* Discord communities
* Personal contacts
* Alumni networks

As a result:

* Job seekers miss valuable referral opportunities.
* Employees repeatedly answer the same questions.
* Referral posts disappear quickly in chat groups.
* There is no centralized referral discovery platform.

---

# Solution

MyReferral solves this problem by providing a dedicated referral platform where employees can:

* Publish internal job openings.
* Share company referral opportunities.
* Help candidates through referrals.
* Manage their referral posts.

Job seekers can:

* Search opportunities by skill.
* View referral details.
* Contact the employee directly.
* Request referrals.
* Engage through comments and likes.

---

# Product Vision

To become the preferred platform connecting employees willing to provide referrals with job seekers seeking career opportunities.

---

# Mission

Simplify employee referrals and improve access to career opportunities through a trusted and community-driven platform.

---

# Target Audience

## Employees

Employees who want to refer candidates for positions available within their companies.

## Job Seekers

Candidates looking for referral opportunities based on their skills and experience.

---

# Minimum Viable Product (MVP)

Version 1 focuses on solving one core problem:

> Employees share internal job referrals and job seekers discover them through skill-based search.

---

# MVP Features

### Authentication

* Google Login
* Secure Authentication using Supabase Auth

---

### Referral Feed

* View latest referral opportunities
* Company details
* Job description
* Employee contact information

---

### Search

* Search by skills
* Search by company
* Search by role
* Search by location

---

### Referral Posts

Employees can:

* Create Referral Post
* Edit Referral Post
* Delete Referral Post
* View My Posts

---

### Social Features

* Comments
* Likes

---

# Future Roadmap

## Version 2

* Resume Upload
* Referral Request Workflow
* Notifications
* Saved Posts
* User Profiles
* Dashboard
* Analytics

---

## Version 3

* AI Resume Matching
* AI Skill Extraction
* AI Job Recommendation
* Company Verification
* Mobile Application
* Referral Success Tracking

---

# Technology Stack

## Frontend

* Next.js
* TypeScript
* Tailwind CSS

---

## Backend

* Supabase

---

## Database

* PostgreSQL

---

## Authentication

* Google OAuth
* Supabase Auth

---

## Hosting

* Vercel

---

## Storage

* Supabase Storage

---

## Development Tools

* Cursor Pro
* GitHub Copilot
* Bolt.new
* GitHub
* VS Code

---

# High-Level Architecture

```
                Users
                   │
                   ▼
            Next.js Frontend
                   │
                   ▼
            Supabase Backend
          ┌────────┼────────┐
          ▼        ▼        ▼
 Authentication Database Storage
          │
          ▼
     PostgreSQL
```

---

# Core Modules

* Authentication
* Referral Feed
* Search
* Referral Management
* Comments
* Likes
* Notifications
* Dashboard

---

# Repository Structure

```
MyReferral/

backend/

database/
    documentation/
    migrations/
    rollback/
    seed/

docs/
    API/
    Architecture/
    Deployment/
    Product/
    Testing/
    UX/

frontend/

scripts/

README.md
```

---

# Database Overview

The application uses PostgreSQL hosted on Supabase.

Database components include:

* Users
* Referral Posts
* Comments
* Likes
* Referral Requests
* Notifications

Implemented features:

* Indexes
* Functions
* Triggers
* Row Level Security
* Policies
* Storage
* Views
* Seed Data

---

# Security

The platform follows security best practices.

* Google OAuth Authentication
* Row Level Security (RLS)
* Principle of Least Privilege
* Secure Storage Policies
* UUID Primary Keys
* Foreign Key Constraints
* Input Validation
* SQL Injection Protection through Supabase

---

# Project Status

| Module                  | Status         |
| ----------------------- | -------------- |
| Product Requirements    | ✅ Completed    |
| Technology Architecture | ✅ Completed    |
| Database Design         | ✅ Completed    |
| SQL Migrations          | ✅ Completed    |
| Database Security       | ✅ Completed    |
| Storage                 | ✅ Completed    |
| Views                   | ✅ Completed    |
| Seed Data               | ✅ Completed    |
| Frontend                | 🚧 In Progress |
| Backend                 | 🚧 In Progress |
| Deployment              | ⏳ Planned      |

---

# Local Development

## Clone Repository

```bash
git clone <repository-url>
```

---

## Install Dependencies

```bash
npm install
```

---

## Configure Environment

Create a `.env.local` file using the `.env.example` template.

---

## Start Development Server

```bash
npm run dev
```

---

# Deployment

## Frontend

* Vercel

## Backend

* Supabase

## Database

* PostgreSQL

---

# Documentation

Detailed documentation is available under the `docs` directory.

* Product Documentation
* Architecture
* Database Design
* API Specifications
* Testing
* Deployment

---

# Development Roadmap

## Phase 0

Project Foundation

## Phase 1

Frontend Development

## Phase 2

Backend Integration

## Phase 3

Authentication

## Phase 4

Core Features

## Phase 5

Testing

## Phase 6

Deployment

## Phase 7

Production Release

---

# Contributing

Contributions are welcome.

Please read the `CONTRIBUTING.md` document before creating issues or pull requests.

---

# License

This project is licensed under the MIT License.

See the `LICENSE` file for details.

---

# Acknowledgements

Built using:

* Next.js
* Supabase
* PostgreSQL
* Tailwind CSS
* TypeScript
* Vercel
* GitHub
* Cursor Pro
* GitHub Copilot
* Bolt.new

---

# Project Motto

> **Helping people help people get hired.**


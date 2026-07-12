-- =============================================================================
-- Project:          MyReferral
-- Migration:        V1.0.9__seed_data.sql
-- Version:          V1.0.9
-- Description:      Development and demo seed data.
-- =============================================================================
-- Execution Order:  Run AFTER V1.0.8__views.sql
-- Database Engine:  PostgreSQL 17+
-- Platform:         Supabase
-- =============================================================================
-- WARNING:          THIS MIGRATION IS NOT INTENDED FOR PRODUCTION ENVIRONMENTS.
--                    It populates development and demo seed data only and
--                    MUST NOT be executed against staging or production
--                    databases. Ensure environment guards / deployment
--                    pipelines exclude this migration from production runs.
-- =============================================================================
-- Author:           Database Architecture Team
-- Change Log:
--   V1.0.9  - Initial creation of development/demo seed data migration.
-- =============================================================================
-- =============================================================================
-- Section:          Demo Users
-- Description:      Seeds 10 realistic demo user records into public.users
--                    for development and demo purposes only.
-- Notes:
--   - Mix of Indian and international names for locale coverage.
--   - Email addresses are guaranteed unique within this seed set.
--   - ON CONFLICT DO NOTHING ensures idempotent re-runs of this migration
--     against an environment where seed data may already exist.
-- =============================================================================

INSERT INTO public.users (
    id,
    name,
    email,
    profile_picture_url,
    role,
    status,
    created_at,
    updated_at
)
VALUES
    -- ---------------------------------------------------------------------
    -- User 1: Admin (India)
    -- ---------------------------------------------------------------------
    (
        '11111111-1111-4111-8111-111111111101',
        'Aarav Sharma',
        'aarav.sharma@myreferral-demo.com',
        'https://i.pravatar.cc/150?u=aarav.sharma',
        'admin',
        'active',
        '2025-01-05 09:15:00+00',
        '2025-01-05 09:15:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- User 2: Standard User (International - USA)
    -- ---------------------------------------------------------------------
    (
        '11111111-1111-4111-8111-111111111102',
        'Emily Johnson',
        'emily.johnson@myreferral-demo.com',
        'https://i.pravatar.cc/150?u=emily.johnson',
        'user',
        'active',
        '2025-01-08 11:30:00+00',
        '2025-02-01 14:20:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- User 3: Standard User (India)
    -- ---------------------------------------------------------------------
    (
        '11111111-1111-4111-8111-111111111103',
        'Priya Patel',
        'priya.patel@myreferral-demo.com',
        'https://i.pravatar.cc/150?u=priya.patel',
        'user',
        'active',
        '2025-01-10 08:45:00+00',
        '2025-01-10 08:45:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- User 4: Recruiter (International - UK)
    -- ---------------------------------------------------------------------
    (
        '11111111-1111-4111-8111-111111111104',
        'Oliver Smith',
        'oliver.smith@myreferral-demo.com',
        'https://i.pravatar.cc/150?u=oliver.smith',
        'recruiter',
        'active',
        '2025-01-12 13:00:00+00',
        '2025-03-02 10:10:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- User 5: Standard User (India)
    -- ---------------------------------------------------------------------
    (
        '11111111-1111-4111-8111-111111111105',
        'Vivaan Reddy',
        'vivaan.reddy@myreferral-demo.com',
        'https://i.pravatar.cc/150?u=vivaan.reddy',
        'user',
        'inactive',
        '2025-01-15 16:20:00+00',
        '2025-01-20 09:00:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- User 6: Standard User (International - Germany)
    -- ---------------------------------------------------------------------
    (
        '11111111-1111-4111-8111-111111111106',
        'Lukas Mueller',
        'lukas.mueller@myreferral-demo.com',
        'https://i.pravatar.cc/150?u=lukas.mueller',
        'user',
        'active',
        '2025-01-18 07:50:00+00',
        '2025-01-18 07:50:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- User 7: Recruiter (India)
    -- ---------------------------------------------------------------------
    (
        '11111111-1111-4111-8111-111111111107',
        'Ananya Iyer',
        'ananya.iyer@myreferral-demo.com',
        'https://i.pravatar.cc/150?u=ananya.iyer',
        'recruiter',
        'active',
        '2025-01-20 12:05:00+00',
        '2025-02-14 15:40:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- User 8: Standard User (International - Japan)
    -- ---------------------------------------------------------------------
    (
        '11111111-1111-4111-8111-111111111108',
        'Haruto Tanaka',
        'haruto.tanaka@myreferral-demo.com',
        'https://i.pravatar.cc/150?u=haruto.tanaka',
        'user',
        'active',
        '2025-01-22 10:25:00+00',
        '2025-01-22 10:25:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- User 9: Standard User (India)
    -- ---------------------------------------------------------------------
    (
        '11111111-1111-4111-8111-111111111109',
        'Diya Nair',
        'diya.nair@myreferral-demo.com',
        'https://i.pravatar.cc/150?u=diya.nair',
        'user',
        'pending',
        '2025-01-25 14:10:00+00',
        '2025-01-25 14:10:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- User 10: Standard User (International - Brazil)
    -- ---------------------------------------------------------------------
    (
        '11111111-1111-4111-8111-111111111110',
        'Isabella Costa',
        'isabella.costa@myreferral-demo.com',
        'https://i.pravatar.cc/150?u=isabella.costa',
        'user',
        'active',
        '2025-01-28 09:35:00+00',
        '2025-03-10 11:00:00+00'
    )
ON CONFLICT (email) DO NOTHING;
-- =============================================================================
-- Section:          Demo Referral Posts
-- Description:      Seeds 25 realistic referral job posts into
--                    public.referral_posts for development and demo purposes.
-- Notes:
--   - References existing demo users seeded above via user_id (posted_by).
--   - Covers a mix of top-tier product, consulting, and cloud/data companies.
--   - key_skills stored as a PostgreSQL TEXT[] array for query flexibility.
--   - job_id values are treated as unique per posting (external ATS reference).
--   - ON CONFLICT DO NOTHING ensures idempotent re-runs of this migration.
-- =============================================================================

INSERT INTO public.referral_posts (
    id,
    user_id,
    company_name,
    company_url,
    job_id,
    role_title,
    location,
    country,
    work_mode,
    key_skills,
    job_description,
    employee_email,
    status,
    created_at
)
VALUES
    -- -------------------------------------------------------------------
    -- 1. Google - Software Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222201',
        '11111111-1111-4111-8111-111111111101',
        'Google',
        'https://careers.google.com',
        'GOOG-SWE-10234',
        'Software Engineer',
        'Bengaluru',
        'India',
        'Hybrid',
        ARRAY['Java', 'Distributed Systems', 'Data Structures', 'Algorithms'],
        'Design, develop, and maintain scalable backend services powering Google Search infrastructure. Collaborate with cross-functional teams to deliver high-availability systems.',
        'aarav.sharma@myreferral-demo.com',
        'open',
        '2025-02-01 09:00:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 2. Microsoft - Cloud Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222202',
        '11111111-1111-4111-8111-111111111102',
        'Microsoft',
        'https://careers.microsoft.com',
        'MSFT-CLD-55821',
        'Cloud Engineer',
        'Redmond, WA',
        'United States',
        'Onsite',
        ARRAY['Azure', 'Kubernetes', 'Terraform', 'CI/CD'],
        'Own the design and implementation of Azure-based cloud infrastructure for enterprise customers, ensuring reliability and cost optimization.',
        'emily.johnson@myreferral-demo.com',
        'open',
        '2025-02-02 10:15:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 3. Amazon - Data Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222203',
        '11111111-1111-4111-8111-111111111103',
        'Amazon',
        'https://www.amazon.jobs',
        'AMZN-DE-77102',
        'Data Engineer',
        'Hyderabad',
        'India',
        'Onsite',
        ARRAY['Python', 'AWS Glue', 'Redshift', 'Spark'],
        'Build and maintain large-scale ETL pipelines supporting Amazon retail analytics platforms. Partner with data science teams on pipeline optimization.',
        'priya.patel@myreferral-demo.com',
        'open',
        '2025-02-03 11:20:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 4. Infosys - Project Manager
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222204',
        '11111111-1111-4111-8111-111111111104',
        'Infosys',
        'https://www.infosys.com/careers',
        'INFY-PM-30456',
        'Project Manager',
        'Pune',
        'India',
        'Hybrid',
        ARRAY['Agile', 'Scrum', 'Stakeholder Management', 'JIRA'],
        'Lead cross-functional delivery teams for enterprise digital transformation programs, ensuring on-time, on-budget project execution.',
        'oliver.smith@myreferral-demo.com',
        'open',
        '2025-02-04 08:30:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 5. TCS - Technical Architect
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222205',
        '11111111-1111-4111-8111-111111111105',
        'TCS',
        'https://www.tcs.com/careers',
        'TCS-TA-90211',
        'Technical Architect',
        'Chennai',
        'India',
        'Onsite',
        ARRAY['Microservices', 'System Design', 'Java', 'AWS'],
        'Define enterprise architecture blueprints and technical standards for large-scale client engagements across BFSI domain.',
        'vivaan.reddy@myreferral-demo.com',
        'draft',
        '2025-02-05 09:45:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 6. Accenture - DevOps Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222206',
        '11111111-1111-4111-8111-111111111106',
        'Accenture',
        'https://www.accenture.com/careers',
        'ACN-DVO-40987',
        'DevOps Engineer',
        'Dublin',
        'Ireland',
        'Remote',
        ARRAY['Docker', 'Jenkins', 'Ansible', 'GitOps'],
        'Automate CI/CD pipelines and infrastructure provisioning for global clients, driving DevOps maturity across delivery teams.',
        'lukas.mueller@myreferral-demo.com',
        'open',
        '2025-02-06 13:10:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 7. Adobe - AI Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222207',
        '11111111-1111-4111-8111-111111111107',
        'Adobe',
        'https://careers.adobe.com',
        'ADBE-AI-60123',
        'AI Engineer',
        'Noida',
        'India',
        'Hybrid',
        ARRAY['PyTorch', 'Generative AI', 'Computer Vision', 'MLOps'],
        'Develop and fine-tune generative AI models powering Adobe Creative Cloud intelligent features.',
        'ananya.iyer@myreferral-demo.com',
        'open',
        '2025-02-07 10:50:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 8. Oracle - Cyber Security Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222208',
        '11111111-1111-4111-8111-111111111108',
        'Oracle',
        'https://www.oracle.com/careers',
        'ORCL-SEC-20876',
        'Cyber Security Engineer',
        'Tokyo',
        'Japan',
        'Onsite',
        ARRAY['SIEM', 'Threat Modeling', 'Cloud Security', 'IAM'],
        'Protect Oracle Cloud Infrastructure by identifying vulnerabilities, implementing security controls, and responding to incidents.',
        'haruto.tanaka@myreferral-demo.com',
        'open',
        '2025-02-08 14:25:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 9. Salesforce - Software Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222209',
        '11111111-1111-4111-8111-111111111109',
        'Salesforce',
        'https://www.salesforce.com/company/careers',
        'CRM-SWE-31567',
        'Software Engineer',
        'San Francisco, CA',
        'United States',
        'Hybrid',
        ARRAY['Apex', 'LWC', 'JavaScript', 'REST APIs'],
        'Build scalable features for the Salesforce Platform, focusing on performance and multi-tenant architecture.',
        'diya.nair@myreferral-demo.com',
        'open',
        '2025-02-09 09:00:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 10. ServiceNow - Cloud Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222210',
        '11111111-1111-4111-8111-111111111110',
        'ServiceNow',
        'https://careers.servicenow.com',
        'NOW-CLD-88452',
        'Cloud Engineer',
        'Santa Clara, CA',
        'United States',
        'Remote',
        ARRAY['GCP', 'Kubernetes', 'Terraform', 'Monitoring'],
        'Manage and scale ServiceNow cloud platform infrastructure, ensuring high availability across global data centers.',
        'isabella.costa@myreferral-demo.com',
        'open',
        '2025-02-10 11:40:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 11. Databricks - Data Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222211',
        '11111111-1111-4111-8111-111111111101',
        'Databricks',
        'https://www.databricks.com/company/careers',
        'DBX-DE-11209',
        'Data Engineer',
        'Amsterdam',
        'Netherlands',
        'Hybrid',
        ARRAY['Spark', 'Delta Lake', 'Scala', 'Databricks SQL'],
        'Design and optimize large-scale data pipelines on the Databricks Lakehouse Platform for enterprise customers.',
        'aarav.sharma@myreferral-demo.com',
        'open',
        '2025-02-11 08:15:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 12. Snowflake - Cloud Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222212',
        '11111111-1111-4111-8111-111111111102',
        'Snowflake',
        'https://careers.snowflake.com',
        'SNOW-CLD-45390',
        'Cloud Engineer',
        'Bengaluru',
        'India',
        'Hybrid',
        ARRAY['Snowflake SQL', 'AWS', 'Data Warehousing', 'Terraform'],
        'Support the scalability and reliability of Snowflake cloud data platform deployments for global enterprise clients.',
        'emily.johnson@myreferral-demo.com',
        'open',
        '2025-02-12 09:20:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 13. Google - AI Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222213',
        '11111111-1111-4111-8111-111111111103',
        'Google',
        'https://careers.google.com',
        'GOOG-AI-66211',
        'AI Engineer',
        'Mountain View, CA',
        'United States',
        'Onsite',
        ARRAY['TensorFlow', 'NLP', 'Python', 'Machine Learning'],
        'Contribute to the development of large language models and applied AI systems within Google Research.',
        'priya.patel@myreferral-demo.com',
        'open',
        '2025-02-13 10:30:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 14. Microsoft - DevOps Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222214',
        '11111111-1111-4111-8111-111111111104',
        'Microsoft',
        'https://careers.microsoft.com',
        'MSFT-DVO-73920',
        'DevOps Engineer',
        'Hyderabad',
        'India',
        'Hybrid',
        ARRAY['Azure DevOps', 'Kubernetes', 'Helm', 'Bicep'],
        'Drive DevOps practices for Microsoft 365 engineering teams, focusing on release automation and observability.',
        'oliver.smith@myreferral-demo.com',
        'open',
        '2025-02-14 12:05:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 15. Amazon - Technical Architect
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222215',
        '11111111-1111-4111-8111-111111111105',
        'Amazon',
        'https://www.amazon.jobs',
        'AMZN-TA-88134',
        'Technical Architect',
        'Seattle, WA',
        'United States',
        'Onsite',
        ARRAY['AWS', 'System Design', 'Microservices', 'Java'],
        'Architect highly scalable, fault-tolerant systems supporting Amazon e-commerce platforms at global scale.',
        'vivaan.reddy@myreferral-demo.com',
        'closed',
        '2025-02-15 09:10:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 16. Infosys - Cyber Security Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222216',
        '11111111-1111-4111-8111-111111111106',
        'Infosys',
        'https://www.infosys.com/careers',
        'INFY-SEC-52781',
        'Cyber Security Engineer',
        'Bengaluru',
        'India',
        'Onsite',
        ARRAY['Penetration Testing', 'SOC', 'Firewalls', 'ISO 27001'],
        'Perform security assessments and vulnerability management for enterprise client infrastructure engagements.',
        'lukas.mueller@myreferral-demo.com',
        'open',
        '2025-02-16 08:50:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 17. TCS - Project Manager
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222217',
        '11111111-1111-4111-8111-111111111107',
        'TCS',
        'https://www.tcs.com/careers',
        'TCS-PM-64520',
        'Project Manager',
        'Mumbai',
        'India',
        'Hybrid',
        ARRAY['PMP', 'Risk Management', 'Agile', 'Budgeting'],
        'Manage large-scale IT infrastructure modernization projects for banking and financial services clients.',
        'ananya.iyer@myreferral-demo.com',
        'open',
        '2025-02-17 11:25:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 18. Accenture - Software Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222218',
        '11111111-1111-4111-8111-111111111108',
        'Accenture',
        'https://www.accenture.com/careers',
        'ACN-SWE-29844',
        'Software Engineer',
        'London',
        'United Kingdom',
        'Hybrid',
        ARRAY['C#', '.NET Core', 'Azure', 'REST APIs'],
        'Develop enterprise-grade applications for Accenture clients across financial services and retail sectors.',
        'haruto.tanaka@myreferral-demo.com',
        'open',
        '2025-02-18 13:40:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 19. Adobe - Cloud Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222219',
        '11111111-1111-4111-8111-111111111109',
        'Adobe',
        'https://careers.adobe.com',
        'ADBE-CLD-77650',
        'Cloud Engineer',
        'Bengaluru',
        'India',
        'Hybrid',
        ARRAY['AWS', 'Kubernetes', 'CloudFormation', 'Python'],
        'Support scalable cloud infrastructure for Adobe Experience Cloud services across global regions.',
        'diya.nair@myreferral-demo.com',
        'open',
        '2025-02-19 09:55:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 20. Oracle - Data Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222220',
        '11111111-1111-4111-8111-111111111110',
        'Oracle',
        'https://www.oracle.com/careers',
        'ORCL-DE-83217',
        'Data Engineer',
        'Austin, TX',
        'United States',
        'Onsite',
        ARRAY['SQL', 'Oracle Data Integrator', 'Python', 'ETL'],
        'Design and maintain enterprise data pipelines supporting Oracle Fusion Analytics Warehouse solutions.',
        'isabella.costa@myreferral-demo.com',
        'open',
        '2025-02-20 10:05:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 21. Salesforce - Technical Architect
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222221',
        '11111111-1111-4111-8111-111111111101',
        'Salesforce',
        'https://www.salesforce.com/company/careers',
        'CRM-TA-99871',
        'Technical Architect',
        'Toronto',
        'Canada',
        'Remote',
        ARRAY['Salesforce Architecture', 'Integration Patterns', 'Apex', 'MuleSoft'],
        'Define solution architecture for large-scale Salesforce implementations across enterprise customers.',
        'aarav.sharma@myreferral-demo.com',
        'open',
        '2025-02-21 08:20:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 22. ServiceNow - AI Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222222',
        '11111111-1111-4111-8111-111111111102',
        'ServiceNow',
        'https://careers.servicenow.com',
        'NOW-AI-42198',
        'AI Engineer',
        'Hyderabad',
        'India',
        'Hybrid',
        ARRAY['Machine Learning', 'NLP', 'Python', 'Now Assist'],
        'Build AI-driven workflow automation features for the ServiceNow Now Platform.',
        'emily.johnson@myreferral-demo.com',
        'open',
        '2025-02-22 12:15:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 23. Databricks - Technical Architect
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222223',
        '11111111-1111-4111-8111-111111111103',
        'Databricks',
        'https://www.databricks.com/company/careers',
        'DBX-TA-13457',
        'Technical Architect',
        'London',
        'United Kingdom',
        'Hybrid',
        ARRAY['Lakehouse Architecture', 'Spark', 'AWS', 'Data Governance'],
        'Design end-to-end Lakehouse architectures for enterprise clients adopting the Databricks platform.',
        'priya.patel@myreferral-demo.com',
        'draft',
        '2025-02-23 09:30:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 24. Snowflake - DevOps Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222224',
        '11111111-1111-4111-8111-111111111104',
        'Snowflake',
        'https://careers.snowflake.com',
        'SNOW-DVO-25630',
        'DevOps Engineer',
        'San Mateo, CA',
        'United States',
        'Onsite',
        ARRAY['CI/CD', 'Terraform', 'AWS', 'Snowflake CLI'],
        'Automate deployment pipelines and infrastructure management for Snowflake platform engineering teams.',
        'oliver.smith@myreferral-demo.com',
        'open',
        '2025-02-24 10:45:00+00'
    ),
    -- -------------------------------------------------------------------
    -- 25. Google - Cyber Security Engineer
    -- -------------------------------------------------------------------
    (
        '22222222-2222-4222-8222-222222222225',
        '11111111-1111-4111-8111-111111111105',
        'Google',
        'https://careers.google.com',
        'GOOG-SEC-91045',
        'Cyber Security Engineer',
        'Bengaluru',
        'India',
        'Hybrid',
        ARRAY['Cloud Security', 'IAM', 'Incident Response', 'GCP'],
        'Protect Google Cloud Platform infrastructure through proactive threat detection and security engineering.',
        'vivaan.reddy@myreferral-demo.com',
        'open',
        '2025-02-25 11:10:00+00'
    )
ON CONFLICT (job_id) DO NOTHING;
-- =============================================================================
-- Section:          Demo Comments
-- Description:      Seeds 50 realistic comments into public.comments,
--                    simulating candidate/referrer engagement on referral
--                    posts for development and demo purposes.
-- Notes:
--   - References existing demo users (public.users) and referral posts
--     (public.referral_posts) seeded above.
--   - Comment text reflects common real-world referral interaction patterns.
--   - ON CONFLICT DO NOTHING ensures idempotent re-runs of this migration.
-- =============================================================================

INSERT INTO public.comments (
    id,
    post_id,
    user_id,
    comment_text,
    created_at
)
VALUES
    -- ---------------------------------------------------------------------
    -- Comments on Post 1: Google - Software Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333301', '22222222-2222-4222-8222-222222222201', '11111111-1111-4111-8111-111111111102', 'Interested.', '2025-02-01 10:05:00+00'),
    ('33333333-3333-4333-8333-333333333302', '22222222-2222-4222-8222-222222222201', '11111111-1111-4111-8111-111111111103', 'Can you refer me?', '2025-02-01 11:20:00+00'),
    ('33333333-3333-4333-8333-333333333303', '22222222-2222-4222-8222-222222222201', '11111111-1111-4111-8111-111111111101', 'Please check your inbox.', '2025-02-01 12:40:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 2: Microsoft - Cloud Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333304', '22222222-2222-4222-8222-222222222202', '11111111-1111-4111-8111-111111111104', 'Resume shared.', '2025-02-02 11:00:00+00'),
    ('33333333-3333-4333-8333-333333333305', '22222222-2222-4222-8222-222222222202', '11111111-1111-4111-8111-111111111105', 'Great opportunity.', '2025-02-02 13:15:00+00'),
    ('33333333-3333-4333-8333-333333333306', '22222222-2222-4222-8222-222222222202', '11111111-1111-4111-8111-111111111102', 'Thank you.', '2025-02-02 14:00:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 3: Amazon - Data Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333307', '22222222-2222-4222-8222-222222222203', '11111111-1111-4111-8111-111111111106', 'Interested.', '2025-02-03 12:10:00+00'),
    ('33333333-3333-4333-8333-333333333308', '22222222-2222-4222-8222-222222222203', '11111111-1111-4111-8111-111111111107', 'Can you refer me?', '2025-02-03 14:30:00+00'),
    ('33333333-3333-4333-8333-333333333309', '22222222-2222-4222-8222-222222222203', '11111111-1111-4111-8111-111111111103', 'Please check your inbox.', '2025-02-03 15:05:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 4: Infosys - Project Manager
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333310', '22222222-2222-4222-8222-222222222204', '11111111-1111-4111-8111-111111111108', 'Resume shared.', '2025-02-04 09:15:00+00'),
    ('33333333-3333-4333-8333-333333333311', '22222222-2222-4222-8222-222222222204', '11111111-1111-4111-8111-111111111109', 'Great opportunity.', '2025-02-04 10:20:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 5: TCS - Technical Architect
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333312', '22222222-2222-4222-8222-222222222205', '11111111-1111-4111-8111-111111111110', 'Thank you.', '2025-02-05 11:00:00+00'),
    ('33333333-3333-4333-8333-333333333313', '22222222-2222-4222-8222-222222222205', '11111111-1111-4111-8111-111111111101', 'Interested.', '2025-02-05 12:45:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 6: Accenture - DevOps Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333314', '22222222-2222-4222-8222-222222222206', '11111111-1111-4111-8111-111111111102', 'Can you refer me?', '2025-02-06 13:30:00+00'),
    ('33333333-3333-4333-8333-333333333315', '22222222-2222-4222-8222-222222222206', '11111111-1111-4111-8111-111111111103', 'Please check your inbox.', '2025-02-06 14:10:00+00'),
    ('33333333-3333-4333-8333-333333333316', '22222222-2222-4222-8222-222222222206', '11111111-1111-4111-8111-111111111104', 'Resume shared.', '2025-02-06 15:00:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 7: Adobe - AI Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333317', '22222222-2222-4222-8222-222222222207', '11111111-1111-4111-8111-111111111105', 'Great opportunity.', '2025-02-07 11:15:00+00'),
    ('33333333-3333-4333-8333-333333333318', '22222222-2222-4222-8222-222222222207', '11111111-1111-4111-8111-111111111106', 'Thank you.', '2025-02-07 12:30:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 8: Oracle - Cyber Security Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333319', '22222222-2222-4222-8222-222222222208', '11111111-1111-4111-8111-111111111107', 'Interested.', '2025-02-08 15:10:00+00'),
    ('33333333-3333-4333-8333-333333333320', '22222222-2222-4222-8222-222222222208', '11111111-1111-4111-8111-111111111108', 'Can you refer me?', '2025-02-08 16:00:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 9: Salesforce - Software Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333321', '22222222-2222-4222-8222-222222222209', '11111111-1111-4111-8111-111111111109', 'Please check your inbox.', '2025-02-09 09:40:00+00'),
    ('33333333-3333-4333-8333-333333333322', '22222222-2222-4222-8222-222222222209', '11111111-1111-4111-8111-111111111110', 'Resume shared.', '2025-02-09 10:55:00+00'),
    ('33333333-3333-4333-8333-333333333323', '22222222-2222-4222-8222-222222222209', '11111111-1111-4111-8111-111111111101', 'Great opportunity.', '2025-02-09 11:30:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 10: ServiceNow - Cloud Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333324', '22222222-2222-4222-8222-222222222210', '11111111-1111-4111-8111-111111111102', 'Thank you.', '2025-02-10 12:05:00+00'),
    ('33333333-3333-4333-8333-333333333325', '22222222-2222-4222-8222-222222222210', '11111111-1111-4111-8111-111111111103', 'Interested.', '2025-02-10 13:20:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 11: Databricks - Data Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333326', '22222222-2222-4222-8222-222222222211', '11111111-1111-4111-8111-111111111104', 'Can you refer me?', '2025-02-11 08:40:00+00'),
    ('33333333-3333-4333-8333-333333333327', '22222222-2222-4222-8222-222222222211', '11111111-1111-4111-8111-111111111105', 'Please check your inbox.', '2025-02-11 09:55:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 12: Snowflake - Cloud Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333328', '22222222-2222-4222-8222-222222222212', '11111111-1111-4111-8111-111111111106', 'Resume shared.', '2025-02-12 10:10:00+00'),
    ('33333333-3333-4333-8333-333333333329', '22222222-2222-4222-8222-222222222212', '11111111-1111-4111-8111-111111111107', 'Great opportunity.', '2025-02-12 11:25:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 13: Google - AI Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333330', '22222222-2222-4222-8222-222222222213', '11111111-1111-4111-8111-111111111108', 'Thank you.', '2025-02-13 11:00:00+00'),
    ('33333333-3333-4333-8333-333333333331', '22222222-2222-4222-8222-222222222213', '11111111-1111-4111-8111-111111111109', 'Interested.', '2025-02-13 12:15:00+00'),
    ('33333333-3333-4333-8333-333333333332', '22222222-2222-4222-8222-222222222213', '11111111-1111-4111-8111-111111111110', 'Can you refer me?', '2025-02-13 13:30:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 14: Microsoft - DevOps Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333333', '22222222-2222-4222-8222-222222222214', '11111111-1111-4111-8111-111111111101', 'Please check your inbox.', '2025-02-14 12:45:00+00'),
    ('33333333-3333-4333-8333-333333333334', '22222222-2222-4222-8222-222222222214', '11111111-1111-4111-8111-111111111102', 'Resume shared.', '2025-02-14 13:50:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 15: Amazon - Technical Architect
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333335', '22222222-2222-4222-8222-222222222215', '11111111-1111-4111-8111-111111111103', 'Great opportunity.', '2025-02-15 09:35:00+00'),
    ('33333333-3333-4333-8333-333333333336', '22222222-2222-4222-8222-222222222215', '11111111-1111-4111-8111-111111111104', 'Thank you.', '2025-02-15 10:40:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 16: Infosys - Cyber Security Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333337', '22222222-2222-4222-8222-222222222216', '11111111-1111-4111-8111-111111111105', 'Interested.', '2025-02-16 09:20:00+00'),
    ('33333333-3333-4333-8333-333333333338', '22222222-2222-4222-8222-222222222216', '11111111-1111-4111-8111-111111111106', 'Can you refer me?', '2025-02-16 10:35:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 17: TCS - Project Manager
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333339', '22222222-2222-4222-8222-222222222217', '11111111-1111-4111-8111-111111111107', 'Please check your inbox.', '2025-02-17 12:00:00+00'),
    ('33333333-3333-4333-8333-333333333340', '22222222-2222-4222-8222-222222222217', '11111111-1111-4111-8111-111111111108', 'Resume shared.', '2025-02-17 13:15:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 18: Accenture - Software Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333341', '22222222-2222-4222-8222-222222222218', '11111111-1111-4111-8111-111111111109', 'Great opportunity.', '2025-02-18 14:05:00+00'),
    ('33333333-3333-4333-8333-333333333342', '22222222-2222-4222-8222-222222222218', '11111111-1111-4111-8111-111111111110', 'Thank you.', '2025-02-18 15:10:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 19: Adobe - Cloud Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333343', '22222222-2222-4222-8222-222222222219', '11111111-1111-4111-8111-111111111101', 'Interested.', '2025-02-19 10:20:00+00'),
    ('33333333-3333-4333-8333-333333333344', '22222222-2222-4222-8222-222222222219', '11111111-1111-4111-8111-111111111102', 'Can you refer me?', '2025-02-19 11:35:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 20: Oracle - Data Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333345', '22222222-2222-4222-8222-222222222220', '11111111-1111-4111-8111-111111111103', 'Please check your inbox.', '2025-02-20 10:50:00+00'),
    ('33333333-3333-4333-8333-333333333346', '22222222-2222-4222-8222-222222222220', '11111111-1111-4111-8111-111111111104', 'Resume shared.', '2025-02-20 12:05:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 21: Salesforce - Technical Architect
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333347', '22222222-2222-4222-8222-222222222221', '11111111-1111-4111-8111-111111111105', 'Great opportunity.', '2025-02-21 09:00:00+00'),
    ('33333333-3333-4333-8333-333333333348', '22222222-2222-4222-8222-222222222221', '11111111-1111-4111-8111-111111111106', 'Thank you.', '2025-02-21 10:15:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 24: Snowflake - DevOps Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333349', '22222222-2222-4222-8222-222222222224', '11111111-1111-4111-8111-111111111107', 'Interested.', '2025-02-24 11:40:00+00'),

    -- ---------------------------------------------------------------------
    -- Comments on Post 25: Google - Cyber Security Engineer
    -- ---------------------------------------------------------------------
    ('33333333-3333-4333-8333-333333333350', '22222222-2222-4222-8222-222222222225', '11111111-1111-4111-8111-111111111108', 'Can you refer me?', '2025-02-25 12:00:00+00')
ON CONFLICT (id) DO NOTHING;
-- =============================================================================
-- Section:          Demo Likes
-- Description:      Seeds approximately 100 "like" interactions into
--                    public.likes, simulating engagement across existing
--                    demo referral posts and demo users.
-- Notes:
--   - Uses a CROSS JOIN of all seeded demo users and referral posts to
--     guarantee (post_id, user_id) pair uniqueness by construction.
--   - A random sample of 100 pairs is selected via row_number() ordered
--     by random() to simulate organic, non-sequential engagement.
--   - created_at timestamps are randomized within a realistic 30-day
--     engagement window following the referral posts' creation dates.
--   - ON CONFLICT DO NOTHING provides a safety net for idempotent re-runs
--     of this migration, in addition to the CROSS JOIN uniqueness guarantee.
-- =============================================================================

INSERT INTO public.likes (
    id,
    post_id,
    user_id,
    created_at
)
SELECT
    gen_random_uuid()          AS id,
    combo.post_id,
    combo.user_id,
    combo.created_at
FROM (
    SELECT
        p.id AS post_id,
        u.id AS user_id,
        (TIMESTAMP '2025-02-01 00:00:00+00'
            + (random() * INTERVAL '30 days')
            + (random() * INTERVAL '12 hours')
        ) AS created_at,
        row_number() OVER (ORDER BY random()) AS rn
    FROM public.referral_posts p
    CROSS JOIN public.users u
    WHERE p.job_id LIKE ANY (ARRAY[
            'GOOG-%', 'MSFT-%', 'AMZN-%', 'INFY-%', 'TCS-%',
            'ACN-%', 'ADBE-%', 'ORCL-%', 'CRM-%', 'NOW-%', 'DBX-%', 'SNOW-%'
        ])
      AND u.email LIKE '%@myreferral-demo.com'
) combo
WHERE combo.rn <= 100
ON CONFLICT (post_id, user_id) DO NOTHING;
-- =============================================================================
-- Section:          Demo Referral Requests
-- Description:      Seeds 30 realistic referral requests into
--                    public.referral_requests, simulating candidates
--                    requesting referrals from employees for existing
--                    demo referral posts.
-- Notes:
--   - requester_id references the demo user submitting the request.
--   - employee_id references the demo user (employee) being asked to refer.
--   - resume_url points to representative demo storage locations.
--   - status values reflect a realistic request lifecycle: pending,
--     accepted, rejected, and referred.
--   - ON CONFLICT DO NOTHING ensures idempotent re-runs of this migration.
-- =============================================================================

INSERT INTO public.referral_requests (
    id,
    post_id,
    requester_id,
    employee_id,
    status,
    message,
    resume_url,
    created_at
)
VALUES
    -- ---------------------------------------------------------------------
    -- 1. Google - Software Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444401',
        '22222222-2222-4222-8222-222222222201',
        '11111111-1111-4111-8111-111111111102',
        '11111111-1111-4111-8111-111111111101',
        'pending',
        'Hi Aarav, I noticed you posted a Software Engineer opening at Google. I have 4 years of backend experience with Java and distributed systems and would really appreciate a referral. Happy to share more details if helpful.',
        'https://storage.myreferral-demo.com/resumes/emily-johnson-resume.pdf',
        '2025-02-01 12:30:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 2. Microsoft - Cloud Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444402',
        '22222222-2222-4222-8222-222222222202',
        '11111111-1111-4111-8111-111111111103',
        '11111111-1111-4111-8111-111111111102',
        'accepted',
        'Hello Emily, I am very interested in the Cloud Engineer role at Microsoft. I have hands-on experience with Azure and Terraform and would love your referral for this position.',
        'https://storage.myreferral-demo.com/resumes/priya-patel-resume.pdf',
        '2025-02-02 14:10:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 3. Amazon - Data Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444403',
        '22222222-2222-4222-8222-222222222203',
        '11111111-1111-4111-8111-111111111104',
        '11111111-1111-4111-8111-111111111103',
        'referred',
        'Hi Priya, could you please refer me for the Data Engineer role at Amazon? I have strong experience building ETL pipelines with Spark and AWS Glue. Thank you for considering.',
        'https://storage.myreferral-demo.com/resumes/oliver-smith-resume.pdf',
        '2025-02-03 15:45:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 4. Infosys - Project Manager
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444404',
        '22222222-2222-4222-8222-222222222204',
        '11111111-1111-4111-8111-111111111105',
        '11111111-1111-4111-8111-111111111104',
        'pending',
        'Hi Oliver, I saw the Project Manager opening at Infosys. I have 6 years managing agile delivery teams and would appreciate a referral. My resume is attached.',
        'https://storage.myreferral-demo.com/resumes/vivaan-reddy-resume.pdf',
        '2025-02-04 09:20:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 5. TCS - Technical Architect
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444405',
        '22222222-2222-4222-8222-222222222205',
        '11111111-1111-4111-8111-111111111106',
        '11111111-1111-4111-8111-111111111105',
        'rejected',
        'Hello Vivaan, I would like to apply for the Technical Architect role at TCS. I have extensive experience with microservices and AWS. Could you refer me?',
        'https://storage.myreferral-demo.com/resumes/lukas-mueller-resume.pdf',
        '2025-02-05 10:50:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 6. Accenture - DevOps Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444406',
        '22222222-2222-4222-8222-222222222206',
        '11111111-1111-4111-8111-111111111107',
        '11111111-1111-4111-8111-111111111106',
        'accepted',
        'Hi Lukas, thanks for posting the DevOps Engineer role at Accenture. I have solid experience with Jenkins, Docker, and Ansible and would love a referral.',
        'https://storage.myreferral-demo.com/resumes/ananya-iyer-resume.pdf',
        '2025-02-06 13:35:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 7. Adobe - AI Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444407',
        '22222222-2222-4222-8222-222222222207',
        '11111111-1111-4111-8111-111111111108',
        '11111111-1111-4111-8111-111111111107',
        'pending',
        'Hi Ananya, I am reaching out regarding the AI Engineer role at Adobe. I have experience with PyTorch and generative AI models and would be grateful for a referral.',
        'https://storage.myreferral-demo.com/resumes/haruto-tanaka-resume.pdf',
        '2025-02-07 11:15:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 8. Oracle - Cyber Security Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444408',
        '22222222-2222-4222-8222-222222222208',
        '11111111-1111-4111-8111-111111111109',
        '11111111-1111-4111-8111-111111111108',
        'referred',
        'Hello Haruto, I would like to be considered for the Cyber Security Engineer position at Oracle. I have experience with SIEM tools and cloud security. Appreciate your referral.',
        'https://storage.myreferral-demo.com/resumes/diya-nair-resume.pdf',
        '2025-02-08 15:00:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 9. Salesforce - Software Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444409',
        '22222222-2222-4222-8222-222222222209',
        '11111111-1111-4111-8111-111111111110',
        '11111111-1111-4111-8111-111111111109',
        'pending',
        'Hi Diya, I saw your post about the Software Engineer opening at Salesforce. I have experience with Apex and Lightning Web Components and would appreciate your referral.',
        'https://storage.myreferral-demo.com/resumes/isabella-costa-resume.pdf',
        '2025-02-09 09:45:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 10. ServiceNow - Cloud Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444410',
        '22222222-2222-4222-8222-222222222210',
        '11111111-1111-4111-8111-111111111101',
        '11111111-1111-4111-8111-111111111110',
        'accepted',
        'Hello Isabella, I am interested in the Cloud Engineer role at ServiceNow. I have experience with GCP and Kubernetes and would appreciate a referral for this position.',
        'https://storage.myreferral-demo.com/resumes/aarav-sharma-resume.pdf',
        '2025-02-10 12:20:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 11. Databricks - Data Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444411',
        '22222222-2222-4222-8222-222222222211',
        '11111111-1111-4111-8111-111111111102',
        '11111111-1111-4111-8111-111111111101',
        'pending',
        'Hi Aarav, I would like to apply for the Data Engineer role at Databricks. I have hands-on experience with Delta Lake and Spark and would appreciate a referral.',
        'https://storage.myreferral-demo.com/resumes/emily-johnson-resume-v2.pdf',
        '2025-02-11 08:40:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 12. Snowflake - Cloud Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444412',
        '22222222-2222-4222-8222-222222222212',
        '11111111-1111-4111-8111-111111111103',
        '11111111-1111-4111-8111-111111111102',
        'referred',
        'Hi Emily, could you refer me for the Cloud Engineer position at Snowflake? I have strong experience with Snowflake SQL and AWS infrastructure.',
        'https://storage.myreferral-demo.com/resumes/priya-patel-resume-v2.pdf',
        '2025-02-12 10:05:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 13. Google - AI Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444413',
        '22222222-2222-4222-8222-222222222213',
        '11111111-1111-4111-8111-111111111104',
        '11111111-1111-4111-8111-111111111103',
        'pending',
        'Hello Priya, I am interested in the AI Engineer role at Google. I have experience with TensorFlow and NLP models and would appreciate your referral.',
        'https://storage.myreferral-demo.com/resumes/oliver-smith-resume-v2.pdf',
        '2025-02-13 11:15:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 14. Microsoft - DevOps Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444414',
        '22222222-2222-4222-8222-222222222214',
        '11111111-1111-4111-8111-111111111105',
        '11111111-1111-4111-8111-111111111104',
        'accepted',
        'Hi Oliver, I would like to be considered for the DevOps Engineer role at Microsoft. I have experience with Azure DevOps and Kubernetes and would appreciate a referral.',
        'https://storage.myreferral-demo.com/resumes/vivaan-reddy-resume-v2.pdf',
        '2025-02-14 13:30:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 15. Amazon - Technical Architect
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444415',
        '22222222-2222-4222-8222-222222222215',
        '11111111-1111-4111-8111-111111111106',
        '11111111-1111-4111-8111-111111111105',
        'rejected',
        'Hello Vivaan, I am reaching out about the Technical Architect position at Amazon. I have deep experience in system design and AWS architecture. Could you refer me?',
        'https://storage.myreferral-demo.com/resumes/lukas-mueller-resume-v2.pdf',
        '2025-02-15 09:50:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 16. Infosys - Cyber Security Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444416',
        '22222222-2222-4222-8222-222222222216',
        '11111111-1111-4111-8111-111111111107',
        '11111111-1111-4111-8111-111111111106',
        'pending',
        'Hi Lukas, I saw the Cyber Security Engineer opening at Infosys. I have experience with penetration testing and SOC operations and would appreciate your referral.',
        'https://storage.myreferral-demo.com/resumes/ananya-iyer-resume-v2.pdf',
        '2025-02-16 08:55:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 17. TCS - Project Manager
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444417',
        '22222222-2222-4222-8222-222222222217',
        '11111111-1111-4111-8111-111111111108',
        '11111111-1111-4111-8111-111111111107',
        'referred',
        'Hello Ananya, I would like to apply for the Project Manager role at TCS. I have 5 years of Agile project delivery experience and would appreciate a referral.',
        'https://storage.myreferral-demo.com/resumes/haruto-tanaka-resume-v2.pdf',
        '2025-02-17 12:25:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 18. Accenture - Software Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444418',
        '22222222-2222-4222-8222-222222222218',
        '11111111-1111-4111-8111-111111111109',
        '11111111-1111-4111-8111-111111111108',
        'pending',
        'Hi Haruto, I am interested in the Software Engineer role at Accenture. I have experience with C# and .NET Core and would appreciate your referral for this role.',
        'https://storage.myreferral-demo.com/resumes/diya-nair-resume-v2.pdf',
        '2025-02-18 14:40:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 19. Adobe - Cloud Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444419',
        '22222222-2222-4222-8222-222222222219',
        '11111111-1111-4111-8111-111111111110',
        '11111111-1111-4111-8111-111111111109',
        'accepted',
        'Hello Diya, I would like to apply for the Cloud Engineer position at Adobe. I have experience with AWS and Kubernetes and would appreciate your referral.',
        'https://storage.myreferral-demo.com/resumes/isabella-costa-resume-v2.pdf',
        '2025-02-19 10:10:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 20. Oracle - Data Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444420',
        '22222222-2222-4222-8222-222222222220',
        '11111111-1111-4111-8111-111111111101',
        '11111111-1111-4111-8111-111111111110',
        'pending',
        'Hi Isabella, I am interested in the Data Engineer role at Oracle. I have experience with Oracle Data Integrator and ETL pipelines and would appreciate a referral.',
        'https://storage.myreferral-demo.com/resumes/aarav-sharma-resume-v2.pdf',
        '2025-02-20 11:00:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 21. Salesforce - Technical Architect
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444421',
        '22222222-2222-4222-8222-222222222221',
        '11111111-1111-4111-8111-111111111102',
        '11111111-1111-4111-8111-111111111101',
        'referred',
        'Hi Aarav, could you please refer me for the Technical Architect role at Salesforce? I have extensive experience with Salesforce architecture and integration patterns.',
        'https://storage.myreferral-demo.com/resumes/emily-johnson-resume-v3.pdf',
        '2025-02-21 09:15:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 22. ServiceNow - AI Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444422',
        '22222222-2222-4222-8222-222222222222',
        '11111111-1111-4111-8111-111111111103',
        '11111111-1111-4111-8111-111111111102',
        'pending',
        'Hello Emily, I am interested in the AI Engineer role at ServiceNow. I have experience with machine learning and NLP and would appreciate your referral.',
        'https://storage.myreferral-demo.com/resumes/priya-patel-resume-v3.pdf',
        '2025-02-22 12:35:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 23. Databricks - Technical Architect
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444423',
        '22222222-2222-4222-8222-222222222223',
        '11111111-1111-4111-8111-111111111104',
        '11111111-1111-4111-8111-111111111103',
        'rejected',
        'Hi Priya, I would like to apply for the Technical Architect role at Databricks. I have experience designing Lakehouse architectures and data governance frameworks.',
        'https://storage.myreferral-demo.com/resumes/oliver-smith-resume-v3.pdf',
        '2025-02-23 10:20:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 24. Snowflake - DevOps Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444424',
        '22222222-2222-4222-8222-222222222224',
        '11111111-1111-4111-8111-111111111105',
        '11111111-1111-4111-8111-111111111104',
        'pending',
        'Hello Oliver, I saw the DevOps Engineer opening at Snowflake. I have experience automating CI/CD pipelines with Terraform and would appreciate your referral.',
        'https://storage.myreferral-demo.com/resumes/vivaan-reddy-resume-v3.pdf',
        '2025-02-24 11:45:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 25. Google - Cyber Security Engineer
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444425',
        '22222222-2222-4222-8222-222222222225',
        '11111111-1111-4111-8111-111111111106',
        '11111111-1111-4111-8111-111111111105',
        'accepted',
        'Hi Vivaan, I would like to be considered for the Cyber Security Engineer role at Google. I have experience with GCP security and incident response.',
        'https://storage.myreferral-demo.com/resumes/lukas-mueller-resume-v3.pdf',
        '2025-02-25 12:10:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 26. Google - Software Engineer (second requester)
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444426',
        '22222222-2222-4222-8222-222222222201',
        '11111111-1111-4111-8111-111111111107',
        '11111111-1111-4111-8111-111111111101',
        'pending',
        'Hi Aarav, following up on the Software Engineer position at Google. I have strong algorithms and data structures experience and would appreciate a referral.',
        'https://storage.myreferral-demo.com/resumes/ananya-iyer-resume-v3.pdf',
        '2025-02-26 09:05:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 27. Microsoft - Cloud Engineer (second requester)
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444427',
        '22222222-2222-4222-8222-222222222202',
        '11111111-1111-4111-8111-111111111108',
        '11111111-1111-4111-8111-111111111102',
        'referred',
        'Hello Emily, I am reaching out again about the Cloud Engineer role at Microsoft. I recently completed an Azure certification and would appreciate your referral.',
        'https://storage.myreferral-demo.com/resumes/haruto-tanaka-resume-v3.pdf',
        '2025-02-27 10:30:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 28. Amazon - Data Engineer (second requester)
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444428',
        '22222222-2222-4222-8222-222222222203',
        '11111111-1111-4111-8111-111111111109',
        '11111111-1111-4111-8111-111111111103',
        'pending',
        'Hi Priya, I would like to apply for the Data Engineer role at Amazon. I have experience with Redshift and Python-based ETL pipelines and would appreciate a referral.',
        'https://storage.myreferral-demo.com/resumes/diya-nair-resume-v3.pdf',
        '2025-02-28 11:50:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 29. Adobe - AI Engineer (second requester)
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444429',
        '22222222-2222-4222-8222-222222222207',
        '11111111-1111-4111-8111-111111111110',
        '11111111-1111-4111-8111-111111111107',
        'accepted',
        'Hello Ananya, I am very interested in the AI Engineer role at Adobe. I have hands-on experience with computer vision and MLOps and would appreciate your referral.',
        'https://storage.myreferral-demo.com/resumes/isabella-costa-resume-v3.pdf',
        '2025-03-01 09:25:00+00'
    ),
    -- ---------------------------------------------------------------------
    -- 30. Salesforce - Software Engineer (second requester)
    -- ---------------------------------------------------------------------
    (
        '44444444-4444-4444-8444-444444444430',
        '22222222-2222-4222-8222-222222222209',
        '11111111-1111-4111-8111-111111111101',
        '11111111-1111-4111-8111-111111111109',
        'rejected',
        'Hi Diya, I would like to apply for the Software Engineer role at Salesforce. I have experience with JavaScript and REST APIs and would appreciate your consideration for a referral.',
        'https://storage.myreferral-demo.com/resumes/aarav-sharma-resume-v3.pdf',
        '2025-03-02 10:40:00+00'
    )
ON CONFLICT (id) DO NOTHING;
-- =============================================================================
-- Section:          Demo Notifications
-- Description:      Seeds 30 realistic notifications into public.notifications,
--                    simulating system-generated alerts for demo users based
--                    on comments, likes, referral requests, and referral
--                    outcomes.
-- Notes:
--   - user_id references the demo user (public.users) receiving the
--     notification.
--   - type values: COMMENT, LIKE, REFERRAL_REQUEST, REFERRAL_ACCEPTED, SYSTEM.
--   - is_read reflects a realistic mix of read/unread notification states.
--   - ON CONFLICT DO NOTHING ensures idempotent re-runs of this migration.
-- =============================================================================

INSERT INTO public.notifications (
    id,
    user_id,
    type,
    message,
    is_read,
    created_at
)
VALUES
    -- ---------------------------------------------------------------------
    -- COMMENT notifications
    -- ---------------------------------------------------------------------
    ('55555555-5555-4555-8555-555555555501', '11111111-1111-4111-8111-111111111101', 'COMMENT', 'Emily Johnson commented on your referral post for Software Engineer at Google.', TRUE, '2025-02-01 10:06:00+00'),
    ('55555555-5555-4555-8555-555555555502', '11111111-1111-4111-8111-111111111102', 'COMMENT', 'Oliver Smith commented on your referral post for Cloud Engineer at Microsoft.', FALSE, '2025-02-02 11:05:00+00'),
    ('55555555-5555-4555-8555-555555555503', '11111111-1111-4111-8111-111111111103', 'COMMENT', 'Lukas Mueller commented on your referral post for Data Engineer at Amazon.', TRUE, '2025-02-03 12:15:00+00'),
    ('55555555-5555-4555-8555-555555555504', '11111111-1111-4111-8111-111111111104', 'COMMENT', 'Diya Nair commented on your referral post for Project Manager at Infosys.', FALSE, '2025-02-04 09:20:00+00'),
    ('55555555-5555-4555-8555-555555555505', '11111111-1111-4111-8111-111111111105', 'COMMENT', 'Isabella Costa commented on your referral post for Technical Architect at TCS.', TRUE, '2025-02-05 11:05:00+00'),
    ('55555555-5555-4555-8555-555555555506', '11111111-1111-4111-8111-111111111106', 'COMMENT', 'Emily Johnson commented on your referral post for DevOps Engineer at Accenture.', FALSE, '2025-02-06 13:35:00+00'),

    -- ---------------------------------------------------------------------
    -- LIKE notifications
    -- ---------------------------------------------------------------------
    ('55555555-5555-4555-8555-555555555507', '11111111-1111-4111-8111-111111111107', 'LIKE', 'Haruto Tanaka liked your referral post for AI Engineer at Adobe.', TRUE, '2025-02-07 11:50:00+00'),
    ('55555555-5555-4555-8555-555555555508', '11111111-1111-4111-8111-111111111108', 'LIKE', 'Diya Nair liked your referral post for Cyber Security Engineer at Oracle.', FALSE, '2025-02-08 15:30:00+00'),
    ('55555555-5555-4555-8555-555555555509', '11111111-1111-4111-8111-111111111109', 'LIKE', 'Isabella Costa liked your referral post for Software Engineer at Salesforce.', TRUE, '2025-02-09 10:00:00+00'),
    ('55555555-5555-4555-8555-555555555510', '11111111-1111-4111-8111-111111111110', 'LIKE', 'Aarav Sharma liked your referral post for Cloud Engineer at ServiceNow.', FALSE, '2025-02-10 12:40:00+00'),
    ('55555555-5555-4555-8555-555555555511', '11111111-1111-4111-8111-111111111101', 'LIKE', 'Priya Patel liked your referral post for Data Engineer at Databricks.', TRUE, '2025-02-11 09:10:00+00'),
    ('55555555-5555-4555-8555-555555555512', '11111111-1111-4111-8111-111111111102', 'LIKE', 'Vivaan Reddy liked your referral post for Cloud Engineer at Snowflake.', FALSE, '2025-02-12 10:35:00+00'),

    -- ---------------------------------------------------------------------
    -- REFERRAL_REQUEST notifications
    -- ---------------------------------------------------------------------
    ('55555555-5555-4555-8555-555555555513', '11111111-1111-4111-8111-111111111101', 'REFERRAL_REQUEST', 'Emily Johnson has requested a referral for the Software Engineer role at Google.', FALSE, '2025-02-01 12:31:00+00'),
    ('55555555-5555-4555-8555-555555555514', '11111111-1111-4111-8111-111111111102', 'REFERRAL_REQUEST', 'Priya Patel has requested a referral for the Cloud Engineer role at Microsoft.', TRUE, '2025-02-02 14:11:00+00'),
    ('55555555-5555-4555-8555-555555555515', '11111111-1111-4111-8111-111111111103', 'REFERRAL_REQUEST', 'Oliver Smith has requested a referral for the Data Engineer role at Amazon.', FALSE, '2025-02-03 15:46:00+00'),
    ('55555555-5555-4555-8555-555555555516', '11111111-1111-4111-8111-111111111104', 'REFERRAL_REQUEST', 'Vivaan Reddy has requested a referral for the Project Manager role at Infosys.', TRUE, '2025-02-04 09:21:00+00'),
    ('55555555-5555-4555-8555-555555555517', '11111111-1111-4111-8111-111111111105', 'REFERRAL_REQUEST', 'Lukas Mueller has requested a referral for the Technical Architect role at TCS.', FALSE, '2025-02-05 10:51:00+00'),
    ('55555555-5555-4555-8555-555555555518', '11111111-1111-4111-8111-111111111106', 'REFERRAL_REQUEST', 'Ananya Iyer has requested a referral for the DevOps Engineer role at Accenture.', TRUE, '2025-02-06 13:36:00+00'),
    ('55555555-5555-4555-8555-555555555519', '11111111-1111-4111-8111-111111111107', 'REFERRAL_REQUEST', 'Haruto Tanaka has requested a referral for the AI Engineer role at Adobe.', FALSE, '2025-02-07 11:16:00+00'),
    ('55555555-5555-4555-8555-555555555520', '11111111-1111-4111-8111-111111111108', 'REFERRAL_REQUEST', 'Diya Nair has requested a referral for the Cyber Security Engineer role at Oracle.', TRUE, '2025-02-08 15:01:00+00'),

    -- ---------------------------------------------------------------------
    -- REFERRAL_ACCEPTED notifications
    -- ---------------------------------------------------------------------
    ('55555555-5555-4555-8555-555555555521', '11111111-1111-4111-8111-111111111103', 'REFERRAL_ACCEPTED', 'Your referral request for the Cloud Engineer role at Microsoft has been accepted by Emily Johnson.', FALSE, '2025-02-02 14:20:00+00'),
    ('55555555-5555-4555-8555-555555555522', '11111111-1111-4111-8111-111111111107', 'REFERRAL_ACCEPTED', 'Your referral request for the DevOps Engineer role at Accenture has been accepted by Lukas Mueller.', TRUE, '2025-02-06 13:40:00+00'),
    ('55555555-5555-4555-8555-555555555523', '11111111-1111-4111-8111-111111111110', 'REFERRAL_ACCEPTED', 'Your referral request for the Cloud Engineer role at Adobe has been accepted by Diya Nair.', FALSE, '2025-02-19 10:15:00+00'),
    ('55555555-5555-4555-8555-555555555524', '11111111-1111-4111-8111-111111111102', 'REFERRAL_ACCEPTED', 'Your referral request for the Technical Architect role at Salesforce has been accepted by Aarav Sharma.', TRUE, '2025-02-21 09:20:00+00'),
    ('55555555-5555-4555-8555-555555555525', '11111111-1111-4111-8111-111111111106', 'REFERRAL_ACCEPTED', 'Your referral request for the Cyber Security Engineer role at Google has been accepted by Vivaan Reddy.', FALSE, '2025-02-25 12:15:00+00'),

    -- ---------------------------------------------------------------------
    -- SYSTEM notifications
    -- ---------------------------------------------------------------------
    ('55555555-5555-4555-8555-555555555526', '11111111-1111-4111-8111-111111111101', 'SYSTEM', 'Welcome to MyReferral! Complete your profile to start posting and requesting referrals.', TRUE, '2025-01-05 09:20:00+00'),
    ('55555555-5555-4555-8555-555555555527', '11111111-1111-4111-8111-111111111104', 'SYSTEM', 'Your account status has been changed to inactive. Contact support if this is unexpected.', FALSE, '2025-01-20 09:05:00+00'),
    ('55555555-5555-4555-8555-555555555528', '11111111-1111-4111-8111-111111111109', 'SYSTEM', 'Your account is pending verification. Please confirm your email address to unlock full access.', FALSE, '2025-01-25 14:15:00+00'),
    ('55555555-5555-4555-8555-555555555529', '11111111-1111-4111-8111-111111111108', 'SYSTEM', 'Scheduled maintenance completed successfully. All referral services are back online.', TRUE, '2025-02-15 06:00:00+00'),
    ('55555555-5555-4555-8555-555555555530', '11111111-1111-4111-8111-111111111105', 'SYSTEM', 'New feature: You can now track referral request status directly from your dashboard.', FALSE, '2025-03-01 08:00:00+00')
ON CONFLICT (id) DO NOTHING;
-- =============================================================================
-- Section:          Post-Seed Validation
-- Description:      Read-only verification queries to validate the seed data
--                    inserted by this migration. Intended for manual review
--                    or CI smoke-testing in non-production environments only.
--                    These queries perform NO writes and are safe to run
--                    repeatedly.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Row Count: public.users
-- -----------------------------------------------------------------------------
SELECT
    'users' AS table_name,
    COUNT(*) AS row_count
FROM public.users;

-- -----------------------------------------------------------------------------
-- 2. Row Count: public.referral_posts
-- -----------------------------------------------------------------------------
SELECT
    'referral_posts' AS table_name,
    COUNT(*) AS row_count
FROM public.referral_posts;

-- -----------------------------------------------------------------------------
-- 3. Row Count: public.comments
-- -----------------------------------------------------------------------------
SELECT
    'comments' AS table_name,
    COUNT(*) AS row_count
FROM public.comments;

-- -----------------------------------------------------------------------------
-- 4. Row Count: public.likes
-- -----------------------------------------------------------------------------
SELECT
    'likes' AS table_name,
    COUNT(*) AS row_count
FROM public.likes;

-- -----------------------------------------------------------------------------
-- 5. Row Count: public.referral_requests
-- -----------------------------------------------------------------------------
SELECT
    'referral_requests' AS table_name,
    COUNT(*) AS row_count
FROM public.referral_requests;

-- -----------------------------------------------------------------------------
-- 6. Row Count: public.notifications
-- -----------------------------------------------------------------------------
SELECT
    'notifications' AS table_name,
    COUNT(*) AS row_count
FROM public.notifications;

-- -----------------------------------------------------------------------------
-- 7a. Referential Integrity Check: referral_posts.user_id -> users.id
--     Expect ZERO orphaned rows.
-- -----------------------------------------------------------------------------
SELECT
    'referral_posts.user_id -> users.id' AS relationship,
    COUNT(*) AS orphaned_rows
FROM public.referral_posts rp
LEFT JOIN public.users u ON u.id = rp.user_id
WHERE u.id IS NULL;

-- -----------------------------------------------------------------------------
-- 7b. Referential Integrity Check: comments.post_id -> referral_posts.id
--     Expect ZERO orphaned rows.
-- -----------------------------------------------------------------------------
SELECT
    'comments.post_id -> referral_posts.id' AS relationship,
    COUNT(*) AS orphaned_rows
FROM public.comments c
LEFT JOIN public.referral_posts rp ON rp.id = c.post_id
WHERE rp.id IS NULL;

-- -----------------------------------------------------------------------------
-- 7c. Referential Integrity Check: comments.user_id -> users.id
--     Expect ZERO orphaned rows.
-- -----------------------------------------------------------------------------
SELECT
    'comments.user_id -> users.id' AS relationship,
    COUNT(*) AS orphaned_rows
FROM public.comments c
LEFT JOIN public.users u ON u.id = c.user_id
WHERE u.id IS NULL;

-- -----------------------------------------------------------------------------
-- 7d. Referential Integrity Check: likes.post_id -> referral_posts.id
--     Expect ZERO orphaned rows.
-- -----------------------------------------------------------------------------
SELECT
    'likes.post_id -> referral_posts.id' AS relationship,
    COUNT(*) AS orphaned_rows
FROM public.likes l
LEFT JOIN public.referral_posts rp ON rp.id = l.post_id
WHERE rp.id IS NULL;

-- -----------------------------------------------------------------------------
-- 7e. Referential Integrity Check: likes.user_id -> users.id
--     Expect ZERO orphaned rows.
-- -----------------------------------------------------------------------------
SELECT
    'likes.user_id -> users.id' AS relationship,
    COUNT(*) AS orphaned_rows
FROM public.likes l
LEFT JOIN public.users u ON u.id = l.user_id
WHERE u.id IS NULL;

-- -----------------------------------------------------------------------------
-- 7f. Referential Integrity Check: likes uniqueness (post_id, user_id)
--     Expect ZERO duplicate combinations.
-- -----------------------------------------------------------------------------
SELECT
    'likes duplicate (post_id, user_id)' AS relationship,
    COUNT(*) AS duplicate_combinations
FROM (
    SELECT post_id, user_id
    FROM public.likes
    GROUP BY post_id, user_id
    HAVING COUNT(*) > 1
) dup;

-- -----------------------------------------------------------------------------
-- 7g. Referential Integrity Check: referral_requests.post_id -> referral_posts.id
--     Expect ZERO orphaned rows.
-- -----------------------------------------------------------------------------
SELECT
    'referral_requests.post_id -> referral_posts.id' AS relationship,
    COUNT(*) AS orphaned_rows
FROM public.referral_requests rr
LEFT JOIN public.referral_posts rp ON rp.id = rr.post_id
WHERE rp.id IS NULL;

-- -----------------------------------------------------------------------------
-- 7h. Referential Integrity Check: referral_requests.requester_id -> users.id
--     Expect ZERO orphaned rows.
-- -----------------------------------------------------------------------------
SELECT
    'referral_requests.requester_id -> users.id' AS relationship,
    COUNT(*) AS orphaned_rows
FROM public.referral_requests rr
LEFT JOIN public.users u ON u.id = rr.requester_id
WHERE u.id IS NULL;

-- -----------------------------------------------------------------------------
-- 7i. Referential Integrity Check: referral_requests.employee_id -> users.id
--     Expect ZERO orphaned rows.
-- -----------------------------------------------------------------------------
SELECT
    'referral_requests.employee_id -> users.id' AS relationship,
    COUNT(*) AS orphaned_rows
FROM public.referral_requests rr
LEFT JOIN public.users u ON u.id = rr.employee_id
WHERE u.id IS NULL;

-- -----------------------------------------------------------------------------
-- 7j. Referential Integrity Check: notifications.user_id -> users.id
--     Expect ZERO orphaned rows.
-- -----------------------------------------------------------------------------
SELECT
    'notifications.user_id -> users.id' AS relationship,
    COUNT(*) AS orphaned_rows
FROM public.notifications n
LEFT JOIN public.users u ON u.id = n.user_id
WHERE u.id IS NULL;

-- -----------------------------------------------------------------------------
-- 7k. Data Integrity Check: users.email uniqueness
--     Expect ZERO duplicate email addresses.
-- -----------------------------------------------------------------------------
SELECT
    'users duplicate email' AS relationship,
    COUNT(*) AS duplicate_emails
FROM (
    SELECT email
    FROM public.users
    GROUP BY email
    HAVING COUNT(*) > 1
) dup;

-- -----------------------------------------------------------------------------
-- 8a. Sample Data: public.users (5 rows)
-- -----------------------------------------------------------------------------
SELECT id, name, email, role, status, created_at
FROM public.users
ORDER BY created_at
LIMIT 5;

-- -----------------------------------------------------------------------------
-- 8b. Sample Data: public.referral_posts (5 rows)
-- -----------------------------------------------------------------------------
SELECT id, company_name, role_title, location, country, work_mode, status, created_at
FROM public.referral_posts
ORDER BY created_at
LIMIT 5;

-- -----------------------------------------------------------------------------
-- 8c. Sample Data: public.comments (5 rows)
-- -----------------------------------------------------------------------------
SELECT id, post_id, user_id, comment_text, created_at
FROM public.comments
ORDER BY created_at
LIMIT 5;

-- -----------------------------------------------------------------------------
-- 8d. Sample Data: public.likes (5 rows)
-- -----------------------------------------------------------------------------
SELECT id, post_id, user_id, created_at
FROM public.likes
ORDER BY created_at
LIMIT 5;

-- -----------------------------------------------------------------------------
-- 8e. Sample Data: public.referral_requests (5 rows)
-- -----------------------------------------------------------------------------
SELECT id, post_id, requester_id, employee_id, status, created_at
FROM public.referral_requests
ORDER BY created_at
LIMIT 5;

-- -----------------------------------------------------------------------------
-- 8f. Sample Data: public.notifications (5 rows)
-- -----------------------------------------------------------------------------
SELECT id, user_id, type, message, is_read, created_at
FROM public.notifications
ORDER BY created_at
LIMIT 5;

-- =============================================================================
-- End of Validation Section
-- Reminder: This entire migration (V1.0.9__seed_data.sql) is NOT intended
-- for production environments. Validation queries above are read-only and
-- intended for development/demo environment sanity checks only.
-- =============================================================================



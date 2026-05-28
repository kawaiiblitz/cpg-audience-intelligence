-- Setup: schema + volume en catalog existente para CPG Audience Intelligence
-- Workspace: fevm-serverless-stable-rtpa
-- Catalog: serverless_stable_rtpa_catalog (existente)

CREATE SCHEMA IF NOT EXISTS serverless_stable_rtpa_catalog.gepp_audience_intelligence
COMMENT 'CPG Audience Intelligence · CPG bebidas MX · población sintética + agentes';

CREATE VOLUME IF NOT EXISTS serverless_stable_rtpa_catalog.gepp_audience_intelligence.raw
COMMENT 'Landing zone para parquet de población sintética CPG';

-- Grants para que el service principal de la app gepp-audience-intelligence pueda leer y ejecutar.
-- Service principal: 44ec4c7f-bb5d-481e-ab01-e2be13a3bf6a (app-5l8ykf gepp-audience-intelligence)

GRANT USE CATALOG ON CATALOG serverless_stable_rtpa_catalog TO `44ec4c7f-bb5d-481e-ab01-e2be13a3bf6a`;
GRANT USE SCHEMA ON SCHEMA serverless_stable_rtpa_catalog.gepp_audience_intelligence TO `44ec4c7f-bb5d-481e-ab01-e2be13a3bf6a`;
GRANT SELECT ON TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes TO `44ec4c7f-bb5d-481e-ab01-e2be13a3bf6a`;
GRANT SELECT ON VIEW serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_baseline_rates TO `44ec4c7f-bb5d-481e-ab01-e2be13a3bf6a`;
GRANT READ VOLUME ON VOLUME serverless_stable_rtpa_catalog.gepp_audience_intelligence.raw TO `44ec4c7f-bb5d-481e-ab01-e2be13a3bf6a`;
GRANT EXECUTE ON FUNCTION serverless_stable_rtpa_catalog.gepp_audience_intelligence.audience_size TO `44ec4c7f-bb5d-481e-ab01-e2be13a3bf6a`;
GRANT EXECUTE ON FUNCTION serverless_stable_rtpa_catalog.gepp_audience_intelligence.find_top_affinities TO `44ec4c7f-bb5d-481e-ab01-e2be13a3bf6a`;
GRANT EXECUTE ON FUNCTION serverless_stable_rtpa_catalog.gepp_audience_intelligence.recommend_channel TO `44ec4c7f-bb5d-481e-ab01-e2be13a3bf6a`;
GRANT EXECUTE ON FUNCTION serverless_stable_rtpa_catalog.gepp_audience_intelligence.compare_segments TO `44ec4c7f-bb5d-481e-ab01-e2be13a3bf6a`;
GRANT EXECUTE ON FUNCTION serverless_stable_rtpa_catalog.gepp_audience_intelligence.preview_audience_sample TO `44ec4c7f-bb5d-481e-ab01-e2be13a3bf6a`;

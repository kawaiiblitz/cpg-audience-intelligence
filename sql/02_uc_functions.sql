-- ====================================================================
-- audience_size
-- ====================================================================
CREATE OR REPLACE FUNCTION serverless_stable_rtpa_catalog.gepp_audience_intelligence.audience_size(
  regions ARRAY<STRING> DEFAULT NULL COMMENT 'Región: METRO, BAJIO, CENTRO, PACIFICO, NORTE',
  territorios ARRAY<STRING> DEFAULT NULL COMMENT 'Territorio (ej. León, Monterrey, CDMX Norte)',
  cedis_list ARRAY<STRING> DEFAULT NULL COMMENT 'CEDIS específicos (ej. CEDIS Apodaca)',
  sales_channels ARRAY<STRING> DEFAULT NULL COMMENT 'Canal: Moderno, Tradicional, Hogar, On Premise, Cuentas Clave',
  pdv_strategies ARRAY<STRING> DEFAULT NULL COMMENT 'Estrategia: Blindar, Impulsar, Desarrollar, Conservar',
  nse_levels ARRAY<STRING> DEFAULT NULL COMMENT 'NSE: A/B, C+, C, C-, D+, D, E',
  lifecycle_stages ARRAY<STRING> DEFAULT NULL COMMENT 'Heavy fan, Loyalty active, Engaged digital, Regular buyer, Light buyer, Lapsado, No engaged',
  personas ARRAY<STRING> DEFAULT NULL COMMENT 'Joven Energético, Health Switcher, Wellness Maduro, Familia Refresquera, Deportista Activo, Pepsi Heavy Loyalist, Cola Heavy User, Maduro Tradicional, Mainstream Bebida',
  cola_tiers ARRAY<STRING> DEFAULT NULL COMMENT 'Heavy, Medium, Light, Non-buyer',
  pepsi_preferences ARRAY<STRING> DEFAULT NULL COMMENT 'Loyalist Pepsi, Loyalist Coca, Pepsi-leaning switcher, Coca-leaning switcher, No cola',
  formats ARRAY<STRING> DEFAULT NULL COMMENT 'Formato preferido: 355ml lata, 600ml PET, 1L PET, 2L PET, 3L PET, 235ml mini lata, 500ml vidrio retornable, 355ml vidrio nostalgia',
  age_min INT DEFAULT NULL,
  age_max INT DEFAULT NULL,
  buys_pepsi_filter BOOLEAN DEFAULT NULL,
  buys_coca_filter BOOLEAN DEFAULT NULL,
  buys_gatorade_filter BOOLEAN DEFAULT NULL,
  buys_epura_filter BOOLEAN DEFAULT NULL,
  buys_energetico_filter BOOLEAN DEFAULT NULL,
  buys_2L_filter BOOLEAN DEFAULT NULL COMMENT 'TRUE/FALSE compra PET 2L',
  buys_600ml_filter BOOLEAN DEFAULT NULL,
  health_conscious_filter BOOLEAN DEFAULT NULL,
  family_buyer_filter BOOLEAN DEFAULT NULL,
  sport_drink_user_filter BOOLEAN DEFAULT NULL,
  is_pepsi_lapsed_filter BOOLEAN DEFAULT NULL,
  is_pepsi_heavy_filter BOOLEAN DEFAULT NULL,
  has_gepp_app_filter BOOLEAN DEFAULT NULL,
  loyalty_member_filter BOOLEAN DEFAULT NULL,
  promo_responsive_filter BOOLEAN DEFAULT NULL,
  weekly_units_min INT DEFAULT NULL
)
RETURNS STRUCT<segment_count: BIGINT, total_population: BIGINT, pct_of_population: DOUBLE>
DETERMINISTIC
READS SQL DATA
COMMENT 'Tamaño de audiencia de consumidores CPG. Filtra por región, territorio, canal de venta, estrategia comercial, portafolio Pepsi, formato, etc.'
RETURN ((
  SELECT STRUCT(
    COUNT(*) AS segment_count,
    (SELECT COUNT(*) FROM serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes) AS total_population,
    COUNT(*) * 1.0 / (SELECT COUNT(*) FROM serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes) AS pct_of_population
  )
  FROM serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes
  WHERE (regions IS NULL OR array_contains(regions, region))
    AND (territorios IS NULL OR array_contains(territorios, territorio))
    AND (cedis_list IS NULL OR array_contains(cedis_list, cedis))
    AND (sales_channels IS NULL OR array_contains(sales_channels, sales_channel))
    AND (pdv_strategies IS NULL OR array_contains(pdv_strategies, pdv_strategy))
    AND (nse_levels IS NULL OR array_contains(nse_levels, nse))
    AND (lifecycle_stages IS NULL OR array_contains(lifecycle_stages, lifecycle_stage))
    AND (personas IS NULL OR array_contains(personas, persona_tag))
    AND (cola_tiers IS NULL OR array_contains(cola_tiers, cola_buyer_tier))
    AND (pepsi_preferences IS NULL OR array_contains(pepsi_preferences, pepsi_preference))
    AND (formats IS NULL OR array_contains(formats, preferred_format))
    AND (age_min IS NULL OR age >= age_min)
    AND (age_max IS NULL OR age <= age_max)
    AND (buys_pepsi_filter IS NULL OR buys_pepsi = buys_pepsi_filter)
    AND (buys_coca_filter IS NULL OR buys_coca = buys_coca_filter)
    AND (buys_gatorade_filter IS NULL OR buys_gatorade = buys_gatorade_filter)
    AND (buys_epura_filter IS NULL OR buys_epura = buys_epura_filter)
    AND (buys_energetico_filter IS NULL OR buys_energetico = buys_energetico_filter)
    AND (buys_2L_filter IS NULL OR buys_2L = buys_2L_filter)
    AND (buys_600ml_filter IS NULL OR buys_600ml = buys_600ml_filter)
    AND (health_conscious_filter IS NULL OR health_conscious = health_conscious_filter)
    AND (family_buyer_filter IS NULL OR family_buyer = family_buyer_filter)
    AND (sport_drink_user_filter IS NULL OR sport_drink_user = sport_drink_user_filter)
    AND (is_pepsi_lapsed_filter IS NULL OR is_pepsi_lapsed = is_pepsi_lapsed_filter)
    AND (is_pepsi_heavy_filter IS NULL OR is_pepsi_heavy = is_pepsi_heavy_filter)
    AND (has_gepp_app_filter IS NULL OR has_gepp_app = has_gepp_app_filter)
    AND (loyalty_member_filter IS NULL OR loyalty_member = loyalty_member_filter)
    AND (promo_responsive_filter IS NULL OR promo_responsive = promo_responsive_filter)
    AND (weekly_units_min IS NULL OR weekly_beverage_units >= weekly_units_min)
));

-- ====================================================================
-- find_top_affinities
-- ====================================================================
CREATE OR REPLACE FUNCTION serverless_stable_rtpa_catalog.gepp_audience_intelligence.find_top_affinities(
  regions ARRAY<STRING> DEFAULT NULL,
  territorios ARRAY<STRING> DEFAULT NULL,
  cedis_list ARRAY<STRING> DEFAULT NULL,
  sales_channels ARRAY<STRING> DEFAULT NULL,
  pdv_strategies ARRAY<STRING> DEFAULT NULL,
  nse_levels ARRAY<STRING> DEFAULT NULL,
  lifecycle_stages ARRAY<STRING> DEFAULT NULL,
  personas ARRAY<STRING> DEFAULT NULL,
  cola_tiers ARRAY<STRING> DEFAULT NULL,
  pepsi_preferences ARRAY<STRING> DEFAULT NULL,
  formats ARRAY<STRING> DEFAULT NULL,
  age_min INT DEFAULT NULL,
  age_max INT DEFAULT NULL,
  buys_pepsi_filter BOOLEAN DEFAULT NULL,
  buys_coca_filter BOOLEAN DEFAULT NULL,
  buys_gatorade_filter BOOLEAN DEFAULT NULL,
  buys_epura_filter BOOLEAN DEFAULT NULL,
  buys_energetico_filter BOOLEAN DEFAULT NULL,
  buys_2L_filter BOOLEAN DEFAULT NULL,
  buys_600ml_filter BOOLEAN DEFAULT NULL,
  health_conscious_filter BOOLEAN DEFAULT NULL,
  family_buyer_filter BOOLEAN DEFAULT NULL,
  sport_drink_user_filter BOOLEAN DEFAULT NULL,
  is_pepsi_lapsed_filter BOOLEAN DEFAULT NULL,
  is_pepsi_heavy_filter BOOLEAN DEFAULT NULL,
  has_gepp_app_filter BOOLEAN DEFAULT NULL,
  loyalty_member_filter BOOLEAN DEFAULT NULL,
  promo_responsive_filter BOOLEAN DEFAULT NULL,
  weekly_units_min INT DEFAULT NULL,
  min_lift DOUBLE DEFAULT 1.2,
  min_support BIGINT DEFAULT 500
)
RETURNS TABLE(
    attribute_name STRING,
    segment_rate DOUBLE,
    baseline_rate DOUBLE,
    lift DOUBLE,
    segment_size BIGINT,
    interpretation STRING
  )
DETERMINISTIC
READS SQL DATA
COMMENT 'Atributos donde el segmento sobre-indexa vs baseline. Lift = segment_rate / baseline_rate.'
RETURN (
  WITH segment AS (
    SELECT *
    FROM serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes
    WHERE (regions IS NULL OR array_contains(regions, region))
      AND (territorios IS NULL OR array_contains(territorios, territorio))
      AND (cedis_list IS NULL OR array_contains(cedis_list, cedis))
      AND (sales_channels IS NULL OR array_contains(sales_channels, sales_channel))
      AND (pdv_strategies IS NULL OR array_contains(pdv_strategies, pdv_strategy))
      AND (nse_levels IS NULL OR array_contains(nse_levels, nse))
      AND (lifecycle_stages IS NULL OR array_contains(lifecycle_stages, lifecycle_stage))
      AND (personas IS NULL OR array_contains(personas, persona_tag))
      AND (cola_tiers IS NULL OR array_contains(cola_tiers, cola_buyer_tier))
      AND (pepsi_preferences IS NULL OR array_contains(pepsi_preferences, pepsi_preference))
      AND (formats IS NULL OR array_contains(formats, preferred_format))
      AND (age_min IS NULL OR age >= age_min)
      AND (age_max IS NULL OR age <= age_max)
      AND (buys_pepsi_filter IS NULL OR buys_pepsi = buys_pepsi_filter)
      AND (buys_coca_filter IS NULL OR buys_coca = buys_coca_filter)
      AND (buys_gatorade_filter IS NULL OR buys_gatorade = buys_gatorade_filter)
      AND (buys_epura_filter IS NULL OR buys_epura = buys_epura_filter)
      AND (buys_energetico_filter IS NULL OR buys_energetico = buys_energetico_filter)
      AND (buys_2L_filter IS NULL OR buys_2L = buys_2L_filter)
      AND (buys_600ml_filter IS NULL OR buys_600ml = buys_600ml_filter)
      AND (health_conscious_filter IS NULL OR health_conscious = health_conscious_filter)
      AND (family_buyer_filter IS NULL OR family_buyer = family_buyer_filter)
      AND (sport_drink_user_filter IS NULL OR sport_drink_user = sport_drink_user_filter)
      AND (is_pepsi_lapsed_filter IS NULL OR is_pepsi_lapsed = is_pepsi_lapsed_filter)
      AND (is_pepsi_heavy_filter IS NULL OR is_pepsi_heavy = is_pepsi_heavy_filter)
      AND (has_gepp_app_filter IS NULL OR has_gepp_app = has_gepp_app_filter)
      AND (loyalty_member_filter IS NULL OR loyalty_member = loyalty_member_filter)
      AND (promo_responsive_filter IS NULL OR promo_responsive = promo_responsive_filter)
      AND (weekly_units_min IS NULL OR weekly_beverage_units >= weekly_units_min)
  ),
  segment_size_cte AS (SELECT COUNT(*) AS n FROM segment),
  baseline AS (SELECT * FROM serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_baseline_rates),
  segment_rates AS (
    SELECT
      AVG(CAST(buys_pepsi AS DOUBLE)) AS r_pepsi,
      AVG(CAST(buys_pepsi_light AS DOUBLE)) AS r_pepsi_light,
      AVG(CAST(buys_pepsi_black AS DOUBLE)) AS r_pepsi_black,
      AVG(CAST(buys_mirinda AS DOUBLE)) AS r_mirinda,
      AVG(CAST(buys_7up AS DOUBLE)) AS r_7up,
      AVG(CAST(buys_manzanita AS DOUBLE)) AS r_manzanita,
      AVG(CAST(buys_gatorade AS DOUBLE)) AS r_gatorade,
      AVG(CAST(buys_aha AS DOUBLE)) AS r_aha,
      AVG(CAST(buys_epura AS DOUBLE)) AS r_epura,
      AVG(CAST(buys_coca AS DOUBLE)) AS r_coca,
      AVG(CAST(buys_coca_zero AS DOUBLE)) AS r_coca_zero,
      AVG(CAST(buys_sprite AS DOUBLE)) AS r_sprite,
      AVG(CAST(buys_powerade AS DOUBLE)) AS r_powerade,
      AVG(CAST(buys_ciel AS DOUBLE)) AS r_ciel,
      AVG(CAST(buys_jugos AS DOUBLE)) AS r_jugos,
      AVG(CAST(buys_te AS DOUBLE)) AS r_te,
      AVG(CAST(buys_energetico AS DOUBLE)) AS r_energetico,
      AVG(CAST(health_conscious AS DOUBLE)) AS r_health,
      AVG(CAST(family_buyer AS DOUBLE)) AS r_family,
      AVG(CAST(sport_drink_user AS DOUBLE)) AS r_sport,
      AVG(CAST(energy_drink_user AS DOUBLE)) AS r_energy_drink,
      AVG(CAST(has_gepp_app AS DOUBLE)) AS r_app,
      AVG(CAST(loyalty_member AS DOUBLE)) AS r_loyalty,
      AVG(CAST(price_sensitive AS DOUBLE)) AS r_price,
      AVG(CAST(brand_loyal AS DOUBLE)) AS r_brand_loyal,
      AVG(CAST(promo_responsive AS DOUBLE)) AS r_promo,
      AVG(CAST(buys_355ml_lata AS DOUBLE)) AS r_355ml,
      AVG(CAST(buys_600ml AS DOUBLE)) AS r_600ml,
      AVG(CAST(buys_1L AS DOUBLE)) AS r_1L,
      AVG(CAST(buys_2L AS DOUBLE)) AS r_2L,
      AVG(CAST(buys_3L AS DOUBLE)) AS r_3L,
      AVG(CAST(consumes_party AS DOUBLE)) AS r_party,
      AVG(CAST(consumes_workout AS DOUBLE)) AS r_workout,
      AVG(CAST(weekend_heavy AS DOUBLE)) AS r_weekend,
      AVG(CAST(pairs_with_snacks AS DOUBLE)) AS r_snacks
    FROM segment
  ),
  unioned AS (
    SELECT 'buys_pepsi' AS attr, s.r_pepsi AS sr, b.rate_pepsi AS br FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_pepsi_light', s.r_pepsi_light, b.rate_pepsi_light FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_pepsi_black', s.r_pepsi_black, b.rate_pepsi_black FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_mirinda', s.r_mirinda, b.rate_mirinda FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_7up', s.r_7up, b.rate_7up FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_manzanita', s.r_manzanita, b.rate_manzanita FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_gatorade', s.r_gatorade, b.rate_gatorade FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_aha', s.r_aha, b.rate_aha FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_epura', s.r_epura, b.rate_epura FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_coca', s.r_coca, b.rate_coca FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_coca_zero', s.r_coca_zero, b.rate_coca_zero FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_sprite', s.r_sprite, b.rate_sprite FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_powerade', s.r_powerade, b.rate_powerade FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_ciel', s.r_ciel, b.rate_ciel FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_jugos', s.r_jugos, b.rate_jugos FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_te', s.r_te, b.rate_te FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_energetico', s.r_energetico, b.rate_energetico FROM segment_rates s, baseline b
    UNION ALL SELECT 'health_conscious', s.r_health, b.rate_health_conscious FROM segment_rates s, baseline b
    UNION ALL SELECT 'family_buyer', s.r_family, b.rate_family_buyer FROM segment_rates s, baseline b
    UNION ALL SELECT 'sport_drink_user', s.r_sport, b.rate_sport_drink FROM segment_rates s, baseline b
    UNION ALL SELECT 'energy_drink_user', s.r_energy_drink, b.rate_energy_drink FROM segment_rates s, baseline b
    UNION ALL SELECT 'has_gepp_app', s.r_app, b.rate_gepp_app FROM segment_rates s, baseline b
    UNION ALL SELECT 'loyalty_member', s.r_loyalty, b.rate_loyalty FROM segment_rates s, baseline b
    UNION ALL SELECT 'price_sensitive', s.r_price, b.rate_price_sensitive FROM segment_rates s, baseline b
    UNION ALL SELECT 'brand_loyal', s.r_brand_loyal, b.rate_brand_loyal FROM segment_rates s, baseline b
    UNION ALL SELECT 'promo_responsive', s.r_promo, b.rate_promo_responsive FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_355ml_lata', s.r_355ml, b.rate_355ml_lata FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_600ml', s.r_600ml, b.rate_600ml FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_1L', s.r_1L, b.rate_1L FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_2L', s.r_2L, b.rate_2L FROM segment_rates s, baseline b
    UNION ALL SELECT 'buys_3L', s.r_3L, b.rate_3L FROM segment_rates s, baseline b
    UNION ALL SELECT 'consumes_party', s.r_party, b.rate_consumes_party FROM segment_rates s, baseline b
    UNION ALL SELECT 'consumes_workout', s.r_workout, b.rate_consumes_workout FROM segment_rates s, baseline b
    UNION ALL SELECT 'weekend_heavy', s.r_weekend, b.rate_weekend_heavy FROM segment_rates s, baseline b
    UNION ALL SELECT 'pairs_with_snacks', s.r_snacks, b.rate_pairs_snacks FROM segment_rates s, baseline b
  )
  SELECT
    attr AS attribute_name,
    ROUND(sr, 4) AS segment_rate,
    ROUND(br, 4) AS baseline_rate,
    ROUND(sr / NULLIF(br, 0), 2) AS lift,
    (SELECT n FROM segment_size_cte) AS segment_size,
    CASE
      WHEN sr / NULLIF(br, 0) >= 2 THEN CONCAT('Sobre-indexa fuerte: ', CAST(ROUND((sr/br - 1) * 100, 0) AS STRING), '% más que población general')
      WHEN sr / NULLIF(br, 0) >= 1.3 THEN CONCAT('Sobre-indexa: ', CAST(ROUND((sr/br - 1) * 100, 0) AS STRING), '% más que población general')
      WHEN sr / NULLIF(br, 0) >= 1.1 THEN CONCAT('Ligeramente sobre-indexado: +', CAST(ROUND((sr/br - 1) * 100, 0) AS STRING), '%')
      WHEN sr / NULLIF(br, 0) <= 0.7 THEN CONCAT('Sub-indexa: ', CAST(ROUND((1 - sr/br) * 100, 0) AS STRING), '% menos que población general')
      ELSE 'En línea con baseline'
    END AS interpretation
  FROM unioned
  WHERE br > 0
    AND sr / br >= min_lift
    AND (SELECT n FROM segment_size_cte) >= min_support
  ORDER BY lift DESC
);

-- ====================================================================
-- recommend_channel
-- ====================================================================
CREATE OR REPLACE FUNCTION serverless_stable_rtpa_catalog.gepp_audience_intelligence.recommend_channel(
  regions ARRAY<STRING> DEFAULT NULL,
  territorios ARRAY<STRING> DEFAULT NULL,
  cedis_list ARRAY<STRING> DEFAULT NULL,
  sales_channels ARRAY<STRING> DEFAULT NULL,
  pdv_strategies ARRAY<STRING> DEFAULT NULL,
  nse_levels ARRAY<STRING> DEFAULT NULL,
  lifecycle_stages ARRAY<STRING> DEFAULT NULL,
  personas ARRAY<STRING> DEFAULT NULL,
  cola_tiers ARRAY<STRING> DEFAULT NULL,
  pepsi_preferences ARRAY<STRING> DEFAULT NULL,
  formats ARRAY<STRING> DEFAULT NULL,
  age_min INT DEFAULT NULL,
  age_max INT DEFAULT NULL,
  buys_pepsi_filter BOOLEAN DEFAULT NULL,
  buys_coca_filter BOOLEAN DEFAULT NULL,
  buys_gatorade_filter BOOLEAN DEFAULT NULL,
  buys_epura_filter BOOLEAN DEFAULT NULL,
  buys_energetico_filter BOOLEAN DEFAULT NULL,
  buys_2L_filter BOOLEAN DEFAULT NULL,
  buys_600ml_filter BOOLEAN DEFAULT NULL,
  health_conscious_filter BOOLEAN DEFAULT NULL,
  family_buyer_filter BOOLEAN DEFAULT NULL,
  sport_drink_user_filter BOOLEAN DEFAULT NULL,
  is_pepsi_lapsed_filter BOOLEAN DEFAULT NULL,
  is_pepsi_heavy_filter BOOLEAN DEFAULT NULL,
  has_gepp_app_filter BOOLEAN DEFAULT NULL,
  loyalty_member_filter BOOLEAN DEFAULT NULL,
  promo_responsive_filter BOOLEAN DEFAULT NULL,
  weekly_units_min INT DEFAULT NULL
)
RETURNS TABLE(
    channel STRING,
    share_of_segment DOUBLE,
    expected_engagement DOUBLE,
    recommendation STRING
  )
DETERMINISTIC
READS SQL DATA
COMMENT 'Canales de venta preferidos del segmento + recomendación de activación trade marketing.'
RETURN (
  WITH segment AS (
    SELECT *
    FROM serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes
    WHERE (regions IS NULL OR array_contains(regions, region))
      AND (territorios IS NULL OR array_contains(territorios, territorio))
      AND (cedis_list IS NULL OR array_contains(cedis_list, cedis))
      AND (sales_channels IS NULL OR array_contains(sales_channels, sales_channel))
      AND (pdv_strategies IS NULL OR array_contains(pdv_strategies, pdv_strategy))
      AND (nse_levels IS NULL OR array_contains(nse_levels, nse))
      AND (lifecycle_stages IS NULL OR array_contains(lifecycle_stages, lifecycle_stage))
      AND (personas IS NULL OR array_contains(personas, persona_tag))
      AND (cola_tiers IS NULL OR array_contains(cola_tiers, cola_buyer_tier))
      AND (pepsi_preferences IS NULL OR array_contains(pepsi_preferences, pepsi_preference))
      AND (formats IS NULL OR array_contains(formats, preferred_format))
      AND (age_min IS NULL OR age >= age_min)
      AND (age_max IS NULL OR age <= age_max)
      AND (buys_pepsi_filter IS NULL OR buys_pepsi = buys_pepsi_filter)
      AND (buys_coca_filter IS NULL OR buys_coca = buys_coca_filter)
      AND (buys_gatorade_filter IS NULL OR buys_gatorade = buys_gatorade_filter)
      AND (buys_epura_filter IS NULL OR buys_epura = buys_epura_filter)
      AND (buys_energetico_filter IS NULL OR buys_energetico = buys_energetico_filter)
      AND (buys_2L_filter IS NULL OR buys_2L = buys_2L_filter)
      AND (buys_600ml_filter IS NULL OR buys_600ml = buys_600ml_filter)
      AND (health_conscious_filter IS NULL OR health_conscious = health_conscious_filter)
      AND (family_buyer_filter IS NULL OR family_buyer = family_buyer_filter)
      AND (sport_drink_user_filter IS NULL OR sport_drink_user = sport_drink_user_filter)
      AND (is_pepsi_lapsed_filter IS NULL OR is_pepsi_lapsed = is_pepsi_lapsed_filter)
      AND (is_pepsi_heavy_filter IS NULL OR is_pepsi_heavy = is_pepsi_heavy_filter)
      AND (has_gepp_app_filter IS NULL OR has_gepp_app = has_gepp_app_filter)
      AND (loyalty_member_filter IS NULL OR loyalty_member = loyalty_member_filter)
      AND (promo_responsive_filter IS NULL OR promo_responsive = promo_responsive_filter)
      AND (weekly_units_min IS NULL OR weekly_beverage_units >= weekly_units_min)
  ),
  by_channel AS (
    SELECT
      sales_channel,
      COUNT(*) AS n,
      AVG((email_open_rate + whatsapp_response_rate + push_engagement + promo_redemption_rate) / 4.0) AS eng
    FROM segment
    GROUP BY sales_channel
  ),
  total AS (SELECT COUNT(*) AS n FROM segment)
  SELECT
    sales_channel AS channel,
    ROUND(n * 1.0 / (SELECT n FROM total), 4) AS share_of_segment,
    ROUND(eng, 4) AS expected_engagement,
    CASE
      WHEN sales_channel = 'Tradicional' THEN 'Trade DSD: rutas frescas, refrigerador CPG exclusivo, material PDV, promo combo tiendita'
      WHEN sales_channel = 'Moderno' THEN 'Trade conveniencia: tag góndola en OXXO, end-cap super, alianza con sub-canal específico'
      WHEN sales_channel = 'Cuentas Clave' THEN 'Trade cuentas clave: end-cap Walmart/Costco, promo multi-pack, negociación central, monto mínimo'
      WHEN sales_channel = 'On Premise' THEN 'Trade on-premise: dispensador en restaurante/bar, alianza con cadena, menú combo, sampling en evento'
      WHEN sales_channel = 'Hogar' THEN 'Digital: push en app de la embotelladora, WhatsApp commerce, partnership con plataformas delivery (Rappi/Uber/Cornershop)'
      ELSE 'Canal mixto'
    END AS recommendation
  FROM by_channel
  ORDER BY n DESC
);

-- ====================================================================
-- preview_audience_sample
-- ====================================================================
CREATE OR REPLACE FUNCTION serverless_stable_rtpa_catalog.gepp_audience_intelligence.preview_audience_sample(
  regions ARRAY<STRING> DEFAULT NULL,
  territorios ARRAY<STRING> DEFAULT NULL,
  cedis_list ARRAY<STRING> DEFAULT NULL,
  sales_channels ARRAY<STRING> DEFAULT NULL,
  pdv_strategies ARRAY<STRING> DEFAULT NULL,
  nse_levels ARRAY<STRING> DEFAULT NULL,
  lifecycle_stages ARRAY<STRING> DEFAULT NULL,
  personas ARRAY<STRING> DEFAULT NULL,
  cola_tiers ARRAY<STRING> DEFAULT NULL,
  pepsi_preferences ARRAY<STRING> DEFAULT NULL,
  formats ARRAY<STRING> DEFAULT NULL,
  age_min INT DEFAULT NULL,
  age_max INT DEFAULT NULL,
  buys_pepsi_filter BOOLEAN DEFAULT NULL,
  buys_coca_filter BOOLEAN DEFAULT NULL,
  buys_gatorade_filter BOOLEAN DEFAULT NULL,
  buys_epura_filter BOOLEAN DEFAULT NULL,
  buys_energetico_filter BOOLEAN DEFAULT NULL,
  buys_2L_filter BOOLEAN DEFAULT NULL,
  buys_600ml_filter BOOLEAN DEFAULT NULL,
  health_conscious_filter BOOLEAN DEFAULT NULL,
  family_buyer_filter BOOLEAN DEFAULT NULL,
  sport_drink_user_filter BOOLEAN DEFAULT NULL,
  is_pepsi_lapsed_filter BOOLEAN DEFAULT NULL,
  is_pepsi_heavy_filter BOOLEAN DEFAULT NULL,
  has_gepp_app_filter BOOLEAN DEFAULT NULL,
  loyalty_member_filter BOOLEAN DEFAULT NULL,
  promo_responsive_filter BOOLEAN DEFAULT NULL,
  weekly_units_min INT DEFAULT NULL,
  sample_size INT DEFAULT 10
)
RETURNS TABLE(
    consumer_id STRING,
    age INT,
    region STRING,
    territorio STRING,
    cedis STRING,
    nse STRING,
    persona_tag STRING,
    pepsi_preference STRING,
    sales_channel STRING,
    pdv_strategy STRING,
    preferred_format STRING,
    weekly_beverage_units INT,
    monthly_spend_beverages_mxn INT,
    ltv_score DOUBLE
  )
DETERMINISTIC
READS SQL DATA
COMMENT 'Sample de hasta N consumidores del segmento, ordenado por LTV. Incluye región, territorio, CEDIS, canal, estrategia.'
RETURN (
  WITH ranked AS (
    SELECT
      consumer_id,
      CAST(age AS INT) AS age,
      region,
      territorio,
      cedis,
      nse,
      persona_tag,
      pepsi_preference,
      sales_channel,
      pdv_strategy,
      preferred_format,
      CAST(weekly_beverage_units AS INT) AS weekly_beverage_units,
      CAST(monthly_spend_beverages_mxn AS INT) AS monthly_spend_beverages_mxn,
      ltv_score,
      ROW_NUMBER() OVER (ORDER BY ltv_score DESC) AS rn
    FROM serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes
    WHERE (regions IS NULL OR array_contains(regions, region))
      AND (territorios IS NULL OR array_contains(territorios, territorio))
      AND (cedis_list IS NULL OR array_contains(cedis_list, cedis))
      AND (sales_channels IS NULL OR array_contains(sales_channels, sales_channel))
      AND (pdv_strategies IS NULL OR array_contains(pdv_strategies, pdv_strategy))
      AND (nse_levels IS NULL OR array_contains(nse_levels, nse))
      AND (lifecycle_stages IS NULL OR array_contains(lifecycle_stages, lifecycle_stage))
      AND (personas IS NULL OR array_contains(personas, persona_tag))
      AND (cola_tiers IS NULL OR array_contains(cola_tiers, cola_buyer_tier))
      AND (pepsi_preferences IS NULL OR array_contains(pepsi_preferences, pepsi_preference))
      AND (formats IS NULL OR array_contains(formats, preferred_format))
      AND (age_min IS NULL OR age >= age_min)
      AND (age_max IS NULL OR age <= age_max)
      AND (buys_pepsi_filter IS NULL OR buys_pepsi = buys_pepsi_filter)
      AND (buys_coca_filter IS NULL OR buys_coca = buys_coca_filter)
      AND (buys_gatorade_filter IS NULL OR buys_gatorade = buys_gatorade_filter)
      AND (buys_epura_filter IS NULL OR buys_epura = buys_epura_filter)
      AND (buys_energetico_filter IS NULL OR buys_energetico = buys_energetico_filter)
      AND (buys_2L_filter IS NULL OR buys_2L = buys_2L_filter)
      AND (buys_600ml_filter IS NULL OR buys_600ml = buys_600ml_filter)
      AND (health_conscious_filter IS NULL OR health_conscious = health_conscious_filter)
      AND (family_buyer_filter IS NULL OR family_buyer = family_buyer_filter)
      AND (sport_drink_user_filter IS NULL OR sport_drink_user = sport_drink_user_filter)
      AND (is_pepsi_lapsed_filter IS NULL OR is_pepsi_lapsed = is_pepsi_lapsed_filter)
      AND (is_pepsi_heavy_filter IS NULL OR is_pepsi_heavy = is_pepsi_heavy_filter)
      AND (has_gepp_app_filter IS NULL OR has_gepp_app = has_gepp_app_filter)
      AND (loyalty_member_filter IS NULL OR loyalty_member = loyalty_member_filter)
      AND (promo_responsive_filter IS NULL OR promo_responsive = promo_responsive_filter)
      AND (weekly_units_min IS NULL OR weekly_beverage_units >= weekly_units_min)
  )
  SELECT consumer_id, age, region, territorio, cedis, nse, persona_tag, pepsi_preference,
         sales_channel, pdv_strategy, preferred_format,
         weekly_beverage_units, monthly_spend_beverages_mxn, ltv_score
  FROM ranked
  WHERE rn <= COALESCE(sample_size, 10)
);

-- ====================================================================
-- compare_segments
-- ====================================================================
CREATE OR REPLACE FUNCTION serverless_stable_rtpa_catalog.gepp_audience_intelligence.compare_segments(
  segment_a_regions ARRAY<STRING> DEFAULT NULL,
  segment_a_pdv_strategies ARRAY<STRING> DEFAULT NULL,
  segment_a_sales_channels ARRAY<STRING> DEFAULT NULL,
  segment_a_personas ARRAY<STRING> DEFAULT NULL,
  segment_a_cola_tiers ARRAY<STRING> DEFAULT NULL,
  segment_a_pepsi_preferences ARRAY<STRING> DEFAULT NULL,
  segment_a_age_min INT DEFAULT NULL,
  segment_a_age_max INT DEFAULT NULL,
  segment_b_regions ARRAY<STRING> DEFAULT NULL,
  segment_b_pdv_strategies ARRAY<STRING> DEFAULT NULL,
  segment_b_sales_channels ARRAY<STRING> DEFAULT NULL,
  segment_b_personas ARRAY<STRING> DEFAULT NULL,
  segment_b_cola_tiers ARRAY<STRING> DEFAULT NULL,
  segment_b_pepsi_preferences ARRAY<STRING> DEFAULT NULL,
  segment_b_age_min INT DEFAULT NULL,
  segment_b_age_max INT DEFAULT NULL
)
RETURNS TABLE(
    metric STRING,
    segment_a_value DOUBLE,
    segment_b_value DOUBLE,
    delta_pct DOUBLE
  )
DETERMINISTIC
READS SQL DATA
COMMENT 'Compara métricas de consumo entre dos segmentos CPG (gasto, unidades, %Pepsi/Coca, engagement).'
RETURN (
  WITH a AS (
    SELECT * FROM serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes
    WHERE (segment_a_regions IS NULL OR array_contains(segment_a_regions, region))
      AND (segment_a_pdv_strategies IS NULL OR array_contains(segment_a_pdv_strategies, pdv_strategy))
      AND (segment_a_sales_channels IS NULL OR array_contains(segment_a_sales_channels, sales_channel))
      AND (segment_a_personas IS NULL OR array_contains(segment_a_personas, persona_tag))
      AND (segment_a_cola_tiers IS NULL OR array_contains(segment_a_cola_tiers, cola_buyer_tier))
      AND (segment_a_pepsi_preferences IS NULL OR array_contains(segment_a_pepsi_preferences, pepsi_preference))
      AND (segment_a_age_min IS NULL OR age >= segment_a_age_min)
      AND (segment_a_age_max IS NULL OR age <= segment_a_age_max)
  ),
  b AS (
    SELECT * FROM serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes
    WHERE (segment_b_regions IS NULL OR array_contains(segment_b_regions, region))
      AND (segment_b_pdv_strategies IS NULL OR array_contains(segment_b_pdv_strategies, pdv_strategy))
      AND (segment_b_sales_channels IS NULL OR array_contains(segment_b_sales_channels, sales_channel))
      AND (segment_b_personas IS NULL OR array_contains(segment_b_personas, persona_tag))
      AND (segment_b_cola_tiers IS NULL OR array_contains(segment_b_cola_tiers, cola_buyer_tier))
      AND (segment_b_pepsi_preferences IS NULL OR array_contains(segment_b_pepsi_preferences, pepsi_preference))
      AND (segment_b_age_min IS NULL OR age >= segment_b_age_min)
      AND (segment_b_age_max IS NULL OR age <= segment_b_age_max)
  ),
  ma AS (
    SELECT
      AVG(monthly_spend_beverages_mxn) AS m_spend,
      AVG(weekly_beverage_units) AS m_units,
      AVG(CAST(buys_pepsi AS DOUBLE)) AS m_pepsi,
      AVG(CAST(buys_coca AS DOUBLE)) AS m_coca,
      AVG(CAST(health_conscious AS DOUBLE)) AS m_health,
      AVG(CAST(family_buyer AS DOUBLE)) AS m_family,
      AVG(CAST(has_gepp_app AS DOUBLE)) AS m_app,
      AVG(ltv_score) AS m_ltv
    FROM a
  ),
  mb AS (
    SELECT
      AVG(monthly_spend_beverages_mxn) AS m_spend,
      AVG(weekly_beverage_units) AS m_units,
      AVG(CAST(buys_pepsi AS DOUBLE)) AS m_pepsi,
      AVG(CAST(buys_coca AS DOUBLE)) AS m_coca,
      AVG(CAST(health_conscious AS DOUBLE)) AS m_health,
      AVG(CAST(family_buyer AS DOUBLE)) AS m_family,
      AVG(CAST(has_gepp_app AS DOUBLE)) AS m_app,
      AVG(ltv_score) AS m_ltv
    FROM b
  )
  SELECT * FROM (
    SELECT 'avg_monthly_spend_mxn' AS metric, a.m_spend, b.m_spend, ROUND((b.m_spend / NULLIF(a.m_spend, 0) - 1) * 100, 1) FROM ma a, mb b
    UNION ALL SELECT 'avg_weekly_units', a.m_units, b.m_units, ROUND((b.m_units / NULLIF(a.m_units, 0) - 1) * 100, 1) FROM ma a, mb b
    UNION ALL SELECT 'rate_buys_pepsi', a.m_pepsi, b.m_pepsi, ROUND((b.m_pepsi / NULLIF(a.m_pepsi, 0) - 1) * 100, 1) FROM ma a, mb b
    UNION ALL SELECT 'rate_buys_coca', a.m_coca, b.m_coca, ROUND((b.m_coca / NULLIF(a.m_coca, 0) - 1) * 100, 1) FROM ma a, mb b
    UNION ALL SELECT 'rate_health_conscious', a.m_health, b.m_health, ROUND((b.m_health / NULLIF(a.m_health, 0) - 1) * 100, 1) FROM ma a, mb b
    UNION ALL SELECT 'rate_family_buyer', a.m_family, b.m_family, ROUND((b.m_family / NULLIF(a.m_family, 0) - 1) * 100, 1) FROM ma a, mb b
    UNION ALL SELECT 'rate_has_gepp_app', a.m_app, b.m_app, ROUND((b.m_app / NULLIF(a.m_app, 0) - 1) * 100, 1) FROM ma a, mb b
    UNION ALL SELECT 'avg_ltv', a.m_ltv, b.m_ltv, ROUND((b.m_ltv / NULLIF(a.m_ltv, 0) - 1) * 100, 1) FROM ma a, mb b
  )
);


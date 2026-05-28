-- Recrear tabla Delta population_attributes con estructura de la embotelladora refinada.

DROP TABLE IF EXISTS serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes;

CREATE TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes
USING DELTA
TBLPROPERTIES (delta.dataSkippingNumIndexedCols = 64)
COMMENT 'Tabla maestra de consumidores CPG · 100K consumidores con estructura organizacional de la embotelladora (región, territorio, CEDIS), canal de venta (Moderno, Tradicional, Hogar, On Premise, Cuentas Clave), estrategia comercial (Blindar, Impulsar, Desarrollar, Conservar), portafolio Pepsi con presentaciones reales (235ml hasta 3L), competencia Coca-Cola y atributos de comportamiento, momentos de consumo y engagement con app de la embotelladora.'
AS
SELECT * FROM read_files(
  '/Volumes/serverless_stable_rtpa_catalog/gepp_audience_intelligence/raw/population_attributes.parquet',
  format => 'parquet'
);

ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN consumer_id COMMENT 'ID único del consumidor';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN age COMMENT 'Edad en años';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN age_range COMMENT 'Rango: 15-17, 18-24, 25-34, 35-44, 45-54, 55-64, 65+';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN gender COMMENT 'F, M, Otro';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN region COMMENT 'Región: METRO, BAJIO, CENTRO, PACIFICO, NORTE';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN territorio COMMENT 'Territorio dentro de la región (ej. León, Monterrey, CDMX Norte). 17 territorios.';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN cedis COMMENT 'Centro de Distribución (CEDIS) asignado al consumidor. ~32 CEDIS.';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN state COMMENT 'Estado de residencia MX';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN city COMMENT 'Ciudad de residencia';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN urban_rural COMMENT 'Zona: Urbano o Rural';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN household_size COMMENT 'Personas en el hogar';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN has_kids COMMENT 'TRUE si hay menores en el hogar';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN household_type COMMENT 'Tipo de hogar: Familia grande con hijos, Familia con hijos, Hogar individual, Pareja sin hijos, Hogar compartido';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN nse COMMENT 'NSE (AMAI MX): A/B, C+, C, C-, D+, D, E';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN income_monthly_mxn COMMENT 'Ingreso mensual del hogar en MXN';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN sales_channel COMMENT 'Canal de venta CPG: Moderno (super/OXXO), Tradicional (tiendita/bodega/mercado), Hogar (e-commerce/delivery), On Premise (restaurante/bar), Cuentas Clave (Walmart/Costco/Soriana)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN sub_channel COMMENT 'Sub-canal específico dentro del canal de venta';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buy_frequency COMMENT 'Frecuencia: Diaria, 3-5x semana, 1-2x semana, Quincenal, Mensual u ocasional';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN weekly_beverage_units COMMENT 'Unidades de bebida compradas por semana';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN preferred_format COMMENT 'Formato preferido: 355ml lata, 600ml PET, 1L PET, 2L PET, 3L PET, 235ml mini lata, 500ml vidrio retornable, 355ml vidrio nostalgia';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN weekly_spend_mxn COMMENT 'Gasto semanal en bebidas (MXN)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN monthly_spend_beverages_mxn COMMENT 'Gasto mensual en bebidas (MXN)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_355ml_lata COMMENT 'TRUE si compra lata 355ml';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_600ml COMMENT 'TRUE si compra PET 600ml (personal)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_1L COMMENT 'TRUE si compra PET 1L';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_2L COMMENT 'TRUE si compra PET 2L (familiar)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_3L COMMENT 'TRUE si compra PET 3L (mega familiar)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_mini_lata COMMENT 'TRUE si compra mini lata 235ml';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_vidrio_retornable COMMENT 'TRUE si compra vidrio retornable 500ml';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_pepsi COMMENT 'TRUE si compra Pepsi regular';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_pepsi_light COMMENT 'TRUE si compra Pepsi Light';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_pepsi_black COMMENT 'TRUE si compra Pepsi Black (zero sugar)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_mirinda COMMENT 'TRUE si compra Mirinda (naranja)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_7up COMMENT 'TRUE si compra 7UP';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_manzanita COMMENT 'TRUE si compra Manzanita Sol';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_gatorade COMMENT 'TRUE si compra Gatorade';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_aha COMMENT 'TRUE si compra AHA (agua mineral saborizada)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_epura COMMENT 'TRUE si compra agua Epura';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_be_light COMMENT 'TRUE si compra Be Light';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_coca COMMENT 'TRUE si compra Coca-Cola (competencia)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_coca_zero COMMENT 'TRUE si compra Coca-Cola Zero';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_sprite COMMENT 'TRUE si compra Sprite';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_fanta COMMENT 'TRUE si compra Fanta';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_powerade COMMENT 'TRUE si compra Powerade';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_ciel COMMENT 'TRUE si compra agua Ciel';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_jugos COMMENT 'TRUE si compra jugos (Del Valle, Jumex, Boing)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_te COMMENT 'TRUE si compra té embotellado';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_energetico COMMENT 'TRUE si compra bebidas energéticas';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN buys_horchata_jamaica COMMENT 'TRUE si compra aguas frescas envasadas';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN cola_buyer_tier COMMENT 'Tier comprador cola: Heavy, Medium, Light, Non-buyer';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN pepsi_preference COMMENT 'Loyalist Pepsi, Loyalist Coca, Pepsi-leaning switcher, Coca-leaning switcher, No cola';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN health_conscious COMMENT 'TRUE si tiende a sin azúcar/light/agua/AHA';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN healthy_lifestyle_score COMMENT 'Score lifestyle saludable 1-10';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN family_buyer COMMENT 'TRUE si compra formato 1L+ o hogar con hijos';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN sport_drink_user COMMENT 'TRUE si compra Gatorade o Powerade';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN energy_drink_user COMMENT 'TRUE si compra energéticas';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN fitness_engagement COMMENT 'Engagement fitness 1-10';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN last_pepsi_purchase_days COMMENT 'Días desde última compra Pepsi (999 si nunca)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN is_pepsi_lapsed COMMENT 'TRUE si compraba Pepsi y >60 días sin comprar';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN is_pepsi_active COMMENT 'TRUE si compró Pepsi en los últimos 14 días';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN is_pepsi_heavy COMMENT 'TRUE si es heavy buyer de Pepsi';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN price_sensitive COMMENT 'TRUE si sensible a precio';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN brand_loyal COMMENT 'TRUE si tiene alta lealtad a marca';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN trend_seeker COMMENT 'TRUE si busca tendencias / nuevos productos';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN pairs_with_snacks COMMENT 'TRUE si consume con botana';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN pdv_strategy COMMENT 'Estrategia comercial CPG asignada al consumidor/PDV: Blindar (heavy loyalist Pepsi), Impulsar (switcher con volumen para convertir), Desarrollar (lapsado/light/no engaged para crecer), Conservar (regular buyer Pepsi loyal)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN consumes_with_food COMMENT 'TRUE si consume con comida';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN consumes_party COMMENT 'TRUE si consume en fiestas/reuniones';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN consumes_breakfast COMMENT 'TRUE si consume en desayuno';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN consumes_workout COMMENT 'TRUE si consume al ejercitar';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN weekend_heavy COMMENT 'TRUE si concentra consumo en fin de semana';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN has_gepp_app COMMENT 'TRUE si tiene app de la embotelladora instalada';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN loyalty_member COMMENT 'TRUE si es miembro del programa de lealtad';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN loyalty_tier COMMENT 'Tier loyalty: No miembro, Bronze, Silver, Gold';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN app_sessions_monthly COMMENT 'Sesiones mensuales en app de la embotelladora';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN email_opt_in COMMENT 'TRUE si acepta email';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN whatsapp_opt_in COMMENT 'TRUE si acepta WhatsApp';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN sms_opt_in COMMENT 'TRUE si acepta SMS';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN email_open_rate COMMENT 'Tasa apertura email (0-1)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN whatsapp_response_rate COMMENT 'Tasa respuesta WhatsApp (0-1)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN push_engagement COMMENT 'Engagement push (0-1)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN promo_redemption_rate COMMENT 'Tasa redención promociones (0-1)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN promo_responsive COMMENT 'TRUE si compra principalmente con promo';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN persona_tag COMMENT 'Persona derivada: Joven Energético, Health Switcher, Wellness Maduro, Familia Refresquera, Deportista Activo, Pepsi Heavy Loyalist, Cola Heavy User, Maduro Tradicional, Mainstream Bebida';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN lifecycle_stage COMMENT 'Etapa: Heavy fan, Loyalty active, Engaged digital, Regular buyer, Light buyer, Lapsado, No engaged';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN ltv_score COMMENT 'LTV anual estimado (basado en spend)';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN acquisition_channel COMMENT 'Canal de adquisición a app de la embotelladora';
ALTER TABLE serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes ALTER COLUMN first_purchase_date COMMENT 'Fecha primera compra';

CREATE OR REPLACE VIEW serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_baseline_rates
COMMENT 'Tasas globales (baseline) de atributos clave para calcular lift.'
AS
SELECT
  COUNT(*) AS total_population,
  AVG(CAST(buys_pepsi AS DOUBLE)) AS rate_pepsi,
  AVG(CAST(buys_pepsi_light AS DOUBLE)) AS rate_pepsi_light,
  AVG(CAST(buys_pepsi_black AS DOUBLE)) AS rate_pepsi_black,
  AVG(CAST(buys_mirinda AS DOUBLE)) AS rate_mirinda,
  AVG(CAST(buys_7up AS DOUBLE)) AS rate_7up,
  AVG(CAST(buys_manzanita AS DOUBLE)) AS rate_manzanita,
  AVG(CAST(buys_gatorade AS DOUBLE)) AS rate_gatorade,
  AVG(CAST(buys_aha AS DOUBLE)) AS rate_aha,
  AVG(CAST(buys_epura AS DOUBLE)) AS rate_epura,
  AVG(CAST(buys_coca AS DOUBLE)) AS rate_coca,
  AVG(CAST(buys_coca_zero AS DOUBLE)) AS rate_coca_zero,
  AVG(CAST(buys_sprite AS DOUBLE)) AS rate_sprite,
  AVG(CAST(buys_powerade AS DOUBLE)) AS rate_powerade,
  AVG(CAST(buys_ciel AS DOUBLE)) AS rate_ciel,
  AVG(CAST(buys_jugos AS DOUBLE)) AS rate_jugos,
  AVG(CAST(buys_te AS DOUBLE)) AS rate_te,
  AVG(CAST(buys_energetico AS DOUBLE)) AS rate_energetico,
  AVG(CAST(health_conscious AS DOUBLE)) AS rate_health_conscious,
  AVG(CAST(family_buyer AS DOUBLE)) AS rate_family_buyer,
  AVG(CAST(sport_drink_user AS DOUBLE)) AS rate_sport_drink,
  AVG(CAST(energy_drink_user AS DOUBLE)) AS rate_energy_drink,
  AVG(CAST(is_pepsi_lapsed AS DOUBLE)) AS rate_pepsi_lapsed,
  AVG(CAST(is_pepsi_heavy AS DOUBLE)) AS rate_pepsi_heavy,
  AVG(CAST(has_gepp_app AS DOUBLE)) AS rate_gepp_app,
  AVG(CAST(loyalty_member AS DOUBLE)) AS rate_loyalty,
  AVG(CAST(price_sensitive AS DOUBLE)) AS rate_price_sensitive,
  AVG(CAST(brand_loyal AS DOUBLE)) AS rate_brand_loyal,
  AVG(CAST(promo_responsive AS DOUBLE)) AS rate_promo_responsive,
  AVG(CAST(buys_355ml_lata AS DOUBLE)) AS rate_355ml_lata,
  AVG(CAST(buys_600ml AS DOUBLE)) AS rate_600ml,
  AVG(CAST(buys_1L AS DOUBLE)) AS rate_1L,
  AVG(CAST(buys_2L AS DOUBLE)) AS rate_2L,
  AVG(CAST(buys_3L AS DOUBLE)) AS rate_3L,
  AVG(CAST(consumes_party AS DOUBLE)) AS rate_consumes_party,
  AVG(CAST(consumes_workout AS DOUBLE)) AS rate_consumes_workout,
  AVG(CAST(weekend_heavy AS DOUBLE)) AS rate_weekend_heavy,
  AVG(CAST(pairs_with_snacks AS DOUBLE)) AS rate_pairs_snacks
FROM serverless_stable_rtpa_catalog.gepp_audience_intelligence.population_attributes;

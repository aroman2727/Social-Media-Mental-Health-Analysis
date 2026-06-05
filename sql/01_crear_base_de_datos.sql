-- ============================================================
--  BASE DE DATOS: SocialMedia_MentalHealth
--  Fuente de datos: Kaggle - Social Media Addiction & Mental Health Dataset
-- Autor del dataset: Adbul Malik Lodhra
-- URL: https://www.kaggle.com/datasets/abdulmaliklodhra/
--		social-media-addiction-and-mental-health-dataset/data
--  Motor: SQL Server 2016+
-- ============================================================

-- ============================================================
-- DECISIONES DE DISEÑO - LEER ANTES DE EJECUTAR
-- ============================================================
--
-- 1. SIN PRIMARY KEY NI FOREIGN KEY
-- Este dataset es de naturaleza sintetica y orientado a analisis
-- estadistico, no a un sistema transaccional. Se verifico que:
--	-user_id NO es unico: existen duplicados
--	-user_id + year + platform tampoco es unico
--	-No existe ninguna combinacion de columnas que garantice unicidad
-- 
-- Conclusion: se obto por no definir PRIMARY KEY ni FOREIGN KEY.
--
-- 2. SIN TABLA TEMPORAL EN LA CARGA
--
-- 3. COLUMNAS BOOLEANAS COMO NVARCHAR(5)
-- Los CSVs almacenan valores booleanos como texto 'True'/'False'.
-- SQL Server no convierte texto a BIT durante BULK INSERT.
-- Solucion: se cargan como NVARCHAR(5) y despues de la carga se
-- agregan columnas BIT calculadas (True=1, False=0), se elimanan
-- las originales de texto y se renombran las BIT con el nombre original.
--
-- ============================================================

-- ============================================================
-- 1. CREAR LA BASE DE DATOS
-- ============================================================

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name ='SocialMedia_MentalHealth')
	CREATE DATABASE SocialMedia_MentalHealth;
GO 

USE SocialMedia_MentalHealth;
GO

-- ============================================================
-- 2. ELIMINAR TABLAS SI EXISTEN
-- ============================================================
-- Sin FK no hay restriccion de orden.
IF OBJECT_ID('social_media_usage', 'U') IS NOT NULL DROP TABLE social_media_usage;
IF OBJECT_ID('screen_time_behavior', 'U') IS NOT NULL DROP TABLE screen_time_behavior;
IF OBJECT_ID('sleep_disruption', 'U') IS NOT NULL DROP TABLE sleep_disruption;
IF OBJECT_ID('teen_behavior_patterns', 'U') IS NOT NULL DROP TABLE teen_behavior_patterns;
IF OBJECT_ID('dopamine_trigger_metrics', 'U') IS NOT NULL DROP TABLE dopamine_trigger_metrics;
IF OBJECT_ID('ai_recommendation_impact', 'U') IS NOT NULL DROP TABLE ai_recommendation_impact;
IF OBJECT_ID('digital_detox_behavior', 'U') IS NOT NULL DROP TABLE digital_detox_behavior;
IF OBJECT_ID('cyberbullying_impact', 'U') IS NOT NULL DROP TABLE cyberbullying_impact;
IF OBJECT_ID('future_psychological_forecast', 'U') IS NOT NULL DROP TABLE future_psychological_forecast;
IF OBJECT_ID('mental_health_trends', 'U') IS NOT NULL DROP TABLE mental_health_trends;
GO

-- ============================================================
-- 3. CREAR TABLAS
-- ============================================================
-- Reglas de tipado aplicadas:
-- INT			-> Identificadores y conteos sin limite definido
-- SMALLINT		-> Año (rango 2011-2060, cabe en 2 bytes vs 4 del INT)
-- NVARCHAR		-> Texto con soporte Unicode (tildes, caracteres especiales)
-- DECIMAL(5,2)	-> Scores y porcentajes de 0.00 a 999.99
-- DECIMAL(4,2)	-> Horas (maximo 24.00, no necesita 3 digitos enteros)
-- DECIMAL(5,4)	-> Probabilidades de 0.0000 a 1.0000
-- NVARCHAR(5)	-> Booleanos 'True'/'False' (se convierten a BIT post-carga)
-- NOT NULL		-> Columnas de contexto sin las cuales el registro es inutil
-- NULL			-> Metricas que pueden no estar disponibles para todos los registros

-- Tabla principal: tendencias de salud mental
CREATE TABLE mental_health_trends(
	user_id				INT					NOT NULL,
	year				SMALLINT			NOT NULL,
	country				NVARCHAR(60)		NOT NULL,
	age_group			NVARCHAR(20)		NOT NULL,
	gender				NVARCHAR(20)		NOT NULL,
	platform			NVARCHAR(30)		NOT NULL,
	anxiety_score		DECIMAL(5,2)		NULL,
	depression_score	DECIMAL(5,2)		NULL,
	stress_level		DECIMAL(5,2)		NULL,
	loneliness_index	DECIMAL(5,2)		NULL,
	therapy_access		NVARCHAR(5)			NULL,
	medication_usage	NVARCHAR(5)			NULL,
	self_esteem_score	DECIMAL(5,2)		NULL,
	mental_health_risk	NVARCHAR(10)		NULL, -- LOW/MEDIUM/HIGH
	);

-- Uso de redes sociales
CREATE TABLE social_media_usage(
	user_id						INT					NOT NULL,
	year						SMALLINT			NOT NULL,
	country						NVARCHAR(60)		NOT NULL,
	age_group					NVARCHAR(20)		NOT NULL,
	gender						NVARCHAR(20)		NOT NULL,
	platform					NVARCHAR(30)		NOT NULL,
	daily_screen_time_hours		DECIMAL(5,2)		NULL,
	doomscrolling_frequency		DECIMAL(5,2)		NULL,
	notification_checks_per_day	INT					NULL,
	ai_recommendation_exposure	DECIMAL(5,2)		NULL,
	productivity_loss_pct		DECIMAL(5,2)		NULL,
	digital_detox_attempts		INT					NULL,
	addiction_risk_level		NVARCHAR(10)		NULL,
	);

-- Comportamiento frente a pantallas
CREATE TABLE screen_time_behavior(
	user_id							INT					NOT NULL,
	year							SMALLINT			NOT NULL,
	country							NVARCHAR(60)		NOT NULL,
	age_group						NVARCHAR(20)		NOT NULL,
	gender							NVARCHAR(20)		NOT NULL,
	platform						NVARCHAR(30)		NOT NULL,
	weekday_screen_hours			DECIMAL(5,2)		NULL,
	weekend_screen_hours			DECIMAL(5,2)		NULL,
	multitasking_frequency			DECIMAL(5,2)		NULL,
	focus_span_minutes				DECIMAL(5,2)		NULL,
	physical_activity_hours_weekly	DECIMAL(5,2)		NULL,
	);

-- Alteraciones del sueño
CREATE TABLE sleep_disruption(
	user_id					INT				NOT NULL,
	year					SMALLINT		NOT NULL,
	country					NVARCHAR(60)	NOT NULL,
	age_group				NVARCHAR(20)	NOT NULL,
	gender					NVARCHAR(20)	NOT NULL,
	platform				NVARCHAR(30)	NOT NULL,
	avg_sleep_hours			DECIMAL(4,2)	NULL,
	sleep_quality_score		DECIMAL(5,2)	NULL,
	late_night_usage_hours	DECIMAL(4,2)	NULL,
	night_notifications		INT				NULL,
	fatigue_level			DECIMAL(5,2)	NULL,
	);

-- Patrones de comportamiento adolescente
CREATE TABLE teen_behavior_patterns(
	user_id						INT					NOT NULL,
	year						SMALLINT			NOT NULL,
	country						NVARCHAR(60)		NOT NULL,
	age_group					NVARCHAR(20)		NOT NULL,
	gender						NVARCHAR(20)		NOT NULL,
	platform					NVARCHAR(30)		NOT NULL,
	academic_performance_score	DECIMAL(5,2)		NULL,
	social_comparison_index		DECIMAL(5,2)		NULL,
	body_image_anxiety_score	DECIMAL(5,2)		NULL,
	peer_pressure_score			DECIMAL(5,2)		NULL,
	suicide_risk_indicator		NVARCHAR(5)			NULL,
	);

-- Metricas de dopamina y engagement
CREATE TABLE dopamine_trigger_metrics(
	user_id								INT				NOT NULL,
	year								SMALLINT		NOT NULL,
	country								NVARCHAR(60)	NOT NULL,
	age_group							NVARCHAR(20)	NOT NULL,
	gender								NVARCHAR(20)	NOT NULL,
	platform							NVARCHAR(30)	NOT NULL,
	engagement_rate						DECIMAL(5,2)	NULL,
	short_video_consumption_hours		DECIMAL(4,2)	NULL,
	dopamine_trigger_score				DECIMAL(5,2)	NULL,
	content_refresh_frequency			INT				NULL,
	instant_gratification_dependency	DECIMAL(5,2)	NULL,
	);

-- Impactos de algoritmos de IA y recomendaciones
CREATE TABLE ai_recommendation_impact(
	user_id								INT				NOT NULL,
	year								SMALLINT		NOT NULL,
	country								NVARCHAR(60)	NOT NULL,
	age_group							NVARCHAR(20)	NOT NULL,
	gender								NVARCHAR(20)	NOT NULL,
	platform							NVARCHAR(30)	NOT NULL,
	algorithmic_content_exposure		DECIMAL(5,2)	NULL,
	echo_chamber_score					DECIMAL(5,2)	NULL,
	content_personalization_intensity	DECIMAL(5,2)	NULL,
	emotional_manipulation_index		DECIMAL(5,2)	NULL,
	ai_addiction_probability			DECIMAL(5,4)	NULL,
	);

-- Comportamiento de desintoxicacion digital
CREATE TABLE digital_detox_behavior(
	user_id							INT				NOT NULL,
	year							SMALLINT		NOT NULL,
	country							NVARCHAR(60)	NOT NULL,
	age_group						NVARCHAR(20)	NOT NULL,
	gender							NVARCHAR(20)	NOT NULL,
	platform						NVARCHAR(30)	NOT NULL,
	detox_attempts					INT				NULL,
	successful_detox				NVARCHAR(5)		NULL,
	offline_activity_hours_weekly	DECIMAL(5,2)	NULL,
	wellbeing_improvement_score		DECIMAL(5,2)	NULL,
	relapse_probability				DECIMAL(5,4)	NULL,
	);

-- Impacto del ciberbullying
CREATE TABLE cyberbullying_impact(
	user_id						INT				NOT NULL,
	year						SMALLINT		NOT NULL,
	country						NVARCHAR(60)	NOT NULL,
	age_group					NVARCHAR(20)	NOT NULL,
	gender						NVARCHAR(20)	NOT NULL,
	platform					NVARCHAR(30)	NOT NULL,
	cyberbullying_exposure		NVARCHAR(5)		NULL,
	harassment_frequency		DECIMAL(5,2)	NULL,
	self_harm_risk_score		DECIMAL(5,2)	NULL,
	social_withdrawal_score		DECIMAL(5,2)	NULL,
	reported_to_authorities		NVARCHAR(5)		NULL,
	);

-- Pronostico psicologico futuro
-- Tabla agregada por año, pais y plataforma
CREATE TABLE future_psychological_forecast(
	forecast_year						SMALLINT		NOT NULL,
	country								NVARCHAR(60)	NOT NULL,
	platform							NVARCHAR(30)	NOT NULL,
	predicted_anxiety_rate				DECIMAL(5,2)	NULL,
	predicted_attention_span_minutes	DECIMAL(5,2)	NULL,
	predicted_ai_addiction_index		DECIMAL(5,2)	NULL,
	digital_isolation_score				DECIMAL(5,2)	NULL,
	mental_health_recovery_rate			DECIMAL(5,2)	NULL,
	predicted_sleep_decline_pct			DECIMAL(5,2)	NULL,
	);
GO

-- ============================================================
-- 4. IMPORTAR DATOS CON BULK INSERT
-- ============================================================
-- IMPORTANTE: ajusta la ruta a la carpeta donde tengas los CSVs
--
-- Parametros usados:
-- FIRSTROW=2		-> Salta la fila de encabezados
-- FIELDTERMINATOR	-> Separador de columnas (coma)
-- ROWTERMINATOR	-> Salto de linea Unix (0x0a)
-- TABLOCK			-> Bloqueo de tabla para mayor velocidad
-- CODEPAGE='65001'	-> Codificacion UTF-8 para caracteres especiales

BULK INSERT mental_health_trends
FROM 'C:\Ruta_A_Tus_Archivos\mental_health_trends.csv'
WITH (	
		FIRSTROW=2, 
		FIELDTERMINATOR=',', 
		ROWTERMINATOR='0x0a', 
		TABLOCK, 
		CODEPAGE='65001'
	);

BULK INSERT social_media_usage
FROM 'C:\Ruta_A_Tus_Archivos\social_media_usage.csv'
WITH(
		FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='0X0a',
		TABLOCK,
		CODEPAGE='65001'
	);

BULK INSERT screen_time_behavior
FROM 'C:\Ruta_A_Tus_Archivos\screen_time_behavior.csv'
WITH(
		FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='0X0a',
		TABLOCK,
		CODEPAGE='65001'
	);

BULK INSERT sleep_disruption
FROM 'C:\Ruta_A_Tus_Archivos\sleep_disruption.csv'
WITH(
		FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='0x0a',
		TABLOCK,
		CODEPAGE='65001'
	);

BULK INSERT teen_behavior_patterns
FROM 'C:\Ruta_A_Tus_Archivos\teen_behavior_patterns.csv'
WITH(
		FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='0x0a',
		TABLOCK,
		CODEPAGE='65001'
	);

BULK INSERT dopamine_trigger_metrics
FROM 'C:\Ruta_A_Tus_Archivos\dopamine_trigger_metrics.csv'
WITH(
		FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='0x0a',
		TABLOCK,
		CODEPAGE='65001'
	);

BULK INSERT ai_recommendation_impact
FROM 'C:\Ruta_A_Tus_Archivos\ai_recommendation_impact.csv'
WITH(
		FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='0x0a',
		TABLOCK,
		CODEPAGE='65001'
	);

BULK INSERT digital_detox_behavior
FROM 'C:\Ruta_A_Tus_Archivos\digital_detox_behavior.csv'
WITH(
		FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='0x0a',
		TABLOCK,
		CODEPAGE='65001'
	);

BULK INSERT cyberbullying_impact
FROM 'C:\Ruta_A_Tus_Archivos\cyberbullying_impact.csv'
WITH(
		FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='0x0a',
		TABLOCK,
		CODEPAGE='65001'
	);

BULK INSERT future_psychological_forecast
FROM 'C:\Ruta_A_Tus_Archivos\future_psychological_forecast.csv'
WITH(
		FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='0x0a',
		TABLOCK,
		CODEPAGE='65001'
	);
GO

-- ============================================================
-- 5. ÍNDICES RECOMENDADOS PARA CONSULTAS FRECUENTES
-- ============================================================
-- Se indexan columnas de contexto usadas en WHERE, JOIN y GROUP BY.
-- No se indexan metricas (anxiety_score, etc.) por que en analisis 
-- se usan en agregaciones (AVG, SUM), no como filtros exactos
-- Con 50 000 filas el impacto es minimo, pero refleja buenas practicas
-- que escalan cuando el volumen de datos crece.
CREATE INDEX IX_mental_user_id			ON mental_health_trends (user_id);
CREATE INDEX IX_mental_country_year		ON mental_health_trends (country, year);
CREATE INDEX IX_mental_platform			ON mental_health_trends (platform);
CREATE INDEX IX_age_gender				ON mental_health_trends (age_group, gender);
CREATE INDEX IX_mental_risk				ON mental_health_trends (mental_health_risk);

CREATE INDEX IX_social_user_id			ON social_media_usage (user_id);
CREATE INDEX IX_screen_user_id			ON screen_time_behavior (user_id);
CREATE INDEX IX_sleep_user_id			ON sleep_disruption (user_id);
CREATE INDEX IX_teen_user_id			ON teen_behavior_patterns (user_id);
CREATE INDEX IX_dopamine_user_id		ON dopamine_trigger_metrics (user_id);
CREATE INDEX IX_ai_user_id				ON ai_recommendation_impact (user_id);
CREATE INDEX IX_digital_user_id			ON digital_detox_behavior (user_id);
CREATE INDEX IX_cyber_user_id			ON cyberbullying_impact (user_id);

CREATE INDEX IX_forecast_year_country	ON future_psychological_forecast (forecast_year, country);
GO

-- ============================================================
-- 6. CONVERTIR COLUMNAS TRUE/FALSE A BIT
-- ============================================================
-- Los CSVs usan texto 'True'/'False' en columnas booleanas.
-- Pasos: agregar columna BIT -> Llenar con CASE -> eliminar texto y renombrar

-- mental_health_trends
ALTER TABLE mental_health_trends
ADD therapy_access_bit		BIT NULL,
	medication_usage_bit	BIT NULL;

UPDATE mental_health_trends SET
	therapy_access_bit		= CASE WHEN therapy_access ='True' THEN 1 ELSE 0 END,
	medication_usage_bit	= CASE WHEN medication_usage = 'True' THEN 1 ELSE 0 END;

ALTER TABLE mental_health_trends
DROP COLUMN therapy_access, medication_usage;

EXEC sp_rename 'mental_health_trends.therapy_access_bit', 'therapy_access', 'COLUMN';
EXEC sp_rename 'mental_health_trends.medication_usage_bit', 'medication_usage', 'COLUMN';
GO
-- digital_detox_behavior
ALTER TABLE digital_detox_behavior 
ADD successful_detox_bit BIT NULL;

UPDATE digital_detox_behavior SET
	successful_detox_bit	= CASE WHEN successful_detox = 'True' THEN 1 ELSE 0 END;

ALTER TABLE digital_detox_behavior 
DROP COLUMN successful_detox;

EXEC sp_rename 'digital_detox_behavior.successful_detox_bit', 'successful_detox', 'COLUMN';
GO

-- cyberbullying_impact
ALTER TABLE cyberbullying_impact
ADD cyberbullying_exposure_bit		BIT NULL,
	reported_to_authorities_bit		BIT NULL;

UPDATE cyberbullying_impact SET
	cyberbullying_exposure_bit	= CASE WHEN cyberbullying_exposure = 'True' THEN 1 ELSE 0 END,
	reported_to_authorities_bit	= CASE WHEN reported_to_authorities = 'True' THEN 1 ELSE 0 END;

ALTER TABLE cyberbullying_impact
DROP COLUMN cyberbullying_exposure, reported_to_authorities;

EXEC sp_rename 'cyberbullying_impact.cyberbullying_exposure_bit', 'cyberbullying_exposure', 'COLUMN';
EXEC sp_rename 'cyberbullying_impact.reported_to_authorities_bit', 'reported_to_authorities', 'COLUMN';
GO

-- teen_behavior_patterns
ALTER TABLE teen_behavior_patterns
ADD suicide_risk_indicator_bit BIT NULL;

UPDATE teen_behavior_patterns SET
	suicide_risk_indicator_bit = CASE WHEN suicide_risk_indicator = 'True' THEN 1 ELSE 0 END;

ALTER TABLE teen_behavior_patterns
DROP COLUMN suicide_risk_indicator

EXEC sp_rename 'teen_behavior_patterns.suicide_risk_indicator_bit', 'suicide_risk_indicator', 'COLUMN';

-- ============================================================
-- 7. VERIFICACIÓN FINAL
-- ============================================================
-- Confirma que todas las tablas cargaron el numero correcto de filas
-- esperado: 50 000 filas en la mayoria, 40 000 en teen, 30 000 en forecast.

SELECT 'mental_health_trends' AS Tabla,	COUNT(*) AS fila	FROM mental_health_trends
UNION ALL
SELECT 'social_media_usage',			COUNT(*)			FROM social_media_usage
UNION ALL
SELECT 'screen_time_behavior',			COUNT(*)			FROM screen_time_behavior
UNION ALL
SELECT 'sleep_disruption',				COUNT(*)			FROM sleep_disruption
UNION ALL
SELECT 'teen_behavior_patterns',		COUNT(*)			FROM teen_behavior_patterns
UNION ALL
SELECT 'dopamine_trigger_metrics',		COUNT(*)			FROM dopamine_trigger_metrics
UNION ALL
SELECT 'ai_recommendation_impact',		COUNT(*)			FROM ai_recommendation_impact
UNION ALL
SELECT 'digital_detox_behavior',		COUNT(*)			FROM digital_detox_behavior
UNION ALL
SELECT 'cyberbullying_impact',			COUNT(*)			FROM cyberbullying_impact
UNION ALL
SELECT 'future_psychological_forecast',	COUNT(*)			FROM future_psychological_forecast;
GO

-- ============================================================
-- 8. ANALISIS EXPLORATORIO: PERFIL GENERAL DEL USUARIO
-- ============================================================
-- Nota de diseño: debido a la dispersion temporal de los registros en este
-- dataset sintetico, cruzar estrictamente por (user_id+year+platform)
-- retorna un conjunto vacio. Se opta por unir las tablas unicamente por
-- user_id para evaluar el perfil de vida historico de la persona.
--
-- ADVERTENCIA DE MODELADO: Esta tecnica genera un Producto Cartesiano
-- (multiplicacion de filas), al conectar este resultado a Popwer BI, es
-- OBLIGATORIO utilizar medidas de Promedio (AVG) y no Sumas (SUM)
-- para no inflar artificialmente las metricas.
	
SELECT
		m.user_id,
		m.country,
		m.age_group,
		m.platform AS mental_platform,
		m.mental_health_risk,
		m.anxiety_score,
		s.addiction_risk_level,
		sl.avg_sleep_hours
FROM mental_health_trends		m
JOIN social_media_usage			s	ON m.user_id = s.user_id
JOIN sleep_disruption			sl	ON m.user_id = sl.user_id
WHERE m.mental_health_risk		= 'High'
	AND s.addiction_risk_level	= 'High'
ORDER BY m.anxiety_score DESC;
GO

-- ============================================================
-- 9. CRUCE OPTIMIZADO PARA BI: AGREGACION PREVIA CON CTEs
-- ============================================================
-- Solucion de Data Engineering para evitar la explosion de datos
-- obaservada en la consulta anterior. En lugar de cruzar tablas crudas,
-- se recume la historia de cada usuario utilizando CTEs.

-- Esto garantiza una relacion estricta de 1 a 1 en el JOIN final.
-- Es el modelo ideal para alimentar herramientas de visualizacion, ya que
-- asegura una precision anlitica del 100% sin importar que funcion
-- de agregacion (SUM, AVG) utilice el usuario final en el dashboard.

WITH Perfil_Mental AS (
	SELECT
		user_id,
		MAX(country)			AS country_profile,
		MAX(age_group)			AS age_profile,
		AVG(anxiety_score)		AS avg_anxiety_life,
		AVG(depression_score)	AS avg_depression_life
	FROM mental_health_trends
	WHERE mental_health_risk = 'High'
	GROUP BY user_id
),
Perfil_Redes AS (
	SELECT
		user_id,
		MAX(addiction_risk_level) AS max_addiction_risk
		FROM social_media_usage
		WHERE addiction_risk_level = 'High'
		GROUP BY user_id
),
Perfil_Sueno AS (
	SELECT
		user_id,
		AVG(avg_sleep_hours) AS avg_sleep_life
	FROM sleep_disruption
	GROUP BY user_id
)
SELECT
	m.user_id,
	m.country_profile,
	m.age_profile,
	m.avg_anxiety_life,
	m.avg_depression_life,
	r.max_addiction_risk,
	s.avg_sleep_life
FROM Perfil_Mental	m
JOIN Perfil_Redes	r ON m.user_id = r.user_id
JOIN Perfil_Sueno	s ON m.user_id = s.user_id
ORDER BY m.avg_anxiety_life DESC;
GO
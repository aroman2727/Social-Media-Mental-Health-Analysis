-- ============================================================
-- ANALISIS SQL: Social Media & Mental Health
-- Base de datos: SocialMedia_MentalHealth
-- Motor: SQL Server
-- ============================================================
--
-- DESCRIPCION TECNICA:
-- Este script contiene 20 consultas analiticas optimizadas para
-- alimentar un modelo dimensional en Power BI.
-- 
-- TECNICAS APLICADAS:
--	- Agregaciones condicionales (CASE WHEN dentro de SUM/AVG).
--	- Manejo de excepciones matematicas (NULLIF para divisiones por cero).
--	- Common Table Expressions (CTEs) para resolver multiplicaciones
--	  de registros (Productos Cartesianos) en uniones de 1:N.
--	- Construccion de indices compuestos y metricas ponderadas.
--
-- ============================================================

USE SocialMedia_MentalHealth
GO

-- ============================================================
-- ANALISIS 01
-- Pregunta:	¿Que plataforma daña mas la salud mental?
-- Tablas:		mental_health_trends
-- Diseño:		Uso de ROUND y AVG para estabilizar metricas dispersas.
-- ============================================================

SELECT
		platform,
		ROUND(AVG(anxiety_score),		2)	AS	avg_anxiety,
		ROUND(AVG(depression_score),	2)	AS	avg_depression,
		ROUND(AVG(stress_level),		2)	AS	avg_stress,
		ROUND(AVG(loneliness_index),	2)	AS	avg_loneliness,
		COUNT(*)							AS	total_usuarios
FROM mental_health_trends
GROUP BY platform
ORDER BY avg_anxiety DESC;
GO

-- ============================================================
-- ANALISIS 02
-- Pregunta:	¿Los algoritmos de IA crean adiccion a traves de la dopamina?
-- Tablas:		dopamine_trigger_metrics + ai_recomendation_impact + social_media_usage
-- Diseño:		JOIN compuesto (user_id + platform) para evitar el cruce
--				accidental de metricas de distintas redes sociales del mismo usuario.	
-- ============================================================

SELECT
	d.platform,
	d.age_group,
	d.gender,
	s.addiction_risk_level,
	ROUND(AVG(d.dopamine_trigger_score),		2)	AS	avg_dopamine_score,
	ROUND(AVG(a.ai_addiction_probability)*100,	2)	AS	avg_ai_addiction_prob,
	ROUND(AVG(a.emotional_manipulation_index),	2)	AS	avg_manipulation,
	ROUND(AVG(a.echo_chamber_score),			2)	AS	avg_echo_chamber	
FROM dopamine_trigger_metrics	d
JOIN ai_recommendation_impact	a	ON d.user_id = a.user_id AND d.platform = a.platform
JOIN social_media_usage			s	ON d.user_id = s.user_id AND d.platform = s.platform
GROUP BY d.platform, d.age_group, d.gender, s.addiction_risk_level
ORDER BY avg_dopamine_score DESC;
GO

-- ============================================================
-- ANALISIS 03
-- Pregunta: ¿La edad protege o empeora el impacto digital?
-- Tablas:	mental_health_trends + screen_time_behavior + cyberbullying_impact
-- Diseño:	Uso de CTEs para pre-agregar el historial del usuario y 
--			evitar perdida de datos por falta de integridad referencial
--			en las dimensiones d eplataforma y año.
-- ============================================================

WITH Screen_Profile AS (
	SELECT
		user_id,
		AVG(weekday_screen_hours)	AS avg_user_weekday,
		AVG(weekend_screen_hours)	AS avg_user_weekend,
		AVG(focus_span_minutes)		AS avg_user_focus
	FROM screen_time_behavior
	GROUP BY user_id
),
Cyber_Profile AS (
	SELECT
		user_id,
		AVG(self_harm_risk_score)		AS avg_user_self_harm,
		AVG(social_withdrawal_score)	AS avg_user_withdrawal
	FROM cyberbullying_impact
	GROUP BY user_id
)
SELECT
	m.age_group,
	ROUND(AVG(m.anxiety_score),			2) AS avg_anxiety,
	ROUND(AVG(m.depression_score),		2) AS avg_depression,
	ROUND(AVG(m.stress_level),			2) AS avg_stress,
	ROUND(AVG(s.avg_user_weekday),		2) AS avg_weekday_screen,
	ROUND(AVG(s.avg_user_weekend),		2) AS avg_weekend_screen,
	ROUND(AVG(s.avg_user_focus),		2) AS avg_focus_span,
	ROUND(AVG(c.avg_user_self_harm),	2) AS avg_self_harm_risk,
	ROUND(AVG(c.avg_user_withdrawal),	2) AS avg_social_withdrawal
FROM mental_health_trends m
LEFT JOIN Screen_Profile s	ON m.user_id = s.user_id
LEFT JOIN Cyber_Profile c	ON m.user_id = c.user_id
GROUP BY m.age_group
ORDER BY avg_anxiety DESC;
GO

-- ============================================================
-- Analisis 04
-- Pregunta: ¿Hacia donde vamos si no cambiamos nada?
-- Tabla: future_psychological_forecast
-- ============================================================

SELECT
	forecast_year,
	platform,
	ROUND(AVG(predicted_anxiety_rate),				2) AS avg_predicted_anxiety,
	ROUND(AVG(predicted_ai_addiction_index),		2) AS avg_predicted_addiction,
	ROUND(AVG(digital_isolation_score),				2) AS avg_isolation,
	ROUND(AVG(mental_health_recovery_rate),			2) AS avg_recovery_rate,
	ROUND(AVG(predicted_sleep_decline_pct),			2) AS avg_sleep_decline,
	ROUND(AVG(predicted_attention_span_minutes),	2) AS avg_attention_span
FROM future_psychological_forecast
GROUP BY forecast_year, platform
ORDER BY forecast_year, avg_predicted_anxiety DESC;
GO

-- ============================================================
-- ANALISIS 05
-- Pregunta: ¿El uso nocturno de pantallas causa depresion?
-- Tablas:	sleep_disruption + mental_health_trends
-- Diseño:	JOIN estricto por user_id y platform para evitar
--			distorsion, y ordenamiento por variable independiente.
-- ============================================================

SELECT
	m.age_group,
	m.platform,
	ROUND(AVG(sl.late_night_usage_hours),	2) AS avg_late_night_hours,
	ROUND(AVG(sl.night_notifications),		2) AS avg_night_notifications,
	ROUND(AVG(sl.avg_sleep_hours),			2) AS avg_sleep_hours,
	ROUND(AVG(sl.sleep_quality_score),		2) AS avg_sleep_quality,
	ROUND(AVG(sl.fatigue_level),			2) AS avg_fatigue,
	ROUND(AVG(m.depression_score),			2) AS avg_depression,
	ROUND(AVG(m.anxiety_score),				2) AS avg_anxiety
FROM sleep_disruption sl
JOIN mental_health_trends m 
	ON sl.user_id = m.user_id
	AND sl.platform = m.platform
GROUP BY m.age_group, m.platform
ORDER BY avg_late_night_hours DESC;
GO

-- ============================================================
-- ANALISIS 06
-- Pregunta: ¿Desconectarse mejora la salud mental de verdad?
-- Tablas: digital_detox_behavior + mental_health_trends
-- ============================================================

SELECT
	d.successful_detox,
	CASE
		WHEN d.successful_detox = 1 THEN 'SI (Exitoso)'
		ELSE 'NO (Fallo)'
	END AS resultado_detox,
	d.platform,
	ROUND(AVG(d.wellbeing_improvement_score),	2) AS avg_wellbeing_improvement,
	ROUND(AVG(d.relapse_probability),			2) AS avg_relapse_probability,
	ROUND(AVG(d.detox_attempts),				2) AS avg_detox_attempts,
	ROUND(AVG(d.offline_activity_hours_weekly),	2) AS avg_offline_hours,
	ROUND(AVG(m.anxiety_score),					2) AS avg_anxiety,
	ROUND(AVG(m.depression_score),				2) AS avg_depression
FROM digital_detox_behavior d
JOIN mental_health_trends m ON d.user_id = m.user_id AND d.platform = m.platform
GROUP BY d.successful_detox, d.platform
ORDER BY d.platform, d.successful_detox;
GO

-- ============================================================
-- ANALISIS 07
-- Pregunta: ¿Donde estan los adolescentes mas en riesgo?
-- Tablas:	cyberbullying_impact + teen_behavior_patterns
-- Diseño:	CTE multidimensional (user_id+country+platform) para
--			evitar perdida de detalle dimensional, combinado con
--			NULLIF para calculos seguros de porcentajes.
-- ============================================================

WITH Cyber_Profile AS (
	SELECT
		user_id,
		country,
		platform,
		AVG(harassment_frequency) AS avg_harassment,
		AVG(self_harm_risk_score) AS avg_self_harm_risk,
		AVG(social_withdrawal_score) AS avg_social_withdrawal,
		MAX(CAST(cyberbullying_exposure AS INT)) AS exposed,
		MAX(CAST(reported_to_authorities AS INT)) AS reported
	FROM cyberbullying_impact
	GROUP BY user_id, country, platform
)
SELECT
	c.country,
	c.platform,
	ROUND(AVG(c.avg_harassment),		2)	AS avg_harassment,
	ROUND(AVG(c.avg_self_harm_risk),	2)	AS avg_self_harm_risk,
	ROUND(AVG(c.avg_social_withdrawal),	2)	AS avg_social_withdrawal,
	SUM(c.exposed)							AS total_exposed,
	SUM(c.reported)							AS total_reported,
	COUNT(c.user_id)						AS total_usuarios,
	ROUND(100*SUM(c.exposed)/NULLIF(COUNT(c.user_id),0),2) AS pct_exposed
FROM Cyber_Profile c
JOIN teen_behavior_patterns t ON c.user_id = t.user_id
GROUP BY c.country, c.platform
ORDER BY avg_self_harm_risk DESC;
GO

-- ============================================================
-- ANALISIS 08
-- Pregunta:	¿Instagram afecta mas a mujeres que a hombres?
-- Tablas:		mental_health_trends + teen_behavior_patterns
-- ============================================================

SELECT
	m.gender,
	m.platform,
	ROUND(AVG(m.anxiety_score),				2) AS avg_anxiety,
	ROUND(AVG(m.depression_score),			2) AS avg_depression,
	ROUND(AVG(m.self_esteem_score),			2) AS avg_self_esteem,
	ROUND(AVG(t.body_image_anxiety_score),	2) AS avg_body_image_anxiety,
	ROUND(AVG(t.social_comparison_index),	2) AS avg_social_comparison,
	ROUND(AVG(t.peer_pressure_score),		2) AS avg_peer_pressure
FROM mental_health_trends m
JOIN teen_behavior_patterns t ON m.user_id = t.user_id
GROUP BY m.gender, m.platform
ORDER BY m.platform, avg_depression DESC;
GO

-- ============================================================
-- ANALISIS 09
-- Pregunta:	¿Cual es el estado actual global de salud mental digital?
-- Tabla:		mental_health_trends + social_media_usage + 
--				ai_recommendation_impact + sleep_disruption + 
-- Diseño:		Las variables globales requieren aislamiento via CTEs para
--				que los conteos globales (COUNT) y sumatorias no generen
--				calculos exponenciales erroneos por multiplicidad de llaves.
-- ============================================================

WITH Global_Mental AS (
	SELECT
		AVG(anxiety_score) AS kpi_avg_anxiety,
		AVG(depression_score) AS kpi_avg_depression,
		AVG(stress_level) AS kpi_avg_stress,
		COUNT(DISTINCT country) AS kpi_total_countries,
		COUNT(DISTINCT platform) AS kpi_total_platforms,
		COUNT(*) AS kpi_total_records,
		SUM(CASE WHEN mental_health_risk = 'High' AND therapy_access = 0 THEN 1
			ELSE 0 END) AS kpi_treatment_gap
	FROM mental_health_trends
),
Global_Social AS (
	SELECT
		AVG(daily_screen_time_hours) AS kpi_avg_screen_hours
	FROM social_media_usage
),
Global_AI AS (
	SELECT
		AVG(ai_addiction_probability)*100 AS kpi_avg_ai_addiction_pct
	FROM ai_recommendation_impact
),
Global_Sleep AS (
	SELECT AVG(avg_sleep_hours) AS kpi_avg_sleep_hours
	FROM sleep_disruption
)
SELECT
	ROUND(m.kpi_avg_anxiety,			2)	AS kpi_avg_anxiety,
	ROUND(m.kpi_avg_depression,			2)	AS kpi_avg_depression,
	ROUND(m.kpi_avg_stress,				2)	AS kpi_avg_stress,
	ROUND(s.kpi_avg_screen_hours,		2)	AS kpi_avg_screen_hours,
	ROUND(a.kpi_avg_ai_addiction_pct,	2)	AS kpi_avg_ai_addiction_pct,
	ROUND(sl.kpi_avg_sleep_hours,		2)	AS kpi_avg_sleep_hours,
	m.kpi_total_countries,
	m.kpi_total_platforms,
	m.kpi_total_records,
	m.kpi_treatment_gap,
	ROUND(100.0*m.kpi_treatment_gap/NULLIF(m.kpi_total_records,0),2) AS kpi_treatment_gap_pct
FROM Global_Mental m
CROSS JOIN Global_Social s
CROSS JOIN Global_AI a
CROSS JOIN Global_Sleep sl;
GO

-- ============================================================
-- ============================================================
-- ANALISIS CON COLUMNAS CALCULADAS (10 AL 20)
-- Construccion de metricas compuestas y ratios de negocio.
-- ============================================================
-- ============================================================

-- ============================================================
-- ANALISIS 10
-- Pregunta:	¿Quien tiene el peor equilibrio digital-fisico?
-- Diseño:		Uso de NULLIF para evitar errores de ejecucion
--				por division entre cero(Divide by Zero Exception).
-- ============================================================

SELECT
	country,
	age_group,
	gender,
	platform,
	ROUND(AVG(weekday_screen_hours),			2) AS avg_weekday_screen,
	ROUND(AVG(weekend_screen_hours),			2) AS avg_weekend_screen,
	ROUND(AVG(physical_activity_hours_weekly),	2) AS avg_physical_activity,
	ROUND(AVG((weekday_screen_hours*5) + (weekend_screen_hours*2)),2) AS total_weekly_screen_hours,
	ROUND(AVG((weekday_screen_hours*5) + (weekend_screen_hours*2))/
				NULLIF(AVG(physical_activity_hours_weekly), 0), 2) AS screen_vs_activity_ratio
FROM screen_time_behavior
GROUP BY country, age_group, gender, platform
ORDER BY screen_vs_activity_ratio DESC;
GO

-- ============================================================
-- ANALISIS 11
-- Pregunta:	¿Donde las personas no tienen acceso a terapia?
-- Diseño:		Calculo de brecha utilizando agregacion logica condicional.
-- ============================================================

SELECT
	country,
	mental_health_risk,
	COUNT(*) AS total_usuarios,
	ROUND(AVG((anxiety_score + depression_score + stress_level + loneliness_index)/4.0), 2) AS psychological_burden_index,
	SUM(CASE WHEN mental_health_risk = 'High' 
		AND therapy_access=0 THEN 1 ELSE 0 END) AS treatment_gap,
	ROUND(100.0*SUM(CASE WHEN mental_health_risk = 'High' 
		AND therapy_access = 0 THEN 1 ELSE 0 END)/COUNT(*), 2) AS treatment_gap_pct,
	ROUND(AVG(CAST(therapy_access AS FLOAT)) * 100, 2) AS pct_with_therapy,
	ROUND(AVG(CAST(medication_usage AS FLOAT)) * 100, 2) AS pct_with_medication
FROM mental_health_trends
GROUP BY country, mental_health_risk
ORDER BY treatment_gap DESC;
GO

-- ============================================================
-- ANALISIS 12
-- Pregunta:	¿Que plataforma tiene el algoritmo mas dañino?
-- Diseño:		Creacion de score ponderado (Weighted Score) para 
--				evaluar impacto multivariable.
-- ============================================================

SELECT
	platform,
	ROUND(AVG(echo_chamber_score),						2) AS avg_echo_chamber,
	ROUND(AVG(emotional_manipulation_index),			2) AS avg_manipulation,
	ROUND(AVG(ai_addiction_probability)*100,			2) AS avg_addiction_prob_pct,
	ROUND(AVG(content_personalization_intensity),		2) AS avg_personalization,
	ROUND(AVG(
			(echo_chamber_score				* 0.30) + 
			(emotional_manipulation_index	* 0.40) +
			(ai_addiction_probability * 100	* 0.30)),	2) AS algorithmic_danger_score,
	COUNT(*) AS total_usuarios
FROM ai_recommendation_impact
GROUP BY platform
ORDER BY algorithmic_danger_score DESC;
GO

-- ============================================================
-- ANALISIS 13
-- Pregunta:	¿Que tienen en comun los teen con mayor riesgo?
-- Diseño:		Aislamiento de la variable "suicide_risk_indicator"
--				mediante subconsulta CTE para sumarizacion exacta.
-- ============================================================

WITH Teen_Profile AS (
	SELECT
		user_id,
		MAX(country) AS country,
		MAX(platform) AS platform,
		MAX(gender) AS gender,
		AVG((body_image_anxiety_score+peer_pressure_score+
			social_comparison_index)/3.0) AS teen_vuln_idx,
		AVG(academic_performance_score) AS avg_academic,
		MAX(CAST(suicide_risk_indicator AS INT)) AS has_suicide_risk
	FROM teen_behavior_patterns
	GROUP BY user_id
)
SELECT
	t.country,
	t.platform,
	t.gender,
	ROUND(AVG(t.teen_vuln_idx),			2)	AS teen_vulnerability_index,
	ROUND(AVG(t.avg_academic),			2)	AS avg_academic_performance,
	ROUND(AVG(c.harassment_frequency),	2)	AS avg_harassment,
	ROUND(AVG(c.self_harm_risk_score),	2)	AS avg_self_harm_risk,
	ROUND(AVG(m.depression_score),		2)	AS avg_depression,
	ROUND(AVG(m.anxiety_score),			2)	AS avg_anxiety,
	SUM(t.has_suicide_risk)					AS total_suicide_risk
FROM Teen_Profile t
JOIN cyberbullying_impact c ON t.user_id = c.user_id
JOIN mental_health_trends m ON t.user_id = m.user_id
GROUP BY t.country, t.platform, t.gender
ORDER BY teen_vulnerability_index DESC;
GO

-- ============================================================
-- ANALISIS 14
-- Pregunta: ¿A que edad afecta mas el bombardeo nocturno?
-- ============================================================

SELECT
    age_group,
    platform,
    gender,
    ROUND(AVG(late_night_usage_hours), 2) AS avg_late_night_hours,
    ROUND(AVG(night_notifications),    2) AS avg_night_notifications,
    ROUND(AVG(avg_sleep_hours),        2) AS avg_sleep_hours,
    ROUND(AVG(sleep_quality_score),    2) AS avg_sleep_quality,
    ROUND(AVG(fatigue_level),          2) AS avg_fatigue,
    ROUND(AVG(late_night_usage_hours * night_notifications), 2) AS digital_bedtime_pressure
FROM sleep_disruption
GROUP BY age_group, platform, gender
ORDER BY digital_bedtime_pressure DESC;
GO

-- ============================================================
-- ANALISIS 15
-- Pregunta: ¿Estamos peor que hace 10 años?
-- ============================================================

SELECT
	year,
	ROUND(AVG((anxiety_score + depression_score + 
		stress_level + loneliness_index)/4.0), 2) AS psychological_burden_index,
	ROUND(AVG(anxiety_score),    2)     AS avg_anxiety,
    ROUND(AVG(depression_score), 2)     AS avg_depression,
    ROUND(AVG(stress_level),     2)     AS avg_stress,
    ROUND(AVG(loneliness_index), 2)     AS avg_loneliness,
    ROUND(AVG(self_esteem_score),2)     AS avg_self_esteem,
    COUNT(*)                            AS total_registros
FROM mental_health_trends
GROUP BY year
ORDER BY year;
GO

-- ============================================================
-- ANALISIS 16
-- Pregunta:	¿Los usuarios de TikTOK recaen mas que los de LinkedIn?
-- Diseño:		CAST explicito y prevencion matematica (NULLIF) en ratio.
-- ============================================================

SELECT
	platform,
    age_group,
    ROUND(AVG(detox_attempts),					2)	AS avg_detox_attempts,
    ROUND(AVG(wellbeing_improvement_score),		2)	AS avg_wellbeing_improvement,
    ROUND(AVG(relapse_probability),				4)	AS avg_relapse_probability,
    ROUND(AVG(offline_activity_hours_weekly),	2)	AS avg_offline_hours,
	ROUND(AVG(
		wellbeing_improvement_score / NULLIF(CAST(detox_attempts AS FLOAT),0)
		),2)										AS detox_efficiency_score,
	COUNT(*)										AS total_usuarios
FROM digital_detox_behavior
GROUP BY platform, age_group
ORDER BY detox_efficiency_score DESC;
GO

-- ============================================================
-- ANALISIS 17
-- Pregunta:	¿A mayor dopamina, peor rendimiento escolar?
-- ============================================================

SELECT
	d.platform,
    d.age_group,
    d.country,
    ROUND(AVG(d.dopamine_trigger_score),			2)	AS avg_dopamine_score,
    ROUND(AVG(d.engagement_rate),					2)	AS avg_engagement,
    ROUND(AVG(d.instant_gratification_dependency),	2)	AS avg_instant_gratification,
    ROUND(AVG(t.academic_performance_score),		2)	AS avg_academic_performance,
    ROUND(AVG(t.social_comparison_index),			2)	AS avg_social_comparison,
    ROUND(AVG(
		d.dopamine_trigger_score * (d.content_refresh_frequency / 100.0) 
		* d.instant_gratification_dependency
    ), 2)												AS addiction_pressure_index
FROM dopamine_trigger_metrics d
JOIN teen_behavior_patterns t ON d.user_id = t.user_id
GROUP BY d.platform, d.age_group, d.country
ORDER BY addiction_pressure_index DESC;
GO

-- ============================================================
-- ANALISIS 18
-- Pregunta:	¿Los algoritmos manipulan mas emocionalmente a mujeres?
-- ============================================================

SELECT
    m.gender,
    a.platform,
    ROUND(AVG(a.emotional_manipulation_index),		2)	AS avg_manipulation,
    ROUND(AVG(a.echo_chamber_score),				2)	AS avg_echo_chamber,
    ROUND(AVG(a.ai_addiction_probability) * 100,	2)	AS avg_addiction_prob_pct,
    ROUND(AVG(m.anxiety_score),						2)	AS avg_anxiety,
    ROUND(AVG(m.depression_score),					2)	AS avg_depression,
    ROUND(AVG(
        (a.echo_chamber_score                 * 0.30) +
        (a.emotional_manipulation_index       * 0.40) +
        (a.ai_addiction_probability * 100     * 0.30)
		 ), 2)											AS algorithmic_danger_score
FROM ai_recommendation_impact a
JOIN mental_health_trends m ON a.user_id = m.user_id
GROUP BY m.gender, a.platform
ORDER BY a.platform, algorithmic_danger_score DESC;
GO

-- ============================================================
-- ANALISIS 19
-- Pregunta:	¿Duermen menos lo que tienen peor slaud mental?
-- ============================================================

SELECT
    m.age_group,
    m.country,
    m.platform,
    ROUND(AVG(sl.avg_sleep_hours),		2)	AS avg_sleep_hours,
    ROUND(AVG(sl.sleep_quality_score),	2)	AS avg_sleep_quality,
    ROUND(AVG(sl.fatigue_level),		2)	AS avg_fatigue,
    ROUND(AVG(m.anxiety_score),			2)	AS avg_anxiety,
    ROUND(AVG(m.depression_score),		2)	AS avg_depression,
    ROUND(AVG(
		(m.anxiety_score + m.depression_score + m.stress_level + m.loneliness_index) / 4.0
    ), 2)									AS psychological_burden_index
FROM sleep_disruption sl
JOIN mental_health_trends m ON sl.user_id = m.user_id
GROUP BY m.age_group, m.country, m.platform
ORDER BY avg_sleep_hours ASC;
GO

-- ============================================================
-- ANALISIS 20
-- Pregunta:	¿Cuanto empeora el mundo año a año hacia 2060?
-- ============================================================

SELECT
    forecast_year,
    country,
    ROUND(AVG(predicted_anxiety_rate),			2)	AS avg_predicted_anxiety,
    ROUND(AVG(predicted_ai_addiction_index),	2)	AS avg_predicted_addiction,
    ROUND(AVG(digital_isolation_score),			2)	AS avg_isolation,
    ROUND(AVG(mental_health_recovery_rate),		2)	AS avg_recovery,
    ROUND(AVG(predicted_sleep_decline_pct),		2)	AS avg_sleep_decline,
    ROUND(AVG(
        (predicted_anxiety_rate       * 0.40) +
        (predicted_ai_addiction_index * 0.35) +
        (digital_isolation_score      * 0.25)
    ), 2)											AS crisis_composite_index
FROM future_psychological_forecast
GROUP BY forecast_year, country
ORDER BY forecast_year, crisis_composite_index DESC;
GO

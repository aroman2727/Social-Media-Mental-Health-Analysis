# 🧠 Social Media Addiction & Mental Health — SQL + Power BI

![SQL Server](https://img.shields.io/badge/SQL_Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=power-bi&logoColor=black)
![Data Engineering](https://img.shields.io/badge/Data_Engineering-005571?style=for-the-badge)

Análisis completo del impacto del uso de redes sociales en la salud mental global. El proyecto abarca desde el diseño de la base de datos y optimización en SQL Server hasta la visualización en Power BI, documentando cada decisión técnica tomada en el proceso.

## 📌 Fuente de datos
| Campo | Detalle |
| :--- | :--- |
| **Dataset** | Social Media Addiction & Mental Health Dataset |
| **Autor** | Abdul Malik Lodhra |
| **Plataforma** | Kaggle ([Enlace al Dataset](https://www.kaggle.com/datasets/abdulmaliklodhra/social-media-addiction-and-mental-health-dataset)) |
| **Naturaleza** | Dataset sintético para análisis estadístico |
| **Volumen** | ~460,000 registros totales en 10 archivos CSV |

---

## 🗂️ Estructura del proyecto

    SocialMedia_MentalHealth/
    │
    ├── data/                          # CSVs originales de Kaggle
    │   ├── mental_health_trends.csv
    │   └── (9 archivos CSV adicionales)
    │
    ├── sql/
    │   ├── 01_crear_base_de_datos.sql # Creación de tablas, carga masiva e índices
    │   └── 02_analisis_consultas.sql  # 20 consultas analíticas optimizadas
    │
    ├── powerbi/
    │   └── dashboard.pbix             # Dashboard Power BI (próximamente)
    │
    └── README.md


---

## 🗄️ Base de datos — Tablas
| Tabla | Filas | Descripción |
| :--- | :--- | :--- |
| `mental_health_trends` | 50,000 | Tabla principal — ansiedad, depresión, estrés, acceso a terapia |
| `social_media_usage` | 50,000 | Uso general, tiempo de pantalla, riesgo de adicción |
| `screen_time_behavior` | 50,000 | Horas de pantalla, foco, actividad física |
| `sleep_disruption` | 50,000 | Horas de sueño, calidad, uso nocturno, notificaciones |
| `ai_recommendation_impact` | 50,000 | Algoritmos, cámaras de eco, manipulación emocional |
| `dopamine_trigger_metrics` | 50,000 | Engagement, videos cortos, dependencia a gratificación |
| `digital_detox_behavior` | 50,000 | Intentos de desintoxicación, recaídas, bienestar |
| `cyberbullying_impact` | 50,000 | Acoso digital, riesgo de autolesión, reporte |
| `teen_behavior_patterns` | 40,000 | Rendimiento académico, presión de pares, autoimagen |
| `future_psychological_forecast` | 30,000 | Proyecciones por año, país y plataforma hasta 2060 |

---

## ⚙️ Decisiones de diseño — SQL Server

### ¿Por qué no hay PRIMARY KEY?
Al analizar los datos se identificaron problemas estructurales que descartaron las opciones tradicionales:

* **Opción 1 descartada — user_id como PK simple:** Se verificó que `user_id` no es único (14,874 duplicados en 50,000 filas). Un mismo usuario aparece en múltiples años y plataformas, lo cual es válido para el análisis histórico.
* **Opción 2 descartada — PK compuesta (user_id + year + platform):** La combinación todavía produce 105 duplicados. Una PK de 6 columnas reduciría esto a 1, pero es altamente ineficiente en rendimiento y mantenimiento.
* **Opción 3 descartada — record_id IDENTITY:** Agrega complejidad (requiere tablas temporales adicionales durante el `BULK INSERT`) sin aportar valor analítico.

**Conclusión adoptada:** El dataset fue diseñado para análisis estadístico, no para un sistema transaccional. No se define PRIMARY KEY. Las tablas se relacionan mediante JOIN analítico por contexto: `user_id` (y CTEs de agregación para evitar multiplicidad). *Saber cuándo no aplicar una restricción es tan importante como saber cuándo aplicarla.*

### Tipos de datos
| Tipo | Uso | Razón técnica |
| :--- | :--- | :--- |
| `INT` | `user_id`, conteos | Rango amplio sin límite definido |
| `SMALLINT` | `year` | Años 2011–2060 caben en 2 bytes vs 4 del INT |
| `NVARCHAR` | `country`, `platform` | Soporte Unicode, longitud ajustada al valor máximo real + margen |
| `DECIMAL(5,2)` | Scores 0–100 | Precisión exacta, 3 enteros + 2 decimales |
| `DECIMAL(4,2)` | Horas 0–24 | Máximo 24.00, no necesita 3 dígitos enteros |
| `DECIMAL(5,4)` | Probabilidades | Rango 0.0000–1.0000, necesita 4 decimales |
| `BIT` | Flags booleanos | Conversión desde texto ('True'/'False') post-carga para optimización de almacenamiento |

---

## 📊 Análisis realizados — 20 consultas

### Grupo 1 — Análisis directos (Consultas 01–09)
| # | Pregunta de Negocio | Tablas Involucradas | Visualización BI |
| :--- | :--- | :--- | :--- |
| **01** | ¿Qué plataforma daña más la salud mental? | mental_health + social_media | Barras horizontales |
| **02** | ¿Los algoritmos crean adicción vía dopamina? | dopamine + ai + social_media | Scatter plot |
| **03** | ¿La edad protege o empeora el impacto digital? | mental + screen + cyberbullying | Radar chart |
| **04** | ¿Hacia dónde vamos si no cambiamos nada? | future_forecast | Área apilada |
| **05** | ¿El uso nocturno de pantallas causa depresión? | sleep + screen + mental | Scatter c/ tendencia |
| **06** | ¿Desconectarse mejora la salud mental? | digital_detox + mental_health | Barras apiladas |
| **07** | ¿Dónde están los adolescentes más en riesgo? | cyberbullying + teen_behavior | Mapa coroplético |
| **08** | ¿Instagram afecta más a mujeres que a hombres? | mental_health + teen_behavior | Heatmap / Barras |
| **09** | ¿Cuál es el estado actual global? | *Todas* | KPI Cards |

### Grupo 2 — Columnas calculadas y CTEs (Consultas 10–20)
| # | Pregunta | Columna Calculada | Lógica de la Fórmula |
| :--- | :--- | :--- | :--- |
| **10** | Peor equilibrio digital-físico | `screen_vs_activity_ratio` | Total horas pantalla ÷ Horas actividad física |
| **11** | Negación de acceso a terapia | `treatment_gap` | Riesgo='High' AND Terapia=0 → 1 |
| **12** | Algoritmo más dañino | `algorithmic_danger_score` | (Echo×0.3) + (Manipulación×0.4) + (Adicción×0.3) |
| **13** | Teens en crisis | `teen_vulnerability_index` | Promedio(Autoimagen, Presión social, Comparación) |
| **14** | Bombardeo nocturno | `digital_bedtime_pressure` | Horas nocturnas × Notificaciones |
| **15** | Tendencia a 10 años | `psychological_burden_index` | Promedio(Ansiedad, Depresión, Estrés, Soledad) |
| **16** | Recaídas por plataforma | `detox_efficiency_score` | Mejora de bienestar ÷ Intentos de detox |
| **17** | Dopamina vs Rendimiento | `addiction_pressure_index` | Dopamina × (Refresh ÷ 100) × Gratificación |
| **20** | Proyección al 2060 | `crisis_composite_index` | (Ansiedad×0.4) + (Adicción×0.35) + (Aislamiento×0.25) |

---

## 📈 Dashboard Power BI (Próximamente)

El modelo visual se alimenta mediante la inyección directa de consultas SQL pre-agregadas (técnica de *Push-Down Computing*), evitando el cálculo pesado en DAX para garantizar un rendimiento instantáneo.

* **Dashboard 1 (Ejecutivo):** KPIs globales, ranking de daño algorítmico, y proyecciones a futuro. Lectura rápida en 5 minutos.
* **Dashboard 2 (Técnico):** Correlaciones profundas (dopamina vs adicción), impacto cruzado por grupos etarios, eficiencia de los intentos de desintoxicación y mapeo de perfiles vulnerables.

---

## 🚀 Cómo reproducir el proyecto

1. **Clona el repositorio:**
   `git clone https://github.com/aroman2727/Social-Media-Mental-Health-Analysis`
2. **Descarga los CSVs:** Obtenlos desde [Kaggle](https://www.kaggle.com/datasets/abdulmaliklodhra/social-media-addiction-and-mental-health-dataset) y colócalos en una ruta local.
3. **Ejecuta la creación:** Abre `01_crear_base_de_datos.sql` en SSMS, ajusta las rutas del `BULK INSERT` y ejecuta el script completo.
4. **Ejecuta el análisis:** Abre `02_analisis_consultas.sql` para explorar las métricas.
5. **Conecta Power BI:** Obtener datos → SQL Server → Base de Datos `SocialMedia_MentalHealth`.

---

## 👨‍💻 Autor

**Aaron Alejandro Kiwaki Alvarez** Ingeniero Mecatrónico en transición directa hacia roles de Data Engineering y Análisis de Datos (SQL, Python, ecosistemas Big Data). 

* 🔗 **LinkedIn:** https://www.linkedin.com/in/aaron-kiwaki/
* 📧 **Email:** alejandro.kiwaki@gmail.com

> *Dataset utilizado bajo los términos de uso de Kaggle. Todos los datos son sintéticos.*

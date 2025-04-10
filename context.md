UX Design for Freguson
Coach UX
(Journey from creating training to dashboard reports)
1. Coach Login & Home Screen
• Login Page: Enters credentials.
• Home/Dashboard (Post-login):
o Upcoming Training Sessions (date, time, location). جلسات التدريب القادمة
o Quick Stats: fatigue alerts, AI recommendations.
o AI Alerts: Players at risk of injury or in need of rest.
• Key Data Fields:
o coach_id, session_count, pending_notifications, injury_alerts[]
 
2. Creating a Training Session / Match
Training / Match
1. Create Session Button:
o Title (e.g., “Speed Drills”, “Strength Training”)
o Date & Time
o Location (manual input or map integration) اختيار من متعدد
o Training Focus (e.g., endurance, speed, tactical)
o Select Players (around 20-30 player) اختيار من متعدد Select All
1. Name, Image, Position
2. Create Match:
o Title
o Opponent Team
o Location
o Players
3. Send Notifications: Alerts players.
 
• Key Data Fields:
o session_id, session_title, session_type, session_date_time, location, invited_players[], confirmation_status[]
 
 
 
 
 
 
3. Post-Training Performance Evaluation
Coach evaluates players after training:
• Performance Metrics: تتغير حسب الPosition للاعب
 
o Speed (1–10)
o Stamina (1–10)
o Accuracy/Technique (1–10)
o Tactical Understanding (1–10)
o Coach’s Comments (optional)
• Key Data Fields:
o performance_id, player_id, player_position, session_id, speed_rating, stamina_rating, accuracy_rating, tactical_rating, coach_comments
 
4. AI-Driven Insights for Coach
• Injury Risk Alerts: Based on fatigue and performance trends.
• Fatigue Management Recommendations: AI suggests rest days or lighter training.
• Performance Analysis: AI tracks long-term improvements and weaknesses.
• Key Data Fields (for AI):
o historical_performance_data[], fatigue_levels[], attendance_data[], injury_risk_score, rest_day_recommendation
 
Player UX
(Journey from training confirmation to fatigue tracking and AI insights)
1. Player Login & Home Screen
• Login Page: Enters credentials.
• Home/Dashboard:
o Upcoming Training Sessions (confirmed & pending).
o AI Insights (fatigue levels, risk of injury, improvement areas).
o Performance Summary (personal stats from previous sessions).
o 
• Key Data Fields:
o player_id, upcoming_sessions[], fatigue_status, personal_performance_trends[], player_position
 
 
2. Post-Training Fatigue & Pain Report
After training, players self-report fatigue and injuries:
• Fatigue Level (1–10 or "None, Mild, Moderate, Severe").
• Pain/Discomfort:
o Select body areas (if applicable).
o Optional comment box.
• Key Data Fields:
o fatigue_level, pain_areas[], self_report_comments
 
3. AI-Driven Insights for Players
• Fatigue Warnings: AI suggests rest or light workouts if needed.
• Performance Trend Analysis:
o Displays improvement areas.
o Highlights consistently weak metrics (e.g., low stamina scores).
• Potential Injury Risk Alerts:
o AI detects high fatigue + performance drops = risk of injury.
• Key Data Fields:
o fatigue_trends[], performance_recommendations[], injury_risk_flag
 
 
Website:
sofascore.com موقع مهم
Owner Dashboard & Reports داشبورد خاصة لمالك الفريق
- أداء اللاعبين (من انخفض ومن ارتفع أدائه)
- عدد الأهداف للاعبين
- الحارس كم هدف صد
- أداء الفريق بشكل عام متحسّن او اسوء
1. Dashboard Overview:
o Team Performance Graphs (speed, stamina trends).
o Fatigue Map (visual fatigue levels per player).
o Injury Risk Indicators (flags players needing attention).
2. Detailed Reports:
o Individual Player Profile (performance + fatigue trends).
o Team Summary (attendance, training intensity, AI recommendations).
• Key Data Fields:
o team_performance_trends, player_risk_flags[], report_date_range, recommendations[]
 
 
 
Final System Flow
Coach Journey
1. Homepage→ Sees dashboard insights.
2. Creates Training → Schedules players, sends invites.
3. Evaluates Players → Enters post-training ratings.
4. Gets AI Insights → Injury risks, rest needs, performance trends.
5. Views Dashboard Reports → Adjusts training based on data.
Player Journey
1. Homepage→ Checks upcoming sessions & past performance.
2. Reports Fatigue → Logs energy levels and injuries.
3. Receives AI Recommendations → Adjusts rest & training.
4. Views Performance Reports → Tracks improvement areas.
 
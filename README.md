# NBA Analysis
NBA SQL Analytics Project
📌 Project Overview

This project is a SQL analytics portfolio project based on NBA player statistics (Season 2024/25).
It demonstrates the ability to perform data exploration, advanced queries, and analytics using SQL, including:
Window functions
Common Table Expressions (CTEs)
Subqueries
Aggregations & conditional logic

The analysis is done on a dataset of NBA games with player statistics (points, rebounds, assists, game score, etc.).

📊 Key Analyses & Queries
## 1. Team Points Analysis

Total games played, points scored, and average points per game.
Breakdown of points in wins vs. losses.
### Team Performance Summary
Sample Output:
| Team | Total Games | Total Points | Avg Game Points | Points at Wins | Points at Losses |
|------|-------------|--------------|-----------------|----------------|------------------|
| CLE  | 52          | 6366         | 122.42          | 5231           | 1135             |
| MEM  | 51          | 6312         | 123.76          | 4493           | 1819             |
| DEN  | 52          | 6284         | 120.85          | 4186           | 2098             |
| BOS  | 52          | 6097         | 117.25          | 4336           | 1761             |
| CHI  | 52          | 6067         | 116.67          | 2728           | 3339             |

Code:


```sql
SELECT 
    tm AS Team,
    COUNT(DISTINCT MDate) AS Total_Games,
    SUM(pts) AS Total_Points,
    ROUND(SUM(pts)/COUNT(DISTINCT MDate), 2) AS Avg_game_points,
    SUM(CASE WHEN res = 'W' THEN pts END) AS Points_at_wins,
    SUM(CASE WHEN res = 'L' THEN pts END) AS Points_at_Loses
FROM player_stats
GROUP BY tm
ORDER BY Total_Points DESC;
```
ףף


## 2. Cumulative Points for Players (Boston Celtics Example)

Window function tracking cumulative points by game date for each player.
# Cumulative Points per Player
### Example Output (Jayson Tatum)

| Player        | Pts | Match Date | Cumulative Points |
|---------------|-----|------------|-------------------|
| Jayson Tatum  | 34  | 2024-10-24 | 34                |
| Jayson Tatum  | 25  | 2024-10-26 | 59                |
| Jayson Tatum  | 28  | 2024-10-28 | 87                |
| Jayson Tatum  | 23  | 2024-10-30 | 110               |
| Jayson Tatum  | 31  | 2024-11-02 | 141               |
| Jayson Tatum  | 27  | 2024-11-04 | 168               |


Code:
```sql
SELECT player,pts,mdate, 
SUM(pts) OVER(partition by player order by mdate) as cumulative_points
FROM player_stats
WHERE tm = "BOS";
```

## 3. Overperformance vs. Seasonal Average
   
Detects games where a player exceeded their seasonal average points by 20% or more.
# Player Performance Example

| Player          | Team | Opposing Team | Match Date  | Points | Avg Points per Game |
|-----------------|------|---------------|------------|--------|-------------------|
| Jayson Tatum    | BOS  | NYK           | 2024-10-22 | 37     | 26.55             |
| Anthony Davis   | LAL  | MIN           | 2024-10-22 | 36     | 25.74             |
| Derrick White   | BOS  | NYK           | 2024-10-22 | 24     | 16.10             |
| Jrue Holiday    | BOS  | NYK           | 2024-10-22 | 18     | 10.98             |
| Miles McBride   | NYK  | BOS           | 2024-10-22 | 22     | 9.15              |

Code: 
```sql
WITH players_avg_points AS
(select player, tm as Team ,ROUND(avg(pts),2) AS avg_points_per_game
from player_stats
GROUP BY player, tm
order by avg_points_per_game DESC)
SELECT ps.player, ps.tm AS Team, ps.opp AS Opposing_Team,
ps.mdate AS Match_Date, ps.pts AS Points, pap.avg_points_per_game
FROM player_stats ps JOIN players_avg_points pap 
ON ps.player = pap.player 
WHERE ps.pts > pap.avg_points_per_game*1.2;
```

## 4. Player Impact Analysis
Measures player contribution by comparing average points & game score in wins vs. losses.
# Player Impact Analysis

| Player          | Win Rate (%) | W/L Avg Points | Impact Type       |
|-----------------|-------------|----------------|------------------|
| Jayson Tatum    | 69.4        | 1.17           | Winner           |
| Anthony Davis   | 57.1        | 1.23           | Clutch Winner    |
| Derrick White   | 71.4        | 1.04           | Winner           |
| Jrue Holiday    | 70.5        | 1.44           | Clutch Winner    |
| Miles McBride   | 68.3        | 1.19           | Winner           |
| Rui Hachimura   | 59.5        | 1.31           | Clutch Winner    |

Code:
```sql
WITH player_impact AS
(SELECT Player,
           COUNT(*) as total_games,
           SUM(CASE WHEN res = 'W' THEN 1 END) AS wins,
           ROUND(AVG(CASE WHEN res= 'W' THEN pts END),1) AS avg_points_at_win,
           ROUND(AVG(CASE WHEN res= 'L' THEN pts END),1) AS avg_points_at_lose,
           ROUND(AVG(CASE WHEN res= 'W' THEN gmsc END),1) AS avg_score_at_win,
           ROUND(AVG(CASE WHEN res= 'L' THEN gmsc END),1) AS avg_score_at_lose
FROM player_stats
GROUP BY Player
HAVING total_games >= 10)

SELECT player, 
ROUND((wins/total_games)*100 ,1) AS win_rate,
ROUND((avg_points_at_win / avg_points_at_lose),2) AS 'W/L_avg_points',
CASE 
	WHEN (avg_points_at_win / avg_points_at_lose) > 1.2 THEN 'Clucth Winner'
    WHEN (avg_points_at_win / avg_points_at_lose) > 1 THEN 'Winner'
    WHEN (avg_points_at_win / avg_points_at_lose) >= 0.95 THEN 'Consistent'
    ELSE 'Struggles in Wins'
END AS impact_type
FROM player_impact
WHERE (avg_points_at_win / avg_points_at_lose) IS NOT NULL;
```

Classifies players into categories: Clutch Winner, Winner, Consistent, Struggles in Wins.


## 5. Consistency Analysis (Game Score-Based)
   
Evaluates volatility and consistency of performance.
Labels players as Very Consistent, Consistent, High Ceiling, or Inconsistent.
# Player Consistency Analysis

| Player                   | Total Games | Avg Game Score | Volatility | Bad Games | Great Games | Bad Game (%) | Great Game (%) | Player Type   |
|--------------------------|------------|----------------|------------|-----------|-------------|--------------|----------------|---------------|
| Nikola Jokić             | 46         | 30.57          | 7.89       | 0         | 42          | 0.0          | 91.3           | High Ceiling  |
| Giannis Antetokounmpo    | 42         | 26.38          | 7.88       | 0         | 36          | 0.0          | 85.7           | High Ceiling  |
| Shai Gilgeous-Alexander  | 50         | 26.74          | 8.52       | 0         | 37          | 0.0          | 74.0           | High Ceiling  |
| Luka Dončić              | 22         | 22.7           | 9.51       | 0         | 13          | 0.0          | 59.1           | High Ceiling  |
| Victor Wembanyama        | 43         | 20.67          | 8.27       | 0         | 24          | 0.0          | 55.8           | High Ceiling  |

Code: 
```sql
 WITH consistency_analysis AS (
    SELECT Player,
           COUNT(*) as total_games,
           ROUND(AVG(GmSc),2) as avg_game_score,
           STDDEV(GmSc) as game_score_std,
           COUNT(CASE WHEN GmSc < 5 THEN 1 END) as bad_games,
           COUNT(CASE WHEN GmSc > 20 THEN 1 END) as great_games
    FROM player_stats
    GROUP BY Player
    HAVING total_games >= 15
)

SELECT player, total_games, avg_game_score,
       ROUND(game_score_std, 2) as volatility,
       bad_games, great_games,
       ROUND(bad_games * 100.0 / total_games, 1) as bad_game_percentage,
       ROUND(great_games * 100.0 / total_games, 1) as great_game_percentage,
       CASE 
           WHEN game_score_std < 5 AND bad_games <= 2 THEN 'Very Consistent'
           WHEN game_score_std < 7 AND bad_games <= 4 THEN 'Consistent'
           WHEN great_games >= 8 THEN 'High Ceiling'
           ELSE 'Inconsistent'
       END as player_type
FROM consistency_analysis
ORDER BY bad_game_percentage ASC, great_game_percentage DESC;
```

## 6. Performance Trend by Month (Deni Avdija Example)

Uses window functions (LAG) to compare performance month-over-month.
Calculates percentage changes in average points.
# Player Monthly Performance (Deni Avdija)

| Player       | Team | Month | Year | Avg Month Performance | Previous Month Performance | Month Change (%) |
|--------------|------|-------|------|----------------------|---------------------------|-----------------|
| Deni Avdija  | POR  | 10    | 2024 | 10.00                | 0.00                      | -               |
| Deni Avdija  | POR  | 11    | 2024 | 11.87                | 10.00                     | 118.70          |
| Deni Avdija  | POR  | 12    | 2024 | 16.75                | 11.87                     | 141.11          |
| Deni Avdija  | POR  | 1     | 2025 | 18.31                | 16.75                     | 109.31          |
| Deni Avdija  | POR  | 2     | 2025 | 12.25                | 18.31                     | 66.90           |

Code:
```sql
WITH player_avg_performance_by_month AS
(SELECT distinct player, tm , month(mdate) AS mnth, year(mdate) AS yr,
ROUND(AVG(pts) OVER(PARTITION BY month(mdate)),2) AS avg_month_performance
from player_stats
WHERE player = 'Deni Avdija'
ORDER BY yr, mnth),

player_performance_by_month AS 
(SELECT *, 
LAG(avg_month_performance,1,0) OVER (ORDER BY yr,mnth) AS previous_month_performance
FROM  player_avg_performance_by_month)
SELECT player, tm AS Team, mnth AS 'Month', yr AS 'Year',
avg_month_performance, previous_month_performance,
ROUND(((avg_month_performance/previous_month_performance) * 100),2)  AS month_change_percent
from player_performance_by_month;
```

🚀 Key SQL Features Demonstrated

Window Functions: SUM() OVER, LAG(), AVG() OVER

CTEs (WITH clauses): Used for multi-step analysis

Conditional Aggregations: CASE WHEN inside SUM/COUNT

Statistical Functions: STDDEV for volatility analysis

Data Classification: Custom player categories based on performance metrics

📈 Insights Example

Some teams score significantly more in wins compared to losses.
Players can be evaluated not only by scoring, but also by consistency and impact in team wins.
Month-over-month analysis provides insights into player development trends.

🎯 Project Value

This project shows the ability to:

Work with complex SQL queries.

Apply advanced analytics techniques beyond simple aggregations.

Derive meaningful sports insights from raw data.

Build a portfolio-ready SQL project with practical use cases.

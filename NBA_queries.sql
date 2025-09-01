USE nba_project;

-- Teams  points analysis
SELECT tm AS Team,
COUNT(distinct MDate) AS Total_Games,
SUM(pts) AS Total_Points,
ROUND(SUM(pts)/COUNT(distinct MDate),2) AS Avg_game_points,
SUM(CASE WHEN res = 'W' THEN pts END) AS Points_at_wins,
SUM(CASE WHEN res = 'L' THEN pts END) AS Points_at_Loses
FROM player_stats
GROUP BY tm
ORDER BY Total_Points DESC;

-- Cumulative points for Boston players 
SELECT player,pts,mdate, 
SUM(pts) OVER(partition by player order by mdate) as cumulative_points
FROM player_stats
WHERE tm = "BOS";

-- How many triple-double each player has
WITH triple_doubles AS 
(SELECT player, pts, trb, ast
from player_stats
where pts >= 10 AND trb >= 10 AND ast >= 10)

SELECT player, count(*) AS total_triple_doubles
FROM triple_doubles
GROUP BY player
ORDER BY total_triple_doubles DESC;

--  Games that a player in the game exceeded his seasonal average by 20% or more.
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

-- Player impact analysis
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


-- Consistency analysis for players using game score
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


-- Player performance (Deni Avdija)  by month change
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






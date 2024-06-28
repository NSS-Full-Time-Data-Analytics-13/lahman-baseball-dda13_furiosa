--1. What range of years for baseball games played does the provided database cover? 
SELECT MIN(yearid), MAX(yearid)
FROM teams
;
--1871 to 2016



--2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
SELECT CONCAT(namegiven, ' "', namefirst, '" ', namelast) AS full_name
	, teams.name AS team_name
	, COUNT(*) AS games_played
FROM appearances LEFT JOIN people USING(playerid)
				 LEFT JOIN teams USING(teamid)
WHERE height = 43 
	AND appearances.yearid = teams.yearid
GROUP BY full_name, team_name
;
--Edward Carl ""Eddie"" Gaedel	St. Louis Browns	1



--3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
SELECT CONCAT(namegiven, ' ', namelast) AS full_name
	, SUM(salary)::numeric::money AS total_salary
FROM salaries LEFT JOIN people USING(playerid)
WHERE playerid IN (SELECT DISTINCT playerid
					FROM collegeplaying INNER JOIN schools USING(schoolid)
					WHERE schoolname = 'Vanderbilt University')
GROUP BY full_name
ORDER BY total_salary DESC
;
--"David Taylor Price"	"$81,851,296.00"


--5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
WITH so_hr_decades AS (
	SELECT playerid
		, yearid
	    , so/g AS so_g
		, hr/g AS hr_g
		, CASE WHEN yearid >= 1920 AND yearid <1930 THEN '1920s'
			   WHEN yearid >= 1930 AND yearid <1940 THEN '1930s'
			   WHEN yearid >= 1940 AND yearid <1950 THEN '1940s'
			   WHEN yearid >= 1950 AND yearid <1960 THEN '1950s'
			   WHEN yearid >= 1960 AND yearid <1970 THEN '1960s'
			   WHEN yearid >= 1970 AND yearid <1980 THEN '1970s'
			   WHEN yearid >= 1980 AND yearid <1990 THEN '1980s'
			   WHEN yearid >= 1990 AND yearid <2000 THEN '1990s'
			   WHEN yearid >= 2000 AND yearid <2010 THEN '2000s'
			   WHEN yearid >= 2010 AND yearid <2020 THEN '2010s'
		  END AS decade
	FROM pitching
	ORDER BY decade NULLS LAST)

SELECT decade
	, ROUND(AVG(so_g),2) as avg_strikeouts
	, ROUND(AVG(hr_g),2) as avg_homeruns
FROM so_hr_decades
GROUP BY decade
;



--7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. 
(SELECT yearid, teamid, w AS total_wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 
	AND wswin = 'N'
	AND yearid <> 1981
ORDER BY total_wins DESC
LIMIT 1)
UNION
(SELECT yearid, teamid, w AS total_wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 
	AND wswin = 'Y'
	AND yearid <> 1981
ORDER BY total_wins
LIMIT 1)
;
--2001	"SEA"	116
--In 1981 LAN won with 63 wins. Due to a players' strike 1981 had much fewer games.
--2006	"SLN"	83 This is the result when 1981 is removed

--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
WITH most_wins AS(
	SELECT yearid
		, teamid
		, w AS total_wins
		, CASE WHEN w = (SELECT MAX(w)
						 FROM teams AS t2
						 WHERE t1.yearid = t2.yearid
						 GROUP BY yearid)
			   THEN 'T'
			   ELSE 'F' 
		  	   END AS max_wins
	FROM teams AS t1
	WHERE yearid BETWEEN 1970 AND 2016 
		AND wswin = 'Y'
	ORDER BY yearid
)
SELECT COUNT(*) AS n_most_wins_won
	, (SELECT COUNT(*) FROM most_wins) AS total_years
	, CONCAT((100 * COUNT(*)/(SELECT COUNT(*) FROM most_wins))::text, '%') AS percent_mww
FROM most_wins
WHERE max_wins = 'T'
;
--Number of times most wins won: 12 in 46 years or 26%



--9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
SELECT 	a.lgid
	, a.yearid
	, CONCAT(p.namegiven, ' ', p.namelast) AS full_name
	, t.name
FROM awardsmanagers AS a LEFT JOIN people AS p USING(playerid)
	LEFT JOIN managers AS m USING(playerid, yearid)
	LEFT JOIN teams AS t USING(teamid, yearid)
WHERE awardid = 'TSN Manager of the Year'
	AND a.lgid IN('NL', 'AL')
ORDER BY a.lgid, a.yearid
;

--11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

--13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?
WITH pitcher_stats AS (
	SELECT throws
		, CASE WHEN playerid IN(SELECT playerid
							FROM awardsplayers
							WHERE awardid ILIKE '%cy%')
				THEN TRUE ELSE FALSE END AS won_cy
		, CASE WHEN playerid IN(SELECT playerid 
							FROM halloffame
							WHERE inducted = 'Y')
				THEN TRUE ELSE FALSE END AS in_hof
	FROM people
	WHERE playerid IN (SELECT DISTINCT playerid
						FROM pitching)
		AND throws IN('L', 'R')
)
(SELECT DISTINCT 'Lefties' AS handed
	, ROUND(100.0 * (SELECT COUNT(*) FROM pitcher_stats WHERE throws = 'L') / (SELECT COUNT(*) FROM pitcher_stats),2) AS percent_pit
	, ROUND(100.0 * (SELECT COUNT(*) FROM pitcher_stats WHERE throws = 'L' AND won_cy) / (SELECT COUNT(*) FROM pitcher_stats WHERE throws = 'L'),2) AS percent_woncy
	, ROUND(100.0 * (SELECT COUNT(*) FROM pitcher_stats WHERE throws = 'L' AND in_hof) / (SELECT COUNT(*) FROM pitcher_stats WHERE throws = 'L'),2) AS percent_hof
FROM pitcher_stats)
UNION
(SELECT DISTINCT 'Righties' AS handed
	, ROUND(100.0 * (SELECT COUNT(*) FROM pitcher_stats WHERE throws = 'R') / (SELECT COUNT(*) FROM pitcher_stats),2) AS percent_pit
	, ROUND(100.0 * (SELECT COUNT(*) FROM pitcher_stats WHERE throws = 'R' AND won_cy) / (SELECT COUNT(*) FROM pitcher_stats WHERE throws = 'R'),2) AS percent_woncy
	, ROUND(100.0 * (SELECT COUNT(*) FROM pitcher_stats WHERE throws = 'R' AND in_hof) / (SELECT COUNT(*) FROM pitcher_stats WHERE throws = 'R'),2) AS percent_hof
FROM pitcher_stats)
UNION
(SELECT DISTINCT 'All' AS handed
	, (SELECT COUNT(*) FROM pitcher_stats) AS percent_pit
	, ROUND(100.0 * (SELECT COUNT(*) FROM pitcher_stats WHERE won_cy) / (SELECT COUNT(*) FROM pitcher_stats),2) AS percent_woncy
	, ROUND(100.0 * (SELECT COUNT(*) FROM pitcher_stats WHERE in_hof) / (SELECT COUNT(*) FROM pitcher_stats),2) AS percent_hof
FROM pitcher_stats)
;
--Lefties make up 27% of pitchers and are more likely to win the Cy Young award but less likely to enter the Hall of Fame.
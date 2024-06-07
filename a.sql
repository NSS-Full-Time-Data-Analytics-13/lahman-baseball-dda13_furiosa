SELECT Min (yearid) from appearances;
	SELECT Max (yearid) from appearances;
------------
------ Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
select playerid, namegiven,height
from people 
group by playerid, namegiven
order by height;


---Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary 
---they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT CONCAT(namegiven, ' ', namelast) AS full_name
	, SUM(salary)::numeric::money AS total_salary
FROM salaries LEFT JOIN people USING(playerid)
WHERE playerid IN (SELECT DISTINCT playerid
					FROM collegeplaying INNER JOIN schools USING(schoolid)
					WHERE schoolname = 'Vanderbilt University')
GROUP BY full_name
ORDER BY total_salary DESC;
---5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. 
---Do you see any trends?

WITH a AS (SELECT
    playerid,
    yearid,
    so/g as so_g,
CASE WHEN yearid BETWEEN '1920' AND '1929' THEN '1920s'
WHEN yearid BETWEEN '1930' AND '1939' THEN '1930s'
WHEN yearid BETWEEN '1940' AND '1949' THEN '1940s'
WHEN yearid BETWEEN '1950' AND '1959' THEN '1950s'
WHEN yearid BETWEEN '1960' AND '1969' THEN '1960s'
WHEN yearid BETWEEN '1970' AND '1979' THEN '1970s'
WHEN yearid BETWEEN '1980' AND '1989' THEN '1980s'
WHEN yearid BETWEEN '1990' AND '1999' THEN '1990s' 
WHEN yearid BETWEEN '2000' AND '2009' THEN '2000s'
WHEN yearid BETWEEN '2010' AND '2019' THEN '2010s'
WHEN yearid BETWEEN '2020' AND '2029' THEN '2020s'  END AS decade
FROM pitching
ORDER BY decade NULLS LAST)

SELECT decade, ROUND(AVG(so_g),2) as strikeouts
FROM a 
GROUP BY decade 



----- . Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016
----(where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. 
------Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.


(SELECT t.name,
		t.park,
		h.attendance,
		h.attendance/h.games AS avg_attendance,
		'largest attendance' as size
FROM homegames AS h
JOIN teams AS t ON h.team = t.teamid
WHERE h.year = 2016
	AND t.yearid = 2016
	AND h.games >= 10
GROUP BY h.attendance,
		t.name,
		t.park,
		h.games
ORDER BY avg_attendance DESC
LIMIT 5)
UNION
(SELECT  t.name,
		t.park,
		h.attendance,
		h.attendance/h.games AS avg_attendance,
		'lowest attendance' as size
FROM homegames AS h
JOIN teams AS t ON h.team = t.teamid
WHERE h.year = 2016
	AND t.yearid = 2016
	AND h.games >= 10
GROUP BY h.attendance,
		 t.name,
		 t.park,
		 h.games
ORDER BY avg_attendance
LIMIT 5)
ORDER BY avg_attendance DESC;



------ 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, 
------and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

with a as (with old as (select playerid,namefirst, namelast, debut,finalgame from people where debut <= '2006-01-01')
select yearid, namefirst, namelast, teamid, debut, hr, (select max(hr) from batting as b2 where b.playerid = b2.playerid group by playerid)
from batting as b 
join old using (playerid)
	where yearid = '2016' and hr >=1)
	select * from a
	where hr = max



----


WITH a AS (SELECT throws, COUNT(playerid) AS hand
FROM people
INNER JOIN pitching USING (playerid)
WHERE throws = 'L'
GROUP BY throws
UNION ALL
SELECT throws, COUNT(playerid) AS hand
FROM people
INNER JOIN pitching USING (playerid)
WHERE throws = 'R'
GROUP BY throws)

SELECT throws, hand, (SELECT SUM(hand) FROM a) AS total_players
FROM a

select * FROM pitching
INNER JOIN people USING (playerid)
where playerid in (select distinct (playerid )from pitching )


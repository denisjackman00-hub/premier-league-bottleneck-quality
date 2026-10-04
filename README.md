# premier-league-bottleneck-quality
Do Premier League teams win because of their best players, or because their weakest regular players are good enough?

This repository contains the paper and R code for my final-year economics research project at University College Dublin (ECON30620, supervised by Kevin Denny). It uses ten seasons of player-level data (2015/16 to 2024/25) to test two competing theories of team production: superstar theory and O-Ring (weak-link) theory. It also asks why the same clubs keep winning.

Key findings
A squad's weakest attacking regulars are the strongest predictor of results. A one-standard-deviation improvement in the 20th-percentile attacking player is associated with about +12 points over a season. That is roughly the gap between mid-table and the top-four race.
The superstar effect disappears once you account for squad depth. On its own, the quality of a club's top three attackers predicts points. Put both measures in the same model and the superstar coefficient drops to 0.078 (p = 0.27), while the bottleneck coefficient stays at 0.292 (p < 0.01).
Wages work mainly through squad quality. Wage bill alone explains 54% of the variation in points per game. Most of that relationship runs through the quality of the players those wages buy.
Dominance persists because squad depth persists. About 80% of a club's points advantage carries over to the next season. Controlling for bottleneck quality cuts that persistence coefficient from 0.54 to 0.22.
Richer clubs buy quality throughout the squad, not just at the top (sorting coefficient 0.024, p < 0.001). Money becomes squad depth, depth becomes points, and points bring in more money.

Main results

Dependent variable: points per game. Club-season panel, N = 136. Season fixed effects in all models; standard errors clustered by club.

	(1) Wages	(3) Bottleneck	(4) Superstar	(5) Both	(6) Both + Club FE
Log wage bill	0.686***	0.286***	0.296***	0.169*	0.167
Bottleneck quality (p20)		0.316***		0.292***	0.261***
Superstar quality (top 3)			0.285***	0.078	0.062
R²	0.541	0.697	0.680	0.714	0.762

*** p<0.01, ** p<0.05, * p<0.10. Quality measures are standardised within season.

Robustness: the bottleneck result holds when the bottleneck is defined as the 10th percentile or as the weakest player, under alternative superstar definitions (top 1 or top 5 players), when the playing-time threshold is lowered from 900 to 450 minutes, and with club fixed effects.

Method

1. Player quality index. For every outfield player with at least 900 minutes in a season, I take four per-90 attacking metrics from Understat: non-penalty xG, xA, xGChain and xGBuildup. Each is converted to a z-score within position and season, and the four are averaged. The average is then measured against a position-specific replacement level (the 20th percentile) and passed through a logistic function, giving a quality score q between 0 and 1.

2. Validation. If q captures real productivity, the market should pay for it. In player wage regressions, moving from replacement level to elite is associated with wages about 75% higher (coefficient 0.748, p < 0.01).

3. Squad distribution measures. The player scores are aggregated to each club-season:

p20_q: bottleneck quality, the 20th percentile of the squad
top3_q: superstar quality, the mean of the top three players
avg_q: average squad quality

4. Horse-race regressions. Points per game is regressed on wage bill plus each measure separately, then on both together, with club-clustered standard errors.

5. Persistence and sorting. A lagged panel tests how much of last season's performance carries into this season, and a sorting regression tests whether richer clubs employ better players throughout the squad.

Data
Source	Used for
Understat	Player npxG, xA, xGChain, xGBuildup
FBref	League points and match outcomes
Capology	Player salaries and club wage bills

The raw data is not included in this repository because of the source sites' terms of use. The sample covers 2,937 player-seasons and 136 club-seasons. Newly promoted clubs drop out more often because Capology's wage coverage for them is incomplete.

Running the code

The analysis is in Final_Rscript_Researchpaper.R. It:

installs any missing packages, including dplyr, tidyr, readxl, sandwich, ggplot2 and modelsummary
checks that the expected columns are present in the input data
builds the quality index and the club panel
runs the wage, horse-race, robustness, persistence and sorting models
exports the regression tables (HTML) and figures

To reproduce the results, collect the player data and the club wage panel from the sources above, update the file paths at the top of the script, and run it from start to finish.

Limitations
Attack only. The quality index uses attacking metrics, so it says nothing about defending, pressing or off-ball work. No public dataset covers those at the player level across ten seasons.
Associations, not causal effects. Performance, wages and squad quality are determined together. The bottleneck and superstar measures are also highly correlated (r = 0.85), so the results should be read as robust associations.
Different from earlier work. These results partly contrast with Szymanski & Wilkinson (2016, Research in Economics), who found more support for superstar theory using transfer fees and 1992–2014 data.
Next steps
Out-of-sample test on the 2025/26 season
Add defensive and pressing contributions using event or tracking data, so the weak-link idea can be tested at both ends of the pitch
Author

Denis Jackman, BSc Economics (minor in Mathematical Sciences), University College Dublin

Interested in football analytics, sports economics and applied econometrics. Feel free to get in touch: LinkedIn

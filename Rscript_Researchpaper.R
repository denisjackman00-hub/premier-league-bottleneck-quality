#Research Paper R script
# Data from years- 2015-16 to 2024-25
# REVISED SCRIPT
pkgs <- c("readxl", "dplyr", "tidyr", "stringr", "lmtest", "sandwich", "ggplot2", "modelsummary", "tibble")
# Before anything else, just list out every package you're going to need — readxl, dplyr, tidyr, the sandwich stuff 
# for standard errors, ggplot2, modelsummary — and write a little loop that installs whatever's missing. That way the 
# script just works on any machine without manually hunting down missing libraries
to_install <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
if(length(to_install) > 0) install.packages(to_install)
library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(lmtest)
library(sandwich)
library(ggplot2)
library(modelsummary)
library(tibble)
# Pull in the player-level spreadsheet with wages and stats. Also check that the club-level panel, wages_df, 
# is already in the environment — if it's not there, just stop immediately and tell yourself to load it. 
# Don't let the script silently run on nothing
wages_stats <- read_excel("C:/Users/denis/OneDrive/Desktop/wage_panel_project/wages_stats.xlsx")
wages_stats <- as.data.frame(wages_stats)
if(!exists("wages_df")) {stop("wages_df is not loaded. Load your club-season dataset first.")}
wages_df <- as.data.frame(wages_df)
# Building Dummy variables for European competition participation
# categories are UCL, UEL, UECL
# You're going to need to know who was in the Champions League, 
# Europa League, and Conference League each season. There's no clean dataset for this, 
# Maybe get chatgpt to do it out, to save time
# just go off 1st to 4th finish is champions league and 5th is europa. And then change it if any outliers
# 1B) UEFA participation map
europe_map <- tibble::tribble(
  ~season,   ~team,                    ~ucl, ~uel, ~uecl,
  "2015-16", "Arsenal",                  1,    0,     0,
  "2015-16", "Chelsea",                  1,    0,     0,
  "2015-16", "Manchester City",          1,    0,     0,
  "2015-16", "Manchester United",        1,    0,     0,
  "2015-16", "Tottenham",                0,    1,     0,
  "2015-16", "Liverpool",                0,    1,     0,
  "2016-17", "Leicester",                1,    0,     0,
  "2016-17", "Arsenal",                  1,    0,     0,
  "2016-17", "Manchester City",          1,    0,     0,
  "2016-17", "Tottenham",                1,    0,     0,
  "2016-17", "Manchester United",        0,    1,     0,
  "2016-17", "Southampton",              0,    1,     0,
  "2017-18", "Chelsea",                  1,    0,     0,
  "2017-18", "Liverpool",                1,    0,     0,
  "2017-18", "Manchester City",          1,    0,     0,
  "2017-18", "Manchester United",        1,    0,     0,
  "2017-18", "Arsenal",                  0,    1,     0,
  "2017-18", "Everton",                  0,    1,     0,
  "2018-19", "Liverpool",                1,    0,     0,
  "2018-19", "Manchester City",          1,    0,     0,
  "2018-19", "Manchester United",        1,    0,     0,
  "2018-19", "Tottenham",                1,    0,     0,
  "2018-19", "Arsenal",                  0,    1,     0,
  "2018-19", "Chelsea",                  0,    1,     0,
  "2018-19", "Burnley",                  0,    1,     0,
  "2019-20", "Chelsea",                  1,    0,     0,
  "2019-20", "Liverpool",                1,    0,     0,
  "2019-20", "Manchester City",          1,    0,     0,
  "2019-20", "Tottenham",                1,    0,     0,
  "2019-20", "Arsenal",                  0,    1,     0,
  "2019-20", "Manchester United",        0,    1,     0,
  "2019-20", "Wolverhampton Wanderers",  0,    1,     0,
  "2020-21", "Chelsea",                  1,    0,     0,
  "2020-21", "Liverpool",                1,    0,     0,
  "2020-21", "Manchester City",          1,    0,     0,
  "2020-21", "Manchester United",        1,    0,     0,
  "2020-21", "Arsenal",                  0,    1,     0,
  "2020-21", "Leicester",                0,    1,     0,
  "2020-21", "Tottenham",                0,    1,     0,
  "2021-22", "Chelsea",                  1,    0,     0,
  "2021-22", "Liverpool",                1,    0,     0,
  "2021-22", "Manchester City",          1,    0,     0,
  "2021-22", "Manchester United",        1,    0,     0,
  "2021-22", "Leicester",                0,    1,     0,
  "2021-22", "West Ham",                 0,    1,     0,
  "2021-22", "Tottenham",                0,    0,     1,
  "2022-23", "Chelsea",                  1,    0,     0,
  "2022-23", "Liverpool",                1,    0,     0,
  "2022-23", "Manchester City",          1,    0,     0,
  "2022-23", "Tottenham",                1,    0,     0,
  "2022-23", "Arsenal",                  0,    1,     0,
  "2022-23", "Manchester United",        0,    1,     0,
  "2022-23", "West Ham",                 0,    0,     1,
  "2023-24", "Arsenal",                  1,    0,     0,
  "2023-24", "Manchester City",          1,    0,     0,
  "2023-24", "Manchester United",        1,    0,     0,
  "2023-24", "Newcastle United",         1,    0,     0,
  "2023-24", "Brighton",                 0,    1,     0,
  "2023-24", "Liverpool",                0,    1,     0,
  "2023-24", "West Ham",                 0,    1,     0,
  "2023-24", "Aston Villa",              0,    0,     1,
  "2024-25", "Arsenal",                  1,    0,     0,
  "2024-25", "Aston Villa",              1,    0,     0,
  "2024-25", "Liverpool",                1,    0,     0,
  "2024-25", "Manchester City",          1,    0,     0,
  "2024-25", "Manchester United",        0,    1,     0,
  "2024-25", "Tottenham",                0,    1,     0,
  "2024-25", "Chelsea",                  0,    0,     1)
# General checks and cleaning
# Before touching the data, write out the column names you expect to exist in both datasets and check they're actually there. 
# Print row counts too. If something's broken i might want to know immediately, not three hundred lines later.
# check whether the necessary columns exist at the player level and then load only the necessary variables in a new dataset
needed_player <- c("player_name", "time", "npxG", "xA", "xGChain", "xGBuildup", "team_title", "season", "Pos", "Age", "annual_eur")
#check for missing data on player level, try and see if chatGPT has a way of knowing whther there is missing data
# I want to start completely fresh so I strip out any old computed columns that might be hanging around from earlier versions of the data
# I also need to handle players who moved clubs mid-season
# those rows need to be split so that each player-club combination gets treated as its own observation
missing_player <- setdiff(needed_player, names(wages_stats))
if(length(missing_player) > 0) {stop(paste("Missing player-level columns:", paste(missing_player, collapse = ", ")))}
# Also, check club level data for the necessary variables
needed_club <- c("team", "season", "Pts", "log_wage_annual")
missing_club <- setdiff(needed_club, names(wages_df))
if(length(missing_club) > 0) {stop(paste("Missing club-level columns in wages_df:", paste(missing_club, collapse = ", ")))}

# 3) Clean player data
# now create a complete dataset just for player level data, combining wages and player metrics data
drop_cols <- c("minutes", "npxG_p90", "xA_p90", "xGChain_p90", "xGBuildup_p90", "z_npxG_p90", "z_xA_p90", "z_xGChain_p90", "z_xGBuildup_p90", "prod", "prod_raw", "prod_p90", "rep_prod_p90", "par_p90", "par_season", "par_z", "q", "q_z", "pos4", "team_wage", "team_wage_loo", "club_log_wage", "lw_c", "q_c", "Age2")
df0 <- wages_stats %>%
select(-any_of(drop_cols)) %>%
separate_rows(team_title, sep = ",\\s*") %>%
mutate(team_title = trimws(team_title), time = as.numeric(time), minutes = as.numeric(time), npxG = as.numeric(npxG), xA = as.numeric(xA), xGChain = as.numeric(xGChain), xGBuildup = as.numeric(xGBuildup), Age = as.numeric(Age), annual_eur = as.numeric(annual_eur), season = as.character(season), Pos = as.character(Pos))


# 4) Collapse positions into stable groups
# The raw position strings in the data are inconsistent and messy
# I want to reduce everything down to four clean buckets — goalkeeper, defender, midfielder and attacker
# so that all the comparisons I make later are between players in similar roles
map_pos4 <- function(pos_string) {pos_string <- toupper(pos_string)
  if(is.na(pos_string)) return(NA_character_)
  if(str_detect(pos_string, "GK")) return("GK")
  if(str_detect(pos_string, "DF|CB|LB|RB|WB")) return("DEF")
  if(str_detect(pos_string, "MF|DM|CM|AM")) return("MID")
  if(str_detect(pos_string, "FW|ST|CF|LW|RW")) return("ATT")
  return(NA_character_)}

df0 <- df0 %>%
mutate(pos4 = vapply(Pos, map_pos4, FUN.VALUE = character(1)))

# 5) Outfield offensive quality metric
# Exclude GKs and build broad attacking contribution
# Build the offensive quality metric without goalkeepers
# This is the heart of the whole project
# I want to measure how much offensive value each outfield player contributes per 90 minutes
# using four metrics — non-penalty expected goals, expected assists, expected goals chain and expected goals buildup
# I z-score each one within season and position so I am always comparing players to their peers
# then I average the four z-scores into a single offensive productivity number
# Goalkeepers get dropped entirely here because they have nothing meaningful to contribute to an offensive metric

df0 <- df0 %>%
filter(!is.na(pos4), pos4 != "GK")
print(table(df0$pos4, useNA = "ifany"))

df0 <- df0 %>%
mutate(npxG_p90 = ifelse(minutes > 0, npxG / (minutes / 90), NA_real_), xA_p90 = ifelse(minutes > 0, xA / (minutes / 90), NA_real_), xGChain_p90 = ifelse(minutes > 0, xGChain / (minutes / 90), NA_real_), xGBuildup_p90 = ifelse(minutes > 0, xGBuildup / (minutes / 90), NA_real_)) %>%
group_by(season, pos4) %>%
mutate( z_npxG_p90 = as.numeric(scale(npxG_p90)), z_xA_p90 = as.numeric(scale(xA_p90)), z_xGChain_p90 = as.numeric(scale(xGChain_p90)), z_xGBuildup_p90 = as.numeric(scale(xGBuildup_p90))) %>%
ungroup() %>%
mutate(prod_p90 = rowMeans(cbind(z_npxG_p90, z_xA_p90, z_xGChain_p90, z_xGBuildup_p90), na.rm = TRUE))
print(summary(df0$prod_p90))

# 6) Keep regular outfield players for replacement-level estimation
# Define regular players and set a replacement level
# I only want players who played at least 900 minutes because part-time appearances are too noisy to be meaningful
# Within each position group I find the 20th percentile of offensive productivity
# That becomes my replacement level — the baseline of what any club could get from a freely available player
df_reg <- df0 %>%
filter(!is.na(minutes), minutes >= 900, !is.na(pos4), !is.na(prod_p90))
# 7- Replacement level by broad outfield position
rep_tbl <- df_reg %>%
group_by(pos4) %>%
summarise(rep_prod_p90 = quantile(prod_p90, 0.20, na.rm = TRUE), n_pos = n(), .groups = "drop")
print(rep_tbl)
df_reg <- df_reg %>%
left_join(rep_tbl %>% select(pos4, rep_prod_p90), by = "pos4")

# 8) Build PAR and bounded offensive quality index
# Build PAR and create the bounded quality index q
# I subtract the replacement level from each player's productivity to get their performance above replacement
# I then scale that within season and position and pass it through the logistic function
# so that q always sits between 0 and 1
# This willgive me a clean intuitive quality score for every outfield player in the sample
df_reg <- df_reg %>%
mutate(par_p90 = prod_p90 - rep_prod_p90, par_season = par_p90 * (minutes / 90)) %>%
group_by(season, pos4) %>%
mutate( par_z = as.numeric(scale(par_p90)), q = plogis(par_z), q_z = as.numeric(scale(q))) %>%
ungroup()
print(summary(df_reg$q))

# 9) Leave-one-out team wage
# Handle the wage variables
# I compute the total wage bill for each club-season
# and then for every player I subtract their own wage from that total to get a leave-one-out figure
# This stops a player's own salary from appearing on both sides of the wage pricing regression
# I merge in the independent club-level log wage bill from the club dataset as the main measure
# and fall back to the leave-one-out estimate only where that is missing
team_wage_tbl <- df_reg %>%
group_by(team_title, season) %>%
summarise( team_wage = sum(annual_eur, na.rm = TRUE), .groups = "drop")
df_reg <- df_reg %>%
left_join(team_wage_tbl, by = c("team_title", "season")) %>%
mutate( team_wage_loo = team_wage - annual_eur)
# 10) Merge independent club wage bill
player_panel <- df_reg %>%
left_join( wages_df %>% select(team, season, log_wage_annual), by = c("team_title" = "team", "season" = "season")) %>%
mutate( club_log_wage = ifelse(is.finite(log_wage_annual), log_wage_annual, NA_real_), club_log_wage = ifelse( is.na(club_log_wage) & team_wage_loo > 0, log(team_wage_loo), club_log_wage ), Age2 = Age^2)

# 11) Final player sample
# Lock down the final player sample
#I should probably drop anyone who is missing a name, a quality score, a wage, an age or a position, for clean data throguhout
# also i should centre both q and club log wage around their means because
# the interaction term in the wage pricing model only makes sense when the variables are centred

df_final <- player_panel %>%
filter( !is.na(player_name), !is.na(q), !is.na(q_z), !is.na(annual_eur), annual_eur > 0, !is.na(club_log_wage), !is.na(Age), !is.na(pos4)) %>%
mutate( lw_c = club_log_wage - mean(club_log_wage, na.rm = TRUE), q_c  = q - mean(q, na.rm = TRUE))

# PART A — PLAYER WAGE PRICING
# I want to test whether clubs actually pay for offensive quality
# The baseline model regresses log wages on quality, club wage bill, their interaction, position, age and season fixed effects
# The interaction term is what I care about most — does quality get rewarded more generously at richer clubs
# I add a team fixed effects version to control for stable club-level differences in how wages are set
# and a player fixed effects version for anyone who appears in at least two seasons
# I run several versions of the standard errors — robust, clustered by player and clustered by both player and team
m_wage_base <- lm( log(annual_eur) ~ q_c + lw_c + q_c:lw_c + pos4 + Age + Age2 + factor(season), data = df_final)
print(summary(m_wage_base))
print(coeftest(m_wage_base, vcov = vcovHC(m_wage_base, type = "HC1")))
print(coeftest(m_wage_base, vcov = vcovCL(m_wage_base, cluster = df_final$player_name)))
try(print(coeftest(m_wage_base, vcov = vcovCL(m_wage_base, cluster = data.frame(player = df_final$player_name,team = df_final$team_title)))),
silent = TRUE)

m_wage_teamFE <- lm(log(annual_eur) ~ q_c + lw_c + q_c:lw_c + pos4 + Age + Age2 + factor(season) + factor(team_title), data = df_final)
print(summary(m_wage_teamFE))
print(coeftest(m_wage_teamFE, vcov = vcovCL(m_wage_teamFE, cluster = df_final$player_name)))

player_counts <- df_final %>%
count(player_name) %>%
filter(n >= 2)

df_pf <- df_final %>%
semi_join(player_counts, by = "player_name")

if(nrow(df_pf) > 0) {m_wage_playerFE <- lm(log(annual_eur) ~ q_c + lw_c + q_c:lw_c + Age + Age2 + factor(season) + factor(player_name), data = df_pf)
print(summary(m_wage_playerFE))
print(coeftest(m_wage_playerFE, vcov = vcovCL(m_wage_playerFE, cluster = df_pf$player_name)))}

# PART A2 — SORTING REGRESSION
# Does player quality sort into richer clubs?
# I want to know whether higher quality players end up at richer clubs
# so I regress player quality on club wage bill controlling for position and season
# If the coefficient is positive it tells me that the labour market is sorting players into clubs in a way that matches quality to money
# and that matters for how I interpret everything that comes after
m_sorting <- lm(q ~ club_log_wage + pos4 + factor(season), data = df_final)
print(coeftest(m_sorting, vcov = vcovCL(m_sorting, cluster = df_final$team_title)))

# PART B — BUILD CLUB-SEASON PANEL
# I need to collapse all the player-level data up to the club level
# For each team and season I want a range of quality summary statistics
# the average, the bottom 20th percentile which captures the weakest link, the bottom 10th, the minimum, the best player, the top three average and the top five average
# I merge these into the club points and wage data, attach the UEFA flags and compute points per game
# I also create a lagged version of the whole panel so I can use last season's values as predictors in the competitive balance models
club_q <- df_final %>%
group_by(team_title, season) %>%
summarise(n_players = n(),
  avg_q   = mean(q, na.rm = TRUE),
  p20_q   = quantile(q, 0.20, na.rm = TRUE),
  p10_q   = quantile(q, 0.10, na.rm = TRUE),
  min_q   = min(q, na.rm = TRUE),
  top1_q  = max(q, na.rm = TRUE),
  top3_q  = mean(sort(q, decreasing = TRUE)[1:min(3, n())], na.rm = TRUE),
  top5_q  = mean(sort(q, decreasing = TRUE)[1:min(5, n())], na.rm = TRUE),
  sd_q    = sd(q, na.rm = TRUE),
  gmean_q = exp(mean(log(pmax(q, 1e-6)), na.rm = TRUE)), .groups = "drop") %>%
  rename(team = team_title)

club_panel <- wages_df %>%
left_join(club_q, by = c("team", "season")) %>%
left_join(europe_map, by = c("team", "season")) %>%
mutate(ucl  = dplyr::coalesce(ucl, 0), uel  = dplyr::coalesce(uel, 0), uecl = dplyr::coalesce(uecl, 0), europe_any = ifelse(ucl + uel + uecl > 0, 1, 0)) %>%
filter(!is.na(Pts), !is.na(log_wage_annual), !is.na(avg_q), !is.na(p20_q), !is.na(top3_q)) %>%
mutate( pts_per_game = Pts / 38, GD_per_game = if("GD" %in% names(.)) GD / 38 else NA_real_)
club_panel <- club_panel %>%
group_by(season) %>%
mutate(
    avg_q_z   = as.numeric(scale(avg_q)),
    p20_q_z   = as.numeric(scale(p20_q)),
    p10_q_z   = as.numeric(scale(p10_q)),
    min_q_z   = as.numeric(scale(min_q)),
    top1_q_z  = as.numeric(scale(top1_q)),
    top3_q_z  = as.numeric(scale(top3_q)),
    top5_q_z  = as.numeric(scale(top5_q)),
    gmean_q_z = as.numeric(scale(gmean_q)),
    logw_z    = as.numeric(scale(log_wage_annual))) %>%
  ungroup()

club_panel2 <- club_panel %>%
arrange(team, season) %>%
group_by(team) %>%
mutate(
    lag_pts         = lag(Pts),
    lag_ppg         = lag(pts_per_game),
    lag_logw        = lag(log_wage_annual),
    lag_avg_q_z     = lag(avg_q_z),
    lag_p20_q_z     = lag(p20_q_z),
    lag_top3_q_z    = lag(top3_q_z),
    lag_ucl         = lag(ucl),
    lag_uel         = lag(uel),
    lag_uecl        = lag(uecl),
    lag_europe_any  = lag(europe_any)) %>%
  ungroup() %>%
mutate(
    lag_logw_c = lag_logw - mean(lag_logw, na.rm = TRUE),
    lag_ppg_c  = lag_ppg  - mean(lag_ppg,  na.rm = TRUE))

# PART C — HORSE-RACE: WEAK LINK VS SUPERSTAR
# This is the central test of the thesis
# I run a sequence of models where points per game is the outcome
# First just wages on their own as a baseline
# then average quality as a benchmark to show that the distribution of quality matters beyond just the mean
# then just the bottleneck measure on its own to test the O-Ring prediction that the weakest player limits the whole team
# then just the superstar measure on its own to test whether having elite players at the top drives performance
# then both together to see which one holds up when they compete directly
# and finally their interaction to ask whether superstars matter more when the squad has no weak links
# I also run a club fixed effects version to check the results are not just picking up time-invariant differences between clubs
m_c1 <- lm(pts_per_game ~ log_wage_annual + factor(season), data = club_panel)
m_c2 <- lm(pts_per_game ~ log_wage_annual + avg_q_z + factor(season), data = club_panel)
print(coeftest(m_c2, vcov = vcovCL(m_c2, cluster = club_panel$team)))
summary(m_c2)$r.squared
m_c3 <- lm(pts_per_game ~ log_wage_annual + p20_q_z + factor(season), data = club_panel)
m_c4 <- lm(pts_per_game ~ log_wage_annual + top3_q_z + factor(season), data = club_panel)
m_c5 <- lm(pts_per_game ~ log_wage_annual + p20_q_z + top3_q_z + factor(season), data = club_panel)
m_c6 <- lm(pts_per_game ~ log_wage_annual + p20_q_z + top3_q_z + p20_q_z:top3_q_z + factor(season), data = club_panel)
print(coeftest(m_c1, vcov = vcovCL(m_c1, cluster = club_panel$team)))
print(coeftest(m_c2, vcov = vcovCL(m_c2, cluster = club_panel$team)))
print(coeftest(m_c3, vcov = vcovCL(m_c3, cluster = club_panel$team)))
print(coeftest(m_c4, vcov = vcovCL(m_c4, cluster = club_panel$team)))
print(coeftest(m_c5, vcov = vcovCL(m_c5, cluster = club_panel$team)))
print(coeftest(m_c6, vcov = vcovCL(m_c6, cluster = club_panel$team)))
# Club FE robustness
m_c5_fe <- lm(pts_per_game ~ log_wage_annual + p20_q_z + top3_q_z + factor(season) + factor(team), data = club_panel)
print(coeftest(m_c5_fe, vcov = vcovCL(m_c5_fe, cluster = club_panel$team)))

if("GD_per_game" %in% names(club_panel) && all(!is.na(club_panel$GD_per_game))) {m_c5_gd <- lm(GD_per_game ~ log_wage_annual + p20_q_z + top3_q_z + factor(season), data = club_panel)
  print(coeftest(m_c5_gd, vcov = vcovCL(m_c5_gd, cluster = club_panel$team)))}

# PART C2 — ROBUSTNESS CHECKS
# I want to make sure none of the main results depend on the specific cutoffs I chose
# So I try the 10th percentile and the minimum as alternative bottleneck measures
# and the single best player and the top five as alternative superstar measures
# I also rebuild the entire quality index from scratch using a 450-minute threshold instead of 900
# to check that the results are not driven by my decision about who counts as a regular player
m_p10 <- lm(pts_per_game ~ log_wage_annual + p10_q_z + factor(season), data = club_panel)
m_min <- lm(pts_per_game ~ log_wage_annual + min_q_z + factor(season), data = club_panel)
# Superstar robustness
m_top1 <- lm(pts_per_game ~ log_wage_annual + top1_q_z + factor(season), data = club_panel)
m_top5 <- lm(pts_per_game ~ log_wage_annual + top5_q_z + factor(season), data = club_panel)
print(coeftest(m_p10, vcov = vcovCL(m_p10, cluster = club_panel$team)))
print(coeftest(m_min, vcov = vcovCL(m_min, cluster = club_panel$team)))
print(coeftest(m_top1, vcov = vcovCL(m_top1, cluster = club_panel$team)))
print(coeftest(m_top5, vcov = vcovCL(m_top5, cluster = club_panel$team)))
# Robustness to minutes threshold
# Rebuild q at 450-minute threshold
df_reg_450 <- df0 %>%
filter(!is.na(minutes), minutes >= 450, !is.na(pos4), !is.na(prod_p90))

rep_tbl_450 <- df_reg_450 %>%
group_by(pos4) %>%
summarise(rep_prod_p90_450 = quantile(prod_p90, 0.20, na.rm = TRUE), .groups = "drop")

df_reg_450 <- df_reg_450 %>%
left_join(rep_tbl_450, by = "pos4") %>%
mutate(par_p90_450 = prod_p90 - rep_prod_p90_450) %>%
group_by(season, pos4) %>%
mutate(q_450 = plogis(as.numeric(scale(par_p90_450)))) %>%
  ungroup()

club_q_450 <- df_reg_450 %>%
group_by(team_title, season) %>%
summarise(p20_q_450 = quantile(q_450, 0.20, na.rm = TRUE), .groups = "drop") %>%
rename(team = team_title)
club_panel_450 <- wages_df %>%
left_join(club_q_450, by = c("team", "season")) %>%
filter(!is.na(Pts), !is.na(log_wage_annual), !is.na(p20_q_450)) %>%
mutate(pts_per_game = Pts / 38) %>%
group_by(season) %>%
mutate(p20_q_450_z = as.numeric(scale(p20_q_450))) %>%
  ungroup()

m_450 <- lm(pts_per_game ~ log_wage_annual + p20_q_450_z + factor(season), data = club_panel_450)
print(coeftest(m_450, vcov = vcovCL(m_450, cluster = club_panel_450$team)))


# PART D — TOURNAMENT THEORY TESTS
# I want to test whether clubs that have steeper internal wage hierarchies perform better
# The idea is that unequal pay structures create stronger incentives for players to compete for the top spots
# I compute several wage dispersion measures within each club-season
# and then test whether those measures predict points after controlling for the overall wage bill
# The interaction between superstar quality and wage dispersion is particularly interesting
# because it asks whether having a top player matters more when the club rewards performance with big pay gaps
club_tourn <- df_final %>%
group_by(team_title, season) %>%
summarise(wage_sd_log = sd(log(annual_eur), na.rm = TRUE), wage_ratio_90_50 = quantile(annual_eur, 0.90, na.rm = TRUE) / quantile(annual_eur, 0.50, na.rm = TRUE), wage_ratio_90_10 = quantile(annual_eur, 0.90, na.rm = TRUE) / quantile(annual_eur, 0.10, na.rm = TRUE), wage_cv = sd(annual_eur, na.rm = TRUE) / mean(annual_eur, na.rm = TRUE), .groups = "drop") %>%
rename(team = team_title)

club_panel_tourn <- club_panel %>%
left_join(club_tourn, by = c("team", "season")) %>%
group_by(season) %>%
mutate(wage_sd_log_z = as.numeric(scale(wage_sd_log)), wage_ratio_90_50_z = as.numeric(scale(wage_ratio_90_50)), wage_ratio_90_10_z = as.numeric(scale(wage_ratio_90_10)), wage_cv_z = as.numeric(scale(wage_cv))) %>%
  ungroup()
m_tourn_1 <- lm(pts_per_game ~ log_wage_annual + wage_sd_log_z + factor(season), data = club_panel_tourn)
m_tourn_2 <- lm(pts_per_game ~ log_wage_annual + wage_ratio_90_50_z + factor(season), data = club_panel_tourn)
m_tourn_3 <- lm(pts_per_game ~ log_wage_annual + top3_q_z + wage_sd_log_z + factor(season), data = club_panel_tourn)
m_tourn_4 <- lm(pts_per_game ~ log_wage_annual + top3_q_z + wage_sd_log_z + top3_q_z:wage_sd_log_z + factor(season), data = club_panel_tourn)
m_tourn_5 <- lm(pts_per_game ~ log_wage_annual + p20_q_z + top3_q_z + wage_sd_log_z + factor(season), data = club_panel_tourn)
print(coeftest(m_tourn_1, vcov = vcovCL(m_tourn_1, cluster = club_panel_tourn$team)))
print(coeftest(m_tourn_2, vcov = vcovCL(m_tourn_2, cluster = club_panel_tourn$team)))
print(coeftest(m_tourn_3, vcov = vcovCL(m_tourn_3, cluster = club_panel_tourn$team)))
print(coeftest(m_tourn_4, vcov = vcovCL(m_tourn_4, cluster = club_panel_tourn$team)))
print(coeftest(m_tourn_5, vcov = vcovCL(m_tourn_5, cluster = club_panel_tourn$team)))
# PART E — COMPETITIVE BALANCE THEORY TESTS
# I want to understand whether the same clubs keep winning season after season
# and whether squad structure helps explain that persistence
# I start by testing whether last season's points predict this season's points
# then I add lagged wages to see how much of that persistence is just financial dominance
# then I add the bottleneck and superstar quality measures to see whether squad composition helps explain it further
# I also bring in the European competition lags to test whether playing in the Champions League last year gives a club an advantage in the league this season
club_cb <- club_panel2 %>%
filter(!is.na(lag_ppg), !is.na(lag_logw)) %>%
mutate(lag_ucl = dplyr::coalesce(lag_ucl, 0), lag_uel = dplyr::coalesce(lag_uel, 0), lag_uecl = dplyr::coalesce(lag_uecl, 0), lag_europe_any = dplyr::coalesce(lag_europe_any, 0))
m_cb_1 <- lm(pts_per_game ~ lag_ppg + factor(season), data = club_cb)
m_cb_2 <- lm(pts_per_game ~ lag_ppg + lag_logw + factor(season), data = club_cb)
m_cb_3 <- lm(pts_per_game ~ lag_ppg + lag_logw + p20_q_z + factor(season), data = club_cb)
m_cb_4 <- lm(pts_per_game ~ lag_ppg + lag_logw + p20_q_z + top3_q_z + factor(season), data = club_cb)
m_cb_5 <- lm(pts_per_game ~ lag_ppg + lag_logw + p20_q_z + top3_q_z + factor(season) + factor(team), data = club_cb)
m_cb_6 <- lm(pts_per_game ~ p20_q_z + lag_logw_c + p20_q_z:lag_logw_c + factor(season), data = club_cb)
m_cb_7 <- lm(pts_per_game ~ top3_q_z + lag_logw_c + top3_q_z:lag_logw_c + factor(season), data = club_cb)
m_cb_8 <- lm(pts_per_game ~ lag_ppg_c + lag_logw_c + p20_q_z + top3_q_z + p20_q_z:top3_q_z + p20_q_z:lag_logw_c + top3_q_z:lag_logw_c + factor(season), data = club_cb)
m_cb_9 <- lm(pts_per_game ~ lag_ppg + lag_logw + lag_europe_any + factor(season), data = club_cb)
m_cb_10 <- lm(pts_per_game ~ lag_ppg + lag_logw + lag_ucl + lag_uel + lag_uecl + factor(season), data = club_cb)
m_cb_11 <- lm(pts_per_game ~ lag_ppg + lag_logw + p20_q_z + top3_q_z + lag_ucl + lag_uel + lag_uecl + factor(season), data = club_cb)
m_cb_12 <- lm(pts_per_game ~ lag_ppg + lag_logw + p20_q_z + top3_q_z + lag_ucl + lag_uel + lag_uecl + top3_q_z:lag_ucl + factor(season), data = club_cb)
cat("\n--- E1 basic persistence ---\n")
print(coeftest(m_cb_1, vcov = vcovCL(m_cb_1, cluster = club_cb$team)))
cat("\n--- E2 persistence + wages ---\n")
print(coeftest(m_cb_2, vcov = vcovCL(m_cb_2, cluster = club_cb$team)))
cat("\n--- E3 persistence + wages + p20_q ---\n")
print(coeftest(m_cb_3, vcov = vcovCL(m_cb_3, cluster = club_cb$team)))
cat("\n--- E4 persistence + wages + p20_q + top3_q ---\n")
print(coeftest(m_cb_4, vcov = vcovCL(m_cb_4, cluster = club_cb$team)))
cat("\n--- E5 FE competitive balance model ---\n")
print(coeftest(m_cb_5, vcov = vcovCL(m_cb_5, cluster = club_cb$team)))
cat("\n--- E6 p20_q x lagged wage environment ---\n")
print(coeftest(m_cb_6, vcov = vcovCL(m_cb_6, cluster = club_cb$team)))
cat("\n--- E7 top3_q x lagged wage environment ---\n")
print(coeftest(m_cb_7, vcov = vcovCL(m_cb_7, cluster = club_cb$team)))
cat("\n--- E8 full competitive balance / dominance model ---\n")
print(coeftest(m_cb_8, vcov = vcovCL(m_cb_8, cluster = club_cb$team)))
cat("\n--- E9 persistence + broad Europe effect ---\n")
print(coeftest(m_cb_9, vcov = vcovCL(m_cb_9, cluster = club_cb$team)))
cat("\n--- E10 persistence + split UEFA competitions ---\n")
print(coeftest(m_cb_10, vcov = vcovCL(m_cb_10, cluster = club_cb$team)))
cat("\n--- E11 full model + split UEFA competitions ---\n")
print(coeftest(m_cb_11, vcov = vcovCL(m_cb_11, cluster = club_cb$team)))
cat("\n--- E12 full model + Europe reinforcement interaction ---\n")
print(coeftest(m_cb_12, vcov = vcovCL(m_cb_12, cluster = club_cb$team)))

# PART E2 — LABOUR MARKET SORTING REGRESSIONS
# try to test whether lagged club performance predicts subsequent
# I want to close the loop by asking whether successful clubs subsequently attract better players
# If last season's performance predicts this season's squad quality
# then there is a self-reinforcing cycle where winning breeds better recruitment which breeds more winning
# I run this for average quality, bottleneck quality and superstar quality separately
sorting_data <- club_panel2 %>%
filter(!is.na(lag_ppg), !is.na(avg_q_z), !is.na(p20_q_z), !is.na(top3_q_z))
# S1 — lagged performance predicts subsequent average squad quality
m_sort_avg <- lm(avg_q_z ~ lag_ppg + lag_logw + factor(season), data = sorting_data)
# S2 — lagged performance predicts subsequent bottleneck quality (Eq. 8b)
m_sort_p20 <- lm(p20_q_z ~ lag_ppg + lag_logw + factor(season), data = sorting_data)
# S3 — lagged performance predicts subsequent superstar quality (Eq. 8a)
m_sort_top3 <- lm(top3_q_z ~ lag_ppg + lag_logw + factor(season), data = sorting_data)

cat("\n--- S1 lagged performance -> average squad quality ---\n")
print(coeftest(m_sort_avg, vcov = vcovCL(m_sort_avg, cluster = sorting_data$team)))
cat("\n--- S2 lagged performance -> bottleneck quality (Eq. 8b) ---\n")
print(coeftest(m_sort_p20, vcov = vcovCL(m_sort_p20, cluster = sorting_data$team)))
cat("\n--- S3 lagged performance -> superstar quality (Eq. 8a) ---\n")
print(coeftest(m_sort_top3, vcov = vcovCL(m_sort_top3, cluster = sorting_data$team)))
modelsummary(list("Avg Quality" = m_sort_avg, "Bottleneck Quality" = m_sort_p20, "Superstar Quality" = m_sort_top3),
  statistic = "({std.error}){stars}",
  gof_omit = "IC|Log|Adj|F",
  output = "outputs/table_sorting_models.html",
  title = "Labour Market Sorting Regressions (Eq. 8)")

# PART F — LEAGUE-LEVEL COMPETITIVE BALANCE DESCRIPTIVES
# Part F — League-level competitive balance descriptives
# I want to step back from individual clubs and look at the league as a whole
# by computing how spread out the points and wage bills are across clubs in each season
# This gives the descriptive context for the whole paper and lets me say something about whether competitive balance is improving or deteriorating over the ten seasons
league_balance <- club_panel %>%
group_by(season) %>%
summarise(
    sd_pts = sd(Pts, na.rm = TRUE),
    sd_ppg = sd(pts_per_game, na.rm = TRUE),
    cv_pts = sd(Pts, na.rm = TRUE) / mean(Pts, na.rm = TRUE),
    cv_logw = sd(log_wage_annual, na.rm = TRUE) / mean(log_wage_annual, na.rm = TRUE),
    mean_top3_q = mean(top3_q, na.rm = TRUE),
    mean_p20_q = mean(p20_q, na.rm = TRUE), 
    .groups = "drop")
print(league_balance)

# PART G — DESCRIPTIVE SUMMARIES
# I want clean printed summaries of the key variables at both the player and club level
# I also want three scatter plots — points against wages, points against bottleneck quality and points against superstar quality
# saved at high resolution for the paper
# All six regression tables get exported as HTML files through model summary or through word, see which one is better
print(summary(df_final$q))
print(summary(club_panel[, c("pts_per_game", "log_wage_annual", "avg_q", "p20_q", "top3_q", "ucl", "uel", "uecl", "europe_any")]))
corr_df <- club_panel %>%
select(pts_per_game, log_wage_annual, avg_q, p20_q, top3_q, europe_any) %>%
na.omit()
print(round(cor(corr_df), 3))

# PART G2 — FORMATTED DESCRIPTIVE TABLES
#create some nice looking tables, maybe makes sense to ask chatgpt to format them nicely.
# Make sure folder exists
dir.create("C:/Users/denis/OneDrive/Desktop/research paper graphs", showWarnings = FALSE)

# Build descriptive statistics manually
#ask chatgpt how to create aesthetically good looking descriptive table for the paper
desc_vars <- club_panel %>%
select(
    `Points per Game`         = pts_per_game,
    `Log Wage Bill`           = log_wage_annual,
    `Avg. Offensive Quality`  = avg_q,
    `Bottleneck Quality`      = p20_q,
    `Superstar Quality`       = top3_q)
desc_table <- data.frame(
  Variable = names(desc_vars),
  Mean     = round(sapply(desc_vars, mean,   na.rm = TRUE), 3),
  SD       = round(sapply(desc_vars, sd,     na.rm = TRUE), 3),
  Min      = round(sapply(desc_vars, min,    na.rm = TRUE), 3),
  Median   = round(sapply(desc_vars, median, na.rm = TRUE), 3),
  Max      = round(sapply(desc_vars, max,    na.rm = TRUE), 3),
  N        = sapply(desc_vars, function(x) sum(!is.na(x))),
  row.names = NULL)

# Print out the console so i can have look at it output
print(desc_table)
# Save as Word document
if(!requireNamespace("flextable", quietly = TRUE)) install.packages("flextable")
if(!requireNamespace("officer",   quietly = TRUE)) install.packages("officer")
library(flextable)
library(officer)
ft <- flextable(desc_table) %>%
set_header_labels(
    Variable = "Variable",
    Mean     = "Mean",
    SD       = "Std. Dev.",
    Min      = "Min",
    Median   = "Median",
    Max      = "Max",
    N        = "N") %>%
add_header_lines("Table 1: Descriptive Statistics — Club-Season Panel") %>%
add_footer_lines("Notes: 136 club-season observations. All quality measures bounded between 0 and 1. Bottleneck quality is the 20th percentile of offensive quality within each squad. Superstar quality is the mean of the top three players.") %>%
autofit() %>%
theme_booktabs()
# Save to Word
doc <- read_docx() %>%
body_add_flextable(ft)
print(doc, target = "C:/Users/denis/OneDrive/Desktop/research paper graphs/table_descriptives.docx")
#Correlation matrix
corr_matrix <- corr_df %>%
rename(
    `PPG`       = pts_per_game,
    `Log Wage`  = log_wage_annual,
    `Avg Q`     = avg_q,
    `p20 Q`     = p20_q,
    `Top3 Q`    = top3_q,
    `Europe`    = europe_any)
corr_out <- round(cor(corr_matrix, use = "complete.obs"), 3)
corr_df2 <- as.data.frame(corr_out)
corr_df2 <- cbind(Variable = rownames(corr_df2), corr_df2)
rownames(corr_df2) <- NULL
print(corr_out)
ft_corr <- flextable(corr_df2) %>%
add_header_lines("Table 2: Correlation Matrix — Main Variables") %>%
add_footer_lines("Notes: Pairwise correlations across 136 club-season observations.") %>%
autofit() %>%
theme_booktabs()
doc_corr <- read_docx() %>%
body_add_flextable(ft_corr)
print(doc_corr, target = "C:/Users/denis/OneDrive/Desktop/research paper graphs/table_correlations.docx")

# PART G3 — FIGURES + REGRESSION TABLES
#create some graphs that will look nice in the research paper, and show the basic relationships between wages and points per game, yada yada
if(!dir.exists("outputs")) dir.create("outputs")
fig_wage <- ggplot(club_panel, aes(x = log_wage_annual, y = pts_per_game)) + geom_point(alpha = 0.75) + geom_smooth(method = "lm", se = TRUE) +
labs(title = "Points per Game vs Club Wage Bill", x = "Log Annual Wage Bill", y = "Points per Game") + theme_minimal(base_size = 12)
print(fig_wage)
ggsave("outputs/fig_pts_vs_logwage.png", fig_wage, width = 7, height = 5, dpi = 300)
fig_p20 <- ggplot(club_panel, aes(x = p20_q, y = pts_per_game)) + geom_point(alpha = 0.75) + geom_smooth(method = "lm", se = TRUE) +
labs(title = "Points per Game vs Bottleneck Quality (p20_q)", x = "Bottom-20% Offensive Quality (p20_q)", y = "Points per Game") + theme_minimal(base_size = 12)
print(fig_p20)
ggsave("outputs/fig_pts_vs_p20q.png", fig_p20, width = 7, height = 5, dpi = 300)
fig_top3 <- ggplot(club_panel, aes(x = top3_q, y = pts_per_game)) + geom_point(alpha = 0.75) + geom_smooth(method = "lm", se = TRUE) + labs(title = "Points per Game vs Superstar Quality (top3_q)", x = "Top-3 Offensive Quality (top3_q)", y = "Points per Game") + theme_minimal(base_size = 12)
print(fig_top3)
ggsave("outputs/fig_pts_vs_top3q.png", fig_top3, width = 7, height = 5, dpi = 300)

# Modelsummary tables
modelsummary(list("Baseline Wage Model" = m_wage_base, "Team FE Wage Model" = m_wage_teamFE),
  statistic = "({std.error}){stars}",
  gof_omit = "IC|Log|Adj|F",
  output = "outputs/table_1_wage_models.html",
  title = "Player Wage Pricing Models")
modelsummary(list("Sorting" = m_sorting),
  statistic = "({std.error}){stars}",
  gof_omit = "IC|Log|Adj|F",
  output = "outputs/table_2_sorting_model.html",
  title = "Sorting of Offensive Quality into Richer Clubs")
modelsummary(list(
    "Wages Only" = m_c1,
    "Wages + Avg Quality (Benchmark)" = m_c2,
    "Wages + Bottleneck" = m_c3,
    "Wages + Superstar" = m_c4,
    "Both" = m_c5,
    "Both + Interaction" = m_c6,
    "Both + Club FE" = m_c5_fe),
  statistic = "({std.error}){stars}",
  gof_omit = "IC|Log|Adj|F",
  output = "outputs/table_3_horserace_models.html",
  title = "Weak-Link vs Superstar Horse Race")
modelsummary(list(
    "p10 Bottleneck" = m_p10,
    "Min Bottleneck" = m_min,
    "Top1 Superstar" = m_top1,
    "Top5 Superstar" = m_top5,
    "450 Min Threshold" = m_450),
  statistic = "({std.error}){stars}",
  gof_omit = "IC|Log|Adj|F",
  output = "outputs/table_4_robustness_models.html",
  title = "Robustness Checks")
modelsummary(list(
    "Tournament 1" = m_tourn_1,
    "Tournament 2" = m_tourn_2,
    "Tournament 3" = m_tourn_3,
    "Tournament 4" = m_tourn_4,
    "Tournament 5" = m_tourn_5),
  statistic = "({std.error}){stars}",
  gof_omit = "IC|Log|Adj|F",
  output = "outputs/table_5_tournament_models.html",
  title = "Tournament Theory Models")
modelsummary(list(
    "CB 1" = m_cb_1,
    "CB 2" = m_cb_2,
    "CB 3" = m_cb_3,
    "CB 4" = m_cb_4,
    "CB FE" = m_cb_5,
    "p20 x Wage Env" = m_cb_6,
    "top3 x Wage Env" = m_cb_7,
    "Full CB Model" = m_cb_8,
    "Europe Any" = m_cb_9,
    "Europe Split" = m_cb_10,
    "Full + Europe Split" = m_cb_11,
    "Europe Reinforcement" = m_cb_12),
  statistic = "({std.error}){stars}",
  gof_omit = "IC|Log|Adj|F",
  output = "outputs/table_6_competitive_balance_models.html",
  title = "Competitive Balance Theory Models")
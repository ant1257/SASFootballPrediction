/* libraries */
libname ml  "/folders/myfolders/footbal/belarus/major_league/data";
libname bl2 "/folders/myfolders/footbal/germany/bundesliga2/data";
libname sb  "/folders/myfolders/footbal/italy/serie_b/data";
libname general "/folders/myfolders/footbal/general";

/* collecting train data */
data train_01;
	set ml.train
		bl2.train
		sb.train	
		;
		if home_prob_total_wins = . then delete;
		if away_prob_total_wins = . then delete;
		if prob_total_home_wins = . then delete;
		if prob_total_away_wins = . then delete;
		
		if home_prob_total_wins > 1
			or home_prob_total_draws > 1
			or home_prob_total_loses > 1
			or prob_total_home_wins > 1
			or prob_total_home_draws > 1
			or prob_total_home_loses > 1
			or home_avg_total_points > 3
			or avg_total_home_points > 3
			or home_team_form < -1
			or home_team_form > 1
			or away_prob_total_wins > 1
			or away_prob_total_draws > 1
			or away_prob_total_loses > 1
			or prob_total_away_wins > 1
			or prob_total_away_draws > 1
			or prob_total_away_loses > 1
			or away_avg_total_points > 3
			or avg_total_away_points > 3
			or away_team_form < -1
			or away_team_form > 1
		then delete;
run;

data train_01;
	set train_01;
		X1 = 0;
		X2 = 0;
		HH05 = 0;
		AH05 = 0;
		HH15 = 0;
		AH15 = 0;
		HH25 = 0;
		AH25 = 0;
		
		if home_win = 1 or draw = 1 then X1 = 1;
		if away_win = 1 or draw = 1 then X2 = 1;
		
		if home_scored > 0.5 then HH05 = 1;		
		if home_scored > 1.5 then HH15 = 1;
		if home_scored > 2.5 then HH25 = 1;
		
		if away_scored > 0.5 then AH05 = 1;		
		if away_scored > 1.5 then AH15 = 1;		
		if away_scored > 2.5 then AH25 = 1;
run;

/* clasterization of the data */
proc contents data = train_01 out = temp_01 noprint;
run;

proc sort data = temp_01;
	by varnum;
run;

proc sql noprint;
	select name
	into : std_names
	separated by ' '
	from temp_01
	where upcase(name) ^in ('HOME_SCORED', 'AWAY_SCORED', 'HOME_WIN', 'AWAY_WIN', 'DRAW', 'HOME_TEAM', 'AWAY_TEAM', 'SEASON', 'X1', 'X2', 'HH05', 'HH15', 'HH25', 'AH05', 'AH15', 'AH25');
quit;

proc fastclus data = train_01 maxclusters = 4 out = train_02 outstat = general.clust_stat_lower;
	var &std_names;
run;

proc fastclus data = train_01 instat = general.clust_stat_lower out = train_03;
	var &std_names;
run;

%macro train(target);
	proc logistic data = train_03 outmodel = general.model_lower_&target;
		model &target(event = '1') = &std_names cluster /
		maxiter = 50
		selection = forward
		slentry=0.15;
	run;
%mend train;

%train(home_win);
%train(away_win);
%train(X1);
%train(X2);
%train(HH05);
%train(HH15);
%train(HH25);
%train(AH05);
%train(AH15);
%train(AH25);


/* libraries */
libname ml  "/folders/myfolders/footbal/belarus/major_league/data";
libname epl "/folders/myfolders/footbal/england/epl/data";
libname bl1 "/folders/myfolders/footbal/germany/bundesliga1/data";
libname sa  "/folders/myfolders/footbal/italy/serie_a/data";
*libname kor "/folders/myfolders/footbal/korea/k_league/data";
*libname por "/folders/myfolders/footbal/portugal/primeira/data";
libname ll  "/folders/myfolders/footbal/spain/laliga/data";
libname general "/folders/myfolders/footbal/general";

/* collecting train data */
data train_01;
	set 
		ml.train
		epl.train
		bl1.train
/* 		bl2.train */
		sa.train
/* 		kor.train */
/* 		por.train */
		ll.train		
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

/*
CLUSTERS DESCRIPTION:
Home
cluster 1 - outsider
cluster 2 - middle
cluster 3 - favorite
cluster 4 - pre-middle
cluster 5 - pre-favorite

Away
cluster 1 - pre-middle
cluster 2 - middle
cluster 3 - favorite
cluster 4 - outsider
cluster 5 - pre-favorite
*/


%let home_vars = home_prob_total_wins home_prob_total_draws home_prob_total_loses prob_total_home_wins prob_total_home_draws prob_total_home_loses home_avg_total_goles_scored home_avg_total_goles_conceded avg_total_home_goles_scored avg_total_home_goles_conceded home_avg_total_points avg_total_home_points home_team_form;
%let away_vars = away_prob_total_wins away_prob_total_draws away_prob_total_loses prob_total_away_wins prob_total_away_draws prob_total_away_loses away_avg_total_goles_scored away_avg_total_goles_conceded avg_total_away_goles_scored avg_total_away_goles_conceded away_avg_total_points avg_total_away_points away_team_form;


%macro define_clusters(side, input);
	proc fastclus data = &input maxclusters = 5 out = dat_&side outstat = general.clust_stat_&side;
		var &&&side._vars;
	run;
	
	data dat_&side;
		set dat_&side;
			&side._cluster = input(strip(put(cluster, best.)), best.);
			drop distance cluster;
	run;
%mend define_clusters;

%define_clusters(home, train_01);
%define_clusters(away, train_01);

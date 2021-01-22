libname general "/folders/myfolders/footbal/general";

/* HOME */
proc fastclus data = general.train_01 maxclusters = 5 out = dat_01;
	var home_prob_total_wins home_prob_total_draws home_prob_total_loses prob_total_home_wins prob_total_home_draws prob_total_home_loses home_avg_total_goles_scored home_avg_total_goles_conceded avg_total_home_goles_scored avg_total_home_goles_conceded home_avg_total_points avg_total_home_points home_team_form;
run;

proc sgpanel data = dat_01;
	panelby cluster;
	histogram home_team_form;
run;

proc sgpanel data = dat_01;
	panelby cluster;
	histogram home_avg_total_goles_scored / transparency = 0.45;
	histogram home_avg_total_goles_conceded / transparency = 0.45;
run;

proc sgpanel data = dat_01;
	panelby cluster;
	histogram home_prob_total_wins / transparency = 0.45;
	histogram home_prob_total_loses / transparency = 0.45;
run;


/* AWAY */
proc fastclus data = general.train_01 maxclusters = 5 out = dat_02;
	var away_prob_total_wins away_prob_total_draws away_prob_total_loses prob_total_away_wins prob_total_away_draws prob_total_away_loses away_avg_total_goles_scored away_avg_total_goles_conceded avg_total_away_goles_scored avg_total_away_goles_conceded away_avg_total_points avg_total_away_points away_team_form;
run;

proc sgpanel data = dat_02;
	panelby cluster;
	histogram away_team_form;
run;


proc sgpanel data = dat_02;
	panelby cluster;
	histogram away_avg_total_goles_scored / transparency = 0.45;
	histogram away_avg_total_goles_conceded / transparency = 0.45;
run;

proc sgpanel data = dat_02;
	panelby cluster;
	histogram away_prob_total_wins / transparency = 0.45;
	histogram away_prob_total_loses / transparency = 0.45;
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



/* DEFINE CLUSTERS */
libname general "/folders/myfolders/footbal/general";

%let home_vars = home_prob_total_wins home_prob_total_draws home_prob_total_loses prob_total_home_wins prob_total_home_draws prob_total_home_loses home_avg_total_goles_scored home_avg_total_goles_conceded avg_total_home_goles_scored avg_total_home_goles_conceded home_avg_total_points avg_total_home_points home_team_form;
%let away_vars = away_prob_total_wins away_prob_total_draws away_prob_total_loses prob_total_away_wins prob_total_away_draws prob_total_away_loses away_avg_total_goles_scored away_avg_total_goles_conceded avg_total_away_goles_scored avg_total_away_goles_conceded away_avg_total_points avg_total_away_points away_team_form;


%macro define_clusters(side, input);
	proc fastclus data = &input maxclusters = 5 out = dat_&side;
		var &&&side._vars;
	run;
	
	data dat_&side;
		set dat_&side;
			&side._cluster = input(strip(put(cluster, best.)), best.);
			drop distance cluster;
	run;
%mend define_clusters;

%define_clusters(home, general.train_01);
%define_clusters(away, general.train_01);

proc sql;
	create table train_02 as
	select a.*
			, b.away_cluster
	from dat_home as a
	left join dat_away as b on a.season = b.season
		and a.round = b.round
		and a.home_team = b.home_team
		and a.away_team = b.away_team;
quit;

proc format;
	value home_cluster
	1 = 'outsider'
	2 = 'middle'
	3 = 'favorite'
	4 = 'preMiddle'
	5 = 'preFavorite'
	;
	
	value away_cluster
	1 = 'preMiddle'
	2 = 'middle'
	3 = 'favorite'
	4 = 'outsider'
	5 = 'preFavorite'
	;
run;

data train_03;
	set train_02;
		length segment $50;
		
		segment = catx(' vs ', strip(put(home_cluster, home_cluster.)), strip(put(away_cluster, away_cluster.)));
		keep season round home_team away_team home_scored away_scored home_win draw away_win segment;
run;

proc sql;
	create table train_04 as
	select segment
			, sum(home_scored) as home_scored_total
			, sum(away_scored) as away_scored_total
			, sum(home_win) as home_win_count
			, sum(draw) as draw_count
			, sum(away_win) as away_win_count
			, round(sum(home_win) /  (sum(home_win) + sum(draw) + sum(away_win)), .0001) * 100 as home_win_prcnt
			, round(sum(draw) /  (sum(home_win) + sum(draw) + sum(away_win)), .0001) * 100 as draw_prcnt
			, round(sum(away_win) /  (sum(home_win) + sum(draw) + sum(away_win)), .0001) * 100 as away_win_prcnt
	from train_03
	group by segment
	order by segment;
quit;


proc print data = train_04;
	var segment home_win_prcnt draw_prcnt away_win_prcnt;
run;

proc transpose data = train_04 out = train_05;
	by segment;
run;

data train_06;
	set train_05;
		length pre_segment $20;
		
		pre_segment = scan(segment, 1, ' ');
		if ^index(_name_, '_prcnt') then delete;
		
		
		rename _name_ = type_name
				col1 = percent;
		label col1 = 'Percent';
run;


proc sgplot data = train_06;
	vbar segment / response = percent group = type_name barwidth = 0.8 transparency = .25;
	yaxis grid ;
run;

	


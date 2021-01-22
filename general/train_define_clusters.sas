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


title 'Favorite';
proc sgplot data = train_06 (where = (pre_segment = 'favorite'));
	vbar segment / response = percent group = type_name barwidth = 0.8 transparency = .25;
	yaxis grid ;
run;

title 'Middle';
proc sgplot data = train_06 (where = (pre_segment = 'middle'));
	vbar segment / response = percent group = type_name barwidth = 0.8 transparency = .25;
	yaxis grid ;
run;

title 'Outsider';
proc sgplot data = train_06 (where = (pre_segment = 'outsider'));
	vbar segment / response = percent group = type_name barwidth = 0.8 transparency = .25;
	yaxis grid ;
run;

title 'Pre-Favorite';
proc sgplot data = train_06 (where = (pre_segment = 'preFavorite'));
	vbar segment / response = percent group = type_name barwidth = 0.8 transparency = .25;
	yaxis grid ;
run;

title 'Pre-Middle';
proc sgplot data = train_06 (where = (pre_segment = 'preMiddle'));
	vbar segment / response = percent group = type_name barwidth = 0.8 transparency = .25;
	yaxis grid ;
run;


data train_07;
	set train_04;
		if segment in ('preFavorite vs favorite', 'preMiddle vs preFavorite', 'outsider vs middle', 'middle vs preFavorite', 'outsider vs preMiddle') then cluster = 1;
		if segment in ('outsider vs favorite', 'preMiddle vs favorite') then cluster = 2;
		if segment in ('outsider vs preFavorite', 'middle vs favorite', 'favorite vs favorite') then cluster = 3;
		if segment in ('preFavorite vs preMiddle', 'favorite vs preFavorite', 'preFavorite vs outsider', 'outsider vs outsider', 'favorite vs outsider', 'middle vs outsider', 'preFavorite vs middle', 'preMiddle vs outsider') then cluster = 4;
		if segment in ('preMiddle vs middle', 'preMiddle vs preMiddle', 'middle vs middle','preFavorite vs preFavorite', 'middle vs preMiddle') then cluster = 5;
		if segment in ('favorite vs preMiddle', 'favorite vs middle') then cluster = 6;
run;

proc sql;
	create table train_08 as
	select cluster
			, sum(home_scored_total) as cluster_home_scored
			, sum(away_scored_total) as cluster_away_scored
			, sum(home_win_count) as cluster_home_win
			, sum(draw_count) as cluster_draw
			, sum(away_win_count) as cluster_away_win
			, round(sum(home_win_count) /  (sum(home_win_count) + sum(draw_count) + sum(away_win_count)), .0001) * 100 as home_win_prcnt
			, round(sum(draw_count) /  (sum(home_win_count) + sum(draw_count) + sum(away_win_count)), .0001) * 100 as draw_prcnt
			, round(sum(away_win_count) /  (sum(home_win_count) + sum(draw_count) + sum(away_win_count)), .0001) * 100 as away_win_prcnt
	from train_07
	group by cluster;
quit;


proc transpose data = train_08 out = train_09;
	by cluster;
run;

data train_10;
	set train_09;
		if ^index(_name_, '_prcnt') then delete;
		
		
		rename _name_ = type_name
				col1 = percent;
		label col1 = 'Percent';
run;

title 'Win-draw-lose structure per clusters';
proc sgplot data = train_10;
	vbar cluster / response = percent group = type_name barwidth = 0.8 transparency = .25;
	yaxis grid ;
run;

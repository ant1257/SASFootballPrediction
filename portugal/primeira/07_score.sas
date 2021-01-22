libname data_f '/folders/myfolders/footbal/portugal/primeira/data';
libname general "/folders/myfolders/footbal/general";


/* %let season = 2021; */

data _null_;
	set data_f.results_&season end = eof;
		if eof then do;
			call symput('round', compress(put(round + 1, best.)));
		end;
run;

/* %let round = 13; */

/* SCORING */
%let home_vars = home_prob_total_wins home_prob_total_draws home_prob_total_loses prob_total_home_wins prob_total_home_draws prob_total_home_loses home_avg_total_goles_scored home_avg_total_goles_conceded avg_total_home_goles_scored avg_total_home_goles_conceded home_avg_total_points avg_total_home_points home_team_form;
%let away_vars = away_prob_total_wins away_prob_total_draws away_prob_total_loses prob_total_away_wins prob_total_away_draws prob_total_away_loses away_avg_total_goles_scored away_avg_total_goles_conceded avg_total_away_goles_scored avg_total_away_goles_conceded away_avg_total_points avg_total_away_points away_team_form;

%macro apply_clusters(side, input);
	proc fastclus data = &input instat = general.clust_stat_&side out = dat_&side;
		var &&&side._vars;
	run;
	
	data dat_&side;
		set dat_&side;
			&side._cluster = input(strip(put(cluster, best.)), best.);
			drop distance cluster;
	run;
%mend apply_clusters;

%macro score(data, target);
	title "&data &target";
	
	%apply_clusters(home, data_f.&data);
	%apply_clusters(away, data_f.&data);
	
	proc sql;
		create table &data._prep_01 as
		select a.*
				, b.away_cluster
				, input(cat(strip(put(a.home_cluster, best.)), strip(put(b.away_cluster, best.))), best.) as game_cluster
		from dat_home as a
		left join dat_away as b on a.season = b.season
			and a.round = b.round
			and a.home_team = b.home_team
			and a.away_team = b.away_team;
	quit;
	
	data &data._prep_01;
		set &data._prep_01;
			if game_cluster in (53, 45, 12, 25, 11) then segment = 1;
			if game_cluster in (13, 43) then segment = 2;
			if game_cluster in (15, 23, 33) then segment = 3;
			if game_cluster in (51, 35, 54, 14, 34, 24, 52, 44) then segment = 4;
			if game_cluster in (42, 41, 22, 55, 21) then segment = 5;
			if game_cluster in (31, 32) then segment = 6;
	run;
	
	proc datasets lib = work nolist;
		delete &data._&target._score;
	run;
	
	%do i = 1 %to 6;
		title "segment &i";
		proc logistic inmodel = general.model_&target._cluster_&i;
			score data = &data._prep_01 (where = (strip(put(segment, best.)) = "&i")) out = &data._&target._&i;
		run;
		
		proc sql;
			create table &data._&target._&i._score as
			select a.*
					, b.*
			from &data._&target._&i as a
			full join general.cutoffs_&target._cluster_&i as b on 1 = 1;
		quit;
		
		data &data._&target._&i._score;
			set &data._&target._&i._score;
				length group $20;
				
				%if &target = home_win %then %do;
					if segment in (5) then blue_value = .;
					else if segment in (1) then do;
						blue_value = .;
						yellow_value = .;
						gray_value = .;
					end;
					else if segment in (2, 3) then do;
						blue_value = .;
						yellow_value = .;
					end;
				%end;
				
				%else %if &target = X1 %then %do;
					if segment in (2, 3) then blue_value = .;
					else if segment in (6) then do;
						blue_value = .;
						yellow_value = .;
					end;
				%end;
				
				%else %if &target = X2 %then %do;
					if segment in (4, 5) then blue_value = .;
				%end;
				
				%else %if &target = away_win %then %do;
					if segment in (1) then blue_value = .;
					else if segment in (4) then do;
						blue_value = .;
						yellow_value = .;
						gray_value = .;
					end;
					else if segment in (5) then do;
						blue_value = .;
						yellow_value = .;
					end;
				%end;
				
				%else %if &target = HH05 %then %do;
					if segment in (2) then blue_value = .;
				%end;
				
				%else %if &target = HH15 %then %do;
					if segment in (4, 5) then blue_value = .;
					
					else if segment in (1, 3) then do;
						blue_value = .;
						yellow_value = .;
					end;						
					
					else if segment in (2) then do;
						blue_value = .;
						yellow_value = .;
						gray_value = .;
					end;
				%end;
				
				%else %if &target = HH25 %then %do;
					if segment in (6) then blue_value = .;
					
					else if segment in (4, 5) then do;
						blue_value = .;
						yellow_value = .;
					end;
				%end;
				
				%else %if &target = AH05 %then %do;
					if segment in (6) then blue_value = .;
				%end;
				
				%else %if &target = AH15 %then %do;
					if segment in (1) then blue_value = .;
					
					else if segment in (4) then do;
						blue_value = .;
						yellow_value = .;
					end;
					
					else if segment in (5, 6) then do;
						blue_value = .;
						yellow_value = .;
						gray_value = .;
					end;
				%end;
				
				%else %if &target = AH25 %then %do;					
					if segment in (1, 2, 3) then do;
						blue_value = .;
						yellow_value = .;
					end;
					
					else if segment in (4, 5, 6) then do;
						blue_value = .;
						yellow_value = .;
						gray_value = .;
					end;
				%end;
				
				if blue_value ne . and p_1 > blue_value then group = 'BLUE';
				else if yellow_value ne . and p_1 > yellow_value then group = 'YELLOW';
				else if gray_value ne . and p_1 > gray_value then group = 'GRAY';
				else group = 'RED';
				
				%if &target = home_win %then %do;
					if segment = 6 then do;
						if group = 'YELLOW' then group = 'BLUE';
						else if group = 'GRAY' then group = 'YELLOW';
						else if group = 'RED' then group = 'GRAY';
					end;
				%end;
				
				%else %if &target = X1 %then %do;
					if segment in (4, 5) then do;
						if group = 'YELLOW' then group = 'BLUE';
						else if group = 'GRAY' then group = 'YELLOW';
						else if group = 'RED' then group = 'GRAY';
					end;
					
					else if segment = 6 then group = 'BLUE';
				%end;
				
				%else %if &target = away_win %then %do;
					if segment = 6 then group = 'RED';
				%end;
				
				%else %if &target = X2 %then %do;
					if segment in (2, 3) then do;
						if group = 'YELLOW' then group = 'BLUE';
						else if group = 'GRAY' then group = 'BLUE';
						else if group = 'RED' then group = 'YELLOW';
					end;
					
					else if segment = 6 then group = 'RED';
				%end;
				
				%else %if &target = HH05 %then %do;
					if segment = 3 then do;
						if group = 'BLUE' then group = 'YELLOW';
					end;
					
					else if segment in (4, 5) then do;
						if group = 'YELLOW' then group = 'BLUE';
						else if group = 'GRAY' then group = 'YELLOW';
						else if group = 'RED' then group = 'YELLOW';
					end;
					
					else if segment = 6 then group = 'BLUE';
				%end;
				
				%else %if &target = HH15 %then %do;
					if segment = 6 then do;
						if group in ('RED', 'GRAY') then group = 'YELLOW';
					end;
				%end;
				
				%else %if &target = HH25 %then %do;
					if segment in (1, 2, 3) then do;
						group = 'RED';
					end;
				%end;
				
				%else %if &target = AH05 %then %do;
					if segment in (2) then do;
						if group = 'YELLOW' then group = 'BLUE';
						else if group = 'GRAY' then group = 'YELLOW';
						else if group = 'RED' then group = 'YELLOW';
					end;
					
					else if segment in (3) then do;
						if group = 'GRAY' then group = 'YELLOW';
						else if group = 'RED' then group = 'YELLOW';
					end;
					
					else if segment in (1, 5) then do;
						if group = 'RED' then group = 'GRAY';
					end;
					
					else if segment in (4) then do;
						if group = 'GRAY' then group = 'YELLOW';
						else if group = 'RED' then group = 'GRAY';
					end;
				%end;
		run;
		
		proc append data = &data._&target._&i._score base = &data._&target._score;
		run;
	%end;
	
	data &data._&target._score;
		set &data._&target._score;
			if season = . then delete;
	run;
%mend score;

%score(score_&season._&round, home_win);
%score(score_&season._&round, away_win);
%score(score_&season._&round, x1);
%score(score_&season._&round, x2);
%score(score_&season._&round, HH05);
%score(score_&season._&round, HH15);
%score(score_&season._&round, HH25);
%score(score_&season._&round, AH05);
%score(score_&season._&round, AH15);
%score(score_&season._&round, AH25);


/* SAVE PREDICTIONS */
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

proc sql;
	create table data_f.prediction_&season._&round as
	select
		a.season
		, a.round
		, a.home_team
		, a.away_team
		, put(a.home_cluster, home_cluster.) as home_type length = 20
		, put(a.away_cluster, away_cluster.) as away_type length = 20
		, catx(':', strip(put(a.segment, best.)), 'P1', strip(put(round(a.P_1, .001), best.))) as P1 length = 20
		, catx(':', strip(put(a.segment, best.)),'P2', strip(put(round(b.P_1, .001), best.))) as P2 length = 20
		, catx(':', strip(put(a.segment, best.)),'X1', strip(put(round(c.P_1, .001), best.))) as X1 length = 20
		, catx(':', strip(put(a.segment, best.)),'X2', strip(put(round(d.P_1, .001), best.))) as X2 length = 20
		, catx(':', strip(put(a.segment, best.)),'HH05', strip(put(round(e.P_1, .001), best.))) as HH05 length = 20
		, catx(':', strip(put(a.segment, best.)),'HH15', strip(put(round(f.P_1, .001), best.))) as HH15 length = 20
		, catx(':', strip(put(a.segment, best.)),'HH25', strip(put(round(g.P_1, .001), best.))) as HH25 length = 20
		, catx(':', strip(put(a.segment, best.)),'AH05', strip(put(round(h.P_1, .001), best.))) as AH05 length = 20
		, catx(':', strip(put(a.segment, best.)),'AH15', strip(put(round(i.P_1, .001), best.))) as AH15 length = 20
		, catx(':', strip(put(a.segment, best.)),'AH25', strip(put(round(j.P_1, .001), best.))) as AH25 length = 20
		, a.group as P1_segment
		, b.group as P2_segment
		, c.group as X1_segment
		, d.group as X2_segment
		, e.group as HH05_segment
		, f.group as HH15_segment
		, g.group as HH25_segment
		, h.group as AH05_segment
		, i.group as AH15_segment
		, j.group as AH25_segment
	from score_&season._&round._home_win_score as a
		left join score_&season._&round._away_win_score as b
		on a.season = b.season and a.round = b.round and a.home_team = b.home_team and a.away_team = b.away_team
		left join score_&season._&round._X1_score as c
		on a.season = c.season and a.round = c.round and a.home_team = c.home_team and a.away_team = c.away_team
		left join score_&season._&round._X2_score as d
		on a.season = d.season and a.round = d.round and a.home_team = d.home_team and a.away_team = d.away_team
		left join score_&season._&round._hh05_score as e
		on a.season = e.season and a.round = e.round and a.home_team = e.home_team and a.away_team = e.away_team
		left join score_&season._&round._hh15_score as f
		on a.season = f.season and a.round = f.round and a.home_team = f.home_team and a.away_team = f.away_team
		left join score_&season._&round._hh25_score as g
		on a.season = g.season and a.round = g.round and a.home_team = g.home_team and a.away_team = g.away_team
		left join score_&season._&round._ah05_score as h
		on a.season = h.season and a.round = h.round and a.home_team = h.home_team and a.away_team = h.away_team
		left join score_&season._&round._ah15_score as i
		on a.season = i.season and a.round = i.round and a.home_team = i.home_team and a.away_team = i.away_team
		left join score_&season._&round._ah25_score as j
		on a.season = j.season and a.round = j.round and a.home_team = j.home_team and a.away_team = j.away_team;
quit;




/* CREATE COLOR FORMATS */
data format_01;
	set data_f.prediction_&season._&round;
		length input_value output_value $50;
		
		if P1 ne '' then do;
			input_value = P1;
			output_value = P1_segment;
			output;
		end;
		
		if P2 ne '' then do;
			input_value = P2;
			output_value = P2_segment;
			output;
		end;
		
		if X1 ne '' then do;
			input_value = X1;
			output_value = X1_segment;
			output;
		end;
		
		if X2 ne '' then do;
			input_value = X2;
			output_value = X2_segment;
			output;
		end;
		
		if HH05 ne '' then do;
			input_value = HH05;
			output_value = HH05_segment;
			output;
		end;
		
		if HH15 ne '' then do;
			input_value = HH15;
			output_value = HH15_segment;
			output;
		end;
		
		if HH25 ne '' then do;
			input_value = HH25;
			output_value = HH25_segment;
			output;
		end;
		
		if AH05 ne '' then do;
			input_value = AH05;
			output_value = AH05_segment;
			output;
		end;
		
		if AH15 ne '' then do;
			input_value = AH15;
			output_value = AH15_segment;
			output;
		end;
		
		if AH25 ne '' then do;
			input_value = AH25;
			output_value = AH25_segment;
			output;
		end;
		
		keep input_value output_value;
proc sort nodupkey;
	by _all_;
run;

data format_02;
	set format_01;
		retain fmtname "$fmt_color" type 'C';
		rename input_value = start
			   output_value = label;
run;

proc format cntlin = format_02;
run;

/* SAVE RESULTS TO EXCEL */
ods excel
	file = "/folders/myfolders/footbal/portugal/primeira/excel/pred_por_pri_&season._&round..xlsx"
	options (sheet_name = "&season._&round");
	proc report data = data_f.prediction_&season._&round;
		column season round home_team away_team home_type away_type P1 X1 P2 X2 HH05 HH15 HH25 AH05 AH15 AH25;
		define season / display;
		define round / display;
		define home_team / display;
		define away_team / display;
		define home_type / display;
		define away_type / display;
		define P1 / display style = {background = $fmt_color.};		
		define X1 / display style = {background = $fmt_color.};
		define P2 / display style = {background = $fmt_color.};
		define X2 / display style = {background = $fmt_color.};
		define HH05 / display style = {background = $fmt_color.};
		define HH15 / display style = {background = $fmt_color.};
		define HH25 / display style = {background = $fmt_color.};
		define AH05 / display style = {background = $fmt_color.};
		define AH15 / display style = {background = $fmt_color.};
		define AH25 / display style = {background = $fmt_color.};
	run;
ods excel close;




/* SELECT MOST LIKELY EVENTS */
data data_f.tlg_bot_&season._&round;
	set data_f.prediction_&season._&round;
		length res_blue res_yellow goal_blue goal_yellow $50;
		array colors_group_{*} P1_segment P2_segment X1_segment X2_segment;
		array colors_result_{*} P1 P2 X1 X2;
		array colors_tot_grp_{*} HH05_segment HH15_segment HH25_segment AH05_segment AH15_segment AH25_segment;
		array colors_goal_{*} HH05 HH15 HH25 AH05 AH15 AH25;
		
		call missing(res_blue, res_yellow, goal_blue, goal_yellow);
				
		do i = 1 to dim(colors_group_);
			if colors_group_{i} = "BLUE" then res_blue = catx('/', strip(res_blue), strip(substr(colors_result_{i}, 3)));
			if colors_group_{i} = "YELLOW" then res_yellow = catx('/', strip(res_yellow), strip(substr(colors_result_{i}, 3)));
		end;
		
		do j = 1 to dim(colors_tot_grp_);
			if colors_tot_grp_{j} = "BLUE" then goal_blue = catx('/', strip(goal_blue), strip(substr(colors_goal_{j}, 3)));
			if colors_tot_grp_{j} = "YELLOW" then goal_yellow = catx('/', strip(goal_yellow), strip(substr(colors_goal_{j}, 3)));
		end;
		
		keep season round res_: goal_: home_team away_team;
run;

proc export data = data_f.tlg_bot_&season._&round
	outfile = "/folders/myfolders/footbal/portugal/primeira/excel/por_pri_tlg_bot_&season._&round..xlsx"
	dbms = xlsx
	replace;
run;


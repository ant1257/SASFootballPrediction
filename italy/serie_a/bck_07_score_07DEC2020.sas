libname data_f '/folders/myfolders/footbal/italy/serie_a/data';
libname general "/folders/myfolders/footbal/general";

%let season = 2021;

data _null_;
	set data_f.results_&season end = eof;
		if eof then do;
			call symput('round', compress(put(round + 1, best.)));
		end;
run;

%*let round = 7;

/* SCORING */
%macro score(data, target);
	proc contents data = data_f.&data out = temp_01 noprint;
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

	proc fastclus data = data_f.&data instat = general.clust_stat out = &data._cluster;
		var &std_names;
	run;
	
	proc logistic inmodel = general.model_&target;
		score data = &data._cluster out = &data._&target;
	run;

	data &data._&target;
		set &data._&target;
			length segment $20;
			
			%if &target = home_win %then %do;
				if cluster = 1 then do;
					if p_1 < 0.4252874955 then segment = 'RED';
					else if p_1 < 0.5104673189 then segment = 'GRAY';
					else if p_1 < 0.5797609311 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 2 then do;
					if p_1 < 0.4265699484 then segment = 'RED';
					else if p_1 < 0.532819898 then segment = 'GRAY';
					else if p_1 < 0.6062793244 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 3 then do;
					if p_1 < 0.4001359062 then segment = 'RED';
					else if p_1 < 0.5495006032 then segment = 'GRAY';
					else if p_1 < 0.6230552593 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 4 then do;
					if p_1 < 0.4315150646 then segment = 'RED';
					else if p_1 < 0.5173771666 then segment = 'GRAY';
					else if p_1 < 0.5935287578 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
			%end;
			
			%else %if &target = away_win %then %do;
				if cluster = 1 then do;
					if p_1 < 0.3018668633 then segment = 'RED';
					else segment = 'YELLOW';
				end;
				
				else if cluster = 2 then do;
					if p_1 < 0.2874589491 then segment = 'RED';
					else segment = 'YELLOW';
				end;
				
				else if cluster = 3 then do;
					if p_1 < 0.2974384665 then segment = 'RED';
					else segment = 'YELLOW';
				end;
				
				else if cluster = 4 then do;
					if p_1 < 0.290976945 then segment = 'RED';
					else segment = 'YELLOW';
				end;
			%end;
			
			%else %if &target = x1 %then %do;
				if cluster = 1 then do;
					if p_1 < 0.6981331367 then segment = 'RED';
					else if p_1 < 0.769743081 then segment = 'GRAY';
					else if p_1 < 0.8159455919 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 2 then do;
					if p_1 < 0.7125410509 then segment = 'RED';
					else if p_1 < 0.7944944087 then segment = 'GRAY';
					else if p_1 < 0.842006454 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 3 then do;
					if p_1 < 0.7025615335 then segment = 'RED';
					else if p_1 < 0.8092516721 then segment = 'GRAY';
					else if p_1 < 0.85 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 4 then do;
					if p_1 < 0.709023055 then segment = 'RED';
					else if p_1 < 0.7770483027 then segment = 'GRAY';
					else if p_1 < 0.8285305978 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
			%end;
			
			%else %if &target = x2 %then %do;
				if cluster = 1 then do;
					if p_1 < 0.4895326811 then segment = 'RED';
					else if p_1 < 0.5747125045 then segment = 'GRAY';
					else if p_1 < 0.6391034297 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 2 then do;
					if p_1 < 0.467180102 then segment = 'RED';
					else if p_1 < 0.5734300516 then segment = 'GRAY';
					else if p_1 < 0.6427450505 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 3 then do;
					if p_1 < 0.4504993968 then segment = 'RED';
					else if p_1 < 0.5998640938	 then segment = 'GRAY';
					else if p_1 < 0.6676195259 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 4 then do;
					if p_1 < 0.4826228334 then segment = 'RED';
					else if p_1 < 0.5684849354 then segment = 'GRAY';
					else if p_1 < 0.6368823301 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
			%end;
			
			%else %if &target = HH05 %then %do;
				if cluster = 1 then do;
					if p_1 < 0.7493977972 then segment = 'RED';
					else if p_1 < 0.8170752016 then segment = 'GRAY';
					else if p_1 < 0.848492817 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 2 then do;
					if p_1 < 0.7428317111	 then segment = 'RED';
					else if p_1 < 0.7987093432 then segment = 'GRAY';
					else if p_1 < 0.8307044386 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 3 then do;
					if p_1 < 0.736567013 then segment = 'RED';
					else if p_1 < 0.8238302021	 then segment = 'GRAY';
					else if p_1 < 0.8561538812 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 4 then do;
					if p_1 < 0.7493869249 then segment = 'RED';
					else if p_1 < 0.8070153914 then segment = 'GRAY';
					else if p_1 < 0.8384406344 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
			%end;
			
			%else %if &target = HH15 %then %do;
				if cluster = 1 then do;
					if p_1 < 0.4069131429 then segment = 'RED';
					else if p_1 < 0.5087343453 then segment = 'GRAY';
					else if p_1 < 0.5696763384 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 2 then do;
					if p_1 < 0.407152829 then segment = 'RED';
					else if p_1 < 0.4956979439 then segment = 'GRAY';
					else if p_1 < 0.5430967234 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 3 then do;
					if p_1 < 0.3923200817 then segment = 'RED';
					else if p_1 < 0.5191174071 then segment = 'GRAY';
					else if p_1 < 0.5870382632 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 4 then do;
					if p_1 < 0.4202449289 then segment = 'RED';
					else if p_1 < 0.5067329625 then segment = 'GRAY';
					else if p_1 < 0.5653615848 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
			%end;
			
			%else %if &target = HH25 %then %do;
				if cluster = 1 then do;
					if p_1 < 0.3148950669 then segment = 'RED';
					else segment = 'GRAY';
				end;
				
				else if cluster = 2 then do;
					if p_1 < 0.2891870941 then segment = 'RED';
					else segment = 'GRAY';
				end;
				
				else if cluster = 3 then do;
					if p_1 < 0.3388146396 then segment = 'RED';
					else segment = 'GRAY';
				end;
				
				else if cluster = 4 then do;
					if p_1 < 0.3210418354 then segment = 'RED';
					else segment = 'GRAY';
				end;
			%end;
			
			%else %if &target = AH05 %then %do;
				if cluster = 1 then do;
					if p_1 < 0.6089746909 then segment = 'RED';
					else if p_1 < 0.6808963528 then segment = 'GRAY';
					else if p_1 < 0.7055653967 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 2 then do;
					if p_1 < 0.6167664587	 then segment = 'RED';
					else if p_1 < 0.6797077941 then segment = 'GRAY';
					else if p_1 < 0.6983220258 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 3 then do;
					if p_1 < 0.5984008002 then segment = 'RED';
					else if p_1 < 0.6896288666	 then segment = 'GRAY';
					else if p_1 < 0.7151651312 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 4 then do;
					if p_1 < 0.6159260729 then segment = 'RED';
					else if p_1 < 0.6784325712 then segment = 'GRAY';
					else if p_1 < 0.7040248616 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
			%end;
			
			%else %if &target = AH15 %then %do;
				if cluster = 1 then do;
					if p_1 < 0.6089746909 then segment = 'RED';
					else if p_1 < 0.6808963528 then segment = 'GRAY';
					else if p_1 < 0.7055653967 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 2 then do;
					if p_1 < 0.6167664587	 then segment = 'RED';
					else if p_1 < 0.6797077941 then segment = 'GRAY';
					else if p_1 < 0.6983220258 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 3 then do;
					if p_1 < 0.5984008002 then segment = 'RED';
					else if p_1 < 0.6896288666	 then segment = 'GRAY';
					else if p_1 < 0.7151651312 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
				
				else if cluster = 4 then do;
					if p_1 < 0.6159260729 then segment = 'RED';
					else if p_1 < 0.6784325712 then segment = 'GRAY';
					else if p_1 < 0.7040248616 then segment = 'YELLOW';
					else segment = 'BLUE';
				end;
			%end;
			
			%else %if &target = AH25 %then %do;
				if p_1 < 0.4 then segment = 'RED';
				else segment = 'GRAY';
			%end;
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
proc sql;
	create table data_f.prediction_&season._&round as
	select
		a.season
		, a.round
		, a.home_team
		, a.away_team
		, catx(':', strip(put(a.cluster, best.)), 'P1', strip(put(round(a.P_1, .001), best.))) as P1 length = 20
		, catx(':', strip(put(a.cluster, best.)),'P2', strip(put(round(b.P_1, .001), best.))) as P2 length = 20
		, catx(':', strip(put(a.cluster, best.)),'X1', strip(put(round(c.P_1, .001), best.))) as X1 length = 20
		, catx(':', strip(put(a.cluster, best.)),'X2', strip(put(round(d.P_1, .001), best.))) as X2 length = 20
		, catx(':', strip(put(a.cluster, best.)),'HH05', strip(put(round(e.P_1, .001), best.))) as HH05 length = 20
		, catx(':', strip(put(a.cluster, best.)),'HH15', strip(put(round(f.P_1, .001), best.))) as HH15 length = 20
		, catx(':', strip(put(a.cluster, best.)),'HH25', strip(put(round(g.P_1, .001), best.))) as HH25 length = 20
		, catx(':', strip(put(a.cluster, best.)),'AH05', strip(put(round(h.P_1, .001), best.))) as AH05 length = 20
		, catx(':', strip(put(a.cluster, best.)),'AH15', strip(put(round(i.P_1, .001), best.))) as AH15 length = 20
		, catx(':', strip(put(a.cluster, best.)),'AH25', strip(put(round(j.P_1, .001), best.))) as AH25 length = 20
		, a.segment as P1_segment
		, b.segment as P2_segment
		, c.segment as X1_segment
		, d.segment as X2_segment
		, e.segment as HH05_segment
		, f.segment as HH15_segment
		, g.segment as HH25_segment
		, h.segment as AH05_segment
		, i.segment as AH15_segment
		, j.segment as AH25_segment
	from score_&season._&round._home_win as a
		left join score_&season._&round._away_win as b
		on a.season = b.season and a.round = b.round and a.home_team = b.home_team and a.away_team = b.away_team
		left join score_&season._&round._X1 as c
		on a.season = c.season and a.round = c.round and a.home_team = c.home_team and a.away_team = c.away_team
		left join score_&season._&round._X2 as d
		on a.season = d.season and a.round = d.round and a.home_team = d.home_team and a.away_team = d.away_team
		left join score_&season._&round._HH05 as e
		on a.season = e.season and a.round = e.round and a.home_team = e.home_team and a.away_team = e.away_team
		left join score_&season._&round._HH15 as f
		on a.season = f.season and a.round = f.round and a.home_team = f.home_team and a.away_team = f.away_team
		left join score_&season._&round._HH25 as g
		on a.season = g.season and a.round = g.round and a.home_team = g.home_team and a.away_team = g.away_team
		left join score_&season._&round._AH05 as h
		on a.season = h.season and a.round = h.round and a.home_team = h.home_team and a.away_team = h.away_team
		left join score_&season._&round._AH15 as i
		on a.season = i.season and a.round = i.round and a.home_team = i.home_team and a.away_team = i.away_team
		left join score_&season._&round._AH25 as j
		on a.season = j.season and a.round = j.round and a.home_team = j.home_team and a.away_team = j.away_team;
quit;




/* CREATE COLOR FORMATS */
data format_01;
	set data_f.prediction_&season._&round;
		length input_value output_value $20;
		
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
	file = "/folders/myfolders/footbal/italy/serie_a/excel/pred_ita_sa_&season._&round..xlsx"
	options (sheet_name = "&season._&round");
	proc report data = data_f.prediction_&season._&round;
		column season round home_team away_team P1 X1 P2 X2 HH05 HH15 HH25 AH05 AH15 AH25;
		define season / display;
		define round / display;
		define home_team / display;
		define away_team / display;
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
	outfile = "/folders/myfolders/footbal/italy/serie_a/excel/ita_sa_tlg_bot_&season._&round..xlsx"
	dbms = xlsx
	replace;
run;


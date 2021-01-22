/* libraries */
libname ml  "/folders/myfolders/footbal/belarus/major_league/data";
libname epl "/folders/myfolders/footbal/england/epl/data";
libname bl1 "/folders/myfolders/footbal/germany/bundesliga1/data";
libname sa  "/folders/myfolders/footbal/italy/serie_a/data";
*libname kor "/folders/myfolders/footbal/korea/k_league/data";
*libname por "/folders/myfolders/footbal/portugal/primeira/data";
libname ll  "/folders/myfolders/footbal/spain/laliga/data";
libname general "/folders/myfolders/footbal/general";


/* COLLECTING TRAIN DATA */
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

%apply_clusters(home, train_01);
%apply_clusters(away, train_01);

proc sql;
	create table train_02 as
	select a.*
			, b.away_cluster
			, input(cat(strip(put(a.home_cluster, best.)), strip(put(b.away_cluster, best.))), best.) as game_cluster
	from dat_home as a
	left join dat_away as b on a.season = b.season
		and a.round = b.round
		and a.home_team = b.home_team
		and a.away_team = b.away_team;
quit;

data train_02;
	set train_02;
		if game_cluster in (53, 45, 12, 25, 11) then segment = 1;
		if game_cluster in (13, 43) then segment = 2;
		if game_cluster in (15, 23, 33) then segment = 3;
		if game_cluster in (51, 35, 54, 14, 34, 24, 52, 44) then segment = 4;
		if game_cluster in (42, 41, 22, 55, 21) then segment = 5;
		if game_cluster in (31, 32) then segment = 6;
run;



/* TRAIN MODELS */
proc contents data = train_02 out = temp_01 noprint;
run;

proc sort data = temp_01;
	by varnum;
run;

proc sql noprint;
	select name
	into : std_names
	separated by ' '
	from temp_01
	where upcase(name) ^in ('HOME_SCORED', 'AWAY_SCORED', 'HOME_WIN', 'AWAY_WIN', 'DRAW', 'HOME_TEAM', 'AWAY_TEAM', 'SEASON', 'X1', 'X2', 'HH05', 'HH15', 'HH25', 'AH05', 'AH15', 'AH25', 'GAME_CLUSTER', 'SEGMENT');
quit;

%macro model_by_cluster(cluster_num, target);
	proc logistic data = train_02 (where = (strip(put(segment, best.)) = "&cluster_num")) outmodel = general.model_&target._cluster_&cluster_num;
		model &target(event = '1') = &std_names /
		maxiter = 50
		selection = forward;
	run;
%mend model_by_cluster;


%macro train(target);
	%do i = 1 %to 6;
		%model_by_cluster(%eval(&i), &target);
	%end;
%mend;

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






/* APPLY SCORING CODE */
%macro train_score(data, target);
	title "&data &target";
	
	%apply_clusters(home, &data);
	%apply_clusters(away, &data);
	
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
			score fitstat data = &data._prep_01 (where = (strip(put(segment, best.)) = "&i")) out = &data._&target._&i;
		run;
		
		proc freq data = &data._&target._&i;
			tables &target * I_&target / norow;
		run;
		
		proc sort data = &data._&target._&i;
			by &target p_1 p_0;
		run;
		
		proc boxplot data = &data._&target._&i;
			plot p_1 * &target / outbox = p_1_cluster_&i;
		run;
		
		data cutoffs_&target._cluster_&i;
			set p_1_cluster_&i end = eof;

				retain gray_value yellow_value blue_value;
				
				if &target = 1 and _type_ = 'Q1' then gray_value = round(_value_, .001);
				if &target = 0 and _type_ = 'Q3' then yellow_value = round(_value_, .001);
				if &target = 1 and _type_ = 'Q3' then blue_value = round(_value_, .001);
				
				if eof;
				keep gray_value yellow_value blue_value;
		run;
		
		data general.cutoffs_&target._cluster_&i;
			set cutoffs_&target._cluster_&i;
		run;
		
		proc sql;
			create table &data._&target._&i._score as
			select a.*
					, b.*
			from &data._&target._&i as a
			full join cutoffs_&target._cluster_&i as b on 1 = 1;
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
		
		proc freq data = &data._&target._&i._score;
			tables group * &target / nocol norow;
		run;
		
		proc append data = &data._&target._&i._score base = &data._&target._score;
		run;
	%end;
%mend train_score;

%train_score(train_01, home_win);
%train_score(train_01, away_win);
%train_score(train_01, X1);
%train_score(train_01, X2);
%train_score(train_01, HH05);
%train_score(train_01, HH15);
%train_score(train_01, HH25);
%train_score(train_01, AH05);
%train_score(train_01, AH15);
%train_score(train_01, AH25);









/* TEST */
data test_01;
	set 
		ml.test
		epl.test
		bl1.test
		sa.test
		ll.test		
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
proc sort nodupkey;
	by season round home_team away_team;
run;

data test_01;
	set test_01;
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

%macro test_score(data, target);
	title "&data &target";
	
	%apply_clusters(home, &data);
	%apply_clusters(away, &data);
	
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
			score fitstat data = &data._prep_01 (where = (strip(put(segment, best.)) = "&i")) out = &data._&target._&i;
		run;
		
		proc freq data = &data._&target._&i;
			tables &target * I_&target / norow;
		run;
		
		proc sql;
			create table &data._&target._&i._score as
			select a.*
					, b.*
			from &data._&target._&i as a
			full join cutoffs_&target._cluster_&i as b on 1 = 1;
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
		
		proc freq data = &data._&target._&i._score;
			tables group * &target / nocol norow;
		run;
		
		proc append data = &data._&target._&i._score base = &data._&target._score;
		run;
	%end;
%mend test_score;

%test_score(test_01, home_win);
%test_score(test_01, away_win);
%test_score(test_01, X1);
%test_score(test_01, X2);
%test_score(test_01, HH05);
%test_score(test_01, HH15);
%test_score(test_01, HH25);
%test_score(test_01, AH05);
%test_score(test_01, AH15);
%test_score(test_01, AH25);



/* SAVE RESULTS */
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
	create table test_predictions as
	select
		a.season
		, a.round
		, a.home_team
		, a.away_team
		, a.home_scored
		, a.away_scored
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
	from test_01_home_win_score as a
		left join test_01_away_win_score as b
		on a.season = b.season and a.round = b.round and a.home_team = b.home_team and a.away_team = b.away_team
		left join test_01_X1_score as c
		on a.season = c.season and a.round = c.round and a.home_team = c.home_team and a.away_team = c.away_team
		left join test_01_X2_score as d
		on a.season = d.season and a.round = d.round and a.home_team = d.home_team and a.away_team = d.away_team
		left join test_01_HH05_score as e
		on a.season = e.season and a.round = e.round and a.home_team = e.home_team and a.away_team = e.away_team
		left join test_01_HH15_score as f
		on a.season = f.season and a.round = f.round and a.home_team = f.home_team and a.away_team = f.away_team
		left join test_01_HH25_score as g
		on a.season = g.season and a.round = g.round and a.home_team = g.home_team and a.away_team = g.away_team
		left join test_01_AH05_score as h
		on a.season = h.season and a.round = h.round and a.home_team = h.home_team and a.away_team = h.away_team
		left join test_01_AH15_score as i
		on a.season = i.season and a.round = i.round and a.home_team = i.home_team and a.away_team = i.away_team
		left join test_01_AH25_score as j
		on a.season = j.season and a.round = j.round and a.home_team = j.home_team and a.away_team = j.away_team;
quit;
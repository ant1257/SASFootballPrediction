libname data_f '/folders/myfolders/footbal/england/epl/data';

%let season = 2021;

data _null_;
	set data_f.results_&season end = eof;
		if eof then do;
			call symput('round', compress(put(round + 1, best.)));
		end;
run;

%macro get_real_score_data;
  %let web_site = https://www.fussballdaten.de/england/&season/&round/;

  filename src temp;
  proc http
    method = "GET"
    url = "&web_site"
    out = src;
  run;

  data whole_page_&season._&round;
    infile src length = len lrecl = 32767;
    input line $varying32767. len;
      line = strip(line);
  run;
  filename src clear;

  data temp_&season._&round;
    set whole_page_&season._&round;
      length temp_value $500;
      i = 1;
      var1 = cat('HREF="/ENGLAND/', "&season", '/', "&round", '/STATISTIK/"');
      
      if index(upcase(line), upcase(compress(var1)))
          and length(line) >= 6000;

      	temp_var = strip(line);

      	do while(index(upcase(temp_var), '" CLASS="" HREF="/ENGLAND/'));
        	start_symbol = index(upcase(temp_var), '" CLASS="" HREF="/ENGLAND/');
        	end_symbol = index(upcase(temp_var), 'PREMIER LEAGUE)"><SPAN>');

        	temp_value = substr(temp_var, start_symbol, end_symbol - start_symbol);
        	temp_var = substr(temp_var, end_symbol + 23);
        	i + 1;

        	output;

        	if i > 20 then do;
          		put 'WAR'"NING: CHECK DATA";
          		leave;
        	end;
      	end;

      keep temp_value;
  run;

  data fixtures_&season._&round;
    set temp_&season._&round;
      length game $50;

      season = &season;
      round = &round;
      game = scan(substr(temp_value, index(temp_value, 'href=') + 5, index(temp_value, 'title') - (index(temp_value, 'href=') + 5)), 5, '/');;
      keep season round game;
  run;

  data results_ditailed_&season._&round;
    set fixtures_&season._&round;
      length home_team away_team $50;

      home_team = scan(game, 1, '-');
/*       select(home_team); */
/*         when('vfbstuttgar') home_team = 'vfbstuttgart'; */
/*         when('bayern') home_team = 'bmuenchen'; */
/*         when('koeln') home_team = 'fckoeln'; */
/*         otherwise home_team = home_team; */
/*       end; */

      away_team = scan(game, 2, '-');
/*       select(away_team); */
/*         when('vfbstuttgar') away_team = 'vfbstuttgart'; */
/*         when('bayern') away_team = 'bmuenchen'; */
/*         when('koeln') away_team = 'fckoeln'; */
/*         otherwise away_team = away_team; */
/*       end; */

      drop game;
  run;

  data teams_list_&season._&round;
    set results_ditailed_&season._&round;
      length name $50;
      name = home_team;
      output;

      name = away_team;
      output;

      keep name;
  proc sort nodupkey;
    by name;
  run;

  proc datasets lib = work nolist;
    delete teams_list_&season._round team_form_&season._&round: team_analysis_&season: teams_list_&season ;
  run;

  %do i = 1 %to 20;
    data _null_;
      set teams_list_&season._&round;
        if _n_ = &i then call symput('team_name', strip(name));
    run;

    data team_form_&season._&round._&team_name;
      set data_f.RESULTS_DITAILED_&season;
        where home_team = "&team_name" or away_team = "&team_name";

        length team_name $50;

        team_name = "&team_name";

        if home_team = "&team_name" then do;
          current_form + home_win - away_win;

          total_wins + home_win;
          total_draws + draw;
          total_loses + away_win;

          total_goles_scored + home_scored;
          total_goles_conceded + home_conceded;

          total_home_wins + home_win;
          total_home_draws + draw;
          total_home_loses + away_win;

          total_home_goles_scored + home_scored;
          total_home_goles_conceded + home_conceded;

          total_home_games + 1;
          total_points + (home_win * 3) + draw;
          total_home_points + (home_win * 3) + draw;
        end;

        if away_team = "&team_name" then do;
          current_form + away_win - home_win;

          total_wins + away_win;
          total_draws + draw;
          total_loses + home_win;

          total_goles_scored + away_scored;
          total_goles_conceded + away_conceded;

          total_away_wins + away_win;
          total_away_draws + draw;
          total_away_loses + home_win;

          total_away_goles_scored + away_scored;
          total_away_goles_conceded + away_conceded;

          total_away_games + 1;
          total_points + (away_win * 3) + draw;
          total_away_points + (away_win * 3) + draw;
        end;
    run;

    %macro prob_count(var);
      %if %sysfunc(index("&var", %str(home))) %then %do;
        prob_&var = round((&var / total_home_games), 0.01);
      %end;

      %else %if %sysfunc(index("&var", %str(away))) %then %do;
        prob_&var = round((&var / total_away_games), 0.01);
      %end;

      %else %do;
        prob_&var = round((&var / round), 0.01);
      %end;
    %mend prob_count;

    %macro avg_count(var);
      %if %sysfunc(index("&var", %str(home))) %then %do;
        avg_&var = round((&var / total_home_games), 0.01);
      %end;

      %else %if %sysfunc(index("&var", %str(away))) %then %do;
        avg_&var = round((&var / total_away_games), 0.01);
      %end;

      %else %do;
        avg_&var = round((&var / round), 0.01);
      %end;
    %mend avg_count;

    data team_form_&season._&round._&team_name;
      set team_form_&season._&round._&team_name;
        %prob_count(total_wins);
        %prob_count(total_draws);
        %prob_count(total_loses);

        %prob_count(total_home_wins);
        %prob_count(total_home_draws);
        %prob_count(total_home_loses);

        %prob_count(total_away_wins);
        %prob_count(total_away_draws);
        %prob_count(total_away_loses);

        %avg_count(total_goles_scored);
        %avg_count(total_goles_conceded);

        %avg_count(total_away_goles_scored);
        %avg_count(total_away_goles_conceded);

        %avg_count(total_home_goles_scored);
        %avg_count(total_home_goles_conceded);

        %avg_count(total_points);
        %avg_count(total_home_points);
        %avg_count(total_away_points);

        %avg_count(current_form);

        round = round + 1;
        if round = &round then output;
        keep season round team_name avg_: prob_: ;
    run;

    proc append base = team_analysis_&season._&round data = team_form_&season._&round._&team_name;
    run;
  %end;

  proc sql;
    create table data_f.score_&season._&round as
    select a.season
          , a.round
          , a.home_team
          , a.away_team
          , 0 as home_win
          , 0 as draw
          , 0 as away_win
          , b.prob_total_wins as home_prob_total_wins
          , b.prob_total_draws as home_prob_total_draws
          , b.prob_total_loses as home_prob_total_loses
          , b.prob_total_home_wins
          , b.prob_total_home_draws
          , b.prob_total_home_loses		
          , b.avg_total_goles_scored as home_avg_total_goles_scored
          , b.avg_total_goles_conceded as home_avg_total_goles_conceded
          , b.avg_total_home_goles_scored
          , b.avg_total_home_goles_conceded
          , b.avg_total_points as home_avg_total_points
          , b.avg_total_home_points
          , b.avg_current_form as home_team_form
          , c.prob_total_wins as away_prob_total_wins
          , c.prob_total_draws as away_prob_total_draws
          , c.prob_total_loses as away_prob_total_loses
          , c.prob_total_away_wins		
          , c.prob_total_away_draws		
          , c.prob_total_away_loses
          , c.avg_total_goles_scored as away_avg_total_goles_scored
          , c.avg_total_goles_conceded as away_avg_total_goles_conceded
          , c.avg_total_away_goles_scored
          , c.avg_total_away_goles_conceded
          , c.avg_total_points as away_avg_total_points
          , c.avg_total_away_points
          , c.avg_current_form as away_team_form
    from results_ditailed_&season._&round as a
      left join team_analysis_&season._&round as b on a.round = b.round and a.home_team = b.team_name
      left join team_analysis_&season._&round as c on a.round = c.round and a.away_team = c.team_name;
  quit;
%mend get_real_score_data;

%get_real_score_data;


data score_&season._&round;
	set data_f.score_&season._&round;
run;

%macro add_missing;
	%let check_home = 1;
	%let count_home = 0;
	
	%let check_away = 1;
	%let count_away = 0;
	
	%do %while(&check_home > 0);
		proc sql noprint;
			select count(*)
			into : check_home
			from score_&season._&round
			where home_prob_total_wins = .;
		quit;
		
		%put &check_home;
		%put &count_home;
		
		%if &check_home > 0 %then %do;
			data _null_;
				call symput('count_home', &count_home + 1);
			run;
			
			proc sql;
				create table temp_home as 
				select a.season
			          , a.round
			          , a.home_team
			          , a.away_team
			          , b.prob_total_wins as home_prob_total_wins
			          , b.prob_total_draws as home_prob_total_draws
			          , b.prob_total_loses as home_prob_total_loses
			          , b.prob_total_home_wins
			          , b.prob_total_home_draws
			          , b.prob_total_home_loses		
			          , b.avg_total_goles_scored as home_avg_total_goles_scored
			          , b.avg_total_goles_conceded as home_avg_total_goles_conceded
			          , b.avg_total_home_goles_scored
			          , b.avg_total_home_goles_conceded
			          , b.avg_total_points as home_avg_total_points
			          , b.avg_total_home_points
			          , b.avg_current_form as home_team_form
	          	from (select * from score_&season._&round where home_prob_total_wins = .) as a
	          		left join (select *, &round as score_round
					from data_f.team_analysis_&season
					where round = &round - &count_home) as b on a.round = b.score_round and a.home_team = b.team_name
					;
			quit;
			
			proc sql;
				create table temp_home_02 as
				select a.season
			          , a.round
			          , a.home_team
			          , a.away_team
			          , a.home_win
			          , a.draw
			          , a.away_win
			          , a.home_prob_total_wins
			          , a.home_prob_total_draws
			          , a.home_prob_total_loses
			          , a.prob_total_home_wins
			          , a.prob_total_home_draws
			          , a.prob_total_home_loses		
			          , a.home_avg_total_goles_scored
			          , a.home_avg_total_goles_conceded
			          , a.avg_total_home_goles_scored
			          , a.avg_total_home_goles_conceded
			          , a.home_avg_total_points
			          , a.avg_total_home_points
			          , a.home_team_form
			          , a.away_prob_total_wins
			          , a.away_prob_total_draws
			          , a.away_prob_total_loses
			          , a.prob_total_away_wins		
			          , a.prob_total_away_draws		
			          , a.prob_total_away_loses
			          , a.away_avg_total_goles_scored
			          , a.away_avg_total_goles_conceded
			          , a.avg_total_away_goles_scored
			          , a.avg_total_away_goles_conceded
			          , a.away_avg_total_points
			          , a.avg_total_away_points
			          , a.away_team_form
			          , b.home_prob_total_wins as home_prob_total_wins_
			          , b.home_prob_total_draws as home_prob_total_draws_
			          , b.home_prob_total_loses as home_prob_total_loses_
			          , b.prob_total_home_wins as prob_total_home_wins_
			          , b.prob_total_home_draws as prob_total_home_draws_
			          , b.prob_total_home_loses as prob_total_home_loses_
			          , b.home_avg_total_goles_scored as home_avg_total_goles_scored_
			          , b.home_avg_total_goles_conceded as home_avg_total_goles_conceded_
			          , b.avg_total_home_goles_scored as avg_total_home_goles_scored_
			          , b.avg_total_home_goles_conceded as avg_total_home_goles_conceded_
			          , b.home_avg_total_points as home_avg_total_points_
			          , b.avg_total_home_points as avg_total_home_points_
			          , b.home_team_form as home_team_form_
				from score_&season._&round as a
					left join temp_home as b on a.round = b.round and a.home_team = b.home_team;
			quit;
			
			%macro change_value(var);
				if &var = . then &var = &var._;
				drop &var._;
			%mend;
			
			data score_&season._&round;
				set temp_home_02;
					%change_value(home_prob_total_wins);
					%change_value(home_prob_total_draws);
					%change_value(home_prob_total_loses);
					%change_value(prob_total_home_wins);
					%change_value(prob_total_home_draws);
					%change_value(prob_total_home_loses);
					%change_value(home_avg_total_goles_scored);
					%change_value(home_avg_total_goles_conceded);
					%change_value(avg_total_home_goles_scored);
					%change_value(avg_total_home_goles_conceded);
					%change_value(home_avg_total_points);
					%change_value(avg_total_home_points);
					%change_value(home_team_form);
			run;
		%end;
	%end;
	
	
	%do %while(&check_away > 0);
		proc sql noprint;
			select count(*)
			into : check_away
			from score_&season._&round
			where away_prob_total_wins = .;
		quit;
		
		%put &check_away;
		%put &count_away;
		
		%if &check_away > 0 %then %do;
			data _null_;
				call symput('count_away', &count_away + 1);
			run;
			
			proc sql;
				create table temp_away as 
				select a.season
			          , a.round
			          , a.home_team
			          , a.away_team
			          , b.prob_total_wins as away_prob_total_wins
			          , b.prob_total_draws as away_prob_total_draws
			          , b.prob_total_loses as away_prob_total_loses
			          , b.prob_total_away_wins		
			          , b.prob_total_away_draws		
			          , b.prob_total_away_loses
			          , b.avg_total_goles_scored as away_avg_total_goles_scored
			          , b.avg_total_goles_conceded as away_avg_total_goles_conceded
			          , b.avg_total_away_goles_scored
			          , b.avg_total_away_goles_conceded
			          , b.avg_total_points as away_avg_total_points
			          , b.avg_total_away_points
			          , b.avg_current_form as away_team_form
	          	from (select * from score_&season._&round where away_prob_total_wins = .) as a
	          		left join (select *, &round as score_round
					from data_f.team_analysis_&season
					where round = &round - &count_away) as b on a.round = b.score_round and a.away_team = b.team_name
					;
			quit;
			
			proc sql;
				create table temp_away_02 as
				select a.season
			          , a.round
			          , a.home_team
			          , a.away_team
			          , a.home_win
			          , a.draw
			          , a.away_win
			          , a.home_prob_total_wins
			          , a.home_prob_total_draws
			          , a.home_prob_total_loses
			          , a.prob_total_home_wins
			          , a.prob_total_home_draws
			          , a.prob_total_home_loses		
			          , a.home_avg_total_goles_scored
			          , a.home_avg_total_goles_conceded
			          , a.avg_total_home_goles_scored
			          , a.avg_total_home_goles_conceded
			          , a.home_avg_total_points
			          , a.avg_total_home_points
			          , a.home_team_form
			          , a.away_prob_total_wins
			          , a.away_prob_total_draws
			          , a.away_prob_total_loses
			          , a.prob_total_away_wins		
			          , a.prob_total_away_draws		
			          , a.prob_total_away_loses
			          , a.away_avg_total_goles_scored
			          , a.away_avg_total_goles_conceded
			          , a.avg_total_away_goles_scored
			          , a.avg_total_away_goles_conceded
			          , a.away_avg_total_points
			          , a.avg_total_away_points
			          , a.away_team_form
			          , b.away_prob_total_wins as away_prob_total_wins_
			          , b.away_prob_total_draws as away_prob_total_draws_
			          , b.away_prob_total_loses as away_prob_total_loses_
			          , b.prob_total_away_wins as prob_total_away_wins_
			          , b.prob_total_away_draws as prob_total_away_draws_
			          , b.prob_total_away_loses as prob_total_away_loses_
			          , b.away_avg_total_goles_scored as away_avg_total_goles_scored_
			          , b.away_avg_total_goles_conceded as away_avg_total_goles_conceded_
			          , b.avg_total_away_goles_scored as avg_total_away_goles_scored_
			          , b.avg_total_away_goles_conceded as avg_total_away_goles_conceded_
			          , b.away_avg_total_points as away_avg_total_points_
			          , b.avg_total_away_points as avg_total_away_points_
			          , b.away_team_form as away_team_form_
				from score_&season._&round as a
					left join temp_away as b on a.round = b.round and a.away_team = b.away_team;
			quit;
			
			%macro change_value(var);
				if &var = . then &var = &var._;
				drop &var._;
			%mend;
			
			data score_&season._&round;
				set temp_away_02;
					%change_value(away_prob_total_wins);
					%change_value(away_prob_total_draws);
					%change_value(away_prob_total_loses);
					%change_value(prob_total_away_wins);
					%change_value(prob_total_away_draws);
					%change_value(prob_total_away_loses);
					%change_value(away_avg_total_goles_scored);
					%change_value(away_avg_total_goles_conceded);
					%change_value(avg_total_away_goles_scored);
					%change_value(avg_total_away_goles_conceded);
					%change_value(away_avg_total_points);
					%change_value(avg_total_away_points);
					%change_value(away_team_form);
			run;
		%end;
	%end;
%mend add_missing;

%add_missing;

data data_f.score_&season._&round;
	set score_&season._&round;
run;


/* proc export data = data_f.score_&season._&round */
/*   outfile = '/folders/myfolders/footbal/england/epl/csv/score.csv' */
/*   dbms = csv */
/*   replace; */
/* run; */

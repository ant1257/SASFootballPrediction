libname data_f '/folders/myfolders/footbal/portugal/primeira/data';

%let current_season = 2021;

%macro get_results(season);
  proc datasets library = work nolist;
    delete whole_page_&season: fixtures_&season: results_&season: game_&season: ;
  run;

  %do round = 1 %to 34;
    %let web_site = https://www.fussballdaten.de/portugal/&season/&round/;

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
        var1 = cat('HREF="/PORTUGAL/', "&season", '/', "&round", '/STATISTIK/"');
        if index(upcase(line), upcase(compress(var1)))
            and index(upcase(line), 'BEGEGNUNGEN');

        temp_var = strip(line);

        do while(index(upcase(temp_var), 'CLASS="ERGEBNIS"'));
          start_symbol = index(upcase(temp_var), 'CLASS="ERGEBNIS"');
          
          if index(upcase(temp_var), 'TITLE="SPIELDETAILS:') then do;
          	end_symbol = index(upcase(temp_var), '</SPAN><SPAN>');
          	plus = 13;
          end;
          
          else do;
          	end_symbol = index(upcase(temp_var), 'TITLE=""><SPAN>');
          	plus = 13;
          end;

          temp_value = substr(temp_var, start_symbol, end_symbol - start_symbol);
          temp_var = substr(temp_var, end_symbol + plus);
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
        length game $50 result $10;

        season = &season;
        round = &round;
        game = scan(substr(temp_value, index(temp_value, 'href=') + 5, index(temp_value, 'title') - (index(temp_value, 'href=') + 5)), 5, '/');
        if index(upcase(temp_value), '><SPAN ID="') then do;
        	result = strip(scan(temp_value, -1, '>'));
        end;
        
        else do;
        	result = '';
        end;
        keep season round game result;
    run;

    proc append base = results_&season data = fixtures_&season._&round;
    run;
  %end;

  proc datasets lib = work nolist;
    delete temp_: whole_: fixtures_&season: game_: ;
  run;

  data data_f.RESULTS_&season;
    set RESULTS_&season (where = (result ne ''));
  run;
%mend get_results;

%get_results(&current_season);






%macro get_stat(season);
  proc datasets lib = work nolist;
    delete team_analysis_&season results_ditailed_&season teams_list_&season team_form_&season: ;
  run;

  data results_ditailed_&season;
    set data_f.results_&season;
      length home_team away_team $50;

      home_team = scan(game, 1, '-');
      select(home_team);
        when('deportivosantaclara') home_team = 'santaclara';
        when('cdsantaclara') home_team = 'santaclara';
        when('benficalissabon') home_team = 'benfica';
        when('scfarense') home_team = 'farense';
        when('sportinglissabon') home_team = 'sporting';
        when('sportinglissa') home_team = 'sporting';
        when('sportingfarense') home_team = 'farense';
        when('cdnacional') home_team = 'nacional';
        when('desportivoaves') home_team = 'aves';
        when('boavista') home_team = 'boavistaporto';
        when('moreirensefc') home_team = 'moreirense';
        when('csmaritimo') home_team = 'madeira';
        when('maritimonacional') home_team = 'madeira';
        when('maritimomadeira') home_team = 'madeira';
        when('cfbelenenses') home_team = 'belenenses';
        when('estoril') home_team = 'gdestoril';
        when('naval1') home_team = 'naval1demaio';
        when('1') home_team = 'naval1demaio';
        when('fcpenafiel') home_team = 'penafiel';
        when('scbeiramar') home_team = 'beiramar';
        when('uniaoleiria') home_team = 'leiria';
        when('sccampomaiorense') home_team = 'campomaiorense';
        when('academicadecoimbra') home_team = 'coimbra';
        when('gilvicente') home_team = 'vicente';
        when('rioavefc') home_team = 'ave';
        when('sportingbraga') home_team = 'braga';
        when('vitoriaguimaraes') home_team = 'guimaraes';
        when('vitoriasetubal') home_team = 'setubal';
        otherwise home_team = home_team;
      end;

      away_team = scan(game, 2, '-');
      select(away_team);
        when('deportivosantaclara') away_team = 'santaclara';
        when('cdsantaclara') away_team = 'santaclara';
        when('benficalissabon') away_team = 'benfica';
        when('scfarense') away_team = 'farense';
        when('sportinglissabon') away_team = 'sporting';
        when('sportinglissa') away_team = 'sporting';
        when('sportingfarense') away_team = 'farense';
        when('cdnacional') away_team = 'nacional';
        when('desportivoaves') away_team = 'aves';
        when('boavista') away_team = 'boavistaporto';
        when('moreirensefc') away_team = 'moreirense';
        when('csmaritimo') away_team = 'madeira';
        when('maritimonacional') away_team = 'madeira';
        when('maritimomadeira') away_team = 'madeira';
        when('cfbelenenses') away_team = 'belenenses';
        when('estoril') away_team = 'gdestoril';
        when('naval1') away_team = 'naval1demaio';
        when('1') away_team = 'naval1demaio';
        when('fcpenafiel') away_team = 'penafiel';
        when('scbeiramar') away_team = 'beiramar';
        when('uniaoleiria') away_team = 'leiria';
        when('sccampomaiorense') away_team = 'campomaiorense';
        when('academicadecoimbra') away_team = 'coimbra';
        when('gilvicente') away_team = 'vicente';
        when('rioavefc') away_team = 'ave';
        when('sportingbraga') away_team = 'braga';
        when('vitoriaguimaraes') away_team = 'guimaraes';
        when('vitoriasetubal') away_team = 'setubal';
        otherwise away_team = away_team;
      end;

      home_scored = input(scan(result, 1, ':'), ?? best.);
      home_conceded = input(scan(result, 2, ':'), ?? best.);

      away_scored = input(scan(result, 2, ':'), ?? best.);
      away_conceded = input(scan(result, 1, ':'), ?? best.);

      home_win = ifn(home_scored > home_conceded, 1, 0);
      draw = ifn(home_scored = away_scored, 1, 0);
      away_win = ifn(away_scored > away_conceded, 1, 0);

      drop game result;
  run;

  data data_f.results_ditailed_&season;
    set results_ditailed_&season;
  run;

  data teams_list_&season;
    set results_ditailed_&season;
      keep home_team;
      rename home_team = name;
  proc sort nodupkey;
    by name;
  run;

  %do i = 1 %to 18;
    data _null_;
      set teams_list_&season;
        if _n_ = &i then call symput('team_name', strip(name));
    run;

    %put &team_name;

    data team_form_&season._&team_name;
      set results_ditailed_&season;
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
        prob_&var = round(lag(&var) / (lag(total_home_games)), 0.01);
      %end;

      %else %if %sysfunc(index("&var", %str(away))) %then %do;
        prob_&var = round(lag(&var) / (lag(total_away_games)), 0.01);
      %end;

      %else %do;
        prob_&var = round(lag(&var) / (lag(round)), 0.01);
      %end;
    %mend prob_count;

    %macro avg_count(var);
      %if %sysfunc(index("&var", %str(home))) %then %do;
        avg_&var = round(lag(&var) / (lag(total_home_games)), 0.01);
      %end;

      %else %if %sysfunc(index("&var", %str(away))) %then %do;
        avg_&var = round(lag(&var) / (lag(total_away_games)), 0.01);
      %end;

      %else %do;
        avg_&var = round(lag(&var) / (lag(round)), 0.01);
      %end;
    %mend avg_count;

    data team_form_&season._&team_name;
      set team_form_&season._&team_name;
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

        keep season round team_name avg_: prob_: ;
    run;

    proc append base = team_analysis_&season data = team_form_&season._&team_name;
    run;
  %end;

 data data_f.results_ditailed_&season;
   set results_ditailed_&season;
 run;

  proc datasets lib = work nolist;
    delete team_form_&season: teams_list_&season results_ditailed_&season;
  run;

  data data_f.team_analysis_&season;
    set team_analysis_&season;
  run;
%mend get_stat;

%get_stat(&current_season);



%macro get_score_dm(season);
  proc sql;
    create table data_f.season_&season._dm as
    select a.season
          , a.round
          , a.home_team
          , a.away_team
          , a.home_scored
          , a.away_scored
          , a.home_win
          , a.draw
          , a.away_win
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
    from data_f.results_ditailed_&season as a
      left join data_f.team_analysis_&season as b on a.round = b.round and a.home_team = b.team_name
      left join data_f.team_analysis_&season as c on a.round = c.round and a.away_team = c.team_name
      where a.round >= 6;
  quit;
%mend get_score_dm;

%get_score_dm(&current_season);



data data_f.datamart_01;
  set data_f.datamart_01 (where = (season ne &current_season))
  	  data_f.season_&current_season._dm;
run;


*** prepare data for training ***;
proc surveyselect data = data_f.datamart_01
  rate = .8
  out = datamart_01
  outall noprint;
run;

data data_f.train data_f.test;
  set datamart_01;
    if Selected = 1 then output data_f.train;
    else output data_f.test;

    drop Selected;
run;
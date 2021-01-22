libname data_f '/folders/myfolders/footbal/portugal/primeira/data';

*** create format for team names ***;
%macro count_stat(season);
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

  options minoperator mindelimiter = ',';
  
  %let num_of_teams = 18;

  %do i = 1 %to &num_of_teams;
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

  proc datasets lib = work nolist;
    delete team_form_&season: teams_list_&season results_ditailed_&season;
  run;

  data data_f.team_analysis_&season;
    set team_analysis_&season;
  run;
%mend count_stat;


%macro stat_per_season(from = 1999, to = 2020);  	
  %do current_season = &from %to &to;
  	%if &current_season = 2002 %then %do;
  		%let current_season = 2004;
  	%end;
  	
  	%if &current_season = 2003 %then %do;
  		%let current_season = 2004;
  	%end;
  	
    %count_stat(&current_season);
  %end;
%mend stat_per_season;


*** RUN DATA COLLECTION ***;
%stat_per_season;


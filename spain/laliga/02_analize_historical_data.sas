libname data_f '/folders/myfolders/footbal/spain/laliga/data';

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
        when('fcburgos') home_team = 'burgos';
        when('celtavigo') home_team = 'vigo';
        when('atleticomadrid') home_team = 'amadrid';
        when('athleticbilbao') home_team = 'bilbao';
        when('cdmerida') home_team = 'merida';
        when('fcsevilla') home_team = 'sevilla';
        when('racingsantander') home_team = 'santander';
        when('albacetepalomie') home_team = 'albacete';
        when('realbetis') home_team = 'betis';
        when('sdcompostela') home_team = 'compostela';
        when('fcsalamanca') home_team = 'salamanca';
        when('fcvalencia') home_team = 'valencia';
        when('halicante') home_team = 'alicante';
        when('deportivolacoruna') home_team = 'lacoruna';
        when('realoviedo') home_team = 'oviedo';
        when('realsociedad') home_team = 'sociedad';
        when('realzaragoza') home_team = 'saragossa';
        when('rayovallecano') home_team = 'vallecano';
        when('cdlogrones') home_team = 'logrones';
		when('cfextremadura') home_team = 'extremadura';
		when('sportinggijon') home_team = 'gijon';
		when('realmadrid') home_team = 'rmadrid';
		when('albacetebalompie') home_team = 'albacete';
		when('udlaspalmas') home_team = 'laspalmas';
		when('atlmadrid') home_team = 'amadrid';
        otherwise home_team = home_team;
      end;

      away_team = scan(game, 2, '-');
      select(away_team);
        when('fcburgos') away_team = 'burgos';
        when('celtavigo') away_team = 'vigo';
        when('atleticomadrid') away_team = 'amadrid';
        when('athleticbilbao') away_team = 'bilbao';
        when('cdmerida') away_team = 'merida';
        when('fcsevilla') away_team = 'sevilla';
        when('racingsantander') away_team = 'santander';
        when('albacetepalomie') away_team = 'albacete';
		when('realbetis') away_team = 'betis';
		when('sdcompostela') away_team = 'compostela';
		when('fcsalamanca') away_team = 'salamanca';
		when('fcvalencia') away_team = 'valencia';
		when('halicante') away_team = 'alicante';
		when('deportivolacoruna') away_team = 'lacoruna';
		when('realoviedo') away_team = 'oviedo';
		when('realsociedad') away_team = 'sociedad';
		when('realzaragoza') away_team = 'saragossa';
		when('rayovallecano') away_team = 'vallecano';
		when('cdlogrones') away_team = 'logrones';
		when('cfextremadura') away_team = 'extremadura';
		when('sportinggijon') away_team = 'gijon';
		when('realmadrid') away_team = 'rmadrid';
		when('albacetebalompie') away_team = 'albacete';
		when('udlaspalmas') away_team = 'laspalmas';
		when('atlmadrid') away_team = 'amadrid';
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

  %if &season in (1979, 1980, 1981, 1982, 1983, 1984, 1985, 1986) %then %do;
    %let num_of_teams = 18;
  %end;
  
  %else %if &season in (1987) %then %do;
    %let num_of_teams = 18;
  %end;
  
  %else %if &season in (1996, 1997) %then %do;
    %let num_of_teams = 22;
  %end;

  %else %do;
    %let num_of_teams = 20;
  %end;

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


%macro stat_per_season(from = 1979, to = 2020);
/* %macro stat_per_season(from = 1981, to = 1981); */
  %do current_season = &from %to &to;
    %count_stat(&current_season);
  %end;
%mend stat_per_season;




*** RUN DATA COLLECTION ***;
%stat_per_season;




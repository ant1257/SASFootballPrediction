libname data_f '/folders/myfolders/footbal/italy/serie_a/data';

%macro prepare_dm(season);
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
%mend prepare_dm;

%macro get_dm(from = 1980, to = 2020);  	
  %do current_season = &from %to &to;
  	%if &current_season = 2000 %then %do;
  		%let current_season = 2002;
  	%end;
  	
  	%if &current_season = 2016 %then %do;
  		%let current_season = 2017;
  	%end;
  	
  	%prepare_dm(&current_season);
  %end;

  data data_f.datamart_01;
    set data_f.season_: ;
  run;
%mend get_dm;

*** RUN DATA COLLECTION ***;
%get_dm;




*** prepare data for training ***;
/* proc surveyselect data = data_f.datamart_01 */
/*   rate = .8 */
/*   out = datamart_01 */
/*   outall noprint; */
/* run; */
/*  */
/* data data_f.train data_f.test; */
/*   set datamart_01; */
/*     if Selected = 1 then output data_f.train; */
/*     else output data_f.test; */
/*  */
/*     drop Selected; */
/* run; */
/*  */
/* proc export data = data_f.train */
/*   outfile = '/folders/myfolders/footbal/italy/serie_a/csv/train.csv' */
/*   dbms = csv */
/*   replace; */
/* run; */
/*  */
/* proc export data = data_f.test */
/*   outfile = '/folders/myfolders/footbal/italy/serie_a/csv/test.csv' */
/*   dbms = csv */
/*   replace; */
/* run; */

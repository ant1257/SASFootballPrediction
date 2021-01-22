/* libraries */
libname ml  "/folders/myfolders/footbal/belarus/major_league/data";
libname epl "/folders/myfolders/footbal/england/epl/data";
libname bl1 "/folders/myfolders/footbal/germany/bundesliga1/data";
libname bl2 "/folders/myfolders/footbal/germany/bundesliga2/data";
libname sa  "/folders/myfolders/footbal/italy/serie_a/data";
libname kor "/folders/myfolders/footbal/korea/k_league/data";
libname por "/folders/myfolders/footbal/portugal/primeira/data";
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
		
		if home_win = 1 or draw = 1 then X1 = 1;
		if away_win = 1 or draw = 1 then X2 = 1;
run;

proc means data = train_01 (drop = round home_team away_team season home_win draw away_win X1 X2);
run;



/* clasterization of the data */
proc contents data = train_01 out = temp_01 noprint;
run;

proc sort data = temp_01;
	by varnum;
run;

proc sql noprint;
	select name
	into : std_names
	separated by ' '
	from temp_01
	where upcase(name) ^in ('HOME_WIN', 'AWAY_WIN', 'DRAW', 'HOME_TEAM', 'AWAY_TEAM', 'SEASON', 'X1', 'X2');
quit;

proc fastclus data = train_01 maxclusters = 4 out = train_02 outstat = train_stat;
	var &std_names;
run;

proc fastclus data = train_01 instat = train_stat out = train_03;
	var &std_names;
run;

%macro train(target);
	proc logistic data = train_03 outmodel = model_&target;
		model &target(event = '1') = &std_names cluster /
		maxiter = 50
		selection = forward
		slentry=0.15;
	run;
%mend train;

%train(home_win);
%train(away_win);
%train(X1);
%train(X2);


data test_01;
	set bl1.test
/* 		bl2.test */
		sa.test
		epl.test
		ll.test
		ml.test
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

data test_01;
	set test_01;
		X1 = 0;
		X2 = 0;
		
		if home_win = 1 or draw = 1 then X1 = 1;
		if away_win = 1 or draw = 1 then X2 = 1;
run;


%macro train_score(data, target);
	title "&data &target";
	
	proc fastclus data = &data instat = general.clust_stat out = &data;
		var &std_names;
	run;
	
	proc logistic inmodel = general.model_&target;
		score fitstat data = &data out = &data._&target;
	run;
	
	proc sort data = &data._&target;
		by cluster;
	run;
	
	proc freq data = &data._&target;
		by cluster;
		tables &target * I_&target / norow;
	run;
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

%train_score(test_01, home_win);
%train_score(test_01, away_win);
%train_score(test_01, X1);
%train_score(test_01, X2);




proc sort data = train_01_home_win;
	by home_win p_1 p_0;
run;

proc boxplot data = train_01_home_win (where = (cluster = 1));
	plot p_1 * home_win / outbox = p_1_cl_1;
run;

proc boxplot data = train_01_home_win (where = (cluster = 2));
	plot p_1 * home_win / outbox = p_1_cl_2;
run;

proc boxplot data = train_01_home_win (where = (cluster = 3));
	plot p_1 * home_win / outbox = p_1_cl_3;
run;

proc boxplot data = train_01_home_win (where = (cluster = 4));
	plot p_1 * home_win / outbox = p_1_cl_4;
run;

data train_02_home_win;
	set train_01_home_win;
		length segment $20;
		
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
run;

proc freq data = train_02_home_win;
	tables cluster*segment*home_win / nocol norow;
run;





proc sort data = train_01_away_win;
	by away_win p_1 p_0;
run;

proc boxplot data = train_01_away_win (where = (cluster = 1));
	plot p_1 * away_win / outbox = p_1_cl_1;
run;

proc boxplot data = train_01_away_win (where = (cluster = 2));
	plot p_1 * away_win / outbox = p_1_cl_2;
run;

proc boxplot data = train_01_away_win (where = (cluster = 3));
	plot p_1 * away_win / outbox = p_1_cl_3;
run;

proc boxplot data = train_01_away_win (where = (cluster = 4));
	plot p_1 * away_win / outbox = p_1_cl_4;
run;

data train_02_away_win;
	set train_01_away_win;
		length segment $20;
		
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
run;

proc freq data = train_02_away_win;
	tables cluster*segment*away_win / nocol norow;
run;






proc sort data = train_01_x1;
	by x1 p_1 p_0;
run;

proc boxplot data = train_01_x1 (where = (cluster = 1));
	plot p_1 * x1 / outbox = p_1_cl_1;
run;

proc boxplot data = train_01_x1 (where = (cluster = 2));
	plot p_1 * x1 / outbox = p_1_cl_2;
run;

proc boxplot data = train_01_x1 (where = (cluster = 3));
	plot p_1 * x1 / outbox = p_1_cl_3;
run;

proc boxplot data = train_01_x1 (where = (cluster = 4));
	plot p_1 * x1 / outbox = p_1_cl_4;
run;

data train_02_x1;
	set train_01_x1;
		length segment $20;
		
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
			else if p_1 < 0.857799851 then segment = 'YELLOW';
			else segment = 'BLUE';
		end;
		
		else if cluster = 4 then do;
			if p_1 < 0.709023055 then segment = 'RED';
			else if p_1 < 0.7770483027 then segment = 'GRAY';
			else if p_1 < 0.8285305978 then segment = 'YELLOW';
			else segment = 'BLUE';
		end;
run;

proc freq data = train_02_x1;
	tables cluster*segment*x1 / nocol norow;
run;






proc sort data = train_01_x2;
	by x2 p_1 p_0;
run;

proc boxplot data = train_01_x2 (where = (cluster = 1));
	plot p_1 * x2 / outbox = p_1_cl_1;
run;

proc boxplot data = train_01_x2 (where = (cluster = 2));
	plot p_1 * x2 / outbox = p_1_cl_2;
run;

proc boxplot data = train_01_x2 (where = (cluster = 3));
	plot p_1 * x2 / outbox = p_1_cl_3;
run;

proc boxplot data = train_01_x2 (where = (cluster = 4));
	plot p_1 * x2 / outbox = p_1_cl_4;
run;

data train_02_x2;
	set train_01_x2;
		length segment $20;
		
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
run;

proc freq data = train_02_x2;
	tables cluster*segment*x2 / nocol norow;
run;





proc sort data = train_01_HH05;
	by HH05 p_1 p_0;
run;

proc boxplot data = train_01_HH05 (where = (cluster = 1));
	plot p_1 * HH05 / outbox = p_1_cl_1;
run;

proc boxplot data = train_01_HH05 (where = (cluster = 2));
	plot p_1 * HH05 / outbox = p_1_cl_2;
run;

proc boxplot data = train_01_HH05 (where = (cluster = 3));
	plot p_1 * HH05 / outbox = p_1_cl_3;
run;

proc boxplot data = train_01_HH05 (where = (cluster = 4));
	plot p_1 * HH05 / outbox = p_1_cl_4;
run;

data train_02_HH05;
	set train_01_HH05;
		length segment $20;
		
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
run;

proc freq data = train_02_HH05;
	tables cluster*segment*HH05 / nocol norow;
run;












proc sort data = train_01_HH15;
	by HH15 p_1 p_0;
run;

proc boxplot data = train_01_HH15 (where = (cluster = 1));
	plot p_1 * HH15 / outbox = p_1_cl_1;
run;

proc boxplot data = train_01_HH15 (where = (cluster = 2));
	plot p_1 * HH15 / outbox = p_1_cl_2;
run;

proc boxplot data = train_01_HH15 (where = (cluster = 3));
	plot p_1 * HH15 / outbox = p_1_cl_3;
run;

proc boxplot data = train_01_HH15 (where = (cluster = 4));
	plot p_1 * HH15 / outbox = p_1_cl_4;
run;

data train_02_HH15;
	set train_01_HH15;
		length segment $20;
		
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
run;

proc freq data = train_02_HH15;
	tables cluster*segment*HH15 / nocol norow;
run;






proc sort data = train_01_HH25;
	by HH25 p_1 p_0;
run;

proc boxplot data = train_01_HH25 (where = (cluster = 1));
	plot p_1 * HH25 / outbox = p_1_cl_1;
run;

proc boxplot data = train_01_HH25 (where = (cluster = 2));
	plot p_1 * HH25 / outbox = p_1_cl_2;
run;

proc boxplot data = train_01_HH25 (where = (cluster = 3));
	plot p_1 * HH25 / outbox = p_1_cl_3;
run;

proc boxplot data = train_01_HH25 (where = (cluster = 4));
	plot p_1 * HH25 / outbox = p_1_cl_4;
run;

data train_02_HH25;
	set train_01_HH25;
		length segment $20;
		
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
run;

proc freq data = train_02_HH25;
	tables cluster*segment*HH25 / nocol norow;
run;







proc sort data = train_01_AH05;
	by AH05 p_1 p_0;
run;

proc boxplot data = train_01_AH05 (where = (cluster = 1));
	plot p_1 * AH05 / outbox = p_1_cl_1;
run;

proc boxplot data = train_01_AH05 (where = (cluster = 2));
	plot p_1 * AH05 / outbox = p_1_cl_2;
run;

proc boxplot data = train_01_AH05 (where = (cluster = 3));
	plot p_1 * AH05 / outbox = p_1_cl_3;
run;

proc boxplot data = train_01_AH05 (where = (cluster = 4));
	plot p_1 * AH05 / outbox = p_1_cl_4;
run;

data train_02_AH05;
	set train_01_AH05;
		length segment $20;
		
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
run;

proc freq data = train_02_AH05;
	tables cluster*segment*AH05 / nocol norow;
run;








proc sort data = train_01_AH25;
	by AH25 p_1 p_0;
run;

proc boxplot data = train_01_AH25 (where = (cluster = 1));
	plot p_1 * AH25 / outbox = p_1_cl_1;
run;

proc boxplot data = train_01_AH25 (where = (cluster = 2));
	plot p_1 * AH25 / outbox = p_1_cl_2;
run;

proc boxplot data = train_01_AH25 (where = (cluster = 3));
	plot p_1 * AH25 / outbox = p_1_cl_3;
run;

proc boxplot data = train_01_AH25 (where = (cluster = 4));
	plot p_1 * AH25 / outbox = p_1_cl_4;
run;

data train_02_AH25;
	set train_01_AH25;
		length segment $20;
		
		if p_1 < 0.4 then segment = 'RED';
		else segment = 'GRAY';
run;

proc freq data = train_02_AH25;
	tables cluster*segment*AH25 / nocol norow;
run;





proc sort data = train_01_AH05;
	by AH05 p_1 p_0;
run;

proc boxplot data = train_01_AH05 (where = (cluster = 1));
	plot p_1 * AH05 / outbox = p_1_cl_1;
run;

proc boxplot data = train_01_AH05 (where = (cluster = 2));
	plot p_1 * AH05 / outbox = p_1_cl_2;
run;

proc boxplot data = train_01_AH05 (where = (cluster = 3));
	plot p_1 * AH05 / outbox = p_1_cl_3;
run;

proc boxplot data = train_01_AH05 (where = (cluster = 4));
	plot p_1 * AH05 / outbox = p_1_cl_4;
run;

data train_02_AH05;
	set train_01_AH05;
		length segment $20;
		
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
run;

proc freq data = train_02_AH05;
	tables cluster*segment*AH05 / nocol norow;
run;













%macro score(data, target);
	title "&data &target";
	
	proc fastclus data = &data instat = train_stat out = score_01;
		var &std_names;
	run;
	
	proc logistic inmodel = model_&target;
		score data = score_01 out = score_01_&target;
	run;
%mend score;

%score(bl1.score_2021_7, home_win);

data score_02_home_win;
	set score_01_home_win;
		length segment $20;
		
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
run;

proc export data = score_02_home_win
	outfile = "/folders/myfolders/footbal/germany/bundesliga1/temp/test_score_2021_7_home.csv"
	dbms = csv
	replace;
run;


%score(bl1.score_2021_7, away_win);

data score_02_away_win;
	set score_01_away_win;
		length segment $20;
		
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
run;


proc export data = score_02_away_win
	outfile = "/folders/myfolders/footbal/germany/bundesliga1/temp/test_score_2021_7_away.csv"
	dbms = csv
	replace;
run;





%score(bl1.score_2021_7, X1);

data score_02_X1;
	set score_01_X1;
		length segment $20;
		
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
			else if p_1 < 0.857799851 then segment = 'YELLOW';
			else segment = 'BLUE';
		end;
		
		else if cluster = 4 then do;
			if p_1 < 0.709023055 then segment = 'RED';
			else if p_1 < 0.7770483027 then segment = 'GRAY';
			else if p_1 < 0.8285305978 then segment = 'YELLOW';
			else segment = 'BLUE';
		end;
run;


proc export data = score_02_X1
	outfile = "/folders/myfolders/footbal/germany/bundesliga1/temp/test_score_2021_7_X1.csv"
	dbms = csv
	replace;
run;




%score(bl1.score_2021_7, X2);

data score_02_X2;
	set score_01_X2;
		length segment $20;
		
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
run;


proc export data = score_02_X2
	outfile = "/folders/myfolders/footbal/germany/bundesliga1/temp/test_score_2021_7_X2.csv"
	dbms = csv
	replace;
run;





proc sql;
	create table bl1.test_prediction_2020_7 as
	select
		a.season
		, a.round
		, a.home_team
		, a.away_team
		, catx(':', strip(put(a.cluster, best.)), 'P1', strip(put(round(a.P_1, .01), best.))) as P1
		, catx(':', strip(put(a.cluster, best.)),'P2', strip(put(round(b.P_1, .01), best.))) as P2
		, catx(':', strip(put(a.cluster, best.)),'X1', strip(put(round(c.P_1, .01), best.))) as X1
		, catx(':', strip(put(a.cluster, best.)),'X2', strip(put(round(d.P_1, .01), best.))) as X2
		, a.segment as P1_segment
		, b.segment as P2_segment
		, c.segment as X1_segment
		, d.segment as X2_segment
	from score_02_home_win as a
		left join score_02_away_win as b
		on a.season = b.season and a.round = b.round and a.home_team = b.home_team and a.away_team = b.away_team
		left join score_02_X1 as c
		on a.season = c.season and a.round = c.round and a.home_team = c.home_team and a.away_team = c.away_team
		left join score_02_X2 as d
		on a.season = d.season and a.round = d.round and a.home_team = d.home_team and a.away_team = d.away_team;
quit;

data format_01;
	set bl1.test_prediction_2020_7;
		length input_value output_value $10;
		
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



/* proc export data = bl1.test_prediction_2020_7 */
/* 	outfile = "/folders/myfolders/footbal/germany/bundesliga1/excel/pred_ger_b1_2021_7_test.xlsx"  */
/* 	dbms = xlsx */
/* 	replace; */
/* run; */


ods excel
	file = "/folders/myfolders/footbal/germany/bundesliga1/excel/pred_ger_b1_2021_7_test_2.xlsx"
	options (sheet_name = "2020_7");
	proc report data = bl1.test_prediction_2020_7;
		column season round home_team away_team P1 X1 P2 X2;
		define season / display;
		define round / display;
		define home_team / display;
		define away_team / display;
		define P1 / display style = {background = $fmt_color.};		
		define X1 / display style = {background = $fmt_color.};
		define P2 / display style = {background = $fmt_color.};
		define X2 / display style = {background = $fmt_color.};
	run;
ods excel close;



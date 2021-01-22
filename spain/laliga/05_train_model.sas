libname data_f '/folders/myfolders/footbal/spain/laliga/data';

proc contents data = data_f.train out = temp_01 noprint;
run;

proc sql noprint;
	select name
	into : num_vars
	separated by ' '
	from temp_01
	where name ^in ('draw', 'home_win', 'home_team', 'away_win', 'away_team', 'season');
quit;

/* TRAIN MODEL */
%macro train(target);
	proc logistic data = data_f.train outmodel = data_f.&target;
		model &target(event = '1') = &num_vars /
		maxiter = 1000
		selection = forward
		slentry=0.15;
	run;
%mend train;

%train(home_win);
%train(away_win);


/* SCORING */
%macro score(data, target);
	title "&data &target";
	
	proc logistic inmodel = data_f.&target;
		score fitstat data = data_f.&data out = &data._&target;
	run;

	proc sort data = &data._&target;
		by &target p_1 p_0;
	run;

	proc boxplot data = &data._&target ;
		plot p_1 * &target / outbox = p_1;
	run;

	data &data._&target;
		set &data._&target;
			length segment $20;
			
			%if &target = home_win %then %do;
				if p_1 < 0.449948773 then segment = 'RED';
				else if p_1 < 0.6256874964 then segment = 'YELLOW';
				else segment = 'GREEN';
			%end;
			
			%else %do;
				if p_1 < 0.1982278927 then segment = 'RED';
				else if p_1 < 0.3583562474 then segment = 'YELLOW';
				else segment = 'GREEN';
			%end;
			
			if input(I_&target, ?? best.) = &target then correct = 1;
			else correct = 0;
	proc sort;
		by season round;
	run;
	
	proc freq data = &data._&target;
		tables segment * correct / nocol norow;
	run;
%mend score;

%score(train, home_win);
%score(train, away_win);

%score(test, home_win);
%score(test, away_win);



libname data_f '/folders/myfolders/footbal/england/epl/data';

%macro get_results(season);
  options minoperator mindelimiter = ',';

  proc datasets library = work nolist;
    delete whole_page_&season: fixtures_&season: results_&season: game_&season: ;
  run;

  %if &season in (1979, 1980, 1981, 1982, 1983, 1984, 1985, 1986, 1987, 1992, 1993, 1994, 1995) %then %do;
    %let num_of_rounds = 42;
  %end;
  
  %else %if &season in (1988) %then %do;
    %let num_of_rounds = 40;
  %end;

  %else %do;
    %let num_of_rounds = 38;
  %end;

  %do round = 1 %to &num_of_rounds;  	
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
            and index(upcase(line), 'BEGEGNUNGEN');

        temp_var = strip(line);

        do while(index(upcase(temp_var), 'CLASS="ERGEBNIS"'));
          start_symbol = index(upcase(temp_var), 'CLASS="ERGEBNIS"');
          end_symbol = index(upcase(temp_var), '</SPAN><SPAN>');

          temp_value = substr(temp_var, start_symbol, end_symbol - start_symbol);
          temp_var = substr(temp_var, end_symbol + 13);
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
        result = strip(scan(temp_value, -1, '>'));
        keep season round game result;
    run;

    proc append base = results_&season data = fixtures_&season._&round;
    run;
  %end;

  proc datasets lib = work nolist;
    delete temp_: whole_: fixtures_&season: game_: ;
  run;

  data data_f.RESULTS_&season;
    set RESULTS_&season;
  run;

  * hardcode;
%mend get_results;

%macro result_per_season(from = 1979, to = 2020);
/* %macro result_per_season(from = 1979, to = 1979); */
  %do i = &from %to &to;
    %get_results(&i);
  %end;
%mend;

*** RUN DATA COLLECTION ***;
%result_per_season;

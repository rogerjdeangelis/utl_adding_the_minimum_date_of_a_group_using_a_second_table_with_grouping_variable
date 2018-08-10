Adding the minimum date of a group using a second table with grouping variable

   TWO SOLUTIONS

        1. SQL   (Paul Dorphman)
        2. HASH  (Paul Dorphman)

INPUT
=====

 I Sorted the two input tables for explanation purposes only.
 Assume 'listing_1 = sgent' is the join.

 WORK.TRANS total obs=10

           LISTING_    LISTING_    DATE_
     ID       1           2         SIGN

      1       A           B        19015
      5       A           C        17663
      4       B           A        18642
      2       C                    17287
      8       C                    17515
      7       C           A        19323
     10       D           A        18975
      6       E                    18823
      3       E           F        19422
      9       F           B        20058

 WORK.AGENT total obs=20

   DATE_                         Added for clarity
    SIGN    AGENT                FROM

   17287                       listing_2
   17515                       listing_2
   18823                       listing_2
   17663      A  ** min A      listing_1
   18642      A                listing_2
   18975      A                listing_2
   19015      A                listing_1
   19323      A                listing_2
   18642      B  *** min B     listing_1
   19015      B                listing_2
   20058      B                listing_2
   17287      C  *** min C     listing_1
   17515      C                listing_1
   17663      C                listing_2
   19323      C                listing_1
   18975      D  *** min D     listing_1
   18823      E  *** min E     listing_1
   19422      E                listing_1
   19422      F  *** min F     listing_2
   20058      F                listing_1


RULES
=====

  EXAMPLE OUTPUT

  Add then minimum data to trans using the minimum from second table work.agent

                                         MIN_
        LISTING_  LISTING_   DATE_   DATE_
  ID       1         2        SIGN    SIGN

   1       A         B       19015   17663    *** min A
   5       A         C       17663   17663    *** min A

   4       B         A       18642   18642    *** min B

   2       C                 17287   17287    *** min C
   8       C                 17515   17287    *** min C
   7       C         A       19323   17287    *** min C

  10       D         A       18975   18975    *** min D

   6       E                 18823   18823    *** min E
   3       E         F       19422   18823    *** min E

   9       F         B       20058   19422    *** min F  * only one from listing_2
                                                         * F from listing_2 id less
                                                           all F's in listing 1

PROCESS
=======

1. SQL   (Paul Dorphman)
------------------------
   proc sql ;
     create table want as
     select t.*
          , a.min_date_sign format=yymmdd10.
     from   trans t
     left join
            (select agent, min (date_sign) as min_date_sign from agent group 1) a
     on     t.listing_1 = a.agent
     order  by t.listing_1
     ;
   quit ;

2. HASH  (Paul Dorphman)

   data want_hash (drop = agent) ;
     if _n_ = 1 then do ;
       dcl hash h () ;
       h.defineKey ("agent") ;
       h.defineData ("agent", "min_date_sign") ;
       h.defineDone () ;
       do until (z) ;
         set trans (keep = id listing: date_sign) end = z ;
         array list listing: ;
         do over list ;
           agent = list ;
           if h.find() ne 0 then min_date_sign = date_sign ;
           else min_date_sign = min_date_sign >< date_sign ;
           h.replace() ;
         end ;
       end ;
     end ;
     set trans ;
     _n_ = h.find(key:listing_1) ;
     format min_date_sign yymmdd10. ;
   run ;

*                _               _       _
 _ __ ___   __ _| | _____     __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \   / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/  | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|   \__,_|\__,_|\__\__,_|

;

data trans ;
  input id (listing_1 listing_2) (:$1.) date_sign:yymmdd10. ;
  format date_sign yymmdd10. ;
  cards ;
  1  A  B  2012-01-23
  2  C  .  2007-05-01
  3  E  F  2013-03-05
  4  B  A  2011-01-15
  5  A  C  2008-05-11
  6  E  .  2011-07-15
  7  C  A  2012-11-26
  8  C  .  2007-12-15
  9  F  B  2014-12-01
 10  D  A  2011-12-14
run ;

data agent (keep = agent date_sign var) / view = agent ;
  set trans (keep = listing: date_sign) ;
  agent = listing_1 ;var   = 'listing_1' ; output ;
  agent = listing_2 ;var   = 'listing_2' ; output ;
run ;

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __
/ __|/ _ \| | | | | __| |/ _ \| '_ \
\__ \ (_) | | |_| | |_| | (_) | | | |
|___/\___/|_|\__,_|\__|_|\___/|_| |_|

;

see process;



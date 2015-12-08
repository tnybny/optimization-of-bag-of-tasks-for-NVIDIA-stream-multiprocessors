To compile:
$make

To clean:
$make clean

To run with sorting based on task size:
./p3 M T 1

To run without sorting (with randomziation):
./p3 M N 0

Note that M should be at aleast 20, and only 20 threads will be actively used during execution.

Performance demonstration:

./p3 25 1000 1
all tasks finished: 1000 tasks in total
Done NXM matrix:
0:-         15         15         15         15         15         15         15         15         15         15         15         15         15         15         15         15         15         15         15         15 
1:-         15         15         15         15         15         15         15         15         15         15         15         15         15         15         15         15         15         15         15         15 
2:-          8          8          8          8          8          8          8          8          8          8          8          8          8          8          8          8          8          8          8          8 
3:-          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7 
4:-          3          3          3          3          3          3          3          3          3          3          3          3          3          3          3          3          3          3          3          3 
5:-          2          2          2          2          2          2          2          2          2          2          2          2          2          2          2          2          2          2          2          2 



Count NxM matrix:
0:-     522757     522757     522757     522757     522757     522757     522757     522757     522757     522757     522757     522757     522757     522757     522757     522757     522757     522757     522757     522757 
1:-     520677     520677     520677     520677     520677     520677     523080     523080     523080     523080     523080     523080     523080     523080     523080     523080     523080     523080     523080     523080 
2:-     312668     312668     312668     312668     312668     312668     312668     312668     312668     312668     312668     312669     312669     312669     312669     312669     312669     312669     312669     312669 
3:-     341867     341867     341867     341867     341867     341867     341867     341867     341867     341868     341868     341868     341868     341868     341868     341868     341868     341868     341868     341868 
4:-          2          2          2          2          2          2          2          2          2          2          2          2          2          2          2          2          2          2          2          2 
5:-     181377     181377     181377     181377     181377     181377     181377     181377     181377     181377     181377     181377     181377     181377     181377     181377     181377     181377     181377     181377 
total time = 3044378

./p3 25 1000 0
all tasks finished: 1000 tasks in total
Done NXM matrix:
0:-          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9 
1:-          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7 
2:-          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9 
3:-          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9 
4:-          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9 
5:-          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7          7 



Count NxM matrix:
0:-          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9 
1:-          7          7          7          7          7          7     232281     232281     232281     232281     232281     232281     232281     232281     232281     232281     232281     232281     232281     232281 
2:-          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9 
3:-          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9 
4:-          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9          9 
5:-          7          7          7          7          7          7          7          7          7          7     201528     201528     201528     201528     201528     201528     201528     201528     201528     201528 
total time = 7722464

First most obvious observation is that total time taken is much less when the data is sorted.
Second, we notice that for the sorted case, in the count matrix: since all the small tasks finish first, the threads in sms 0 and 1 are left idling for a longer time than those in sms 2 and 3. Since sm 4 has the most runs with large tasks, it idles for the least amount of time before the program ends.
Third, we notice that all the sms in the unsorted run have approximately equal number of runs. Unfortunately, we cannot visualize one thread's idling versus another's in the same sm. 

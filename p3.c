#include <stdio.h>
//#include <sys/time.h>
#include <stdlib.h>
#include <time.h>
#include "header.h"

long mastertime;
struct timeval start;
struct timeval end;

void swap (int *a, int *b)
{
    	int temp = *a;
    	*a = *b;
   	*b = temp;
}

void randomize ( int arr[], int n )
{
	// Use a different seed value so that we don't get same
   	// result each time we run this program
    	srand ( time(NULL) );
              
    	//Start from the last element and swap one by one. We don't
    	// need to run for the first element that's why i > 0
    	int i;
	for (i = n-1; i > 0; i--)
	{
   		// Pick a random index from 0 to i
            	int j = rand() % (i+1);
    		// Swap arr[i] with the element at random index
                swap(&arr[i], &arr[j]);
	}
}

int main(int argc, char *argv[])
{
	if(argc != 4)
		printf("usage: ./p3 num_threads num_tasks 1/0(for sorting to SMs or not)");
	
	int M = atoi(argv[1]);
	int T = atoi(argv[2]);
	int sort = atoi(argv[3]);
	
	int i;

	int num_st = 0.6*T;
	int num_mt = 0.3*T;
	int num_lt = T - num_st - num_mt;
	int tasks[T];
	for(i = 0; i < num_st; i++)
	{
		tasks[i] = 100;
	}
	for(i = num_st; i < (num_st+num_mt); i++)
	{
		tasks[i] = 400;
	}
	for(i = (num_st + num_mt); i < T; i++)
	{
		tasks[i] = 1000;
	}

	if(sort == 0)
	{
		int n = sizeof(tasks)/ sizeof(tasks[0]);
		randomize(tasks, n);
	}

	int j;
	for(j = 0; j < N; j++)
	{
		queues_h[j].count = 0;	
	}		

	//CUDA kernel call wrapper	
	gettimeofday(&start, NULL);
	wrapper(M, T, tasks, sort, num_st, num_mt, num_lt);
	gettimeofday(&end, NULL);

	//calculate total time
	mastertime = ((end.tv_sec - start.tv_sec)*1000000L
           +end.tv_usec) - start.tv_usec;
	printf("total time = %d\n",mastertime);

	return 0;
}

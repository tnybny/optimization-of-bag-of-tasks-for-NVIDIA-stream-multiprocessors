#include <stdio.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <stdlib.h>
extern "C" {
#include "header.h"
}

cudaStream_t stream1, stream2;
int *t;
int *h_t;
int si = 0;
int mi;
int li;
int uindex = 0;
int idle[N][active_t];


__device__ uint get_smid(void) 
{
	uint ret;
	asm("mov.u32 %0, %smid;" : "=r"(ret) );
	return ret;
}

__device__ void* pnum(void* max)
{
	int limit = *((int *)max);
	printf("in task function\n");
	printf("%d",limit);
	int i, n, sum;
	for(n = 0; n < limit; n++)
	{
		i = 1;
		sum = 0;
		while(i < n){
			if(n % i == 0)
			{
				sum = sum + i;
			}
			i++;
		}
	}
	return NULL;
}

__device__ func f = pnum;

__global__ void scheduler(taskQueue_t *queues, complete_t *complete_d, int T, int *t)
{
	int sm = get_smid();
	if(threadIdx.x < active_t)
	{
		func g = NULL;
		while(*t < T)
		{
			if(queues[sm].f[threadIdx.x] != NULL)
			{
				queues[sm].f[threadIdx.x]((void *)&(queues[sm].arg[threadIdx.x]));
				queues[sm].f[threadIdx.x] = g;
				complete_d[sm].complete[threadIdx.x] += 1;
				atomicAdd(t, 1);
			}
		}
	}
}

// schedule func(arg) to be invoked on GPU in taskQueue[sm], return taskId
int taskAdd(void *(*func) (void *), void *arg, int sm)
{
	queues_h[sm].f[queues_h[sm].count] = func;
	queues_h[sm].arg[queues_h[sm].count] = *((int *)arg);
	int taskID = queues_h[sm].count * 10 + sm;	
	queues_h[sm].count += 1;
	return taskID;
}

void add_to_queue(int tasks[], int sort, int num_st, int num_mt, int num_lt, int taskIDs[][active_t], int sm, func h_f, int T)
{
	int i,j;
	int max;
	func g = NULL; 
	if(sort == 1)
	{
		if(sm == 0 | sm == 1)
		{
			j = si;
			max = num_st;
			for(i = 0; i < active_t; j++, i++)
			{       
				if(j < max)
				{       
					taskIDs[sm][i] = taskAdd(h_f, (void *)&tasks[j], sm);
					si++;
				}
				else    
				{       
					taskIDs[sm][i] = taskAdd(g, (void*)&tasks[j], sm);
				}
			}
		}
		else if(sm == 2 | sm == 3)
		{
			j = mi;
			max = num_st + num_mt;
			for(i = 0; i < active_t; j++, i++)
			{       
				if(j < max)
				{       
					taskIDs[sm][i] = taskAdd(h_f, (void *)&tasks[j], sm);
					mi++;
				}
				else    
				{       
					taskIDs[sm][i] = taskAdd(g, (void*)&tasks[j], sm);
				}
			}
		}
		else
		{
			j = li;
			max = T;
			for(i = 0; i < active_t; j++, i++)
			{       
				if(j < max)
				{       
					taskIDs[sm][i] = taskAdd(h_f, (void *)&tasks[j], sm);
					li++;
				}
				else    
				{       
					taskIDs[sm][i] = taskAdd(g, (void*)&tasks[j], sm);
				}
			}
		}
	}
	else if(sort == 0)
	{
		j = uindex;
		max = T;
		for(i = 0; i < active_t; j++, i++)
		{
			if(j < max)
			{
				if(tasks[j] == 100)
					si++;
				else if(tasks[j] == 400)
					mi++;
				else if(tasks[j] == 1000)
					li++;
				taskIDs[sm][i] = taskAdd(h_f, (void *)&tasks[j], sm);
				uindex++;
			}
			else
			{
				taskIDs[sm][i] = taskAdd(g, (void *)&tasks[j], sm);
			}
		}
	}
	for(i = 0; i < active_t; i++)
	{
		h_complete[sm].complete[i] = complete_h[sm].complete[i];
		h_queues[sm].arg[i] = queues_h[sm].arg[i];
		h_queues[sm].f[i] = queues_h[sm].f[i];
		h_queues[sm].count = queues_h[sm].count;
	}
}

void printoutput()
{
	printf("Done NXM matrix:\n");
	int i,j;
	for(i = 0; i < N; i++)
	{
		for(j = 0; j < active_t; j++)
		{
			if(j == 0)
				printf("%d:- ", i);
			printf("%10d ", h_complete[i].complete[j]);
		}
		printf("\n");
	}
	printf("\n\n\nCount NxM matrix:\n");
	for(i = 0; i < N; i++)
	{
		for(j = 0; j < active_t; j++)
		{
			if(j == 0)
				printf("%d:- ", i);
			printf("%10d ", idle[i][j]);
		}
		printf("\n");
	}
}

// check if task taskId is done, returns TRUE/FALSE
int taskDone(int taskId)
{
	int sm = taskId % 10;
	int index = taskId / 10;
	if(h_complete[sm].complete[index] == (dindex[sm] + 1))
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

void wrapper(int M, int T, int tasks[], int sort, int num_st, int num_mt, int num_lt)
{
	complete_t *complete_d;
	taskQueue_t *queues_d;

	int taskIDs[N][active_t];
	mi = num_st;
	li = num_st + num_mt;

	cudaStreamCreate(&stream1);
	cudaStreamCreate(&stream2);

	func h_f;

	cudaMemcpyFromSymbol(&h_f, f, sizeof(func));

	//cudaMalloc
	cudaMalloc((void **)&queues_d, N * sizeof(taskQueue_t));
	cudaMalloc((void **)&complete_d, N * sizeof(complete_t));
	cudaMalloc((void **)&t, sizeof(int));
	cudaMallocHost(&h_queues, N * sizeof(taskQueue_t));
	cudaMallocHost(&h_complete, N * sizeof(complete_t));
	cudaMallocHost(&h_t, sizeof(int));

	int i;
	for(i = 0; i < N; i++)
	{
		add_to_queue(tasks, sort, num_st, num_mt, num_lt, taskIDs, i, h_f, T);
	}

	//cudaMemcpy
	*h_t = 0;
	cudaMemcpy(t, (void *)h_t, sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(queues_d, (void *)&queues_h, N * sizeof(taskQueue_t), cudaMemcpyHostToDevice);
	cudaMemcpy(complete_d, (void *)&complete_h, N * sizeof(complete_t), cudaMemcpyHostToDevice);

	//kernel call
	scheduler<<<N, M, 0, stream1>>>(queues_d, complete_d, T, t);

	//while all tasks are not done
	while(1)
	{
		int i;
		//memcpyasync
		cudaMemcpyAsync(h_complete, complete_d, N * sizeof(complete_t), cudaMemcpyDeviceToHost, stream2);
		cudaMemcpyAsync(h_t, t, sizeof(int), cudaMemcpyDeviceToHost, stream2);
		for(i = 0; i < N; i++)
		{
			int j;
			int done = 1;
			for(j = 0; j < active_t; j++)
			{
				if((taskDone(taskIDs[i][j])) == 0)
				{
					done = 0;
				}
				else
				{
					idle[i][j] = idle[i][j] + 1;
				}	
			}
			int flag = 0;
			if(done)
			{
				if(sort)
				{
					if(i == 0 | i == 1)
					{
						if(si < num_st)
						{
							flag = 1;
						}
					}	
					if(i == 2 | i == 3)
					{
						if(mi < num_st + num_mt)
						{
							flag = 1;
						}
					}
					if(i == 4 | i == 5)
					{
						if(li < T)
						{
							flag = 1;
						}	
					}
				}
				else
				{
					flag = 1;
				}
				if(flag == 1)
				{
					queues_h[i].count = 0;
					dindex[i]++;
					add_to_queue(tasks, sort, num_st, num_mt, num_lt, taskIDs, i, h_f, T);
					cudaMemcpyAsync((void *)&queues_d[i], (void *)&h_queues[i], sizeof(taskQueue_t), cudaMemcpyHostToDevice, stream2);
				}
			}
		}
		if(*h_t == T & si == num_st & mi == (num_st+num_mt) & li == T)
		{
			printf("all tasks finished: %d tasks in total\n", *h_t);
			printoutput();
			break;
		}
	}
	//cudaStreamDestroy(stream1);
	//cudaStreamDestroy(stream2);
	//cudaFreeHost(&h_queues);
	//cudaFreeHost(&h_complete);
}

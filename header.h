
#ifndef HEADER_H
#define HEADER_H

#define N 6
#define active_t 20

typedef void * (*func) (void*);

typedef struct taskq{
	int arg[active_t];
	int count;
	func f[active_t];
}taskQueue_t;

typedef struct comp{
	int complete[active_t];
}complete_t;

taskQueue_t queues_h[N];
taskQueue_t *h_queues;
complete_t complete_h[N];
complete_t *h_complete;

//done index array
int dindex[N];

// schedule func(arg) to be invoked on GPU in taskQueue[sm], return taskId
int taskAdd(void *(*func) (void *), void *arg, int sm);
// check if task taskId is done, returns TRUE/FALSE
int taskDone(int taskId);
//wrapper
void wrapper(int M, int T, int tasks[], int sort, int num_st, int num_mt, int num_lt);

#endif

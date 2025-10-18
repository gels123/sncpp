// 测试
//make colib && make testmain
//
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <queue>
#include "co_routine.h"

struct stEnv_t
{
    int num;
    stCoCond_t* cond;
    stCoRoutine_t *co_producer;
    stCoRoutine_t *co_consumer;
    std::queue<int> queue;
};

void* RoutineProducer(void* env_)
{
    // 启用协程HOOK项
    co_enable_hook_sys();

    stEnv_t* env = (stEnv_t*)env_;
    while (true) {
        for(int i=0;i<5;i++) {
            ++env->num;
            env->queue.push(env->num);
        }
        printf("RoutineProducer do %s.cpp:%d\n", __func__, __LINE__);
        co_cond_signal(env->cond);
        //use poll as sleep
        poll(NULL, 0, 1000);
    }

    return NULL;
}

void* RoutineConsumer(void* env_)
{
    // 启用协程HOOK项
    co_enable_hook_sys();

    stEnv_t* env = (stEnv_t*)env_;
    while (true) {
        if (env->queue.empty())
        {
            co_cond_timedwait(env->cond, -1);
            continue;
        }
        int num = env->queue.front();
        env->queue.pop();
        printf("RoutineConsumer do %s.cpp:%d num = %d\n", __func__, __LINE__, num);
    }

    return NULL;
}

int main(int argc, char* argv[])
{
    stEnv_t env;
    env.num = 0;
    env.cond = co_cond_alloc();

    co_create(&env.co_consumer, NULL, RoutineConsumer, &env);
    co_resume(env.co_consumer);

    co_create(&env.co_producer, NULL, RoutineProducer, &env);
    co_resume(env.co_producer);

    co_eventloop(co_get_epoll_ct(), NULL, NULL);
    return 0;
}


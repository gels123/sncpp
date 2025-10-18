#ifndef _THREADSOCKET_
#define _THREADSOCKET_

#pragma pack(1)

struct ListNode {
    void *data;
    struct ListNode *next;
};

static struct ListNode * connlist = NULL;

struct BufferData
{
    char * buffer;
    int len;
};

//主结构体
struct ConnThread
{   
    //host port number
    int port;
    //connect timeout,default by second
    float connectTimeout;
    //read data timeout,default by second
    float readTimeout;
    //write data timeout,default by second
    float writeTimeout;
    //curl
    CURL *curl;
    //curl return code
    CURLcode returnCode;
    //curl socket ID
    long socket;
    // socket tag to be unique
    char tag;
    //curl error infomation
    char errorMessage[CURL_ERROR_SIZE];
    //thread running or not
    char isRunning;
    //connect or not
    char isConnect;
    //receive header data ok or not
    char isReceiveHeaderOK;
    //receive message ok or not
    char isReceiveOK;
    //close socket by user.
    char closeSocketByUser; 
    //host address
    char host[64];    
    //mutex used for thread synchronization
    pthread_mutex_t mutexWrite;
    //thread handle
    pthread_t _thread;
    //queue sending
    struct queue * sendQueue;
    //queue receive
    struct queue * recvQueue;
};

#endif

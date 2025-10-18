#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <memory.h>
#include <math.h>
#include <signal.h>

//libcurl include
#include "curl/curl.h"
#include "curl/easy.h"

//thread include
#include <time.h>
#include <sched.h>
#include <pthread.h>

#include "lua.h"
#include "lauxlib.h"

#include "queue.h"
#include "threadsocket.h"

#define FD_SEND 0 /* 0-发送 */
#define FD_RECV 1 /* 1-接收 */


static const short SIZE_OF_HEADER_LEN = sizeof(unsigned short);

static void releaseQueueData( struct queue * mQueue)
{
    void * tmpSendData = queue_pop(mQueue);
    while ( NULL != tmpSendData ) 
    {
        struct BufferData * snddata = (struct BufferData *) tmpSendData;
        free(snddata->buffer);
        free(snddata);
        tmpSendData = queue_pop(mQueue);
    }
}

static struct ListNode* listCreate(void *data)
{
    struct ListNode *l = malloc(sizeof(struct ListNode));
    if (l != NULL) {
        l->next = NULL;
        l->data = data;
    }
    return l;
}

static struct ListNode* listAppend(struct ListNode *node, void *data)
{
    struct ListNode *new_node = listCreate(data);
    if (new_node) {
        new_node->next = node->next;
        node->next = new_node;
    }
    return new_node;
}

static struct ListNode* listFind(struct ListNode *node,int tag)
{
    struct ListNode* tmplist = node;
    while (tmplist) {
        struct ConnThread * conn = (struct ConnThread *) tmplist->data;
        printf("listFind ==%d,%d,%f,%f,%f\n ",tag,conn->tag,conn->connectTimeout,conn->readTimeout,conn->writeTimeout);
        if (conn && conn->tag == tag) 
        {
            break;
        }
        tmplist = tmplist->next;
    }
  return tmplist;
}

static struct ListNode* listRemove(struct ListNode *node,int tag)
{
    struct ListNode * headNode = node; //头节点
    struct ConnThread * headConn = (struct ConnThread *) node->data;
    printf("listRemove, %d, %d\n", headConn->tag , tag);
    if(headConn && headConn->tag == tag)
    {
        headNode = node->next;
        node->next = NULL;

        releaseQueueData(headConn->sendQueue);
        releaseQueueData(headConn->recvQueue);

        queue_release(headConn->sendQueue,NULL);
        queue_release(headConn->recvQueue,NULL);

        free(headConn);//
        free(node);
    }
    else
    {

        struct ListNode* tmplist = node->next;
        struct ListNode* prelist = node;
        while (tmplist) {
            struct ConnThread * conn = (struct ConnThread *) tmplist->data;
            if (conn && conn->tag == tag) 
            {
                prelist->next = tmplist->next;
                
                releaseQueueData(conn->sendQueue);
                releaseQueueData(conn->recvQueue);

                queue_release(conn->sendQueue,NULL);
                queue_release(conn->recvQueue,NULL);

                free(conn);//
                free(tmplist);

                break;
            }
            prelist = tmplist;
            tmplist = tmplist->next;
        }
    }
    
  return headNode;
}


/*
 * 打印错误信息到错误缓冲区(ut_error_message)，私有函数
 */
static int on_error(const char *format, ...)
{
    int bytes_written;
    va_list arg_ptr;
    
    va_start(arg_ptr, format);

    bytes_written = vfprintf(stderr, format, arg_ptr);
    
    va_end(arg_ptr);

    return bytes_written;
}

static void thread_sleep(int mSec,int mNsec)
{
    struct timespec sleepTime;
    struct timespec returnTime;
    sleepTime.tv_sec = mSec;
    sleepTime.tv_nsec = mNsec;
    nanosleep(&sleepTime, &returnTime);
}

static int waitOnSocket(curl_socket_t sockfd, int for_recv, long timeout_ms)
{
    struct timeval tv;
    fd_set infd, outfd, errfd;
    int res;
    int selectStatus = -1;

    tv.tv_sec = timeout_ms / 1000;
    tv.tv_usec= (timeout_ms % 1000) * 1000;
    
    FD_ZERO(&infd);
    FD_ZERO(&outfd);
    FD_ZERO(&errfd);
    
    FD_SET(sockfd, &errfd); /* always check for error */ 
    
    if(for_recv)//receive
    {
        FD_SET(sockfd, &infd);
    }
    else//send
    {
        FD_SET(sockfd, &outfd);
    }
    
    res = select(sockfd + 1, &infd, &outfd, &errfd, &tv);
    
    if (res == 0) { //wait timeout
        #ifdef DEBUG
        //printf("wait_on_socket=== timeout\n");
        #endif
        selectStatus = 0;
    }
    else if (res == -1)//error happends
    {
        #ifdef DEBUG
        printf("wait_on_socket=== error\n");
        #endif
        selectStatus = 0;
    }
    else
    {
        if(for_recv)//receive
        {
            if(FD_ISSET(sockfd,&infd))
            {
                selectStatus = res;
            }
        }
        else//send
        {
            if(FD_ISSET(sockfd,&outfd))
            {
                selectStatus = res;
            }
        }
    }
    printf("res =%d \n",selectStatus);
    return selectStatus;
}

static int stopThread( int tag ,int error )
{
    struct ListNode * connNode = listFind(connlist,tag);
    if( NULL == connNode )
    {
        return -1;
    }

    printf("stop start ==========\n");
    struct ConnThread * conn = (struct ConnThread *) connNode->data;

    conn->closeSocketByUser = 1;
    conn->isRunning   = 0;
    conn->isReceiveHeaderOK= 1;
    conn->isReceiveOK = 1;

    shutdown(conn->socket, SHUT_RDWR);
    pthread_kill(conn->_thread, 0);
    pthread_join(conn->_thread, NULL);
    printf("stop success ==========\n");
    return 0;
}

/**handle error when socket has some exceptions*/
static void handleError(int tag, CURLcode mCode)
{
    //接收数据出错
    const char * erroinfo = curl_easy_strerror(mCode);
    on_error("handleError tag=%d: 传输数据失败，错误信息:%s\n",tag,erroinfo);
    stopThread(tag,mCode);
}

static void sighandle(int signo)
{
    printf("Thread in signal handler = %d\n",signo);
    return;
}

static int connectServer(struct ConnThread * conn)
{
    curl_easy_setopt(conn->curl, CURLOPT_URL, conn->host);
    curl_easy_setopt(conn->curl, CURLOPT_PORT,conn->port);
    curl_easy_setopt(conn->curl, CURLOPT_CONNECT_ONLY, 1L);
    curl_easy_setopt(conn->curl, CURLOPT_CONNECTTIMEOUT, conn->connectTimeout);  // 设置连接超时，单位秒
    
    curl_easy_setopt(conn->curl, CURLOPT_NOSIGNAL, 1);
    curl_easy_setopt(conn->curl, CURLOPT_SSL_VERIFYPEER, 0);
    curl_easy_setopt(conn->curl, CURLOPT_SSL_VERIFYHOST, 0);

#if DEBUG
    curl_easy_setopt(conn->curl, CURLOPT_VERBOSE, 1);
#endif
    
    int returnCode = curl_easy_perform(conn->curl);
    
    if(returnCode != CURLE_OK){
        on_error("connectServer : 启动CURL失败，错误信息：%s\n", \
                 curl_easy_strerror(returnCode));
        return -1;
    }
    
    long longdata;
    returnCode = curl_easy_getinfo(conn->curl, CURLINFO_LASTSOCKET, &longdata);
    conn->socket = longdata;
    
    if(returnCode != CURLE_OK){
        on_error("connectServer : 获取套接字失败，错误信息：%s\n", \
                 curl_easy_strerror(returnCode));
        return -1;
    }

#if DEBUG
    printf("connect success tag=%d,%d, %s:%d\n",conn->tag,conn->socket,conn->host,conn->port);
#endif

    conn->isConnect = 1;
    return returnCode;
}

static int lua_f_stop(lua_State *L)
{
    int tag = luaL_checkinteger(L, 1);
    
    int ret = stopThread(tag,0);
    if( !ret )
    {
        //暂停失败
        lua_pushinteger(L,ret);
        printf("stop failed ==========\n");
        return 1;
    }

    lua_pushinteger ( L, 0);
    return 1;
}

static void * threadMain(void *operation)
{
    int tag = (int)operation;
    struct ListNode * connNode = listFind(connlist,tag);
    if( NULL == connNode )
    {
        printf("threadMain can not find %d\n",tag );
        return NULL;
    }

    // struct ListNode * connNode = (struct ListNode *) operation ;
    // if( NULL == connNode )
    // {
    //     return NULL;
    // }
    struct ConnThread * conn = (struct ConnThread *) connNode->data;
    printf("thread main aaa=====%p,%d, %d,%d,%d,%d\n",conn,(*conn).isConnect,conn->tag,conn->connectTimeout,conn->readTimeout,conn->writeTimeout);
    
    short isExitThread = 0;
    short comStatus = 1;
    int retCode = -1;
    while (conn && conn->isRunning) 
    {
        printf("thread main =====%p,%d,%d,%d,%d\n",conn,(*conn).tag,conn->connectTimeout,conn->readTimeout,conn->writeTimeout);
        if (!conn->isConnect) {
            retCode = connectServer(conn);

            /////////////////////////////////////////
            if (comStatus == -1)
            {
                isExitThread = 1;
            }
            
            ///////send error info message //////////
            
        }

        //break to exit thread
        if (isExitThread) {
            printf("thread exit\n");
            break;// exit thread
        }
        
/////////////////////////////// send start ///////////////////////////////////////////
        size_t ret_len; //返回长度
        short isSendOK = 0;
        int sendIndex = 0;
        
        void * tmpSendData = queue_pop(conn->sendQueue);
        if ( NULL != tmpSendData ) 
        {
            struct BufferData * snddata = (struct BufferData *) tmpSendData;
            //write lock
            const char * tmpData = snddata->buffer;
            int req_len = snddata->len;
            while (!isSendOK)
            {
                /* wait for the socket to become ready for sending */
                if(!waitOnSocket(conn->socket, FD_SEND, conn->writeTimeout * 1000)){ // 30 seconds default
                    printf("wait error =========\n");
                    handleError(conn->tag,conn->returnCode); // 错误处理
                    isExitThread = 1;
                    break; //break for current while
                }
                
                conn->returnCode = curl_easy_send(conn->curl,tmpData + sendIndex,req_len - sendIndex,&ret_len);

                if(conn->returnCode != CURLE_OK){
                    printf("send error =========\n");
                    handleError(conn->tag,conn->returnCode); // 错误处理
                    isExitThread = 1;
                    break;
                }
                
                if(req_len - sendIndex != ret_len){
                    sendIndex += ret_len;
                    printf("raw_send tag=%d: 数据未发送完成,剩余:%ld\n",conn->tag,((req_len - sendIndex) - ret_len));
                }
                else{
                    sendIndex += ret_len;
                    isSendOK = 1;
                    break;//break for current while
                }
            }
            
            //释放内存
            free(tmpData);
            free(tmpSendData);

            #ifdef DEBUG
            printf("--> conn thread tag=%d,%d, ret_len=%d,send,buf length =%d,really send length=%d \n",conn->tag,conn->socket,ret_len,req_len,sendIndex);
            #endif
        }
/////////////////////////////////////////// send end OK /////////////////////////////////////////////////////////
        
        const short HEADER_BUFFER_SIZE = SIZE_OF_HEADER_LEN;
        char headerBuffer[HEADER_BUFFER_SIZE];
        memset(headerBuffer, '\0', HEADER_BUFFER_SIZE);
        
        int receivePackageIndex = 0;
        int curHeaderDataIndex = 0;
        conn->isReceiveHeaderOK = 0;
        ret_len = 0;
        
        ///////////// receive header data ///////////////
        
        while (! conn->isReceiveHeaderOK)
        {
            if (! waitOnSocket(conn->socket, FD_RECV, conn->readTimeout * 1000) )// 30 seconds default
            {
                printf("not data to recv \n");
                break;
            }
            
            conn->returnCode = curl_easy_recv(conn->curl, headerBuffer+curHeaderDataIndex, HEADER_BUFFER_SIZE - curHeaderDataIndex, &ret_len);//先读取 HEADER_BUFFER_SIZE 个字节,actionID(short),data length(int)
            if(conn->returnCode != CURLE_OK){
                printf("recv header error =========\n");
                handleError(conn->tag,conn->returnCode); // 错误处理
                isExitThread = 1;
                break;
            }
            
            if (HEADER_BUFFER_SIZE - curHeaderDataIndex == ret_len) {
                conn->isReceiveHeaderOK = 1;
            }
            else
            {
                #ifdef DEBUG
                printf("---->conn thread %p, %d,tag=%d receive header left length =%ld\n",conn,conn->isReceiveHeaderOK,conn->tag,((HEADER_BUFFER_SIZE - curHeaderDataIndex) - ret_len));
                #endif
                handleError(conn->tag,conn->returnCode); // 错误处理
                isExitThread = 1;
                break;
            }
            curHeaderDataIndex += ret_len;
        }
        
        if (!conn->isReceiveHeaderOK || (ret_len==0)) {
            #ifdef DEBUG
            // printf("---->conn thread tag=%d receive header unsuccess \n",conn->tag);
            #endif
            continue; // continue for outer while loop /////
        }
        /////// receive header OK ////////////
        unsigned char tmpChar = headerBuffer[0]; 
        headerBuffer[0] = headerBuffer[1];
        headerBuffer[1] = tmpChar;

        unsigned short dataLength = *((unsigned short *)headerBuffer);
        printf("receive header len = %d \n", dataLength);
        if (dataLength >= 0)
        {
            char * recvBuf = malloc(dataLength);
            
            conn->isReceiveOK = 0;
            while (!conn->isReceiveOK)
            {
                if(! waitOnSocket(conn->socket, FD_RECV, conn->readTimeout * 1000))// 30 seconds default
                {
                    //接收后续数据在没有到达的情况下,报错
                    handleError(conn->tag,conn->returnCode); // 错误处理
                    isExitThread = 1;
                    break;
                }
                conn->returnCode = curl_easy_recv(conn->curl,recvBuf + receivePackageIndex,dataLength - receivePackageIndex, &ret_len);
                
                if(conn->returnCode != CURLE_OK){
                    printf("recv data error =========\n");
                    handleError(conn->tag,conn->returnCode); // 错误处理
                    isExitThread = 1;
                    break;//break for current while
                }
                
                if (dataLength - receivePackageIndex != ret_len) {
                    #ifdef DEBUG
                    printf("==conn thread tag=%p, %d receive left length =%ld of %d\n",conn,conn->tag,((dataLength - receivePackageIndex) - ret_len),dataLength);
                    #endif
                }
                else
                {
                    conn->isReceiveOK = 1;
                }
                receivePackageIndex += ret_len;
            }
            
            #ifdef DEBUG
            printf("==conn thread rev success tag=%p,conn->isReceiveOK=%d, %d receive length =%ld of %d\n",conn,conn->tag,conn->isReceiveOK,ret_len,dataLength);
            #endif
            if (conn->isReceiveOK) {
                struct BufferData * revdata = malloc(sizeof(*revdata));
                revdata->buffer = recvBuf;
                revdata->len = dataLength;
                //进队列
                queue_push(conn->recvQueue,revdata);
            }
            else
            {
                continue; // continue for outer while loop
            }
        }
        
        /*Notifies the scheduler that the current thread is willing to release its processor to other threads of the same or higher   priority.*/
        //sched_yield();
        
        //thread_sleep(0,1000 * 1000 * 60); //60毫秒. 1微秒 = 1000纳秒,1毫秒 = 1000微秒
        
    }////////////////// end while loop /////////////////
    
    if (isExitThread) {
        int tag = conn->tag;
        connlist = listRemove(connlist,tag);

        #ifdef DEBUG
        printf("exit thread success %d\n",tag);
        #endif
    }

    return NULL;
}

static int lua_f_start( lua_State *L )
{
    int tag = luaL_checkinteger(L, 1);
    struct ListNode * connNode = listFind(connlist,tag);
    if( NULL == connNode )
    {
        lua_pushinteger ( L, -1);
        return 1;
    }
    struct ConnThread * conn = (struct ConnThread *) connNode->data;
    conn->isRunning   = 1;
    
    ////// signal handle ////////
    struct sigaction actions;
    memset(&actions, 0, sizeof(actions));
    sigemptyset(&actions.sa_mask);
    actions.sa_flags = 0;
    actions.sa_handler = sighandle;
    sigaction(SIGALRM,&actions,NULL);
    ///////////////////////////
    
    pthread_attr_t attr;
    int iErrorCode = pthread_attr_init( &attr );
    if ( 0 != iErrorCode ) {
        pthread_attr_destroy( &attr );
        lua_pushinteger ( L, -1);
        return 1;
    }
    pthread_attr_setdetachstate( &attr, PTHREAD_CREATE_JOINABLE );
    pthread_create(&conn->_thread, 0, threadMain, (void *)tag);
    //成功
    lua_pushinteger ( L, 0);
    return 1;
}

static int lua_f_send( lua_State *L )
{
    if (lua_isnoneornil(L,1) || lua_isnoneornil(L,2)) {
        //发送失败
        lua_pushlightuserdata(L,NULL);
        return 1;
    }

    int tag = luaL_checkinteger(L, 1);
    struct ListNode * connNode = listFind(connlist,tag);
    if( NULL == connNode )
    {
        //发送失败
        lua_pushinteger(L,-1);
        return 1;
    }
    struct ConnThread * conn = (struct ConnThread *) connNode->data;

    char * buffer;
    unsigned short len;

    if (lua_type(L,2) == LUA_TSTRING) {
        size_t sz;
        buffer = (void *)lua_tolstring(L,2,&sz);
        //拷贝一份
        char * tmpBuff = (char *) malloc(sz+SIZE_OF_HEADER_LEN);
        memcpy(tmpBuff+SIZE_OF_HEADER_LEN,buffer,sz);
        buffer = tmpBuff;
        len = (int)sz;
    } else {
        buffer = lua_touserdata(L,2);
        len = luaL_checkinteger(L,3);
        //拷贝一份
        char * tmpBuff = (char *) malloc(len+SIZE_OF_HEADER_LEN);
        memcpy(tmpBuff+SIZE_OF_HEADER_LEN,buffer,len);
        buffer = tmpBuff;
    }
    if (len == 0) {
        lua_pushinteger(L,-2);
        return 1;
    }
    if (buffer == NULL) {
        return luaL_error(L, "deserialize null pointer");
    }

    //写入长度
    buffer[0] = (len >> 8) & 0xff;
    buffer[1] = len & 0xff;

    struct BufferData * snddata = malloc(sizeof(*snddata));
    snddata->buffer = buffer;
    snddata->len = len+ sizeof(len);

    //进队列
    queue_push(conn->sendQueue,snddata);
    lua_pushinteger(L,0);

    return 1;
}

static int lua_f_get( lua_State *L )
{
    if (lua_isnoneornil(L,1) || lua_isnoneornil(L,2)) {
        //发送失败
        lua_pushlightuserdata(L,NULL);
        return 1;
    }
    int tag = luaL_checkinteger(L, 1);
    struct ListNode * connNode = listFind(connlist,tag);
    if( NULL == connNode )
    {
        //发送失败
        lua_pushlightuserdata(L,NULL);
        return 1;
    }
    struct ConnThread * conn = (struct ConnThread *) connNode->data;

    void * tmpRecvData = queue_pop(conn->recvQueue);
    if ( NULL != tmpRecvData ) 
    {
        struct BufferData * revdata = (struct BufferData *) tmpRecvData;
        lua_pushlstring(L, revdata->buffer, revdata->len);
        
        //释放内存
        free(revdata->buffer);
        free(revdata);
        return 1;
    }

    lua_pushlightuserdata(L,NULL);

    return 1;
}

static int lua_f_ctor( lua_State *L )
{
    size_t vlen;
    const char * mHost = lua_tolstring ( L, 1, &vlen );
    int mPort = luaL_checkinteger(L, 2);
    unsigned short mTag = luaL_checkinteger(L, 3);
    unsigned short mConnectTimeout = luaL_checkinteger(L, 4);
    unsigned short mReadTimeout = luaL_checkinteger(L, 5);
    unsigned short mWriteTimeout = luaL_checkinteger(L, 6);
    struct ConnThread * conn = (struct ConnThread *) malloc(sizeof(struct ConnThread));
    conn->curl = curl_easy_init();

    memset(conn->errorMessage, 0, CURL_ERROR_SIZE);
    conn->closeSocketByUser = 0;
    conn->isRunning = 0;
    conn->isConnect = 0;
    conn->socket = -1;
    conn->connectTimeout = mConnectTimeout;
    conn->readTimeout = mReadTimeout;
    conn->writeTimeout = mWriteTimeout;
    conn->tag = mTag;
    conn->port = mPort;

    printf("ctor ======%p,%d,%d,%d,%d,%d,%d \n",conn,mPort,mTag,conn->tag,mConnectTimeout,mReadTimeout,mWriteTimeout);
    //handl host info
    memset(&conn->host, 0, 64);
    memcpy(&conn->host, mHost, strlen(mHost));
    
    conn->sendQueue = queue_create();
    conn->recvQueue = queue_create();

    //thread 
    pthread_mutex_init(&conn->mutexWrite, NULL);

    //返回对象
    lua_pushlightuserdata(L, conn);

    if( NULL == connlist)
    {
        connlist = listCreate(conn);
    }
    else
    {
        listAppend(connlist,listCreate(conn));
        printf("append connection\n");
    }

    return 1;
}

LUALIB_API int luaopen_threadsocket( lua_State *L )
{
    luaL_checkversion(L);

    luaL_Reg l[] = {
        { "ctor", lua_f_ctor },
        { "start", lua_f_start },
        { "stop", lua_f_stop },
        { "send", lua_f_send },
        { "get", lua_f_get },
        { NULL, NULL },
    };

    luaL_newlib(L,l);

    return 1;
}

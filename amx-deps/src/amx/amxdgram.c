/*  Datagram sending/receiving module for the Pawn Abstract Machine
 *
 *  This module uses the UDP protocol (from the TCP/IP protocol suite).
 *
 *  Copyright (c) ITB CompuPhase, 2005-2008
 *
 *  This software is provided "as-is", without any express or implied warranty.
 *  In no event will the authors be held liable for any damages arising from
 *  the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *
 *  1.  The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software. If you use this software in
 *      a product, an acknowledgment in the product documentation would be
 *      appreciated but is not required.
 *  2.  Altered source versions must be plainly marked as such, and must not be
 *      misrepresented as being the original software.
 *  3.  This notice may not be removed or altered from any source distribution.
 *
 *  Version: $Id: amxdgram.c 3664 2006-11-08 12:09:25Z thiadmer $
 */

#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "amx.h"
#if defined __WIN32 || defined _WIN32 || defined WIN32
  #include <malloc.h>
  #include <winsock.h>
#else
  #include <arpa/inet.h>
  #include <netinet/in.h>
  #include <sys/ioctl.h>
  #include <sys/types.h>
  #include <sys/socket.h>
  #include <netdb.h>
  #include <unistd.h>
#endif

#define EXPECT_PARAMS(num) \
  do { \
    if (params[0]!=(num)*sizeof(cell)) \
      return amx_RaiseError(amx,AMX_ERR_PARAMS),0; \
  } while(0)


#define SRC_BUFSIZE     22
#define BUFLEN          512
#define AMX_DGRAMPORT   9930  /* default port */

#if !defined SOCKET_ERROR
  #define SOCKET_ERROR -1
#endif

#if !defined isdigit
  #define isdigit(c)     ((unsigned)((c)-'0')<10u)
#endif

static int sLocal;

static unsigned long udp_GetHostAddr(const char *host,int index)
{
  unsigned long addr=inet_addr(host);
  if (addr==0xffffffffL) {
    struct hostent *phost=gethostbyname(host);
    if (phost!=NULL) {
      /* count the number of addresses in the list */
      int count;
      for (count=0; phost->h_addr_list[count]!=0; count++)
        /* nothing */;
      if (index<count)
        addr=*(unsigned long *)phost->h_addr_list[index];
    } /* if */
  } /* if */
  return addr;
}

static int udp_Open(void)
{
#if defined __WIN32 || defined _WIN32 || defined WIN32
  WORD wVersionRequested = MAKEWORD(1,1);
  WSADATA wsaData;
#endif
  int optval = 1;

  #if defined __WIN32 || defined _WIN32 || defined WIN32
    WSAStartup(wVersionRequested, &wsaData);
  #endif

  if ((sLocal=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
    return -1;

  if (setsockopt(sLocal, SOL_SOCKET, SO_BROADCAST, (void*)&optval, sizeof optval) == -1)
    return -1;

  return sLocal;
}

static int udp_Close(void)
{
  if (sLocal>=0) {
    #if defined __WIN32 || defined _WIN32 || defined WIN32
      closesocket(sLocal);
    #else
      close(sLocal);
    #endif
  } /* if */

  #if defined __WIN32 || defined _WIN32 || defined WIN32
    WSACleanup();
  #endif

  return 0;
}

static int udp_Send(const char *host,short port,const char *message,int size)
{
  struct sockaddr_in sRemote;

  if (sLocal<0)
    return -1;

  memset((void *)&sRemote,0,sizeof sRemote);
  sRemote.sin_family=AF_INET;
  sRemote.sin_port=htons(port);
  sRemote.sin_addr.s_addr= (host[0]=='\0') ? htonl(INADDR_BROADCAST) : udp_GetHostAddr(host,0);

  if (sendto(sLocal,message,size,0,(struct sockaddr *)&sRemote,sizeof sRemote)==-1)
    return -1;

  return size;
}

/* This call is blocking
 * if source is not NULL, it must point to a buffer that can contain at least
 * 22 characters.
 */
static int udp_Receive(char *message,size_t maxmsg,char *source)
{
  struct sockaddr_in sSource;
#if defined __WIN32 || defined _WIN32 || defined WIN32
  int slen = sizeof(sSource);
#else
  socklen_t slen = sizeof(sSource);
#endif
  int size;

  size=recvfrom(sLocal, message, maxmsg, 0, (struct sockaddr *)&sSource, &slen);
  if (size==-1)
    return -1;
  if (source!=NULL)
    sprintf(source, "%s:%d", inet_ntoa(sSource.sin_addr), ntohs(sSource.sin_port));

  return size;
}

static int udp_IsPacket(void)
{
  int result;
  fd_set rdset;
  struct timeval time;

  /* the select() function waits until the socket can be read, or until a
   * time-out occurs; the time-out is set to 1 microsecond (the shortest
   * delay possible).
   */
  time.tv_sec=0;
  time.tv_usec=1;
  FD_ZERO(&rdset);
  FD_SET(sLocal,&rdset);
  result=select(0,&rdset,NULL,NULL,&time);
  if (result==SOCKET_ERROR)
    return -1;

  return result != 0;
}

static int udp_Listen(short port)
{
  struct sockaddr_in sFrom;

  memset((void *)&sFrom,0,sizeof sFrom);
  sFrom.sin_family=AF_INET;
  sFrom.sin_port=htons(port);
  sFrom.sin_addr.s_addr=htonl(INADDR_ANY);
  if (bind(sLocal,(struct sockaddr *)&sFrom,sizeof sFrom)==-1)
    return -1;

  return 0;
}

static AMX_IDLE PrevIdle = NULL;
static int idxReceiveString = -1;
static int idxReceivePacket = -1;
static short dgramPort = 0;
static int dgramBound = 0;

/* sendstring(const message[], const destination[]="")
 * destination has the format "127.0.0.1:9930"; when set to an empty string,
 * a broadcast is sent.
 * To mark the text as a "string", the function inserts a "byte order mark" in
 * front of it. It does this for Extended ASCII strings too, although this is
 * not entirely correct.
 * Returns true on success, false on failure.
 */
static cell AMX_NATIVE_CALL n_sendstring(AMX *amx, const cell *params)
{
  int length;
  cell *cstr;
  char *host, *message, *ptr;
  short port;

  EXPECT_PARAMS(2);

  if (amx_GetAddr(amx, params[1], &cstr)!=AMX_ERR_NONE) {
err_native:
    amx_RaiseError(amx,AMX_ERR_NATIVE);
    return 0;
  } /* if */
  amx_UTF8Len(cstr, &length);

  if ((message = alloca(length + 3 + 1)) == NULL)
    return 0;
  /* insert the byte order mark (BOM) */
  message[0]='\xef';
  message[1]='\xbb';
  message[2]='\xbf';
  /* if this is a wide string, convert it to UTF-8 */
  if ((ucell)*cstr<=UNPACKEDMAX) {
    ptr=message+3;
    while (*cstr!=0)
      amx_UTF8Put(ptr, &ptr, length - (ptr-message), *cstr++);
    *ptr='\0';
  } else {
    amx_GetString(message+3, cstr, 0, UNLIMITED);
  } /* if */

  amx_StrParam(amx, params[2], host);
  if (host == NULL)
    goto err_native;
  port=AMX_DGRAMPORT;
  if ((ptr=strchr(host,':'))!=NULL && isdigit(ptr[1])) {
    *ptr++='\0';
    port=(short)atoi(ptr);
  } /* if */
  return (udp_Send(host,port,message,strlen(message)+1) > 0);
}

/* sendpacket(const packet[], size, const destination[]="")
 * destination has the format "127.0.0.1:9930"; when set to an empty string,
 * a broadcast is sent.
 * Returns true on success, false on failure.
 */
static cell AMX_NATIVE_CALL n_sendpacket(AMX *amx, const cell *params)
{
  cell *cstr;
  char *host, *ptr;
  short port;

  EXPECT_PARAMS(3);

  if (amx_GetAddr(amx, params[1], &cstr)!=AMX_ERR_NONE) {
err_native:
    amx_RaiseError(amx,AMX_ERR_NATIVE);
    return 0;
  } /* if */
  amx_StrParam(amx, params[3], host);
  if (host == NULL)
    goto err_native;
  port=AMX_DGRAMPORT;
  if ((ptr=strchr(host,':'))!=NULL && isdigit(ptr[1])) {
    *ptr++='\0';
    port=(short)atoi(ptr);
  } /* if */
  return (udp_Send(host,port,(const char *)cstr,params[2] * sizeof(cell)) > 0);
}

/* listenport(port)
 * A program must call this function from main() or another start-up function
 * because the module will use the default port 9930 otherwise.
 */
static cell AMX_NATIVE_CALL n_listenport(AMX *amx, const cell *params)
{
  EXPECT_PARAMS(1);
  (void)amx;
  dgramPort = (short)params[1];
  return 0;
}

static int AMXAPI amx_DGramIdle(AMX *amx, int AMXAPI Exec(AMX *, cell *, int))
{
  char message[BUFLEN], source[SRC_BUFSIZE];
  cell amx_addr_msg, amx_addr_src;
  int len, chars;
  int err=0;

  assert(idxReceiveString >= 0 || idxReceivePacket >= 0);

  if (PrevIdle != NULL)
    PrevIdle(amx, Exec);

  /* set up listener (first call only) */
  if (!dgramBound) {
    if (dgramPort==0)
      dgramPort=AMX_DGRAMPORT;  /* use default port if none was set */
    if (udp_Listen(dgramPort)==-1)
      return AMX_ERR_GENERAL;
    dgramBound=1;
  } /* if */

  if (udp_IsPacket()) {
    len=udp_Receive(message, sizeof message / sizeof message[0], source);
    amx_PushString(amx,&amx_addr_src,NULL,source,1,0);
    /* check the presence of a byte order mark: if it is absent, the received
     * packet is no string; also check the packet size against string length
     */
    if ((message[0]!='\xef' || message[1]!='\xbb' || message[2]!='\xbf'
        || len!=(int)strlen(message)+1 || idxReceiveString<0) && idxReceivePacket>=0)
    {
      /* receive as "packet" */
      amx_Push(amx,len);
      amx_PushArray(amx,&amx_addr_msg,NULL,(cell*)message,len);
      err=Exec(amx,NULL,idxReceivePacket);
    } else {
      const char *msg=message;
      if (msg[0]=='\xef' && msg[1]=='\xbb' && msg[2]=='\xbf')
        msg+=3;                 /* skip BOM */
      /* optionally convert from UTF-8 to a wide string */
      if (amx_UTF8Check(msg,&chars)==AMX_ERR_NONE) {
        cell *array=alloca((chars+1)*sizeof(cell));
        cell *ptr=array;
        if (array==NULL) {
          err=AMX_ERR_MEMORY;
          goto release_src;
        } /* if */
        while (err==AMX_ERR_NONE && *msg!='\0')
          amx_UTF8Get(msg,&msg,ptr++);
        *ptr=0;               /* zero-terminate */
        amx_PushArray(amx,&amx_addr_msg,NULL,array,chars+1);
      } else {
        amx_PushString(amx,&amx_addr_msg,NULL,msg,1,0);
      } /* if */
      err=Exec(amx,NULL,idxReceiveString);
    } /* if */
    while (err==AMX_ERR_SLEEP)
      err=Exec(amx,NULL,AMX_EXEC_CONT);
    amx_Release(amx,amx_addr_msg);
release_src:
    amx_Release(amx,amx_addr_src);
  } /* if */

  return err;
}


static const AMX_NATIVE_INFO natives[] = {
  { "sendstring", n_sendstring },
  { "sendpacket", n_sendpacket },
  { "listenport", n_listenport },
  { NULL, NULL }        /* terminator */
};

int AMXEXPORT AMXAPI amx_DGramInit(AMX *amx)
{
  dgramBound = 0;
  if (udp_Open()==-1)
    return AMX_ERR_GENERAL;

  /* see whether there is an @receivestring() function */
  if (amx_FindPublic(amx,"@receivestring",&idxReceiveString)==AMX_ERR_NONE
      || amx_FindPublic(amx,"@receivepacket",&idxReceivePacket)==AMX_ERR_NONE)
  {
    if (amx_GetUserData(amx,AMX_USERTAG('I','d','l','e'),(void**)&PrevIdle)!=AMX_ERR_NONE)
      PrevIdle=NULL;
    amx_SetUserData(amx,AMX_USERTAG('I','d','l','e'),amx_DGramIdle);
  } /* if */

  return amx_Register(amx,natives,-1);
}

int AMXEXPORT AMXAPI amx_DGramCleanup(AMX *amx)
{
  (void)amx;
  udp_Close();
  return AMX_ERR_NONE;
}

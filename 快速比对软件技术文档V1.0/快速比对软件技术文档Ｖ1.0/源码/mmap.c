#include <sys/types.h>
#include <stdio.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <pthread.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
char *Uflag = NULL;
//static char *ShiftP;
//static char *JustP;
static clock_t begin,end;
static  double cost;
static  char *startS;
//static  char *startJ;
void* just_map();
void* shift_map();

void mk_cache_data(char* fname)
{
    int ret;
    int fd;
    struct stat sb;
    begin = clock();
  //  pthread_t tid_just; 
    pthread_t tid_shift;
    Uflag = (char*)malloc(HASHSIZE);
    if(!Uflag)
    {
        printf("Uflag:memory is not enough\n");
        getchar();
        exit(0);
    }
/***************map file to memory*************************************/
    fd = open(fname, O_RDONLY); //
    fstat(fd, &sb); /* 取得文件大小 */
    printf("sb.sizeof :%ld",sb.st_size);
    startS = mmap(NULL, sb.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    if(startS == MAP_FAILED) /* 判断是否映射成功 */
    {
        printf("mmap file to memory failure!");
        exit(0);
    }
  //  startJ = mmap(NULL, sb.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
  //  if(startJ == MAP_FAILED) /* 判断是否映射成功 */
  //  {
  //      printf("mmap file to memory failure!");
  //      exit(0);
  //  }
    close(fd);
    end = clock();
    cost = (double)(end - begin)/CLOCKS_PER_SEC;
    printf("建cache用时：%lfs\n",cost);
    printf("startS strint count:%ld\n",strlen(startS));
    //printf("startJ strint count:%ld\n",strlen(startJ));
   /************************开2个子线程*****************************************/
    ret = pthread_create(&tid_shift,NULL,(void*)shift_map,NULL);   //保留void*?    ??
    if(ret != 0)
    {
        printf("Create pthread error!\n");
        exit(1);
    } 
/*  ret = pthread_create(&tid_just,NULL,(void*)just_map,NULL);   //保留void*???
    if(ret != 0)
    {
        printf("Create pthread error!\n");
        exit(1);
    }*/ 
    just_map();
/**************************************************************************/

/*********************等待子线程结束****************************/
/*    ret = pthread_join(tid_just,NULL);  //等待子线程结束
    if(ret != 0)
    {
        printf("wait thread tidQue done error:%s\n",strerror(ret));
        exit(1);
    }
*/  
    ret = pthread_join(tid_shift,NULL);  //等待子线程结束
    if(ret != 0)
    {
        printf("wait thread tidMap done error:%s\n",strerror(ret));
        exit(1);
    }
    end = clock();
    cost = (double)(end - begin)/CLOCKS_PER_SEC;
    printf("比对完用时：%lfs\n",cost);
    munmap(startS, sb.st_size); /* 解除映射 */
   // munmap(startJ, sb.st_size); /* 解除映射 */

    free(Uflag);  //释放标志位数组资源
    Uflag = NULL;

    end = clock();
    cost = (double)(end - begin)/CLOCKS_PER_SEC;
    printf("销毁变量用时：%lfs\n",cost);

}

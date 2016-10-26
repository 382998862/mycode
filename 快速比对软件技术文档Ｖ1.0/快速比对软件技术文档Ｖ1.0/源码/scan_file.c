#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <dirent.h>
#include <sys/stat.h>
#define BASE_PATH "/home/mawf/workdir/hash1/input/"  //下机数据所在路径 
#define TIME_DIFF 60000   //秒，检测近6000内的目录更新 
time_t old_time =0;
char* Find_refresh_dir(char* path)
{
    time_t rawtime;
    time ( &rawtime );

    DIR *d; 
    struct dirent *file; 
    struct stat buf;    
    time_t time_diff;
    chdir(path);//Add this, so that it can scan the children dir(please look at main() function)
  
    if(!(d = opendir(path)))
    {
        printf("error opendir %s!!!\n",path);
        return NULL;
    }
    
    while((file = readdir(d)) != NULL)
    {
        
        if(strcmp(file->d_name,".")==0  || strcmp(file->d_name,"..")==0) 
        continue;
        
        if(stat(file->d_name, &buf) ==0  && S_ISDIR(buf.st_mode) )
        {   
            time_diff =  rawtime - buf.st_mtime;
            
            if(time_diff < TIME_DIFF && buf.st_mtime > old_time)
            { 
                old_time = buf.st_mtime;
                closedir(d);
                return file->d_name;
                
            }
        
        } 
    }
    closedir(d);
    return NULL;                                                                
}

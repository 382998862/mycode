#include <string.h>
#include <sys/stat.h> 
#include <time.h>
#include <errno.h>
#include <math.h>
#define STR_JUMP_BASE 50
#define ROW_MAX_LEN 100 //不能太小 值要大于大行的字符数；
#define KEY_LEN 36  //保存一行数据的临时数据大小：36个字符+一个空格
#define CHR_LEN 26  
#define DIR_NAME_LEN 100  
#define HASHSIZE 0xFFFFFFFB //4294967291 //一般取素数,本案例不是常规求余法，无需；
#define PATH_LEN 150    //支持文件名150个字符内；
#define PATH_SAVE "/home/mawf/workdir/hash1/output/"
//#define PATH_HG19 "/home/mawf/workdir/chr/HG19/tailvS4"
//#define PATH_HG19 "/home/mawf/workdir/chr/HG19/hg19kmer.vStest"
#define PATH_HG19 "/home/mawf/workdir/bwa/chrkmer36"
#include "scan_file.c"
//#include "queu1.c"
#include "mmap.c"
//链表节点
   static clock_t begin,end;
   static  double cost;
typedef struct Node{
    //unsigned char b;
    unsigned char num;
    //unsigned int loc; 
    unsigned int hash2;
}HashType;
//线程变量
pthread_mutex_t mutex_flag = PTHREAD_MUTEX_INITIALIZER;

//冲突偏移量
unsigned clash_num_max = 0;
//char str_tmp[36]= {0};//逆序队列入队暂存数据
/**************shiftmapA时所用全局变量**********************/
float Smapped_num[CHR_LEN]= {0};   //比对上的reads条数
float Smapped_num_gc[CHR_LEN]= {0};    //比对上的一条染色体的reads GC含量

float Suniq_mapped_num[CHR_LEN]= {0};
float Suniq_num_gc[CHR_LEN]= {0};

float Srepet_num[CHR_LEN]= {0};
float Srepet_num_gc[CHR_LEN]= {0};

float Stotal_mapped_num= 0;
float Stotal_repet= 0;
float Stotal_uniq= 0;
/*******************合并统计所用全局变量******************/
float mapped_num[CHR_LEN]= {0};   //比对上的reads条数
float mapped_num_gc[CHR_LEN]= {0};    //比对上的一条染色体的reads GC含量

float uniq_mapped_num[CHR_LEN]= {0};
float uniq_num_gc[CHR_LEN]= {0};

float repet_num[CHR_LEN]= {0};
float repet_num_gc[CHR_LEN]= {0};


float total_reads_num = 0;
float total_mapped_num = 0;
float total_uniq = 0;
float total_repet = 0;
float uniq_gc_ratio[CHR_LEN] = {0};
float maped_gc_ratio[CHR_LEN] = {0};
float redun_ratio = 0;
/******************hash table*******************************/
static HashType hashtab[HASHSIZE];   //定义hash数组

/***************函数声明部分*********************************/
//定义hash函数模块；
inline unsigned int  time33_int(char const*str, int len) 
{ 
    unsigned  int hash = 63; //hash初始值变化可调整hash值集合的范围，但不能影响冲突率；已验证。
    for (; len >= 18; len -= 18) 
    { 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
        hash = ((hash << 5) + hash) + *str++; 
    } 


    return hash;  //此处加1是为了解决0索引和全局变量0冲突的问题 
} 

inline unsigned int BKDRHash(char *str,int len)
{
    unsigned int hash = 0;
    for (; len >= 18; len -= 18) 
    { 
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
        hash = hash * 131 + *str++;  //seed  取31可以用移位
    } 
    return hash;
} 
//创建hash表
void CreateHashTable(unsigned Hash1,unsigned Hash2,unsigned Chr_num)
{
    unsigned clash_num = 0; 

    while(hashtab[Hash1].num != 0) 
    {
        Hash1++; 
        clash_num++;
    }//全局变量可以用默认值0来判断空位，如果是局部变量这默认值是随机。
    hashtab[Hash1].hash2 = Hash2;   //小心2个hash值同时冲突
    hashtab[Hash1].num = Chr_num;
 //   //hashtab[Hash1].loc = Chr_loc;
    if(clash_num_max < clash_num) 
        clash_num_max = clash_num;  //记录最大冲突偏移量
}
//查找关键字
unsigned SearchHash(unsigned Hash1,unsigned Hash2)
{
    unsigned i = 0;
    
    if(hashtab[Hash1].num == 0) 
    {
        return HASHSIZE;
    }
    else
    {
        while(hashtab[Hash1].hash2 != Hash2 && i <= clash_num_max ) //注意i的次数 
        {    
            Hash1++;
            i++;
        }
        
        return (i > clash_num_max) ? HASHSIZE : Hash1;
    }
}

//扫描文件目录寻找更新的目录，并返回目录指针
char* scan_base_dir(char* path)
{
    char *Dir_name = NULL;

    while(1)
    {
        sleep(3);
        Dir_name = Find_refresh_dir(path);
        if(Dir_name != NULL) break;
    }
    return Dir_name;
}

FILE *out=NULL;
void save_data(char *file_name)
{
    int i;  //染色体号
        printf("创建:%s\n",file_name);
   // if((out = fopen("/home/mawf/workdir/hash1/output/path_copy21.txt","w"))== NULL) 
    if((out = fopen(file_name,"w"))== NULL) 
    {
        printf("创建新文件失败\n");
        printf("创建:%s\n",file_name);

        perror("fopen");
        printf("strerror: %s\n", strerror(errno)); 
        getchar();
        exit(0);
    }
    fprintf(out,"-------------------------------------------------------------------------------\n");
    fprintf(out,"ChrSeq   UniqNum     UniqGC     UniqGC%%     MapedNum    MapedGC     MapedGC%% \n");  
    fprintf(out,"-------------------------------------------------------------------------------\n");
    for(i = 1; i < CHR_LEN; i++)
    {
        fprintf(out,"%-8d|%-11f|%-11f|%-11f|%-11f|%-11f|%-11f\n",i,uniq_mapped_num[i],uniq_num_gc[i],uniq_gc_ratio[i],mapped_num[i],mapped_num_gc[i],maped_gc_ratio[i]);
    }
    fprintf(out,"------------------------------------------------------------------------------\n");
    fprintf(out,"TotalReads:%f\nMappedReads:%f\nUniqMapReads:%f\nRedunRatio:%f\n",total_reads_num,total_mapped_num,total_uniq,redun_ratio);
    fclose(out);
}

//统计数据函数
void statistic()
{
    int i;
    total_repet = 0;    //初始化统计值
    total_uniq = 0;
    redun_ratio = 0;
    total_mapped_num = 0;
    memset(maped_gc_ratio,0,104);
    
    memset(uniq_mapped_num,0,104);
    memset(uniq_num_gc,0,104);
    memset(uniq_gc_ratio,0,104);

    for(i=0;i<CHR_LEN;i++)
    {
        //线程数据合并  
        mapped_num_gc[i] += Smapped_num_gc[i]; 
        mapped_num[i] += Smapped_num[i]; 
        repet_num_gc[i] += Srepet_num_gc[i]; 
        repet_num[i] += Srepet_num[i]; 
        //数据统计计算 
        maped_gc_ratio[i] = mapped_num_gc[i] / (mapped_num[i]*36);    //比对上GC含量
        
        uniq_mapped_num[i] = mapped_num[i] - repet_num[i];   // 唯一比对上reads数
        uniq_num_gc[i] = mapped_num_gc[i] - repet_num_gc[i]; //唯一比对上gc的含量
        uniq_gc_ratio[i] = uniq_num_gc[i] / (uniq_mapped_num[i]*36);    //唯一比对上reads的GC的百分比
        
        total_repet += repet_num[i];    //比对冗余reads数目（所有染色体）
        total_uniq  += uniq_mapped_num[i];   //唯一比对上总数目（所有染色体）
    }
    total_mapped_num = total_repet + total_uniq;
    redun_ratio = total_repet / total_uniq; //冗余率
}    

void* shift_map()
{
    clock_t end2;
    double cost2;
    int len;
    int gc = 0;
    int find_chrNUM = 0;  //所在染色体号
    unsigned Findex = 0;
    //unsigned find_chrLOC = 0;    //比对返回索引，找到所在的位置
    unsigned  int hash1; 
    unsigned int hash2;
    char *ShiftP = startS;

    //memset(Uflag, 0, HASHSIZE); //标志位清零
    memset(Smapped_num, 0, 104); // 
    memset(Srepet_num, 0, 104); //
    
    memset(Smapped_num_gc, 0, 104); //
    memset(Srepet_num_gc, 0, 104); //
    //ShiftP = start;
    do
    { 
        ShiftP += STR_JUMP_BASE;               //  s视fq文件第一行基数为36
        gc = 0;
        len = 36;
        hash1=63; 
        hash2 = 0;
        while(*ShiftP++ != '\n');    //换行字符值,  换了 词句
        ShiftP += 36;
        while(len--)
        {    
            switch(*--ShiftP)
            {
                case 'A': 
                    hash1 = ((hash1 << 5) + hash1) + 'T';
                    hash2 = hash2 * 131 + 'T';  //seed  取31可以用移位 ,字符换数字？
                    break;    
                case 'T': 
                    hash1 = ((hash1 << 5) + hash1) + 'A';
                    hash2 = hash2 * 131 + 'A';  //seed  取31可以用移位字符换数字？
                    break;    
                case 'C': 
                    hash1 = ((hash1 << 5) + hash1) + 'G';
                    hash2 = hash2 * 131 + 'G';  //seed  取31可以用移位字符换数字？
                    gc++;
                    break;    
                case 'G': 
                    hash1 = ((hash1 << 5) + hash1) + 'C';
                    hash2 = hash2 * 131 + 'C';  //seed  取31可以用移位字符换数字？
                    gc++;
                    break;    
                default: break;   //换goto筛选
            }
   
        }

        Findex = SearchHash(hash1,hash2);   //跟查询正链冲突？加读写锁？最好加上,加上会影响效率？  
        if(Findex != HASHSIZE)  //换0？
        {
            find_chrNUM = hashtab[Findex].num; //有点大注意拆分的文件。
            //find_chrLOC = hashtab[Findex].loc;    //待用,提取位置，以后待用
            Smapped_num[find_chrNUM]++;   //比对上的染色体的reads加1
        
      //      pthread_mutex_lock(&mutex_flag);    //上锁     
            if(*(Uflag+Findex) == 0) //同一read没出现过
            {
                        Smapped_num_gc[find_chrNUM] += gc;
            }   
            else if(*(Uflag+Findex) == 1) //同一read第一次出现重复比对
            {
                Srepet_num[find_chrNUM]++;
                Srepet_num[find_chrNUM]++;
                Smapped_num_gc[find_chrNUM] += gc;
                gc *= 2;
                Srepet_num_gc[find_chrNUM] += gc;
            }       
            else //同一read出现2次以上比对
            {
                Srepet_num[find_chrNUM]++;
                Smapped_num_gc[find_chrNUM] += gc;
                Srepet_num_gc[find_chrNUM] += gc;
            }
            (*(Uflag+Findex))++;
        }
        ShiftP += 76;
      //  pthread_mutex_unlock(&mutex_flag);  //解锁
    }while(*ShiftP);
    end2 = clock();
    cost2 = (double)(end2 - begin)/CLOCKS_PER_SEC;
    printf("Shiftmap用时：%lfs\n",cost2);
    return NULL;
}    
void* just_map()
{
    clock_t end2;
    double cost2;
    end2 = clock();
    cost2 = (double)(end2 - begin)/CLOCKS_PER_SEC;
    printf("just开始表用时：%lfs\n",cost2);
    int len;
    int Acount=0;
    int find_chrNUM = 0;  //所在染色体号
    unsigned Findex = 0;
    //unsigned find_chrLOC = 0;    //比对返回索引，找到所在的位置
    unsigned  int hash1; 
    unsigned int hash2;
    char *JustP = startS;

    //memset(Uflag, 0, HASHSIZE); //标志位清零
    total_reads_num = 0;
    memset(mapped_num, 0, 104); // 
    memset(repet_num, 0, 104); //
    
    memset(mapped_num_gc, 0, 104); //
    memset(repet_num_gc, 0, 104); //
    //JustP = start;
    end2 = clock();
    cost2 = (double)(end2 - begin)/CLOCKS_PER_SEC;
    printf("just memset表用时：%lfs\n",cost2);
    do
    { 
        Acount++;
        JustP += STR_JUMP_BASE;               //  s视fq文件第一行基数为36
        while(*JustP++ != '\n');    //换行字符值,  换了 词句
        hash1 = time33_int(JustP,KEY_LEN);
        hash2 = BKDRHash(JustP,KEY_LEN); 
        Findex = SearchHash(hash1,hash2);   //跟查询正链冲突？加读写锁？最好加上,加上会影响效率？  
        if(Findex != HASHSIZE)
        {
            find_chrNUM = hashtab[Findex].num; //有点大注意拆分的文件。
            //find_chrLOC = hashtab[Findex].loc;    //待用,提取位置，以后待用
            mapped_num[find_chrNUM]++;   //比对上的染色体的reads加1
        
      //      pthread_mutex_lock(&mutex_flag);    //上锁     
            if(*(Uflag+Findex) == 0) //同一read没出现过
            {
                for(len=36;len>0;len--)
                {
                    if(*JustP == 'G' || *JustP == 'C')    //先后以及用数字替换的效率 
                    {
                        mapped_num_gc[find_chrNUM]++;
                    }                    
                    JustP++;
                }
            }   
            else if(*(Uflag+Findex) == 1) //同一read第一次出现重复比对
            {
                repet_num[find_chrNUM]++;
                repet_num[find_chrNUM]++;
                for(len=36;len>0;len--)
                {
                    if(*JustP == 'G' || *JustP == 'C')    //先后以及用数字替换的效率 
                    {
                        mapped_num_gc[find_chrNUM]++;
                        repet_num_gc[find_chrNUM]++;
                        repet_num_gc[find_chrNUM]++;
                    }                    
                    JustP++;
                }
            }       
            else //同一read出现2次以上比对
            {
                repet_num[find_chrNUM]++;
                for(len=36;len>0;len--)
                {
                    if(*JustP == 'G' || *JustP == 'C')    //先后以及用数字替换的效率 
                    {
                        mapped_num_gc[find_chrNUM]++;
                        repet_num_gc[find_chrNUM]++;
                    }                    
                    JustP++;
                }
            }
            (*(Uflag+Findex))++;
            JustP += 40;
        }
        else            //比对不上指针也需要后移
        {
            JustP += 76;
        }
      //  pthread_mutex_unlock(&mutex_flag);  //解锁
    //}while(Acount<2000000);
     }while(*JustP);
    total_reads_num = Acount;
    end2 = clock();
    cost2 = (double)(end2 - begin)/CLOCKS_PER_SEC;
    printf("justmap用时：%lfs\n",cost2);
    return NULL;
}    
    
//遍历打开更新目录中的样本文件
void trave_map_file(char* DirName)
{
    
    //以下是创建待会要保存的分析结果路径
    int status;
    chdir(PATH_SAVE);
    status = mkdir(DirName, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH); 
    if(status < 0)
    {
        printf("不能创建目录\n");
        perror("system");
        printf("strerror: %s\n", strerror(errno)); 
        getchar();
        //exit(1);
    }
    //目录结构体 
    DIR *dp;
    struct dirent *file;
    struct stat buf;
    
/*    //以下是解压输入文件    
    char para[PATH_LEN] = "gzip -rd ";
    chdir(BASE_PATH);
    
    strcat(para,DirName);
    system(para);   //解压
*/
    
    //以下为遍历分析处理刚下机的新批次
    chdir(BASE_PATH);
    if(!(dp = opendir(DirName)))
    {
        printf("error opendir %s!!!\n",DirName);
        exit(0);
    }
    //chdir(path);
    while((file = readdir(dp)) != NULL)
    {
        printf("文件名：%s\n",file->d_name);
        printf("stat：%d\n",stat(file->d_name, &buf));
        printf("sidir：%d\n",S_ISDIR(buf.st_mode));
        if(strcmp(file->d_name,".")==0  || strcmp(file->d_name,"..")==0)
        {
            continue;
        }


            chdir(BASE_PATH);
            chdir(DirName);
            //maping(file->d_name,Clash_num_max);
            mk_cache_data(file->d_name);   //读取文件正向和逆向到2个缓冲队列；
            statistic();
    end = clock();
    cost = (double)(end - begin)/CLOCKS_PER_SEC;
    printf("统计用时：%lfs\n",cost);
            
           
            //保存maping的结果
            chdir(PATH_SAVE);            
            chdir(DirName);
            
            save_data(file->d_name);
    end = clock();
    cost = (double)(end - begin)/CLOCKS_PER_SEC;
    printf("保存数据用时：%lfs\n",cost);
            
            
            
        
    }
}

    
//主函数
int main(int argc,char* argv[])
{   
    clock_t begin,end;
    double cost;
    begin = clock();
     
    char dir_name[DIR_NAME_LEN]; //基目录下刚更新的目录名字
    char *dirname;
    //以下是建立hash表
    printf("程序开始运行......\n");
    FILE* fp;
    if((fp = fopen(argv[1],"rb")) == NULL)
    {
        printf("文件打开失败\n");
        getchar();
        exit(0);
    }
    fread(hashtab,sizeof(HashType),HASHSIZE,fp);
    fclose(fp);
  //*****************************************************************************************//  

    end = clock();
    cost = (double)(end - begin)/CLOCKS_PER_SEC;
    printf("建表用时：%lfs\n",cost);
 //******************************以下是比对查询部分*************************************//
   
    restart : dirname = scan_base_dir(BASE_PATH); //goto语句标号
              printf("更新文件明：%s\n",dirname);
              strcpy(dir_name,dirname);
    printf("-----新数据出现,努力分析中，稍等-----\n");
    begin = clock();
    trave_map_file(dir_name);  //遍历所有更新样本数据并比对
    printf("-----数据分析完毕-----\n");
   
    end = clock();
    cost = (double)(end - begin)/CLOCKS_PER_SEC;
    printf("比对分析统计存储用时：%lfs\n",cost);

    goto restart;  
    
    return 0;
}

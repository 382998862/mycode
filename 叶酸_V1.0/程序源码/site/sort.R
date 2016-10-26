#writer:sunqh <sunqh\@biomarker.com.cn>
#data:2015
#整合数据规律输出

arg<-commandArgs(trailingOnly=TRUE)

files=list.files(path=arg[1],pattern=".txt",full.names=T)
X=matrix(1,nrow=length(files),ncol=2)
for(i in 1:length(files))
{
data<-read.table(files[i],header=F,sep="\t")
a<-data[1,2]
b<-data[2,2]
library(stringdist)
y<-stringdist(a,b)
samplename=unlist(strsplit(files[i],"_|/"))[2]
X[i,1]=samplename
X[i,2]=y
}
write.table(X,"z.txt",row.names=F,col.names=F,sep="\t",quote=F)

a<-read.table("c",header=F,sep="\t")
b<-read.table("z.txt",header=F,sep="\t")
c<-merge(a,b, all = T ,by=c("V1"))
names(c)=c("num","pri","loc","gene","type","rate")
write.table(c,"h",row.names=F,col.names=T,sep="\t",quote=F)

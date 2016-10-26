#writer:sunqh <sunqh\@biomarker.com.cn>
#data:2015
#合并1F、2F、5F的结果

arg<-commandArgs(trailingOnly=TRUE)

a<-read.table("f1",header=T,sep="\t")
b<-read.table("f2",header=T,sep="\t")
c<-read.table("f5",header=T,sep="\t")
d<-merge(a,b, all = T ,by=c("num"))
e<-merge(d,c, all = T ,by=c("num"))
names(e)=c("num","pri","loc","gene","type","rate","pri","loc","gene","type","rate","pri","loc","gene","type","rate")
write.table(e,"z",row.names=F,col.names=T,sep="\t",quote=F)

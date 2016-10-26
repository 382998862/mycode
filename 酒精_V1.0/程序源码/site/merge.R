#writer:sunqh <sunqh\@biomarker.com.cn>
#data:2015

#数据整合，将3F和4F的结果合并

arg<-commandArgs(trailingOnly=TRUE)

a<-read.table("f3",header=T,sep="\t")
b<-read.table("f4",header=T,sep="\t")
d<-merge(a,b, all = T ,by=c("num"))
names(d)=c("num","pri","loc","gene","type","rate","pri","loc","gene","type","rate")
write.table(d,"z",row.names=F,col.names=T,sep="\t",quote=F)

#writer:sunqh <sunqh\@biomarker.com.cn>
#data:2015
#识别第一第二峰图

arg<-commandArgs(trailingOnly=TRUE)

library(sangerseqR)

files=list.files(path=arg[1],pattern=".ab1",full.names=T)

for(i in 1:length(files)){

abiData=readsangerseq(files[i])
#str(abiData)

hetcalls<-makeBaseCalls(abiData,ratio=0.33)

primarySeq=as.character(hetcalls@primarySeq)
secondarySeq=as.character(hetcalls@secondarySeq)
Seq=rbind(primarySeq,secondarySeq)

samplename=unlist(strsplit(files[i],"__"))[1]
write.table(Seq,paste(samplename,"Seq.txt",sep="_"),col.names=F,sep="\t",quote=F)

# trim5/trim3: Number of bases to trim from the beginning/end of the sequence.
# chromatogram(hetcalls,width=100,height=2,showcalls="both",filename=paste(samplename,"chromatogram.pdf",sep="_"))

}
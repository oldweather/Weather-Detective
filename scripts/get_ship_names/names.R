# Make cannonical ship names

s<-read.csv('names.txt',fill=TRUE,header=FALSE,
            stringsAsFactors=FALSE)
d<-read.csv('../../raw_data/Exports/result_all.csv',
            na.strings='NULL',
            stringsAsFactors=FALSE)
names(d)<-c('IMAGE','RECORD.TYPE','YEAR','MONTH','DATE','TIME',
            'THERMOMETER','BAROMETER','WIND.DIRECTION',
            'WIND.FORCE','LATITUDE','LONGITUDE','NOTES')
w<-which(d$RECORD.TYPE=='ship_name')
d<-d[w,]
n<-data.frame()
for(n.i in seq_along(s[[1]])) {
    for(s.i in seq_along(s[n.i,])) {
      if(nchar(s[n.i,s.i])<2) break
      w<-grep(s[n.i,s.i],d$NOTES,ignore.case=TRUE) 
      if(length(w)==0) next
      images<-unique(d[w,]$IMAGE)
      w<-which(d$IMAGE %in% images)
      d[w,]$NOTES<-s[n.i,1]
      n<-rbind(n,d[w,])
      d<-d[-w,] # Don't do any twice
    }
}
write.csv(n[order(n$NOTES),],file='ship.names.csv')
      

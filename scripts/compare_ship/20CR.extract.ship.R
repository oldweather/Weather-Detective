# Get pressures from 20CR, for a selected ship.

ship<-'Alanuda'

library(GSDF.TWCR)

# Get the observations for this ship
s<-read.csv('../convert_units/new_units.csv',
            fill=TRUE,header=FALSE,
            na.strings='NULL',
            stringsAsFactors=FALSE)
w<-grep(ship,s$V4)
s<-s[w,]


# Get mean and spread from 3.2.1 for each ob.
tt<-rep(NA,length(s$V1))
mean<-rep(NA,length(s$V1))
spread<-rep(NA,length(s$V1))
for(i in seq_along(s$V1)) {

  year<-s$V13[i]
  if(year<1891 || year> 1896) next
  month<-s$V14[i]
  day<-s$V15[i]
  hour<-s$V16[i]
  t2m<-TWCR.get.slice.at.hour('air.2m',year,month,day,hour,
                              version='3.2.1',opendap=F)
  tt[i]<-GSDF.interpolate.ll(t2m,s$V11[i],s$V12[i])  
  old<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                              version='3.2.1',opendap=F)
  mean[i]<-GSDF.interpolate.ll(old,s$V11[i],s$V12[i])
  old<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                              type='spread',
                              version='3.2.1',opendap=F)
  spread[i]<-GSDF.interpolate.ll(old,s$V11[i],s$V12[i])
  #if(i==10) break
}

# Output the result
fileConn<-file(sprintf("obs.%s",ship))
writeLines(sprintf("%d %d %d %d %f %f %f %f %f",
                   s$V13,s$V14,s$V15,s$V16,
                   as.numeric(s$V18),mean,spread,
                   as.numeric(s$V17),tt),
                   fileConn)
close(fileConn)

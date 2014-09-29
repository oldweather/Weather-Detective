#!/usr/bin/Rscript --no-save

# Pacific Centre for the 1890s, WD obs only

library(GSDF)
library(GSDF.WeatherMap)
library(parallel)
library(chron)

year<-1894
month<-1
day<-1
hour<-0
start.hour<-hour
n.total<-24*366 # Total number of hours to be rendered
fog.threshold<-exp(1)

GSDF.cache.dir<-sprintf("%s/GSDF.cache",Sys.getenv('GSCRATCH'))
if(!file.exists(GSDF.cache.dir)) dir.create(GSDF.cache.dir,recursive=TRUE)
Imagedir<-sprintf("%s/images/WD",Sys.getenv('GSCRATCH'))
if(!file.exists(Imagedir)) dir.create(Imagedir,recursive=TRUE)

use.cores<-2

c.date<-chron(dates=sprintf("%04d/%02d/%02d",year,month,day),
          times=sprintf("%02d:00:00",hour),
          format=c(dates='y/m/d',times='h:m:s'))

Options<-WeatherMap.set.option(NULL)
Options<-WeatherMap.set.option(Options,'show.mslp',F)
Options<-WeatherMap.set.option(Options,'show.ice',F)
Options<-WeatherMap.set.option(Options,'show.obs',T)
Options<-WeatherMap.set.option(Options,'show.fog',F)
Options<-WeatherMap.set.option(Options,'show.wind',F)
Options<-WeatherMap.set.option(Options,'show.temperature',F)
Options<-WeatherMap.set.option(Options,'show.precipitation',F)
Options<-WeatherMap.set.option(Options,'temperature.range',12)
Options<-WeatherMap.set.option(Options,'obs.size',2)
Options<-WeatherMap.set.option(Options,'obs.colour',rgb(255,215,0,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'ice.colour',Options$land.colour)
Options<-WeatherMap.set.option(Options,'lat.min',-90)
Options<-WeatherMap.set.option(Options,'lat.max',90)
Options<-WeatherMap.set.option(Options,'lon.min',-180)
Options<-WeatherMap.set.option(Options,'lon.max',180)
Options<-WeatherMap.set.option(Options,'pole.lon',10)
Options<-WeatherMap.set.option(Options,'pole.lat',90)

Options$ice.points<-50000
land<-WeatherMap.get.land(Options)

WD.obs<-read.csv('/Users/philip/Projects/WeatherDetective/scripts/interpolate_positions/interpolated.csv')
WD.obs$Year<-1894 #as.integer(substr(WD.obs$V2,1,4))
WD.obs$Month<-as.integer(substr(WD.obs$V2,6,7))
WD.obs$Day<-as.integer(substr(WD.obs$V2,9,10))
WD.obs$Hour<-as.integer(substr(WD.obs$V2,12,13))
WD.obs$ch<-chron(dates=sprintf("%04d/%02d/%02d",WD.obs$Year,WD.obs$Month,WD.obs$Day),
                times=sprintf("%02d:00:00",WD.obs$Hour),
                format=c(dates='y/m/d',times='h:m:s'))

WD.get.obs<-function(year,month,day,hour) {
   o.date<-chron(dates=sprintf("%04d/%02d/%02d",year,month,day),
                times=sprintf("%02d:00:00",hour),
                format=c(dates='y/m/d',times='h:m:s'))
    w<-which(WD.obs$ch>=o.date-0.5 & WD.obs$ch<=o.date+0.5)
    if(length(w)==0) return(NULL)
    s.o<-WD.obs[w,]
    s.o$Latitude<-s.o$V10
    s.o$Longitude<-s.o$V11
    return(s.o)
}   

plot.hour<-function(l.count) {    

    n.date<-c.date+l.count/24
    year<-as.numeric(as.character(years(n.date)))
    month<-months(n.date)
    day<-days(n.date)
    #hour<-hours(n.date)
    hour<-(l.count+start.hour)%%24

    image.name<-sprintf("%04d-%02d-%02d:%02d.png",year,month,day,hour)

    ifile.name<-sprintf("%s/%s",Imagedir,image.name)
    if(file.exists(ifile.name) && file.info(ifile.name)$size>0) return()
    print(sprintf("%d %04d-%02d-%02d:%02d - %s",l.count,year,month,day,hour,
                   Sys.time()))

    obs<-WD.get.obs(year,month,day,hour)
    Options.local<-Options
    if(is.null(obs)) {
      Options.local<-WeatherMap.set.option(Options.local,'show.obs',F)
    }
    #w<-which(obs$Longitude>180)
    #obs$Longitude[w]<-obs$Longitude[w]-360

     png(ifile.name,
             width=1080*16/9,
             height=1080,
             bg=Options$sea.colour,
             pointsize=24,
             type='cairo')
    Options.local$label<-sprintf("%02d-%02d",month,day)
       WeatherMap.draw(Options=Options.local,uwnd=NULL,icec=NULL,
                          vwnd=NULL,precip=NULL,mslp=NULL,
                          t.actual=NULL,t.normal=NULL,land=land,
                          fog=NULL,obs=obs,streamlines=NULL)
    dev.off()
}

r<-mclapply(seq(0,n.total,2),plot.hour,mc.cores=use.cores,mc.preschedule=FALSE)

# For each URL, interpolate missing lats and longs using simple
#  linear fits.

c<-read.csv('../make_cannonical/cannonical.out',
            fill=TRUE,header=FALSE,
            na.strings='NULL',
            stringsAsFactors=FALSE)
by.url<-split(c,c$V1)

simple.fill<-function(y) {
  w<-which(is.na(y))
  g<-which(!is.na(y))
  if(length(w)==0) return(y) # No fill needed
  if(length(w)>length(y)-2) return(y) # Fill impossible
  s<-seq(length(y))
  # interpolate where possible
  for(i in w) {
    below<-g[g<i]
    if(length(below)==0) next
    below<-max(below)
    above<-g[g>i]
    if(length(above)==0) next
    above<-min(above)
    v.above<-y[above]
    v.below<-y[below]
    if(abs(v.above-360-v.below)<abs(v.above-v.below)) v.above<-v.above-360
    if(abs(v.above+360-v.below)<abs(v.above-v.below)) v.above<-v.above+360
    if(abs(v.above-v.below)>10) next # Big difference - don't interpolate
    weight<-(above-i)/(above-below)
    y[i]<-v.below*weight+v.above*(1-weight)
    if(y[i]>180) y[i]<-y[i]-360
    if(y[i]< -180) y[i]<-y[i]+360
  }
  # Extrapolate at the top and bottom
  w<-which(is.na(y))
  g<-which(!is.na(y))
  if(length(w)==0) return(y) # No fill needed
  mg<-min(g)
  if(mg>1 && !is.na(y[mg+1])) {
    dg<-y[mg+1]-y[mg]
    if(dg>360) dg<-dg-360
    if(dg< -360) dg<-dg+360
    for(i in seq(mg-1,1)) {
      if(dg>5) break
      y[i]<-y[mg]-(mg-i)*dg
      if(y[i]>180) y[i]<-y[i]-360
      if(y[i]< -180) y[i]<-y[i]+360
    }
  }
  mg<-max(g)
  if(mg<length(y) && !is.na(y[mg-1])) {
    dg<-y[mg]-y[mg-1]
    if(dg>360) dg<-dg-360
    if(dg< -360) dg<-dg+360
    for(i in seq(mg+1,length(y))) {
      if(dg>5) break
      y[i]<-y[mg]-(mg-i)*dg
      if(y[i]>180) y[i]<-y[i]-360
      if(y[i]< -180) y[i]<-y[i]+360
    }
  }
    
  return(y)
}
  

for(i in seq_along(by.url)) {
  by.url[[i]]$V10<-simple.fill(by.url[[i]]$V8)
  w<-which(by.url[[i]]$V10>90 | by.url[[i]]$V10< -90)
  if(length(w)>0) is.na(by.url[[i]]$V10)<-TRUE
  by.url[[i]]$V11<-simple.fill(by.url[[i]]$V9)
  w<-which(by.url[[i]]$V11>180 | by.url[[i]]$V10< -180)
  if(length(w)>0) is.na(by.url[[i]]$V11)<-TRUE
}
o<-do.call('rbind',by.url)
write.csv(o,file='interpolated.csv')
  
  

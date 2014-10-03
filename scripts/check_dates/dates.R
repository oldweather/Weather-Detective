# Find transcribed dates inconsistent with the expected range
#  or with the directory names.
# Apply some fixes derived by checking the originals.

d<-read.csv('../make_cannonical/cannonical.out',
            header=F,
            na.strings='NULL',
            stringsAsFactors=FALSE)
first.year<-as.integer(gsub('\\D*(\\d\\d\\d\\d).*','\\1',d$V1))
last.year<-as.integer(gsub('.*(\\d\\d\\d\\d)\\D*/.*','\\1',d$V1))
transcribed.year<-as.integer(substr(d$V2,1,4))

# Identify the problem years
w<-which(transcribed.year<first.year | transcribed.year>last.year)

# Stray Decembers and Januaries are OK
transcribed.month<-as.integer(substr(d$V2,6,7))
ok<-which(transcribed.year==first.year-1 & transcribed.month==12)
ok<-c(ok,
    which(transcribed.year==last.year+1 & transcribed.month==1))

# Some 1892s in an 1895 directory are OK
o2<-which(grepl('january_1895_february_1895',d$V1) & transcribed.year==1892)
ok<-c(ok,o2)

# Remove problems which are really OK
w2<-which(w %in% ok)
w<-w[-w2]

# Where directory specifies one year, set transcribed year to directory year
w3<-which(first.year==last.year)
w4<-which(w %in% w3)
transcribed.year[w[w4]]<-first.year[w[w4]]

# Otherwise, set transcribed year to missing
transcribed.year<-as.character(transcribed.year)
transcribed.year[w[-w4]]<-'    '
substr(d$V2,1,4)<-transcribed.year
write.csv(d,file='fixed.dates.out',
          na='NULL',
          quote=FALSE,row.names=FALSE)




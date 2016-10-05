FROM centos:7
MAINTAINER Mnuolr <18x@ihx.me>


ADD jbls /usr/bin/jbls

RUN chmod +x /usr/bin/jbls

#Set port
EXPOSE 8080

CMD ["jbls"]

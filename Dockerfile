
FROM rocker/shiny:latest

WORKDIR /build

# system libraries of general use
RUN apt-get update && apt-get install -y \
    git g++ \
    sudo \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    zlib1g-dev 

ENV DEBIAN_FRONTEND=noninteractive

RUN cd /build \
 && mkdir fftw3 \
 && cd fftw3 \
 && wget http://www.fftw.org/fftw-3.3.8.tar.gz \
 && tar -xzvf fftw-3.3.8.tar.gz \
 && cd fftw-3.3.8 \
 && ./configure --prefix=/build/fftw3 --enable-shared \
 && make && make install

# install R packages required 
RUN R -e "install.packages('shiny', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('shinydashboard', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('shinyFiles', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('DT', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('xtable', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('aws.s3', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('viridis', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('lubridate', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('wkb', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('plotrix', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('geosphere', repos='http://cran.rstudio.com/')"

RUN cd /build \
 && git clone https://github.com/remnrem/luna-base.git \
 && git clone https://github.com/remnrem/luna.git \
 && cd luna-base \
 && make FFTW=/build/fftw3 -j 2 \
 && ln -s /build/luna-base/luna /usr/local/bin/luna \
 && ln -s /build/luna-base/destrat /usr/local/bin/destrat \
 && ln -s /build/luna-base/behead /usr/local/bin/behead \
 && cd /build \
 && R CMD build luna \
 && LUNA_BASE=/build/luna-base FFTW=/build/fftw3 R CMD INSTALL luna_0.24.tar.gz


COPY *.R /srv/shiny-server/
COPY .Renviron /home/shiny/

# select port
EXPOSE 3838

# allow permission
RUN sudo chown -R shiny:shiny /srv/shiny-server
RUN sudo chown -R shiny:shiny /home/shiny/.Renviron

USER shiny

# Create a script to pass command line args to python
RUN echo "#!/bin/bash" > /home/shiny/runme.sh
RUN echo "env | grep SESSION_SLST >> /home/shiny/.Renviron" >> /home/shiny/runme.sh
RUN echo "/usr/bin/shiny-server" >> /home/shiny/runme.sh
RUN ["chmod", "+x", "/home/shiny/runme.sh" ]

# run app
#CMD [ "/usr/bin/shiny-server"]
CMD [ "/home/shiny/runme.sh" ]


#
# lunaR/NAP/Moonshine
# v0.02, 13-April-2020
# http://zzz.bwh.harvard.edu/luna/
#

library(luna)

library(shiny , quietly = T )
library(DT , quietly = T )
library(shinyFiles , quietly = T )
library(xtable , quietly = T )
library(shinydashboard , quietly = T )
library(viridis , quietly = T )


##
## Environment variables (& determine run-mode)
##

##
##  i) Moonshine:
##       - only signal/annotation viewer (no NAP components)
##       - expects to run via fixed sample list (e.g. for Docker use) or Open Dialog (local)
##
##  ii) NAP
##       - includes NAP components/tabs
##       - run either via AWS or fixed sample-path
##

use_moonshine <- Sys.getenv( "USE_MOONSHINE" ) == "TRUE" 

use_nap       <- Sys.getenv( "USE_NAP" ) == "TRUE" 

use_aws       <- Sys.getenv( "USE_S3" ) == "TRUE" || Sys.getenv( "USE_AWS" ) == "TRUE"


if ( use_moonshine && ( use_nap || use_aws ) )
 stop( "cannot specify moonshine + NAP or AWS run-modes" )


##
## Other environment variables
##

SESSION_PATH <- Sys.getenv("SESSION_PATH")

SESSION_SLST <- Sys.getenv("SESSION_SLST")

SESSION_SLST="s.lst"
message("SESSION_PATH " , SESSION_PATH , "\n" ) 
message("SESSION_SLST " , SESSION_SLST , "\n" ) 

# test case
#use_moonshine = T
#SESSION_PATH="/Users/smp37/tmp22/data/user1/example1/"



#
# temporary fix: hard-code a sample list instead of allowing upload
#

fixed.sl <- paste( SESSION_PATH, SESSION_SLST , sep="/", collapse = NULL)

#library(aws.s3 , quietly = T )
#library(lubridate , quietly = T )
#library(wkb , quietly = T )
#library(digest , quietly = T )


##
## AWS run-mode variables
##

if ( use_aws )
{
 s3BucketName <- "nap-nsrr"
 enc_key <- charToRaw(Sys.getenv('ENCRYPT_KEY'))
 enc_iv <- charToRaw(Sys.getenv('ENCRYPT_IV'))
 AWS_ACCESS_KEY_ID <- Sys.getenv("AWS_ACCESS_KEY_ID")
 AWS_SECRET_ACCESS_KEY <- Sys.getenv("AWS_SECRET_ACCESS_KEY")
 AWS_DEFAULT_REGION <- Sys.getenv("AWS_DEFAULT_REGION")
 aws.user <- ""
 aws.runid <- ""
}




#
# temporary fix: point to NAP output directory, where we look for any tables/figures under nap.dir/{id}/
#

nap.dir <- paste( SESSION_PATH, "nap/", sep="/", collapse = NULL)


#
# UI: Moonshine or NAP 
#

if ( use_moonshine ) {
  source( "ui-moonshine.R" , local = T )
} else {
  source( "ui-nap.R" , local = T )
}

#
# Server logic
#

server <- function(input, output, session) {

#
# handle inputs
#

source( "inp.R" , local = T  ) 

#
# Functions
#

if ( use_nap ) source( "tab_nap.R" , local = T )
  
source( "tab_headers.R" , local = T )

source( "tab_annots.R" , local = T )

source( "tab_staging.R" , local = T )

if ( use_nap ) source( "tab_suds.R" , local = T )

source( "tab_signals.R" , local = T )

source( "tab_spectral.R" , local = T )

}


#
# run the application
#

shinyApp( ui = ui, server = server)
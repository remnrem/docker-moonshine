

#
# pallele w/ 10 distinctive colours
#

pal10 <- c(
  rgb(255,88,46,max=255) ,
  rgb(1,56,168,max=255),
  rgb(177,212,18,max=255),
  rgb(255,128,237,max=255),
  rgb(1,199,86,max=255),
  rgb(171,0,120,max=255),
  rgb(85,117,0,max=255),
  rgb(251,180,179,max=255),
  rgb(95,32,0,max=255),
  rgb(164,209,176,max=255)
  )


#
# Define UI for LunaR interdace
#

ui <- fluidPage(

  dashboardPage(  
    
    #
    # Application title
    #
    
    dashboardHeader( title = "Luna | NAP" ),
    
    dashboardSidebar(
      uiOutput("samplesLocal"),      
      selectInput( "edfs", label = "Samples", choices = list() ) ,      
      selectInput( "sel.ch", "Channels" , list(), multiple = TRUE, selectize = TRUE ),      
      selectInput( "sel.ann", "Annotations" , list(), multiple = TRUE, selectize = TRUE ),
      br(), hr(),       
      selectInput( "disp.ann", "Annotations (list instances)" , list(), multiple = TRUE, selectize = TRUE ),      
      selectInput( "sel.inst", "Instances" , list(), multiple = TRUE ,  selectize = FALSE )
      ),
    
    
    dashboardBody( tabsetPanel(
      
      tabPanel( "NAP", actionButton("refresh_nap_log", "Reload NAP log"), br(), verbatimTextOutput("logger", placeholder = TRUE) ),

      tabPanel( "Headers", br() , tableOutput("header.summary") , br(), dataTableOutput("header.channels") ),

      tabPanel( "Staging",
      		tabsetPanel(
                 tabPanel( "Manual", br(), textOutput("stage.num.epochs"), hr(), plotOutput("stage.view", width='100%', height="100px"), hr(), tableOutput("stage.summary") ),
                 tabPanel( "SUDS", br(), textOutput("suds.num.epochs"), hr(), plotOutput("suds.view" , width='100%', height="100px") )  ) ) ,

      tabPanel( "Annotations" ,
                plotOutput("annot.view", width = '100%', height = "200px") ,
                br() , 
                tabsetPanel( tabPanel( "Summary" , tableOutput("annot.summary") ) , tabPanel( "Instances" , dataTableOutput("annot.table") ) ) ),
      
      tabPanel( "Signals",                
                verbatimTextOutput("info2"),
                plotOutput( "signal.master", width='100%', height="30px", click="master_click", dblclick="master_dblclick", 
                            brush = brushOpts( id="master_brush", direction="x", resetOnNew=F ) ), 
                plotOutput( "signal.master2", width='100%', height="10px" ),
                br(),
		plotOutput( "signal.view" , width='100%', height="600px", dblclick="zoom_dblclick", 
                            brush = brushOpts( id="zoom_brush", direction="x", resetOnNew=F ) ) ), 
      
      # to resize the plot dynamically, uiOutput() rather than plotOutput()
      tabPanel( "Spectral",
                sliderInput("sel.freq", "Frequency (Hz)", width = '100%', min=0, max=100, step=0.25, value=c(0.25, 35) ) ,
      	        uiOutput('ui_psdplot') ),

      tabPanel( "Tables",
                selectInput("sel.table.group", label="Group", choices=list() ),
                selectInput("sel.table.table", label="Table", choices=list()),
                hr(),
                dataTableOutput("table.table") ),
      
      tabPanel( "Figures",
                selectInput("sel.figure.group", label="Group", choices=list() ),
                selectInput("sel.figure.figure", label="Figure", choices=list() ),
                hr(),
                imageOutput("figure.view") )
      
    )  # tabsetpanel
    
    ) #dashboardBody
    ) #dashboardPage
) # fluidPage

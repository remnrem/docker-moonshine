  #
  # keep state information here...
  #
  
  values <- reactiveValues()


  #
  # upload (or use fixed) sample-list
  #
  
  verify_token <- reactive({
    query<- parseQueryString(session$clientData$url_search)
    is_valid <- FALSE
    is_valid <- tryCatch({
        aes <- AES(enc_key, mode="CBC", enc_iv)
        decrypted <- strsplit(aes$decrypt(hex2raw(query[["token"]])),'\003')[[1]][1]
        if( !is.na(suppressWarnings(as.numeric(decrypted)))){
          token_time<-as.numeric(decrypted)
          curr_epoch= time_length(interval('1970-01-01 00:00:00 EDT', Sys.time()),"second")*1000
          if ((curr_epoch - token_time) >0 && (curr_epoch - token_time) < 86400000){
            return(TRUE)
          }
        }
       },error= function(e){
          return(FALSE)
    })
    return(is_valid)
  })
  

  


  attached.sl <- reactive({
    
    query <- parseQueryString(session$clientData$url_search)

    SESSION_SLST <- Sys.getenv("SESSION_SLST")

    fixed.sl <- paste( SESSION_PATH, SESSION_SLST , sep="/", collapse = NULL)

    if ( fixed.sl != "" && ! use_aws )
    {
     if (use_moonshine) 
      sl <- lsl( fixed.sl , SESSION_PATH )
     else 
      sl <- lsl( fixed.sl )
    }
    else if( length(query) == 0 )
     {
      output$samplesLocal <- renderUI({
        fileInput("samples", "Sample List" ,  accept = c( "lst" ) )
      })
      req( input$samples )
      sl <- lsl(input$samples$datapath) 
      use_aws <<- FALSE
    }

    # AWS run-mode
    else
    {

      req(query[["user"]],query[["token"]])
      req(verify_token())

      use_aws <<-TRUE
      random=sample(1:1000000000000, 1)
      session_dir= paste(SESSION_PATH,"session",random,sep='/',collapse = NULL)
      dir.create(session_dir,recursive = TRUE)
      setwd(session_dir)
      session$onSessionEnded(function(){
        unlink(session_dir,recursive = TRUE)
      })

      aws.user <<- query[["user"]]
      aws.runid <<- ""
      if (!is.null(query[["runid"]])){
        aws.runid <<- query[["runid"]]
      }

      keyV=paste(aws.user, aws.runid, "s.lst", sep = "/", collapse = NULL)
      final_keyV=gsub("//","/",keyV)

      index=1
      pre_val=paste(aws.user, aws.runid, sep = "/", collapse = NULL)
      s3_bucket <<- get_bucket( s3BucketName, prefix=pre_val )
      for (i in s3_bucket) {
        if ( i["Key"] == final_keyV) break
        index= index+1
      }

      save_object(s3_bucket[[index]], file=s3_bucket[[index]][["Key"]] )
      sl <- lsl( s3_bucket[[index]][["Key"]] )
    }
    
    # update sample-list selector
    updateSelectInput(session , "edfs" , choices = names(sl), selected = FALSE)
    values$sl <- sl
  })
  


  #
  # load EDF
  #
  
  attached.edf <- reactive({

    req(attached.sl() , input$edfs)

    if (use_aws) {
      nap.dir <<- paste( getwd(), aws.user, aws.runid, "nap", sep = "/", collapse = NULL)
      get_nap=TRUE
      nap_files <-paste(user,runid,"nap",input$edfs,sep = "/", collapse = NULL)
      for (file_name in values$sl[input$edfs][[1]]){
        file_index<-1
        for (f in s3_bucket){
          file_path=paste(aws.user,aws.runid,file_name,sep = "/", collapse = NULL)
          final_path=gsub("//","/",file_path)
          if (f[["Key"]] == final_path){
            save_object(s3_bucket[[file_index]],file=file_name, show_progress = TRUE)
          }
          if (grepl(nap_files,f[["Key"]]) && get_nap){
            save_object(s3_bucket[[file_index]],file=f[["Key"]], show_progress = TRUE)
          }
          file_index<-file_index+1
        }
        get_nap<-FALSE
      }
    }

    # lunaR to attach EDF from sample-list

    lattach(values$sl , input$edfs )

    # ID
    values$ID <- input$edfs

    # channels
    x <- lchs()
    names(x) <- x
    values$channels <- x

    # annotations
    values$annots <- lannots()
    values$annot.inst <- leval("ANNOTS")$ANNOTS
    
    # epoch (fixed at 30 seconds)
    values$ne <- lepoch()
    
    # attach pre-computed sigstats, if exists
    values$sigstats <- NULL
    sigstats.filename <- paste(nap.dir, values$ID , "nap.sigstats.RData" , sep = "/")
    if ( file.exists( sigstats.filename ) ) {
      # loads 'sigstats'
      load( sigstats.filename )  
      values$sigstats <- sigstats   
      rm( sigstats )
    }
    
    # update control widgets
    updateSelectInput(
      session,
      "sel.ch",
      choices = values$channels ,
      label = paste(length(values$channels) , "channels"),
      selected = 0
    )
    updateSelectInput(
      session,
      "sel.ann",
      choices = values$annots  ,
      label = paste(length(values$annots) , "annotations"),
      selected = 0
    )
    updateSelectInput(
      session,
      "disp.ann",
      choices = values$annots  ,
      label = paste(length(values$annots) , "annotations (list instances)"),
      selected = 0
    )

    # get SS 
    values$ss <- leval("STAGE")$STAGE$E
    
    # plot views (seconds)
    values$epochs <- c(1,1)  
    values$zoom <- NULL 
    values$raw.signals <- T 
    
    # get channel units
    k <- leval("HEADERS")$HEADERS$CH
    values$units <- k$PDIM
    isolate( { names( values$units ) <- as.character( k$CH ) } )
    
    # any NAP tables?
    nap.files <-
      list.files(paste(nap.dir, values$ID , sep = "/") ,
                 full.names = T ,
                 pattern = "*-tab.RData")
    cat("dir" , paste(nap.dir, values$ID , sep = "/") , "\n")
    print(nap.files)
    tmpenv = new.env()
    invisible(lapply(nap.files, load, envir = tmpenv))
    values$data <- as.list(tmpenv)
    rm(tmpenv)
    groups <- unlist(lapply(values$data , "[[" , "desc"))
    d.groups <- as.list(names(groups))
    names(d.groups) <- unlist(groups)
    updateSelectInput(
      session,
      "sel.table.group",
      choices = d.groups  ,
      label = paste(length(d.groups) , " groups")
    )
    
    # any NAP figures?
    nap.files <-
      list.files(paste(nap.dir, values$ID , sep = "/") ,
                 full.names = T ,
                 pattern = "*-fig.RData")
    tmpenv = new.env()
    invisible(lapply(nap.files, load, envir = tmpenv))
    values$figures <- as.list(tmpenv)
    rm(tmpenv)
    groups <- unlist(lapply(values$figures , "[[" , "desc"))
    d.groups <- as.list(names(groups))
    names(d.groups) <- unlist(groups)
    updateSelectInput(
      session,
      "sel.figure.group",
      choices = d.groups,
      label = paste(length(d.groups) , " groups")
    )
    
  })

  # 
  # annot-instance list selector
  #

  observe( {
    req( values$annot.inst )
    flt <- values$annot.inst$ANNOT_INST_T1_T2$ANNOT %in% input$disp.ann
    if ( sum(flt)>0) {
      secs1  <- values$annot.inst$ANNOT_INST_T1_T2$START[ flt ]
      secs2  <- values$annot.inst$ANNOT_INST_T1_T2$STOP[ flt ]
      annot <- values$annot.inst$ANNOT_INST_T1_T2$ANNOT[ flt ]
      #      inst <- values$annot.inst$ANNOT_INST_T1_T2$INST[ flt ]
      vals <- paste( annot , secs1 , sep=": " )
      inst <- as.list( paste( secs1, secs2 ) )
      names( inst ) <- vals
      if ( length(secs1)>0 ) inst <- inst[ order( secs2 ) ] 
      updateSelectInput(
        session,
        "sel.inst",
        choices = inst , 
        label = paste(length(secs1) , " instances," , length(input$disp.ann) , "annotations"),
        selected = 0
      )
    }
  })
  

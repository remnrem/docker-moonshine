  #
  # SUDS
  #
  
  output$suds.view <- renderPlot({
    req(attached.edf())
    par(mar = c(2.2, 4, 1, 0))
    # get SUDS stages, if they exist
    suds.filename <- paste(nap.dir, values$ID , "suds.eannot" , sep = "/")
    if ( file.exists( suds.filename ) ) {
      # check matches manual
      suds <- scan( suds.filename , what = integer() )
      if ( length( values$ss$E ) != 0  & length(values$ss$E ) != length( suds ) ) {
         cat( "SEA" , length( values$ss$E ) , length( suds ) , "\n" )
               stop("SUDS epoch length does not match")
    }
      suds.str <- rep( "?" , length( suds ) )
      suds.str[ suds == 1 ] <- "wake"
      suds.str[ suds == 0 ] <- "REM"
      suds.str[ suds == -1 ] <- "NREM1"
      suds.str[ suds == -2 ] <- "NREM2"
      suds.str[ suds == -3 ] <- "NREM2"
      
      # hypnogram image
      plot( values$ss$E / 120 , suds , type = "l" , lwd = 2, col = "gray" , axes = F , ylim = c(-3, 2) , ylab = "" )
      points( values$ss$E / 120 , suds , col = lstgcols( suds.str ) , type = "p" , cex = 1 , pch = 20 )
      axis(1)
      axis(2 , 2 , "?" , col.axis = "black" , las = 2)
      axis(2 , 1 , "W" , col.axis = lstgcols("wake") , las = 2)
      axis(2 , 0 , "R" , col.axis = lstgcols("REM") , las = 2)
      axis(2 ,-1 , "N1" , col.axis = lstgcols("NREM1") , las = 2)
      axis(2 ,-2 , "N2" , col.axis = lstgcols("NREM2") , las = 2)
      axis(2 ,-3 , "N3" , col.axis = lstgcols("NREM3") , las = 2)
    }
  })
  
  

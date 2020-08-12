

output$header.summary <- renderTable({

  req(attached.sl() , attached.edf())

  k <- leval("HEADERS")

  df <- k$HEADERS$BL

  names(df) <- c(
      "ID",
      "ID (EDF header)",
      "Number of records",
      "Number of signals",
      "Record duration (secs)",
      "Start date",
      "Start time",
      "Duration (hh:mm:ss)",
      "Duration (secs)"
    )

  # return value
  t(df)
  } ,
  width = '100%' , rownames = T , colnames = F , striped = T
 )
  


output$header.channels <- renderDataTable({

  req(attached.sl() , attached.edf())

  k <- leval("HEADERS")$HEADERS$CH

  k$ID <- NULL

  k <- k[, c("CH", "SR", "PDIM", "PMIN", "PMAX")]

  names(k) <- c("Channel" , "Sample rate", "Unit", "Minimum", "Maximum")

  # return value
  k
 } ,
  rownames = FALSE,
  options = list( pageLength=20, rownames=F , columnDefs = list(list( className="dt-center", targets = "_all" ) ) )
)

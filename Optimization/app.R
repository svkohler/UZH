library(shiny)
library(dplyr)
library(shinycssloaders)

##################
# App Multi-period optimization problem
##################


# user interface
ui <- fluidPage(
  tabsetPanel(
    tabPanel(
      "Start", 
      titlePanel("Multi-period Consumption Optimization"),
      withMathJax(),
      helpText('The expression to be optimzed: $$U(x_0) + \\delta*\\beta[p[U(x_{1(u)})+\\beta(U(x_{2(u)}))]+
           (1-p)[U(x_{1(d)})+\\beta(U(x_{2(d)}))]]$$'),
      tags$head(tags$style('h5 {color:gray;}')),
      tags$h5("Remark: The following optimizations are done using the Nelder-Mead Algorithm"),
      # panel where all the external variables are set
      wellPanel(fluidRow(tags$h3("Select external variables below:")),
                fluidRow(tags$h4("wages")),
                fluidRow(column(3, sliderInput(inputId = "wage_0", label = "wage period 0", value=75, min=10, max=150)),
                         column(3, sliderInput(inputId = "wage_1_up", label = "wage period 1 (up)", value = 100, min = 10, max=150)),
                         column(3, sliderInput(inputId = "wage_1_down", label = "wage period 1 (down)", value = 25, min = 10, max=150)),
                         column(3, sliderInput(inputId = "wage_2", label = "wage period 2", value = 50, min = 10, max=150)),
                ),
                fluidRow(tags$h4("discount factors, interest, scenario probabilities:")),
                fluidRow(column(3, sliderInput(inputId = "delta", label = "delta", value=0.8, min=0, max=1.5)),
                         column(3, sliderInput(inputId = "beta", label = "beta", value = 0.9, min = 0, max=1)),
                         column(3, sliderInput(inputId = "r", label = "interest", value=1.1, min=1, max=5, step=0.1)),
                         column(3, sliderInput(inputId = "p", label = "probability scenario up", value = 0.6, min = 0, max=1)),
                ),
                fluidRow(tags$h4("select the utility function:")),
                fluidRow(column(3, selectInput(inputId = "u", label = "utility function", choices=c("log", "sqrt"), selected="log"))),
      ),
      tags$hr(),
      # reactive button
      actionButton(inputId = "optim", label="start optimization"),
      tags$hr(),
      # title for table
      textOutput(outputId = "title_table"),
      # output of the optimization result
      tableOutput(outputId = "optim_results"),
      # title for constraints
      textOutput(outputId = "title_constraints"),
      # output of the optimization result
      tableOutput(outputId = "constraints")
    ),
    # second panel for the plots
    tabPanel("Plots", 
             helpText("The external variables are taken from the tab <Start>"),
             # drop-down menu to select the variables for range analysis
             wellPanel(fluidRow(tags$h3("Select external variables for range analysis:")),
                       # left plot
                       fluidRow(column(2, selectInput(inputId = "select_plot_left", 
                                                      label = "variable left plot", 
                                                      choices = c("wage_0"="wage_0",
                                                                  "wage_1_up"="wage_1_up",
                                                                  "wage_1_down"="wage_1_down",
                                                                  "wage_2"="wage_2",
                                                                  "delta"="delta",
                                                                  "beta"="beta",
                                                                  "r"="r",
                                                                  "p"="p"))),
                                column(2, numericInput(inputId = "from_left", label="from", value="insert")),
                                column(2, numericInput(inputId = "to_left", label="to", value="insert")),
                                # right plot
                                column(2, selectInput(inputId = "select_plot_right", 
                                                      label = "variable left plot", 
                                                      choices = c("wage_0"="wage_0",
                                                                  "wage_1_up"="wage_1_up",
                                                                  "wage_1_down"="wage_1_down",
                                                                  "wage_2"="wage_2",
                                                                  "delta"="delta",
                                                                  "beta"="beta",
                                                                  "r"="r",
                                                                  "p"="p"))),
                                column(2, numericInput(inputId = "from_right", label="from", value="insert")),
                                column(2, numericInput(inputId = "to_right", label="to", value="insert")),
                       )
                       ),
             tags$hr(),
             fluidRow(column(6,actionButton(inputId = "plot_left", label="plot left")),
                      column(6, actionButton(inputId = "plot_right", label="plot right"))),
             tags$hr(),
             fluidRow(column(6, plotOutput(outputId = "left_plot") %>% withSpinner(color="#0dc5c1")),
                      column(6, plotOutput(outputId = "right_plot") %>% withSpinner(color="#0dc5c1")))
  )
)
)

# server side of the app. Here: R Code to be performed.
server <- function(input, output){
  # order of parameters [c,s,c_1_up,c_2_down]
  results_optim <- eventReactive(input$optim,
                           {utility <- function(params){
                             # we optimze over the endogenic variables:
                             # -> cash_savings in period 0 (c)
                             # -> investment in period 0 (s)
                             # -> cash consumption in period 1 (up/down)
                             
                             ### external variables
                             
                             # wages
                             wage_0 <- input$wage_0
                             wage_1_up <- input$wage_1_up
                             wage_1_down <- input$wage_1_down
                             wage_2 <- input$wage_2
                             
                             # discount factors
                             delta <- input$delta
                             beta <- input$beta
                             
                             # interest
                             r <- input$r
                             
                             # scenario probabilites
                             p <- input$p
                             
                             # utility function
                             if(input$u == "log"){
                               u <- function(x){
                                 return(log(x))
                               }
                             }else{
                               u <- function(x){
                                 return(sqrt(x))
                               }
                             }
                             
                             
                             # function
                             U <- u(wage_0-params[1]-params[2]) + 
                               delta*beta*(p*(u(wage_1_up+params[3])+beta*u(wage_2+(params[1]-params[3])+r*params[2]))+
                                             (1-p)*(u(wage_1_down+params[4])+beta*u(wage_2+(params[1]-params[4])+r*params[2])))
                             
                             return(U)
                           }
                           
                           # constraint optimization
                           
                           # constrain matrix and constraint vector. Make sure that cash consumption in period 1 is not higher than
                           # cash savings in period 0
                           ui <- rbind(c(1,0,0,0), # makes sure cash savings in period 0 is positive
                                       c(0,1,0,0), # makes sure investment in period 0 is positive
                                       c(0,0,1,0), # makes sure cash consumption (up) in period 1 is positive
                                       c(0,0,0,1), # makes sure cash consumption (down) in period 1 is positive
                                       c(1,0,-1,0), # makes sure cash savings in period 0 are bigger than cash consumption (up) in period 1
                                       c(1,0,0,-1), # makes sure cash savings in period 0 are bigger than cash consumption (down) in period 1
                                       c(-1,-1,0,0) # makes sure that wage in period 0 is bigger than cash savings and investment in period 0
                                       )
                           ci <- c(0,0,0,0,0,0,-input$wage_0)
                           
                           # call the constrained-optimization function
                           opt <- constrOptim(theta = c(5,5,1,1), 
                                        f=utility, # function to optimize
                                        grad=NULL, 
                                        ui=ui, ci=ci, # constraints
                                        control = list(fnscale = -1)) # search for a maximum
                           # define table to collect optimized parameters
                           table <- data.frame(matrix(opt$par, nrow = 1, ncol = 4))
                           colnames(table) <- c("cash savings period 0", 
                                                "investment period 0", 
                                                "cash spending period 1 (up)", 
                                                "cash spending period 1 (down)")
                           
                           # build constraints table
                           constraints_table <- data.frame(matrix(nrow = 1, ncol=5))
                           colnames(constraints_table) <- c("wages >= 0", 
                                                            "interest >= 1", 
                                                            "p*delta <= 1",
                                                            "0 < beta <= 1",
                                                            "w_0 >= (c+s)")
                           # constrain 1
                           if(input$wage_0 >=0 && input$wage_1_up >=0 && input$wage_1_down >=0 && input$wage_2 >=0){
                             constraints_table[1,1] <- "ok"
                           }else{
                             constraints_table[1,1] <- "violated"
                           }
                           # constrain 2
                           if(input$r >=1){
                             constraints_table[1,2] <- "ok"
                           }else{
                             constraints_table[1,2] <- "violated"
                           }
                           # constrain 3
                           if(input$p * input$delta <=1){
                             constraints_table[1,3] <- "ok"
                           }else{
                             constraints_table[1,3] <- "violated"
                           }
                           # constrain 4
                           if(input$beta >0 && input$beta <=1){
                             constraints_table[1,4] <- "ok"
                           }else{
                             constraints_table[1,4] <- "violated"
                           }
                           # constrain 5
                           if(input$wage_0 >=table[1]+table[2]){
                             constraints_table[1,5] <- "ok"
                           }else{
                             constraints_table[1,5] <- "violated"
                           }
                           output <- list(results=table, constraints=constraints_table)
                           output
                          }
                          )
  
  # code for left plot
  results_plot_left <- eventReactive(input$plot_left, {
    # define range
    range_left <- seq(input$from_left, input$to_left, (input$to_left-input$from_left)/20)
    # define matrices where we collect optimized parameters
    params_left <- matrix(NA, nrow=length(range_left), ncol=5)
    colnames(params_left) <- c(input$select_plot_left,
                               "cash savings period 0", 
                                "investment period 0", 
                                "cash spending period 1 (up)", 
                                "cash spending period 1 (down)")
    # start loop
    for(l in 1:length(range_left)){
      utility <- function(params){
        
        # we optimze over the endogenic variables:
        # -> cash_savings in period 0 (c)
        # -> investment in period 0 (s)
        # -> cash consumption in period 1 (up/down)
        
        ### external variables
        
        # wages
        if(input$select_plot_left == "wage_0"){
          wage_0 <- range_left[l]
        }else{
          wage_0 <- input$wage_0
        }
        
        if(input$select_plot_left == "wage_1_up"){
          wage_1_up <- range_left[l]
        }else{
          wage_1_up <- input$wage_1_up
        }
        
        if(input$select_plot_left == "wage_1_down"){
          wage_1_down <- range_left[l]
        }else{
          wage_1_down <- input$wage_1_down
        }
        
        if(input$select_plot_left == "wage_2"){
          wage_2 <- range_left[l]
        }else{
          wage_2 <- input$wage_2
        }
        
        
        # discount factors
        if(input$select_plot_left == "delta"){
          delta <- range_left[l]
        }else{
          delta <- input$delta
        }
        
        if(input$select_plot_left == "beta"){
          beta <- range_left[l]
        }else{
          beta <- input$beta
        }
        
        # interest
        if(input$select_plot_left == "r"){
          r <- range_left[l]
        }else{
          r <- input$r
        }
        
        # scenario probabilites
        if(input$select_plot_left == "p"){
          p <- range_left[l]
        }else{
          p <- input$p
        }
        
        # utility function
        if(input$u == "log"){
          u <- function(x){
            return(log(x))
          }
        }else{
          u <- function(x){
            return(sqrt(x))
          }
        }
        
        
        # function
        U <- u(wage_0-params[1]-params[2]) + 
          delta*beta*(p*(u(wage_1_up+params[3])+beta*u(wage_2+(params[1]-params[3])+r*params[2]))+
                        (1-p)*(u(wage_1_down+params[4])+beta*u(wage_2+(params[1]-params[4])+r*params[2])))
        
        return(U)
      }
      
      # constraint optimization
      
      # constrain matrix and constraint vector. Make sure that cash consumption in period 1 is not higher than
      # cash savings in period 0
      if(input$select_plot_left == "wage_0"){
        wage_0 <- range_left[l]
      }else{
        wage_0 <- input$wage_0
      }
      ui <- rbind(c(1,0,0,0)
                  ,c(0,1,0,0)
                  ,c(0,0,1,0),
                  c(0,0,0,1),
                  c(1,0,-1,0),
                  c(1,0,0,-1),
                  c(-1,-1,0,0))
      ci <- c(0,0,0,0,0,0,-wage_0)
      
      # order of parameters [c,s,c_1_up,c_2_down]
      opt <- constrOptim(theta = c(5,5,1,1), 
                         f=utility, grad=NULL, 
                         ui=ui, ci=ci, 
                         control = list(fnscale = -1))
      params_left[l,] <- c(range_left[l],opt$par)
    }
    params_left

  })
  
  # code for right plot
  results_plot_right <- eventReactive(input$plot_right, {
    # define range
    range_right <- seq(input$from_right, input$to_right, (input$to_right-input$from_right)/20)
    # define matrices where we collect optimized parameters
    params_right <- matrix(NA, nrow=length(range_right), ncol=5)
    colnames(params_right) <- c(input$select_plot_right,
                               "cash savings period 0", 
                               "investment period 0", 
                               "cash spending period 1 (up)", 
                               "cash spending period 1 (down)")
    # start loop
    for(l in 1:length(range_right)){
      utility <- function(params){
        
        # we optimze over the endogenic variables:
        # -> cash_savings in period 0 (c)
        # -> investment in period 0 (s)
        # -> cash consumption in period 1 (up/down)
        
        ### external variables
        
        # wages
        if(input$select_plot_right == "wage_0"){
          wage_0 <- range_right[l]
        }else{
          wage_0 <- input$wage_0
        }
        
        if(input$select_plot_right == "wage_1_up"){
          wage_1_up <- range_right[l]
        }else{
          wage_1_up <- input$wage_1_up
        }
        
        if(input$select_plot_right == "wage_1_down"){
          wage_1_down <- range_right[l]
        }else{
          wage_1_down <- input$wage_1_down
        }
        
        if(input$select_plot_right == "wage_2"){
          wage_2 <- range_right[l]
        }else{
          wage_2 <- input$wage_2
        }
        
        
        # discount factors
        if(input$select_plot_right == "delta"){
          delta <- range_right[l]
        }else{
          delta <- input$delta
        }
        
        if(input$select_plot_right == "beta"){
          beta <- range_right[l]
        }else{
          beta <- input$beta
        }
        
        # interest
        if(input$select_plot_right == "r"){
          r <- range_right[l]
        }else{
          r <- input$r
        }
        
        # scenario probabilites
        if(input$select_plot_right == "p"){
          p <- range_right[l]
        }else{
          p <- input$p
        }
        
        # utility function
        if(input$u == "log"){
          u <- function(x){
            return(log(x))
          }
        }else{
          u <- function(x){
            return(sqrt(x))
          }
        }
        
        
        # function
        U <- u(wage_0-params[1]-params[2]) + 
          delta*beta*(p*(u(wage_1_up+params[3])+beta*u(wage_2+(params[1]-params[3])+r*params[2]))+
                        (1-p)*(u(wage_1_down+params[4])+beta*u(wage_2+(params[1]-params[4])+r*params[2])))
        
        return(U)
      }
      
      # constraint optimization
      
      # constrain matrix and constraint vector. Make sure that cash consumption in period 1 is not higher than
      # cash savings in period 0
      if(input$select_plot_right == "wage_0"){
        wage_0 <- range_right[l]
      }else{
        wage_0 <- input$wage_0
      }
      ui <- rbind(c(1,0,0,0)
                  ,c(0,1,0,0),
                  c(0,0,1,0),
                  c(0,0,0,1),
                  c(1,0,-1,0),
                  c(1,0,0,-1),
                  c(-1,-1,0,0))
      ci <- c(0,0,0,0,0,0,-wage_0)
      
      # order of parameters [c,s,c_1_up,c_2_down]
      opt <- constrOptim(theta = c(5,5,1,1), 
                         f=utility, grad=NULL, 
                         ui=ui, ci=ci, 
                         control = list(fnscale = -1))
      params_right[l,] <- c(range_right[l],opt$par)
    }
    params_right
    
  })
  
  output$left_plot <- renderPlot({
    plot(results_plot_left()[,1], results_plot_left()[,2], 
         col=1, pch=1, type="b", xlab=input$select_plot_left, ylab="endogenic variables", 
         ylim=c(0.9*min(results_plot_left()[,2:5]), 1.1*max(results_plot_left()[,2:5])))
    lines(results_plot_left()[,1], results_plot_left()[,3], col=2, pch=2, type="b")
    lines(results_plot_left()[,1], results_plot_left()[,4], col=3, pch=3, type="b")
    lines(results_plot_left()[,1], results_plot_left()[,5], col=4, pch=4, type="b")
    legend("topleft", col=1:4, cex=0.8, legend = colnames(results_plot_left())[2:5], pch = 1:4 )
  })
  
  output$right_plot <- renderPlot({
    plot(results_plot_right()[,1], results_plot_right()[,2], 
         col=1, pch=1, type="b", xlab=input$select_plot_right, ylab="endogenic variables",
         ylim=c(0.9*min(results_plot_right()[,2:5]), 1.1*max(results_plot_right()[,2:5])))
     lines(results_plot_right()[,1], results_plot_right()[,3], col=2, pch=2, type="b")
    lines(results_plot_right()[,1], results_plot_right()[,4], col=3, pch=3, type="b")
    lines(results_plot_right()[,1], results_plot_right()[,5], col=4, pch=4, type="b")
    legend("topleft", col=1:4, cex=0.8, legend = colnames(results_plot_right())[2:5], pch = 1:4 )
  })
  
  title_table <- eventReactive(input$optim, {
    "Optimization results for chosen parameters: "
  })
  
  output$title_table <- renderText({title_table()})
  output$optim_results <- renderTable({
    out <- results_optim()
    t <- out$results
    t
    })
  
  title_constraints <- eventReactive(input$optim, {
    "Check constraints for current optimization: "
  })
  output$title_constraints <- renderText({title_constraints()})
  output$constraints <- renderTable({
    out <- results_optim()
    t <- out$constraints
    t
  })
  
}

shinyApp(ui=ui, server=server)
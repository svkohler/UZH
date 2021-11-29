

#############
# Multi-period optimization scenario
#############

# utility function to optimize

### external variables

# wages
wage_0 <- 100
wage_1_up <- 50
wage_1_down <- 10
wage_2 <- 40

# discount factors
delta <- 0.8
beta <- 0.9

# interest
r <- 2

# scenario probabilites
p <- 0.6

# utility function
u <- function(x){
  return(log(x))
}

utility <- function(params){
  
  # we optimze over the endogenic variables:
  # -> cash_savings in period 0 (c)
  # -> investment in period 0 (s)
  # -> cash consumption in period 1 (up/down)
  
  # function
  U <- u(wage_0-params[1]-params[2]) + 
    delta*beta*(p*(u(wage_1_up+params[3])+beta*u(wage_2+(params[1]-params[3])+r*params[2]))+
                  (1-p)*(u(wage_1_down+params[4])+beta*u(wage_2+(params[1]-params[4])+r*params[2])))
  
  return(U)
}

# constraint optimization

# constrain matrix and constraint vector.
ui <- rbind(c(1,0,0,0),
            c(0,1,0,0),
            c(0,0,1,0),
            c(0,0,0,1),
            c(1,0,-1,0),
            c(1,0,0,-1),
            c(-1,-1,0,0)
            )
ci <- c(0,0,0,0,0,0,-wage_0)

# order of parameters [c,s,c_1_up,c_2_down]
results <- constrOptim(theta = c(5,5,1,1), f=utility, grad=NULL, ui=ui, ci=ci, control = list(fnscale = -1))
print(results)


############################

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

# drop-down menu to select the variables for range analysis
fluidRow(column(12, tags$h3("Select external variables for range analysis:"), 
                wellPanel(fluidRow(column(6, 
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
                                                   column(2, numericInput(inputId = "to_left", label="to", value="insert"))
                                          )
                )
                )
                ),
                wellPanel(fluidRow(column(6, 
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
                                                   column(2, numericInput(inputId = "to_left", label="to", value="insert"))
                                          )
                )
                )
                )
)
),
)

plot(results_plot_2D()[,1], results_plot_2D()[,2], 
     col=1, pch=1, type="b", xlab=input$select_plot_2D, ylab="endogenic variables", 
     ylim=c(0.9*min(results_plot_2D()[,2:5]), 1.1*max(results_plot_2D()[,2:5])))
lines(results_plot_2D()[,1], results_plot_2D()[,3], col=2, pch=2, type="b")
lines(results_plot_2D()[,1], results_plot_2D()[,4], col=3, pch=3, type="b")
lines(results_plot_2D()[,1], results_plot_2D()[,5], col=4, pch=4, type="b")
legend("topleft", col=1:4, cex=0.8, legend = colnames(results_plot_2D())[2:5], pch = 1:4 )

plot(results_plot_right()[,1], results_plot_right()[,2], 
     col=1, pch=1, type="b", xlab=input$select_plot_right, ylab="endogenic variables",
     ylim=c(0.9*min(results_plot_right()[,2:5]), 1.1*max(results_plot_right()[,2:5])))
lines(results_plot_right()[,1], results_plot_right()[,3], col=2, pch=2, type="b")
lines(results_plot_right()[,1], results_plot_right()[,4], col=3, pch=3, type="b")
lines(results_plot_right()[,1], results_plot_right()[,5], col=4, pch=4, type="b")
legend("topleft", col=1:4, cex=0.8, legend = colnames(results_plot_right())[2:5], pch = 1:4 )



fluidRow(column(6, wellPanel(fluidRow(column(4, selectInput(inputId = "select_plot_2D", 
                                                            label = "exog. var.", 
                                                            choices = c("wage_0"="wage_0",
                                                                        "wage_1_up"="wage_1_up",
                                                                        "wage_1_down"="wage_1_down",
                                                                        "wage_2"="wage_2",
                                                                        "delta"="delta",
                                                                        "beta"="beta",
                                                                        "r"="r",
                                                                        "p"="p"))),
                                      column(4, numericInput(inputId = "from_2D", label="from", value="insert")),
                                      column(4, numericInput(inputId = "to_2D", label="to", value="insert"))
),
fluidRow(column(12, checkboxGroupInput(inputId = "endogenic_vars_2D",
                                       label = "Choose endogenic variables to plot",
                                       choices=c("c", "s", "c1_u", "c1_d"),
                                       selected = c("c", "s"),
                                       inline = TRUE))),
)),
column(6, wellPanel(fluidRow(column(4, selectInput(inputId = "exog_1_3D", 
                                                   label = "exog. var 1", 
                                                   choices = c("wage_0"="wage_0",
                                                               "wage_1_up"="wage_1_up",
                                                               "wage_1_down"="wage_1_down",
                                                               "wage_2"="wage_2",
                                                               "delta"="delta",
                                                               "beta"="beta",
                                                               "r"="r",
                                                               "p"="p"))),
                             column(4, numericInput(inputId = "from_exog_1_3D", label="from", value="insert")),
                             column(4, numericInput(inputId = "to_exog_1_3D", label="to", value="insert"))
),
fluidRow(column(4, selectInput(inputId = "exog_2_3D", 
                               label = "exog. var 2", 
                               choices = c("wage_0"="wage_0",
                                           "wage_1_up"="wage_1_up",
                                           "wage_1_down"="wage_1_down",
                                           "wage_2"="wage_2",
                                           "delta"="delta",
                                           "beta"="beta",
                                           "r"="r",
                                           "p"="p"))),
         column(4, numericInput(inputId = "from_exog_2_3D", label="from", value="insert")),
         column(4, numericInput(inputId = "to_exog_2_3D", label="to", value="insert"))
),
fluidRow(column(4, selectInput(inputId = "endo_3D", 
                               label = "endog. var", 
                               choices = c("c"="c",
                                           "s"="s",
                                           "c1_u"="c1_u",
                                           "c1_d"="c1_d")))
),
))),


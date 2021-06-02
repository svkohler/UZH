library(shiny)
library(dplyr)
library(shinycssloaders)

##################
# App Multi-period optimization problem
##################

source("source.R")

# user interface
ui <- fluidPage(
  tabsetPanel(
    tabPanel(
      "Start", 
      #
      # title section
      titlePanel("Multi-period Consumption Optimization"),
      withMathJax(),
      helpText('The expression to be optimzed: $$U(x_0) + \\delta*\\beta[p[U(x_{1(u)})+\\beta(U(x_{2(u)}))]+
           (1-p)[U(x_{1(d)})+\\beta(U(x_{2(d)}))]]$$'),
      tags$head(tags$style('h5 {color:gray;}')),
      tags$h5("Remark: The following optimizations are done using the Nelder-Mead Algorithm.
              The optimization is repeated multiple times with different initilization values and the average is returned."),
      #
      # panel where all the external variables are set
      wellPanel(fluidRow(tags$h3("Select external variables below:")),
                fluidRow(tags$h4("wages")),
                fluidRow(column(3, sliderInput(inputId = "wage_0", label = "wage period 0", value=5, min=1, max=10, step=0.1)),
                         column(3, sliderInput(inputId = "wage_1_up", label = "wage period 1 (up)", value = 7, min = 1, max=10, step=0.1)),
                         column(3, sliderInput(inputId = "wage_1_down", label = "wage period 1 (down)", value = 3, min = 1, max=10, step=0.1)),
                         column(3, sliderInput(inputId = "wage_2", label = "wage period 2", value = 5, min = 1, max=10, step=0.1)),
                ),
                fluidRow(tags$h4("discount factors, interest, scenario probabilities:")),
                fluidRow(column(3, sliderInput(inputId = "delta", label = "delta", value=0.8, min=0.5, max=1.1)),
                         column(3, sliderInput(inputId = "beta", label = "beta", value = 0.9, min = 0.5, max=1.1)),
                         column(3, sliderInput(inputId = "r", label = "interest", value=1.1, min=0.9, max=2, step=0.1)),
                         column(3, sliderInput(inputId = "p", label = "probability scenario up", value = 0.6, min = 0, max=1)),
                ),
                fluidRow(tags$h4("select the utility function and alpha-factor:")),
                  fluidRow(column(3, selectInput(inputId = "u", label = "utility function", choices=c("log: a*log(1+x)", "sqrt: (x^a)/a"), selected="log")),
                         column(3, sliderInput(inputId = "alpha", label = "alpha", value = 0.5, min = 0, max=5, step=0.1)),
                         ),
      ),
      # horizontal line
      tags$hr(),
      #
      # reactive button
      fluidRow(column(2, numericInput(inputId = "iter_optim", label="select no. of initializations", value = 100)),
               column(2, actionButton(inputId = "optim", label="start optimization"))),
      # horizontal line
      tags$hr(),
      #
      # tables for optimization results and constraints
      textOutput(outputId = "title_table"),
      # output of the optimization result
      tableOutput(outputId = "optim_results"),
      # title for constraints
      textOutput(outputId = "title_constraints"),
      # output of the optimization result
      tableOutput(outputId = "constraints")
    ),
    #
    # start second panel for the plots
    #
    # title section
    tabPanel("Plots", 
             helpText("The external variables are taken from the tab <Start>"),
             #
             wellPanel(fluidRow(column(2, selectInput(inputId = "select_plot_2D", 
                                                      label = "exog. var.", 
                                                      choices = c("wage_0"="wage_0",
                                                                  "wage_1_up"="wage_1_up",
                                                                  "wage_1_down"="wage_1_down",
                                                                  "wage_2"="wage_2",
                                                                  "delta"="delta",
                                                                  "beta"="beta",
                                                                  "r"="r",
                                                                  "p"="p"))),
                                column(2, numericInput(inputId = "from_2D", label="from", value="insert")),
                                column(2, numericInput(inputId = "to_2D", label="to", value="insert")),
                                column(6, checkboxGroupInput(inputId = "endogenic_vars_2D",
                                                              label = "Choose endogenic variables to plot",
                                                              choices=c("c", "s", "c1_u", "c1_d"),
                                                              selected = c("c", "s"),
                                                              inline = TRUE))
             ),
             ),
             tags$hr(),
             fluidRow(column(2, numericInput(inputId = "iter_2D", label="select no. of initializations", value = 50)),
                      column(2, actionButton(inputId = "plot_2D", label="plot 2D-Plot"))),
             plotOutput(outputId = "plot_2D"),
             tags$hr(),
             wellPanel(
               fluidRow(column(4, selectInput(inputId = "exog_1_3D", 
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
             ),
             tags$hr(),
             fluidRow(column(2, numericInput(inputId = "iter_3D", label="select no. of initializations", value = 25)),
                      column(2, actionButton(inputId = "plot_3D", label="plot 3D-Plot"))),
             plotlyOutput(outputId = "graph")
    )
  )
)

# server side of the app. Here: R Code to be performed.
server <- function(input, output, session){
  observe({
    if(input$u=="sqrt: (x^a)/a"){
      updateSliderInput(inputId = "alpha", value=0.5, min=0, max=1)
    }
    if(input$u=="log: a*log(1+x)"){
      updateSliderInput(inputId = "alpha", value=0.5, min=0, max=5)
    }
    
  })
  
  # order of parameters [c,s,c_1_up,c_2_down]
  results_optim <- eventReactive(input$optim,
                           {opt <- utility_optim(wage_0=input$wage_0,
                                                 wage_1_up=input$wage_1_up, 
                                                 wage_1_down=input$wage_1_down, 
                                                 wage_2=input$wage_2, 
                                                 delta=input$delta, 
                                                 beta=input$beta, 
                                                 rate=input$r, 
                                                 prob=input$p, 
                                                 base_func=input$u, 
                                                 alpha=input$alpha,
                                                 n_optim = input$iter_optim,
                                                 with_progress=T)
                           res_table <- make_res_table(opt)
                           constr_table <- make_constr_table(res_table,
                                                             wage_0=input$wage_0,
                                                             wage_1_up=input$wage_1_up, 
                                                             wage_1_down=input$wage_1_down, 
                                                             wage_2=input$wage_2, 
                                                             delta=input$delta, 
                                                             beta=input$beta, 
                                                             rate=input$r, 
                                                             prob=input$p, 
                                                             base_func=input$u, 
                                                             alpha=input$alpha)
                           output <- list(results=res_table, constraints=constr_table)
                           output
                           }
                          )
  
  # code for 2D plot
  results_plot_2D <- eventReactive(input$plot_2D, {
    # define range
    range_2D <- seq(input$from_2D, input$to_2D, (input$to_2D-input$from_2D)/20)
    # define matrices where we collect optimized parameters
    params_2D <- matrix(NA, nrow=length(range_2D), ncol=5)
    colnames(params_2D) <- c(input$select_plot_2D,
                               "cash savings period 0",
                                "investment period 0",
                                "cash spending period 1 (up)",
                                "cash spending period 1 (down)")
    # start loop
    withProgress(message = 'Optimization in progress...', style = 'notification', detail = "Starting Optimization", value = 0, {
      for(l in 1:length(range_2D)){
        opt <- utility_optim_loop(selected_vars=c(input$select_plot_2D),
                                  selected_vals=c(range_2D[l]),
                                  wage_0=input$wage_0,
                                  wage_1_up=input$wage_1_up,
                                  wage_1_down=input$wage_1_down,
                                  wage_2=input$wage_2,
                                  delta=input$delta,
                                  beta=input$beta,
                                  rate=input$r,
                                  prob=input$p,
                                  base_func=input$u,
                                  alpha=input$alpha,
                                  n_optim=input$iter_2D,
                                  with_progress=F)
        params_2D[l,] <- c(range_2D[l],opt)
        
        incProgress(1/length(range_2D), detail = paste("Optimization for ", input$select_plot_2D, "with value ", range_2D[l]))
      }
    })
    
    params_2D
  }
  )
  
  results_plot_3D <- eventReactive(input$plot_3D, {
    # define range
    range_3D_var1 <- seq(input$from_exog_1_3D, input$to_exog_1_3D, (input$to_exog_1_3D-input$from_exog_1_3D)/10)
    range_3D_var2 <- seq(input$from_exog_2_3D, input$to_exog_2_3D, (input$to_exog_2_3D-input$from_exog_2_3D)/10)
    # define matrices where we collect optimized parameters
    params_3D <- array(NA,
                       dim=c(length(range_3D_var1), length(range_3D_var2), 4))
    attr(params_3D, "x") <- range_3D_var1
    attr(params_3D, "y") <- range_3D_var2
    attr(params_3D, "z") <- c("c","s","c1_u","c1_d")

    # start loop
    withProgress(message = 'Optimization in progress...', style = 'notification', detail = "Starting Optimization", value = 0, {
      for(l in 1:length(range_3D_var1)){
        for(r in 1:length(range_3D_var2)){
          opt <- utility_optim_loop(selected_vars=c(input$exog_1_3D,input$exog_2_3D),
                                    selected_vals=c(range_3D_var1[l], range_3D_var2[r]),
                                    wage_0=input$wage_0,
                                    wage_1_up=input$wage_1_up,
                                    wage_1_down=input$wage_1_down,
                                    wage_2=input$wage_2,
                                    delta=input$delta,
                                    beta=input$beta,
                                    rate=input$r,
                                    prob=input$p,
                                    base_func=input$u,
                                    alpha=input$alpha,
                                    n_optim=input$iter_3D,
                                    with_progress=F)
          params_3D[l,r,] <- c(opt)
          incProgress(1/(length(range_3D_var1)*length(range_3D_var2)), 
                      detail = paste("Optimization for ", input$exog_1_3D, "/",input$exog_2_3D, "with values ", range_3D_var1[l],"/", range_3D_var2[r]))
        }
      }
      
    })
    
    params_3D
  }
  )
  
  output$plot_2D <- renderPlot({
    p2D(results=results_plot_2D, endog_var=input$select_plot_2D, chosen_vars=input$endogenic_vars_2D)
  })
  
  # output$plot_3D <- renderPlot({
  #   plot_3D(results=results_plot_3D, endog_var=input$endo_3D)
  # })
  
  output$graph <- renderPlotly({
    data <- results_plot_3D()
    idx <- match(input$endo_3D, attributes(data)$z)
    plot_ly() %>% add_surface(x = ~attributes(data)$x, y = ~attributes(data)$y, z = ~data[,,idx]) %>%
      layout(
        scene = list(
          xaxis = list(title = input$exog_1_3D),
          yaxis = list(title = input$exog_2_3D),
          zaxis = list(title = input$endo_3D)
        ),
        legend=list(title=list(text=input$endo_3D))
      )
    #plot_ly(z = ~volcano) %>% add_surface() #(x = ~dimnames(results_plot_3D())[1], y = ~dimnames(results_plot_3D())[2], z = ~results_plot_3D()[,,1])
    #plot_3D(results = results_plot_3D, endog_var = input$endo_3D)
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
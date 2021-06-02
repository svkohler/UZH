library(plotly)

utility_optim <- function(wage_0, 
                          wage_1_up, 
                          wage_1_down,
                          wage_2, 
                          delta,
                          beta,
                          rate,
                          prob,
                          base_func,
                          alpha,
                          n_optim=100,
                          with_progress=TRUE){
  ####
  # Function implements the utlity function as defined via mail by Prof. Thorsten Hens
  #
  # Hereby, params refers to the collection of endogenic variables (cash savings (c), investment (s),
  # cash consumption in szenario "up" (c1_u), cash consumption in szenario "down" (c1_d)).
  ####
  
  ### external variables
  
  # wages
  w0 <- wage_0
  w1_u <- wage_1_up
  w1_d <- wage_1_down
  w2 <- wage_2
  
  # discount factors
  d <- delta
  b <- beta
  
  # interest
  r <- rate
  
  # scenario probabilites
  p <- prob
  
  # utility function
  if(base_func=="log: a*log(1+x)"){
    u <- function(x){
      return(alpha*log(1+x))
    }
  }else if(base_func=="sqrt: (x^a)/a"){
    u <- function(x){
      return((x^alpha)/alpha)
    }
  }
  
  U <- function(params){
    U <- u(w0-params[1]-params[2])+
      d*b*(p*(u(w1_u+params[3])+b*u(w2+(params[1]-params[3])+r*params[2]))+
             (1-p)*(u(w1_d+params[4])+b*u(w2+(params[1]-params[4])+r*params[2])))
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
  ci <- c(0,0,0,0,0,0,-w0)
  
  # initiate loop to counter variance in optim results
  result <- c(0,0,0,0)
  if(with_progress==T){
    withProgress(message = 'Optimization in progress...', style = 'notification', detail = "Starting Optimization", value = 0, {
      for(i in 1:n_optim){
        # random initialization of starting point for optimization
        random_init <- runif(1, 0.6, 0.99)
        # call the constrained-optimization function
        opt <- constrOptim(theta = c(random_init*w0/2,random_init*w0/2,random_init*0.9*w0/2,random_init*0.9*w0/2), 
                           f=U, # function to optimize
                           grad=NULL, 
                           method="Nelder-Mead",
                           ui=ui, ci=ci, # constraints
                           control = list(fnscale = -1)) # search for a maximum
        result <- result + 1/n_optim*opt$par
        
        incProgress(1/n_optim, detail = paste("Optimization", i))
      }
    })
  }else{
    for(i in 1:n_optim){
      # call the constrained-optimization function
      # random initialization of starting point for optimization
      random_init <- runif(1, 0.6, 0.99)
      opt <- constrOptim(theta = c(random_init*w0/2,random_init*w0/2,random_init*0.9*w0/2,random_init*0.9*w0/2), 
                         f=U, # function to optimize
                         grad=NULL, 
                         method="Nelder-Mead",
                         ui=ui, ci=ci, # constraints
                         control = list(fnscale = -1)) # search for a maximum
      result <- result + 1/n_optim*opt$par
    }
  }
  return(result)
}

make_res_table <- function(results){
  table <- data.frame(matrix(results, nrow = 1, ncol = 4))
  colnames(table) <- c("cash savings period 0", 
                       "investment period 0", 
                       "cash spending period 1 (up)", 
                       "cash spending period 1 (down)")
  return(table)
}

make_constr_table <- function(res_table,
                              wage_0,
                              wage_1_up, 
                              wage_1_down, 
                              wage_2, 
                              delta, 
                              beta, 
                              rate, 
                              prob, 
                              base_func, 
                              alpha){
  constraints_table <- data.frame(matrix(nrow = 1, ncol=5))
  colnames(constraints_table) <- c("wages >= 0", 
                                   "interest >= 1", 
                                   "p*delta <= 1",
                                   "0 < beta <= 1",
                                   "w_0 >= (c+s)")
  # constrain 1
  if(wage_0 >=0 && wage_1_up >=0 && wage_1_down >=0 && wage_2 >=0){
    constraints_table[1,1] <- "ok"
  }else{
    constraints_table[1,1] <- "violated"
  }
  # constrain 2
  if(rate >=1){
    constraints_table[1,2] <- "ok"
  }else{
    constraints_table[1,2] <- "violated"
  }
  # constrain 3
  if(prob * delta <=1){
    constraints_table[1,3] <- "ok"
  }else{
    constraints_table[1,3] <- "violated"
  }
  # constrain 4
  if(beta >0 && beta <=1){
    constraints_table[1,4] <- "ok"
  }else{
    constraints_table[1,4] <- "violated"
  }
  # constrain 5
  if(wage_0 >=res_table[1]+res_table[2]){
    constraints_table[1,5] <- "ok"
  }else{
    constraints_table[1,5] <- "violated"
  }
  return(constraints_table)
}

set_var <- function(curr_var, i){
  if(curr_var == "wage_0"){
    print(i)
    updateSliderInput(inputId = "wage_0", value=i)
  }
  
  if(curr_var == "wage_1_up"){
    updateNumericInput(inputId = "wage_1_up", value=i)
  }
  
  if(curr_var == "wage_1_down"){
    updateNumericInput(inputId = "wage_1_down", value=i)
  }
  
  if(curr_var == "wage_2"){
    updateNumericInput(inputId = "wage_2", value=i)
  }
  
  if(curr_var == "beta"){
    updateNumericInput(inputId = "beta", value=i)
  }
  
  if(curr_var == "delta"){
    updateNumericInput(inputId = "delta", value=i)
  }
  
  if(curr_var == "p"){
    updateNumericInput(inputId = "p", value=i)
  }
  
  if(curr_var == "r"){
    updateNumericInput(inputId = "r", value=i)
  }
  
  if(curr_var == "alpha"){
    updateNumericInput(inputId = "alpha", value=i)
  }
}

p2D <- function(results, endog_var, chosen_vars){
  plot(0,type="n", xlab=endog_var, ylab="endogenic variables", 
       ylim=c(0.9*min(results()[,2:5]), 1.1*max(results()[,2:5])),
       xlim=c(min(results()[,1]), max(results()[,1])))
  bucket <- c()
  for(var in chosen_vars){
    idx <- match(var, c("c", "s", "c1_u", "c1_d"))
    lines(results()[,1], results()[,idx+1], col=idx, pch=idx, type="b")
    bucket <- append(bucket, idx)
  }
  legend("topleft", col=bucket, cex=0.8, legend = colnames(results())[bucket+1], pch = bucket )
}

utility_optim_loop <- function(selected_vars,
                               selected_vals,
                               wage_0, 
                               wage_1_up, 
                               wage_1_down,
                               wage_2, 
                               delta,
                               beta,
                               rate,
                               prob,
                               base_func,
                               alpha,
                               n_optim=100,
                               with_progress=FALSE){
  for(i in 1:length(selected_vars)){
    if(selected_vars[i] == "wage_0"){
      wage_0 <- selected_vals[i]
    }else{
      wage_0 <- wage_0
    }
    
    if(selected_vars[i] == "wage_1_up"){
      wage_1_up <- selected_vals[i]
    }else{
      wage_1_up <- wage_1_up
    }
    
    if(selected_vars[i] == "wage_1_down"){
      wage_1_down <- selected_vals[i]
    }else{
      wage_1_down <- wage_1_down
    }
    
    if(selected_vars[i] == "wage_2"){
      wage_2 <- selected_vals[i]
    }else{
      wage_2 <- wage_2
    }
    
    if(selected_vars[i] == "beta"){
      beta <- selected_vals[i]
    }else{
      beta <- beta
    }
    
    if(selected_vars[i] == "delta"){
      delta <- selected_vals[i]
    }else{
      delta <- delta
    }
    
    if(selected_vars[i] == "p"){
      p <- selected_vals[i]
    }else{
      p <- prob
    }
    
    if(selected_vars[i] == "r"){
      r <- selected_vals[i]
    }else{
      r <- rate
    }
    
    if(selected_vars[i] == "alpha"){
      alpha <- selected_vals[i]
    }else{
      alpha <- alpha
    }
  }
  
  opt <- utility_optim(wage_0=wage_0,
                  wage_1_up=wage_1_up,
                  wage_1_down=wage_1_down,
                  wage_2=wage_2,
                  delta=delta,
                  beta=beta,
                  rate=r,
                  prob=p,
                  base_func=base_func,
                  alpha=alpha,
                  n_optim=n_optim,
                  with_progress=with_progress)
  
  return(opt)
}

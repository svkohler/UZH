

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




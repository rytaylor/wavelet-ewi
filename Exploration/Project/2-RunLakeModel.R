# Lake Model - Mean Field
# Based on Serizawa et al (2008)


run_lakemodel_step <- function(param,sigma,dt){
  f.p = as.numeric(param[1])
  in1 = as.numeric(param[2])
  in2 = as.numeric(param[3])
  sequence = as.numeric(param[5:7])
  
  
  #install.packages("devtools")
  #install.packages("Rcpp")
  #devtools::install_github("japilo/colorednoise",force=TRUE)
  
  require(colorednoise)
  #library(ggplot2)
  
  ##### Simulation Parameters #####
  t.i = 0
  t.f = 129600
  t = seq(t.i,t.f,by=dt)
  timelength = length(t)
  
  
  step_index = timelength*(sequence[1] + sequence[2]/2)/(sum(sequence))
  
  
  
  ##### Model Parameters #####
  min.per.sample = 60# not 15
  min.per.day = 1440
  
  mu = 0.5 # max growth rate of phytoplankton
  k = 0.01  # nutrient concentration in phytoplankton
  
  m.N = 0.015 # removal rate of nutrients
  h.N = 0.005 # half saturation of nutrients
  h.P = 4.0 # half saturation of phytoplankton
  
  Initials = Find_Equilibrium(in1, f.p)
  
  N.i = Initials[1] # initial concentration of nutirents
  P.i = Initials[2]  # initial concentration of phytoplankton
  
  #Critical Parameters
  F.P = f.p*mu*h.P
  I.N1 =  in1*mu*h.N
  I.N2 = in2*mu*h.N
  
  
  stdev = min(c(abs((in1-in2)),min(c(in1,in2))/2))*sigma
  STDEV = mu*h.N*stdev 
  
  
  daily.PHI = 0.5
  dt.per.day = min.per.day/dt
  PHI = daily.PHI^(1/dt.per.day) 
  

  ##### Variables #####
  index = 1:timelength
  bool = index > step_index
  I.N.data.temp = I.N.data.temp = bool*(I.N2-I.N1) + I.N1
  I.N.data = I.N.data.temp + colored_noise(timesteps = length(I.N.data.temp), mean = 0, sd = STDEV, phi = PHI)
  
  N.data = na.omit(c(N.i, rep(0, timelength-1))) # Nutrient concentration over time
  P.data = na.omit(c(P.i, rep(0, timelength-1))) # Phytoplankton concentration over time
  time.data = na.omit(c(0, rep(0, timelength-1))) # Phytoplankton concentration over time
  i.data = na.omit(c(0, rep(0, timelength-1))) # Phytoplankton concentration over time
  
  ##### Functions #####
  
  dN <- function(n,p,i){
    dt*(i - k*mu*n*p/(h.N+n) - n*m.N)
  }
  
  dP <- function(n,p){
    dt*(mu*p*n/(h.N+n) - F.P*p/(h.P+p))
  }
  
  
  ##### Simulation #####
  index = 1
  N.curr = N.i
  P.curr = P.i
  N.data = NULL
  i.data = NULL
  P.data = NULL
  N.data[index] = N.curr
  P.data[index] = P.curr
  time.data[index] = 0
  i.data[index] = I.N1/(mu*h.N)
  
  
  plot.res.skip = min.per.sample*as.integer(1/dt)
  
  for(i in 2:timelength){
    N.prev = N.curr
    P.prev = P.curr
    P.curr <- P.prev + dP(N.prev,P.prev)
    dn <- dN(N.prev,P.prev,I.N.data[i-1])
    N.curr <- (N.prev + dn)*(N.prev+dn >= 0)
    if(((i-1)%%plot.res.skip)==0){
      index = index + 1
      N.data[index] = N.curr
      P.data[index] = P.curr
      time.data[index] = t[i]
      i.data[index] = I.N.data[i]/(mu*h.N)
    }
  }
  
  #P.ts <- data.frame(Time = time.data, Conc = P.data, Var = rep("Phytoplankton",length(time.data)), Run = run)
  #N.ts <- data.frame(Time = time.data, Conc = N.data, Var = rep("Nutrients",length(time.data)), Run = run)
  #i.ts <- data.frame(Time = time.data, Conc = i.data, Var = rep("Inflow",length(time.data)), Run = run)
  
  
  DATA.ts <- cbind(N.data,P.data,i.data)
}


Find_Equilibrium <- function(in1, f.p){
  ##### Simulation Parameters #####
  dt = 0.01
  iter.limit = 10000/dt
  
  ##### Model Parameters #####
  mu = 0.5 # max growth rate of phytoplankton
  k = 0.01  # nutrient concentration in phytoplankton
  
  m.N = 0.015 # removal rate of nutrients
  h.N = 0.005 # half saturation of nutrients
  h.P = 4.0 # half saturation of phytoplankton
  
  
  #Critical Parameters
  F.P = f.p*mu*h.P
  I.N1 =  in1*mu*h.N
  
  ##### Variables #####
  P.prev = 0.01
  N.prev = 0.01
  P.curr = 1  # initial concentration of phytoplankton
  N.curr = 1  # initial concentration of nutirents
  
  
  dN <- function(n,p,i){
    dt*(i - k*mu*n*p/(h.N+n) - n*m.N)
  }
  
  dP <- function(n,p){
    dt*(mu*p*n/(h.N+n) - F.P*p/(h.P+p))
  }
  ##### Simulation #####
  i = 0
  while((i < iter.limit)){
    N.prev = N.curr
    P.prev = P.curr
    P.curr = P.prev + dP(N.prev,P.prev)
    dn = dN(N.prev,P.prev,I.N1)
    N.curr = (N.prev + dn)*(N.prev+dn >= 0)
    i = i + 1
  }
  
  return = c(N.curr, P.curr)
}



run_lakemodel <- function(param,sigma,dt){
  f.p = as.numeric(param[1])
  in1 = as.numeric(param[2])
  in2 = as.numeric(param[3])
  sequence = as.numeric(param[5:7])
  
  
  #install.packages("devtools")
  #install.packages("Rcpp")
  #devtools::install_github("japilo/colorednoise",force=TRUE)
  
  require(colorednoise)
  #library(ggplot2)
  
  ##### Simulation Parameters #####
  t.i = 0
  t.f = 129600
  t = seq(t.i,t.f,by=dt)
  timelength = length(t)
  sequence = round(sequence*timelength)
    
  
  
  ##### Model Parameters #####
  min.per.sample = 60# not 15
  min.per.day = 1440
  
  mu = 0.5 # max growth rate of phytoplankton
  k = 0.01  # nutrient concentration in phytoplankton
  
  m.N = 0.015 # removal rate of nutrients
  h.N = 0.005 # half saturation of nutrients
  h.P = 4.0 # half saturation of phytoplankton
  
  Initials = Find_Equilibrium(in1, f.p)
  
  N.i = Initials[1] # initial concentration of nutirents
  P.i = Initials[2]  # initial concentration of phytoplankton
  
  #Critical Parameters
  F.P = f.p*mu*h.P
  I.N1 =  in1*mu*h.N
  I.N2 = in2*mu*h.N
  
  
  stdev = min(c(abs((in1-in2)),min(c(in1,in2))/2))*sigma
  STDEV = mu*h.N*stdev 
  
  
  daily.PHI = 0.5
  dt.per.day = min.per.day/dt
  PHI = daily.PHI^(1/dt.per.day) 
  
  
  ##### Variables #####
  ##### Variables #####
  #redshifted noise with autocorrelation of PHI
  I.N.data1 = rep(I.N1, sequence[1])
  I.N.data2 = seq(from = I.N1, to = I.N2, length.out = sequence[2]+1)
  I.N.data3 = rep(I.N2, sequence[3])
  
  temp = c(I.N.data1,I.N.data2,I.N.data3)
  I.N.data = temp + colored_noise(timesteps = length(temp), mean = 0, sd = STDEV, phi = PHI)
  
  N.data = na.omit(c(N.i, rep(0, timelength-1))) # Nutrient concentration over time
  P.data = na.omit(c(P.i, rep(0, timelength-1))) # Phytoplankton concentration over time
  time.data = na.omit(c(0, rep(0, timelength-1))) # Phytoplankton concentration over time
  i.data = na.omit(c(0, rep(0, timelength-1))) # Phytoplankton concentration over time
  
  
  ##### Functions #####
  
  dN <- function(n,p,i){
    dt*(i - k*mu*n*p/(h.N+n) - n*m.N)
  }
  
  dP <- function(n,p){
    dt*(mu*p*n/(h.N+n) - F.P*p/(h.P+p))
  }
  
  
  ##### Simulation #####
  index = 1
  N.curr = N.i
  P.curr = P.i
  N.data = NULL
  i.data = NULL
  P.data = NULL
  N.data[index] = N.curr
  P.data[index] = P.curr
  time.data[index] = 0
  i.data[index] = I.N1/(mu*h.N)
  
  
  plot.res.skip = min.per.sample*as.integer(1/dt)
  
  for(i in 2:timelength){
      N.prev = N.curr
    P.prev = P.curr
    P.curr <- P.prev + dP(N.prev,P.prev)
    dn <- dN(N.prev,P.prev,I.N.data[i-1])
    N.curr <- (N.prev + dn)*(N.prev+dn >= 0)
    if(((i-1)%%plot.res.skip)==0){
      index = index + 1
      N.data[index] = N.curr
      P.data[index] = P.curr
      time.data[index] = t[i]
      i.data[index] = I.N.data[i]/(mu*h.N)
    }
  }
  
  #P.ts <- data.frame(Time = time.data, Conc = P.data, Var = rep("Phytoplankton",length(time.data)), Run = run)
  #N.ts <- data.frame(Time = time.data, Conc = N.data, Var = rep("Nutrients",length(time.data)), Run = run)
  #i.ts <- data.frame(Time = time.data, Conc = i.data, Var = rep("Inflow",length(time.data)), Run = run)
  
  
  DATA.ts <- cbind(N.data,P.data,i.data)
}


Find_Equilibrium <- function(in1, f.p){
  ##### Simulation Parameters #####
  dt = 0.01
  iter.limit = 10000/dt
  
  ##### Model Parameters #####
  mu = 0.5 # max growth rate of phytoplankton
  k = 0.01  # nutrient concentration in phytoplankton
  
  m.N = 0.015 # removal rate of nutrients
  h.N = 0.005 # half saturation of nutrients
  h.P = 4.0 # half saturation of phytoplankton
  
  
  #Critical Parameters
  F.P = f.p*mu*h.P
  I.N1 =  in1*mu*h.N
  
  ##### Variables #####
  P.prev = 0.01
  N.prev = 0.01
  P.curr = 1  # initial concentration of phytoplankton
  N.curr = 1  # initial concentration of nutirents
  
  
  dN <- function(n,p,i){
    dt*(i - k*mu*n*p/(h.N+n) - n*m.N)
  }
  
  dP <- function(n,p){
    dt*(mu*p*n/(h.N+n) - F.P*p/(h.P+p))
  }
  ##### Simulation #####
  i = 0
  while((i < iter.limit)){
    N.prev = N.curr
    P.prev = P.curr
    P.curr = P.prev + dP(N.prev,P.prev)
    dn = dN(N.prev,P.prev,I.N1)
    N.curr = (N.prev + dn)*(N.prev+dn >= 0)
    i = i + 1
  }
  
  return = c(N.curr, P.curr)
}


#------------------------------------------------------------#
# 一人の参加者に対し，最尤推定・MAP推定を行うための関数の定義
#------------------------------------------------------------#

library(Rsolnp)

#　負の対数尤度のみを返すラッパー関数
func_minimize <- function(modelfunc, param, data, prior)
{
  ret <- modelfunc(param, data, prior)
  
  # return negative log-likelihood
  return(ret$negll)
}

# 最尤推定 
paramfitML <- function(modelfunctions, data, nParamList)
{
  
  nModel <- length(modelfunctions)
  aic <- numeric(nModel)
  bic <- numeric(nModel)
  negll <- numeric(nModel)
  paramlist <- list()
  
  for (idxm in 1:nModel) {
    fvalmin <- Inf
    print(sprintf("Model %d:", idxm))
    
    for (idx in 1:10) {
      
      # set initial value
      initparam <- runif(nParamList[idxm], 0, 1.0)
      
      res <- solnp(initparam, fun = func_minimize, 
                   modelfunc = modelfunctions[[idxm]], 
                   control = list(trace = 0),
                   data = data, prior = NULL)
      
      nll <- res$values[length(res$values)]
      
      if (nll < fvalmin) {
        paramest <- res$par
        res_ML_best <- res
        fvalmin <- nll
      }
    }
    T <- length(data$reward)
    aic[idxm] <- 2*fvalmin + 2 * nParamList[idxm]
    bic[idxm] <- 2*fvalmin + nParamList[idxm] * log(T)
    negll[idxm] <- fvalmin
    paramlist[[idxm]] <- paramest
    
    print(sprintf("Estimated value: %.2f", paramest))
    print(sprintf("log-likelihood: %.2f, AIC: %.2f, -BIC/2: %.2f", 
                  negll[idxm], 
                  aic[idxm],
                  -bic[idxm]/2))
  }
  return(list(negll = negll, aic = aic, bic = bic, paramlist = paramlist))
}


# MAP推定 
paramfitMAP <- function(modelfunctions, data,  nParamList, prior)
{
  
  nModel <- length(modelfunctions)
  lml <- numeric(nModel)
  negll <- numeric(nModel)
  paramlist <- list()
  hessian <- list()
  
  for (idxm in 1:nModel) {
    fvalmin <- Inf
    print(sprintf("Model %d:", idxm))
    
    for (idx in 1:10) {
      
      # set initial value
      initparam <- runif(nParamList[idxm], 0, 1.0)

      res <- solnp(initparam, fun = func_minimize, 
                   modelfunc = modelfunctions[[idxm]], 
                   control = list(trace = 0),
                   data = data, prior = prior[[idxm]])
      
      nll <- res$values[length(res$values)]
      
      if (nll < fvalmin) {
        paramest <- res$par
        lp <- -nll
        H <- res$hessian
        res_ML_best <- res
        fvalmin <- nll
      }
    }
    negll[idxm] <- fvalmin
    paramlist[[idxm]] <- paramest
    
    # ラプラス近似による対数周辺尤度の計算
    lml[idxm] <- lp + nParamList[idxm]/2 * log(2*pi) - 0.5 * log(det(H)) 
    
    hessian[[idxm]] <- H 
    
    print(sprintf("Estimated value: %.2f", paramest))
    print(sprintf("log marginal likelihood: %.2f", lml[idxm]))
    
  }
  return(list(negll = fvalmin, lml = lml, paramlist = paramlist))
}


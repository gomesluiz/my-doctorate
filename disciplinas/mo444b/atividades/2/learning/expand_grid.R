
grid <- expand.grid(cost=c(2**-5, 2**-2, 2**0, 2**2, 2**5), gamma=c(2**-15, 2**-10, 2**-5, 2**0, 2**5))
hmax <- c(grid$cost[2], grid$gamma[2])
hmax
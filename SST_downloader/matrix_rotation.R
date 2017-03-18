#equacao rotacao de matriz

mat_rot <- function(x) {
      
      t(apply(x, 2, rev))
      
}
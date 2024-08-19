# Key functions for clustering
# 2024-08-20
#

# References
#
# rpart documentation
# https://cran.r-project.org/web/packages/rpart/rpart.pdf
# https://cran.r-project.org/web/packages/rpart/vignettes/longintro.pdf
# rpart.plot documentation
# http://www.milbo.org/rpart-plot/prp.pdf
#


# Necessary Package
install.packages("rpart")
library(rpart)

# Create a data frame with the sample data
data(iris)

# Fit classification model
cart_model <- rpart(
  Sepal.Length ~ Sepal.Width + Petal.Width + Petal.Length,
  data = iris,
  method = "anova",
  control = rpart.control(minsplit = 10, cp = 0.001)
)

# Plot decision tree - base R
plot(cart_model, uniform = TRUE, main = "Regression Tree for Iris")
text(cart_model, use.n = TRUE, all = TRUE, cex = 0.8)

# Plot decision tree - rpart.plot
rpart.plot::prp(cart_model, faclen = 0, cex = 0.8, extra = 1)

# Make predictions
new_data <- data.frame(Sepal.Width = 10, Petal.Width = 15, Petal.Length = 17)
predicted_price <- predict(cart_model, new_data)
print(predicted_price)  # Output the predicted price

test_that("the package namespace loads", {
  expect_true(requireNamespace("trainingmodels", quietly = TRUE))
  expect_true("trainingmodels" %in% loadedNamespaces())
})

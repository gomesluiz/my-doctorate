if (!require('qdap')) install.packages('qdap')
if (!require('SnowballC')) install.packages('SnowballC')
if (!require('tm')) install.packages('tm')

library(qdap)
library(SnowballC)
library(tm)

# text cleaning function.
clean_text <- function(text){
  text <- replace_abbreviation(text)
  text <- replace_contraction(text)
  text <- replace_symbol(text)
  text <- tolower(text)
  return(text)
}

# corpus cleaning function.
clean_corpus <- function(corpus) {
  toSpace <- content_transformer(function(x, pattern) {return (gsub(pattern, " ", x))})
  corpus <- tm_map(corpus, toSpace, "/|@|\\|")
  corpus <- tm_map(corpus, toSpace, "[.]")
  corpus <- tm_map(corpus, toSpace, "<.*?>")
  corpus <- tm_map(corpus, toSpace, "-")
  corpus <- tm_map(corpus, toSpace, ":")
  corpus <- tm_map(corpus, toSpace, "’")
  corpus <- tm_map(corpus, toSpace, "‘")
  corpus <- tm_map(corpus, toSpace, " -")
  
  corpus <-  tm_map(corpus, content_transformer(tolower))
  corpus <-  tm_map(corpus, removePunctuation)
  corpus <-  tm_map(corpus, removeNumbers)
  corpus <-  tm_map(corpus, removeWords, c(stopwords("en")))
  corpus <-  tm_map(corpus, stripWhitespace)
  
  corpus <- tm_map(corpus, stemDocument)
  corpus <- tm_map(corpus, stripWhitespace)
  return(corpus)
}

# make document term matrix
make_dtm <- function(corpus, n = 100){
  names(corpus) <- c('doc_id', 'text')
  corpus$text   <- clean_text(corpus$text)
  
  corpus        <- DataframeSource(corpus)
  corpus        <- Corpus(corpus)
  corpus        <- clean_corpus(corpus)
  
  dtm           <- DocumentTermMatrix(corpus, control = list(weighting = weightTfIdf))
  
  freq <- colSums(as.matrix(dtm))
  freq <- order(freq, decreasing = TRUE)
  
  #dtm           <- removeSparseTerms(dtm, sparse=0.993)
  return(dtm[, freq[1:n]])
}

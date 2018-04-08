get_access_token <- function(api_key) {
  if(api_key == "") {
    stop("You need to provide an API key")
  }
}

store_access_token <- api_key) {
  Sys.setenv(YELP_ACCESS_TOKEN = access_token)
}

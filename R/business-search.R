#' Search for businesses
#'
#' Use the Yelp business search API to find businesses close to a give location.
#' @param term A string denoting the search term.
#' @param location A string describing the location. If this is not provided,
#' then \code{latitude} and \code{longitude} are compulsory.
#' @param latitude A number representing the latitude to search close to.
#' @param longitude A number representing the longitude to search close to.
#' @param radius_m A number giving the radius, in metres, of the search circle
#' around the specified location.
#' @param categories A character vector of search categories to filter on,
#' or \code{NULL} to return everything. See \code{\link{SUPPORTED_CATEGORY_ALIASES}}
#' for allowed values.
#' @param locale A string naming the locale. See \code{\link{SUPPORTED_LOCALES}}
#' for allowed values.
#' @param limit An integer giving the maximum number of businesses to return.
#' Maximum 50.
#' @param offset An integer giving the number of businesses to skip before
#' returning. Allows you to return more than 50 businesses (split between
#' multiple searches).
#' @param sort_by A string naming the metric to order results by.
#' @param price A vector of integers in 1 (cheap) to 4 (expensive) denoting
#' price brackets.
#' @param open_now A logical value of whether or not to only return businesses
#' that are currently open.
#' @param open_at A time when to check if businesses are open.
#' @param attributes A character vector of business attributes to filter on.
#' See \code{\link{SUPPORTED_BUSINESS_ATTRIBUTES}}.
#' @param access_token A string giving an access token to authenticate the API
#' call. See \code{\link{get_access_token}}.
#' @return A data frame of business results.
#' @references https://www.yelp.com/developers/documentation/v3/business_search
#' @examples
#' \donttest{
#' ## Marked as don't test because an access token is needed
#' delis_in_queens <- business_search("deli", "Queens, New York")
#' if(interactive()) View(delis_in_queens) else delis_in_queens
#' }
#' @importFrom assertive.numbers assert_all_are_in_closed_range
#' @importFrom assertive.sets assert_is_subset
#' @importFrom assertive.types assert_is_a_bool
#' @importFrom httr add_headers
#' @importFrom httr GET
#' @importFrom httr stop_for_status
#' @importFrom httr content
#' @importFrom purrr map_df
#' @importFrom purrr map_chr
#' @importFrom tibble data_frame
#' @export
business_search <- function(term, location, latitude = NULL, longitude = NULL, radius_m = 40000,
  categories = NULL, locale = "en_US", limit = 20, offset = 0,
  sort_by = c("best_match", "rating", "review_count", "distance"),
  price = 1:4, open_now = FALSE, open_at = NULL,
  attributes = NULL,
  access_token = Sys.getenv("YELP_ACCESS_TOKEN", NA)) {
  if(is.na(access_token)) {
    stop("No Yelp API access token was found. See ?get_access_token.")
  }
  if(!is.null(location)) {
    location <- paste0(location, collapse = "")
  } else {
    assert_all_are_in_closed_range(latitude, -90, 90)
    assert_all_are_in_closed_range(longitude, -180, 180)
  }
  radius_m <- as.integer(radius_m)
  categories <- if(!is.null(categories)) {
    categories <- match.arg(categories, SUPPORTED_CATEGORY_ALIASES, several.ok = TRUE)
    categories <- paste0(categories, collapse = ",")
  }
  locale <- match.arg(locale, SUPPORTED_LOCALES)
  assert_all_are_in_closed_range(limit, 0, 50)
  sort_by <- match.arg(sort_by)
  assert_is_subset(price, 1:4)
  price <- paste0(price, collapse = ",")
  if(!is.null(open_at)) {
    open_now <- NULL
    open_at <- as.integer(as.POSIXct(open_at))
  } else {
    assert_is_a_bool(open_now)
  }
  if(!is.null(attributes)) {
    attributes <- match.arg(attributes, SUPPORTED_BUSINESS_ATTRIBUTES, several.ok = TRUE)
    attributes <- paste0(attributes, collapse = ",")
  }
  response <- GET(
    "https://api.yelp.com/v3/businesses/search",
    config = add_headers(Authorization = paste("bearer", access_token)),
    query = list(
      term = term, location = location,
      latitude = latitude, longitude = longitude,
      radius = radius_m, categories = categories,
      locale = locale, limit = limit,
      offset = offset, sort_by = sort_by,
      price = price, open_now = open_now,
      open_at = open_at, attributes = attributes
    )
  )
  stop_for_status(response)
  results <- content(response, as = "parsed")
  map_df(
    results$businesses,
    function(business) {
      data_frame(
        id = business$id,
        name = business$name,
        rating = business$rating,
        review_count = business$review_count,
        price = business$price,
        image_url = business$image_url,
        is_closed = business$is_closed,
        url = business$url,
        category_aliases = list(map_chr(business$categories, function(x) x$alias)),
        category_titles = list(map_chr(business$categories, function(x) x$title)),
        latitude = business$coordinates$latitude,
        longitude = business$coordinates$longitude,
        distance_m = business$distance,
        transactions = list(as.character(business$transactions)),
        address1 = business$location$address1,
        address2 = n2e(business$location$address2),
        address3 = n2e(business$location$address3),
        city = n2e(business$location$city),
        zip_code = n2e(business$location$zip_code),
        state = n2e(business$location$state),
        country = n2e(business$location$country),
        display_address = list(as.character(business$location$display_address)),
        phone = business$phone,
        display_phone = business$display_phone
      )
    }
  )
}

#' Get Schedule and Results for NCAA Baseball Teams
#'
#' @param teamid The team's unique NCAA id.
#' @param year The season (i.e. use 2016 for the 2015-2016 season,
#' etc.)
#'
#' @importFrom rvest html_nodes html_text
#' @importFrom xml2 read_html
#' @importFrom tibble tibble
#' @importFrom tidyr separate
#' @return A dataframe with the following fields: date, opponent,
#' result, score, innings (if more than regulation), and the url
#' for the game itself.
#' @export
#'
#' @examples \dontrun{get_ncaa_schedule_info(736, 2019)}

get_ncaa_schedule_info <- function(teamid = NULL,
                                   year = NULL) {

  id <- subset(ncaa_season_id_lu, season == year, select = id)

  school_info <- subset(master_ncaa_team_lu, school_id ==
                          teamid & year == year) %>%
    dplyr::select(-year) %>%
    dplyr::distinct()

  url <- paste0("https://stats.ncaa.org/team/", teamid, "/", id)

  payload <- xml2::read_html(url)

  dates <- payload %>%
    rvest::html_nodes("fieldset td:nth-child(1)") %>%
    rvest::html_text() %>%
    as.data.frame() %>%
    dplyr::rename(date = '.') %>%
    dplyr::filter(!date == "") %>%
    dplyr::mutate(date = gsub("\\s*\\([^\\)]+\\)", "", date))

  game_opponents <- payload %>%
    rvest::html_nodes("fieldset td:nth-child(2)") %>%
    rvest::html_text() %>%
    as.data.frame() %>%
    dplyr::rename(opponent = '.') %>%
    dplyr::filter(!opponent == "") %>%
    dplyr::mutate(opponent = str_trim(opponent))

  game_info_url <- payload %>%
    rvest::html_nodes("fieldset .skipMask") %>%
    rvest::html_attr("href") %>%
    as.data.frame() %>%
    dplyr::rename(slug = '.') %>%
    dplyr::mutate(game_info_url = paste0("https://stats.ncaa.org", slug))

  game_result <- payload %>%
    rvest::html_nodes("fieldset .skipMask") %>%
    rvest::html_text() %>%
    as.data.frame() %>%
    dplyr::rename(result = '.') %>%
    dplyr::mutate(result = str_trim(result)) %>%
    tidyr::separate(result, into = c("result", "score", "innings"),
                    sep = " ") %>%
    dplyr::mutate(innings = str_extract(innings, "[[0-9]]+"))

  game_info <- tibble::tibble(date = dates$date,
                              opponent = game_opponents$opponent,
                              result = game_result$result,
                              score = game_result$score,
                              innings = game_result$innings,
                              game_info_url = game_info_url$game_info_url)

  game_info
}

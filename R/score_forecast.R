
#' Score a Model Fit
#'
#' @param observations A dataframe of observations against which to score. Should contain a `date` and `rt` column.
#'
#' @return A dataframe containing the following scores per forecast timepoint: dss, crps,
#' logs, bias, and sharpness as well as the forecast date and time horizon.
#' @export
#'
#' @importFrom dplyr filter select
#' @importFrom tidyr spread
#' @importFrom tibble tibble
#' @importFrom scoringRules dss_sample crps_sample logs_sample
#' @importFrom scoringutils bias sharpness
#' @inheritParams summarise_forecast
#' @examples
#'
#' ## Fit a model (using a subset of observations)
#' samples <- forecast_rt(EpiSoon::example_obs_rts[1:10, ],
#'                      model = function(...) {EpiSoon::bsts_model(model =
#'                     function(ss, y){bsts::AddSemilocalLinearTrend(ss, y = y)}, ...)},
#'                      horizon = 7, samples = 10)
#'
#' ## Score the model fit (with observations during the time horizon of the forecast)
#' score_forecast(samples, EpiSoon::example_obs_rts)
score_forecast <- function(fit_samples, observations) {

  observations <- observations %>%
    dplyr::filter(
      date >= min(fit_samples$date),
      date <= max(fit_samples$date)
    )

  fit_samples <- fit_samples %>%
    dplyr::filter(
      date >= min(observations$date),
      date <= max(observations$date)
    )


  obs <- observations$rt

  samples_matrix <- fit_samples %>%
    tidyr::spread(key = "sample", value = "rt") %>%
    dplyr::select(-horizon, -date) %>%
    as.matrix

  scores <- tibble::tibble(
    date = observations$date,
    horizon = 1:length(observations$date),
    dss = scoringRules::dss_sample(y = obs, dat = samples_matrix),
    crps = scoringRules::crps_sample(y = obs, dat = samples_matrix),
    logs = scoringRules::logs_sample(y = obs, dat = samples_matrix),
    bias = suppressWarnings(
      scoringutils::bias(obs, samples_matrix)
      ),
    sharpness = scoringutils::sharpness(samples_matrix)
  )


  return(scores)
}

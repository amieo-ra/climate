
# Script Purpose ----------------------------------------------------------

# This script attempts to recreate:
#   Fig 3A.5.1 Delineation of major climate zones, updated from the 2006 IPCC Guidelines.
# Located in:
#   Chapter 3: Consistent Representation of Lands
#   Volume 4: Agriculture, Forestry and Other Land Uses
#   2019 Refinement to the 2006 IPCC Guidelines for National Greenhouse Gas Inventories
# Accessible at:
#   https://www.ipcc-nggip.iges.or.jp/public/2019rf/pdf/4_Volume4/19R_V4_Ch03_Land%20Representation.pdf
# Noting that there is a correction to the figure:
#   https://www.ipcc-nggip.iges.or.jp/public/2019rf/corrigenda1.html

# Script created: 2022-11-07
# Author: Matt Lewis

# Packages ----------------------------------------------------------------

packs <-
  c(
    'magrittr',
    'terra',
    'elevatr',
    'lubridate'
  )

invisible(
  lapply(
    packs,
    library,
    character.only = T
  )
)

# Data --------------------------------------------------------------------

## Climate
clim_ver <- 'ts_3.25'
clim_dir <- paste0('100_data/110_rawdata/ClimateResearchUnit/', clim_ver,'/')

# Temp
temp <-
  paste0(clim_dir, 'temp_mean/') %>%
  list.files(full.names = T, recursive = T, pattern = ".nc") %>%
  lapply(terra::rast) %>%
  terra::rast()

# Precipitation
pre <-
  paste0(clim_dir, 'precipitation/') %>%
  list.files(full.names = T, recursive = T, pattern = ".nc") %>%
  lapply(terra::rast) %>%
  terra::rast()
  
# PET
pet <-
  paste0(clim_dir, 'PET/') %>%
  list.files(full.names = T, recursive = T, pattern = ".nc") %>%
  lapply(terra::rast) %>%
  terra::rast()

# Frost
frost <-
  paste0(clim_dir, 'frost/') %>%
  list.files(full.names = T, recursive = T, pattern = ".nc") %>%
  lapply(terra::rast) %>%
  terra::rast()

# elevation - commented out lines obtain data.
# at a zoom level of 2, elevatr uses ETOPO1 data, see
# https://github.com/tilezen/joerd/blob/master/docs/data-sources.md 
# and https://www.ngdc.noaa.gov/mgg/global/global.html
elev <- 
  # elevatr::get_elev_raster(locations = raster::raster(frost[[1]]), z = 2) %>%
  # terra::rast() %>%
  # terra::resample(frost[[1]])
  '100_data/110_rawdata/elevatr/elevation_halfdeg.tif' %>%
  terra::rast()

# Aggregate time ----------------------------------------------------------

time_window <- 
  seq(as.Date('1985-01-01'), as.Date('2016-01-01'), 'years')

# aggregate temperature for all months to get mean annual temperature
agg_mean <-
  function(x){
    time_s <- terra::time(x)
    lyrs <- which(time_s >= time_window[1] &
                  time_s < tail(time_window, 1))
    ret <-
      x %>%
      terra::subset(lyrs) %>%
      mean()
    
    return(ret)
  }
temp_agg <- temp %>% agg_mean()

# aggregate temperature for each month across all years
agg_mean_monthly <-
  function(x){
    time_s <- terra::time(x)
    lyrs <- which(time_s >= time_window[1] &
                    time_s < tail(time_window, 1))
    lyrs_seq <- outer(X=c(1:12), Y=seq(0, length(lyrs), 12), FUN="+")
    ret <- list()
    for(i in 1:nrow(lyrs_seq)){
      ret[[i]] <-
        x %>%
        terra::subset(lyrs_seq[i,]) %>%
        mean()
      
      terra::set.names(ret[[i]], as.character(month.name[i]))
    }
    ret<-
      ret %>%
      terra::rast()
    return(ret)
  }
temp_agg_monthly <- temp %>% agg_mean_monthly()

# aggregate by summing for one year then taking the mean across multiple
agg_ann_sum <-
  function(x, unit_denom = NA){
    time_s <- terra::time(x)
    # sum
    ret<- list()
    for(i in 1:(length(time_window)-1)){
      lyrs <- which(time_s >= time_window[i] &
                      time_s <= time_window[i+1])
      if(length(lyrs) == 0L){next()}
      tmp <-
        x %>%
        terra::subset(lyrs)
      
      # unit_denom here allows PET which is in mm/day to be converted to mm/month 
      # to match precipitation data
      if(!is.na(unit_denom)){
        # get number of days in months to multiply mm/day by for each month for PET
        # first make each date the start of each month
        yr <- lubridate::year(time_s[lyrs][1])
        
        lyrs_mths <- 
          paste(c(rep(yr, 12), yr+1), c(1:12, 1), 1, sep = '-') %>%
          as.Date()
        
        # then get the number of days in each interval
        lyrs_multi <-
          (lyrs_mths[2:length(lyrs_mths)] - 
          lyrs_mths[1:length(lyrs_mths)-1]) %>%
          as.numeric()
        
        # make sure we are multiplying by a vector of correct length
        stopifnot(length(lyrs_multi) == terra::nlyr(tmp))
        
        # and multiply!
        tmp <-
          tmp * lyrs_multi
      }
      
      ret[[i]] <-
        tmp %>%
        sum()
    }
    
    # mean
    ret <-
      ret %>%
      terra::rast() %>%
      mean()
    
    return(ret)
  }

# NOTE: The decision tree published by the IPCC only makes sense if mean annual
# precipitation (MAP) is in units of mm/month
pet_agg <- pet %>% agg_ann_sum(unit_denom = 'day')
pre_agg <- pre %>% agg_ann_sum(unit_denom = NA)

frost_agg <- frost %>% agg_ann_sum(unit_denom = NA)

# precipitation:PET
pre_pet <- pre_agg / pet_agg

# Decision tree -----------------------------------------------------------

# taken from https://www.ipcc-nggip.iges.or.jp/public/2019rf/corrigenda1.html

ipcc_clim_zones <- list()

tropical <-
  # mean temp > 18
  temp_agg %>%
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(18, Inf, 1)), 
                  others = NA, include.lowest = F, right = T) %>%
  terra::mask(
    # <= 7 frost days
    frost_agg %>%
      terra::classify(matrix(nrow = 1, ncol = 3, data = c(0, 7, 1)),
                      others = NA, include.lowest = T, right = T)
  )

ipcc_clim_zones$tropical_montane <-
  tropical %>%
  terra::mask(
    # elevation > 1000m
    elev %>%
      terra::classify(matrix(nrow = 1, ncol = 3, data = c(1000, Inf, 1)), 
                      others = NA, include.lowest = F, right = T)
  )

ipcc_clim_zones$tropical_wet <-
  # tropical - tropical montane
  tropical %>%
  terra::mask(ipcc_clim_zones$tropical_montane, inverse = T) %>%
  terra::mask(
    # precipitation > 2000mm/month
    pre_agg %>%
      terra::classify(matrix(nrow = 1, ncol = 3, data = c(2000, Inf, 1)), 
                      others = NA, include.lowest = F, right = T)
  ) %>%
  # give value of 2 (for flattening list to rast later)
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(-Inf, Inf, 2)),
                  others = NA, include.lowest = F, right = F)

ipcc_clim_zones$tropical_moist <-
  # tropical - tropical montane and tropical wet
  tropical %>%
  terra::mask(ipcc_clim_zones$tropical_montane, inverse = T) %>%
  terra::mask(ipcc_clim_zones$tropical_wet, inverse = T) %>%
  terra::mask(
    # precipitation > 1000mm/month
    pre_agg %>%
      terra::classify(matrix(nrow = 1, ncol = 3, data = c(1000, Inf, 1)), 
                      others = NA, include.lowest = F, right = T)
  ) %>%
  # give value of 3 (for flattening list to rast later)
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(-Inf, Inf, 3)),
                  others = NA, include.lowest = F, right = F)

ipcc_clim_zones$tropical_dry <-
  # tropical - tropical montane, tropical wet, and tropical moist
  tropical %>%
  terra::mask(ipcc_clim_zones$tropical_montane, inverse = T) %>%
  terra::mask(ipcc_clim_zones$tropical_wet, inverse = T) %>%
  terra::mask(ipcc_clim_zones$tropical_moist, inverse = T) %>%
  # give value of 4 (for flatting list to rast later)
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(-Inf, Inf, 4)),
                  others = NA, include.lowest = F, right = F)

## Warm temperate

warm_temperate <-
  # mean temp > 10
  temp_agg %>%
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(10, Inf, 1)), 
                  others = NA, include.lowest = F, right = T) %>%
  # get rid of tropical
  terra::mask(
    tropical,
    inverse = T
  )

ipcc_clim_zones$warm_temperate_moist <-
  warm_temperate %>%
  terra::mask(
    # pre:pet >1
    pre_pet %>%
      terra::classify(matrix(nrow = 1, ncol =3, data = c(1, Inf, 1)),
                      others = NA, include.lowest = F, right = T)
  ) %>%
  # give value of 5 (for flatting list to rast later)
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(-Inf, Inf, 5)),
                  others = NA, include.lowest = F, right = F)

ipcc_clim_zones$warm_temperate_dry <-
  # warm temperate - warm temp moist
  warm_temperate %>%
  terra::mask(ipcc_clim_zones$warm_temperate_moist, inverse = T) %>%
  # give value of 6 (for flatting list to rast later)
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(-Inf, Inf, 6)), 
                  others = NA, include.lowest = F, right = F)

## Cool temperate
cool_temperate <-
  # temp > 0
  temp_agg %>%
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(0, Inf, 1)), 
                  others = NA, include.lowest = F, right = T) %>%
  # remove tropical and warm temperate
  terra::mask(tropical, inverse = T) %>%
  terra::mask(warm_temperate, inverse = T)

ipcc_clim_zones$cool_temperate_moist <-
  cool_temperate %>%
  terra::mask(
    # pre:pet >1
    pre_pet %>%
      terra::classify(matrix(nrow = 1, ncol =3, data = c(1, Inf, 1)),
                      others = NA, include.lowest = F, right = T)
  ) %>%
  # give value of 7 (for flatting list to rast later)
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(-Inf, Inf, 7)), 
                  others = NA, include.lowest = F, right = F)

ipcc_clim_zones$cool_temperate_dry <-
  # cool temperate - cool temperate moist
  cool_temperate %>%
  terra::mask(ipcc_clim_zones$cool_temperate_moist, inverse = T) %>%
  # give value of 8 (for flatting list to rast later)
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(-Inf, Inf, 8)), 
                  others = NA, include.lowest = F, right = F)

## Boreal
boreal_polar <-
  # mean temp > 0
  temp_agg %>%
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(-Inf, 0, 1)), 
                  others = NA, include.lowest = F, right = T)

boreal <-
  boreal_polar %>%
  # at least 1 month's mean temperature >= 10
  terra::mask(
    temp_agg_monthly %>%
      terra::classify(matrix(nrow = 1, ncol = 3, data = c(10, Inf, 1)), 
                      others = NA, include.lowest = T, right = T) %>%
      mean(na.rm = T)
  )

ipcc_clim_zones$boreal_moist <-
  boreal %>%
  terra::mask(
    # pre:pet >1
    pre_pet %>%
      terra::classify(matrix(nrow = 1, ncol =3, data = c(1, Inf, 1)),
                      others = NA, include.lowest = F, right = T)
  ) %>%
  # give value of 9 (for flatting list to rast later)
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(-Inf, Inf, 9)), 
                  others = NA, include.lowest = F, right = F)

ipcc_clim_zones$boreal_dry <-
  # boreal - boreal moist
  boreal %>%
  terra::mask(ipcc_clim_zones$boreal_moist, inverse = T) %>%
  # give value of 10 (for flatting list to rast later)
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(-Inf, Inf, 10)), 
                  others = NA, include.lowest = F, right = F)

## Polar
polar <-
  # boreal/polar - boreal
  boreal_polar %>%
  terra::mask(boreal, inverse = T)

ipcc_clim_zones$polar_moist <-
  polar %>%
  terra::mask(
    # pre:pet >1
    pre_pet %>%
      terra::classify(matrix(nrow = 1, ncol =3, data = c(1, Inf, 1)),
                      others = NA, include.lowest = F, right = T)
  ) %>%
  # give value of 11 (for flatting list to rast later)
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(-Inf, Inf, 11)), 
                  others = NA, include.lowest = F, right = F)

ipcc_clim_zones$polar_dry <-
  # polar - polar moist
  polar %>%
  terra::mask(ipcc_clim_zones$polar_moist, inverse = T) %>%
  # give value of 12 (for flatting list to rast later)
  terra::classify(matrix(nrow = 1, ncol = 3, data = c(-Inf, Inf, 12)), 
                  others = NA, include.lowest = F, right = F)

# Flattening list to rast -------------------------------------------------

ipcc_clim_zones_rast <-
  ipcc_clim_zones %>%
  # flatten
  terra::rast() %>%
  # each cell should have one value so this could be sum, or any number of functions
  mean(na.rm = T) %>%
  # make categorical
  as.factor()

# add levels
levels(ipcc_clim_zones_rast) <-
  data.frame(
    ids = c(1:12),
    label = c(
      'Tropical Montane', 'Tropical Wet', 'Tropical Moist', 'Tropical Dry',
      'Warm Temperate Moist', 'Warm Temperate Dry',
      'Cool Temperate Moist', 'Cool Temperate Dry',
      'Boreal Moist', 'Boreal Dry',
      'Polar Moist', 'Polar Dry'
    )
  )

# Export ------------------------------------------------------------------

outdir <- '300_outputs/IPCC_Climate_Zones/'

dir.create(outdir, showWarnings = F, recursive = T)

terra::writeRaster(ipcc_clim_zones_rast, 
                   filename = paste0(outdir, 'IPCC_Climate_Zones_', clim_ver, '.tif'),
                   overwrite = T)

png(paste0(outdir, 'IPCC_Climate_Zones_', clim_ver, '.png'), res = 300, 
    height = 3000, width = 6000)
plot(ipcc_clim_zones_rast,
     col = c('#6699cd', '#448970', '#89cd66', '#f5f57a',
             '#73dfff', '#ffd37f', '#cdf57a', '#c29ed7',
             '#9eaad7', '#d7d79e', '#d9ffe8', '#e1e1e1'),
     legend = 'bottom')
dev.off()

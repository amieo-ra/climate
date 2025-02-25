from clim_zone_lookup import determine_zone
from calculate_fpp_fppet import calculate_fp_pet, calculate_fpp

import datetime

class WetDryDecisionTree:
    def __init__(self, lon, lat, start_date, end_date, well_drained, soil_type):
        self.lon = lon
        self.lat = lat
        self.zone = determine_zone(self.lon, self.lat)
        self.start_date = start_date
        self.end_date = end_date
        self.well_drained = well_drained
        self.soil_type = soil_type

    def decision(self):
        if self.zone == "Non-Temperate":
            return "Use wet or dry factors depending on annual climate zone set in farm settings"
        elif self.zone == 'Temperate':
            self.fp_pet = calculate_fp_pet(self.start_date, self.end_date)
            self.fpp = calculate_fpp(self.start_date, self.end_date)
            if self.fpp/self.fp_pet > 1:
                if self.well_drained == "yes":
                    if self.soil_type == "sandy":
                        return "dry"
                    elif self.soil_type == "clay":
                        return "wet"
                elif self.well_drained == "no":
                    return "wet"
            else:
                return "dry"
# Example usage
wet_dry = WetDryDecisionTree(lon=-1.0815, lat=53.9590, start_date=datetime.datetime(2025,1,1) , end_date=datetime.datetime(2025,2,1), well_drained="yes", soil_type="clay")
print((wet_dry).decision())  

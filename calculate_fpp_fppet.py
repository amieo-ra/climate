import math
from datetime import date, timedelta
import numpy as np

def source_climate_data():

    # Example inputs
    t_max = 30  # Max temperature (°C)
    t_min = 20  # Min temperature (°C)
    rh_max = 80  # Max relative humidity (%)
    rh_min = 50  # Min relative humidity (%)
    rs = 20  # Solar radiation (MJ/m²/day)
    u2 = 2  # Wind speed at 2m (m/s)
    altitude = 100  # Altitude (m)

    return t_max, t_min, rh_max, rh_min, rs, u2, altitude


def calculate_fp_pet(start_date, end_date):

    # Constants
    lambda_val = 2.45  # Latent heat of vaporization (MJ/kg)
    cp = 1.013 * 10**-3  # Specific heat of air (MJ/kg°C)
    epsilon = 0.622  # Ratio molecular weight of water vapor/dry air
    sigma = 4.903 * 10**-9  # Stefan-Boltzmann constant (MJ K⁻⁴ m⁻² day⁻¹) - this is used for more detailed estimation of net radiation

    fp_pet = 0

    for single_date in daterange(start_date, end_date):

        t_max, t_min, rh_max, rh_min, rs, u2, altitude = source_climate_data()

        # Net radiation (Rn) approximation
        rn = 0.77 * rs  # Assuming 23% albedo
        g = 0  # Soil heat flux (G) assumed to be zero for daily calculations
        
        # Mean air temperature
        t_mean = (t_max + t_min) / 2
        
        # Atmospheric pressure (P)
        p = 101.3 * ((293 - (0.0065 * altitude)) / 293) ** 5.26
        
        # Psychrometric constant (γ)
        gamma = (0.665 * 10**-3) * p
        
        # Saturation vapor pressure (es)
        es_max = 0.6108 * math.exp((17.27 * t_max) / (t_max + 237.3))
        es_min = 0.6108 * math.exp((17.27 * t_min) / (t_min + 237.3))
        es = (es_max + es_min) / 2
        
        # Actual vapor pressure (ea)
        ea = ((rh_max / 100) * es_min + (rh_min / 100) * es_max) / 2
        
        # Slope of saturation vapor pressure curve (Δ)
        delta = (4098 * es) / ((t_mean + 237.3) ** 2)
        
        # Penman-Monteith equation
        et0 = ((0.408 * delta * (rn - g)) + (gamma * (900 / (t_mean + 273)) * u2 * (es - ea))) / (delta + gamma * (1 + 0.34 * u2))

        fp_pet += et0
        
    return round(fp_pet, 2)  # Rounded to 2 decimal places


def calculate_fpp(start_date, end_date):
    fpp = 0

    for single_date in daterange(start_date, end_date):
        p = np.random.normal(10,2,1)
        fpp += p
    
    return fpp


def daterange(start_date, end_date):
    days = int((end_date - start_date).days)
    for n in range(days):
        yield start_date + timedelta(n)   
    



# Calculate ET0
#et0_value = calculate_et0(t_max, t_min, rh_max, rh_min, rs, u2, altitude)
#print(f"Reference Evapotranspiration (ET₀): {et0_value} mm/day")


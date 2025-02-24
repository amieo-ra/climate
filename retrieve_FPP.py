import cdsapi

c = cdsapi.Client()

c.retrieve(
    'reanalysis-era5-land',
    {
        'variable': 'total_precipitation',
        'year': '2023',  # Change this to your required year
        'month': ['03', '04'],  # Example: March & April (Fertiliser period)
        'day': [str(i).zfill(2) for i in range(1, 31)],  # Full month
        'time': ['00:00', '06:00', '12:00', '18:00'],  # Four time steps per day
        'format': 'netcdf',
    },
    'era5_fertiliser_precip.nc'  # Output file
)

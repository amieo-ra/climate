import cdsapi

#c = cdsapi.Client()

#c.retrieve(
#    'reanalysis-era5-land',
#    {
#        'variable': 'total_precipitation',
#        'year': '2023',  # Change this to your required year
#        'month': ['03', '04'],  # Example: March & April (Fertiliser period)
#        'day': [str(i).zfill(2) for i in range(1, 31)],  # Full month
#        'time': ['00:00', '06:00', '12:00', '18:00'],  # Four time steps per day
#        'format': 'netcdf',
#    },
#    'era5_fertiliser_precip.nc'  # Output file
#)

client = cdsapi.Client()

dataset = 'reanalysis-era5-land'
request = {
  #'product_type': ['reanalysis'],
  'variable': ['geopotential'],
  'year': ['2024'],
  'month': ['03'],
  'day': ['01'],
  'time': ['13:00'],
  #'pressure_level': ['1000'],
  'data_format': 'netcdf',
}
target = 'era5_fertiliser_precip.nc'

client.retrieve(dataset, request, target)

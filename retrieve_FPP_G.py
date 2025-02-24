import ee
import geemap

# Initialize Google Earth Engine
ee.Authenticate()
ee.Initialize(project="climate-project-451916")

# Define the date range for the fertiliser period
start_date = '2023-03-01'
end_date = '2023-04-30'

# Load ERA5-Land dataset and filter by date
era5 = ee.ImageCollection("ECMWF/ERA5_LAND/HOURLY") \
          .select("total_precipitation") \
          .filterDate(start_date, end_date)

# Compute mean precipitation over the period
mean_precip = era5.mean()

# Define visualization parameters
viz_params = {
    'min': 0,
    'max': 50,  # Adjust max value as needed
    'palette': ['blue', 'white', 'red']
}

# Display on an interactive map
Map = geemap.Map()
Map.addLayer(mean_precip, viz_params, "Mean Precipitation (mm)")
Map.centerObject(mean_precip, 3)  # Zoom to a global scale
Map.show()
task = ee.batch.Export.image.toDrive(
    image=mean_precip,
    description="ERA5_Fertiliser_Period_Precip",
    folder="GEE_exports",  # Change to your preferred Google Drive folder
    fileNamePrefix="era5_fertiliser_precip",
    region=ee.Geometry.Rectangle([-180, -90, 180, 90]),  # Global extent
    scale=10000,  # 10 km resolution
    crs="EPSG:4326"
)

# Start the export task
task.start()
print("Export started! Check your Google Drive for the file.")

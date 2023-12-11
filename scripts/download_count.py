import requests

# URLs for reqwest and hyper crates on crates.io
reqwest_url = "https://crates.io/api/v1/crates/reqwest"
hyper_url = "https://crates.io/api/v1/crates/hyper"

# Function to get download count from crates.io API
def get_download_count(url):
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        return data["crate"]["downloads"]
    else:
        print(response.status_code)
        return "Error fetching data"

# Get download counts
reqwest_downloads = get_download_count(reqwest_url)
hyper_downloads = get_download_count(hyper_url)

print(reqwest_downloads, hyper_downloads)


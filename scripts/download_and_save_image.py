import requests
import time
import uuid
import os

def download_and_save_image(folder_path):
    image_url = "https://picsum.photos/200/300"
    try:
        response = requests.get(image_url)
        if response.status_code == 200:
            filename = os.path.join(folder_path, f"{uuid.uuid4()}.jpg")
            with open(filename, 'wb') as file:
                file.write(response.content)
            return 1
    except Exception as e:
        print(f"Error downloading or saving image: {e}")
    return 0

def download_for_a_minute(folder_path):
    start_time = time.time()
    image_count = 0
    while time.time() - start_time < 60:
        image_count += download_and_save_image(folder_path)
    return image_count

def main():
    folder_path = "downloaded_images"
    os.makedirs(folder_path, exist_ok=True)

    image_count = download_for_a_minute(folder_path)
    print(f"Completed downloading images for 1 minute. Total images downloaded: {image_count}")

if __name__ == "__main__":
    main()

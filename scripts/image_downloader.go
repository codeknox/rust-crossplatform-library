package main

import (
    "fmt"
    "io"
    "net/http"
    "os"
    "path/filepath"
    "time"
    "math/rand"
)

func downloadImage(imageURL, folderPath string) error {
    resp, err := http.Get(imageURL)
    if err != nil {
        return err
    }
    defer resp.Body.Close()

    fileName := fmt.Sprintf("%d.jpg", rand.Int())
    filePath := filepath.Join(folderPath, fileName)

    file, err := os.Create(filePath)
    if err != nil {
        return err
    }
    defer file.Close()

    _, err = io.Copy(file, resp.Body)
    return err
}

func main() {
    folderPath := "./downloaded_images"
    _ = os.Mkdir(folderPath, os.ModePerm)

    imageURL := "https://picsum.photos/200/300"
    startTime := time.Now()
    imageCount := 0

    for time.Since(startTime) < time.Minute {
        if err := downloadImage(imageURL, folderPath); err == nil {
            imageCount++
        }
    }

    fmt.Printf("Completed downloading images for 1 minute. Total images downloaded: %d\n", imageCount)
}

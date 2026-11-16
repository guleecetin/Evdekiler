using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.Extensions.Options;

namespace Evdekiler.Pantry.Api.Storage;

public class StorageOptions
{
    public string ConnectionString { get; set; } = string.Empty;
    public string Container { get; set; } = "media";
}

// Recipe servisindekinin kopyası: servisler ortak koda bağlanmasın diye bilinçli tekrar
public class ImageStorage(BlobServiceClient client, IOptions<StorageOptions> options)
{
    private const string MediaPrefix = "/media/";
    private readonly string _container = options.Value.Container;

    public async Task<string> UploadAsync(Stream content, string blobName, string contentType, CancellationToken ct)
    {
        var container = client.GetBlobContainerClient(_container);
        await container.CreateIfNotExistsAsync(PublicAccessType.Blob, cancellationToken: ct);

        await container.GetBlobClient(blobName).UploadAsync(content, new BlobUploadOptions
        {
            HttpHeaders = new BlobHttpHeaders
            {
                ContentType = contentType,
                CacheControl = "public, max-age=31536000, immutable"
            }
        }, ct);

        return $"{MediaPrefix}{blobName}";
    }

    public async Task DeleteByUrlAsync(string? url, CancellationToken ct)
    {
        if (string.IsNullOrEmpty(url) || !url.StartsWith(MediaPrefix)) return;

        await client.GetBlobContainerClient(_container)
            .GetBlobClient(url[MediaPrefix.Length..])
            .DeleteIfExistsAsync(cancellationToken: ct);
    }
}

// Dosyanın gerçekten resim olup olmadığını ilk baytlarından anlar
public static class ImageFormats
{
    public static (string Extension, string ContentType)? Detect(byte[] h)
    {
        if (h.Length < 12) return null;
        if (h[0] == 0xFF && h[1] == 0xD8 && h[2] == 0xFF) return ("jpg", "image/jpeg");
        if (h[0] == 0x89 && h[1] == 0x50 && h[2] == 0x4E && h[3] == 0x47) return ("png", "image/png");
        if (h[0] == 0x52 && h[1] == 0x49 && h[2] == 0x46 && h[3] == 0x46 &&
            h[8] == 0x57 && h[9] == 0x45 && h[10] == 0x42 && h[11] == 0x50) return ("webp", "image/webp");
        return null;
    }
}
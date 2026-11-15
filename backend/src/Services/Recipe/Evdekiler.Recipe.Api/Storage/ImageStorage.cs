using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.Extensions.Options;

namespace Evdekiler.Recipe.Api.Storage;

public class StorageOptions
{
    public string ConnectionString { get; set; } = string.Empty;
    public string Container { get; set; } = "media";
}

public class ImageStorage(BlobServiceClient client, IOptions<StorageOptions> options)
{
    private const string MediaPrefix = "/media/";
    private readonly string _container = options.Value.Container;

    public async Task<string> UploadAsync(
        Stream content, string blobName, string contentType, CancellationToken ct)
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

    // Sadece bizim depomuzdaki dosyaları siler (/media/...); eski wwwroot fotoğraflarına dokunmaz
    public async Task DeleteByUrlAsync(string? url, CancellationToken ct)
    {
        if (string.IsNullOrEmpty(url) || !url.StartsWith(MediaPrefix)) return;

        var blobName = url[MediaPrefix.Length..];
        await client.GetBlobContainerClient(_container)
            .GetBlobClient(blobName)
            .DeleteIfExistsAsync(cancellationToken: ct);
    }
}
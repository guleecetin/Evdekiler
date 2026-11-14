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
    private readonly string _container = options.Value.Container;

    // Dosyayı yükler, uygulamanın kullanacağı adresi döner: /media/recipes/xxx.jpg
    public async Task<string> UploadAsync(
        Stream content, string blobName, string contentType, CancellationToken ct)
    {
        var container = client.GetBlobContainerClient(_container);

        // Container yoksa oluştur; içindeki dosyalar herkese açık okunabilir
        await container.CreateIfNotExistsAsync(PublicAccessType.Blob, cancellationToken: ct);

        await container.GetBlobClient(blobName).UploadAsync(content, new BlobUploadOptions
        {
            HttpHeaders = new BlobHttpHeaders
            {
                ContentType = contentType,
                // Dosya adı benzersiz ve hiç değişmeyecek: istemci bir yıl önbellekte tutabilir
                CacheControl = "public, max-age=31536000, immutable"
            }
        }, ct);

        return $"/media/{blobName}";
    }
}
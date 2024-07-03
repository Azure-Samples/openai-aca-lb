using Azure.Core;
using Azure.Identity;

namespace openai_loadbalancer;

public class AzureCredentialTokenProvider
{
    private AccessToken? _accessToken;
    private readonly SemaphoreSlim _semaphore = new(1, 1);

    public async Task<string> GetTokenAsync()
    {
        if (_accessToken == null || IsExpired())
        {
            await _semaphore.WaitAsync();
            try
            {
                if (_accessToken == null || IsExpired())
                {
                    _accessToken = await new DefaultAzureCredential().GetTokenAsync(
                            new TokenRequestContext(scopes: ["https://cognitiveservices.azure.com/.default"]));
                }
            }
            finally
            {
                _semaphore.Release();
            }
        }
        
        return _accessToken.Value.Token;
    }

    private bool IsExpired()
    {
        return _accessToken == null || DateTimeOffset.UtcNow >= _accessToken.Value.ExpiresOn.AddMinutes(-5);
    }
}
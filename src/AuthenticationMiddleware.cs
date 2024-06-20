using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;

namespace openai_loadbalancer;

public class AuthenticationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<AuthenticationMiddleware> _logger;
    private readonly IDictionary<string, string> _customerConfigurations;

    public AuthenticationMiddleware(RequestDelegate next, ILogger<AuthenticationMiddleware> logger, IConfiguration configuration)
    {
        _next = next;
        _logger = logger;
        _customerConfigurations = configuration.GetSection("CustomerConfiguration").Get<Dictionary<string, string>>() ?? [];
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (!context.Request.Headers.TryGetValue("api-key", out var extractedApiKey))
        {
            _logger.LogWarning("API key was not provided.");
            context.Response.StatusCode = 401; // Unauthorized
            await context.Response.WriteAsync("API key is missing.");
            return;
        }

        var customer = _customerConfigurations.FirstOrDefault(c => c.Value == extractedApiKey);

        if (customer.Equals(default(KeyValuePair<string, string>)))
        {
            // display client id in logs
            _logger.LogWarning($"Unauthorized client.");
            context.Response.StatusCode = 401; // Unauthorized
            await context.Response.WriteAsync("Unauthorized client.");
            return;
        }

        _logger.LogInformation($"Customer '{customer.Key}' successfully authenticated.");
        await _next(context);
    }
}
